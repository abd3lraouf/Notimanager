# Notimanager Development Guide

This guide covers everything you need to know to build, test, and contribute to Notimanager.

## 🛠 Prerequisites

- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later
- **Tools**: `git`, `xcode-select`
- **Optional**: `librsvg` (for icon generation), `create-dmg` (for packaging)

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/abd3lraouf/Notimanager.git
   cd Notimanager
   ```

2. **Open in Xcode**
   ```bash
   open Notimanager.xcodeproj
   ```

3. **Build and Run**
   - Press `⌘R` to run in Debug mode.
   - Or use the CLI: `./scripts/build.sh build`

## 🏗 Project Structure

```
Notimanager/
├── Notimanager/              # Main app source
│   ├── Components/          # Reusable UI components
│   ├── Coordinators/        # App coordination and lifecycle
│   ├── Managers/            # Core services (NotificationMover, etc.)
│   ├── Models/              # Data models
│   ├── Protocols/           # Protocol definitions
│   └── Views/               # SwiftUI views and AppKit controllers
├── NotimanagerTests/        # Unit and UI tests
├── docs/                    # Documentation
└── scripts/                 # Build, release, and utility scripts
```

## ⚡️ Build System

The project uses a comprehensive `build.sh` script to handle development and release tasks.

| Command | Description |
|---------|-------------|
| `./scripts/build.sh build` | Build for development (Debug) |
| `./scripts/build.sh test` | Run all test suites |
| `./scripts/build.sh clean` | Clean build artifacts |
| `./scripts/build.sh all` | Run full release pipeline (Archive -> Export -> ZIP -> DMG) |
| `./scripts/build.sh prepare` | Interactive release preparation (version bump, changelog) |

### Manual Building
You can also use standard `xcodebuild` commands or the Xcode IDE directly. The script is just a wrapper for convenience and CI consistency.

## 🎨 Icon System

Notimanager uses a completely automated icon generation system based on SVG sources.
**Do not edit assets in `Assets.xcassets` directly.** Instead, modify the source SVGs.

- **Source**: `scripts/assets/*.svg`
- **Script**: `./scripts/generate-all-icons.sh`

To update icons:
1. Modify the SVG files in `scripts/assets/`.
2. Run `./scripts/generate-all-icons.sh`.
3. Commit the changes.

## 🧪 Testing

```bash
# Run all tests
./scripts/build.sh test

# Or using xcodebuild directly
xcodebuild test -scheme NotimanagerTests -destination 'platform=macOS'
```

## 🚢 Release Workflow

1. **Update Changelog**: Add notes to `docs/CHANGELOG.md` under `[Unreleased]`.
2. **Prepare Release**:
   ```bash
   ./scripts/build.sh prepare
   ```
   This script will ask for the new version number, update `Info.plist`, update the changelog, and create a git tag.
3. **Build Artifacts** (Optional locally, CI does this):
   ```bash
   ./scripts/build.sh all
   ```
4. **Push**:
   ```bash
   git push origin main
   git push origin vX.Y.Z
   ```
   GitHub Actions will automatically build the release and attach artifacts.

## 🔄 CI/CD

The project uses GitHub Actions for CI/CD.

- **Workflows**: Located in `.github/workflows/`.
- **Self-Signed Certificate**: For local DMG creation and CI signing, we use a self-signed certificate generation script (`scripts/create-self-signed-cert.sh`).

**Setting up CI for your fork:**
1. Run `./scripts/create-self-signed-cert.sh` to generate a certificate.
2. Run `./scripts/setup-ci.sh` to get the secrets needed for GitHub.
3. Add `SELF_SIGNED_CERTIFICATE` and `CERTIFICATE_PASSWORD` to your repo secrets.

## 🧩 Sparkle Auto-Updates

The app uses Sparkle 2.x for updates.
See [docs/SPARKLE_SETUP.md](SPARKLE_SETUP.md) for detailed configuration.

## 📝 Troubleshooting

**Permissions**:
If the app crashes or notifications don't move, ensure "Accessibility" permissions are granted in System Settings.

**Code Signing**:
Local builds use ad-hoc signing or the self-signed certificate. You may need to `xattr -cr` the app bundle if moving it between machines.
