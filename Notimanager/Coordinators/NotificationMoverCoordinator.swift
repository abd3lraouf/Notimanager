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

    // MARK: - UI Components

    // Permission window is now managed by UICoordinator

    // MARK: - Initialization

    init(
        configurationManager: ConfigurationManager = .shared,
        accessibilityManager: AccessibilityManager = .shared,
        permissionService: AccessibilityPermissionService = .shared,
        positioningService: NotificationPositioningService = .shared,
        windowMonitor: WindowMonitorService = .shared,
        widgetMonitor: WidgetMonitorService = .shared,
        logger: LoggingService = .shared
    ) {
        self.configurationManager = configurationManager
        self.accessibilityManager = accessibilityManager
        self.permissionService = permissionService
        self.positioningService = positioningService
        self.windowMonitor = windowMonitor
        self.widgetMonitor = widgetMonitor
        self.logger = logger

        super.init()

        // Set up monitor delegates
        setupMonitorDelegates()

        // Set up configuration observers
        setupConfigurationObservers()
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
        logger.debug("ApplicationDidFinishLaunching called", category: "Coordinator")

        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Initialize MenuBarManager first (sets up NSStatusItem based on saved preference)


        logSystemInfo()
        requestNotificationPermissions()

        // Index content for Spotlight (2026 feature)
        if #available(macOS 10.15, *) {
            SpotlightIndexer.shared.indexAllContent()
        }

        // Delay permission check slightly to allow system to register the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAccessibilityPermissions()
        }

        // Observe app activation to restore menu bar icon when hidden
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive(_:)),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    /// Application is about to become active
    /// When launched from Launchpad/Applications while icon is hidden, open Settings but keep icon hidden
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        // If the status icon is currently hidden, open Settings but keep it hidden
        // This allows users to access the app when launching from Launchpad, Applications, or Xcode
        if configurationManager.isMenuBarIconHidden && configurationManager.openSettingsAtLaunch {
            logger.info("Status icon hidden on app activation - opening Settings")

            // Open Settings window so user can access the app
            showSettings()
        }
    }

    /// Application is about to terminate
    func applicationWillTerminate(_ notification: Notification) {
        stopAllServices()
    }

    deinit {
        stopAllServices()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Permission Management

    private func checkAccessibilityPermissions() {
        logger.debug("Checking accessibility permissions...", category: "Coordinator")
        let isGranted = permissionService.checkPermissions()

        // Check for stale permission state (app in settings but not trusted due to signature change)
        let isStale = permissionService.isPermissionStateStale()

        if isStale {
            logger.warning("Detected stale accessibility permission state (code signature may have changed)", category: "Coordinator")
            // Store this state for the UI to display appropriate message
            UserDefaults.standard.set(true, forKey: "accessibilityPermissionIsStale")
        } else {
            UserDefaults.standard.set(false, forKey: "accessibilityPermissionIsStale")
        }

        logger.info("Accessibility permission check: \(isGranted ? "granted" : "denied")\(isStale ? " (stale state detected)" : "")", category: "Coordinator")

        if isGranted {
            logger.debug("Permissions granted, starting services", category: "Coordinator")
            startAllServices()
            moveAllNotifications()
        } else {
            logger.debug("Permissions denied, showing permission window", category: "Coordinator")
            showPermissionWindow()
        }
    }

    private func requestNotificationPermissions() {
        logger.debug("Requesting notification permissions...", category: "Coordinator")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if let error = error {
                self?.logger.error("Error requesting notification permissions: \(error)", category: "Coordinator")
            } else {
                self?.logger.info("Notification permissions granted: \(granted)", category: "Coordinator")
            }
        }
    }

    // MARK: - Service Coordination

    private func startAllServices() {
        logger.info("Starting all services...", category: "Coordinator")
        logger.debug("isEnabled: \(configurationManager.isEnabled)", category: "Coordinator")

        // Start monitoring
        if configurationManager.isEnabled {
            windowMonitor.startMonitoring()
            widgetMonitor.startMonitoring()
            logger.debug("Window and Widget monitors started", category: "Coordinator")
        } else {
            logger.debug("Not starting monitors - positioning is disabled", category: "Coordinator")
        }

        logger.info("All services started", category: "Coordinator")
    }

    private func stopAllServices() {
        logger.info("Stopping all services...", category: "Coordinator")

        windowMonitor.stopMonitoring()
        widgetMonitor.stopMonitoring()

        logger.info("All services stopped", category: "Coordinator")
    }

    // MARK: - UI Coordination

    private func showPermissionWindow() {
        UICoordinator.shared.showPermissionWindowFromCoordinator()
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

        let newPosition = positioningService.calculatePositionWithAutoPadding(
            notifSize: size,
            currentPosition: configurationManager.currentPosition
        )

        _ = positioningService.applyPosition(to: element, at: newPosition)
    }

    // MARK: - Configuration Changes

    func configurationDidChange(_ event: ConfigurationManager.ConfigurationEvent) {
        switch event {
        case .positionChanged:
            logger.info("Position changed to \(configurationManager.currentPosition.displayName)")
            moveAllNotifications()

        case .enabledChanged:
            logger.info("Enabled changed to \(configurationManager.isEnabled)")
            if configurationManager.isEnabled {
                startAllServices()
            } else {
                stopAllServices()
            }

        case .debugModeChanged:
            logger.info("Debug mode changed to \(configurationManager.debugMode)")
            // Logging service automatically updates via observer

        case .menuBarIconChanged:
            logger.info("Menu bar icon visibility changed")

        case .interceptionChanged:
            logger.info("Interception settings changed")
            // Update monitoring based on new interception settings
            // Only start monitors if master switch is enabled AND the specific interception flag is enabled
            
            // Handle window monitoring (normal notifications)
            if configurationManager.isEnabled && configurationManager.interceptNotifications {
                windowMonitor.startMonitoring()
            } else {
                windowMonitor.stopMonitoring()
            }

            // Handle widget monitoring
            if configurationManager.isEnabled && configurationManager.interceptWidgets {
                widgetMonitor.startMonitoring()
            } else {
                widgetMonitor.stopMonitoring()
            }

            logger.info("Window monitoring: \(configurationManager.interceptNotifications ? "active" : "inactive"), Widget monitoring: \(configurationManager.interceptWidgets ? "active" : "inactive")")

        case .reset:
            logger.info("Configuration reset to defaults")
            moveAllNotifications()
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

    private func sendDelayedTestNotification() {
        // Delay for 1 second to allow any visible notification to dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.sendPositionTestNotification()
        }
    }

    private func sendPositionTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Position Changed"
        let positionName = configurationManager.currentPosition.displayName
        content.body = "Notifications will now appear at the \(positionName)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "position-test-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Error sending position test notification: \(error)")
            } else {
                self?.logger.info("Position test notification sent to \(positionName)")
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
                "AXPanel",
                "AXNotificationCenterNotification",
                "AXNotificationCenterBannerWindow"
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

// MARK: - UNUserNotificationCenterDelegate

extension NotificationMoverCoordinator: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow banner and sound when app is in foreground
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}

// MARK: - ConfigurationObserver

extension NotificationMoverCoordinator: ConfigurationManager.ConfigurationObserver {}

// MARK: - CoordinatorAction (Protocol for Views)

extension NotificationMoverCoordinator: CoordinatorAction {

    // MARK: - Permission Actions

    func requestAccessibilityPermission() {
        _ = permissionService.requestPermissions(showPrompt: true)
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

        // Use the industry-standard AppRestart utility
        AppRestart.restart(delay: 0.5)
    }

    // MARK: - Settings Actions

    func updatePosition(to position: NotificationPosition) {
        configurationManager.currentPosition = position
        // Donate activity for Siri Suggestions
        ActivityManager.shared.donateChangePositionActivity(to: position)
    }

    func showPermissionWindowFromSettings() {
        UICoordinator.shared.showPermissionWindow()
    }

    func showDiagnostics() {
        UICoordinator.shared.showDiagnostics()
    }

    // MARK: - Menu Actions

    func showSettings() {
        // Use native Settings/Preferences window mechanism
        if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        
        // Donate activity for Siri Suggestions
        if #available(macOS 10.15, *) {
            ActivityManager.shared.donateSettingsActivity()
        }
    }

    func toggleEnabled() {
        configurationManager.isEnabled.toggle()
        // Donate activity for Siri Suggestions
        if #available(macOS 10.15, *) {
            ActivityManager.shared.donateTogglePositioningActivity(isEnabled: configurationManager.isEnabled)
        }
    }

    func sendTestNotification() {
        sendTestNotificationInternal()
        // Donate activity for Siri Suggestions
        if #available(macOS 10.15, *) {
            ActivityManager.shared.donateSendTestNotificationActivity()
        }
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

    // MARK: - Support Links

    func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/abd3lraouf/Notimanager")!)
    }

    func openIssues() {
        NSWorkspace.shared.open(URL(string: "https://github.com/abd3lraouf/Notimanager/issues")!)
    }
}
