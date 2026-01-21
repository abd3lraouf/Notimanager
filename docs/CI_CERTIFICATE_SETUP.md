# CI Certificate Setup

This document explains how to set up code signing for automated CI/CD builds using a self-signed certificate.

## Overview

Notimanager uses a **self-signed code signing certificate** for CI/CD automation. This allows GitHub Actions to build and sign releases automatically without requiring a paid Apple Developer account.

## Prerequisites

1. **OpenSSL** - For certificate generation (usually pre-installed on macOS)
2. **GitHub CLI** (optional) - For adding secrets via command line

## Quick Setup

### 1. Generate the Self-Signed Certificate

Run the setup script:

```bash
./scripts/setup-ci-cert.sh
```

This will:
- Generate a self-signed code signing certificate
- Export it as `Notimanager-CI.p12`
- Display instructions for adding to GitHub Secrets

### 2. Add GitHub Secrets

Add these secrets to your GitHub repository:
**https://github.com/abd3lraouf/Notimanager/settings/secrets/actions**

| Secret | Value | How to get |
|--------|-------|------------|
| `CERTIFICATE_P12` | Base64 encoded .p12 file | `base64 -i Notimanager-CI.p12 \| pbcopy` |
| `CERTIFICATE_PASSWORD` | Keychain password | Use: `ci-keychain-password` |
| `CERTIFICATE_NAME` | Certificate name | Use: `Notimanager CI` |

### Using GitHub CLI (Recommended)

```bash
# After running setup-ci-cert.sh

gh secret set CERTIFICATE_P12 < <(base64 -i Notimanager-CI.p12)
gh secret set CERTIFICATE_PASSWORD -b "ci-keychain-password"
gh secret set CERTIFICATE_NAME -b "Notimanager CI"
```

### 3. Sparkle Private Key (Optional)

For Sparkle auto-update signing:

```bash
gh secret set SPARKLE_PRIVATE_KEY < private_key.pem
```

## How It Works

### CI Workflow

When you push a version tag (`v2.1.15`), GitHub Actions will:

1. **Set up keychain** - Create a temporary keychain
2. **Import certificate** - Import the self-signed certificate from secrets
3. **Build the app** - Archive and export with xcodebuild
4. **Create DMG** - Build the distribution disk image
5. **Sign with Sparkle** - Sign for auto-update (if key provided)
6. **Publish release** - Upload DMG and appcast to GitHub Releases

### Certificate Details

| Property | Value |
|----------|-------|
| Type | Self-signed Code Signing |
| Common Name | `Notimanager CI` |
| Organization | `Notimanager` |
| Validity | 10 years |
| Exportable | Yes (as .p12) |
| CI Compatible | Yes |

## User Experience

When users download the DMG:

### First Launch

1. Right-click (or Control-click) **Notimanager.app**
2. Select **Open**
3. Click **Open** in the security dialog
4. The app is now trusted and opens normally

This only needs to be done once per installation.

### Why Right-Click?

macOS shows this warning because:
- The certificate is self-signed (not from Apple)
- Gatekeeper doesn't recognize the certificate authority

This is **normal and expected** for apps signed with self-signed certificates.

## Comparison: Free vs Paid

| Feature | Self-Signed | Apple Developer Account |
|---------|-------------|------------------------|
| Cost | Free | $99/year |
| CI/CD | ✅ Yes | ✅ Yes |
| Exportable | ✅ Yes | ✅ Yes |
| User Experience | Right-click to open | Direct launch |
| App Store | ❌ No | ✅ Yes |
| Gatekeeper | Warning (once) | No warning |

## Local Development

For local development, use your **Apple Development** certificate from Xcode:

```bash
# Local builds use your Apple ID certificate
./scripts/build.sh all

# CI builds use the self-signed certificate
git tag v2.1.15
git push origin v2.1.15
```

## Troubleshooting

### "No signing certificate found"

**CI:**
- Verify all three secrets are set correctly
- Check that `CERTIFICATE_P12` is base64 encoded
- Ensure `CERTIFICATE_NAME` matches the certificate common name

**Local:**
```bash
# Check if certificate exists in keychain
security find-certificate -c "Notimanager CI"

# Re-run setup script
./scripts/setup-ci-cert.sh
```

### "Certificate expired"

The self-signed certificate is valid for **10 years**. To regenerate:

```bash
# Remove old certificate
security delete-certificate -c "Notimanager CI"

# Generate new one
./scripts/setup-ci-cert.sh
```

### Build fails in CI

Check the GitHub Actions logs:
1. Go to **Actions** tab
2. Select the failed workflow run
3. Check each step for errors

Common issues:
- Missing GitHub Secrets
- Incorrect base64 encoding
- Certificate password mismatch
- ExportOptions.plist not found

## Certificate Management

### View Certificate Details

```bash
# From the .p12 file
openssl pkcs12 -in Notimanager-CI.p12 -info -nokeys -passin pass:ci-keychain-password

# From the keychain
security find-certificate -c "Notimanager CI" -p | openssl x509 -text
```

### Re-generate Certificate

If you need to create a new certificate:

```bash
# 1. Run the setup script
./scripts/setup-ci-cert.sh

# 2. Update GitHub Secrets
gh secret set CERTIFICATE_P12 < <(base64 -i Notimanager-CI.p12)

# 3. Test locally
./scripts/build.sh all
```

### Backup

Keep a backup of your certificate:

```bash
# Backup the .p12 file
cp Notimanager-CI.p12 ~/Backup/

# Store the password securely
security add-generic-password -a "CI Certificate" -s "Notimanager CI" -w "ci-keychain-password"
```

## Security Notes

- **Never commit** `.p12` files to the repository
- **Use GitHub Secrets** for sensitive data
- The `ci-keychain-password` is the default - you can change it
- Self-signed certificates are trusted by **you only**
- For public distribution, consider an Apple Developer account

## Architecture

### Files

| File | Purpose |
|------|---------|
| `scripts/setup-ci-cert.sh` | Generates the self-signed certificate |
| `.github/workflows/release.yml` | CI workflow that uses the certificate |
| `scripts/ExportOptions.plist` | Xcode export configuration |

### Workflow Steps

1. **Setup** - Generate certificate locally
2. **Secrets** - Add certificate to GitHub Secrets
3. **Trigger** - Push a version tag
4. **Build** - CI builds and signs automatically
5. **Release** - Published to GitHub Releases

## Testing Locally

To test the CI certificate locally:

```bash
# 1. Generate certificate
./scripts/setup-ci-cert.sh

# 2. Import to keychain
security import Notimanager-CI.p12 \
  -k ~/Library/Keychains/login.keychain-db \
  -P ci-keychain-password \
  -T /usr/bin/codesign

# 3. Build with the certificate
xcodebuild -project Notimanager.xcodeproj \
  -scheme Notimanager \
  -configuration Release \
  CODE_SIGN_IDENTITY="Notimanager CI" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=""
```

## Further Reading

- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Sparkle Documentation](https://sparkle-project.org/)
