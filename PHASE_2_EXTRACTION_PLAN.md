# Phase 2 Extraction Plan - Reuse Existing Architecture

## Overview

**Status:** Phase 1 Complete ✅ (2797 lines remaining, down from 3032)

## Existing Architecture (Already Extracted)

| Component | Location | Lines | Purpose |
|-----------|----------|-------|---------|
| **IconManager** | `Utilities/IconManager.swift` | 280 | Icon state management, menu bar icons |
| **SettingsWindow** | `Views/SettingsWindow.swift` | ~500 | Settings UI with PositionGridView |
| **PermissionWindow** | `Views/PermissionWindow.swift` | ~450 | Permission request UI |

---

## 🎯 PHASE 2: Extract Core Services (No Duplication)

### **Priority 1: Extract AX Element Manager** (~300 lines)

**What to Extract:**
- `getPosition()` - Get element position
- `getSize()` - Get element size
- `setPosition()` - Set element position
- `getPositionableElement()` - Determine which element to move
- `verifyPositionSet()` - Verify position was applied
- `findElementWithSubrole()` - Find notification by subrole
- `findNotificationElementFallback()` - Fallback search strategies
- `findElementByIdentifier()` - Find by ID
- `findElementByRoleAndSize()` - Find by role/size
- `findDeepestSizedElement()` - Deepest element search
- `findAnyElementWithSize()` - Any element with constraints
- `getWindowIdentifier()` - Get window ID
- `getWindowTitle()` - Get window title
- `logElementDetails()` - Log element info
- `collectAllSubrolesInHierarchy()` - Collect all subroles
- `dumpElementHierarchy()` - Debug tree dump

**Create:** `Managers/AXElementManager.swift`

```swift
/// Centralized Accessibility API element operations
@available(macOS 10.15, *)
class AXElementManager {

    static let shared = AXElementManager()

    private init() {}

    // MARK: - Element Properties

    /// Gets the position of an accessibility element
    func getPosition(of element: AXUIElement) -> CGPoint? {
        var positionValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        guard result == .success,
              let posVal = positionValue,
              AXValueGetType(posVal as! AXValue) == .cgPoint else {
            return nil
        }
        var position = CGPoint.zero
        AXValueGetValue(posVal as! AXValue, .cgPoint, &position)
        return position
    }

    /// Gets the size of an accessibility element
    func getSize(of element: AXUIElement) -> CGSize? {
        // ... implementation ...
    }

    /// Sets the position of an element
    func setPosition(of element: AXUIElement, x: CGFloat, y: CGFloat) -> Bool {
        // ... implementation ...
    }

    /// Determines which element should be moved (window vs banner)
    func getPositionableElement(window: AXUIElement, banner: AXUIElement, osVersion: OperatingSystemVersion) -> AXUIElement {
        // ... implementation ...
    }

    /// Verifies that a position was successfully applied
    func verifyPositionSet(_ element: AXUIElement, expected: CGPoint) -> Bool {
        // ... implementation ...
    }

    // MARK: - Element Finding

    /// Finds notification elements by subrole (primary search strategy)
    func findElementBySubrole(
        root: AXUIElement,
        targetSubroles: [String],
        osVersion: OperatingSystemVersion
    ) -> AXUIElement? {
        // From line 2316 (findElementWithSubrole)
        // Includes depth-aware search with candidate scoring
    }

    /// Finds notification elements using fallback strategies
    func findElementUsingFallbacks(root: AXUIElement, osVersion: OperatingSystemVersion) -> AXUIElement? {
        // From line 2424 (findNotificationElementFallback)
        // Multiple fallback strategies by role/size
    }

    /// Finds elements by identifier
    func findElementByIdentifier(
        root: AXUIElement,
        identifier: String,
        currentDepth: Int,
        maxDepth: Int
    ) -> AXUIElement? {
        // From line 2476 (findElementByIdentifier)
        // Recursive identifier search
    }

    /// Finds elements by role and size constraints
    func findElementByRoleAndSize(
        root: AXUIElement,
        role: String,
        sizeConstraints: SizeConstraints
    ) -> AXUIElement? {
        // From line 2499 (findElementByRoleAndSize)
        // Role-based size-constrained search
    }

    /// Finds the deepest element matching size constraints
    func findDeepestSizedElement(
        root: AXUIElement,
        sizeConstraints: SizeConstraints,
        currentDepth: Int,
        maxDepth: Int
    ) -> AXUIElement? {
        // From line 2523 (findDeepestSizedElement)
        // Depth-based recursive search
    }

    /// Finds any element matching size constraints
    func findAnyElementWithSize(
        root: AXUIElement,
        sizeConstraints: SizeConstraints
    ) -> AXUIElement? {
        // From line 2551 (findAnyElementWithSize)
        // Last-resort fallback
    }

    // MARK: - Element Information

    /// Gets window identifier
    func getWindowIdentifier(_ element: AXUIElement) -> String? {
        var identifierRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute as CFString, &identifierRef)
        guard result == .success,
              let identifier = identifierRef as? String else {
            return nil
        }
        return identifier
    }

    /// Gets window title
    func getWindowTitle(_ element: AXUIElement) -> String? {
        // From line 2198 (getWindowTitle)
        // Get window title attribute
    }

    /// Logs detailed element information
    func logElementDetails(_ element: AXUIElement, label: String) {
        // From line 2598 (logElementDetails)
        // Log role, subrole, size, position, identifier
    }

    /// Collects all subroles in element hierarchy
    func collectAllSubrolesInHierarchy(
        _ element: AXUIElement,
        depth: Int,
        maxDepth: Int
    ) -> Set<String> {
        // From line 2616 (collectAllSubrolesInHierarchy)
        // Recursive subrole collection
    }

    /// Dumps element hierarchy for debugging
    func dumpElementHierarchy(
        _ element: AXUIElement,
        label: String,
        depth: Int,
        maxDepth: Int
    ) {
        // From line 2670 (dumpElementHierarchy)
        // Debug tree dump with depth limit
    }
}
```

**Replace in NotificationMover:**
- All `self.getSize(` → `AXElementManager.shared.getSize(`
- All `self.setPosition(` → `AXElementManager.shared.setPosition(`
- All `self.getPosition(` → `AXElementManager.shared.getPosition(`
- All `self.getPositionableElement(` → `AXElementManager.shared.getPositionableElement(`
- All `self.verifyPositionSet(` → `AXElementManager.shared.verifyPositionSet(`
- All `self.findElement...(` → `AXElementManager.shared.findElement...(`

**Lines to Remove:** ~300 lines (lines ~2142-2445)

---

### **Priority 2: Extract Notification Positioning Service** (~150 lines)

**What to Extract:**
- `calculateNewPosition()` - Calculate target position based on settings
- `calculateNewPosition()` logic from lines 2472-2497

**Create:** `Managers/NotificationPositioningService.swift`

```swift
/// Service for calculating notification positions based on current settings
@available(macOS 10.15, *)
class NotificationPositioningService {

    static let shared = NotificationPositioningService()

    private init() {}

    /// Calculates the target position for a notification
    func calculatePosition(
        notifSize: CGSize,
        padding: CGFloat,
        currentPosition: NotificationPosition,
        screenBounds: CGRect = NSScreen.main!.frame
    ) -> CGPoint {

        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        let dockSize = screenBounds.origin.y // Use visible frame origin

        let newX: CGFloat
        let newY: CGFloat

        // Calculate X coordinate (horizontal position)
        switch currentPosition {
        case .topLeft, .middleLeft, .bottomLeft:
            newX = padding
        case .topMiddle, .bottomMiddle, .deadCenter:
            newX = (screenWidth - notifSize.width) / 2
        case .topRight, .middleRight, .bottomRight:
            newX = screenWidth - notifSize.width - padding
        }

        // Calculate Y coordinate (vertical position) - macOS uses bottom-left origin
        switch currentPosition {
        case .topLeft, .topMiddle, .topRight:
            newY = screenHeight - notifSize.height - padding
        case .middleLeft, .middleRight, .deadCenter:
            newY = (screenHeight - notifSize.height) / 2
        case .bottomLeft, .bottomMiddle, .bottomRight:
            newY = dockSize + 30  // paddingAboveDock constant
        }

        return (newX, newY)
    }
}
```

**Replace in NotificationMover:**
- `calculateNewPosition(notifSize:, padding:)` → `NotificationPositioningService.shared.calculatePosition(...)`

**Lines to Remove:** ~30 lines (lines ~2472-2497)

---

### **Priority 3: Extract Window Monitor Service** (~200 lines)

**What to Extract:**
- `setupNotificationCenterObserver()` - Setup AX observer
- `setupGlobalWindowMonitoring()` - Global window polling
- `buildKnownWindowSet()` - Build initial window set
- `detectNewNotificationWindows()` - Poll for new windows
- `getAXElementForWindow()` - Map window number to AX element
- `scanAllWindowsForNotifications()` - Scan all visible windows

**Create:** `Managers/WindowMonitorService.swift`

```swift
/// Monitors for notification windows across all apps
@available(macOS 10.15, *)
class WindowMonitorService {

    static let shared = WindowMonitorService()

    private var globalWindowMonitorTimer: Timer?
    private var knownWindowNumbers: Set<Int> = []
    private var appObservers: [pid_t: AXObserver] = [:]

    private let notificationCenterBundleID = "com.apple.notificationcenterui"
    private let widgetIdentifierPrefix = "widget-local:"
    private let osVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion

    private weak var notificationMover: NotificationMover?

    private init() {}

    func setNotificationMover(_ mover: NotificationMover) {
        self.notificationMover = mover
    }

    /// Starts monitoring all windows for new notifications
    func startMonitoring() {
        buildKnownWindowSet()

        globalWindowMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] in
            self?.detectNewNotificationWindows()
        }
    }

    /// Stops monitoring
    func stopMonitoring() {
        globalWindowMonitorTimer?.invalidate()
        appObservers.values.forEach { CFRunLoopRemoveSource(AXObserverGetRunLoopSource($0, .defaultMode) }
        appObservers.removeAll()
        knownWindowNumbers.removeAll()
    }

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
    }

    /// Detects new notification windows
    private func detectNewNotificationWindows() {
        // From line 2242 (detectNewNotificationWindows)
        // Polls for new windows matching notification size constraints
        // Calls moveExternalNotificationWindow for each new notification found
    }

    /// Gets AX element for a window number
    func getAXElementForWindow(windowNumber: Int) -> AXUIElement? {
        // From line 2005 (getAXElementForWindow)
        // Maps window CGWindowNumber to AXUIElement
    }
}
```

**Replace in NotificationMover:**
- Remove monitoring methods (~200 lines)
- Create `WindowMonitorService.shared.setNotificationMover(self)`
- Call `WindowMonitorService.shared.startMonitoring()`

---

### **Priority 4: Extract Widget Monitor Service** (~100 lines)

**What to Extract:**
- `checkForWidgetChanges()` - Monitor Notification Center state
- `hasNotificationCenterUI()` - Check if NC UI is visible
- `findElementWithWidgetIdentifier()` - Find widget panels
- `widgetMonitorTimer` - Polling timer

**Create:** `Managers/WidgetMonitorService.swift`

```swift
/// Monitors Notification Center widget panel visibility
@available(macOS 10.15, *)
class WidgetMonitorService {

    static let shared = WidgetMonitorService()

    private var widgetMonitorTimer: Timer?
    private var lastWidgetWindowCount: Int = 0
    private var pollingEndTime: Date?

    private let notificationCenterBundleID = "com.apple.notificationcenterui"
    private let widgetIdentifierPrefix: "widget-local:"

    private weak var notificationMover: NotificationMover?

    private init() {}

    func setNotificationMover(_ mover: NotificationMover) {
        self.notificationMover = mover
    }

    /// Starts monitoring widget panel visibility
    func startMonitoring(pollingDuration: TimeInterval = 6.5) {
        pollingEndTime = Date().addingTimeInterval(pollingDuration)

        widgetMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] in
            self?.checkForWidgetChanges()
        }
    }

    /// Stops monitoring
    func stopMonitoring() {
        widgetMonitorTimer?.invalidate()
        pollingEndTime = nil
    }

    /// Checks if Notification Center UI is visible
    func hasNotificationCenterUI() -> Bool {
        guard let pid = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else { return false }

        let app = AXUIElementCreateApplication(pid)
        return findElementWithWidgetIdentifier(root: app) != nil
    }

    /// Finds widget panel by identifier
    private func findElementWithWidgetIdentifier(root: AXUIElement) -> AXUIElement? {
        // From line 2428 (findElementWithWidgetIdentifier)
        // Searches for elements with "widget-local:" prefix
    }

    /// Checks for widget state changes
    private func checkForWidgetChanges() {
        guard let pollingEnd = pollingEndTime, Date() < pollingEnd else { return }

        let hasNCUI = hasNotificationCenterUI()
        let currentNCState = hasNCUI ? 1 : 0

        if lastWidgetWindowCount != currentNCState {
            notificationMover?.moveAllNotifications()
        }

        lastWidgetWindowCount = currentNCState
    }
}
```

**Replace in NotificationMover:**
- Remove widget monitoring code (~100 lines)
- Create `WidgetMonitorService.shared.setNotificationMover(self)`
- Call `WidgetMonitorService.shared.startMonitoring(pollingDuration: 6.5)`

---

## 📊 PHASE 2 SUMMARY

| Priority | Service | Lines | New File | Reused? |
|----------|---------|-------|----------|----------|
| 1 | **AXElementManager** | ~300 | `Managers/AXElementManager.swift` | ❌ No |
| 2 | **NotificationPositioningService** | ~150 | `Managers/NotificationPositioningService.swift` | ❌ No |
| 3 | **WindowMonitorService** | ~200 | `Managers/WindowMonitorService.swift` | ❌ No |
| 4 | **WidgetMonitorService** | ~100 | `Managers/WidgetMonitorService.swift` | ❌ No |

---

## 🎯 WHAT NOT TO TOUCH (Already Extracted)

| Component | Location | Status |
|-----------|----------|--------|
| MenuBar Icon management | `IconManager.swift` | ✅ Complete |
| Settings UI | `SettingsWindow.swift` | ✅ Complete |
| Permission UI | `PermissionWindow.swift` | ✅ Complete |
| Diagnostic Window | `PermissionWindow.swift` | ✅ Complete |
| Settings UI components | `SettingsWindow.swift` | ✅ Complete |
| Permission UI components | `PermissionWindow.swift` | ✅ Complete |

---

## 📈 EXPECTED RESULTS

**Before:** 2797 lines
**After Phase 2:** ~2200 lines (removing ~600 lines)

**Services Created:** 4 new manager classes
**Lines Extracted:** ~750 lines (27%)

---

## 🚀 READY FOR PHASE 3

After Phase 2, remaining work:
- Notification discovery logic (~400 lines)
- Element tree traversal (~200 lines)
- Diagnostic tools (~150 lines)
- Application lifecycle methods (~50 lines)

Would you like me to proceed with creating these 4 services?
