//
//  ConfigurationManager.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Centralized configuration management with change notifications
//

import AppKit
import Foundation

/// Manages application configuration settings with UserDefaults persistence and change notifications
@available(macOS 10.15, *)
class ConfigurationManager {

    // MARK: - Singleton

    static let shared = ConfigurationManager()

    private init() {
        // Set default values first
        currentPosition = .topRight
        isEnabled = true
        debugMode = false
        isMenuBarIconHidden = false
        // Then load from storage (which will override defaults if values exist)
        loadFromStorage()
    }

    // MARK: - Keys

    private enum Keys {
        static let notificationPosition = "notificationPosition"
        static let isEnabled = "isEnabled"
        static let debugMode = "debugMode"
        static let isMenuBarIconHidden = "isMenuBarIconHidden"
        static let launchAgentPlistPath = NSHomeDirectory() + "/Library/LaunchAgents/dev.abd3lraouf.notimanager.plist"
    }

    // MARK: - Properties

    /// Current notification position setting
    var currentPosition: NotificationPosition {
        didSet {
            saveToStorage()
            notifyObservers(of: .positionChanged)
        }
    }

    /// Whether notification positioning is enabled
    var isEnabled: Bool {
        didSet {
            saveToStorage()
            notifyObservers(of: .enabledChanged)
        }
    }

    /// Whether debug mode is enabled
    var debugMode: Bool {
        didSet {
            LoggingService.shared.isDebugModeEnabled = debugMode
            saveToStorage()
            notifyObservers(of: .debugModeChanged)
        }
    }

    /// Whether the menu bar icon is hidden
    var isMenuBarIconHidden: Bool {
        didSet {
            saveToStorage()
            notifyObservers(of: .menuBarIconChanged)
        }
    }

    /// Path to the launch agent plist file
    var launchAgentPlistPath: String {
        return Keys.launchAgentPlistPath
    }

    // MARK: - Change Observers

    private var observers: [ConfigurationObserver] = []

    /// Configuration change events
    enum ConfigurationEvent {
        case positionChanged
        case enabledChanged
        case debugModeChanged
        case menuBarIconChanged
        case reset
    }

    /// Protocol for configuration change observers
    protocol ConfigurationObserver: AnyObject {
        func configurationDidChange(_ event: ConfigurationManager.ConfigurationEvent)
    }

    /// Adds an observer for configuration changes
    /// - Parameter observer: The observer to add
    func addObserver(_ observer: ConfigurationObserver) {
        observers.append(observer)
    }

    /// Removes an observer
    /// - Parameter observer: The observer to remove
    func removeObserver(_ observer: ConfigurationObserver) {
        observers.removeAll { $0 === observer }
    }

    private func notifyObservers(of event: ConfigurationEvent) {
        observers.forEach { observer in
            observer.configurationDidChange(event)
        }
    }

    // MARK: - Persistence

    /// Saves current configuration to UserDefaults
    func saveToStorage() {
        UserDefaults.standard.set(currentPosition.rawValue, forKey: Keys.notificationPosition)
        UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled)
        UserDefaults.standard.set(debugMode, forKey: Keys.debugMode)
        UserDefaults.standard.set(isMenuBarIconHidden, forKey: Keys.isMenuBarIconHidden)
    }

    /// Loads configuration from UserDefaults
    func loadFromStorage() {
        if let positionString = UserDefaults.standard.string(forKey: Keys.notificationPosition),
           let position = NotificationPosition(rawValue: positionString) {
            currentPosition = position
        } else {
            currentPosition = .topRight
        }

        isEnabled = UserDefaults.standard.object(forKey: Keys.isEnabled) as? Bool ?? true
        debugMode = UserDefaults.standard.bool(forKey: Keys.debugMode)
        isMenuBarIconHidden = UserDefaults.standard.bool(forKey: Keys.isMenuBarIconHidden)
    }

    /// Resets all settings to default values
    func resetToDefaults() {
        currentPosition = .topRight
        isEnabled = true
        debugMode = false
        isMenuBarIconHidden = false
        saveToStorage()
        notifyObservers(of: .reset)
    }
}

// MARK: - Configuration State

extension ConfigurationManager {

    /// Represents the complete configuration state
    struct ConfigurationState: Codable {
        var notificationPosition: NotificationPosition
        var isEnabled: Bool
        var debugMode: Bool
        var isMenuBarIconHidden: Bool
    }

    /// Current configuration state
    var currentState: ConfigurationState {
        return ConfigurationState(
            notificationPosition: currentPosition,
            isEnabled: isEnabled,
            debugMode: debugMode,
            isMenuBarIconHidden: isMenuBarIconHidden
        )
    }

    /// Applies a configuration state
    /// - Parameter state: The state to apply
    func applyState(_ state: ConfigurationState) {
        currentPosition = state.notificationPosition
        isEnabled = state.isEnabled
        debugMode = state.debugMode
        isMenuBarIconHidden = state.isMenuBarIconHidden
    }
}
