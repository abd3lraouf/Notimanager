//
//  NotimanagerApp.swift
//  Notimanager
//
//  Created on 2025-11-16.
//

import Cocoa

@main
struct NotimanagerApp {
    // Keep delegate alive for the lifetime of the app
    private static let delegate = NotificationMover()

    static func main() {
        // Initialize NSApplication first before checking single instance
        let app = NSApplication.shared
        app.delegate = delegate

        // Set activation policy to accessory to run as menu bar app without Dock icon
        // This must be set BEFORE app.run() to take effect
        app.setActivationPolicy(.accessory)

        // Check if another instance is already running
        if !isSingleInstance() {
            NSLog("Notimanager is already running. Exiting this instance.")
            // Use exit instead of terminate to avoid any potential NSApp issues
            Foundation.exit(0)
        }

        app.run()
    }

    /// Checks if this is the single instance of the app
    /// - Returns: true if this is the only instance, false otherwise
    private static func isSingleInstance() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? "dev.abd3lraouf.notimanager"

        // Check if the app is already running using NSRunningApplication
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)

        // Filter out the current instance
        let otherInstances = runningApps.filter { app in
            app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }

        return otherInstances.isEmpty
    }
}
