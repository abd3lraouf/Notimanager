//
//  UpdateManager.swift
//  Notimanager
//
//  Created on 2025-01-17.
//  Manages auto-updates using AppUpdater.
//

import AppKit
import AppUpdater
import PromiseKit

/// Manages application auto-updates using AppUpdater
final class UpdateManager: NSObject {

    // MARK: - Singleton

    static let shared = UpdateManager()

    // MARK: - Properties

    /// The AppUpdater instance
    private(set) var updater: AppUpdater!

    /// Whether automatic update checks are enabled
    /// Note: AppUpdater handles automatic checks internally via NSBackgroundActivityScheduler
    var automaticallyChecksForUpdates: Bool {
        get {
            // AppUpdater always checks automatically, so we return true
            // Users can still trigger manual checks
            return true
        }
        set {
            // AppUpdater doesn't support disabling automatic checks
            // The property exists for API compatibility with the old Sparkle implementation
        }
    }

    /// The update check interval in seconds
    /// Note: AppUpdater uses a fixed 24-hour interval
    var updateCheckInterval: TimeInterval {
        get {
            return 24 * 60 * 60 // AppUpdater uses 24 hours
        }
        set {
            // AppUpdater doesn't support custom intervals
        }
    }

    /// Whether automatic downloading of updates is enabled
    /// Note: AppUpdater automatically downloads and installs updates
    var automaticallyDownloadsUpdates: Bool {
        get {
            return true
        }
        set {
            // AppUpdater doesn't support toggling this
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

    /// Sets up the AppUpdater
    private func setupUpdater() {
        // Initialize AppUpdater with GitHub owner and repo
        // AppUpdater will automatically check for updates daily in the background
        updater = AppUpdater(owner: "abd3lraouf", repo: "Notimanager")
        updater.allowPrereleases = false
    }

    // MARK: - Public Methods

    /// Initiates a manual check for updates
    func checkForUpdates() {
        updateLastCheckDate()

        updater.check().catch(policy: .allErrors) { error in
            if error.isCancelled {
                // Already up-to-date
                print("AppUpdater: Already up to date")
            } else {
                // Show error alert
                print("AppUpdater error: \(error.localizedDescription)")
            }
        }
    }

    /// Checks for updates in the background
    /// Note: AppUpdater handles this automatically via NSBackgroundActivityScheduler
    func checkForUpdatesInBackground() {
        updateLastCheckDate()
        // AppUpdater handles background checks automatically
        // This method exists for API compatibility
    }

    private func updateLastCheckDate() {
        lastUpdateCheckDate = Date()
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
