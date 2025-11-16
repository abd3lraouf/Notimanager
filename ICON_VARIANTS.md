# Notimanager Icon System

## Overview

Beautiful bell-shaped notification icons with multiple state variants, created from the ProIcons SVG. The icon system includes app icons for different states and a dynamic menu bar icon that updates based on app state.

---

## Icon Variants

### App Icons (Dock & Finder)

| State | Color Scheme | Usage |
|-------|-------------|-------|
| **Default (AppIcon)** | Blue gradient (#0A84FF → #32D74B) | Default app state |
| **Enabled (AppIcon-Enabled)** | Green gradient (#32D74B) | When notification positioning is active |
| **Disabled (AppIcon-Disabled)** | Gray gradient (#8E8E93) | When notification positioning is disabled |
| **Notification (AppIcon-Notification)** | Blue with red notification dot | When notifications are detected |

### Menu Bar Icons

| Size | Usage |
|------|-------|
| 16x16 (1x) | Standard menu bar |
| 32x32 (2x) | Retina displays |

The menu bar icon is a template image (monochrome) that adapts to light/dark mode automatically.

---

## Generated Assets

### Location
```
Notimanager/Resources/Assets.xcassets/
├── AppIcon.appiconset/
│   ├── AppIcon_16x16.png
│   ├── AppIcon_32x32.png
│   ├── AppIcon_64x64.png
│   ├── AppIcon_128x128.png
│   ├── AppIcon_256x256.png
│   ├── AppIcon_512x512.png
│   └── AppIcon_1024x1024.png
├── AppIcon-Enabled.svg (source)
├── AppIcon-Disabled.svg (source)
├── AppIcon-Notification.svg (source)
└── MenuBarIcon/
    ├── MenuBarIcon.png (16x16)
    └── MenuBarIcon@2x.png (32x32)
```

### Sizes Generated
- 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024 pixels
- All sizes generated for all 4 icon states (default, enabled, disabled, notification)

---

## Icon Features

### Design Elements

1. **Bell Shape**: Clean, modern bell design from ProIcons
2. **Gradient Fill**: Subtle gradient from top-left to bottom-right
3. **Translucent Fill**: 10% opacity fill with full opacity stroke
4. **Notification Dot**: Red circle with white stroke when active
5. **Clapper Line**: Horizontal line at bottom of bell

### Color Scheme

**Default State:**
- Primary: `#0A84FF` (iOS Blue)
- Secondary: `#32D74B` (Green)
- Fill: Semi-transparent gradient

**Enabled State:**
- Primary: `#32D74B` (Green)
- Secondary: `#32D74B` (Green)
- Fill: Semi-transparent green

**Disabled State:**
- Primary: `#8E8E93` (Gray)
- Secondary: `#8E8E93` (Gray)
- Fill: Semi-transparent gray

**Notification State:**
- Primary: `#0A84FF` (Blue)
- Secondary: `#FF3B30` (Red notification dot)
- Fill: Semi-transparent blue

---

## IconManager Class

### Purpose
Manages dynamic icon updates based on app state.

### Key Methods

```swift
// Update app icon based on state
IconManager.shared.updateAppIcon(to: .enabled)

// Get menu bar icon for current state
let icon = IconManager.shared.getMenuBarIcon(isEnabled: true)

// Get menu bar icon with notification badge
let iconWithBadge = IconManager.shared.getMenuBarIconWithNotification(isEnabled: true)

// Create position indicator image
let positionIcon = IconManager.shared.createPositionIndicator(for: .topRight)

// Create status indicator
let statusIcon = IconManager.shared.createStatusIcon(isActive: true)
```

### States

```swift
enum IconState {
    case enabled      // Green - app is active
    case disabled     // Gray - app is disabled
    case notification // Blue with red dot - has notifications
}
```

---

## Integration with NotificationMover

### Menu Bar Icon Updates

The menu bar icon automatically updates when:

1. **App State Changes**: Toggle enabled/disabled from menu
2. **Startup**: Icon reflects current `isEnabled` state
3. **Settings Changes**: Updates from settings window

```swift
// In NotificationMover.swift
private func updateMenuBarIcon() {
    guard let button = statusItem?.button else { return }
    if let icon = IconManager.shared.getMenuBarIcon(isEnabled: isEnabled) {
        button.image = icon
    }
}

@objc private func menuBarToggleEnabled(_ sender: NSMenuItem) {
    isEnabled = !isEnabled
    // ... update state ...

    // Update menu bar icon
    updateMenuBarIcon()

    // Update app icon
    IconManager.shared.updateAppIcon(to: isEnabled ? .enabled : .disabled)
}
```

### App Icon Updates

The dock icon updates to reflect:

- **Green**: When notification positioning is enabled
- **Gray**: When notification positioning is disabled
- **Blue with dot**: When notifications are being actively detected

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
        'primary': '#YOUR_COLOR',
        'secondary': '#YOUR_COLOR',
        'bell': '#YOUR_COLOR'
    },
    # ... other states
}
```

---

## Icon Source

The bell icon is from **ProIcons** by ProCode:
- https://github.com/ProCode-Software/proicons
- Licensed under the project's LICENSE

**Icon:** Bell with notification dot
**SVG:** Modified with gradients and color variants for Notimanager

---

## Future Enhancements

### Potential Additions

1. **Alternative Color Themes**
   - Dark mode variants
   - User-customizable colors

2. **Animated Icons**
   - Subtle pulse when detecting notifications
   - Transition animations between states

3. **Position-Specific Icons**
   - Bell icon rotated to indicate position
   - Arrows indicating notification direction

4. **Status Badges**
   - Count badge for multiple notifications
   - Priority indicators

---

## Troubleshooting

### Icons Not Showing

1. **Clean Build**: Product → Clean Build Folder (⇧⌘K)
2. **Restart Xcode**: Ensure asset catalog reloads
3. **Check Assets.xcassets**: Verify files are in correct locations
4. **Verify Code Signing**: Icons require proper bundle setup

### Menu Bar Icon Not Updating

1. **Check IconManager**: Verify it's being called
2. **Debug State**: Log `isEnabled` value
3. **Force Refresh**: Call `updateMenuBarIcon()` manually

### Wrong Icon Size

1. **Verify Assets**: Check 1x and 2x variants exist
2. **Screen Scale**: Test on Retina and non-Retina displays
3. **Template Mode**: Ensure `isTemplate = true` for menu bar

---

**Last Updated:** 2025-01-15
**Icon Version:** 1.0
