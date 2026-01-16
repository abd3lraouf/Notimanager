# Build & Release Guide

This guide covers building and releasing Notimanager.

## Quick Start

```bash
# Full release pipeline (tests, archive, export, zip, dmg)
./scripts/build.sh all

# Prepare for release (interactive version bump and tagging)
./scripts/build.sh prepare

# Quick local dev DMG (fast, opens for testing)
./scripts/build.sh dev-dmg

# Show all available commands
./scripts/build.sh help
```

## Build Script Commands

| Command | Description |
|---------|-------------|
| `build.sh build` | Build for development |
| `build.sh test` | Run all tests |
| `build.sh clean` | Clean build artifacts |
| `build.sh archive` | Create Xcode archive |
| `build.sh export` | Export app from archive |
| `build.sh zip` | Create ZIP distribution |
| `build.sh dmg` | Create DMG distribution (release mode) |
| `build.sh dev-dmg` | Create DMG distribution (dev mode - fast, opens for testing) |
| `build.sh all` | Run full release pipeline |
| `build.sh prepare` | Prepare for release (interactive) |

## Local Development Workflow

For rapid iteration during development, use the dev-dmg command:

```bash
# 1. Export the app from archive
./scripts/build.sh export

# 2. Create DMG in dev mode (fast, opens for testing)
./scripts/build.sh dev-dmg

# Or use the DMG script directly for more options:
./scripts/create-dmg.sh --dev --test    # Create and open DMG
./scripts/create-dmg.sh --dev --verify  # Create and verify DMG
```

**Dev mode advantages:**
- Faster build times (minimal code signing)
- Automatically opens DMG for testing
- No certificate required
- Uses ad-hoc signing

**Direct DMG script options:**

```bash
# Dev mode (fast, for local testing)
./scripts/create-dmg.sh --dev

# Release mode (with code signing)
./scripts/create-dmg.sh --release

# Create and test DMG
./scripts/create-dmg.sh --dev --test

# Verify DMG after creation
./scripts/create-dmg.sh --dev --verify

# Custom output filename
./scripts/create-dmg.sh --dev --output Notimanager-Dev.dmg

# Use specific certificate
./scripts/create-dmg.sh --release --sign "Developer ID Application: Name"

# Skip code signing entirely
./scripts/create-dmg.sh --no-sign

# Show all options
./scripts/create-dmg.sh --help
```

## Release Workflow

### 1. Development

Make your changes and test:

```bash
# Run tests
./scripts/build.sh test

# Development build
./scripts/build.sh build

# Quick DMG test (after export)
./scripts/build.sh dev-dmg
```

### 2. Update Changelog

Edit `CHANGELOG.md` and add changes under the `[Unreleased]` section:

```markdown
## [Unreleased]

### Added
- New feature description

### Fixed
- Bug fix description
```

### 3. Prepare Release

Run the prepare command (interactive):

```bash
./scripts/build.sh prepare
```

This will:
- Prompt for new version number
- Update `Info.plist` with new version
- Update `CHANGELOG.md`
- Commit changes
- Create git tag

### 4. Build Release Artifacts

```bash
# Full pipeline (tests → archive → export → zip → dmg)
./scripts/build.sh all
```

Or run steps individually:

```bash
./scripts/build.sh clean
./scripts/build.sh archive
./scripts/build.sh export
./scripts/build.sh zip
./scripts/build.sh dmg
```

### 5. Test the Build

```bash
# Test the app
open build/release/Notimanager.app

# Test the DMG
open build/Notimanager-macOS.dmg
```

### 6. Push to GitHub

```bash
git push origin main
git push origin vX.Y.Z
```

GitHub Actions will automatically:
- Build the app
- Create ZIP and DMG artifacts
- Generate release notes
- Publish to GitHub Releases

## Output Files

After running `build.sh all`:

```
build/
├── Notimanager.xcarchive/          # Xcode archive
├── Notimanager-macOS.zip           # ZIP distribution
├── Notimanager-macOS.dmg           # DMG installer
└── release/
    └── Notimanager.app             # Exported app bundle
```

## Code Signing

Notimanager uses ad-hoc code signing for distribution. This means:

- No certificate is required
- Users need to right-click and select "Open" on first launch
- Works without Apple Developer account

### First Launch

Users should be instructed to:
1. Right-click Notimanager.app
2. Select "Open"
3. Click "Open" in the security dialog

This only needs to be done once per installation.

## GitHub Actions Setup

For automated releases, the workflow requires no secrets.

### Workflow Triggers

The release workflow runs on version tags:

```bash
git tag v2.1.0
git push origin v2.1.0
```

## Troubleshooting

### Build Failures

```bash
# Clean and retry
./scripts/build.sh clean
./scripts/build.sh all
```

### Xcode Version Issues

The script uses Xcode 15.3 by default. To change:

```bash
# Edit scripts/build.sh
XCODE_VERSION="15.3"  # Change to your version
```

### DMG Creation

The build script uses [`create-dmg`](https://github.com/create-dmg/create-dmg) for beautiful DMG creation.

**Requirements:**
- `create-dmg` shell script (install via Homebrew)

```bash
brew install create-dmg
```

**DMG creation modes:**

```bash
# Quick dev DMG (fast, for local testing)
./scripts/build.sh dev-dmg

# Release DMG (with code signing)
./scripts/build.sh dmg

# Full pipeline (includes DMG)
./scripts/build.sh all
```

**Direct DMG script usage:**
```bash
# Show all options
./scripts/create-dmg.sh --help

# Dev mode (fast, for local testing)
./scripts/create-dmg.sh --dev

# Release mode (with code signing if available)
./scripts/create-dmg.sh --release

# Create and test (opens DMG after creation)
./scripts/create-dmg.sh --dev --test

# Verify DMG after creation
./scripts/create-dmg.sh --dev --verify

# Custom output filename
./scripts/create-dmg.sh --dev --output Notimanager-Dev.dmg

# Use specific certificate for DMG code signing
./scripts/create-dmg.sh --release --sign "Developer ID Application: Name"

# Skip code signing entirely
./scripts/create-dmg.sh --no-sign
```

The DMG will have:
- Beautiful disk image with app icon
- Drag-and-drop installation to Applications folder
- Proper window positioning and sizing
- Hidden app extension
- Custom icon size and positioning
- Proper code signing (if certificate available)

**DMG Verification:**

The script includes a verification mode that checks:
- DMG format and structure
- Checksum validity
- Mount capability
- App bundle presence inside DMG

```bash
# Create and verify
./scripts/create-dmg.sh --dev --verify
```

**Customizing DMG Appearance:**

You can customize the DMG appearance by editing the configuration variables in `scripts/create-dmg.sh`:

```bash
# DMG appearance settings (at the top of the script)
VOLNAME="${APP_NAME}"           # Volume name
WINDOW_SIZE="600 400"           # Window width height
WINDOW_POS="400 300"            # Window position x y
ICON_SIZE="100"                 # Icon size in pixels
APP_ICON_POS="150 190"          # App icon position x y
DROP_LINK_POS="450 190"         # Applications link position x y
BACKGROUND_IMG=""               # Optional background image path
```

## Manual Build (Without Script)

If you prefer using Xcode directly:

1. Open `Notimanager.xcodeproj`
2. Select **Product → Archive**
3. Wait for archive to complete
4. In the organizer, click **Distribute App**
5. Choose **Copy App**
6. Export to desired location

Then use the scripts for distribution:

```bash
./scripts/create-dmg.sh
```

## CI/CD Pipeline

The GitHub Actions workflow:

1. **Tests** - Runs on every push to main/develop
2. **Release** - Runs on version tags (v*.*.*)

### Test Workflow

- Unit tests
- UI tests
- Integration tests
- Code coverage reporting

### Release Workflow

- Update build version
- Create archive with ad-hoc signing
- Export app bundle
- Create ZIP distribution
- Create DMG distribution
- Generate release notes
- Publish to GitHub Releases

## Versioning

Notimanager uses [Semantic Versioning](https://semver.org/):

- **MAJOR** - Breaking changes
- **MINOR** - New features (backward compatible)
- **PATCH** - Bug fixes (backward compatible)

Example: `2.1.0`
- 2 = MAJOR version
- 1 = MINOR version
- 0 = PATCH version

## Additional Resources

- [INSTALLATION.md](INSTALLATION.md) - Installation guide for users
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [README.md](README.md) - Project overview
