//
//  MenuBarManager.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Manages the menu bar icon and menu.
//  Extracted from NotificationMoverCoordinator to separate concerns.
//

import AppKit
import Foundation
import LaunchAtLogin

/// Manages the menu bar icon and menu
@available(macOS 10.15, *)
class MenuBarManager: NSObject {

    // MARK: - Properties

    private weak var coordinator: CoordinatorAction?
    private var statusItem: NSStatusItem?
    private var theMenu: NSMenu?

    /// Whether the menu bar icon is visible
    var isVisible: Bool = true {
        didSet {
            if isVisible != oldValue {
                displayStatusIcon()
            }
        }
    }

    // MARK: - Initialization

    init(coordinator: CoordinatorAction? = nil) {
        self.coordinator = coordinator
        super.init()
    }

    deinit {
        teardown()
    }

    /// Sets the coordinator for actions
    /// - Parameter coordinator: The coordinator instance
    func setCoordinator(_ coordinator: CoordinatorAction?) {
        self.coordinator = coordinator
    }

    // MARK: - Setup

    /// Sets up the menu bar icon and menu
    func setup() {
        displayStatusIcon()
    }

    /// Removes the menu bar icon
    func teardown() {
        removeStatusIcon()
    }

    /// Rebuilds the menu (e.g., after configuration change)
    func rebuildMenu() {
        updateButtonIcon()
        buildMenu()
    }

    // MARK: - Icon Updates

    /// Updates the menu bar icon based on current state
    private func updateButtonIcon() {
        guard let button = statusItem?.button,
              let coordinator = coordinator else { return }

        let iconName: String
        if !coordinator.isEnabled {
            iconName = "MenuBarIcon-disabled"
        } else {
            // Use position-specific icon based on current position
            iconName = "MenuBarIcon-" + coordinator.currentPosition.iconName
        }

        button.image = NSImage(named: iconName)
        button.image?.isTemplate = true
    }

    // MARK: - Status Item Management

    /// Adds the status icon to the menu bar
    private func addStatusIcon() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.action = #selector(menuBarButtonClicked)
            button.target = self
            updateButtonIcon()
        }

        buildMenu()
    }

    /// Removes the status icon from the menu bar
    private func removeStatusIcon() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
    }

    /// Displays or hides the status icon based on isVisible property
    private func displayStatusIcon() {
        if isVisible {
            addStatusIcon()
        } else {
            removeStatusIcon()
        }
    }

    // MARK: - Menu Building

    private func buildMenu() {
        guard let coordinator = coordinator else { return }

        let menu = NSMenu()

        // Header
        menu.addItem(NSMenuItem.sectionHeader(title: "Notimanager"))
        menu.addItem(NSMenuItem.separator())

        // Position submenu
        let positionMenuItem = NSMenuItem(
            title: "Position",
            action: nil,
            keyEquivalent: ""
        )
        positionMenuItem.target = self

        let positionMenu = buildPositionMenu()
        positionMenuItem.submenu = positionMenu
        menu.addItem(positionMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Enable Toggle
        let enabledItem = NSMenuItem(
            title: "Enable Notification Positioning",
            action: #selector(toggleEnabled),
            keyEquivalent: "e"
        )
        enabledItem.target = self
        enabledItem.state = coordinator.isEnabled ? .on : .off
        menu.addItem(enabledItem)

        // Launch at Login
        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: "l"
        )
        launchItem.target = self
        launchItem.state = isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        // Test Notification
        let testItem = NSMenuItem(
            title: "Send Test Notification",
            action: #selector(sendTestNotification),
            keyEquivalent: "t"
        )
        testItem.target = self
        menu.addItem(testItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Notimanager",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        theMenu = menu
        statusItem?.menu = menu
    }

    /// Attach a menu to the status item
    func attachMenu(_ menu: NSMenu) {
        theMenu = menu
        if let statusItem = statusItem {
            statusItem.menu = menu
        }
    }

    /// Open the status item menu
    func openMenu() {
        guard let statusItem = statusItem,
              let button = statusItem.button else { return }

        // Temporarily set the menu
        statusItem.menu = theMenu

        // Perform a click to show the menu
        button.performClick(nil)

        // Clear the menu so target/action works
        statusItem.menu = nil
    }

    private func buildPositionMenu() -> NSMenu {
        guard let coordinator = coordinator else { return NSMenu() }

        let menu = NSMenu()

        // Add only the 4 corner positions (matching the 2x2 grid in PositionGridView)
        let positions: [NotificationPosition] = [
            .topLeft, .topRight,
            .bottomLeft, .bottomRight
        ]

        for position in positions {
            let item = NSMenuItem(
                title: position.displayName,
                action: #selector(changePosition(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = position

            // Check mark for current position
            if position == coordinator.currentPosition {
                item.state = .on
            }

            menu.addItem(item)
        }

        return menu
    }

    // MARK: - Actions

    /// Checks if launch at login is enabled using LaunchAtLogin library
    private var isLaunchAtLoginEnabled: Bool {
        if #available(macOS 13.0, *) {
            return LaunchAtLogin.isEnabled
        }
        // No fallback for macOS < 13.0 - LaunchAtLogin package requires macOS 13+
        return false
    }

    @objc private func menuBarButtonClicked() {
        // Menu is shown automatically via statusItem.menu
    }

    @objc private func showSettings() {
        coordinator?.showSettings()
        rebuildMenu()
    }

    @objc private func changePosition(_ sender: NSMenuItem) {
        guard let position = sender.representedObject as? NotificationPosition else { return }
        coordinator?.updatePosition(to: position)
        rebuildMenu()
    }

    @objc private func toggleEnabled() {
        coordinator?.toggleEnabled()
        rebuildMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            LaunchAtLogin.isEnabled.toggle()
            rebuildMenu()
        }
        // Note: No fallback for macOS < 13.0 as LaunchAtLogin package requires macOS 13+
    }

    @objc private func sendTestNotification() {
        coordinator?.sendTestNotification()
    }

    @objc private func quit() {
        coordinator?.quit()
    }
}

// MARK: - NSMenuItem Extensions

extension NSMenuItem {
    /// Creates a section header menu item (disabled, no action)
    static func sectionHeader(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
