# Phase 3 Cleanup Plan - Comprehensive Guide

**Agent:** Agent 10
**Date:** 2025-01-15
**Status:** Ready for Execution
**Current File Size:** 2628 lines (NotificationMover.swift)

---

## Executive Summary

Phase 1 & 2 successfully extracted core services (Logging, Configuration, AX Elements, Positioning, Window Monitoring, Widget Monitoring). Phase 3 focuses on **removing redundant code** while maintaining **backward compatibility** and **diagnostic functionality**.

**Target:** Reduce NotificationMover.swift from 2628 lines to ~1800 lines (~800 lines removed)

---

## 1. IMMEDIATE REMOVALS (Safe to Delete)

These methods are **100% duplicated** by extracted services and can be deleted immediately.

### 1.1 AX Element Operations (Lines ~1973-2145)

**DUPLICATED BY:** `AXElementManager.swift`

| Method | Lines | Replacement |
|--------|-------|-------------|
| `getPosition(of:)` | 1973-1987 | `axElementManager.getPosition(of:)` |
| `getSize(of:)` | 2039-2069 | `axElementManager.getSize(of:)` |
| `setPosition(_:x:y:)` | 2071-2083 | `axElementManager.setPosition(of:x:y:)` |
| `getPositionableElement(window:banner:)` | 2085-2126 | `axElementManager.getPositionableElement(window:banner:osVersion:)` |
| `verifyPositionSet(_:expected:)` | 2128-2145 | `axElementManager.verifyPositionSet(_:expected:)` |

**Justification:** These are simple wrappers around AX API calls. The extracted `AXElementManager` provides identical functionality with enhanced error handling and retry logic.

**Action:** Delete lines 1973-2145 (~173 lines)

---

### 1.2 Element Finding Methods (Lines ~2147-2401)

**DUPLICATED BY:** `AXElementManager.swift`

| Method | Lines | Replacement |
|--------|-------|-------------|
| `findElementWithSubrole(root:targetSubroles:)` | 2147-2253 | `axElementManager.findElementBySubrole(root:targetSubroles:osVersion:)` |
| `findNotificationElementFallback(root:)` | 2255-2305 | `axElementManager.findElementUsingFallbacks(root:osVersion:)` |
| `findElementByIdentifier(root:identifier:currentDepth:maxDepth:)` | 2307-2328 | `axElementManager.findElementByIdentifier(root:identifier:currentDepth:maxDepth:)` |
| `findElementByRoleAndSize(root:role:minWidth:minHeight:maxWidth:maxHeight:)` | 2330-2352 | `axElementManager.findElementByRoleAndSize(root:role:sizeConstraints:)` |
| `findDeepestSizedElement(root:minWidth:maxWidth:maxHeight:currentDepth:maxDepth:)` | 2354-2380 | `axElementManager.findDeepestSizedElement(root:sizeConstraints:currentDepth:maxDepth:)` |
| `findAnyElementWithSize(root:minWidth:maxWidth:minHeight:maxHeight:)` | 2382-2401 | `axElementManager.findAnyElementWithSize(root:sizeConstraints:)` |

**Justification:** Complex element discovery logic with identical implementation. Extracted version includes better documentation and SizeConstraints struct.

**Action:** Delete lines 2147-2401 (~254 lines)

---

### 1.3 Element Information & Diagnostics (Lines ~2403-2457)

**DUPLICATED BY:** `AXElementManager.swift`

| Method | Lines | Replacement |
|--------|-------|-------------|
| `logElementDetails(_:label:)` | 2403-2427 | `axElementManager.logElementDetails(_:label:)` |
| `collectAllSubrolesInHierarchy(_:depth:maxDepth:foundSubroles:)` | 2429-2445 | `axElementManager.collectAllSubrolesInHierarchy(_:depth:maxDepth:)` |
| `collectAllSubrolesInHierarchy(_:)` | 2447-2457 | `axElementManager.collectAllSubrolesInHierarchy(_:depth:maxDepth:)` |

**Justification:** Debug utilities completely replicated in AXElementManager.

**Action:** Delete lines 2403-2457 (~54 lines)

---

### 1.4 Position Calculation (Lines ~1989-2025)

**DUPLICATED BY:** `NotificationPositioningService.swift`

| Method | Lines | Replacement |
|--------|-------|-------------|
| `calculateNewPosition(notifSize:padding:)` | 1989-2025 | `positioningService.calculatePosition(notifSize:padding:currentPosition:screenBounds:)` |

**Justification:** Position calculation logic is centralized in NotificationPositioningService with added validation.

**Action:** Delete lines 1989-2025 (~36 lines)

---

### 1.5 Widget Detection (Lines ~1945-1971)

**DUPLICATED BY:** `WidgetMonitorService.swift`

| Method | Lines | Replacement |
|--------|-------|-------------|
| `findElementWithWidgetIdentifier(root:)` | 1945-1971 | `widgetMonitor` internal method |

**Justification:** Widget monitoring is now handled by WidgetMonitorService. This duplicate is only used by removed methods.

**Action:** Delete lines 1945-1971 (~26 lines)

---

### 1.6 Obsolete Constants & State

**DUPLICATED BY:** Service properties

| Property | Lines | Justification |
|----------|-------|---------------|
| `hasLoggedEmptyWidget` | (removed from state) | Now handled by WidgetMonitorService |
| `lastWidgetWindowCount` | (removed from state) | Now managed by WidgetMonitorService |
| `pollingEndTime` | (removed from state) | Now managed by WidgetMonitorService |

**Action:** Remove these properties from NotificationMover class

---

## 2. REFACTORING REQUIRED

These methods need updates before their dependencies can be removed.

### 2.1 Diagnostic Methods (Lines ~873-1165)

**STATUS:** Keep but update to use services

| Method | Lines | Changes Needed |
|--------|-------|----------------|
| `diagnosticTestAccessibility()` | 912-962 | Replace direct AX calls with `axElementManager` methods |
| `diagnosticTrySetPosition()` | 966-1027 | Replace `getPosition/setPosition` with `axElementManager` calls |
| `diagnosticAnalyzeNCPanel()` | 1028-1067 | Update to use `axElementManager.findElementBySubrole()` |
| `diagnosticTestSubroles()` | 1097-1155 | Update to use `axElementManager.collectAllSubrolesInHierarchy()` |

**Action:** Update these methods to call service layer instead of direct AX API

**Example Refactoring:**

```swift
// BEFORE (line 930):
if let size = getSize(of: window) {

// AFTER:
if let size = axElementManager.getSize(of: window) {
```

---

### 2.2 Notification Movement Logic (Lines ~1626-1756)

**STATUS:** Partially updated, needs completion

**Current State:**
- Already uses `axElementManager` in some places (lines 1640-1740)
- Still has local `getPosition/setSize/setPosition` calls in diagnostic code

**Changes Needed:**

| Line Range | Current Call | Replace With |
|------------|--------------|--------------|
| 930, 945, 982, 996, 1006, 1047, 1049, 1078, 1128, 1132, 1133, 1136 | `getSize(of:)` | `axElementManager.getSize(of:)` |
| 982, 996, 1006, 1136 | `getPosition(of:)` | `axElementManager.getPosition(of:)` |
| 944, 1132 | `findElementWithSubrole(root:targetSubroles:)` | `axElementManager.findElementBySubrole(root:targetSubroles:osVersion:)` |

**Action:** Search and replace all remaining direct AX method calls

---

### 2.3 Legacy Widget Monitoring (Lines ~1918-1934)

**STATUS:** Remove after verification

| Method | Lines | Justification |
|--------|-------|---------------|
| `checkForWidgetChanges()` | 1918-1934 | Replaced by `WidgetMonitorService` |

**Verification Needed:**
1. Confirm `widgetMonitor.startMonitoring()` is called in `setupObserver()` (line 1873) ✅
2. Confirm `widgetMonitor.stopMonitoring()` is called in `applicationWillTerminate()` (line 152) ✅

**Action:** Delete lines 1918-1934 after confirming WidgetMonitorService is working

---

### 2.4 NC UI Detection (Lines ~1936-1943)

**STATUS:** Remove after verification

| Method | Lines | Justification |
|--------|-------|---------------|
| `hasNotificationCenterUI()` | 1936-1943 | Replaced by `widgetMonitor.hasNotificationCenterUI()` |

**Verification Needed:**
1. No remaining callers in NotificationMover
2. WidgetMonitorService implementation is complete

**Action:** Delete lines 1936-1943

---

## 3. PRESERVE THESE (Do NOT Remove)

These methods must stay in NotificationMover for backward compatibility and diagnostic functionality.

### 3.1 Application Lifecycle (Lines ~97-154)

**REASON:** Core app delegate methods

| Method | Lines | Purpose |
|--------|-------|---------|
| `applicationDidFinishLaunching(_:)` | 97-118 | App initialization, service wiring |
| `applicationWillBecomeActive(_:)` | 131-146 | Permission re-check on activation |
| `applicationWillTerminate(_:)` | 148-154 | Cleanup services |

**Action:** KEEP - No changes needed

---

### 3.2 Permission Management (Lines ~120-598)

**REASON:** User-facing permission UI, not extracted

| Method | Lines | Purpose |
|--------|-------|---------|
| `checkAccessibilityPermissions()` | 162-182 | Initial permission check |
| `showPermissionStatusWindow()` | 184-410 | Complex UI with golden ratio layout |
| `requestAccessibilityPermission()` | 467-486 | System permission prompt |
| `resetAccessibilityPermission()` | 412-465 | tccutil reset for troubleshooting |
| `startPermissionPolling()` | 488-506 | Permission status polling |
| `updatePermissionStatus(granted:)` | 532-598 | UI state updates |

**Action:** KEEP - These are unique to NotificationMover

---

### 3.3 Menu Bar Management (Lines ~600-648)

**REASON:** Status item and menu creation

| Method | Lines | Purpose |
|--------|-------|---------|
| `setupStatusItem()` | 600-609 | Create status item |
| `updateMenuBarIcon()` | 612-618 | Update icon based on state |
| `createMenu()` | 620-648 | Build menu structure |

**Action:** KEEP - Menu bar logic is app-specific

---

### 3.4 Diagnostic Window (Lines ~671-871)

**REASON:** User-facing diagnostic tools

| Method | Lines | Purpose |
|--------|-------|---------|
| `createDiagnosticWindow()` | 679-819 | Diagnostic UI with test buttons |
| `diagnosticSendTestNotification()` | 826-871 | Test notification with interception tracking |
| `diagnosticScanWindows()` | 873-910 | Scan for notification-sized windows |
| `diagnosticClearOutput()` | 821-824 | Clear diagnostic text view |

**Action:** KEEP - Essential for user troubleshooting

---

### 3.5 Settings Window (Lines ~1156-1492)

**REASON:** User settings UI (already extracted to SettingsWindow.swift but kept for compatibility)

**Note:** This should eventually be removed once SettingsWindow.swift is confirmed working, but KEEP for Phase 3 safety.

---

### 3.6 Core Movement Logic (Lines ~1626-1778)

**REASON:** Orchestrates the entire movement process

| Method | Lines | Purpose |
|--------|-------|---------|
| `moveNotification(_:)` | 1626-1756 | Main movement orchestration |
| `moveAllNotifications()` | 1758-1778 | Batch movement |
| `cacheInitialNotificationData(notifSize:)` | 1604-1624 | Cache management |

**Action:** KEEP - This is the core business logic

---

### 3.7 Observer Setup (Lines ~1865-1904)

**REASON:** AX observer initialization

| Method | Lines | Purpose |
|--------|-------|---------|
| `setupObserver()` | 1865-1876 | Initialize all observers |
| `setupNotificationCenterObserver()` | 1878-1904 | Create AX observer for NC |

**Action:** KEEP - Observer creation is app-specific

---

### 3.8 Configuration Observer (Lines ~2512-2531)

**REASON:** Responds to configuration changes

| Method | Lines | Purpose |
|--------|-------|---------|
| `configurationDidChange(_:)` | 2512-2531 | Handle config change events |

**Action:** KEEP - Implements ConfigurationManager.ConfigurationObserver

---

### 3.9 Internal Helper Methods (Lines ~2570-2628)

**REASON:** Bridge methods for external callers

| Method | Lines | Purpose |
|--------|-------|---------|
| `updatePosition(to:)` | 2570-2580 | Public position update |
| `internalSendTestNotification()` | 2582-2585 | Test notification bridge |
| Various internal* methods | 2586-2628 | Action bridges |

**Action:** KEEP - Required for external access

---

### 3.10 Utility Methods

**REASON:** App-specific utilities

| Method | Lines | Purpose |
|--------|-------|---------|
| `getWindowIdentifier(_:)` | 1906-1916 | Get window ID (different signature than AXElementManager) |
| `getWindowTitle(_:)` | 2027-2037 | Get window title |
| `dumpElementHierarchy(_:label:depth:maxDepth:)` | 2459-2499 | Debug tree dump (used by diagnostics) |
| `logSystemInfo()` | 2501-2510 | System information logging |

**Action:** KEEP - Used by diagnostic tools

---

## 4. EXECUTION ORDER

Follow this sequence to ensure safe removal with validation checkpoints.

### Step 1: Update Diagnostic Methods (Refactoring)
**Priority:** HIGH
**Risk:** LOW
**Estimated Time:** 30 minutes

1. Update `diagnosticTestAccessibility()` (line 912)
   - Replace `getSize(of:)` with `axElementManager.getSize(of:)` (line 930, 945)
   - Replace `getPosition(of:)` with `axElementManager.getPosition(of:)` (line 982)
   - Replace `findElementWithSubrole()` with `axElementManager.findElementBySubrole()` (line 944)

2. Update `diagnosticTrySetPosition()` (line 966)
   - Replace `getPosition(of:)` calls (lines 996, 1006)
   - Replace `getSize(of:)` calls (lines 1047, 1049)

3. Update `diagnosticAnalyzeNCPanel()` (line 1028)
   - Replace `getSize(of:)` and `getPosition(of:)` calls (lines 1078, 1128, 1133, 1136)

4. Update `diagnosticTestSubroles()` (line 1097)
   - Replace `findElementWithSubrole()` with `axElementManager` version (line 1132)

**Validation:** Build and test diagnostic window

---

### Step 2: Remove Redundant AX Methods (Immediate Removal)
**Priority:** HIGH
**Risk:** MEDIUM
**Estimated Time:** 15 minutes
**Dependencies:** Step 1 complete

1. Delete `getPosition(of:)` (lines 1973-1987)
2. Delete `getSize(of:)` (lines 2039-2069)
3. Delete `setPosition(_:x:y:)` (lines 2071-2083)
4. Delete `getPositionableElement(window:banner:)` (lines 2085-2126)
5. Delete `verifyPositionSet(_:expected:)` (lines 2128-2145)

**Validation:** Build and run unit tests (if available)

---

### Step 3: Remove Element Finding Methods (Immediate Removal)
**Priority:** HIGH
**Risk:** MEDIUM
**Estimated Time:** 20 minutes
**Dependencies:** Step 2 complete

1. Delete `findElementWithSubrole(root:targetSubroles:)` (lines 2147-2253)
2. Delete `findNotificationElementFallback(root:)` (lines 2255-2305)
3. Delete `findElementByIdentifier(root:identifier:currentDepth:maxDepth:)` (lines 2307-2328)
4. Delete `findElementByRoleAndSize(root:role:minWidth:minHeight:maxWidth:maxHeight:)` (lines 2330-2352)
5. Delete `findDeepestSizedElement(root:minWidth:maxWidth:maxHeight:currentDepth:maxDepth:)` (lines 2354-2380)
6. Delete `findAnyElementWithSize(root:minWidth:maxWidth:minHeight:maxHeight:)` (lines 2382-2401)

**Validation:** Build and test notification movement

---

### Step 4: Remove Debug Utilities (Immediate Removal)
**Priority:** MEDIUM
**Risk:** LOW
**Estimated Time:** 10 minutes
**Dependencies:** Step 3 complete

1. Delete `logElementDetails(_:label:)` (lines 2403-2427)
2. Delete `collectAllSubrolesInHierarchy(_:depth:maxDepth:foundSubroles:)` (lines 2429-2445)
3. Delete `collectAllSubrolesInHierarchy(_:)` (lines 2447-2457)

**Validation:** Build and verify no compiler errors

---

### Step 5: Remove Position Calculation (Immediate Removal)
**Priority:** MEDIUM
**Risk:** LOW
**Estimated Time:** 5 minutes
**Dependencies:** Step 3 complete

1. Delete `calculateNewPosition(notifSize:padding:)` (lines 1989-2025)

**Validation:** Test notification positioning at all screen positions

---

### Step 6: Remove Legacy Widget Methods (Immediate Removal)
**Priority:** MEDIUM
**Risk:** MEDIUM
**Estimated Time:** 10 minutes
**Dependencies:** WidgetMonitorService verified working

1. Delete `findElementWithWidgetIdentifier(root:)` (lines 1945-1971)
2. Delete `hasNotificationCenterUI()` (lines 1936-1943)
3. Delete `checkForWidgetChanges()` (lines 1918-1934)

**Validation:** Test Notification Center open/close behavior

---

### Step 7: Remove Obsolete State Properties
**Priority:** LOW
**Risk:** LOW
**Estimated Time:** 5 minutes

1. Remove `hasLoggedEmptyWidget` property
2. Remove `lastWidgetWindowCount` property
3. Remove `pollingEndTime` property

**Validation:** Build and verify no runtime errors

---

### Step 8: Final Cleanup & Documentation
**Priority:** LOW
**Risk:** LOW
**Estimated Time:** 30 minutes

1. Remove unused imports (if any)
2. Update file header comment with new architecture
3. Add TODO comments for future extractions (SettingsWindow, PermissionWindow)
4. Update MARK comments for clarity

**Validation:** Final build and full manual testing

---

## 5. RISK ASSESSMENT

### High Risk Areas

| Area | Risk | Mitigation |
|------|------|------------|
| **Diagnostic Tool Breaking** | MEDIUM | Thoroughly test each diagnostic button after refactoring |
| **Widget Monitoring Regression** | MEDIUM | Verify NC open/close triggers notification movement |
| **Permission UI Regression** | LOW | No changes to permission flow in Phase 3 |
| **Notification Movement Failure** | HIGH | Test all 9 positions with real notifications |

### Medium Risk Areas

| Area | Risk | Mitigation |
|------|------|------------|
| **AX Method Signature Mismatch** | MEDIUM | Verify all call sites use correct parameter names |
| **Missing osVersion Parameter** | MEDIUM | Ensure all `axElementManager` calls include `osVersion` |
| **Configuration Observer Breakage** | LOW | Test configuration changes trigger properly |

### Low Risk Areas

| Area | Risk | Mitigation |
|------|------|------------|
| **Method Removal** | LOW | Compilers will detect missing methods |
| **Property Removal** | LOW | Unused properties don't affect runtime |

---

## 6. VALIDATION CHECKPOINTS

### After Each Step

- [ ] **Build succeeds** without errors or warnings
- [ ] **App launches** without crashes
- [ ] **Diagnostic window opens** (Cmd+D)
- [ ] **Settings window opens** (Cmd+,)
- [ ] **Menu bar icon visible** (if not hidden)

### After Step 1 (Diagnostic Updates)

- [ ] All 6 diagnostic test buttons work
- [ ] "Send Test Notification" creates notification
- [ ] "Scan All Windows" shows output
- [ ] "Test Accessibility API" completes
- [ ] "Try Set Position" executes
- [ ] "Analyze NC Panel" analyzes
- [ ] "Test macOS 26 Subroles" tests

### After Step 2-3 (AX Method Removal)

- [ ] Notifications appear at correct position
- [ ] Test all 9 position settings
- [ ] Position changes take effect immediately
- [ ] Enable/Disable toggle works
- [ ] Menu bar icon updates correctly

### After Step 6 (Widget Removal)

- [ ] Opening Notification Center triggers move
- [ ] Closing Notification Center repositions notifications
- [ ] Widget panel detection works

### Final Validation

- [ ] Full regression test (1 hour)
- [ ] Test on macOS 15 (if available)
- [ ] Test on macOS 26 (if available)
- [ ] Verify diagnostic output is informative
- [ ] Check Console.app for errors

---

## 7. ROLLBACK STRATEGIES

### If Build Fails

1. **Immediate rollback:** `git checkout -- NotificationMover.swift`
2. **Investigate:** Check compiler error for missing method
3. **Fix:** Add back the missing method or update call site

### If Runtime Error

1. **Check crash log:** Look for "unrecognized selector"
2. **Identify missing method:** Add back to NotificationMover
3. **Update call sites:** Ensure all callers use correct syntax

### If Notifications Don't Move

1. **Enable debug mode:** Toggle in Settings window
2. **Check Console.app:** Filter for "Notimanager"
3. **Run diagnostics:** Use diagnostic window
4. **Compare to pre-refactor:** `git diff HEAD~1 NotificationMover.swift`

### If Diagnostic Tools Fail

1. **Verify LoggingService:** Check `diagnosticTextView` is set
2. **Check AXElementManager:** Verify singleton is initialized
3. **Test manually:** Use Console.app to see logs

---

## 8. EXPECTED RESULTS

### Before Phase 3
- **File:** NotificationMover.swift
- **Lines:** 2628
- **Responsibilities:** 15+ (movement, UI, permissions, diagnostics, AX, monitoring, etc.)

### After Phase 3
- **File:** NotificationMover.swift
- **Lines:** ~1800 (target: 800 lines removed)
- **Responsibilities:** 8 (app lifecycle, UI, permissions, diagnostics, movement orchestration)
- **Services Used:** 6 (Logging, Configuration, AXElement, Positioning, WindowMonitor, WidgetMonitor)

### Code Quality Improvements
- ✅ Single Responsibility Principle: NotificationMover only orchestrates
- ✅ DRY: No duplicated AX logic
- ✅ Testability: Services can be mocked
- ✅ Maintainability: Changes to AX logic in one place
- ✅ Documentation: Service files are well-documented

---

## 9. POST-PHASE 3 WORK (Future)

### Phase 4 Candidates
1. **Extract DiagnosticWindow** (~400 lines)
   - Diagnostic window UI creation
   - Test button handlers
   - Diagnostic output management

2. **Extract PermissionManager** (~300 lines)
   - Permission checking logic
   - Permission window creation
   - tccutil integration

3. **Extract MenuBarManager** (~150 lines)
   - Status item management
   - Menu creation
   - Icon updates

4. **Extract SettingsWindowManager** (~500 lines)
   - Settings window UI
   - Position grid view
   - Settings handlers

**Potential Total Reduction:** Additional 1350 lines
**Final Target:** ~450 lines for NotificationMover.swift (app lifecycle + orchestration only)

---

## 10. SUMMARY

### Immediate Actions (Phase 3)
1. ✅ Update diagnostic methods to use services (Step 1)
2. ✅ Remove redundant AX methods (Steps 2-5)
3. ✅ Remove legacy widget methods (Step 6)
4. ✅ Clean up state properties (Step 7)
5. ✅ Final documentation (Step 8)

### Expected Impact
- **Lines removed:** ~800 (30% reduction)
- **Methods removed:** 25
- **Files modified:** 1 (NotificationMover.swift)
- **Risk level:** MEDIUM (mitigated by thorough testing)

### Success Criteria
- [ ] Build succeeds with zero errors
- [ ] All diagnostic tools work
- [ ] Notifications move correctly to all 9 positions
- [ ] Widget monitoring works
- [ ] No regression in user-facing features

---

**Ready for execution. Awaiting Squad Manager approval.**
