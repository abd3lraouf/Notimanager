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
    private var stabilizationTimer: Timer?
    private var knownWindowNumbers: Set<Int> = []
    private var appObservers: [pid_t: AXObserver] = [:]
    
    /// Tracks windows that are currently being stabilized (fighting animation)
    /// Key: AXUIElement (wrapped), Value: Start time of stabilization
    private var stabilizingWindows: [AXUIElementWrapper: Date] = [:]
    private let stabilizationDuration: TimeInterval = 2.0 // Stabilize for 2 seconds (longer for smoother experience)

    // MARK: - Dependencies

    private let notificationCenterBundleID = "com.apple.notificationcenterui"
    private let widgetIdentifierPrefix: String = "widget-local:"
    private let osVersion = ProcessInfo.processInfo.operatingSystemVersion

    // MARK: - Weak Reference

    private weak var notificationMover: NotificationMover?

    // MARK: - Configuration

    private let checkInterval: TimeInterval = 0.016 // Check every ~16ms (~60fps) for ultra-fast detection
    private let stabilizationInterval: TimeInterval = 0.016 // Re-adjust every ~16ms for smooth stabilization
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
        setupNotificationCenterObserver()

        globalWindowMonitorTimer = Timer.scheduledTimer(
            withTimeInterval: checkInterval,
            repeats: true,
            block: { [weak self] _ in
                self?.detectNewNotificationWindows()
            }
        )
        
        stabilizationTimer = Timer.scheduledTimer(
            withTimeInterval: stabilizationInterval,
            repeats: true,
            block: { [weak self] _ in
                self?.stabilizeWindows()
            }
        )
    }

    /// Stops monitoring
    func stopMonitoring() {
        globalWindowMonitorTimer?.invalidate()
        globalWindowMonitorTimer = nil
        
        stabilizationTimer?.invalidate()
        stabilizationTimer = nil
        stabilizingWindows.removeAll()

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

    // MARK: - Notification Center Observer

    private func setupNotificationCenterObserver() {
        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        }) else {
            LoggingService.shared.error("❌ Notification Center not running")
            return
        }

        let pid = app.processIdentifier

        // Check if we already have an observer
        if appObservers[pid] != nil { return }

        var observer: AXObserver?
        let observerCallback: AXObserverCallback = { (observer, element, notification, refcon) in
            guard let refcon = refcon else { return }
            let service = Unmanaged<WindowMonitorService>.fromOpaque(refcon).takeUnretainedValue()
            service.handleWindowCreated(element: element)
        }

        let result = AXObserverCreate(pid, observerCallback, &observer)

        guard result == .success, let axObserver = observer else {
            LoggingService.shared.error("❌ Failed to create observer for Notification Center")
            return
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let appElement = AXUIElementCreateApplication(pid)

        AXObserverAddNotification(axObserver, appElement, kAXWindowCreatedNotification as CFString, selfPtr)
        CFRunLoopAddSource(RunLoop.current.getCFRunLoop(), AXObserverGetRunLoopSource(axObserver), .defaultMode)

        appObservers[pid] = axObserver
        LoggingService.shared.info("✅ Monitoring Notification Center (PID: \(pid))")
    }

    private func handleWindowCreated(element: AXUIElement) {
        // Validate element is still valid before proceeding
        var pid: pid_t = 0
        let result = AXUIElementGetPid(element, &pid)
        guard result == .success && pid > 0 else {
            LoggingService.shared.debug("   ⚠️ Invalid window element, skipping")
            return
        }

        // Move immediately without delay for smoother interception
        // Get size immediately - retry if not available
        guard let size = AXElementManager.shared.getSize(of: element) else {
            // If size isn't available yet, retry once after a short delay
            // Don't be too aggressive to avoid overwhelming the window system
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self, weak element] in
                guard let self = self, let element = element else { return }
                // Validate element is still valid
                var checkPid: pid_t = 0
                let checkResult = AXUIElementGetPid(element, &checkPid)
                guard checkResult == .success && checkPid > 0 else { return }

                if let s = AXElementManager.shared.getSize(of: element) {
                    self.moveNotificationElement(element, size: s, immediateMode: true)
                    self.startStabilizing(element)
                }
            }
            return
        }

        // Move it immediately in immediate mode (sets position multiple times)
        moveNotificationElement(element, size: size, immediateMode: true)

        // Start stabilizing it (to fight animation)
        startStabilizing(element)
    }

    private func moveNotificationElement(_ window: AXUIElement, size: CGSize, immediateMode: Bool = false) {
        let config = ConfigurationManager.shared
        let configPosition = config.currentPosition

        guard configPosition != .topRight else { return }

        // Validate window element before proceeding
        var pid: pid_t = 0
        let pidResult = AXUIElementGetPid(window, &pid)
        guard pidResult == .success && pid > 0 else {
            return
        }

        // Debug logging to track which position is being used
        LoggingService.shared.debug("   🎯 Target position: \(configPosition.displayName)")

        // Check for widgets
        if let identifier = AXElementManager.shared.getWindowIdentifier(window),
           identifier.hasPrefix("widget") {
            // LoggingService.shared.debug("   ℹ️ Skipping move - widget window detected: \(identifier)")
            return
        }

        // Skip NSThemeWidgetSharedWindowRemoteButton windows which cause system errors
        if let role = AXElementManager.shared.getRole(of: window),
           role.contains("RemoteButton") || role.contains("ThemeWidget") {
            LoggingService.shared.debug("   ℹ️ Skipping move - system widget button detected")
            return
        }

        // Check if normal notification interception is enabled
        guard config.interceptNotifications else {
            return
        }

        // For normal notifications, find the actual banner content within the window
        let targetSubroles = [
            "AXNotificationCenterBanner",
            "AXNotificationCenterAlert",
            "AXNotificationCenterNotification",
            "AXNotificationCenterBannerWindow",
            "AXBanner",
            "AXAlert"
        ]

        // Try to find the banner element. If not found, skip (window popups no longer supported)
        guard let elementToMeasure = AXElementManager.shared.findElementBySubrole(
            root: window,
            targetSubroles: targetSubroles,
            osVersion: ProcessInfo.processInfo.operatingSystemVersion
        ) else {
            LoggingService.shared.debug("   ℹ️ Skipping move - No banner element found (not a standard notification)")
            return
        }

        guard let currentBannerPos = AXElementManager.shared.getPosition(of: elementToMeasure),
              let bannerSize = AXElementManager.shared.getSize(of: elementToMeasure),
              let currentWindowPos = AXElementManager.shared.getPosition(of: window) else {
            // LoggingService.shared.error("   ❌ Failed to get positions/sizes")
            return
        }

        // Calculate where we WANT the banner to be
        let targetBannerPos = NotificationPositioningService.shared.calculatePositionWithAutoPadding(
            notifSize: bannerSize,
            currentPosition: configPosition,
            screenBounds: NSScreen.main!.frame
        )

        // Calculate the delta needed
        let deltaX = targetBannerPos.x - currentBannerPos.x
        let deltaY = targetBannerPos.y - currentBannerPos.y

        // If delta is negligible, stop
        if abs(deltaX) < 1.0 && abs(deltaY) < 1.0 {
            return
        }

        // Apply delta to the WINDOW
        let newWindowPos = CGPoint(
            x: currentWindowPos.x + deltaX,
            y: currentWindowPos.y + deltaY
        )

        LoggingService.shared.debug("   Attempting to stabilize notification to \(configPosition.displayName)")
        LoggingService.shared.debug("   Banner: \(currentBannerPos) -> \(targetBannerPos) (Delta: \(deltaX), \(deltaY))")
        LoggingService.shared.debug("   Window: \(currentWindowPos) -> \(newWindowPos)")

        applyPositionToWindow(window, targetPos: newWindowPos, deltaX: deltaX, deltaY: deltaY, immediateMode: immediateMode)
    }

    /// Applies position to a window with optional immediate mode firehose
    /// - Parameters:
    ///   - window: The window element to position
    ///   - targetPos: The target position
    ///   - deltaX: X delta for logging
    ///   - deltaY: Y delta for logging
    ///   - immediateMode: Whether to use aggressive positioning
    private func applyPositionToWindow(_ window: AXUIElement, targetPos: CGPoint, deltaX: CGFloat, deltaY: CGFloat, immediateMode: Bool = false) {
        // In immediate mode, set position more aggressively to catch it before first render
        if immediateMode {
            let success = AXElementManager.shared.setPosition(of: window, x: targetPos.x, y: targetPos.y)

            // Set position 2 more times with small delays to ensure it sticks
            // This combats the macOS animation that tries to return it to default
            // Using fewer retries to avoid overwhelming the window system
            for delay in [0.002, 0.008] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak window] in
                    guard let window = window else { return }
                    // Validate window is still valid before setting position
                    var checkPid: pid_t = 0
                    let checkResult = AXUIElementGetPid(window, &checkPid)
                    if checkResult == .success {
                        _ = AXElementManager.shared.setPosition(of: window, x: targetPos.x, y: targetPos.y)
                    }
                }
            }

            if success {
                // LoggingService.shared.info("   ✅ Successfully moved notification!")
            } else {
                LoggingService.shared.error("   ⚠️ Failed to move notification")
            }
        } else {
            let success = AXElementManager.shared.setPosition(of: window, x: targetPos.x, y: targetPos.y)

            if success {
                // LoggingService.shared.info("   ✅ Successfully moved notification!")
            } else {
                LoggingService.shared.error("   ⚠️ Failed to move notification")
            }
        }
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

        LoggingService.shared.debug("🔍 Initial window set: \(knownWindowNumbers.count) windows tracked")
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

                LoggingService.shared.info("🆕 NEW notification window detected!")
                LoggingService.shared.debug("   App: \(ownerName) [PID: \(ownerPID)]")
                LoggingService.shared.debug("   Size: \(Int(width))×\(Int(height)) at (\(Int(x)), \(Int(y)))")
                LoggingService.shared.debug("   Window#: \(windowNumber), Layer: \(layer)")

                // Add to known windows
                knownWindowNumbers.insert(windowNumber)

                // Try to move it immediately
                if let axElement = getAXElementForWindow(
                    windowNumber: windowNumber,
                    processID: pid_t(ownerPID),
                    position: CGPoint(x: x, y: y),
                    size: CGSize(width: width, height: height)
                ) {
                    // Move immediately with immediate mode (firehose positioning)
                    moveNotificationElement(axElement, size: CGSize(width: width, height: height), immediateMode: true)
                    // Start stabilizing it
                    startStabilizing(axElement)
                }
            } else {
                // Not a notification, but track it anyway
                knownWindowNumbers.insert(windowNumber)
            }
        }
    }
    
    // MARK: - Stabilization Logic
    
    private func startStabilizing(_ element: AXUIElement) {
        let wrapper = AXUIElementWrapper(element: element)
        stabilizingWindows[wrapper] = Date()
    }
    
    private func stabilizeWindows() {
        let now = Date()
        
        // Remove expired windows
        for (wrapper, startTime) in stabilizingWindows {
            if now.timeIntervalSince(startTime) > stabilizationDuration {
                stabilizingWindows.removeValue(forKey: wrapper)
            } else {
                // Check if element is still valid
                if let size = AXElementManager.shared.getSize(of: wrapper.element) {
                    moveNotificationElement(wrapper.element, size: size)
                } else {
                    stabilizingWindows.removeValue(forKey: wrapper)
                }
            }
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

                LoggingService.shared.debug("🔍 Found potential notification window: \(ownerName) [\(ownerPID)] - \(windowName) - Size: \(Int(width))×\(Int(height)) at (\(Int(x)), \(Int(y)))")
            }
        }
    }
}

// MARK: - Helper Wrapper for Dictionary Key
struct AXUIElementWrapper: Hashable {
    let element: AXUIElement
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(element))
    }
    
    static func == (lhs: AXUIElementWrapper, rhs: AXUIElementWrapper) -> Bool {
        return CFEqual(lhs.element, rhs.element)
    }
}
