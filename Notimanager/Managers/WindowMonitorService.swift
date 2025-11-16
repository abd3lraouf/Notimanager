//
//  WindowMonitorService.swift
//  Notimanager
//
//  Created on 2025-2025-01-15.
//  Global window monitoring service extracted from NotificationMover.
//  Monitors all applications for notification windows.
//

import AppKit
import Foundation

/// Monitors for notification windows across all applications
@available(macOS 10.15, *)
class WindowMonitorService {

    // MARK: - Singleton

    static let shared = WindowMonitorService()

    private init() {}

    // MARK: - Properties

    private var globalWindowMonitorTimer: Timer?
    private var knownWindowNumbers: Set<Int> = []
    private var appObservers: [pid_t: AXObserver] = [:]

    // MARK: - Dependencies

    private let notificationCenterBundleID = "com.apple.notificationcenterui"
    private let widgetIdentifierPrefix: String = "widget-local:"
    private let osVersion = ProcessInfo.processInfo.operatingSystemVersion

    // MARK: - Weak Reference

    private weak var notificationMover: NotificationMover?

    // MARK: - Configuration

    private let checkInterval: TimeInterval = 0.2 // Check every 200ms
    private let notificationSizeMin = CGSize(width: 200, height: 60)
    private let notificationSizeMax = CGSize(width: 800, height: 200)

    // MARK: - Lifecycle

    /// Sets the NotificationMover reference for callbacks
    /// - Parameter mover: The NotificationMover instance
    func setNotificationMover(_ mover: NotificationMover?) {
        notificationMover = mover
    }

    /// Starts monitoring all windows for new notifications
    func startMonitoring() {
        buildKnownWindowSet()

        globalWindowMonitorTimer = Timer.scheduledTimer(
            withTimeInterval: checkInterval,
            repeats: true,
            block: { [weak self] _ in
                self?.detectNewNotificationWindows()
            }
        )
    }

    /// Stops monitoring
    func stopMonitoring() {
        globalWindowMonitorTimer?.invalidate()
        globalWindowMonitorTimer = nil

        // Clean up all app observers
        appObservers.values.forEach { observer in
            CFRunLoopRemoveSource(
                RunLoop.current.getCFRunLoop(),
                AXObserverGetRunLoopSource(observer),
                .commonModes
            )
        }
        appObservers.removeAll()
        knownWindowNumbers.removeAll()
    }

    /// Gets the current set of tracked windows
    /// - Returns: Set of known window numbers
    func getKnownWindowNumbers() -> Set<Int> {
        return knownWindowNumbers
    }

    // MARK: - Window Detection

    /// Builds initial set of known windows
    private func buildKnownWindowSet() {
        let options = CGWindowListOption([.optionOnScreenOnly, .excludeDesktopElements])

        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return
        }

        for window in windowList {
            if let windowNumber = window[kCGWindowNumber as String] as? Int {
                knownWindowNumbers.insert(windowNumber)
            }
        }

        print("🔍 Initial window set: \(knownWindowNumbers.count) windows tracked")
    }

    /// Detects new notification windows
    private func detectNewNotificationWindows() {
        let options = CGWindowListOption([.optionOnScreenOnly, .excludeDesktopElements])

        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return
        }

        for window in windowList {
            guard let windowNumber = window[kCGWindowNumber as String] as? Int,
                  !knownWindowNumbers.contains(windowNumber),
                  let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = bounds["Width"],
                  let height = bounds["Height"],
                  let x = bounds["X"],
                  let y = bounds["Y"],
                  let ownerPID = window[kCGWindowOwnerPID as String] as? Int else {
                continue
            }

            // Check if this is a notification-sized window
            if width >= notificationSizeMin.width && width <= notificationSizeMax.width &&
               height >= notificationSizeMin.height && height <= notificationSizeMax.height {

                let ownerName = window[kCGWindowOwnerName as String] as? String ?? "Unknown"
                let layer = window[kCGWindowLayer as String] as? Int ?? 0

                print("🆕 NEW notification window detected!")
                print("   App: \(ownerName) [PID: \(ownerPID)]")
                print("   Size: \(Int(width))×\(Int(height)) at (\(Int(x)), \(Int(y)))")
                print("   Window#: \(windowNumber), Layer: \(layer)")

                // Add to known windows
                knownWindowNumbers.insert(windowNumber)

                // Try to move it
                moveExternalNotificationWindow(
                    windowNumber: windowNumber,
                    currentX: x,
                    currentY: y,
                    width: width,
                    height: height,
                    processID: pid_t(ownerPID)
                )
            } else {
                // Not a notification, but track it anyway
                knownWindowNumbers.insert(windowNumber)
            }
        }
    }

    /// Moves an external application's notification window
    /// - Parameters:
    ///   - windowNumber: The CGWindowNumber of the window to move
    ///   - currentX: Current X position
    ///   - currentY: Current Y position
    ///   - width: Window width
    ///   - height: Window height
    ///   - processID: Process ID of the window owner
    private func moveExternalNotificationWindow(
        windowNumber: Int,
        currentX: CGFloat,
        currentY: CGFloat,
        width: CGFloat,
        height: CGFloat,
        processID: pid_t
    ) {

        // Get current position from config
        let config = ConfigurationManager.shared
        let configPosition = config.currentPosition

        guard configPosition != .topRight else {
            print("   Position is Top Right (default) - not moving")
            return
        }

        guard let mover = notificationMover else {
            print("   ⚠️ No notification mover instance available")
            return
        }

        // Calculate new position
        let newPosition = NotificationPositioningService.shared.calculatePosition(
            notifSize: CGSize(width: width, height: height),
            padding: 20,
            currentPosition: configPosition,
            screenBounds: NSScreen.main!.frame
        )

        print("   Attempting to move external notification to \(configPosition.displayName)")
        print("   Target position: (\(Int(newPosition.x)), \(Int(newPosition.y)))")

        // Try to get AX element for this window
        if let axElement = getAXElementForWindow(
            windowNumber: windowNumber,
            processID: processID,
            position: CGPoint(x: currentX, y: currentY),
            size: CGSize(width: width, height: height)
        ) {
            // Use AXElementManager to set position
            let success = AXElementManager.shared.setPosition(
                of: axElement,
                x: newPosition.x,
                y: newPosition.y
            )

            if success {
                print("   ✅ Successfully moved external notification!")
            } else {
                print("   ⚠️ Position set failed")
            }
        } else {
            print("   ❌ Could not get AX element for window #\(windowNumber)")
        }
    }

    /// Gets the AXUIElement for a specific window
    /// - Parameters:
    ///   - windowNumber: The CGWindowNumber
    ///   - processID: Process ID
    ///   - position: Current position (for matching)
    ///   - size: Current size (for matching)
    /// - Returns: The AXUIElement, if found
    func getAXElementForWindow(
        windowNumber: Int,
        processID: pid_t,
        position: CGPoint,
        size: CGSize
    ) -> AXUIElement? {

        // Get all windows across all apps and find the one matching this window number
        for app in NSWorkspace.shared.runningApplications {
            guard let pid = app.processIdentifier as pid_t? else { continue }

            let appElement = AXUIElementCreateApplication(pid)
            var windowsRef: AnyObject?

            guard AXUIElementCopyAttributeValue(
                appElement,
                kAXWindowsAttribute as CFString,
                &windowsRef
            ) == .success,
            let windows = windowsRef as? [AXUIElement] else {
                continue
            }

            for window in windows {
                // Try to match by position and size
                if let pos = AXElementManager.shared.getPosition(of: window),
                   let windowSize = AXElementManager.shared.getSize(of: window) {

                    // Get this window's info from CGWindow
                    let options = CGWindowListOption([
                        .optionOnScreenOnly,
                        .excludeDesktopElements
                    ])

                    guard let cgWindowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
                        continue
                    }

                    // Find the window with matching window number
                    guard let cgWindow = cgWindowList.first(where: {
                        ($0[kCGWindowNumber as String] as? Int) == windowNumber
                    }) else {
                        continue
                    }

                    guard let bounds = cgWindow[kCGWindowBounds as String] as? [String: CGFloat],
                          let x = bounds["X"],
                          let y = bounds["Y"],
                          let w = bounds["Width"],
                          let h = bounds["Height"] else {
                        continue
                    }

                    // Match by position and size with some tolerance
                    let tolerance: CGFloat = 5
                    let posMatch = abs(pos.x - x) < tolerance && abs(pos.y - y) < tolerance
                    let sizeMatch = abs(windowSize.width - w) < tolerance && abs(windowSize.height - h) < tolerance

                    if posMatch && sizeMatch {
                        return window
                    }
                }
            }
        }

        return nil
    }

    /// Scans all windows for notifications
    func scanAllWindowsForNotifications() {
        let options = CGWindowListOption([.optionOnScreenOnly, .excludeDesktopElements])

        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return
        }

        for window in windowList {
            guard let windowLayer = window[kCGWindowLayer as String] as? Int,
                  windowLayer == 0 || windowLayer == 25,
                  let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = bounds["Width"],
                  let height = bounds["Height"],
                  let x = bounds["X"],
                  let y = bounds["Y"],
                  let ownerPID = window[kCGWindowOwnerPID as String] as? Int else {
                continue
            }

            // Look for notification-sized windows
            if width >= notificationSizeMin.width && width <= notificationSizeMax.width &&
               height >= notificationSizeMin.height && height <= notificationSizeMax.height {

                let ownerName = window[kCGWindowOwnerName as String] as? String ?? "Unknown"
                let windowName = window[kCGWindowName as String] as? String ?? ""

                print("🔍 Found potential notification window: \(ownerName) [\(ownerPID)] - \(windowName) - Size: \(Int(width))×\(Int(height)) at (\(Int(x)), \(Int(y)))")
            }
        }
    }
}
