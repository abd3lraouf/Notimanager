//
//  IntegrationTestPatterns.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
import Foundation
@testable import Notimanager

/// Integration test patterns and examples
/// Provides reusable patterns for common integration testing scenarios
/// combining database, API, and message queue operations
class IntegrationTestPatterns {

    // MARK: - Properties

    let dbFixtures = DatabaseTestFixtures()
    let apiFixtures = APITestFixtures()
    let queueFixtures = MessageQueueTestFixtures()

    // MARK: - Combined Setup Patterns

    /// Pattern: Full stack setup with database, API, and message queue
    /// Use this when testing features that interact with all three components
    func setupFullStackEnvironment() -> FullStackTestEnvironment {
        let dbURL = dbFixtures.setupInMemoryDatabase()
        let mockAPI = apiFixtures.createMockURLSession()
        let mockQueue = queueFixtures.setupMockMessageQueue()
        let mockDatabase = dbFixtures.database

        return FullStackTestEnvironment(
            databaseURL: dbURL,
            mockDatabase: mockDatabase,
            mockURLSession: mockAPI,
            mockMessageQueue: mockQueue
        )
    }

    /// Pattern: API to Database sync setup
    /// Use this when testing data synchronization from API to local database
    func setupAPIToDatabaseSync() -> APIToDatabaseEnvironment {
        let dbURL = dbFixtures.setupInMemoryDatabase()
        let mockAPI = apiFixtures.createMockURLSession()
        let mockDatabase = dbFixtures.database

        return APIToDatabaseEnvironment(
            databaseURL: dbURL,
            mockDatabase: mockDatabase,
            mockURLSession: mockAPI
        )
    }

    /// Pattern: Database to Message Queue event setup
    /// Use this when testing database change notifications via message queue
    func setupDatabaseToQueueEvents() -> DatabaseToQueueEnvironment {
        let dbURL = dbFixtures.setupInMemoryDatabase()
        let mockQueue = queueFixtures.setupMockMessageQueue()
        let mockDatabase = dbFixtures.database

        return DatabaseToQueueEnvironment(
            databaseURL: dbURL,
            mockDatabase: mockDatabase,
            mockMessageQueue: mockQueue
        )
    }

    // MARK: - Common Test Scenarios

    /// Scenario: Test fetching data from API and storing in database
    /// - Parameters:
    ///   - endpoint: API endpoint to fetch from
    ///   - apiResponse: Mock API response data
    ///   - mockDatabase: Mock database to store data
    func testAPIToDatabaseFlow(
        endpoint: String,
        apiResponse: Data,
        mockDatabase: MockNotimanagerDatabase
    ) throws {
        // Setup mock API response
        let mockAPI = apiFixtures.createMockURLSession()
        apiFixtures.setMockResponse(for: endpoint, data: apiResponse, statusCode: 200)

        // Create API client
        let apiClient = APIClient(session: mockAPI)

        // Fetch data from API
        let fetchedData = try waitForAPIResponse(
            from: endpoint,
            using: apiClient
        )

        // Store in database
        try storeAPIDataInDatabase(fetchedData, database: mockDatabase)

        // Verify data was stored
        XCTAssertTrue(dbFixtures.verifyWindowCount(expectedCount: 1))
    }

    /// Scenario: Test database change triggers message queue event
    /// - Parameters:
    ///   - mockDatabase: Mock database
    ///   - mockQueue: Mock message queue
    ///   - windowData: Window data to save
    func testDatabaseToQueueFlow(
        mockDatabase: MockNotimanagerDatabase,
        mockQueue: MockMessageQueue,
        windowData: TestNotificationWindow
    ) throws {
        // Subscribe to database change events
        var eventReceived = false
        mockQueue.setHandler(for: "database_change") { _ in
            eventReceived = true
        }

        // Save data to database
        try mockDatabase.saveWindow(windowData)

        // Simulate database change notification
        mockQueue.publish([
            "type": "database_change",
            "entity": "window",
            "action": "create",
            "id": windowData.id.uuidString
        ])

        // Verify event was published
        XCTAssertTrue(eventReceived, "Database change event should be published")
    }

    /// Scenario: Test end-to-end API to database to message queue flow
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - apiResponse: Mock API response
    ///   - environment: Full stack test environment
    func testFullStackFlow(
        endpoint: String,
        apiResponse: Data,
        environment: FullStackTestEnvironment
    ) throws {
        var eventReceived = false
        var receivedEventData: [String: Any]?

        // Subscribe to events
        environment.mockMessageQueue.setHandler(for: "data_synced") { message in
            eventReceived = true
            receivedEventData = message as? [String: Any]
        }

        // Setup mock API
        apiFixtures.setMockResponse(for: endpoint, data: apiResponse, statusCode: 200)

        // Create API client
        let apiClient = APIClient(session: environment.mockURLSession)

        // Fetch and sync data
        let data = try waitForAPIResponse(from: endpoint, using: apiClient)

        // Store in database
        try storeAPIDataInDatabase(data, database: environment.mockDatabase)

        // Publish sync event
        environment.mockMessageQueue.publish([
            "type": "data_synced",
            "source": "api",
            "count": 1
        ])

        // Verify complete flow
        XCTAssertTrue(eventReceived, "Sync event should be published")
        XCTAssertNotNil(receivedEventData, "Event data should be present")
    }

    // MARK: - Helper Methods

    private func waitForAPIResponse(from endpoint: String, using client: APIClient) throws -> Data {
        let expectation = XCTestExpectation(description: "API response received")
        var result: Data?
        var error: Error?

        client.fetch(from: endpoint) { data, err in
            error = err
            result = data
            expectation.fulfill()
        }

        let waiter = XCTWaiter.wait(for: [expectation], timeout: 2.0)
        if waiter != .completed {
            throw TestError.timeout
        }

        if let error = error {
            throw error
        }

        guard let data = result else {
            throw TestError.nilResult
        }

        return data
    }

    private func storeAPIDataInDatabase(_ data: Data, database: MockNotimanagerDatabase) throws {
        // Parse and store data - implementation depends on actual data structure
        // This is a placeholder for the actual implementation
        // In a real implementation, you would decode the JSON and create TestNotificationWindow objects
    }
}

// MARK: - Test Environment Models

/// Full stack test environment containing all test components
struct FullStackTestEnvironment {
    let databaseURL: URL
    let mockDatabase: MockNotimanagerDatabase
    let mockURLSession: MockURLSession
    let mockMessageQueue: MockMessageQueue

    func cleanup() {
        try? FileManager.default.removeItem(at: databaseURL)
        mockDatabase.reset()
    }
}

/// API to Database sync environment
struct APIToDatabaseEnvironment {
    let databaseURL: URL
    let mockDatabase: MockNotimanagerDatabase
    let mockURLSession: MockURLSession

    func cleanup() {
        try? FileManager.default.removeItem(at: databaseURL)
        mockDatabase.reset()
    }
}

/// Database to Queue event environment
struct DatabaseToQueueEnvironment {
    let databaseURL: URL
    let mockDatabase: MockNotimanagerDatabase
    let mockMessageQueue: MockMessageQueue

    func cleanup() {
        try? FileManager.default.removeItem(at: databaseURL)
        mockDatabase.reset()
    }
}

// MARK: - Integration Test Example Classes

/// Example: Testing notification persistence workflow
/// Demonstrates testing the flow from notification detection to database storage
final class NotificationPersistenceIntegrationTests: NotimanagerTestCase {

    let patterns = IntegrationTestPatterns()
    var environment: FullStackTestEnvironment!

    override func setUp() {
        super.setUp()
        environment = patterns.setupFullStackEnvironment()
    }

    override func tearDown() {
        environment?.cleanup()
        super.tearDown()
    }

    func testNotificationDetectedAndStored() {
        // Given: A notification is detected
        let notification = patterns.apiFixtures.createTestNotification(
            id: UUID().uuidString,
            title: "Test Notification",
            body: "Test body"
        )

        // When: Notification is processed and stored
        let testWindow = TestNotificationWindow(
            id: UUID(),
            title: notification["title"] as? String ?? "",
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 350, height: 80),
            creationDate: Date()
        )

        try? environment.mockDatabase.saveWindow(testWindow)

        // Then: Notification should be in database
        XCTAssertTrue(
            patterns.dbFixtures.verifyWindowExists(windowID: testWindow.id)
        )
    }

    func testBatchNotificationProcessing() {
        // Given: Multiple notifications arrive
        let count = 5
        var windowIDs: [UUID] = []

        // When: All notifications are processed
        for i in 0..<count {
            let windowID = UUID()
            windowIDs.append(windowID)

            let window = TestNotificationWindow(
                id: windowID,
                title: "Notification \(i)",
                position: CGPoint(x: 100 + CGFloat(i * 50), y: 100),
                size: CGSize(width: 350, height: 80),
                creationDate: Date()
            )

            try? environment.mockDatabase.saveWindow(window)
        }

        // Then: All notifications should be in database
        XCTAssertTrue(
            patterns.dbFixtures.verifyWindowCount(expectedCount: count)
        )
    }
}

/// Example: Testing settings synchronization workflow
/// Demonstrates testing settings update propagation
final class SettingsSyncIntegrationTests: NotimanagerTestCase {

    let patterns = IntegrationTestPatterns()
    var environment: APIToDatabaseEnvironment!

    override func setUp() {
        super.setUp()
        environment = patterns.setupAPIToDatabaseSync()
    }

    override func tearDown() {
        environment?.cleanup()
        super.tearDown()
    }

    func testSettingsFetchedFromAPIAndStored() {
        // Given: API has settings
        let settingsData = patterns.apiFixtures.createTestSettingsResponse()

        // When: Settings are fetched from API
        // (Mock the API response)
        patterns.apiFixtures.setMockResponse(
            for: "/settings",
            data: settingsData,
            statusCode: 200
        )

        // Store in database
        let setting = TestNotificationSetting(
            key: "test_setting",
            value: "test_value",
            lastModified: Date()
        )
        try? environment.mockDatabase.saveSetting(setting)

        // Then: Settings should be in database
        XCTAssertTrue(
            patterns.dbFixtures.verifySettingExists(settingKey: "test_setting")
        )
    }

    func testSettingsChangeNotifiesObservers() {
        // Given: An observer is registered
        var notificationReceived = false
        let expectation = XCTestExpectation(description: "Settings change notified")

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsChanged"),
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }

        // When: Settings are changed
        let setting = TestNotificationSetting(
            key: "notification_setting",
            value: "new_value",
            lastModified: Date()
        )
        try? environment.mockDatabase.saveSetting(setting)

        // Notify observers
        NotificationCenter.default.post(
            name: NSNotification.Name("SettingsChanged"),
            object: setting
        )

        // Then: Observer should be notified
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(notificationReceived)

        NotificationCenter.default.removeObserver(self)
    }
}

/// Example: Testing event-driven notification workflow
/// Demonstrates testing message queue event handling
final class EventDrivenNotificationTests: NotimanagerTestCase {

    let patterns = IntegrationTestPatterns()
    var environment: DatabaseToQueueEnvironment!
    var receivedEvents: [[String: Any]] = []

    override func setUp() {
        super.setUp()
        environment = patterns.setupDatabaseToQueueEvents()

        // Set up event handler
        environment.mockMessageQueue.setHandler(for: "notification_event") { [weak self] message in
            if let event = message as? [String: Any] {
                self?.receivedEvents.append(event)
            }
        }
    }

    override func tearDown() {
        receivedEvents.removeAll()
        environment?.cleanup()
        super.tearDown()
    }

    func testNotificationCreatedEvent() {
        // Given: A notification is created
        let windowID = UUID()
        let window = TestNotificationWindow(
            id: windowID,
            title: "New Notification",
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 350, height: 80),
            creationDate: Date()
        )

        // When: Window is saved to database
        try? environment.mockDatabase.saveWindow(window)

        // Publish event
        environment.mockMessageQueue.publish([
            "type": "notification_event",
            "action": "created",
            "windowId": windowID.uuidString,
            "timestamp": Date().timeIntervalSince1970
        ])

        // Then: Event should be received
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents.first?["action"] as? String, "created")
    }

    func testNotificationMovedEvent() {
        // Given: An existing notification
        let windowID = UUID()
        let window = TestNotificationWindow(
            id: windowID,
            title: "Existing Notification",
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 350, height: 80),
            creationDate: Date()
        )

        try? environment.mockDatabase.saveWindow(window)

        // When: Window is moved
        let newPosition = CGPoint(x: 200, y: 200)

        // Publish move event
        environment.mockMessageQueue.publish([
            "type": "notification_event",
            "action": "moved",
            "windowId": windowID.uuidString,
            "oldPosition": ["x": 100, "y": 100],
            "newPosition": ["x": newPosition.x, "y": newPosition.y],
            "timestamp": Date().timeIntervalSince1970
        ])

        // Then: Move event should be received with correct data
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents.first?["action"] as? String, "moved")
    }

    func testNotificationDismissedEvent() {
        // Given: An existing notification
        let windowID = UUID()
        let window = TestNotificationWindow(
            id: windowID,
            title: "Notification to Dismiss",
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 350, height: 80),
            creationDate: Date()
        )

        try? environment.mockDatabase.saveWindow(window)

        // When: Window is dismissed
        try? environment.mockDatabase.deleteWindow(id: windowID)

        // Publish dismiss event
        environment.mockMessageQueue.publish([
            "type": "notification_event",
            "action": "dismissed",
            "windowId": windowID.uuidString,
            "timestamp": Date().timeIntervalSince1970
        ])

        // Then: Dismiss event should be received
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents.first?["action"] as? String, "dismissed")

        // And window should not exist in database
        XCTAssertFalse(
            patterns.dbFixtures.verifyWindowExists(windowID: windowID)
        )
    }
}

// MARK: - API Client Mock

/// Mock API client for testing
class APIClient {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func fetch(from endpoint: String, completion: @escaping (Data?, Error?) -> Void) {
        guard let url = URL(string: "https://api.example.com\(endpoint)") else {
            completion(nil, TestError.conditionFailed)
            return
        }

        let task = session.dataTask(with: url) { data, _, error in
            completion(data, error)
        }

        task.resume()
    }
}
