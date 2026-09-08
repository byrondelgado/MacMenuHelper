//
//  StringExtension.swift
//  MenuHelper
//
//  Created by Kyle on 2021/10/20.
//

import Foundation

let appDisplayName = "Finder Menu Tools"
let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
var subsystem: String { bundleIdentifier }

enum Key {
    static let showContextualMenuForItem = "SHOW_CONTEXTUAL_MENU_FOR_ITEM"
    static let showContextualMenuForContainer = "SHOW_CONTEXTUAL_MENU_FOR_CONTAINER"
    static let showContextualMenuForSidebar = "SHOW_CONTEXTUAL_MENU_FOR_SIDEBAR"
    static let showToolbarItemMenu = "SHOW_TOOLBAR_ITEM_MENU"

    static let globalApplicationArgumentsString = "GLOBAL_APPLICATION_ARGUMENTS_STRING"
    static let globalApplicationEnvironmentString = "GLOBAL_APPLICATION_ENVIRONMENT_STRING"

    static let copySeparator = "COPY_SEPARATOR"
    static let copyOption = "COPY_OPTION"
    static let newFileName = "NEW_FILE_NAME"
    static let newFileExtension = "NEW_FILE_EXTENSION"

    static let showSubMenuForApplication = "SHOW_SUB_MENU_FOR_APPLICATION"
    static let showSubMenuForAction = "SHOW_SUB_MENU_FOR_ACTION"
}

enum CopyOption: Int, CustomStringConvertible, CaseIterable, Identifiable {
    var id: Int { rawValue }

    case origin, escape, quoto

    var description: String {
        switch self {
        case .origin: return String(localized: "Use origin path")
        case .escape: return String(localized: "Escape for shell")
        case .quoto: return String(localized: "Quote for shell")
        }
    }

    func format(_ value: String) -> String {
        func quoted() -> String { "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'" }
        switch self {
        case .origin: return value
        case .quoto: return quoted()
        case .escape:
            guard !value.isEmpty, value.rangeOfCharacter(from: .controlCharacters) == nil else { return quoted() }
            let safe = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/_-.")
            return value.unicodeScalars.map { safe.contains($0) ? String($0) : "\\" + String($0) }.joined()
        }
    }

    func join(_ values: [String], separator: String) -> String {
        // A custom separator must not reintroduce shell operators between safe words.
        values.map(format).joined(separator: self == .origin ? separator : " ")
    }
}

enum NewFileExtension: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case none = "(none)"
    case swift
    case txt
}

extension String {
    func toDictionary(separator: Character = " ") -> [String: String] {
        split(separator: separator)
            .map { $0.split(separator: "=") }
            .filter { $0.count == 2 }
            .reduce(into: [String: String]()) { result, pair in
                let key = String(pair[0])
                let value = String(pair[1])
                result[key] = value
            }
    }
    
    func toArray(separator: Character = " ") -> [String] {
        split(separator: separator)
            .map { String($0) }
    }
}

extension Dictionary {
    func toString(separator: String = " ") -> String {
        compactMap { "\($0)=\($1)" }.joined(separator: separator)
    }
}
