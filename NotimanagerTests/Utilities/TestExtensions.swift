//
//  TestExtensions.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
@testable import Notimanager

/// Base test class with common setup/teardown and wait helpers
/// All test classes should inherit from this to get consistent behavior
class NotimanagerTestCase: XCTestCase {

    // MARK: - Properties

    var testDefaults: UserDefaults!
    var testSuiteName: String?

    // MARK: - Setup/Teardown

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        testDefaults = nil
        testSuiteName = nil
        super.tearDown()
    }

    // MARK: - UserDefaults Isolation Helpers

    /// Creates an isolated UserDefaults instance for testing
    /// - Returns: A UserDefaults instance with a unique suite name
    func createTestDefaults() -> UserDefaults {
        let suiteName = "test_\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    /// Cleans up a test UserDefaults instance
    /// - Parameter defaults: The UserDefaults instance to clean up
    func cleanupTestDefaults(_ defaults: UserDefaults) {
        guard let suiteName = testSuiteName else { return }
        defaults.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Wait Helpers

    /// Waits for a condition to be true within a timeout
    /// - Parameters:
    ///   - condition: The condition to evaluate
    ///   - timeout: The maximum time to wait (default: 1.0 second)
    ///   - description: Description of what's being waited for
    func waitForCondition(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 1.0,
        description: String = "condition to be true"
    ) {
        let expectation = self.expectation(description: description)

        let startTime = Date()
        let checkInterval: TimeInterval = 0.01

        // Check condition periodically
        Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { timer in
            if condition() {
                timer.invalidate()
                expectation.fulfill()
            } else if Date().timeIntervalSince(startTime) >= timeout {
                timer.invalidate()
                XCTFail("Timeout waiting for \(description)")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: timeout + 0.1)
    }

    /// Waits for an async operation to complete
    /// - Parameters:
    ///   - block: The async block to execute
    ///   - timeout: The maximum time to wait (default: 1.0 second)
    /// - Returns: The result of the async operation
    func waitForAsync<T>(
        _ block: @escaping (@escaping (T) -> Void) -> Void,
        timeout: TimeInterval = 1.0
    ) throws -> T {
        var result: T?

        let expectation = self.expectation(description: "Async operation completes")

        block { (value: T) in
            result = value
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)

        guard let finalResult = result else {
            XCTFail("Async operation returned nil")
            throw TestError.nilResult
        }

        return finalResult
    }

    // MARK: - Assertion Helpers

    /// Asserts that two CGFloat values are approximately equal
    /// - Parameters:
    ///   - actual: The actual value
    ///   - expected: The expected value
    ///   - accuracy: The maximum allowed difference (default: 0.001)
    ///   - message: Optional message for the assertion
    func assertCGFloatEqual(
        _ actual: CGFloat,
        _ expected: CGFloat,
        accuracy: CGFloat = 0.001,
        _ message: String = ""
    ) {
        let difference = abs(actual - expected)
        XCTAssertTrue(
            difference <= accuracy,
            "\(message) - Expected \(expected), got \(actual) (difference: \(difference))"
        )
    }

    /// Asserts that two CGPoint values are approximately equal
    /// - Parameters:
    ///   - actual: The actual value
    ///   - expected: The expected value
    ///   - accuracy: The maximum allowed difference for each coordinate (default: 0.001)
    ///   - message: Optional message for the assertion
    func assertCGPointEqual(
        _ actual: CGPoint,
        _ expected: CGPoint,
        accuracy: CGFloat = 0.001,
        _ message: String = ""
    ) {
        assertCGFloatEqual(
            actual.x,
            expected.x,
            accuracy: accuracy,
            "\(message) - x coordinate"
        )
        assertCGFloatEqual(
            actual.y,
            expected.y,
            accuracy: accuracy,
            "\(message) - y coordinate"
        )
    }

    /// Asserts that two NSRect values are approximately equal
    /// - Parameters:
    ///   - actual: The actual value
    ///   - expected: The expected value
    ///   - accuracy: The maximum allowed difference for each dimension (default: 0.001)
    ///   - message: Optional message for the assertion
    func assertNSRectEqual(
        _ actual: NSRect,
        _ expected: NSRect,
        accuracy: CGFloat = 0.001,
        _ message: String = ""
    ) {
        assertCGPointEqual(
            actual.origin,
            expected.origin,
            accuracy: accuracy,
            "\(message) - origin"
        )
        assertCGSizeEqual(
            actual.size,
            expected.size,
            accuracy: accuracy,
            "\(message) - size"
        )
    }

    /// Asserts that two NSSize values are approximately equal
    /// - Parameters:
    ///   - actual: The actual value
    ///   - expected: The expected value
    ///   - accuracy: The maximum allowed difference for each dimension (default: 0.001)
    ///   - message: Optional message for the assertion
    func assertCGSizeEqual(
        _ actual: NSSize,
        _ expected: NSSize,
        accuracy: CGFloat = 0.001,
        _ message: String = ""
    ) {
        assertCGFloatEqual(
            actual.width,
            expected.width,
            accuracy: accuracy,
            "\(message) - width"
        )
        assertCGFloatEqual(
            actual.height,
            expected.height,
            accuracy: accuracy,
            "\(message) - height"
        )
    }
}

// MARK: - Test Errors

enum TestError: Error {
    case nilResult
    case timeout
    case conditionFailed
}
