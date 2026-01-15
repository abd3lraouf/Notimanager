//
//  NotificationMoverCoordinator.swift
//  Notimanager
//
//  Refactored on 2025-01-15.
//  Pure coordinator - delegates all work to services and views.
//  Replaces the monolithic NotificationMover class.
//

import AppKit
import Foundation
import UserNotifications

/// Main coordinator for the Notimanager application.
/// Handles application lifecycle, service coordination, and UI delegation.
@available(macOS 10.15, *)
final class NotificationMoverCoordinator: NSObject {

    // MARK: - Dependencies (Injected)

    private let configurationManager: ConfigurationManager
    private let accessibilityManager: AccessibilityManager
    private let permissionService: AccessibilityPermissionService
    private let positioningService: NotificationPositioningService
    private let windowMonitor: WindowMonitorService
    private let widgetMonitor: WidgetMonitorService
    private let logger: LoggingService
    private let menuBarManager: MenuBarManager
    private let launchAgentManager: LaunchAgentManager

    // MARK: - UI Components

    private var permissionWindow: PermissionWindow?
    private var settingsWindow: SettingsWindow?

    // MARK: - Initialization

    init(
        configurationManager: ConfigurationManager = .shared,
        accessibilityManager: AccessibilityManager = .shared,
        permissionService: AccessibilityPermissionService = .shared,
        positioningService: NotificationPositioningService = .shared,
        windowMonitor: WindowMonitorService = .shared,
        widgetMonitor: WidgetMonitorService = .shared,
        logger: LoggingService = .shared,
        menuBarManager: MenuBarManager? = nil,
        launchAgentManager: LaunchAgentManager? = nil
    ) {
        self.configurationManager = configurationManager
        self.accessibilityManager = accessibilityManager
        self.permissionService = permissionService
        self.positioningService = positioningService
        self.windowMonitor = windowMonitor
        self.widgetMonitor = widgetMonitor
        self.logger = logger

        // Use provided managers or create new instances
        let menuBarMgr = menuBarManager ?? MenuBarManager()
        self.menuBarManager = menuBarMgr

        let launchAgentMgr = launchAgentManager ?? LaunchAgentManager()
        self.launchAgentManager = launchAgentMgr

        super.init()

        // Set up monitor delegates
        setupMonitorDelegates()

        // Set up configuration observers
        setupConfigurationObservers()

        // Set up menu bar manager coordinator reference (after super.init)
        menuBarMgr.setCoordinator(self)
    }

    // MARK: - Setup

    private func setupMonitorDelegates() {
        // Window and Widget monitors call back to coordinator
        // They use weak references to avoid retain cycles
    }

    private func setupConfigurationObservers() {
        configurationManager.addObserver(self)
    }

    // MARK: - Application Lifecycle

    /// Application finished launching - entry point
    func applicationDidFinishLaunching(_ notification: Notification) {
        logSystemInfo()
        requestNotificationPermissions()

        // Delay permission check slightly to allow system to register the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAccessibilityPermissions()
        }

        // Setup menu bar if not hidden
        if !configurationManager.isMenuBarIconHidden {
            menuBarManager.setup()
        }
    }

    /// Application is about to become active
    func applicationWillBecomeActive(_ notification: Notification) {
        // Re-check accessibility permissions when app becomes active
        if permissionWindow != nil && permissionWindow?.isVisible == true {
            let isGranted = permissionService.checkPermissions()
            if isGranted {
                logger.info("Permission detected as granted on app activation")
                permissionWindow?.updateStatus(granted: true)
            }
        }

        // Show menu bar if it was hidden
        if configurationManager.isMenuBarIconHidden {
            configurationManager.isMenuBarIconHidden = false
            menuBarManager.setup()
        }
    }

    /// Application is about to terminate
    func applicationWillTerminate(_ notification: Notification) {
        stopAllServices()
    }

    // MARK: - Permission Management

    private func checkAccessibilityPermissions() {
        let isGranted = permissionService.checkPermissions()

        logger.info("Accessibility permission check: \(isGranted ? "granted" : "denied")")

        if isGranted {
            startAllServices()
            moveAllNotifications()
        } else {
            showPermissionWindow()
        }
    }

    private func requestNotificationPermissions() {
        logger.info("Requesting notification permissions...")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if let error = error {
                self?.logger.error("Error requesting notification permissions: \(error)")
            } else {
                self?.logger.info("Notification permissions granted: \(granted)")
            }
        }
    }

    // MARK: - Service Coordination

    private func startAllServices() {
        logger.info("Starting all services...")

        // Start monitoring
        if configurationManager.isEnabled {
            windowMonitor.startMonitoring()
            widgetMonitor.startMonitoring()
        }

        logger.info("All services started")
    }

    private func stopAllServices() {
        logger.info("Stopping all services...")

        windowMonitor.stopMonitoring()
        widgetMonitor.stopMonitoring()

        logger.info("All services stopped")
    }

    // MARK: - UI Coordination

    private func showPermissionWindow() {
        permissionWindow = PermissionWindow(coordinator: self)
        permissionWindow?.show()
    }

    // MARK: - Notification Movement

    func moveAllNotifications() {
        guard configurationManager.isEnabled else {
            logger.debug("Notification positioning is disabled")
            return
        }

        logger.info("Moving all notifications to \(configurationManager.currentPosition.displayName)")

        // Delegate to window monitor (which handles the actual movement)
        windowMonitor.scanAllWindowsForNotifications()
    }

    func moveNotification(_ element: AXUIElement, size: CGSize) {
        guard configurationManager.isEnabled else { return }

        let newPosition = positioningService.calculatePosition(
            notifSize: size,
            padding: 20,
            currentPosition: configurationManager.currentPosition
        )

        positioningService.applyPosition(to: element, at: newPosition)
    }

    // MARK: - Configuration Changes

    func configurationDidChange(_ event: ConfigurationManager.ConfigurationEvent) {
        switch event {
        case .positionChanged:
            logger.info("Position changed to \(configurationManager.currentPosition.displayName)")
            moveAllNotifications()
            menuBarManager.rebuildMenu()

        case .enabledChanged:
            logger.info("Enabled changed to \(configurationManager.isEnabled)")
            if configurationManager.isEnabled {
                startAllServices()
            } else {
                stopAllServices()
            }
            menuBarManager.rebuildMenu()

        case .debugModeChanged:
            logger.info("Debug mode changed to \(configurationManager.debugMode)")
            // Logging service automatically updates via observer
            menuBarManager.rebuildMenu()

        case .menuBarIconChanged:
            logger.info("Menu bar icon visibility changed")
            if configurationManager.isMenuBarIconHidden {
                menuBarManager.teardown()
            } else {
                menuBarManager.setup()
            }

        case .reset:
            logger.info("Configuration reset to defaults")
            moveAllNotifications()
            menuBarManager.rebuildMenu()
        }
    }

    // MARK: - Launch Agent Management

    private func isLaunchAgentEnabled() -> Bool {
        return launchAgentManager.isEnabled
    }

    private func setLaunchAgentEnabled(_ enabled: Bool) {
        do {
            try launchAgentManager.setEnabled(enabled)
            logger.info("Launch at login: \(enabled ? "enabled" : "disabled")")
        } catch {
            logger.error("Failed to set launch agent: \(error)")
        }
    }

    // MARK: - Helpers

    private func sendTestNotificationInternal() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from Notimanager"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Error sending test notification: \(error)")
            } else {
                self?.logger.info("Test notification sent")
            }
        }
    }

    private func logSystemInfo() {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion

        logger.logSystemInfo(
            osVersion: osVersion,
            notificationSubroles: getNotificationSubroles(for: osVersion),
            currentPosition: configurationManager.currentPosition
        )
    }

    private func getNotificationSubroles(for osVersion: OperatingSystemVersion) -> [String] {
        if osVersion.majorVersion >= 26 {
            return [
                "AXNotificationCenterBanner",
                "AXNotificationCenterAlert",
                "AXNotification",
                "AXBanner",
                "AXAlert",
                "AXSystemDialog",
                "AXNotificationBanner",
                "AXNotificationAlert",
                "AXFloatingPanel",
                "AXPanel"
            ]
        } else if osVersion.majorVersion >= 15 {
            return [
                "AXNotificationCenterBanner",
                "AXNotificationCenterAlert",
                "AXNotification",
                "AXBanner",
                "AXAlert",
                "AXSystemDialog"
            ]
        } else {
            return ["AXNotificationCenterBanner", "AXNotificationCenterAlert"]
        }
    }
}

// MARK: - ConfigurationObserver

extension NotificationMoverCoordinator: ConfigurationManager.ConfigurationObserver {}

// MARK: - CoordinatorAction (Protocol for Views)

extension NotificationMoverCoordinator: CoordinatorAction {

    // MARK: - Permission Actions

    func requestAccessibilityPermission() {
        permissionService.requestPermissions(showPrompt: true)
    }

    func resetAccessibilityPermission() {
        do {
            try permissionService.resetPermissions()
            logger.info("Accessibility permission reset")
        } catch {
            logger.error("Failed to reset permissions: \(error)")
        }
    }

    func restartApp() {
        logger.info("Restarting application...")
        NSApp.terminate(nil)
    }

    // MARK: - Settings Actions

    func updatePosition(to position: NotificationPosition) {
        configurationManager.currentPosition = position
    }

    func showPermissionWindowFromSettings() {
        showPermissionWindow()
    }

    // MARK: - Menu Actions

    func showSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow(coordinator: self)
        }
        settingsWindow?.show()
    }

    func toggleEnabled() {
        configurationManager.isEnabled.toggle()
    }

    func toggleLaunchAtLogin() {
        let newState = !isLaunchAgentEnabled()
        setLaunchAgentEnabled(newState)
    }

    func sendTestNotification() {
        sendTestNotificationInternal()
    }

    func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Configuration Properties

    var currentPosition: NotificationPosition {
        return configurationManager.currentPosition
    }

    var isEnabled: Bool {
        get { return configurationManager.isEnabled }
        set { configurationManager.isEnabled = newValue }
    }

    var debugMode: Bool {
        get { return configurationManager.debugMode }
        set { configurationManager.debugMode = newValue }
    }

    var isMenuBarIconHidden: Bool {
        get { return configurationManager.isMenuBarIconHidden }
        set { configurationManager.isMenuBarIconHidden = newValue }
    }

    var launchAgentPlistPath: String {
        return configurationManager.launchAgentPlistPath
    }

    // MARK: - Support Links

    func openKofi() {
        NSWorkspace.shared.open(URL(string: "https://ko-fi.com/wadegrimridge")!)
    }

    func openBuyMeACoffee() {
        NSWorkspace.shared.open(URL(string: "https://www.buymeacoffee.com/wadegrimridge")!)
    }
}
