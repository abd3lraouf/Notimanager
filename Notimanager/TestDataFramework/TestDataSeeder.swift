//
//  TestDataSeeder.swift
//  NotimanagerTestDataFramework
//
//  Created for feature-1768473183452-7a7rg9upp
//  Test Data Framework
//

import Foundation

// MARK: - Test Data Seeder

/// Main class for seeding and managing test data
public class TestDataSeeder {
    
    // MARK: - Singleton
    
    public static let shared = TestDataSeeder()
    
    // MARK: - Properties
    
    /// Registry of all loaded test data collections
    private var testDataRegistry: [String: Any] = [:]
    
    /// Environment configurations
    private var environments: [String: TestDataEnvironment] = [:]
    
    /// Current active environment
    private var currentEnvironment: String = "development"
    
    /// Relationship mappings
    private var relationshipMappings: [String: [TestDataRelationship]] = [:]
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer for singleton
        setupDefaultEnvironments()
    }
    
    // MARK: - Public API
    
    /// Set the current environment
    public func setEnvironment(_ environment: String) {
        guard environments[environment] != nil else {
            print("Warning: Environment '\(environment)' not found, using 'development' instead")
            currentEnvironment = "development"
            return
        }
        currentEnvironment = environment
        print("Test data environment set to: \(environment)")
    }
    
    /// Get the current environment
    public func getCurrentEnvironment() -> String {
        return currentEnvironment
    }
    
    /// Register a test data collection
    public func register<T: TestData>(_ collection: TestDataCollection<T>) throws {
        // Validate the collection
        try collection.validate()
        
        // Check if collection is for current environment or is universal
        if collection.environment != "universal" && collection.environment != currentEnvironment {
            print("Skipping collection for environment '\(collection.environment)' in current environment '\(currentEnvironment)'")
            return
        }
        
        // Store the collection
        let key = "\(String(describing: T.self))_\(collection.version)"
        testDataRegistry[key] = collection
        
        print("Registered test data collection: \(key) with \(collection.records.count) records")
    }
    
    /// Get a test data collection by type and version
    public func getCollection<T: TestData>(type: T.Type, version: String = "1.0") -> TestDataCollection<T>? {
        let key = "\(String(describing: type))_\(version)"
        return testDataRegistry[key] as? TestDataCollection<T>
    }
    
    /// Get all records of a specific type
    public func getAllRecords<T: TestData>(type: T.Type, version: String = "1.0") -> [T] {
        guard let collection = getCollection(type: type, version: version) else {
            return []
        }
        
        return collection.records
    }
    
    /// Get a specific record by ID
    public func getRecord<T: TestData>(type: T.Type, id: String, version: String = "1.0") -> T? {
        let records = getAllRecords(type: type, version: version)
        return records.first { $0.id == id }
    }
    
    /// Get records filtered by tags
    public func getRecordsByTags<T: TestData>(type: T.Type, tags: Set<String>, version: String = "1.0") -> [T] {
        guard let collection = getCollection(type: type, version: version) else {
            return []
        }
        
        let filteredCollection = collection.filter(byTags: tags)
        return filteredCollection.records
    }
    
    /// Load test data from a JSON file
    public func loadFromFile<T: TestData>(type: T.Type, filename: String, bundle: Bundle = .main) throws -> TestDataCollection<T> {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw TestDataError.fileNotFound("Test data file '\(filename).json' not found")
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let collection = try decoder.decode(TestDataCollection<T>.self, from: data)
        
        // Register the loaded collection
        try register(collection)
        
        return collection
    }
    
    /// Save test data to a JSON file
    public func saveToFile<T: TestData>(_ collection: TestDataCollection<T>, filename: String, to directory: URL? = nil) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(collection)
        
        let fileURL: URL
        if let directory = directory {
            fileURL = directory.appendingPathComponent("\(filename).json")
        } else {
            fileURL = URL(fileURLWithPath: "\(filename).json")
        }
        
        try data.write(to: fileURL)
        print("Saved test data to: \(fileURL.path)")
    }
    
    /// Create relationships between test data records
    public func createRelationship(from sourceId: String, to targetId: String, type: String, targetType: String, metadata: [String: String] = [:]) {
        let relationship = TestDataRelationship(
            type: type,
            targetType: targetType,
            targetId: targetId,
            metadata: metadata
        )
        
        if relationshipMappings[sourceId] == nil {
            relationshipMappings[sourceId] = []
        }
        
        relationshipMappings[sourceId]?.append(relationship)
        print("Created relationship: \(sourceId) --\(type)--> \(targetId)")
    }
    
    /// Get related records for a given record
    public func getRelatedRecords<T: TestData>(for record: T, relationshipType: String? = nil) -> [Any] {
        var relatedRecords: [Any] = []
        
        guard let relationships = relationshipMappings[record.id] else {
            return relatedRecords
        }
        
        for relationship in relationships {
            if let type = relationshipType, relationship.type != type {
                continue
            }
            
            // This is a simplified approach - in a real implementation, 
            // you would need to reflectively find the correct type and fetch the record
            print("Found relationship: \(record.id) --\(relationship.type)--> \(relationship.targetId)")
        }
        
        return relatedRecords
    }
    
    /// Clear all registered test data
    public func clearAll() {
        testDataRegistry.removeAll()
        relationshipMappings.removeAll()
        print("Cleared all test data")
    }
    
    /// Print summary of loaded test data
    public func printSummary() {
        print("=== Test Data Summary ===")
        print("Current Environment: \(currentEnvironment)")
        print("Registered Collections: \(testDataRegistry.count)")
        
        for (key, value) in testDataRegistry {
            // Use Mirror to introspect the collection type and get count
            let mirror = Mirror(reflecting: value)
            if let records = mirror.children.first(where: { $0.label == "records" })?.value {
                let countMirror = Mirror(reflecting: records)
                print("  - \(key): \(countMirror.children.count) records")
            } else {
                print("  - \(key): (collection)")
            }
        }
        
        print("Relationship Mappings: \(relationshipMappings.count)")
        print("=========================")
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultEnvironments() {
        // Setup default environments
        environments["development"] = TestDataEnvironment(
            name: "development",
            baseURL: URL(string: "http://localhost:8080"),
            settings: [
                "debug_mode": "true",
                "log_level": "debug",
                "mock_data": "true"
            ],
            featureFlags: [
                "enable_experimental_features": true,
                "skip_validation": true
            ]
        )
        
        environments["testing"] = TestDataEnvironment(
            name: "testing",
            baseURL: URL(string: "https://testing.api.example.com"),
            settings: [
                "debug_mode": "false",
                "log_level": "info",
                "mock_data": "false"
            ],
            featureFlags: [
                "enable_experimental_features": false,
                "skip_validation": false
            ]
        )
        
        environments["production"] = TestDataEnvironment(
            name: "production",
            baseURL: URL(string: "https://api.example.com"),
            settings: [
                "debug_mode": "false",
                "log_level": "error",
                "mock_data": "false"
            ],
            featureFlags: [
                "enable_experimental_features": false,
                "skip_validation": false
            ]
        )
        
        print("Setup default environments: development, testing, production")
    }
}