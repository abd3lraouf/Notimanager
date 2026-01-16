//
//  NotificationMoverProtocols.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Core protocols for the NotificationMover architecture
//

import AppKit
import Foundation

// MARK: - Notification Positioning

/// Defines the contract for notification positioning operations
@available(macOS 10.15, *)
protocol NotificationPositioning {

    /// Calculates the target position for a notification
    /// - Parameters:
    ///   - notifSize: The size of the notification
    ///   - screenBounds: The screen bounds
    ///   - position: The desired position
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
    /// - Returns: True if valid
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

// MARK: - Accessibility Element Handling

/// Defines the contract for handling Accessibility API elements
@available(macOS 10.15, *)
protocol AccessibilityElementHandling {

    /// Finds a notification element within a window
    /// - Parameter window: The window to search
    /// - Returns: The found element, if any
    func findNotificationElement(in window: AXUIElement) -> AXUIElement?

    /// Gets the position of an element
    /// - Parameter element: The element to query
    /// - Returns: The element's position
    func getPosition(of element: AXUIElement) -> CGPoint?

    /// Sets the position of an element
    /// - Parameters:
    ///   - element: The element to modify
    ///   - position: The new position
    /// - Returns: Success status
    func setPosition(of element: AXUIElement, to position: CGPoint) -> Bool

    /// Gets the size of an element
    /// - Parameter element: The element to query
    /// - Returns: The element's size
    func getSize(of element: AXUIElement) -> CGSize?

    /// Checks if an attribute is settable
    /// - Parameters:
    ///   - element: The element to check
    ///   - attribute: The attribute name
    /// - Returns: True if settable
    func isAttributeSettable(
        _ attribute: String,
        on element: AXUIElement
    ) -> Bool
}

// MARK: - Window Tracking

/// Defines the contract for tracking notification windows
@available(macOS 10.15, *)
protocol NotificationWindowTracking {

    /// Starts monitoring for notification windows
    func startMonitoring()

    /// Stops monitoring
    func stopMonitoring()

    /// Returns all tracked notification windows
    /// - Returns: Array of tracked windows
    func getTrackedWindows() -> [NotificationWindow]

    /// Registers a callback for new notifications
    /// - Parameter callback: Closure to execute
    func onNotificationDetected(_ callback: @escaping (NotificationWindow) -> Void)

    /// Registers a callback for dismissed notifications
    /// - Parameter callback: Closure to execute
    func onNotificationDismissed(_ callback: @escaping (NotificationWindow) -> Void)
}

// MARK: - Permission Management

/// Defines the contract for managing accessibility permissions
@available(macOS 10.15, *)
protocol AccessibilityPermissionManaging {

    /// Checks if accessibility permissions are granted
    /// - Returns: True if granted
    func checkPermissions() -> Bool

    /// Requests accessibility permissions from the user
    /// - Parameter showPrompt: Whether to show the system prompt
    /// - Returns: True if permissions are granted
    func requestPermissions(showPrompt: Bool) -> Bool

    /// Resets accessibility permissions (for testing/troubleshooting)
    func resetPermissions() throws

    /// Current permission status
    var permissionStatus: PermissionStatus { get }

    /// Observer for permission changes
    func observePermissionChanges(_ callback: @escaping (PermissionStatus) -> Void)
}

// PermissionStatus is defined in AccessibilityAPIProtocol.swift to avoid duplication

// MARK: - Notification Discovery

/// Defines the contract for discovering notification elements
@available(macOS 10.15, *)
protocol NotificationDiscovery {

    /// Finds notification elements using subrole search
    /// - Parameters:
    ///   - root: The root element to search from
    ///   - subroles: The subroles to search for
    /// - Returns: The found element, if any
    func findElementBySubrole(
        root: AXUIElement,
        targetSubroles: [String]
    ) -> AXUIElement?

    /// Finds notification elements using fallback strategies
    /// - Parameter root: The root element to search from
    /// - Returns: The found element, if any
    func findElementUsingFallbacks(root: AXUIElement) -> AXUIElement?

    /// Searches for elements by role and size constraints
    /// - Parameters:
    ///   - root: The root element
    ///   - role: The role to match
    ///   - sizeConstraints: Size constraints
    /// - Returns: The found element, if any
    func findElementByRoleAndSize(
        root: AXUIElement,
        role: String,
        sizeConstraints: SizeConstraints
    ) -> AXUIElement?
}

// MARK: - Models

/// Represents a tracked notification window
struct NotificationWindow: Identifiable, Equatable {
    let id: String
    let axElement: AXUIElement
    var position: CGPoint
    var size: CGSize
    let processID: pid_t
    let bundleIdentifier: String
    let detectionTime: Date
    var lastUpdateTime: Date
    let isSystemNotification: Bool
    let subrole: String?
    var hasBeenMoved: Bool
    let initialPosition: CGPoint?

    static func == (lhs: NotificationWindow, rhs: NotificationWindow) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Supporting Types

/// Size constraints for element matching
// Import from AccessibilityAPIProtocol module (internal reference)
// The actual SizeConstraints struct is defined in AccessibilityAPIProtocol.swift

// Forward declaration to resolve ambiguity
struct SizeConstraints {
    let minWidth: CGFloat
    let minHeight: CGFloat
    let maxWidth: CGFloat
    let maxHeight: CGFloat
}

// MARK: - Re-export NotificationPosition
// The NotificationPosition enum is defined in Models/NotificationPosition.swift
// This file provides the protocols that depend on it.
