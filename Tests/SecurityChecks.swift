// Regression checks for security-sensitive behaviour, using the production helpers.
// Copyright 2026 Byron Delgado. Distributed under FSL-1.1-MIT.
import AppKit
import Foundation

final class TestChannel {
    var sends = 0
    func send(name: String) { sends += 1 }
}
let channel = TestChannel()

enum CheckFailure: Error { case failed(String) }
func check(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
    if try !condition() { throw CheckFailure.failed(message) }
}
func rejects(_ message: String, _ operation: () throws -> Void) throws {
    do { try operation() } catch { return }
    throw CheckFailure.failed(message)
}

@main
struct SecurityChecks {
    static func main() async {
        do { try await runChecks() }
        catch {
            fputs("FAIL: \(error)\n", stderr)
            exit(1)
        }
    }

    @MainActor static func runChecks() async throws {
        let manager = FileManager.default
        let root = manager.temporaryDirectory.appendingPathComponent("finder-menu-security-" + UUID().uuidString)
        try manager.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: root) }
        guard let domain = Bundle.main.object(forInfoDictionaryKey: "MenuHelperPreferencesDomain") as? String,
              domain.contains(".security-tests.") else { fatalError("Isolated test preference domain missing") }
        UserDefaults.group.removePersistentDomain(forName: domain)
        defer { UserDefaults.group.removePersistentDomain(forName: domain) }

        // Creation is confined to one filename and cannot clobber existing entries.
        let created = try FileActionSafety.createEmptyFile(for: root, name: "", fileExtension: nil)
        try check(created.lastPathComponent == "Untitled", "Empty name did not use Untitled")
        let data = Data("keep this content".utf8)
        try data.write(to: created)
        try rejects("Existing file was overwritten") {
            _ = try FileActionSafety.createEmptyFile(for: root, name: "Untitled", fileExtension: nil)
        }
        try check(try Data(contentsOf: created) == data, "Existing data changed")
        let victim = root.appendingPathComponent("victim")
        try data.write(to: victim)
        let symlink = root.appendingPathComponent("link")
        try manager.createSymbolicLink(at: symlink, withDestinationURL: victim)
        try rejects("Destination symlink was followed") {
            _ = try FileActionSafety.createEmptyFile(for: root, name: "link", fileExtension: nil)
        }
        try check(try Data(contentsOf: victim) == data, "Symlink victim changed")
        let absent = root.appendingPathComponent("absent")
        try manager.createSymbolicLink(at: root.appendingPathComponent("broken"), withDestinationURL: absent)
        try rejects("Broken symlink destination created") {
            _ = try FileActionSafety.createEmptyFile(for: root, name: "broken", fileExtension: nil)
        }
        try check(!manager.fileExists(atPath: absent.path), "Broken symlink target appeared")
        try manager.linkItem(at: victim, to: root.appendingPathComponent("hardlink"))
        try rejects("Existing hard link was replaced") {
            _ = try FileActionSafety.createEmptyFile(for: root, name: "hardlink", fileExtension: nil)
        }
        for name in ["../outside", "/tmp/outside", "nested/file", ".", "..", "bad\u{0}name", "bad\nname"] {
            try rejects("Invalid filename accepted") {
                _ = try FileActionSafety.createEmptyFile(for: root, name: name, fileExtension: nil)
            }
        }
        try rejects("Extension path traversal accepted") {
            _ = try FileActionSafety.createEmptyFile(for: root, name: "safe", fileExtension: "../bad")
        }
        try rejects("Remote selection accepted") {
            _ = try FileActionSafety.createEmptyFile(for: URL(string: "https://example.com/folder")!, name: "safe", fileExtension: nil)
        }
        let sibling = try FileActionSafety.createEmptyFile(for: victim, name: "sibling", fileExtension: "txt")
        try check(sibling.deletingLastPathComponent().path == root.path && sibling.lastPathComponent == "sibling.txt", "File selection did not use parent directory")
        let permissions = try manager.attributesOfItem(atPath: sibling.path)[.posixPermissions] as? NSNumber
        try check(permissions?.intValue == 0o600, "New file mode is not 0600")
        let lock = NSLock()
        var successes = 0
        DispatchQueue.concurrentPerform(iterations: 24) { _ in
            if (try? FileActionSafety.createEmptyFile(for: root, name: "concurrent", fileExtension: nil)) != nil {
                lock.withLock { successes += 1 }
            }
        }
        try check(successes == 1, "Exclusive creation allowed more than one writer")
        print("PASS: file creation, collisions, traversal, symlinks, modes and concurrent creation")

        // Shell output must round-trip as one argument, without executing filenames.
        let marker = root.appendingPathComponent("executed").path
        let values = ["plain", "a b", "a'b", "a\"b", "a\\b", "a;b", "$(touch \(marker))", "`touch \(marker)`", "a\nb", "a\tb", "!123", "[ab]*?", "é日本語", ""]
        for value in values {
            try check(CopyOption.origin.format(value) == value, "Literal copy changed content")
            for option in [CopyOption.escape, .quoto] {
                for shell in ["/bin/sh", "/bin/bash", "/bin/zsh"] {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: shell)
                    process.arguments = ["-c", "printf '%s' " + option.format(value)]
                    let output = Pipe(); process.standardOutput = output
                    try process.run()
                    let actual = output.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    // NSTask may canonicalise Unicode arguments on macOS. Compare their logical value.
                    try check(process.terminationStatus == 0 && String(decoding: actual, as: UTF8.self) == value, "Shell copy did not round-trip: shell=\(shell), mode=\(option.rawValue), input=\(value.debugDescription), output=\(String(decoding: actual, as: UTF8.self).debugDescription), status=\(process.terminationStatus)")
                    try check(!manager.fileExists(atPath: marker), "Filename was executed by a shell")
                }
            }
        }
        try check(CopyOption.escape.join(["one", "two"], separator: "; touch injected;") == "one two", "Custom separator injected shell syntax")
        try check(CopyOption.origin.join(["one", "two"], separator: "\n") == "one\ntwo", "Literal separator changed")
        print("PASS: literal and shell formats, including command substitutions, quotes, newlines and separators")

        // Scopes must not grow on refresh or outlive their owner's requested list.
        var starts = 0; var stops = 0
        var access: SecurityScopedResourceAccess? = SecurityScopedResourceAccess(start: { _ in starts += 1; return true }, stop: { _ in stops += 1 })
        access?.update([root, root, victim])
        access?.update([root, victim])
        try check(starts == 2 && stops == 0, "Repeated refresh leaked scope acquisitions")
        access?.update([root])
        try check(stops == 1, "Removed scope was not released")
        access?.update([])
        try check(stops == 2, "Clear-all did not release scopes")
        access?.update([root]); access = nil
        try check(starts == 3 && stops == 3, "Owner destruction did not balance scopes")
        let denied = SecurityScopedResourceAccess(start: { _ in false }, stop: { _ in stops += 1 })
        denied.update([root]); denied.update([])
        try check(stops == 3, "Unsuccessful acquisition was incorrectly released")
        try rejects("Remote bookmark accepted") { _ = try BookmarkFolderItem(URL(string: "https://example.com")!) }
        print("PASS: balanced scope lifetime and invalid bookmark input")

        // Legacy serialized indexes cannot select a different operation or crash.
        try check(ActionMenuItem(key: "Copy Path", actionIndex: 3).safeActionIndex == 0, "Mislabeled action could create a file")
        try check(ActionMenuItem(key: "Copy Path", actionIndex: Int.max).safeActionIndex == 0, "Oversized action index not neutralized")
        try check(ActionMenuItem(key: "unexpected", actionIndex: 0).safeActionIndex == nil, "Unknown action accepted")
        let first = AppMenuItem(appURL: URL(fileURLWithPath: "/Applications/Code.app"))
        let second = AppMenuItem(appURL: URL(fileURLWithPath: "/Applications/Visual Studio Code.app"))
        let registry = MenuCommandRegistry<AppMenuItem>()
        let originalCommands = registry.register([first, second])
        let reordered = registry.register([second, first])
        try check(registry.value(for: originalCommands[1].tag)?.url == second.url, "Old menu dispatched to a reordered application")
        try check(originalCommands[1].tag != reordered[1].tag, "Menu command IDs were reused")
        for _ in 0..<8 { _ = registry.register([first]) }
        try check(registry.value(for: originalCommands[1].tag) == nil, "Expired command did not fail closed")
        let store = MenuItemStore()
        await Task.yield()
        store.appItems = [first, second]
        store.actionItems = ActionMenuItem.all
        let saved = store.snapshot()
        let sends = channel.sends
        store.refresh()
        try check(channel.sends == sends, "Refresh published another notification")
        store.appItems[0].enabled = false
        try check(saved.appItems[0].enabled && !store.snapshot().appItems[0].enabled, "Snapshot changed after publication")
        let reader = Task.detached {
            for _ in 0..<2_000 {
                let snapshot = store.snapshot()
                precondition(snapshot.appItems.count == 2)
                precondition(snapshot.appItems[1].url == second.url)
            }
        }
        for i in 0..<100 { store.appItems[0].enabled = i.isMultiple(of: 2) }
        await reader.value
        let deniedError = NSError(domain: NSPOSIXErrorDomain, code: 13)
        try check(FileActionSafety.isPermissionError(deniedError), "Permission error was not recognized")
        try check(!FileActionSafety.isPermissionError(NSError(domain: NSOSStatusErrorDomain, code: -10814)), "Unrelated launch error requested folder access")
        print("PASS: action identity, indexes, immutable snapshots, refresh and error classification")
    }
}
