# File Structure Quick Reference
## Agent 18 - Complete Structure Design

### FOLDER STRUCTURE (One-Page View)

```
Notimanager/
├── App/                          # 2 files
│   ├── NotimanagerApp.swift
│   └── ServiceContainer.swift
│
├── Core/                         # 12 files - Foundation layer
│   ├── Models/                   # Domain models
│   ├── Protocols/                # 6 protocol files split by domain
│   ├── Errors/                   # 3 error type files
│   └── State/                    # State machine & persistence
│
├── Services/                     # 18 files - Business logic
│   ├── Accessibility/            # AX operations & detection
│   ├── Positioning/              # Position calculation
│   │   └── Strategies/           # Positioning strategies
│   ├── Monitoring/               # Window/widget tracking
│   ├── Permissions/              # Accessibility permissions
│   ├── UI/                       # Menu bar & settings
│   └── Diagnostics/              # Diagnostic tools
│
├── Features/                     # 7 files - High-level coordinators
│   ├── NotificationMoving/       # Main feature (refactored NotificationMover)
│   ├── Configuration/            # Settings management
│   ├── Accessibility/            # A11y features
│   └── Theme/                    # Theme management
│
├── Presentation/                 # 14 files - UI layer
│   ├── Windows/                  # All windows
│   │   ├── Settings/
│   │   ├── Permissions/
│   │   ├── About/
│   │   └── Diagnostics/
│   ├── Components/               # Reusable UI components
│   └── DesignSystem/             # Design tokens & components
│
├── Infrastructure/               # 8 files - Cross-cutting concerns
│   ├── Logging/
│   ├── Persistence/
│   ├── Keyboard/
│   └── Utilities/
│
└── Resources/                    # Assets, icons, configs
```

### KEY METRICS

**Before:**
- NotificationMover.swift: 3,013 lines (TOO LARGE)
- Total files: 25
- Manager folder: 11 files (mixed concerns)

**After:**
- NotificationMover.swift: ~800 lines (73% reduction)
- Total files: ~60
- Organized into 6 layers

### MIGRATION PHASES

**Phase 1: Create Folders** (Safe, no code changes)
```bash
mkdir -p Notimanager/Core/{Models,Protocols,Errors,State}
mkdir -p Notimanager/Services/{Accessibility,Positioning,Monitoring,Permissions,UI,Diagnostics}
mkdir -p Notimanager/Services/Positioning/Strategies
mkdir -p Notimanager/Features/{NotificationMoving,Configuration,Accessibility,Theme}
mkdir -p Notimanager/Presentation/{Windows,Components,DesignSystem}
mkdir -p Notimanager/Presentation/Windows/{Settings,Permissions,About,Diagnostics}
mkdir -p Notimanager/Infrastructure/{Logging,Persistence,Keyboard,Utilities}
```

**Phase 2: Move Files** (Reorganization)
- Move Managers to Services/
- Move Views to Presentation/
- Move Components to Presentation/Components/
- Move Infrastructure files to Infrastructure/

**Phase 3: Split Protocols** (NotificationMoverProtocols.swift → 6 files)
- AccessibilityProtocols.swift
- PositioningProtocols.swift
- MonitoringProtocols.swift
- UIProtocols.swift
- PermissionProtocols.swift
- NotificationProtocols.swift

**Phase 4: Extract from NotificationMover** (Code refactoring)
- Extract ~1,500 lines to Services/
- Extract ~500 lines to Core/State/
- Extract ~400 lines to Services/Diagnostics/
- Extract ~200 lines to Core/Models/

**Phase 5: Cleanup & Update**
- Update imports across all files
- Update Xcode project references
- Build and test
- Update documentation

### LAYER DEPENDENCIES (Bottom-Up)

```
Presentation (UI)
      ↓ depends on
Features (Coordinators)
      ↓ depends on
Services (Business Logic)
      ↓ depends on
Core (Models, Protocols, Errors)
      ↓ depends on
Infrastructure (Logging, Utilities)
```

### FILE NAMING CONVENTIONS

- **Models:** Noun, singular → `NotificationPosition.swift`
- **Services:** Noun + "Service" → `NotificationDetectionService.swift`
- **Managers:** Noun + "Manager" → `AccessibilityManager.swift`
- **Coordinators:** Feature + "Coordinator" → `NotificationMoverCoordinator.swift`
- **Protocols:** Domain + "Protocols" → `AccessibilityProtocols.swift`
- **Views:** Purpose + "Window" → `SettingsWindow.swift`
- **Components:** Purpose + type → `PositionGridButton.swift`

### KEY WIN

**NotificationMover.swift: 3,013 lines → ~800 lines**

Extracted to:
- Services/Accessibility/NotificationDetectionService.swift (~600 lines)
- Services/Positioning/NotificationPositioningService.swift (already exists)
- Services/Diagnostics/DiagnosticService.swift (~570 lines)
- Core/State/NotificationMoverStateMachine.swift (~150 lines)
- Core/Models/NotificationWindow.swift (~80 lines)
- Features/NotificationMoving/NotificationMoverCoordinator.swift (~200 lines)

### NEXT STEPS

1. Review this structure with team
2. Agent 19: Execute Phase 1 (Folder Creation) & Phase 2 (File Movement)
3. Agent 20: Execute Phase 3 (Protocol Split) & Phase 4 (Code Extraction)
4. Agent 21: Execute Phase 5 (Cleanup & Update)

### FULL DOCUMENTATION

See: `AGENT_18_FILE_STRUCTURE_DESIGN.md` for complete details (11 sections)

---

**Agent 18 - File Structure Architect**
**Date: 2025-01-15**
