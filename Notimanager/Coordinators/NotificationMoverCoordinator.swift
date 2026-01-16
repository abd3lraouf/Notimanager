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
import Settings
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

    // MARK: - UI Components

    // Permission window is now managed by UICoordinator

    // MARK: - Settings Window Controller (Settings Framework)

    /// Returns the appropriate settings style based on macOS version
    private var settingsPaneStyle: Settings.Style {
        if #available(macOS 11.0, *) {
            return .toolbarItems
        } else {
            return .segmentedControl
        }
    }

    /// Lazy loaded settings window controller using the Settings framework
    private lazy var settingsWindowController: SettingsWindowController = {
        let generalPane = GeneralSettingsViewController()
        let positionPane = PositionSettingsViewController()
        let aboutPane = AboutSettingsViewController()

        let controller = SettingsWindowController(
            panes: [generalPane, positionPane, aboutPane],
            style: settingsPaneStyle,
            animated: true
        )
        controller.windowFrameAutosaveName = "NotimanagerSettingsV2"
        return controller
    }()

    // MARK: - Initialization

    init(
        configurationManager: ConfigurationManager = .shared,
        accessibilityManager: AccessibilityManager = .shared,
        permissionService: AccessibilityPermissionService = .shared,
        positioningService: NotificationPositioningService = .shared,
        windowMonitor: WindowMonitorService = .shared,
        widgetMonitor: WidgetMonitorService = .shared,
        logger: LoggingService = .shared,
        menuBarManager: MenuBarManager? = nil
    ) {
        self.configurationManager = configurationManager
        self.accessibilityManager = accessibilityManager
        self.permissionService = permissionService
        self.positioningService = positioningService
        self.windowMonitor = windowMonitor
        self.widgetMonitor = widgetMonitor
        self.logger = logger

        // Create menu bar manager
        let menuBarMgr = menuBarManager ?? MenuBarManager()
        self.menuBarManager = menuBarMgr

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
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self

        logSystemInfo()
        requestNotificationPermissions()

        // Delay permission check slightly to allow system to register the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAccessibilityPermissions()
        }

        // Setup menu bar - visibility is controlled by isVisible property
        menuBarManager.setup()

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
        // If the status item is currently hidden, open Settings but keep it hidden
        // This allows users to access the app when launching from Launchpad, Applications, or Xcode
        if !menuBarManager.isVisible {
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
            // Update the isVisible property which will handle showing/hiding
            menuBarManager.isVisible = !configurationManager.isMenuBarIconHidden

        case .reset:
            logger.info("Configuration reset to defaults")
            moveAllNotifications()
            menuBarManager.rebuildMenu()
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
        NSApp.terminate(nil)
    }

    // MARK: - Settings Actions

    func updatePosition(to position: NotificationPosition) {
        configurationManager.currentPosition = position
    }

    func showPermissionWindowFromSettings() {
        UICoordinator.shared.showPermissionWindow()
    }

    func showDiagnostics() {
        UICoordinator.shared.showDiagnostics()
    }

    // MARK: - Menu Actions

    func showSettings() {
        settingsWindowController.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    func toggleEnabled() {
        configurationManager.isEnabled.toggle()
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

    // MARK: - Support Links

    func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/abd3lraouf/Notimanager")!)
    }

    func openIssues() {
        NSWorkspace.shared.open(URL(string: "https://github.com/abd3lraouf/Notimanager/issues")!)
    }
}
