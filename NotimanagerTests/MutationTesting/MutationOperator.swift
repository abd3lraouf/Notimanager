//
//  MutationOperator.swift
//  NotimanagerTests
//
//  Created on 2025-01-15 for mutation testing feature.
//

import Foundation

/// Protocol for mutation operators that can introduce intentional bugs
protocol MutationOperator {
    /// Name of the mutation operator
    var name: String { get }
    
    /// Description of what this operator does
    var description: String { get }
    
    /// Applies the mutation to the given source code
    /// - Parameter source: The source code to mutate
    /// - Returns: The mutated source code, or nil if mutation cannot be applied
    func apply(to source: String) -> String?
    
    /// Checks if the mutation can be applied to the given source code
    /// - Parameter source: The source code to check
    /// - Returns: True if mutation can be applied
    func canApply(to source: String) -> Bool
}

/// Base class for mutation operators
class BaseMutationOperator: MutationOperator {
    let name: String
    let description: String
    
    init(name: String, description: String) {
        self.name = name
        self.description = description
    }
    
    func apply(to source: String) -> String? {
        fatalError("Subclasses must implement apply(to:)")
    }
    
    func canApply(to source: String) -> Bool {
        return apply(to: source) != nil
    }
}

/// Mutates equality comparisons (== to !=)
class EqualityReversalMutation: BaseMutationOperator {
    init() {
        super.init(
            name: "Equality Reversal",
            description: "Changes == to != and != to =="
        )
    }
    
    override func apply(to source: String) -> String? {
        var mutated = source
        
        // Change == to !=
        mutated = mutated.replacingOccurrences(
            of: " == ",
            with: " != "
        )
        
        // Change != to ==
        mutated = mutated.replacingOccurrences(
            of: " != ",
            with: " == "
        )
        
        return mutated == source ? nil : mutated
    }
}

/// Mutates boolean literals (true to false, false to true)
class BooleanLiteralMutation: BaseMutationOperator {
    init() {
        super.init(
            name: "Boolean Literal",
            description: "Changes true to false and false to true"
        )
    }
    
    override func apply(to source: String) -> String? {
        var mutated = source
        
        // Only mutate actual boolean literals, not those in strings or comments
        let patterns = [
            "\\btrue\\b",
            "\\bfalse\\b"
        ]
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(mutated.startIndex..<mutated.endIndex, in: mutated)
            
            regex?.enumerateMatches(in: mutated, options: [], range: range) { match, _, _ in
                if let matchRange = match?.range {
                    let startIndex = mutated.index(mutated.startIndex, offsetBy: matchRange.location)
                    let endIndex = mutated.index(startIndex, offsetBy: matchRange.length)
                    let matchedText = String(mutated[startIndex..<endIndex])
                    
                    if matchedText == "true" {
                        mutated.replaceSubrange(startIndex..<endIndex, with: "false")
                    } else if matchedText == "false" {
                        mutated.replaceSubrange(startIndex..<endIndex, with: "true")
                    }
                }
            }
        }
        
        return mutated == source ? nil : mutated
    }
}

/// Mutates return statements in void functions
class VoidReturnMutation: BaseMutationOperator {
    init() {
        super.init(
            name: "Void Return",
            description: "Inserts early return statements in void functions"
        )
    }
    
    override func apply(to source: String) -> String? {
        let lines = source.components(separatedBy: .newlines)
        var mutatedLines: [String] = []
        var mutationApplied = false
        
        for line in lines {
            mutatedLines.append(line)
            
            // Look for function declarations with void return
            if line.contains("func ") && line.contains("-> Void") {
                // Skip if it's a test function
                if line.contains("test") || line.contains("XCTest") {
                    continue
                }
                
                // Find the opening brace
                if let braceRange = line.range(of: "\\{", options: .regularExpression) {
                    mutatedLines.append("    return // Mutation: Early return")
                    mutationApplied = true
                }
            }
        }
        
        return mutationApplied ? mutatedLines.joined(separator: "\n") : nil
    }
}

/// Mutates numeric literals by incrementing/decrementing
class NumericLiteralMutation: BaseMutationOperator {
    init() {
        super.init(
            name: "Numeric Literal",
            description: "Changes numeric literals (0->1, 1->0, etc.)"
        )
    }
    
    override func apply(to source: String) -> String? {
        var mutated = source
        
        // Change 0 to 1
        mutated = mutated.replacingOccurrences(
            of: "\\b0\\b",
            with: "1",
            options: .regularExpression
        )
        
        // Change 1 to 0 (but be careful about "1.0" or other contexts)
        mutated = mutated.replacingOccurrences(
            of: "\\b1\\b",
            with: "0",
            options: .regularExpression
        )
        
        // Change positive numbers to negative and vice versa
        let negativeRegex = try? NSRegularExpression(pattern: "\\b(-?\\d+)\\b", options: [])
        let range = NSRange(mutated.startIndex..<mutated.endIndex, in: mutated)
        
        mutated = negativeRegex?.stringByReplacingMatches(
            in: mutated,
            options: [],
            range: range,
            withTemplate: "$1"
        ) ?? mutated
        
        return mutated == source ? nil : mutated
    }
}

/// Mutates conditional statements (if conditions)
class ConditionalNegationMutation: BaseMutationOperator {
    init() {
        super.init(
            name: "Conditional Negation",
            description: "Negates if conditions by adding ! operator"
        )
    }
    
    override func apply(to source: String) -> String? {
        var mutated = source
        var mutationApplied = false
        
        // Find if statements and negate their conditions
        let ifRegex = try? NSRegularExpression(
            pattern: "(if\\s*\\()([^)]+)(\\))",
            options: []
        )
        
        let range = NSRange(mutated.startIndex..<mutated.endIndex, in: mutated)
        
        mutated = ifRegex?.stringByReplacingMatches(
            in: mutated,
            options: [],
            range: range,
            withTemplate: "$1!($2)$3"
        ) ?? mutated
        
        mutationApplied = mutated != source
        
        return mutationApplied ? mutated : nil
    }
}

/// Factory for creating mutation operators
class MutationOperatorFactory {
    /// Creates all available mutation operators
    /// - Returns: Array of mutation operators
    static func createAllOperators() -> [MutationOperator] {
        return [
            EqualityReversalMutation(),
            BooleanLiteralMutation(),
            VoidReturnMutation(),
            NumericLiteralMutation(),
            ConditionalNegationMutation()
        ]
    }
    
    /// Creates operators by name
    /// - Parameter names: Array of operator names
    /// - Returns: Array of matching mutation operators
    static func createOperators(names: [String]) -> [MutationOperator] {
        let allOperators = createAllOperators()
        return allOperators.filter { names.contains($0.name) }
    }
}