# NotificationMover Architecture - Domain Models (Agent 2A)

## Overview

This document defines the core domain models and protocols for the refactored NotificationMover system. These models represent the foundational abstractions that will be used across all layers of the application.

## 1. Protocol Definitions

### 1.1 NotificationPositioning Protocol

```swift
/// Defines the contract for notification positioning operations
protocol NotificationPositioning {
    /// Calculates the target position for a notification based on current settings
    /// - Parameters:
    ///   - notifSize: The size of the notification to position
    ///   - screenBounds: The screen bounds to position within
    ///   - position: The desired position enum
    /// - Returns: A CGPoint representing the target position
    func calculatePosition(
        notifSize: CGSize,
        screenBounds: CGRect,
        position: NotificationPosition
    ) -> CGPoint

    /// Validates if a position is within screen bounds
    /// - Parameters:
    ///   - position: The position to validate
    ///   - notifSize: The notification size
    ///   - screenBounds: The screen bounds
    /// - Returns: True if the position is valid
    func validatePosition(
        _ position: CGPoint,
        for notifSize: CGSize,
        in screenBounds: CGRect
    ) -> Bool

    /// Applies a position to a notification element
    /// - Parameters:
    ///   - element: The AXUIElement to position
    ///   - position: The target position
    /// - Returns: Success status
    func applyPosition(to element: AXUIElement, at position: CGPoint) -> Bool
}
```

### 1.2 NotificationWindowTracker Protocol

```swift
/// Defines the contract for tracking notification windows
protocol NotificationWindowTracker {
    /// Starts monitoring for notification windows
    func startMonitoring()

    /// Stops monitoring for notification windows
    func stopMonitoring()

    /// Returns all currently tracked notification windows
    /// - Returns: Array of tracked notification windows
    func getTrackedWindows() -> [NotificationWindow]

    /// Registers a callback for when new notifications are detected
    /// - Parameter callback: Closure to execute when a new notification is found
    func onNotificationDetected(_ callback: @escaping (NotificationWindow) -> Void)

    /// Registers a callback for when notifications are dismissed
    /// - Parameter callback: Closure to execute when a notification is dismissed
    func onNotificationDismissed(_ callback: @escaping (NotificationWindow) -> Void)
}
```

### 1.3 AccessibilityElementHandler Protocol

```swift
/// Defines the contract for handling Accessibility API elements
protocol AccessibilityElementHandler {
    /// Finds a notification element within a window
    /// - Parameter window: The window to search within
    /// - Returns: The found notification element, if any
    func findNotificationElement(in window: AXUIElement) -> AXUIElement?

    /// Gets the position of an accessibility element
    /// - Parameter element: The element to query
    /// - Returns: The element's position, if successful
    func getPosition(of element: AXUIElement) -> CGPoint?

    /// Sets the position of an accessibility element
    /// - Parameters:
    ///   - element: The element to modify
    ///   - position: The new position
    /// - Returns: Success status
    func setPosition(of element: AXUIElement, to position: CGPoint) -> Bool

    /// Gets the size of an accessibility element
    /// - Parameter element: The element to query
    /// - Returns: The element's size, if successful
    func getSize(of element: AXUIElement) -> CGSize?

    /// Checks if an attribute is settable on an element
    /// - Parameters:
    ///   - element: The element to check
    ///   - attribute: The attribute name
    /// - Returns: True if the attribute is settable
    func isAttributeSettable(
        _ attribute: String,
        on element: AXUIElement
    ) -> Bool
}
```

### 1.4 ConfigurationManager Protocol

```swift
/// Defines the contract for managing application configuration
protocol ConfigurationManager {
    /// Gets the current notification position setting
    var currentPosition: NotificationPosition { get set }

    /// Gets whether notification positioning is enabled
    var isEnabled: Bool { get set }

    /// Gets whether debug mode is enabled
    var debugMode: Bool { get set }

    /// Gets whether the menu bar icon is hidden
    var isMenuBarIconHidden: Bool { get set }

    /// Gets the launch agent plist path
    var launchAgentPlistPath: String { get }

    /// Saves the current configuration to persistent storage
    func save()

    /// Loads configuration from persistent storage
    func load()

    /// Resets configuration to default values
    func resetToDefaults()

    /// Registers a callback for configuration changes
    /// - Parameter callback: Closure to execute when configuration changes
    func onConfigurationChanged(_ callback: @escaping () -> Void)
}
```

## 2. Data Model Definitions

### 2.1 NotificationPosition Enum

```swift
/// Represents the possible positions for notifications on screen
enum NotificationPosition: String, CaseIterable, Codable {
    case topLeft = "top-left"
    case topMiddle = "top-middle"
    case topRight = "top-right"
    case middleLeft = "middle-left"
    case deadCenter = "dead-center"
    case middleRight = "middle-right"
    case bottomLeft = "bottom-left"
    case bottomMiddle = "bottom-middle"
    case bottomRight = "bottom-right"

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topMiddle: return "Top Middle"
        case .topRight: return "Top Right"
        case .middleLeft: return "Middle Left"
        case .deadCenter: return "Center"
        case .middleRight: return "Middle Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomMiddle: return "Bottom Middle"
        case .bottomRight: return "Bottom Right"
        }
    }

    /// SF Symbol icon name for this position
    var iconName: String {
        switch self {
        case .topLeft: return "arrow.up.left"
        case .topMiddle: return "arrow.up"
        case .topRight: return "arrow.up.right"
        case .middleLeft: return "arrow.left"
        case .deadCenter: return "circle.fill"
        case .middleRight: return "arrow.right"
        case .bottomLeft: return "arrow.down.left"
        case .bottomMiddle: return "arrow.down"
        case .bottomRight: return "arrow.down.right"
        }
    }

    /// Grid position for UI (row, col) in 3x3 grid
    var gridPosition: (row: Int, col: Int) {
        switch self {
        case .topLeft: return (0, 0)
        case .topMiddle: return (0, 1)
        case .topRight: return (0, 2)
        case .middleLeft: return (1, 0)
        case .deadCenter: return (1, 1)
        case .middleRight: return (1, 2)
        case .bottomLeft: return (2, 0)
        case .bottomMiddle: return (2, 1)
        case .bottomRight: return (2, 2)
        }
    }
}
```

### 2.2 NotificationWindow Model

```swift
/// Represents a tracked notification window
struct NotificationWindow: Identifiable, Equatable {
    /// Unique identifier for this window
    let id: String

    /// The underlying AXUIElement
    let axElement: AXUIElement

    /// Window position
    var position: CGPoint

    /// Window size
    var size: CGSize

    /// Process ID of the owning application
    let processID: pid_t

    /// Bundle identifier of the owning application
    let bundleIdentifier: String

    /// When this window was first detected
    let detectionTime: Date

    /// Last time this window was updated
    var lastUpdateTime: Date

    /// Whether this is a NotificationCenter system notification
    let isSystemNotification: Bool

    /// The notification subrole, if any
    let subrole: String?

    /// Whether this window has been successfully moved
    var hasBeenMoved: Bool

    /// Initial position before any moves
    let initialPosition: CGPoint?

    static func == (lhs: NotificationWindow, rhs: NotificationWindow) -> Bool {
        lhs.id == rhs.id
    }
}
```

### 2.3 NotificationMovementState Model

```swift
/// Represents the state of notification movement tracking
struct NotificationMovementState {
    /// Current positioning state
    enum PositioningState {
        case idle
        case positioning
        case polling
        case complete
        case failed(Error)
    }

    /// The current state of the positioning system
    var currentState: PositioningState

    /// Currently active notification windows
    var activeWindows: [NotificationWindow]

    /// Cached initial notification size
    var cachedNotificationSize: CGSize?

    /// Cached initial padding value
    var cachedPadding: CGFloat?

    /// Cached initial window position
    var cachedWindowPosition: CGPoint?

    /// Timestamp when polling should end
    var pollingEndTime: Date?

    /// Whether a test notification was intercepted
    var testNotificationIntercepted: Bool

    /// Last notification time (for test tracking)
    var lastNotificationTime: Date?

    /// Creates a new default state
    static func initial() -> NotificationMovementState {
        return NotificationMovementState(
            currentState: .idle,
            activeWindows: [],
            cachedNotificationSize: nil,
            cachedPadding: nil,
            cachedWindowPosition: nil,
            pollingEndTime: nil,
            testNotificationIntercepted: false,
            lastNotificationTime: nil
        )
    }
}
```

### 2.4 ConfigurationSettings Model

```swift
/// Represents application configuration settings
struct ConfigurationSettings: Codable {
    /// Current notification position
    var notificationPosition: NotificationPosition

    /// Whether notification positioning is enabled
    var isEnabled: Bool

    /// Whether debug mode is enabled
    var debugMode: Bool

    /// Whether menu bar icon is hidden
    var isMenuBarIconHidden: Bool

    /// Default configuration
    static let `default` = ConfigurationSettings(
        notificationPosition: .topMiddle,
        isEnabled: true,
        debugMode: false,
        isMenuBarIconHidden: false
    )

    /// UserDefaults keys
    enum Keys {
        static let notificationPosition = "notificationPosition"
        static let isEnabled = "isEnabled"
        static let debugMode = "debugMode"
        static let isMenuBarIconHidden = "isMenuBarIconHidden"
    }

    /// Load from UserDefaults
    static func load() -> ConfigurationSettings {
        return ConfigurationSettings(
            notificationPosition: UserDefaults.standard.string(forKey: Keys.notificationPosition)
                .flatMap { NotificationPosition(rawValue: $0) } ?? .topMiddle,
            isEnabled: UserDefaults.standard.object(forKey: Keys.isEnabled) as? Bool ?? true,
            debugMode: UserDefaults.standard.bool(forKey: Keys.debugMode),
            isMenuBarIconHidden: UserDefaults.standard.bool(forKey: Keys.isMenuBarIconHidden)
        )
    }

    /// Save to UserDefaults
    func save() {
        UserDefaults.standard.set(notificationPosition.rawValue, forKey: Keys.notificationPosition)
        UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled)
        UserDefaults.standard.set(debugMode, forKey: Keys.debugMode)
        UserDefaults.standard.set(isMenuBarIconHidden, forKey: Keys.isMenuBarIconHidden)
    }
}
```

## 3. State Management Design

### 3.1 State Machine

```swift
/// Manages state transitions for the notification mover
class NotificationMoverStateMachine {
    private(set) var currentState: PositioningState
    private let stateChangeCallbacks: [((PositioningState) -> Void)] = []

    enum PositioningState {
        case initialized
        case monitoring
        case positioning
        case paused
        case stopped
        case error(Error)

        var canPositionNotifications: Bool {
            switch self {
            case .monitoring, .positioning:
                return true
            default:
                return false
            }
        }
    }

    func transition(to newState: PositioningState) {
        guard isValidTransition(from: currentState, to: newState) else {
            assertionFailure("Invalid state transition from \(currentState) to \(newState)")
            return
        }

        let oldState = currentState
        currentState = newState

        notifyStateChange(from: oldState, to: newState)
    }

    private func isValidTransition(from: PositioningState, to: PositioningState) -> Bool {
        // Define valid state transitions
        switch (from, to) {
        case (.initialized, .monitoring),
             (.monitoring, .positioning),
             (.positioning, .monitoring),
             (.monitoring, .paused),
             (.paused, .monitoring),
             (_, .stopped),
             (_, .error):
            return true
        default:
            return false
        }
    }

    func onStateChange(_ callback: @escaping (PositioningState) -> Void) {
        stateChangeCallbacks.append(callback)
    }

    private func notifyStateChange(from: PositioningState, to: PositioningState) {
        stateChangeCallbacks.forEach { $0(to) }
    }
}
```

### 3.2 State Persistence Strategy

```swift
/// Manages persistence of state across app launches
protocol StatePersistence {
    /// Save the current state
    /// - Parameter state: The state to persist
    func save(_ state: NotificationMovementState)

    /// Load the persisted state
    /// - Returns: The persisted state, or nil if none exists
    func load() -> NotificationMovementState?

    /// Clear persisted state
    func clear()
}

class UserDefaultsStatePersistence: StatePersistence {
    private let stateKey = "notificationMovementState"

    func save(_ state: NotificationMovementState) {
        // Serialize only the necessary data
        let data: [String: Any] = [
            "cachedNotificationSize": state.cachedNotificationSize.map { ["width": $0.width, "height": $0.height] },
            "cachedPadding": state.cachedPadding ?? 0,
            "cachedWindowPosition": state.cachedWindowPosition.map { ["x": $0.x, "y": $0.y] }
        ]
        UserDefaults.standard.set(data, forKey: stateKey)
    }

    func load() -> NotificationMovementState? {
        guard let data = UserDefaults.standard.dictionary(forKey: stateKey) else {
            return nil
        }

        var state = NotificationMovementState.initial()

        if let sizeData = data["cachedNotificationSize"] as? [String: CGFloat] {
            state.cachedNotificationSize = CGSize(width: sizeData["width"]!, height: sizeData["height"]!)
        }

        if let padding = data["cachedPadding"] as? CGFloat {
            state.cachedPadding = padding
        }

        if let posData = data["cachedWindowPosition"] as? [String: CGFloat] {
            state.cachedWindowPosition = CGPoint(x: posData["x"]!, y: posData["y"]!)
        }

        return state
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: stateKey)
    }
}
```

## 4. Protocol Dependency Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   NOTIFICATION MOVER                         │
│                       DOMAIN MODELS                          │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│ ConfigurationManager │
├──────────────────────┤
│ - currentPosition    │───uses──→ NotificationPosition (enum)
│ - isEnabled          │
│ - debugMode          │
│ - save()             │
│ - load()             │
└──────────────────────┘

┌──────────────────────────┐
│ NotificationPositioning   │
├──────────────────────────┤
│ - calculatePosition()    │───uses──→ NotificationPosition
│ - validatePosition()     │
│ - applyPosition()        │───uses──→ NotificationWindow
└──────────────────────────┘

┌─────────────────────────┐
│ NotificationWindowTracker│
├─────────────────────────┤
│ - startMonitoring()     │
│ - stopMonitoring()      │
│ - getTrackedWindows()   │───returns──→ [NotificationWindow]
└─────────────────────────┘

┌──────────────────────────┐
│ AccessibilityElementHandler│
├──────────────────────────┤
│ - findNotification()     │───uses──→ NotificationWindow
│ - getPosition()          │
│ - setPosition()          │
│ - getSize()              │
└──────────────────────────┘

┌──────────────────────────┐
│ NotificationMovementState│
├──────────────────────────┤
│ - currentState           │
│ - activeWindows          │───contains──→ [NotificationWindow]
│ - cachedData             │
└──────────────────────────┘

┌──────────────────────┐
│ NotificationWindow   │
├──────────────────────┤
│ - id                 │
│ - axElement          │
│ - position           │
│ - size               │
│ - processID          │
│ - subrole            │
└──────────────────────┘
```

## 5. Key Design Decisions

1. **Protocol-Oriented Design**: All major components are defined as protocols to enable testability and dependency injection.

2. **Value Objects for State**: Using structs for `NotificationWindow` and `NotificationMovementState` ensures immutability and thread-safety.

3. **Enum for Positions**: `NotificationPosition` is an enum with associated values for display names and icons, making it type-safe and self-documenting.

4. **State Machine Pattern**: Explicit state management prevents invalid states and makes transitions clear.

5. **Persistence Abstraction**: State persistence is protocol-based, allowing for different storage backends.

6. **Observable Configuration**: `ConfigurationManager` supports change callbacks for reactive updates.

## File Organization

```
Notimanager/
├── Models/
│   ├── NotificationPosition.swift
│   ├── NotificationWindow.swift
│   ├── NotificationMovementState.swift
│   └── ConfigurationSettings.swift
├── Protocols/
│   ├── NotificationPositioning.swift
│   ├── NotificationWindowTracker.swift
│   ├── AccessibilityElementHandler.swift
│   └── ConfigurationManager.swift
├── State/
│   ├── NotificationMoverStateMachine.swift
│   └── StatePersistence.swift
└── Utilities/
    └── UserDefaults+Helpers.swift
```
