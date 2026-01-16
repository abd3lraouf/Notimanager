//
//  LaunchAgentManager.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Manages the launch agent plist for "launch at login" functionality.
//  Extracted from NotificationMover to separate concerns.
//
//  DEPRECATED: This class is deprecated in favor of the LaunchAtLogin package (Swift Package Manager).
//  LaunchAtLogin provides a more modern, SwiftUI-based approach that handles "launch at login"
//  functionality automatically and follows current macOS best practices.
//  This file is kept for backwards compatibility with macOS versions prior to 13.0.
//
//  To migrate:
//  1. Add LaunchAtLogin SPM package: https://github.com/sindresorhus/LaunchAtLogin-Modern
//  2. Replace usage with: `LaunchAtLogin.isEnabled` and `LaunchAtLogin.Toggle`
//  3. Remove this file once your minimum deployment target is macOS 13.0+
//

import Foundation

/// Manages the launch agent plist for "launch at login" functionality.
///
/// **DEPRECATED**: Use LaunchAtLogin package instead for macOS 13.0+
///
/// This class serves as the single source of truth for launch agent paths and provides
/// methods to enable, disable, and check the status of the launch at login functionality.
///
/// The default plist path follows macOS conventions: `~/Library/LaunchAgents/{bundleIdentifier}.plist`
@available(macOS 10.15, *)
@available(*, deprecated, message: "Use LaunchAtLogin SPM package instead for macOS 13.0+")
class LaunchAgentManager {

    // MARK: - Public Static Properties

    /// The default path for the launch agent plist file.
    ///
    /// This path follows the standard macOS convention for launch agents:
    /// `~/Library/LaunchAgents/dev.abd3lraouf.notimanager.plist`
    ///
    /// Use this property when you need to reference the launch agent path from other parts
    /// of the application, rather than hardcoding the path.
    public static let defaultPlistPath: String = {
        NSHomeDirectory() + "/Library/LaunchAgents/dev.abd3lraouf.notimanager.plist"
    }()

    // MARK: - Properties

    private let plistPath: String
    private let bundleIdentifier: String
    private let executablePath: String

    // MARK: - Initialization

    /// Initializes a new LaunchAgentManager instance.
    ///
    /// - Parameter plistPath: Optional custom path for the launch agent plist.
    ///                       If nil, uses the default path specified by `defaultPlistPath`.
    init(plistPath: String? = nil) {
        self.plistPath = plistPath ?? Self.defaultPlistPath

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
