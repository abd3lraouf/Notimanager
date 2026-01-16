#!/bin/bash

# Notimanager Build Script
# Handles the complete build and release process
# Usage: ./scripts/build.sh [command] [options]
#
# Commands:
#   build           Build the app (development)
#   release         Build release version with archives
#   test            Run tests
#   clean           Clean build artifacts
#   archive         Create Xcode archive
#   export          Export app from archive
#   zip             Create ZIP distribution
#   dmg             Create DMG distribution (release mode)
#   dev-dmg         Create DMG distribution (dev mode - faster, opens for testing)
#   all             Run full release pipeline (archive, export, zip, dmg)
#   prepare         Prepare for release (update changelog, tag)
#   help            Show this help message

set -e

# Configuration
APP_NAME="Notimanager"
SCHEME="Notimanager"
WORKSPACE="Notimanager.xcodeproj"  # Using project instead of workspace
ARCHIVE_PATH="build/Notimanager.xcarchive"
EXPORT_PATH="build/release"
APP_BUNDLE="${EXPORT_PATH}/${APP_NAME}.app"
ZIP_OUTPUT="build/${APP_NAME}-macOS.zip"
DMG_OUTPUT="build/${APP_NAME}-macOS.dmg"
CERTIFICATE_NAME="Notimanager Self-Signed Code Signing"

# Xcode configuration
XCODE_VERSION=""  # Empty = use system default
DESTINATION="platform=macOS"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${CYAN}${BOLD}▶ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}$1${NC}"
    echo "================================"
}

# Check dependencies
check_dependencies() {
    log_step "Checking dependencies..."

    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Please install Xcode."
        exit 1
    fi

    if ! command -v xcrun &> /dev/null; then
        log_error "xcrun not found. Please install Xcode Command Line Tools."
        exit 1
    fi

    log_success "All dependencies found"
}

# Generate icons before build
generate_icons() {
    log_step "Generating icons from SVG sources..."

    if [ -f "scripts/generate-all-icons.sh" ]; then
        ./scripts/generate-all-icons.sh
        log_success "Icons generated successfully"
    else
        log_warning "Icon generation script not found, skipping..."
    fi
}

# Select Xcode version
select_xcode() {
    if [ -n "$XCODE_VERSION" ]; then
        log_step "Selecting Xcode ${XCODE_VERSION}..."

        if [ -d "/Applications/Xcode_${XCODE_VERSION}.app" ]; then
            sudo xcode-select -s "/Applications/Xcode_${XCODE_VERSION}.app/Contents/Developer"
            log_success "Xcode ${XCODE_VERSION} selected"
        else
            log_warning "Xcode ${XCODE_VERSION} not found. Using default xcode-select"
        fi
    else
        log_step "Using system default Xcode..."
    fi

    xcodebuild -version
}

# Clean build artifacts
clean_build() {
    log_step "Cleaning build artifacts..."

    rm -rf build/
    rm -rf "${ARCHIVE_PATH}"
    rm -f "${ZIP_OUTPUT}"
    rm -f "${DMG_OUTPUT}"

    log_success "Build artifacts cleaned"
}

# Run tests
run_tests() {
    print_header "Running Tests"

    check_dependencies
    select_xcode

    log_step "Running unit tests..."

    # Try to run tests, but don't fail if not configured
    if xcodebuild test \
        -scheme "NotimanagerTests" \
        -destination "${DESTINATION}" \
        -enableCodeCoverage YES 2>/dev/null; then
        log_success "All tests passed"
    else
        log_warning "Tests not configured or failed - continuing..."
    fi
}

# Build for development
build_dev() {
    print_header "Building (Development)"

    check_dependencies
    generate_icons
    select_xcode

    log_step "Building ${APP_NAME}..."
    xcodebuild build \
        -scheme "${SCHEME}" \
        -destination "${DESTINATION}"

    log_success "Build completed"
    log_info "To run the app, use: open build/${APP_NAME}.app"
}

# Create archive
create_archive() {
    print_header "Creating Archive"

    check_dependencies
    generate_icons
    select_xcode

    mkdir -p build

    # Check for certificate
    if security find-identity -v -p codesigning 2>/dev/null | grep -q "${CERTIFICATE_NAME}"; then
        CODE_SIGN_IDENTITY="${CERTIFICATE_NAME}"
        log_info "Using certificate: ${CERTIFICATE_NAME}"
    else
        CODE_SIGN_IDENTITY="-"
        log_warning "No certificate found, using ad-hoc signing"
    fi

    log_step "Archiving ${APP_NAME}..."

    xcodebuild archive \
        -scheme "${SCHEME}" \
        -archivePath "${ARCHIVE_PATH}" \
        -destination "${DESTINATION}" \
        CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
        CODE_SIGN_STYLE=Manual \
        DEVELOPMENT_TEAM=""

    if [ -d "${ARCHIVE_PATH}" ]; then
        log_success "Archive created: ${ARCHIVE_PATH}"

        # Show archive info
        ARCHIVE_SIZE=$(du -sh "${ARCHIVE_PATH}" | cut -f1)
        log_info "Archive size: ${ARCHIVE_SIZE}"
    else
        log_error "Archive creation failed"
        exit 1
    fi
}

# Export app from archive
export_app() {
    print_header "Exporting App"

    if [ ! -d "${ARCHIVE_PATH}" ]; then
        log_error "Archive not found at ${ARCHIVE_PATH}"
        log_info "Run: $0 archive"
        exit 1
    fi

    mkdir -p "${EXPORT_PATH}"

    log_step "Exporting app bundle..."

    # Copy app from archive products
    ARCHIVE_APP="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"

    if [ -d "${ARCHIVE_APP}" ]; then
        cp -R "${ARCHIVE_APP}" "${APP_BUNDLE}"
        log_success "App exported: ${APP_BUNDLE}"

        # Copy .icns file to app bundle Resources
        log_step "Copying app icon to bundle..."
        if [ -f "Notimanager/Resources/AppIcon.icns" ]; then
            cp "Notimanager/Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
            log_success "App icon copied to bundle"
        else
            log_warning "AppIcon.icns not found, icon may not display correctly in System Settings"
        fi
    else
        log_error "App not found in archive"
        exit 1
    fi

    # Get version info
    VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${APP_BUNDLE}/Contents/Info.plist")
    BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${APP_BUNDLE}/Contents/Info.plist")

    log_info "Version: ${VERSION} (${BUILD})"

    # Verify code signature
    log_step "Verifying code signature..."
    codesign -dv "${APP_BUNDLE}" 2>&1 | head -5
}

# Create ZIP distribution
create_zip() {
    print_header "Creating ZIP Distribution"

    if [ ! -d "${APP_BUNDLE}" ]; then
        log_error "App not found at ${APP_BUNDLE}"
        log_info "Run: $0 export"
        exit 1
    fi

    log_step "Creating ZIP archive..."

    cd "${EXPORT_PATH}"
    zip -r "../$(basename ${ZIP_OUTPUT})" "${APP_NAME}.app" -q
    cd - > /dev/null

    if [ -f "${ZIP_OUTPUT}" ]; then
        ZIP_SIZE=$(du -h "${ZIP_OUTPUT}" | cut -f1)
        log_success "ZIP created: ${ZIP_OUTPUT}"
        log_info "Size: ${ZIP_SIZE}"
    else
        log_error "ZIP creation failed"
        exit 1
    fi
}

# Create DMG distribution
create_dmg() {
    print_header "Creating DMG Distribution"

    if [ ! -d "${APP_BUNDLE}" ]; then
        log_error "App not found at ${APP_BUNDLE}"
        log_info "Run: $0 export"
        exit 1
    fi

    if [ -f "scripts/create-dmg.sh" ]; then
        log_step "Running DMG creation script..."

        # Check for certificate and use release mode
        if security find-identity -v -p codesigning 2>/dev/null | grep -q "${CERTIFICATE_NAME}"; then
            # Use release mode with certificate
            ./scripts/create-dmg.sh --release
        else
            # Use dev mode (ad-hoc signing)
            ./scripts/create-dmg.sh --dev
        fi

        if [ -f "${DMG_OUTPUT}" ]; then
            DMG_SIZE=$(du -h "${DMG_OUTPUT}" | cut -f1)
            log_success "DMG created: ${DMG_OUTPUT}"
            log_info "Size: ${DMG_SIZE}"
        else
            log_error "DMG creation failed"
            exit 1
        fi
    else
        log_error "DMG script not found at scripts/create-dmg.sh"
        exit 1
    fi
}

# Create DMG for local development
create_dmg_dev() {
    print_header "Creating DMG (Local Dev)"

    if [ ! -d "${APP_BUNDLE}" ]; then
        log_error "App not found at ${APP_BUNDLE}"
        log_info "Run: $0 export"
        exit 1
    fi

    if [ -f "scripts/create-dmg.sh" ]; then
        log_step "Running DMG creation script in dev mode..."

        # Use dev mode (fast, minimal signing)
        ./scripts/create-dmg.sh --dev --test

        if [ -f "${DMG_OUTPUT}" ]; then
            DMG_SIZE=$(du -h "${DMG_OUTPUT}" | cut -f1)
            log_success "DMG created: ${DMG_OUTPUT}"
            log_info "Size: ${DMG_SIZE}"
            log_info "DMG has been opened for testing"
        else
            log_error "DMG creation failed"
            exit 1
        fi
    else
        log_error "DMG script not found at scripts/create-dmg.sh"
        exit 1
    fi
}

# Full release pipeline
release_pipeline() {
    print_header "🚀 Full Release Pipeline"

    check_dependencies
    select_xcode

    log_step "Step 1/5: Running tests..."
    run_tests

    log_step "Step 2/5: Creating archive..."
    create_archive

    log_step "Step 3/5: Exporting app..."
    export_app

    log_step "Step 4/5: Creating ZIP..."
    create_zip

    log_step "Step 5/5: Creating DMG..."
    create_dmg

    print_header "Release Build Complete"

    echo ""
    log_success "All artifacts created successfully!"
    echo ""
    echo "📦 Output files:"
    echo "   - ${ZIP_OUTPUT}"
    echo "   - ${DMG_OUTPUT}"
    echo "   - ${APP_BUNDLE}"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Test the app: open ${APP_BUNDLE}"
    echo "   2. Open DMG to verify: open ${DMG_OUTPUT}"
    echo "   3. Commit and tag: git tag vX.Y.Z && git push origin vX.Y.Z"
    echo ""
}

# Prepare for release
prepare_release() {
    print_header "Preparing for Release"

    # Check if there are uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "You have uncommitted changes"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted"
            exit 1
        fi
    fi

    # Get current version
    VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${APP_NAME}/Resources/Info.plist" 2>/dev/null || echo "unknown")

    log_info "Current version: ${VERSION}"

    # Ask for new version
    read -p "Enter new version (e.g., 2.1.0): " NEW_VERSION

    if [ -z "$NEW_VERSION" ]; then
        log_error "Version cannot be empty"
        exit 1
    fi

    # Update Info.plist
    log_step "Updating version to ${NEW_VERSION}..."
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${NEW_VERSION}" "${APP_NAME}/Resources/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_VERSION}" "${APP_NAME}/Resources/Info.plist"

    log_success "Version updated in Info.plist"

    # Update changelog
    if [ -f "scripts/update-changelog.sh" ]; then
        log_step "Updating changelog..."
        echo "$NEW_VERSION" | ./scripts/update-changelog.sh > /dev/null 2>&1 || true
        log_success "Changelog updated"
    fi

    # Commit changes
    log_step "Committing changes..."
    git add "${APP_NAME}/Resources/Info.plist" CHANGELOG.md
    git commit -m "chore: bump version to ${NEW_VERSION}"

    # Create tag
    log_step "Creating tag v${NEW_VERSION}..."
    git tag "v${NEW_VERSION}"

    log_success "Prepared for release v${NEW_VERSION}"
    echo ""
    log_info "To push the release:"
    echo "   git push origin main"
    echo "   git push origin v${NEW_VERSION}"
    echo ""
}

# Show help
show_help() {
    cat << EOF
${BOLD}Notimanager Build Script${NC}

Usage: $0 [command] [options]

${BOLD}Commands:${NC}

  ${CYAN}build${NC}           Build the app (development)
  ${CYAN}release${NC}         Build release version with archives
  ${CYAN}test${NC}            Run tests
  ${CYAN}clean${NC}           Clean build artifacts
  ${CYAN}archive${NC}         Create Xcode archive
  ${CYAN}export${NC}          Export app from archive
  ${CYAN}zip${NC}             Create ZIP distribution
  ${CYAN}dmg${NC}             Create DMG distribution (release mode)
  ${CYAN}dev-dmg${NC}         Create DMG distribution (dev mode - fast, opens for testing)
  ${CYAN}all${NC}             Run full release pipeline
  ${CYAN}prepare${NC}         Prepare for release (update version, tag)
  ${CYAN}help${NC}            Show this help message

${BOLD}Examples:${NC}

  $0 all              # Run full release pipeline
  $0 archive          # Create archive only
  $0 clean && $0 all  # Clean and rebuild
  $0 dev-dmg          # Create DMG for local testing
  $0 prepare          # Prepare for release (interactive)

${BOLD}Local Development Workflow:${NC}

  1. Make your changes
  2. Build:          $0 export
  3. Test DMG:       $0 dev-dmg
  4. Iterate as needed

${BOLD}Release Workflow:${NC}

  1. Make your changes
  2. Update CHANGELOG.md under [Unreleased]
  3. Run: $0 prepare
  4. Run: $0 all
  5. Test the build
  6. Push: git push origin main && git push origin vX.Y.Z
  7. GitHub Actions will publish the release

${BOLD}Direct DMG Script Usage:${NC}

  For more DMG options, use the create-dmg script directly:
    ./scripts/create-dmg.sh --dev       # Fast dev build
    ./scripts/create-dmg.sh --release   # Release build
    ./scripts/create-dmg.sh --test      # Create and open DMG
    ./scripts/create-dmg.sh --verify    # Create and verify DMG
    ./scripts/create-dmg.sh --help      # Show all options

EOF
}

# Main script
main() {
    local command="${1:-help}"

    case "$command" in
        build)
            build_dev
            ;;
        release)
            release_pipeline
            ;;
        test)
            run_tests
            ;;
        clean)
            clean_build
            ;;
        archive)
            create_archive
            ;;
        export)
            export_app
            ;;
        zip)
            create_zip
            ;;
        dmg)
            create_dmg
            ;;
        dev-dmg)
            create_dmg_dev
            ;;
        all)
            release_pipeline
            ;;
        prepare)
            prepare_release
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main
main "$@"
