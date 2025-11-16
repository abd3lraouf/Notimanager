//
//  WidgetMonitorService.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Monitors Notification Center widget panel visibility.
//  Extracted from NotificationMover to separate widget monitoring logic.
//

import AppKit
import Foundation

/// Monitors Notification Center widget panel visibility
@available(macOS 10.15, *)
class WidgetMonitorService {

    // MARK: - Singleton

    static let shared = WidgetMonitorService()

    private init() {}

    // MARK: - Properties

    private var widgetMonitorTimer: Timer?
    private var lastWidgetWindowCount: Int = 0
    private var pollingEndTime: Date?

    // MARK: - Constants

    private let notificationCenterBundleID = "com.apple.notificationcenterui"
    private let widgetIdentifierPrefix: String = "widget-local:"

    // MARK: - Dependencies

    private weak var notificationMover: NotificationMover?

    // MARK: - Configuration

    private let checkInterval: TimeInterval = 0.5
    private let defaultPollingDuration: TimeInterval = 6.5

    // MARK: - Lifecycle

    /// Sets the NotificationMover reference for callbacks
    /// - Parameter mover: The NotificationMover instance
    func setNotificationMover(_ mover: NotificationMover?) {
        notificationMover = mover
    }

    /// Starts monitoring widget panel visibility
    /// - Parameter pollingDuration: How long to poll (default 6.5s)
    func startMonitoring(pollingDuration: TimeInterval? = nil) {
        let duration = pollingDuration ?? defaultPollingDuration
        pollingEndTime = Date().addingTimeInterval(duration)

        widgetMonitorTimer = Timer.scheduledTimer(
            withTimeInterval: checkInterval,
            repeats: true,
            block: { [weak self] _ in
                self?.checkForWidgetChanges()
            }
        )

        print("🔍 Widget monitoring started for \(duration)s")
    }

    /// Stops monitoring
    func stopMonitoring() {
        widgetMonitorTimer?.invalidate()
        widgetMonitorTimer = nil
        pollingEndTime = nil
        lastWidgetWindowCount = 0

        print("🛑 Widget monitoring stopped")
    }

    /// Checks if Notification Center UI is visible
    /// - Returns: True if Notification Center UI is visible
    func hasNotificationCenterUI() -> Bool {
        guard let pid = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else {
            return false
        }

        let app = AXUIElementCreateApplication(pid)
        return findElementWithWidgetIdentifier(root: app) != nil
    }

    /// Finds widget panel by identifier prefix
    /// - Parameter root: The root element to search from
    /// - Returns: The found widget panel, or nil
    private func findElementWithWidgetIdentifier(root: AXUIElement) -> AXUIElement? {

        if let identifier = AXElementManager.shared.getWindowIdentifier(root),
           identifier.hasPrefix(widgetIdentifierPrefix) {

            // Verify this is an actual widget panel (significant size)
            if let size = AXElementManager.shared.getSize(of: root),
               size.width >= 150 && size.height >= 150 {

                let hasLoggedEmptyWidget = false

                let notificationCount = UserDefaults.standard.integer(forKey: "notificationCount")
                UserDefaults.standard.set(notificationCount + 1, forKey: "notificationCount")

                print("✓ Found actual Notification Center widget panel: \\(identifier), size: \\(size)")

                return root
            } else {
                if !UserDefaults.standard.bool(forKey: "hasLoggedEmptyWidget") {
                    print("Ignoring empty widget container: \\(identifier), size too small or unavailable")

                    UserDefaults.standard.set(true, forKey: "hasLoggedEmptyWidget")
                }

                return nil
            }
        }

        // Search children
        var childrenRef: AnyObject?

        guard AXUIElementCopyAttributeValue(
            root,
            kAXChildrenAttribute as CFString,
            &childrenRef
        ) == .success,
        let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            if let found = findElementWithWidgetIdentifier(root: child) {
                return found
            }
        }

        return nil
    }

    /// Checks for widget state changes
    private func checkForWidgetChanges() {
        guard let pollingEnd = pollingEndTime, Date() < pollingEnd else {
            // Stop polling when time expires
            stopMonitoring()
            return
        }

        let hasNCUI = hasNotificationCenterUI()
        let currentNCState = hasNCUI ? 1 : 0

        if lastWidgetWindowCount != currentNCState {
            print("Notification Center state changed (\\(lastWidgetWindowCount) → \\(currentNCState)) - triggering move")

            if !hasNCUI {
                notificationMover?.moveAllNotifications()
            }
        }

        lastWidgetWindowCount = currentNCState
    }

    /// Gets the current widget state count
    /// - Returns: 1 if NC UI is visible, 0 if hidden
    func getWidgetState() -> Int {
        return hasNotificationCenterUI() ? 1 : 0
    }

    /// Gets whether a widget panel is currently visible
    /// - Returns: True if widget panel exists and has significant size
    func isWidgetPanelVisible() -> Bool {
        let notificationApps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == notificationCenterBundleID
        }

        guard let pid = notificationApps.first?.processIdentifier else {
            return false
        }

        let app = AXUIElementCreateApplication(pid)
        guard let widgetElement = findElementWithWidgetIdentifier(root: app) else {
            return false
        }

        if let size = AXElementManager.shared.getSize(of: widgetElement),
           size.width >= 150 && size.height >= 150 {
            return true
        }

        return false
    }
}
