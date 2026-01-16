#!/bin/bash

# Changelog Update Script for Notimanager
# This script helps update CHANGELOG.md when preparing a new release

set -e

CHANGELOG_FILE="CHANGELOG.md"
VERSION_REGEX="\[Unreleased\]"

echo "📋 Notimanager Changelog Updater"
echo "================================="
echo ""

# Check if CHANGELOG.md exists
if [ ! -f "$CHANGELOG_FILE" ]; then
    echo "❌ CHANGELOG.md not found in current directory"
    exit 1
fi

# Get current unreleased section
UNRELEASED_CONTENT=$(awk '/^## \[Unreleased\]/{flag=1; next} /^## \[/{flag=0} flag' "$CHANGELOG_FILE")

if [ -z "$UNRELEASED_CONTENT" ]; then
    echo "⚠️  No unreleased changes found in CHANGELOG.md"
    echo "   Add changes under the [Unreleased] section before running this script."
    exit 1
fi

echo "📝 Current unreleased changes:"
echo "$UNRELEASED_CONTENT"
echo ""

# Prompt for version
read -p "Enter new version (e.g., 2.1.0): " NEW_VERSION
read -p "Enter release date (default: today): " RELEASE_DATE

# Use today's date if not provided
if [ -z "$RELEASE_DATE" ]; then
    RELEASE_DATE=$(date +"%Y-%m-%d")
fi

# Confirm
echo ""
echo "Creating release:"
echo "  Version: $NEW_VERSION"
echo "  Date: $RELEASE_DATE"
echo ""
read -p "Proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Update the changelog
echo ""
echo "📝 Updating CHANGELOG.md..."

# Create a temporary file
TEMP_FILE=$(mktemp)

# Process the changelog
awk -v new_ver="$NEW_VERSION" -v new_date="$RELEASE_DATE" '
/^## \[Unreleased\]/ {
    print
    print
    print "## [" new_ver "] - " new_date
    next
}
{print}
' "$CHANGELOG_FILE" > "$TEMP_FILE"

# Replace the original file
mv "$TEMP_FILE" "$CHANGELOG_FILE"

# Create new Unreleased section at the top
sed -i '' '/^## \['"$NEW_VERSION"'\]/a\
\
### Planned\
\
- New features coming soon\
' "$CHANGELOG_FILE"

echo "✅ CHANGELOG.md updated!"
echo ""

# Show what was added
echo "📋 New release section:"
awk '/^## \['"$NEW_VERSION"'\]/{flag=1} /^## \[Unreleased\]/{if(flag) exit} flag' "$CHANGELOG_FILE"
echo ""

echo "📌 Next steps:"
echo "   1. Review the updated CHANGELOG.md"
echo "   2. Commit the changes: git add CHANGELOG.md && git commit -m 'chore: prepare for release $NEW_VERSION'"
echo "   3. Create and push tag: git tag v$NEW_VERSION && git push origin v$NEW_VERSION"
echo "   4. GitHub Actions will build and publish the release"
echo ""

# Optionally show git log for reference
read -p "Show recent git commits for reference? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "📜 Recent commits:"
    git log --oneline -10
    echo ""
fi
