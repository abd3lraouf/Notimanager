# NOTIMANAGER ARCHITECTURE MIGRATION PLAN
## From Monolithic NotificationMover to Service-Based Architecture

**Agent:** Agent 19
**Date:** 2025-01-15
**Current State:** Monolithic NotificationMover (3013 lines)
**Target State:** Service-based architecture with dependency injection

---

## EXECUTIVE SUMMARY

This migration plan provides a phased approach to refactor the monolithic `NotificationMover.swift` (3013 lines) into a clean, service-based architecture. The migration ensures **zero downtime** - the app continues working throughout the process.

**Current Architecture Analysis:**
- Single `NotificationMover` class handling 13+ responsibilities
- Mixed UI, business logic, and system integration
- Tightly coupled dependencies
- Difficult to test and maintain

**Target Architecture:**
- 8 focused services with single responsibilities
- Protocol-based abstractions
- Dependency injection container
- Testable components
- Clean separation of concerns

**Migration Strategy:** **Incremental extraction with backward compatibility**

---

## MIGRATION OVERVIEW

```
PHASE 0: PREPARATION           (Est. 30 min)    Complexity: LOW
PHASE 1: PROTOCOL DEFINITION    (Est. 1 hr)     Complexity: LOW
PHASE 2: CORE SERVICES          (Est. 3 hrs)    Complexity: MEDIUM
PHASE 3: BUSINESS LOGIC         (Est. 4 hrs)    Complexity: MEDIUM-HIGH
PHASE 4: UI LAYER               (Est. 3 hrs)    Complexity: MEDIUM
PHASE 5: PERMISSIONS            (Est. 1 hr)     Complexity: LOW
PHASE 6: COORDINATION           (Est. 2 hrs)    Complexity: MEDIUM
PHASE 7: CLEANUP                (Est. 2 hrs)    Complexity: MEDIUM

TOTAL TIME: ~16 hours (spread across 2-3 days)
RISK LEVEL: LOW (incremental with rollback capability)
```

---

## PHASE 0: PREPARATION

**Objective:** Set up infrastructure for migration

**Estimated Time:** 30 minutes
**Complexity:** LOW
**Risk:** NONE (no code changes)

### Tasks

#### 0.1 Create Service Folder Structure
```bash
# Create organized folder structure
Notimanager/
├── Services/
│   ├── Core/
│   ├── Business/
│   ├── UI/
│   └── Coordination/
```

**Verification:**
- [ ] Folders created
- [ ] Xcode project updated with new groups
- [ ] Build succeeds (no changes yet)

#### 0.2 Create Empty Protocol Files
Create placeholder files for all protocols:

```
Protocols/
├── NotificationPositioning.swift (already exists - verify)
├── AccessibilityElementHandling.swift (already exists - verify)
├── NotificationWindowTracking.swift (already exists - verify)
├── AccessibilityPermissionManaging.swift (already exists - verify)
├── NotificationDiscovery.swift (already exists - verify)
```

**Verification:**
- [ ] All protocol files exist
- [ ] No compilation errors
- [ ] Protocols match NotificationMoverProtocols.swift

#### 0.3 Create Test Infrastructure
```swift
// Tests/MigrationTests/MigrationVerificationTests.swift
// Verify app functionality after each phase
```

**Verification:**
- [ ] Test file created
- [ ] Test target compiles
- [ ] Baseline tests pass

#### 0.4 Document Current State
Create `PRE_MIGRATION_STATE.md` documenting:
- Current NotificationMover public API
- All dependencies and their usage
- Critical integration points
- Test coverage gaps

**Verification:**
- [ ] Documentation complete
- [ ] Review with team

---

## PHASE 1: PROTOCOL DEFINITION

**Objective:** Define all service protocols with clear contracts

**Estimated Time:** 1 hour
**Complexity:** LOW
**Risk:** NONE (additive changes only)

### Tasks

#### 1.1 Define Notification Detection Service Protocol
```swift
// Protocols/NotificationDetectionServiceProtocol.swift

protocol NotificationDetectionServiceProtocol {
    func startMonitoring()
    func stopMonitoring()
    var isMonitoring: Bool { get }
    func onNotificationDetected(_ callback: @escaping (NotificationWindow) -> Void)
}
```

**Verification:**
- [ ] Protocol compiles
- [ ] Protocol methods cover all NotificationMover detection needs
- [ ] Documentation complete

#### 1.2 Define Positioning Service Protocol
```swift
// Protocols/NotificationPositioningServiceProtocol.swift

protocol NotificationPositioningServiceProtocol {
    func calculatePosition(
        notifSize: CGSize,
        padding: CGFloat,
        currentPosition: NotificationPosition,
        screenBounds: CGRect
    ) -> CGPoint

    func validatePosition(
        _ position: CGPoint,
        for notifSize: CGSize,
        in screenBounds: CGRect
    ) -> Bool

    func applyPosition(to element: AXUIElement, at position: CGPoint) -> Bool
}
```

**Verification:**
- [ ] Protocol compiles
- [ ] Matches existing NotificationPositioningService interface
- [ ] All positioning scenarios covered

#### 1.3 Define Permission Service Protocol
```swift
// Protocols/AccessibilityPermissionServiceProtocol.swift

protocol AccessibilityPermissionServiceProtocol {
    var permissionStatus: PermissionStatus { get }
    func checkPermissions() -> Bool
    func requestPermissions(showPrompt: Bool) -> Bool
    func resetPermissions() throws
    func observePermissionChanges(_ callback: @escaping (PermissionStatus) -> Void)
}
```

**Verification:**
- [ ] Protocol compiles
- [ ] Covers all permission scenarios in NotificationMover
- [ ] Observer pattern defined

#### 1.4 Define MenuBar Service Protocol
```swift
// Protocols/MenuBarServiceProtocol.swift

protocol MenuBarServiceProtocol {
    func setupStatusItem()
    func updateMenu()
    func showIcon(_ show: Bool)
    var isVisible: Bool { get }
}
```

**Verification:**
- [ ] Protocol compiles
- [ ] Covers all menu bar functionality
- [ ] Show/hide behavior defined

#### 1.5 Define Settings Service Protocol
```swift
// Protocols/SettingsServiceProtocol.swift

protocol SettingsServiceProtocol {
    func showSettings()
    func showPermissionWindow()
    func showDiagnostics()
}
```

**Verification:**
- [ ] Protocol compiles
- [ ] All window management covered

#### 1.6 Verify Protocol Coverage
Review NotificationMover.swift and ensure:
- [ ] Every public method has a corresponding protocol
- [ ] No missing abstractions
- [ ] Protocols are composable

**Backward Compatibility:**
- [ ] Existing NotificationMover unchanged
- [ ] App continues to work normally

---

## PHASE 2: CORE SERVICES

**Objective:** Extract low-level infrastructure services

**Estimated Time:** 3 hours
**Complexity:** MEDIUM
**Risk:** LOW (services are already extracted as singletons)

### Note: Several core services already exist as singletons:
- `AXElementManager` - AX element operations
- `LoggingService` - Debug and diagnostic logging
- `ConfigurationManager` - Settings persistence
- `NotificationPositioningService` - Position calculations
- `AccessibilityManager` - VoiceOver and accessibility
- `WidgetMonitorService` - Widget panel monitoring
- `WindowMonitorService` - Global window monitoring

#### 2.1 Verify AXElementManager Completeness
**Current State:** Already extracted as singleton

**Tasks:**
- [ ] Verify all AX operations from NotificationMover are in AXElementManager
- [ ] Check for missing methods:
  - [ ] `getPosition(of:)` - ✓ exists
  - [ ] `getSize(of:)` - ✓ exists
  - [ ] `setPosition(of:x:y:)` - ✓ exists
  - [ ] `findElementBySubrole()` - ✓ exists
  - [ ] `findElementUsingFallbacks()` - ✓ exists
  - [ ] `findElementByIdentifier()` - ✓ exists
  - [ ] `findElementByRoleAndSize()` - ✓ exists
  - [ ] `findDeepestSizedElement()` - ✓ exists
  - [ ] `findAnyElementWithSize()` - ✓ exists

**Verification:**
- [ ] All NotificationMover AX methods have equivalents
- [ ] No AX code remains in NotificationMover that should be extracted
- [ ] Tests pass

#### 2.2 Verify LoggingService Integration
**Current State:** Already extracted as singleton

**Tasks:**
- [ ] Replace all `debugLog()` calls in NotificationMover with `LoggingService.shared.debug()`
- [ ] Update diagnostic window to use `LoggingService.shared.diagnosticTextView`
- [ ] Remove `logger` property from NotificationMover
- [ ] Remove `debugMode` property (use LoggingService.shared.isDebugModeEnabled)

**Code Changes:**
```swift
// BEFORE (in NotificationMover)
private let logger: Logger = .init(subsystem: "dev.abd3lraouf.notimanager", category: "NotificationMover")
fileprivate func debugLog(_ message: String) {
    guard debugMode else { return }
    logger.info("\(message, privacy: .public)")
}

// AFTER (using LoggingService)
LoggingService.shared.debug(message)
```

**Verification:**
- [ ] All debugLog() calls replaced
- [ ] Logger property removed
- [ ] Debug mode managed by LoggingService
- [ ] Logs appear in Console.app
- [ ] Diagnostic window output works

**Rollback Plan:**
Keep old `debugLog()` method as passthrough for one phase:
```swift
fileprivate func debugLog(_ message: String) {
    LoggingService.shared.debug(message)
}
```

#### 2.3 Verify ConfigurationManager Usage
**Current State:** Already extracted as singleton

**Tasks:**
- [ ] Replace UserDefaults reads with ConfigurationManager.shared
- [ ] Replace UserDefaults writes with ConfigurationManager.shared
- [ ] Remove UserDefaults direct access from NotificationMover
- [ ] Update all settings references

**Code Changes:**
```swift
// BEFORE
var currentPosition: NotificationPosition = {
    guard let rawValue = UserDefaults.standard.string(forKey: "notificationPosition"),
          let position = NotificationPosition(rawValue: rawValue)
    else { return .topMiddle }
    return position
}()

// AFTER
var currentPosition: NotificationPosition {
    get { return ConfigurationManager.shared.currentPosition }
    set {
        currentPosition = newValue
        ConfigurationManager.shared.currentPosition = newValue
    }
}
```

**Verification:**
- [ ] All UserDefaults access replaced
- [ ] Settings persist correctly
- [ ] Settings load on startup
- [ ] Configuration observers work

#### 2.4 Create NotificationCache Service
**New service to manage notification state**

```swift
// Services/Core/NotificationCacheService.swift

class NotificationCacheService {
    static let shared = NotificationCacheService()

    private init() {}

    // Cache initial notification data
    var cachedInitialNotifSize: CGSize?
    var cachedInitialPadding: CGFloat?
    var cachedInitialWindowPosition: CGPoint?

    func cacheInitialNotificationData(notifSize: CGSize, padding: CGFloat) {
        cachedInitialNotifSize = notifSize
        cachedInitialPadding = padding
        LoggingService.shared.debug("Cached initial data - size: \(notifSize), padding: \(padding)")
    }

    func validateCache(against newSize: CGSize) -> Bool {
        guard let existingSize = cachedInitialNotifSize else {
            return false
        }

        if existingSize != newSize {
            LoggingService.shared.debug("Cache size mismatch - clearing")
            clearCache()
            return false
        }

        return true
    }

    func clearCache() {
        cachedInitialNotifSize = nil
        cachedInitialPadding = nil
        cachedInitialWindowPosition = nil
    }
}
```

**Verification:**
- [ ] Service compiles
- [ ] Cache logic works correctly
- [ ] NotificationMover uses NotificationCacheService
- [ ] Old cache properties removed from NotificationMover

#### 2.5 Create LaunchAgent Service
**Extract launch-at-login management**

```swift
// Services/Core/LaunchAgentService.swift

class LaunchAgentService {
    static let shared = LaunchAgentService()

    private let plistPath: String
    private let bundleExecutable: String

    private init() {
        self.plistPath = NSHomeDirectory() + "/Library/LaunchAgents/dev.abd3lraouf.notimanager.plist"
        self.bundleExecutable = Bundle.main.executablePath ?? ""
    }

    var isEnabled: Bool {
        return FileManager.default.fileExists(atPath: plistPath)
    }

    func enable() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>dev.abd3lraouf.notimanager</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(bundleExecutable)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """

        try plistContent.write(toFile: plistPath, atomically: true, encoding: .utf8)
        LoggingService.shared.debug("Launch at login enabled")
    }

    func disable() throws {
        try FileManager.default.removeItem(atPath: plistPath)
        LoggingService.shared.debug("Launch at login disabled")
    }
}
```

**Verification:**
- [ ] Service compiles
- [ ] Can enable/disable launch at login
- [ ] Status checking works
- [ ] NotificationMover uses LaunchAgentService

**Backward Compatibility:**
- [ ] App continues to work
- [ ] Launch at login functions normally
- [ ] Settings UI updates correctly

---

## PHASE 3: BUSINESS LOGIC SERVICES

**Objective:** Extract notification movement and detection logic

**Estimated Time:** 4 hours
**Complexity:** MEDIUM-HIGH
**Risk:** MEDIUM (core functionality extraction)

### Tasks

#### 3.1 Create NotificationMovementService
**Extract the core `moveNotification()` logic**

```swift
// Services/Business/NotificationMovementService.swift

class NotificationMovementService {

    // MARK: - Dependencies
    private let positioningService: NotificationPositioningService
    private let axElementManager: AXElementManager
    private let cacheService: NotificationCacheService
    private let configManager: ConfigurationManager
    private let logger: LoggingService

    // Inject dependencies for testability
    init(
        positioningService: NotificationPositioningService = .shared,
        axElementManager: AXElementManager = .shared,
        cacheService: NotificationCacheService = .shared,
        configManager: ConfigurationManager = .shared,
        logger: LoggingService = .shared
    ) {
        self.positioningService = positioningService
        self.axElementManager = axElementManager
        self.cacheService = cacheService
        self.configManager = configManager
        self.logger = logger
    }

    // MARK: - Public API

    func moveNotification(_ window: AXUIElement) {
        logger.debug("=== NotificationMovementService: moveNotification called ===")

        // Check if enabled
        guard configManager.isEnabled else {
            logger.debug("Notification positioning disabled - skipping")
            return
        }

        // Get window info
        guard let windowSize = axElementManager.getSize(of: window) else {
            logger.error("Failed to get window size")
            return
        }

        logger.debug("Window size: \(windowSize.width)×\(windowSize.height)")

        // Skip top-right (default position)
        guard configManager.currentPosition != .topRight else {
            logger.debug("Position is Top Right (default) - not moving")
            return
        }

        // Skip standalone widgets
        if let identifier = axElementManager.getWindowIdentifier(window),
           identifier.hasPrefix("widget-local:") {
            if windowSize.width >= 150 && windowSize.height >= 150 {
                logger.debug("Skipping standalone widget window")
                return
            }
        }

        // Find notification element
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        guard let bannerElement = findNotificationElement(in: window, osVersion: osVersion) else {
            logger.error("Could not find notification element")
            return
        }

        logger.debug("Found banner element")

        // Get notification size
        guard let notifSize = axElementManager.getSize(of: bannerElement) else {
            logger.error("Failed to get notification size")
            return
        }

        // Update cache
        if cacheService.cachedInitialNotifSize == nil {
            cacheService.cacheInitialNotificationData(
                notifSize: notifSize,
                padding: 16.0
            )
        }

        // Calculate new position
        guard let cachedSize = cacheService.cachedInitialNotifSize,
              let cachedPadding = cacheService.cachedInitialPadding else {
            logger.error("Cache not initialized")
            return
        }

        let newPosition = positioningService.calculatePosition(
            notifSize: cachedSize,
            padding: cachedPadding,
            currentPosition: configManager.currentPosition,
            screenBounds: NSScreen.main!.frame
        )

        // Determine element to move (window vs banner)
        let elementToMove = axElementManager.getPositionableElement(
            window: window,
            banner: bannerElement,
            osVersion: osVersion
        )

        // Apply position
        let success = positioningService.applyPosition(
            to: elementToMove,
            at: newPosition
        )

        if success {
            logger.debug("✅ Moved notification to \(configManager.currentPosition.displayName)")
        } else {
            logger.error("❌ Failed to move notification")
        }
    }

    func moveAllNotifications() {
        guard let pid = findNotificationCenterPID() else {
            logger.error("Cannot find Notification Center process")
            return
        }

        let app = AXUIElementCreateApplication(pid)
        guard let windows = axElementManager.getWindows(from: app) else {
            logger.error("Failed to get windows")
            return
        }

        for window in windows {
            moveNotification(window)
        }
    }

    // MARK: - Private Helpers

    private func findNotificationElement(in window: AXUIElement, osVersion: OperatingSystemVersion) -> AXUIElement? {
        // Get subroles for OS version
        let subroles = getNotificationSubroles(for: osVersion)

        // Try primary search
        if let element = axElementManager.findElementBySubrole(
            root: window,
            targetSubroles: subroles,
            osVersion: osVersion
        ) {
            return element
        }

        // Try fallback
        return axElementManager.findElementUsingFallbacks(
            root: window,
            osVersion: osVersion
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
    }

    private func findNotificationCenterPID() -> pid_t? {
        return NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.apple.notificationcenterui"
        })?.processIdentifier
    }
}
```

**Verification:**
- [ ] Service compiles
- [ ] All moveNotification() logic extracted
- [ ] Dependencies injectable
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Notifications still move correctly

**Backward Compatibility:**
Keep NotificationMover.moveNotification() as passthrough:
```swift
// In NotificationMover
private lazy var movementService = NotificationMovementService()

func moveNotification(_ window: AXUIElement) {
    movementService.moveNotification(window)
}
```

#### 3.2 Create NotificationDetectionService
**Combine widget and window monitoring**

```swift
// Services/Business/NotificationDetectionService.swift

class NotificationDetectionService {

    // MARK: - Dependencies
    private let widgetMonitor: WidgetMonitorService
    private let windowMonitor: WindowMonitorService
    private let movementService: NotificationMovementService
    private let logger: LoggingService

    private var observerCallback: ((AXUIElement) -> Void)?

    init(
        widgetMonitor: WidgetMonitorService = .shared,
        windowMonitor: WindowMonitorService = .shared,
        movementService: NotificationMovementService,
        logger: LoggingService = .shared
    ) {
        self.widgetMonitor = widgetMonitor
        self.windowMonitor = windowMonitor
        self.movementService = movementService
        self.logger = logger

        // Setup callbacks
        setupCallbacks()
    }

    // MARK: - Public API

    func startMonitoring() {
        logger.debug("Starting notification detection...")

        // Start AX observer for NotificationCenter
        setupNotificationCenterObserver()

        // Start global window monitoring
        windowMonitor.startMonitoring()

        // Start widget monitoring
        widgetMonitor.startMonitoring()

        logger.debug("✅ All monitoring started")
    }

    func stopMonitoring() {
        logger.debug("Stopping notification detection...")

        windowMonitor.stopMonitoring()
        widgetMonitor.stopMonitoring()

        // TODO: Stop AX observer

        logger.debug("🛑 All monitoring stopped")
    }

    // MARK: - Setup

    private func setupCallbacks() {
        // Widget panel state changes
        widgetMonitor.onWidgetPanelHidden = { [weak self] in
            self?.logger.debug("Widget panel hidden - moving notifications")
            self?.movementService.moveAllNotifications()
        }

        // New notification windows detected
        windowMonitor.onNotificationWindowDetected = { [weak self] window in
            self?.logger.debug("New notification window detected")
            self?.movementService.moveNotification(window)
        }
    }

    private func setupNotificationCenterObserver() {
        guard let pid = findNotificationCenterPID() else {
            logger.warning("NotificationCenter not found")
            return
        }

        let app = AXUIElementCreateApplication(pid)
        var observer: AXObserver?

        let result = AXObserverCreate(pid, { observer, element, notification, context in
            // TODO: Handle notification
        }, &observer)

        guard result == .success, let observer = observer else {
            logger.error("Failed to create AXObserver")
            return
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        AXObserverAddNotification(observer, app, kAXWindowCreatedNotification as CFString, selfPtr)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)

        logger.debug("✅ AXObserver installed for NotificationCenter (PID: \(pid))")
    }

    private func findNotificationCenterPID() -> pid_t? {
        return NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.apple.notificationcenterui"
        })?.processIdentifier
    }
}
```

**Verification:**
- [ ] Service compiles
- [ ] Combines widget and window monitoring
- [ ] AX observer setup works
- [ ] All monitoring triggers work
- [ ] Notifications detected and moved

**Backward Compatibility:**
Keep old setupObserver() as passthrough.

#### 3.3 Update AXElementManager Extensions
**Add missing methods for NotificationMovementService**

```swift
// In AXElementManager

func getWindows(from app: AXUIElement) -> [AXUIElement]? {
    var windowsRef: AnyObject?
    let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)

    guard result == .success,
          let windows = windowsRef as? [AXUIElement] else {
        return nil
    }

    return windows
}
```

**Verification:**
- [ ] Method compiles
- [ ] Returns correct windows
- [ ] Used by NotificationMovementService

#### 3.4 Verify WidgetMonitorService Integration
**Current State:** Already extracted, needs updates

**Tasks:**
- [ ] Verify WidgetMonitorService.setNotificationMover() usage
- [ ] Update to use NotificationMovementService instead
- [ ] Add callback-based interface
- [ ] Remove direct NotificationMover coupling

**Verification:**
- [ ] Widget detection works
- [ ] Callbacks fire correctly
- [ ] No direct NotificationMover references

#### 3.5 Verify WindowMonitorService Integration
**Current State:** Already extracted, needs updates

**Tasks:**
- [ ] Verify WindowMonitorService.setNotificationMover() usage
- [ ] Update to use NotificationMovementService instead
- [ ] Add callback-based interface
- [ ] Remove direct NotificationMover coupling

**Verification:**
- [ ] Window detection works
- [ ] Callbacks fire correctly
- [ ] No direct NotificationMover references

**Backward Compatibility:**
- [ ] App continues to work
- [ ] All notifications detected and moved
- [ ] Monitoring works correctly

---

## PHASE 4: UI LAYER SERVICES

**Objective:** Extract UI management into dedicated services

**Estimated Time:** 3 hours
**Complexity:** MEDIUM
**Risk:** MEDIUM (UI changes)

### Tasks

#### 4.1 Create MenuBarService
**Extract menu bar management**

```swift
// Services/UI/MenuBarService.swift

class MenuBarService {

    // MARK: - Dependencies
    private let configManager: ConfigurationManager
    private let settingsService: SettingsService
    private let logger: LoggingService

    private var statusItem: NSStatusItem?

    init(
        configManager: ConfigurationManager = .shared,
        settingsService: SettingsService,
        logger: LoggingService = .shared
    ) {
        self.configManager = configManager
        self.settingsService = settingsService
        self.logger = logger

        // Observe config changes
        configManager.addObserver(self)
    }

    // MARK: - Public API

    func setupStatusItem() {
        guard !configManager.isMenuBarIconHidden else {
            statusItem = nil
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button,
           let menuBarIcon = NSImage(named: "MenuBarIcon") {
            menuBarIcon.isTemplate = true
            button.image = menuBarIcon
        }

        updateMenu()
    }

    func updateMenu() {
        statusItem?.menu = createMenu()
    }

    func showIcon(_ show: Bool) {
        if show {
            setupStatusItem()
        } else {
            statusItem = nil
        }
    }

    var isVisible: Bool {
        return statusItem != nil
    }

    // MARK: - Private

    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        // Position selector
        for position in NotificationPosition.allCases {
            let item = NSMenuItem(
                title: position.displayName,
                action: #selector(changePosition(_:)),
                keyEquivalent: ""
            )
            item.representedObject = position
            item.state = position == configManager.currentPosition ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Enable/Disable
        let toggleItem = NSMenuItem(
            title: configManager.isEnabled ? "✓ Enabled" : "Disabled",
            action: #selector(toggleEnabled(_:)),
            keyEquivalent: ""
        )
        toggleItem.state = configManager.isEnabled ? .on : .off
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Actions
        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(showSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem(
            title: "About Notimanager",
            action: #selector(showAbout),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Notimanager",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        return menu
    }

    // MARK: - Actions

    @objc private func changePosition(_ sender: NSMenuItem) {
        guard let position = sender.representedObject as? NotificationPosition else { return }

        let oldPosition = configManager.currentPosition
        configManager.currentPosition = position

        logger.debug("Position changed: \(oldPosition.displayName) → \(position.displayName)")

        // TODO: Trigger movement via NotificationMovementService
        updateMenu()
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        configManager.isEnabled.toggle()

        sender.title = configManager.isEnabled ? "✓ Enabled" : "Disabled"
        sender.state = configManager.isEnabled ? .on : .off

        logger.debug("Notification positioning \(configManager.isEnabled ? "enabled" : "disabled")")
    }

    @objc private func showSettings() {
        settingsService.showSettings()
    }

    @objc private func showAbout() {
        settingsService.showAbout()
    }
}

// MARK: - ConfigurationObserver

extension MenuBarService: ConfigurationManager.ConfigurationObserver {
    func configurationDidChange(_ event: ConfigurationManager.ConfigurationEvent) {
        switch event {
        case .positionChanged, .enabledChanged, .menuBarIconChanged:
            updateMenu()
        default:
            break
        }
    }
}
```

**Verification:**
- [ ] Service compiles
- [ ] Menu bar displays correctly
- [ ] All menu items work
- [ ] Position changes trigger movement
- [ ] Configuration changes update menu
- [ ] Show/hide icon works

**Backward Compatibility:**
Keep old methods in NotificationMover as passthroughs:
```swift
func setupStatusItem() {
    menuBarService.setupStatusItem()
}

private func createMenu() -> NSMenu {
    return menuBarService.createMenu()
}
```

#### 4.2 Create SettingsService
**Extract settings window management**

```swift
// Services/UI/SettingsService.swift

class SettingsService {

    // MARK: - Dependencies
    private let configManager: ConfigurationManager
    private let permissionService: AccessibilityPermissionService
    private let movementService: NotificationMovementService
    private let logger: LoggingService

    private var settingsWindow: NSWindow?
    private var diagnosticWindow: NSWindow?

    init(
        configManager: ConfigurationManager = .shared,
        permissionService: AccessibilityPermissionService,
        movementService: NotificationMovementService,
        logger: LoggingService = .shared
    ) {
        self.configManager = configManager
        self.permissionService = permissionService
        self.movementService = movementService
        self.logger = logger
    }

    // MARK: - Public API

    func showSettings() {
        if settingsWindow == nil {
            createSettingsWindow()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showPermissionWindow() {
        // Use PermissionWindow from Views/
        let permissionWindow = PermissionWindow(mover: /* TODO: remove mover dependency */)
        permissionWindow.show()
    }

    func showDiagnostics() {
        if diagnosticWindow == nil {
            createDiagnosticWindow()
        }
        diagnosticWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showAbout() {
        // Use AboutWindow from Views/
        let aboutWindow = AboutWindow()
        aboutWindow.show()
    }

    // MARK: - Window Creation

    private func createSettingsWindow() {
        // Use ModernSettingsWindow from Views/
        settingsWindow = ModernSettingsWindow(mover: /* TODO: remove mover dependency */)
    }

    private func createDiagnosticWindow() {
        // Extract from NotificationMover.createDiagnosticWindow()
        // TODO: Create separate DiagnosticWindow view
    }
}
```

**Verification:**
- [ ] Service compiles
- [ ] Settings window opens
- [ ] Permission window opens
- [ ] Diagnostic window opens
- [ ] About window opens
- [ ] All settings work

**Backward Compatibility:**
Keep old methods as passthroughs.

#### 4.3 Create DiagnosticService
**Extract diagnostic functionality**

```swift
// Services/UI/DiagnosticService.swift

class DiagnosticService {

    // MARK: - Dependencies
    private let axElementManager: AXElementManager
    private let logger: LoggingService

    private var diagnosticTextView: NSTextView?

    init(
        axElementManager: AXElementManager = .shared,
        logger: LoggingService = .shared
    ) {
        self.axElementManager = axElementManager
        self.logger = logger

        // Set up logging
        logger.setDiagnosticTextView(nil) // Will be set when window created
    }

    // MARK: - Public API

    func showDiagnosticWindow() {
        let window = createDiagnosticWindow()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Diagnostic Tests

    func scanAllWindows() {
        logger.diagnostic("🔍 Scanning all windows on screen...")

        let options = CGWindowListOption([.optionOnScreenOnly, .excludeDesktopElements])
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            logger.diagnostic("❌ Failed to get window list")
            return
        }

        var notificationCount = 0
        for window in windowList {
            guard let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = bounds["Width"],
                  let height = bounds["Height"] else {
                continue
            }

            if width >= 200 && width <= 800 && height >= 60 && height <= 200 {
                let ownerName = window[kCGWindowOwnerName as String] as? String ?? "Unknown"
                let windowNumber = window[kCGWindowNumber as String] as? Int ?? -1
                notificationCount += 1

                logger.diagnostic("  ✓ Found: \(ownerName) [#\(windowNumber)] - \(Int(width))×\(Int(height))")
            }
        }

        if notificationCount == 0 {
            logger.diagnostic("❌ No notification-sized windows found")
        } else {
            logger.diagnostic("✅ Found \(notificationCount) potential notification window(s)")
        }
    }

    func testAccessibilityAPI() {
        logger.diagnostic("♿️ Testing Accessibility API...")

        guard let pid = findNotificationCenterPID() else {
            logger.diagnostic("❌ Cannot find Notification Center process")
            return
        }

        let app = AXUIElementCreateApplication(pid)
        // ... continue with diagnostic logic
    }

    // MARK: - Private

    private func createDiagnosticWindow() -> NSWindow {
        // Extract from NotificationMover.createDiagnosticWindow()
        // TODO: Create dedicated DiagnosticWindow view
        fatalError("Implement diagnostic window creation")
    }

    private func findNotificationCenterPID() -> pid_t? {
        return NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.apple.notificationcenterui"
        })?.processIdentifier
    }
}
```

**Verification:**
- [ ] Service compiles
- [ ] Diagnostic window opens
- [ ] Scan test works
- [ ] AX API test works
- [ ] All diagnostic tests functional

**Backward Compatibility:**
- [ ] Old diagnostic methods work as passthroughs

---

## PHASE 5: PERMISSIONS SERVICE

**Objective:** Complete accessibility permission management

**Estimated Time:** 1 hour
**Complexity:** LOW
**Risk:** LOW

### Tasks

#### 5.1 Create AccessibilityPermissionService
**Extract permission management**

```swift
// Services/Permissions/AccessibilityPermissionService.swift

class AccessibilityPermissionService {

    // MARK: - Dependencies
    private let logger: LoggingService

    private var statusObservers: [(PermissionStatus) -> Void] = []
    private var pollingTimer: Timer?

    init(logger: LoggingService = .shared) {
        self.logger = logger
    }

    // MARK: - Public API

    var permissionStatus: PermissionStatus {
        guard AXIsProcessTrusted() else {
            return .denied
        }
        return .granted
    }

    func checkPermissions() -> Bool {
        let isTrusted = AXIsProcessTrusted()
        logger.debug("Accessibility permission check: \(isTrusted ? "✓ granted" : "✗ denied")")
        return isTrusted
    }

    func requestPermissions(showPrompt: Bool = true) -> Bool {
        logger.debug("Requesting accessibility permissions...")

        if showPrompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        }

        return checkPermissions()
    }

    func resetPermissions() throws {
        logger.debug("Resetting accessibility permissions...")

        let task = Process()
        task.launchPath = "/usr/bin/tccutil"
        task.arguments = ["reset", "Accessibility", "dev.abd3lraouf.notimanager"]

        do {
            try task.run()
            task.waitUntilExit()
            logger.debug("✓ Permission reset successfully")
        } catch {
            logger.error("✗ Failed to reset permission: \(error)")
            throw error
        }
    }

    func observePermissionChanges(_ callback: @escaping (PermissionStatus) -> Void) {
        statusObservers.append(callback)

        // Start polling
        startPolling()
    }

    // MARK: - Private

    private func startPolling() {
        pollingTimer?.invalidate()

        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let currentStatus = self.permissionStatus

            // Notify observers
            DispatchQueue.main.async {
                self.statusObservers.forEach { $0(currentStatus) }
            }

            // Stop if granted
            if currentStatus == .granted {
                self.pollingTimer?.invalidate()
            }
        }
    }
}

enum PermissionStatus {
    case granted
    case denied
    case unknown
}
```

**Verification:**
- [ ] Service compiles
- [ ] Permission checking works
- [ ] Permission requesting works
- [ ] Permission resetting works
- [ ] Observers notified on changes
- [ ] Polling stops when granted

**Backward Compatibility:**
Keep old methods as passthroughs:
```swift
func checkAccessibilityPermissions() {
    permissionService.checkPermissions()
}

func requestAccessibilityPermission() {
    permissionService.requestPermissions(showPrompt: true)
}

func resetAccessibilityPermission() {
    try? permissionService.resetPermissions()
}
```

---

## PHASE 6: COORDINATION LAYER

**Objective:** Create dependency injection container and refactor NotificationMover

**Estimated Time:** 2 hours
**Complexity:** MEDIUM
**Risk:** MEDIUM

### Tasks

#### 6.1 Create ServiceContainer
**Dependency injection container**

```swift
// Services/Coordination/ServiceContainer.swift

class ServiceContainer {

    // MARK: - Singleton
    static let shared = ServiceContainer()

    private init() {
        registerServices()
    }

    // MARK: - Services

    let loggingService: LoggingService
    let configManager: ConfigurationManager
    let axElementManager: AXElementManager
    let positioningService: NotificationPositioningService
    let cacheService: NotificationCacheService
    let launchAgentService: LaunchAgentService
    let permissionService: AccessibilityPermissionService
    let movementService: NotificationMovementService
    let detectionService: NotificationDetectionService
    let menuBarService: MenuBarService
    let settingsService: SettingsService
    let diagnosticService: DiagnosticService

    // MARK: - Registration

    private func registerServices() {
        // Core services (already singletons)
        loggingService = .shared
        configManager = .shared
        axElementManager = .shared
        positioningService = .shared

        // New services
        cacheService = .shared
        launchAgentService = .shared
        permissionService = AccessibilityPermissionService(logger: loggingService)

        // Business logic
        movementService = NotificationMovementService(
            positioningService: positioningService,
            axElementManager: axElementManager,
            cacheService: cacheService,
            configManager: configManager,
            logger: loggingService
        )

        detectionService = NotificationDetectionService(
            movementService: movementService,
            logger: loggingService
        )

        // UI services
        menuBarService = MenuBarService(
            configManager: configManager,
            settingsService: /* will be set below */,
            logger: loggingService
        )

        settingsService = SettingsService(
            configManager: configManager,
            permissionService: permissionService,
            movementService: movementService,
            logger: loggingService
        )

        // Update menuBarService with settingsService reference
        // (this creates a circular dependency that we'll resolve)

        diagnosticService = DiagnosticService(
            axElementManager: axElementManager,
            logger: loggingService
        )

        // Configure logging
        loggingService.isDebugModeEnabled = configManager.debugMode
    }

    // MARK: - Public API

    func startAllServices() {
        loggingService.info("Starting all services...")

        detectionService.startMonitoring()
        menuBarService.setupStatusItem()

        loggingService.info("✅ All services started")
    }

    func stopAllServices() {
        loggingService.info("Stopping all services...")

        detectionService.stopMonitoring()

        loggingService.info("🛑 All services stopped")
    }
}
```

**Verification:**
- [ ] Container compiles
- [ ] All services initialized
- [ ] Dependencies injected correctly
- [ ] Services start/stop correctly
- [ ] No circular dependencies

#### 6.2 Refactor NotificationMover to use ServiceContainer
**Transform NotificationMover into a lightweight coordinator**

```swift
// NotificationMover.swift (refactored)

class NotificationMover: NSObject, NSApplicationDelegate, NSWindowDelegate {

    // MARK: - Dependencies
    private let container: ServiceContainer

    // MARK: - Properties (minimal)
    private var diagnosticTextView: NSTextView?

    // MARK: - Initialization

    override init() {
        self.container = ServiceContainer.shared
        super.init()

        // Set up diagnostic logging
        container.loggingService.setDiagnosticTextView(diagnosticTextView)
    }

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        container.loggingService.logSystemInfo(
            osVersion: ProcessInfo.processInfo.operatingSystemVersion,
            notificationSubroles: getNotificationSubroles(),
            currentPosition: container.configManager.currentPosition
        )

        // Request notification permissions
        requestNotificationPermissions()

        // Check accessibility permissions (delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAccessibilityPermissions()
        }

        // Start all services
        container.startAllServices()

        // Move existing notifications
        container.movementService.moveAllNotifications()
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        // Re-check permissions when app becomes active
        if container.permissionService.permissionStatus == .granted {
            container.loggingService.debug("✓ Permission detected as granted on app activation")
        }

        // Show menu bar icon if hidden
        if container.configManager.isMenuBarIconHidden {
            container.configManager.isMenuBarIconHidden = false
            container.menuBarService.setupStatusItem()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        container.stopAllServices()
    }

    // MARK: - Permission Methods (passthroughs)

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                self.container.loggingService.error("Error requesting notification permissions: \(error)")
            } else {
                self.container.loggingService.debug("Notification permissions granted: \(granted)")
            }
        }
    }

    private func checkAccessibilityPermissions() {
        let isGranted = container.permissionService.checkPermissions()

        if !isGranted {
            container.settingsService.showPermissionWindow()
        }
    }

    // MARK: - Internal Methods (for SettingsWindow)

    internal var internalCurrentPosition: NotificationPosition {
        return container.configManager.currentPosition
    }

    internal var internalIsEnabled: Bool {
        return container.configManager.isEnabled
    }

    internal var internalDebugMode: Bool {
        return container.configManager.debugMode
    }

    internal var internalIsMenuBarIconHidden: Bool {
        return container.configManager.isMenuBarIconHidden
    }

    internal var internalLaunchAgentPlistPath: String {
        return container.launchAgentService.plistPath
    }

    internal func updatePosition(to position: NotificationPosition) {
        container.configManager.currentPosition = position
        container.movementService.moveAllNotifications()
    }

    internal func internalSendTestNotification() {
        // Test notification logic
    }

    // ... other internal methods as passthroughs

    // MARK: - Private Helpers

    private func getNotificationSubroles() -> [String] {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion

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
    }
}
```

**Verification:**
- [ ] NotificationMover compiles
- [ ] Reduced to ~200 lines (from 3013)
- [ ] All functionality preserved
- [ ] App launches correctly
- [ ] All features work
- [ ] Services coordinate properly

#### 6.3 Resolve Circular Dependencies
**Fix any circular dependencies in ServiceContainer**

**Common Issues:**
- MenuBarService needs SettingsService
- SettingsService needs MovementService
- MovementService needs everything

**Solutions:**
1. Use lazy initialization
2. Inject dependencies via properties
3. Use protocol abstractions
4. Break cycles with observers

**Verification:**
- [ ] No circular dependencies
- [ ] Services initialize in correct order
- [ ] No retain cycles
- [ ] Memory profile clean

---

## PHASE 7: CLEANUP

**Objective:** Remove legacy code and finalize migration

**Estimated Time:** 2 hours
**Complexity:** MEDIUM
**Risk:** MEDIUM (deleting code)

### Tasks

#### 7.1 Remove Legacy Methods from NotificationMover
**Delete all methods that are now passthroughs**

**Methods to Remove:**
- [ ] `setupObserver()` → use detectionService.startMonitoring()
- [ ] `moveNotification()` → use movementService.moveNotification()
- [ ] `moveAllNotifications()` → use movementService.moveAllNotifications()
- [ ] `setupStatusItem()` → use menuBarService.setupStatusItem()
- [ ] `createMenu()` → use menuBarService.updateMenu()
- [ ] `createSettingsWindow()` → use settingsService.showSettings()
- [ ] `createDiagnosticWindow()` → use diagnosticService.showDiagnosticWindow()
- [ ] `showPermissionStatusWindow()` → use permissionService
- [ ] `requestAccessibilityPermission()` → use permissionService
- [ ] `resetAccessibilityPermission()` → use permissionService
- [ ] All AX helper methods → use axElementManager
- [ ] All positioning logic → use positioningService
- [ ] All cache management → use cacheService
- [ ] All launch agent logic → use launchAgentService

**Verification:**
- [ ] Only app delegate methods remain
- [ ] Internal accessor methods remain (for SettingsWindow)
- [ ] NotificationMover ~100-150 lines
- [ ] App still works

#### 7.2 Update Views to Use Services
**Remove NotificationMover dependency from views**

**Views to Update:**
- [ ] `ModernSettingsWindow.swift` - inject services via init
- [ ] `PermissionWindow.swift` - inject services via init
- [ ] `AboutWindow.swift` - standalone (no changes needed)
- [ ] `SettingsWindow.swift` - inject services via init

**Example:**
```swift
// BEFORE
class ModernSettingsWindow: NSWindow {
    private weak var mover: NotificationMover?

    init(mover: NotificationMover) {
        self.mover = mover
        // ...
    }
}

// AFTER
class ModernSettingsWindow: NSWindow {
    private let configManager: ConfigurationManager
    private let movementService: NotificationMovementService
    private let permissionService: AccessibilityPermissionService

    init(
        configManager: ConfigurationManager = .shared,
        movementService: NotificationMovementService,
        permissionService: AccessibilityPermissionService
    ) {
        self.configManager = configManager
        self.movementService = movementService
        self.permissionService = permissionService
        // ...
    }
}
```

**Verification:**
- [ ] All views compile
- [ ] No NotificationMover dependencies
- [ ] Views work correctly
- [ ] Settings apply correctly

#### 7.3 Remove Test-Only Code
**Clean up diagnostic and test code**

**Code to Review:**
- [ ] `diagnosticLog()` → use LoggingService
- [ ] `dumpElementHierarchy()` → move to AXElementManager
- [ ] `logElementDetails()` → use AXElementManager
- [ ] `collectAllSubrolesInHierarchy()` → use AXElementManager
- [ ] Diagnostic window UI → move to DiagnosticService

**Verification:**
- [ ] Diagnostic functionality preserved
- [ ] Code is in appropriate services
- [ ] No duplicate code

#### 7.4 Update Tests
**Migrate tests to use new architecture**

**Tests to Update:**
- [ ] NotificationMovementTests → use NotificationMovementService
- [ ] NotificationDetectionTests → use NotificationDetectionService
- [ ] NotificationPositionTests → use NotificationPositioningService
- [ ] MenuBarUITests → use MenuBarService
- [ ] SettingsWindowUITests → use SettingsService
- [ ] PermissionGuideUITests → use PermissionService

**Verification:**
- [ ] All tests compile
- [ ] All tests pass
- [ ] Test coverage maintained or improved

#### 7.5 Update Documentation
**Document new architecture**

**Documentation to Create/Update:**
- [ ] README.md with new architecture overview
- [ ] Service documentation in each service file
- [ ] Migration guide for contributors
- [ ] Architecture diagram (optional but recommended)
- [ ] API documentation for public interfaces

**Verification:**
- [ ] Documentation is clear
- [ ] Architecture is explained
- [ ] Examples provided
- [ ] Contributing guidelines updated

#### 7.6 Final Verification
**Comprehensive testing before marking migration complete**

**Testing Checklist:**

**Functional Tests:**
- [ ] App launches successfully
- [ ] Menu bar icon shows/hides correctly
- [ ] Settings window opens and works
- [ ] Permission window displays correctly
- [ ] Position changes work
- [ ] Notifications move to correct positions
- [ ] Test notification works
- [ ] Enable/disable toggle works
- [ ] Debug mode toggle works
- [ ] Launch at login works
- [ ] Diagnostics window works
- [ ] About window works

**Integration Tests:**
- [ ] Permission granting flow works
- [ ] Permission resetting works
- [ ] Configuration persistence works
- [ ] Service coordination works
- [ ] Observers receive notifications

**Edge Cases:**
- [ ] App behaves correctly when permissions denied
- [ ] App handles missing Notification Center
- [ ] App handles external app notifications
- [ ] Widget panel detection works
- [ ] Multiple notifications handled correctly

**Performance Tests:**
- [ ] No memory leaks
- [ ] No performance regressions
- [ ] Services start/stop quickly
- [ ] Monitoring doesn't impact CPU

**Code Quality:**
- [ ] No compiler warnings
- [ ] Code formatted consistently
- [ ] No TODO comments left (or documented)
- [ ] All services have proper error handling
- [ ] Logging works correctly

**Backward Compatibility:**
- [ ] User settings preserved
- [ ] No breaking changes for users
- [ ] Migration is transparent

---

## ROLLBACK PLAN

Each phase is designed to be independently reversible:

### Phase Rollback

**Phase 0-1:** No rollback needed (additive changes)

**Phase 2:** Revert to direct UserDefaults if ConfigurationManager issues:
```swift
// Rollback: Direct UserDefaults access
let value = UserDefaults.standard.bool(forKey: "isEnabled")
```

**Phase 3:** If NotificationMovementService has issues, use original moveNotification():
```swift
// Rollback: Keep original method, call it from service
func moveNotification(_ window: AXUIElement) {
    // Original implementation here
}
```

**Phase 4:** If UI services fail, use original window creation:
```swift
// Rollback: Create windows directly in NotificationMover
func showSettings() {
    if settingsWindow == nil {
        createSettingsWindow() // Original method
    }
    settingsWindow?.makeKeyAndOrderFront(nil)
}
```

**Phase 5:** If permission service fails, use original permission checking:
```swift
// Rollback: Direct AX API calls
func checkPermissions() -> Bool {
    return AXIsProcessTrusted()
}
```

**Phase 6:** If ServiceContainer fails, instantiate services directly in NotificationMover:
```swift
// Rollback: Direct service instantiation
private lazy var movementService = NotificationMovementService()
private lazy var menuBarService = MenuBarService()
// etc.
```

**Phase 7:** If cleanup breaks anything, restore passthrough methods:
```swift
// Rollback: Keep passthrough methods
func moveNotification(_ window: AXUIElement) {
    movementService.moveNotification(window)
}
```

### Complete Rollback

If critical issues arise:
1. Revert to commit before Phase 1
2. All changes are additive, so old code still exists
3. Zero impact on users

---

## SUCCESS METRICS

### Code Quality
- [ ] NotificationMover reduced from 3013 to <150 lines (95% reduction)
- [ ] Average service file <300 lines
- [ ] Test coverage >80%
- [ ] Zero compiler warnings

### Architecture
- [ ] All services have single responsibility
- [ ] Dependencies injectable
- [ ] No circular dependencies
- [ ] Clear separation of concerns

### Maintainability
- [ ] Easy to add new features
- [ ] Easy to test components
- [ ] Easy to understand code flow
- [ ] Easy to debug issues

### Performance
- [ ] No memory leaks
- [ ] No performance regressions
- [ ] Startup time <1 second
- [ ] CPU usage during monitoring <1%

### User Experience
- [ ] All features work correctly
- [ ] No breaking changes
- [ ] Settings preserved
- [ ] Smooth migration

---

## APPENDICES

### Appendix A: File Structure

**Before:**
```
Notimanager/
├── Managers/
│   ├── NotificationMover.swift (3013 lines)
│   ├── AccessibilityManager.swift
│   ├── AXElementManager.swift
│   ├── ConfigurationManager.swift
│   ├── LoggingService.swift
│   ├── NotificationPositioningService.swift
│   ├── ThemeManager.swift
│   └── ...
├── Models/
│   └── NotificationPosition.swift
├── Protocols/
│   └── NotificationMoverProtocols.swift
└── Views/
    ├── SettingsWindow.swift
    ├── PermissionWindow.swift
    └── ...
```

**After:**
```
Notimanager/
├── Services/
│   ├── Core/
│   │   ├── NotificationCacheService.swift
│   │   └── LaunchAgentService.swift
│   ├── Business/
│   │   ├── NotificationMovementService.swift
│   │   └── NotificationDetectionService.swift
│   ├── UI/
│   │   ├── MenuBarService.swift
│   │   ├── SettingsService.swift
│   │   └── DiagnosticService.swift
│   ├── Permissions/
│   │   └── AccessibilityPermissionService.swift
│   └── Coordination/
│       └── ServiceContainer.swift
├── Managers/
│   ├── NotificationMover.swift (<150 lines)
│   ├── AccessibilityManager.swift
│   ├── AXElementManager.swift
│   ├── ConfigurationManager.swift
│   ├── LoggingService.swift
│   ├── NotificationPositioningService.swift
│   ├── WidgetMonitorService.swift
│   └── WindowMonitorService.swift
├── Models/
│   └── NotificationPosition.swift
├── Protocols/
│   └── NotificationMoverProtocols.swift
└── Views/
    ├── ModernSettingsWindow.swift
    ├── PermissionWindow.swift
    └── ...
```

### Appendix B: Service Dependency Graph

```
ServiceContainer
├── LoggingService (no dependencies)
├── ConfigurationManager (no dependencies)
├── AXElementManager (no dependencies)
├── NotificationPositioningService (no dependencies)
├── NotificationCacheService (no dependencies)
├── LaunchAgentService (no dependencies)
├── AccessibilityPermissionService (→ LoggingService)
├── NotificationMovementService (→ Positioning, AXElement, Cache, Config, Logging)
├── NotificationDetectionService (→ Movement, WidgetMonitor, WindowMonitor, Logging)
├── MenuBarService (→ Config, Settings, Logging)
├── SettingsService (→ Config, Permission, Movement, Logging)
└── DiagnosticService (→ AXElement, Logging)
```

### Appendix C: Migration Timeline

**Day 1:**
- Morning: Phase 0-1 (1.5 hours)
- Afternoon: Phase 2 (3 hours)

**Day 2:**
- Morning: Phase 3 (4 hours)
- Afternoon: Phase 4 (3 hours)

**Day 3:**
- Morning: Phase 5-6 (3 hours)
- Afternoon: Phase 7 (2 hours) + Final verification

### Appendix D: Testing Strategy

**Unit Tests:**
- Test each service in isolation
- Mock all dependencies
- Cover all public methods
- Test edge cases

**Integration Tests:**
- Test service interactions
- Test real dependencies
- Test end-to-end flows
- Test error scenarios

**UI Tests:**
- Test all UI flows
- Test user interactions
- Test state changes
- Test accessibility

**Performance Tests:**
- Memory profiling
- CPU profiling
- Startup time
- Response time

---

## CONCLUSION

This migration plan provides a safe, incremental path from the current monolithic architecture to a clean, service-based architecture. Each phase is independently verifiable and reversible, minimizing risk while ensuring the app continues working throughout the migration.

**Key Benefits:**
- 95% reduction in NotificationMover complexity
- Testable, maintainable code
- Clear separation of concerns
- Easy to extend and modify
- No breaking changes for users

**Estimated Timeline:** 16 hours across 2-3 days
**Risk Level:** LOW (incremental with rollback capability)
**Success Rate:** HIGH (thorough verification at each step)

---

**End of Migration Plan**
