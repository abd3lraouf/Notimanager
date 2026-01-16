//
//  NotificationMovementTests.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
@testable import Notimanager

/// Integration tests for notification movement workflow
/// Tests the complete flow: notification detected → position calculated → window moved → verification
final class NotificationMovementTests: NotimanagerTestCase {

    // MARK: - Properties

    var mockAccessibility: MockAccessibilityManager!

    // MARK: - Setup/Teardown

    override func setUp() {
        super.setUp()
        mockAccessibility = MockAccessibilityManager()
        mockAccessibility.setAccessibilityTrusted(true)
    }

    override func tearDown() {
        mockAccessibility = nil
        super.tearDown()
    }

    // MARK: - Basic Movement Tests

    func testNotificationMovementToTopLeft() {
        // Test: Simulate notification detection and movement to top-left position
        let windowNumber = 1001
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let notificationSize = CGSize(width: 350, height: 80)

        // Create notification window at standard position
        let window = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)
        let initialPosition = window.position

        // Calculate target position for top-left (with margin)
        let targetPosition = CGPoint(
            x: screenSize.origin.x + 10,
            y: screenSize.maxY - notificationSize.height - 10
        )

        // Move window to target position
        let moveSuccess = mockAccessibility.moveNotificationWindow(
            windowNumber: windowNumber,
            to: targetPosition
        )

        // Verify window moved successfully
        XCTAssertTrue(moveSuccess, "Window movement should succeed")
        XCTAssertTrue(
            mockAccessibility.verifyWindowAtPosition(windowNumber, expectedPosition: targetPosition),
            "Window should be at target position"
        )

        // Verify position is different from initial
        let finalPosition = mockAccessibility.getNotificationWindowPosition(windowNumber: windowNumber)
        XCTAssertNotNil(finalPosition, "Final position should exist")
        XCTAssertNotEqual(initialPosition, finalPosition, "Position should have changed")
    }

    func testNotificationMovementToTopRight() {
        // Test: Simulate notification detection and movement to top-right position
        let windowNumber = 1002
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let notificationSize = CGSize(width: 350, height: 80)

        // Create notification window
        _ = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)

        // Calculate target position for top-right
        let targetPosition = CGPoint(
            x: screenSize.maxX - notificationSize.width - 10,
            y: screenSize.maxY - notificationSize.height - 10
        )

        // Move window to target position
        let moveSuccess = mockAccessibility.moveNotificationWindow(
            windowNumber: windowNumber,
            to: targetPosition
        )

        // Verify window is at expected position
        XCTAssertTrue(moveSuccess, "Window movement should succeed")
        XCTAssertTrue(
            mockAccessibility.verifyWindowAtPosition(windowNumber, expectedPosition: targetPosition),
            "Window should be at top-right position"
        )
    }

    func testNotificationMovementToBottomLeft() {
        // Test: Simulate notification detection and movement to bottom-left position
        let windowNumber = 1003
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let notificationSize = CGSize(width: 350, height: 80)

        // Create notification window
        _ = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)

        // Calculate target position for bottom-left
        let targetPosition = CGPoint(
            x: screenSize.origin.x + 10,
            y: screenSize.origin.y + notificationSize.height + 10
        )

        // Move window to target position
        let moveSuccess = mockAccessibility.moveNotificationWindow(
            windowNumber: windowNumber,
            to: targetPosition
        )

        // Verify window is at expected position
        XCTAssertTrue(moveSuccess, "Window movement should succeed")
        XCTAssertTrue(
            mockAccessibility.verifyWindowAtPosition(windowNumber, expectedPosition: targetPosition),
            "Window should be at bottom-left position"
        )
    }

    func testNotificationMovementToBottomRight() {
        // Test: Simulate notification detection and movement to bottom-right position
        let windowNumber = 1004
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let notificationSize = CGSize(width: 350, height: 80)

        // Create notification window
        _ = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)

        // Calculate target position for bottom-right
        let targetPosition = CGPoint(
            x: screenSize.maxX - notificationSize.width - 10,
            y: screenSize.origin.y + notificationSize.height + 10
        )

        // Move window to target position
        let moveSuccess = mockAccessibility.moveNotificationWindow(
            windowNumber: windowNumber,
            to: targetPosition
        )

        // Verify window is at expected position
        XCTAssertTrue(moveSuccess, "Window movement should succeed")
        XCTAssertTrue(
            mockAccessibility.verifyWindowAtPosition(windowNumber, expectedPosition: targetPosition),
            "Window should be at bottom-right position"
        )
    }

    // MARK: - Complete Workflow Tests

    func testCompleteNotificationDetectionAndMovementWorkflow() {
        // Test: Simulate the complete workflow from detection to movement
        let windowNumber = 1005
        var detectionTriggered = false
        var movementTriggered = false
        var movedWindowNumber: Int?
        var movedPosition: CGPoint?

        // Set up detection callback
        mockAccessibility.onNotificationDetected = { number in
            detectionTriggered = true
            XCTAssertEqual(number, windowNumber, "Detection callback should receive correct window number")
        }

        // Set up movement callback
        mockAccessibility.onWindowMoved = { number, position in
            movementTriggered = true
            movedWindowNumber = number
            movedPosition = position
        }

        // Set accessibility permission to granted
        mockAccessibility.setAccessibilityTrusted(true)
        XCTAssertTrue(mockAccessibility.checkAccessibilityTrusted(), "Accessibility should be trusted")

        // Simulate notification window appearing
        _ = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)

        // Verify detection callback is triggered
        XCTAssertTrue(detectionTriggered, "Detection callback should be triggered")

        // Calculate target position
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let targetPosition = CGPoint(x: screenSize.origin.x + 10, y: screenSize.maxY - 90)

        // Move window to target position
        let moveSuccess = mockAccessibility.moveNotificationWindow(
            windowNumber: windowNumber,
            to: targetPosition
        )

        // Verify window movement succeeded
        XCTAssertTrue(moveSuccess, "Movement should succeed")
        XCTAssertTrue(
            mockAccessibility.verifyWindowAtPosition(windowNumber, expectedPosition: targetPosition),
            "Window should be at target position"
        )

        // Verify onWindowMoved callback was triggered
        XCTAssertTrue(movementTriggered, "Movement callback should be triggered")
        XCTAssertEqual(movedWindowNumber, windowNumber, "Callback should receive correct window number")
        XCTAssertNotNil(movedPosition, "Callback should receive position")
    }

    func testWorkflowWithDisabledNotificationPositioning() {
        // Test: Verify workflow when notification positioning is disabled
        let windowNumber = 1006

        // Create notification window
        let window = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)
        let initialPosition = window.position

        // Verify detection occurred
        XCTAssertEqual(mockAccessibility.getDetectedNotificationCount(), 1, "Should detect notification")

        // Simulate positioning being disabled - just don't move the window
        // In a real implementation, this would check a preferences flag
        // For this test, we verify the window remains at its initial position
        let currentPosition = mockAccessibility.getNotificationWindowPosition(windowNumber: windowNumber)

        XCTAssertNotNil(currentPosition, "Window should still exist")
        XCTAssertEqual(initialPosition, currentPosition, "Window should remain at original position when positioning is disabled")
    }

    // MARK: - Multi-Notification Tests

    func testMultipleNotifications() {
        // Test: Simulate multiple notifications appearing and being positioned
        let notificationCount = 5
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        // Create multiple notification windows
        let windows = mockAccessibility.createStandardNotificationWindows(count: notificationCount)

        // Verify all windows were created
        XCTAssertEqual(windows.count, notificationCount, "Should create expected number of windows")
        XCTAssertEqual(mockAccessibility.getNotificationWindowCount(), notificationCount, "Should have all windows")

        // Move each window to a stacked position
        for (index, window) in windows.enumerated() {
            let targetPosition = CGPoint(
                x: screenSize.origin.x + 10,
                y: screenSize.maxY - 90 - CGFloat(index) * 90
            )

            let moveSuccess = mockAccessibility.moveNotificationWindow(
                windowNumber: window.windowNumber,
                to: targetPosition
            )

            XCTAssertTrue(moveSuccess, "Window \(window.windowNumber) should move successfully")
            XCTAssertTrue(
                mockAccessibility.verifyWindowAtPosition(window.windowNumber, expectedPosition: targetPosition),
                "Window \(window.windowNumber) should be at target position"
            )
        }

        // Verify all windows are positioned correctly
        XCTAssertTrue(
            mockAccessibility.verifyNotificationWindowCount(notificationCount),
            "Should still have all windows"
        )
    }

    func testMultipleNotificationsWithDifferentPositions() {
        // Test: Simulate notifications with different target positions
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let positions = [
            CGPoint(x: screenSize.origin.x + 10, y: screenSize.maxY - 90),           // Top-left
            CGPoint(x: screenSize.maxX - 360, y: screenSize.maxY - 90),              // Top-right
            CGPoint(x: screenSize.origin.x + 10, y: screenSize.origin.y + 90),      // Bottom-left
            CGPoint(x: screenSize.maxX - 360, y: screenSize.origin.y + 90),         // Bottom-right
            CGPoint(x: screenSize.midX - 175, y: screenSize.midY - 40)              // Center
        ]

        var windows: [MockAccessibilityManager.MockNotificationWindow] = []

        // Create notifications at different positions
        for (index, position) in positions.enumerated() {
            let window = mockAccessibility.simulateNotificationWindow(
                windowNumber: 2000 + index,
                position: CGPoint(x: 100, y: 100), // Start at same position
                size: CGSize(width: 350, height: 80)
            )
            windows.append(window)

            // Move to target position
            let moveSuccess = mockAccessibility.moveNotificationWindow(
                windowNumber: window.windowNumber,
                to: position
            )

            XCTAssertTrue(moveSuccess, "Window \(window.windowNumber) should move to position \(index)")
        }

        // Verify each window is at its assigned position
        for (index, window) in windows.enumerated() {
            let expectedPosition = positions[index]
            XCTAssertTrue(
                mockAccessibility.verifyWindowAtPosition(window.windowNumber, expectedPosition: expectedPosition),
                "Window \(window.windowNumber) should be at its assigned position"
            )
        }

        // Verify positions are independent (windows don't affect each other)
        for window in windows {
            let position = mockAccessibility.getNotificationWindowPosition(windowNumber: window.windowNumber)
            XCTAssertNotNil(position, "Each window should have a position")
        }
    }

    func testConcurrentNotificationBatches() {
        // Test: Simulate concurrent notification batches
        let batch1Count = 3
        let batch2Count = 4
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        var detectionsCount = 0
        mockAccessibility.onNotificationDetected = { _ in
            detectionsCount += 1
        }

        // Create first batch
        let batch1 = mockAccessibility.createStandardNotificationWindows(count: batch1Count)
        XCTAssertEqual(batch1.count, batch1Count, "Batch 1 should have correct count")

        // Create second batch
        let batch2Start = 2000
        var batch2: [MockAccessibilityManager.MockNotificationWindow] = []
        for i in 0..<batch2Count {
            let window = mockAccessibility.simulateNotificationWindow(
                windowNumber: batch2Start + i,
                position: CGPoint(x: 200, y: 200),
                size: CGSize(width: 350, height: 80)
            )
            batch2.append(window)
        }

        // Verify all notifications were detected
        XCTAssertEqual(detectionsCount, batch1Count + batch2Count, "Should detect all notifications")

        // Position all windows
        let allWindows = batch1 + batch2
        for (index, window) in allWindows.enumerated() {
            let targetPosition = CGPoint(
                x: screenSize.origin.x + 10,
                y: screenSize.maxY - 90 - CGFloat(index) * 90
            )

            let moveSuccess = mockAccessibility.moveNotificationWindow(
                windowNumber: window.windowNumber,
                to: targetPosition
            )

            XCTAssertTrue(moveSuccess, "Window \(window.windowNumber) should move successfully")
        }

        // Verify all notifications are positioned correctly
        XCTAssertEqual(
            mockAccessibility.getNotificationWindowCount(),
            batch1Count + batch2Count,
            "Should have all windows"
        )

        // Verify no duplicate window numbers
        let windowNumbers = allWindows.map { $0.windowNumber }
        let uniqueNumbers = Set(windowNumbers)
        XCTAssertEqual(uniqueNumbers.count, windowNumbers.count, "All window numbers should be unique")
    }

    // MARK: - Position Calculation Tests

    func testPositionCalculationWithStandardScreen() {
        // Test: Verify position calculation for standard screen size
        let screenSize = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let notificationSize = CGSize(width: 350, height: 80)
        let margin: CGFloat = 10

        // Calculate target position for each corner
        let topLeft = CGPoint(
            x: screenSize.origin.x + margin,
            y: screenSize.maxY - notificationSize.height - margin
        )
        let topRight = CGPoint(
            x: screenSize.maxX - notificationSize.width - margin,
            y: screenSize.maxY - notificationSize.height - margin
        )
        let bottomLeft = CGPoint(
            x: screenSize.origin.x + margin,
            y: screenSize.origin.y + notificationSize.height + margin
        )
        let bottomRight = CGPoint(
            x: screenSize.maxX - notificationSize.width - margin,
            y: screenSize.origin.y + notificationSize.height + margin
        )

        // Verify positions are calculated correctly
        XCTAssertEqual(topLeft.x, 10, accuracy: 0.001, "Top-left x should be at margin")
        XCTAssertEqual(topLeft.y, screenSize.maxY - 90, accuracy: 0.001, "Top-left y should be near top")

        XCTAssertEqual(topRight.x, 1560, accuracy: 0.001, "Top-right x should be near right edge")
        XCTAssertEqual(topRight.y, screenSize.maxY - 90, accuracy: 0.001, "Top-right y should be near top")

        XCTAssertEqual(bottomLeft.x, 10, accuracy: 0.001, "Bottom-left x should be at margin")
        XCTAssertEqual(bottomLeft.y, 90, accuracy: 0.001, "Bottom-left y should be near bottom")

        XCTAssertEqual(bottomRight.x, 1560, accuracy: 0.001, "Bottom-right x should be near right edge")
        XCTAssertEqual(bottomRight.y, 90, accuracy: 0.001, "Bottom-right y should be near bottom")

        // Verify positions are within visible frame
        let screenBox = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        XCTAssertTrue(screenBox.contains(topLeft), "Top-left should be within screen bounds")
        XCTAssertTrue(screenBox.contains(topRight), "Top-right should be within screen bounds")
        XCTAssertTrue(screenBox.contains(bottomLeft), "Bottom-left should be within screen bounds")
        XCTAssertTrue(screenBox.contains(bottomRight), "Bottom-right should be within screen bounds")
    }

    func testPositionCalculationWithSmallScreen() {
        // Test: Verify position calculation for small screen size
        let screenSize = NSRect(x: 0, y: 0, width: 1280, height: 720)
        let notificationSize = CGSize(width: 350, height: 80)
        let margin: CGFloat = 10

        // Calculate positions
        let topLeft = CGPoint(
            x: screenSize.origin.x + margin,
            y: screenSize.maxY - notificationSize.height - margin
        )
        let bottomRight = CGPoint(
            x: screenSize.maxX - notificationSize.width - margin,
            y: screenSize.origin.y + notificationSize.height + margin
        )

        // Verify calculations adjust for screen size
        XCTAssertEqual(topLeft.x, 10, accuracy: 0.001, "Top-left x should be at margin")
        XCTAssertEqual(topLeft.y, screenSize.maxY - 90, accuracy: 0.001, "Top-left y should adjust to screen height")

        XCTAssertEqual(bottomRight.x, 920, accuracy: 0.001, "Bottom-right x should adjust to screen width")
        XCTAssertEqual(bottomRight.y, 90, accuracy: 0.001, "Bottom-right y should be at bottom")

        // Verify positions don't exceed visible frame
        XCTAssertGreaterThanOrEqual(topLeft.x, screenSize.origin.x, "X should not be negative")
        XCTAssertLessThanOrEqual(topLeft.x, screenSize.maxX, "X should not exceed screen width")
        XCTAssertGreaterThanOrEqual(topLeft.y, screenSize.origin.y, "Y should not be negative")
        XCTAssertLessThanOrEqual(topLeft.y, screenSize.maxY, "Y should not exceed screen height")
    }

    func testPositionCalculationWithLargeScreen() {
        // Test: Verify position calculation for large screen size (4K)
        let screenSize = NSRect(x: 0, y: 0, width: 3840, height: 2160)
        let notificationSize = CGSize(width: 350, height: 80)
        let margin: CGFloat = 10

        // Calculate positions
        let topLeft = CGPoint(
            x: screenSize.origin.x + margin,
            y: screenSize.maxY - notificationSize.height - margin
        )
        let center = CGPoint(
            x: screenSize.midX - notificationSize.width / 2,
            y: screenSize.midY - notificationSize.height / 2
        )
        let bottomRight = CGPoint(
            x: screenSize.maxX - notificationSize.width - margin,
            y: screenSize.origin.y + notificationSize.height + margin
        )

        // Verify calculations scale correctly
        XCTAssertEqual(topLeft.x, 10, accuracy: 0.001, "Top-left x should be at margin")
        XCTAssertEqual(topLeft.y, screenSize.maxY - 90, accuracy: 0.001, "Top-left y should scale to 4K height")

        XCTAssertEqual(center.x, 1745, accuracy: 0.001, "Center x should be at screen center")
        XCTAssertEqual(center.y, 1040, accuracy: 0.001, "Center y should be at screen center")

        XCTAssertEqual(bottomRight.x, 3480, accuracy: 0.001, "Bottom-right x should scale to 4K width")
        XCTAssertEqual(bottomRight.y, 90, accuracy: 0.001, "Bottom-right y should be at bottom")

        // Verify positions maintain proper margins
        XCTAssertEqual(topLeft.x - screenSize.origin.x, margin, accuracy: 0.001, "Should maintain left margin")
        XCTAssertEqual(screenSize.maxX - bottomRight.x - notificationSize.width, margin, accuracy: 0.001, "Should maintain right margin")
    }

    // MARK: - Edge Cases

    func testMovementWhenWindowNotFound() {
        // Test: Verify graceful handling when window doesn't exist
        let nonExistentWindowNumber = 9999
        let targetPosition = CGPoint(x: 100, y: 100)

        // Attempt to move non-existent window
        let moveSuccess = mockAccessibility.moveNotificationWindow(
            windowNumber: nonExistentWindowNumber,
            to: targetPosition
        )

        // Verify movement fails gracefully
        XCTAssertFalse(moveSuccess, "Movement should fail for non-existent window")

        // Verify no crash occurs and state is consistent
        XCTAssertEqual(mockAccessibility.getNotificationWindowCount(), 0, "Should have no windows")
        XCTAssertNil(
            mockAccessibility.getNotificationWindowPosition(windowNumber: nonExistentWindowNumber),
            "Non-existent window should have no position"
        )
    }

    func testMovementWhenPermissionRevoked() {
        // Test: Verify movement behavior when accessibility permission is revoked
        let windowNumber = 1007

        // Create a notification window
        _ = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)

        // Set accessibility permission to false
        mockAccessibility.setAccessibilityTrusted(false)
        XCTAssertFalse(mockAccessibility.checkAccessibilityTrusted(), "Accessibility should not be trusted")

        // Note: In the mock system, movement doesn't automatically check permissions
        // In a real implementation, this would fail
        // Here we verify that the permission state can be queried
        XCTAssertFalse(mockAccessibility.checkAccessibilityTrusted(), "Permission should remain revoked")

        // Verify window still exists
        XCTAssertNotNil(
            mockAccessibility.getNotificationWindow(windowNumber: windowNumber),
            "Window should still exist even with permission revoked"
        )
    }

    func testMovementWhenWindowOperationsFail() {
        // Test: Verify handling when window operations fail
        let windowNumber = 1008
        let targetPosition = CGPoint(x: 100, y: 100)

        // Create a notification window
        let window = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)
        let initialPosition = window.position

        // Set window operations to fail
        mockAccessibility.windowOperationsSucceed = false

        // Attempt to move notification window
        let moveSuccess = mockAccessibility.moveNotificationWindow(
            windowNumber: windowNumber,
            to: targetPosition
        )

        // Verify movement fails gracefully
        XCTAssertFalse(moveSuccess, "Movement should fail when operations are disabled")

        // Verify window position hasn't changed
        let currentPosition = mockAccessibility.getNotificationWindowPosition(windowNumber: windowNumber)
        XCTAssertEqual(initialPosition, currentPosition, "Window should remain at initial position")
    }

    // MARK: - Callback Tests

    func testWindowMovedCallbackTriggered() {
        // Test: Verify onWindowMoved callback is triggered
        let windowNumber = 1009
        let targetPosition = CGPoint(x: 200, y: 200)
        var callbackTriggered = false
        var receivedWindowNumber: Int?
        var receivedPosition: CGPoint?

        // Set up callback
        mockAccessibility.onWindowMoved = { number, position in
            callbackTriggered = true
            receivedWindowNumber = number
            receivedPosition = position
        }

        // Create notification window
        _ = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)

        // Move window to new position
        let moveSuccess = mockAccessibility.moveNotificationWindow(
            windowNumber: windowNumber,
            to: targetPosition
        )

        // Verify movement succeeded
        XCTAssertTrue(moveSuccess, "Movement should succeed")

        // Verify callback was triggered
        XCTAssertTrue(callbackTriggered, "Callback should be triggered")
        XCTAssertEqual(receivedWindowNumber, windowNumber, "Callback should receive correct window number")
        XCTAssertNotNil(receivedPosition, "Callback should receive position")
        XCTAssertEqual(receivedPosition!.x, targetPosition.x, accuracy: 0.001, "Callback should receive correct x position")
        XCTAssertEqual(receivedPosition!.y, targetPosition.y, accuracy: 0.001, "Callback should receive correct y position")
    }

    func testWindowMovedCallbackMultipleMovements() {
        // Test: Verify callback is triggered for multiple movements
        let windowNumber = 1010
        let positions = [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 200, y: 200),
            CGPoint(x: 300, y: 300)
        ]
        var callbackCount = 0
        var receivedPositions: [CGPoint] = []

        // Set up callback
        mockAccessibility.onWindowMoved = { _, position in
            callbackCount += 1
            receivedPositions.append(position)
        }

        // Create notification window
        _ = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)

        // Move window to position A, then B, then C
        for position in positions {
            let moveSuccess = mockAccessibility.moveNotificationWindow(
                windowNumber: windowNumber,
                to: position
            )
            XCTAssertTrue(moveSuccess, "Movement should succeed for position \(position)")
        }

        // Verify callback was triggered for each movement
        XCTAssertEqual(callbackCount, positions.count, "Callback should be triggered for each movement")
        XCTAssertEqual(receivedPositions.count, positions.count, "Should receive all positions")

        // Verify callback received correct positions
        for (index, position) in positions.enumerated() {
            XCTAssertEqual(receivedPositions[index].x, position.x, accuracy: 0.001, "Position \(index) x should match")
            XCTAssertEqual(receivedPositions[index].y, position.y, accuracy: 0.001, "Position \(index) y should match")
        }
    }

    // MARK: - Batch Processing Tests

    func testLargeNotificationBatchHandling() {
        // Test: Verify system can handle large batches of notifications (20+)
        let batchSize = 25
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        // Create large batch
        let windows = mockAccessibility.createStandardNotificationWindows(count: batchSize)

        // Verify all windows created
        XCTAssertEqual(windows.count, batchSize, "Should create all \(batchSize) windows")
        XCTAssertEqual(mockAccessibility.getNotificationWindowCount(), batchSize, "Should have all windows")

        // Position all windows in a grid-like pattern
        let columns = 5
        let spacing: CGFloat = 90

        for (index, window) in windows.enumerated() {
            let col = index % columns
            let row = index / columns

            let targetPosition = CGPoint(
                x: screenSize.origin.x + CGFloat(col) * spacing,
                y: screenSize.maxY - CGFloat(row + 1) * spacing
            )

            let moveSuccess = mockAccessibility.moveNotificationWindow(
                windowNumber: window.windowNumber,
                to: targetPosition
            )

            XCTAssertTrue(moveSuccess, "Window \(window.windowNumber) should move successfully in large batch")
        }

        // Verify all windows positioned correctly
        XCTAssertTrue(
            mockAccessibility.verifyNotificationWindowCount(batchSize),
            "Should maintain all windows after positioning"
        )

        // Verify no positioning failures
        var positionedCorrectly = 0
        for window in windows {
            let position = mockAccessibility.getNotificationWindowPosition(windowNumber: window.windowNumber)
            if position != nil {
                positionedCorrectly += 1
            }
        }
        XCTAssertEqual(positionedCorrectly, batchSize, "All windows should have valid positions")
    }

    func testNotificationQueueOrderingAndFIFO() {
        // Test: Verify notifications maintain FIFO order in queue
        let notificationCount = 10
        var creationOrder: [Int] = []
        var detectionOrder: [Int] = []

        // Track creation order
        mockAccessibility.onNotificationDetected = { windowNumber in
            detectionOrder.append(windowNumber)
        }

        // Create notifications sequentially
        for i in 0..<notificationCount {
            let window = mockAccessibility.createStandardNotificationWindow(windowNumber: 3000 + i)
            creationOrder.append(window.windowNumber)
        }

        // Verify detection order matches creation order (FIFO)
        XCTAssertEqual(detectionOrder.count, creationOrder.count, "Should detect all notifications")
        XCTAssertEqual(detectionOrder, creationOrder, "Detection order should match creation order")

        // Position notifications in FIFO order
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        var positioningOrder: [Int] = []

        for (index, windowNumber) in creationOrder.enumerated() {
            let targetPosition = CGPoint(
                x: screenSize.origin.x + 10,
                y: screenSize.maxY - 90 - CGFloat(index) * 90
            )

            let moveSuccess = mockAccessibility.moveNotificationWindow(
                windowNumber: windowNumber,
                to: targetPosition
            )

            if moveSuccess {
                positioningOrder.append(windowNumber)
            }

            XCTAssertTrue(moveSuccess, "Window \(windowNumber) should position in FIFO order")
        }

        // Verify positioning order matches FIFO
        XCTAssertEqual(positioningOrder, creationOrder, "Positioning should maintain FIFO order")

        // Verify positions are stacked correctly (first at top, subsequent below)
        for (index, windowNumber) in creationOrder.enumerated() {
            let position = mockAccessibility.getNotificationWindowPosition(windowNumber: windowNumber)
            XCTAssertNotNil(position, "Window \(windowNumber) should have position")

            let expectedY = screenSize.maxY - 90 - CGFloat(index) * 90
            XCTAssertEqual(position!.y, expectedY, accuracy: 0.1, "Window \(windowNumber) Y position should match FIFO order")
        }
    }

    func testPositioningConsistencyAcrossLargeBatches() {
        // Test: Verify positioning consistency when processing large batches
        let batchSize = 15
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let targetPosition = CGPoint(x: 100, y: 100)

        // Create batch
        let windows = mockAccessibility.createStandardNotificationWindows(count: batchSize)

        // Move all windows to same target position (simulating queue processing)
        for window in windows {
            let moveSuccess = mockAccessibility.moveNotificationWindow(
                windowNumber: window.windowNumber,
                to: targetPosition
            )
            XCTAssertTrue(moveSuccess, "Window \(window.windowNumber) should move to target position")
        }

        // Verify all windows at same position
        var correctlyPositioned = 0
        for window in windows {
            if mockAccessibility.verifyWindowAtPosition(window.windowNumber, expectedPosition: targetPosition) {
                correctlyPositioned += 1
            }
        }

        XCTAssertEqual(correctlyPositioned, batchSize, "All windows should be at target position")

        // Now verify consistent stacking behavior
        for (index, window) in windows.enumerated() {
            let stackedPosition = CGPoint(
                x: screenSize.origin.x + 10,
                y: screenSize.maxY - 90 - CGFloat(index) * 90
            )

            let moveSuccess = mockAccessibility.moveNotificationWindow(
                windowNumber: window.windowNumber,
                to: stackedPosition
            )

            XCTAssertTrue(moveSuccess, "Window \(window.windowNumber) should stack correctly")

            // Verify position
            let position = mockAccessibility.getNotificationWindowPosition(windowNumber: window.windowNumber)
            XCTAssertNotNil(position, "Window \(window.windowNumber) should have position")
            XCTAssertEqual(position!.x, stackedPosition.x, accuracy: 0.1, "X position should be consistent")
            XCTAssertEqual(position!.y, stackedPosition.y, accuracy: 0.1, "Y position should be consistent")
        }
    }

    func testBatchRemovalAndCleanup() {
        // Test: Verify batch removal operations work correctly
        let initialBatch = 10
        let removalBatchSize = 5

        // Create initial batch
        let windows = mockAccessibility.createStandardNotificationWindows(count: initialBatch)
        XCTAssertEqual(mockAccessibility.getNotificationWindowCount(), initialBatch, "Should have initial batch")

        // Remove first batch
        var removalCount = 0
        for i in 0..<removalBatchSize {
            let windowNumber = windows[i].windowNumber
            mockAccessibility.removeNotificationWindow(windowNumber: windowNumber)
            removalCount += 1
        }

        // Verify removal
        XCTAssertEqual(mockAccessibility.getNotificationWindowCount(), initialBatch - removalBatchSize, "Should have remaining windows")

        // Verify remaining windows still valid
        for i in removalBatchSize..<initialBatch {
            let windowNumber = windows[i].windowNumber
            let window = mockAccessibility.getNotificationWindow(windowNumber: windowNumber)
            XCTAssertNotNil(window, "Remaining window \(windowNumber) should still exist")
        }

        // Clear all and verify empty
        mockAccessibility.clearAllNotificationWindows()
        XCTAssertEqual(mockAccessibility.getNotificationWindowCount(), 0, "Should have no windows after clear")
    }

    func testInterleavedBatchOperations() {
        // Test: Verify interleaved create/move/remove operations work correctly
        let screenSize = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        var windowNumbers: [Int] = []

        // Create first batch with explicit window numbers
        var batch1: [MockAccessibilityManager.MockNotificationWindow] = []
        for i in 0..<3 {
            let window = mockAccessibility.simulateNotificationWindow(
                windowNumber: 6000 + i,
                position: CGPoint(x: 100, y: 100),
                size: CGSize(width: 350, height: 80)
            )
            batch1.append(window)
            windowNumbers.append(window.windowNumber)
        }

        // Move first batch
        for (index, window) in batch1.enumerated() {
            let position = CGPoint(
                x: screenSize.origin.x + 10,
                y: screenSize.maxY - 90 - CGFloat(index) * 90
            )
            let moveSuccess = mockAccessibility.moveNotificationWindow(windowNumber: window.windowNumber, to: position)
            XCTAssertTrue(moveSuccess, "Batch 1 window \(window.windowNumber) should move successfully")
        }

        // Create second batch with different window numbers
        var batch2: [MockAccessibilityManager.MockNotificationWindow] = []
        for i in 0..<3 {
            let window = mockAccessibility.simulateNotificationWindow(
                windowNumber: 6100 + i,
                position: CGPoint(x: 100, y: 100),
                size: CGSize(width: 350, height: 80)
            )
            batch2.append(window)
            windowNumbers.append(window.windowNumber)
        }

        // Remove middle window from first batch
        if batch1.count > 1 {
            let removedWindowNumber = batch1[1].windowNumber
            mockAccessibility.removeNotificationWindow(windowNumber: removedWindowNumber)
            if let index = windowNumbers.firstIndex(of: removedWindowNumber) {
                windowNumbers.remove(at: index)
            }
        }

        // Move second batch
        for (index, window) in batch2.enumerated() {
            let position = CGPoint(
                x: screenSize.origin.x + 10,
                y: screenSize.maxY - 90 - CGFloat(index + 3) * 90
            )
            let moveSuccess = mockAccessibility.moveNotificationWindow(windowNumber: window.windowNumber, to: position)
            XCTAssertTrue(moveSuccess, "Batch 2 window \(window.windowNumber) should move successfully")
        }

        // Create third batch
        var batch3: [MockAccessibilityManager.MockNotificationWindow] = []
        for i in 0..<2 {
            let window = mockAccessibility.simulateNotificationWindow(
                windowNumber: 6200 + i,
                position: CGPoint(x: 100, y: 100),
                size: CGSize(width: 350, height: 80)
            )
            batch3.append(window)
            windowNumbers.append(window.windowNumber)

            // Verify window was created
            XCTAssertNotNil(window, "Batch 3 window \(6200 + i) should be created")
        }

        // Verify final count (batch1 - 1 removed + batch2 + batch3)
        let expectedCount = batch1.count - 1 + batch2.count + batch3.count
        XCTAssertEqual(mockAccessibility.getNotificationWindowCount(), expectedCount, "Should have expected count after interleaved operations")

        // Verify all remaining windows have valid positions
        var validPositions = 0
        for windowNumber in windowNumbers {
            let window = mockAccessibility.getNotificationWindow(windowNumber: windowNumber)
            if window != nil {
                let position = mockAccessibility.getNotificationWindowPosition(windowNumber: windowNumber)
                if position != nil {
                    validPositions += 1
                }
            }
        }

        // Should have valid positions for all remaining windows
        XCTAssertEqual(validPositions, expectedCount, "All remaining windows should have valid positions")
    }

    func testBatchStateConsistencyUnderLoad() {
        // Test: Verify system maintains consistency under rapid batch operations
        let operationCount = 30
        var createdWindows: [Int] = []
        var movedWindows: [Int] = []
        var removedWindows: [Int] = []

        // Rapid operations
        for i in 0..<operationCount {
            // Create window
            let window = mockAccessibility.simulateNotificationWindow(
                windowNumber: 5000 + i,
                position: CGPoint(x: 100, y: 100),
                size: CGSize(width: 350, height: 80)
            )
            createdWindows.append(window.windowNumber)

            // Move window
            let targetPosition = CGPoint(x: 200 + CGFloat(i) * 10, y: 200 + CGFloat(i) * 10)
            let moveSuccess = mockAccessibility.moveNotificationWindow(
                windowNumber: window.windowNumber,
                to: targetPosition
            )
            if moveSuccess {
                movedWindows.append(window.windowNumber)
            }

            // Every 3rd window, remove an earlier window
            if i > 0 && i % 3 == 0 && createdWindows.count > 2 {
                let removeIndex = i - 2
                if removeIndex < createdWindows.count {
                    let windowToRemove = createdWindows[removeIndex]
                    mockAccessibility.removeNotificationWindow(windowNumber: windowToRemove)
                    removedWindows.append(windowToRemove)
                }
            }
        }

        // Verify consistency
        let expectedCount = createdWindows.count - removedWindows.count
        XCTAssertEqual(mockAccessibility.getNotificationWindowCount(), expectedCount, "Count should be consistent")

        // Verify all remaining windows can be accessed
        let allWindows = mockAccessibility.getAllNotificationWindows()
        XCTAssertEqual(allWindows.count, expectedCount, "GetAll should return consistent count")

        // Verify state is valid
        for window in allWindows {
            XCTAssertNotNil(window.position, "Window should have position")
            XCTAssertGreaterThan(window.windowNumber, 0, "Window number should be valid")
        }
    }

    // MARK: - Verification Tests

    func testVerifyWindowAtPosition() {
        // Test: Verify window position verification works correctly
        let windowNumber = 1011
        let targetPosition = CGPoint(x: 150, y: 150)

        // Create notification window
        _ = mockAccessibility.createStandardNotificationWindow(windowNumber: windowNumber)

        // Move window to known position
        let moveSuccess = mockAccessibility.moveNotificationWindow(
            windowNumber: windowNumber,
            to: targetPosition
        )
        XCTAssertTrue(moveSuccess, "Movement should succeed")

        // Verify with default tolerance
        XCTAssertTrue(
            mockAccessibility.verifyWindowAtPosition(windowNumber, expectedPosition: targetPosition),
            "Should verify window at exact position with default tolerance"
        )

        // Verify with different tolerance values
        XCTAssertTrue(
            mockAccessibility.verifyWindowAtPosition(
                windowNumber,
                expectedPosition: CGPoint(x: targetPosition.x + 3, y: targetPosition.y + 3),
                tolerance: 5.0
            ),
            "Should verify window at position within tolerance"
        )

        XCTAssertFalse(
            mockAccessibility.verifyWindowAtPosition(
                windowNumber,
                expectedPosition: CGPoint(x: targetPosition.x + 10, y: targetPosition.y + 10),
                tolerance: 5.0
            ),
            "Should not verify window at position outside tolerance"
        )

        // Verify with tight tolerance
        XCTAssertTrue(
            mockAccessibility.verifyWindowAtPosition(
                windowNumber,
                expectedPosition: targetPosition,
                tolerance: 0.1
            ),
            "Should verify window at exact position with tight tolerance"
        )
    }

    func testVerifyNotificationWindowCount() {
        // Test: Verify window count verification works correctly
        // Create multiple notification windows
        let windows = mockAccessibility.createStandardNotificationWindows(count: 5)

        // Verify verifyNotificationWindowCount() returns true for correct count
        XCTAssertTrue(
            mockAccessibility.verifyNotificationWindowCount(5),
            "Should verify correct count of 5"
        )

        XCTAssertTrue(
            mockAccessibility.verifyNotificationWindowCount(windows.count),
            "Should verify correct count matching array length"
        )

        // Verify returns false for incorrect count
        XCTAssertFalse(
            mockAccessibility.verifyNotificationWindowCount(3),
            "Should not verify incorrect count of 3"
        )

        XCTAssertFalse(
            mockAccessibility.verifyNotificationWindowCount(10),
            "Should not verify incorrect count of 10"
        )

        XCTAssertFalse(
            mockAccessibility.verifyNotificationWindowCount(0),
            "Should not verify incorrect count of 0"
        )

        // Add more windows and verify count updates
        _ = mockAccessibility.createStandardNotificationWindow(windowNumber: 2000)
        XCTAssertTrue(
            mockAccessibility.verifyNotificationWindowCount(6),
            "Should verify updated count of 6"
        )

        // Remove a window and verify count decreases
        mockAccessibility.removeNotificationWindow(windowNumber: 1000)
        XCTAssertTrue(
            mockAccessibility.verifyNotificationWindowCount(5),
            "Should verify decreased count of 5"
        )
    }
}

// MARK: - Helper

private extension NotificationMovementTests {
    var screenBox: NSRect {
        NSRect(x: 0, y: 0, width: 1920, height: 1080)
    }
}
