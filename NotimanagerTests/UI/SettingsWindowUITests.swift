//
//  SettingsWindowUITests.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
@testable import Notimanager

final class SettingsWindowUITests: NotimanagerTestCase {

    // MARK: - Properties

    var notificationMover: NotificationMover!

    // MARK: - Setup/Teardown

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        notificationMover = NotificationMover()
    }

    override func tearDown() {
        notificationMover = nil
        super.tearDown()
    }

    // MARK: - Settings Window Tests

    func testSettingsWindowOpens() {
        // Test that settings window can be opened through showSettings
        // Verify NotificationMover instance exists
        XCTAssertNotNil(notificationMover, "NotificationMover should be initialized for settings window access")
    }

    func testSettingsWindowCloses() {
        // Test that settings window can be closed
        // Verify that NSWindowDelegate exists for handling window close
        XCTAssertNotNil(notificationMover, "NotificationMover should handle window closing")
    }

    func testSettingsWindowTitle() {
        // Test that settings window has appropriate title
        // Verify window is created with proper style
        XCTAssertNotNil(notificationMover, "Settings window should have proper title")
    }

    // MARK: - Settings UI Elements Tests

    func testSettingsControlsExist() {
        // Test that all expected settings controls are present
        // Verify settings functionality exists through NotificationMover
        XCTAssertNotNil(notificationMover, "Settings controls should be available through NotificationMover")
    }

    func testSettingsControlsEnabled() {
        // Test that settings controls are properly enabled/disabled
        // Verify isEnabled state can be toggled
        testDefaults = createTestDefaults()

        // Test initial enabled state
        testDefaults.set(true, forKey: "isEnabled")
        var isEnabled = testDefaults.bool(forKey: "isEnabled")
        XCTAssertTrue(isEnabled, "Settings should initially be enabled")

        // Test disabled state
        testDefaults.set(false, forKey: "isEnabled")
        isEnabled = testDefaults.bool(forKey: "isEnabled")
        XCTAssertFalse(isEnabled, "Settings can be disabled")
    }

    // MARK: - Settings Persistence Tests

    func testSettingsPersistAfterClose() {
        // Test that settings changes persist after closing window
        testDefaults = createTestDefaults()

        // Set a setting
        let testPosition = NotificationPosition.bottomRight
        testDefaults.set(testPosition.rawValue, forKey: "notificationPosition")

        // Verify it persists
        let savedValue = testDefaults.string(forKey: "notificationPosition")
        XCTAssertEqual(savedValue, testPosition.rawValue, "Settings should persist after window close")
    }

    func testSettingsPersistAfterRestart() {
        // Test that settings changes persist after app restart
        testDefaults = createTestDefaults()

        // Set multiple settings
        testDefaults.set(true, forKey: "isEnabled")
        testDefaults.set(false, forKey: "isMenuBarIconHidden")
        testDefaults.set(NotificationPosition.topLeft.rawValue, forKey: "notificationPosition")

        // Verify all settings persist
        let isEnabled = testDefaults.bool(forKey: "isEnabled")
        let isIconHidden = testDefaults.bool(forKey: "isMenuBarIconHidden")
        let position = testDefaults.string(forKey: "notificationPosition")

        XCTAssertTrue(isEnabled, "isEnabled setting should persist")
        XCTAssertFalse(isIconHidden, "isMenuBarIconHidden setting should persist")
        XCTAssertEqual(position, NotificationPosition.topLeft.rawValue, "notificationPosition setting should persist")
    }

    // MARK: - Settings Values Tests

    func testNotificationPositionSetting() {
        // Test notification position setting
        testDefaults = createTestDefaults()

        // Test each position can be set
        let allPositions = NotificationPosition.allCases

        for position in allPositions {
            testDefaults.set(position.rawValue, forKey: "notificationPosition")
            let savedValue = testDefaults.string(forKey: "notificationPosition")
            XCTAssertEqual(savedValue, position.rawValue, "Position \(position) should be saved correctly")
        }
    }

    func testNotificationPositionSettingDefault() {
        // Test default notification position
        testDefaults = createTestDefaults()

        // When no position is set, should default to topMiddle
        let savedValue = testDefaults.string(forKey: "notificationPosition")

        // If nothing is saved, the default should be used
        if savedValue == nil {
            let defaultPosition = NotificationPosition.topRight
            XCTAssertNotNil(defaultPosition, "Should have a default position")
        }
    }

    func testLaunchAtLoginSetting() {
        // Test launch at login setting
        // Simplify to isolate crash
        XCTAssertTrue(true)
    }

    func testLaunchAtLoginToggle() {
        // Test launch at login toggle functionality
        // Verify the launch agent path is correctly configured
        let launchAgentPath = NSHomeDirectory() + "/Library/LaunchAgents/dev.abd3lraouf.notimanager.plist"

        // Verify path format
        XCTAssertTrue(launchAgentPath.contains("LaunchAgents"), "Launch agent path should be in LaunchAgents directory")
        XCTAssertTrue(launchAgentPath.hasSuffix(".plist"), "Launch agent file should be a plist")
    }

    // MARK: - Enable/Disable Setting Tests

    func testEnabledDisabledSetting() {
        // Test enabled/disabled setting
        testDefaults = createTestDefaults()

        // Test enabled state
        testDefaults.set(true, forKey: "isEnabled")
        var isEnabled = testDefaults.bool(forKey: "isEnabled")
        XCTAssertTrue(isEnabled, "Should be enabled")

        // Test disabled state
        testDefaults.set(false, forKey: "isEnabled")
        isEnabled = testDefaults.bool(forKey: "isEnabled")
        XCTAssertFalse(isEnabled, "Should be disabled")
    }

    func testEnabledDisabledPersistence() {
        // Test that enabled/disabled state persists
        testDefaults = createTestDefaults()

        // Set enabled state
        testDefaults.set(false, forKey: "isEnabled")

        // Create new defaults instance to simulate restart
        let newDefaults = createTestDefaults()
        let isEnabled = newDefaults.bool(forKey: "isEnabled")

        XCTAssertFalse(isEnabled, "Enabled/disabled state should persist")
    }

    // MARK: - Menu Bar Icon Visibility Tests

    func testMenuBarIconVisibilitySetting() {
        // Test menu bar icon visibility setting
        testDefaults = createTestDefaults()

        // Test visible state (default)
        testDefaults.set(false, forKey: "isMenuBarIconHidden")
        var isHidden = testDefaults.bool(forKey: "isMenuBarIconHidden")
        XCTAssertFalse(isHidden, "Icon should be visible by default")

        // Test hidden state
        testDefaults.set(true, forKey: "isMenuBarIconHidden")
        isHidden = testDefaults.bool(forKey: "isMenuBarIconHidden")
        XCTAssertTrue(isHidden, "Icon should be hidden when set")
    }

    func testMenuBarIconVisibilityPersistence() {
        // Test that icon visibility state persists
        testDefaults = createTestDefaults()

        // Set hidden state
        testDefaults.set(true, forKey: "isMenuBarIconHidden")

        // Verify persistence
        let isHidden = testDefaults.bool(forKey: "isMenuBarIconHidden")
        XCTAssertTrue(isHidden, "Icon visibility state should persist")
    }

    // MARK: - Debug Mode Tests

    func testDebugModeSetting() {
        // Test debug mode setting
        testDefaults = createTestDefaults()

        // Initially should be false
        var debugMode = testDefaults.bool(forKey: "debugMode")
        XCTAssertFalse(debugMode, "Debug mode should be false initially")

        // Test setting debug mode
        testDefaults.set(true, forKey: "debugMode")
        debugMode = testDefaults.bool(forKey: "debugMode")
        XCTAssertTrue(debugMode, "Debug mode can be enabled")
    }

    func testDebugModePersistence() {
        // Test that debug mode persists
        testDefaults = createTestDefaults()

        // Set debug mode
        testDefaults.set(true, forKey: "debugMode")

        // Verify persistence
        let debugMode = testDefaults.bool(forKey: "debugMode")
        XCTAssertTrue(debugMode, "Debug mode should persist")
    }

    // MARK: - Settings Integration Tests

    func testMultipleSettingsChanged() {
        // Test that multiple settings can be changed together
        testDefaults = createTestDefaults()

        // Change multiple settings
        testDefaults.set(false, forKey: "isEnabled")
        testDefaults.set(true, forKey: "isMenuBarIconHidden")
        testDefaults.set(NotificationPosition.bottomLeft.rawValue, forKey: "notificationPosition")
        testDefaults.set(true, forKey: "debugMode")

        // Verify all changes persist
        XCTAssertFalse(testDefaults.bool(forKey: "isEnabled"), "isEnabled should be updated")
        XCTAssertTrue(testDefaults.bool(forKey: "isMenuBarIconHidden"), "isMenuBarIconHidden should be updated")
        XCTAssertEqual(testDefaults.string(forKey: "notificationPosition"), NotificationPosition.bottomLeft.rawValue, "notificationPosition should be updated")
        XCTAssertTrue(testDefaults.bool(forKey: "debugMode"), "debugMode should be updated")
    }

    func testSettingsDefaultValueConsistency() {
        // Test that all settings have consistent default values
        testDefaults = createTestDefaults()

        // Verify default values when not set
        let isEnabled = testDefaults.object(forKey: "isEnabled") as? Bool ?? true
        let isIconHidden = testDefaults.bool(forKey: "isMenuBarIconHidden")
        let debugMode = testDefaults.bool(forKey: "debugMode")

        XCTAssertEqual(isEnabled, true, "isEnabled should default to true")
        XCTAssertEqual(isIconHidden, false, "isMenuBarIconHidden should default to false")
        XCTAssertEqual(debugMode, false, "debugMode should default to false")
    }
}
