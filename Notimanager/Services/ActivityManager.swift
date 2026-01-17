//
//  ActivityManager.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  NSUserActivity donations for Handoff, Siri Suggestions, and Picks.
//

import Foundation
import CoreSpotlight

/// Manages NSUserActivity donations for Notimanager
@available(macOS 10.15, *)
final class ActivityManager {

    // MARK: - Singleton

    static let shared = ActivityManager()

    private init() {
        // Private initializer for singleton
    }

    // MARK: - Activity Types

    private enum ActivityType {
        static let settings = "com.notimanager.activity.settings"
        static let changePosition = "com.notimanager.activity.changePosition"
        static let togglePositioning = "com.notimanager.activity.togglePositioning"
        static let sendTestNotification = "com.notimanager.activity.sendTestNotification"
    }

    // MARK: - Settings Activity

    /// Donates activity when user opens settings
    func donateSettingsActivity() {
        let activity = NSUserActivity(activityType: ActivityType.settings)
        activity.persistentIdentifier = "settings"

        activity.title = NSLocalizedString("Open Settings", comment: "Activity title")

        // suggestedInvocationPhrase is deprecated in newer macOS versions

        // Add searchable item for Spotlight
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = NSLocalizedString("Notimanager Settings", comment: "Spotlight title")
        attributes.contentDescription = NSLocalizedString("Configure notification positioning and preferences", comment: "Spotlight description")
        attributes.keywords = ["settings", "preferences", "notification", "position"]
        activity.contentAttributeSet = attributes

        // Set user info to restore state
        activity.userInfo = ["action": "openSettings"]

        activity.becomeCurrent()
        LoggingService.shared.debug("Donated settings activity")
    }

    // MARK: - Change Position Activity

    /// Donates activity when user changes notification position
    func donateChangePositionActivity(to position: NotificationPosition) {
        let activity = NSUserActivity(activityType: ActivityType.changePosition)
        activity.persistentIdentifier = "changePosition"

        let positionName = position.displayName
        activity.title = String(format: NSLocalizedString("Change Position to %@", comment: "Activity title"), positionName)

        // suggestedInvocationPhrase is deprecated in newer macOS versions

        // Add searchable item for Spotlight
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = activity.title
        attributes.contentDescription = String(format: NSLocalizedString("Move notifications to the %@ corner", comment: "Spotlight description"), positionName)
        attributes.keywords = ["position", "notification", positionName.lowercased()]
        activity.contentAttributeSet = attributes

        // Set user info to restore state
        activity.userInfo = [
            "action": "changePosition",
            "position": position.id
        ]

        activity.becomeCurrent()
        LoggingService.shared.debug("Donated change position activity: \(positionName)")
    }

    // MARK: - Toggle Positioning Activity

    /// Donates activity when user enables/disables positioning
    func donateTogglePositioningActivity(isEnabled: Bool) {
        let activity = NSUserActivity(activityType: ActivityType.togglePositioning)
        activity.persistentIdentifier = "togglePositioning"

        let status = isEnabled ? NSLocalizedString("Enable", comment: "") : NSLocalizedString("Disable", comment: "")
        activity.title = String(format: NSLocalizedString("%@ Notification Positioning", comment: "Activity title"), status)

        // suggestedInvocationPhrase is deprecated in newer macOS versions
        // SiriKit and Shortcuts now handle this automatically

        // Add searchable item for Spotlight
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = activity.title
        attributes.contentDescription = isEnabled ?
            NSLocalizedString("Enable notification positioning for Notimanager", comment: "Spotlight description") :
            NSLocalizedString("Disable notification positioning for Notimanager", comment: "Spotlight description")
        attributes.keywords = ["toggle", "enable", "disable", "positioning", "notification"]
        activity.contentAttributeSet = attributes

        // Set user info to restore state
        activity.userInfo = [
            "action": "togglePositioning",
            "isEnabled": isEnabled
        ]

        activity.becomeCurrent()
        LoggingService.shared.debug("Donated toggle positioning activity: \(isEnabled ? "enabled" : "disabled")")
    }

    // MARK: - Send Test Notification Activity

    /// Donates activity when user sends a test notification
    func donateSendTestNotificationActivity() {
        let activity = NSUserActivity(activityType: ActivityType.sendTestNotification)
        activity.persistentIdentifier = "sendTestNotification"

        activity.title = NSLocalizedString("Send Test Notification", comment: "Activity title")

        // suggestedInvocationPhrase is deprecated in newer macOS versions

        // Add searchable item for Spotlight
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = activity.title
        attributes.contentDescription = NSLocalizedString("Send a test notification to verify interception is working", comment: "Spotlight description")
        attributes.keywords = ["test", "notification", "verify"]
        activity.contentAttributeSet = attributes

        // Set user info to restore state
        activity.userInfo = ["action": "sendTestNotification"]

        activity.becomeCurrent()
        LoggingService.shared.debug("Donated send test notification activity")
    }

    // MARK: - Invalidate Activity

    /// Invalidates the current user activity
    func invalidateCurrentActivity() {
        NSUserActivity.deleteAllSavedUserActivities {
            LoggingService.shared.debug("Cleared all saved user activities")
        }
    }
}

// MARK: - Position Extension for Activity Manager

extension NotificationPosition {
    var id: String {
        switch self {
        case .topLeft: return "top-left"
        case .topRight: return "top-right"
        case .bottomLeft: return "bottom-left"
        case .bottomRight: return "bottom-right"
        }
    }
}
