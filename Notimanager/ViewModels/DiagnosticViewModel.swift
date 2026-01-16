//
//  DiagnosticViewModel.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  ViewModel for diagnostic screen - manages API testing and diagnostics
//

import Cocoa

/// ViewModel for DiagnosticViewController
class DiagnosticViewModel {

    // MARK: - Callbacks

    var onLogMessage: ((String) -> Void)?
    var onOutputCleared: (() -> Void)?

    // MARK: - Properties

    private let notificationCenterBundleID = "com.apple.notificationcenterui"
    private let notificationSubroles: [String]

    private var lastWindowElement: AXUIElement?
    private var lastNotificationElement: AXUIElement?

    // MARK: - Initialization

    init() {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion

        if osVersion.majorVersion >= 26 {
            notificationSubroles = [
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
            notificationSubroles = [
                "AXNotificationCenterBanner",
                "AXNotificationCenterAlert",
                "AXNotification",
                "AXBanner",
                "AXAlert",
                "AXSystemDialog"
            ]
        } else {
            notificationSubroles = ["AXNotificationCenterBanner", "AXNotificationCenterAlert"]
        }
    }

    // MARK: - Logging

    func log(_ message: String) {
        onLogMessage?(message)
        debugLog(message)
    }

    private func debugLog(_ message: String) {
        LoggingService.shared.debug(message)
    }

    func clearOutput() {
        onOutputCleared?()
        log("Output cleared")
    }

    func sendTestNotification() {
        log("🔔 Sending test notification...")

        // Use the shared TestNotificationService to send a test notification
        if #available(macOS 10.15, *) {
            TestNotificationService.shared.sendTestNotification { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.log("✅ Test notification sent successfully!")
                        self?.log("💡 Check if it appears at your configured position")
                    case .failure(let error):
                        self?.log("❌ Failed to send test notification: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            log("❌ Test notifications require macOS 10.15 or later")
        }
    }

    // MARK: - Diagnostic Operations

    func scanWindows() {
        log("🔍 Scanning all windows on screen...")

        let options = CGWindowListOption([.optionOnScreenOnly, .excludeDesktopElements])
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            log("❌ Failed to get window list")
            return
        }

        var notificationCount = 0
        for window in windowList {
            guard let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = bounds["Width"],
                  let height = bounds["Height"],
                  let x = bounds["X"],
                  let y = bounds["Y"] else {
                continue
            }

            // Look for notification-sized windows
            if width >= 200 && width <= 800 && height >= 60 && height <= 200 {
                let ownerName = window[kCGWindowOwnerName as String] as? String ?? "Unknown"
                let windowNumber = window[kCGWindowNumber as String] as? Int ?? -1
                let layer = window[kCGWindowLayer as String] as? Int ?? -1
                notificationCount += 1
                log("  ✓ Found: \(ownerName) [#\(windowNumber)] Layer:\(layer) - \(Int(width))×\(Int(height)) at (\(Int(x)), \(Int(y)))")
            }
        }

        if notificationCount == 0 {
            log("❌ No notification-sized windows found")
            log("💡 This means notifications are likely ONLY in NC panel (cannot be moved)")
        } else {
            log("✅ Found \(notificationCount) potential notification window(s)")
            log("💡 These might be movable using CGWindow APIs")
        }
        log("")
    }

    func testAccessibilityAPI() {
        log("♿️ Testing Accessibility API...")

        guard let pid = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else {
            log("❌ Cannot find Notification Center process")
            return
        }

        let app = AXUIElementCreateApplication(pid)
        var windowsRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)

        if result == .success, let windows = windowsRef as? [AXUIElement] {
            log("✅ Found \(windows.count) AX windows from Notification Center")

            for (index, window) in windows.enumerated() {
                if let size = getSize(of: window) {
                    log("  Window \(index): \(Int(size.width))×\(Int(size.height))")

                    // Check if it's the NC panel
                    if size.width > 1000 && size.height > 1000 {
                        log("    → This is the NC panel (contains nested notifications)")
                        lastWindowElement = window

                        // Check if window position is settable
                        var windowSettable: DarwinBoolean = false
                        AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &windowSettable)
                        log("    → Window position settable: \(windowSettable.boolValue ? "✅ YES" : "❌ NO")")

                        // Try to find notification children
                        if let banner = findElementWithSubrole(root: window) {
                            if let bannerSize = getSize(of: banner) {
                                log("    → Found notification element: \(Int(bannerSize.width))×\(Int(bannerSize.height))")
                                lastNotificationElement = banner

                                // Check if banner position is settable
                                var bannerSettable: DarwinBoolean = false
                                AXUIElementIsAttributeSettable(banner, kAXPositionAttribute as CFString, &bannerSettable)
                                log("    → Banner position settable: \(bannerSettable.boolValue ? "✅ YES" : "❌ NO")")
                            }
                        }
                    }
                }
            }
        } else {
            log("❌ Failed to get AX windows: \(axErrorToString(result))")
        }
        log("")
    }

    func trySetPosition() {
        log("📍 Testing different positioning approaches...")
        log("")

        // Test 1: Try banner element
        if let banner = lastNotificationElement {
            log("🧪 Test 1: Banner Element Position")
            var settable: DarwinBoolean = false
            AXUIElementIsAttributeSettable(banner, kAXPositionAttribute as CFString, &settable)
            log("  Settable: \(settable.boolValue ? "✅ YES" : "❌ NO")")

            if settable.boolValue {
                var point = CGPoint(x: 100, y: 100)
                let value = AXValueCreate(.cgPoint, &point)!
                let result = AXUIElementSetAttributeValue(banner, kAXPositionAttribute as CFString, value)
                log("  Set result: \(result == .success ? "✅ SUCCESS" : "❌ FAILED")")
                if result == .success, let newPos = getPosition(of: banner) {
                    log("  New position: (\(Int(newPos.x)), \(Int(newPos.y)))")
                }
            }
            log("")
        }

        // Test 2: Try window element
        if let window = lastWindowElement {
            log("🧪 Test 2: Window Element Position (Notimanager approach)")
            var settable: DarwinBoolean = false
            AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &settable)
            log("  Settable: \(settable.boolValue ? "✅ YES" : "❌ NO")")

            if let currentPos = getPosition(of: window) {
                log("  Current window position: (\(Int(currentPos.x)), \(Int(currentPos.y)))")
            }

            var point = CGPoint(x: 500, y: 500)
            let value = AXValueCreate(.cgPoint, &point)!
            let result = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
            log("  Set result: \(result == .success ? "✅ SUCCESS" : "❌ FAILED (\(axErrorToString(result)))")")

            if let newPos = getPosition(of: window) {
                log("  After set position: (\(Int(newPos.x)), \(Int(newPos.y)))")
                if newPos.x == 500 && newPos.y == 500 {
                    log("  ✅✅ POSITION CHANGED! Window element IS movable!")
                }
            }
            log("")
        }

        if lastNotificationElement == nil && lastWindowElement == nil {
            log("❌ No elements found. Click 'Test Accessibility API' first!")
        }

        log("💡 Notimanager sets position on WINDOW element, not banner!")
        log("   If Test 2 works, we should use that approach!")
        log("")
    }

    func analyzeNCPanel() {
        log("📋 Analyzing Notification Center panel...")

        guard let pid = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else {
            log("❌ Cannot find Notification Center process")
            return
        }

        let app = AXUIElementCreateApplication(pid)
        var windowsRef: AnyObject?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else {
            log("❌ Failed to get windows")
            return
        }

        for window in windows {
            if let size = getSize(of: window), size.width > 1000 {
                log("✅ Found NC panel: \(Int(size.width))×\(Int(size.height))")
                if let pos = getPosition(of: window) {
                    log("   Position: (\(Int(pos.x)), \(Int(pos.y)))")
                    if pos.x > 2560 {
                        log("   ⚠️ Panel is OFF-SCREEN (x > screen width)")
                    }
                }

                var settable: DarwinBoolean = false
                AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &settable)
                log("   Panel position settable: \(settable.boolValue ? "✅ YES" : "❌ NO")")

                log("   Searching for notification children...")
                scanElementTree(window, depth: 0, maxDepth: 6)
            }
        }
        log("")
    }

    func testStabilization() {
        log("🔄 Testing Stabilization System...")

        // Simulate the stabilization process
        log("   Checking for actively moving windows...")

        guard let pid = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else {
            log("❌ Cannot find Notification Center process")
            return
        }

        let app = AXUIElementCreateApplication(pid)
        var windowsRef: AnyObject?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else {
            log("❌ Failed to get windows")
            return
        }

        var stabilizingCount = 0
        for window in windows {
            if let size = getSize(of: window) {
                // Check if it's a notification-sized window
                if size.width >= 200 && size.width <= 800 && size.height >= 60 && size.height <= 200 {
                    log("   📊 Found notification window: \(Int(size.width))×\(Int(size.height))")

                    // Test position reading over time to detect animation
                    var positions: [CGPoint] = []
                    for _ in 0..<5 {
                        if let pos = getPosition(of: window) {
                            positions.append(pos)
                        }
                        Thread.sleep(forTimeInterval: 0.05)
                    }

                    // Check if positions are changing (animation)
                    let isAnimating = positions.count > 1 &&
                                     positions.dropFirst().allSatisfy { $0 != positions.first }

                    if isAnimating {
                        stabilizingCount += 1
                        log("      ⚠️ WINDOW IS ANIMATING - needs stabilization")
                        log("      Position samples: \(positions.map { "(\(Int($0.x)),\(Int($0.y)))" }.joined(separator: " → "))")
                    } else {
                        log("      ✅ Window is stable")
                    }
                }
            }
        }

        log("")
        log("📊 Stabilization Summary:")
        log("   Total notification windows: \(stabilizingCount)")
        log("   Stabilization duration: 1.0 second")
        log("   Re-adjust interval: 50ms")

        if stabilizingCount > 0 {
            log("   💡 These windows will be continuously re-positioned for 1 second")
        } else {
            log("   ℹ️ Send a notification to test stabilization in real-time")
        }
        log("")
    }

    func testWidgetDetection() {
        log("🧩 Testing Widget Panel Detection...")

        guard let pid = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else {
            log("❌ Cannot find Notification Center process")
            return
        }

        let app = AXUIElementCreateApplication(pid)

        // Search for widget elements
        let widgetElements = findElementsByWidgetIdentifier(root: app, prefix: "widget-local:")

        if widgetElements.isEmpty {
            log("❌ No widget panels found")
            log("💡 This means Notification Center is not currently open")
        } else {
            log("✅ Found \(widgetElements.count) widget panel(s)")

            for (index, widget) in widgetElements.enumerated() {
                if let size = getSize(of: widget) {
                    log("   Widget \(index + 1): \(Int(size.width))×\(Int(size.height))")

                    if let pos = getPosition(of: widget) {
                        log("      Position: (\(Int(pos.x)), \(Int(pos.y)))")
                    }

                    if let identifier = getWindowIdentifier(of: widget) {
                        log("      ID: \(identifier)")
                    }

                    // Check if widget is visible
                    if size.width >= 150 && size.height >= 150 {
                        log("      Status: ✅ Visible and sized correctly")
                    } else {
                        log("      Status: ⚠️ Too small (likely hidden/collapsed)")
                    }
                }
            }

            log("")
            log("💡 Widget Detection Impact:")
            log("   When NC opens → Notifications may move to NC panel (unmovable)")
            log("   When NC closes → Notifications return to separate windows (movable)")
        }
        log("")
    }

    func testMultipleNotifications() {
        log("📚 Testing Multiple Notification Stacking...")

        guard let pid = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else {
            log("❌ Cannot find Notification Center process")
            return
        }

        let app = AXUIElementCreateApplication(pid)
        var windowsRef: AnyObject?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else {
            log("❌ Failed to get windows")
            return
        }

        var notificationWindows: [(element: AXUIElement, size: CGSize, position: CGPoint)] = []

        for window in windows {
            if let size = getSize(of: window), let pos = getPosition(of: window) {
                // Check if it's a notification-sized window
                if size.width >= 200 && size.width <= 800 && size.height >= 60 && size.height <= 200 {
                    notificationWindows.append((window, size, pos))
                }
            }
        }

        if notificationWindows.isEmpty {
            log("ℹ️ No notification windows found")
            log("💡 Send multiple test notifications to see stacking behavior")
            log("")
            return
        }

        log("✅ Found \(notificationWindows.count) notification window(s)")

        // Group by Y position to detect stacking
        let groupedByY = Dictionary(grouping: notificationWindows) { entry in
            Int(entry.position.y / 100) * 100 // Group by 100px bands
        }

        if groupedByY.count > 1 {
            log("📊 Notifications are stacked vertically:")
            let sortedGroups = groupedByY.sorted { $0.key < $1.key }

            for (yBand, entries) in sortedGroups {
                log("   Y-band \(yBand): \(entries.count) notification(s)")
                for entry in entries {
                    log("      - \(Int(entry.size.width))×\(Int(entry.size.height)) at (\(Int(entry.position.x)), \(Int(entry.position.y)))")
                }
            }

            log("")
            log("💡 Stacking Info:")
            log("   macOS stacks notifications with ~20px vertical spacing")
            log("   Each notification is moved independently to the target position")
            log("   The stabilization system fights the stacking animation")
        } else {
            log("📊 All notifications are in the same Y-band")
            for entry in notificationWindows {
                log("   - \(Int(entry.size.width))×\(Int(entry.size.height)) at (\(Int(entry.position.x)), \(Int(entry.position.y)))")
            }
        }
        log("")
    }

    func testPositionVerification() {
        log("✅ Testing Position Verification...")

        guard let pid = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else {
            log("❌ Cannot find Notification Center process")
            return
        }

        let app = AXUIElementCreateApplication(pid)
        var windowsRef: AnyObject?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else {
            log("❌ Failed to get windows")
            return
        }

        var verifiedCount = 0
        var failedCount = 0

        for window in windows {
            if let size = getSize(of: window) {
                // Check if it's a notification-sized window
                if size.width >= 200 && size.width <= 800 && size.height >= 60 && size.height <= 200 {
                    log("   Testing notification window: \(Int(size.width))×\(Int(size.height))")

                    // Get current position
                    guard let currentPos = getPosition(of: window) else {
                        log("      ❌ Cannot read position")
                        failedCount += 1
                        continue
                    }

                    log("      Current position: (\(Int(currentPos.x)), \(Int(currentPos.y)))")

                    // Try to set a new position
                    let targetPos = CGPoint(x: 100, y: 100)
                    let didSet = AXElementManager.shared.setPosition(of: window, x: targetPos.x, y: targetPos.y)

                    if !didSet {
                        log("      ❌ Failed to set position")
                        failedCount += 1
                        continue
                    }

                    // Verify the position was set
                    Thread.sleep(forTimeInterval: 0.01) // Small delay for system to update

                    if let newPos = getPosition(of: window) {
                        let tolerance: CGFloat = 2.0
                        let xMatch = abs(newPos.x - targetPos.x) <= tolerance
                        let yMatch = abs(newPos.y - targetPos.y) <= tolerance
                        let isVerified = xMatch && yMatch

                        if isVerified {
                            log("      ✅ Position verified: (\(Int(newPos.x)), \(Int(newPos.y)))")
                            log("         Tolerance: ±\(Int(tolerance))px")
                            verifiedCount += 1
                        } else {
                            log("      ⚠️ Position mismatch!")
                            log("         Expected: (\(Int(targetPos.x)), \(Int(targetPos.y)))")
                            log("         Got: (\(Int(newPos.x)), \(Int(newPos.y)))")
                            log("         Delta: (\(Int(abs(newPos.x - targetPos.x))), \(Int(abs(newPos.y - targetPos.y))))")
                            failedCount += 1
                        }
                    } else {
                        log("      ❌ Cannot verify position (read failed)")
                        failedCount += 1
                    }
                }
            }
        }

        log("")
        log("📊 Verification Summary:")
        log("   ✅ Verified: \(verifiedCount)")
        log("   ❌ Failed: \(failedCount)")

        if verifiedCount == 0 && failedCount == 0 {
            log("ℹ️ No notification windows found - send a test notification first")
        }
        log("")
    }

    // MARK: - Helper Methods

    private func findElementWithSubrole(root: AXUIElement) -> AXUIElement? {
        var subroleRef: AnyObject?
        if AXUIElementCopyAttributeValue(root, kAXSubroleAttribute as CFString, &subroleRef) == .success,
           let subrole = subroleRef as? String,
           notificationSubroles.contains(subrole) {
            return root
        }

        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            if let found = findElementWithSubrole(root: child) {
                return found
            }
        }

        return nil
    }

    private func scanElementTree(_ element: AXUIElement, depth: Int, maxDepth: Int) {
        if depth > maxDepth { return }

        let indent = String(repeating: "  ", count: depth + 1)

        var subroleRef: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef) == .success,
           let subrole = subroleRef as? String {

            if subrole.contains("Notification") {
                if let size = getSize(of: element), let pos = getPosition(of: element) {
                    log("\(indent)🎯 NOTIFICATION: \(subrole) - \(Int(size.width))×\(Int(size.height)) at (\(Int(pos.x)), \(Int(pos.y)))")

                    var settable: DarwinBoolean = false
                    AXUIElementIsAttributeSettable(element, kAXPositionAttribute as CFString, &settable)
                    log("\(indent)   Settable: \(settable.boolValue ? "✅ YES" : "❌ NO")")
                }
            }
        }

        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else { return }

        for child in children {
            scanElementTree(child, depth: depth + 1, maxDepth: maxDepth)
        }
    }

    private func getSize(of element: AXUIElement) -> CGSize? {
        var sizeValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)
        guard result == .success else { return nil }
        guard let sizeVal = sizeValue, AXValueGetType(sizeVal as! AXValue) == .cgSize else { return nil }

        var size = CGSize.zero
        AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)
        return size
    }

    private func getPosition(of element: AXUIElement) -> CGPoint? {
        var positionValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        guard result == .success else { return nil }
        guard let posVal = positionValue, AXValueGetType(posVal as! AXValue) == .cgPoint else { return nil }

        var position = CGPoint.zero
        AXValueGetValue(posVal as! AXValue, .cgPoint, &position)
        return position
    }

    private func axErrorToString(_ error: AXError) -> String {
        switch error {
        case .success: return "success"
        case .failure: return "failure"
        case .illegalArgument: return "illegalArgument"
        case .invalidUIElement: return "invalidUIElement"
        case .invalidUIElementObserver: return "invalidUIElementObserver"
        case .cannotComplete: return "cannotComplete"
        case .attributeUnsupported: return "attributeUnsupported"
        case .actionUnsupported: return "actionUnsupported"
        case .notificationUnsupported: return "notificationUnsupported"
        case .notImplemented: return "notImplemented"
        case .notificationAlreadyRegistered: return "notificationAlreadyRegistered"
        case .notificationNotRegistered: return "notificationNotRegistered"
        case .apiDisabled: return "apiDisabled"
        case .noValue: return "noValue"
        case .parameterizedAttributeUnsupported: return "parameterizedAttributeUnsupported"
        case .notEnoughPrecision: return "notEnoughPrecision"
        @unknown default: return "unknown(\(error.rawValue))"
        }
    }

    private func findElementsByWidgetIdentifier(root: AXUIElement, prefix: String) -> [AXUIElement] {
        var results: [AXUIElement] = []

        if let identifier = getWindowIdentifier(of: root),
           identifier.hasPrefix(prefix) {

            // Verify this is an actual widget panel (significant size)
            if let size = getSize(of: root),
               size.width >= 150 && size.height >= 150 {
                results.append(root)
            }
        }

        // Search children
        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {
            return results
        }

        for child in children {
            results.append(contentsOf: findElementsByWidgetIdentifier(root: child, prefix: prefix))
        }

        return results
    }

    private func getWindowIdentifier(of element: AXUIElement) -> String? {
        var identifierRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute as CFString, &identifierRef)

        guard result == .success,
              let identifier = identifierRef as? String else {
            return nil
        }

        return identifier
    }
}
