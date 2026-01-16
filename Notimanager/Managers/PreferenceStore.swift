//
//  PreferenceStore.swift
//  Notimanager
//
//  Created on 2025-01-16.
//  Generic, type-safe preference storage system following the Open/Closed Principle
//

import Foundation

// MARK: - Preference Key Protocol

/// A protocol that defines a preference with a key and default value.
/// Conforming types can be used with PreferenceStore for type-safe storage.
///
/// Example usage:
/// ```swift
/// enum AppPreferences {
///     static let notificationPosition = PreferenceKey<NotificationPosition>(
///         key: "notificationPosition",
///         defaultValue: .topRight
///     )
///
///     static let isEnabled = PreferenceKey<Bool>(
///         key: "isEnabled",
///         defaultValue: true
///     )
/// }
/// ```
public struct PreferenceKey<T>: Hashable {
    /// The UserDefaults key for this preference
    public let key: String

    /// The default value to use if no stored value exists
    public let defaultValue: T

    /// Creates a new preference key
    /// - Parameters:
    ///   - key: The UserDefaults key for storage
    ///   - defaultValue: The default value when no stored value exists
    public init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    // MARK: - Hashable & Equatable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    public static func == (lhs: PreferenceKey<T>, rhs: PreferenceKey<T>) -> Bool {
        return lhs.key == rhs.key
    }
}

// MARK: - Preference Change Event

/// Represents a change event for a preference
public struct PreferenceChangeEvent<T>: Hashable where T: Hashable {
    /// The preference key that changed
    public let key: PreferenceKey<T>

    /// The old value before the change
    public let oldValue: T

    /// The new value after the change
    public let newValue: T

    /// The timestamp of the change
    public let timestamp: Date

    public init(key: PreferenceKey<T>, oldValue: T, newValue: T, timestamp: Date = Date()) {
        self.key = key
        self.oldValue = oldValue
        self.newValue = newValue
        self.timestamp = timestamp
    }
}

// MARK: - Preference Observer Protocol

/// Protocol for observing preference changes
public protocol PreferenceObserver: AnyObject {
    /// Called when a preference changes
    /// - Parameter change: The change event containing key, old value, and new value
    func preferenceDidChange<T>(_ change: PreferenceChangeEvent<T>)
}

// MARK: - Preference Store

/// A generic, type-safe preference storage system that manages UserDefaults persistence.
/// Supports change observation via closures or NotificationCenter.
///
/// This design follows the Open/Closed Principle:
/// - Open for extension: Add new preferences by creating PreferenceKey instances
/// - Closed for modification: No need to modify PreferenceStore when adding preferences
///
/// Example usage:
/// ```swift
/// // Define preferences
/// enum Preferences {
///     static let notificationPosition = PreferenceKey<NotificationPosition>(
///         key: "notificationPosition",
///         defaultValue: .topRight
///     )
///     static let isEnabled = PreferenceKey<Bool>(
///         key: "isEnabled",
///         defaultValue: true
///     )
/// }
///
/// // Use the store
/// let store = PreferenceStore.shared
///
/// // Get a preference value
/// let position = store.get(Preferences.notificationPosition)
///
/// // Set a preference value
/// store.set(Preferences.notificationPosition, value: .bottomRight)
///
/// // Observe changes
/// store.observe(Preferences.notificationPosition) { change in
///     print("Position changed from \(change.oldValue) to \(change.newValue)")
/// }
/// ```
public class PreferenceStore {

    // MARK: - Singleton

    /// Shared singleton instance
    public static let shared = PreferenceStore()

    private init() {}

    // MARK: - UserDefaults

    /// The UserDefaults suite to use for storage
    /// Can be overridden for testing or custom storage
    public var userDefaults: UserDefaults = .standard

    // MARK: - Type Constraints

    /// Types that can be stored in UserDefaults directly
    private typealias UserDefaultsStorable = Codable & Equatable

    // MARK: - Observers

    private class ObserverBox {
        weak var observer: AnyObject?
        let closure: ((Any) -> Void)?

        init(observer: AnyObject? = nil, closure: ((Any) -> Void)? = nil) {
            self.observer = observer
            self.closure = closure
        }
    }

    /// Type-erased observers for all preferences
    private var observers: [String: ObserverBox] = [:]

    /// Lock for thread-safe observer access
    private let observersLock = NSLock()

    // MARK: - Notification Names

    /// Notification name posted when any preference changes
    /// The userInfo dictionary contains:
    /// - "key": The preference key as a String
    /// - "oldValue": The old value (if Equatable)
    /// - "newValue": The new value (if Equatable)
    public static let preferenceDidChangeNotification = Notification.Name("preferenceDidChangeNotification")

    // MARK: - Get/Set Operations

    /// Retrieves the current value for a preference key
    /// - Parameter key: The preference key to retrieve
    /// - Returns: The stored value, or the default value if not stored
    public func get<T>(_ key: PreferenceKey<T>) -> T where T: Codable {
        if let data = userDefaults.data(forKey: key.key),
           let value = try? JSONDecoder().decode(T.self, from: data) {
            return value
        }
        return key.defaultValue
    }

    /// Specialized getter for Bool types (stored directly in UserDefaults for efficiency)
    /// - Parameter key: The preference key to retrieve
    /// - Returns: The stored value, or the default value if not stored
    public func get(_ key: PreferenceKey<Bool>) -> Bool {
        if userDefaults.object(forKey: key.key) != nil {
            return userDefaults.bool(forKey: key.key)
        }
        return key.defaultValue
    }

    /// Specialized getter for Int types (stored directly in UserDefaults for efficiency)
    /// - Parameter key: The preference key to retrieve
    /// - Returns: The stored value, or the default value if not stored
    public func get(_ key: PreferenceKey<Int>) -> Int {
        if userDefaults.object(forKey: key.key) != nil {
            return userDefaults.integer(forKey: key.key)
        }
        return key.defaultValue
    }

    /// Specialized getter for Double types (stored directly in UserDefaults for efficiency)
    /// - Parameter key: The preference key to retrieve
    /// - Returns: The stored value, or the default value if not stored
    public func get(_ key: PreferenceKey<Double>) -> Double {
        if userDefaults.object(forKey: key.key) != nil {
            return userDefaults.double(forKey: key.key)
        }
        return key.defaultValue
    }

    /// Specialized getter for String types (stored directly in UserDefaults for efficiency)
    /// - Parameter key: The preference key to retrieve
    /// - Returns: The stored value, or the default value if not stored
    public func get(_ key: PreferenceKey<String>) -> String {
        if let value = userDefaults.string(forKey: key.key) {
            return value
        }
        return key.defaultValue
    }

    /// Stores a value for a preference key
    /// - Parameters:
    ///   - key: The preference key to store
    ///   - value: The value to store
    public func set<T>(_ key: PreferenceKey<T>, value: T) where T: Codable & Equatable & Hashable {
        let oldValue = get(key)

        // Only proceed if value actually changed
        if oldValue == value {
            return
        }

        // Store the value based on type
        if let boolValue = value as? Bool {
            userDefaults.set(boolValue, forKey: key.key)
        } else if let intValue = value as? Int {
            userDefaults.set(intValue, forKey: key.key)
        } else if let doubleValue = value as? Double {
            userDefaults.set(doubleValue, forKey: key.key)
        } else if let stringValue = value as? String {
            userDefaults.set(stringValue, forKey: key.key)
        } else {
            // For complex types, encode as JSON
            if let data = try? JSONEncoder().encode(value) {
                userDefaults.set(data, forKey: key.key)
            } else {
                assertionFailure("Failed to encode preference value for key: \(key.key)")
                return
            }
        }

        // Notify observers
        notifyObservers(key: key, oldValue: oldValue, newValue: value)

        // Post notification
        postNotification(key: key, oldValue: oldValue, newValue: value)
    }

    // MARK: - Observation

    /// Observes changes to a specific preference using a closure
    /// - Parameters:
    ///   - key: The preference key to observe
    ///   - observer: The observer object (kept weakly)
    ///   - handler: Closure called when the preference changes
    ///
    /// Example:
    /// ```swift
    /// store.observe(Preferences.notificationPosition) { change in
    ///     print("Position changed from \(change.oldValue) to \(change.newValue)")
    /// }
    /// ```
    public func observe<T>(
        _ key: PreferenceKey<T>,
        observer: AnyObject? = nil,
        handler: @escaping (PreferenceChangeEvent<T>) -> Void
    ) where T: Codable & Equatable & Hashable {
        observersLock.lock()
        defer { observersLock.unlock() }

        let box = ObserverBox(observer: observer) { [weak self] change in
            guard let self = self else { return }
            if let typedChange = change as? PreferenceChangeEvent<T> {
                handler(typedChange)
            }
        }
        observers[key.key] = box
    }

    /// Observes changes to a specific preference using the observer protocol
    /// - Parameters:
    ///   - key: The preference key to observe
    ///   - observer: The observer object
    public func observe<T>(_ key: PreferenceKey<T>, observer: PreferenceObserver) where T: Codable & Equatable & Hashable {
        observersLock.lock()
        defer { observersLock.unlock() }

        let box = ObserverBox(observer: observer) { change in
            if let typedChange = change as? PreferenceChangeEvent<T> {
                observer.preferenceDidChange(typedChange)
            }
        }
        observers[key.key] = box
    }

    /// Removes an observer for a specific preference
    /// - Parameter key: The preference key to stop observing
    public func removeObserver<T>(for key: PreferenceKey<T>) {
        observersLock.lock()
        defer { observersLock.unlock() }
        observers.removeValue(forKey: key.key)
    }

    /// Removes all observers for a specific observer object
    /// - Parameter observer: The observer to remove
    public func removeObserver(_ observer: AnyObject) {
        observersLock.lock()
        defer { observersLock.unlock() }

        observers = observers.filter { _, box in
            box.observer !== observer
        }
    }

    /// Removes all observers
    public func removeAllObservers() {
        observersLock.lock()
        defer { observersLock.unlock() }
        observers.removeAll()
    }

    // MARK: - Private Methods

    private func notifyObservers<T>(key: PreferenceKey<T>, oldValue: T, newValue: T) where T: Equatable & Hashable {
        observersLock.lock()
        let observersCopy = observers
        observersLock.unlock()

        let change = PreferenceChangeEvent(key: key, oldValue: oldValue, newValue: newValue)

        for (_, box) in observersCopy where box.observer != nil || box.closure != nil {
            box.closure?(change)
        }
    }

    private func postNotification<T>(key: PreferenceKey<T>, oldValue: T, newValue: T) where T: Equatable {
        var userInfo: [String: Any] = [
            "key": key.key,
            "oldValue": oldValue,
            "newValue": newValue
        ]

        NotificationCenter.default.post(
            name: Self.preferenceDidChangeNotification,
            object: self,
            userInfo: userInfo
        )
    }

    // MARK: - Batch Operations

    /// Resets a preference to its default value
    /// - Parameter key: The preference key to reset
    public func reset<T>(_ key: PreferenceKey<T>) where T: Codable & Equatable & Hashable {
        let currentValue = get(key)
        if currentValue != key.defaultValue {
            set(key, value: key.defaultValue)
        } else {
            userDefaults.removeObject(forKey: key.key)
        }
    }

    /// Resets all preferences to their default values
    /// Note: This only resets preferences that have been accessed or set
    public func resetAll() {
        let domain = Bundle.main.bundleIdentifier ?? "com.example.app"
        userDefaults.removePersistentDomain(forName: domain)
        userDefaults.synchronize()

        // Notify all observers with a special "reset" event
        // (This is a simplified approach; you might want more sophisticated reset handling)
    }

    /// Clears all stored preferences
    public func clearAll() {
        let domain = Bundle.main.bundleIdentifier ?? "com.example.app"
        userDefaults.removePersistentDomain(forName: domain)
        userDefaults.synchronize()
    }

    // MARK: - Export/Import

    /// Exports all preferences as a dictionary
    /// - Returns: Dictionary containing all stored preferences
    public func exportAll() -> [String: Any] {
        return userDefaults.dictionaryRepresentation()
    }

    /// Imports preferences from a dictionary
    /// - Parameter dictionary: Dictionary containing preferences to import
    public func `import`(from dictionary: [String: Any]) {
        for (key, value) in dictionary {
            userDefaults.set(value, forKey: key)
        }
        userDefaults.synchronize()
    }
}

// MARK: - Convenience Extensions

extension PreferenceStore {

    /// Checks if a preference has a non-default value
    /// - Parameter key: The preference key to check
    /// - Returns: True if the preference has been explicitly set
    public func hasCustomValue<T>(_ key: PreferenceKey<T>) -> Bool where T: Codable & Equatable & Hashable {
        return userDefaults.object(forKey: key.key) != nil
    }

    /// Gets the default value for a preference key
    /// - Parameter key: The preference key
    /// - Returns: The default value
    public func defaultValue<T>(_ key: PreferenceKey<T>) -> T {
        return key.defaultValue
    }

    /// Resets a preference if it has a custom value
    /// - Parameter key: The preference key to reset
    /// - Returns: True if the preference was reset, false if it was already at default
    @discardableResult
    public func resetIfNeeded<T>(_ key: PreferenceKey<T>) -> Bool where T: Codable & Equatable & Hashable {
        if hasCustomValue(key) {
            reset(key)
            return true
        }
        return false
    }
}
