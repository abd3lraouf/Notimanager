# Icon Generation & Build Integration

This document describes how icons are generated and integrated into the Notimanager build pipeline.

## Overview

Notimanager uses SVG source files for all icon assets. These are automatically converted to PNG format during the build process, ensuring consistency across all builds.

## Directory Structure

```
scripts/
├── assets/
│   ├── oui-editor-position-top-left.svg
│   ├── oui-editor-position-top-right.svg
│   ├── oui-editor-position-bottom-left.svg
│   └── oui-editor-position-bottom-right.svg
└── generate-all-icons.sh

Notimanager/Resources/Assets.xcassets/
├── AppIcon.appiconset/          # Auto-generated
│   ├── AppIcon-Enabled_*.png    # Various sizes
│   └── Contents.json
└── MenuBarIcon*.imageset/        # Auto-generated
    ├── MenuBarIcon.png
    ├── MenuBarIcon@2x.png
    └── Contents.json
```

## SVG Source Files

The app uses [OpenSearch UI](https://github.com/opensearch-project/oui) icons, licensed under the Apache License 2.0.

### Available Icons

- `oui-editor-position-top-left.svg` - Top-left corner position indicator
- `oui-editor-position-top-right.svg` - Top-right corner position indicator (also used as default/app icon)
- `oui-editor-position-bottom-left.svg` - Bottom-left corner position indicator
- `oui-editor-position-bottom-right.svg` - Bottom-right corner position indicator

## Icon Generation Script

### Usage

```bash
./scripts/generate-all-icons.sh
```

### What It Does

1. **Cleans up old data**: Completely removes and recreates all imageset directories
2. **Generates menu bar icons**: Creates 16x16 and 32x32 PNGs for all position variants
3. **Generates app icons**: Creates all required sizes (16x16 to 1024x1024)
4. **Updates Contents.json**: Creates proper asset catalog configuration files

### Requirements

- `rsvg-convert` from librsvg (install via `brew install librsvg`)
- SVG source files in `scripts/assets/`

## Generated Assets

### Menu Bar Icons

| Icon Name | Usage | Sizes |
|-----------|-------|-------|
| `MenuBarIcon` | Default menu bar icon | 16x16, 32x32 |
| `MenuBarIcon-top-left` | Top-left position selected | 16x16, 32x32 |
| `MenuBarIcon-top-right` | Top-right position selected | 16x16, 32x32 |
| `MenuBarIcon-bottom-left` | Bottom-left position selected | 16x16, 32x32 |
| `MenuBarIcon-bottom-right` | Bottom-right position selected | 16x16, 32x32 |
| `MenuBarIcon-disabled` | App disabled state | 16x16, 32x32 |

### App Icon

The app icon uses the top-right position design and includes all required macOS sizes:
- 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024

## Build Pipeline Integration

### Local Builds

The build script automatically generates icons before building:

```bash
# Development build
./scripts/build.sh build

# Release build
./scripts/build.sh all
```

### CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/release.yml`) automatically:
1. Installs librsvg dependency
2. Generates icons from SVG sources
3. Builds the app with fresh icons
4. Creates signed DMG and ZIP releases

### Icon Update Workflow

When you need to update icons:

1. **Modify SVG files** in `scripts/assets/`
2. **Run icon generation**:
   ```bash
   ./scripts/generate-all-icons.sh
   ```
3. **Verify icons** in Xcode
4. **Commit changes**:
   ```bash
   git add scripts/assets/ Notimanager/Resources/Assets.xcassets/
   git commit -m "chore: update icons"
   ```

## Code Integration

The `MenuBarManager` automatically displays the correct icon based on the current notification position:

```swift
private func iconNameForPosition(_ position: NotificationPosition) -> String {
    switch position {
    case .topLeft: return "MenuBarIcon-top-left"
    case .topRight: return "MenuBarIcon-top-right"
    case .bottomLeft: return "MenuBarIcon-bottom-left"
    case .bottomRight: return "MenuBarIcon-bottom-right"
    default: return "MenuBarIcon-top-right"  // Default for middle positions
    }
}
```

## Benefits

1. **Single Source of Truth**: SVG files are the authoritative source
2. **Automated Generation**: No manual PNG editing required
3. **Consistent Quality**: All icons generated from vector sources
4. **Easy Updates**: Change SVG and regenerate
5. **Clean Builds**: Old assets completely removed before generation
6. **CI/CD Ready**: Fully integrated into release pipeline

## Troubleshooting

### Icons not appearing in Xcode

1. Clean build folder: `Product > Clean Build Folder` (⇧⌘K)
2. Regenerate icons: `./scripts/generate-all-icons.sh`
3. Restart Xcode

### rsvg-convert not found

Install librsvg:
```bash
brew install librsvg
```

### Icons not updating in built app

1. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
2. Clean build: `./scripts/build.sh clean`
3. Rebuild: `./scripts/build.sh build`

## License

Icons are from [OpenSearch UI](https://github.com/opensearch-project/oui), licensed under the Apache License 2.0.
https://github.com/opensearch-project/oui/blob/main/LICENSE.txt
