//
//  AccessibilityManager.swift
//  Notimanager
//
//  Centralized accessibility management for VoiceOver, keyboard navigation,
//  and accessibility announcements.
//

import AppKit

/// Manages accessibility features throughout the app
class AccessibilityManager {

    // MARK: - Singleton

    static let shared = AccessibilityManager()

    private init() {}

    // MARK: - Announcements

    /// Announces an important message to VoiceOver users
    /// - Parameter message: The message to announce
    func announce(_ message: String) {
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow,
               let focusedView = window.firstResponder as? NSView {
                NSAccessibility.post(element: focusedView, notification: .announcementRequested, userInfo: [
                    NSAccessibility.NotificationUserInfoKey.announcement: message
                ])
            }
        }
    }

    // MARK: - Button Configuration

    /// Configures a button with proper accessibility attributes
    /// - Parameters:
    ///   - button: The button to configure
    ///   - label: The accessibility label
    ///   - hint: Optional hint text
    ///   - title: The visible button title (if different from label)
    func configureButton(_ button: NSButton, label: String, hint: String? = nil, title: String? = nil) {
        button.setAccessibilityLabel(label)
        button.setAccessibilityRole(.button)
        button.setAccessibilityIdentifier(label.components(separatedBy: " ").joined(separator: "_").lowercased())

        // Note: NSButton doesn't have setAccessibilityHint on macOS
        // Use setAccessibilityToolTip or similar if needed
        if let hint = hint {
            button.toolTip = hint
        }

        if let title = title {
            button.title = title
        }
    }

    /// Configures a checkbox with proper accessibility attributes
    /// - Parameters:
    ///   - checkbox: The checkbox to configure
    ///   - label: The accessibility label
    ///   - hint: Optional hint text
    ///   - value: Current state description
    func configureCheckbox(_ checkbox: NSButton, label: String, hint: String? = nil, value: String? = nil) {
        checkbox.setAccessibilityLabel(label)
        checkbox.setAccessibilityRole(.checkBox)
        checkbox.setAccessibilityTitle(label)

        if let hint = hint {
            checkbox.toolTip = hint
        }

        if let value = value {
            checkbox.setAccessibilityValue(value)
        } else {
            // Update value based on button state
            updateCheckboxValue(checkbox)
        }
    }

    /// Updates the accessibility value of a checkbox based on its state
    func updateCheckboxValue(_ checkbox: NSButton) {
        let state = checkbox.state == .on ? "checked" : "unchecked"
        checkbox.setAccessibilityValue(state)
    }

    // MARK: - Section Configuration

    /// Configures a section/container view with proper accessibility
    /// - Parameters:
    ///   - view: The view to configure
    ///   - title: The section title
    ///   - role: The accessibility role (default: .group)
    func configureSection(_ view: NSView, title: String, role: NSAccessibility.Role = .group) {
        view.setAccessibilityLabel(title)
        view.setAccessibilityRole(role)
        view.setAccessibilityElement(false) // Container is not directly accessible
    }

    // MARK: - Grid Configuration

    /// Configures a grid of items for accessibility
    /// - Parameters:
    ///   - gridView: The container view
    ///   - label: The grid label
    ///   - rowCount: Number of rows
    ///   - columnCount: Number of columns
    func configureGrid(_ gridView: NSView, label: String, rowCount: Int, columnCount: Int) {
        gridView.setAccessibilityLabel(label)
        gridView.setAccessibilityRole(.group)
        // Note: grid role and row/column count are iOS-specific
    }

    /// Configures a grid cell with proper accessibility
    /// - Parameters:
    ///   - cellView: The cell view
    ///   - label: The cell label
    ///   - row: The row index (0-based)
    ///   - column: The column index (0-based)
    ///   - isSelected: Whether the cell is selected
    func configureGridCell(_ cellView: NSView, label: String, row: Int, column: Int, isSelected: Bool = false) {
        cellView.setAccessibilityLabel(label)
        cellView.setAccessibilityRole(isSelected ? .radioButton : .button)
        // Store row/column in identifier for reference
        cellView.setAccessibilityIdentifier("cell_\(row)_\(column)")
    }

    // MARK: - Window Configuration

    /// Configures a window with proper accessibility
    /// - Parameters:
    ///   - window: The window to configure
    ///   - title: The window title
    func configureWindow(_ window: NSWindow, title: String) {
        window.setAccessibilityLabel(title)
        window.setAccessibilityRole(.window)
        window.title = title
    }

    // MARK: - Scroll View Configuration

    /// Configures a scroll view for accessibility
    /// - Parameter scrollView: The scroll view to configure
    func configureScrollView(_ scrollView: NSScrollView) {
        scrollView.setAccessibilityRole(.scrollArea)
        scrollView.setAccessibilityLabel("Scrollable content")
    }

    // MARK: - Status Announcements

    /// Announces a status change (e.g., permission granted/denied)
    /// - Parameters:
    ///   - status: The status message
    ///   - isImportant: Whether this is an important announcement
    func announceStatus(_ status: String, isImportant: Bool = false) {
        announce(status)
    }

    /// Announces a setting change
    /// - Parameters:
    ///   - setting: The setting name
    ///   - value: The new value
    func announceSettingChange(setting: String, value: String) {
        announce("\(setting) set to \(value)")
    }

    /// Announces an error message
    /// - Parameter error: The error message
    func announceError(_ error: String) {
        announce("Error: \(error)")
    }

    // MARK: - Helper Methods

    /// Checks if VoiceOver is currently running
    var isVoiceOverRunning: Bool {
        return NSWorkspace.shared.isVoiceOverEnabled
    }

    /// Checks if any accessibility features are enabled
    var isAccessibilityEnabled: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast ||
               NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency ||
               isVoiceOverRunning
    }
}

// MARK: - NSView Extensions for Accessibility

extension NSView {

    /// Makes the view and its subviews accessible
    func makeAccessible() {
        setAccessibilityEnabled(true)
    }

    /// Sets up a view as an accessibility element with common properties
    /// - Parameters:
    ///   - label: The accessibility label
    ///   - role: The accessibility role
    func setupAccessibility(label: String, role: NSAccessibility.Role) {
        setAccessibilityElement(true)
        setAccessibilityLabel(label)
        setAccessibilityRole(role)
    }
}

// MARK: - NSButton Extensions for Accessibility

extension NSButton {

    /// Configures button as a toggle with accessibility
    /// - Parameters:
    ///   - label: The accessibility label
    ///   - isOn: Current state
    ///   - hint: Optional hint
    func setupAsToggle(label: String, isOn: Bool, hint: String? = nil) {
        setAccessibilityLabel(label)
        setAccessibilityRole(.button)
        setAccessibilityValue(isOn ? "On" : "Off")

        if let hint = hint {
            toolTip = hint
        }
    }

    /// Updates toggle state accessibility
    /// - Parameter isOn: New state
    func updateToggleState(isOn: Bool) {
        setAccessibilityValue(isOn ? "On" : "Off")
    }
}
