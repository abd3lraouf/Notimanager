# Changelog

All notable changes to Notimanager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### 🚧 Work in Progress
- Placeholder for upcoming changes

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
