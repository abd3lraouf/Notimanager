//
//  TestDataProtocol.swift
//  NotimanagerTestDataFramework
//
//  Created for feature-1768473183452-7a7rg9upp
//  Test Data Framework
//

import Foundation

// MARK: - Test Data Protocol

/// Protocol that all test data structures must conform to
public protocol TestData: Codable {
    /// Unique identifier for this test data record
    var id: String { get }
    
    /// Version of this test data structure
    var version: String { get }
    
    /// Environment this data is intended for (e.g., "development", "testing", "production")
    var environment: String { get }
    
    /// Tags for categorizing and filtering test data
    var tags: [String] { get }
    
    /// Relationships to other test data records
    var relationships: [String: String] { get }
    
    /// Validate this test data record
    func validate() throws
}

// MARK: - Test Data Collection

/// Represents a collection of test data records
public struct TestDataCollection<T: TestData>: Codable {
    /// Version of this collection
    public let version: String
    
    /// Environment this collection is for
    public let environment: String
    
    /// The test data records in this collection
    public let records: [T]
    
    /// Metadata about this collection
    public let metadata: [String: String]
    
    /// Initialize a test data collection
    public init(version: String, environment: String, records: [T], metadata: [String: String] = [:]) {
        self.version = version
        self.environment = environment
        self.records = records
        self.metadata = metadata
    }
    
    /// Get records filtered by tags
    public func filter(byTags tags: Set<String>) -> TestDataCollection<T> {
        let filteredRecords = records.filter { record in
            let recordTags = Set(record.tags)
            return tags.isDisjoint(with: recordTags) ? false : true
        }
        
        return TestDataCollection(
            version: version,
            environment: environment,
            records: filteredRecords,
            metadata: metadata
        )
    }
    
    /// Validate all records in the collection
    public func validate() throws {
        for record in records {
            try record.validate()
        }
    }
}

// MARK: - Test Data Relationship

/// Defines relationships between different test data types
public struct TestDataRelationship: Codable {
    /// Type of relationship (e.g., "belongsTo", "hasMany")
    public let type: String
    
    /// Target type name
    public let targetType: String
    
    /// Target record ID
    public let targetId: String
    
    /// Additional relationship metadata
    public let metadata: [String: String]
    
    public init(type: String, targetType: String, targetId: String, metadata: [String: String] = [:]) {
        self.type = type
        self.targetType = targetType
        self.targetId = targetId
        self.metadata = metadata
    }
}

// MARK: - Test Data Environment

/// Configuration for different environments
public struct TestDataEnvironment: Codable {
    /// Environment name
    public let name: String
    
    /// Base URL for APIs in this environment
    public let baseURL: URL?
    
    /// Configuration settings
    public let settings: [String: String]
    
    /// Feature flags for this environment
    public let featureFlags: [String: Bool]
    
    public init(name: String, baseURL: URL? = nil, settings: [String: String] = [:], featureFlags: [String: Bool] = [:]) {
        self.name = name
        self.baseURL = baseURL
        self.settings = settings
        self.featureFlags = featureFlags
    }
}

// MARK: - Test Data Errors

/// Errors that can occur during test data operations
public enum TestDataError: Error, LocalizedError {
    case invalidData(String)
    case validationFailed(String)
    case relationshipNotFound(String)
    case environmentNotFound(String)
    case versionMismatch(String)
    case fileNotFound(String)
    case encodingError(String)
    case decodingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid test data: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .relationshipNotFound(let message):
            return "Relationship not found: \(message)"
        case .environmentNotFound(let message):
            return "Environment not found: \(message)"
        case .versionMismatch(let message):
            return "Version mismatch: \(message)"
        case .fileNotFound(let message):
            return "File not found: \(message)"
        case .encodingError(let message):
            return "Encoding error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}