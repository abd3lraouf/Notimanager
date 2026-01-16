//
//  NotificationPositionTests.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
@testable import Notimanager

final class NotificationPositionTests: XCTestCase {

    // MARK: - Count Tests

    func testAllPositionsExist() {
        // Verify all 4 corner positions exist
        XCTAssertEqual(NotificationPosition.allCases.count, 4, "Should have exactly 4 notification positions (corners only)")
    }

    // MARK: - Display Name Tests

    func testDisplayNames() {
        XCTAssertEqual(NotificationPosition.topLeft.displayName, "Top Left")
        XCTAssertEqual(NotificationPosition.topRight.displayName, "Top Right")
        XCTAssertEqual(NotificationPosition.bottomLeft.displayName, "Bottom Left")
        XCTAssertEqual(NotificationPosition.bottomRight.displayName, "Bottom Right")
    }

    // MARK: - Raw Value Tests

    func testRawValues() {
        XCTAssertEqual(NotificationPosition.topLeft.rawValue, "top-left")
        XCTAssertEqual(NotificationPosition.topRight.rawValue, "top-right")
        XCTAssertEqual(NotificationPosition.bottomLeft.rawValue, "bottom-left")
        XCTAssertEqual(NotificationPosition.bottomRight.rawValue, "bottom-right")
    }

    // MARK: - Initialization Tests

    func testInitializationFromRawValue() {
        XCTAssertNotNil(NotificationPosition(rawValue: "top-left"))
        XCTAssertNotNil(NotificationPosition(rawValue: "top-right"))
        XCTAssertNotNil(NotificationPosition(rawValue: "bottom-right"))
        XCTAssertNil(NotificationPosition(rawValue: "invalid"))
    }
}
