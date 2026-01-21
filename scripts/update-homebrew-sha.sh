#!/bin/bash

# Update Homebrew Cask SHA256
# This script downloads the DMG and calculates the SHA256 hash for the Homebrew cask

set -e

VERSION="${1:-$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" /Applications/Notimanager.app/Contents/Info.plist 2>/dev/null || echo "2.2.0")}"
DMG_URL="https://github.com/abd3lraouf/Notimanager/releases/download/v${VERSION}/Notimanager-${VERSION}.dmg"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📦 Calculating SHA256 for Notimanager ${VERSION}${NC}"
echo ""
echo "Downloading: ${DMG_URL}"

# Download DMG to temp file
TEMP_DMG=$(mktemp)
trap "rm -f ${TEMP_DMG}" EXIT

curl -L -o "${TEMP_DMG}" "${DMG_URL}"

# Calculate SHA256
SHA256=$(shasum -a 256 "${TEMP_DMG}" | cut -d' ' -f1)

echo ""
echo -e "${GREEN}✅ SHA256: ${SHA256}${NC}"
echo ""

# Update the cask file
CASK_FILE="homebrew-notimanager.rb"
if [ -f "$CASK_FILE" ]; then
    echo "Updating ${CASK_FILE}..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed
        sed -i '' "s/sha256 \"[a-f0-9]\{64\}\"/sha256 \"${SHA256}\"/" "$CASK_FILE"
    else
        # Linux sed
        sed -i "s/sha256 \"[a-f0-9]\{64\}\"/sha256 \"${SHA256}\"/" "$CASK_FILE"
    fi
    sed -i '' "s/version \"[0-9.]\+\"/version \"${VERSION}\"/" "$CASK_FILE"
    echo -e "${GREEN}✅ Cask file updated${NC}"
fi

echo ""
echo "To test the cask locally:"
echo "  brew install --cask --debug ${CASK_FILE}"
echo ""
echo "To submit to Homebrew:"
echo "  1. Fork https://github.com/Homebrew/homebrew-cask"
echo "  2. Add your cask to Casks/"
echo "  3. Submit a pull request"
