//
//  NotimanagerApp.swift
//  Notimanager
//
//  Created on 2025-11-16.
//  Updated 2026-01-17: Now using pure AppKit NSMenu instead of SwiftUI MenuBarExtra
//  to fix nested submenu bug where child menus don't open properly.
//

import SwiftUI

// MARK: - Notification.Name Extensions

extension Notification.Name {
    static let navigateToHelpTab = Notification.Name("navigateToHelpTab")
    static let bringSettingsToFront = Notification.Name("bringSettingsToFront")
    static let openSettingsFromAppKit = Notification.Name("openSettingsFromAppKit")
    static let settingsWindowClosed = Notification.Name("settingsWindowClosed")
}

@main
struct NotimanagerApp: App {
    @NSApplicationDelegateAdaptor(NotificationMover.self) var appDelegate
    @StateObject private var store = AppStore.shared

    init() {
        #if !DEBUG
        // Check if another instance is already running
        if !Self.isSingleInstance() {
            NSLog("Notimanager is already running. Exiting this instance.")
            Foundation.exit(0)
        }
        #endif

        // Set activation policy to accessory to run as menu bar app without Dock icon
        NSApplication.shared.setActivationPolicy(.accessory)

        // Initialize AppKit menu bar (replaces SwiftUI MenuBarExtra)
        _ = AppKitMenuBarManager.shared
    }

    var body: some Scene {
        // Empty scene as we manage windows manually via AppKit to avoid Dock icon
        // Settings window is managed by SettingsWindowController
        Settings {
            EmptyView()
        }
        // Using an empty Settings scene keeps the "Preferences" menu item alive in standard menus
        // but we override it via standard actions. However, suppressing it completely might be better.
        // Actually, for a menu bar app with NSApplicationDelegateAdaptor, we don't strictly need a WindowGroup or Settings.
        // But removing 'Settings' scene might remove the "Preferences" menu item if we relied on SwiftUI to Generate it.
        // Since we are using "AppKitMenuBarManager" which builds the menu manually, we don't need this.
        
        // But SwiftUI App cycle requires at least one scene?
        // "The body of an App ... must return a Scene"
        // We can use a WindowGroup that we never open, or just an empty Settings.
        
        // Let's rely on standard implicit behavior or just return an Empty Scene
        // But 'EmptyScene' doesn't exist.
        // We will return a 'Settings' scene with EmptyView but we won't use it.
        Settings {
            EmptyView()
        }
    }

    /// Checks if this is the single instance of the app
    /// - Returns: true if this is the only instance, false otherwise
    private static func isSingleInstance() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? "dev.abd3lraouf.notimanager"

        // Check if the app is already running
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)

        // Filter out the current instance
        let otherInstances = runningApps.filter { app in
            app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }

        return otherInstances.isEmpty
    }
}




