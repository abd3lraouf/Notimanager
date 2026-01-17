//
//  UpdateManager.swift
//  Notimanager
//
//  Created on 2025-01-17.
//  Manages Sparkle auto-updates.
//

import AppKit
import Sparkle

/// Manages application auto-updates using Sparkle
final class UpdateManager: NSObject {

    // MARK: - Singleton

    static let shared = UpdateManager()

    // MARK: - Properties

    /// The Sparkle updater controller
    private(set) var updaterController: SPUStandardUpdaterController?

    /// The Sparkle updater (for direct access to updater APIs)
    var updater: SPUUpdater? {
        updaterController?.updater
    }

    /// Whether automatic update checks are enabled
    var automaticallyChecksForUpdates: Bool {
        get {
            updater?.automaticallyChecksForUpdates ?? true
        }
        set {
            updater?.automaticallyChecksForUpdates = newValue
        }
    }

    /// The update check interval in seconds
    var updateCheckInterval: TimeInterval {
        get {
            updater?.updateCheckInterval ?? 86400 // 24 hours default
        }
        set {
            updater?.updateCheckInterval = newValue
        }
    }

    /// Whether automatic downloading of updates is enabled
    var automaticallyDownloadsUpdates: Bool {
        get {
            updater?.automaticallyDownloadsUpdates ?? false
        }
        set {
            updater?.automaticallyDownloadsUpdates = newValue
        }
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        setupUpdater()
    }

    // MARK: - Setup

    /// Sets up the Sparkle updater
    private func setupUpdater() {
        // Initialize the updater controller with Sparkle
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    // MARK: - Public Methods

    /// Initiates a manual check for updates
    func checkForUpdates() {
        updater?.checkForUpdates()
    }

    /// Checks for updates in the background (no UI shown unless update found)
    func checkForUpdatesInBackground() {
        updater?.checkForUpdatesInBackground()
    }
}
