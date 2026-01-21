# Release Process

This document describes the automated release process for Notimanager.

## Overview

Releases are **fully automated** via GitHub Actions. When you push a version tag, CI will:
1. Build the app with the self-signed certificate
2. Create a DMG disk image
3. Sign with Sparkle (for auto-updates)
4. Publish to GitHub Releases

## Prerequisites

Ensure these are set up:

1. **GitHub Secrets** (run `./scripts/setup-ci-cert.sh` if not):
   ```bash
   gh secret list
   ```
   Required:
   - `CERTIFICATE_P12` - Base64 encoded certificate
   - `CERTIFICATE_PASSWORD` - Keychain password
   - `CERTIFICATE_NAME` - Certificate name

2. **Optional Sparkle Key** (for auto-update signing):
   - `SPARKLE_PRIVATE_KEY` - EdDSA private key

## Creating a Release

### 1. Update CHANGELOG.md

Add a new version entry:

```markdown
## [2.1.15] - 2026-01-21

### ✨ New Features
- Add new feature description

### 🐛 Bug Fixes
- Fix bug description

### 🔧 Improvements
- Improvement description
```

### 2. Commit Changes

```bash
git add docs/CHANGELOG.md
git commit -m "chore: release v2.1.15"
```

### 3. Push Version Tag

```bash
git tag v2.1.15
git push origin main
git push origin v2.1.15
```

### 4. Wait for CI

GitHub Actions will automatically:
- Build the app (~5-10 minutes)
- Create signed DMG
- Generate release notes from CHANGELOG
- Publish to GitHub Releases

Watch progress at:
```
https://github.com/abd3lraouf/Notimanager/actions
```

### 5. Verify Release

Once complete, check:
```
https://github.com/abd3lraouf/Notimanager/releases
```

The release should include:
- `Notimanager-{VERSION}.dmg` - Signed disk image
- `appcast.xml` - Sparkle update feed
- Release notes from CHANGELOG

## Version Numbering

Notimanager uses [Semantic Versioning](https://semver.org/):

- **MAJOR** (.2.x.x) - Incompatible API changes
- **MINOR** (x.1.x) - New features (backwards compatible)
- **PATCH** (x.x.15) - Bug fixes (backwards compatible)

Examples:
- `v2.2.0` - New feature release
- `v2.1.16` - Bug fix release
- `v3.0.0` - Major version change

## Troubleshooting

### Release Failed

Check the GitHub Actions logs:
1. Go to Actions tab
2. Click on failed workflow run
3. Expand failed steps for error details

Common issues:
- **Certificate expired** - Run `./scripts/setup-ci-cert.sh` again
- **Build error** - Check Xcode project settings
- **Missing secrets** - Run `gh secret list` to verify

### Need to Cancel Release

If you push a tag by mistake:

1. Delete the tag locally and remotely:
   ```bash
   git tag -d v2.1.15
   git push origin :refs/tags/v2.1.15
   ```

2. Cancel the workflow run on GitHub

3. Delete the draft release (if created)

### Users Can't Open App

With self-signed certificate, users must:
1. Right-click (or Control-click) the app
2. Select "Open"
3. Click "Open" in the security dialog

This only needs to be done once per installation.

## Checking Existing Releases

```bash
# List all releases
gh release list

# View latest release
gh release view latest

# Download latest DMG
gh release download latest --pattern "*.dmg"
```

## Rollback Procedure

If a release has critical issues:

1. **Yank the release** (mark as prerelease/draft):
   ```bash
   gh release edit v2.1.15 --prerelease true
   ```

2. **Delete the release** (if necessary):
   ```bash
   gh release delete v2.1.15 --yes
   git tag -d v2.1.15
   git push origin :refs/tags/v2.1.15
   ```

3. **Issue a fix release**:
   - Fix the issue
   - Bump version to v2.1.16
   - Create new release

## Testing Locally Before Release

Before pushing a tag, you can test the build locally:

```bash
# Clean build
./scripts/build.sh clean

# Build and create DMG
./scripts/build.sh all

# Test the DMG
open build/Notimanager*.dmg
```

## Release Checklist

Before pushing a release tag:

- [ ] CHANGELOG.md updated with version notes
- [ ] All changes committed
- [ ] GitHub secrets configured (CERTIFICATE_P12, CERTIFICATE_PASSWORD, CERTIFICATE_NAME)
- [ ] Sparkle key set (if using auto-updates)
- [ ] Version number follows semantic versioning
- [ ] Local build tested (optional but recommended)

## Auto-Updates

Notimanager uses [Sparkle](https://sparkle-project.org/) for automatic updates:

1. Each release includes `appcast.xml`
2. App checks for updates on launch
3. New versions are downloaded automatically
4. User is prompted to install

**Note:** With self-signed certificate, the first launch of the updated app will also require right-click → "Open".

## CI/CD Workflow Details

The release workflow (`.github/workflows/release.yml`) runs these steps:

| Step | Description | Duration |
|------|-------------|----------|
| Checkout | Clone repository | ~10s |
| Extract Version | Parse tag name | ~5s |
| Setup Keychain | Import certificate | ~15s |
| Build App | Compile with Xcode | ~3-5 min |
| Create DMG | Build disk image | ~1-2 min |
| Sign Sparkle | Sign for updates | ~10s |
| Update Appcast | Generate update feed | ~10s |
| Generate Changelog | Extract notes | ~10s |
| Publish Release | Upload to GitHub | ~30s |

**Total time:** ~5-10 minutes

## Further Reading

- [Semantic Versioning](https://semver.org/)
- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [CI Certificate Setup](./CI_CERTIFICATE_SETUP.md)
