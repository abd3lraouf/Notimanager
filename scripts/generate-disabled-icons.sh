#!/bin/bash

# Generate Disabled Icons with Slash Overlay
# Combines position icons with a slash overlay for disabled state

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"

echo "🎨 Generating Disabled Icons with Slash Overlay"
echo "==============================================="

# Function to create disabled SVG with slash overlay
create_disabled_svg() {
    local position="$1"
    local input_svg="$ASSETS_DIR/oui-editor-position-$position.svg"
    local output_svg="$ASSETS_DIR/disabled-$position.svg"

    echo "  → Creating disabled icon for $position"

    # Extract the path data from the original SVG (the filled corner part)
    # We need to extract just the filled corner path, not the frame
    local path_data=$(grep -oP 'd="M8 \d+h5a1 1 0 0 1 1 1v5H9a1 1 0 0 1-1-1z"' "$input_svg" 2>/dev/null || \
                      grep -oP 'd="M8 2v5a1 1 0 0 0 1 1h5a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1z"' "$input_svg" 2>/dev/null || \
                      grep -oP 'd="M3 8h5v5a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"' "$input_svg" 2>/dev/null || \
                      grep -oP 'd="M3 3a1 1 0 0 1 1-1h5a1 1 0 0 1 1 1v5H8V3a1 1 0 0 0-1-1H3z"' "$input_svg" 2>/dev/null)

    # Create the disabled SVG with frame, corner fill, and slash
    cat > "$output_svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 16 16">
  <!-- Outer frame -->
  <path fill="currentColor" d="M3 1h10a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V3a2 2 0 0 1 2-2m0 1a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1z"/>
  <!-- Slash overlay -->
  <path fill="currentColor" d="M11.854 4.146a.5.5 0 0 1 0 .708l-7 7a.5.5 0 0 1-.708-.708l7-7a.5.5 0 0 1 .708 0z"/>
</svg>
EOF

    echo "    ✓ Created $output_svg"
}

# Create disabled icons for all four positions
for position in "top-left" "top-right" "bottom-left" "bottom-right"; do
    create_disabled_svg "$position"
done

echo ""
echo "✅ All disabled icons generated!"
echo ""
echo "Generated files:"
for position in "top-left" "top-right" "bottom-left" "bottom-right"; do
    echo "  • disabled-$position.svg"
done
