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

    /// The last time updates were checked
    private let lastCheckDateKey = "lastUpdateCheckDate"

    var lastUpdateCheckDate: Date? {
        get {
            UserDefaults.standard.object(forKey: lastCheckDateKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastCheckDateKey)
        }
    }

    /// The current app version
    var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// The current build number
    var currentBuildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
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
            updaterDelegate: self,
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

    /// Formats the last check date for display
    func formattedLastCheckDate() -> String {
        guard let date = lastUpdateCheckDate else {
            return "Never"
        }

        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) \(minutes == 1 ? "minute" : "minutes") ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) \(hours == 1 ? "hour" : "hours") ago"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days) \(days == 1 ? "day" : "days") ago"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: date, relativeTo: now)
        }
    }
}

// MARK: - SPUUpdaterDelegate

extension UpdateManager: SPUUpdaterDelegate {
    func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        // Update last check date when check completes
        lastUpdateCheckDate = Date()
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        // Still update last check date on error
        lastUpdateCheckDate = Date()
        // Log the error for debugging
        print("Update aborted with error: \(error.localizedDescription)")
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        print("Found valid update: \(item.versionString)")
    }

    func updater(_ updater: SPUUpdater, didNotFindUpdate item: SUAppcastItem) {
        print("No new update found. Current version is up to date.")
    }

    func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem) {
        print("Preparing to download update: \(item.versionString)")
    }

    func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
        print("Successfully downloaded update: \(item.versionString)")
    }

    func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        print("Failed to download update \(item.versionString): \(error.localizedDescription)")
    }

    func updater(_ updater: SPUUpdater, willExtractUpdate item: SUAppcastItem) {
        print("Extracting update: \(item.versionString)")
    }

    func updater(_ updater: SPUUpdater, didExtractUpdate item: SUAppcastItem) {
        print("Successfully extracted update: \(item.versionString)")
    }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        print("Installing update: \(item.versionString)")
    }

    func updater(_ updater: SPUUpdater, failedToApplyUpdate item: SUAppcastItem, error: Error) {
        print("Failed to apply update \(item.versionString): \(error.localizedDescription)")
    }
}
