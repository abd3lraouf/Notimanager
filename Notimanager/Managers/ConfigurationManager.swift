//
//  ConfigurationManager.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Centralized configuration management with UserDefaults persistence and change notifications
//

import AppKit
import Foundation
import Combine
import SwiftUI

/// Menu bar icon color options
enum IconColor: String, CaseIterable, Identifiable, Codable {
    case normal
    case green
    case blue
    case purple
    case orange
    case red
    case pink

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return "System (Adaptive)"
        case .green: return "Success Green"
        case .blue: return "Focus Blue"
        case .purple: return "Creative Purple"
        case .orange: return "Alert Orange"
        case .red: return "Urgent Red"
        case .pink: return "Vibrant Pink"
        }
    }

    var color: Color {
        switch self {
        case .normal: return .primary
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        }
    }

    var nsColor: NSColor {
        switch self {
        case .normal: return NSColor.labelColor
        case .green: return NSColor.systemGreen
        case .blue: return NSColor.systemBlue
        case .purple: return NSColor.systemPurple
        case .orange: return NSColor.systemOrange
        case .red: return NSColor.systemRed
        case .pink: return NSColor.systemPink
        }
    }
}

/// Manages application configuration settings with UserDefaults persistence and change notifications
@available(macOS 10.15, *)
class ConfigurationManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ConfigurationManager()

    private init() {
        // Set default values first
        currentPosition = .topRight
        isEnabled = true
        debugMode = true
        isMenuBarIconHidden = false
        openSettingsAtLaunch = true
        iconColor = .green
        interceptNotifications = true
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
        static let openSettingsAtLaunch = "openSettingsAtLaunch"
        static let iconColor = "iconColor"
        static let interceptNotifications = "interceptNotifications"
        static let interceptWidgets = "interceptWidgets"
        static let includeAppleWidgets = "includeAppleWidgets"
    }

    // MARK: - Properties

    /// Current notification position setting
    @Published var currentPosition: NotificationPosition {
        didSet {
            saveToStorage()
            notifyObservers(of: .positionChanged)
        }
    }

    /// Whether notification positioning is enabled
    @Published var isEnabled: Bool {
        didSet {
            saveToStorage()
            notifyObservers(of: .enabledChanged)
        }
    }

    /// Whether debug mode is enabled
    @Published var debugMode: Bool {
        didSet {
            LoggingService.shared.isDebugModeEnabled = debugMode
            // Automatically enable file logging when debug mode is enabled
            LoggingService.shared.isFileLoggingEnabled = debugMode
            saveToStorage()
            notifyObservers(of: .debugModeChanged)
        }
    }

    /// Whether the menu bar icon is hidden
    @Published var isMenuBarIconHidden: Bool {
        didSet {
            guard oldValue != isMenuBarIconHidden else { return }
            saveToStorage()
            notifyObservers(of: .menuBarIconChanged)
        }
    }

    /// Whether to open settings window at app launch
    @Published var openSettingsAtLaunch: Bool {
        didSet {
            saveToStorage()
        }
    }

    /// Menu bar icon color when enabled
    @Published var iconColor: IconColor = .green {
        didSet {
            saveToStorage()
        }
    }

    // MARK: - Interception Settings

    /// Whether to intercept normal notifications
    @Published var interceptNotifications: Bool {
        didSet {
            saveToStorage()
            notifyObservers(of: .interceptionChanged)
        }
    }

    /// Whether to intercept widgets
    @Published var interceptWidgets: Bool {
        didSet {
            saveToStorage()
            notifyObservers(of: .interceptionChanged)
        }
    }

    /// Whether to include Apple widgets when widget interception is enabled
    @Published var includeAppleWidgets: Bool {
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
        // Capture values on the current thread (likely Main) to avoid data races
        let position = currentPosition.rawValue
        let enabled = isEnabled
        let debug = debugMode
        let hidden = isMenuBarIconHidden
        let openSettings = openSettingsAtLaunch
        let iconColorVal = iconColor
        let interceptNotif = interceptNotifications
        let interceptWidget = interceptWidgets
        let includeApple = includeAppleWidgets

        // Perform I/O on background queue
        DispatchQueue.global(qos: .utility).async {
            UserDefaults.standard.set(position, forKey: Keys.notificationPosition)
            UserDefaults.standard.set(enabled, forKey: Keys.isEnabled)
            UserDefaults.standard.set(debug, forKey: Keys.debugMode)
            UserDefaults.standard.set(hidden, forKey: Keys.isMenuBarIconHidden)
            UserDefaults.standard.set(openSettings, forKey: Keys.openSettingsAtLaunch)
            if let iconColorData = try? JSONEncoder().encode(iconColorVal) {
                UserDefaults.standard.set(iconColorData, forKey: Keys.iconColor)
            }
            UserDefaults.standard.set(interceptNotif, forKey: Keys.interceptNotifications)
            UserDefaults.standard.set(interceptWidget, forKey: Keys.interceptWidgets)
            UserDefaults.standard.set(includeApple, forKey: Keys.includeAppleWidgets)
        }
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
        openSettingsAtLaunch = UserDefaults.standard.object(forKey: Keys.openSettingsAtLaunch) as? Bool ?? true
        if let iconColorData = UserDefaults.standard.data(forKey: Keys.iconColor),
           let decodedIconColor = try? JSONDecoder().decode(IconColor.self, from: iconColorData) {
            iconColor = decodedIconColor
        }
        interceptNotifications = UserDefaults.standard.object(forKey: Keys.interceptNotifications) as? Bool ?? true
        interceptWidgets = UserDefaults.standard.object(forKey: Keys.interceptWidgets) as? Bool ?? false
        includeAppleWidgets = UserDefaults.standard.object(forKey: Keys.includeAppleWidgets) as? Bool ?? false
    }

    /// Resets all settings to default values
    func resetToDefaults() {
        currentPosition = .topRight
        isEnabled = true
        debugMode = false
        isMenuBarIconHidden = false
        openSettingsAtLaunch = true
        iconColor = .green
        interceptNotifications = true
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
        var openSettingsAtLaunch: Bool
        var interceptNotifications: Bool
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
            openSettingsAtLaunch: openSettingsAtLaunch,
            interceptNotifications: interceptNotifications,
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
        openSettingsAtLaunch = state.openSettingsAtLaunch
        interceptNotifications = state.interceptNotifications
        interceptWidgets = state.interceptWidgets
        includeAppleWidgets = state.includeAppleWidgets
    }
}
