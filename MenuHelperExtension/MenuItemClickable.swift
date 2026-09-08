//
//  MenuItemClickable.swift
//  MenuHelperExtension
//
//  Created by Kyle on 2021/10/9.
//

import AppKit
import Foundation
import os.log

private let logger = Logger(subsystem: subsystem, category: "menu_click")

@MainActor
protocol MenuItemClickable {
    func menuClick(with urls: [URL])
}

extension AppMenuItem: MenuItemClickable {
    func menuClick(with urls: [URL]) {
        guard !urls.isEmpty, urls.allSatisfy(\.isFileURL) else {
            NSAlert(error: FileActionSafety.ValidationError.nonFileURL).runModal()
            return
        }
        guard url.isFileURL, url.pathExtension.lowercased() == "app" else {
            NSAlert(error: FileActionSafety.ValidationError.invalidApplication).runModal()
            return
        }
        Task { @MainActor in
            do {
                let config = NSWorkspace.OpenConfiguration()
                config.promptsUserIfNeeded = true
                config.arguments = arguments + (inheritFromGlobalArguments ? UserDefaults.group.globalApplicationArguments : [])
                config.environment = inheritFromGlobalEnvironment
                    ? environment.merging(UserDefaults.group.globalApplicationEnvironment, uniquingKeysWith: { old, _ in old })
                    : environment
                _ = try await NSWorkspace.shared.open(urls, withApplicationAt: url, configuration: config)
                logger.notice("Application opened successfully")
            } catch {
                let nsError = error as NSError
                logger.error("Application launch failed: \(nsError.domain, privacy: .public) code \(nsError.code)")
                guard FileActionSafety.isPermissionError(nsError), let first = urls.first else {
                    NSAlert(error: error).runModal()
                    return
                }
                let panel = NSOpenPanel()
                panel.message = String(localized: "Choose a folder to allow Finder Menu Tools to open its files.")
                panel.allowsMultipleSelection = true
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.directoryURL = first.hasDirectoryPath ? first : first.deletingLastPathComponent()
                if await panel.begin() == .OK {
                    do {
                        folderStore.appendItems(try panel.urls.map { try BookmarkFolderItem($0) })
                    } catch {
                        NSAlert(error: error).runModal()
                    }
                }
            }
        }
    }
}

extension ActionMenuItem: MenuItemClickable {
    @MainActor private static let actions: [([URL]) -> ActionMenuResult] = [
        { urls in
            let board = NSPasteboard.general
            board.clearContents()
            let string = UserDefaults.group.copyOption.join(urls.map(\.path), separator: UserDefaults.group.copySeparator)
            let success = board.setString(string, forType: .string)

            return ActionMenuResult(success: success, message: "Copied \(urls.count) items")
        },
        { urls in
            let board = NSPasteboard.general
            board.clearContents()
            let string = UserDefaults.group.copyOption.join(urls.map(\.lastPathComponent), separator: UserDefaults.group.copySeparator)
            let success = board.setString(string, forType: .string)
            return ActionMenuResult(success: success, message: "Copied \(urls.count) items")
        },
        { urls in
            let subResults = urls.map { url in
                let success = NSWorkspace.shared.selectFile(url.deletingLastPathComponent().path, inFileViewerRootedAtPath: "")
                return ActionMenuResult(success: success)
            }
            return ActionMenuResult(success: subResults.allSatisfy(\.success), subResults: subResults)
        },
        { urls in
            let subResults = urls.map { url in
                do {
                    let extensionOption = UserDefaults.group.newFileExtension
                    _ = try FileActionSafety.createEmptyFile(
                        for: url,
                        name: UserDefaults.group.newFileName,
                        fileExtension: extensionOption == .none ? nil : extensionOption.rawValue
                    )
                    return ActionMenuResult(success: true)
                } catch {
                    NSAlert(error: error).runModal()
                    return ActionMenuResult(success: false, message: "Could not create a new file")
                }
            }
            return ActionMenuResult(success: subResults.allSatisfy(\.success), subResults: subResults)
        },
    ]

    func menuClick(with urls: [URL]) {
        guard !urls.isEmpty, urls.allSatisfy(\.isFileURL),
              let index = safeActionIndex, Self.actions.indices.contains(index) else {
            logger.error("Rejected an invalid action or selection")
            return
        }
        let result = Self.actions[index](urls)
        if result.success {
            logger.notice("\(result.description, privacy: .public)")
        } else {
            logger.error("\(result.description, privacy: .public)")
        }
    }
}

struct ActionMenuResult: CustomStringConvertible {
    var success = false
    var message: String?
    var subResults: [ActionMenuResult]?

    var description: String {
        var result = "ActionMenuResult:\n"
        result.append("success: \(success ? "✅" : "❌") \n")
        if let message {
            result.append("message: \(message)\n")
        }
        if let subResults {
            result.append("subResults:\n")
            subResults.forEach { result.append($0.description) }
            result.append("\n")
        }
        return result
    }
}
