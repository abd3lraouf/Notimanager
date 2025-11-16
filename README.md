# Notimanager

Control notification position on macOS.

> **Note**: This is a fork/continuation of [PingPlace by Wade Grimridge](https://github.com/notwadegrimridge/pingplace). Development continues with new features and improvements.

![Notimanager Screenshot](https://github.com/user-attachments/assets/469b318f-eba5-464f-87be-74d3decaa8a2)

## Features

- **9 Position Grid**: Place notifications anywhere on screen (top-left, center, bottom-right, etc.)
- **Menu Bar Control**: Quick access to settings and position changes
- **Launch at Login**: Optional auto-start
- **Test Notifications**: Verify your setup works
- **Beautiful UI**: Liquid glass design with golden ratio spacing

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later

## Building & Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/notimanager.git
cd notimanager
```

### 2. Open in Xcode

```bash
open Notimanager.xcodeproj
```

Or simply double-click `Notimanager.xcodeproj` in Finder.

### 3. Build and Run

- **Development**: Press `⌘R` to build and run
- **Release Build**:
  1. Select "Product → Archive" from the menu
  2. Once archived, click "Distribute App"
  3. Choose "Copy App" to export the .app bundle
  4. Move `Notimanager.app` to `/Applications`

## Project Structure

```
PingPlace/
├── Notimanager.xcodeproj/    # Xcode project file
├── Notimanager/
│   └── Notimanager/          # Source files
│       ├── Notimanager.swift # Main app code
│       ├── Info.plist        # App metadata
│       ├── Notimanager.entitlements
│       └── assets/           # Icons and resources
└── README.md
```

## Usage

1. Launch Notimanager from Applications or Xcode
2. Grant Accessibility permissions when prompted
3. Choose your preferred notification position from the menu bar icon
4. Test with "Send Test Notification"

### Available Positions

- Top Left, Top Middle, Top Right
- Middle Left, Center, Middle Right
- Bottom Left, Bottom Middle, Bottom Right

## Development

### Code Signing

The app uses your development team certificate. Update the `DEVELOPMENT_TEAM` in the Xcode project if needed:

1. Select the project in Xcode
2. Go to "Signing & Capabilities"
3. Choose your team

### Permissions

Notimanager requires:
- **Accessibility**: To detect and move notification windows
- **Notifications**: To send test notifications (optional)

The app disables App Sandbox to access system accessibility features.

### Bundle Identifier

- **Bundle ID**: `dev.abd3lraouf.notimanager`
- **Version**: 2.0.0

## Debugging

If notifications aren't moving:
1. Check System Settings → Privacy & Security → Accessibility
2. Ensure Notimanager has accessibility permissions
3. Try toggling the permission off/on
4. View logs in Console.app filtered by `dev.abd3lraouf.notimanager`

## Credits

- Original PingPlace app by [Wade Grimridge](https://github.com/notwadegrimridge)
- Continued development by Abdelraouf Sabri

## Support Original Author

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/wadegrimridge)

Follow [@WadeGrimridge](https://x.com/WadeGrimridge) on X

## License

© 2025 Abdelraouf Sabri. All rights reserved.

Based on PingPlace © 2025 Wade Grimridge
