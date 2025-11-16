//
//  PermissionViewModel.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  ViewModel for permission screen - manages accessibility permission state
//

import Cocoa

/// ViewModel for PermissionViewController
class PermissionViewModel {

    // MARK: - Callbacks

    var onPermissionStatusChanged: ((Bool) -> Void)?
    var onPermissionRequested: (() -> Void)?

    // MARK: - Properties

    var isAccessibilityGranted: Bool {
        return AXIsProcessTrusted()
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Permission Management

    func requestAccessibilityPermission() {
        debugLog("User requested accessibility permission")

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)

        onPermissionRequested?()
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

            // Run tccutil to reset permissions
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

                    // Update permission status
                    self.updatePermissionStatus(granted: false)
                }
            } catch {
                debugLog("Failed to clear permission: \(error)")
                self.showError("Failed to clear permission: \(error.localizedDescription)")
            }
        }
    }

    func updatePermissionStatus(granted: Bool) {
        onPermissionStatusChanged?(granted)
    }

    func restartApp() {
        debugLog("Restarting app...")

        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", "-a", Bundle.main.bundlePath]

        do {
            try task.run()
            debugLog("New instance launched, waiting before quit...")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.debugLog("Terminating current instance...")
                NSApplication.shared.terminate(nil)
            }
        } catch {
            debugLog("Failed to relaunch: \(error)")
            showError("Failed to restart app: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func debugLog(_ message: String) {
        LoggingService.shared.log(message, category: "PermissionViewModel")
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.runModal()
    }
}
