//
//  AccessibilityAPIProtocol.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Core protocols for Accessibility API operations
//  Extracts all AX API calls from NotificationMover into testable service layer
//

import ApplicationServices
import AppKit
import Foundation

// MARK: - Accessibility API Protocol

/// Defines the contract for all Accessibility API operations
/// This protocol makes AX operations testable and mockable
@available(macOS 10.15, *)
protocol AccessibilityAPIProtocol {

    // MARK: - Element Properties

    /// Gets the position of an accessibility element
    /// - Parameter element: The element to query
    /// - Returns: The element's position, or nil if unavailable
    func getPosition(of element: AXUIElement) -> CGPoint?

    /// Gets the size of an accessibility element
    /// - Parameter element: The element to query
    /// - Returns: The element's size, or nil if unavailable
    func getSize(of element: AXUIElement) -> CGSize?

    /// Sets the position of an accessibility element
    /// - Parameters:
    ///   - element: The element to modify
    ///   - x: New X coordinate
    ///   - y: New Y coordinate
    /// - Returns: True if successful
    func setPosition(of element: AXUIElement, x: CGFloat, y: CGFloat) -> Bool

    /// Gets the role of an element
    /// - Parameter element: The element to query
    /// - Returns: The role, or nil if unavailable
    func getRole(of element: AXUIElement) -> String?

    /// Gets the subrole of an element
    /// - Parameter element: The element to query
    /// - Returns: The subrole, or nil if unavailable
    func getSubrole(of element: AXUIElement) -> String?

    /// Gets the window title
    /// - Parameter element: The element to query
    /// - Returns: The window title, if available
    func getWindowTitle(_ element: AXUIElement) -> String?

    /// Gets the window identifier of an element
    /// - Parameter element: The element to query
    /// - Returns: The element's identifier, if available
    func getWindowIdentifier(_ element: AXUIElement) -> String?

    // MARK: - Attribute Queries

    /// Copies an attribute value from an element
    /// - Parameters:
    ///   - element: The element to query
    ///   - attribute: The attribute to copy
    /// - Returns: The attribute value, or nil if unavailable
    func copyAttributeValue(_ element: AXUIElement, _ attribute: CFString) -> AnyObject?

    /// Checks if an attribute is settable on an element
    /// - Parameters:
    ///   - attribute: The attribute name
    ///   - element: The element to check
    /// - Returns: True if settable
    func isAttributeSettable(_ attribute: CFString, on element: AXUIElement) -> Bool

    // MARK: - Element Discovery

    /// Finds notification elements by subrole (primary search strategy)
    /// - Parameters:
    ///   - root: Root element to search from
    ///   - targetSubroles: Subroles to search for
    ///   - osVersion: OS version for strategy selection
    /// - Returns: Found element, or nil if not found
    func findElementBySubrole(
        root: AXUIElement,
        targetSubroles: [String],
        osVersion: OperatingSystemVersion
    ) -> AXUIElement?

    /// Finds notification elements using fallback strategies
    /// - Parameters:
    ///   - root: Root element to search from
    ///   - osVersion: OS version for strategy selection
    /// - Returns: Found element, or nil if not found
    func findElementUsingFallbacks(
        root: AXUIElement,
        osVersion: OperatingSystemVersion
    ) -> AXUIElement?

    /// Finds an element by its identifier
    /// - Parameters:
    ///   - root: Root element to search from
    ///   - identifier: Identifier to match
    ///   - currentDepth: Current search depth
    ///   - maxDepth: Maximum search depth
    /// - Returns: Found element, or nil if not found
    func findElementByIdentifier(
        root: AXUIElement,
        identifier: String,
        currentDepth: Int,
        maxDepth: Int
    ) -> AXUIElement?

    /// Finds elements by role and size constraints
    /// - Parameters:
    ///   - root: Root element to search
    ///   - role: Role to match
    ///   - sizeConstraints: Size constraints
    /// - Returns: Found element, or nil if not found
    func findElementByRoleAndSize(
        root: AXUIElement,
        role: String,
        sizeConstraints: SizeConstraints
    ) -> AXUIElement?

    /// Finds the deepest element matching size constraints
    /// - Parameters:
    ///   - root: Root element to search
    ///   - sizeConstraints: Size constraints
    ///   - currentDepth: Current search depth
    ///   - maxDepth: Maximum search depth
    /// - Returns: Found element, or nil if not found
    func findDeepestSizedElement(
        root: AXUIElement,
        sizeConstraints: SizeConstraints,
        currentDepth: Int,
        maxDepth: Int
    ) -> AXUIElement?

    /// Finds any element matching size constraints
    /// - Parameters:
    ///   - root: Root element to search
    ///   - sizeConstraints: Size constraints
    /// - Returns: Found element, or nil if not found
    func findAnyElementWithSize(
        root: AXUIElement,
        sizeConstraints: SizeConstraints
    ) -> AXUIElement?

    // MARK: - Application & Windows

    /// Creates an AXUIElement for an application
    /// - Parameter pid: Process ID
    /// - Returns: Application element
    func createApplicationElement(pid: pid_t) -> AXUIElement

    /// Gets all windows for an application
    /// - Parameter app: The application element
    /// - Returns: Array of window elements, or nil if unavailable
    func getWindows(for app: AXUIElement) -> [AXUIElement]?

    // MARK: - OS Version Handling

    /// Returns notification subroles for a given macOS version
    /// - Parameter osVersion: The OS version
    /// - Returns: Array of subrole strings to search for
    func getNotificationSubroles(for osVersion: OperatingSystemVersion) -> [String]

    /// Determines which element should be positioned (window vs banner)
    /// - Parameters:
    ///   - window: The window element
    ///   - banner: The banner/content element
    ///   - osVersion: The OS version to target
    /// - Returns: The element that should be moved
    func getPositionableElement(
        window: AXUIElement,
        banner: AXUIElement,
        osVersion: OperatingSystemVersion
    ) -> AXUIElement?

    // MARK: - Verification

    /// Verifies that a position was successfully applied
    /// - Parameters:
    ///   - element: The element to check
    ///   - expected: The expected position
    /// - Returns: True if position matches within tolerance
    func verifyPositionSet(_ element: AXUIElement, expected: CGPoint) -> Bool

    // MARK: - Debugging

    /// Dumps the element hierarchy for debugging
    /// - Parameters:
    ///   - element: The root element
    ///   - label: A label for the log
    ///   - depth: Current depth
    ///   - maxDepth: Maximum depth
    func dumpElementHierarchy(
        _ element: AXUIElement,
        label: String,
        depth: Int,
        maxDepth: Int
    )

    /// Logs detailed element information for debugging
    /// - Parameters:
    ///   - element: The element to log
    ///   - label: A label for the log entry
    func logElementDetails(_ element: AXUIElement, label: String)

    /// Collects all subroles present in element hierarchy
    /// - Parameters:
    ///   - element: The root element
    ///   - depth: Current search depth
    ///   - maxDepth: Maximum search depth
    /// - Returns: Set of all subroles found
    func collectAllSubrolesInHierarchy(
        _ element: AXUIElement,
        depth: Int,
        maxDepth: Int
    ) -> Set<String>
}

// MARK: - AX Observer Protocol

/// Protocol for AX observer operations
/// Handles creation and management of AXObserver instances
@available(macOS 10.15, *)
protocol AXObserverProtocol {

    /// Creates an observer for a process
    /// - Parameters:
    ///   - pid: Process ID to observe
    ///   - callback: Callback function for notifications
    /// - Returns: Tuple of (observer, error) where observer is nil on failure
    func createObserver(
        pid: pid_t,
        callback: @escaping AXObserverCallback
    ) -> (AXObserver?, AXError?)

    /// Adds a notification to the observer
    /// - Parameters:
    ///   - observer: The observer
    ///   - element: Element to observe
    ///   - notification: Notification type
    ///   - context: Context pointer
    /// - Returns: Success status
    func addNotification(
        to observer: AXObserver,
        for element: AXUIElement,
        notification: CFString,
        context: UnsafeMutableRawPointer?
    ) -> Bool

    /// Adds observer to run loop
    /// - Parameter observer: The observer to add
    func addToRunLoop(_ observer: AXObserver)

    /// Removes observer from run loop
    /// - Parameter observer: The observer to remove
    func removeFromRunLoop(_ observer: AXObserver)

    /// Gets the run loop source for an observer
    /// - Parameter observer: The observer
    /// - Returns: The run loop source
    func getRunLoopSource(for observer: AXObserver) -> CFRunLoopSource?
}

// MARK: - Accessibility Permission Protocol

/// Protocol for accessibility permission management
@available(macOS 10.15, *)
protocol AccessibilityPermissionProtocol {

    /// Checks if process is trusted for accessibility
    /// - Returns: True if trusted
    func checkTrusted() -> Bool

    /// Checks trust with optional prompt
    /// - Parameter withPrompt: Whether to show system prompt
    /// - Returns: True if trusted
    func checkTrusted(withPrompt: Bool) -> Bool

    /// Gets trusted options with prompt flag
    /// - Parameter prompt: Whether to show prompt
    /// - Returns: CFDictionary of options
    func getTrustedOptions(prompt: Bool) -> CFDictionary

    /// Resets accessibility permissions (for testing)
    /// - Throws: Process error if reset fails
    func resetPermissions() throws

    /// Gets the current permission status
    /// - Returns: Permission status enum
    func getPermissionStatus() -> PermissionStatus

    /// Checks if permissions are in a stale state due to code signature change
    /// This happens when the app is in System Settings but AXIsProcessTrusted returns false
    /// - Returns: True if permissions appear stale (likely due to code signature mismatch)
    func isPermissionStateStale() -> Bool
}

// MARK: - Supporting Types

// SizeConstraints is defined in NotificationMoverProtocols.swift to avoid ambiguity
// PermissionStatus is defined below

/// Status of accessibility permissions
enum PermissionStatus: Equatable, Sendable {
    case granted
    case denied
}

/// macOS version categories
enum MacOSVersion {
    case sequoia  // macOS 15+
    case sonoma   // macOS 14
    case ventura  // macOS 13
    case monterey // macOS 12 and earlier

    init(osVersion: OperatingSystemVersion) {
        switch osVersion.majorVersion {
        case 26...:
            self = .sequoia  // macOS 26+ (future)
        case 15...25:
            self = .sequoia  // macOS 15-25 (Sequoia)
        case 14:
            self = .sonoma
        case 13:
            self = .ventura
        default:
            self = .monterey
        }
    }

    /// Returns notification subroles for this version
    var notificationSubroles: [String] {
        switch self {
        case .sequoia:
            // macOS 15+ may use new subrole naming
            return [
                "AXNotificationCenterBanner",
                "AXNotificationCenterAlert",
                "AXNotification",
                "AXBanner",
                "AXAlert",
                "AXSystemDialog",
                "AXNotificationBanner",  // Potential macOS 26 name
                "AXNotificationAlert",   // Potential macOS 26 name
                "AXFloatingPanel",       // Alternative structure
                "AXPanel"                // Simplified panel name
            ]

        case .sonoma, .ventura, .monterey:
            // macOS 14 and earlier subroles
            return [
                "AXNotificationCenterBanner",
                "AXNotificationCenterAlert",
                "AXNotification",  // Potential new name
                "AXBanner",        // Potential simplified name
                "AXAlert",         // Potential simplified name
                "AXSystemDialog"   // Potential alternative
            ]
        }
    }
}

// MARK: - AX Observer Callback Type

/// Type alias for AX observer callback function
typealias AXObserverCallback = @convention(c) (
    _ observer: AXObserver,
    _ element: AXUIElement,
    _ notification: CFString,
    _ context: UnsafeMutableRawPointer?
) -> Void
