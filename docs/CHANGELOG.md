# Changelog

All notable changes to Notimanager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### 🚧 Work in Progress
- Placeholder for upcoming changes

## [2.1.2] - 2026-01-20

### 🧪 Testing
- **Dummy Release**: Another version bump for testing cumulative changelogs

## [2.1.1] - 2026-01-20

### 🧪 Testing
- **Dummy Release**: Version bump for testing update mechanism with cumulative changelogs

## [2.1.0] - 2026-01-20

### ✨ New Features
- **Cumulative Release Notes**: Sparkle now shows all changes from intermediate versions when updating
  - Users updating from older versions (e.g., v2.0.2) will see full changelog including all versions between
  - Release notes are displayed with beautiful HTML formatting using Apple system fonts
  - Changelogs are embedded directly in appcast.xml for immediate display

### 🔧 Improvements
- **Release Workflow**: Enhanced GitHub Actions workflow for better release automation
  - Added Python script to convert Markdown changelogs to styled HTML
  - Improved appcast generation with cumulative release note injection
  - DMG files now include version number in filename

### 🛠️ Developer Experience
- **Update Logging**: Added comprehensive logging for Sparkle update lifecycle
  - Track update discovery, download, extraction, and installation stages
  - Error logging at each stage for easier debugging

## [2.0.4] - 2026-01-18

### 🧪 Testing
- **Dummy Release**: Version bump for testing update mechanism

## [2.0.3] - 2026-01-18

### 🔧 Improvements
- **Appcast Hosting**: Migrated from GitHub Pages to GitHub Releases
  - Updated SUFeedURL to use GitHub Releases download endpoint
  - Removed GitHub Pages deployment workflow
  - Simplified release infrastructure by hosting appcast.xml directly in releases

## [2.0.2] - 2026-01-18

### 🐛 Fixed
- **Sparkle Signing**: Fixed appcast generation to use macOS keychain for private key
  - Import private key to keychain instead of using --key flag
  - Use generate_appcast from extracted ./bin/ directory
  - Enable proper signing for update feeds
- **Release Command**: Fixed pre-commit hook logic for working directory checks

## [2.0.1] - 2026-01-18

### 🐛 Fixed
- **GitHub Pages Deployment**: Fixed automatic deployment trigger for appcast.xml
  - Changed from `release:published` to `workflow_run:completed` to ensure deployment works with GITHUB_TOKEN
  - Fixed tag resolution to use `workflow_run.head_branch` for tag pushes
- **Release Notes Formatting**: Improved changelog extraction to skip duplicate header lines

## [2.0.0] - 2026-01-18

### ✨ New Features
- **Automatic Updates**: Integrated Sparkle 2.x framework for automatic update checking and installation
- **Update Settings**: Added two new settings in General pane:
  - Automatically check for updates
  - Automatically download updates
- **Check for Updates**: Menu bar item to manually check for updates
- **UpdateManager**: New service for managing Sparkle updater functionality
- **Clean Architecture**: Complete app restructure following Clean Architecture principles
  - **Domain Layer**: Business logic with use cases and entities
  - **Data Layer**: Repository pattern for data access
  - **Presentation Layer**: MVVM pattern with SwiftUI
- **SwiftUI Migration**: Major UI migration from UIKit to SwiftUI
  - SwiftUI views for Settings, MenuBar, Diagnostics, and Permissions
  - ObservableObject ViewModels for reactive state management
  - Advanced settings with integrated log viewer
- **AppStore**: Global state management for application-wide data
- **Utility Managers**: Comprehensive manager system for app services
- **Disabled State Icons**: Added app icons for disabled/enabled states

### 🔧 Improvements
- **Signed Updates**: All releases will be EdDSA-signed for security
- **GitHub Actions**: Enhanced release workflow with appcast generation
- **GitHub Pages**: Automatic deployment of appcast.xml for updates
- **Extracted Services**: Better separation of concerns with dedicated logging and file managers
- **Removed Redundant Features**: Cleaned up unused keyboard shortcuts implementation

### 🛠️ Developer Experience
- **Setup Script**: Automated `scripts/setup-sparkle.sh` for complete Sparkle setup
- **Documentation**: Comprehensive `docs/SPARKLE_SETUP.md` with step-by-step instructions
- **Enhanced Icons**: Complete set of disabled state app icons
- **Better Testing**: Updated UI tests for SwiftUI migration

### 🔒 Security
- **EdDSA Signatures**: Update archives are signed with Ed25519 keys
- **Signature Verification**: All updates are verified before installation

### 🐛 Fixed
- Menu bar About item now opens standard About panel on older macOS versions

## [1.3.0] - 2026-01-17

### ✨ New Features
- **Granular Interception Controls**: Choose which notification types to intercept (normal notifications, window popups, widgets)
- **Widget Interception**: Support for intercepting Notification Center widgets and interactive widgets
- **Widget Testing**: Built-in widget test notification to verify widget interception is working
- **Position Preview**: Interactive grid overlay in settings to visualize and select notification positions
- **Quit Button**: Convenient quit button in settings with confirmation dialog

### 🔧 Improvements
- **Settings Reorganization**: Streamlined settings architecture for better organization
  - Merged position settings into interception pane for better context
  - Created dedicated Advanced pane for developer/debug options
  - Renamed "System" section to "Startup & Menu" for clarity
- **Enhanced Accessibility**: Improved accessibility roles, identifiers, and help text throughout
- **Better Configuration Management**: Enhanced persistence and handling of position-related settings
- **Improved Notification Testing**: Enhanced test notification service with better feedback
- **Better Window Tracking**: Improved window monitoring service for more reliable detection

### 🎨 UI/UX Enhancements
- **Info Button Component**: New inline help tooltip component for settings
- **Liquid Glass Components**: Enhanced checkbox rows with info integration
- **Keyboard Shortcuts Panel**: New UI component for shortcut management
- **Widget Preview Overlay**: Visual feedback for position selection
- **Consistent Shadow Styling**: New ShadowHelper utility for unified shadows

### 🛠️ Developer Experience
- **ActivityManager**: New service for app activity tracking
- **SpotlightIndexer**: Service for Spotlight integration
- **KeyboardShortcuts Utility**: Centralized keyboard shortcut handling
- **AppRestart Utility**: Application restart functionality
- **Enhanced Documentation**: Updated UX audit documentation and added release command docs

## [1.2.0] - 2026-01-17

### ✨ New Features
- Liquid Glass design system components
- Launch at Login checkbox with SwiftUI wrapper
- Enhanced Position settings with Liquid Glass materials
- Refactored General settings with Liquid Glass design

### 🔧 Improvements
- Improved About settings with semantic typography
- Refactored coordinator actions and UI components
- PreferenceStore for persistent settings management
- Enhanced app initialization for preference handling

### 🛠️ Build & Release
- Enhanced build and release automation
- Updated project configuration and dependencies
- Added UX audit documentation and command reference

## [1.0.0] - 2026-01-16

### ✨ New Features
- **4 Corner Positioning**: Place notifications in any corner of your screen (top-left, top-right, bottom-left, bottom-right)
- **Menu Bar Control**: Quick access to settings and position changes right from your menu bar
- **Launch at Login**: Optional auto-start for seamless integration
- **Test Notifications**: Verify your setup works with a single click
- **Position Memory**: Your chosen position is remembered across app restarts
- **Enable/Disable Toggle**: Quickly turn notification positioning on or off
- **Settings Window**: Comprehensive settings interface with tabbed navigation
- **Beautiful Liquid Glass UI**: Modern design with golden ratio spacing

### 🔧 Improvements
- Streamlined 4-corner positioning for better user experience
- Intuitive menu bar icon shows current position at a glance
- One-click test notifications to verify your setup
- Built-in diagnostic mode for troubleshooting

### 📱 Requirements
- macOS 14.0 (Sonoma) or later
- Accessibility permissions (required for notification detection and movement)

---

## Version Summary

- **1.x.x** - Initial stable release with 4-corner positioning system
