//
//  ActionMenuItem.swift
//  ActionMenuItem
//
//  Created by Kyle on 2021/10/9.
//

import AppKit
import Foundation

struct ActionMenuItem: MenuItem, Sendable {
    static func == (lhs: ActionMenuItem, rhs: ActionMenuItem) -> Bool {
        lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) { hasher.combine(key) }

    // Stored indexes are legacy data, not authority to choose another operation.
    var safeActionIndex: Int? { Self.all.first(where: { $0.key == key })?.actionIndex }

    var key: String
    var name: String { String(localized: String.LocalizationValue(key)) }
    var enabled = true
    var actionIndex: Int

    var icon: NSImage {
        let symbols = ["Copy Path": "doc.on.clipboard", "Copy File Name": "textformat", "Go Parent Directory": "folder", "New File": "doc.badge.plus"]
        return NSImage(systemSymbolName: symbols[key] ?? "questionmark.square", accessibilityDescription: name) ?? NSImage()
    }
}

extension ActionMenuItem {
    static let all: [ActionMenuItem] = [.copyPath, copyFileName, .goParent, .newFile]

    static let copyPath = ActionMenuItem(key: "Copy Path", actionIndex: 0)
    static let copyFileName = ActionMenuItem(key: "Copy File Name", actionIndex: 1)
    static let goParent = ActionMenuItem(key: "Go Parent Directory", actionIndex: 2)
    static let newFile = ActionMenuItem(key: "New File", actionIndex: 3)

    // MARK: - Making the compiler to extract Localized key

    #if DEBUG
    // FIXME: - Refactor this when compiler time const is introduced to Swift
    private static let copyPathString = NSLocalizedString("Copy Path", comment: "Copy Path")
    private static let copyFileNameString = NSLocalizedString("Copy File Name", comment: "Copy File Name")
    private static let goParentString = NSLocalizedString("Go Parent Directory", comment: "Go Parent Directory")
    private static let newFileString = NSLocalizedString("New File", comment: "New File")
    #endif
}
