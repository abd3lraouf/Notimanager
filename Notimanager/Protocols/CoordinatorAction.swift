//
//  CoordinatorAction.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Protocol for actions that the NotificationMoverCoordinator can perform.
//  Used by views (PermissionWindow, SettingsWindow) and MenuBarManager.
//

import AppKit
import Foundation

/// Protocol for actions that the coordinator can perform
@available(macOS 10.15, *)
protocol CoordinatorAction: AnyObject {

    // MARK: - Permission Actions

    /// Requests accessibility permissions from the user
    func requestAccessibilityPermission()

    /// Resets accessibility permissions (for testing/troubleshooting)
    func resetAccessibilityPermission()

    /// Restarts the application
    func restartApp()

    // MARK: - Settings Actions

    /// Updates the notification position
    /// - Parameter position: The new position
    func updatePosition(to position: NotificationPosition)

    /// Shows the permission window from settings
    func showPermissionWindowFromSettings()

    // MARK: - Menu Actions

    /// Shows the settings window
    func showSettings()

    /// Toggles notification positioning on/off
    func toggleEnabled()

    /// Toggles launch at login
    func toggleLaunchAtLogin()

    /// Sends a test notification
    func sendTestNotification()

    /// Quits the application
    func quit()

    // MARK: - Configuration Properties

    /// Current notification position
    var currentPosition: NotificationPosition { get }

    /// Whether notification positioning is enabled
    var isEnabled: Bool { get }

    /// Whether debug mode is enabled
    var debugMode: Bool { get }

    /// Whether the menu bar icon is hidden
    var isMenuBarIconHidden: Bool { get }

    /// Path to the launch agent plist file
    var launchAgentPlistPath: String { get }
}

// MARK: - Checkbox Actions (for Settings Window)

extension CoordinatorAction {

    /// Handles enabled checkbox toggle
    /// - Parameter checkbox: The checkbox that was toggled
    func toggleEnabledFromSettings(_ checkbox: NSButton) {
        toggleEnabled()
        // Update checkbox state to match
        checkbox.state = isEnabled ? .on : .off
    }

    /// Handles launch at login checkbox toggle
    /// - Parameter checkbox: The checkbox that was toggled
    func toggleLaunchFromSettings(_ checkbox: NSButton) {
        toggleLaunchAtLogin()
        // Update checkbox state to match
        // Note: This needs access to launch agent state
    }

    /// Handles debug mode checkbox toggle
    /// - Parameter checkbox: The checkbox that was toggled
    func toggleDebugFromSettings(_ checkbox: NSButton) {
        // Debug mode is set via ConfigurationManager
        // This is a no-op here, handled in SettingsViewModel
    }

    /// Handles hide icon checkbox toggle
    /// - Parameter checkbox: The checkbox that was toggled
    func toggleHideIconFromSettings(_ checkbox: NSButton) {
        // Menu bar icon is set via ConfigurationManager
        // This is a no-op here, handled in SettingsViewModel
    }
}

// MARK: - Support Links

extension CoordinatorAction {

    /// Opens the Ko-fi support page
    func openKofi() {
        NSWorkspace.shared.open(URL(string: "https://ko-fi.com/wadegrimridge")!)
    }

    /// Opens the Buy Me a Coffee support page
    func openBuyMeACoffee() {
        NSWorkspace.shared.open(URL(string: "https://www.buymeacoffee.com/wadegrimridge")!)
    }
}
