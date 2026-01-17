//
//  SpotlightIndexer.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  CoreSpotlight integration for searchable app content.
//

import Foundation
import CoreSpotlight
import CoreServices

/// Manages Spotlight indexing for Notimanager settings and features
@available(macOS 10.15, *)
final class SpotlightIndexer {

    // MARK: - Singleton

    static let shared = SpotlightIndexer()

    private init() {
        // Private initializer for singleton
    }

    // MARK: - Domain Identifiers

    private enum Domain {
        static let settings = "com.notimanager.spotlight.settings"
        static let positions = "com.notimanager.spotlight.positions"
        static let actions = "com.notimanager.spotlight.actions"
    }

    // MARK: - Index All Content

    /// Indexes all searchable content in Notimanager
    func indexAllContent() {
        indexSettings()
        indexPositions()
        indexActions()
    }

    // MARK: - Index Settings

    /// Indexes the settings page for Spotlight search
    func indexSettings() {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = NSLocalizedString("Notimanager Settings", comment: "Spotlight title")
        attributes.contentDescription = NSLocalizedString(
            "Configure notification positioning, interception, and app preferences",
            comment: "Spotlight description"
        )
        attributes.keywords = [
            "notification", "position", "settings", "preferences", "configuration",
            "interception", "widgets", "accessibility"
        ]

        let item = CSSearchableItem(
            uniqueIdentifier: "settings",
            domainIdentifier: Domain.settings,
            attributeSet: attributes
        )

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                LoggingService.shared.error("Failed to index settings: \(error)")
            } else {
                LoggingService.shared.debug("Successfully indexed settings in Spotlight")
            }
        }
    }

    // MARK: - Index Positions

    /// Indexes all available notification positions for Spotlight search
    func indexPositions() {
        let positions: [(id: String, title: String, description: String)] = [
            (
                "top-left",
                NSLocalizedString("Top Left Position", comment: "Spotlight title"),
                NSLocalizedString("Move notifications to the top left corner of the screen", comment: "Spotlight description")
            ),
            (
                "top-right",
                NSLocalizedString("Top Right Position", comment: "Spotlight title"),
                NSLocalizedString("Move notifications to the top right corner of the screen", comment: "Spotlight description")
            ),
            (
                "bottom-left",
                NSLocalizedString("Bottom Left Position", comment: "Spotlight title"),
                NSLocalizedString("Move notifications to the bottom left corner of the screen", comment: "Spotlight description")
            ),
            (
                "bottom-right",
                NSLocalizedString("Bottom Right Position", comment: "Spotlight title"),
                NSLocalizedString("Move notifications to the bottom right corner of the screen", comment: "Spotlight description")
            )
        ]

        let items = positions.map { position -> CSSearchableItem in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = position.title
            attributes.contentDescription = position.description
            attributes.keywords = [
                "position", "notification", "corner", position.title.lowercased(),
                "move", "reposition", "screen"
            ]

            return CSSearchableItem(
                uniqueIdentifier: "position-\(position.id)",
                domainIdentifier: Domain.positions,
                attributeSet: attributes
            )
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                LoggingService.shared.error("Failed to index positions: \(error)")
            } else {
                LoggingService.shared.debug("Successfully indexed positions in Spotlight")
            }
        }
    }

    // MARK: - Index Actions

    /// Indexes common actions for Spotlight search
    func indexActions() {
        let actions: [(id: String, title: String, description: String)] = [
            (
                "toggle",
                NSLocalizedString("Toggle Notification Positioning", comment: "Spotlight title"),
                NSLocalizedString("Enable or disable notification positioning", comment: "Spotlight description")
            ),
            (
                "test",
                NSLocalizedString("Send Test Notification", comment: "Spotlight title"),
                NSLocalizedString("Send a test notification to verify interception is working", comment: "Spotlight description")
            ),
            (
                "permissions",
                NSLocalizedString("Accessibility Permissions", comment: "Spotlight title"),
                NSLocalizedString("View or change accessibility permissions", comment: "Spotlight description")
            )
        ]

        let items = actions.map { action -> CSSearchableItem in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = action.title
            attributes.contentDescription = action.description
            attributes.keywords = [
                "action", "notification", action.title.lowercased(),
                "enable", "disable", "test", "permission"
            ]

            return CSSearchableItem(
                uniqueIdentifier: "action-\(action.id)",
                domainIdentifier: Domain.actions,
                attributeSet: attributes
            )
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                LoggingService.shared.error("Failed to index actions: \(error)")
            } else {
                LoggingService.shared.debug("Successfully indexed actions in Spotlight")
            }
        }
    }

    // MARK: - Handle Spotlight Search

    /// Called when user selects an item from Spotlight search
    func handleSpotlightSearch(identifier: String) -> Bool {
        LoggingService.shared.info("Spotlight search selected: \(identifier)")

        // Parse the identifier and take appropriate action
        if identifier == "settings" {
            NotificationMover.shared.coordinator.showSettings()
            return true
        } else if identifier.hasPrefix("position-") {
            let positionString = identifier.replacingOccurrences(of: "position-", with: "")
            if let position = positionFromSpotlightIdentifier(positionString) {
                ConfigurationManager.shared.currentPosition = position
                NotificationMover.shared.coordinator.showSettings()
                return true
            }
        } else if identifier.hasPrefix("action-") {
            let actionString = identifier.replacingOccurrences(of: "action-", with: "")
            return handleActionFromSpotlight(actionString)
        }

        return false
    }

    // MARK: - Helpers

    private func positionFromSpotlightIdentifier(_ identifier: String) -> NotificationPosition? {
        switch identifier {
        case "top-left": return .topLeft
        case "top-right": return .topRight
        case "bottom-left": return .bottomLeft
        case "bottom-right": return .bottomRight
        default: return nil
        }
    }

    private func handleActionFromSpotlight(_ action: String) -> Bool {
        switch action {
        case "toggle":
            ConfigurationManager.shared.isEnabled.toggle()
            return true
        case "test":
            TestNotificationService.shared.sendTestNotification()
            return true
        case "permissions":
            NotificationMover.shared.coordinator.showPermissionWindowFromSettings()
            return true
        default:
            return false
        }
    }

    // MARK: - Remove Index

    /// Removes all Notimanager items from Spotlight index
    func removeAllIndexItems() {
        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if let error = error {
                LoggingService.shared.error("Failed to remove Spotlight items: \(error)")
            } else {
                LoggingService.shared.debug("Successfully removed all Spotlight items")
            }
        }
    }
}
