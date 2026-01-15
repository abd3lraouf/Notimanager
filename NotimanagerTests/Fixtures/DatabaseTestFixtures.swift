//
//  DatabaseTestFixtures.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
import Foundation
@testable import Notimanager

/// Database test fixtures for integration testing
/// Provides reusable setup/teardown patterns for database operations
class DatabaseTestFixtures {

    // MARK: - Properties

    private(set) var mockDatabase: MockNotimanagerDatabase!
    private(set) var inMemoryDatabaseURL: URL!

    // MARK: - Database Setup

    /// Sets up an in-memory database for testing
    /// - Returns: URL to the in-memory database
    func setupInMemoryDatabase() -> URL {
        // Create a temporary in-memory database URL
        let tempDir = FileManager.default.temporaryDirectory
        let dbName = "test_\(UUID().uuidString).db"
        inMemoryDatabaseURL = tempDir.appendingPathComponent(dbName)

        // Create and configure mock database
        mockDatabase = MockNotimanagerDatabase()

        return inMemoryDatabaseURL
    }

    /// Creates a test database with predefined data
    /// - Parameters:
    ///   - windowCount: Number of test windows to create
    ///   - settingsCount: Number of test settings to create
    /// - Returns: URLs for created databases
    func createTestDatabase(windowCount: Int = 5, settingsCount: Int = 3) -> (databaseURL: URL, windowIDs: [UUID], settingKeys: [String]) {
        let databaseURL = setupInMemoryDatabase()
        var windowIDs: [UUID] = []
        var settingKeys: [String] = []

        // Create test windows
        for i in 0..<windowCount {
            let windowID = UUID()
            windowIDs.append(windowID)

            let window = TestNotificationWindow(
                id: windowID,
                title: "Test Window \(i)",
                position: CGPoint(x: 100 + CGFloat(i * 50), y: 100),
                size: CGSize(width: 350, height: 80),
                creationDate: Date().addingTimeInterval(-TimeInterval(i * 60))
            )

            try? mockDatabase.saveWindow(window)
        }

        // Create test settings
        for i in 0..<settingsCount {
            let key = "test_setting_\(i)"
            settingKeys.append(key)

            let setting = TestNotificationSetting(
                key: key,
                value: "test_value_\(i)",
                lastModified: Date()
            )

            try? mockDatabase.saveSetting(setting)
        }

        return (databaseURL, windowIDs, settingKeys)
    }

    // MARK: - Cleanup

    /// Cleans up test database files
    func cleanupTestDatabase() {
        guard let databaseURL = inMemoryDatabaseURL else { return }

        try? FileManager.default.removeItem(at: databaseURL)
        inMemoryDatabaseURL = nil
        mockDatabase?.reset()
        mockDatabase = nil
    }

    /// Deletes all test data from the mock database
    func clearTestDatabase() {
        mockDatabase?.reset()
    }

    // MARK: - Verification Helpers

    /// Verifies that a window exists in the database
    /// - Parameter windowID: ID of the window to verify
    /// - Returns: True if the window exists
    func verifyWindowExists(windowID: UUID) -> Bool {
        return mockDatabase?.loadWindow(id: windowID) != nil
    }

    /// Verifies that a setting exists in the database
    /// - Parameter settingKey: Key of the setting to verify
    /// - Returns: True if the setting exists
    func verifySettingExists(settingKey: String) -> Bool {
        return mockDatabase?.loadSetting(key: settingKey) != nil
    }

    /// Verifies the count of windows in the database
    /// - Parameter expectedCount: Expected number of windows
    /// - Returns: True if the count matches
    func verifyWindowCount(expectedCount: Int) -> Bool {
        return mockDatabase?.countWindows() ?? 0 == expectedCount
    }

    /// Verifies the count of settings in the database
    /// - Parameter expectedCount: Expected number of settings
    /// - Returns: True if the count matches
    func verifySettingCount(expectedCount: Int) -> Bool {
        return mockDatabase?.countSettings() ?? 0 == expectedCount
    }

    /// Gets the mock database instance
    var database: MockNotimanagerDatabase {
        guard let db = mockDatabase else {
            return MockNotimanagerDatabase()
        }
        return db
    }
}

// MARK: - Test Data Models

/// Test window data model for database testing
struct TestNotificationWindow {
    let id: UUID
    let title: String
    let position: CGPoint
    let size: CGSize
    let creationDate: Date
}

/// Test setting data model for database testing
struct TestNotificationSetting {
    let key: String
    let value: String
    let lastModified: Date
}

// MARK: - Database Test Case

/// Base test case for database-related integration tests
/// Automatically sets up and tears down test database
class DatabaseTestCase: NotimanagerTestCase {

    // MARK: - Properties

    let dbFixtures = DatabaseTestFixtures()
    var testDatabaseURL: URL?
    var testWindowIDs: [UUID] = []
    var testSettingKeys: [String] = []
    var mockDatabase: MockNotimanagerDatabase?

    // MARK: - Setup/Teardown

    override func setUp() {
        super.setUp()

        // Setup test database with sample data
        let (databaseURL, windowIDs, settingKeys) = dbFixtures.createTestDatabase()
        self.testDatabaseURL = databaseURL
        self.testWindowIDs = windowIDs
        self.testSettingKeys = settingKeys
        self.mockDatabase = dbFixtures.database
    }

    override func tearDown() {
        // Cleanup test database
        dbFixtures.cleanupTestDatabase()
        testDatabaseURL = nil
        testWindowIDs.removeAll()
        testSettingKeys.removeAll()
        mockDatabase = nil

        super.tearDown()
    }

    // MARK: - Convenience Properties

    /// First test window ID (convenience accessor)
    var firstTestWindowID: UUID {
        guard let firstID = testWindowIDs.first else {
            XCTFail("No test window IDs available")
            return UUID()
        }
        return firstID
    }

    /// First test setting key (convenience accessor)
    var firstTestSettingKey: String {
        guard let firstKey = testSettingKeys.first else {
            XCTFail("No test setting keys available")
            return ""
        }
        return firstKey
    }
}

// MARK: - Mock Database Class

/// Mock database class for testing database operations without real persistence
class MockNotimanagerDatabase {

    // MARK: - Properties

    private var windows: [UUID: TestNotificationWindow] = [:]
    private var settings: [String: TestNotificationSetting] = [:]

    // MARK: - Window Operations

    func saveWindow(_ window: TestNotificationWindow) throws {
        windows[window.id] = window
    }

    func loadWindow(id: UUID) -> TestNotificationWindow? {
        return windows[id]
    }

    func loadAllWindows() -> [TestNotificationWindow] {
        return Array(windows.values)
    }

    func deleteWindow(id: UUID) throws {
        windows.removeValue(forKey: id)
    }

    func clearAllWindows() throws {
        windows.removeAll()
    }

    // MARK: - Setting Operations

    func saveSetting(_ setting: TestNotificationSetting) throws {
        settings[setting.key] = setting
    }

    func loadSetting(key: String) -> TestNotificationSetting? {
        return settings[key]
    }

    func loadAllSettings() -> [TestNotificationSetting] {
        return Array(settings.values)
    }

    func deleteSetting(key: String) throws {
        settings.removeValue(forKey: key)
    }

    func clearAllSettings() throws {
        settings.removeAll()
    }

    // MARK: - Utility Methods

    func countWindows() -> Int {
        return windows.count
    }

    func countSettings() -> Int {
        return settings.count
    }

    func reset() {
        windows.removeAll()
        settings.removeAll()
    }
}
