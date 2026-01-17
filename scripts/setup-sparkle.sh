#!/bin/bash

################################################################################
# Sparkle Auto-Update Setup Script
################################################################################
# This script automates the complete setup of Sparkle for Notimanager, including:
# - Downloading Sparkle tools
# - Generating EdDSA signing keys
# - Configuring Info.plist with the public key
# - Exporting and encoding the private key for GitHub Actions
# - Creating GitHub Pages deployment workflow
# - Providing instructions for GitHub repository secrets
#
# Usage: ./scripts/setup-sparkle.sh
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

################################################################################
# Colors for output
################################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

################################################################################
# Script directories
################################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/tools"

################################################################################
# Helper functions
################################################################################

print_header() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_step() {
    echo -e "\n${BLUE}▶ $1${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_box() {
    local title="$1"
    local content="$2"
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│ ${title}${NC}"
    echo -e "${YELLOW}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${YELLOW}│${NC} $content"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────┘${NC}\n"
}

################################################################################
# Verification functions
################################################################################

verify_prerequisites() {
    print_step "Verifying Prerequisites"

    local all_good=true

    # Check Xcode
    if command -v xcodebuild &> /dev/null; then
        local xcode_version=$(xcodebuild -version | head -1)
        print_success "Xcode found: $xcode_version"
    else
        print_error "Xcode not found. Please install Xcode from the App Store."
        all_good=false
    fi

    # Check Git
    if command -v git &> /dev/null; then
        local git_version=$(git --version)
        print_success "Git found: $git_version"
    else
        print_error "Git not found. Please install Git."
        all_good=false
    fi

    # Check wget or curl
    if command -v wget &> /dev/null; then
        print_success "wget found"
    elif command -v curl &> /dev/null; then
        print_success "curl found"
    else
        print_error "Neither wget nor curl found. Please install one of them."
        all_good=false
    fi

    if [ "$all_good" = false ]; then
        print_error "Missing prerequisites. Please install required tools and run again."
        exit 1
    fi

    print_success "All prerequisites verified!"
}

verify_project_structure() {
    print_step "Verifying Project Structure"

    local required_files=(
        "Notimanager/Resources/Info.plist"
        "Notimanager/Managers/UpdateManager.swift"
        "Notimanager/Managers/MenuBarManager.swift"
        "Notimanager.xcodeproj/project.pbxproj"
    )

    local all_good=true
    for file in "${required_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            print_success "Found: $file"
        else
            print_error "Missing: $file"
            all_good=false
        fi
    done

    if [ "$all_good" = false ]; then
        print_error "Project structure verification failed."
        exit 1
    fi

    print_success "Project structure verified!"
}

################################################################################
# Sparkle tools installation
################################################################################

get_latest_sparkle_version() {
    # Fetch latest version without using print_info to avoid mixing with command substitution
    local latest_url
    latest_url=$(curl -s "https://api.github.com/repos/sparkle-project/Sparkle/releases" 2>/dev/null | \
                grep -E '"tag_name":\s*"2\.[0-9]+\.[0-9]+"' | \
                head -1 | \
                grep -oE '2\.[0-9]+\.[0-9]+' | \
                head -1)

    if [ -z "$latest_url" ]; then
        echo "2.7.0"
        return 1
    fi

    echo "$latest_url"
}

download_sparkle_tools() {
    print_step "Downloading Sparkle Tools"

    # Get latest version
    print_info "Fetching latest Sparkle 2.x version from GitHub..."
    local sparkle_version
    sparkle_version=$(get_latest_sparkle_version)

    if [ $? -ne 0 ]; then
        print_warning "Could not fetch latest version, using fallback"
    fi

    print_success "Latest Sparkle 2.x version: $sparkle_version"

    mkdir -p "$TOOLS_DIR"
    cd "$TOOLS_DIR"

    local sparkle_archive="Sparkle-${sparkle_version}.tar.xz"
    local sparkle_url="https://github.com/sparkle-project/Sparkle/releases/download/${sparkle_version}/${sparkle_archive}"

    if [ -d "Sparkle" ]; then
        print_warning "Sparkle directory already exists. Removing..."
        rm -rf Sparkle
    fi

    # Clean up any existing files from previous extraction
    rm -f bin/generate_keys bin/generate_appcast bin/sign_update 2>/dev/null

    print_info "Downloading Sparkle ${sparkle_version} from:"
    print_info "  $sparkle_url"
    if command -v wget &> /dev/null; then
        wget -q --show-progress "$sparkle_url" -O "$sparkle_archive"
    else
        curl -L -o "$sparkle_archive" --progress-bar "$sparkle_url"
    fi

    print_info "Extracting archive to Sparkle subdirectory..."
    mkdir -p Sparkle
    tar xf "$sparkle_archive" -C Sparkle

    # Clean up archive
    rm -f "$sparkle_archive"

    # Verify tools exist in Sparkle/bin/
    local tools=("generate_keys" "generate_appcast" "sign_update")
    local tools_found=true
    for tool in "${tools[@]}"; do
        if [ -f "Sparkle/bin/$tool" ]; then
            chmod +x "Sparkle/bin/$tool"
            print_success "Found tool: $tool"
        else
            print_error "Missing tool: $tool"
            tools_found=false
        fi
    done

    if [ "$tools_found" = false ]; then
        print_error "Required tools not found after extraction"
        print_info "Contents of tools directory:"
        ls -la "$TOOLS_DIR"
        exit 1
    fi

    # Save version info for reference
    echo "$sparkle_version" > .sparkle-version

    print_success "Sparkle tools downloaded and extracted!"
}

################################################################################
# Key generation
################################################################################

generate_eddsa_keys() {
    print_step "Generating EdDSA Key Pair"

    cd "$TOOLS_DIR"

    print_info "Running generate_keys..."
    print_warning "This will store the private key in your macOS Keychain."

    # Run generate_keys and capture output
    local output
    output=$("./Sparkle/bin/generate_keys" 2>&1)

    # Display the output
    echo "$output"

    # Extract public key from output
    PUBLIC_KEY=$(echo "$output" | grep -A1 '<string>' | grep -oE '[A-Za-z0-9+/=]{40,50}' || echo "")

    if [ -z "$PUBLIC_KEY" ]; then
        print_error "Failed to extract public key from output."
        print_info "Please run: ./Sparkle/bin/generate_keys"
        print_info "Then manually copy the public key from the output."
        exit 1
    fi

    print_box "PUBLIC KEY GENERATED" "Your EdDSA public key is: $PUBLIC_KEY"

    # Verify key in keychain
    print_info "Verifying key in Keychain..."
    if security find-generic-password -s "Sparkle dev.abd3lraouf.notimanager" &> /dev/null 2>&1; then
        print_success "Private key stored in macOS Keychain!"
    else
        print_warning "Could not verify key in Keychain, but generation may have succeeded."
    fi
}

export_private_key() {
    print_step "Exporting Private Key for GitHub Actions"

    cd "$TOOLS_DIR"

    # Export private key to PEM file
    print_info "Exporting private key to PEM file..."
    "./Sparkle/bin/generate_keys" -x private-key.pem > /dev/null 2>&1

    if [ ! -f "private-key.pem" ]; then
        print_error "Failed to export private key."
        exit 1
    fi

    print_success "Private key exported to: $TOOLS_DIR/private-key.pem"

    # Base64 encode the private key
    print_info "Base64 encoding private key..."
    if base64 -i private-key.pem > private-key-base64.txt 2>/dev/null; then
        :
    elif base64 private-key.pem > private-key-base64.txt 2>/dev/null; then
        :
    else
        print_error "Failed to base64 encode private key."
        exit 1
    fi

    BASE64_KEY=$(cat private-key-base64.txt)
    print_success "Private key base64 encoded!"

    # Securely delete the unencrypted key
    shred -u private-key.pem 2>/dev/null || rm private-key.pem

    print_success "Unencrypted private key securely deleted!"
}

################################################################################
# Update Info.plist
################################################################################

update_info_plist() {
    print_step "Updating Info.plist with Public Key"

    local info_plist="$PROJECT_ROOT/Notimanager/Resources/Info.plist"

    # Check if SUPublicEDKey exists
    if /usr/libexec/PlistBuddy -c "Print :SUPublicEDKey" "$info_plist" &> /dev/null; then
        print_info "Updating existing SUPublicEDKey..."
        /usr/libexec/PlistBuddy -c "Set :SUPublicEDKey $PUBLIC_KEY" "$info_plist"
    else
        print_info "Adding SUPublicEDKey..."
        /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $PUBLIC_KEY" "$info_plist"
    fi

    print_success "Info.plist updated with public key!"

    # Verify the update
    local stored_key
    stored_key=$(/usr/libexec/PlistBuddy -c "Print :SUPublicEDKey" "$info_plist")
    if [ "$stored_key" = "$PUBLIC_KEY" ]; then
        print_success "Public key verified in Info.plist!"
    else
        print_error "Public key mismatch in Info.plist!"
        exit 1
    fi
}

################################################################################
# Create GitHub Pages workflow
################################################################################

create_github_pages_workflow() {
    print_step "Creating GitHub Pages Deployment Workflow"

    local workflow_dir="$PROJECT_ROOT/.github/workflows"
    local workflow_file="$workflow_dir/deploy-pages.yml"

    mkdir -p "$workflow_dir"

    if [ -f "$workflow_file" ]; then
        print_warning "Workflow file already exists: $workflow_file"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping workflow creation."
            return
        fi
    fi

    cat > "$workflow_file" << 'EOF'
name: Deploy to GitHub Pages

on:
  workflow_dispatch:  # Allow manual trigger
  release:
    types: [published]  # Run when release is published

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: macos-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download appcast from release
        uses: robinraju/release-downloader@v1.8
        with:
          repository: abd3lraouf/Notimanager
          tag: v${{ github.event.release.tag_name }}
          fileName: appcast.xml
          out-file-path: ./appcast.xml

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF

    print_success "GitHub Pages workflow created: $workflow_file"
}

################################################################################
# Create secure files directory
################################################################################

create_secure_storage() {
    print_step "Creating Secure Key Storage"

    local secure_dir="$HOME/.notimanager-secrets"
    mkdir -p "$secure_dir"

    # Copy base64 key to secure location
    cp "$TOOLS_DIR/private-key-base64.txt" "$secure_dir/sparkle-private-key-b64.txt"

    # Set restrictive permissions
    chmod 700 "$secure_dir"
    chmod 600 "$secure_dir/sparkle-private-key-b64.txt"

    print_success "Secure storage created: $secure_dir"
    print_info "Base64-encoded key saved to: $secure_dir/sparkle-private-key-b64.txt"

    # Also save a README with instructions
    cat > "$secure_dir/README.txt" << EOF
Notimanager Sparkle Keys
========================

This directory contains sensitive signing keys for Sparkle auto-updates.

Files:
- spark-private-key-b64.txt: Base64-encoded EdDSA private key for GitHub Actions

IMPORTANT:
- Never commit these files to git
- Never share these keys with anyone
- Keep backups in a secure location

To add the key to GitHub Secrets:
1. Copy the contents of spark-private-key-b64.txt
2. Go to: https://github.com/abd3lraouf/Notimanager/settings/secrets/actions
3. Click "New repository secret"
4. Name: SPARKLE_PRIVATE_KEY
5. Paste the base64 key as the value
6. Click "Add secret"

Generated: $(date)
EOF

    print_success "README created in secure storage"
}

################################################################################
# Print final instructions
################################################################################

copy_secret_to_clipboard() {
    local secret_file="$HOME/.notimanager-secrets/sparkle-private-key-b64.txt"

    if [ -f "$secret_file" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            pbcopy < "$secret_file"
            print_success "Secret copied to clipboard!"
        elif command -v wl-copy &> /dev/null; then
            # Wayland
            wl-copy < "$secret_file"
            print_success "Secret copied to clipboard!"
        elif command -v xclip &> /dev/null; then
            # X11
            xclip -selection clipboard < "$secret_file"
            print_success "Secret copied to clipboard!"
        elif command -v xsel &> /dev/null; then
            # X11 alternative
            xsel --clipboard --input < "$secret_file"
            print_success "Secret copied to clipboard!"
        else
            print_warning "Could not copy to clipboard automatically"
            print_info "Secret file location: $secret_file"
            return 1
        fi
        return 0
    else
        print_error "Secret file not found: $secret_file"
        return 1
    fi
}

set_github_secret() {
    local secret_file="$HOME/.notimanager-secrets/sparkle-private-key-b64.txt"

    if [ ! -f "$secret_file" ]; then
        print_error "Secret file not found: $secret_file"
        return 1
    fi

    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI (gh) not found"
        print_info "Install it from: https://cli.github.com/"
        return 1
    fi

    # Check if user is authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI not authenticated"
        print_info "Run: gh auth login"
        return 1
    fi

    print_info "Setting SPARKLE_PRIVATE_KEY secret via GitHub CLI..."

    # Read the secret value
    local secret_value
    secret_value=$(cat "$secret_file")

    # Set the secret using gh CLI
    if echo "$secret_value" | gh secret set SPARKLE_PRIVATE_KEY; then
        print_success "GitHub secret SPARKLE_PRIVATE_KEY set successfully!"
        return 0
    else
        print_error "Failed to set GitHub secret"
        print_info "You may need admin permissions on the repository"
        return 1
    fi
}

print_final_instructions() {
    print_header "SETUP COMPLETE!"

    cat << 'EOF'

The Sparkle setup is almost complete! Follow these remaining steps:

1. ADD GITHUB SECRET
   ──────────────────────────────────────────────────────────────────
   Your base64-encoded private key is stored at:

      ~/.notimanager-secrets/sparkle-private-key-b64.txt

   You have two options to add it to GitHub:

   OPTION A - Automatic (using GitHub CLI):
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   The script can set the secret for you automatically if:
   • GitHub CLI (gh) is installed
   • You're authenticated with: gh auth login
   • You have admin permissions on the repository

   OPTION B - Manual:
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   a) Copy the secret to clipboard
   b) Go to: https://github.com/abd3lraouf/Notimanager/settings/secrets/actions
   c) Click "New repository secret"
   d) Name: SPARKLE_PRIVATE_KEY
   e) Paste the secret as the value
   f) Click "Add secret"

2. ENABLE GITHUB PAGES
   ──────────────────────────────────────────────────────────────────
   a) Go to: https://github.com/abd3lraouf/Notimanager/settings/pages
   b) Under "Source", select: GitHub Actions
   c) Click "Save"

   Your appcast will be hosted at:
   https://abd3lraouf.github.io/Notimanager/appcast.xml

3. CREATE YOUR FIRST SIGNED RELEASE
   ──────────────────────────────────────────────────────────────────
   a) Update version in Info.plist:
      /usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1.4.0" \
         Notimanager/Resources/Info.plist

   b) Commit changes:
      git add Notimanager/Resources/Info.plist
      git commit -m "chore: prepare v1.4.0 with Sparkle support"
      git push origin main

   c) Create and push tag:
      git tag -a v1.4.0 -m "Release v1.4.0"
      git push origin v1.4.0

   d) Monitor the workflow at:
      https://github.com/abd3lraouf/Notimanager/actions

4. TEST UPDATES
   ──────────────────────────────────────────────────────────────────
   a) Build and run the app
   b) Click "Check for Updates..." from the menu bar
   c) Verify the update check works

EOF

    print_box "FILES CREATED/MODIFIED" "
    ✅ Info.plist updated with public key
    ✅ GitHub Pages workflow created
    ✅ Private key exported and stored securely
    ✅ Sparkle tools downloaded to: $TOOLS_DIR/Sparkle
    "

    print_box "SECURITY REMINDERS" "
    ⚠️  Never commit the private key to git
    ⚠️  The unencrypted private key has been deleted
    ⚠️  Keep backups of ~/.notimanager-secrets/ in a safe place
    "

    print_info "For detailed documentation, see: docs/SPARKLE_SETUP.md"
    print_info "For issues, open a GitHub issue: https://github.com/abd3lraouf/Notimanager/issues"

    # Show installed Sparkle version
    if [ -f "$TOOLS_DIR/.sparkle-version" ]; then
        local installed_version=$(cat "$TOOLS_DIR/.sparkle-version")
        print_info "Sparkle version installed: $installed_version"
    fi

    # Ask if user wants to set GitHub secret now
    echo ""
    print_step "Set GitHub Secret Now?"

    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        print_info "GitHub CLI is available and authenticated!"
        echo ""
        read -p "Would you like to set the SPARKLE_PRIVATE_KEY secret now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if set_github_secret; then
                print_success "Secret set successfully! You can skip step 1 in the instructions above."
            else
                print_warning "Automatic setup failed. Please use manual setup (Option B above)."
            fi
        fi
    else
        print_info "To set the secret automatically via GitHub CLI:"
        echo "  1. Install: https://cli.github.com/"
        echo "  2. Authenticate: gh auth login"
        echo "  3. Run: gh secret set SPARKLE_PRIVATE_KEY < ~/.notimanager-secrets/sparkle-private-key-b64.txt"
    fi

    # Ask if user wants to copy secret to clipboard
    if [ -f "$HOME/.notimanager-secrets/sparkle-private-key-b64.txt" ]; then
        echo ""
        read -p "Would you like to copy the secret to your clipboard? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if copy_secret_to_clipboard; then
                print_success "Secret copied! Ready to paste into GitHub."
            fi
        fi
    fi
}

################################################################################
# Main execution
################################################################################

main() {
    print_header "Notimanager Sparkle Setup Script"

    print_info "This script will:"
    echo "  • Download Sparkle tools"
    echo "  • Generate EdDSA signing keys"
    echo "  • Update Info.plist with public key"
    echo "  • Export private key for GitHub Actions"
    echo "  • Create GitHub Pages deployment workflow"
    echo ""

    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Setup cancelled."
        exit 0
    fi

    # Run setup steps
    verify_prerequisites
    verify_project_structure
    download_sparkle_tools
    generate_eddsa_keys
    export_private_key
    update_info_plist
    create_github_pages_workflow
    create_secure_storage

    # Print final instructions
    print_final_instructions

    print_success "Setup script completed successfully!"
}

# Run main function
main "$@"
