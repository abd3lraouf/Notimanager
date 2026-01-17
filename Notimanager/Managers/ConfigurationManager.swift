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
        interceptNotifications = true
        interceptWindowPopups = false
        interceptWidgets = false
        includeAppleWidgets = false
        // Then load from storage (which will override defaults if values exist)
        loadFromStorage()
    }

    // MARK: - Keys

    private enum Keys {
        static let notificationPosition = "notificationPosition"
        static let isEnabled = "isEnabled"
        static let debugMode = "debugMode"
        static let isMenuBarIconHidden = "isMenuBarIconHidden"
        static let interceptNotifications = "interceptNotifications"
        static let interceptWindowPopups = "interceptWindowPopups"
        static let interceptWidgets = "interceptWidgets"
        static let includeAppleWidgets = "includeAppleWidgets"
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

    // MARK: - Interception Settings

    /// Whether to intercept normal notifications
    var interceptNotifications: Bool {
        didSet {
            saveToStorage()
            notifyObservers(of: .interceptionChanged)
        }
    }

    /// Whether to intercept window popups
    var interceptWindowPopups: Bool {
        didSet {
            saveToStorage()
            notifyObservers(of: .interceptionChanged)
        }
    }

    /// Whether to intercept widgets
    var interceptWidgets: Bool {
        didSet {
            saveToStorage()
            notifyObservers(of: .interceptionChanged)
        }
    }

    /// Whether to include Apple widgets when widget interception is enabled
    var includeAppleWidgets: Bool {
        didSet {
            saveToStorage()
            notifyObservers(of: .interceptionChanged)
        }
    }

    // MARK: - Change Observers

    private var observers: [ConfigurationObserver] = []

    /// Configuration change events
    enum ConfigurationEvent {
        case positionChanged
        case enabledChanged
        case debugModeChanged
        case menuBarIconChanged
        case interceptionChanged
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
        UserDefaults.standard.set(interceptNotifications, forKey: Keys.interceptNotifications)
        UserDefaults.standard.set(interceptWindowPopups, forKey: Keys.interceptWindowPopups)
        UserDefaults.standard.set(interceptWidgets, forKey: Keys.interceptWidgets)
        UserDefaults.standard.set(includeAppleWidgets, forKey: Keys.includeAppleWidgets)
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
        interceptNotifications = UserDefaults.standard.object(forKey: Keys.interceptNotifications) as? Bool ?? true
        interceptWindowPopups = UserDefaults.standard.bool(forKey: Keys.interceptWindowPopups)
        interceptWidgets = UserDefaults.standard.bool(forKey: Keys.interceptWidgets)
        includeAppleWidgets = UserDefaults.standard.bool(forKey: Keys.includeAppleWidgets)
    }

    /// Resets all settings to default values
    func resetToDefaults() {
        currentPosition = .topRight
        isEnabled = true
        debugMode = false
        isMenuBarIconHidden = false
        interceptNotifications = true
        interceptWindowPopups = false
        interceptWidgets = false
        includeAppleWidgets = false
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
        var interceptNotifications: Bool
        var interceptWindowPopups: Bool
        var interceptWidgets: Bool
        var includeAppleWidgets: Bool
    }

    /// Current configuration state
    var currentState: ConfigurationState {
        return ConfigurationState(
            notificationPosition: currentPosition,
            isEnabled: isEnabled,
            debugMode: debugMode,
            isMenuBarIconHidden: isMenuBarIconHidden,
            interceptNotifications: interceptNotifications,
            interceptWindowPopups: interceptWindowPopups,
            interceptWidgets: interceptWidgets,
            includeAppleWidgets: includeAppleWidgets
        )
    }

    /// Applies a configuration state
    /// - Parameter state: The state to apply
    func applyState(_ state: ConfigurationState) {
        currentPosition = state.notificationPosition
        isEnabled = state.isEnabled
        debugMode = state.debugMode
        isMenuBarIconHidden = state.isMenuBarIconHidden
        interceptNotifications = state.interceptNotifications
        interceptWindowPopups = state.interceptWindowPopups
        interceptWidgets = state.interceptWidgets
        includeAppleWidgets = state.includeAppleWidgets
    }
}
