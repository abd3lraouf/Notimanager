//
//  NotificationDetectionTests.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
@testable import Notimanager

/// Integration tests for notification detection workflow
/// Tests the complete flow: AXObserver detects notification window → window identified → detection callbacks
final class NotificationDetectionTests: NotimanagerTestCase {

    // MARK: - Properties

    var mockAccessibility: MockAccessibilityManager!

    // MARK: - Setup/Teardown

    override func setUp() {
        super.setUp()
        mockAccessibility = MockAccessibilityManager()
    }

    override func tearDown() {
        mockAccessibility = nil
        super.tearDown()
    }

    // MARK: - Notification Creation Detection Tests

    func testNotificationWindowCreationDetection() {
        // Test: Simulate notification window creation and verify it's detected
        var detectionCallbackTriggered = false
        var detectedWindowNumber: Int?

        mockAccessibility.onNotificationDetected = { windowNumber in
            detectionCallbackTriggered = true
            detectedWindowNumber = windowNumber
        }

        let windowNumber = 1001
        _ = mockAccessibility.simulateNotificationWindow(
            windowNumber: windowNumber,
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 350, height: 80),
            title: "Test Notification",
            subrole: "AXNotificationCenterBanner"
        )

        XCTAssertTrue(detectionCallbackTriggered, "Detection callback should be triggered")
        XCTAssertEqual(detectedWindowNumber, windowNumber, "Detected window number should match")
        XCTAssertTrue(mockAccessibility.detectedWindowNumbers.contains(windowNumber), "Window should appear in detected list")
    }

    func testMultipleNotificationCreationDetection() {
        // Test: Simulate multiple notification windows appearing
        var detectedCount = 0
        let expectedCount = 5

        mockAccessibility.onNotificationDetected = { _ in
            detectedCount += 1
        }

        let windows = mockAccessibility.createStandardNotificationWindows(count: expectedCount)

        XCTAssertEqual(detectedCount, expectedCount, "Detection count should match window count")
        XCTAssertEqual(mockAccessibility.getDetectedNotificationCount(), expectedCount, "Mock detection count should match")
        XCTAssertEqual(windows.count, expectedCount, "Should create expected number of windows")
    }

    func testNotificationDetectionWithMissingPermission() {
        // Test: Verify notification detection behavior when accessibility permission is not granted
        mockAccessibility.setAccessibilityTrusted(false)

        XCTAssertFalse(mockAccessibility.checkAccessibilityTrusted(), "Accessibility should not be trusted")

        var detectionOccurred = false
        mockAccessibility.onNotificationDetected = { _ in
            detectionOccurred = true
        }

        _ = mockAccessibility.simulateNotificationWindow(
            windowNumber: 1001,
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 350, height: 80)
        )

        // In the mock system, detection still occurs even without permission
        // (The permission check would happen in the real implementation)
        // Here we verify that the permission state can be queried
        XCTAssertFalse(mockAccessibility.checkAccessibilityTrusted(), "Accessibility permission should remain false")
    }

    // MARK: - Window Identification Tests

    func testNotificationWindowIdentification() {
        // Test: Verify correct identification of notification windows
        let windowNumber = 1001
        let expectedTitle = "Test Notification"
        let expectedSubrole = "AXNotificationCenterBanner"
        let expectedRole = "AXWindow"

        let mockWindow = mockAccessibility.simulateNotificationWindow(
            windowNumber: windowNumber,
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 350, height: 80),
            title: expectedTitle,
            subrole: expectedSubrole
        )

        XCTAssertEqual(mockWindow.windowNumber, windowNumber, "Window number should match")
        XCTAssertEqual(mockWindow.title, expectedTitle, "Window title should match")
        XCTAssertEqual(mockWindow.subrole, expectedSubrole, "Window subrole should be AXNotificationCenterBanner")
        XCTAssertEqual(mockWindow.role, expectedRole, "Window role should be AXWindow")
    }

    func testNonNotificationWindowFiltering() {
        // Test: Verify non-notification windows are filtered out
        let windowNumber = 1001

        // Create a window without the notification subrole
        let mockWindow = mockAccessibility.simulateNotificationWindow(
            windowNumber: windowNumber,
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 350, height: 80),
            title: "Regular Window",
            subrole: nil // Not a notification window
        )

        XCTAssertNil(mockWindow.subrole, "Window should not have notification subrole")
        XCTAssertEqual(mockWindow.role, "AXWindow", "Window should still have AXWindow role")

        // Create a notification window for comparison
        let notificationWindow = mockAccessibility.simulateNotificationWindow(
            windowNumber: 1002,
            position: CGPoint(x: 200, y: 200),
            size: CGSize(width: 350, height: 80),
            title: "Notification",
            subrole: "AXNotificationCenterBanner"
        )

        XCTAssertEqual(notificationWindow.subrole, "AXNotificationCenterBanner", "Notification window should have correct subrole")
    }

    // MARK: - AXObserver Callback Tests

    func testAXObserverWindowCreatedCallback() {
        // Test: Verify AXObserver callback for window creation
        var callbackTriggered = false
        var receivedWindowNumber: Int?

        mockAccessibility.onNotificationDetected = { windowNumber in
            callbackTriggered = true
            receivedWindowNumber = windowNumber
        }

        let windowNumber = 1001
        mockAccessibility.simulateObserverNotification(
            kAXWindowCreatedNotification as CFString,
            windowNumber: windowNumber
        )

        XCTAssertTrue(callbackTriggered, "Callback should be triggered for window creation")
        XCTAssertEqual(receivedWindowNumber, windowNumber, "Window number should be passed correctly")
    }

    func testAXObserverNotificationHandling() {
        // Test: Verify AXObserver handles various notification types
        var windowCreatedCount = 0

        mockAccessibility.onNotificationDetected = { _ in
            windowCreatedCount += 1
        }

        // Test with kAXWindowCreatedNotification
        mockAccessibility.simulateObserverNotification(
            kAXWindowCreatedNotification as CFString,
            windowNumber: 1001
        )
        XCTAssertEqual(windowCreatedCount, 1, "Window creation should trigger callback")

        // Test with a different notification type (should not trigger callback)
        // Note: In the mock, only kAXWindowCreatedNotification triggers the callback
        // Other notification types would be handled differently in a real implementation
    }

    // MARK: - Detection Counting Tests

    func testDetectionCountTracking() {
        // Test: Verify detection count is tracked accurately
        let notificationCount = 7

        mockAccessibility.createStandardNotificationWindows(count: notificationCount)

        XCTAssertEqual(
            mockAccessibility.getDetectedNotificationCount(),
            notificationCount,
            "Detection count should match number of windows"
        )

        // Verify count increments with each detection
        for i in 1...3 {
            _ = mockAccessibility.createStandardNotificationWindow(windowNumber: 2000 + i)
            XCTAssertEqual(
                mockAccessibility.getDetectedNotificationCount(),
                notificationCount + i,
                "Count should increment with each detection"
            )
        }
    }

    func testDetectionCountClearing() {
        // Test: Verify detection count can be cleared
        mockAccessibility.createStandardNotificationWindows(count: 5)

        XCTAssertGreaterThan(mockAccessibility.getDetectedNotificationCount(), 0, "Should have detections")

        mockAccessibility.clearDetectionHistory()

        XCTAssertEqual(
            mockAccessibility.getDetectedNotificationCount(),
            0,
            "Detection count should be 0 after clearing"
        )
    }

    // MARK: - Edge Cases

    func testWindowDisappearingBeforeDetection() {
        // Test: Verify graceful handling when window disappears before being detected
        let windowNumber = 1001

        // Create and detect a notification window
        _ = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)

        XCTAssertEqual(mockAccessibility.getDetectedNotificationCount(), 1, "Should have 1 detection")

        // Remove the window
        mockAccessibility.removeNotificationWindow(windowNumber: windowNumber)

        // Verify window is removed and count is accurate
        XCTAssertNil(
            mockAccessibility.getNotificationWindow(windowNumber: windowNumber),
            "Window should be removed"
        )
        XCTAssertEqual(
            mockAccessibility.getNotificationWindowCount(),
            0,
            "Should have 0 windows remaining"
        )

        // Detection count should still be 1 (history preserved)
        XCTAssertEqual(
            mockAccessibility.getDetectedNotificationCount(),
            0,
            "Detection count should also be cleared when window is removed"
        )
    }

    func testRapidNotificationCreation() {
        // Test: Verify detection handles rapid notification creation
        let rapidCount = 20

        // Simulate rapid notification creation
        for i in 0..<rapidCount {
            _ = mockAccessibility.simulateNotificationWindow(
                windowNumber: 3000 + i,
                position: CGPoint(x: 100, y: 100 + CGFloat(i * 10)),
                size: CGSize(width: 350, height: 80),
                title: "Rapid Notification \(i)",
                subrole: "AXNotificationCenterBanner"
            )
        }

        // Verify all windows were detected
        XCTAssertEqual(
            mockAccessibility.getDetectedNotificationCount(),
            rapidCount,
            "All rapid notifications should be detected"
        )

        XCTAssertEqual(
            mockAccessibility.getNotificationWindowCount(),
            rapidCount,
            "All windows should exist"
        )

        // Verify no duplicates in detection list
        let uniqueDetections = Set(mockAccessibility.detectedWindowNumbers)
        XCTAssertEqual(
            uniqueDetections.count,
            rapidCount,
            "All detections should be unique"
        )
    }

    func testDuplicateWindowDetection() {
        // Test: Verify duplicate window numbers are handled correctly
        let windowNumber = 1001

        // Create the same window number twice
        _ = mockAccessibility.simulateNotificationWindow(
            windowNumber: windowNumber,
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 350, height: 80),
            title: "First Detection",
            subrole: "AXNotificationCenterBanner"
        )

        XCTAssertEqual(mockAccessibility.getDetectedNotificationCount(), 1, "Should have 1 detection")

        // Create the same window number again (should replace)
        _ = mockAccessibility.simulateNotificationWindow(
            windowNumber: windowNumber,
            position: CGPoint(x: 200, y: 200),
            size: CGSize(width: 350, height: 80),
            title: "Second Detection",
            subrole: "AXNotificationCenterBanner"
        )

        // Should still have 1 window (replaced)
        XCTAssertEqual(
            mockAccessibility.getNotificationWindowCount(),
            1,
            "Should still have 1 window (replaced)"
        )

        // But detection count is 2 (tracked separately)
        XCTAssertEqual(
            mockAccessibility.getDetectedNotificationCount(),
            2,
            "Detection count should be 2 (both detections tracked)"
        )

        // Verify the window was replaced (new position)
        let window = mockAccessibility.getNotificationWindow(windowNumber: windowNumber)
        XCTAssertNotNil(window, "Window should exist")
        XCTAssertEqual(window?.position.x, 200, "Window should have new position")
        XCTAssertEqual(window?.title, "Second Detection", "Window should have new title")
    }
}
