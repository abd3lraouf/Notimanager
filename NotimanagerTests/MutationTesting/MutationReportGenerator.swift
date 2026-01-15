//
//  MutationReportGenerator.swift
//  NotimanagerTests
//
//  Created on 2025-01-15 for mutation testing feature.
//

import Foundation

/// Generates reports from mutation testing results
class MutationReportGenerator {
    
    // MARK: - Report Generation
    
    /// Generates a detailed text report
    /// - Parameter summary: Mutation test summary
    /// - Returns: Formatted text report
    func generateTextReport(_ summary: MutationTestSummary) -> String {
        var report = """
        
        🧪 MUTATION TESTING REPORT
        ==========================
        
        Summary:
        - Total files tested: \(summary.totalFiles)
        - Total mutations applied: \(summary.totalMutations)
        - Mutations killed: \(summary.killedMutations)
        - Mutations survived: \(summary.survivedMutations)
        - Mutation score: \(String(format: "%.1f", summary.mutationScorePercentage))%
        
        """
        
        if summary.mutationScorePercentage >= 80.0 {
            report += "✅ Excellent mutation score! Tests are effective.\n\n"
        } else if summary.mutationScorePercentage >= 60.0 {
            report += "⚠️  Good mutation score. Some tests could be improved.\n\n"
        } else if summary.mutationScorePercentage >= 40.0 {
            report += "❌ Poor mutation score. Tests need significant improvement.\n\n"
        } else {
            report += "🚨 Very poor mutation score. Tests are not effective.\n\n"
        }
        
        // Group results by file
        let resultsByFile = Dictionary(grouping: summary.results, by: { $0.file })
        
        for (file, fileResults) in resultsByFile {
            report += """
            File: \(file)
            \(String(repeating: "=", count: file.count + 6))
            
            """
            
            for result in fileResults {
                let status = result.mutationKilled ? "✅ KILLED" : "❌ SURVIVED"
                report += """
                \(status) - \(result.operatorName)
                - Execution time: \(String(format: "%.2f", result.executionTime))s
                """
                
                if !result.testFailures.isEmpty {
                    report += "\n  Failures:"
                    for failure in result.testFailures {
                        report += "\n    - \(failure)"
                    }
                }
                
                report += "\n\n"
            }
        }
        
        // Add recommendations
        report += generateRecommendations(summary)
        
        return report
    }
    
    /// Generates an HTML report
    /// - Parameter summary: Mutation test summary
    /// - Returns: HTML report string
    func generateHTMLReport(_ summary: MutationTestSummary) -> String {
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Mutation Testing Report</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    margin: 0;
                    padding: 20px;
                    background-color: #f5f5f7;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    background: white;
                    border-radius: 10px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                    padding: 30px;
                }
                h1 {
                    color: #1d1d1f;
                    border-bottom: 2px solid #007aff;
                    padding-bottom: 10px;
                }
                .summary {
                    background: #f0f8ff;
                    padding: 20px;
                    border-radius: 8px;
                    margin: 20px 0;
                }
                .metric {
                    display: inline-block;
                    margin: 10px 20px 10px 0;
                }
                .metric-value {
                    font-size: 24px;
                    font-weight: bold;
                    color: #007aff;
                }
                .metric-label {
                    font-size: 14px;
                    color: #666;
                }
                .score-excellent { color: #34c759; }
                .score-good { color: #ff9500; }
                .score-poor { color: #ff3b30; }
                .file-section {
                    margin: 30px 0;
                    border: 1px solid #e0e0e0;
                    border-radius: 8px;
                    padding: 20px;
                }
                .file-name {
                    font-size: 18px;
                    font-weight: bold;
                    color: #1d1d1f;
                    margin-bottom: 15px;
                }
                .mutation-result {
                    margin: 15px 0;
                    padding: 15px;
                    border-radius: 6px;
                    background: #fafafa;
                }
                .killed {
                    border-left: 4px solid #34c759;
                }
                .survived {
                    border-left: 4px solid #ff3b30;
                }
                .operator-name {
                    font-weight: bold;
                    color: #333;
                }
                .execution-time {
                    font-size: 12px;
                    color: #666;
                }
                .failures {
                    margin-top: 10px;
                    padding: 10px;
                    background: #ffebee;
                    border-radius: 4px;
                    font-size: 14px;
                }
                .recommendations {
                    margin-top: 30px;
                    padding: 20px;
                    background: #fff3cd;
                    border-radius: 8px;
                    border-left: 4px solid #ffc107;
                }
                .recommendations h3 {
                    margin-top: 0;
                    color: #856404;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🧪 Mutation Testing Report</h1>
                
                <div class="summary">
                    <h2>Summary</h2>
                    <div class="metric">
                        <div class="metric-value">\(summary.totalFiles)</div>
                        <div class="metric-label">Files Tested</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">\(summary.totalMutations)</div>
                        <div class="metric-label">Total Mutations</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">\(summary.killedMutations)</div>
                        <div class="metric-label">Killed</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">\(summary.survivedMutations)</div>
                        <div class="metric-label">Survived</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value score-\(scoreClass(for: summary.mutationScorePercentage))">\(String(format: "%.1f", summary.mutationScorePercentage))%</div>
                        <div class="metric-label">Mutation Score</div>
                    </div>
                </div>
        """
        
        // Add file results
        let resultsByFile = Dictionary(grouping: summary.results, by: { $0.file })
        
        for (file, fileResults) in resultsByFile {
            html += """
                
                <div class="file-section">
                    <div class="file-name">📁 \(file)</div>
            """
            
            for result in fileResults {
                let statusClass = result.mutationKilled ? "killed" : "survived"
                let statusIcon = result.mutationKilled ? "✅" : "❌"
                
                html += """
                    <div class="mutation-result \(statusClass)">
                        <div class="operator-name">\(statusIcon) \(result.operatorName)</div>
                        <div class="execution-time">Execution time: \(String(format: "%.2f", result.executionTime))s</div>
                """
                
                if !result.testFailures.isEmpty {
                    html += """
                        <div class="failures">
                            <strong>Test Failures:</strong>
                            <ul>
                    """
                    for failure in result.testFailures {
                        html += "<li>\(failure)</li>"
                    }
                    html += """
                            </ul>
                        </div>
                    """
                }
                
                html += """
                    </div>
                """
            }
            
            html += """
                </div>
            """
        }
        
        // Add recommendations
        html += """
                <div class="recommendations">
                    <h3>💡 Recommendations</h3>
                    \(generateRecommendations(summary).replacingOccurrences(of: "\n", with: "<br>"))
                </div>
            </div>
        </body>
        </html>
        """
        
        return html
    }
    
    /// Generates a JSON report
    /// - Parameter summary: Mutation test summary
    /// - Returns: JSON string
    func generateJSONReport(_ summary: MutationTestSummary) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let report: [String: Any] = [
            "summary": [
                "total_files": summary.totalFiles,
                "total_mutations": summary.totalMutations,
                "killed_mutations": summary.killedMutations,
                "survived_mutations": summary.survivedMutations,
                "mutation_score": summary.mutationScore,
                "mutation_score_percentage": summary.mutationScorePercentage
            ],
            "results": summary.results.map { result in
                [
                    "operator_name": result.operatorName,
                    "file": result.file,
                    "tests_passed": result.testsPassed,
                    "mutation_killed": result.mutationKilled,
                    "execution_time": result.executionTime,
                    "test_failures": result.testFailures
                ]
            }
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: report, options: .prettyPrinted)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"Failed to generate JSON report\"}"
        }
    }
    
    /// Saves report to file
    /// - Parameters:
    ///   - report: Report content
    ///   - filePath: File path to save to
    ///   - format: Report format (text, html, json)
    /// - Returns: True if saved successfully
    func saveReport(_ report: String, to filePath: String, format: ReportFormat) -> Bool {
        do {
            let finalPath = filePath.hasSuffix(".\(format.fileExtension)") ? filePath : "\(filePath).\(format.fileExtension)"
            try report.write(toFile: finalPath, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Error saving report: \(error)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func scoreClass(for score: Double) -> String {
        if score >= 80.0 { return "excellent" }
        if score >= 60.0 { return "good" }
        return "poor"
    }
    
    private func generateRecommendations(_ summary: MutationTestSummary) -> String {
        var recommendations = "Recommendations:\n\n"
        
        if summary.mutationScorePercentage >= 80.0 {
            recommendations += "✅ Your tests are very effective! Keep up the good work.\n\n"
            recommendations += "Additional suggestions:\n"
            recommendations += "- Consider adding more edge case tests\n"
            recommendations += "- Regular mutation testing to maintain quality\n"
        } else if summary.mutationScorePercentage >= 60.0 {
            recommendations += "⚠️  Your tests are good but could be improved:\n\n"
            recommendations += "Focus on:\n"
            recommendations += "- Adding tests for survived mutations\n"
            recommendations += "- Improving assertion coverage\n"
            recommendations += "- Testing edge cases and error conditions\n"
        } else {
            recommendations += "🚨 Your tests need significant improvement:\n\n"
            recommendations += "Priority actions:\n"
            recommendations += "- Review all survived mutations\n"
            recommendations += "- Add comprehensive tests for each mutation\n"
            recommendations += "- Focus on boundary conditions and error handling\n"
            recommendations += "- Consider test-driven development for new features\n"
        }
        
        // Find most common survived mutations
        let survivedByOperator = Dictionary(grouping: summary.results.filter { !$0.mutationKilled }, by: { $0.operatorName })
        let topSurvived = survivedByOperator.sorted { $0.value.count > $1.value.count }.prefix(3)
        
        if !topSurvived.isEmpty {
            recommendations += "\nMost common survived mutations:\n"
            for (operatorName, results) in topSurvived {
                recommendations += "- \(operatorName) (\(results.count) occurrences)\n"
            }
        }
        
        return recommendations
    }
}

// MARK: - Report Format

enum ReportFormat {
    case text
    case html
    case json
    
    var fileExtension: String {
        switch self {
        case .text: return "txt"
        case .html: return "html"
        case .json: return "json"
        }
    }
    
    var description: String {
        switch self {
        case .text: return "Plain Text"
        case .html: return "HTML"
        case .json: return "JSON"
        }
    }
}