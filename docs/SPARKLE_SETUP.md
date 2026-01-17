# Sparkle Auto-Update Setup Guide

This document provides comprehensive, step-by-step instructions for setting up and configuring Sparkle auto-updates in Notimanager.

## Table of Contents

1. [Overview](#overview)
2. [Integration Status](#integration-status)
3. [Prerequisites](#prerequisites)
4. [Part 1: Initial Setup](#part-1-initial-setup)
5. [Part 2: Key Generation](#part-2-key-generation)
6. [Part 3: GitHub Actions Configuration](#part-3-github-actions-configuration)
7. [Part 4: Hosting the Appcast](#part-4-hosting-the-appcast)
8. [Part 5: Creating Your First Signed Release](#part-5-creating-your-first-signed-release)
9. [Part 6: Testing Updates](#part-6-testing-updates)
10. [Part 7: Ongoing Maintenance](#part-7-ongoing-maintenance)
11. [Configuration Reference](#configuration-reference)
12. [Troubleshooting](#troubleshooting)
13. [Security Best Practices](#security-best-practices)

---

## Overview

**Sparkle** is a software update framework for macOS that allows applications to automatically check for, download, and install updates. Notimanager uses Sparkle 2.x to provide seamless update experiences for users.

### What Sparkle Does

- **Automatic Update Checks**: Periodically checks for new versions (default: every 24 hours)
- **Background Downloads**: Optionally downloads updates automatically when found
- **User Notifications**: Alerts users when updates are available
- **Secure Updates**: Uses EdDSA (Ed25519) signatures to verify update authenticity
- **Silent Installation**: Installs updates without requiring user interaction (when possible)

### How It Works

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  Notimanager    │  HTTP   │   Appcast       │  HTTPS  │  GitHub Release │
│  App (Client)   │ ──────> │   .xml          │ <────── │    Assets       │
│                 │         │  (Hosted on     │         │  (.dmg, .zip)   │
│                 │         │   GitHub Pages) │         │                 │
└─────────────────┘         └─────────────────┘         └─────────────────┘
         │                                                    │
         │ verifies EdDSA signature                            │
         └────────────────────────────────────────────────────┘
```

### Current Configuration

| Setting | Value | Location |
|---------|-------|----------|
| Feed URL | `https://abd3lraouf.github.io/Notimanager/appcast.xml` | `Info.plist`: `SUFeedURL` |
| Public Key | `PUBLIC_KEY_PLACEHOLDER` (needs updating) | `Info.plist`: `SUPublicEDKey` |
| Auto-Check Interval | 24 hours (86400 seconds) | Default Sparkle setting |
| Auto-Download | Disabled by default (user preference) | General Settings |

---

## Integration Status

### ✅ Completed Tasks

- [x] Sparkle 2.x framework added via Swift Package Manager
- [x] `Info.plist` configured with `SUFeedURL` and `SUPublicEDKey` placeholder
- [x] `UpdateManager.swift` created for programmatic updater control
- [x] "Check for Updates..." menu item added to menu bar
- [x] Auto-update settings added to General Settings pane:
  - "Automatically check for updates"
  - "Automatically download updates"
- [x] GitHub Actions workflow updated for appcast generation
- [x] Appcast template created (`appcast.xml`)

### 🔄 Remaining Tasks

- [ ] Generate EdDSA signing keys
- [ ] Update `Info.plist` with actual public key
- [ ] Configure GitHub repository secrets
- [ ] Set up GitHub Pages for appcast hosting
- [ ] Test end-to-end update flow
- [ ] Create first signed release

---

## Prerequisites

Before proceeding, ensure you have:

### Required

1. **Xcode 15.0+** - For building the macOS app
2. **Git** - For version control
3. **GitHub Account** - For hosting releases and GitHub Pages
4. **macOS 14.0+** - Minimum deployment target

### Recommended

1. **Command Line Tools** - Install via `xcode-select --install`
2. **Homebrew** - For installing additional tools
3. **GitHub CLI** (`gh`) - For managing releases from terminal

### Verify Prerequisites

```bash
# Check Xcode version
xcodebuild -version

# Check Git
git --version

# Check GitHub CLI (optional)
gh --version

# Verify you can clone/build the project
cd /path/to/Notimanager
xcodebuild -scheme Notimanager -destination 'platform=macOS' build
```

---

## Part 1: Initial Setup

### Step 1.1: Verify Sparkle Integration

First, confirm that Sparkle is properly integrated into the project:

```bash
cd /path/to/Notimanager

# Check that Sparkle is in SPM dependencies
grep -A5 "sparkle-project" Notimanager.xcodeproj/project.pbxproj

# Verify Info.plist has Sparkle keys
/usr/libexec/PlistBuddy -c "Print SUFeedURL" Notimanager/Resources/Info.plist
/usr/libexec/PlistBuddy -c "Print SUPublicEDKey" Notimanager/Resources/Info.plist
```

Expected output:
```
https://abd3lraouf.github.io/Notimanager/appcast.xml
PUBLIC_KEY_PLACEHOLDER
```

### Step 1.2: Build and Run the App

Verify the app builds and runs correctly:

```bash
# Clean build
xcodebuild clean -scheme Notimanager

# Build the app
xcodebuild -scheme Notimanager -destination 'platform=macOS' build

# Run the app
open build/Build/Products/Debug/Notimanager.app
```

Verify that:
- The app launches successfully
- The menu bar icon appears
- "Check for Updates..." is visible in the menu
- General Settings shows the update toggles

---

## Part 2: Key Generation

Sparkle uses EdDSA (Ed25519) keys for signing updates. You must generate a key pair and keep the private key secure.

### Step 2.1: Download Sparkle Tools

Download the latest Sparkle 2.x distribution:

```bash
cd /path/to/Notimanager

# Create a tools directory
mkdir -p tools
cd tools

# Download Sparkle 2.7.0 (or latest 2.x)
wget https://github.com/sparkle-project/Sparkle/releases/download/2.7.0/Sparkle-2.7.0.tar.xz

# Extract the archive
tar xf Sparkle-2.7.0.tar.xz

# Verify the tools exist
ls -la Sparkle/bin/
```

You should see:
```
generate_keys
generate_appcast
sign_update
```

### Step 2.2: Generate EdDSA Key Pair

Run the `generate_keys` tool to create your signing keys:

```bash
./Sparkle/bin/generate_keys
```

**What this does:**
- Generates a new EdDSA (Ed25519) key pair
- Saves the **private key** in your macOS Login Keychain
- Prints the **public key** to terminal for you to copy

**Expected output:**
```
A key has been generated and saved in your keychain. Add the `SUPublicEDKey` key to
the Info.plist of each app for which you intend to use Sparkle for distributing
updates. It should appear like this:

    <key>SUPublicEDKey</key>
    <string>pfIShU4dEXqPd5ObYNfDBiQWcXozk7estwzTnF9BamQ=</string>
```

### Step 2.3: Save Your Public Key

**IMPORTANT**: Copy the public key string from the output. It will look something like:

```
pfIShU4dEXqPd5ObYNfDBiQWcXozk7estwzTnF9BamQ=
```

Save this key somewhere secure (you'll need it in Step 2.5).

### Step 2.4: Verify Key in Keychain

Confirm the private key was saved to your keychain:

```bash
# Search for Sparkle keys in keychain
security find-generic-password -s "Sparkle <your-bundle-id>" 2>&1 | grep -A5 "attributes"

# For Notimanager specifically:
security find-generic-password -s "Sparkle dev.abd3lraouf.notimanager" 2>&1 | grep -A5 "attributes"
```

You should see output indicating the key exists in your Login keychain.

### Step 2.5: Update Info.plist with Public Key

Now update the `Info.plist` with your actual public key:

```bash
cd /path/to/Notimanager

# Using PlistBuddy to update the key
/usr/libexec/PlistBuddy -c "Set :SUPublicEDKey YOUR_PUBLIC_KEY_HERE" Notimanager/Resources/Info.plist
```

**Or manually edit** `Notimanager/Resources/Info.plist`:

```xml
<!-- Replace PUBLIC_KEY_PLACEHOLDER with your actual key -->
<key>SUPublicEDKey</key>
<string>pfIShU4dEXqPd5ObYNfDBiQWcXozk7estwzTnF9BamQ=</string>
```

### Step 2.6: Export Private Key for GitHub Actions

To sign updates in CI/CD, you need to export the private key:

```bash
cd /path/to/Notimanager/tools

# Export the private key to a PEM file
./Sparkle/bin/generate_keys -x private-key.pem

# Verify the file was created
ls -la private-key.pem
```

**IMPORTANT**: Keep `private-key.pem` secure! Never commit it to git.

### Step 2.7: Base64-Encode the Private Key

GitHub Secrets work best with base64-encoded values:

```bash
# Base64 encode the private key
base64 -i private-key.pem > private-key-base64.txt

# Display the encoded key (copy this for GitHub Secrets)
cat private-key-base64.txt

# On macOS, if base64 -i doesn't work, try:
base64 private-key.pem > private-key-base64.txt
```

Copy the entire base64 string - you'll need it for Step 3.2.

### Step 2.8: Clean Up

Remove the unencrypted private key file (keep only the base64 version):

```bash
# Securely delete the unencrypted key
shred -u private-key.pem 2>/dev/null || rm private-key.pem

# Keep the base64 version somewhere safe (NOT in the repo)
mv private-key-base64.txt ~/secure-location/sparkle-key-b64.txt
```

---

## Part 3: GitHub Actions Configuration

Configure GitHub Actions to automatically sign updates and generate the appcast.

### Step 3.1: Add GitHub Repository Secret

1. Go to your GitHub repository: `https://github.com/abd3lraouf/Notimanager`
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Create a secret with these values:

   | Name | Value |
   |------|-------|
   | `SPARKLE_PRIVATE_KEY` | Paste the base64-encoded private key from Step 2.7 |

5. Click **Add secret**

### Step 3.2: Verify the Release Workflow

The `.github/workflows/release.yml` has been pre-configured with Sparkle support. Verify the key sections:

```bash
cd /path/to/Notimanager

# Check that Sparkle tools download is present
grep -A5 "Install Sparkle tools" .github/workflows/release.yml

# Check that appcast generation is present
grep -A10 "Generate appcast" .github/workflows/release.yml

# Check that appcast is uploaded as artifact
grep "appcast.xml" .github/workflows/release.yml
```

### Step 3.3: Understanding the Release Workflow

Here's what happens when you push a tag (e.g., `v1.4.0`):

1. **Checkout repository** - Gets your code
2. **Install Sparkle tools** - Downloads `generate_appcast`
3. **Configure code signing** - Sets up ad-hoc signing
4. **Update build version** - Sets `CFBundleVersion` from tag
5. **Build and archive** - Creates the app bundle
6. **Create DMG/ZIP** - Packages the app for distribution
7. **Setup signing key** - Imports `SPARKLE_PRIVATE_KEY` from secrets
8. **Generate appcast** - Creates signed `appcast.xml`
9. **Create GitHub Release** - Publishes assets to releases
10. **Upload artifacts** - Saves appcast as workflow artifact

### Step 3.4: Test the Workflow (Dry Run)

Before creating a real release, you can test the workflow:

```bash
cd /path/to/Notimanager

# Create a test tag
git tag v9.9.9-test
git push origin v9.9.9-test

# Monitor the workflow at:
# https://github.com/abd3lraouf/Notimanager/actions

# After testing, delete the test tag
git tag -d v9.9.9-test
git push origin :refs/tags/v9.9.9-test
```

---

## Part 4: Hosting the Appcast

The `appcast.xml` file must be hosted at a publicly accessible HTTPS URL.

### Step 4.1: Choose a Hosting Option

| Option | Difficulty | Cost | Recommended |
|--------|-----------|------|-------------|
| **GitHub Pages** | Easy | Free | ✅ Yes |
| **Netlify / Vercel** | Easy | Free | ✅ Yes |
| **Custom Server** | Medium | Varies | For advanced users |

### Step 4.2: Option A - GitHub Pages (Recommended)

#### 4.2.1: Enable GitHub Pages

1. Go to repository **Settings** → **Pages**
2. Under **Source**, select:
   - **Source**: GitHub Actions
   - OR **Branch**: `gh-pages` folder
3. Click **Save**

#### 4.2.2: Create GitHub Pages Workflow

Create `.github/workflows/deploy-pages.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  workflow_dispatch:  # Manual trigger
  release:
    types: [published]  # Run when release is published

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: macos-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download appcast from release
        uses: robinraju/release-downloader@v1.8
        with:
          repository: abd3lraouf/Notimanager
          tag: v${{ github.event.release.tag_name }}
          fileName: appcast.xml
          out-file-path: ./appcast.xml

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

#### 4.2.3: Verify the URL

After deployment, your appcast will be available at:

```
https://abd3lraouf.github.io/Notimanager/appcast.xml
```

Test it:

```bash
curl -I https://abd3lraouf.github.io/Notimanager/appcast.xml
```

### Step 4.3: Option B - Manual Upload

For simple setups, you can manually upload:

```bash
# After a release, download the appcast artifact
gh run download <run-id> -n appcast-xml

# Upload to your hosting via scp/rsync/ftp
scp appcast.xml user@server:/path/to/hosting/
```

### Step 4.4: Update SUFeedURL (If Needed)

If you're NOT using GitHub Pages at the default URL, update `Info.plist`:

```bash
# Update the feed URL
/usr/libexec/PlistBuddy -c "Set :SUFeedURL https://your-hosting.com/appcast.xml" Notimanager/Resources/Info.plist
```

---

## Part 5: Creating Your First Signed Release

Now that everything is configured, create your first properly signed release.

### Step 5.1: Prepare the Release

1. **Update the version** in `Info.plist`:

```bash
# Set version to 1.4.0 (example)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.4.0" Notimanager/Resources/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1.4.0" Notimanager/Resources/Info.plist
```

2. **Update CHANGELOG.md** with release notes:

```markdown
## [1.4.0] - 2025-01-17

### Added
- Automatic update checks using Sparkle
- "Check for Updates..." menu item
- Update settings in General settings pane

### Changed
- Improved update distribution workflow

### Security
- Added EdDSA signing for update verification
```

3. **Commit your changes**:

```bash
git add Notimanager/Resources/Info.plist docs/CHANGELOG.md
git commit -m "chore(release): prepare v1.4.0"
git push origin main
```

### Step 5.2: Create and Push the Tag

```bash
# Create annotated tag
git tag -a v1.4.0 -m "Release v1.4.0"

# Push the tag to trigger the workflow
git push origin v1.4.0
```

### Step 5.3: Monitor the Release Workflow

1. Go to: `https://github.com/abd3lraouf/Notimanager/actions`
2. Find the "Release" workflow run for your tag
3. Click into it to monitor progress
4. Verify that:
   - Build succeeds
   - Appcast is generated
   - Release is published

### Step 5.4: Download and Verify the Appcast

After the workflow completes:

```bash
# Download the appcast artifact
gh run download <run-id> -n appcast-xml

# Verify the content
cat appcast.xml

# Check for the sparkle:edSignature attribute
grep "sparkle:edSignature" appcast.xml
```

You should see an `edSignature` attribute on the enclosure, indicating the update is signed.

### Step 5.5: Deploy the Appcast

If using GitHub Pages with automatic deployment, this should happen automatically. Otherwise, manually deploy:

```bash
# Manual deployment example
cp appcast.xml ~/gh-pages/Notimanager/
cd ~/gh-pages/Notimanager
git add appcast.xml
git commit -m "Update appcast for v1.4.0"
git push origin gh-pages
```

---

## Part 6: Testing Updates

Before relying on Sparkle for production updates, thoroughly test the update flow.

### Step 6.1: Test Manual Update Check

1. **Download and install the current version** (e.g., v1.3.0)

2. **Run the app** and click "Check for Updates..." from the menu bar

3. **Expected result**:
   - Sparkle checks the appcast URL
   - If a newer version exists, shows an update alert
   - Offers to download and install the update

### Step 6.2: Test Automatic Update Checks

1. **Build an older version** for testing:

```bash
# Temporarily set version to something lower
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1.0.0" Notimanager/Resources/Info.plist

# Build
xcodebuild -scheme Notimanager -destination 'platform=macOS' build

# Run the app
open build/Build/Products/Debug/Notimanager.app
```

2. **Quit and relaunch** the app

3. **Expected result**: On second launch, Sparkle should check for updates automatically

### Step 6.3: Force Immediate Update Check

Clear the last check time to force an immediate check:

```bash
# Clear Sparkle's last check time
defaults delete dev.abd3lraouf.notimanager SULastCheckTime

# Also clear the last check time background
defaults delete dev.abd3lraouf.notimanager SULastCheckTimeBackground

# Now run the app - it should check immediately
open build/Build/Products/Debug/Notimanager.app
```

### Step 6.4: View Sparkle Logs

Monitor Sparkle's behavior using Console.app:

```bash
# Open Console.app
open -a Console

# Filter for Sparkle logs
# In the search box, enter: SUUpdater OR Sparkle
```

Or use the command line:

```bash
log stream --predicate 'process CONTAINS "Notimanager"' --level debug | grep -i sparkle
```

### Step 6.5: Test Update Download and Installation

1. Trigger an update check (manual or automatic)
2. When prompted to download, click "Install Update"
3. Verify:
   - Download starts and completes
   - App is relaunched after installation
   - New version is running (check About or menu)

### Step 6.6: Verify Signature Validation

To test that signature validation is working:

1. Try modifying a downloaded DMG (simulating tampering)
2. Attempt to install - Sparkle should reject it with a signature error

```bash
# This is for testing purposes only
# Download an update manually
curl -L -o test.dmg "https://github.com/abd3lraouf/Notimanager/releases/download/v1.4.0/Notimanager-1.4.0.dmg"

# Modify it (breaks signature)
echo "tampered" >> test.dmg

# Try to verify signature (should fail)
./tools/Sparkle/bin/sign_update --verify test.dmg
```

---

## Part 7: Ongoing Maintenance

### Step 7.1: Creating Future Releases

For each new release:

1. **Update version numbers**:
   ```bash
   /usr/libexec/PlistBuddy -c "Set :CFBundleVersion X.Y.Z" Notimanager/Resources/Info.plist
   /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString X.Y.Z" Notimanager/Resources/Info.plist
   ```

2. **Add release notes** to `docs/CHANGELOG.md`

3. **Commit changes**:
   ```bash
   git add .
   git commit -m "chore(release): prepare vX.Y.Z"
   ```

4. **Create and push tag**:
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin main
   git push origin vX.Y.Z
   ```

5. **Workflow handles the rest** automatically

### Step 7.2: Key Rotation

If your private key is compromised or you need to rotate keys:

1. **Generate a new key pair**:
   ```bash
   ./Sparkle/bin/generate_keys
   ```

2. **Update Info.plist** with the new public key

3. **Update GitHub secret** with the new private key

4. **Release a new version** with the new keys

5. **Sparkle will automatically transition** users to the new key

### Step 7.3: Monitoring Update Statistics

To track how many users are updating:

1. Check GitHub release asset download counts
2. Use GitHub Analytics to see appcast.xml requests
3. Consider adding analytics to your app

### Step 7.4: Updating Sparkle Framework

To update to a newer version of Sparkle:

```bash
# In Xcode:
# 1. File → Add Package Dependencies
# 2. Find "Sparkle" in the list
# 3. Select "Up to Next Major Version" and set minimum version
# 4. Click "Update Package" or "Add Package"

# Or manually edit project.pbxproj and update the minimum version
```

---

## Configuration Reference

### Info.plist Keys

| Key | Value | Description |
|-----|-------|-------------|
| `SUFeedURL` | `https://abd3lraouf.github.io/Notimanager/appcast.xml` | URL of the appcast feed |
| `SUPublicEDKey` | `<base64-public-key>` | EdDSA public key for signature verification |
| `SUEnableAutomaticChecks` | `true` (default) | Enable automatic update checks |
| `SUScheduledCheckInterval` | `86400` (default) | Seconds between checks (24 hours) |
| `SUAutomaticallyUpdate` | `false` (default) | Automatically install updates without prompting |

### User Defaults Keys

| Key | Type | Description |
|-----|------|-------------|
| `SULastCheckTime` | Date | When the last update check occurred |
| `SULastCheckTimeBackground` | Date | Last background check time |
| `SUEnableAutomaticChecks` | Boolean | Whether auto-checks are enabled |
| `SUSendProfileInfo` | Boolean | Whether to send anonymous system info |

### Appcast XML Structure

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>Notimanager Appcast</title>
        <link>https://abd3lraouf.github.io/Notimanager/appcast.xml</link>
        <description>Most recent updates for Notimanager</description>

        <item>
            <title>Version 1.4.0</title>
            <sparkle:version>1.4.0</sparkle:version>
            <sparkle:versionString>1.4.0</sparkle:versionString>
            <pubDate>Mon, 17 Jan 2025 12:00:00 +0000</pubDate>
            <enclosure
                url="https://github.com/abd3lraouf/Notimanager/releases/download/v1.4.0/Notimanager-1.4.0.dmg"
                sparkle:edSignature="..."
                length="..."
                type="application/octet-stream" />
            <description><![CDATA[
                <h2>What's New</h2>
                <ul>
                    <li>Added automatic updates</li>
                    <li>Fixed bugs</li>
                </ul>
            ]]></description>
        </item>
    </channel>
</rss>
```

---

## Troubleshooting

### Problem: "No updates available" when there should be

**Symptoms**: Sparkle says you're up to date even when a newer version exists.

**Possible Causes**:

1. **CFBundleVersion not incrementing**
   - Check: `/usr/libexec/PlistBuddy -c "Print CFBundleVersion" Notimanager/Resources/Info.plist`
   - Fix: Ensure version numbers always increase

2. **Appcast not accessible**
   - Check: `curl -I https://abd3lraouf.github.io/Notimanager/appcast.xml`
   - Fix: Ensure appcast is deployed and accessible

3. **Wrong SUFeedURL in Info.plist**
   - Check: `grep SUFeedURL Notimanager/Resources/Info.plist`
   - Fix: Update to correct URL

### Problem: "Signature verification failed"

**Symptoms**: Update fails with signature error.

**Possible Causes**:

1. **Public key mismatch**
   - Check: Compare `SUPublicEDKey` in Info.plist with output from `generate_keys`
   - Fix: Update Info.plist with correct public key

2. **Appcast not signed**
   - Check: `grep sparkle:edSignature appcast.xml`
   - Fix: Ensure `SPARKLE_PRIVATE_KEY` secret is set in GitHub

3. **Archive modified after signing**
   - Check: Download size matches what's in appcast
   - Fix: Re-sign the archive

### Problem: Update check never runs

**Symptoms**: No automatic update checks occur.

**Possible Causes**:

1. **Last check time too recent**
   - Check: `defaults read dev.abd3lraouf.notimanager SULastCheckTime`
   - Fix: `defaults delete dev.abd3lraouf.notimanager SULastCheckTime`

2. **Automatic checks disabled**
   - Check: `defaults read dev.abd3lraouf.notimanager SUEnableAutomaticChecks`
   - Fix: `defaults write dev.abd3lraouf.notimanager SUEnableAutomaticChecks -bool true`

### Problem: Can't download update

**Symptoms**: Update download fails or doesn't start.

**Possible Causes**:

1. **Invalid archive URL in appcast**
   - Check: Try downloading URL manually in browser
   - Fix: Correct URL in appcast

2. **Network/firewall issues**
   - Check: Can you reach GitHub Releases from the Mac?
   - Fix: Check firewall and network settings

3. **Not enough disk space**
   - Check: `df -h`
   - Fix: Free up disk space

### Problem: App doesn't relaunch after update

**Symptoms**: Update installs but app doesn't restart.

**Possible Causes**:

1. **Improper code signing**
   - Check: `codesign -dv Notimanager.app`
   - Fix: Ensure app is properly signed

2. **Hardened runtime issues**
   - Check: Entitlements configuration
   - Fix: Adjust entitlements if needed

---

## Security Best Practices

### 1. Key Security

- ✅ **DO** Store private keys in secure locations (Keychain, encrypted files)
- ❌ **DON'T** Commit private keys to version control
- ❌ **DON'T** Share private keys in chat, email, or tickets
- ✅ **DO** Use different keys for different apps
- ✅ **DO** Rotate keys if compromised

### 2. Update Security

- ✅ **DO** Serve updates over HTTPS only
- ✅ **DO** Sign all update archives
- ✅ **DO** Verify signatures before installation
- ❌ **DON'T** Use HTTP for appcast or downloads
- ❌ **DON'T** Allow unsigned updates in production

### 3. Code Signing

- ✅ **DO** Use Developer ID certificates for distribution
- ✅ **DO** Enable Hardened Runtime
- ✅ **DO** Notarize your app for macOS 10.15+
- ❌ **DON'T** Distribute unsigned apps

### 4. Hosting Security

- ✅ **DO** Use reputable hosting (GitHub Pages, Netlify)
- ✅ **DO** Enable HTTPS with valid certificates
- ✅ **DO** Monitor for unauthorized access
- ❌ **DON'T** Host on compromised servers

### 5. Release Security

- ✅ **DO** Review code before releases
- ✅ **DO** Test updates thoroughly
- ✅ **DO** Keep changelogs accurate
- ❌ **DON'T** Rush releases without testing

---

## Additional Resources

### Official Documentation

- [Sparkle Official Website](https://sparkle-project.org/)
- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle GitHub Repository](https://github.com/sparkle-project/Sparkle)
- [Publishing an Update Guide](https://sparkle-project.org/documentation/publishing/)

### Community Resources

- [Sparkle Discord](https://discord.gg/7U7TUKyCJh)
- [Stack Overflow - Sparkle Tag](https://stackoverflow.com/questions/tagged/sparkle)

### Tools

- `generate_keys` - Generate signing key pairs
- `generate_appcast` - Create signed appcast from archives
- `sign_update` - Sign individual update archives

### Example Implementations

- [Sparkle Sample App](https://github.com/sparkle-project/Sparkle/tree2.x/SampleApp)
- Various macOS apps using Sparkle (open source)

---

## Appendix: Quick Reference

### Essential Commands

```bash
# Generate keys
./Sparkle/bin/generate_keys

# Export private key
./Sparkle/bin/generate_keys -x private-key.pem

# Generate appcast
./Sparkle/bin/generate_appcast /path/to/updates/folder

# Sign update manually
./Sparkle/bin/sign_update archive.dmg

# Verify signature
./Sparkle/bin/sign_update --verify archive.dmg

# Update Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion X.Y.Z" Info.plist

# Read defaults
defaults read dev.abd3lraouf.notimanager

# Delete update check time
defaults delete dev.abd3lraouf.notimanager SULastCheckTime

# View Sparkle logs
log stream --predicate 'process CONTAINS "Notimanager"' --level debug
```

### Checklist for New Releases

- [ ] Update CFBundleVersion and CFBundleShortVersionString in Info.plist
- [ ] Add release notes to CHANGELOG.md
- [ ] Commit changes
- [ ] Create and push git tag
- [ ] Verify GitHub Actions workflow completes successfully
- [ ] Download and verify appcast.xml
- [ ] Deploy appcast to hosting
- [ ] Test update from older version
- [ ] Announce release to users

---

**Last Updated**: 2025-01-17

**Sparkle Version**: 2.7.0

**For questions or issues**, please open an issue on GitHub: https://github.com/abd3lraouf/Notimanager/issues
