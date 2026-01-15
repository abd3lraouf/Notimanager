//
//  SettingsViewModel.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  ViewModel for settings screen - manages business logic and state
//

import Cocoa
import UserNotifications

/// ViewModel for SettingsViewController
class SettingsViewModel {

    // MARK: - Callbacks

    var onPositionChanged: ((NotificationPosition) -> Void)?
    var onEnabledChanged: ((Bool) -> Void)?
    var onTestStatusChanged: ((String) -> Void)?

    // MARK: - Properties (read-only for view)

    private(set) var currentPosition: NotificationPosition {
        didSet {
            onPositionChanged?(currentPosition)
        }
    }

    private(set) var isEnabled: Bool {
        didSet {
            onEnabledChanged?(isEnabled)
        }
    }

    private(set) var debugMode: Bool {
        didSet {
            ConfigurationManager.shared.debugMode = debugMode
        }
    }

    private(set) var isMenuBarIconHidden: Bool {
        didSet {
            ConfigurationManager.shared.isMenuBarIconHidden = isMenuBarIconHidden
        }
    }

    var isAccessibilityGranted: Bool {
        return AXIsProcessTrusted()
    }

    var isLaunchAtLoginEnabled: Bool {
        return FileManager.default.fileExists(atPath: launchAgentPlistPath)
    }

    private var launchAgentPlistPath: String {
        return ConfigurationManager.shared.launchAgentPlistPath
    }

    // MARK: - Test Notification State

    private var lastNotificationTime: Date?
    private(set) var notificationWasIntercepted: Bool = false

    // MARK: - Initialization

    init() {
        let config = ConfigurationManager.shared
        currentPosition = config.currentPosition
        isEnabled = config.isEnabled
        debugMode = config.debugMode
        isMenuBarIconHidden = config.isMenuBarIconHidden
    }

    // MARK: - Position Management

    func updatePosition(to position: NotificationPosition) {
        currentPosition = position
        ConfigurationManager.shared.currentPosition = position

        // Notify NotificationCenterMover to reposition notifications
        NotificationCenter.default.post(name: .notificationPositionChanged, object: position)
    }

    // MARK: - Enabled Toggle

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        ConfigurationManager.shared.isEnabled = enabled

        // Notify other components
        NotificationCenter.default.post(name: .notificationEnabledChanged, object: enabled)
    }

    // MARK: - Launch at Login

    func setLaunchAtLogin(_ enabled: Bool) {
        if enabled {
            enableLaunchAtLogin()
        } else {
            disableLaunchAtLogin()
        }
    }

    private func enableLaunchAtLogin() {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>dev.abd3lraouf.notimanager</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(Bundle.main.executablePath!)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """

        do {
            try plistContent.write(toFile: launchAgentPlistPath, atomically: true, encoding: .utf8)
            debugLog("Launch at login enabled")
        } catch {
            debugLog("Failed to enable launch at login: \(error)")
            showError("Failed to enable launch at login: \(error.localizedDescription)")
        }
    }

    private func disableLaunchAtLogin() {
        do {
            try FileManager.default.removeItem(atPath: launchAgentPlistPath)
            debugLog("Launch at login disabled")
        } catch {
            debugLog("Failed to disable launch at login: \(error)")
            showError("Failed to disable launch at login: \(error.localizedDescription)")
        }
    }

    // MARK: - Debug Mode

    func setDebugMode(_ enabled: Bool) {
        debugMode = enabled
        debugLog("Debug mode \(enabled ? "enabled" : "disabled")")
    }

    // MARK: - Menu Bar Icon

    func setMenuBarIconHidden(_ hidden: Bool) {
        isMenuBarIconHidden = hidden

        if hidden {
            // Show confirmation
            NotificationCenter.default.post(name: .showHideMenuBarIconConfirmation, object: nil)
        } else {
            NotificationCenter.default.post(name: .menuBarIconVisibilityChanged, object: false)
        }
    }

    // MARK: - Accessibility Permissions

    func requestAccessibilityPermission() {
        debugLog("User requested accessibility permission")

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)

        // Start polling for permission status
        startPermissionPolling()
    }

    func resetAccessibilityPermission() {
        debugLog("User requested to clear accessibility permissions")

        let alert = NSAlert()
        alert.messageText = "Clear Permission?"
        alert.informativeText = """
        This will clear Notimanager's accessibility permission.

        What happens next:
        • Accessibility permission will be reset
        • You'll need to grant permission again
        • The app will continue running

        This is useful for troubleshooting permission issues.
        """
        alert.alertStyle = .warning
        alert.icon = NSImage(systemSymbolName: "trash", accessibilityDescription: "Clear")
        alert.addButton(withTitle: "Clear Permission")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            debugLog("Clearing accessibility permissions...")

            let task = Process()
            task.launchPath = "/usr/bin/tccutil"
            task.arguments = ["reset", "Accessibility", "dev.abd3lraouf.notimanager"]

            do {
                try task.run()
                task.waitUntilExit()

                debugLog("Permission cleared successfully")

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let success = NSAlert()
                    success.messageText = "Permission Cleared"
                    success.informativeText = "Accessibility permission has been reset.\n\nYou can grant it again using the button below."
                    success.alertStyle = .informational
                    success.runModal()

                    // Start polling again
                    self.startPermissionPolling()
                }
            } catch {
                debugLog("Failed to clear permission: \(error)")
                showError("Failed to clear permission: \(error.localizedDescription)")
            }
        }
    }

    private func startPermissionPolling() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            let isGranted = self.isAccessibilityGranted

            if isGranted {
                timer.invalidate()
                debugLog("✓ Accessibility permission granted!")

                // Notify UI to update
                NotificationCenter.default.post(name: .accessibilityPermissionGranted, object: nil)
            } else {
                NotificationCenter.default.post(name: .accessibilityPermissionDenied, object: nil)
            }
        }
    }

    // MARK: - Test Notifications

    func sendTestNotification() {
        debugLog("Sending test notification...")

        updateTestStatus("Checking permissions...")

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self.performSendTestNotification()

                case .denied:
                    self.debugLog("Notification permission denied by user")
                    self.showNotificationPermissionDeniedAlert()

                case .notDetermined:
                    self.debugLog("Notification permission not determined, requesting...")
                    self.requestAndSendTestNotification()

                @unknown default:
                    self.debugLog("Unknown notification authorization status")
                    self.updateTestStatus("✗ Unknown permission status")
                }
            }
        }
    }

    private func performSendTestNotification() {
        // Reset tracking
        notificationWasIntercepted = false
        lastNotificationTime = Date()

        updateTestStatus("Sending test notification...")

        let content = UNMutableNotificationContent()
        content.title = "Notimanager Test"
        content.body = "If you see this at \(currentPosition.displayName), it's working! 🎯"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.debugLog("Failed to send test notification: \(error)")
                    self.updateTestStatus("✗ Failed to send")
                } else {
                    self.debugLog("Test notification sent successfully")
                    self.updateTestStatus("Waiting for notification...")

                    // Check after 5 seconds if it was intercepted
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                        self?.updateTestStatusResult()
                    }
                }
            }
        }
    }

    private func requestAndSendTestNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.debugLog("Error requesting notification permission: \(error)")
                    self.updateTestStatus("✗ Permission error")
                    return
                }

                if granted {
                    self.debugLog("Notification permission granted, sending test...")
                    self.performSendTestNotification()
                } else {
                    self.debugLog("User denied notification permission")
                    self.showNotificationPermissionDeniedAlert()
                }
            }
        }
    }

    private func showNotificationPermissionDeniedAlert() {
        updateTestStatus("✗ Permission denied")

        let alert = NSAlert()
        alert.messageText = "Notification Permission Denied"
        alert.informativeText = """
        Notimanager needs notification permission to send test notifications.

        To enable notifications:
        1. Open System Settings
        2. Go to Notifications
        3. Find Notimanager in the list
        4. Enable "Allow Notifications"
        """
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "bell.slash.fill", accessibilityDescription: "Notifications Disabled")
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func updateTestStatusResult() {
        if notificationWasIntercepted {
            updateTestStatus("✓ Intercepted & moved successfully!")
            debugLog("Test notification was successfully intercepted")
        } else {
            updateTestStatus("ℹ️ Try a real notification (Calendar, Mail, Messages)")
            debugLog("Test notification was NOT intercepted - may be in Notification Center panel")
        }
    }

    private func updateTestStatus(_ status: String) {
        onTestStatusChanged?(status)
    }

    // MARK: - App Restart

    func restartApp() {
        debugLog("Restarting app...")

        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", "-a", Bundle.main.bundlePath]

        do {
            try task.run()
            debugLog("New instance launched, waiting before quit...")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.debugLog("Terminating current instance...")
                NSApplication.shared.terminate(nil)
            }
        } catch {
            debugLog("Failed to relaunch: \(error)")
            showError("Failed to restart app: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func debugLog(_ message: String) {
        LoggingService.shared.debug(message)
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.runModal()
    }
}

// MARK: - Notification.Name Extensions

extension Notification.Name {
    static let notificationPositionChanged = Notification.Name("notificationPositionChanged")
    static let notificationEnabledChanged = Notification.Name("notificationEnabledChanged")
    static let accessibilityPermissionGranted = Notification.Name("accessibilityPermissionGranted")
    static let accessibilityPermissionDenied = Notification.Name("accessibilityPermissionDenied")
    static let menuBarIconVisibilityChanged = Notification.Name("menuBarIconVisibilityChanged")
    static let showHideMenuBarIconConfirmation = Notification.Name("showHideMenuBarIconConfirmation")
}
