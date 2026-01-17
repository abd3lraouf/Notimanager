//
//  AppRestart.swift
//  Notimanager
//
//  Industry-standard macOS app restart utility
//  Uses POSIX spawn for reliable app relaunching
//

import AppKit
import Foundation

/// Utility class for handling application restart in a robust, industry-standard way
/// Based on practices from Sparkle, Alfred, and other production macOS apps
@available(macOS 10.15, *)
class AppRestart {

    // MARK: - Public API

    /// Restarts the application with a delay
    /// - Parameter delay: Delay before termination in seconds (default: 0.5)
    /// - Note: Launches new instance immediately, waits before terminating current one
    class func restart(delay: TimeInterval = 0.5) {
        LoggingService.shared.log("AppRestart: Initiating application restart")

        guard let bundleURL = getAppBundleURL() else {
            LoggingService.shared.logError("AppRestart: Failed to get bundle URL")
            showErrorAndExit(message: "Could not locate application bundle.")
            return
        }

        // Validate bundle URL points to an .app bundle
        guard bundleURL.pathExtension == "app" else {
            LoggingService.shared.logError("AppRestart: Bundle URL is not an .app bundle: \(bundleURL.path)")
            showErrorAndExit(message: "Invalid application bundle location.")
            return
        }

        LoggingService.shared.logDebug("AppRestart: Bundle URL: \(bundleURL.path)")

        // Launch new instance using POSIX spawn
        let success = spawnNewInstance(at: bundleURL)

        if !success {
            LoggingService.shared.logError("AppRestart: Failed to spawn new instance")
        }

        // Terminate current instance after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            terminateCurrentInstance()
        }
    }

    // MARK: - Private Methods

    /// Spawns a new instance of application using POSIX spawn
    /// - Parameter bundleURL: URL pointing to .app bundle
    /// - Returns: True if spawn was successful
    private class func spawnNewInstance(at bundleURL: URL) -> Bool {
        // Use /usr/bin/open which is an industry-standard way to launch apps
        // -n: Open a new instance even if one is already running
        // -a: Specifies the application to open (use bundle path)

        let task = Process()
        task.launchPath = "/usr/bin/open"

        // Build arguments - use -a with bundle path for reliable launching
        var arguments = [
            "-n",              // New instance
            "-a",              // Application
            bundleURL.path
        ]

        task.arguments = arguments

        LoggingService.shared.logDebug("AppRestart: Launching with command: /usr/bin/open \(arguments.joined(separator: " "))")

        do {
            try task.run()
            task.waitUntilExit()

            let status = task.terminationStatus
            if status == 0 {
                LoggingService.shared.log("AppRestart: Successfully launched new instance")
                return true
            } else {
                LoggingService.shared.logError("AppRestart: open command failed with exit code \(status)")
                return false
            }
        } catch {
            LoggingService.shared.logError("AppRestart: Failed to run open command: \(error.localizedDescription)")
            return false
        }
    }

    /// Terminates current application instance
    private class func terminateCurrentInstance() {
        LoggingService.shared.log("AppRestart: Terminating current instance")

        // Save any unsaved data
        // (Add your save logic here if needed)

        // Stop all services gracefully
        NotificationMover.shared.coordinator.applicationWillTerminate(Notification(name: NSApplication.willTerminateNotification))

        // Terminate app
        NSApplication.shared.terminate(nil)
    }

    /// Shows an error alert and exits app
    private class func showErrorAndExit(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Restart Failed", comment: "Alert title")
            alert.informativeText = message
            alert.alertStyle = .critical
            alert.addButton(withTitle: NSLocalizedString("OK", comment: "Button label"))
            alert.runModal()

            // Still exit even if restart failed
            NSApplication.shared.terminate(nil)
        }
    }

    /// Gets the URL of the current application bundle
    /// Handles both development and production builds correctly
    /// - Returns: URL to .app bundle, or nil if not found
    private class func getAppBundleURL() -> URL? {
        // Method 1: Try Bundle.main.bundlePath (works for production apps)
        let bundlePath = Bundle.main.bundlePath

        // If we're not already in an .app bundle, traverse up to find it
        var currentURL = URL(fileURLWithPath: bundlePath)

        // Check if we're already at the .app bundle level
        if currentURL.pathExtension == "app" {
            // Verify it's a valid app by checking for executable
            let executablePath = currentURL.appendingPathComponent("Contents/MacOS/\(Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? "Notimanager")")
            if FileManager.default.fileExists(atPath: executablePath.path) {
                return currentURL
            }
        }

        // Traverse up the directory tree to find the .app bundle
        // This handles development builds where bundlePath points inside the .app
        for _ in 0..<10 { // Limit depth to avoid infinite loops
            currentURL.deleteLastPathComponent()

            if currentURL.pathExtension == "app" {
                // Verify this is a valid app bundle
                let executablePath = currentURL.appendingPathComponent("Contents/MacOS/\(Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? "Notimanager")")
                if FileManager.default.fileExists(atPath: executablePath.path) {
                    LoggingService.shared.logDebug("AppRestart: Found app bundle at: \(currentURL.path)")
                    return currentURL
                }
            }

            if currentURL.path == "/" {
                break
            }
        }

        LoggingService.shared.logError("AppRestart: Could not locate .app bundle from: \(bundlePath)")
        return nil
    }
}

// MARK: - Logging Service Extension

private extension LoggingService {
    /// Logs an error message
    func logError(_ message: String) {
        log("[ERROR] \(message)")
    }

    /// Logs a debug message
    func logDebug(_ message: String) {
        log("[DEBUG] \(message)")
    }
}
