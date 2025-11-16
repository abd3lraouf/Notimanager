# Phase 3 Execution Checklist

**Print this out and check off each item as you complete it.**

---

## ✅ PRE-EXECUTION CHECKLIST

### Environment Setup
- [ ] Git repository is clean (no uncommitted changes)
- [ ] Current branch: `main` (or feature branch)
- [ ] Xcode is closed
- [ ] Backup created: `git branch phase3-backup`
- [ ] Read full PHASE_3_CLEANUP_PLAN.md
- [ ] Read PHASE_3_QUICK_REFERENCE.md
- [ ] Have 2+ hours available for execution

### Validation Tools Ready
- [ ] Console.app open (filtered for "Notimanager")
- [ ] Test notification script ready
- [ ] Multiple monitors (to test all positions)
- [ ] Notimanager app built and working

---

## 📋 EXECUTION STEPS

### STEP 1: Update Diagnostic Methods (30 min)

#### 1.1 Update diagnosticTestAccessibility
- [ ] Open NotificationMover.swift to line 912
- [ ] Find `getSize(of: window)` at line 930
- [ ] Replace with `axElementManager.getSize(of: window)`
- [ ] Find `getSize(of: banner)` at line 945
- [ ] Replace with `axElementManager.getSize(of: banner)`
- [ ] Find `getPosition(of: banner)` at line 982
- [ ] Replace with `axElementManager.getPosition(of: banner)`
- [ ] Find `findElementWithSubrole(root: window, targetSubroles: notificationSubroles)` at line 944
- [ ] Replace with `axElementManager.findElementBySubrole(root: window, targetSubroles: notificationSubroles, osVersion: osVersion)`

#### 1.2 Update diagnosticTrySetPosition
- [ ] Open NotificationMover.swift to line 966
- [ ] Replace all `getSize(of:` calls with `axElementManager.getSize(of:`
- [ ] Replace all `getPosition(of:` calls with `axElementManager.getPosition(of:`
- [ ] Count replacements: Should be 5 total

#### 1.3 Update diagnosticAnalyzeNCPanel
- [ ] Open NotificationMover.swift to line 1028
- [ ] Replace `getSize(of:` with `axElementManager.getSize(of:`
- [ ] Replace `getPosition(of:` with `axElementManager.getPosition(of:`
- [ ] Replace `findElementWithSubrole` with `axElementManager.findElementBySubrole(..., osVersion: osVersion)`

#### 1.4 Update diagnosticTestSubroles
- [ ] Open NotificationMover.swift to line 1097
- [ ] Replace `findElementWithSubrole` call with `axElementManager.findElementBySubrole(..., osVersion: osVersion)`

#### 1.5 Validate Step 1
- [ ] Build project: `xcodebuild build` (or Cmd+B in Xcode)
- [ ] Build succeeds with 0 errors
- [ ] Build succeeds with 0 warnings
- [ ] Run app
- [ ] Open Diagnostic window (Cmd+D)
- [ ] Click "Test Accessibility API" - works ✓
- [ ] Click "Try Set Position" - works ✓
- [ ] Click "Analyze NC Panel" - works ✓
- [ ] Click "Test macOS 26 Subroles" - works ✓
- [ ] Close Diagnostic window
- [ ] Commit: `git commit -am "Phase 3 Step 1: Updated diagnostic methods to use AXElementManager"`

---

### STEP 2: Remove Redundant AX Methods (15 min)

#### 2.1 Delete getPosition
- [ ] Go to line 1973
- [ ] Select lines 1973-1987 (entire `getPosition(of:)` method)
- [ ] Delete
- [ ] Verify no compilation errors

#### 2.2 Delete getSize
- [ ] Go to line 2039
- [ ] Select lines 2039-2069 (entire `getSize(of:)` method)
- [ ] Delete
- [ ] Verify no compilation errors

#### 2.3 Delete setPosition
- [ ] Go to line 2071
- [ ] Select lines 2071-2083 (entire `setPosition(_:x:y:)` method)
- [ ] Delete
- [ ] Verify no compilation errors

#### 2.4 Delete getPositionableElement
- [ ] Go to line 2085
- [ ] Select lines 2085-2126 (entire `getPositionableElement(window:banner:)` method)
- [ ] Delete
- [ ] Verify no compilation errors

#### 2.5 Delete verifyPositionSet
- [ ] Go to line 2128
- [ ] Select lines 2128-2145 (entire `verifyPositionSet(_:expected:)` method)
- [ ] Delete
- [ ] Verify no compilation errors

#### 2.6 Validate Step 2
- [ ] Build project
- [ ] Build succeeds
- [ ] Run app
- [ ] Send test notification
- [ ] Notification appears at correct position
- [ ] Commit: `git commit -am "Phase 3 Step 2: Removed redundant AX element methods"`

---

### STEP 3: Remove Element Finding Methods (20 min)

#### 3.1 Delete findElementWithSubrole
- [ ] Go to line 2147
- [ ] Select lines 2147-2253
- [ ] Delete
- [ ] Verify no compilation errors

#### 3.2 Delete findNotificationElementFallback
- [ ] Go to line 2255
- [ ] Select lines 2255-2305
- [ ] Delete
- [ ] Verify no compilation errors

#### 3.3 Delete findElementByIdentifier
- [ ] Go to line 2307
- [ ] Select lines 2307-2328
- [ ] Delete
- [ ] Verify no compilation errors

#### 3.4 Delete findElementByRoleAndSize
- [ ] Go to line 2330
- [ ] Select lines 2330-2352
- [ ] Delete
- [ ] Verify no compilation errors

#### 3.5 Delete findDeepestSizedElement
- [ ] Go to line 2354
- [ ] Select lines 2354-2380
- [ ] Delete
- [ ] Verify no compilation errors

#### 3.6 Delete findAnyElementWithSize
- [ ] Go to line 2382
- [ ] Select lines 2382-2401
- [ ] Delete
- [ ] Verify no compilation errors

#### 3.7 Validate Step 3
- [ ] Build project
- [ ] Build succeeds
- [ ] Run app
- [ ] Test all 9 positions:
  - [ ] Top Left
  - [ ] Top Middle
  - [ ] Top Right
  - [ ] Middle Left
  - [ ] Dead Center
  - [ ] Middle Right
  - [ ] Bottom Left
  - [ ] Bottom Middle
  - [ ] Bottom Right
- [ ] Commit: `git commit -am "Phase 3 Step 3: Removed element finding methods"`

---

### STEP 4: Remove Debug Utilities (10 min)

#### 4.1 Delete logElementDetails
- [ ] Go to line 2403
- [ ] Select lines 2403-2427
- [ ] Delete
- [ ] Verify no compilation errors

#### 4.2 Delete collectAllSubrolesInHierarchy (first version)
- [ ] Go to line 2429
- [ ] Select lines 2429-2445
- [ ] Delete
- [ ] Verify no compilation errors

#### 4.3 Delete collectAllSubrolesInHierarchy (second version)
- [ ] Go to line 2447
- [ ] Select lines 2447-2457
- [ ] Delete
- [ ] Verify no compilation errors

#### 4.4 Validate Step 4
- [ ] Build project
- [ ] Build succeeds
- [ ] Commit: `git commit -am "Phase 3 Step 4: Removed debug utilities"`

---

### STEP 5: Remove Position Calculation (5 min)

#### 5.1 Delete calculateNewPosition
- [ ] Go to line 1989
- [ ] Select lines 1989-2025
- [ ] Delete
- [ ] Verify no compilation errors

#### 5.2 Validate Step 5
- [ ] Build project
- [ ] Build succeeds
- [ ] Run app
- [ ] Test notification positioning
- [ ] All positions work correctly
- [ ] Commit: `git commit -am "Phase 3 Step 5: Removed position calculation method"`

---

### STEP 6: Remove Widget Methods (10 min)

#### 6.1 Pre-removal Verification
- [ ] Confirm widgetMonitor.startMonitoring() called at line 1873
- [ ] Confirm widgetMonitor.stopMonitoring() called at line 152
- [ ] Test Notification Center open/close behavior
- [ ] Notifications reposition when NC closes

#### 6.2 Delete hasNotificationCenterUI
- [ ] Go to line 1936
- [ ] Select lines 1936-1943
- [ ] Delete
- [ ] Verify no compilation errors

#### 6.3 Delete findElementWithWidgetIdentifier
- [ ] Go to line 1945
- [ ] Select lines 1945-1971
- [ ] Delete
- [ ] Verify no compilation errors

#### 6.4 Delete checkForWidgetChanges
- [ ] Go to line 1918
- [ ] Select lines 1918-1934
- [ ] Delete
- [ ] Verify no compilation errors

#### 6.5 Validate Step 6
- [ ] Build project
- [ ] Build succeeds
- [ ] Run app
- [ ] Open Notification Center
- [ ] Close Notification Center
- [ ] Notifications move back to correct position
- [ ] Commit: `git commit -am "Phase 3 Step 6: Removed legacy widget methods"`

---

### STEP 7: Remove State Properties (5 min)

#### 7.1 Remove hasLoggedEmptyWidget
- [ ] Search for `hasLoggedEmptyWidget`
- [ ] Remove property declaration
- [ ] Remove all usages
- [ ] Verify no compilation errors

#### 7.2 Remove lastWidgetWindowCount
- [ ] Search for `lastWidgetWindowCount`
- [ ] Remove property declaration
- [ ] Remove all usages
- [ ] Verify no compilation errors

#### 7.3 Remove pollingEndTime
- [ ] Search for `pollingEndTime`
- [ ] Remove property declaration
- [ ] Remove all usages
- [ ] Verify no compilation errors

#### 7.4 Validate Step 7
- [ ] Build project
- [ ] Build succeeds
- [ ] Run app
- [ ] No runtime errors
- [ ] Commit: `git commit -am "Phase 3 Step 7: Removed obsolete state properties"`

---

### STEP 8: Final Cleanup (30 min)

#### 8.1 Code Cleanup
- [ ] Remove unused imports (if any)
- [ ] Update file header comment
- [ ] Clean up MARK comments
- [ ] Remove trailing whitespace
- [ ] Fix any lingering warnings

#### 8.2 Line Count Verification
- [ ] Run: `wc -l Notimanager/Managers/NotificationMover.swift`
- [ ] Current line count: _______
- [ ] Target line count: ~1800
- [ ] Lines removed: _______ (target: ~800)

#### 8.3 Documentation
- [ ] Update PHASE_3_CLEANUP_PLAN.md with actual results
- [ ] Note any deviations from plan
- [ ] Document any issues encountered
- [ ] Create PHASE_4_PLAN.md (if applicable)

#### 8.4 Final Build
- [ ] Clean build folder: `Cmd+Shift+K`
- [ ] Build project: `Cmd+B`
- [ ] Build succeeds with 0 errors
- [ ] Build succeeds with 0 warnings

#### 8.5 Final Testing (Regression Test)
- [ ] App launches without crash
- [ ] Menu bar icon visible
- [ ] Settings window opens (Cmd+,)
- [ ] Diagnostic window opens (Cmd+D)
- [ ] All 6 diagnostic buttons work
- [ ] Send test notification - works
- [ ] Test all 9 positions - all work
- [ ] Enable/Disable toggle - works
- [ ] Permission window shows (if not granted)
- [ ] About window opens
- [ ] Quit app - works

#### 8.6 Final Commit
- [ ] Commit: `git commit -am "Phase 3 Step 8: Final cleanup and documentation"`
- [ ] Push to remote: `git push`
- [ ] Create PR (if on feature branch)

---

## ✅ POST-EXECUTION CHECKLIST

### Verification
- [ ] All 8 steps completed
- [ ] All commits pushed
- [ ] No regressions detected
- [ ] Line count reduced by ~800
- [ ] Documentation updated

### Metrics
- [ ] Starting line count: 2628
- [ ] Ending line count: _______
- [ ] Lines removed: _______
- [ ] Methods removed: 25
- [ ] Methods refactored: 4
- [ ] Time taken: _______

### Known Issues
- [ ] None (ideal)
- [ ] Document any issues found:
    _________________________________
    _________________________________
    _________________________________

### Next Steps
- [ ] Monitor for bug reports
- [ ] Plan Phase 4 (if needed)
- [ ] Update user documentation
- [ ] Celebrate! 🎉

---

## 🚨 EMGENCY ROLLBACK

If something goes wrong:

1. **Stop immediately**
2. **Identify the last working step**
3. **Rollback:** `git checkout -- Notimanager/Managers/NotificationMover.swift`
4. **Or revert commits:** `git revert HEAD`
5. **Report issue** with details
6. **Do not proceed** until issue is resolved

---

**Checklist complete. Ready for Phase 3 execution!**
