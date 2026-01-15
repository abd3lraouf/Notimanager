//
//  MutationTester.swift
//  NotimanagerTests
//
//  Created on 2025-01-15 for mutation testing feature.
//

import Foundation
import XCTest

/// Result of a single mutation test
struct MutationTestResult {
    let operatorName: String
    let file: String
    let originalSource: String
    let mutatedSource: String
    let testsPassed: Bool
    let mutationKilled: Bool
    let executionTime: TimeInterval
    let testFailures: [String]
}

/// Summary of mutation testing session
struct MutationTestSummary {
    let totalFiles: Int
    let totalMutations: Int
    let killedMutations: Int
    let survivedMutations: Int
    let mutationScore: Double
    let results: [MutationTestResult]
    
    /// Calculates mutation score (percentage of mutations killed)
    var mutationScorePercentage: Double {
        guard totalMutations > 0 else { return 0.0 }
        return (Double(killedMutations) / Double(totalMutations)) * 100.0
    }
}

/// Main mutation testing engine
class MutationTester {
    
    // MARK: - Properties
    
    private let operators: [MutationOperator]
    private let testRunner: TestRunner
    private let fileManager: FileManager
    private let verbose: Bool
    
    // MARK: - Initialization
    
    init(operators: [MutationOperator], testRunner: TestRunner = XCTestRunner(), verbose: Bool = false) {
        self.operators = operators
        self.testRunner = testRunner
        self.fileManager = FileManager.default
        self.verbose = verbose
    }
    
    // MARK: - Public Methods
    
    /// Runs mutation testing on the specified files
    /// - Parameters:
    ///   - files: Array of file paths to test
    ///   - completion: Callback with mutation test summary
    func runMutationTests(on files: [String], completion: @escaping (MutationTestSummary) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let results = self.testFiles(files)
            let summary = self.createSummary(from: results)
            
            DispatchQueue.main.async {
                completion(summary)
            }
        }
    }
    
    /// Runs mutation testing on files matching a pattern
    /// - Parameters:
    ///   - pattern: Glob pattern for file matching
    ///   - completion: Callback with mutation test summary
    func runMutationTests(on pattern: String, completion: @escaping (MutationTestSummary) -> Void) {
        let files = self.findFiles(matching: pattern)
        log("Found \(files.count) files matching pattern: \(pattern)")
        runMutationTests(on: files, completion: completion)
    }
    
    // MARK: - Private Methods
    
    private func testFiles(_ files: [String]) -> [MutationTestResult] {
        var allResults: [MutationTestResult] = []
        
        for file in files {
            log("Testing file: \(file)")
            let fileResults = testFile(file)
            allResults.append(contentsOf: fileResults)
        }
        
        return allResults
    }
    
    private func testFile(_ filePath: String) -> [MutationTestResult] {
        guard let sourceCode = readFile(filePath) else {
            log("Could not read file: \(filePath)")
            return []
        }
        
        var results: [MutationTestResult] = []
        
        for mutationOperator in operators {
            log("Applying mutation: \(mutationOperator.name) to \(filePath)")
            
            guard let mutatedSource = mutationOperator.apply(to: sourceCode) else {
                log("Could not apply mutation: \(mutationOperator.name) to \(filePath)")
                continue
            }
            
            let result = testMutation(
                operatorName: mutationOperator.name,
                file: filePath,
                originalSource: sourceCode,
                mutatedSource: mutatedSource
            )
            
            results.append(result)
            
            // Restore original file
            _ = writeFile(filePath, content: sourceCode)
        }
        
        return results
    }
    
    private func testMutation(
        operatorName: String,
        file: String,
        originalSource: String,
        mutatedSource: String
    ) -> MutationTestResult {
        let startTime = Date()
        
        // Backup original file
        let backupCreated = backupFile(file)
        
        // Apply mutation
        let mutationApplied = writeFile(file, content: mutatedSource)
        
        guard mutationApplied else {
            log("Failed to apply mutation to file: \(file)")
            return MutationTestResult(
                operatorName: operatorName,
                file: file,
                originalSource: originalSource,
                mutatedSource: mutatedSource,
                testsPassed: false,
                mutationKilled: false,
                executionTime: 0.0,
                testFailures: ["Failed to apply mutation"]
            )
        }
        
        // Run tests
        let testResult = testRunner.runTests()
        let executionTime = Date().timeIntervalSince(startTime)
        
        // Restore original file
        if backupCreated {
            _ = restoreFile(file)
        } else {
            _ = writeFile(file, content: originalSource)
        }
        
        // Determine if mutation was killed (tests failed) or survived (tests passed)
        let mutationKilled = !testResult.passed
        let testFailures = testResult.failures
        
        log("Mutation \(operatorName) on \(file): \(mutationKilled ? "KILLED" : "SURVIVED")")
        
        return MutationTestResult(
            operatorName: operatorName,
            file: file,
            originalSource: originalSource,
            mutatedSource: mutatedSource,
            testsPassed: testResult.passed,
            mutationKilled: mutationKilled,
            executionTime: executionTime,
            testFailures: testFailures
        )
    }
    
    private func createSummary(from results: [MutationTestResult]) -> MutationTestSummary {
        let totalFiles = Set(results.map { $0.file }).count
        let totalMutations = results.count
        let killedMutations = results.filter { $0.mutationKilled }.count
        let survivedMutations = totalMutations - killedMutations
        let mutationScore = totalMutations > 0 ? Double(killedMutations) / Double(totalMutations) : 0.0
        
        return MutationTestSummary(
            totalFiles: totalFiles,
            totalMutations: totalMutations,
            killedMutations: killedMutations,
            survivedMutations: survivedMutations,
            mutationScore: mutationScore,
            results: results
        )
    }
    
    // MARK: - File Management
    
    private func readFile(_ path: String) -> String? {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            log("Error reading file \(path): \(error)")
            return nil
        }
    }
    
    private func writeFile(_ path: String, content: String) -> Bool {
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            return true
        } catch {
            log("Error writing file \(path): \(error)")
            return false
        }
    }
    
    private func backupFile(_ path: String) -> Bool {
        let backupPath = path + ".mutation_backup"
        return fileManager.copyItem(atPath: path, toPath: backupPath)
    }
    
    private func restoreFile(_ path: String) -> Bool {
        let backupPath = path + ".mutation_backup"
        
        guard fileManager.fileExists(atPath: backupPath) else {
            return false
        }
        
        // Remove current file
        try? fileManager.removeItem(atPath: path)
        
        // Restore from backup
        let restored = fileManager.copyItem(atPath: backupPath, toPath: path)
        
        // Remove backup
        try? fileManager.removeItem(atPath: backupPath)
        
        return restored
    }
    
    private func findFiles(matching pattern: String) -> [String] {
        // This is a simplified implementation
        // In a real implementation, you'd use proper glob matching
        let currentPath = fileManager.currentDirectoryPath
        
        guard let files = try? fileManager.contentsOfDirectory(atPath: currentPath) else {
            return []
        }
        
        return files
            .filter { $0.hasSuffix(".swift") }
            .map { "\(currentPath)/\($0)" }
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        if verbose {
            print("[MutationTester] \(message)")
        }
    }
}

// MARK: - Test Runner Protocol

protocol TestRunner {
    /// Runs tests and returns the result
    /// - Returns: Test execution result
    func runTests() -> TestRunResult
}

/// Result of running tests
struct TestRunResult {
    let passed: Bool
    let failures: [String]
    let executionTime: TimeInterval
}

/// XCTest runner implementation
class XCTestRunner: TestRunner {
    
    func runTests() -> TestRunResult {
        // This is a simplified implementation
        // In a real implementation, you'd use XCTest to actually run tests
        // For now, we'll simulate test execution
        
        let suite = XCTestSuite(name: "Mutation Test Suite")
        let observation = XCTestObservationCenter.shared
        
        var testFailures: [String] = []
        var testsPassed = true
        
        // Add test observers to capture results
        observation.addTestObserver(TestFailureObserver { failures in
            testFailures = failures
            testsPassed = failures.isEmpty
        })
        
        // Run the test suite
        suite.run()
        
        return TestRunResult(
            passed: testsPassed,
            failures: testFailures,
            executionTime: 0.0
        )
    }
}

/// Test observer to capture test failures
class TestFailureObserver: NSObject, XCTestObservation {
    private let failureHandler: ([String]) -> Void
    private var failures: [String] = []
    
    init(failureHandler: @escaping ([String]) -> Void) {
        self.failureHandler = failureHandler
        super.init()
    }
    
    func test(_ test: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: Int) {
        let failureMessage = "\(test.name): \(description)"
        failures.append(failureMessage)
    }
    
    func testSuiteDidFinish(_ testSuite: XCTestSuite) {
        failureHandler(failures)
    }
}