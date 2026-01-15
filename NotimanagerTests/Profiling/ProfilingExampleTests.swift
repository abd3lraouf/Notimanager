//
//  ProfilingExampleTests.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
@testable import Notimanager

/// Example tests that demonstrate the profiling functionality
class ProfilingExampleTests: ProfiledTestCase {
    
    func testFastExample() {
        // This is a fast test
        let result = 2 + 2
        XCTAssertEqual(result, 4)
    }
    
    func testMediumExample() {
        // This test takes a bit longer
        Thread.sleep(forTimeInterval: 0.5)
        let items = ["apple", "banana", "cherry"]
        XCTAssertEqual(items.count, 3)
    }
    
    func testSlowExample() {
        // This is a slow test that would benefit from optimization
        Thread.sleep(forTimeInterval: 1.5)
        var sum = 0
        for i in 1...1000000 {
            sum += i
        }
        XCTAssertEqual(sum, 500000500000)
    }
    
    func testVerySlowExample() {
        // This is a very slow test that definitely needs optimization
        Thread.sleep(forTimeInterval: 3.0)
        let data = (1...1000).map { _ in String.random(length: 100) }
        XCTAssertEqual(data.count, 1000)
    }
    
    func testFailedExample() {
        // This test will fail to demonstrate error handling
        XCTFail("This is a deliberate failure for testing")
    }
}

extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}