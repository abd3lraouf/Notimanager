#!/bin/bash

# Notimanager DMG Creation Script
# Uses create-dmg npm package for beautiful DMG creation

set -e

# Configuration
APP_NAME="Notimanager"
APP_FILE="Notimanager.app"
SOURCE_APP="build/release/${APP_FILE}"
BUILD_DIR="build"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}📦 Notimanager DMG Creation${NC}"
echo "==========================="
echo ""

# Check if app exists
if [ ! -d "$SOURCE_APP" ]; then
    echo -e "${RED}❌ Error: ${APP_FILE} not found at ${SOURCE_APP}${NC}"
    echo ""
    echo "Build the app first:"
    echo "  ./scripts/build.sh export"
    exit 1
fi

echo -e "${GREEN}✅ Found ${APP_FILE}${NC}"

# Get version
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${SOURCE_APP}/Contents/Info.plist" 2>/dev/null || echo "unknown")
echo "📋 App Version: ${VERSION}"
echo ""

# Check for create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}⚠️  create-dmg not found${NC}"
    echo "Using npx to run create-dmg..."
    echo ""

    if command -v npx &> /dev/null; then
        CREATE_DMG_CMD="npx -y create-dmg"
    else
        echo -e "${RED}❌ Node.js/npm not found${NC}"
        echo ""
        echo "Please install Node.js:"
        echo "  brew install node"
        exit 1
    fi
else
    CREATE_DMG_CMD="create-dmg"
fi

# Check for code signing certificate
echo -e "${BLUE}🔍 Checking for code signing certificate...${NC}"

CERT_ID=""
CERT_ID=$(security find-identity -v -p codesigning 2>/dev/null | grep "Notimanager" | head -1 | awk '{print $2}' || echo "")

if [ -n "$CERT_ID" ]; then
    echo -e "${GREEN}✅ Found certificate: ${CERT_ID}${NC}"
    CODE_SIGN_FLAGS="--identity=${CERT_ID}"
else
    echo -e "${YELLOW}⚠️  No certificate found, using ad-hoc signing${NC}"
    CODE_SIGN_FLAGS="--no-code-sign"
fi

echo ""

# Sign the app first
echo -e "${BLUE}✍️  Signing application...${NC}"
codesign --force --deep --sign "-" "$SOURCE_APP" 2>/dev/null || true
echo -e "${GREEN}✅ App signed${NC}"

echo ""
echo -e "${BLUE}📦 Creating DMG with create-dmg...${NC}"
echo ""

# Create DMG in the app's directory
cd build/release

if $CREATE_DMG_CMD \
    --overwrite \
    ${CODE_SIGN_FLAGS} \
    "$APP_FILE" 2>&1; then

    # Find the created DMG
    CREATED_DMG=$(ls -t ${APP_NAME}*.dmg 2>/dev/null | head -1)

    if [ -n "$CREATED_DMG" ] && [ -f "$CREATED_DMG" ]; then
        # Move to build directory with standard name
        mv "$CREATED_DMG" "../${APP_NAME}-macOS.dmg"

        # Return to original directory
        cd ../..

        DMG_SIZE=$(du -h "${BUILD_DIR}/${APP_NAME}-macOS.dmg" | cut -f1)
        echo ""
        echo -e "${GREEN}${BOLD}✅ DMG created successfully!${NC}"
        echo ""
        echo "📦 Output: ${BUILD_DIR}/${APP_NAME}-macOS.dmg"
        echo "📊 Size: ${DMG_SIZE}"
        echo ""
        echo "🚀 To test the DMG:"
        echo "   open ${BUILD_DIR}/${APP_NAME}-macOS.dmg"
        echo ""

        # Show DMG info
        echo "📋 DMG Information:"
        hdiutil imageinfo "${BUILD_DIR}/${APP_NAME}-macOS.dmg" 2>/dev/null | grep -E "Checksum|Format" | head -2
    else
        cd ../..
        echo -e "${RED}❌ DMG file not found after creation${NC}"
        exit 1
    fi
else
    cd ../..
    echo -e "${RED}❌ DMG creation failed${NC}"
    exit 1
fi
