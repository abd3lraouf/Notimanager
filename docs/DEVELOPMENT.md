# Development Guide

Build, test, and contribute to Notimanager.

## Prerequisites

- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later
- **Tools**: `git`, `xcode-select`
- **Optional**: `librsvg` (icon generation), `create-dmg` (packaging)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/abd3lraouf/Notimanager.git
cd Notimanager

# Open in Xcode
open Notimanager.xcodeproj

# Or build from CLI
./scripts/build.sh build
```

## Project Structure

```
Notimanager/
├── Notimanager/              # Main app source
│   ├── Components/          # Reusable UI components
│   ├── Coordinators/        # App coordination and lifecycle
│   ├── Managers/            # Core services
│   ├── Models/              # Data models
│   ├── Protocols/           # Protocol definitions
│   └── Views/               # SwiftUI views and AppKit controllers
├── NotimanagerTests/        # Unit and UI tests
├── docs/                    # Documentation
└── scripts/                 # Build, release, and utility scripts
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture.

## Build System

The `build.sh` script handles development and release tasks.

| Command | Description |
|---------|-------------|
| `./scripts/build.sh build` | Build for development |
| `./scripts/build.sh test` | Run all tests |
| `./scripts/build.sh clean` | Clean build artifacts |
| `./scripts/build.sh archive` | Create Xcode archive |
| `./scripts/build.sh export` | Export app from archive |
| `./scripts/build.sh zip` | Create ZIP distribution |
| `./scripts/build.sh dmg` | Create DMG distribution (release mode) |
| `./scripts/build.sh dev-dmg` | Create DMG (dev mode - fast, opens for testing) |
| `./scripts/build.sh all` | Run full release pipeline |
| `./scripts/build.sh prepare` | Prepare for release (interactive) |

### Common Workflows

```bash
# Development build
./scripts/build.sh build

# Full release pipeline
./scripts/build.sh all

# Prepare for release (interactive)
./scripts/build.sh prepare

# Quick local dev DMG (fast, opens for testing)
./scripts/build.sh export
./scripts/build.sh dev-dmg
```

### DMG Creation

Install `create-dmg`:
```bash
brew install create-dmg
```

Direct DMG script options:
```bash
./scripts/create-dmg.sh --dev              # Fast, local testing
./scripts/create-dmg.sh --release          # With code signing
./scripts/create-dmg.sh --dev --test       # Create and test
./scripts/create-dmg.sh --help             # Show all options
```

### Output Files

After running `build.sh all`:

```
build/
├── Notimanager.xcarchive/          # Xcode archive
├── Notimanager-macOS.zip           # ZIP distribution
├── Notimanager-macOS.dmg           # DMG installer
└── release/
    └── Notimanager.app             # Exported app bundle
```

## Testing

```bash
./scripts/build.sh test
```

## Icon System

Icons are generated from SVG sources. Do not edit assets in `Assets.xcassets` directly.

1. Modify SVG files in `scripts/assets/`
2. Run `./scripts/generate-all-icons.sh`
3. Commit the changes

See [ICON_GENERATION.md](ICON_GENERATION.md) for details.

## Release Workflow

### 1. Development

```bash
./scripts/build.sh test
./scripts/build.sh build
./scripts/build.sh export
./scripts/build.sh dev-dmg
```

### 2. Update Changelog

Edit `CHANGELOG.md` under the `[Unreleased]` section:

```markdown
## [Unreleased]

### Added
- New feature description

### Fixed
- Bug fix description
```

### 3. Prepare Release

```bash
./scripts/build.sh prepare
```

This prompts for version number, updates `Info.plist`, updates `CHANGELOG.md`, commits changes, and creates a git tag.

### 4. Build Release Artifacts (Optional)

```bash
./scripts/build.sh all
```

### 5. Push to GitHub

```bash
git push origin main
git push origin vX.Y.Z
```

GitHub Actions automatically builds, creates artifacts, and publishes the release.

## CI/CD Pipeline

GitHub Actions runs on version tags (v*.*.*).

Workflow steps:
1. Generate icons from SVG
2. Build app with code signing
3. Create signed ZIP and DMG
4. Generate appcast for Sparkle
5. Publish release

```bash
git tag v2.1.0
git push origin v2.1.0
```

Monitor at: https://github.com/abd3lraouf/Notimanager/actions

## Code Signing

See [CODE_SIGNING_SETUP.md](CODE_SIGNING_SETUP.md) for details.

Summary: Open `Notimanager.xcodeproj`, select the **Notimanager** target, go to **Signing & Capabilities**, enable **"Automatically manage signing"**, and select your **Team** (personal Apple ID).

Users should right-click Notimanager.app and select **Open** on first launch.

## Sparkle Auto-Updates

The app uses Sparkle 2.x for updates. See [Sparkle documentation](https://sparkle-project.org/documentation/) for configuration.

## Versioning

Uses [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

## Troubleshooting

```bash
# Clean and retry
./scripts/build.sh clean
./scripts/build.sh all
```

Ensure Accessibility permissions are granted in System Settings.

Local builds use automatic signing. Use `xattr -cr` on the app bundle if moving between machines.

## Manual Build (Without Script)

1. Open `Notimanager.xcodeproj`
2. Select **Product → Archive**
3. In organizer, click **Distribute App**
4. Choose **Copy App** and export

Then use `./scripts/create-dmg.sh` for distribution.

## Resources

- [ARCHITECTURE.md](ARCHITECTURE.md) - App architecture
- [CODE_SIGNING_SETUP.md](CODE_SIGNING_SETUP.md) - Code signing configuration
- [INSTALLATION.md](INSTALLATION.md) - User installation guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
