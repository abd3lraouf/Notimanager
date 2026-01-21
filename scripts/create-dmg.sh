#!/bin/bash

# Notimanager DMG Creation Script
# Uses create-dmg npm package for beautiful DMG creation
# https://github.com/sindresorhus/create-dmg
#
# Usage:
#   ./scripts/create-dmg.sh [options]
#
# Options:
#   --dev, -d           Enable local dev mode (no signing, faster build)
#   --release, -r       Enable release mode (with code signing if available)
#   --no-sign           Force skip code signing
#   --identity CERT     Manually set code signing identity
#   --overwrite         Overwrite existing DMG
#   --test              Open DMG after creation for testing
#   --output DIR        Custom output directory
#   --help, -h          Show this help message

set -e

# ============================================================================
# Configuration
# ============================================================================

APP_NAME="Notimanager"
APP_FILE="Notimanager.app"
SOURCE_APP="build/release/${APP_FILE}"
BUILD_DIR="build"
DEFAULT_OUTPUT_DIR="${BUILD_DIR}"

# Default mode
DEV_MODE=false
RELEASE_MODE=false
FORCE_NO_SIGN=false
IDENTITY=""
OVERWRITE=false
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
  ${GREEN}--dev, -d${NC}          Enable local dev mode (fast, no DMG signing)
  ${GREEN}--release, -r${NC}      Enable release mode (with code signing)
  ${GREEN}--no-sign${NC}          Force skip code signing
  ${GREEN}--identity CERT${NC}    Manually set code signing identity
  ${GREEN}--overwrite${NC}        Overwrite existing DMG
  ${GREEN}--test${NC}             Open DMG after creation for testing
  ${GREEN}--output DIR${NC}       Custom output directory
  ${GREEN}--help, -h${NC}         Show this help message

${BOLD}Examples:${NC}
  $0 --dev              # Create DMG in dev mode (fast)
  $0 --release          # Create DMG in release mode
  $0 --dev --test       # Create and test DMG
  $0 --overwrite        # Overwrite existing DMG

${BOLD}Local Development Workflow:${NC}
  1. Build the app:     ./scripts/build.sh export
  2. Create DMG:        ./scripts/create-dmg.sh --dev
  3. Test DMG:          ./scripts/create-dmg.sh --dev --test

${BOLD}Release Workflow:${NC}
  1. Build the app:     ./scripts/build.sh export
  2. Create DMG:        ./scripts/create-dmg.sh --release

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
            --identity)
                IDENTITY="$2"
                shift 2
                ;;
            --overwrite)
                OVERWRITE=true
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

    # Check for create-dmg (npm version)
    if ! command -v create-dmg &> /dev/null; then
        log_warning "create-dmg (npm) not found"
        missing_deps=true
    fi

    # Check for PlistBuddy
    if ! command -v /usr/libexec/PlistBuddy &> /dev/null; then
        log_warning "PlistBuddy not found"
        missing_deps=true
    fi

    if [ "$missing_deps" = true ]; then
        log_error "Missing required dependencies"
        echo ""
        echo "Please install missing dependencies:"
        echo "  npm install --global create-dmg"
        exit 1
    fi

    # Get create-dmg version
    local dmg_version
    dmg_version=$(create-dmg --version 2>/dev/null || echo "unknown")
    log_success "Using create-dmg: ${dmg_version}"
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

# Determine code signing approach
setup_code_signing() {
    log_step "Setting up code signing..."

    # Dev mode: skip DMG code signing
    if [ "$DEV_MODE" = true ]; then
        log_info "Dev mode: Skipping DMG code signing"
        CODE_SIGN_DMG=false
        return
    fi

    # Force no sign
    if [ "$FORCE_NO_SIGN" = true ]; then
        log_info "Skipping DMG code signing (forced)"
        CODE_SIGN_DMG=false
        return
    fi

    # Use specified identity
    if [ -n "$IDENTITY" ]; then
        log_info "Using specified identity for DMG: ${IDENTITY}"
        CODE_SIGN_DMG=true
        return
    fi

    # Auto-detect certificate - priority order
    local cert_id=""
    local cert_name=""

    # 1) Developer ID Application (best for distribution)
    if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
        cert_id=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | awk '{print $2}')
        cert_name="Developer ID Application"
    # 2) Apple Development (for development)
    elif security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Development"; then
        cert_id=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development" | head -1 | awk '{print $2}')
        cert_name="Apple Development"
    # 3) Notimanager self-signed
    elif security find-identity -v -p codesigning 2>/dev/null | grep -qi "notimanager"; then
        cert_id=$(security find-identity -v -p codesigning 2>/dev/null | grep -i "notimanager" | head -1 | awk '{print $2}')
        cert_name="Notimanager self-signed"
    fi

    if [ -n "$cert_id" ]; then
        IDENTITY="$cert_id"
        CODE_SIGN_DMG=true
        log_success "Found certificate for DMG: ${cert_name} (${cert_id})"
    else
        log_warning "No code signing certificate found"
        log_info "DMG will not be code signed"
        CODE_SIGN_DMG=false
    fi
}

# Sign the application
sign_app() {
    log_step "Signing application..."

    local sign_identity="-"

    if [ -n "$IDENTITY" ]; then
        sign_identity="$IDENTITY"
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

# Create DMG using npm create-dmg
create_dmg() {
    log_step "Creating DMG..."

    local output_dir="${CUSTOM_OUTPUT:-${DEFAULT_OUTPUT_DIR}}"

    # Ensure output directory exists
    mkdir -p "$output_dir"

    # Build create-dmg command
    local create_dmg_cmd=("create-dmg")

    # Add overwrite flag
    if [ "$OVERWRITE" = true ]; then
        create_dmg_cmd+=("--overwrite")
    fi

    # Add code signing identity
    if [ "$CODE_SIGN_DMG" = true ] && [ -n "$IDENTITY" ]; then
        create_dmg_cmd+=("--identity=${IDENTITY}")
        log_info "DMG will be codesigned with: ${IDENTITY}"
    fi

    # Skip code signing if needed
    if [ "$CODE_SIGN_DMG" = false ]; then
        create_dmg_cmd+=("--no-code-sign")
        log_info "DMG code signing disabled"
    fi

    # Add app and output directory
    create_dmg_cmd+=("${SOURCE_APP}")
    create_dmg_cmd+=("${output_dir}")

    log_info "Running create-dmg..."
    log_info "Source: ${SOURCE_APP}"
    log_info "Output: ${output_dir}"

    # Execute create-dmg
    if "${create_dmg_cmd[@]}" 2>&1; then
        # Find the created DMG (create-dmg adds version to filename)
        local dmg_name="${APP_NAME} ${VERSION}.dmg"
        local dmg_path="${output_dir}/${dmg_name}"

        # Also check for the alternative naming without version
        if [ ! -f "$dmg_path" ]; then
            # Try to find any DMG in the output directory
            dmg_path=$(find "${output_dir}" -name "${APP_NAME}*.dmg" -maxdepth 1 | head -1)
        fi

        if [ -z "$dmg_path" ] || [ ! -f "$dmg_path" ]; then
            log_error "Could not find created DMG"
            exit 1
        fi

        DMG_PATH="${dmg_path}"
        DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)

        log_success "DMG created: ${DMG_PATH}"
        log_info "Size: ${DMG_SIZE}"

        # Return DMG path for further processing
        echo "$DMG_PATH"
    else
        log_error "DMG creation failed"
        exit 1
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

    if [ "$CODE_SIGN_DMG" = true ]; then
        echo ""
        echo "🔐 Code signing: Enabled (${IDENTITY})"
    else
        echo ""
        echo "🔓 Code signing: Disabled"
    fi

    echo ""
    echo "🔧 Commands:"
    echo "   Open DMG:     open ${dmg_path}"
    echo "   Mount:        hdiutil attach ${dmg_path}"
    echo "   Verify:       hdiutil imageinfo ${dmg_path}"

    if [ "$DEV_MODE" = false ] && [ "$CODE_SIGN_DMG" = true ]; then
        echo ""
        echo "📋 For distribution:"
        echo "   1. Notarize the DMG"
        echo "   2. Test the DMG installation"
        echo "   3. Upload to GitHub Releases"
        echo "   4. Update documentation"
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
    setup_code_signing
    echo ""

    # Sign app
    sign_app
    echo ""

    # Create DMG
    dmg_path=$(create_dmg)
    echo ""

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
