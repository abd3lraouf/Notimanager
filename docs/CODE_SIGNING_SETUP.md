# Code Signing Setup

This document explains the code signing setup for Notimanager using a **free Apple ID**.

## Overview

Notimanager uses **Xcode's automatic code signing** with your free Apple ID. This provides:
- Proper code signing with Apple certificates
- No paid Developer account required
- Automatic certificate management

## Prerequisites

1. **Apple ID** - Free account (no paid Developer account needed)
2. **Xcode installed** - For local development
3. **App-specific password** - For CI/CD (generate at [appleid.apple.com](https://appleid.apple.com))

## Local Development Setup

### 1. Open in Xcode

```bash
open Notimanager.xcodeproj
```

### 2. Enable Automatic Signing

In Xcode:
1. Select the **Notimanager** target
2. Go to **Signing & Capabilities** tab
3. Check **"Automatically manage signing"**
4. Select your **Team** (your personal Apple ID)

Xcode will automatically download and configure the necessary **Apple Development** certificate.

### 3. Build

```bash
./scripts/build.sh all
```

The build scripts will automatically detect and use your Apple Development certificate.

## CI/CD Setup (GitHub Actions)

### Required GitHub Secrets

Go to: **Repository Settings → Secrets and variables → Actions**

Add these secrets:

| Secret | Value | How to get |
|--------|-------|------------|
| `APPLE_ID` | Your Apple ID email | Your Apple ID |
| `APPLE_ID_PASSWORD` | App-specific password | See instructions below |
| `APPLE_TEAM_ID` | Your Team ID | See instructions below |
| `SPARKLE_PRIVATE_KEY` | EdDSA private key | Run `./scripts/setup-sparkle.sh` |

### Generate App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Go to **Sign-In and Security**
4. Click **App-Specific Passwords**
5. Click **+** (or "Generate Password")
6. Enter a label (e.g., "GitHub Actions - Notimanager")
7. Copy the password (format: `abcd-efgh-ijkl-mnop`)

### Find Your Team ID

**In Xcode:**
```
Xcode → Settings (or Preferences) → Accounts
Select your Apple ID
Your Team ID is shown next to your name (10 characters)
```

**Or run this command:**
```bash
# List all available certificates
security find-identity -v -p codesigning
```

Your Team ID is a 10-character alphanumeric string (e.g., `5F97S3Q2DP`).

**Note:** With a free Apple ID, your Team ID is the same as your personal team identifier shown in Xcode.

## Building

### Local Build

```bash
# Full release build
./scripts/build.sh all

# Archive and export
./scripts/build.sh archive
./scripts/build.sh export

# Create DMG
./scripts/build.sh dmg
```

The build script will automatically find and use your **Apple Development** certificate.

### CI/CD Build

Push a version tag to trigger the release workflow:

```bash
git tag v2.1.15
git push origin v2.1.15
```

GitHub Actions will:
1. Configure Xcode with your Apple credentials
2. Download the Apple Development certificate automatically
3. Build and sign the app
4. Create signed DMG
5. Publish to GitHub Releases

## Certificate Details

With a free Apple ID, you get:

| Certificate | Type | Expiry | Notes |
|-------------|------|--------|-------|
| Apple Development | Development | 1 year (auto-renewed) | For local builds and CI |
| Developer ID Application | Distribution | Not available | Requires paid Developer account |

### What This Means

- ✅ Your app is properly code signed
- ✅ Works for local development and testing
- ⚠️ **Users need to right-click and select "Open" on first launch**
- ⚠️ **Apple may show an "unidentified developer" warning**

These warnings are normal for apps signed with a free Apple ID development certificate.

## User Instructions

When distributing your app, tell users:

### First Launch

1. Right-click (or Control-click) **Notimanager.app**
2. Select **Open**
3. Click **Open** in the security dialog
4. The app is now trusted and opens normally

This only needs to be done once per installation.

## Troubleshooting

### "No code signing certificate found"

**Local:**
```bash
# Check available certificates
security find-identity -v -p codesigning

# If empty, open Xcode and let it download certificates
open Notimanager.xcodeproj
# In Xcode: Select target → Signing & Capabilities → Enable "Automatically manage signing"
```

**CI/CD:**
- Verify `APPLE_ID`, `APPLE_ID_PASSWORD`, and `APPLE_TEAM_ID` secrets are set
- Check the app-specific password is correct
- Ensure your Team ID is correct (10 characters)

### Build Fails with "Code signing failed"

**Local:**
```bash
# Clean build folder
rm -rf build/
./scripts/build.sh clean
./scripts/build.sh all
```

**CI/CD:**
- Check the GitHub Actions logs for specific error
- Verify all secrets are correctly set
- Ensure your Apple ID is properly linked to Xcode

### Certificate Expired

```bash
# Open Xcode, it will automatically renew the certificate
open Notimanager.xcodeproj
```

Certificates are automatically managed by Xcode and renew when needed.

## Architecture

The following files handle code signing:

1. **`Notimanager.xcodeproj/project.pbxproj`**
   - `CODE_SIGN_STYLE = Automatic`
   - `DEVELOPMENT_TEAM = ""` (auto-detected from your Apple ID)

2. **`.github/workflows/release.yml`**
   - Uses Apple ID credentials for automatic signing
   - Xcode downloads Apple Development certificate automatically

3. **`scripts/build.sh`**
   - Auto-detects your Apple Development certificate
   - Uses it for signing the app

4. **`scripts/create-dmg.sh`**
   - Uses same certificate for DMG signing
   - Auto-detects available certificate

## Free Apple ID vs Paid Developer Account

| Feature | Free Apple ID | Paid Developer Account |
|---------|--------------|----------------------|
| Apple Development certificate | ✅ Yes | ✅ Yes |
| Developer ID certificate | ❌ No | ✅ Yes |
| Code signing | ✅ Yes | ✅ Yes |
| No right-click required | ❌ No | ✅ Yes |
| App Store distribution | ❌ No | ✅ Yes |
| Cost | Free | $99/year |

### Should You Upgrade?

Upgrade to a paid Developer account if:
- You want to distribute outside the Mac App Store
- You want users to open apps without warnings
- You need proper Developer ID signing

For personal projects or testing, a free Apple ID is sufficient.

## Security Notes

- **App-specific passwords** are required for CI/CD
- Never commit passwords to the repository
- Use GitHub Secrets for all sensitive data
- Certificates are managed by Apple and renewed automatically
