// Security-sensitive file and permission helpers for Finder Menu Tools.
// Copyright 2026 Byron Delgado. Distributed under FSL-1.1-MIT.
import Darwin
import Foundation

enum FileActionSafety {
    enum ValidationError: LocalizedError {
        case nonFileURL, invalidName, invalidApplication
        var errorDescription: String? {
            switch self {
            case .nonFileURL: return "Choose a local file or folder."
            case .invalidName: return "Use a single file name without path separators or control characters."
            case .invalidApplication: return "Select a macOS application (.app) in Settings."
            }
        }
    }

    static func createEmptyFile(for selection: URL, name: String, fileExtension: String?) throws -> URL {
        guard selection.isFileURL else { throw ValidationError.nonFileURL }
        let baseName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : name
        func validate(_ component: String) throws {
            guard !component.isEmpty, component != ".", component != "..",
                  !component.contains("/"),
                  component.rangeOfCharacter(from: .controlCharacters) == nil else {
                throw ValidationError.invalidName
            }
        }
        try validate(baseName)
        var filename = baseName
        if let fileExtension, !fileExtension.isEmpty {
            try validate(fileExtension)
            filename += "." + fileExtension
        }
        let isDirectory = try selection.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true
        let directory = isDirectory ? selection : selection.deletingLastPathComponent()
        let directoryFD = Darwin.open(directory.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard directoryFD >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { Darwin.close(directoryFD) }
        // Resolve only one filename relative to the opened directory. Never truncate
        // an existing item or follow a destination symlink, even during a race.
        let fileFD = Darwin.openat(directoryFD, filename, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, mode_t(0o600))
        guard fileFD >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        Darwin.close(fileFD)
        return directory.appendingPathComponent(filename, isDirectory: false)
    }

    static func isPermissionError(_ error: NSError, depth: Int = 0) -> Bool {
        if error.domain == NSCocoaErrorDomain && [NSFileReadNoPermissionError, NSFileWriteNoPermissionError].contains(error.code) { return true }
        if error.domain == NSPOSIXErrorDomain && [Int(EACCES), Int(EPERM)].contains(error.code) { return true }
        if error.domain == NSOSStatusErrorDomain && [-54, -5000].contains(error.code) { return true }
        if depth < 4, let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            return isPermissionError(underlying, depth: depth + 1)
        }
        return false
    }
}

// Owned and updated by the folder store on the main actor. Decoding a bookmark
// does not acquire access; this object balances each successful acquisition.
final class SecurityScopedResourceAccess {
    private var active: [String: URL] = [:]
    private let start: (URL) -> Bool
    private let stop: (URL) -> Void

    init(start: @escaping (URL) -> Bool = { $0.startAccessingSecurityScopedResource() },
         stop: @escaping (URL) -> Void = { $0.stopAccessingSecurityScopedResource() }) {
        self.start = start
        self.stop = stop
    }

    func update(_ urls: [URL]) {
        let requested = Dictionary(urls.filter(\.isFileURL).map { ($0.path, $0) }, uniquingKeysWith: { first, _ in first })
        for path in Array(active.keys) where requested[path] == nil {
            if let url = active.removeValue(forKey: path) { stop(url) }
        }
        for (path, url) in requested where active[path] == nil {
            if start(url) { active[path] = url }
        }
    }

    deinit {
        for url in active.values { stop(url) }
    }
}

// Finder's menu bridge reliably transports integer tags. Keep each generation's
// immutable payload locally rather than sending Swift objects through that bridge.
final class MenuCommandRegistry<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var nextTag = 0
    private var generations: [[Int: Value]] = []

    func register(_ values: [Value]) -> [(tag: Int, value: Value)] {
        lock.withLock {
            guard values.count <= Int.max - nextTag else { return [] }
            var generation: [Int: Value] = [:]
            let entries = values.map { value in
                nextTag += 1
                generation[nextTag] = value
                return (tag: nextTag, value: value)
            }
            generations.append(generation)
            if generations.count > 8 { generations.removeFirst() }
            return entries
        }
    }

    func value(for tag: Int) -> Value? {
        lock.withLock {
            for generation in generations.reversed() {
                if let value = generation[tag] { return value }
            }
            return nil
        }
    }
}
