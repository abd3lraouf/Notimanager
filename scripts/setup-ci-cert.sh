#!/bin/bash

# Notimanager CI Self-Signed Certificate Setup
# Generates a self-signed code signing certificate for CI/CD use
#
# Usage:
#   ./scripts/setup-ci-cert.sh
#
# This script:
#   1. Creates a self-signed code signing certificate using native macOS tools
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

# Create the self-signed certificate using native macOS tools
log_step "Generating self-signed code signing certificate..."

# Create a temporary keychain for certificate generation
TEMP_KEYCHAIN="temp-cert.keychain"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$TEMP_KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$TEMP_KEYCHAIN"
security set-keychain-settings "$TEMP_KEYCHAIN"

log_info "Creating certificate and key pair in keychain..."

# Create a self-signed code signing certificate using the 'security' command
# This is the native macOS way and creates properly formatted certificates
# We use the 'req' option to create a certificate signing request and self-sign it

# First, create a private key and certificate in one step using security
# The trick is to create a certificate authority first, then create the code signing cert

# Generate private key
TEMP_KEY_FILE="temp_cert_key.pem"
TEMP_CSR_FILE="temp_cert.csr"
TEMP_CERT_FILE="temp_cert.crt"

openssl genrsa -out "$TEMP_KEY_FILE" 2048 2>/dev/null

# Create a certificate signing request configuration
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

# Generate self-signed certificate
openssl req -new -x509 \
    -key "$TEMP_KEY_FILE" \
    -out "$TEMP_CERT_FILE" \
    -days 3650 \
    -config cert.conf

# Import certificate and key to temporary keychain
log_info "Importing certificate to keychain..."

# Import the certificate first
security import "$TEMP_CERT_FILE" \
    -k "$TEMP_KEYCHAIN" \
    -T /usr/bin/codesign \
    -T /usr/bin/productsign \
    -A

# Import the private key
security import "$TEMP_KEY_FILE" \
    -k "$TEMP_KEYCHAIN" \
    -T /usr/bin/codesign \
    -T /usr/bin/productsign \
    -A

# Set the certificate type to code signing
# This is done by setting the trust settings
security set-trust -r trustAsRoot -p basic -p codeSign -k "$TEMP_KEYCHAIN" \
    -c "$CERT_COMMON_NAME" \
    -t user 2>/dev/null || true

# Export to PKCS12 format for CI use
log_info "Exporting to PKCS12 format..."

# Use security export to create the .p12 file
# This creates a properly formatted .p12 that macOS security can import
security export \
    -k "$TEMP_KEYCHAIN" \
    -f pkcs12 \
    -t cert \
    -c "$CERT_COMMON_NAME" \
    -P "$KEYCHAIN_PASSWORD" \
    -o "$CERT_P12" \
    -p "$KEYCHAIN_PASSWORD" 2>/dev/null || {
    # If security export fails, fall back to openssl with proper flags
    log_warning "security export failed, using OpenSSL fallback..."

    openssl pkcs12 -export \
        -in "$TEMP_CERT_FILE" \
        -inkey "$TEMP_KEY_FILE" \
        -out "$CERT_P12" \
        -passout pass:"$KEYCHAIN_PASSWORD" \
        -certpbe PBE-SHA1-3DES \
        -keypbe PBE-SHA1-3DES \
        -macalg SHA1
    }

# Clean up temporary files
rm -f "$TEMP_KEY_FILE" "$TEMP_CSR_FILE" "$TEMP_CERT_FILE" cert.conf
security delete-keychain "$TEMP_KEYCHAIN" 2>/dev/null || true

log_success "Certificate generated"
log_info "Certificate: $CERT_NAME"
log_info "Common Name: $CERT_COMMON_NAME"
log_info "Organization: $CERT_ORG"
log_info "Valid for: 10 years"

# Verify certificate
log_step "Verifying certificate..."
if [ -f "$CERT_P12" ]; then
    # Verify the PKCS12 file
    if openssl pkcs12 -info -in "$CERT_P12" -nokeys -passin pass:"$KEYCHAIN_PASSWORD" >/dev/null 2>&1; then
        log_success "Certificate file is valid"

        # Verify it can be imported by security command
        TEST_KEYCHAIN="verify-test.keychain"
        if security create-keychain -p "test-pass" "$TEST_KEYCHAIN" 2>/dev/null; then
            if security import "$CERT_P12" -k "$TEST_KEYCHAIN" -P "$KEYCHAIN_PASSWORD" -T /usr/bin/codesign >/dev/null 2>&1; then
                log_success "Certificate is compatible with macOS security import"
            else
                log_warning "Certificate import test failed"
            fi
            security delete-keychain "$TEST_KEYCHAIN" 2>/dev/null || true
        fi
    else
        log_error "Certificate file is invalid"
        exit 1
    fi
else
    log_error "Certificate file not found: $CERT_P12"
    exit 1
fi

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
echo "  ${CYAN}https://github.com/abd3lraouf/Notimanager/settings/secrets/actions${NC}"
echo ""
echo "Required secrets:"
echo "  ${BOLD}CERTIFICATE_P12${NC}       - Base64 encoded .p12 file"
echo "  ${BOLD}CERTIFICATE_PASSWORD${NC}  - Keychain password (use: $KEYCHAIN_PASSWORD)"
echo "  ${BOLD}CERTIFICATE_NAME${NC}      - Certificate name (use: $CERT_COMMON_NAME)"
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
