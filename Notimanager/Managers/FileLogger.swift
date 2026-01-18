//
//  FileLogger.swift
//  Notimanager
//
//  Created on 2025-01-17.
//  File-based logging with automatic rotation (5MB max total folder size)
//

import Foundation
import os.log

/// File-based logger with automatic rotation
/// Format: notimanager.log.00001.log, notimanager.log.00002.log, etc.
/// Total folder size capped at 5MB
actor FileLogger {
    // MARK: - Constants

    private static let maxTotalFolderSize: UInt64 = 5 * 1024 * 1024 // 5MB
    private static let maxFileSize: UInt64 = 512 * 1024 // 512KB per file (rotate after this)
    private static let logFileName = "notimanager.log"

    // MARK: - Properties

    private let logsDirectory: URL
    private let dateFormatter: DateFormatter
    private var isInitialized = false

    // Log level tracking
    private var logLevelCounts: [LogLevel: Int] = [.debug: 0, .info: 0, .warning: 0, .error: 0]

    // MARK: - Singleton

    static let shared = FileLogger()

    // MARK: - Initialization

    private init() {
        // Get logs directory in Application Support
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "dev.abd3lraouf.notimanager"
        self.logsDirectory = appSupportURL.appendingPathComponent(bundleID).appendingPathComponent("Logs")

        // Setup date formatter for log entries
        self.dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        // Initialize synchronously
        self.isInitialized = true
    }

    /// Initialize the logger (call this after accessing shared instance)
    nonisolated func initialize() {
        Task {
            await createLogsDirectoryIfNeeded()
            await enforceFolderSizeLimit()
            await writeLog("=== FileLogger initialized ===")

            // Get logsDirectory path for logging
            let dir = await logsDirectory
            await writeLog("Logs directory: \(dir.path)")
        }
    }

    // MARK: - Directory Management

    private func createLogsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: logsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
                print("Created logs directory: \(logsDirectory.path)")
            } catch {
                print("Error creating logs directory: \(error)")
            }
        }
    }

    // MARK: - Public API

    /// Returns the logs directory URL
    func getLogsDirectory() -> URL {
        return logsDirectory
    }

    /// Returns an array of all log files in the logs directory, sorted by index
    func getLogFiles() -> [URL] {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: logsDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                options: .skipsHiddenFiles
            )
            return files.filter { $0.lastPathComponent.hasPrefix("notimanager.log") }
                .sorted { lhs, rhs in
                    let lhsIndex = extractLogIndex(from: lhs.lastPathComponent)
                    let rhsIndex = extractLogIndex(from: rhs.lastPathComponent)
                    return lhsIndex < rhsIndex
                }
        } catch {
            return []
        }
    }

    /// Returns the total size of all log files in bytes
    func getTotalLogSize() -> UInt64 {
        var total: UInt64 = 0
        for file in getLogFiles() {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path) {
                total += attributes[.size] as? UInt64 ?? 0
            }
        }
        return total
    }

    /// Returns the size of the current log file in bytes
    func getCurrentLogFileSize() -> UInt64 {
        let logFile = logsDirectory.appendingPathComponent(Self.logFileName)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: logFile.path)
            return attributes[.size] as? UInt64 ?? 0
        } catch {
            return 0
        }
    }

    /// Clears all log files
    func clearAllLogs() {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: logsDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            resetLogLevelCounts()
            writeLog("=== All logs cleared ===")
        } catch {
            print("Error clearing logs: \(error)")
        }
    }

    /// Reads and parses the most recent log entries
    /// - Parameter maxEntries: Maximum number of entries to return (default 2000)
    /// - Returns: Array of LogEntry objects sorted by timestamp (newest first)
    func getLogEntries(maxEntries: Int = 2000) -> [LogEntry] {
        let logFiles = getLogFiles().reversed() // Start from newest file
        var entries: [LogEntry] = []
        var entriesCount = 0
        
        let parserDateFormatter = DateFormatter()
        parserDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        parserDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Regex pattern: [Timestamp] [Level] [Category] Message
        let pattern = "^\\[(.*?)\\] \\[(.*?)\\] \\[(.*?)\\] (.*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        for file in logFiles {
            guard entriesCount < maxEntries else { break }
            
            do {
                let content = try String(contentsOf: file, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines).reversed() // Read bottom-up (newest first)
                
                for line in lines {
                    guard !line.isEmpty, entriesCount < maxEntries else { continue }
                    
                    // Skip separator lines like === ... ===
                    if line.hasPrefix("===") { continue }
                    
                    if let entry = parseLogLine(line, regex: regex, dateFormatter: parserDateFormatter) {
                        entries.append(entry)
                        entriesCount += 1
                    }
                }
            } catch {
                print("Error reading log file \(file.lastPathComponent): \(error)")
            }
        }
        
        return entries.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    private func parseLogLine(_ line: String, regex: NSRegularExpression, dateFormatter: DateFormatter) -> LogEntry? {
        let range = NSRange(location: 0, length: line.utf16.count)
        guard let match = regex.firstMatch(in: line, range: range),
              match.numberOfRanges == 5,
              let timestampRange = Range(match.range(at: 1), in: line),
              let levelRange = Range(match.range(at: 2), in: line),
              let categoryRange = Range(match.range(at: 3), in: line),
              let messageRange = Range(match.range(at: 4), in: line) else {
            return nil
        }
        
        let timestampStr = String(line[timestampRange])
        let levelStr = String(line[levelRange])
        let category = String(line[categoryRange])
        let message = String(line[messageRange])
        
        guard let date = dateFormatter.date(from: timestampStr),
              let level = LogLevel(rawValue: levelStr) else {
            return nil
        }
        
        return LogEntry(
            timestamp: date,
            level: level,
            category: category,
            message: message,
            originalText: line
        )
    }

    // MARK: - Log Writing

    func log(level: LogLevel, message: String, category: String = "General") {
        guard isInitialized else { return }

        let timestamp = dateFormatter.string(from: Date())
        let logEntry = "[\(timestamp)] [\(level.rawValue)] [\(category)] \(message)\n"

        writeLog(logEntry)

        // Track log level count
        logLevelCounts[level, default: 0] += 1

        // Check if rotation is needed after writing
        rotateLogsIfNeeded()
    }

    /// Returns the current log level counts
    func getLogLevelCounts() -> [LogLevel: Int] {
        return logLevelCounts
    }

    /// Resets log level counts (called when logs are cleared)
    func resetLogLevelCounts() {
        logLevelCounts = [.debug: 0, .info: 0, .warning: 0, .error: 0]
    }

    private func writeLog(_ message: String) {
        let logFile = logsDirectory.appendingPathComponent(Self.logFileName)

        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFile.path) {
            FileManager.default.createFile(atPath: logFile.path, contents: nil)
        }

        do {
            let fileHandle = try FileHandle(forWritingTo: logFile)
            defer {
                try? fileHandle.close()
            }
            try fileHandle.seekToEnd()
            guard let data = message.data(using: .utf8) else { return }
            try fileHandle.write(contentsOf: data)
            try fileHandle.synchronize()
        } catch {
            print("Error writing to log file: \(error)")
        }
    }

    // MARK: - Log Rotation

    private func rotateLogsIfNeeded() {
        let logFile = logsDirectory.appendingPathComponent(Self.logFileName)

        // Check current file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: logFile.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0

            if fileSize >= Self.maxFileSize {
                rotateLogs()
            }
        } catch {
            print("Error checking file size: \(error)")
        }
    }

    private func rotateLogs() {
        writeLog("\n=== Rotating log file (reached \(Self.maxFileSize / 1024)KB) ===\n")

        // Get all existing rotated log files and find the highest index
        let logFiles = getLogFiles()
        var highestIndex = 0

        for file in logFiles {
            let index = extractLogIndex(from: file.lastPathComponent)
            if index > highestIndex {
                highestIndex = index
            }
        }

        // Move current log to new indexed file
        let currentLog = logsDirectory.appendingPathComponent(Self.logFileName)
        let newIndex = highestIndex + 1
        let rotatedFileName = String(format: "%s.%05d.log", Self.logFileName, newIndex)
        let rotatedLog = logsDirectory.appendingPathComponent(rotatedFileName)

        do {
            try FileManager.default.moveItem(at: currentLog, to: rotatedLog)

            // Create new log file
            FileManager.default.createFile(atPath: currentLog.path, contents: nil)

            writeLog("=== Log rotation complete, created \(rotatedFileName) ===")

            // Enforce folder size limit after rotation
            enforceFolderSizeLimit()
        } catch {
            print("Error rotating logs: \(error)")
        }
    }

    /// Enforces the 5MB total folder size limit by deleting oldest log files
    private func enforceFolderSizeLimit() {
        var totalSize = getTotalLogSize()

        while totalSize > Self.maxTotalFolderSize {
            let logFiles = getLogFiles()

            guard !logFiles.isEmpty else { break }

            // Delete the oldest log file (lowest index that's not the current log)
            let oldestFile = logFiles.first { !$0.lastPathComponent.equals(Self.logFileName) }

            if let fileToDelete = oldestFile {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileToDelete.path) {
                    let fileSize = attributes[.size] as? UInt64 ?? 0
                    totalSize -= fileSize
                }

                try? FileManager.default.removeItem(at: fileToDelete)
                writeLog("=== Deleted old log file: \(fileToDelete.lastPathComponent) to maintain 5MB limit ===")
            } else {
                break
            }
        }
    }

    // MARK: - Helpers

    /// Extracts the numeric index from a log filename
    /// Examples:
    /// - "notimanager.log" -> 0 (current log)
    /// - "notimanager.log.00001.log" -> 1
    /// - "notimanager.log.00042.log" -> 42
    private func extractLogIndex(from filename: String) -> Int {
        if filename == Self.logFileName {
            return 0
        }

        // Extract the 5-digit index from the middle
        // Format: notimanager.log.XXXXX.log
        let pattern = "^notimanager\\.log\\.(\\d+)\\.log$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }

        let range = NSRange(location: 0, length: filename.utf16.count)
        if let match = regex.firstMatch(in: filename, range: range),
           let indexRange = Range(match.range(at: 1), in: filename),
           let index = Int(String(filename[indexRange])) {
            return index
        }

        return 0
    }

    // MARK: - Log Levels

    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
    }
}

// MARK: - String Extension

private extension String {
    func equals(_ other: String) -> Bool {
        return self == other
    }
}
