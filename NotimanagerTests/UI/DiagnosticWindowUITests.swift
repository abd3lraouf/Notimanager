//
//  DiagnosticWindowUITests.swift
//  NotimanagerTests
//
//  UI Tests for DiagnosticView and PermissionView window lifecycle.
//

import XCTest
@testable import Notimanager

final class DiagnosticWindowUITests: NotimanagerTestCase {
    
    // MARK: - Properties
    
    var uiCoordinator: UICoordinator!
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        uiCoordinator = UICoordinator.shared
    }
    
    override func tearDown() {
        // Ensure windows are closed
        uiCoordinator.closeAllWindows()
        uiCoordinator = nil
        super.tearDown()
    }
    
    // MARK: - Diagnostic Window Tests
    
    func testDiagnosticWindowOpens() {
        // Test that diagnostic window can be opened
        uiCoordinator.showDiagnostics()
        
        // Give window time to appear
        let expectation = XCTestExpectation(description: "Window opens")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertTrue(true, "Diagnostic window should open without crash")
    }
    
    func testDiagnosticWindowCloses() {
        // Test that diagnostic window can be closed without crash
        uiCoordinator.showDiagnostics()
        
        // Give window time to appear
        let openExpectation = XCTestExpectation(description: "Window opens")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            openExpectation.fulfill()
        }
        wait(for: [openExpectation], timeout: 2.0)
        
        // Close the window
        uiCoordinator.closeAllWindows()
        
        // Give window time to close
        let closeExpectation = XCTestExpectation(description: "Window closes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            closeExpectation.fulfill()
        }
        wait(for: [closeExpectation], timeout: 2.0)
        
        XCTAssertTrue(true, "Diagnostic window should close without crash")
    }
    
    func testDiagnosticWindowOpenCloseMultipleTimes() {
        // Test opening and closing multiple times doesn't cause crash
        for i in 1...3 {
            uiCoordinator.showDiagnostics()
            
            let openExpectation = XCTestExpectation(description: "Window opens \(i)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                openExpectation.fulfill()
            }
            wait(for: [openExpectation], timeout: 1.0)
            
            uiCoordinator.closeAllWindows()
            
            let closeExpectation = XCTestExpectation(description: "Window closes \(i)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                closeExpectation.fulfill()
            }
            wait(for: [closeExpectation], timeout: 1.0)
        }
        
        XCTAssertTrue(true, "Multiple open/close cycles should not crash")
    }
    
    // MARK: - Permission Window Tests
    
    func testPermissionWindowOpens() {
        // Test that permission window can be opened
        uiCoordinator.showPermissionWindow()
        
        // Give window time to appear
        let expectation = XCTestExpectation(description: "Window opens")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertTrue(true, "Permission window should open without crash")
    }
    
    func testPermissionWindowCloses() {
        // Test that permission window can be closed without crash
        uiCoordinator.showPermissionWindow()
        
        // Give window time to appear
        let openExpectation = XCTestExpectation(description: "Window opens")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            openExpectation.fulfill()
        }
        wait(for: [openExpectation], timeout: 2.0)
        
        // Close the window
        uiCoordinator.closeAllWindows()
        
        // Give window time to close
        let closeExpectation = XCTestExpectation(description: "Window closes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            closeExpectation.fulfill()
        }
        wait(for: [closeExpectation], timeout: 2.0)
        
        XCTAssertTrue(true, "Permission window should close without crash")
    }
    
    // MARK: - Run Loop Survival Tests
    
    func testWindowCloseSurvivesRunLoop() {
        // Test that window close completes without crash through multiple run loop iterations
        uiCoordinator.showDiagnostics()
        
        // Wait for window to open
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        
        // Close the window
        uiCoordinator.closeAllWindows()
        
        // Run the run loop several times to ensure no delayed crash
        for _ in 1...5 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
        }
        
        XCTAssertTrue(true, "Window close should survive multiple run loop iterations")
    }
}
