//
//  UICoordinator.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Central coordinator for managing all view controllers and windows.
//  Updated to use SwiftUI views with robust lifecycle management.
//

import Cocoa
import SwiftUI

/// Central coordinator for managing app UI
class UICoordinator: NSObject {

    // MARK: - Singleton

    static let shared = UICoordinator()

    private override init() {
        super.init()
        setupNotificationObservers()
    }

    // MARK: - Properties

    private var permissionWindow: NSWindow?
    private var diagnosticWindow: NSWindow?
    private var logViewerWindow: NSWindow?

    // MARK: - Public Methods

    /// Show the settings window (now handled by NotificationMoverCoordinator using Settings framework)
    func showSettings() {
        // Delegate to NotificationMoverCoordinator which has the Settings framework integration
        // Use the shared coordinator to avoid recreating everything
        NotificationMover.shared.showSettings()
    }

    /// Show the permission window using SwiftUI
    func showPermissionWindow() {
        if permissionWindow == nil {
            let viewModel = PermissionViewModel()
            let contentView = PermissionView(viewModel: viewModel)

            let hostingController = NSHostingController(rootView: contentView)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 620),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Notimanager"
            window.titlebarAppearsTransparent = false
            window.isMovableByWindowBackground = true
            window.contentViewController = hostingController
            window.delegate = self
            window.isReleasedWhenClosed = false // Important: we manage lifecycle manually

            permissionWindow = window
        }

        permissionWindow?.center()
        permissionWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Show the diagnostic window using SwiftUI
    func showDiagnostics() {
        if diagnosticWindow == nil {
            let viewModel = DiagnosticViewModel()
            let contentView = DiagnosticView(viewModel: viewModel)

            let hostingController = NSHostingController(rootView: contentView)

            let osVersion = ProcessInfo.processInfo.operatingSystemVersion

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 750),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "API Diagnostics - macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
            window.contentViewController = hostingController
            window.delegate = self
            window.isReleasedWhenClosed = false // Important: we manage lifecycle manually

            diagnosticWindow = window
        }

        diagnosticWindow?.center()
        diagnosticWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Show the log viewer window using SwiftUI
    func showLogViewer() {
        if logViewerWindow == nil {
            let contentView = LogViewerView()
            let hostingController = NSHostingController(rootView: contentView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Log Viewer"
            window.contentViewController = hostingController
            window.delegate = self
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 700, height: 400)
            
            logViewerWindow = window
        }
        
        logViewerWindow?.center()
        logViewerWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Show the permission window (called from coordinator)
    func showPermissionWindowFromCoordinator() {
        showPermissionWindow()
    }

    /// Check if accessibility permission is granted and show window if needed
    func checkAccessibilityPermission() {
        let isCurrentlyTrusted = AXIsProcessTrusted()

        if isCurrentlyTrusted {
            debugLog("✓ Accessibility permissions already granted")
        } else {
            debugLog("⚠️  Accessibility permissions not granted - showing status window")
            showPermissionWindow()
        }
    }

    /// Close all windows
    func closeAllWindows() {
        permissionWindow?.close()
        permissionWindow?.close()
        diagnosticWindow?.close()
        logViewerWindow?.close()
        // References cleared in windowWillClose delegate
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotificationPositionChanged),
            name: .notificationPositionChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotificationEnabledChanged),
            name: .notificationEnabledChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHideMenuBarIconConfirmation),
            name: .showHideMenuBarIconConfirmation,
            object: nil
        )
    }

    @objc private func handleNotificationPositionChanged(_ notification: Notification) {
        guard let position = notification.object as? NotificationPosition else { return }
        debugLog("Position changed via UI coordinator: \(position.displayName)")

        // Trigger notification repositioning
        NotificationCenter.default.post(name: .repositionAllNotifications, object: position)
    }

    @objc private func handleNotificationEnabledChanged(_ notification: Notification) {
        guard let enabled = notification.object as? Bool else { return }
        debugLog("Notification positioning \(enabled ? "enabled" : "disabled") via UI coordinator")
    }

    @objc private func handleHideMenuBarIconConfirmation() {
        let alert = NSAlert()
        alert.messageText = "Hide Menu Bar Icon"
        alert.informativeText = "The menu bar icon will be hidden. To show it again, launch Notimanager from Applications."
        alert.addButton(withTitle: "Hide Icon")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            // Notify to proceed
            NotificationCenter.default.post(name: .confirmHideMenuBarIcon, object: nil)
        } else {
            // Notify to cancel
            NotificationCenter.default.post(name: .cancelHideMenuBarIcon, object: nil)
        }
    }

    // MARK: - Helpers

    private func debugLog(_ message: String) {
        LoggingService.shared.debug(message)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - NSWindowDelegate

extension UICoordinator: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // For permission window, if permission is NOT granted, hide instead of close
        if sender === permissionWindow {
            if !AXIsProcessTrusted() {
                sender.orderOut(nil)
                return false
            }
        }
        
        return true
    }
    
    func windowWillClose(_ notification: Notification) {
        // Clean up window references AFTER close animation completes
        // CRITICAL: Use async to prevent deallocating window while it is still in the middle of closing
        // This avoids EXC_BAD_ACCESS in autorelease pool drain
        guard let window = notification.object as? NSWindow else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if window === self.permissionWindow {
                self.permissionWindow = nil
            } else if window === self.diagnosticWindow {
                self.diagnosticWindow = nil
            } else if window === self.logViewerWindow {
                self.logViewerWindow = nil
            }
        }
    }
}

// MARK: - Notification.Name Extensions

extension Notification.Name {
    static let repositionAllNotifications = Notification.Name("repositionAllNotifications")
    static let confirmHideMenuBarIcon = Notification.Name("confirmHideMenuBarIcon")
    static let cancelHideMenuBarIcon = Notification.Name("cancelHideMenuBarIcon")
    static let notificationPositionChanged = Notification.Name("notificationPositionChanged")
    static let notificationEnabledChanged = Notification.Name("notificationEnabledChanged")
    static let showHideMenuBarIconConfirmation = Notification.Name("showHideMenuBarIconConfirmation")
}
