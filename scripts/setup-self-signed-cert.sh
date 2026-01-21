#!/bin/bash

# Notimanager Self-Signed Certificate Setup Script
# Creates a local code signing certificate for development and distribution
#
# Usage: ./scripts/setup-self-signed-cert.sh

set -e

# Configuration
CERT_NAME="Notimanager Self-Signed Code Signing"
CERT_COMMON_NAME="Notimanager Code Signing"
CERT_TEAM_ID="NOTIMANAG"
CERT_EXPIRE_DAYS=3650  # 10 years

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

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

# Check if certificate already exists
check_existing_cert() {
    log_step "Checking for existing certificate..."

    if security find-identity -v -p codesigning 2>/dev/null | grep -qi "notimanager"; then
        log_warning "A Notimanager certificate already exists!"
        echo ""
        security find-identity -v -p codesigning 2>/dev/null | grep -i "notimanager" || true
        echo ""
        read -p "Do you want to remove and recreate it? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_step "Removing existing certificate..."
            # Find and remove the certificate
            CERT_HASH=$(security find-identity -v -p codesigning 2>/dev/null | grep -i "notimanager" | head -1 | awk -F'"' '{print $2}' | awk '{print $1}' || true)
            if [ -n "$CERT_HASH" ]; then
                security delete-certificate -Z "$CERT_HASH" 2>/dev/null || true
            fi
            log_success "Certificate removed"
        else
            log_info "Keeping existing certificate"
            return 1
        fi
    fi

    return 0
}

# Create self-signed certificate using Keychain certificate assistant
create_certificate_keychain() {
    print_header "Creating Self-Signed Code Signing Certificate"

    log_step "Creating certificate using Keychain..."

    # Create a temporary conf file for the certificate
    cat > /tmp/cert_conf.txt << EOF
[constraints]
basicConstraints = CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

    # Use the security command to create a self-signed certificate
    # This creates a certificate that can be used for code signing
    security create-keychain -p "temp_password" temp_build.keychain 2>/dev/null || true
    security unlock-keychain -p "temp_password" temp_build.keychain 2>/dev/null || true

    # Create the certificate using security (macOS native way)
    /usr/bin/security -i << 'SCRIPT'
tell application "Security"
    set certName to "Notimanager Self-Signed Code Signing"
    set certEmail to "notimanager@self-signed"
    set certCA to false
    set certCodeSigning to true
end tell
SCRIPT

    # Alternative: Use openssl and then import
    log_info "Creating certificate with OpenSSL..."

    # Generate private key
    openssl genrsa -out /tmp/notimanager_key.pem 2048 2>/dev/null

    # Create certificate signing request
    openssl req -new -key /tmp/notimanager_key.pem -out /tmp/notimanager_csr.pem \
        -subj "/C=US/ST=California/L=San Francisco/O=Notimanager/OU=Development/CN=Notimanager Code Signing/emailAddress=notimanager@self-signed" 2>/dev/null

    # Create self-signed certificate with code signing extensions
    openssl x509 -req -days 3650 -in /tmp/notimanager_csr.pem -signkey /tmp/notimanager_key.pem \
        -out /tmp/notimanager_cert.pem \
        -extfile /dev/stdin << 'EOF'
extendedKeyUsage=codeSigning
keyUsage=digitalSignature
basicConstraints=CA:FALSE
EOF

    # Convert to PKCS12
    openssl pkcs12 -export -in /tmp/notimanager_cert.pem -inkey /tmp/notimanager_key.pem \
        -out /tmp/notimanager_cert.p12 -name "Notimanager Self-Signed Code Signing" \
        -passin pass: -passout pass:notimanager 2>/dev/null

    log_success "Certificate generated"

    # Import into login keychain
    log_step "Importing certificate into Keychain..."

    security import /tmp/notimanager_cert.p12 \
        -k ~/Library/Keychains/login.keychain-db \
        -P notimanager \
        -T /usr/bin/codesign \
        -T /usr/bin/security \
        -T /usr/bin/xcodebuild

    # Set trust settings to allow code signing
    log_step "Setting trust settings..."
    security set-trust -r trustAsRoot -p basic -p codesigning -p default \
        ~/Library/Keychains/login.keychain-db 2>/dev/null || true

    # Alternative method to set trust
    ACL_FILE="/tmp/cert_acl.txt"
    security authorizationdb read com.apple.trust-settings.default > "$ACL_FILE" 2>/dev/null || true

    # Clean up temp files
    rm -f /tmp/notimanager_key.pem /tmp/notimanager_csr.pem /tmp/notimanager_cert.pem /tmp/notimanager_cert.p12 /tmp/cert_conf.txt "$ACL_FILE"

    log_success "Certificate imported into Keychain"
}

# Verify certificate installation
verify_certificate() {
    log_step "Verifying certificate installation..."

    # List all code signing identities
    ALL_IDENTITIES=$(security find-identity -v -p codesigning 2>/dev/null)

    if echo "$ALL_IDENTITIES" | grep -qi "notimanager"; then
        log_success "Certificate is installed and ready!"
        echo ""
        echo "$ALL_IDENTITIES" | grep -i "notimanager" || true
        return 0
    else
        log_warning "Certificate not found in code signing identities"
        echo ""
        log_info "All code signing identities:"
        security find-identity -v -p codesigning 2>/dev/null
        return 1
    fi
}

# Show certificate info
show_cert_info() {
    print_header "Certificate Information"

    log_info "Certificate Name: ${CERT_NAME}"
    log_info "Common Name: ${CERT_COMMON_NAME}"
    log_info "Valid For: ${CERT_EXPIRE_DAYS} days (~$((CERT_EXPIRE_DAYS / 365)) years)"
    echo ""

    # Try to show certificate details
    if security find-certificate -c "Notimanager" -p > /dev/null 2>&1; then
        log_step "Certificate found in Keychain"

        # Show fingerprint
        FINGERPRINT=$(security find-certificate -c "Notimanager" -p | openssl x509 -fingerprint -noout 2>/dev/null)
        if [ -n "$FINGERPRINT" ]; then
            echo "   $FINGERPRINT"
        fi
    fi
}

# Show next steps
show_next_steps() {
    print_header "Next Steps"

    echo ""
    log_success "Self-signed certificate setup complete!"
    echo ""

    cat << EOF
${BOLD}For Local Development:${NC}

  The certificate will be used automatically by the build scripts.
  Just run your normal build commands:

    ./scripts/build.sh export
    ./scripts/build.sh dev-dmg
    ./scripts/build.sh all

${BOLD}For CI/CD:${NC}

  The certificate needs to be exported and added to GitHub Secrets.

  ${YELLOW}1. Export the certificate:${NC}
    security find-certificate -c "Notimanager" -p > ~/Desktop/notimanager_cert.pem

  ${YELLOW}2. Export private key and create PKCS12:${NC}
    # First, find the key in your keychain and export:
    security export -p12 -t identities -o ~/Desktop/notimanager_cert.p12

  ${YELLOW}3. Encode for GitHub:${NC}
    base64 -i ~/Desktop/notimanager_cert.p12 | pbcopy

  ${YELLOW}4. Add to GitHub Secrets:${NC}
    - Go to: Repository Settings → Secrets and variables → Actions
    - Add: CERTIFICATE_P12 (paste the base64 encoded content)
    - Add: CERTIFICATE_PASSWORD (the export password you set)

${BOLD}Alternative - Using Apple Developer Certificate:${NC}

  If you have an Apple Developer account, you can also use your
  "Apple Development" certificate. The build scripts will auto-detect
  any valid certificate.

${BOLD}Certificate Expiry:${NC}

  This certificate expires in ${CERT_EXPIRE_DAYS} days.
  Make a note to renew it before then!

EOF
}

# Main script
main() {
    print_header "🔐 Notimanager Self-Signed Certificate Setup"
    echo ""

    # Check if we should proceed
    if ! check_existing_cert; then
        verify_certificate
        show_cert_info
        echo ""
        log_info "No changes made. Exiting."
        exit 0
    fi

    # Create the certificate
    create_certificate_keychain
    echo ""

    # Verify installation
    if verify_certificate; then
        echo ""
        show_cert_info
        echo ""
        show_next_steps
    else
        log_warning "Certificate may not be properly set up for code signing"
        echo ""
        log_info "You can still use ad-hoc signing for development"
        log_info "Or use your Apple Development certificate if available"
        exit 1
    fi
}

# Run main
main
