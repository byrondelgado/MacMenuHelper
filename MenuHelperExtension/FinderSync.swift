//
//  FinderSync.swift
//  MenuHelperExtension
//
//  Created by Kyle on 2021/6/27.
//

import Cocoa
import Darwin
import FinderSync
import os.log

let menuStore = MenuItemStore()
let folderStore = FolderItemStore()
let channel = FinderCommChannel()
private let logger = Logger(subsystem: subsystem, category: "menu")

class FinderSync: FIFinderSync {
    private enum Command: Sendable {
        case application(AppMenuItem)
        case action(ActionMenuItem)
    }
    private let commands = MenuCommandRegistry<Command>()

    override init() {
        super.init()
        // Populate the store before Finder requests its first contextual menu.
        menuStore.refresh()
        channel.setup()
        logger.notice("Finder extension started")
        FIFinderSyncController.default().directoryURLs = Set(folderStore.syncItems.map { URL(fileURLWithPath: $0.path) })

        // Monitor volumes
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didMountNotification, object: nil, queue: .main) { notification in
            if let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                Task {
                    await MainActor.run {
                        folderStore.appendItem(SyncFolderItem(volumeURL))
                    }
                }
            }
        }
    }

    // MARK: - Menu and toolbar item support

    override var toolbarItemName: String { UserDefaults.group.showToolbarItemMenu ? appDisplayName : "" }

    override var toolbarItemToolTip: String { UserDefaults.group.showToolbarItemMenu ? appDisplayName : "" }

    override var toolbarItemImage: NSImage {
        func defaultImage() -> NSImage {
            logger.info("showToolbarItemMenu: \(UserDefaults.group.showToolbarItemMenu, privacy: .public)")
            return NSImage()
        }
        if UserDefaults.group.showToolbarItemMenu {
            return NSImage(systemSymbolName: "terminal", accessibilityDescription: appDisplayName) ?? defaultImage()
        } else {
            return defaultImage()
        }
    }

    // This should not be marked as MainActor otherwise it will trigger a crash
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        switch menuKind {
        case .contextualMenuForItems:
            if !UserDefaults.group.showContextualMenuForItem { return NSMenu() }
        case .contextualMenuForContainer:
            if !UserDefaults.group.showContextualMenuForContainer { return NSMenu() }
        case .contextualMenuForSidebar:
            if !UserDefaults.group.showContextualMenuForSidebar { return NSMenu() }
        case .toolbarItemMenu:
            if !UserDefaults.group.showToolbarItemMenu { return NSMenu() }
        @unknown default:
            break
        }
        // Produce a menu for the extension.
        logger.notice("Create menu for \(menuKind.rawValue)")
        let menu = NSMenu(title: appDisplayName)
        menu.showsStateColumn = true

        let snapshot = menuStore.snapshot()
        let entries = commands.register(
            snapshot.appItems.filter(\.enabled).map(Command.application)
            + snapshot.actionItems.filter { $0.enabled && $0.safeActionIndex != nil }.map(Command.action)
        )
        let applicationMenu: NSMenu
        if UserDefaults.group.showSubMenuForApplication {
            applicationMenu = NSMenu()
            let applicationSubMenuItem = NSMenuItem(title: String(localized: "Application Menus"), action: nil, keyEquivalent: "")
            menu.addItem(applicationSubMenuItem)
            menu.setSubmenu(applicationMenu, for: applicationSubMenuItem)
        } else {
            applicationMenu = menu
        }
        for entry in entries {
            guard case let .application(item) = entry.value else { continue }
            let menuItem = NSMenuItem()
            menuItem.target = self
            menuItem.title = String(format: String(localized: "Open in %@", comment: "Open in the given application"), item.name)
            menuItem.action = #selector(menuAction(_:))
            menuItem.toolTip = "\(item.name)"
            menuItem.tag = entry.tag
            if menuKind == .toolbarItemMenu {
                menuItem.image = item.icon
            }
            applicationMenu.addItem(menuItem)
        }

        let actionMenu: NSMenu
        if UserDefaults.group.showSubMenuForAction {
            actionMenu = NSMenu()
            let actionSubMenuItem = NSMenuItem(title: String(localized: "Action Menus"), action: nil, keyEquivalent: "")
            menu.addItem(actionSubMenuItem)
            menu.setSubmenu(actionMenu, for: actionSubMenuItem)
        } else {
            actionMenu = menu
        }
        for entry in entries {
            guard case let .action(item) = entry.value else { continue }
            let menuItem = NSMenuItem()
            menuItem.target = self
            menuItem.title = item.name
            menuItem.action = #selector(menuAction(_:))
            menuItem.toolTip = "\(item.name)"
            menuItem.tag = entry.tag
            if menuKind == .toolbarItemMenu {
                menuItem.image = item.icon
            }
            actionMenu.addItem(menuItem)
        }

        if !menu.items.isEmpty {
            menu.addItem(.separator())
        }
        let settingsItem = NSMenuItem(
            title: String(localized: "Finder Menu Tools Settings…"),
            action: #selector(openAppSettings(_:)),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        return menu
    }

    @objc
    private func openAppSettings(_ sender: NSMenuItem) {
        guard let url = URL(string: "finder-menu-tools://settings") else { return }
        logger.notice("Requesting the Settings window")
        let appURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        guard appURL.pathExtension == "app" else { return }
        // Target our containing app, not whichever app registered the URL scheme.
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: .init()) { _, error in
            if error != nil { logger.error("Unable to open Finder Menu Tools settings") }
        }
    }

    @objc
    func menuAction(_ menuItem: NSMenuItem) {
        guard let targetURL = FIFinderSyncController.default().targetedURL(),
              let itemURLs = FIFinderSyncController.default().selectedItemURLs() else { return }
        let urls = itemURLs.isEmpty ? [targetURL] : itemURLs
        guard urls.allSatisfy(\.isFileURL) else { return }
        logger.notice("Dispatching a menu action for \(urls.count) items")
        guard let command = commands.value(for: menuItem.tag) else { return }
        Task { @MainActor in
            switch command {
            case let .application(item): item.menuClick(with: urls)
            case let .action(item): item.menuClick(with: urls)
            }
        }
    }
}
