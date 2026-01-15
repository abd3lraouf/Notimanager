//
//  CommonTestHelpers.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
import Foundation
import AppKit
@testable import Notimanager

/// Common test helpers for integration testing
/// Provides utility methods for common testing scenarios
class CommonTestHelpers {

    // MARK: - Async Testing Helpers

    /// Waits for an async operation to complete with a result
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - operation: Async operation to execute
    /// - Returns: Result of the operation
    static func waitForResult<T>(
        timeout: TimeInterval = 2.0,
        operation: @escaping (@escaping (T) -> Void) -> Void
    ) throws -> T {
        let expectation = XCTestExpectation(description: "Async operation completes")
        var result: T?
        var error: Error?

        operation { value in
            result = value
            expectation.fulfill()
        }

        let waiter = XCTWaiter.wait(for: [expectation], timeout: timeout)

        if waiter != .completed {
            throw TestError.timeout
        }

        guard let finalResult = result else {
            throw TestError.nilResult
        }

        return finalResult
    }

    /// Waits for an async operation to complete without a return value
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - operation: Async operation to execute
    static func waitForCompletion(
        timeout: TimeInterval = 2.0,
        operation: @escaping (@escaping () -> Void) -> Void
    ) throws {
        let expectation = XCTestExpectation(description: "Async operation completes")

        operation {
            expectation.fulfill()
        }

        let waiter = XCTWaiter.wait(for: [expectation], timeout: timeout)

        if waiter != .completed {
            throw TestError.timeout
        }
    }

    /// Waits for a condition to become true
    /// - Parameters:
    ///   - condition: Condition to check
    ///   - timeout: Maximum time to wait
    ///   - description: Description of what's being waited for
    static func waitForCondition(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 2.0,
        description: String = "condition"
    ) {
        let expectation = XCTestExpectation(description: description)
        let startTime = Date()
        let checkInterval: TimeInterval = 0.01

        // Create a timer that checks the condition
        let timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { timer in
            if condition() {
                timer.invalidate()
                expectation.fulfill()
            } else if Date().timeIntervalSince(startTime) >= timeout {
                timer.invalidate()
                XCTFail("Timeout waiting for \(description)")
                expectation.fulfill()
            }
        }

        XCTWaiter.wait(for: [expectation], timeout: timeout + 0.1)
    }

    // MARK: - Data Generation Helpers

    /// Generates random test data
    /// - Parameter size: Size of data in bytes
    /// - Returns: Random data
    static func generateRandomData(size: Int) -> Data {
        var data = Data(count: size)
        _ = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, size, bytes.baseAddress!)
        }
        return data
    }

    /// Generates a random UUID string
    /// - Returns: Random UUID string
    static func generateRandomUUID() -> String {
        return UUID().uuidString
    }

    /// Generates a random string of specified length
    /// - Parameter length: Length of string to generate
    /// - Returns: Random string
    static func generateRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    /// Generates a random email address
    /// - Returns: Random email address
    static func generateRandomEmail() -> String {
        let username = generateRandomString(length: 8).lowercased()
        let domain = ["example.com", "test.com", "demo.org"].randomElement()!
        return "\(username)@\(domain)"
    }

    /// Generates a random date within a range
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Random date within range
    static func generateRandomDate(from startDate: Date, to endDate: Date) -> Date {
        let interval = endDate.timeIntervalSince(startDate)
        let randomInterval = TimeInterval.random(in: 0...interval)
        return startDate.addingTimeInterval(randomInterval)
    }

    // MARK: - File System Helpers

    /// Creates a temporary directory for testing
    /// - Returns: URL to temporary directory
    static func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueDir = tempDir.appendingPathComponent("test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: uniqueDir, withIntermediateDirectories: true)
        return uniqueDir
    }

    /// Creates a temporary file for testing
    /// - Parameters:
    ///   - content: Content to write to file
    ///   - extension: File extension
    /// - Returns: URL to temporary file
    static func createTemporaryFile(content: Data, extension: String) -> URL {
        let tempDir = createTemporaryDirectory()
        let fileURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).\(extension)")
        try? content.write(to: fileURL)
        return fileURL
    }

    /// Cleans up a temporary directory
    /// - Parameter url: URL of directory to clean up
    static func cleanupTemporaryDirectory(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - JSON Helpers

    /// Encodes an object to JSON data
    /// - Parameter object: Object to encode
    /// - Returns: JSON data
    static func encodeToJSON<T: Encodable>(_ object: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(object)
    }

    /// Decodes JSON data to an object
    /// - Parameters:
    ///   - data: JSON data to decode
    ///   - type: Type to decode to
    /// - Returns: Decoded object
    static func decodeFromJSON<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }

    /// Creates a JSON dictionary from a string
    /// - Parameter jsonString: JSON string
    /// - Returns: JSON dictionary
    static func jsonDictionary(from jsonString: String) -> [String: Any]? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    /// Converts a dictionary to JSON string
    /// - Parameter dictionary: Dictionary to convert
    /// - Returns: JSON string
    static func jsonString(from dictionary: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Mock Data Builders

    /// Builder pattern for creating test notifications
    class TestNotificationBuilder {
        private var id: String = UUID().uuidString
        private var title: String = "Test Notification"
        private var body: String = "Test notification body"
        private var timestamp: Date = Date()
        private var priority: Int = 0
        private var userInfo: [String: Any] = [:]

        func with(id: String) -> TestNotificationBuilder {
            self.id = id
            return self
        }

        func with(title: String) -> TestNotificationBuilder {
            self.title = title
            return self
        }

        func with(body: String) -> TestNotificationBuilder {
            self.body = body
            return self
        }

        func with(timestamp: Date) -> TestNotificationBuilder {
            self.timestamp = timestamp
            return self
        }

        func with(priority: Int) -> TestNotificationBuilder {
            self.priority = priority
            return self
        }

        func with(userInfo: [String: Any]) -> TestNotificationBuilder {
            self.userInfo = userInfo
            return self
        }

        func build() -> [String: Any] {
            var result: [String: Any] = [
                "id": id,
                "title": title,
                "body": body,
                "timestamp": timestamp.timeIntervalSince1970,
                "priority": priority
            ]
            result.merge(userInfo) { _, new in new }
            return result
        }
    }

    /// Builder pattern for creating test window configurations
    class TestWindowConfigBuilder {
        private var position: CGPoint = .zero
        private var size: CGSize = CGSize(width: 350, height: 80)
        private var level: NSWindow.Level = .floating
        private var isOpaque: Bool = false
        private var backgroundColor: NSColor = .windowBackgroundColor
        private var hasShadow: Bool = true

        func with(position: CGPoint) -> TestWindowConfigBuilder {
            self.position = position
            return self
        }

        func with(size: CGSize) -> TestWindowConfigBuilder {
            self.size = size
            return self
        }

        func with(level: NSWindow.Level) -> TestWindowConfigBuilder {
            self.level = level
            return self
        }

        func with(opaque: Bool) -> TestWindowConfigBuilder {
            self.isOpaque = opaque
            return self
        }

        func with(backgroundColor: NSColor) -> TestWindowConfigBuilder {
            self.backgroundColor = backgroundColor
            return self
        }

        func with(shadow: Bool) -> TestWindowConfigBuilder {
            self.hasShadow = shadow
            return self
        }

        func build() -> [String: Any] {
            return [
                "position": ["x": position.x, "y": position.y],
                "size": ["width": size.width, "height": size.height],
                "level": level.rawValue,
                "isOpaque": isOpaque,
                "backgroundColor": backgroundColor.hexString,
                "hasShadow": hasShadow
            ]
        }
    }

    // MARK: - Assertion Helpers

    /// Asserts that two arrays contain the same elements, regardless of order
    /// - Parameters:
    ///   - actual: Actual array
    ///   - expected: Expected array
    ///   - message: Optional message
    static func assertArraysEqual<T: Equatable>(
        _ actual: [T],
        _ expected: [T],
        _ message: String = ""
    ) {
        XCTAssertEqual(actual.count, expected.count, "\(message) - Array counts differ")
        for element in expected {
            XCTAssertTrue(actual.contains(element), "\(message) - Expected array to contain \(element)")
        }
    }

    /// Asserts that a block throws a specific error
    /// - Parameters:
    ///   - errorType: Expected error type
    ///   - block: Block to execute
    static func assertThrowsError<E: Error & Equatable>(
        _ errorType: E.Type,
        _ block: () throws -> Void
    ) {
        var errorThrown = false
        var expectedError: E?

        do {
            try block()
        } catch let error as E {
            errorThrown = true
            expectedError = error
        } catch {
            XCTFail("Expected error of type \(errorType), got \(error)")
        }

        XCTAssertTrue(errorThrown, "Expected error to be thrown")
        XCTAssertNotNil(expectedError, "Expected error of type \(errorType)")
    }

    /// Asserts that a value is within a specified range
    /// - Parameters:
    ///   - value: Value to check
    ///   - range: Expected range
    ///   - message: Optional message
    static func assertInRange<T: Comparable>(
        _ value: T,
        _ range: ClosedRange<T>,
        _ message: String = ""
    ) {
        XCTAssertTrue(
            range.contains(value),
            "\(message) - Expected \(value) to be in range \(range)"
        )
    }

    // MARK: - Performance Testing Helpers

    /// Measures the execution time of a block
    /// - Parameters:
    ///   - iterations: Number of iterations to run
    ///   - block: Block to measure
    /// - Returns: Average time per iteration in seconds
    static func measureAverageTime(iterations: Int = 10, block: () -> Void) -> TimeInterval {
        var totalTime: TimeInterval = 0

        for _ in 0..<iterations {
            let startTime = Date()
            block()
            let endTime = Date()
            totalTime += endTime.timeIntervalSince(startTime)
        }

        return totalTime / TimeInterval(iterations)
    }

    /// Measures memory usage of a block
    /// - Parameter block: Block to measure
    /// - Returns: Memory usage in bytes
    static func measureMemoryUsage(block: () -> Void) -> UInt64 {
        let before = getMemoryUsage()
        block()
        let after = getMemoryUsage()
        return after - before
    }

    /// Gets current memory usage
    /// - Returns: Memory usage in bytes
    static func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}

// MARK: - NSColor Extension

extension NSColor {
    /// Hex string representation of the color
    var hexString: String {
        guard let rgbColor = usingColorSpace(.deviceRGB) else {
            return "#000000"
        }

        let red = Int(rgbColor.redComponent * 255)
        let green = Int(rgbColor.greenComponent * 255)
        let blue = Int(rgbColor.blueComponent * 255)

        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

// MARK: - Concurrency Testing Helpers

/// Helpers for testing concurrent operations
class ConcurrencyTestHelpers {

    /// Runs multiple operations concurrently and waits for all to complete
    /// - Parameters:
    ///   - operations: Operations to run
    ///   - timeout: Maximum time to wait for all operations
    static func waitForConcurrentOperations(
        _ operations: [@escaping () -> Void],
        timeout: TimeInterval = 5.0
    ) {
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = operations.count

        let queue = DispatchQueue.global(qos: .userInitiated)

        for operation in operations {
            queue.async {
                operation()
                expectation.fulfill()
            }
        }

        XCTWaiter.wait(for: [expectation], timeout: timeout)
    }

    /// Tests that a critical section is properly synchronized
    /// - Parameters:
    ///   - iterations: Number of iterations to run
    ///   - criticalSection: Critical section to test
    static func testSynchronization(
        iterations: Int = 1000,
        criticalSection: @escaping () -> Void
    ) {
        let expectation = XCTestExpectation(description: "Synchronization test")
        expectation.expectedFulfillmentCount = iterations

        let queue = DispatchQueue.global(qos: .userInitiated)
        var completed = 0
        let lock = NSLock()

        for _ in 0..<iterations {
            queue.async {
                criticalSection()
                lock.lock()
                completed += 1
                if completed == iterations {
                    expectation.fulfill()
                }
                lock.unlock()
            }
        }

        XCTWaiter.wait(for: [expectation], timeout: 10.0)
    }
}

// MARK: - Retry Logic Helpers

/// Helpers for testing retry logic
class RetryTestHelpers {

    /// Creates a failure count tracker for testing retry logic
    class FailureTracker {
        private var failuresAllowed: Int
        private var failureCount: Int = 0

        init(failuresAllowed: Int) {
            self.failuresAllowed = failuresAllowed
        }

        func attempt() -> Bool {
            if failureCount < failuresAllowed {
                failureCount += 1
                return false // Failure
            }
            return true // Success
        }

        func getFailureCount() -> Int {
            return failureCount
        }

        func reset() {
            failureCount = 0
        }
    }

    /// Tests that an operation succeeds after a specified number of retries
    /// - Parameters:
    ///   - maxRetries: Maximum number of retries
    ///   - operation: Operation to test
    static func testRetrySuccess(
        maxRetries: Int,
        operation: @escaping (Int) -> Bool
    ) {
        var success = false
        var attempts = 0

        for attempt in 0...maxRetries {
            attempts = attempt + 1
            if operation(attempt) {
                success = true
                break
            }
        }

        XCTAssertTrue(success, "Operation should succeed after \(attempts) attempts")
    }
}
