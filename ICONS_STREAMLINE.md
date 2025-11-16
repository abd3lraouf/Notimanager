# Notimanager Icon System

## Overview

Beautiful bell icons using **Streamline Plump** design (CC BY 4.0 license). The icon system includes app icons for different states and a template-style menu bar icon.

---

## Icon Source

**Icons by:** Streamline - Plump free icon set
**License:** Creative Commons Attribution 4.0 (CC BY 4.0)
**Website:** https://creativecommons.org/licenses/by/4.0/

### Icon Variants Used

1. **Outline Bell** - Stroke-based bell with detailed curves
2. **Filled Bell** - Bell with subtle gradient fill and inner details
3. **Bell with Notification Dot** - Bell with red notification indicator

---

## Generated Icons

### App Icons (Dock & Finder)

Located in: `Notimanager/Resources/Assets.xcassets/AppIcon.appiconset/`

| State | Color | Description |
|-------|-------|-------------|
| **AppIcon** | 🔵 Blue (#0A84FF) | Default state - bell with 15% fill opacity |
| **AppIcon-Enabled** | 🟢 Green (#32D74B) | Positioning enabled - green bell |
| **AppIcon-Disabled** | ⚪ Gray (#8E8E93) | Positioning disabled - gray bell |
| **AppIcon-Notification** | 🔴 Blue + Red Dot | Active notification detection |

### Sizes Generated

- 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024 pixels
- All sizes generated for all 4 states (28 PNG total + 4 SVG source files)

### Menu Bar Icons

Located in: `Notimanager/Resources/MenuBarIcon/`

| File | Size | Description |
|------|------|-------------|
| `MenuBarIcon.png` | 16x16 | Standard menu bar (1x) |
| `MenuBarIcon@2x.png` | 32x32 | Retina display (2x) |
| `MenuBarIcon.svg` | Source | SVG template |

The menu bar icon uses **template mode** (monochrome) for proper appearance in both light and dark mode.

---

## Icon Features

### Design Elements

1. **Bell Body** - Smooth curves following Streamline Plump aesthetic
2. **Clapper Line** - Horizontal line at top of bell
3. **Base Plate** - Curved bottom section of bell
4. **Notification Dot** - Red circle with white border (when active)
5. **Subtle Fill** - 10-15% opacity gradient fill for depth

### Color Scheme

| State | Primary Color | Fill Opacity | Use Case |
|-------|--------------|--------------|----------|
| **Default** | `#0A84FF` (iOS Blue) | 15% | Normal operation |
| **Enabled** | `#32D74B` (Green) | 15% | Positioning active |
| **Disabled** | `#8E8E93` (Gray) | 10% | Positioning paused |
| **Notification** | `#0A84FF` (Blue) + `#FF3B30` (Red) | 15% | Detecting notifications |

---

## IconManager Class

### Purpose

Manages dynamic icon updates based on app state. Located at:
`Notimanager/Utilities/IconManager.swift`

### Key Methods

```swift
// Update app icon based on state
IconManager.shared.updateAppIcon(to: .enabled)

// Get menu bar icon (template style)
let icon = IconManager.shared.getMenuBarIcon(isEnabled: true)

// Get menu bar icon with notification badge
let iconWithBadge = IconManager.shared.getMenuBarIconWithNotification(isEnabled: true)

// Create position indicator image
let positionIcon = IconManager.shared.createPositionIndicator(for: .topRight)

// Create status indicator
let statusIcon = IconManager.shared.createStatusIcon(isActive: true)

// Create custom dot indicator
let dotIcon = IconManager.shared.createDotIndicator(color: .systemRed, size: 8)
```

### Icon States

```swift
enum IconState {
    case `default`    // Blue - normal state
    case enabled      // Green - positioning active
    case disabled     // Gray - positioning disabled
    case notification // Blue with red dot - detecting notifications
}
```

---

## Integration with NotificationMover

The app automatically updates icons when:

1. **App Launch** - Icon reflects initial `isEnabled` state
2. **Toggle Enabled/Disabled** - Both menu bar and dock icon update
3. **Notification Detection** - Icon shows notification dot when active

### Example Integration

```swift
// In NotificationMover.swift

@objc private func menuBarToggleEnabled(_ sender: NSMenuItem) {
    isEnabled = !isEnabled
    UserDefaults.standard.set(isEnabled, forKey: "isEnabled")

    // Update menu item
    sender.title = isEnabled ? "Enabled" : "Disabled"
    sender.state = isEnabled ? .on : .off

    // Update icons
    updateMenuBarIcon()
    IconManager.shared.updateAppIcon(to: isEnabled ? .enabled : .disabled)
}
```

---

## Regenerating Icons

If you need to modify colors or regenerate icons:

```bash
cd /Users/abdelraouf/Developer/Notimanager
python3 scripts/generate_icons.py
```

### Customizing Colors

Edit the `COLORS` dictionary in `scripts/generate_icons.py`:

```python
COLORS = {
    'default': {
        'stroke': '#YOUR_COLOR',
        'fill': '#YOUR_COLOR',
        'fill_opacity': '0.15',
    },
    # ... other states
}
```

---

## Icon Preview

### Default State (Blue)
```
  🔔 Blue bell with subtle fill
  Clean stroke design
  Professional appearance
```

### Enabled State (Green)
```
  🟢 Green bell
  Indicates active positioning
  Easy to identify state
```

### Disabled State (Gray)
```
  ⚪ Gray bell
  Shows paused/inactive state
  Lower opacity fill
```

### Notification State (Blue + Red Dot)
```
  🔵 Blue bell with 🔴 red dot
  Red dot in top-right corner
  Indicates active detection
```

---

## File Structure

```
Notimanager/Resources/
├── Assets.xcassets/
│   ├── AppIcon.appiconset/
│   │   ├── Contents.json
│   │   ├── AppIcon_16x16.png
│   │   ├── AppIcon_32x32.png
│   │   ├── ... (all sizes)
│   │   └── AppIcon_1024x1024.png
│   ├── AppIcon-Enabled.svg (source)
│   ├── AppIcon-Disabled.svg (source)
│   ├── AppIcon-Notification.svg (source)
│   └── AppIcon.svg (source)
└── MenuBarIcon/
    ├── MenuBarIcon.png (16x16)
    ├── MenuBarIcon@2x.png (32x32)
    └── MenuBarIcon.svg (source)
```

---

## Credits

**Icon Design:** Streamline Plump by Streamline
**License:** Creative Commons Attribution 4.0 International
**License URL:** https://creativecommons.org/licenses/by/4.0/
**Icon Pack:** https://streamlinehq.com/streamline-plump

---

**Last Updated:** 2025-01-15
**Icon Version:** 2.0 (Streamline Plump)
**Generated with:** Python + sips (macOS built-in)
