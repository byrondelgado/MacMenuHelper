// Fail release preparation if signing grants more privileges than intended.
// Copyright 2026 Byron Delgado. Distributed under FSL-1.1-MIT.
import Foundation

enum VerificationFailure: Error { case invalid(String) }
func command(_ arguments: [String]) throws -> (Data, String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
    process.arguments = arguments
    let output = Pipe(); let errors = Pipe()
    process.standardOutput = output; process.standardError = errors
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    let stderr = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw VerificationFailure.invalid("codesign verification failed") }
    return (data, stderr)
}

do {
    guard CommandLine.arguments.count == 2 else { throw VerificationFailure.invalid("Provide the app bundle path") }
    let app = URL(fileURLWithPath: CommandLine.arguments[1])
    let extensionURL = app.appendingPathComponent("Contents/PlugIns/MenuHelperExtension.appex")
    _ = try command(["--verify", "--deep", "--strict", app.path])
    for (bundle, access) in [(app, "read-only"), (extensionURL, "read-write")] {
        let (data, _) = try command(["-d", "--entitlements", "-", "--xml", bundle.path])
        guard let entitlements = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw VerificationFailure.invalid("Unreadable entitlements")
        }
        let expected: [String: Any] = [
            "com.apple.security.app-sandbox": true,
            "com.apple.security.files.user-selected.\(access)": true,
            "com.apple.security.temporary-exception.shared-preference.read-write": ["com.byrondelgado.MacMenuHelper.preferences"],
        ]
        guard NSDictionary(dictionary: entitlements).isEqual(to: expected) else {
            throw VerificationFailure.invalid("Unexpected entitlements in \(bundle.lastPathComponent)")
        }
        let (_, description) = try command(["-d", "--verbose=4", bundle.path])
        guard description.split(separator: "\n").contains(where: { $0.hasPrefix("CodeDirectory") && $0.contains("runtime") }) else {
            throw VerificationFailure.invalid("Hardened runtime missing")
        }
    }
    print("PASS: exact sandbox entitlements, least file access, hardened runtime and nested signatures")
} catch {
    fputs("Security verification failed: \(error)\n", stderr)
    exit(1)
}
