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

    /// Shows the diagnostics window
    func showDiagnostics()

    // MARK: - Menu Actions

    /// Shows the settings window
    func showSettings()

    /// Toggles notification positioning on/off
    func toggleEnabled()

    /// Sends a test notification
    func sendTestNotification()

    /// Quits the application
    func quit()

    // MARK: - Configuration Properties

    /// Current notification position
    var currentPosition: NotificationPosition { get }

    /// Whether notification positioning is enabled
    var isEnabled: Bool { get set }

    /// Whether debug mode is enabled
    var debugMode: Bool { get set }

    /// Whether the menu bar icon is hidden
    var isMenuBarIconHidden: Bool { get set }
}


// MARK: - Support Links

extension CoordinatorAction {

    /// Opens the GitHub repository
    func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/abd3lraouf/Notimanager")!)
    }

    /// Opens the GitHub issues page
    func openIssues() {
        NSWorkspace.shared.open(URL(string: "https://github.com/abd3lraouf/Notimanager/issues")!)
    }
}
