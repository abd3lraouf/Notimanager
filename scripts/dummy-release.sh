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

# Function to prompt for Y/N confirmation (default: yes)
confirm() {
    local prompt="$1"
    local response

    while true; do
        read -p "$(echo -e "${YELLOW}${prompt} (Y/n): ${NC}")" response
        case "$response" in
            [Yy]|[Yy][Ee][Ss]|"")
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                echo -e "${RED}Please answer y or n${NC}"
                ;;
        esac
    done
}

# Function to validate CHANGELOG.md structure
validate_and_fix_changelog() {
    local changelog="$1"
    local temp_file="$2"

    # Remove duplicate [Unreleased] headers and fix structure
    # This awk script:
    # 1. Removes duplicate consecutive [Unreleased] lines
    # 2. Ensures [Unreleased] is followed by a blank line
    # 3. Ensures version entries are properly formatted
    awk '
    BEGIN { last_unreleased = 0; printed_blank = 0 }
    /^## \[Unreleased\]/ {
        if (!last_unreleased) {
            print
            last_unreleased = 1
            printed_blank = 0
        }
        next
    }
    /^## \[/ {
        # Print blank line before new version if not already printed
        if (!printed_blank && last_unreleased) {
            print ""
            printed_blank = 1
        }
        last_unreleased = 0
        printed_blank = 0
        print
        next
    }
    { print; printed_blank = 0 }
    ' "$changelog" > "$temp_file"

    # Replace original if different
    if ! diff -q "$changelog" "$temp_file" > /dev/null 2>&1; then
        mv "$temp_file" "$changelog"
        echo -e "${YELLOW}🔧 Fixed CHANGELOG.md structure${NC}"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

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

# Validate and fix CHANGELOG before starting
echo -e "${BLUE}🔍 Validating CHANGELOG.md structure...${NC}"
TEMP_CHANGELOG=$(mktemp)
if validate_and_fix_changelog "docs/CHANGELOG.md" "$TEMP_CHANGELOG"; then
    echo -e "${GREEN}✅ CHANGELOG.md is clean${NC}"
    echo ""
fi

# Get current version
CURRENT_VERSION=$(get_current_version)
echo -e "${BLUE}Current version: ${CURRENT_VERSION}${NC}"

# Determine new version
if [ -n "$1" ]; then
    NEW_VERSION="$1"
else
    NEW_VERSION=$(increment_patch_version "$CURRENT_VERSION")
fi

echo -e "${GREEN}Will create dummy release: ${NEW_VERSION}${NC}"
echo ""

# Confirm before starting
if ! confirm "Create dummy release v${NEW_VERSION}?"; then
    echo -e "${RED}❌ Aborted${NC}"
    exit 0
fi
echo ""

# Step 1: Update UpdateManager.swift with dummy comment
echo -e "${BLUE}Step 1: Adding dummy comment to UpdateManager.swift${NC}"

# Create a unique change by appending a newline comment instead of replacing
# This ensures git always sees a change
echo "" >> Notimanager/Managers/UpdateManager.swift
echo "// Dummy change for testing ${NEW_VERSION} release" >> Notimanager/Managers/UpdateManager.swift

echo -e "${GREEN}✅ Updated UpdateManager.swift${NC}"
echo ""

# Step 2: Commit the dummy change
echo -e "${BLUE}Step 2: Committing dummy change${NC}"
if ! confirm "Commit the dummy change?"; then
    echo -e "${RED}❌ Aborted - changes not committed${NC}"
    echo -e "${YELLOW}💡 Tip: Reset changes with: git checkout -- Notimanager/Managers/UpdateManager.swift${NC}"
    exit 0
fi

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
if grep -q "\\[${NEW_VERSION}\\]" docs/CHANGELOG.md; then
    echo -e "${YELLOW}⚠️  Version ${NEW_VERSION} already exists in CHANGELOG.md, skipping...${NC}"
else
    # Use Python for more reliable text manipulation
    python3 << PYTHON_SCRIPT
changelog_path = "docs/CHANGELOG.md"
version = "$NEW_VERSION"
date = "$TODAY"

with open(changelog_path, 'r') as f:
    lines = f.readlines()

# Build output, find insertion point after [Unreleased] section
output = []
i = 0
inserted = False

# Find [Unreleased] and collect its content
while i < len(lines):
    if lines[i].startswith('## [Unreleased]'):
        # Add the [Unreleased] header
        output.append(lines[i])
        i += 1
        # Add all content under [Unreleased]
        while i < len(lines) and not lines[i].startswith('## ['):
            output.append(lines[i])
            i += 1
        # Now insert the new version
        output.append(f'## [{version}] - {date}\n')
        output.append('\n')
        output.append('### 🐛 Fixed\n')
        output.append('- **Dummy Release**: Bugfix release for testing update mechanism\n')
        output.append('\n')
        inserted = True
        # Continue with the rest of the file (next version header)
    else:
        output.append(lines[i])
        i += 1

with open(changelog_path, 'w') as f:
    f.writelines(output)

print(f"✅ Added {version} entry to CHANGELOG.md")
PYTHON_SCRIPT
fi
echo ""

# Step 5: Commit release changes
echo -e "${BLUE}Step 5: Committing release changes${NC}"
if ! confirm "Commit release changes (Info.plist, CHANGELOG.md)?"; then
    echo -e "${RED}❌ Aborted - changes not committed${NC}"
    echo -e "${YELLOW}💡 Tip: Reset changes with: git checkout -- Notimanager/Resources/Info.plist docs/CHANGELOG.md${NC}"
    exit 0
fi

git add Notimanager/Resources/Info.plist docs/CHANGELOG.md
git commit -m "chore(release): prepare release v${NEW_VERSION}

- Update version to ${NEW_VERSION} in Info.plist
- Update docs/CHANGELOG.md for v${NEW_VERSION} release
- Dummy bugfix release for testing"
echo -e "${GREEN}✅ Committed release changes${NC}"
echo ""

# Step 6: Create tag
echo -e "${BLUE}Step 6: Creating git tag${NC}"
if ! confirm "Create git tag v${NEW_VERSION}?"; then
    echo -e "${RED}❌ Aborted - tag not created${NC}"
    exit 0
fi

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
echo ""

# Final confirmation for push
if confirm "Push to remote now?"; then
    echo -e "${BLUE}🚀 Pushing to remote...${NC}"
    git push origin main
    git push origin "v${NEW_VERSION}"
    echo -e "${GREEN}✅ Pushed successfully!${NC}"
    echo -e "${YELLOW}🔗 Check the GitHub Actions workflow for build progress${NC}"
else
    echo -e "${YELLOW}⏸️  Not pushed. Push manually when ready:${NC}"
    echo -e "${YELLOW}  git push origin main && git push origin v${NEW_VERSION}${NC}"
fi
