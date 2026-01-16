//
//  ViewControllerProtocol.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Protocols for view controller communication and coordination
//

import Cocoa

/// Base protocol for all coordinators
protocol Coordinator: AnyObject {
    /// Associated view controller
    var viewController: NSViewController? { get }

    /// Start the coordinator
    func start()
}

/// Protocol for view controllers that need to communicate with settings
protocol SettingsDependent: AnyObject {
    /// Called when settings change
    func settingsDidChange(_ event: ConfigurationManager.ConfigurationEvent)
}

/// Protocol for view controllers that handle accessibility permissions
protocol PermissionHandling: AnyObject {
    /// Request accessibility permission
    func requestAccessibilityPermission()

    /// Reset accessibility permission
    func resetAccessibilityPermission()

    /// Check current permission status
    func checkPermissionStatus() -> Bool

    /// Callback when permission is granted
    var onPermissionGranted: (() -> Void)? { get set }

    /// Callback when permission is denied
    var onPermissionDenied: (() -> Void)? { get set }
}

/// Protocol for diagnostic view controllers
protocol DiagnosticsDisplay: AnyObject {
    /// Log a diagnostic message
    func log(_ message: String)

    /// Clear all diagnostic output
    func clearOutput()

    /// Update status indicator
    func updateStatus(_ status: String)
}

/// Protocol for menu bar interaction
protocol MenuBarInteractable: AnyObject {
    /// Show settings window
    func showSettings()

    /// Show diagnostics window
    func showDiagnostics()

    /// Show about window
    func showAbout()

    /// Show permission window
    func showPermissionWindow()
}

/// Protocol for test notification handling
protocol TestNotificationHandler: AnyObject {
    /// Send a test notification
    func sendTestNotification()

    /// Callback when test notification status changes
    var onTestStatusChanged: ((String) -> Void)? { get set }
}

/// Window management protocol
protocol WindowManager: AnyObject {
    /// Create and configure a window
    /// - Parameters:
    ///   - contentRect: The window frame
    ///   - styleMask: Window style mask
    ///   - backing: Backing store type
    ///   - defer: Flag to defer window creation
    /// - Returns: Configured NSWindow
    func createWindow(contentRect: NSRect, styleMask: NSWindow.StyleMask, backing: NSWindow.BackingStoreType, defer: Bool) -> NSWindow

    /// Show a window centered on screen
    /// - Parameter window: The window to show
    func showWindowCentered(_ window: NSWindow)

    /// Close a window and cleanup
    /// - Parameter window: The window to close
    func closeWindow(_ window: NSWindow)
}

// MARK: - Default Implementations

extension WindowManager {
    func showWindowCentered(_ window: NSWindow) {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeWindow(_ window: NSWindow) {
        window.close()
    }
}
