//
//  TestProfiler.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import Foundation
import XCTest

/// Profiling data for a single test
public struct TestProfile: Codable, Equatable {
    public let testName: String
    public let className: String
    public let duration: TimeInterval
    public let timestamp: Date
    public let status: TestStatus
    
    public enum TestStatus: String, Codable, Equatable {
        case passed
        case failed
        case skipped
    }
    
    public var fullName: String {
        return "\(className).\(testName)"
    }
    
    public var isSlow: Bool {
        return duration > 1.0 // Tests taking longer than 1 second are considered slow
    }
}

/// Test profiling suggestions
public struct OptimizationSuggestion: Codable {
    public let title: String
    public let description: String
    public let type: SuggestionType
    public let priority: Priority
    public let estimatedImprovement: String?
    
    public enum SuggestionType: String, Codable {
        case parallelization
        case fixtureOptimization
        case testSplitting
        case asyncImprovement
        case mockOptimization
        case setupTeardown
        case other
    }
    
    public enum Priority: String, Codable {
        case high
        case medium
        case low
    }
}

/// Main test profiler class
public class TestProfiler {
    public static let shared = TestProfiler()
    
    private var testProfiles: [TestProfile] = []
    private var currentTestStartTime: Date?
    private var currentTestName: String?
    private var currentClassName: String?
    
    private init() {}
    
    /// Start profiling a test
    public func startTest(testName: String, className: String) {
        currentTestName = testName
        currentClassName = className
        currentTestStartTime = Date()
    }
    
    /// End profiling a test and record the result
    public func endTest(status: TestProfile.TestStatus = .passed) {
        guard let startTime = currentTestStartTime,
              let testName = currentTestName,
              let className = currentClassName else {
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let profile = TestProfile(
            testName: testName,
            className: className,
            duration: duration,
            timestamp: Date(),
            status: status
        )
        
        testProfiles.append(profile)
        
        // Reset current test info
        currentTestStartTime = nil
        currentTestName = nil
        currentClassName = nil
    }
    
    /// Get all recorded test profiles
    public func getTestProfiles() -> [TestProfile] {
        return testProfiles
    }
    
    /// Get slow tests (tests taking longer than 1 second)
    public func getSlowTests(threshold: TimeInterval = 1.0) -> [TestProfile] {
        return testProfiles.filter { $0.duration > threshold }
    }
    
    /// Get test statistics
    public func getTestStatistics() -> TestStatistics {
        let totalTests = testProfiles.count
        let passedTests = testProfiles.filter { $0.status == .passed }.count
        let failedTests = testProfiles.filter { $0.status == .failed }.count
        let skippedTests = testProfiles.filter { $0.status == .skipped }.count
        
        let totalDuration = testProfiles.reduce(0) { $0 + $1.duration }
        let averageDuration = totalTests > 0 ? totalDuration / Double(totalTests) : 0
        let slowTests = getSlowTests()
        
        return TestStatistics(
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            skippedTests: skippedTests,
            totalDuration: totalDuration,
            averageDuration: averageDuration,
            slowTestCount: slowTests.count,
            slowestTest: testProfiles.max(by: { $0.duration < $1.duration })
        )
    }
    
    /// Generate optimization suggestions based on test profiles
    public func generateOptimizationSuggestions() -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []
        let stats = getTestStatistics()
        let slowTests = getSlowTests()
        
        // Suggest parallelization if there are many tests
        if stats.totalTests > 10 {
            suggestions.append(OptimizationSuggestion(
                title: "Enable Test Parallelization",
                description: "You have \(stats.totalTests) tests. Enabling parallel execution could significantly reduce total test time.",
                type: .parallelization,
                priority: .high,
                estimatedImprovement: "30-60% reduction in execution time"
            ))
        }
        
        // Suggest fixture optimization if there are very slow tests
        if let slowestTest = stats.slowestTest, slowestTest.duration > 5.0 {
            suggestions.append(OptimizationSuggestion(
                title: "Optimize Test Fixtures for '\(slowestTest.fullName)'",
                description: "The test '\(slowestTest.fullName)' takes \(String(format: "%.2f", slowestTest.duration)) seconds. Consider optimizing setup/teardown or using lighter fixtures.",
                type: .fixtureOptimization,
                priority: .high,
                estimatedImprovement: "50-90% reduction for this test"
            ))
        }
        
        // Suggest test splitting if some tests are very long
        if slowTests.contains(where: { $0.duration > 10.0 }) {
            suggestions.append(OptimizationSuggestion(
                title: "Split Long Running Tests",
                description: "Some tests take longer than 10 seconds. Consider splitting them into smaller, focused tests.",
                type: .testSplitting,
                priority: .medium,
                estimatedImprovement: "Better isolation and faster feedback"
            ))
        }
        
        // Suggest async improvements if average test time is high
        if stats.averageDuration > 2.0 {
            suggestions.append(OptimizationSuggestion(
                title: "Use Async/Await for UI Tests",
                description: "Average test duration is \(String(format: "%.2f", stats.averageDuration)) seconds. Consider using async/await patterns for better performance.",
                type: .asyncImprovement,
                priority: .medium,
                estimatedImprovement: "20-40% improvement in test responsiveness"
            ))
        }
        
        // Suggest setup/teardown optimization if there are many tests
        if stats.totalTests > 5 {
            suggestions.append(OptimizationSuggestion(
                title: "Optimize Setup and Teardown",
                description: "With \(stats.totalTests) tests, optimizing setup and teardown methods can significantly improve performance.",
                type: .setupTeardown,
                priority: .medium,
                estimatedImprovement: "10-30% reduction in overhead"
            ))
        }
        
        return suggestions.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    /// Generate a comprehensive report
    public func generateReport() -> TestReport {
        let stats = getTestStatistics()
        let suggestions = generateOptimizationSuggestions()
        let slowTests = getSlowTests()
        
        return TestReport(
            generatedAt: Date(),
            statistics: stats,
            slowTests: slowTests,
            suggestions: suggestions
        )
    }
    
    /// Clear all test profiles
    public func clear() {
        testProfiles.removeAll()
    }
    
    /// Export test profiles to JSON
    public func exportToJSON() -> String? {
        let report = generateReport()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(report)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding test profiles: \(error)")
            return nil
        }
    }
}

/// Test statistics
public struct TestStatistics: Codable {
    public let totalTests: Int
    public let passedTests: Int
    public let failedTests: Int
    public let skippedTests: Int
    public let totalDuration: TimeInterval
    public let averageDuration: TimeInterval
    public let slowTestCount: Int
    public let slowestTest: TestProfile?
    
    public var passRate: Double {
        return totalTests > 0 ? Double(passedTests) / Double(totalTests) * 100 : 0
    }
}

/// Comprehensive test report
public struct TestReport: Codable {
    public let generatedAt: Date
    public let statistics: TestStatistics
    public let slowTests: [TestProfile]
    public let suggestions: [OptimizationSuggestion]
}

/// Base class for test cases that want to use profiling
open class ProfiledTestCase: XCTestCase {
    open override func setUp() {
        super.setUp()
        TestProfiler.shared.startTest(
            testName: String(name.split(separator: " ").last ?? "unknown"),
            className: String(String(describing: type(of: self)).split(separator: " ").first ?? "unknown")
        )
    }
    
    open override func tearDown() {
        let status: TestProfile.TestStatus = testRun?.hasSucceeded == true ? .passed : .failed
        TestProfiler.shared.endTest(status: status)
        super.tearDown()
    }
}