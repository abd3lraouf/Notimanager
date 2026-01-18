//
//  LoggingService.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Centralized logging service for debug and diagnostic output
//

import AppKit
import os.log

/// Centralized logging service that handles both debug logging, file logging, and diagnostic window output
@available(macOS 10.15, *)
class LoggingService {

    // MARK: - Singleton

    static let shared = LoggingService()

    private init() {
        // Initialize the FileLogger
        FileLogger.shared.initialize()
    }

    // MARK: - Properties

    private let logger = Logger(subsystem: "dev.abd3lraouf.notimanager", category: "NotificationMover")

    /// Diagnostic text view for output logging (optional, set via setter)
    private weak var diagnosticTextView: NSTextView?

    /// Whether debug mode is enabled
    var isDebugModeEnabled: Bool = false

    /// Whether file logging is enabled
    var isFileLoggingEnabled: Bool = false {
        didSet {
            Task { @MainActor in
                await FileLogger.shared.log(
                    level: .info,
                    message: "File logging \(isFileLoggingEnabled ? "enabled" : "disabled")",
                    category: "LoggingService"
                )
            }
        }
    }

    // MARK: - Debug Logging

    /// Logs a debug message if debug mode is enabled
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category for better organization (default: "General")
    func debug(_ message: String, category: String = "General") {
        guard isDebugModeEnabled else { return }
        logger.info("\(message, privacy: .public)")

        if isFileLoggingEnabled {
            Task { @MainActor in
                await FileLogger.shared.log(level: .debug, message: message, category: category)
            }
        }
    }

    /// Logs a debug message regardless of debug mode setting
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category for better organization (default: "General")
    func info(_ message: String, category: String = "General") {
        logger.info("\(message, privacy: .public)")

        if isFileLoggingEnabled {
            Task { @MainActor in
                await FileLogger.shared.log(level: .info, message: message, category: category)
            }
        }
    }

    /// Logs an error message
    /// - Parameters:
    ///   - message: The error message to log
    ///   - category: Optional category for better organization (default: "General")
    func error(_ message: String, category: String = "General") {
        logger.error("\(message, privacy: .public)")

        if isFileLoggingEnabled {
            Task { @MainActor in
                await FileLogger.shared.log(level: .error, message: message, category: category)
            }
        }
    }

    /// Logs a warning message
    /// - Parameters:
    ///   - message: The warning message to log
    ///   - category: Optional category for better organization (default: "General")
    func warning(_ message: String, category: String = "General") {
        logger.warning("\(message, privacy: .public)")

        if isFileLoggingEnabled {
            Task { @MainActor in
                await FileLogger.shared.log(level: .warning, message: message, category: category)
            }
        }
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

    // MARK: - File Logging Management

    /// Opens the logs directory in Finder
    func openLogsDirectory() {
        Task { @MainActor in
            let logsDir = await FileLogger.shared.getLogsDirectory()
            NSWorkspace.shared.activateFileViewerSelecting([logsDir])
        }
    }

    /// Returns an array of all log files with their sizes
    func getLogFilesInfo() async -> [(name: String, size: String, url: URL)] {
        let files = await FileLogger.shared.getLogFiles()
        var fileInfo: [(name: String, size: String, url: URL)] = []

        for file in files {
            let name = file.lastPathComponent
            let sizeBytes = getFileSize(at: file)
            let sizeFormatted = formatFileSize(sizeBytes)
            fileInfo.append((name: name, size: sizeFormatted, url: file))
        }

        return fileInfo.sorted { $0.name > $1.name }
    }

    /// Returns the current log file size formatted as string
    func getCurrentLogFileSize() async -> String {
        let sizeBytes = await FileLogger.shared.getCurrentLogFileSize()
        return formatFileSize(sizeBytes)
    }

    /// Clears all log files
    func clearAllLogs() {
        Task { @MainActor in
            await FileLogger.shared.clearAllLogs()
        }
    }

    private func getFileSize(at url: URL) -> UInt64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? UInt64 ?? 0
        } catch {
            return 0
        }
    }

    private func formatFileSize(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
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
