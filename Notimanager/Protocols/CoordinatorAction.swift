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
        isEnabled = (checkbox.state == .on)
    }

    /// Handles launch at login checkbox toggle
    /// - Parameter checkbox: The checkbox that was toggled
    func toggleLaunchFromSettings(_ checkbox: NSButton) {
        // Implementation depends on LaunchAgentManager
    }

    /// Handles debug mode checkbox toggle
    /// - Parameter checkbox: The checkbox that was toggled
    func toggleDebugFromSettings(_ checkbox: NSButton) {
        debugMode = (checkbox.state == .on)
    }

    /// Handles hide icon checkbox toggle
    /// - Parameter checkbox: The checkbox that was toggled
    func toggleHideIconFromSettings(_ checkbox: NSButton) {
        isMenuBarIconHidden = (checkbox.state == .on)
    }
}

// MARK: - Support Links

extension CoordinatorAction {

    /// Opens the Ko-fi support page
    func openKofi()

    /// Opens the Buy Me a Coffee support page
    func openBuyMeACoffee()
}
