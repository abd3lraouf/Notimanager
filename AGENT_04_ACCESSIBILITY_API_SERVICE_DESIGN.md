# ACCESSIBILITY API SERVICE DESIGN
## Agent 04 Report - AX Operations Extraction

**Date:** 2025-01-15
**macOS Version:** 26.2 (Sequoia)
**Status:** DESIGN COMPLETE - Ready for Implementation

---

## EXECUTIVE SUMMARY

This document provides a comprehensive design for extracting all Accessibility API (AX) operations from `NotificationMover.swift` (3013 lines) into a dedicated, testable service layer. The design addresses macOS version differences (Sequoia vs older), makes AX operations mockable for testing, and follows the existing protocol-based architecture.

**Key Finding:** AX operations are already partially extracted into `AXElementManager.swift`, but `NotificationMover.swift` still contains **40+ direct AX API calls** that need to be migrated to a complete service layer.

---

## 1. IDENTIFIED AX OPERATIONS IN NotificationMover.swift

### 1.1 Core AX API Functions

| Function | Lines | Description | Current State |
|----------|-------|-------------|---------------|
| `getPosition()` | 2296-2310 | Gets element position via AXUIElementCopyAttributeValue | Direct AX call |
| `getSize()` | 2362-2392 | Gets element size with retry logic | Direct AX call |
| `setPosition()` | 2394-2406 | Sets element position via AXUIElementSetAttributeValue | Direct AX call |
| `getWindowTitle()` | 2350-2360 | Gets window title attribute | Direct AX call |
| `getWindowIdentifier()` | 2229-2237 | Gets window identifier attribute | Direct AX call |
| `getPositionableElement()` | 2408-2449 | Determines which element to position (window vs banner) | Uses AX calls |
| `verifyPositionSet()` | 2451-2468 | Verifies position was applied correctly | Uses AX calls |
| `logElementDetails()` | 2726-2750 | Logs element attributes for debugging | Uses AX calls |

### 1.2 Element Discovery Functions

| Function | Lines | Description | Current State |
|----------|-------|-------------|---------------|
| `findElementWithSubrole()` | 2470-2576 | Finds elements by subrole with scoring | Direct AX calls |
| `findNotificationElementFallback()` | 2578-2628 | Multiple fallback strategies | Direct AX calls |
| `findElementByIdentifier()` | 2630-2651 | Searches by AXIdentifier attribute | Direct AX calls |
| `findElementByRoleAndSize()` | 2653-2677 | Searches by role + size constraints | Direct AX calls |
| `findDeepestSizedElement()` | 2679-2703 | Finds deepest matching element | Direct AX calls |
| `findAnyElementWithSize()` | 2705-2724 | Finds any element matching size | Direct AX calls |
| `collectAllSubrolesInHierarchy()` | 2752-2768 | Collects all subroles for debugging | Direct AX calls |
| `dumpElementHierarchy()` | 2782-2822 | Dumps element tree structure | Direct AX calls |

### 1.3 AX Observer & Monitoring Functions

| Function | Lines | Description | Current State |
|----------|-------|-------------|---------------|
| `setupObserver()` | 2013-2054 | Creates AXObserver for window creation | Direct AX calls |
| `observerCallback()` | 2856-2867 | Callback for AX notifications | Direct AX usage |
| `setupGlobalWindowMonitoring()` | 2056-2066 | Sets up window polling | CGWindow API |
| `buildKnownWindowSet()` | 2068-2080 | Tracks existing windows | CGWindow API |
| `detectNewNotificationWindows()` | 2082-2120 | Detects new notification windows | CGWindow API |
| `getAXElementForWindow()` | 2159-2200 | Maps window number to AX element | Direct AX calls |

### 1.4 Permission & Trust Functions

| Function | Lines | Description | Current State |
|----------|-------|-------------|---------------|
| `checkAccessibilityPermissions()` | 147-167 | Checks AXIsProcessTrusted() | Direct AX call |
| `requestAccessibilityPermission()` | 452-471 | Shows system prompt | Direct AX call |
| `startPermissionPolling()` | 473-491 | Polls for permission changes | Direct AX call |
| `updatePermissionStatus()` | 517-583 | Updates UI based on permission | Direct AX call |

### 1.5 AX API Direct Calls (Distribution)

```
Total AX API Calls in NotificationMover.swift: 47+

Breakdown:
- AXUIElementCopyAttributeValue: 28 calls
- AXUIElementSetAttributeValue: 2 calls
- AXUIElementIsAttributeSettable: 7 calls
- AXValueCreate: 1 call
- AXValueGetType: 2 calls (implicit in value checks)
- AXValueGetValue: 2 calls (implicit in value extraction)
- AXUIElementCreateApplication: 3 calls
- AXObserverCreate: 1 call
- AXObserverAddNotification: 1 call
- AXObserverGetRunLoopSource: 1 call
- AXIsProcessTrusted: 2 calls
- AXIsProcessTrustedWithOptions: 1 call
```

---

## 2. NEW SERVICE DESIGN

### 2.1 Protocol Architecture

```swift
/// Primary protocol for all AX API operations
@available(macOS 10.15, *)
protocol AccessibilityAPIProtocol {

    // MARK: - Element Properties
    func getPosition(of element: AXUIElement) -> CGPoint?
    func getSize(of element: AXUIElement) -> CGSize?
    func setPosition(of element: AXUIElement, x: CGFloat, y: CGFloat) -> Bool
    func getRole(of element: AXUIElement) -> String?
    func getSubrole(of element: AXUIElement) -> String?
    func getWindowTitle(_ element: AXUIElement) -> String?
    func getWindowIdentifier(_ element: AXUIElement) -> String?

    // MARK: - Attribute Queries
    func copyAttributeValue(_ element: AXUIElement, _ attribute: CFString) -> AnyObject?
    func isAttributeSettable(_ attribute: CFString, on element: AXUIElement) -> Bool

    // MARK: - Element Discovery
    func findElementBySubrole(
        root: AXUIElement,
        targetSubroles: [String],
        osVersion: OperatingSystemVersion
    ) -> AXUIElement?

    func findElementUsingFallbacks(
        root: AXUIElement,
        osVersion: OperatingSystemVersion
    ) -> AXUIElement?

    func findElementByIdentifier(
        root: AXUIElement,
        identifier: String,
        currentDepth: Int,
        maxDepth: Int
    ) -> AXUIElement?

    func findElementByRoleAndSize(
        root: AXUIElement,
        role: String,
        sizeConstraints: SizeConstraints
    ) -> AXUIElement?

    // MARK: - Application & Windows
    func createApplicationElement(pid: pid_t) -> AXUIElement
    func getWindows(for app: AXUIElement) -> [AXUIElement]?

    // MARK: - OS Version Handling
    func getNotificationSubroles(for osVersion: OperatingSystemVersion) -> [String]
    func getPositionableElement(
        window: AXUIElement,
        banner: AXUIElement,
        osVersion: OperatingSystemVersion
    ) -> AXUIElement?

    // MARK: - Verification
    func verifyPositionSet(_ element: AXUIElement, expected: CGPoint) -> Bool

    // MARK: - Debugging
    func dumpElementHierarchy(
        _ element: AXUIElement,
        label: String,
        depth: Int,
        maxDepth: Int
    )

    func logElementDetails(_ element: AXUIElement, label: String)
    func collectAllSubrolesInHierarchy(
        _ element: AXUIElement,
        depth: Int,
        maxDepth: Int
    ) -> Set<String>
}
```

### 2.2 AXObserver Protocol

```swift
/// Protocol for AX observer operations
@available(macOS 10.15, *)
protocol AXObserverProtocol {

    /// Creates an observer for a process
    /// - Parameters:
    ///   - pid: Process ID to observe
    ///   - callback: Callback function for notifications
    /// - Returns: Tuple of (observer, error) where observer is nil on failure
    func createObserver(
        pid: pid_t,
        callback: @escaping AXObserverCallback
    ) -> (AXObserver?, AXError?)

    /// Adds a notification to the observer
    /// - Parameters:
    ///   - observer: The observer
    ///   - element: Element to observe
    ///   - notification: Notification type
    ///   - context: Context pointer
    /// - Returns: Success status
    func addNotification(
        to observer: AXObserver,
        for element: AXUIElement,
        notification: CFString,
        context: UnsafeMutableRawPointer?
    ) -> Bool

    /// Adds observer to run loop
    /// - Parameter observer: The observer to add
    /// func addToRunLoop(_ observer: AXObserver)

    /// Removes observer from run loop
    /// - Parameter observer: The observer to remove
    /// func removeFromRunLoop(_ observer: AXObserver)
}
```

### 2.3 Permission Protocol

```swift
/// Protocol for accessibility permission management
@available(macOS 10.15, *)
protocol AccessibilityPermissionProtocol {

    /// Checks if process is trusted for accessibility
    /// - Returns: True if trusted
    func checkTrusted() -> Bool

    /// Checks trust with optional prompt
    /// - Parameter withPrompt: Whether to show system prompt
    /// - Returns: True if trusted
    func checkTrusted(withPrompt: Bool) -> Bool

    /// Gets trusted options with prompt flag
    /// - Parameter prompt: Whether to show prompt
    /// - Returns: CFDictionary of options
    func getTrustedOptions(prompt: Bool) -> CFDictionary

    /// Resets accessibility permissions (for testing)
    /// - Throws: Process error if reset fails
    func resetPermissions() throws
}
```

### 2.4 Implementation Structure

```swift
/// Main implementation of AccessibilityAPIProtocol
@available(macOS 10.15, *)
final class AccessibilityAPIService: AccessibilityAPIProtocol {

    // MARK: - Singleton
    static let shared = AccessibilityAPIService()
    private init() {}

    // MARK: - Dependencies
    private let osVersion = ProcessInfo.processInfo.operatingSystemVersion

    // MARK: - Element Properties
    func getPosition(of element: AXUIElement) -> CGPoint? {
        var positionValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &positionValue
        )

        guard result == .success,
              let posVal = positionValue,
              AXValueGetType(posVal as! AXValue) == .cgPoint else {
            return nil
        }

        var position = CGPoint.zero
        AXValueGetValue(posVal as! AXValue, .cgPoint, &position)
        return position
    }

    func getSize(of element: AXUIElement) -> CGSize? {
        let maxRetries = 2
        for attempt in 0...maxRetries {
            var sizeValue: AnyObject?
            let result = AXUIElementCopyAttributeValue(
                element,
                kAXSizeAttribute as CFString,
                &sizeValue
            )

            guard result == .success else {
                if attempt < maxRetries {
                    usleep(10000) // 10ms delay
                    continue
                }
                return nil
            }

            guard let sizeVal = sizeValue,
                  AXValueGetType(sizeVal as! AXValue) == .cgSize else {
                return nil
            }

            var size = CGSize.zero
            AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)
            return size
        }
        return nil
    }

    func setPosition(of element: AXUIElement, x: CGFloat, y: CGFloat) -> Bool {
        var point = CGPoint(x: x, y: y)
        let value = AXValueCreate(.cgPoint, &point)!
        let result = AXUIElementSetAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            value
        )
        return result == .success
    }

    // ... (other methods)
}

/// AXObserver implementation
@available(macOS 10.15, *)
final class AXObserverService: AXObserverProtocol {

    static let shared = AXObserverService()
    private init() {}

    func createObserver(
        pid: pid_t,
        callback: @escaping AXObserverCallback
    ) -> (AXObserver?, AXError?) {
        var observer: AXObserver?
        let result = AXObserverCreate(pid, callback, &observer)

        if result == .success {
            return (observer, nil)
        } else {
            return (nil, result)
        }
    }

    func addNotification(
        to observer: AXObserver,
        for element: AXUIElement,
        notification: CFString,
        context: UnsafeMutableRawPointer?
    ) -> Bool {
        let result = AXObserverAddNotification(observer, element, notification, context)
        return result == .success
    }

    func addToRunLoop(_ observer: AXObserver) {
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            AXObserverGetRunLoopSource(observer),
            .defaultMode
        )
    }
}

/// Permission management implementation
@available(macOS 10.15, *)
final class AccessibilityPermissionService: AccessibilityPermissionProtocol {

    static let shared = AccessibilityPermissionService()
    private init() {}

    func checkTrusted() -> Bool {
        return AXIsProcessTrusted()
    }

    func checkTrusted(withPrompt: Bool) -> Bool {
        if withPrompt {
            let options = getTrustedOptions(prompt: true)
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }

    func getTrustedOptions(prompt: Bool) -> CFDictionary {
        return [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt
        ] as CFDictionary
    }

    func resetPermissions() throws {
        let task = Process()
        task.launchPath = "/usr/bin/tccutil"
        task.arguments = ["reset", "Accessibility", "dev.abd3lraouf.notimanager"]

        try task.run()
        task.waitUntilExit()
    }
}
```

### 2.5 Mock Implementation for Testing

```swift
/// Mock implementation for unit testing
@available(macOS 10.15, *)
final class MockAccessibilityAPIService: AccessibilityAPIProtocol {

    var mockPosition: CGPoint?
    var mockSize: CGSize?
    var mockElements: [String: AXUIElement] = [:]
    var setPositionCalled: Bool = false
    var setPositionCallCount: Int = 0

    func getPosition(of element: AXUIElement) -> CGPoint? {
        return mockPosition
    }

    func getSize(of element: AXUIElement) -> CGSize? {
        return mockSize
    }

    func setPosition(of element: AXUIElement, x: CGFloat, y: CGFloat) -> Bool {
        setPositionCalled = true
        setPositionCallCount += 1
        mockPosition = CGPoint(x: x, y: y)
        return true
    }

    // ... (other mock methods)
}
```

---

## 3. MACOS VERSION HANDLING

### 3.1 Version Detection Strategy

```swift
/// macOS version categories
enum MacOSVersion {
    case sequoia // macOS 15+
    case sonoma  // macOS 14
    case ventura // macOS 13
    case monterey // macOS 12 and earlier

    init(osVersion: OperatingSystemVersion) {
        switch osVersion.majorVersion {
        case 26...: self = .sequoia  // macOS 26+ (future)
        case 15...25: self = .sequoia // macOS 15-25 (Sequoia)
        case 14: self = .sonoma
        case 13: self = .ventura
        default: self = .monterey
        }
    }
}
```

### 3.2 Subrole Differences by Version

```swift
extension AccessibilityAPIService {

    /// Returns notification subroles for a given macOS version
    func getNotificationSubroles(for osVersion: OperatingSystemVersion) -> [String] {
        let version = MacOSVersion(osVersion: osVersion)

        switch version {
        case .sequoia:
            // macOS 15+ may use new subrole naming
            return [
                "AXNotificationCenterBanner",
                "AXNotificationCenterAlert",
                "AXNotification",
                "AXBanner",
                "AXAlert",
                "AXSystemDialog",
                "AXNotificationBanner",  // Potential new name
                "AXNotificationAlert",   // Potential new name
                "AXFloatingPanel",       // Alternative structure
                "AXPanel"                // Simplified panel name
            ]

        case .sonoma, .ventura, .monterey:
            return [
                "AXNotificationCenterBanner",
                "AXNotificationCenterAlert",
                "AXNotification",  // Potential new name
                "AXBanner",        // Potential simplified name
                "AXAlert",         // Potential simplified name
                "AXSystemDialog"   // Potential alternative
            ]
        }
    }
}
```

### 3.3 Positioning Strategy by Version

```swift
extension AccessibilityAPIService {

    func getPositionableElement(
        window: AXUIElement,
        banner: AXUIElement,
        osVersion: OperatingSystemVersion
    ) -> AXUIElement? {

        let version = MacOSVersion(osVersion: osVersion)

        switch version {
        case .sequoia:
            // macOS 15+: Try window element first for standalone notifications
            return getSequoiaPositionableElement(window: window, banner: banner)

        case .sonoma, .ventura, .monterey:
            // macOS 14 and earlier: Always use banner element
            return banner
        }
    }

    private func getSequoiaPositionableElement(
        window: AXUIElement,
        banner: AXUIElement
    ) -> AXUIElement? {

        // Check window size - never move oversized windows
        if let windowSize = getSize(of: window) {
            if windowSize.width > 600 || windowSize.height > 300 {
                return banner // NC panel detected, use banner
            }
        }

        // Check if window position is settable
        var windowSettable = DarwinBoolean = false
        let windowResult = AXUIElementIsAttributeSettable(
            window,
            kAXPositionAttribute as CFString,
            &windowSettable
        )

        if windowResult == .success && windowSettable.boolValue {
            return window
        }

        return banner
    }
}
```

---

## 4. MIGRATION PLAN

### 4.1 Phase 1: Create Service Layer (1-2 hours)

1. **Create protocol files:**
   - `/Users/abdelraouf/Developer/Notimanager/Notimanager/Protocols/AccessibilityAPIProtocol.swift`
   - Include all three protocols: `AccessibilityAPIProtocol`, `AXObserverProtocol`, `AccessibilityPermissionProtocol`

2. **Create service implementations:**
   - `/Users/abdelraouf/Developer/Notimanager/Notimanager/Services/AccessibilityAPIService.swift`
   - `/Users/abdelraouf/Developer/Notimanager/Notimanager/Services/AXObserverService.swift`
   - `/Users/abdelraouf/Developer/Notimanager/Notimanager/Services/AccessibilityPermissionService.swift`

3. **Create mock implementations:**
   - Update `/Users/abdelraouf/Developer/Notimanager/NotimanagerTests/Utilities/MockAccessibilityAPIService.swift`

### 4.2 Phase 2: Refactor NotificationMover (2-3 hours)

1. **Add service dependencies:**
```swift
class NotificationMover: NSObject {
    private let axService: AccessibilityAPIProtocol
    private let observerService: AXObserverProtocol
    private let permissionService: AccessibilityPermissionProtocol

    // Initialize with real services by default
    init(
        axService: AccessibilityAPIProtocol = AccessibilityAPIService.shared,
        observerService: AXObserverProtocol = AXObserverService.shared,
        permissionService: AccessibilityPermissionProtocol = AccessibilityPermissionService.shared
    ) {
        self.axService = axService
        self.observerService = observerService
        self.permissionService = permissionService
        super.init()
    }
}
```

2. **Replace direct AX calls with service calls:**
   - Replace `getPosition(of:)` with `axService.getPosition(of:)`
   - Replace `getSize(of:)` with `axService.getSize(of:)`
   - Replace `setPosition(_:x:y:)` with `axService.setPosition(of:x:y:)`
   - Continue for all 47 AX API calls

3. **Remove duplicate methods:**
   - Delete methods that now exist in `AccessibilityAPIService`
   - Keep only business logic in `NotificationMover`

### 4.3 Phase 3: Update Tests (1 hour)

1. **Create unit tests for service layer:**
   - Test each AX operation with mock data
   - Test version-specific behavior
   - Test error handling

2. **Update existing tests:**
   - Inject mock services into `NotificationMover`
   - Verify service methods are called correctly
   - Test business logic without actual AX calls

### 4.4 Phase 4: Documentation (30 minutes)

1. **Add inline documentation:**
   - Document each protocol method
   - Add version-specific behavior notes
   - Add usage examples

2. **Update architecture docs:**
   - Add service layer to architecture diagram
   - Document dependency injection pattern

---

## 5. TESTING STRATEGY

### 5.1 Unit Tests

```swift
final class AccessibilityAPIServiceTests: XCTestCase {

    var service: AccessibilityAPIService!
    var mockElement: AXUIElement!

    override func setUp() {
        super.setUp()
        service = AccessibilityAPIService.shared
        // Create mock element for testing
    }

    func testGetPosition() {
        // Test: getPosition returns correct position
        // Setup mock element with known position
        // Verify service returns expected position
    }

    func testGetSizeWithRetry() {
        // Test: getSize retries on failure
        // Verify retry logic works correctly
    }

    func testSetPosition() {
        // Test: setPosition returns success/failure correctly
    }

    func testFindElementBySubrole() {
        // Test: Element discovery with scoring
        // Test: Multiple candidates handling
        // Test: Depth-aware search
    }

    func testMacOSVersionSubroles() {
        // Test: Correct subroles for each macOS version
        let sequoiaSubroles = service.getNotificationSubroles(
            for: OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0)
        )
        XCTAssertFalse(sequoiaSubroles.isEmpty)
    }
}
```

### 5.2 Integration Tests

```swift
final class NotificationMoverIntegrationTests: XCTestCase {

    var mockAXService: MockAccessibilityAPIService!
    var mockObserverService: MockAXObserverService!
    var mockPermissionService: MockAccessibilityPermissionService!
    var mover: NotificationMover!

    override func setUp() {
        super.setUp()
        mockAXService = MockAccessibilityAPIService()
        mockObserverService = MockAXObserverService()
        mockPermissionService = MockAccessibilityPermissionService()

        mover = NotificationMover(
            axService: mockAXService,
            observerService: mockObserverService,
            permissionService: mockPermissionService
        )
    }

    func testMoveNotificationUsesService() {
        // Test: moveNotification calls axService.getPosition
        // Test: moveNotification calls axService.setSize
        // Verify business logic is correct
    }
}
```

### 5.3 Version-Specific Tests

```swift
final class MacOSVersionTests: XCTestCase {

    func testSequoiaPositioning() {
        // Test: macOS 15 positioning strategy
        // Verify window vs banner selection
    }

    func testSonomaPositioning() {
        // Test: macOS 14 positioning strategy
        // Verify always uses banner
    }
}
```

---

## 6. BENEFITS OF THIS DESIGN

### 6.1 Testability

**Before:**
- Direct AX API calls impossible to mock
- Tests require actual accessibility permissions
- Tests fail on CI/CD without proper setup

**After:**
- All AX operations behind protocols
- Easy to mock for testing
- Tests run without permissions
- Fast, reliable unit tests

### 6.2 Maintainability

**Before:**
- 47 AX API calls scattered across 3000+ lines
- Duplicate AX logic in multiple methods
- Hard to understand AX usage patterns

**After:**
- All AX operations centralized in services
- Clear separation: AX operations vs business logic
- Easy to update AX API usage

### 6.3 Version Compatibility

**Before:**
- Version checks mixed with business logic
- Hard to add support for new macOS versions
- Risk of breaking older versions

**After:**
- Version-specific logic in service layer
- Easy to add new version strategies
- Clear version boundaries

### 6.4 Code Reusability

**Before:**
- AX code locked in NotificationMover
- Can't reuse in other components

**After:**
- Services can be used anywhere
- Consistent AX API usage across app
- Share mock implementations

---

## 7. ESTIMATED IMPACT

### 7.1 Code Reduction

- **Current NotificationMover.swift:** 3013 lines
- **After extraction:** ~1800 lines (40% reduction)
- **New service code:** ~600 lines
- **Net change:** -613 lines (-20%)

### 7.2 Test Coverage

- **Current:** Limited tests (AX APIs hard to mock)
- **After:** Comprehensive coverage possible
- **Target:** 80%+ coverage for service layer

### 7.3 Implementation Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Create Protocols & Services | 1-2 hours | None |
| Phase 2: Refactor NotificationMover | 2-3 hours | Phase 1 |
| Phase 3: Update/Create Tests | 1 hour | Phase 2 |
| Phase 4: Documentation | 30 min | Phase 2 |
| **Total** | **4.5-6.5 hours** | |

---

## 8. OPEN QUESTIONS & DECISIONS

### 8.1 Dependency Injection

**Question:** Should we use a DI framework or manual injection?

**Recommendation:** Manual injection (constructor injection)
- Simpler for current codebase size
- No external dependencies
- Sufficient for current needs

### 8.2 Service Scope

**Question:** Should AXElementManager be merged into AccessibilityAPIService?

**Recommendation:** Yes, merge and consolidate
- AXElementManager has overlapping functionality
- Single source of truth for AX operations
- Reduces confusion about which to use

### 8.3 Error Handling

**Question:** Should service methods throw errors or return optionals?

**Recommendation:** Return optionals for consistency with current code
- Matches existing patterns in NotificationMover
- Simpler error handling
- Can add throwing methods later if needed

### 8.4 Observer Lifecycle

**Question:** Who owns the observer lifecycle?

**Recommendation:** NotificationMover owns, but creates via service
- Service provides factory methods
- NotificationMover manages start/stop
- Clear separation of concerns

---

## 9. NEXT STEPS

1. **Review this design** with team/stakeholders
2. **Create GitHub issue** tracking implementation
3. **Begin Phase 1** - Create protocol files
4. **Update progress** every 60 seconds during implementation
5. **Test thoroughly** after each phase

---

## APPENDIX A: File Structure

```
Notimanager/
├── Protocols/
│   ├── NotificationMoverProtocols.swift (existing)
│   └── AccessibilityAPIProtocol.swift (NEW)
│       ├── AccessibilityAPIProtocol
│       ├── AXObserverProtocol
│       └── AccessibilityPermissionProtocol
├── Services/
│   ├── AccessibilityAPIService.swift (NEW)
│   ├── AXObserverService.swift (NEW)
│   └── AccessibilityPermissionService.swift (NEW)
├── Managers/
│   ├── NotificationMover.swift (MODIFIED - reduces from 3013 to ~1800 lines)
│   ├── AXElementManager.swift (DEPRECATED - merge into AccessibilityAPIService)
│   └── AccessibilityManager.swift (UNCHANGED - different purpose)
└── Tests/
    └── Utilities/
        ├── MockAccessibilityAPIService.swift (NEW)
        ├── MockAXObserverService.swift (NEW)
        └── MockAccessibilityPermissionService.swift (NEW)
```

---

## APPENDIX B: Quick Reference - AX Operations Migration

| Current Method | New Service Method | Protocol |
|----------------|-------------------|----------|
| `getPosition(of:)` | `axService.getPosition(of:)` | AccessibilityAPIProtocol |
| `getSize(of:)` | `axService.getSize(of:)` | AccessibilityAPIProtocol |
| `setPosition(_:x:y:)` | `axService.setPosition(of:x:y:)` | AccessibilityAPIProtocol |
| `findElementWithSubrole(_:targetSubroles:)` | `axService.findElementBySubrole(root:targetSubroles:osVersion:)` | AccessibilityAPIProtocol |
| `setupObserver()` | `observerService.createObserver(pid:callback:)` | AXObserverProtocol |
| `AXIsProcessTrusted()` | `permissionService.checkTrusted()` | AccessibilityPermissionProtocol |
| `AXUIElementCreateApplication(pid)` | `axService.createApplicationElement(pid:)` | AccessibilityAPIProtocol |

---

**END OF REPORT**

*Prepared by Agent 04 - Accessibility API Service Extraction Squad*
*Date: 2025-01-15*
*Status: Ready for Implementation*
