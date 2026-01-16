# Installation Guide

This guide covers installing Notimanager on macOS.

## Quick Install (Downloaded Release)

Choose one of the following installation methods:

### Method 1: DMG Installer (Recommended)

The DMG installer provides the easiest installation experience with a drag-and-drop interface.

1. **Download** the latest `Notimanager-macOS.dmg` from [GitHub Releases](https://github.com/abd3lraouf/Notimanager/releases)
2. **Open the DMG** by double-clicking it
3. **Drag Notimanager** to the Applications folder shortcut
4. **Eject the DMG** by clicking the eject button in Finder or dragging it to Trash
5. **Right-click** Notimanager in Applications and select **Open** (first launch only)
6. **Grant Accessibility permissions** when prompted

### Method 2: ZIP Archive

If you prefer the ZIP archive format:

1. **Download** the latest `Notimanager-macOS.zip` from [GitHub Releases](https://github.com/abd3lraouf/Notimanager/releases)
2. **Extract** the ZIP file to get `Notimanager.app`
3. **Move to Applications**:
   ```bash
   mv Downloads/Notimanager.app /Applications/
   ```
4. **Right-click** Notimanager and select **Open** (first launch only)
5. **Grant Accessibility permissions** when prompted

### Granting Accessibility Permissions

After launching Notimanager:

1. When prompted, click **"Open System Settings"**
2. In **System Settings** → **Privacy & Security** → **Accessibility**
3. Find Notimanager in the list and enable the toggle
4. You may need to enter your macOS password

> **Note**: Accessibility permission is required for Notimanager to detect and move notification windows. The app cannot function without this permission.

## Troubleshooting

### "Notimanager is damaged and can't be opened"

This error occurs when macOS Gatekeeper blocks the app. To fix it:

**Right-click the app and select Open** (first launch only)

Or use the command line:
```bash
xattr -cr /Applications/Notimanager.app
open /Applications/Notimanager.app
```

### "Notimanager cannot be opened because the developer cannot be verified"

This appears because the app uses ad-hoc signing. To bypass:

1. **Option 1 - Right-click method (Recommended)**:
   - Right-click (or Control-click) on Notimanager.app
   - Select **Open**
   - Click **Open** in the security dialog
   - This only needs to be done once

2. **Option 2 - Allow via System Settings**:
   - Try to open the app
   - Click **Cancel** on the security dialog
   - Open **System Settings** → **Privacy & Security**
   - Find the message about Notimanager at the bottom
   - Click **Open Anyway**

### Notifications aren't moving

1. Verify Accessibility permissions are granted:
   - **System Settings** → **Privacy & Security** → **Accessibility**
   - Ensure Notimanager is enabled

2. Try toggling the permission:
   - Turn off Notimanager's accessibility access
   - Wait 2 seconds
   - Turn it back on
   - Restart Notimanager

3. Check Console.app for errors:
   - Open Console.app
   - Filter by `dev.abd3lraouf.notimanager`
   - Look for any error messages

### App crashes on launch

1. Check your macOS version (requires macOS 14.0+)
2. Try launching from Terminal to see error messages:
   ```bash
   /Applications/Notimanager.app/Contents/MacOS/Notimanager
   ```
3. Create an issue on [GitHub Issues](https://github.com/abd3lraouf/Notimanager/issues) with the error log

## Building from Source

If you prefer to build from source or want to verify the code:

### Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Command Line Tools for Xcode

### Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/abd3lraouf/Notimanager.git
   cd Notimanager
   ```

2. **Open in Xcode**:
   ```bash
   open Notimanager.xcodeproj
   ```

3. **Build and run**:
   - Press `⌘R` to build and run in development mode
   - Or select **Product** → **Archive** for a release build

4. **For a release build**:
   - Select **Product** → **Archive**
   - Once complete, click **Distribute App**
   - Choose **Copy App**
   - The exported app will be signed with your development certificate

### Self-Signed Certificate for Local Builds

Local builds will use your development certificate automatically. No special setup is required.

## Security & Verification

This app uses ad-hoc code signing and requires:
- **Accessibility** - To detect and move notification windows

The app:
- Does NOT have App Sandbox enabled (required for Accessibility)
- Does NOT collect or transmit any data
- Does NOT make network connections
- Runs entirely locally on your Mac

### Source Code Verification

The complete source code is available on GitHub:
https://github.com/abd3lraouf/Notimanager

You can review the code, build it yourself, and verify that it matches the released version.

## Upgrading

To upgrade to a new version:

1. Quit Notimanager (click menu bar icon → Quit)
2. Download the new release
3. Replace the old app:
   ```bash
   rm -rf /Applications/Notimanager.app
   mv Downloads/Notimanager.app /Applications/
   ```
4. Right-click and select **Open** (first launch of new version)
5. Your settings will be preserved automatically

## Uninstallation

To completely remove Notimanager:

1. Quit the app if running
2. Remove the app:
   ```bash
   rm -rf /Applications/Notimanager.app
   ```
3. (Optional) Remove preferences:
   ```bash
   rm -rf ~/Library/Preferences/dev.abd3lraouf.notimanager.plist
   rm -rf ~/Library/Application\ Support/Notimanager
   ```
4. (Optional) Revoke Accessibility permissions:
   - **System Settings** → **Privacy & Security** → **Accessibility**
   - Find Notimanager and remove it

## Getting Help

If you encounter issues not covered here:

- Check existing [GitHub Issues](https://github.com/abd3lraouf/Notimanager/issues)
- Create a new issue with details about your problem
- Include your macOS version and any error messages
- Attach logs from Console.app if applicable
