//
//  KeyboardShortcuts.swift
//  Notimanager
//
//  Keyboard shortcuts for common actions
//  Improves power user efficiency and accessibility
//
//  Based on: HIG Keyboard Shortcuts Guidelines (2026)
//

import AppKit

// MARK: - Keyboard Shortcuts Manager

/// Manages global and local keyboard shortcuts for Notimanager
final class KeyboardShortcutsManager {

    // MARK: - Singleton

    static let shared = KeyboardShortcutsManager()

    private init() {
        // Private initializer for singleton
    }

    // MARK: - Shortcut Definitions

    /// All keyboard shortcuts used in the app
    enum Shortcut: String, CaseIterable {
        // Settings navigation
        case openSettings = "Open Settings"
        case generalSettings = "General Settings"
        case positionSettings = "Position Settings"
        case interceptionSettings = "Interception Settings"
        case aboutSettings = "About Settings"

        // Quick actions
        case sendTest = "Send Test Notification"
        case togglePositioning = "Toggle Positioning"
        case openDiagnostics = "Open Diagnostics"

        // Position shortcuts
        case topLeft = "Position Top Left"
        case topRight = "Position Top Right"
        case bottomLeft = "Position Bottom Left"
        case bottomRight = "Position Bottom Right"

        // System
        case quitApp = "Quit Notimanager"
        case hideApp = "Hide Notimanager"

        /// Default key combination for the shortcut
        var defaultValue: KeyCombo {
            switch self {
            case .openSettings:
                return KeyCombo(key: ",", modifiers: [.command])
            case .generalSettings:
                return KeyCombo(key: "1", modifiers: [.command, .shift])
            case .positionSettings:
                return KeyCombo(key: "2", modifiers: [.command, .shift])
            case .interceptionSettings:
                return KeyCombo(key: "3", modifiers: [.command, .shift])
            case .aboutSettings:
                return KeyCombo(key: "4", modifiers: [.command, .shift])
            case .sendTest:
                return KeyCombo(key: "t", modifiers: [.command, .option])
            case .togglePositioning:
                return KeyCombo(key: "p", modifiers: [.command, .option])
            case .openDiagnostics:
                return KeyCombo(key: "d", modifiers: [.command, .option])
            case .topLeft:
                return KeyCombo(key: "1", modifiers: [.command, .control])
            case .topRight:
                return KeyCombo(key: "2", modifiers: [.command, .control])
            case .bottomLeft:
                return KeyCombo(key: "3", modifiers: [.command, .control])
            case .bottomRight:
                return KeyCombo(key: "4", modifiers: [.command, .control])
            case .quitApp:
                return KeyCombo(key: "q", modifiers: [.command])
            case .hideApp:
                return KeyCombo(key: "h", modifiers: [.command])
            }
        }

        /// Localized description for accessibility
        var localizedDescription: String {
            switch self {
            case .openSettings:
                return NSLocalizedString("Open Notimanager Settings", comment: "Shortcut description")
            case .generalSettings:
                return NSLocalizedString("Show General Settings", comment: "Shortcut description")
            case .positionSettings:
                return NSLocalizedString("Show Position Settings", comment: "Shortcut description")
            case .interceptionSettings:
                return NSLocalizedString("Show Interception Settings", comment: "Shortcut description")
            case .aboutSettings:
                return NSLocalizedString("Show About Settings", comment: "Shortcut description")
            case .sendTest:
                return NSLocalizedString("Send Test Notification", comment: "Shortcut description")
            case .togglePositioning:
                return NSLocalizedString("Toggle Notification Positioning", comment: "Shortcut description")
            case .openDiagnostics:
                return NSLocalizedString("Open Diagnostics", comment: "Shortcut description")
            case .topLeft:
                return NSLocalizedString("Set Position to Top Left", comment: "Shortcut description")
            case .topRight:
                return NSLocalizedString("Set Position to Top Right", comment: "Shortcut description")
            case .bottomLeft:
                return NSLocalizedString("Set Position to Bottom Left", comment: "Shortcut description")
            case .bottomRight:
                return NSLocalizedString("Set Position to Bottom Right", comment: "Shortcut description")
            case .quitApp:
                return NSLocalizedString("Quit Notimanager", comment: "Shortcut description")
            case .hideApp:
                return NSLocalizedString("Hide Notimanager", comment: "Shortcut description")
            }
        }
    }

    // MARK: - Key Combo Structure

    struct KeyCombo: Hashable {
        let key: String
        let modifiers: NSEvent.ModifierFlags

        // Custom hash implementation for NSEvent.ModifierFlags
        func hash(into hasher: inout Hasher) {
            hasher.combine(key)
            hasher.combine(modifiers.rawValue)
        }

        static func == (lhs: KeyCombo, rhs: KeyCombo) -> Bool {
            return lhs.key == rhs.key && lhs.modifiers.rawValue == rhs.modifiers.rawValue
        }

        /// String representation for display in UI
        var displayString: String {
            var parts: [String] = []

            if modifiers.contains(.command) {
                parts.append("⌘")
            }
            if modifiers.contains(.option) {
                parts.append("⌥")
            }
            if modifiers.contains(.control) {
                parts.append("⌃")
            }
            if modifiers.contains(.shift) {
                parts.append("⇧")
            }

            // Capitalize the key character
            let displayKey = key.uppercased()
            parts.append(displayKey)

            return parts.joined(separator: "")
        }
    }

    // MARK: - Registration

    /// Register all keyboard shortcuts for the app
    func registerShortcuts() {
        // Global shortcuts that work anywhere in the system
        registerGlobalShortcuts()

        // Local shortcuts for when the app is active
        registerLocalShortcuts()

        LoggingService.shared.log("Keyboard shortcuts registered")
    }

    private func registerGlobalShortcuts() {
        // Note: Global shortcuts require additional setup and permissions
        // For now, we'll use local shortcuts only
        // Global shortcuts would require using Carbon RegisterEventHotKey
        // or the newer Keyboard Shortcuts framework
    }

    private func registerLocalShortcuts() {
        // Local shortcuts are handled through menu items
        // These are registered in MainMenu.xib or programmatically
    }

    // MARK: - Shortcut Handlers

    /// Execute the action associated with a shortcut
    @MainActor
    func executeShortcut(_ shortcut: Shortcut) {
        switch shortcut {
        case .openSettings:
            NotificationMover.shared.coordinator.showSettings()

        case .generalSettings:
            NotificationMover.shared.coordinator.showSettings(pane: .general)

        case .positionSettings:
            NotificationMover.shared.coordinator.showSettings(pane: .position)

        case .interceptionSettings:
            // Interception settings are now part of Position & Interception pane
            NotificationMover.shared.coordinator.showSettings(pane: .position)

        case .aboutSettings:
            NotificationMover.shared.coordinator.showSettings(pane: .about)

        case .sendTest:
            TestNotificationService.shared.sendTestNotification()

        case .togglePositioning:
            let config = ConfigurationManager.shared
            config.isEnabled.toggle()
            ActivityManager.shared.donateTogglePositioningActivity(isEnabled: config.isEnabled)

        case .openDiagnostics:
            NotificationMover.shared.coordinator.showDiagnostics()

        case .topLeft:
            setPosition(.topLeft)

        case .topRight:
            setPosition(.topRight)

        case .bottomLeft:
            setPosition(.bottomLeft)

        case .bottomRight:
            setPosition(.bottomRight)

        case .quitApp:
            NSApplication.shared.terminate(nil)

        case .hideApp:
            NSApplication.shared.hide(nil)
        }
    }

    private func setPosition(_ position: NotificationPosition) {
        ConfigurationManager.shared.currentPosition = position
        ActivityManager.shared.donateChangePositionActivity(to: position)
        AccessibilityManager.shared.announce("Notification position changed to \(position.displayName)")
    }
}

// MARK: - NSResponder Extension for Shortcut Handling

extension NSResponder {

    /// Handle keyboard shortcuts using key equivalents
    /// Note: This is a helper method - actual shortcuts are registered through menu items
    func createMenuItem(withKeyCombo keyCombo: KeyboardShortcutsManager.KeyCombo, action: Selector) -> NSMenuItem {
        let menuItem = NSMenuItem(
            title: "",
            action: action,
            keyEquivalent: keyCombo.key
        )
        menuItem.keyEquivalentModifierMask = keyCombo.modifiers
        return menuItem
    }
}

// MARK: - Menu Item Builder

extension NSMenuItem {

    /// Create a menu item with keyboard shortcut
    static func menuItem(
        title: String,
        shortcut: KeyboardShortcutsManager.Shortcut,
        action: Selector?,
        target: AnyObject? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: action,
            keyEquivalent: shortcut.defaultValue.key
        )
        item.keyEquivalentModifierMask = shortcut.defaultValue.modifiers
        item.representedObject = shortcut.rawValue
        item.target = target
        return item
    }

    /// Create a menu item with custom key combo
    static func menuItem(
        title: String,
        key: String,
        modifiers: NSEvent.ModifierFlags,
        action: Selector?,
        target: AnyObject? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: action,
            keyEquivalent: key
        )
        item.keyEquivalentModifierMask = modifiers
        item.target = target
        return item
    }
}

// MARK: - Shortcut Reference for Help

/// Provides human-readable keyboard shortcut documentation
struct KeyboardShortcutReference {

    static let allShortcuts: [(category: String, shortcuts: [(name: String, key: String)])] = [
        (
            category: NSLocalizedString("Settings", comment: "Shortcut category"),
            shortcuts: [
                (NSLocalizedString("Open Settings", comment: "Shortcut name"), "⌘,"),
                (NSLocalizedString("General Settings", comment: "Shortcut name"), "⌘⇧1"),
                (NSLocalizedString("Position Settings", comment: "Shortcut name"), "⌘⇧2"),
                (NSLocalizedString("Interception Settings", comment: "Shortcut name"), "⌘⇧3"),
                (NSLocalizedString("About Settings", comment: "Shortcut name"), "⌘⇧4")
            ]
        ),
        (
            category: NSLocalizedString("Quick Actions", comment: "Shortcut category"),
            shortcuts: [
                (NSLocalizedString("Send Test Notification", comment: "Shortcut name"), "⌘⌥T"),
                (NSLocalizedString("Toggle Positioning", comment: "Shortcut name"), "⌘⌥P"),
                (NSLocalizedString("Open Diagnostics", comment: "Shortcut name"), "⌘⌥D")
            ]
        ),
        (
            category: NSLocalizedString("Position Shortcuts", comment: "Shortcut category"),
            shortcuts: [
                (NSLocalizedString("Top Left", comment: "Shortcut name"), "⌘⌃1"),
                (NSLocalizedString("Top Right", comment: "Shortcut name"), "⌘⌃2"),
                (NSLocalizedString("Bottom Left", comment: "Shortcut name"), "⌘⌃3"),
                (NSLocalizedString("Bottom Right", comment: "Shortcut name"), "⌘⌃4")
            ]
        )
    ]

    /// Generate markdown documentation for keyboard shortcuts
    static func markdownDocumentation() -> String {
        var markdown = "# Keyboard Shortcuts\n\n"

        for (category, shortcuts) in allShortcuts {
            markdown += "## \(category)\n\n"
            for (name, key) in shortcuts {
                markdown += "- **\(key)** – \(name)\n"
            }
            markdown += "\n"
        }

        return markdown
    }
}
