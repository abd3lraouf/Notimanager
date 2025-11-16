//
//  LaunchAgentManager.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Manages the launch agent plist for "launch at login" functionality.
//  Extracted from NotificationMover to separate concerns.
//

import Foundation

/// Manages the launch agent plist for "launch at login" functionality
@available(macOS 10.15, *)
class LaunchAgentManager {

    // MARK: - Properties

    private let plistPath: String
    private let bundleIdentifier: String
    private let executablePath: String

    // MARK: - Initialization

    init(plistPath: String? = nil) {
        self.plistPath = plistPath ?? (NSHomeDirectory() + "/Library/LaunchAgents/dev.abd3lraouf.notimanager.plist")

        guard let bundleID = Bundle.main.bundleIdentifier else {
            fatalError("Bundle identifier not found")
        }
        self.bundleIdentifier = bundleID

        guard let execPath = Bundle.main.executablePath else {
            fatalError("Executable path not found")
        }
        self.executablePath = execPath
    }

    // MARK: - Public Methods

    /// Whether the launch agent is currently enabled
    var isEnabled: Bool {
        return FileManager.default.fileExists(atPath: plistPath)
    }

    /// Sets the launch agent enabled state
    /// - Parameter enabled: Whether to enable or disable the launch agent
    /// - Throws: FileManager errors if plist operations fail
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try createPlist()
        } else {
            try removePlist()
        }
    }

    /// Toggles the launch agent state
    /// - Returns: The new state
    /// - Throws: FileManager errors if plist operations fail
    func toggle() throws -> Bool {
        let newState = !isEnabled
        try setEnabled(newState)
        return newState
    }

    // MARK: - Private Methods

    /// Creates the launch agent plist file
    private func createPlist() throws {
        let plistDirectory = (plistPath as NSString).deletingLastPathComponent

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: plistDirectory) {
            try FileManager.default.createDirectory(
                atPath: plistDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        // Create plist content
        let plistContent: [String: Any] = [
            "Label": bundleIdentifier,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false
        ]

        // Write plist
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: plistContent,
            format: .xml,
            options: 0
        )

        try plistData.write(to: URL(fileURLWithPath: plistPath))

        // Load the launch agent
        loadLaunchAgent()
    }

    /// Removes the launch agent plist file
    private func removePlist() throws {
        // Unload the launch agent first
        unloadLaunchAgent()

        // Remove plist file
        if FileManager.default.fileExists(atPath: plistPath) {
            try FileManager.default.removeItem(atPath: plistPath)
        }
    }

    /// Loads the launch agent using launchctl
    private func loadLaunchAgent() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = ["load", plistPath]

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Failed to load launch agent: \(error)")
        }
    }

    /// Unloads the launch agent using launchctl
    private func unloadLaunchAgent() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = ["unload", plistPath]

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            // Ignore errors - launch agent might not be loaded
            print("Note: Launch agent unload result: \(error)")
        }
    }
}
