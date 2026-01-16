//
//  AXElementManager.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Centralized Accessibility API element operations extracted from NotificationMover.
//  Handles position, size, discovery, and verification of AXUIElements.
//

import ApplicationServices
import AppKit
import Foundation

/// Centralized Accessibility API element operations
@available(macOS 10.15, *)
class AXElementManager {

    // MARK: - Singleton

    static let shared = AXElementManager()

    private init() {}

    // MARK: - Constants

    private let notificationCenterBundleID = "com.apple.notificationcenterui"
    private let widgetIdentifierPrefix: String = "widget-local:"
    private let paddingAboveDock: CGFloat = 30

    // MARK: - Element Properties

    /// Gets the position of an accessibility element
    /// - Parameter element: The element to query
    /// - Returns: The element's position, or nil if unavailable
    func getPosition(of element: AXUIElement) -> CGPoint? {
        var positionValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)

        guard result == .success,
              let posVal = positionValue,
              AXValueGetType(posVal as! AXValue) == .cgPoint else {
            return nil
        }

        var position = CGPoint.zero
        AXValueGetValue(posVal as! AXValue, .cgPoint, &position)
        return position
    }

    /// Gets the size of an accessibility element
    /// - Parameter element: The element to query
    /// - Returns: The element's size, or nil if unavailable
    func getSize(of element: AXUIElement) -> CGSize? {
        let maxRetries = 2
        for attempt in 0...maxRetries {
            var sizeValue: AnyObject?
            let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)

            guard result == .success else {
                if attempt < maxRetries {
                    usleep(10000) // 10ms delay before retry
                    continue
                }
                return nil
            }

            guard let sizeVal = sizeValue,
                  AXValueGetType(sizeVal as! AXValue) == .cgSize else {
                return nil
            }

            var size = CGSize.zero
            AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)

            return size
        }
        return nil
    }

    /// Sets the position of an accessibility element
    /// - Parameters:
    ///   - element: The element to modify
    ///   - x: New X coordinate
    /// - y: New Y coordinate
    /// - Returns: True if successful
    func setPosition(of element: AXUIElement, x: CGFloat, y: CGFloat) -> Bool {
        var point = CGPoint(x: x, y: y)
        let value = AXValueCreate(.cgPoint, &point)!
        let result = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value)

        if result == .success {
            return true
        }

        return false
    }

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
    ) -> AXUIElement {

        // For macOS 26+, try the window element first
        if osVersion.majorVersion >= 26 {
            // Check window size - never move oversized windows (NC panel, etc.)
            if let windowSize = getSize(of: window) {
                if windowSize.width > 600 || windowSize.height > 300 {
                    return banner // NC panel detected, use banner
                }
            }

            // Check if window position is settable
            var windowSettable = DarwinBoolean(false)
            let windowResult = AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &windowSettable)

            // Check if banner position is settable
            var bannerSettable = DarwinBoolean(false)
            let bannerResult = AXUIElementIsAttributeSettable(banner, kAXPositionAttribute as CFString, &bannerSettable)

            if windowResult == .success && windowSettable.boolValue {
                return window
            } else if bannerResult == .success && bannerSettable.boolValue {
                return banner
            } else {
                return banner
            }
        }

        // On older macOS versions, use banner element
        return banner
    }

    /// Verifies that a position was successfully applied
    /// - Parameters:
    ///   - element: The element to check
    ///   - expected: The expected position
    /// - Returns: True if position matches within tolerance
    func verifyPositionSet(_ element: AXUIElement, expected: CGPoint) -> Bool {
        guard let actualPosition = getPosition(of: element) else {
            return false
        }

        let tolerance: CGFloat = 2.0 // Allow 2px variance
        let xMatch = abs(actualPosition.x - expected.x) <= tolerance
        let yMatch = abs(actualPosition.y - expected.y) <= tolerance

        return xMatch && yMatch
    }

    // MARK: - Element Finding

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
    ) -> AXUIElement? {

        // Helper structure to track candidates with metadata
        struct Candidate {
            let element: AXUIElement
            let depth: Int
            let subrole: String
            let size: CGSize
            let score: Int

            init(element: AXUIElement, depth: Int, subrole: String, size: CGSize) {
                self.element = element
                self.depth = depth
                self.subrole = subrole
                self.size = size

                // Calculate score: depth is primary factor, then subrole specificity, then size accuracy
                var score = depth * 100  // Deeper = higher score

                // Bonus for specific notification subroles
                if subrole == "AXNotificationCenterBanner" || subrole == "AXNotificationCenterAlert" ||
                   subrole == "AXNotificationBanner" || subrole == "AXNotificationAlert" ||
                   subrole == "AXNotificationCenterNotification" || subrole == "AXNotificationCenterBannerWindow" {
                    score += 50
                }

                // Bonus for size closer to typical notification (350×65 is common)
                if size.width >= 300 && size.width <= 450 && size.height >= 55 && size.height <= 85 {
                    score += 30
                }

                self.score = score
            }
        }

        // Recursive search function that collects all candidates
        func searchRecursive(
            _ element: AXUIElement,
            currentDepth: Int,
            candidates: inout [Candidate]
        ) {
            guard currentDepth < 15 else { return }

            // Check if current element has matching subrole
            var subroleRef: AnyObject?
            let result = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef)

            if result == .success, let subrole = subroleRef as? String {
                if targetSubroles.contains(subrole) {
                    // Validate size - notifications are typically 200-800px wide, 60-200px tall
                    if let size = getSize(of: element) {
                        let isNotificationSized = size.width >= 200 && size.width <= 800 &&
                                                   size.height >= 60 && size.height <= 200

                        if isNotificationSized {
                            let candidate = Candidate(
                                element: element,
                                depth: currentDepth,
                                subrole: subrole,
                                size: size
                            )
                            candidates.append(candidate)
                        }
                    }
                }
            }

            // ALWAYS search children regardless
            var childrenRef: AnyObject?
            if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
               let children = childrenRef as? [AXUIElement] {
                for child in children {
                    searchRecursive(child, currentDepth: currentDepth + 1, candidates: &candidates)
                }
            }
        }

        // Start search
        var candidates: [Candidate] = []
        searchRecursive(root, currentDepth: 0, candidates: &candidates)

        // Select best candidate (highest score = deepest + most specific)
        if candidates.isEmpty {
            return nil
        }

        let bestCandidate = candidates.max(by: { $0.score < $1.score })
        return bestCandidate?.element
    }

    /// Finds notification elements using fallback strategies
    /// - Parameters:
    ///   - root: Root element to search from
    ///   - osVersion: OS version for strategy selection
    /// - Returns: Found element, or nil if not found
    func findElementUsingFallbacks(
        root: AXUIElement,
        osVersion: OperatingSystemVersion
    ) -> AXUIElement? {

        // Strategy 0: Find by identifier "AXNotificationListItems" (macOS 26.1+)
        if let element = findElementByIdentifier(root: root, identifier: "AXNotificationListItems") {
            return element
        }

        // Strategy 1: Find by role = "AXGroup" and reasonable size
        if let element = findElementByRoleAndSize(
            root: root,
            role: "AXGroup",
            sizeConstraints: SizeConstraints(
                minWidth: 300,
                minHeight: 60,
                maxWidth: 800,
                maxHeight: 300
            )
        ) {
            return element
        }

        // Strategy 2: Find by role = "AXScrollArea"
        if let element = findElementByRoleAndSize(
            root: root,
            role: "AXScrollArea",
            sizeConstraints: SizeConstraints(
                minWidth: 300,
                minHeight: 60,
                maxWidth: 800,
                maxHeight: 300
            )
        ) {
            return element
        }

        // Strategy 3: Find any sizeable element with specific roles
        let fallbackRoles = ["AXGroup", "AXScrollArea", "AXLayoutArea", "AXSplitGroup", "AXUnknown"]
        for role in fallbackRoles {
            if let element = findElementByRoleAndSize(
                root: root,
                role: role,
                sizeConstraints: SizeConstraints(
                    minWidth: 280,
                    minHeight: 50,
                    maxWidth: 800,
                    maxHeight: 300
                )
            ) {
                return element
            }
        }

        // Strategy 4: Find deepest element with significant size
        if let element = findDeepestSizedElement(
            root: root,
            sizeConstraints: SizeConstraints(
                minWidth: 280,
                minHeight: 50,
                maxWidth: 800,
                maxHeight: 300
            )
        ) {
            return element
        }

        // Strategy 5: Last resort - find ANY element with notification-like dimensions
        if let element = findAnyElementWithSize(
            root: root,
            sizeConstraints: SizeConstraints(
                minWidth: 250,
                minHeight: 40,
                maxWidth: 600,
                maxHeight: 200
            )
        ) {
            return element
        }

        return nil
    }

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
        currentDepth: Int = 0,
        maxDepth: Int = 10
    ) -> AXUIElement? {
        guard currentDepth < maxDepth else { return nil }

        // Check if current element has the target identifier
        if let elemIdentifier = getWindowIdentifier(root), elemIdentifier == identifier {
            return root
        }

        // Search children
        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            if let found = findElementByIdentifier(
                root: child,
                identifier: identifier,
                currentDepth: currentDepth + 1,
                maxDepth: maxDepth
            ) {
                return found
            }
        }

        return nil
    }

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
    ) -> AXUIElement? {
        var roleRef: AnyObject?
        if AXUIElementCopyAttributeValue(root, kAXRoleAttribute as CFString, &roleRef) == .success,
           let elementRole = roleRef as? String,
           elementRole == role,
           let size = getSize(of: root),
           size.width >= sizeConstraints.minWidth &&
           size.height >= sizeConstraints.minHeight &&
           size.width <= sizeConstraints.maxWidth &&
           size.height <= sizeConstraints.maxHeight {
            return root
        }

        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            if let found = findElementByRoleAndSize(
                root: child,
                role: role,
                sizeConstraints: sizeConstraints
            ) {
                return found
            }
        }

        return nil
    }

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
        currentDepth: Int = 0,
        maxDepth: Int = 10
    ) -> AXUIElement? {
        guard currentDepth < maxDepth else { return nil }

        var deepestElement: AXUIElement?
        var maxFoundDepth = currentDepth

        var childrenRef: AnyObject?
        if AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findDeepestSizedElement(
                    root: child,
                    sizeConstraints: sizeConstraints,
                    currentDepth: currentDepth + 1,
                    maxDepth: maxDepth
                ) {
                    if currentDepth + 1 > maxFoundDepth {
                        deepestElement = found
                        maxFoundDepth = currentDepth + 1
                    }
                }
            }
        }

        if deepestElement == nil,
           let size = getSize(of: root),
           size.width >= sizeConstraints.minWidth &&
           size.width <= sizeConstraints.maxWidth &&
           size.height <= sizeConstraints.maxHeight {
            return root
        }

        return deepestElement
    }

    /// Finds any element matching size constraints
    /// - Parameters:
    ///   - root: Root element to search
    ///   - sizeConstraints: Size constraints
    /// - Returns: Found element, or nil if not found
    func findAnyElementWithSize(
        root: AXUIElement,
        sizeConstraints: SizeConstraints
    ) -> AXUIElement? {
        if let size = getSize(of: root),
           size.width >= sizeConstraints.minWidth &&
           size.width <= sizeConstraints.maxWidth &&
           size.height >= sizeConstraints.minHeight &&
           size.height <= sizeConstraints.maxHeight {
            return root
        }

        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            if let found = findAnyElementWithSize(
                root: child,
                sizeConstraints: sizeConstraints
            ) {
                return found
            }
        }

        return nil
    }

    // MARK: - Element Information

    /// Gets the window identifier of an element
    /// - Parameter element: The element to query
    /// - Returns: The element's identifier, if available
    func getWindowIdentifier(_ element: AXUIElement) -> String? {
        var identifierRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute as CFString, &identifierRef)

        guard result == .success,
              let identifier = identifierRef as? String else {
            return nil
        }

        return identifier
    }

    /// Gets the window title
    /// - Parameter element: The element to query
    /// - Returns: The window title, if available
    func getWindowTitle(_ element: AXUIElement) -> String? {
        var titleRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)

        guard result == .success,
              let title = titleRef as? String else {
            return nil
        }

        return title
    }

    /// Logs detailed element information for debugging
    /// - Parameters:
    ///   - element: The element to log
    ///   - label: A label for the log entry
    func logElementDetails(_ element: AXUIElement, label: String) {
        var details: [String] = []

        if let role = getRole(of: element) {
            details.append("role=\(role)")
        }

        if let subrole = getSubrole(of: element) {
            details.append("subrole=\(subrole)")
        }

        if let size = getSize(of: element) {
            details.append("size=\(size.width)×\(size.height)")
        }

        if let position = getPosition(of: element) {
            details.append("position=(\(position.x), \(position.y))")
        }

        if let identifier = getWindowIdentifier(element) {
            details.append("id=\(identifier)")
        }

        print("📍 [\(label)] \(details.joined(separator: ", "))")
    }

    /// Gets the role of an element
    /// - Parameter element: The element to query
    /// - Returns: The role, or nil if unavailable
    func getRole(of element: AXUIElement) -> String? {
        var roleRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)

        guard result == .success,
              let role = roleRef as? String else {
            return nil
        }

        return role
    }

    /// Gets the subrole of an element
    /// - Parameter element: The element to query
    /// - Returns: The subrole, or nil if unavailable
    func getSubrole(of element: AXUIElement) -> String? {
        var subroleRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef)

        guard result == .success,
              let subrole = subroleRef as? String else {
            return nil
        }

        return subrole
    }

    // MARK: - Utility Methods

    /// Collects all subroles present in element hierarchy
    /// - Parameters:
    ///   - element: The root element
    ///   - depth: Current search depth
    ///   - maxDepth: Maximum search depth
    ///   - foundSubroles: Collected subroles
    func collectAllSubrolesInHierarchy(
        _ element: AXUIElement,
        depth: Int,
        maxDepth: Int
    ) -> Set<String> {

        var foundSubroles = Set<String>()

        func collectRecursive(_ element: AXUIElement, currentDepth: Int) {
            guard depth < maxDepth else { return }

            if let subrole = getSubrole(of: element) {
                foundSubroles.insert(subrole)
            }

            var childrenRef: AnyObject?
            if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
               let children = childrenRef as? [AXUIElement] {
                for child in children {
                    collectRecursive(child, currentDepth: currentDepth + 1)
                }
            }
        }

        collectRecursive(element, currentDepth: 0)

        return foundSubroles
    }

    /// Dumps the element hierarchy for debugging
    /// - Parameters:
    ///   - element: The root element
    ///   - label: A label for the log
    ///   - depth: Current depth
    ///   - maxDepth: Maximum depth
    func dumpElementHierarchy(
        _ element: AXUIElement,
        label: String,
        depth: Int = 0,
        maxDepth: Int = 5
    ) {
        guard depth < maxDepth else { return }

        let indent = String(repeating: "  ", count: depth)
        var info: [String] = []

        if let role = getRole(of: element) {
            info.append("role=\(role)")
        }

        if let subrole = getSubrole(of: element) {
            info.append("subrole=\(subrole)")
        }

        if let size = getSize(of: element) {
            info.append("size=\(size.width)×\(size.height)")
        }

        if let identifier = getWindowIdentifier(element) {
            info.append("id=\(identifier)")
        }

        print("\(indent)[\(label) depth=\(depth)] \(info.joined(separator: ", "))")

        // Recurse to children
        var childrenRef: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement] {
            for (index, child) in children.enumerated() {
                dumpElementHierarchy(child, label: "Child[\(index)]", depth: depth + 1, maxDepth: maxDepth)
            }
        }
    }
}
