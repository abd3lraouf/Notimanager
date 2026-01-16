#!/bin/bash

# Notimanager DMG Creation Script
# Uses create-dmg shell script for beautiful DMG creation
# https://github.com/create-dmg/create-dmg
#
# Usage:
#   ./scripts/create-dmg.sh [options]
#
# Options:
#   --dev, -d           Enable local dev mode (no signing, faster build)
#   --release, -r       Enable release mode (with code signing if available)
#   --no-sign           Force skip code signing
#   --sign CERT         Use specific certificate for signing
#   --verify            Verify DMG after creation
#   --test              Open DMG after creation for testing
#   --output FILE       Custom output filename
#   --help, -h          Show this help message

set -e

# ============================================================================
# Configuration
# ============================================================================

APP_NAME="Notimanager"
APP_FILE="Notimanager.app"
SOURCE_APP="build/release/${APP_FILE}"
BUILD_DIR="build"
DMG_TEMP_DIR="build/dmg-temp"
DEFAULT_OUTPUT="${BUILD_DIR}/${APP_NAME}-macOS.dmg"

# DMG appearance settings
VOLNAME="${APP_NAME}"
WINDOW_SIZE="600 400"
WINDOW_POS="400 300"
ICON_SIZE="100"
APP_ICON_POS="150 190"
DROP_LINK_POS="450 190"

# Background image (optional - will use default if not found)
BACKGROUND_IMG=""

# Default mode
DEV_MODE=false
RELEASE_MODE=false
FORCE_NO_SIGN=false
SPECIFIC_CERT=""
VERIFY_DMG=false
TEST_DMG=false
CUSTOM_OUTPUT=""

# ============================================================================
# Colors
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# Functions
# ============================================================================

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

show_help() {
    cat << EOF
${BOLD}Notimanager DMG Creation Script${NC}

${BOLD}Usage:${NC}
  $0 [options]

${BOLD}Options:${NC}
  ${GREEN}--dev, -d${NC}          Enable local dev mode (fast, no signing)
  ${GREEN}--release, -r${NC}      Enable release mode (with code signing)
  ${GREEN}--no-sign${NC}          Force skip code signing
  ${GREEN}--sign CERT${NC}        Use specific certificate for signing
  ${GREEN}--verify${NC}           Verify DMG after creation
  ${GREEN}--test${NC}             Open DMG after creation for testing
  ${GREEN}--output FILE${NC}      Custom output filename
  ${GREEN}--help, -h${NC}         Show this help message

${BOLD}Examples:${NC}
  $0 --dev              # Create DMG in dev mode (fast)
  $0 --release          # Create DMG in release mode
  $0 --dev --test       # Create and test DMG
  $0 --verify           # Create and verify DMG

${BOLD}Local Development Workflow:${NC}
  1. Build the app:     ./scripts/build.sh export
  2. Create DMG:        ./scripts/create-dmg.sh --dev
  3. Test DMG:          ./scripts/create-dmg.sh --dev --test
  4. Verify:            ./scripts/create-dmg.sh --dev --verify

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dev|-d)
                DEV_MODE=true
                shift
                ;;
            --release|-r)
                RELEASE_MODE=true
                shift
                ;;
            --no-sign)
                FORCE_NO_SIGN=true
                shift
                ;;
            --sign)
                SPECIFIC_CERT="$2"
                shift 2
                ;;
            --verify)
                VERIFY_DMG=true
                shift
                ;;
            --test)
                TEST_DMG=true
                shift
                ;;
            --output)
                CUSTOM_OUTPUT="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
}

# Check dependencies
check_dependencies() {
    log_step "Checking dependencies..."

    local missing_deps=false

    # Check for create-dmg
    if ! command -v create-dmg &> /dev/null; then
        log_warning "create-dmg not found"
        missing_deps=true
    fi

    # Check for PlistBuddy
    if ! command -v /usr/libexec/PlistBuddy &> /dev/null; then
        log_warning "PlistBuddy not found"
        missing_deps=true
    fi

    # Check for hdiutil
    if ! command -v hdiutil &> /dev/null; then
        log_warning "hdiutil not found"
        missing_deps=true
    fi

    if [ "$missing_deps" = true ]; then
        log_error "Missing required dependencies"
        echo ""
        echo "Please install missing dependencies:"
        echo "  brew install create-dmg"
        exit 1
    fi

    log_success "All dependencies found"
}

# Check if app exists
check_app_exists() {
    if [ ! -d "$SOURCE_APP" ]; then
        log_error "${APP_FILE} not found at ${SOURCE_APP}"
        echo ""
        echo "Build the app first:"
        if [ "$DEV_MODE" = true ]; then
            echo "  ./scripts/build.sh clean && ./scripts/build.sh export"
        else
            echo "  ./scripts/build.sh export"
        fi
        echo ""
        echo "Or run full build:"
        echo "  ./scripts/build.sh all"
        exit 1
    fi

    log_success "Found ${APP_FILE}"
}

# Get app version info
get_app_info() {
    local info_plist="${SOURCE_APP}/Contents/Info.plist"

    if [ -f "$info_plist" ]; then
        VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$info_plist" 2>/dev/null || echo "unknown")
        BUILD_NUM=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$info_plist" 2>/dev/null || echo "unknown")
    else
        VERSION="unknown"
        BUILD_NUM="unknown"
    fi

    log_info "App Version: ${VERSION} (Build ${BUILD_NUM})"
}

# Check for create-dmg
check_create_dmg() {
    if command -v create-dmg &> /dev/null; then
        CREATE_DMG_VERSION=$(create-dmg --version 2>/dev/null || echo "unknown")
        log_success "Using create-dmg: ${CREATE_DMG_VERSION}"
    else
        log_error "create-dmg not found"
        echo ""
        echo "Please install create-dmg:"
        echo "  brew install create-dmg"
        exit 1
    fi
}

# Determine code signing approach
setup_code_signing() {
    log_step "Setting up code signing..."

    # Dev mode: skip DMG code signing
    if [ "$DEV_MODE" = true ]; then
        log_info "Dev mode: Using ad-hoc signing for app, no DMG signing"
        return
    fi

    # Force no sign
    if [ "$FORCE_NO_SIGN" = true ]; then
        log_info "Skipping DMG code signing (forced)"
        return
    fi

    # Use specific certificate
    if [ -n "$SPECIFIC_CERT" ]; then
        log_info "Will use specified certificate for DMG: ${SPECIFIC_CERT}"
    else
        # Auto-detect certificate
        local cert_id
        cert_id=$(security find-identity -v -p codesigning 2>/dev/null | grep -i "notimanager\|developer id application" | head -1 | awk '{print $2}' || echo "")

        if [ -n "$cert_id" ]; then
            SPECIFIC_CERT="$cert_id"
            log_success "Found certificate for DMG: ${cert_id}"
        else
            log_warning "No certificate found, DMG will not be code signed"
        fi
    fi
}

# Sign the application
sign_app() {
    log_step "Signing application..."

    local sign_identity="-"

    if [ -n "$SPECIFIC_CERT" ]; then
        sign_identity="$SPECIFIC_CERT"
    fi

    # Force re-sign with deep option
    if codesign --force --deep --sign "$sign_identity" "$SOURCE_APP" 2>&1; then
        log_success "Application signed successfully"
    else
        log_warning "Code signing failed, continuing anyway..."
    fi

    # Verify signature
    log_info "Verifying signature..."
    if codesign -dv "$SOURCE_APP" 2>&1 | grep -q "Signature"; then
        log_success "Signature verified"
    else
        log_warning "Signature verification failed (may be ad-hoc)"
    fi
}

# Create DMG
create_dmg() {
    log_step "Creating DMG..."

    local output_file="${CUSTOM_OUTPUT:-${DEFAULT_OUTPUT}}"

    # Remove existing DMG if it exists
    if [ -f "$output_file" ]; then
        log_info "Removing existing DMG..."
        rm -f "$output_file"
    fi

    # Prepare source folder for create-dmg
    local source_folder="${DMG_TEMP_DIR}"
    rm -rf "${source_folder}"
    mkdir -p "${source_folder}"

    # Copy app to source folder
    log_info "Preparing DMG contents..."
    cp -R "$SOURCE_APP" "${source_folder}/"

    # Build create-dmg command
    local create_dmg_cmd=(
        create-dmg
        --volname "${VOLNAME}"
        --window-pos ${WINDOW_POS}
        --window-size ${WINDOW_SIZE}
        --icon-size ${ICON_SIZE}
        --icon "${APP_FILE}" ${APP_ICON_POS}
        --hide-extension "${APP_FILE}"
        --app-drop-link ${DROP_LINK_POS}
    )

    # Add background if available
    if [ -n "$BACKGROUND_IMG" ] && [ -f "$BACKGROUND_IMG" ]; then
        create_dmg_cmd+=(--background "${BACKGROUND_IMG}")
        log_info "Using background image: ${BACKGROUND_IMG}"
    fi

    # Add code signing for the DMG itself (not the app)
    if [ "$DEV_MODE" = false ] && [ "$FORCE_NO_SIGN" = false ] && [ -n "$SPECIFIC_CERT" ]; then
        create_dmg_cmd+=(--codesign "${SPECIFIC_CERT}")
        log_info "DMG will be codesigned with: ${SPECIFIC_CERT}"
    fi

    # Add verbosity option for dev mode
    if [ "$DEV_MODE" = true ]; then
        create_dmg_cmd+=(--hdiutil-verbose)
    fi

    # Output file and source folder
    create_dmg_cmd+=("${output_file}")
    create_dmg_cmd+=("${source_folder}")

    log_info "Running create-dmg..."
    log_info "Output: ${output_file}"

    # Execute create-dmg
    if "${create_dmg_cmd[@]}" 2>&1; then
        # Clean up temp folder
        rm -rf "${source_folder}"

        DMG_PATH="${output_file}"
        DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)

        log_success "DMG created: ${DMG_PATH}"
        log_info "Size: ${DMG_SIZE}"

        # Return DMG path for further processing
        echo "$DMG_PATH"
    else
        # Clean up temp folder
        rm -rf "${source_folder}"
        log_error "DMG creation failed"
        exit 1
    fi
}

# Verify DMG
verify_dmg() {
    local dmg_path="$1"

    log_step "Verifying DMG..."

    # Basic checks
    if [ ! -f "$dmg_path" ]; then
        log_error "DMG not found: ${dmg_path}"
        return 1
    fi

    # Check DMG format
    local format
    format=$(hdiutil imageinfo "$dmg_path" 2>/dev/null | grep "Format:" | head -1 | awk -F': ' '{print $2}')

    if [ -n "$format" ]; then
        log_success "Format: ${format}"
    fi

    # Check checksum
    local checksum
    checksum=$(hdiutil imageinfo "$dmg_path" 2>/dev/null | grep "Checksum type" | head -1)

    if [ -n "$checksum" ]; then
        log_info "Checksum: ${checksum}"
    fi

    # Verify DMG is mountable
    log_info "Testing DMG mount..."
    if hdiutil attach "$dmg_path" -readonly -noverify -quiet 2>/dev/null; then
        log_success "DMG is mountable"

        # Check if app is inside
        local mount_point
        mount_point=$(hdiutil attach "$dmg_path" -readonly -noverify -quiet 2>/dev/null | grep "/Volumes" | awk '{print $3}')

        if [ -d "${mount_point}/${APP_NAME}.app" ]; then
            log_success "App bundle found in DMG"
        else
            log_warning "App bundle not found in DMG"
        fi

        hdiutil detach "$mount_point" -quiet 2>/dev/null || true
    else
        log_warning "Could not mount DMG for verification"
    fi
}

# Test DMG
test_dmg() {
    local dmg_path="$1"

    log_step "Opening DMG for testing..."
    log_info "DMG will open in Finder for manual testing"

    if [ "$DEV_MODE" = true ]; then
        log_warning "Dev mode: DMG uses ad-hoc signing"
        log_info "You may need to right-click and 'Open' the app"
    fi

    open "$dmg_path"
}

# Show summary
show_summary() {
    local dmg_path="$1"

    print_header "DMG Creation Summary"

    echo ""
    log_success "DMG created successfully!"
    echo ""
    echo "📦 Output: ${dmg_path}"
    echo "📊 Size: $(du -h "$dmg_path" | cut -f1)"

    if [ "$DEV_MODE" = true ]; then
        echo ""
        log_warning "Dev mode DMG - Not suitable for distribution"
        echo "   Use --release for production builds"
    fi

    echo ""
    echo "🔧 Commands:"
    echo "   Open DMG:     open ${dmg_path}"
    echo "   Mount:        hdiutil attach ${dmg_path}"
    echo "   Verify:       hdiutil imageinfo ${dmg_path}"

    if [ "$DEV_MODE" = false ] && [ "$FORCE_NO_SIGN" = false ]; then
        echo ""
        echo "📋 For distribution:"
        echo "   1. Test the DMG installation"
        echo "   2. Upload to GitHub Releases"
        echo "   3. Update documentation"
    fi

    echo ""
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    print_header "📦 Notimanager DMG Creation"
    echo ""

    # Parse arguments
    parse_args "$@"

    # Show mode
    if [ "$DEV_MODE" = true ]; then
        log_info "Mode: Local Development"
    elif [ "$RELEASE_MODE" = true ]; then
        log_info "Mode: Release"
    else
        log_info "Mode: Standard"
    fi
    echo ""

    # Run checks
    check_dependencies
    check_app_exists
    get_app_info
    check_create_dmg
    setup_code_signing
    echo ""

    # Sign app
    sign_app
    echo ""

    # Create DMG
    dmg_path=$(create_dmg)
    echo ""

    # Verify if requested
    if [ "$VERIFY_DMG" = true ]; then
        verify_dmg "$dmg_path"
        echo ""
    fi

    # Test if requested
    if [ "$TEST_DMG" = true ]; then
        test_dmg "$dmg_path"
        echo ""
    fi

    # Show summary
    show_summary "$dmg_path"
}

# Run main
main "$@"
