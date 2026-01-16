# 📚 Notimanager Documentation Index

Complete documentation for Notimanager development, CI/CD, and icon generation.

## 🚀 Quick Setup (Start Here)

**New to the project?** Start here:
1. [**QUICK_REFERENCE.md**](QUICK_REFERENCE.md) - 2-page quick reference card
2. [**COMPLETE_SETUP_GUIDE.md**](COMPLETE_SETUP_GUIDE.md) - Full step-by-step setup guide

**Want the 5-minute version?**
- [**QUICK_START_CI.md**](QUICK_START_CI.md) - Essential steps only

## 📖 Documentation by Topic

### Icon System

| Document | Description |
|----------|-------------|
| [ICON_GENERATION.md](ICON_GENERATION.md) | Icon generation from SVG sources |
| [scripts/assets/](scripts/assets/) | SVG source files |

### Code Signing & CI/CD

| Document | Description |
|----------|-------------|
| [CICD_SETUP.md](CICD_SETUP.md) | Detailed CI/CD setup guide |
| [SELF_SIGNING_CI_SUMMARY.md](SELF_SIGNING_CI_SUMMARY.md) | Architecture overview |
| [PASSWORD_SETUP_CHANGES.md](PASSWORD_SETUP_CHANGES.md) | Password system changes |

### Build System

| Document | Description |
|----------|-------------|
| [BUILD.md](BUILD.md) | Build process documentation |

### Installation

| Document | Description |
|----------|-------------|
| [INSTALLATION.md](INSTALLATION.md) | User installation guide |
| [README.md](README.md) | Project overview and features |

### Development

| Document | Description |
|----------|-------------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| [LICENSE](LICENSE) | License information |

## 🛠️ Scripts Reference

### Certificate & CI Scripts

| Script | Purpose |
|--------|---------|
| `scripts/create-self-signed-cert.sh` | Create self-signed certificate (interactive password) |
| `scripts/setup-ci.sh` | Configure GitHub Actions secrets |
| `scripts/generate-all-icons.sh` | Generate all icons from SVG |
| `scripts/build.sh` | Main build orchestration script |
| `scripts/create-dmg.sh` | Create DMG installer |

### Build Commands

```bash
# Development build
./scripts/build.sh build

# Full release pipeline
./scripts/build.sh all

# Prepare for release (interactive)
./scripts/build.sh prepare

# Clean build artifacts
./scripts/build.sh clean
```

## 🔐 Security & Certificates

### Quick Setup

```bash
# 1. Create certificate
./scripts/create-self-signed-cert.sh
# → Prompts for password (min 8 chars)

# 2. Setup CI
./scripts/setup-ci.sh
# → Auto-loads password or prompts

# 3. Add GitHub secrets
# → SELF_SIGNED_CERTIFICATE (base64 cert)
# → CERTIFICATE_PASSWORD (your password)
```

### Password Management

- **Saved in**: `build/.certificate_password` (permissions: 600)
- **Load command**: `cat build/.certificate_password`
- **Change**: Re-run `./scripts/create-self-signed-cert.sh`

### Certificate Details

- **Name**: `Notimanager Self-Signed Code Signing`
- **Location**: `~/Library/Keychains/login.keychain-db`
- **Validity**: 10 years
- **Password**: User-defined (interactive)

## 🎨 Icon Generation

### Source Files

```
scripts/assets/
├── oui-editor-position-top-left.svg
├── oui-editor-position-top-right.svg
├── oui-editor-position-bottom-left.svg
└── oui-editor-position-bottom-right.svg
```

### Generated Icons

```
Notimanager/Resources/Assets.xcassets/
├── AppIcon.appiconset/
│   ├── AppIcon-Enabled_16x16.png
│   ├── AppIcon-Enabled_32x32.png
│   └── ... (all sizes)
└── MenuBarIcon*.imageset/
    ├── MenuBarIcon.png (default - top-right)
    ├── MenuBarIcon-disabled.png
    ├── MenuBarIcon-top-left.png
    ├── MenuBarIcon-top-right.png
    ├── MenuBarIcon-bottom-left.png
    └── MenuBarIcon-bottom-right.png
```

### Regenerate Icons

```bash
./scripts/generate-all-icons.sh
```

Icons auto-generate on every build.

## 🚢 CI/CD Pipeline

### Trigger

Push a version tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Workflow Steps

1. Import certificate (from GitHub secrets)
2. Generate icons (from SVG)
3. Build app (with code signing)
4. Create ZIP (signed)
5. Create DMG (signed)
6. Publish release (with artifacts)

### Monitor

- **Actions**: https://github.com/abd3lraouf/Notimanager/actions
- **Releases**: https://github.com/abd3lraouf/Notimanager/releases

## 📦 Release Workflow

### Creating a Release

```bash
# 1. Update CHANGELOG.md
vim CHANGELOG.md

# 2. Prepare release
./scripts/build.sh prepare
# Enter version: 1.0.0

# 3. Push
git push origin main
git push origin v1.0.0

# 4. Done!
# Check: https://github.com/abd3lraouf/Notimanager/releases
```

### Artifacts

Each release creates:
- `Notimanager-macOS.zip` - Signed app bundle
- `Notimanager-macOS.dmg` - Signed DMG installer

## 🔧 Common Tasks

### Check Certificate

```bash
security find-certificate -c "Notimanager Self-Signed Code Signing" -p | \
  openssl x509 -noout -dates
```

### Verify Signature

```bash
codesign -dv Notimanager.app
```

### Regenerate Icons

```bash
./scripts/generate-all-icons.sh
```

### Re-create Certificate

```bash
# Delete old
security delete-certificate -c "Notimanager Self-Signed Code Signing"

# Create new
./scripts/create-self-signed-cert.sh

# Update CI
./scripts/setup-ci.sh
```

### Check Password

```bash
cat build/.certificate_password
```

### Test Build

```bash
./scripts/build.sh clean
./scripts/build.sh build
```

### Test CI (without release)

```bash
git tag v1.0.0-test
git push origin v1.0.0-test
```

## 📝 Troubleshooting

### Certificate Issues

| Problem | Solution |
|---------|----------|
| Certificate not found | Run `./scripts/create-self-signed-cert.sh` |
| Password incorrect | Check `cat build/.certificate_password` |
| MAC verification failed | Re-enter password correctly |
| Certificate expired | Re-create certificate |

### Build Issues

| Problem | Solution |
|---------|----------|
| Icons outdated | `./scripts/generate-all-icons.sh` |
| Build fails | `./scripts/build.sh clean && ./scripts/build.sh build` |
| Code sign fails | Check certificate exists and is trusted |

### CI Issues

| Problem | Solution |
|---------|----------|
| Ad-hoc signing | Check GitHub secrets are set |
| Certificate import fails | Verify base64 encoding is correct |
| DMG not created | Check Node.js and npm are installed |

## 🎯 Learning Path

### First Time Setup

1. **Read** [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
2. **Follow** [COMPLETE_SETUP_GUIDE.md](COMPLETE_SETUP_GUIDE.md)
3. **Create certificate** with `./scripts/create-self-signed-cert.sh`
4. **Setup CI** with `./scripts/setup-ci.sh`
5. **Test** with a test release tag

### Understanding the System

1. **Read** [SELF_SIGNING_CI_SUMMARY.md](SELF_SIGNING_CI_SUMMARY.md) for architecture
2. **Read** [ICON_GENERATION.md](ICON_GENERATION.md) for icon system
3. **Read** [CICD_SETUP.md](CICD_SETUP.md) for CI/CD details

### Daily Development

1. **Use** [QUICK_REFERENCE.md](QUICK_REFERENCE.md) as a cheat sheet
2. **Make changes** to code
3. **Test locally** with `./scripts/build.sh build`
4. **Create release** when ready

## 📋 Quick Reference Cards

### Certificate Setup
```bash
./scripts/create-self-signed-cert.sh  # Create cert
./scripts/setup-ci.sh                   # Setup GitHub
```

### Build Commands
```bash
./scripts/build.sh build    # Dev build
./scripts/build.sh all      # Release pipeline
./scripts/build.sh prepare  # Tag version
```

### Icon Generation
```bash
./scripts/generate-all-icons.sh  # Regenerate icons
```

### Password Recovery
```bash
cat build/.certificate_password  # Show password
```

## 🌐 Online Resources

### GitHub
- **Repository**: https://github.com/abd3lraouf/Notimanager
- **Issues**: https://github.com/abd3lraouf/Notimanager/issues
- **Actions**: https://github.com/abd3lraouf/Notimanager/actions
- **Releases**: https://github.com/abd3lraouf/Notimanager/releases

### Secrets Configuration
- **Secrets URL**: https://github.com/abd3lraouf/Notimanager/settings/secrets/actions

## 📞 Support

### Getting Help

1. **Check documentation** - Start with relevant doc above
2. **Search issues** - https://github.com/abd3lraouf/Notimanager/issues
3. **Create issue** - Include:
   - Steps to reproduce
   - Error messages
   - Script output
   - System information

### Useful Debug Info

```bash
# System info
sw_vers
xcodebuild -version

# Certificate info
security find-certificate -c "Notimanager Self-Signed Code Signing" -p | \
  openssl x509 -noout -text | head -20

# GitHub CLI (if installed)
gh --version
gh auth status
gh secret list

# Build info
./scripts/build.sh --help 2>/dev/null || echo "See BUILD.md"
```

## 📚 Document Summary

| Document | For | Length |
|----------|-----|--------|
| QUICK_REFERENCE.md | Quick lookup | Short |
| COMPLETE_SETUP_GUIDE.md | First-time setup | Long |
| QUICK_START_CI.md | Fast setup | Short |
| CICD_SETUP.md | CI/CD details | Long |
| SELF_SIGNING_CI_SUMMARY.md | Understanding system | Long |
| PASSWORD_SETUP_CHANGES.md | Password system | Medium |
| ICON_GENERATION.md | Icon system | Medium |
| BUILD.md | Build details | Medium |
| INSTALLATION.md | End users | Medium |
| README.md | Project overview | Short |
| This file | Navigation | Short |

## 🎓 Recommended Reading Order

### New Developer
1. README.md
2. QUICK_REFERENCE.md
3. COMPLETE_SETUP_GUIDE.md

### Understanding Architecture
1. SELF_SIGNING_CI_SUMMARY.md
2. ICON_GENERATION.md
3. CICD_SETUP.md

### Daily Reference
1. QUICK_REFERENCE.md
2. BUILD.md
3. This file (for navigation)

---

**🎉 Happy Developing!**

For questions or issues, visit: https://github.com/abd3lraouf/Notimanager/issues
