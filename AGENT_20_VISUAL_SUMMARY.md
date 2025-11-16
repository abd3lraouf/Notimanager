# AGENT 20: COORDINATOR DESIGN - VISUAL SUMMARY

## ARCHITECTURE DIAGRAM

```
┌─────────────────────────────────────────────────────────────────┐
│                         Notimanager App                         │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              NotificationMoverCoordinator               │   │
│  │                    (~150 lines)                         │   │
│  │                                                           │   │
│  │  Responsibilities:                                       │   │
│  │  • Application lifecycle                                 │   │
│  │  • Service coordination                                  │   │
│  │  • UI delegation                                         │   │
│  │  • Event routing                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│         ┌────────────────────┼────────────────────┐            │
│         │                    │                    │            │
│         ▼                    ▼                    ▼            │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐   │
│  │   Views     │      │  Services   │      │  Managers   │   │
│  └─────────────┘      └─────────────┘      └─────────────┘   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## COORDINATOR STRUCTURE

```
NotificationMoverCoordinator
│
├── Dependencies (Injected)
│   ├── ConfigurationManager
│   ├── AccessibilityManager
│   ├── NotificationPositioningService
│   ├── WindowMonitorService
│   ├── WidgetMonitorService
│   ├── LoggingService
│   ├── MenuBarManager
│   └── LaunchAgentManager
│
├── UI References (No construction)
│   ├── permissionWindow: PermissionWindow?
│   ├── settingsWindow: SettingsWindow?
│   └── (menu bar managed by MenuBarManager)
│
├── Application Lifecycle (~40 lines)
│   ├── applicationDidFinishLaunching()
│   ├── applicationWillBecomeActive()
│   └── applicationWillTerminate()
│
├── Permission Management (~25 lines)
│   ├── checkAccessibilityPermissions()
│   └── requestNotificationPermissions()
│
├── Service Coordination (~20 lines)
│   ├── startAllServices()
│   └── stopAllServices()
│
├── Notification Movement (~15 lines)
│   ├── moveAllNotifications()
│   └── moveNotification(_:size:)
│
└── Configuration Handling (~20 lines)
    └── configurationDidChange(_:)
```

---

## SERVICE ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                            │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │  Configuration   │  │   Accessibility  │                │
│  │     Manager      │  │     Manager      │                │
│  │                  │  │                  │                │
│  │  • State         │  │  • Permissions   │                │
│  │  • Persistence   │  │  • Trust check   │                │
│  │  • Observers     │  │  • Requests      │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Positioning      │  │  AX Element      │                │
│  │   Service        │  │    Manager       │                │
│  │                  │  │                  │                │
│  │  • Calculate     │  │  • Get/Set Pos   │                │
│  │  • Validate      │  │  • Get Size      │                │
│  │  • Apply         │  │  • Find Elements │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Window Monitor   │  │  Widget Monitor  │                │
│  │   Service        │  │    Service       │                │
│  │                  │  │                  │                │
│  │  • Detect windows│  │  • Detect NC UI  │                │
│  │  • Track state   │  │  • Poll changes  │                │
│  │  • Callbacks     │  │  • Callbacks     │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │   Logging        │  │  Menu Bar        │                │
│  │   Service        │  │  Manager         │                │
│  │                  │  │                  │                │
│  │  • Debug logs    │  │  • Status item   │                │
│  │  • Diagnostic    │  │  • Menu          │                │
│  │  • System info   │  │  • Actions       │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                              │
│  ┌──────────────────┐                                       │
│  │ Launch Agent     │                                       │
│  │    Manager       │                                       │
│  │                  │                                       │
│  │  • Enable/Disable│                                       │
│  │  • Plist mgmt    │                                       │
│  │  • launchctl     │                                       │
│  └──────────────────┘                                       │
└──────────────────────────────────────────────────────────────┘
```

---

## DATA FLOW DIAGRAMS

### 1. App Startup Flow

```
User launches app
       │
       ▼
applicationDidFinishLaunching
       │
       ├─► logSystemInfo()
       │
       ├─► requestNotificationPermissions()
       │       (UNUserNotificationCenter)
       │
       └─► [0.5s delay]
               │
               ▼
       checkAccessibilityPermissions()
               │
       ┌───────┴───────┐
       │               │
  Granted          Denied
       │               │
       ▼               ▼
startAllServices()  showPermissionWindow()
       │               │
       ▼           User grants
moveAllNotifications()  permission
                          │
                          ▼
              User clicks "Restart App"
                          │
                          ▼
                  NSApp.terminate()
```

### 2. Notification Detection Flow

```
System notification appears
       │
       ▼
WindowMonitorService
(global window scan)
       │
       ├─► Detects new window
       │   (CGWindowListCopyWindowInfo)
       │
       ├─► Filters by size
       │   (200-800px wide, 60-200px tall)
       │
       ├─► Gets AXUIElement
       │   (getAXElementForWindow)
       │
       ├─► Coordinator.moveNotification()
       │       │
       │       ▼
       │   positioningService.calculatePosition()
       │       │
       │       ▼
       │   positioningService.applyPosition()
       │       │
       │       ▼
       └───────► AXElementManager.setPosition()
                   │
                   ▼
           Notification moved!
```

### 3. Configuration Change Flow

```
User changes position in Settings
       │
       ▼
SettingsWindow.positionChanged()
       │
       ▼
coordinator.updatePosition(to: .newPosition)
       │
       ▼
configurationManager.currentPosition = .newPosition
       │
       ▼
didSet {
    saveToStorage()
    notifyObservers(.positionChanged)
}
       │
       ▼
coordinator.configurationDidChange(.positionChanged)
       │
       ▼
moveAllNotifications()
       │
       ▼
windowMonitor.scanAllWindowsForNotifications()
       │
       └──► All notifications moved!
```

---

## COMPARISON: BEFORE vs AFTER

### BEFORE (NotificationMover)

```
┌─────────────────────────────────────────┐
│        NotificationMover                │
│           (~1500 lines)                 │
│                                          │
│  ❌ Everything in one class             │
│  ❌ UI construction mixed with logic    │
│  ❌ Direct AX API calls                 │
│  ❌ Hard-coded dependencies             │
│  ❌ Difficult to test                   │
│                                          │
│  Contains:                              │
│  • Permission UI (200+ lines)           │
│  • Settings UI (400+ lines)             │
│  • Menu bar code (100+ lines)           │
│  • Position logic (150+ lines)          │
│  • AX operations (200+ lines)           │
│  • Window monitoring (150+ lines)       │
│  • Widget monitoring (100+ lines)       │
│  • Launch agent (100+ lines)            │
│  • Permission checks (100+ lines)       │
│  • App lifecycle (50+ lines)            │
└─────────────────────────────────────────┘
```

### AFTER (Coordinator + Services)

```
┌─────────────────────────────────────────┐
│   NotificationMoverCoordinator          │
│          (~150 lines)                   │
│                                          │
│  ✅ Pure coordination                   │
│  ✅ UI delegated to views               │
│  ✅ Logic delegated to services         │
│  ✅ Dependency injection                │
│  ✅ Easy to test                        │
│                                          │
│  Contains:                              │
│  • App lifecycle (40 lines)             │
│  • Permission coordination (25 lines)   │
│  • Service coordination (20 lines)      │
│  • Notification routing (15 lines)      │
│  • Configuration handling (20 lines)    │
│  • UI delegation (30 lines)             │
└─────────────────────────────────────────┘
           │
           │ delegates to
           ▼
┌─────────────────────────────────────────┐
│         Services & Views                │
│                                          │
│  Services:                               │
│  • ConfigurationManager                 │
│  • AccessibilityManager                 │
│  • NotificationPositioningService       │
│  • AXElementManager                     │
│  • WindowMonitorService                 │
│  • WidgetMonitorService                 │
│  • LoggingService                       │
│  • MenuBarManager                       │
│  • LaunchAgentManager                   │
│                                          │
│  Views:                                  │
│  • PermissionWindow                     │
│  • SettingsWindow                       │
│  • Components (reusable)                │
└─────────────────────────────────────────┘
```

---

## KEY IMPROVEMENTS

| Aspect | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Line Count** | 1500+ | 150 | **90% reduction** |
| **Testability** | Low (singletons) | High (DI) | **100% testable** |
| **Maintainability** | Low (monolithic) | High (modular) | **Easy changes** |
| **Reusability** | None | High (services) | **Reusable services** |
| **Separation** | Mixed concerns | Clear layers | **Clean architecture** |
| **Dependencies** | Hard-coded | Injected | **Flexible** |

---

## FILE STRUCTURE

```
Notimanager/
├── Coordinators/
│   └── NotificationMoverCoordinator.swift    (NEW, ~150 lines)
│
├── Managers/
│   ├── ConfigurationManager.swift            (EXISTS, ✅)
│   ├── AccessibilityManager.swift            (EXISTS, ✅)
│   ├── NotificationPositioningService.swift (EXISTS, ✅)
│   ├── AXElementManager.swift               (EXISTS, ✅)
│   ├── WindowMonitorService.swift           (EXISTS, ✅)
│   ├── WidgetMonitorService.swift           (EXISTS, ✅)
│   ├── LoggingService.swift                 (EXISTS, ✅)
│   ├── MenuBarManager.swift                 (NEW, ~80 lines)
│   └── LaunchAgentManager.swift             (NEW, ~100 lines)
│
├── Protocols/
│   ├── NotificationMoverProtocols.swift     (EXISTS, ✅)
│   ├── CoordinatorAction.swift              (NEW, ~60 lines)
│   └── MonitorDelegate.swift                (NEW, ~20 lines)
│
├── Views/
│   ├── PermissionWindow.swift               (EXISTS, ✅)
│   ├── SettingsWindow.swift                 (EXISTS, ✅)
│   └── Components/
│       ├── PositionGridButton.swift         (EXISTS, ✅)
│       └── ThemePicker.swift                (EXISTS, ✅)
│
└── Models/
    └── NotificationPosition.swift           (EXISTS, ✅)
```

---

## MIGRATION CHECKLIST

### Phase 1: Create New Classes (Agents 21-24)
- [ ] Agent 21: Create MenuBarManager
- [ ] Agent 22: Create LaunchAgentManager
- [ ] Agent 23: Create CoordinatorAction protocol
- [ ] Agent 24: Create MonitorDelegate protocol

### Phase 2: Create Coordinator (Agent 25)
- [ ] Agent 25: Create NotificationMoverCoordinator
- [ ] Agent 25: Implement CoordinatorAction protocol
- [ ] Agent 25: Implement MonitorDelegate protocol
- [ ] Agent 25: Test with mocks

### Phase 3: Update App (Agents 26-27)
- [ ] Agent 26: Update main.swift to use coordinator
- [ ] Agent 26: Update views to use CoordinatorAction
- [ ] Agent 26: Update monitors to use MonitorDelegate
- [ ] Agent 27: Integration testing

### Phase 4: Remove Old Code (Agent 28)
- [ ] Agent 28: Delete NotificationMover.swift
- [ ] Agent 28: Performance profiling
- [ ] Agent 28: Final testing

---

## SUCCESS CRITERIA

✅ **Functionality**
- All features work identically to current app
- No regressions in notification positioning
- Permission flow works correctly
- Settings changes apply immediately

✅ **Code Quality**
- Line count ≤ 150 for coordinator
- No compilation errors or warnings
- All services properly injected
- Clear separation of concerns

✅ **Testing**
- Unit tests for coordinator (80%+ coverage)
- Integration tests for flows
- Mock implementations for all dependencies

✅ **Performance**
- No performance regressions
- Memory usage unchanged or better
- Startup time unchanged or better

---

**STATUS: ✅ DESIGN COMPLETE**
**NEXT: Agent 21 - Implement MenuBarManager**
