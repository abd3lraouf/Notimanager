//
//  MutationTestingExampleTests.swift
//  NotimanagerTests
//
//  Created on 2025-01-15 for mutation testing feature.
//  This example demonstrates mutation testing to verify test effectiveness.
//

import XCTest
@testable import Notimanager

/// Example class to demonstrate mutation testing
/// This class has intentional simple logic that we'll test with mutations
class Calculator {
    func add(_ a: Int, _ b: Int) -> Int {
        return a + b
    }

    func subtract(_ a: Int, _ b: Int) -> Int {
        return a - b
    }

    func isPositive(_ number: Int) -> Bool {
        return number > 0
    }

    func max(_ a: Int, _ b: Int) -> Int {
        return a > b ? a : b
    }

    func divide(_ a: Int, _ b: Int) -> Int? {
        if b == 0 {
            return nil
        }
        return a / b
    }

    func getGrade(for score: Int) -> String {
        if score >= 90 {
            return "A"
        } else if score >= 80 {
            return "B"
        } else if score >= 70 {
            return "C"
        } else if score >= 60 {
            return "D"
        } else {
            return "F"
        }
    }
}

/// Tests that should catch mutations
/// These tests demonstrate effective mutation testing
final class CalculatorTests: XCTestCase {

    // MARK: - Addition Tests

    func testAdd() {
        let calc = Calculator()
        XCTAssertEqual(calc.add(2, 3), 5, "2 + 3 should equal 5")
        XCTAssertEqual(calc.add(-1, 1), 0, "-1 + 1 should equal 0")
        XCTAssertEqual(calc.add(0, 0), 0, "0 + 0 should equal 0")
    }

    // MARK: - Subtraction Tests

    func testSubtract() {
        let calc = Calculator()
        XCTAssertEqual(calc.subtract(5, 3), 2, "5 - 3 should equal 2")
        XCTAssertEqual(calc.subtract(0, 5), -5, "0 - 5 should equal -5")
    }

    // MARK: - Positive Number Tests

    func testIsPositive() {
        let calc = Calculator()
        XCTAssertTrue(calc.isPositive(5), "5 should be positive")
        XCTAssertFalse(calc.isPositive(-5), "-5 should not be positive")
        XCTAssertFalse(calc.isPositive(0), "0 should not be positive")
    }

    // MARK: - Max Tests

    func testMax() {
        let calc = Calculator()
        XCTAssertEqual(calc.max(5, 3), 5, "max(5, 3) should be 5")
        XCTAssertEqual(calc.max(3, 5), 5, "max(3, 5) should be 5")
        XCTAssertEqual(calc.max(5, 5), 5, "max(5, 5) should be 5")
    }

    // MARK: - Division Tests

    func testDivide() {
        let calc = Calculator()
        XCTAssertEqual(calc.divide(10, 2), 5, "10 / 2 should equal 5")
        XCTAssertEqual(calc.divide(7, 2), 3, "7 / 2 should equal 3 (integer division)")
        XCTAssertNil(calc.divide(5, 0), "Division by zero should return nil")
    }

    // MARK: - Grade Tests

    func testGetGrade() {
        let calc = Calculator()
        XCTAssertEqual(calc.getGrade(for: 95), "A", "95 should be an A")
        XCTAssertEqual(calc.getGrade(for: 85), "B", "85 should be a B")
        XCTAssertEqual(calc.getGrade(for: 75), "C", "75 should be a C")
        XCTAssertEqual(calc.getGrade(for: 65), "D", "65 should be a D")
        XCTAssertEqual(calc.getGrade(for: 55), "F", "55 should be an F")
        XCTAssertEqual(calc.getGrade(for: 90), "A", "90 should be an A (boundary)")
    }
}

/// This test suite demonstrates WEAK tests that mutations would SURVIVE
/// Use this to understand why mutation testing is important
final class WeakCalculatorTests: XCTestCase {

    // MARK: - Weak Addition Tests (Mutations would SURVIVE)

    func testAdd_Weak() {
        let calc = Calculator()
        // This test only checks one case - mutations could survive
        XCTAssertEqual(calc.add(1, 1), 2, "1 + 1 should equal 2")
        // Missing: negative numbers, zero, different values
    }

    // MARK: - Weak Positive Tests (Mutations would SURVIVE)

    func testIsPositive_Weak() {
        let calc = Calculator()
        // Only tests positive case - mutation of true to false would NOT be caught
        XCTAssertTrue(calc.isPositive(5), "5 should be positive")
        // Missing: negative numbers, zero
    }
}

/// Demonstration of how mutations would affect tests
final class MutationDemonstrationTests: XCTestCase {

    /// This demonstrates what happens when code has a bug
    /// In real mutation testing, we'd automatically introduce such bugs
    func testEqualityReversalImpact() {
        // Original: XCTAssertEqual(NotificationPosition.allCases.count, 9)
        // Mutated:  XCTAssertNotEqual(NotificationPosition.allCases.count, 9)
        // This mutation would be CAUGHT (killed) because the test would fail

        // But if we had a weak test like:
        // XCTAssertTrue(NotificationPosition.allCases.count > 0)
        // The mutation would SURVIVE because the count is still > 0

        XCTAssertTrue(NotificationPosition.allCases.count == 9, "Mutation test: equality check")
    }

    func testBooleanLiteralMutationImpact() {
        // If we mutate 'true' to 'false' in this test:
        // Original:  XCTAssertTrue(NotificationPosition.topLeft.displayName.contains("Left"))
        // Mutated:  XCTAssertFalse(NotificationPosition.topLeft.displayName.contains("Left"))
        // This mutation would be CAUGHT

        let hasLeft = NotificationPosition.topLeft.displayName.contains("Left")
        XCTAssertTrue(hasLeft, "Mutation test: boolean literal")
    }

    func testConditionalNegationImpact() {
        // If we negate the condition:
        // Original:  if score >= 90 { return "A" }
        // Mutated:  if !(score >= 90) { return "A" }
        // This would be caught by proper tests

        let calc = Calculator()
        let grade = calc.getGrade(for: 95)
        XCTAssertEqual(grade, "A", "Mutation test: conditional negation")
    }
}

/// Mutation testing integration example
final class MutationTestingIntegrationTests: XCTestCase {

    /// Example of how to manually test mutations
    /// In production, use the automated MutationTester
    func testManualMutationExample() {
        // Step 1: Run original code
        let calc = Calculator()
        let originalResult = calc.add(2, 3)

        // Step 2: Simulate mutation (change + to -)
        // In real mutation testing, the source code would be modified
        let mutatedResult = 2 - 3  // Mutation: operator changed from + to -

        // Step 3: Verify mutation would be caught
        XCTAssertEqual(originalResult, 5, "Original code produces 5")
        XCTAssertNotEqual(mutatedResult, 5, "Mutation would be caught")

        print("Mutation Analysis:")
        print("  Original result: \(originalResult)")
        print("  Mutated result: \(mutatedResult)")
        print("  Mutation status: WOULD BE KILLED")
    }

    /// Demonstrates mutation survival scenario
    func testMutationSurvivalExample() {
        // This test has a flaw - it would NOT catch certain mutations
        let calc = Calculator()

        // Weak assertion - doesn't verify exact value
        XCTAssertGreaterThan(calc.add(2, 3), 0, "Result should be positive")

        // If mutation changes + to *, result is still > 0
        let mutatedResult = 2 * 3  // 6, still positive
        XCTAssertGreaterThan(mutatedResult, 0, "Mutation SURVIVES - test passes with mutated code")

        print("Mutation Analysis:")
        print("  Original: 2 + 3 = 5")
        print("  Mutated:  2 * 3 = 6")
        print("  Mutation status: SURVIVED (test didn't catch the bug)")
    }

    func testMutationScoreCalculation() {
        // Calculate mutation score for a hypothetical test suite
        let totalMutations = 10
        let killedMutations = 7
        let mutationScore = Double(killedMutations) / Double(totalMutations) * 100

        print("Mutation Score: \(mutationScore)%")

        // Interpretation
        if mutationScore >= 80 {
            print("Status: Excellent - Tests are effective")
        } else if mutationScore >= 60 {
            print("Status: Good - Some tests could be improved")
        } else {
            print("Status: Poor - Tests need improvement")
        }

        XCTAssertGreaterThanOrEqual(mutationScore, 70, "Mutation score should be at least 70%")
    }
}
