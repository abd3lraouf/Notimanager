//
//  AppKitMenuBarManager.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Pure AppKit implementation of menu bar with NSMenu to fix SwiftUI submenu bugs.
//

import AppKit
import Combine

/// Manages the menu bar using pure AppKit NSMenu instead of SwiftUI MenuBarExtra.
/// This fixes the nested submenu bug where SwiftUI Menu components don't open properly.
@available(macOS 10.15, *)
class AppKitMenuBarManager: NSObject {

    static let shared = AppKitMenuBarManager()

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    // Menu item references for updating state
    private var enableToggleItem: NSMenuItem?
    private var positionMenuItem: NSMenuItem?
    private var positionSubmenuItems: [NotificationPosition: NSMenuItem] = [:]

    // MARK: - Initialization

    private override init() {
        super.init()
        setupMenuBar()
        setupObservers()
    }

    // MARK: - Setup

    private func setupMenuBar() {
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Initial icon update will happen through observers
        updateIcon()

        // Build the menu
        buildMenu()
    }

    private func buildMenu() {
        guard let statusItem = statusItem else { return }

        let menu = NSMenu()

        // Enable Toggle
        enableToggleItem = NSMenuItem(
            title: "Enable Positioning",
            action: #selector(toggleEnabled),
            keyEquivalent: "e"
        )
        enableToggleItem?.target = self
        enableToggleItem?.state = ConfigurationManager.shared.isEnabled ? .on : .off
        menu.addItem(enableToggleItem!)

        // Divider
        menu.addItem(NSMenuItem.separator())

        // Screen Corner Submenu
        positionMenuItem = NSMenuItem(
            title: "Screen Corner",
            action: nil,
            keyEquivalent: ""
        )
        positionMenuItem?.target = self

        // Create submenu with position options
        let positionMenu = NSMenu()
        for position in NotificationPosition.allCases {
            let item = NSMenuItem(
                title: position.displayName,
                action: #selector(changePosition(_:)),
                keyEquivalent: ""
            )
            item.tag = positionHash(position)
            item.target = self
            item.state = (position == ConfigurationManager.shared.currentPosition) ? .on : .off
            positionSubmenuItems[position] = item
            positionMenu.addItem(item)
        }

        positionMenuItem?.submenu = positionMenu
        menu.addItem(positionMenuItem!)

        // Divider
        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        // Check for Updates
        let updatesItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updatesItem.target = self
        menu.addItem(updatesItem)

        // Divider
        menu.addItem(NSMenuItem.separator())

        // About
        let aboutItem = NSMenuItem(
            title: "About Notimanager",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Notimanager",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func setupObservers() {
        // Observe enabled state
        ConfigurationManager.shared.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.updateEnabledState(isEnabled)
            }
            .store(in: &cancellables)

        // Observe position changes
        ConfigurationManager.shared.$currentPosition
            .receive(on: DispatchQueue.main)
            .sink { [weak self] position in
                self?.updatePositionState(position)
                self?.updateIcon()
                self?.updatePositionMenuItemTitle(position)
            }
            .store(in: &cancellables)

        // Observe icon color changes
        ConfigurationManager.shared.$iconColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)

        // Observe menu bar visibility
        ConfigurationManager.shared.$isMenuBarIconHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isHidden in
                self?.updateVisibility(isHidden)
            }
            .store(in: &cancellables)
    }

    // MARK: - UI Updates

    private func updateIcon() {
        guard let statusItem = statusItem, let button = statusItem.button else { return }

        let position = ConfigurationManager.shared.currentPosition
        let iconColor = ConfigurationManager.shared.iconColor

        // Build icon name based on position and enabled state
        let baseIconName = "MenuBarIcon-" + position.iconName
        let isEnabled = ConfigurationManager.shared.isEnabled

        // If disabled, use the disabled icon variant
        let iconName = isEnabled ? baseIconName : "MenuBarIcon-disabled"

        if let image = NSImage(named: iconName) {
            switch iconColor {
            case .normal:
                button.image = image
                // Use template rendering for system adaptive color
                button.image?.isTemplate = true
            default:
                // Apply custom tint
                let tintedImage = image.tinted(color: iconColor.nsColor)
                button.image = tintedImage
                button.image?.isTemplate = false
            }
        }
    }

    private func updateEnabledState(_ isEnabled: Bool) {
        enableToggleItem?.state = isEnabled ? .on : .off
        updateIcon()
    }

    private func updatePositionState(_ position: NotificationPosition) {
        // Update checkmarks in submenu
        for (pos, item) in positionSubmenuItems {
            item.state = (pos == position) ? .on : .off
        }
    }

    private func updatePositionMenuItemTitle(_ position: NotificationPosition) {
        // Update the submenu title to show current position
        positionMenuItem?.title = "Screen Corner"
    }

    private func updateVisibility(_ isHidden: Bool) {
        if isHidden {
            statusItem?.isVisible = false
        } else {
            statusItem?.isVisible = true
            updateIcon()
        }
    }

    // MARK: - Menu Actions

    @objc private func toggleEnabled() {
        let newState = !ConfigurationManager.shared.isEnabled
        ConfigurationManager.shared.isEnabled = newState
    }

    @objc private func changePosition(_ sender: NSMenuItem) {
        // Find position by tag
        for position in NotificationPosition.allCases {
            if sender.tag == positionHash(position) {
                ConfigurationManager.shared.currentPosition = position
                break
            }
        }
    }

    @objc private func openPreferences() {
        // Use SettingsOpener to open Settings with @Environment(\.openSettings)
        if #available(macOS 14.0, *) {
            SettingsOpener.shared.openSettings(tab: "general")
        } else {
            // Fallback for older macOS versions
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func checkForUpdates() {
        AppStore.shared.dispatch(.checkForUpdates)
    }

    @objc private func showAbout() {
        // Use SettingsOpener to open Settings with @Environment(\.openSettings)
        if #available(macOS 14.0, *) {
            SettingsOpener.shared.openSettings(tab: "help")
        } else {
            // Fallback for older macOS versions
            NSApp.orderFrontStandardAboutPanel(options: [:])
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Helpers

    private func positionHash(_ position: NotificationPosition) -> Int {
        return position.rawValue.hashValue
    }
}
