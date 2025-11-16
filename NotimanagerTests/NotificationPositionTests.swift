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
        // Verify all 9 positions exist
        XCTAssertEqual(NotificationPosition.allCases.count, 9, "Should have exactly 9 notification positions")
    }

    // MARK: - Display Name Tests

    func testDisplayNames() {
        XCTAssertEqual(NotificationPosition.topLeft.displayName, "Top Left")
        XCTAssertEqual(NotificationPosition.topMiddle.displayName, "Top Middle")
        XCTAssertEqual(NotificationPosition.topRight.displayName, "Top Right")
        XCTAssertEqual(NotificationPosition.middleLeft.displayName, "Middle Left")
        XCTAssertEqual(NotificationPosition.deadCenter.displayName, "Middle")
        XCTAssertEqual(NotificationPosition.middleRight.displayName, "Middle Right")
        XCTAssertEqual(NotificationPosition.bottomLeft.displayName, "Bottom Left")
        XCTAssertEqual(NotificationPosition.bottomMiddle.displayName, "Bottom Middle")
        XCTAssertEqual(NotificationPosition.bottomRight.displayName, "Bottom Right")
    }

    // MARK: - Raw Value Tests

    func testRawValues() {
        XCTAssertEqual(NotificationPosition.topLeft.rawValue, "topLeft")
        XCTAssertEqual(NotificationPosition.topMiddle.rawValue, "topMiddle")
        XCTAssertEqual(NotificationPosition.topRight.rawValue, "topRight")
        XCTAssertEqual(NotificationPosition.middleLeft.rawValue, "middleLeft")
        XCTAssertEqual(NotificationPosition.deadCenter.rawValue, "deadCenter")
        XCTAssertEqual(NotificationPosition.middleRight.rawValue, "middleRight")
        XCTAssertEqual(NotificationPosition.bottomLeft.rawValue, "bottomLeft")
        XCTAssertEqual(NotificationPosition.bottomMiddle.rawValue, "bottomMiddle")
        XCTAssertEqual(NotificationPosition.bottomRight.rawValue, "bottomRight")
    }

    // MARK: - Initialization Tests

    func testInitializationFromRawValue() {
        XCTAssertNotNil(NotificationPosition(rawValue: "topLeft"))
        XCTAssertNotNil(NotificationPosition(rawValue: "deadCenter"))
        XCTAssertNotNil(NotificationPosition(rawValue: "bottomRight"))
        XCTAssertNil(NotificationPosition(rawValue: "invalid"))
    }
}
