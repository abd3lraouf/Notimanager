//
//  LoggingService.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Centralized logging service for debug and diagnostic output
//

import AppKit
import os.log

/// Centralized logging service that handles both debug logging and diagnostic window output
@available(macOS 10.15, *)
class LoggingService {

    // MARK: - Singleton

    static let shared = LoggingService()

    private init() {}

    // MARK: - Properties

    private let logger = Logger(subsystem: "dev.abd3lraouf.notimanager", category: "NotificationMover")

    /// Diagnostic text view for output logging (optional, set via setter)
    private weak var diagnosticTextView: NSTextView?

    /// Whether debug mode is enabled
    var isDebugModeEnabled: Bool = false

    // MARK: - Debug Logging

    /// Logs a debug message if debug mode is enabled
    /// - Parameter message: The message to log
    func debug(_ message: String) {
        guard isDebugModeEnabled else { return }
        logger.info("\(message, privacy: .public)")
    }

    /// Logs a debug message regardless of debug mode setting
    /// - Parameter message: The message to log
    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    /// Logs an error message
    /// - Parameter message: The error message to log
    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    /// Logs a warning message
    /// - Parameter message: The warning message to log
    func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    // MARK: - Diagnostic Logging

    /// Sets the diagnostic text view for output
    /// - Parameter textView: The text view to receive diagnostic output
    func setDiagnosticTextView(_ textView: NSTextView?) {
        diagnosticTextView = textView
    }

    /// Logs a message to the diagnostic window
    /// - Parameter message: The message to log
    func diagnostic(_ message: String) {
        guard let textView = diagnosticTextView else { return }
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] \(message)\n"

        DispatchQueue.main.async {
            textView.string += line
            textView.scrollToEndOfDocument(nil)
        }
    }

    /// Clears the diagnostic window output
    func clearDiagnosticOutput() {
        guard let textView = diagnosticTextView else { return }
        DispatchQueue.main.async {
            textView.string = ""
        }
    }

    // MARK: - System Information Logging

    /// Logs comprehensive system information
    /// - Parameters:
    ///   - osVersion: The operating system version
    ///   - notificationSubroles: Active notification subroles
    ///   - currentPosition: Current notification position setting
    func logSystemInfo(
        osVersion: OperatingSystemVersion,
        notificationSubroles: [String],
        currentPosition: NotificationPosition
    ) {
        debug("=== SYSTEM INFORMATION ===")
        debug("macOS Version: \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")

        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            debug("Notimanager Version: \(appVersion)")
        }

        if let bundleID = Bundle.main.bundleIdentifier {
            debug("Bundle ID: \(bundleID)")
        }

        debug("Current Position: \(currentPosition.displayName)")
        debug("Debug Mode: \(isDebugModeEnabled ? "ON" : "OFF")")

        if osVersion.majorVersion >= 26 {
            debug("macOS 26+ Mode: ENABLED - Using expanded notification subroles")
        }

        debug("Active Notification Subroles: \(notificationSubroles.joined(separator: ", "))")
    }
}

// MARK: - Convenience Aliases

extension LoggingService {
    /// Alias for debug logging - maintains compatibility with existing code
    func debugLog(_ message: String) {
        debug(message)
    }

    /// Alias for diagnostic logging - maintains compatibility with existing code
    func diagnosticLog(_ message: String) {
        diagnostic(message)
    }

    /// Generic log function - compatible with existing code calling .log()
    func log(_ message: String) {
        info(message)
    }
}
