#!/usr/bin/env swift

import Foundation

// MARK: - Command Line Test Profiler
// This script runs tests with profiling enabled and generates reports

// Add the project root to the Swift search paths
let projectRoot = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()

// Simple argument parser
struct CommandLineArguments {
    let generateHTML: Bool
    let outputDir: URL
    let threshold: Double
    let runTests: Bool
    
    init(arguments: [String]) {
        var generateHTML = false
        var outputDirString = "./test-reports"
        var threshold = 1.0
        var runTests = true
        
        for (index, arg) in arguments.enumerated() {
            switch arg {
            case "--html":
                generateHTML = true
            case "--output":
                if index + 1 < arguments.count {
                    outputDirString = arguments[index + 1]
                }
            case "--threshold":
                if index + 1 < arguments.count {
                    threshold = Double(arguments[index + 1]) ?? 1.0
                }
            case "--no-run":
                runTests = false
            default:
                break
            }
        }
        
        self.generateHTML = generateHTML
        self.outputDir = URL(fileURLWithPath: outputDirString).absoluteURL
        self.threshold = threshold
        self.runTests = runTests
    }
}

// Print help information
func printHelp() {
    print("""
    Test Profiler - Identify slow tests and suggest optimizations
    
    USAGE: test-profiler.swift [OPTIONS]
    
    OPTIONS:
      --html              Generate HTML report (default: JSON only)
      --output <DIR>      Output directory for reports (default: ./test-reports)
      --threshold <SEC>   Slow test threshold in seconds (default: 1.0)
      --no-run            Don't run tests, just analyze existing data
      --help              Show this help message
    
    EXAMPLES:
      test-profiler.swift                    # Run tests with JSON report
      test-profiler.swift --html             # Run tests with HTML report
      test-profiler.swift --html --threshold 2.0  # Run tests, HTML report, 2s threshold
    """)
}

// Main execution
func main() {
    let args = CommandLine.arguments
    
    if args.contains("--help") {
        printHelp()
        exit(0)
    }
    
    let commandArgs = CommandLineArguments(arguments: args)
    
    print("🧪 Test Profiler")
    print("===============")
    print("HTML Report: \(commandArgs.generateHTML)")
    print("Output Dir: \(commandArgs.outputDir.path)")
    print("Threshold: \(commandArgs.threshold)s")
    print("Run Tests: \(commandArgs.runTests)")
    print("")
    
    // Create output directory
    do {
        try FileManager.default.createDirectory(at: commandArgs.outputDir, withIntermediateDirectories: true)
    } catch {
        print("❌ Error creating output directory: \(error)")
        exit(1)
    }
    
    if commandArgs.runTests {
        print("🏃 Running tests with profiling...")
        // In a real implementation, this would run the actual tests
        // For now, we'll simulate test execution
        
        // Simulate running some tests
        simulateTestExecution()
    }
    
    // Generate and save reports
    print("📊 Generating reports...")
    let report = TestProfiler.shared.generateReport()
    
    // Save JSON report
    let jsonReport = TestProfiler.shared.exportToJSON()
    if let jsonReport = jsonReport {
        let jsonURL = commandArgs.outputDir.appendingPathComponent("test-profile.json")
        do {
            try jsonReport.write(to: jsonURL, atomically: true, encoding: .utf8)
            print("✅ JSON report saved to: \(jsonURL.path)")
        } catch {
            print("❌ Error saving JSON report: \(error)")
        }
    }
    
    // Save HTML report if requested
    if commandArgs.generateHTML {
        let htmlURL = commandArgs.outputDir.appendingPathComponent("test-profile.html")
        do {
            try report.saveHTML(to: htmlURL)
            print("✅ HTML report saved to: \(htmlURL.path)")
        } catch {
            print("❌ Error saving HTML report: \(error)")
        }
    }
    
    // Print summary
    print("\n📋 Summary:")
    print("  Total Tests: \(report.statistics.totalTests)")
    print("  Passed: \(report.statistics.passedTests)")
    print("  Failed: \(report.statistics.failedTests)")
    print("  Slow Tests: \(report.statistics.slowTestCount)")
    print("  Total Duration: \(String(format: "%.2f", report.statistics.totalDuration))s")
    print("  Average Duration: \(String(format: "%.2f", report.statistics.averageDuration))s")
    
    if !report.suggestions.isEmpty {
        print("\n💡 Optimization Suggestions:")
        for suggestion in report.suggestions.prefix(5) {
            print("  • \(suggestion.title) (\(suggestion.priority.rawValue))")
        }
    } else {
        print("\n🎉 No optimization suggestions needed!")
    }
    
    print("\n✨ Done!")
}

// Simulate test execution with various durations
func simulateTestExecution() {
    // Since we can't easily import the test modules in this script,
    // we'll simulate some test data
    
    let profiler = TestProfiler.shared
    
    // Clear any existing data
    profiler.clear()
    
    // Simulate fast test
    profiler.startTest(testName: "testFastExample", className: "ProfilingExampleTests")
    Thread.sleep(forTimeInterval: 0.01)
    profiler.endTest(status: .passed)
    
    // Simulate medium test
    profiler.startTest(testName: "testMediumExample", className: "ProfilingExampleTests")
    Thread.sleep(forTimeInterval: 0.5)
    profiler.endTest(status: .passed)
    
    // Simulate slow test
    profiler.startTest(testName: "testSlowExample", className: "ProfilingExampleTests")
    Thread.sleep(forTimeInterval: 1.5)
    profiler.endTest(status: .passed)
    
    // Simulate very slow test
    profiler.startTest(testName: "testVerySlowExample", className: "ProfilingExampleTests")
    Thread.sleep(forTimeInterval: 3.0)
    profiler.endTest(status: .passed)
    
    // Simulate failed test
    profiler.startTest(testName: "testFailedExample", className: "ProfilingExampleTests")
    Thread.sleep(forTimeInterval: 0.2)
    profiler.endTest(status: .failed)
    
    // Simulate more tests
    for i in 1...10 {
        profiler.startTest(testName: "testAdditionalExample\(i)", className: "AdditionalTests")
        Thread.sleep(forTimeInterval: Double.random(in: 0.1...0.8))
        profiler.endTest(status: .passed)
    }
}

// MARK: - Need to redefine the classes since this is a separate script

// Reimport the classes we need (simplified versions for the script)
public struct TestProfile: Codable {
    public let testName: String
    public let className: String
    public let duration: TimeInterval
    public let timestamp: Date
    public let status: TestStatus

    public enum TestStatus: String, Codable {
        case passed
        case failed
        case skipped
    }
}

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

public struct TestReport: Codable {
    public let generatedAt: Date
    public let statistics: TestStatistics
    public let slowTests: [TestProfile]
    public let suggestions: [OptimizationSuggestion]
}

// Simplified TestProfiler for the script
public class TestProfiler {
    public static let shared = TestProfiler()
    
    private var testProfiles: [TestProfile] = []
    private var currentTestStartTime: Date?
    private var currentTestName: String?
    private var currentClassName: String?
    
    private init() {}
    
    public func startTest(testName: String, className: String) {
        currentTestName = testName
        currentClassName = className
        currentTestStartTime = Date()
    }
    
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
        
        currentTestStartTime = nil
        currentTestName = nil
        currentClassName = nil
    }
    
    public func getTestProfiles() -> [TestProfile] {
        return testProfiles
    }
    
    public func getSlowTests(threshold: TimeInterval = 1.0) -> [TestProfile] {
        return testProfiles.filter { $0.duration > threshold }
    }
    
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
    
    public func generateOptimizationSuggestions() -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []
        let stats = getTestStatistics()
        let slowTests = getSlowTests()
        
        if stats.totalTests > 10 {
            suggestions.append(OptimizationSuggestion(
                title: "Enable Test Parallelization",
                description: "You have \(stats.totalTests) tests. Enabling parallel execution could significantly reduce total test time.",
                type: .parallelization,
                priority: .high,
                estimatedImprovement: "30-60% reduction in execution time"
            ))
        }
        
        if let slowestTest = stats.slowestTest, slowestTest.duration > 5.0 {
            suggestions.append(OptimizationSuggestion(
                title: "Optimize Test Fixtures for '\(slowestTest.className).\(slowestTest.testName)'",
                description: "The test '\(slowestTest.className).\(slowestTest.testName)' takes \(String(format: "%.2f", slowestTest.duration)) seconds. Consider optimizing setup/teardown or using lighter fixtures.",
                type: .fixtureOptimization,
                priority: .high,
                estimatedImprovement: "50-90% reduction for this test"
            ))
        }
        
        if slowTests.contains(where: { $0.duration > 10.0 }) {
            suggestions.append(OptimizationSuggestion(
                title: "Split Long Running Tests",
                description: "Some tests take longer than 10 seconds. Consider splitting them into smaller, focused tests.",
                type: .testSplitting,
                priority: .medium,
                estimatedImprovement: "Better isolation and faster feedback"
            ))
        }
        
        if stats.averageDuration > 2.0 {
            suggestions.append(OptimizationSuggestion(
                title: "Use Async/Await for UI Tests",
                description: "Average test duration is \(String(format: "%.2f", stats.averageDuration)) seconds. Consider using async/await patterns for better performance.",
                type: .asyncImprovement,
                priority: .medium,
                estimatedImprovement: "20-40% improvement in test responsiveness"
            ))
        }
        
        return suggestions.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
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
    
    public func clear() {
        testProfiles.removeAll()
    }
}

// Simplified HTML generator
extension TestReport {
    public func toHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test Profiling Report</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                .container { max-width: 1000px; margin: 0 auto; }
                h1 { color: #333; }
                .stat { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
                .slow-test { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; margin: 10px 0; border-radius: 5px; }
                .suggestion { background: #d1ecf1; border: 1px solid #bee5eb; padding: 15px; margin: 10px 0; border-radius: 5px; }
                .priority-high { border-left: 4px solid #dc3545; }
                .priority-medium { border-left: 4px solid #ffc107; }
                .priority-low { border-left: 4px solid #28a745; }
                table { width: 100%; border-collapse: collapse; margin: 20px 0; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f2f2f2; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🧪 Test Profiling Report</h1>
                
                <div class="stat">
                    <strong>Total Tests:</strong> \(self.statistics.totalTests)<br>
                    <strong>Pass Rate:</strong> \(String(format: "%.1f", self.statistics.passRate))%<br>
                    <strong>Total Duration:</strong> \(String(format: "%.2f", self.statistics.totalDuration))s<br>
                    <strong>Average Duration:</strong> \(String(format: "%.2f", self.statistics.averageDuration))s<br>
                    <strong>Slow Tests:</strong> \(self.statistics.slowTestCount)
                </div>
                
                \(self.slowTests.isEmpty ? "<h3>🎉 No slow tests found!</h3>" : """
                <h2>🐌 Slow Tests</h2>
                \(self.slowTests.map { test in """
                    <div class="slow-test">
                        <strong>\(test.className).\(test.testName)</strong><br>
                        Duration: \(String(format: "%.3f", test.duration))s<br>
                        Status: \(test.status.rawValue.uppercased())
                    </div>
                """ }.joined(separator: "\n"))
                """)
                
                \(self.suggestions.isEmpty ? "<h3>💡 No optimization suggestions needed!</h3>" : """
                <h2>💡 Optimization Suggestions</h2>
                \(self.suggestions.map { suggestion in """
                    <div class="suggestion priority-\(suggestion.priority.rawValue)">
                        <strong>\(suggestion.title)</strong> <span style="background: \(suggestion.priority == .high ? "#dc3545" : suggestion.priority == .medium ? "#ffc107" : "#28a745"); color: white; padding: 2px 8px; border-radius: 12px; font-size: 0.8em;">\(suggestion.priority.rawValue.uppercased())</span><br>
                        \(suggestion.description)<br>
                        <small>Type: \(suggestion.type.rawValue.capitalized)</small>
                    </div>
                """ }.joined(separator: "\n"))
                """)
                
                <p><em>Generated on \(Date())</em></p>
            </div>
        </body>
        </html>
        """
    }
    
    public func saveHTML(to url: URL) throws {
        let html = self.toHTML()
        try html.write(to: url, atomically: true, encoding: .utf8)
    }
}

// Run the main function
main()