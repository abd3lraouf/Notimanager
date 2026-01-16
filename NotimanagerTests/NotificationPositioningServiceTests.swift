//
//  NotificationPositioningServiceTests.swift
//  NotimanagerTests
//
//  Created on 2026-01-15.
//

import XCTest
@testable import Notimanager

final class NotificationPositioningServiceTests: XCTestCase {

    var service: NotificationPositioningService!
    
    // Standard 1080p Screen
    let fullFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    // Visible: Menu Bar 24px (Top), Dock 80px (Bottom)
    // Visible Y range: 80 to 1056 (height 976)
    let visibleFrame = CGRect(x: 0, y: 80, width: 1920, height: 976)
    
    let notifSize = CGSize(width: 300, height: 80)
    let padding: CGFloat = 20

    override func setUp() {
        super.setUp()
        service = NotificationPositioningService.shared
    }

    func testTopLeft() {
        // SafeTop = 1080 - 1056 = 24
        // X = 0 + 20 = 20
        // Y = 24 + 20 = 44
        let pos = service.calculatePosition(
            currentPosition: .topLeft,
            notifSize: notifSize,
            padding: padding,
            visibleFrame: visibleFrame,
            fullFrame: fullFrame
        )
        XCTAssertEqual(pos.x, 20)
        XCTAssertEqual(pos.y, 44)
    }

    func testTopRight() {
        // SafeRight = 1920
        // X = 1920 - 300 - 20 = 1600
        // Y = 24 + 20 = 44
        let pos = service.calculatePosition(
            currentPosition: .topRight,
            notifSize: notifSize,
            padding: padding,
            visibleFrame: visibleFrame,
            fullFrame: fullFrame
        )
        XCTAssertEqual(pos.x, 1600)
        XCTAssertEqual(pos.y, 44)
    }

    func testBottomRight() {
        // SafeBottom = 1080 - 80 = 1000
        // X = 1600
        // Y = 1000 - 80 - 20 = 900
        let pos = service.calculatePosition(
            currentPosition: .bottomRight,
            notifSize: notifSize,
            padding: padding,
            visibleFrame: visibleFrame,
            fullFrame: fullFrame
        )
        XCTAssertEqual(pos.x, 1600)
        XCTAssertEqual(pos.y, 900)
    }
    
    func testDeadCenter() {
        // Not used anymore - only 4 corner positions exist
        // This test can be removed or updated to test a corner position instead
        let pos = service.calculatePosition(
            currentPosition: .topRight,
            notifSize: notifSize,
            padding: padding,
            visibleFrame: visibleFrame,
            fullFrame: fullFrame
        )
        // Top Right position - right side with padding
        // SafeRight = 1920 - padding = 1890
        // X = 1890 - 300 = 1590
        // Y = SafeTop + padding = 24
        XCTAssertEqual(pos.x, 1590)
        XCTAssertEqual(pos.y, 24)
    }
    
    func testSecondaryScreen() {
        // Secondary Screen (e.g. Right of main)
        // 1920x1080, aligned at top
        // Frame: (1920, 0, 1920, 1080)
        // No Menu Bar, No Dock (Full visible)
        let secFrame = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let secVisible = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        
        // SafeTop = 1080 - 1080 = 0
        // SafeBottom = 1080 - 0 = 1080
        
        // Top Left
        // X = 1920 + 20 = 1940
        // Y = 0 + 20 = 20
        let pos = service.calculatePosition(
            currentPosition: .topLeft,
            notifSize: notifSize,
            padding: padding,
            visibleFrame: secVisible,
            fullFrame: secFrame
        )
        XCTAssertEqual(pos.x, 1940)
        XCTAssertEqual(pos.y, 20)
    }
}
