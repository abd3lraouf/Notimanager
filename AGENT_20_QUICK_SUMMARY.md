# AGENT 20: COORDINATOR DESIGN - QUICK SUMMARY

## THE MISSION
Design a slim NotificationMoverCoordinator (~150 lines) that delegates all work to services.

---

## WHAT STAYS IN COORDINATOR

```swift
final class NotificationMoverCoordinator {

    // Dependencies (injected)
    private let configurationManager: ConfigurationManager
    private let accessibilityManager: AccessibilityManager
    private let positioningService: NotificationPositioningService
    private let windowMonitor: WindowMonitorService
    private let widgetMonitor: WidgetMonitorService
    private let logger: LoggingService

    // UI references only (no construction code)
    private var permissionWindow: PermissionWindow?
    private var settingsWindow: SettingsWindow?
    private var statusItem: NSStatusItem?

    // MARK: - App Lifecycle (~40 lines)
    func applicationDidFinishLaunching(_ notification: Notification)
    func applicationWillBecomeActive(_ notification: Notification)
    func applicationWillTerminate(_ notification: Notification)

    // MARK: - Permission Coordination (~25 lines)
    private func checkAccessibilityPermissions()
    private func requestNotificationPermissions()

    // MARK: - Service Coordination (~20 lines)
    private func startAllServices()
    private func stopAllServices()

    // MARK: - Notification Movement (~15 lines)
    func moveAllNotifications()
    func moveNotification(_ element: AXUIElement, size: CGSize)

    // MARK: - Configuration (~20 lines)
    func configurationDidChange(_ event: ConfigurationManager.ConfigurationEvent)
}
```

---

## WHAT GETS EXTRACTED

| From NotificationMover | To | Service/Class |
|------------------------|-----|---------------|
| Permission checking | → | `AccessibilityManager` ✅ (exists) |
| Position calculation | → | `NotificationPositioningService` ✅ (exists) |
| AX element operations | → | `AXElementManager` ✅ (exists) |
| Window monitoring | → | `WindowMonitorService` ✅ (exists) |
| Widget monitoring | → | `WidgetMonitorService` ✅ (exists) |
| Debug logging | → | `LoggingService` ✅ (exists) |
| Configuration | → | `ConfigurationManager` ✅ (exists) |
| Permission UI | → | `PermissionWindow` ✅ (exists) |
| Settings UI | → | `SettingsWindow` ✅ (exists) |
| Menu bar code | → | `MenuBarManager` ⚠️ (needs creation) |
| Launch agent code | → | `LaunchAgentManager` ⚠️ (needs creation) |

---

## NEW CLASSES TO CREATE

### 1. MenuBarManager (~50 lines)
```swift
class MenuBarManager {
    private weak var coordinator: CoordinatorAction?
    private var statusItem: NSStatusItem?

    func setup(coordinator: CoordinatorAction)
    func buildMenu()
    func updateMenuState()

    // Menu actions
    @objc func showSettings()
    @objc func toggleEnabled()
    @objc func quit()
}
```

### 2. LaunchAgentManager (~30 lines)
```swift
class LaunchAgentManager {
    private let plistPath: String

    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool)
    private func createPlist()
    private func removePlist()
}
```

---

## COORDINATION FLOWS

### App Startup
```
applicationDidFinishLaunching
  → logSystemInfo
  → requestNotificationPermissions (UNUserNotificationCenter)
  → [0.5s delay]
  → checkAccessibilityPermissions
    → granted: startAllServices → moveAllNotifications
    → denied: showPermissionWindow
```

### Notification Detected
```
WindowMonitorService detects window
  → getAXElementForWindow
  → coordinator.moveNotification(element, size)
  → positioningService.calculatePosition
  → positioningService.applyPosition
  → AXElementManager.setPosition
```

### Configuration Change
```
User changes position
  → configurationManager.currentPosition = .newPosition
  → didSet → notifyObservers
  → coordinator.configurationDidChange(.positionChanged)
  → moveAllNotifications
```

---

## LINE COUNT TARGET

**Current NotificationMover:** ~1500 lines
**Target Coordinator:** ~150 lines

### Breakdown of 150 lines:
- Dependencies & init: 20 lines
- App lifecycle: 40 lines
- Permission coordination: 25 lines
- Service coordination: 20 lines
- Notification movement: 15 lines
- Configuration handling: 20 lines
- Extensions: 10 lines

---

## DEPENDENCY INJECTION

```swift
// Production (use singletons)
let coordinator = NotificationMoverCoordinator(
    configurationManager: .shared,
    accessibilityManager: .shared,
    positioningService: .shared,
    windowMonitor: .shared,
    widgetMonitor: .shared,
    logger: .shared
)

// Testing (inject mocks)
let coordinator = NotificationMoverCoordinator(
    configurationManager: mockConfig,
    accessibilityManager: mockAccessibility,
    positioningService: mockPositioning,
    windowMonitor: mockWindowMonitor,
    widgetMonitor: mockWidgetMonitor,
    logger: mockLogger
)
```

---

## TESTING APPROACH

```swift
class NotificationMoverCoordinatorTests: XCTestCase {
    func testStart_GrantedPermission_StartsServices() {
        // Given
        mockAccessibility.permissionGranted = true

        // When
        coordinator.applicationDidFinishLaunching(...)

        // Then
        XCTAssertTrue(mockWindowMonitor.started)
        XCTAssertTrue(mockWidgetMonitor.started)
    }

    func testPositionChanged_MovesNotifications() {
        // When
        coordinator.updatePosition(to: .bottomRight)

        // Then
        XCTAssertEqual(mockPositioningService.callCount, 1)
    }
}
```

---

## IMPLEMENTATION ORDER

1. ✅ Phase 1: Extract services (DONE - Agents 01-19)
2. ⏳ Phase 2: Extract UI (DONE - Agents 01-19)
3. 🔄 Phase 3: Create supporting classes
   - Agent 21: MenuBarManager
   - Agent 22: LaunchAgentManager
4. ⏳ Phase 4: Create coordinator
   - Agent 23: Create CoordinatorAction protocol
   - Agent 24: Update views to use protocol
   - Agent 25: Implement NotificationMoverCoordinator
   - Agent 26: Update main.swift
5. ⏳ Phase 5: Testing & polish
   - Agent 27: Integration tests
   - Agent 28: Performance profiling

---

## KEY DESIGN DECISIONS

| Decision | Rationale |
|----------|-----------|
| Keep singletons | Simple, sufficient for app size |
| Constructor injection | Testable without DI framework |
| No Combine | Observer pattern is simpler |
| Protocol-based views | Clear interface, testable |
| Pure coordinator | Easy to understand, maintain |

---

## FILES TO MODIFY

### New Files
- `/Notimanager/Managers/MenuBarManager.swift`
- `/Notimanager/Managers/LaunchAgentManager.swift`
- `/Notimanager/Protocols/CoordinatorAction.swift`
- `/Notimanager/Coordinators/NotificationMoverCoordinator.swift`

### Modified Files
- `/Notimanager/main.swift` (use coordinator)
- `/Notimanager/Views/PermissionWindow.swift` (use protocol)
- `/Notimanager/Views/SettingsWindow.swift` (use protocol)

### Deleted Files
- `/Notimanager/Managers/NotificationMover.swift` (replaced by coordinator)

---

## SUCCESS METRICS

✅ Line count: ≤ 150 lines
✅ Compilation: No errors
✅ Tests: All pass
✅ Functionality: Identical to current app
✅ Performance: No regressions
✅ Code review: Approved by Squad Manager

---

**STATUS: ✅ DESIGN COMPLETE**
**NEXT: Agent 21 - Implement MenuBarManager**
