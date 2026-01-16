//
//  MockAccessibilityManager.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import Foundation
import AppKit
@testable import Notimanager

/// Mock accessibility manager for integration testing
/// Simulates Accessibility API behavior without requiring actual permissions
class MockAccessibilityManager {

    // MARK: - Properties

    /// Whether the mock reports that accessibility permissions are granted
    var isAccessibilityTrusted: Bool = false

    /// Whether the mock should simulate successful window operations
    var windowOperationsSucceed: Bool = true

    /// Simulated notification windows (windowNumber -> position)
    private var mockNotificationWindows: [Int: MockNotificationWindow] = [:]

    /// Callbacks for when windows are moved
    var onWindowMoved: ((Int, CGPoint) -> Void)?

    /// Callbacks for when notifications are detected
    var onNotificationDetected: ((Int) -> Void)?

    /// List of all detected notification window numbers
    private(set) var detectedWindowNumbers: [Int] = []

    // MARK: - Mock Notification Window

    /// Represents a mock notification window for testing
    struct MockNotificationWindow {
        let windowNumber: Int
        var position: CGPoint
        var size: CGSize
        var title: String?
        var subrole: String?
        var role: String = "AXWindow"

        init(windowNumber: Int, position: CGPoint, size: CGSize, title: String? = nil, subrole: String? = nil) {
            self.windowNumber = windowNumber
            self.position = position
            self.size = size
            self.title = title
            self.subrole = subrole
        }
    }

    // MARK: - Permission Mocking

    /// Simulates AXIsProcessTrusted() call
    /// - Returns: The mocked trusted status
    func checkAccessibilityTrusted() -> Bool {
        return isAccessibilityTrusted
    }

    /// Sets whether accessibility permissions are granted
    /// - Parameter trusted: Whether to report permissions as granted
    func setAccessibilityTrusted(_ trusted: Bool) {
        isAccessibilityTrusted = trusted
    }

    // MARK: - Notification Window Simulation

    /// Simulates the creation of a notification window
    /// - Parameters:
    ///   - windowNumber: The window number to assign
    ///   - position: Initial position of the window
    ///   - size: Size of the window
    ///   - title: Optional window title
    ///   - subrole: Optional window subrole (e.g., "AXNotificationCenterBanner")
    /// - Returns: The created mock window
    @discardableResult
    func simulateNotificationWindow(
        windowNumber: Int,
        position: CGPoint,
        size: CGSize = CGSize(width: 350, height: 80),
        title: String? = nil,
        subrole: String? = "AXNotificationCenterBanner"
    ) -> MockNotificationWindow {
        let mockWindow = MockNotificationWindow(
            windowNumber: windowNumber,
            position: position,
            size: size,
            title: title,
            subrole: subrole
        )

        mockNotificationWindows[windowNumber] = mockWindow
        detectedWindowNumbers.append(windowNumber)

        onNotificationDetected?(windowNumber)

        return mockWindow
    }

    /// Simulates multiple notification windows appearing
    /// - Parameters:
    ///   - count: Number of windows to create
    ///   - startPosition: Starting position for first window
    ///   - offset: Offset between windows
    /// - Returns: Array of created mock windows
    @discardableResult
    func simulateMultipleNotificationWindows(
        count: Int,
        startPosition: CGPoint,
        offset: CGFloat = 90
    ) -> [MockNotificationWindow] {
        var windows: [MockNotificationWindow] = []

        for i in 0..<count {
            let position = CGPoint(x: startPosition.x, y: startPosition.y - CGFloat(i) * offset)
            let window = simulateNotificationWindow(
                windowNumber: 1000 + i,
                position: position
            )
            windows.append(window)
        }

        return windows
    }

    /// Removes a simulated notification window
    /// - Parameter windowNumber: The window number to remove
    func removeNotificationWindow(windowNumber: Int) {
        mockNotificationWindows.removeValue(forKey: windowNumber)
        detectedWindowNumbers.removeAll { $0 == windowNumber }
    }

    /// Clears all simulated notification windows
    func clearAllNotificationWindows() {
        mockNotificationWindows.removeAll()
        detectedWindowNumbers.removeAll()
    }

    // MARK: - Window Query Mocking

    /// Returns all simulated notification windows
    /// - Returns: Array of mock notification windows
    func getAllNotificationWindows() -> [MockNotificationWindow] {
        return Array(mockNotificationWindows.values)
    }

    /// Returns a specific mock notification window
    /// - Parameter windowNumber: The window number to retrieve
    /// - Returns: The mock window if it exists, nil otherwise
    func getNotificationWindow(windowNumber: Int) -> MockNotificationWindow? {
        return mockNotificationWindows[windowNumber]
    }

    /// Returns the number of simulated notification windows
    /// - Returns: Count of mock windows
    func getNotificationWindowCount() -> Int {
        return mockNotificationWindows.count
    }

    // MARK: - Window Movement Simulation

    /// Simulates moving a notification window to a new position
    /// - Parameters:
    ///   - windowNumber: The window number to move
    ///   - newPosition: The new position
    /// - Returns: True if the move succeeded, false otherwise
    func moveNotificationWindow(windowNumber: Int, to newPosition: CGPoint) -> Bool {
        guard windowOperationsSucceed else {
            return false
        }

        guard var window = mockNotificationWindows[windowNumber] else {
            return false
        }

        window.position = newPosition
        mockNotificationWindows[windowNumber] = window

        onWindowMoved?(windowNumber, newPosition)

        return true
    }

    /// Gets the current position of a simulated notification window
    /// - Parameter windowNumber: The window number to query
    /// - Returns: The current position if the window exists, nil otherwise
    func getNotificationWindowPosition(windowNumber: Int) -> CGPoint? {
        return mockNotificationWindows[windowNumber]?.position
    }

    /// Returns all windows at a given position (within tolerance)
    /// - Parameters:
    ///   - position: The position to check
    ///   - tolerance: Pixel tolerance for position matching (default: 5 pixels)
    /// - Returns: Array of windows at or near the position
    func getWindowsAtPosition(
        _ position: CGPoint,
        tolerance: CGFloat = 5.0
    ) -> [MockNotificationWindow] {
        return mockNotificationWindows.values.filter { window in
            abs(window.position.x - position.x) <= tolerance &&
            abs(window.position.y - position.y) <= tolerance
        }
    }

    // MARK: - Verification Helpers

    /// Verifies that a window was moved to the expected position
    /// - Parameters:
    ///   - windowNumber: The window number to verify
    ///   - expectedPosition: The expected position
    ///   - tolerance: Pixel tolerance for position matching (default: 5 pixels)
    /// - Returns: True if the window is at the expected position
    func verifyWindowAtPosition(
        _ windowNumber: Int,
        expectedPosition: CGPoint,
        tolerance: CGFloat = 5.0
    ) -> Bool {
        guard let window = mockNotificationWindows[windowNumber] else {
            return false
        }

        return abs(window.position.x - expectedPosition.x) <= tolerance &&
               abs(window.position.y - expectedPosition.y) <= tolerance
    }

    /// Verifies that a specific number of notification windows exist
    /// - Parameter expectedCount: The expected count
    /// - Returns: True if the count matches
    func verifyNotificationWindowCount(_ expectedCount: Int) -> Bool {
        return mockNotificationWindows.count == expectedCount
    }

    /// Returns the count of detected notifications
    /// - Returns: Number of times notifications were detected
    func getDetectedNotificationCount() -> Int {
        return detectedWindowNumbers.count
    }

    /// Clears detection history
    func clearDetectionHistory() {
        detectedWindowNumbers.removeAll()
    }

    // MARK: - AXObserver Simulation

    /// Simulates an AXObserver notification callback
    /// - Parameters:
    ///   - notification: The notification type (e.g., kAXWindowCreatedNotification)
    ///   - windowNumber: The window number involved
    func simulateObserverNotification(
        _ notification: CFString,
        windowNumber: Int
    ) {
        // In a real scenario, this would trigger the callback registered with AXObserverAddNotification
        // For testing, we just track the notification
        if notification == kAXWindowCreatedNotification as CFString {
            onNotificationDetected?(windowNumber)
        }
    }

    // MARK: - Reset

    /// Resets all mock state to defaults
    func reset() {
        isAccessibilityTrusted = false
        windowOperationsSucceed = true
        mockNotificationWindows.removeAll()
        detectedWindowNumbers.removeAll()
        onWindowMoved = nil
        onNotificationDetected = nil
    }
}

// MARK: - Test Helpers

extension MockAccessibilityManager {

    /// Creates a mock notification window at a standard top-right position
    /// - Parameter windowNumber: The window number to assign
    /// - Returns: The created mock window
    func createStandardNotificationWindow(windowNumber: Int = 1000) -> MockNotificationWindow {
        // Standard macOS notification banner size and position (top-right)
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let notificationSize = CGSize(width: 350, height: 80)
        let position = CGPoint(
            x: screenSize.maxX - notificationSize.width - 10,
            y: screenSize.maxY - notificationSize.height - 10
        )

        return simulateNotificationWindow(
            windowNumber: windowNumber,
            position: position,
            size: notificationSize,
            title: "Notification",
            subrole: "AXNotificationCenterBanner"
        )
    }

    /// Creates multiple mock notification windows at standard positions
    /// - Parameter count: Number of windows to create
    /// - Returns: Array of created mock windows
    func createStandardNotificationWindows(count: Int) -> [MockNotificationWindow] {
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let startPosition = CGPoint(
            x: screenSize.maxX - 360, // 350 width + 10 margin
            y: screenSize.maxY - 90    // 80 height + 10 margin
        )

        return simulateMultipleNotificationWindows(
            count: count,
            startPosition: startPosition,
            offset: 90 // Standard notification stacking offset
        )
    }

    /// Simulates the complete workflow: notification appears and is moved
    /// - Parameters:
    ///   - windowNumber: The window number
    ///   - targetPosition: The position to move to
    /// - Returns: True if the simulation succeeded
    func simulateNotificationDetectionAndMovement(
        windowNumber: Int,
        to targetPosition: CGPoint
    ) -> Bool {
        // Step 1: Create notification
        _ = createStandardNotificationWindow(windowNumber: windowNumber)

        // Step 2: Move it
        return moveNotificationWindow(windowNumber: windowNumber, to: targetPosition)
    }
}
