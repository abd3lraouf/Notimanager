#!/bin/bash

# Notimanager CI Self-Signed Certificate Setup
# Generates a self-signed code signing certificate for CI/CD use
#
# Usage:
#   ./scripts/setup-ci-cert.sh
#
# This script:
#   1. Creates a self-signed code signing certificate
#   2. Exports it as .p12 for CI use
#   3. Displays instructions for adding to GitHub Secrets

set -e

# ============================================================================
# Configuration
# ============================================================================

CERT_NAME="Notimanager CI Code Signing"
CERT_COMMON_NAME="Notimanager CI"
CERT_ORG="Notimanager"
CERT_UID="notimanager-ci"
CERT_EMAIL="ci@notimanager.com"

CERT_P12="Notimanager-CI.p12"
KEYCHAIN_PASSWORD="ci-keychain-password"

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

# ============================================================================
# Main Script
# ============================================================================

print_header "🔐 Notimanager CI Certificate Setup"
echo ""

# Check if certificate already exists
log_step "Checking for existing certificate..."

CERT_IN_KEYCHAIN=false
CERT_FILE_EXISTS=false

# Check if .p12 file exists
if [ -f "$CERT_P12" ]; then
    CERT_FILE_EXISTS=true
fi

# Check if certificate is in keychain
if security find-certificate -c "$CERT_NAME" /Library/Keychains/System.keychain 2>/dev/null || \
   security find-certificate -c "$CERT_NAME" ~/Library/Keychains/login.keychain-db 2>/dev/null; then
    CERT_IN_KEYCHAIN=true
fi

# Warn user if certificate already exists
if [ "$CERT_FILE_EXISTS" = true ] || [ "$CERT_IN_KEYCHAIN" = true ]; then
    log_warning "Certificate already exists!"
    echo ""

    if [ "$CERT_FILE_EXISTS" = true ]; then
        echo "  📁 File: $CERT_P12"
    fi
    if [ "$CERT_IN_KEYCHAIN" = true ]; then
        echo "  🔐 Keychain: $CERT_NAME"
    fi

    echo ""
    echo -e "${RED}${BOLD}⚠️  WARNING: Regenerating the certificate will:${NC}"
    echo ""
    echo "  • Invalidate ALL existing releases signed with the old certificate"
    echo "  • Require users to re-install the app (right-click → Open won't work on old versions)"
    echo "  • Break auto-updates from older versions"
    echo ""
    echo "You should ONLY regenerate if:"
    echo "  • This is a new setup"
    echo "  • The old certificate was compromised"
    echo "  • You're okay with breaking existing installations"
    echo ""
    echo -e "${YELLOW}If you want to keep using the existing certificate, press Ctrl+C to cancel.${NC}"
    echo ""

    read -p "Do you want to regenerate the certificate anyway? (type 'yes' to confirm): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Cancelled. Keeping existing certificate."
        echo ""
        echo "To use the existing certificate:"
        echo "  1. Make sure GitHub secrets are set:"
        echo "     gh secret list"
        echo "  2. If not, add them:"
        echo -e "     ${GREEN}gh secret set CERTIFICATE_P12 < <(base64 -i $CERT_P12)${NC}"
        echo -e "     ${GREEN}gh secret set CERTIFICATE_PASSWORD -b \"$KEYCHAIN_PASSWORD\"${NC}"
        echo -e "     ${GREEN}gh secret set CERTIFICATE_NAME -b \"$CERT_COMMON_NAME\"${NC}"
        exit 0
    fi

    # Remove existing certificate
    if [ "$CERT_IN_KEYCHAIN" = true ]; then
        log_info "Removing existing certificate from keychain..."
        security delete-certificate -c "$CERT_NAME" 2>/dev/null || true
        log_success "Existing certificate removed from keychain"
    fi

    # Backup old .p12 file
    if [ "$CERT_FILE_EXISTS" = true ]; then
        BACKUP_NAME="${CERT_P12}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up old certificate to: $BACKUP_NAME"
        cp "$CERT_P12" "$BACKUP_NAME"
        log_success "Backup created"
    fi

    CERT_NAME_EXISTS=false
else
    CERT_NAME_EXISTS=false
fi

# Create the self-signed certificate
if [ "$CERT_NAME_EXISTS" = false ]; then
    log_step "Generating self-signed code signing certificate..."

    # Create a temporary keychain for certificate generation
    TEMP_KEYCHAIN="temp-cert.keychain"
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$TEMP_KEYCHAIN" 2>/dev/null || true
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$TEMP_KEYCHAIN" 2>/dev/null || true
    security set-keychain-settings "$TEMP_KEYCHAIN" 2>/dev/null || true

    # Use the security command to create a code signing certificate
    # This creates a self-signed certificate directly in the keychain
    security create-keypair -a \
        -k "$TEMP_KEYCHAIN" \
        -p "$KEYCHAIN_PASSWORD" \
        -t rsa \
        -s 2048 \
        -C "$CERT_EMAIL" \
        -n "$CERT_COMMON_NAME" \
        -A 2>/dev/null || true

    # Alternative approach: Use openssl to create certificate
    log_info "Creating certificate with OpenSSL..."

    # Generate private key
    openssl genrsa -out private.key 2048 2>/dev/null

    # Create certificate signing request configuration
    cat > cert.conf << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = usr_cert
prompt = no

[req_distinguished_name]
O = $CERT_ORG
CN = $CERT_COMMON_NAME
emailAddress = $CERT_EMAIL

[usr_cert]
basicConstraints=CA:FALSE
nsComment = "Notimanager CI Code Signing Certificate"
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF

    # Generate self-signed certificate (valid for 10 years)
    openssl req -new -x509 \
        -key private.key \
        -out certificate.crt \
        -days 3650 \
        -config cert.conf

    # Create PKCS12 file with no encryption on private key
    openssl pkcs12 -export \
        -out "$CERT_P12" \
        -inkey private.key \
        -in certificate.crt \
        -passout pass:"$KEYCHAIN_PASSWORD"

    # Verify the PKCS12 file was created correctly
    if ! openssl pkcs12 -info -in "$CERT_P12" -nokeys -passin pass:"$KEYCHAIN_PASSWORD" >/dev/null 2>&1; then
        log_error "Failed to create valid PKCS12 file"
        rm -f private.key certificate.crt cert.conf
        exit 1
    fi

    # Import certificate to temporary keychain for verification
    # Note: -f pkcs12 specifies the format
    security import "$CERT_P12" \
        -f pkcs12 \
        -k "$TEMP_KEYCHAIN" \
        -P "$KEYCHAIN_PASSWORD" \
        -T /usr/bin/codesign \
        -T /usr/bin/productsign \
        -T /usr/bin/security

    # Set keychain ACL
    security set-key-partition-list \
        -S apple-tool:,apple:,codesign:,productsign: \
        -s \
        -k "$KEYCHAIN_PASSWORD" \
        "$TEMP_KEYCHAIN" 2>&1 | head -1

    log_success "Certificate generated"
    log_info "Certificate: $CERT_NAME"
    log_info "Common Name: $CERT_COMMON_NAME"
    log_info "Organization: $CERT_ORG"
    log_info "Valid for: 10 years"

    # Clean up temporary keychain
    security delete-keychain "$TEMP_KEYCHAIN" 2>/dev/null || true
fi

# Verify certificate
log_step "Verifying certificate..."
if [ -f "$CERT_P12" ]; then
    # Verify the PKCS12 file
    if openssl pkcs12 -info -in "$CERT_P12" -nokeys -passin pass:"$KEYCHAIN_PASSWORD" >/dev/null 2>&1; then
        log_success "Certificate file is valid"

        # Show certificate details
        echo ""
        echo "Certificate Details:"
        openssl pkcs12 -info -in "$CERT_P12" -nokeys -passin pass:"$KEYCHAIN_PASSWORD" 2>/dev/null | grep -E "(subject=|issuer=)" || true
    else
        log_error "Certificate file is invalid"
        exit 1
    fi
else
    log_error "Certificate file not found: $CERT_P12"
    exit 1
fi

# Clean up temporary files
log_step "Cleaning up temporary files..."
rm -f private.key certificate.crt cert.conf
log_success "Cleanup complete"

# Display instructions
print_header "📋 Next Steps"
echo ""

log_success "Certificate created successfully!"
echo ""
echo "Generated file:"
echo "  📁 $CERT_P12"
echo ""
echo "Base64 encode the certificate for GitHub Secrets:"
echo ""
echo -e "${YELLOW}base64 -i $CERT_P12 | pbcopy${NC}"
echo ""
echo "Then add these secrets to your GitHub repository:"
echo ""
echo -e "  ${CYAN}https://github.com/abd3lraouf/Notimanager/settings/secrets/actions${NC}"
echo ""
echo "Required secrets:"
echo -e "  ${BOLD}CERTIFICATE_P12${NC}       - Base64 encoded .p12 file"
echo -e "  ${BOLD}CERTIFICATE_PASSWORD${NC}  - Keychain password (use: $KEYCHAIN_PASSWORD)"
echo -e "  ${BOLD}CERTIFICATE_NAME${NC}      - Certificate name (use: $CERT_COMMON_NAME)"
echo ""
echo "Example commands to add secrets:"
echo ""
echo -e "${GREEN}gh secret set CERTIFICATE_P12 < <(base64 -i $CERT_P12)${NC}"
echo -e "${GREEN}gh secret set CERTIFICATE_PASSWORD -b \"$KEYCHAIN_PASSWORD\"${NC}"
echo -e "${GREEN}gh secret set CERTIFICATE_NAME -b \"$CERT_COMMON_NAME\"${NC}"
echo ""
echo "Or use the GitHub web UI to add these secrets."
echo ""

# Offer to add secrets automatically
if command -v gh >/dev/null 2>&1; then
    read -p "Do you want to add these secrets to GitHub now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Adding secrets to GitHub..."

        if gh secret set CERTIFICATE_P12 < <(base64 -i "$CERT_P12") 2>/dev/null; then
            log_success "CERTIFICATE_P12 added"
        else
            log_warning "Failed to add CERTIFICATE_P12 (you may not have permissions)"
        fi

        if gh secret set CERTIFICATE_PASSWORD -b "$KEYCHAIN_PASSWORD" 2>/dev/null; then
            log_success "CERTIFICATE_PASSWORD added"
        else
            log_warning "Failed to add CERTIFICATE_PASSWORD"
        fi

        if gh secret set CERTIFICATE_NAME -b "$CERT_COMMON_NAME" 2>/dev/null; then
            log_success "CERTIFICATE_NAME added"
        else
            log_warning "Failed to add CERTIFICATE_NAME"
        fi

        echo ""
        log_success "Secrets added to GitHub!"
        echo "You can verify at: https://github.com/abd3lraouf/Notimanager/settings/secrets/actions"
    fi
fi

echo ""
log_info "You can now trigger a release by pushing a version tag:"
echo "  git tag v2.1.15"
echo "  git push origin v2.1.15"
echo ""
