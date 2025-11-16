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

/// Manages the menu bar icon and menu
@available(macOS 10.15, *)
class MenuBarManager {

    // MARK: - Properties

    private weak var coordinator: CoordinatorAction?
    private var statusItem: NSStatusItem?

    // MARK: - Initialization

    init(coordinator: CoordinatorAction? = nil) {
        self.coordinator = coordinator
    }

    /// Sets the coordinator for actions
    /// - Parameter coordinator: The coordinator instance
    func setCoordinator(_ coordinator: CoordinatorAction?) {
        self.coordinator = coordinator
    }

    // MARK: - Setup

    /// Sets up the menu bar icon and menu
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.action = #selector(menuBarButtonClicked)
            button.target = self
        }

        buildMenu()
    }

    /// Removes the menu bar icon
    func teardown() {
        statusItem = nil
    }

    /// Rebuilds the menu (e.g., after configuration change)
    func rebuildMenu() {
        buildMenu()
    }

    // MARK: - Menu Building

    private func buildMenu() {
        guard let coordinator = coordinator else { return }

        let menu = NSMenu()

        // Header
        menu.addItem(NSMenuItem.sectionHeader(title: "Notimanager"))
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
        launchItem.state = isLaunchAgentEnabled() ? .on : .off
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

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func menuBarButtonClicked() {
        // Menu is shown automatically via statusItem.menu
    }

    @objc private func showSettings() {
        coordinator?.showSettings()
        rebuildMenu()
    }

    @objc private func toggleEnabled() {
        coordinator?.toggleEnabled()
        rebuildMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        coordinator?.toggleLaunchAtLogin()
        rebuildMenu()
    }

    @objc private func sendTestNotification() {
        coordinator?.sendTestNotification()
    }

    @objc private func quit() {
        coordinator?.quit()
    }

    // MARK: - Helpers

    private func isLaunchAgentEnabled() -> Bool {
        // Delegate to LaunchAgentManager
        // For now, check if plist exists
        guard let coordinator = coordinator else { return false }
        return FileManager.default.fileExists(atPath: coordinator.launchAgentPlistPath)
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
