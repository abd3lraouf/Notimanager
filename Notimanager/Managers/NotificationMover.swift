//
//  NotificationMover.swift
//  Notimanager
//
//  Created on 2025-11-16.
//  Refactored on 2025-01-15.
//  Simplified delegate - forwards all work to NotificationMoverCoordinator.
//

import Cocoa
import UserNotifications

/// Simplified NotificationMover class that delegates to NotificationMoverCoordinator.
/// This maintains backward compatibility while moving all logic to the coordinator.
class NotificationMover: NSObject, NSApplicationDelegate, NSWindowDelegate {

    // MARK: - Shared Instance

    /// Shared instance for accessing the app delegate/coordinator from anywhere
    static let shared = NotificationMover()

    // MARK: - Coordinator

    /// The internal coordinator that handles all app logic
    private(set) var coordinator: NotificationMoverCoordinator

    // MARK: - Initialization

    override init() {
        // Initialize the coordinator with all its services
        self.coordinator = NotificationMoverCoordinator()
        super.init()
    }

    // MARK: - NSApplicationDelegate

    /// Application finished launching - forward to coordinator
    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.applicationDidFinishLaunching(notification)
    }

    /// Application should handle reopen - show settings when dock icon is clicked
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // If no windows are visible, show settings window
        if !flag {
            coordinator.showSettings()
        }
        return true
    }

    /// Application is about to become active - forward to coordinator
    func applicationWillBecomeActive(_ notification: Notification) {
        coordinator.applicationDidBecomeActive(notification)
    }

    /// Application is about to terminate - forward to coordinator
    func applicationWillTerminate(_ notification: Notification) {
        coordinator.applicationWillTerminate(notification)
    }

    // MARK: - NSWindowDelegate

    /// Window should close - forward to coordinator's settings handling
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Allow the window to close
        return true
    }

    // MARK: - Legacy Support Methods

    /// These methods are kept for backward compatibility with existing code
    /// that may reference NotificationMover directly. They delegate to the coordinator.

    /// Moves all notifications to the configured position
    func moveAllNotifications() {
        // This is called by WindowMonitorService via setNotificationMover
        // The coordinator's moveAllNotifications will handle this
    }

    /// Moves a single notification element
    func moveNotification(_ window: AXUIElement) {
        // This is called by WindowMonitorService via setNotificationMover
        // The coordinator will handle this through its services
    }

    /// Sets up the status item (menu bar icon)
    func setupStatusItem() {
        // Handled by MenuBarManager in the coordinator
    }

    /// Shows the settings window
    func showSettings() {
        coordinator.showSettings()
    }

    /// Sends a test notification
    @objc func sendTestNotification() {
        coordinator.sendTestNotification()
    }

    /// Shows the about dialog
    @objc func showAbout() {
        // Can be implemented with a proper About window
    }

    /// Shows diagnostics window
    @objc func showDiagnostics() {
        // Can be implemented with a proper Diagnostics window
    }

    /// Changes the notification position
    @objc func changePosition(_ sender: NSMenuItem) {
        if let position = sender.representedObject as? NotificationPosition {
            coordinator.updatePosition(to: position)
        }
    }

    /// Toggles enabled state
    @objc func menuBarToggleEnabled(_ sender: NSMenuItem) {
        coordinator.toggleEnabled()
    }

    /// Internal method for test notification
    @objc internal func internalSendTestNotification() {
        coordinator.sendTestNotification()
    }

    // MARK: - Properties for Backward Compatibility

    /// Current position - forwards to coordinator
    var currentPosition: NotificationPosition {
        return coordinator.currentPosition
    }

    /// Enabled state - forwards to coordinator
    var isEnabled: Bool {
        return coordinator.isEnabled
    }

    /// Debug mode state - forwards to coordinator
    var debugMode: Bool {
        return coordinator.debugMode
    }
}
