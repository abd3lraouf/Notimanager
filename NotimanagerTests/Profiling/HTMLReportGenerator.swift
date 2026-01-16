//
//  HTMLReportGenerator.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import Foundation

/// Generates HTML reports for test profiling data
public class HTMLReportGenerator {
    
    /// Generate an HTML report from test profiling data
    public static func generateHTMLReport(_ report: TestReport) -> String {
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Test Profiling Report</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    margin: 0;
                    padding: 20px;
                    background-color: #f5f5f5;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    background: white;
                    border-radius: 8px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                    padding: 30px;
                }
                h1 {
                    color: #333;
                    border-bottom: 3px solid #007AFF;
                    padding-bottom: 10px;
                }
                h2 {
                    color: #555;
                    margin-top: 30px;
                }
                .stats-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 20px;
                    margin: 20px 0;
                }
                .stat-card {
                    background: #f8f9fa;
                    padding: 20px;
                    border-radius: 8px;
                    border-left: 4px solid #007AFF;
                }
                .stat-value {
                    font-size: 2em;
                    font-weight: bold;
                    color: #007AFF;
                }
                .stat-label {
                    color: #666;
                    font-size: 0.9em;
                }
                .slow-tests {
                    margin: 20px 0;
                }
                .slow-test {
                    background: #fff3cd;
                    border: 1px solid #ffeaa7;
                    border-radius: 4px;
                    padding: 15px;
                    margin: 10px 0;
                }
                .slow-test-name {
                    font-weight: bold;
                    color: #856404;
                }
                .slow-test-duration {
                    color: #d63031;
                    font-weight: bold;
                }
                .suggestions {
                    margin: 20px 0;
                }
                .suggestion {
                    background: #d1ecf1;
                    border: 1px solid #bee5eb;
                    border-radius: 4px;
                    padding: 15px;
                    margin: 10px 0;
                }
                .suggestion.high { border-left: 4px solid #dc3545; }
                .suggestion.medium { border-left: 4px solid #ffc107; }
                .suggestion.low { border-left: 4px solid #28a745; }
                .suggestion-title {
                    font-weight: bold;
                    color: #0c5460;
                }
                .suggestion-priority {
                    display: inline-block;
                    padding: 2px 8px;
                    border-radius: 12px;
                    font-size: 0.8em;
                    font-weight: bold;
                    color: white;
                    margin-left: 10px;
                }
                .priority-high { background-color: #dc3545; }
                .priority-medium { background-color: #ffc107; }
                .priority-low { background-color: #28a745; }
                .timestamp {
                    color: #666;
                    font-style: italic;
                    text-align: right;
                    margin-top: 20px;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 20px 0;
                }
                th, td {
                    border: 1px solid #ddd;
                    padding: 12px;
                    text-align: left;
                }
                th {
                    background-color: #f2f2f2;
                    font-weight: bold;
                }
                tr:nth-child(even) {
                    background-color: #f9f9f9;
                }
                .duration-bar {
                    background-color: #e9ecef;
                    height: 20px;
                    border-radius: 10px;
                    overflow: hidden;
                    margin: 5px 0;
                }
                .duration-fill {
                    height: 100%;
                    background: linear-gradient(90deg, #28a745, #ffc107, #dc3545);
                    transition: width 0.3s ease;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🧪 Test Profiling Report</h1>
                
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-value">\(report.statistics.totalTests)</div>
                        <div class="stat-label">Total Tests</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">\(String(format: "%.1f", report.statistics.passRate))%</div>
                        <div class="stat-label">Pass Rate</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">\(String(format: "%.2f", report.statistics.totalDuration))s</div>
                        <div class="stat-label">Total Duration</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">\(String(format: "%.2f", report.statistics.averageDuration))s</div>
                        <div class="stat-label">Average Duration</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">\(report.statistics.slowTestCount)</div>
                        <div class="stat-label">Slow Tests</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">\(report.suggestions.count)</div>
                        <div class="stat-label">Optimization Suggestions</div>
                    </div>
                </div>
                
                \(generateSlowTestsSection(report.slowTests))
                
                \(generateTestDetailsTable(report))
                
                \(generateSuggestionsSection(report.suggestions))
                
                <div class="timestamp">
                    Generated on \(formatDate(report.generatedAt))
                </div>
            </div>
        </body>
        </html>
        """
        
        return html
    }
    
    private static func generateSlowTestsSection(_ slowTests: [TestProfile]) -> String {
        guard !slowTests.isEmpty else {
            return ""
        }
        
        let slowTestItems = slowTests.map { test in
            """
            <div class="slow-test">
                <div class="slow-test-name">\(test.fullName)</div>
                <div>Duration: <span class="slow-test-duration">\(String(format: "%.3f", test.duration))s</span></div>
                <div>Status: \(test.status.rawValue.uppercased())</div>
                <div class="duration-bar">
                    <div class="duration-fill" style="width: \((test.duration / 10.0) * 100)%"></div>
                </div>
            </div>
            """
        }.joined(separator: "\n")
        
        return """
        <h2>🐌 Slow Tests (> 1.0 second)</h2>
        <div class="slow-tests">
            \(slowTestItems)
        </div>
        """
    }
    
    private static func generateTestDetailsTable(_ report: TestReport) -> String {
        let allTests = (report.slowTests + (TestProfiler.shared.getTestProfiles().filter { !report.slowTests.contains($0) }))
            .sorted { $0.duration > $1.duration }
        
        let testRows = allTests.map { test in
            let statusClass = test.status == .passed ? "style='color: #28a745;'" : test.status == .failed ? "style='color: #dc3545;'" : "style='color: #6c757d;'"
            let durationClass = test.isSlow ? "style='color: #dc3545; font-weight: bold;'" : ""
            
            return """
            <tr>
                <td>\(test.testName)</td>
                <td>\(test.className)</td>
                <td \(durationClass)>\(String(format: "%.3f", test.duration))s</td>
                <td \(statusClass)>\(test.status.rawValue.uppercased())</td>
            </tr>
            """
        }.joined(separator: "\n")
        
        return """
        <h2>📊 All Test Details</h2>
        <table>
            <thead>
                <tr>
                    <th>Test Name</th>
                    <th>Class</th>
                    <th>Duration</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                \(testRows)
            </tbody>
        </table>
        """
    }
    
    private static func generateSuggestionsSection(_ suggestions: [OptimizationSuggestion]) -> String {
        guard !suggestions.isEmpty else {
            return """
            <h2>💡 Optimization Suggestions</h2>
            <div class="suggestions">
                <div class="suggestion">
                    <div class="suggestion-title">No optimizations needed!</div>
                    <p>Your tests are performing well. Keep up the good work!</p>
                </div>
            </div>
            """
        }
        
        let suggestionItems = suggestions.map { suggestion in
            """
            <div class="suggestion \(suggestion.priority.rawValue)">
                <div class="suggestion-title">
                    \(suggestion.title)
                    <span class="suggestion-priority priority-\(suggestion.priority.rawValue)">\(suggestion.priority.rawValue.uppercased())</span>
                </div>
                <p>\(suggestion.description)</p>
                \(suggestion.estimatedImprovement != nil ? "<p><strong>Estimated Improvement:</strong> \(suggestion.estimatedImprovement!)</p>" : "")
                <p><small>Type: \(suggestion.type.rawValue.capitalized)</small></p>
            </div>
            """
        }.joined(separator: "\n")
        
        return """
        <h2>💡 Optimization Suggestions</h2>
        <div class="suggestions">
            \(suggestionItems)
        </div>
        """
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

extension TestReport {
    /// Generate HTML report
    public func toHTML() -> String {
        return HTMLReportGenerator.generateHTMLReport(self)
    }
    
    /// Save HTML report to file
    public func saveHTML(to url: URL) throws {
        let html = self.toHTML()
        try html.write(to: url, atomically: true, encoding: .utf8)
    }
}