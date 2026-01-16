# 🚀 Notimanager CI/CD Quick Reference

## One-Time Setup (15 minutes)

```bash
# 1. Create Certificate (5 min)
./scripts/create-self-signed-cert.sh
# → Set password (min 8 chars)
# → Certificate created
# → Password saved to build/.certificate_password

# 2. Setup GitHub Secrets (10 min)
./scripts/setup-ci.sh
# → Copy base64 certificate
# → Add to GitHub: SELF_SIGNED_CERTIFICATE
# → Add to GitHub: CERTIFICATE_PASSWORD
```

## Creating a Release (5 minutes)

```bash
# 1. Update CHANGELOG.md
vim CHANGELOG.md

# 2. Prepare Release
./scripts/build.sh prepare
# → Enter version: 2.1.0
# → Auto-commits and tags

# 3. Push
git push origin main
git push origin v2.1.0

# 4. Watch Build
# → https://github.com/abd3lraouf/Notimanager/actions
# → Auto-builds, signs, creates DMG/ZIP
# → Publishes to Releases
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Password not working | `cat build/.certificate_password` |
| Certificate not found | Run `./scripts/create-self-signed-cert.sh` |
| CI shows "ad-hoc signing" | Check GitHub secrets exist |
| Icons outdated | `./scripts/generate-all-icons.sh` |
| App won't open | `xattr -cr Notimanager.app` |

## Important Files

| File | Purpose |
|------|---------|
| `build/.certificate_password` | Your certificate password |
| `build/NotimanagerSelfSigned.p12` | Certificate file |
| `build/certificate-base64.txt` | Encoded certificate for GitHub |
| `scripts/create-self-signed-cert.sh` | Create certificate |
| `scripts/setup-ci.sh` | Setup GitHub secrets |
| `scripts/generate-all-icons.sh` | Generate icons |

## GitHub Secrets

- **URL**: https://github.com/abd3lraouf/Notimanager/settings/secrets/actions
- **Secret 1**: `SELF_SIGNED_CERTIFICATE`
  - Value: Contents of `build/certificate-base64.txt`
- **Secret 2**: `CERTIFICATE_PASSWORD`
  - Value: Your password (from `build/.certificate_password`)

## Quick Commands

```bash
# Create certificate
./scripts/create-self-signed-cert.sh

# Setup CI
./scripts/setup-ci.sh

# Build app
./scripts/build.sh build

# Full release pipeline
./scripts/build.sh all

# Generate icons
./scripts/generate-all-icons.sh

# Check certificate
security find-certificate -c "Notimanager Self-Signed Code Signing" -p | \
  openssl x509 -noout -dates

# Check saved password
cat build/.certificate_password

# Verify app signature
codesign -dv build/Notimanager.app

# Remove quarantine
xattr -cr Notimanager.app
```

## Documentation

- **Complete Guide**: `COMPLETE_SETUP_GUIDE.md`
- **Quick Start**: `QUICK_START_CI.md`
- **CI/CD Details**: `CICD_SETUP.md`
- **Architecture**: `SELF_SIGNING_CI_SUMMARY.md`
- **Password Changes**: `PASSWORD_SETUP_CHANGES.md`
- **Icon Generation**: `ICON_GENERATION.md`

## What Gets Automated

✅ Icon generation from SVG
✅ Building app with Xcode
✅ Code signing with certificate
✅ ZIP archive creation
✅ DMG installer creation
✅ GitHub Release creation
✅ Release notes generation
✅ Artifact uploading

## User Installation

Users need to:
1. Download DMG or ZIP
2. Right-click → Open (first time)
3. Grant Accessibility permissions

See: `INSTALLATION.md`

## Security Notes

⚠️ **Self-signed certificate = security warnings**
- This is expected and normal
- Users see one-time warning
- Documented in installation guide
- Acceptable for free distribution

✅ **Security measures in place:**
- Password stored securely (chmod 600)
- Certificate files gitignored
- GitHub Secrets encrypted
- Runtime flag enabled

---

**Need Help?** → See `COMPLETE_SETUP_GUIDE.md`
