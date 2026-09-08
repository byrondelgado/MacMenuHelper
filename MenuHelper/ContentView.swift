//
//  ContentView.swift
//  MenuHelper
//
//  Created by Kyle on 2021/6/27.
//

import FinderSync
import os.log
import SwiftUI

private let logger = Logger(subsystem: subsystem, category: "main")

struct ContentView: View {
    @Environment(\.openSettings) private var openSettings

    private var enable: Bool {
        FIFinderSyncController.isExtensionEnabled
    }

    private var imageName: String {
        enable ? "gear.badge.checkmark" : "gear.badge.xmark"
    }

    private var hint: LocalizedStringKey {
        enable
        ? "The Finder Menu Tools extension is enabled. You can manage it in System Settings."
        : "Enable the Finder Menu Tools extension in System Settings to show its Finder commands."
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50)
                        .symbolRenderingMode(.multicolor)
                    Text(hint)
                        .multilineTextAlignment(.leading)
                }
            } header: {
                HStack {
                    Spacer()
                    Image("ForkIcon")
                    Spacer()
                }
            }
            Section {
                Button {
                    FIFinderSyncController.showExtensionManagementInterface()
                } label: {
                    Text("Open System Extension Panel...")
                }
                SettingsLink {
                    Text("Open App Settings Window...")
                }
            }
            .buttonStyle(.link)
            .foregroundStyle(.accent)
        }
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
        .handlesExternalEvents(preferring: ["finder-menu-tools://settings"], allowing: ["finder-menu-tools://settings"])
        .onOpenURL { url in
            guard url.scheme == "finder-menu-tools", url.host == "settings" else { return }
            logger.notice("Opening Settings from Finder")
            Task { @MainActor in
                openSettings()
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
