# Notimanager Architecture

Architecture and design patterns used in Notimanager.

## Overview

macOS application built with SwiftUI that moves system notifications to different screen corners. Follows Clean Architecture principles with clear separation of concerns.

## Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum OS**: macOS 14.0 (Sonoma)
- **Dependencies**: Sparkle 2.x (auto-updates)

## Architecture Layers

```
┌────────────────────────────────────────────┐
│         Presentation Layer                 │
│  SwiftUI Views + ViewModels (MVVM)         │
└────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────┐
│           Domain Layer                     │
│  Coordinators + Managers + Models          │
└────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────┐
│            Data Layer                      │
│  Repositories + Data Sources               │
└────────────────────────────────────────────┘
```

## Core Components

### Presentation Layer

**Views**: `SettingsView`, `MenuBarView`, `PermissionView`, `DiagnosticsView`

**ViewModels**: `PermissionViewModel`, `SettingsViewModel`, `DiagnosticsViewModel`

### Domain Layer

**Coordinators**: `NotificationMoverCoordinator` - Orchestrates notification detection and movement

**Managers**:
- `AccessibilityPermissionService` - Permission handling
- `MenuBarManager` - Menu bar icon and state
- `NotificationTestManager` - Test notifications
- `WindowMonitoringService` - Window monitoring
- `UpdateManager` - Sparkle auto-updates

**Models**: `NotificationPosition`, `NotificationWindow`, `InterceptionType`

### Data Layer

**Repositories**: `PreferenceStore` - UserDefaults wrapper with type-safe accessors

**Utilities**: `LogManager`, `FileManager`, `ActivityManager`

## Design Patterns

- **MVVM**: SwiftUI views + ObservableObject ViewModels
- **Coordinator**: `NotificationMoverCoordinator` orchestrates workflow
- **Repository**: `PreferenceStore` abstracts data access
- **Observer**: `@Published`/`@StateObject` for reactive UI

## Key Workflows

**Notification Detection**:
```
WindowMonitoringService detects window → Permission check → NotificationMoverCoordinator validates → Moves window
```

**Settings Management**:
```
User changes setting → ViewModel updates PreferenceStore → Persists to UserDefaults → Published property notifies → UI updates
```

**Permission Request**:
```
Launch/Enable → Check permission → Show PermissionView → User grants → Monitor for grant → Enable feature
```

## Project Structure

```
Notimanager/
├── App/                    # App entry point
├── Components/             # Reusable UI components
├── Coordinators/           # App coordination
├── Managers/               # Core services
├── Models/                 # Data models
├── Protocols/              # Protocol definitions
├── ViewModels/             # ViewModels
├── Views/
│   ├── SwiftUI/           # SwiftUI views
│   └── AppKit/            # AppKit controllers
└── Resources/
    ├── Assets.xcassets/   # Images, icons
    └── Info.plist         # App configuration
```

## Data Flow

**User Interaction**:
```
User Action → View → ViewModel → Manager/Coordinator → Model → UserDefaults → Published Property → View Update
```

**Notification Movement**:
```
System Event → WindowMonitoringService → NotificationMoverCoordinator → Accessibility API → Window Position Change
```

## Dependencies

**SPM**: Sparkle 2.x (auto-updates)

**System Frameworks**: SwiftUI, AppKit, ApplicationServices, Foundation, Combine

## Security and Privacy

- Requires Accessibility permission to detect and move notification windows
- All data stored locally in UserDefaults
- No network communication or data collection
- Source code available for audit

## Testing

**Unit Tests**: Business logic with mocked dependencies

**UI Tests**: Critical user flows, settings persistence, permission flow

**Manual Testing**: Various macOS versions, notification types, accessibility features

## Performance

- Efficient window detection with debouncing
- Proper observer cleanup and weak references
- Minimal background activity and efficient polling

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Accessibility API](https://developer.apple.com/documentation/applicationservices/assistant_management_for_macos)
- [Sparkle Framework](https://sparkle-project.org/)
