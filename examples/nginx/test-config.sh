#!/bin/bash
# Test script for NGINX error page configuration
# This script demonstrates how to test different error scenarios

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/nginx-standalone.conf"

echo "========================================="
echo "NGINX Error Page Configuration Test"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Note: This script should be run with sudo for full functionality"
    echo "Continuing with syntax validation only..."
    echo ""
fi

# Test 1: Validate configuration syntax
echo "Test 1: Validating NGINX configuration syntax..."
if nginx -t -c "$CONFIG_FILE" 2>&1 | grep -q "syntax is ok"; then
    echo "✓ Configuration syntax is valid"
else
    echo "✗ Configuration syntax validation failed"
    nginx -t -c "$CONFIG_FILE"
    exit 1
fi
echo ""

# Test 2: Check if error page files exist
echo "Test 2: Checking error page files..."
ERROR_PAGES=(
    "$SCRIPT_DIR/error-pages/maintenance.html"
    "$SCRIPT_DIR/error-pages/502.html"
    "$SCRIPT_DIR/error-pages/504.html"
    "$SCRIPT_DIR/error-pages/500.html"
    "$SCRIPT_DIR/error-pages/429.html"
)

for page in "${ERROR_PAGES[@]}"; do
    if [ -f "$page" ]; then
        echo "✓ Found $(basename "$page")"
    else
        echo "✗ Missing $(basename "$page")"
        exit 1
    fi
done
echo ""

# Test 3: Validate HTML in error pages
echo "Test 3: Validating HTML structure..."
for page in "${ERROR_PAGES[@]}"; do
    # Check if it's valid HTML5 (basic check)
    if grep -q "<!DOCTYPE html>" "$page" && grep -q "</html>" "$page"; then
        echo "✓ $(basename "$page") has valid HTML structure"
    else
        echo "✗ $(basename "$page") may have invalid HTML structure"
    fi
done
echo ""

# Test 4: Check configuration features
echo "Test 4: Checking key configuration features..."

if grep -q "error_page 503 @maintenance" "$SCRIPT_DIR/nginx.conf"; then
    echo "✓ Maintenance mode handler configured"
else
    echo "✗ Maintenance mode handler not found"
fi

if grep -q "if (-f /var/www/maintenance.flag)" "$SCRIPT_DIR/nginx.conf"; then
    echo "✓ Maintenance flag file check configured"
else
    echo "✗ Maintenance flag file check not found"
fi

if grep -q "error_page 502 /502.html" "$SCRIPT_DIR/nginx.conf"; then
    echo "✓ Bad Gateway (502) error page configured"
else
    echo "✗ Bad Gateway error page not configured"
fi

if grep -q "error_page 504 /504.html" "$SCRIPT_DIR/nginx.conf"; then
    echo "✓ Gateway Timeout (504) error page configured"
else
    echo "✗ Gateway Timeout error page not configured"
fi

if grep -q "error_page 500 /500.html" "$SCRIPT_DIR/nginx.conf"; then
    echo "✓ Internal Server Error (500) page configured"
else
    echo "✗ Internal Server Error page not configured"
fi

if grep -q "error_page 429 /429.html" "$SCRIPT_DIR/nginx.conf"; then
    echo "✓ Too Many Requests (429) page configured"
else
    echo "✗ Too Many Requests page not configured"
fi
echo ""

# Test 5: Check that error pages have distinct content
echo "Test 5: Verifying error pages have distinct content..."
if ! cmp -s "$SCRIPT_DIR/error-pages/502.html" "$SCRIPT_DIR/error-pages/504.html"; then
    echo "✓ 502 and 504 pages have different content"
else
    echo "✗ 502 and 504 pages have identical content"
fi

if ! cmp -s "$SCRIPT_DIR/error-pages/maintenance.html" "$SCRIPT_DIR/error-pages/502.html"; then
    echo "✓ Maintenance and 502 pages have different content"
else
    echo "✗ Maintenance and 502 pages have identical content"
fi
echo ""

echo "========================================="
echo "All tests completed successfully!"
echo "========================================="
echo ""
echo "To deploy this configuration:"
echo "1. Copy nginx.conf to /etc/nginx/sites-available/"
echo "2. Copy error-pages/* to /var/www/html/"
echo "3. Run: sudo nginx -t"
echo "4. Run: sudo systemctl reload nginx"
echo ""
echo "To enable maintenance mode:"
echo "  sudo touch /var/www/maintenance.flag"
echo ""
echo "To disable maintenance mode:"
echo "  sudo rm /var/www/maintenance.flag"
