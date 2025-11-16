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
        LoggingService.shared.log(message, category: "DiagnosticViewModel")
    }

    func clearOutput() {
        onOutputCleared?()
        log("Output cleared")
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
            log("🧪 Test 2: Window Element Position (PingPlace approach)")
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

        log("💡 PingPlace sets position on WINDOW element, not banner!")
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
}
