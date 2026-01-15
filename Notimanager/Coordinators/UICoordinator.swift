//
//  UICoordinator.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Central coordinator for managing all view controllers and windows
//

import Cocoa

/// Central coordinator for managing app UI
class UICoordinator: NSObject {

    // MARK: - Singleton

    static let shared = UICoordinator()

    private override init() {
        super.init()
        setupNotificationObservers()
    }

    // MARK: - Properties

    private var settingsViewController: SettingsViewController?
    private var permissionViewController: PermissionViewController?
    private var diagnosticViewController: DiagnosticViewController?
    private var aboutViewController: AboutViewController?

    // MARK: - Public Methods

    /// Show the settings window
    func showSettings() {
        if settingsViewController == nil {
            let viewModel = SettingsViewModel()
            settingsViewController = SettingsViewController(viewModel: viewModel)
        }

        settingsViewController?.showInWindow()
    }

    /// Show the permission window
    func showPermissionWindow() {
        if permissionViewController == nil {
            let viewModel = PermissionViewModel()
            permissionViewController = PermissionViewController(viewModel: viewModel)
        }

        permissionViewController?.showInWindow()
    }

    /// Show the diagnostic window
    func showDiagnostics() {
        if diagnosticViewController == nil {
            let viewModel = DiagnosticViewModel()
            diagnosticViewController = DiagnosticViewController(viewModel: viewModel)
        }

        diagnosticViewController?.showInWindow()
    }

    /// Show the about window
    func showAbout() {
        if aboutViewController == nil {
            let viewModel = AboutViewModel()
            aboutViewController = AboutViewController(viewModel: viewModel)
        }

        aboutViewController?.showInWindow()
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
        // Note: ViewControllers manage their own windows lifecycle
        settingsViewController = nil
        permissionViewController = nil
        diagnosticViewController = nil
        aboutViewController = nil
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
            // Notify settings view model to proceed
            NotificationCenter.default.post(name: .confirmHideMenuBarIcon, object: nil)
        } else {
            // Notify settings view model to cancel
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

// MARK: - Notification.Name Extensions

extension Notification.Name {
    static let repositionAllNotifications = Notification.Name("repositionAllNotifications")
    static let confirmHideMenuBarIcon = Notification.Name("confirmHideMenuBarIcon")
    static let cancelHideMenuBarIcon = Notification.Name("cancelHideMenuBarIcon")
}
