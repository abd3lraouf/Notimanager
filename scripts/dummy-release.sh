#!/bin/bash
# Create a new dummy release for testing
# Usage: ./scripts/dummy-release.sh [version]
# If version is not provided, it will increment the patch version automatically

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Function to get current version from Info.plist
get_current_version() {
    /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Notimanager/Resources/Info.plist
}

# Function to increment patch version
increment_patch_version() {
    local version=$1
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    echo "${major}.${minor}.$((patch + 1))"
}

# Get current version
CURRENT_VERSION=$(get_current_version)
echo -e "${BLUE}Current version: ${CURRENT_VERSION}${NC}"

# Determine new version
if [ -n "$1" ]; then
    NEW_VERSION="$1"
else
    NEW_VERSION=$(increment_patch_version "$CURRENT_VERSION")
fi

echo -e "${GREEN}Creating dummy release: ${NEW_VERSION}${NC}"
echo ""

# Step 1: Update UpdateManager.swift with dummy comment
echo -e "${BLUE}Step 1: Adding dummy comment to UpdateManager.swift${NC}"
sed -i '' "s|// Testing.*|// Dummy change for testing ${NEW_VERSION} release|" Notimanager/Managers/UpdateManager.swift
echo -e "${GREEN}✅ Updated UpdateManager.swift${NC}"
echo ""

# Step 2: Commit the dummy change
echo -e "${BLUE}Step 2: Committing dummy change${NC}"
git add Notimanager/Managers/UpdateManager.swift
git commit -m "chore: add dummy comment for testing ${NEW_VERSION} release"
echo -e "${GREEN}✅ Committed dummy change${NC}"
echo ""

# Step 3: Update Info.plist
echo -e "${BLUE}Step 3: Updating version in Info.plist${NC}"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" Notimanager/Resources/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION" Notimanager/Resources/Info.plist
echo -e "${GREEN}✅ Updated Info.plist to ${NEW_VERSION}${NC}"
echo ""

# Step 4: Update CHANGELOG.md
echo -e "${BLUE}Step 4: Updating CHANGELOG.md${NC}"
TODAY=$(date +%Y-%m-%d)

# Check if version already exists in CHANGELOG
if grep -q "\[${NEW_VERSION}\]" docs/CHANGELOG.md; then
    echo -e "${YELLOW}⚠️  Version ${NEW_VERSION} already exists in CHANGELOG.md, skipping...${NC}"
else
    # Insert new version entry after [Unreleased] section
    TEMP_FILE=$(mktemp)
    awk "
        /\[Unreleased\]/ {
            print
            print
            print \"## [${NEW_VERSION}] - ${TODAY}\"
            print
            print \"### 🐛 Fixed\"
            print \"- **Dummy Release**: Bugfix release for testing update mechanism\"
            print
            next
        }
        { print }
    " docs/CHANGELOG.md > "$TEMP_FILE"
    mv "$TEMP_FILE" docs/CHANGELOG.md
    echo -e "${GREEN}✅ Added ${NEW_VERSION} entry to CHANGELOG.md${NC}"
fi
echo ""

# Step 5: Commit release changes
echo -e "${BLUE}Step 5: Committing release changes${NC}"
git add Notimanager/Resources/Info.plist docs/CHANGELOG.md
git commit -m "chore(release): prepare release v${NEW_VERSION}

- Update version to ${NEW_VERSION} in Info.plist
- Update docs/CHANGELOG.md for v${NEW_VERSION} release
- Dummy bugfix release for testing"
echo -e "${GREEN}✅ Committed release changes${NC}"
echo ""

# Step 6: Create tag
echo -e "${BLUE}Step 6: Creating git tag${NC}"
git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}

Dummy bugfix release for testing update mechanism"
echo -e "${GREEN}✅ Created tag v${NEW_VERSION}${NC}"
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Dummy release v${NEW_VERSION} created!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Commits created:${NC}"
git log --oneline -3
echo ""
echo -e "${YELLOW}To push this release, run:${NC}"
echo -e "${YELLOW}  git push origin main${NC}"
echo -e "${YELLOW}  git push origin v${NEW_VERSION}${NC}"
echo ""
echo -e "${YELLOW}This will trigger the GitHub Actions workflow to build the release.${NC}"
