# Phase 1 Refactoring - Migration Guide

## Overview

This document shows how to migrate from the monolithic `NotificationMover` class to use the newly extracted services.

## New Files Created

1. **LoggingService.swift** - Centralized debug and diagnostic logging
2. **ConfigurationManager.swift** - UserDefaults management with change notifications
3. **AXErrorFormatter.swift** - Accessibility API error formatting
4. **NotificationMoverProtocols.swift** - Core protocol definitions

---

## Step 1: Update NotificationMover Properties

### Before (Lines 17-43):
```swift
private let notificationCenterBundleID: String = "com.apple.notificationcenterui"
private let paddingAboveDock: CGFloat = 30
private let widgetIdentifierPrefix: String = "widget-local:"
private var axObserver: AXObserver?
private var statusItem: NSStatusItem?
private var isMenuBarIconHidden: Bool = UserDefaults.standard.bool(forKey: "isMenuBarIconHidden")
private let logger: Logger = .init(subsystem: "dev.abd3lraouf.notimanager", category: "NotificationMover")
private var debugMode: Bool = UserDefaults.standard.bool(forKey: "debugMode")
private var isEnabled: Bool = UserDefaults.standard.object(forKey: "isEnabled") as? Bool ?? true
private let launchAgentPlistPath: String = NSHomeDirectory() + "/Library/LaunchAgents/dev.abd3lraouf.notimanager.plist"
private var settingsWindow: NSWindow?
private var testStatusLabel: NSTextField?
private var lastNotificationTime: Date?
private var notificationWasIntercepted: Bool = false
private var cachedInitialNotifSize: CGSize?
private var cachedInitialPadding: CGFloat?
private var cachedInitialWindowPosition: CGPoint?
private var widgetMonitorTimer: Timer?
private var lastWidgetWindowCount: Int = 0
private var pollingEndTime: Date?
private let osVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
private var hasLoggedEmptyWidget: Bool = false
private var knownWindowNumbers: Set<Int> = []
private var globalWindowMonitorTimer: Timer?
private var appObservers: [pid_t: AXObserver] = [:]

private lazy var notificationSubroles: [String] = {
    if osVersion.majorVersion >= 26 {
        return ["AXNotificationCenterBanner", ...]
    } else if osVersion.majorVersion >= 15 {
        return ["AXNotificationCenterBanner", ...]
    } else {
        return ["AXNotificationCenterBanner", "AXNotificationCenterAlert"]
    }
}()

private var currentPosition: NotificationPosition = {
    guard let rawValue: String = UserDefaults.standard.string(forKey: "notificationPosition"),
          let position = NotificationPosition(rawValue: rawValue)
    else {
        return .topMiddle
    }
    return position
}()
```

### After:
```swift
// MARK: - Services
private let loggingService = LoggingService.shared
private let configurationManager = ConfigurationManager.shared

// MARK: - Constants
private let notificationCenterBundleID: String = "com.apple.notificationcenterui"
private let paddingAboveDock: CGFloat = 30
private let widgetIdentifierPrefix: String = "widget-local:"
private let osVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion

// MARK: - AX & Window State
private var axObserver: AXObserver?
private var statusItem: NSStatusItem?
private var settingsWindow: NSWindow?
private var testStatusLabel: NSTextField?
private var lastNotificationTime: Date?
private var notificationWasIntercepted: Bool = false
private var cachedInitialNotifSize: CGSize?
private var cachedInitialPadding: CGFloat?
private var cachedInitialWindowPosition: CGPoint?
private var widgetMonitorTimer: Timer?
private var lastWidgetWindowCount: Int = 0
private var pollingEndTime: Date?
private var hasLoggedEmptyWidget: Bool = false
private var knownWindowNumbers: Set<Int> = []
private var globalWindowMonitorTimer: Timer?
private var appObservers: [pid_t: AXObserver] = [:]

// MARK: - Computed Properties (backed by ConfigurationManager)
private var currentPosition: NotificationPosition {
    get { configurationManager.currentPosition }
    set { configurationManager.currentPosition = newValue }
}

private var isEnabled: Bool {
    get { configurationManager.isEnabled }
    set { configurationManager.isEnabled = newValue }
}

private var debugMode: Bool {
    get { configurationManager.debugMode }
    set { configurationManager.debugMode = newValue }
}

private var isMenuBarIconHidden: Bool {
    get { configurationManager.isMenuBarIconHidden }
    set { configurationManager.isMenuBarIconHidden = newValue }
}

private var launchAgentPlistPath: String {
    configurationManager.launchAgentPlistPath
}

// MARK: - Lazy Properties
private lazy var notificationSubroles: [String] = {
    if osVersion.majorVersion >= 26 {
        return [
            "AXNotificationCenterBanner",
            "AXNotificationCenterAlert",
            "AXNotificationCenterNotification",
            "AXNotificationCenterBannerWindow",
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
}()
```

---

## Step 2: Replace debugLog Calls

### Before (Line 87-90):
```swift
fileprivate func debugLog(_ message: String) {
    guard debugMode else { return }
    logger.info("\(message, privacy: .public)")
}
```

### After:
```swift
// No longer needed - use LoggingService.shared directly
// Example usage:
// loggingService.debug("Message here")
// or
// LoggingService.shared.debug("Message here")
```

### Global Search & Replace:
- **Find:** `debugLog(`
- **Replace:** `LoggingService.shared.debugLog(`
- **Find:** `logger.info(`
- **Replace:** `LoggingService.shared.info(`

---

## Step 3: Replace diagnosticLog Calls

### Before (Line 805-810):
```swift
private func diagnosticLog(_ message: String) {
    guard let textView = diagnosticTextView else { return }
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    let line = "[\(timestamp)] \(message)\n"
    textView.string += line
    textView.scrollToEndOfDocument(nil)
}
```

### After:
```swift
// No longer needed - use LoggingService.shared directly
// Set the diagnostic text view once during setup:
// LoggingService.shared.setDiagnosticTextView(diagnosticTextView)

// Then use:
// LoggingService.shared.diagnostic("Message here")
```

### Don't forget to set the diagnostic view during window creation:
```swift
private func createDiagnosticWindow() {
    // ... existing window creation code ...

    // After creating the text view:
    LoggingService.shared.setDiagnosticTextView(diagnosticTextView)
}
```

---

## Step 4: Replace axErrorToString Calls

### Before (Line 2984-3004):
```swift
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
```

### After:
```swift
// No longer needed - use AXErrorFormatter directly
// Example usage:
// let errorString = AXErrorFormatter.string(from: error)
// or
// let readableError = error.readableDescription
```

### Global Search & Replace:
- **Find:** `axErrorToString(`
- **Replace:** `AXErrorFormatter.string(from:`

---

## Step 5: Replace UserDefaults Access

### Before:
```swift
// Reading
let isHidden = UserDefaults.standard.bool(forKey: "isMenuBarIconHidden")
let isEnabled = UserDefaults.standard.object(forKey: "isEnabled") as? Bool ?? true

// Writing
UserDefaults.standard.set(newValue, forKey: "notificationPosition")
```

### After:
```swift
// Reading
let isHidden = configurationManager.isMenuBarIconHidden
let isEnabled = configurationManager.isEnabled

// Writing (automatic via setter)
configurationManager.currentPosition = newValue
// or
configurationManager.isEnabled = false
```

---

## Step 6: Update System Info Logging

### Before (Line 3006-3018):
```swift
private func logSystemInfo() {
    debugLog("=== SYSTEM INFORMATION ===")
    debugLog("macOS Version: \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")
    debugLog("Notimanager Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
    debugLog("Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
    debugLog("Current Position: \(currentPosition.displayName)")
    debugLog("Debug Mode: \(debugMode ? "ON" : "OFF")")

    if osVersion.majorVersion >= 26 {
        debugLog("macOS 26+ Mode: ENABLED - Using expanded notification subroles")
    }
    debugLog("Active Notification Subroles: \(notificationSubroles.joined(separator: ", "))")
}
```

### After:
```swift
private func logSystemInfo() {
    LoggingService.shared.logSystemInfo(
        osVersion: osVersion,
        notificationSubroles: notificationSubroles,
        currentPosition: currentPosition
    )
}
```

---

## Step 7: Add Configuration Observer

To observe configuration changes, make `NotificationMover` conform to the observer protocol:

```swift
// Add to NotificationMover class
extension NotificationMover: ConfigurationManager.ConfigurationObserver {
    func configurationDidChange(_ event: ConfigurationManager.ConfigurationEvent) {
        switch event {
        case .positionChanged:
            loggingService.debug("Position changed to \(currentPosition.displayName)")
            // Handle position change if needed

        case .enabledChanged:
            loggingService.debug("Enabled changed to \(isEnabled)")
            // Handle enabled state change

        case .debugModeChanged:
            loggingService.debug("Debug mode changed to \(debugMode)")
            // Debug mode already synced via LoggingService

        case .menuBarIconChanged:
            loggingService.debug("Menu bar icon visibility changed")
            updateMenuBarIcon()

        case .reset:
            loggingService.debug("Configuration reset to defaults")
            // Handle reset if needed
        }
    }
}

// In applicationDidFinishLaunching, register as observer:
func applicationDidFinishLaunching(_ notification: Notification) {
    logSystemInfo()
    requestNotificationPermissions()

    // Register as configuration observer
    ConfigurationManager.shared.addObserver(self)

    // ... rest of existing code ...
}
```

---

## Step 8: Update Clear Diagnostic Output

### Before (Line 813-814):
```swift
@objc private func diagnosticClearOutput() {
    diagnosticTextView?.string = ""
}
```

### After:
```swift
@objc private func diagnosticClearOutput() {
    LoggingService.shared.clearDiagnosticOutput()
}
```

---

## Testing Checklist

After applying these changes, verify:

- [ ] App compiles without errors
- [ ] Debug logging still works when enabled
- [ ] Diagnostic window still displays output
- [ ] Settings changes persist correctly
- [ ] Menu bar icon toggle works
- [ ] Position changes save and load
- [ ] AX error messages still display correctly

---

## Benefits

1. **Reduced coupling**: NotificationMover no longer manages logging, config, or error formatting
2. **Testability**: Each service can be tested independently
3. **Reusability**: Other parts of the app can use these services
4. **Clarity**: Responsibilities are clearly separated
5. **Maintainability**: Changes to logging/config affect single files

---

## Next Steps (Phase 2)

Phase 2 will extract:
- `AccessibilityPermissionManager` - Permission checking and UI (~400 lines)
- `MenuBarIconManager` - Status item management (~150 lines)
- `SettingsWindowController` - Settings UI (~500 lines)
- `DiagnosticWindowController` - Diagnostics tools (~400 lines)

This will reduce NotificationMover by approximately 1400 lines (45% reduction).
