//
//  MessageQueueTestFixtures.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
import Foundation
@testable import Notimanager

/// Message queue test fixtures for integration testing
/// Provides reusable patterns for testing message queue operations, pub/sub systems, and async communication
class MessageQueueTestFixtures {

    // MARK: - Properties

    private(set) var mockMessageQueue: MockMessageQueue!
    private(set) var messageHandlers: [String: (Any) -> Void] = [:]
    private(set) var receivedMessages: [Any] = []

    // MARK: - Queue Setup

    /// Sets up a mock message queue for testing
    /// - Returns: Configured mock message queue
    func setupMockMessageQueue() -> MockMessageQueue {
        mockMessageQueue = MockMessageQueue()
        
        // Set up default message handlers
        setupDefaultMessageHandlers()
        
        return mockMessageQueue
    }

    /// Sets up default message handlers for common message types
    private func setupDefaultMessageHandlers() {
        mockMessageQueue?.setHandler(for: "notification") { [weak self] message in
            self?.handleNotificationMessage(message)
        }
        
        mockMessageQueue?.setHandler(for: "settings") { [weak self] message in
            self?.handleSettingsMessage(message)
        }
        
        mockMessageQueue?.setHandler(for: "system") { [weak self] message in
            self?.handleSystemMessage(message)
        }
    }

    /// Handles notification messages
    private func handleNotificationMessage(_ message: Any) {
        receivedMessages.append(message)
    }

    /// Handles settings messages
    private func handleSettingsMessage(_ message: Any) {
        receivedMessages.append(message)
    }

    /// Handles system messages
    private func handleSystemMessage(_ message: Any) {
        receivedMessages.append(message)
    }

    // MARK: - Message Creation

    /// Creates a test notification message
    /// - Parameters:
    ///   - id: Notification ID
    ///   - title: Notification title
    ///   - body: Notification body
    /// - Returns: Notification message dictionary
    func createTestNotificationMessage(
        id: String = UUID().uuidString,
        title: String = "Test Notification",
        body: String = "Test notification body"
    ) -> [String: Any] {
        return [
            "type": "notification",
            "id": id,
            "title": title,
            "body": body,
            "timestamp": Date().timeIntervalSince1970,
            "priority": Int.random(in: 0...2)
        ]
    }

    /// Creates a test settings message
    /// - Parameters:
    ///   - key: Setting key
    ///   - value: Setting value
    ///   - action: Action type (create, update, delete)
    /// - Returns: Settings message dictionary
    func createTestSettingsMessage(
        key: String = "test_setting",
        value: Any = "test_value",
        action: String = "update"
    ) -> [String: Any] {
        return [
            "type": "settings",
            "key": key,
            "value": value,
            "action": action,
            "timestamp": Date().timeIntervalSince1970
        ]
    }

    /// Creates a test system message
    /// - Parameters:
    ///   - event: System event type
    ///   - data: Additional event data
    /// - Returns: System message dictionary
    func createTestSystemMessage(
        event: String = "system_event",
        data: [String: Any] = [:]
    ) -> [String: Any] {
        return [
            "type": "system",
            "event": event,
            "data": data,
            "timestamp": Date().timeIntervalSince1970
        ]
    }

    /// Creates a batch of test messages
    /// - Parameter count: Number of messages to create
    /// - Returns: Array of test messages
    func createTestMessageBatch(count: Int = 5) -> [[String: Any]] {
        var messages: [[String: Any]] = []
        
        for i in 0..<count {
            let message: [String: Any]
            if i % 3 == 0 {
                message = createTestNotificationMessage(title: "Batch Notification \(i)")
            } else if i % 3 == 1 {
                message = createTestSettingsMessage(key: "batch_setting_\(i)")
            } else {
                message = createTestSystemMessage(event: "batch_event_\(i)")
            }
            messages.append(message)
        }
        
        return messages
    }

    // MARK: - Message Publishing

    /// Publishes a message to the queue
    /// - Parameter message: Message to publish
    func publishMessage(_ message: Any) {
        mockMessageQueue?.publish(message)
    }

    /// Publishes multiple messages to the queue
    /// - Parameter messages: Messages to publish
    func publishMessages(_ messages: [Any]) {
        for message in messages {
            publishMessage(message)
        }
    }

    /// Publishes a message with a specific topic
    /// - Parameters:
    ///   - topic: Message topic
    ///   - message: Message content
    func publishMessage(toTopic topic: String, message: Any) {
        let wrappedMessage: [String: Any] = [
            "topic": topic,
            "content": message,
            "timestamp": Date().timeIntervalSince1970
        ]
        mockMessageQueue?.publish(to: topic, message: wrappedMessage)
    }

    // MARK: - Subscription Management

    /// Subscribes to a message type
    /// - Parameters:
    ///   - messageType: Type of message to subscribe to
    ///   - handler: Handler function for the message
    func subscribe(to messageType: String, handler: @escaping (Any) -> Void) {
        messageHandlers[messageType] = handler
        mockMessageQueue?.setHandler(for: messageType, handler: handler)
    }

    /// Unsubscribes from a message type
    /// - Parameter messageType: Type of message to unsubscribe from
    func unsubscribe(from messageType: String) {
        messageHandlers.removeValue(forKey: messageType)
        mockMessageQueue?.removeHandler(for: messageType)
    }

    /// Subscribes to multiple message types
    /// - Parameters:
    ///   - messageTypes: Array of message types to subscribe to
    ///   - handler: Handler function for the messages
    func subscribe(to messageTypes: [String], handler: @escaping (Any) -> Void) {
        for type in messageTypes {
            subscribe(to: type, handler: handler)
        }
    }

    // MARK: - Verification Helpers

    /// Verifies that a message was received
    /// - Parameters:
    ///   - expectedMessage: Expected message content
    ///   - timeout: Timeout for verification (default: 1 second)
    /// - Returns: True if the message was received
    func verifyMessageReceived(_ expectedMessage: Any, timeout: TimeInterval = 1.0) -> Bool {
        let expectation = XCTestExpectation(description: "Message received")
        var messageReceived = false

        // Check if message is already in received messages
        if containsMessage(expectedMessage, in: receivedMessages) {
            return true
        }

        // Set up a temporary handler to catch the message
        let tempHandler: (Any) -> Void = { message in
            if self.containsMessage(expectedMessage, in: [message]) {
                messageReceived = true
                expectation.fulfill()
            }
        }

        subscribe(to: "verification", handler: tempHandler)
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        unsubscribe(from: "verification")
        
        return result == .completed
    }

    /// Verifies that a specific number of messages were received
    /// - Parameters:
    ///   - expectedCount: Expected number of messages
    ///   - timeout: Timeout for verification (default: 1 second)
    /// - Returns: True if the count matches
    func verifyMessageCount(_ expectedCount: Int, timeout: TimeInterval = 1.0) -> Bool {
        let expectation = XCTestExpectation(description: "Message count verification")
        
        DispatchQueue.global().async {
            let startTime = Date()
            while Date().timeIntervalSince(startTime) < timeout {
                if self.receivedMessages.count == expectedCount {
                    expectation.fulfill()
                    return
                }
                Thread.sleep(forTimeInterval: 0.01)
            }
            expectation.fulfill()
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout + 0.1)
        return result == .completed && receivedMessages.count == expectedCount
    }

    /// Verifies that messages were received in the correct order
    /// - Parameter expectedMessages: Expected messages in order
    /// - Returns: True if messages were received in the correct order
    func verifyMessageOrder(_ expectedMessages: [Any]) -> Bool {
        guard receivedMessages.count >= expectedMessages.count else {
            return false
        }
        
        for i in 0..<expectedMessages.count {
            if !containsMessage(expectedMessages[i], in: [receivedMessages[i]]) {
                return false
            }
        }
        
        return true
    }

    /// Helper method to check if a message exists in an array
    private func containsMessage(_ message: Any, in messages: [Any]) -> Bool {
        guard let messageDict = message as? [String: Any] else { return false }
        
        for receivedMessage in messages {
            guard let receivedDict = receivedMessage as? [String: Any] else { continue }
            
            var allMatch = true
            for (key, value) in messageDict {
                let receivedValue = receivedDict[key]
                
                if let v1 = receivedValue as? AnyHashable, let v2 = value as? AnyHashable {
                    if v1 != v2 {
                        allMatch = false
                        break
                    }
                } else if receivedValue == nil && value != nil {
                    allMatch = false
                    break
                } else if receivedValue != nil && value == nil {
                    allMatch = false
                    break
                }
                // If both are nil, they match. If they aren't Hashable, we can't compare them easily here, 
                // but for most test data this will work.
            }
            
            if allMatch {
                return true
            }
        }
        
        return false
    }

    // MARK: - Cleanup

    /// Clears all received messages
    func clearReceivedMessages() {
        receivedMessages.removeAll()
    }

    /// Resets the message queue state
    func resetMessageQueue() {
        clearReceivedMessages()
        messageHandlers.removeAll()
        mockMessageQueue?.reset()
    }

    /// Cleanup resources
    func cleanup() {
        resetMessageQueue()
        mockMessageQueue = nil
    }
}

// MARK: - Mock Message Queue

/// Mock message queue for testing message operations
class MockMessageQueue {

    // MARK: - Properties

    private(set) var messages: [Any] = []
    private var handlers: [String: (Any) -> Void] = [:]
    private(set) var publishedTopics: [String] = []

    // MARK: - Message Publishing

    func publish(_ message: Any) {
        messages.append(message)
        processMessage(message)
    }

    func publish(to topic: String, message: Any) {
        publishedTopics.append(topic)
        let wrappedMessage: [String: Any] = [
            "topic": topic,
            "message": message,
            "timestamp": Date().timeIntervalSince1970
        ]
        publish(wrappedMessage)
    }

    // MARK: - Handler Management

    func setHandler(for messageType: String, handler: @escaping (Any) -> Void) {
        handlers[messageType] = handler
    }

    func removeHandler(for messageType: String) {
        handlers.removeValue(forKey: messageType)
    }

    // MARK: - Message Processing

    private func processMessage(_ message: Any) {
        guard let messageDict = message as? [String: Any] else {
            // Handle non-dictionary messages
            for (_, handler) in handlers {
                handler(message)
            }
            return
        }

        // Route message based on type or topic
        if let type = messageDict["type"] as? String,
           let handler = handlers[type] {
            handler(message)
        } else if let topic = messageDict["topic"] as? String,
                  let handler = handlers[topic] {
            handler(message)
        } else {
            // If no specific handler, use all handlers
            for (_, handler) in handlers {
                handler(message)
            }
        }
    }

    // MARK: - Query Methods

    func getMessages(ofType type: String) -> [Any] {
        return messages.filter { message in
            guard let messageDict = message as? [String: Any] else { return false }
            return messageDict["type"] as? String == type
        }
    }

    func getMessages(forTopic topic: String) -> [Any] {
        return messages.filter { message in
            guard let messageDict = message as? [String: Any] else { return false }
            return messageDict["topic"] as? String == topic
        }
    }

    func getMessageCount() -> Int {
        return messages.count
    }

    func isEmpty() -> Bool {
        return messages.isEmpty
    }

    // MARK: - Reset

    func reset() {
        messages.removeAll()
        handlers.removeAll()
        publishedTopics.removeAll()
    }
}

// MARK: - Message Queue Test Case

/// Base test case for message queue-related integration tests
/// Automatically sets up and tears down mock message queue
class MessageQueueTestCase: NotimanagerTestCase {

    // MARK: - Properties

    let queueFixtures = MessageQueueTestFixtures()
    var mockQueue: MockMessageQueue?

    // MARK: - Setup/Teardown

    override func setUp() {
        super.setUp()
        
        // Setup mock message queue
        mockQueue = queueFixtures.setupMockMessageQueue()
    }

    override func tearDown() {
        // Cleanup
        queueFixtures.cleanup()
        mockQueue = nil
        
        super.tearDown()
    }

    // MARK: - Convenience Methods

    /// Publishes a test notification and waits for processing
    func publishTestNotificationAndWait(
        title: String = "Test Notification",
        timeout: TimeInterval = 1.0
    ) {
        let message = queueFixtures.createTestNotificationMessage(title: title)
        let expectation = XCTestExpectation(description: "Notification processed")
        
        queueFixtures.subscribe(to: "notification") { _ in
            expectation.fulfill()
        }
        
        queueFixtures.publishMessage(message)
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Notification processing timed out")
    }

    /// Verifies that a specific number of messages were processed
    func verifyMessageCount(_ expectedCount: Int, timeout: TimeInterval = 1.0) {
        let expectation = XCTestExpectation(description: "Message count verification")
        
        DispatchQueue.global().async {
            let startTime = Date()
            while Date().timeIntervalSince(startTime) < timeout {
                if self.mockQueue?.getMessageCount() == expectedCount {
                    expectation.fulfill()
                    return
                }
                Thread.sleep(forTimeInterval: 0.01)
            }
            expectation.fulfill()
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout + 0.1)
        XCTAssertEqual(result, .completed, "Message count verification timed out")
        XCTAssertEqual(mockQueue?.getMessageCount() ?? 0, expectedCount)
    }

    /// Gets all messages of a specific type
    func getMessages(ofType type: String) -> [Any] {
        return mockQueue?.getMessages(ofType: type) ?? []
    }

    /// Gets all messages for a specific topic
    func getMessages(forTopic topic: String) -> [Any] {
        return mockQueue?.getMessages(forTopic: topic) ?? []
    }
}