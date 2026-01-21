# Installation Guide

Installation instructions for Notimanager on macOS.

## Installation Methods

### DMG Installer (Recommended)

1. Download the latest `Notimanager-macOS.dmg` from [GitHub Releases](https://github.com/abd3lraouf/Notimanager/releases)
2. Open the DMG and drag Notimanager to Applications
3. Eject the DMG
4. Right-click Notimanager in Applications and select **Open** (first launch only)

### ZIP Archive

1. Download `Notimanager-macOS.zip` from [GitHub Releases](https://github.com/abd3lraouf/Notimanager/releases)
2. Extract and move to Applications:
   ```bash
   mv Downloads/Notimanager.app /Applications/
   ```
3. Right-click Notimanager and select **Open** (first launch only)

## Accessibility Permissions

After launching, grant Accessibility permissions:

1. Click **"Open System Settings"** when prompted
2. Go to **System Settings** → **Privacy & Security** → **Accessibility**
3. Enable Notimanager in the list

This permission is required for the app to detect and move notification windows.

## Troubleshooting

### "App is damaged and can't be opened"

macOS Gatekeeper blocks unsigned apps. Right-click the app and select **Open**, or run:

```bash
xattr -cr /Applications/Notimanager.app
open /Applications/Notimanager.app
```

### "Developer cannot be verified"

The app uses ad-hoc signing. Either:

1. Right-click Notimanager.app and select **Open**, then click **Open** in the dialog
2. Or go to **System Settings** → **Privacy & Security** and click **Open Anyway**

### Notifications aren't moving

1. Verify Accessibility permissions are enabled in System Settings
2. Toggle the permission off and on, then restart the app
3. Check Console.app for errors (filter by `dev.abd3lraouf.notimanager`)

### App crashes on launch

1. Verify macOS 14.0+ is installed
2. Launch from Terminal to see error messages:
   ```bash
   /Applications/Notimanager.app/Contents/MacOS/Notimanager
   ```
3. Create an issue on [GitHub Issues](https://github.com/abd3lraouf/Notimanager/issues) with the error log

## Building from Source

See [DEVELOPMENT.md](DEVELOPMENT.md) for build instructions.

## Security

- Requires Accessibility permission to detect and move notification windows
- No App Sandbox (required for Accessibility)
- No data collection or network connections
- All processing happens locally

Source code available at https://github.com/abd3lraouf/Notimanager

## Upgrading

1. Quit Notimanager
2. Download the new release
3. Replace the app:
   ```bash
   rm -rf /Applications/Notimanager.app
   mv Downloads/Notimanager.app /Applications/
   ```
4. Right-click and select **Open** (first launch)
5. Settings are preserved automatically

## Uninstallation

1. Quit the app
2. Remove the app:
   ```bash
   rm -rf /Applications/Notimanager.app
   ```
3. Optionally remove preferences:
   ```bash
   rm -rf ~/Library/Preferences/dev.abd3lraouf.notimanager.plist
   rm -rf ~/Library/Application\ Support/Notimanager
   ```
4. Optionally revoke Accessibility permissions in System Settings

## Help

- Check [GitHub Issues](https://github.com/abd3lraouf/Notimanager/issues) for existing problems
- Create a new issue with your macOS version, error messages, and Console.app logs
