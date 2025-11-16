//
//  TestHelpers.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
import AppKit
@testable import Notimanager

/// UI Testing helper class with methods for launching app, finding windows, and simulating interactions
class UITestHelpers {

    // MARK: - App Launch Helpers

    /// Launches the Notimanager app and returns the application instance
    /// - Parameter timeout: Maximum time to wait for app to launch (default: 5.0 seconds)
    /// - Returns: The launched XCUIApplication instance
    static func launchApp(timeout: TimeInterval = 5.0) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--UITesting"]
        app.launch()

        // Wait for app to be running
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "state == XCUIApplication.State.running"),
            object: app
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)

        if result != .completed {
            XCTFail("App failed to launch within \(timeout) seconds")
        }

        return app
    }

    /// Terminates the Notimanager app
    /// - Parameter app: The application instance to terminate
    static func terminateApp(_ app: XCUIApplication) {
        app.terminate()
    }

    // MARK: - Window Finding Helpers

    /// Finds a window by its title
    /// - Parameters:
    ///   - title: The window title to search for
    ///   - timeout: Maximum time to wait for window to appear (default: 2.0 seconds)
    /// - Returns: The found XCUIElement, or nil if not found
    static func findWindow(title: String, timeout: TimeInterval = 2.0) -> XCUIElement? {
        let app = XCUIApplication()
        let window = app.windows[title]

        let exists = window.waitForExistence(timeout: timeout)
        return exists ? window : nil
    }

    /// Finds a window by its identifier
    /// - Parameters:
    ///   - identifier: The window identifier to search for
    ///   - timeout: Maximum time to wait for window to appear (default: 2.0 seconds)
    /// - Returns: The found XCUIElement, or nil if not found
    static func findWindow(identifier: String, timeout: TimeInterval = 2.0) -> XCUIElement? {
        let app = XCUIApplication()
        let window = app.windows.matching(identifier: identifier).firstMatch

        let exists = window.waitForExistence(timeout: timeout)
        return exists ? window : nil
    }

    /// Returns all visible windows
    /// - Returns: Array of XCUIElement representing all windows
    static func getAllWindows() -> [XCUIElement] {
        let app = XCUIApplication()
        return app.windows.allElementsBoundByIndex
    }

    // MARK: - Menu Bar Helpers

    /// Finds the menu bar icon
    /// - Parameter timeout: Maximum time to wait for icon to appear (default: 2.0 seconds)
    /// - Returns: The status bar item, or nil if not found
    static func findMenuBarIcon(timeout: TimeInterval = 2.0) -> XCUIElement? {
        let app = XCUIApplication()
        // Status items are typically found in the status bar
        let statusItems = app.statusItems.allElementsBoundByIndex

        for item in statusItems {
            if item.exists {
                return item
            }
        }

        return nil
    }

    /// Clicks the menu bar icon to open the menu
    /// - Parameter timeout: Maximum time to wait for icon to be clickable (default: 2.0 seconds)
    /// - Returns: True if click was successful, false otherwise
    static func clickMenuBarIcon(timeout: TimeInterval = 2.0) -> Bool {
        guard let icon = findMenuBarIcon(timeout: timeout) else {
            XCTFail("Menu bar icon not found")
            return false
        }

        icon.click()
        return true
    }

    /// Finds a menu item by its title
    /// - Parameter title: The menu item title to search for
    /// - Returns: The menu item, or nil if not found
    static func findMenuItem(title: String) -> XCUIElement? {
        let app = XCUIApplication()
        let menuItem = app.menuItems[title]

        return menuItem.exists ? menuItem : nil
    }

    /// Clicks a menu item by its title
    /// - Parameters:
    ///   - title: The menu item title to click
    ///   - timeout: Maximum time to wait for menu item to be available (default: 1.0 second)
    /// - Returns: True if click was successful, false otherwise
    static func clickMenuItem(title: String, timeout: TimeInterval = 1.0) -> Bool {
        guard let menuItem = findMenuItem(title: title) else {
            XCTFail("Menu item '\(title)' not found")
            return false
        }

        let exists = menuItem.waitForExistence(timeout: timeout)
        guard exists else {
            XCTFail("Menu item '\(title)' did not become available")
            return false
        }

        menuItem.click()
        return true
    }

    // MARK: - UI Element Interaction Helpers

    /// Simulates a click on a UI element
    /// - Parameters:
    ///   - element: The element to click
    ///   - timeout: Maximum time to wait for element to be available (default: 1.0 second)
    /// - Returns: True if click was successful, false otherwise
    static func clickElement(_ element: XCUIElement, timeout: TimeInterval = 1.0) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        guard exists else {
            XCTFail("Element does not exist")
            return false
        }

        guard element.isHittable else {
            XCTFail("Element is not hittable")
            return false
        }

        element.click()
        return true
    }

    /// Simulates typing text into a text field
    /// - Parameters:
    ///   - element: The text field
    ///   - text: The text to type
    ///   - timeout: Maximum time to wait for text field to be available (default: 1.0 second)
    /// - Returns: True if typing was successful, false otherwise
    static func typeText(_ element: XCUIElement, text: String, timeout: TimeInterval = 1.0) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        guard exists else {
            XCTFail("Text field not found")
            return false
        }

        element.click()
        element.typeText(text)
        return true
    }

    /// Toggles a checkbox or switch
    /// - Parameter element: The checkbox or switch element
    /// - Returns: True if toggle was successful, false otherwise
    static func toggleElement(_ element: XCUIElement) -> Bool {
        guard element.exists else {
            XCTFail("Element to toggle not found")
            return false
        }

        // Get current state
        let currentValue = element.value as? String ?? "0"
        let newState = currentValue == "1" ? "0" : "1"

        element.click()

        // Wait for state to change
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", newState),
            object: element
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: 1.0)

        return result == .completed
    }

    /// Selects an item from a popup button
    /// - Parameters:
    ///   - popupButton: The popup button element
    ///   - itemTitle: The title of the item to select
    /// - Returns: True if selection was successful, false otherwise
    static func selectPopupButtonItem(_ popupButton: XCUIElement, itemTitle: String) -> Bool {
        guard popupButton.exists else {
            XCTFail("Popup button not found")
            return false
        }

        popupButton.click()

        let menuItem = popupButton.menuItems[itemTitle]
        let exists = menuItem.waitForExistence(timeout: 1.0)
        guard exists else {
            XCTFail("Menu item '\(itemTitle)' not found in popup button")
            return false
        }

        menuItem.click()
        return true
    }

    // MARK: - Wait Helpers

    /// Waits for a UI element to exist
    /// - Parameters:
    ///   - element: The element to wait for
    ///   - timeout: Maximum time to wait (default: 2.0 seconds)
    /// - Returns: True if element exists, false otherwise
    static func waitForElementToExist(_ element: XCUIElement, timeout: TimeInterval = 2.0) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// Waits for a UI element to disappear
    /// - Parameters:
    ///   - element: The element to wait for
    ///   - timeout: Maximum time to wait (default: 2.0 seconds)
    /// - Returns: True if element disappeared, false otherwise
    static func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 2.0) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: element
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Waits for a window to close
    /// - Parameters:
    ///   - title: The window title
    ///   - timeout: Maximum time to wait (default: 2.0 seconds)
    /// - Returns: True if window closed, false otherwise
    static func waitForWindowToClose(title: String, timeout: TimeInterval = 2.0) -> Bool {
        guard let window = findWindow(title: title, timeout: 0.5) else {
            // Window is already closed
            return true
        }

        return waitForElementToDisappear(window, timeout: timeout)
    }

    // MARK: - Assertion Helpers

    /// Asserts that a window exists
    /// - Parameters:
    ///   - title: The window title
    ///   - timeout: Maximum time to wait for window to appear (default: 2.0 seconds)
    ///   - file: The file where the assertion is made (auto-generated)
    ///   - line: The line where the assertion is made (auto-generated)
    static func assertWindowExists(
        title: String,
        timeout: TimeInterval = 2.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exists = findWindow(title: title, timeout: timeout) != nil
        XCTAssert(
            exists,
            "Window with title '\(title)' should exist",
            file: file,
            line: line
        )
    }

    /// Asserts that a window does not exist
    /// - Parameters:
    ///   - title: The window title
    ///   - file: The file where the assertion is made (auto-generated)
    ///   - line: The line where the assertion is made (auto-generated)
    static func assertWindowDoesNotExist(
        title: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let app = XCUIApplication()
        let window = app.windows[title]
        XCTAssert(
            !window.exists,
            "Window with title '\(title)' should not exist",
            file: file,
            line: line
        )
    }

    /// Asserts that a UI element is visible
    /// - Parameters:
    ///   - element: The element to check
    ///   - timeout: Maximum time to wait for element to become visible (default: 1.0 second)
    ///   - file: The file where the assertion is made (auto-generated)
    ///   - line: The line where the assertion is made (auto-generated)
    static func assertElementVisible(
        _ element: XCUIElement,
        timeout: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssert(
            exists,
            "Element should be visible",
            file: file,
            line: line
        )
    }

    /// Asserts that a UI element is enabled
    /// - Parameters:
    ///   - element: The element to check
    ///   - file: The file where the assertion is made (auto-generated)
    ///   - line: The line where the assertion is made (auto-generated)
    static func assertElementEnabled(
        _ element: XCUIElement,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssert(
            element.isEnabled,
            "Element should be enabled",
            file: file,
            line: line
        )
    }

    /// Asserts that a UI element is disabled
    /// - Parameters:
    ///   - element: The element to check
    ///   - file: The file where the assertion is made (auto-generated)
    ///   - line: The line where the assertion is made (auto-generated)
    static func assertElementDisabled(
        _ element: XCUIElement,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            element.isEnabled,
            "Element should be disabled",
            file: file,
            line: line
        )
    }

    // MARK: - Screenshot Helpers

    /// Takes a screenshot for debugging purposes
    /// - Parameter name: The name to give the screenshot
    /// - Returns: The XCUIScreenshot instance
    static func takeScreenshot(named name: String) -> XCUIScreenshot {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        _ = XCTContext.runActivity(named: "Screenshot: \(name)") { _ in
            XCTAttachment(screenshot: screenshot)
        }
        return screenshot
    }
}
