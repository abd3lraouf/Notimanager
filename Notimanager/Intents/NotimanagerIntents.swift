//
//  NotimanagerIntents.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  App Intents for Siri, Shortcuts, and Apple Intelligence integration.
//

import AppIntents
import Foundation

// MARK: - Toggle Notification Positioning Intent

/// Enables or disables notification positioning via Siri or Shortcuts
struct ToggleNotificationPositioningIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Notification Positioning"
    static var description = IntentDescription("Enable or disable notification positioning for Notimanager")

    @Parameter(
        title: "Enable",
        description: "Whether to enable or disable notification positioning",
        default: nil
    )
    var isEnabled: Bool?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let newState: Bool
        if let enabled = isEnabled {
            newState = enabled
        } else {
            // Toggle if no parameter provided
            newState = !ConfigurationManager.shared.isEnabled
        }

        ConfigurationManager.shared.isEnabled = newState
        LoggingService.shared.info("Notification positioning \(newState ? "enabled" : "disabled") via App Intent")

        let message = "Notification positioning \(newState ? "enabled" : "disabled")"
        AccessibilityManager.shared.announce(message)

        return .result(
            dialog: IntentDialog(
                full: LocalizedStringResource(stringLiteral: message),
                supporting: LocalizedStringResource(stringLiteral: "\(newState ? "Enabled" : "Disabled") notification positioning")
            )
        )
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Toggle notification positioning \(\.$isEnabled)") {
            \.$isEnabled
        }
    }
}

// MARK: - Change Notification Position Intent

/// Moves notifications to a specific corner via Siri or Shortcuts
struct ChangeNotificationPositionIntent: AppIntent {
    static var title: LocalizedStringResource = "Change Notification Position"
    static var description = IntentDescription("Move notifications to a specific corner of the screen")

    @Parameter(
        title: "Position",
        description: "The corner where notifications should appear"
    )
    var position: NotificationPositionAppEnum

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let newPosition = position.notificationPosition
        ConfigurationManager.shared.currentPosition = newPosition
        LoggingService.shared.info("Position changed to \(newPosition.displayName) via App Intent")

        // Move existing notifications to new position
        NotificationMover.shared.coordinator.moveAllNotifications()

        let message = "Notifications moved to \(newPosition.displayName)"
        AccessibilityManager.shared.announce(message)

        return .result(
            dialog: IntentDialog(
                full: LocalizedStringResource(stringLiteral: message),
                supporting: LocalizedStringResource(stringLiteral: "Position set to \(newPosition.displayName)")
            )
        )
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Change notification position to \(\.$position)") {
            \.$position
        }
    }
}

// MARK: - Notification Position App Enum

/// Enumeration of available notification positions for App Intents
enum NotificationPositionAppEnum: String, AppEnum {
    case topLeft = "top-left"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomRight = "bottom-right"

    var notificationPosition: NotificationPosition {
        switch self {
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottomRight: return .bottomRight
        }
    }

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Position")

    static var caseDisplayRepresentations: [NotificationPositionAppEnum: DisplayRepresentation] = [
        .topLeft: "Top Left",
        .topRight: "Top Right",
        .bottomLeft: "Bottom Left",
        .bottomRight: "Bottom Right"
    ]
}

// MARK: - Send Test Notification Intent

/// Sends a test notification via Siri or Shortcuts
struct SendTestNotificationIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Test Notification"
    static var description = IntentDescription("Send a test notification to verify interception is working")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        LoggingService.shared.info("Sending test notification via App Intent")

        await MainActor.run {
            TestNotificationService.shared.sendTestNotification()
        }

        return .result(
            dialog: IntentDialog(
                full: LocalizedStringResource(stringLiteral: "Test notification sent"),
                supporting: LocalizedStringResource(stringLiteral: "A test notification will appear shortly")
            )
        )
    }
}

// MARK: - Open Settings Intent

/// Opens Notimanager settings via Siri or Shortcuts
struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Settings"
    static var description = IntentDescription("Open Notimanager settings")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        LoggingService.shared.info("Opening settings via App Intent")

        await MainActor.run {
            NotificationMover.shared.coordinator.showSettings()
        }

        return .result(
            dialog: IntentDialog(
                full: LocalizedStringResource(stringLiteral: "Opening settings"),
                supporting: LocalizedStringResource(stringLiteral: "Settings window will appear")
            )
        )
    }
}

// MARK: - App Shortcuts Provider

/// Registers app shortcuts for Siri and Shortcuts
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Toggle Notification Positioning
        let toggleShortcut = AppShortcut(
            intent: ToggleNotificationPositioningIntent(),
            phrases: [
                "Toggle notification positioning in \(.applicationName)",
                "Enable notification positioning in \(.applicationName)",
                "Disable notification positioning in \(.applicationName)",
                "Turn on notification positioning",
                "Turn off notification positioning"
            ],
            shortTitle: "Toggle Positioning",
            systemImageName: "move.3d"
        )

        // Change Position
        let positionShortcut = AppShortcut(
            intent: ChangeNotificationPositionIntent(),
            phrases: [
                "Change notification position in \(.applicationName)",
                "Move notifications to \(\.$position) in \(.applicationName)",
                "Set notification position to \(\.$position)",
                "Change position to \(\.$position)"
            ],
            shortTitle: "Change Position",
            systemImageName: "arrow.up.left.and.arrow.down.right"
        )

        // Send Test Notification
        let testShortcut = AppShortcut(
            intent: SendTestNotificationIntent(),
            phrases: [
                "Send test notification in \(.applicationName)",
                "Test notification positioning",
                "Send a test notification"
            ],
            shortTitle: "Test Notification",
            systemImageName: "bell.badge"
        )

        // Open Settings
        let settingsShortcut = AppShortcut(
            intent: OpenSettingsIntent(),
            phrases: [
                "Open settings in \(.applicationName)",
                "Open \(.applicationName) settings",
                "Show settings"
            ],
            shortTitle: "Open Settings",
            systemImageName: "gearshape"
        )

        return [toggleShortcut, positionShortcut, testShortcut, settingsShortcut]
    }

    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}
