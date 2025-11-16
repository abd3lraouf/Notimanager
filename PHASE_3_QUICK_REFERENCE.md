# Phase 3 Quick Reference - Method Removal Guide

**For rapid lookup during cleanup execution.**

---

## 🗑️ DELETE THESE METHODS (Safe to Remove)

### AX Operations (Lines 1973-2145)
```
getPosition(of:)                    → Line 1973
getSize(of:)                        → Line 2039
setPosition(_:x:y:)                 → Line 2071
getPositionableElement(window:banner:) → Line 2085
verifyPositionSet(_:expected:)      → Line 2128
```

### Element Finding (Lines 2147-2401)
```
findElementWithSubrole(root:targetSubroles:)     → Line 2147
findNotificationElementFallback(root:)            → Line 2255
findElementByIdentifier(root:identifier:...)      → Line 2307
findElementByRoleAndSize(root:role:minWidth:...)  → Line 2330
findDeepestSizedElement(root:minWidth:...)        → Line 2354
findAnyElementWithSize(root:minWidth:...)         → Line 2382
```

### Debug Utilities (Lines 2403-2457)
```
logElementDetails(_:label:)                     → Line 2403
collectAllSubrolesInHierarchy(_:depth:maxDepth:foundSubroles:) → Line 2429
collectAllSubrolesInHierarchy(_:)                → Line 2447
```

### Position Calculation (Lines 1989-2025)
```
calculateNewPosition(notifSize:padding:)         → Line 1989
```

### Widget Detection (Lines 1936-1971)
```
hasNotificationCenterUI()                       → Line 1936
findElementWithWidgetIdentifier(root:)           → Line 1945
checkForWidgetChanges()                         → Line 1918
```

---

## 🔄 UPDATE THESE METHODS (Refactor Required)

### Diagnostic Methods
```
Line 912:  diagnosticTestAccessibility()
           → Replace getSize/getPosition with axElementManager calls

Line 966:  diagnosticTrySetPosition()
           → Replace getSize/getPosition with axElementManager calls

Line 1028: diagnosticAnalyzeNCPanel()
           → Replace getSize/getPosition with axElementManager calls

Line 1097: diagnosticTestSubroles()
           → Replace findElementWithSubrole with axElementManager version
```

### Search & Replace Patterns
```
FIND:                   getSize(of:
REPLACE WITH:           axElementManager.getSize(of:

FIND:                   getPosition(of:
REPLACE WITH:           axElementManager.getPosition(of:

FIND:                   setPosition(
REPLACE WITH:           axElementManager.setPosition(

FIND:                   findElementWithSubrole(root:
REPLACE WITH:           axElementManager.findElementBySubrole(
                        root:targetSubroles:osVersion:
```

---

## ✅ KEEP THESE METHODS (Do Not Remove)

### Application Lifecycle
```
applicationDidFinishLaunching(_:)      → Line 97
applicationWillBecomeActive(_:)         → Line 131
applicationWillTerminate(_:)            → Line 148
```

### Permission Management
```
checkAccessibilityPermissions()         → Line 162
showPermissionStatusWindow()            → Line 184
requestAccessibilityPermission()        → Line 467
resetAccessibilityPermission()          → Line 412
startPermissionPolling()                → Line 488
updatePermissionStatus(granted:)        → Line 532
```

### Menu Bar
```
setupStatusItem()                       → Line 600
updateMenuBarIcon()                     → Line 612
createMenu()                            → Line 620
```

### Diagnostics
```
createDiagnosticWindow()                → Line 679
diagnosticSendTestNotification()        → Line 826
diagnosticScanWindows()                 → Line 873
diagnosticClearOutput()                 → Line 821
diagnosticTestAccessibility()           → Line 912 (update only)
diagnosticTrySetPosition()              → Line 966 (update only)
diagnosticAnalyzeNCPanel()              → Line 1028 (update only)
diagnosticTestSubroles()                → Line 1097 (update only)
```

### Core Movement
```
moveNotification(_:)                    → Line 1626
moveAllNotifications()                  → Line 1758
cacheInitialNotificationData(notifSize:) → Line 1604
```

### Observer Setup
```
setupObserver()                         → Line 1865
setupNotificationCenterObserver()       → Line 1878
observerCallback(...)                   → Line 2533
```

### Configuration
```
configurationDidChange(_:)              → Line 2512
```

### Utilities
```
getWindowIdentifier(_:)                 → Line 1906
getWindowTitle(_:)                      → Line 2027
dumpElementHierarchy(_:label:depth:maxDepth:) → Line 2459
logSystemInfo()                         → Line 2501
```

---

## 📊 Progress Tracker

### Step 1: Update Diagnostics
- [ ] diagnosticTestAccessibility updated
- [ ] diagnosticTrySetPosition updated
- [ ] diagnosticAnalyzeNCPanel updated
- [ ] diagnosticTestSubroles updated
- [ ] Build succeeds
- [ ] All diagnostic buttons work

### Step 2: Remove AX Methods
- [ ] getPosition deleted
- [ ] getSize deleted
- [ ] setPosition deleted
- [ ] getPositionableElement deleted
- [ ] verifyPositionSet deleted
- [ ] Build succeeds

### Step 3: Remove Finding Methods
- [ ] findElementWithSubrole deleted
- [ ] findNotificationElementFallback deleted
- [ ] findElementByIdentifier deleted
- [ ] findElementByRoleAndSize deleted
- [ ] findDeepestSizedElement deleted
- [ ] findAnyElementWithSize deleted
- [ ] Build succeeds
- [ ] Notifications move correctly

### Step 4: Remove Debug Utilities
- [ ] logElementDetails deleted
- [ ] collectAllSubrolesInHierarchy (both) deleted
- [ ] Build succeeds

### Step 5: Remove Position Calculation
- [ ] calculateNewPosition deleted
- [ ] Build succeeds
- [ ] All 9 positions work

### Step 6: Remove Widget Methods
- [ ] hasNotificationCenterUI deleted
- [ ] findElementWithWidgetIdentifier deleted
- [ ] checkForWidgetChanges deleted
- [ ] Build succeeds
- [ ] NC open/close works

### Step 7: Remove Properties
- [ ] hasLoggedEmptyWidget removed
- [ ] lastWidgetWindowCount removed
- [ ] pollingEndTime removed
- [ ] Build succeeds

### Step 8: Final Cleanup
- [ ] Unused imports removed
- [ ] File header updated
- [ ] MARK comments cleaned up
- [ ] Documentation updated
- [ ] Final build succeeds
- [ ] Full regression test passed

---

## 🚨 Common Pitfalls

### Don't Forget
- ⚠️ Update ALL call sites before removing methods
- ⚠️ Include osVersion parameter in axElementManager calls
- ⚠️ Test diagnostic window after each refactoring
- ⚠️ Commit after each successful step

### Watch Out For
- ⚠️ Methods with same name but different signatures
- ⚠️ Calls from diagnostic methods (easy to miss)
- ⚠️ Optional chaining in method calls
- ⚠️ Property access vs method calls

### Validation Commands
```bash
# Build
xcodebuild -project Notimanager.xcodeproj -scheme Notimanager build

# Count lines
wc -l Notimanager/Managers/NotificationMover.swift

# Search for remaining direct calls
grep -n "getSize(of:" Notimanager/Managers/NotificationMover.swift
grep -n "getPosition(of:" Notimanager/Managers/NotificationMover.swift
grep -n "setPosition(" Notimanager/Managers/NotificationMover.swift
```

---

## 📞 Rollback Commands

```bash
# Undo all changes
git checkout -- Notimanager/Managers/NotificationMover.swift

# Undo last step (if committed)
git revert HEAD

# Check diff
git diff Notimanager/Managers/NotificationMover.swift
```

---

**Quick Reference for Phase 3 execution. Keep this open while working!**
