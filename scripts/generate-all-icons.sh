#!/bin/bash

# Notimanager Icon Generation Script
# Generates all menu bar and app icons from SVG source files

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$SCRIPT_DIR/assets"
TEMP_DIR="$SCRIPT_DIR/.icon_temp"

# Asset catalog paths
ASSETS_CATALOG="$PROJECT_DIR/Notimanager/Resources/Assets.xcassets"
MENUBAR_DIR="$ASSETS_CATALOG"
APPICON_DIR="$ASSETS_CATALOG/AppIcon.appiconset"

# Colors
DISABLED_COLOR="#999999"

echo "🎨 Notimanager Icon Generator"
echo "=============================="

# Clean and create temp directory
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Ensure rsvg-convert is available
if ! command -v rsvg-convert &> /dev/null; then
    echo "❌ Error: rsvg-convert not found"
    echo "Install with: brew install librsvg"
    exit 1
fi

echo "✅ Using rsvg-convert"

# Function to create disabled SVG
create_disabled_svg() {
    local input_svg="$1"
    local output_svg="$2"
    # Read the SVG and replace fill color with gray
    sed 's/fill="currentColor"/fill="'$DISABLED_COLOR'"/g' "$input_svg" > "$output_svg"
}

# Function to generate menu bar icon (16x16 and 32x32)
generate_menu_bar_icon() {
    local svg_file="$1"
    local output_name="$2"
    local output_dir="$3"

    echo "  → Generating $output_name"

    rsvg-convert -w 16 -h 16 "$svg_file" -o "$TEMP_DIR/${output_name}.png"
    rsvg-convert -w 32 -h 32 "$svg_file" -o "$TEMP_DIR/${output_name}@2x.png"

    # Copy to destination
    cp "$TEMP_DIR/${output_name}.png" "$output_dir/${output_name}.png"
    cp "$TEMP_DIR/${output_name}@2x.png" "$output_dir/${output_name}@2x.png"
}

# Function to generate app icon sizes
generate_app_icon() {
    local svg_file="$1"
    local output_dir="$2"

    echo "  → Generating app icon sizes"

    # All required app icon sizes for Asset Catalog
    local sizes=(16 32 64 128 256 512 1024)

    for size in "${sizes[@]}"; do
        local filename="AppIcon-Enabled_${size}x${size}.png"
        rsvg-convert -w $size -h $size "$svg_file" -o "$TEMP_DIR/$filename"
        cp "$TEMP_DIR/$filename" "$output_dir/$filename"
        echo "    Generated $filename"
    done
}

# Function to generate .icns file
generate_icns_file() {
    local svg_file="$1"
    local output_path="$2"

    echo "  → Generating .icns file"

    local iconset_dir="$TEMP_DIR/AppIcon.iconset"
    rm -rf "$iconset_dir"
    mkdir -p "$iconset_dir"

    # Generate all required sizes for .icns
    # Format: icon_<size>x<size>.png and icon_<size>x<size>@2x.png
    local sizes=(16 32 128 256 512)

    for size in "${sizes[@]}"; do
        # Regular size
        rsvg-convert -w $size -h $size "$svg_file" -o "$iconset_dir/icon_${size}x${size}.png"
        # Retina size (2x)
        rsvg-convert -w $((size * 2)) -h $((size * 2)) "$svg_file" -o "$iconset_dir/icon_${size}x${size}@2x.png"
        echo "    Generated icon_${size}x${size}.png and @2x variant"
    done

    # Generate .icns from iconset
    iconutil -c icns "$iconset_dir" -o "$output_path"

    if [ $? -eq 0 ]; then
        echo "    ✓ Generated $output_path"
    else
        echo "    ❌ Failed to generate .icns file"
        exit 1
    fi
}

# Function to update Contents.json
update_contents_json() {
    local imageset_dir="$1"
    local base_name="$2"

    cat > "$imageset_dir/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "${base_name}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${base_name}@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "template"
  }
}
EOF
}

# ============================================================================
# CLEANUP OLD ICONS AND IMAGESETS
# ============================================================================
echo ""
echo "🧹 Cleaning up old icons and imagesets..."

# Clean up and recreate AppIcon.appiconset
if [ -d "$APPICON_DIR" ]; then
    echo "  → Cleaning AppIcon.appiconset"
    rm -rf "$APPICON_DIR"
fi
mkdir -p "$APPICON_DIR"
echo "  ✓ Recreated AppIcon.appiconset"

# Clean up and recreate menu bar icon imagesets
MENUBAR_IMAGESETS=(
    "MenuBarIcon.imageset"
    "MenuBarIcon-disabled.imageset"
    "MenuBarIcon-top-left.imageset"
    "MenuBarIcon-top-right.imageset"
    "MenuBarIcon-bottom-left.imageset"
    "MenuBarIcon-bottom-right.imageset"
)

for imageset in "${MENUBAR_IMAGESETS[@]}"; do
    imageset_path="$MENUBAR_DIR/$imageset"
    if [ -d "$imageset_path" ]; then
        echo "  → Cleaning $imageset"
        rm -rf "$imageset_path"
    fi
    mkdir -p "$imageset_path"
    echo "  ✓ Recreated $imageset"
done

echo "✅ Imageset cleanup complete"

# ============================================================================
# MENU BAR ICONS
# ============================================================================
echo ""
echo "📱 Generating Menu Bar Icons..."

# Default icon (use top-right as default)
generate_menu_bar_icon \
    "$ASSETS_DIR/oui-editor-position-top-right.svg" \
    "MenuBarIcon" \
    "$MENUBAR_DIR/MenuBarIcon.imageset"

update_contents_json "$MENUBAR_DIR/MenuBarIcon.imageset" "MenuBarIcon"

# Position-specific icons (only 4 corners)
generate_menu_bar_icon \
    "$ASSETS_DIR/oui-editor-position-top-left.svg" \
    "MenuBarIcon-top-left" \
    "$MENUBAR_DIR/MenuBarIcon-top-left.imageset"

update_contents_json "$MENUBAR_DIR/MenuBarIcon-top-left.imageset" "MenuBarIcon-top-left"

generate_menu_bar_icon \
    "$ASSETS_DIR/oui-editor-position-top-right.svg" \
    "MenuBarIcon-top-right" \
    "$MENUBAR_DIR/MenuBarIcon-top-right.imageset"

update_contents_json "$MENUBAR_DIR/MenuBarIcon-top-right.imageset" "MenuBarIcon-top-right"

generate_menu_bar_icon \
    "$ASSETS_DIR/oui-editor-position-bottom-left.svg" \
    "MenuBarIcon-bottom-left" \
    "$MENUBAR_DIR/MenuBarIcon-bottom-left.imageset"

update_contents_json "$MENUBAR_DIR/MenuBarIcon-bottom-left.imageset" "MenuBarIcon-bottom-left"

generate_menu_bar_icon \
    "$ASSETS_DIR/oui-editor-position-bottom-right.svg" \
    "MenuBarIcon-bottom-right" \
    "$MENUBAR_DIR/MenuBarIcon-bottom-right.imageset"

update_contents_json "$MENUBAR_DIR/MenuBarIcon-bottom-right.imageset" "MenuBarIcon-bottom-right"

# Disabled icon
create_disabled_svg \
    "$ASSETS_DIR/oui-editor-position-top-right.svg" \
    "$TEMP_DIR/disabled-icon.svg"

generate_menu_bar_icon \
    "$TEMP_DIR/disabled-icon.svg" \
    "MenuBarIcon-disabled" \
    "$MENUBAR_DIR/MenuBarIcon-disabled.imageset"

update_contents_json "$MENUBAR_DIR/MenuBarIcon-disabled.imageset" "MenuBarIcon-disabled"

echo "✅ Menu bar icons generated"

# ============================================================================
# APP ICON
# ============================================================================
echo ""
echo "🖥️  Generating App Icon..."

generate_app_icon \
    "$ASSETS_DIR/oui-editor-position-top-right.svg" \
    "$APPICON_DIR"

# Update AppIcon Contents.json
cat > "$APPICON_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "AppIcon-Enabled_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "AppIcon-Enabled_32x32.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "AppIcon-Enabled_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "AppIcon-Enabled_64x64.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "AppIcon-Enabled_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "AppIcon-Enabled_256x256.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "AppIcon-Enabled_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "AppIcon-Enabled_512x512.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "AppIcon-Enabled_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "AppIcon-Enabled_1024x1024.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ App icon Asset Catalog generated"

# ============================================================================
# ICNS FILE
# ============================================================================
echo ""
echo "📦 Generating .icns file for System Settings..."

generate_icns_file \
    "$ASSETS_DIR/oui-editor-position-top-right.svg" \
    "$PROJECT_DIR/Notimanager/Resources/AppIcon.icns"

# Copy to Resources directory
cp "$PROJECT_DIR/Notimanager/Resources/AppIcon.icns" "$PROJECT_DIR/build/AppIcon.icns" 2>/dev/null || true

echo "✅ .icns file generated"

# ============================================================================
# CLEANUP
# ============================================================================
echo ""
echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"

echo ""
echo "✨ All icons generated successfully!"
echo ""
echo "Generated files:"
echo "  • Menu bar icons: 5 variants (default, 4 corners, disabled)"
echo "  • App icon Asset Catalog: 7 sizes (16x16 to 1024x1024)"
echo "  • AppIcon.icns: For System Settings and Finder"
echo ""
echo "Next steps:"
echo "  1. Open the project in Xcode"
echo "  2. Verify the icons appear correctly"
echo "  3. Build and run the app"
echo "  4. Check that the icon appears in System Settings"
