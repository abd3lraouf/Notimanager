---
allowed-tools:
  Bash(git*)
  Bash(cat*)
  Bash(date*)
  Bash(/usr/libexec/PlistBuddy*)
description: Prepare and execute a complete release process
argument-hint: [version] [major|minor|patch|auto]
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: "!git diff --quiet || !git diff --cached --quiet"
          once: false
---

# Release Process for Notimanager

You are guiding the user through a complete release process. This is a comprehensive workflow that updates all necessary files and creates a proper git tag for the release.

## Current Context

Current Git Status: !`git status --short`

Current Branch: !`git branch --show-current`

Current Version from Info.plist:
!`/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Notimanager/Resources/Info.plist`

Latest Tag: !`git describe --tags --abbrev=0 2>/dev/null || echo "No tags found"`

## Release Checklist

Follow this checklist in order. Do NOT proceed to the next step until the current step is complete.

### Step 1: Determine the New Version

The version argument provided is: `$ARGUMENTS`

If the user provided:
- **Nothing (empty)**: Ask them what version bump they want (major, minor, patch, or custom version)
- **"major"**: Increment MAJOR version (e.g., 1.0.0 → 2.0.0)
- **"minor"**: Increment MINOR version (e.g., 1.0.0 → 1.1.0)
- **"patch"**: Increment PATCH version (e.g., 1.0.0 → 1.0.1)
- **"auto"**: Analyze commits to suggest version bump (default: patch)
- **Specific version** (e.g., "1.2.0"): Use this version

**Ask the user**: "What version should we release? Options: major, minor, patch, auto, or specify version (e.g., 1.2.0)"

Once determined, calculate the **NEW_VERSION** and store it for use in all subsequent steps.

### Step 2: Verify Prerequisites

Before starting the release, verify:

- [ ] Working directory is clean (no uncommitted changes)
- [ ] We are on the `main` branch (or ask if they want to release from current branch)
- [ ] CHANGELOG.md is up to date with an `[Unreleased]` section or a section for NEW_VERSION

**If working directory is NOT clean**:
1. Show the user the uncommitted changes: !`git diff --stat`
2. Ask: "You have uncommitted changes. Would you like to:
   a) Stash changes and continue
   b) Commit changes first (recommended)
   c) Cancel release"

**If not on main branch**:
Ask: "You're on the current branch, not main. Continue with release from this branch? (y/N)"

**Check CHANGELOG**:
!`cat docs/CHANGELOG.md 2>/dev/null || cat CHANGELOG.md 2>/dev/null || echo "CHANGELOG.md not found"`

If CHANGELOG doesn't have an entry for NEW_VERSION, ask: "CHANGELOG.md doesn't have an entry for version NEW_VERSION. Would you like to:
   a) Add it now (you'll need to describe the changes)
   b) Proceed without updating CHANGELOG
   c) Cancel release"

### Step 3: Review Recent Changes

Show the user what will be included in this release:

```
📋 Changes since last release (!`git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "initial"`):
!`git log --pretty=format:%h %s $(git describe --tags --abbrev=0 HEAD^ 2>/dev/null)..HEAD 2>/dev/null || git log --pretty=format:%h -10`
```

**Ask**: "Do these changes look correct for version NEW_VERSION? (y/N)"

### Step 4: Update Info.plist

Update the version in `Notimanager/Resources/Info.plist`:

**Current values**:
!`/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Notimanager/Resources/Info.plist`
!`/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Notimanager/Resources/Info.plist`

**Action**: Update both `CFBundleShortVersionString` and `CFBundleVersion` to NEW_VERSION

Tell the user you're about to update Info.plist, then execute:
```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString NEW_VERSION" Notimanager/Resources/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion NEW_VERSION" Notimanager/Resources/Info.plist
```

**Verify** the changes: !`/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Notimanager/Resources/Info.plist`

### Step 5: Update CHANGELOG.md

Ensure CHANGELOG.md has the version entry. The format should be:

```markdown
## [NEW_VERSION] - YYYY-MM-DD

### ✨ New Features
- Feature 1
- Feature 2

### 🔧 Improvements
- Improvement 1

### 🐛 Bug Fixes
- Bug fix 1
```

**If the entry exists but has the wrong date**, update the date to today: !`date +"%Y-%m-%d"`

**If the entry doesn't exist**, help the user create it by:
1. Asking them to describe the main changes
2. Offering to extract from git commit messages
3. Creating a properly formatted entry

### Step 6: Review All Changes

Show the user what will be committed:

```
📋 Files that will be committed:
!`git diff --name-only`
!`git diff --cached --name-only`
```

Show a diff of the changes:

```
📋 Changes to be committed:
!`git diff`
!`git diff --cached`
```

**Ask**: "Review the changes above. Ready to commit? (y/N)"

### Step 7: Create Release Commit

Create a conventional commit for the release:

```bash
git add Notimanager/Resources/Info.plist CHANGELOG.md docs/CHANGELOG.md
git commit -m "chore(release): prepare release vNEW_VERSION

- Update version to NEW_VERSION in Info.plist
- Update CHANGELOG.md for NEW_VERSION release
"
```

**Show the commit**: !`git log -1 --pretty=fuller`

### Step 8: Create Git Tag

Create an annotated tag for the release:

```bash
git tag -a vNEW_VERSION -m "Release vNEW_VERSION

Release notes:
- Main feature/fix summary
"
```

**Verify the tag**: !`git tag -l -n99 vNEW_VERSION 2>/dev/null || git tag -l vNEW_VERSION`

### Step 9: Push to Remote

**CRITICAL**: Ask for final confirmation before pushing:

```
🚀 Ready to push release vNEW_VERSION to remote!

This will:
1. Push commit: !`git rev-parse --short HEAD`
2. Push tag: vNEW_VERSION
3. Trigger GitHub Actions release workflow
4. Build and publish release artifacts

This action CANNOT be undone. Proceed? (yes/no)
```

The user must type "yes" (full word, not just "y") to proceed.

If confirmed:
```bash
git push origin main
git push origin vNEW_VERSION
```

### Step 10: Verify Release

After pushing, provide the user with:

```
✅ Release vNEW_VERSION initiated successfully!

📦 Release artifacts will be built by GitHub Actions:
- ZIP archive: Notimanager-macOS.zip
- DMG installer: Notimanager-macOS.dmg

🔗 Monitor the build at:
https://github.com/abd3lraouf/Notimanager/actions

📋 Release will be published at:
https://github.com/abd3lraouf/Notimanager/releases/tag/vNEW_VERSION

⏳ The build typically takes 5-10 minutes.
```

## Error Handling

If any step fails:
1. Stop immediately
2. Tell the user what went wrong
3. Suggest how to fix it
4. Offer to retry the step or cancel the release

## Additional Options

After successful release, ask:
"Would you like to:
   a) View the release on GitHub (opens browser)
   b) Create the next [Unreleased] section in CHANGELOG
   c) Start working on the next version (bump to dev version)
   d) Nothing, I'm done"

## Important Notes

- Always preserve the format of Info.plist (XML structure)
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Tag format must be `vNEW_VERSION` (with 'v' prefix)
- The CI workflow automatically builds on tag push
- Never force push tags
- Ensure CHANGELOG.md follows Keep a Changelog format
