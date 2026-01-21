# Homebrew Cask Setup

This document explains how to publish and maintain the Notimanager Homebrew cask.

## What is Homebrew?

[Homebrew](https://brew.sh/) is the package manager for macOS. A **cask** is a formula for installing macOS applications.

## Current Status

- **Cask File**: `homebrew-notimanager.rb`
- **Official Repository**: Not yet submitted to Homebrew
- **Installation**: Users can install locally with `brew install --cask ./homebrew-notimanager.rb`

## Quick Start

### For Users

To install Notimanager via Homebrew:

```bash
# From the project root
brew install --cask ./homebrew-notimanager.rb
```

### For Maintainers

#### 1. Update SHA256 for New Release

After releasing a new version:

```bash
# Update SHA256 in the cask file
./scripts/update-homebrew-sha.sh 2.2.0
```

This will:
- Download the DMG from GitHub Releases
- Calculate the SHA256 hash
- Update `homebrew-notimanager.rb` with the new hash and version

#### 2. Test Locally

Before submitting:

```bash
# Test installation
brew install --cask ./homebrew-notimanager.rb

# Test uninstall
brew uninstall --cask notimanager
```

#### 3. Update Official Homebrew Cask

Once the cask is in the official repository:

```bash
# Update the livecheck
brew bump-cask-pr --notimanager

# Or manually create a PR
# 1. Fork Homebrew/homebrew-cask
# 2. Create branch: git checkout -b notimanager-2.2.0
# 3. Update Casks/notimanager.rb
# 4. Submit PR
```

## Cask File Structure

```ruby
cask "notimanager" do
  version "2.2.0"
  sha256 "calculated_sha256"

  url "https://github.com/abd3lraouf/Notimanager/releases/download/v#{version}/Notimanager-#{version}.dmg"
  name "Notimanager"
  desc "macOS notification positioning utility"
  homepage "https://github.com/abd3lraouf/Notimanager"

  app "Notimanager.app"

  uninstall quit: "dev.abd3lraouf.notimanager"

  livecheck do
    url "https://github.com/abd3lraouf/Notimanager/releases/latest/download/appcast.xml"
    strategy :sparkle
  end
end
```

### Fields Explained

| Field | Value | Purpose |
|-------|-------|---------|
| `version` | Current app version | Used for URL generation and livecheck |
| `sha256` | DMG checksum | Security verification |
| `url` | Download source | GitHub Releases DMG |
| `app` | App name | Path to .app inside DMG |
| `uninstall quit` | Bundle ID | Quit app before uninstall |
| `livecheck` | Update strategy | Uses Sparkle appcast |

## Submitting to Homebrew

### Initial Submission

1. **Fork the repository**:
   ```bash
   # Fork https://github.com/Homebrew/homebrew-cask
   git clone https://github.com/YOUR_USERNAME/homebrew-cask.git
   cd homebrew-cask
   ```

2. **Add the cask**:
   ```bash
   # Create the cask file
   cp /path/to/notimanager/homebrew-notimanager.rb Casks/notimanager.rb

   # Update SHA256 (if not already done)
   ./scripts/update-homebrew-sha.sh
   ```

3. **Test**:
   ```bash
   brew audit --cask --online Casks/notimanager.rb
   brew style Casks/notimanager.rb
   brew install --cask Casks/notimanager.rb
   ```

4. **Submit PR**:
   ```bash
   git checkout -b notimanager-2.2.0
   git add Casks/notimanager.rb
   git commit -m "Add notimanager cask"
   git push origin notimanager-2.2.0
   # Then create PR on GitHub
   ```

### Updating Existing Cask

```bash
# Use the bump-cask-pr command
brew bump-cask-pr --notimanager

# Or manually
brew bump-cask-pr --notimanager --version=2.2.0 --sha256=calculated_hash
```

## Release Workflow

When releasing a new version:

1. **Create release** (automated via CI):
   ```bash
   git tag v2.2.1
   git push origin v2.2.1
   ```

2. **Wait for CI** to build and publish the DMG

3. **Update cask**:
   ```bash
   ./scripts/update-homebrew-sha.sh 2.2.1
   ```

4. **Submit PR**:
   ```bash
   brew bump-cask-pr --notimanager
   ```

## Important Notes

### Code Signing Requirements (September 2026)

Starting September 2026, Homebrew will disable casks that fail Gatekeeper checks. The current self-signed certificate will trigger warnings.

**To prepare:**
1. Obtain an Apple Developer account ($99/year)
2. Update CI to use proper Developer ID certificate
3. Update the cask with the new signing info

### Livecheck

The cask uses Sparkle's `appcast.xml` for version checking, which means:
- Updates are detected automatically
- No manual version bumping needed
- Homebrew maintainers can use `brew livecheck` to check for updates

### Naming Convention

- **Cask token**: `notimanager` (lowercase)
- **App name**: `Notimanager` (original casing)
- **Bundle ID**: `dev.abd3lraouf.notimanager`

## Troubleshooting

### SHA256 Mismatch

```bash
# Recalculate SHA256 manually
curl -L -o /tmp/notimanager.dmg "https://github.com/abd3lraouf/Notimanager/releases/download/v2.2.0/Notimanager-2.2.0.dmg"
shasum -a 256 /tmp/notimanager.dmg
```

### Livecheck Fails

```bash
# Test livecheck manually
brew livecheck --debug --notimanager
```

### Installation Fails

```bash
# Install with debug output
brew install --cask --debug ./homebrew-notimanager.rb

# Check audit issues
brew audit --cask --online ./homebrew-notimanager.rb
```

## Further Reading

- [Homebrew Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
- [Adding Software to Homebrew](https://docs.brew.sh/Adding-Software-to-Homebrew)
- [Homebrew Livecheck](https://docs.brew.sh/rubydoc/Homebrew/Livecheck/Strategy/Sparkle.html)
- [Homebrew for Maintainers](https://docs.brew.sh/For-Maintainers)
