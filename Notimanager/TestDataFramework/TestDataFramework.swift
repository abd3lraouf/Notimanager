//
//  TestDataFramework.swift
//  NotimanagerTestDataFramework
//
//  Created for feature-1768473183452-7a7rg9upp
//  Test Data Framework - Main Entry Point
//

import Foundation

// MARK: - Framework Export
// Foundation is imported - test data framework uses Foundation types

// MARK: - Framework Version

public struct TestDataFramework {
    /// Version of the test data framework
    public static let version = "1.0.0"
    
    /// Framework name
    public static let name = "TestDataFramework"
    
    /// Initialize the framework
    public static func initialize() {
        print("Initializing \(name) v\(version)")
        
        // Setup default configurations
        _ = TestDataSeeder.shared
    }
    
    /// Get framework information
    public static func getInfo() -> String {
        return "\(name) v\(version) - A framework for defining and seeding test data"
    }
}

// MARK: - Quick Start Extension

extension TestDataSeeder {
    
    /// Quick start method to load and register standard test data
    public func quickStart() throws {
        print("=== Quick Start: Loading Standard Test Data ===")
        
        // Load standard notifications
        let standardNotifications = NotificationTestDataFactory.createStandardNotifications()
        try register(standardNotifications)
        
        // Load edge case notifications
        let edgeCaseNotifications = NotificationTestDataFactory.createEdgeCaseNotifications()
        try register(edgeCaseNotifications)
        
        // Load environment-specific notifications
        let environmentNotifications = NotificationTestDataFactory.createEnvironmentNotifications()
        for collection in environmentNotifications {
            try register(collection)
        }
        
        print("=== Quick Start Complete ===")
        printSummary()
    }
}

// MARK: - Convenience Extensions

extension TestDataSeeder {
    
    /// Get all notification test data
    public func getAllNotificationTestData(version: String = "1.0") -> [NotificationTestData] {
        return getAllRecords(type: NotificationTestData.self, version: version)
    }

    /// Get notification test data by position
    public func getNotificationTestData(by position: String, version: String = "1.0") -> [NotificationTestData] {
        let allNotifications = getAllNotificationTestData(version: version)
        return allNotifications.filter { $0.position == position }
    }

    /// Get notification test data by tags
    public func getNotificationTestData(byTags tags: [String], version: String = "1.0") -> [NotificationTestData] {
        let tagSet = Set(tags)
        return getRecordsByTags(type: NotificationTestData.self, tags: tagSet, version: version)
    }
    
    /// Get notification test data that should be intercepted
    public func getInterceptableNotifications(version: String = "1.0") -> [NotificationTestData] {
        let allNotifications = getAllNotificationTestData(version: version)
        return allNotifications.filter { $0.shouldBeIntercepted }
    }
    
    /// Get notification test data that should NOT be intercepted
    public func getNonInterceptableNotifications(version: String = "1.0") -> [NotificationTestData] {
        let allNotifications = getAllNotificationTestData(version: version)
        return allNotifications.filter { !$0.shouldBeIntercepted }
    }
}

// MARK: - Test Data Generator

/// Protocol for generating test data
public protocol TestDataGenerator {
    associatedtype Data: TestData
    
    /// Generate test data
    func generate() -> TestDataCollection<Data>
    
    /// Generate variations of test data
    func generateVariations(count: Int) -> TestDataCollection<Data>
}

// MARK: - Test Data Validator

/// Protocol for validating test data
public protocol TestDataValidator {
    associatedtype Data: TestData
    
    /// Validate a single test data record
    func validate(_ data: Data) throws
    
    /// Validate a collection of test data
    func validateCollection(_ collection: TestDataCollection<Data>) throws
}

// MARK: - Test Data Export

/// Options for exporting test data
public struct TestDataExportOptions {
    /// Include framework metadata
    public let includeMetadata: Bool
    
    /// Include relationships
    public let includeRelationships: Bool
    
    /// Format for export
    public let format: ExportFormat
    
    /// Compression level
    public let compressionLevel: Int
    
    public init(
        includeMetadata: Bool = true,
        includeRelationships: Bool = true,
        format: ExportFormat = .json,
        compressionLevel: Int = 6
    ) {
        self.includeMetadata = includeMetadata
        self.includeRelationships = includeRelationships
        self.format = format
        self.compressionLevel = compressionLevel
    }
}

/// Export formats
public enum ExportFormat: String, Codable {
    case json
    case yaml
    case xml
    case csv
    case plist
}

// MARK: - Test Data Import

/// Options for importing test data
public struct TestDataImportOptions {
    /// Skip validation during import
    public let skipValidation: Bool
    
    /// Overwrite existing data
    public let overwriteExisting: Bool
    
    /// Import environment
    public let targetEnvironment: String?
    
    public init(
        skipValidation: Bool = false,
        overwriteExisting: Bool = false,
        targetEnvironment: String? = nil
    ) {
        self.skipValidation = skipValidation
        self.overwriteExisting = overwriteExisting
        self.targetEnvironment = targetEnvironment
    }
}