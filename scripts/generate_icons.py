#!/usr/bin/env python3
"""
Generate Notimanager app icons using Streamline Plump bell icons.
Creates properly colored and filled variants for different app states.
"""

import subprocess
from pathlib import Path

# Color palette - macOS system colors
COLORS = {
    'default': {
        'stroke': '#0A84FF',      # Blue - default active state
        'fill': '#0A84FF',        # Blue fill
        'fill_opacity': '0.15',   # Subtle fill
    },
    'enabled': {
        'stroke': '#32D74B',      # Green - enabled
        'fill': '#32D74B',        # Green fill
        'fill_opacity': '0.15',
    },
    'disabled': {
        'stroke': '#8E8E93',      # Gray - disabled
        'fill': '#8E8E93',        # Gray fill
        'fill_opacity': '0.10',
    },
    'notification': {
        'stroke': '#0A84FF',      # Blue bell
        'fill': '#0A84FF',
        'fill_opacity': '0.15',
        'dot_fill': '#FF3B30',    # Red notification dot
    }
}

# SVG template for outline bell (stroke-based)
SVG_OUTLINE = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 48 48">
  <defs>
    <linearGradient id="bellGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{stroke};stop-opacity:1" />
      <stop offset="100%" style="stop-color:{stroke};stop-opacity:0.8" />
    </linearGradient>
  </defs>
  <g fill="none" stroke="url(#bellGradient)" stroke-linecap="round" stroke-linejoin="round" stroke-width="3">
    <path d="M24 10c10.582 0 19.337 7.828 20.789 18.009c.233 1.64-1.128 2.991-2.785 2.991H5.996c-1.657 0-3.019-1.35-2.785-2.991C4.663 17.828 13.417 10 24 10"/>
    <path d="M24 15c5.756 0 10.755 3.242 13.27 8m4.875 14.091c1.21.016 2.51.423 2.77 1.604c.053.239.085.507.085.805s-.032.566-.085.805c-.26 1.181-1.56 1.588-2.77 1.604C39.416 41.944 33.582 42 24 42s-15.416-.056-18.145-.091c-1.21-.016-2.51-.423-2.77-1.604C3.032 40.066 3 39.798 3 39.5s.032-.566.085-.805c.26-1.181 1.56-1.588 2.77-1.604C8.584 37.056 14.418 37 24 37s15.416.056 18.145.091M24 4v6m4-6h-8"/>
  </g>
  {notification_dot}
</svg>'''

# SVG template for filled bell (notification state)
SVG_FILLED = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 48 48">
  <defs>
    <linearGradient id="bellFill" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{stroke};stop-opacity:{fill_opacity}" />
      <stop offset="100%" style="stop-color:{stroke};stop-opacity:{fill_opacity}" />
    </linearGradient>
  </defs>
  <g fill="none" stroke="{stroke}" stroke-linecap="round" stroke-linejoin="round" stroke-width="3">
    <path d="M24 10c10.582 0 19.337 7.828 20.789 18.009c.233 1.64-1.128 2.991-2.785 2.991H5.996c-1.657 0-3.019-1.35-2.785-2.991C4.663 17.828 13.417 10 24 10" fill="url(#bellFill)"/>
    <path d="M24 15c5.756 0 10.755 3.242 13.27 8m4.875 14.091c1.21.016 2.51.423 2.77 1.604c.053.239.085.507.085.805s-.032.566-.085.805c-.26 1.181-1.56 1.588-2.77 1.604C39.416 41.944 33.582 42 24 42s-15.416-.056-18.145-.091c-1.21-.016-2.51-.423-2.77-1.604C3.032 40.066 3 39.798 3 39.5s.032-.566.085-.805c.26-1.181 1.56-1.588 2.77-1.604C8.584 37.056 14.418 37 24 37s15.416.056 18.145.091M24 4v6m4-6h-8" fill="url(#bellFill)"/>
  </g>
  {notification_dot}
</svg>'''

# SVG template for filled bell with inner details (alternative)
SVG_FILLED_ALT = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 48 48">
  <defs>
    <linearGradient id="bellGradientAlt" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{stroke};stop-opacity:0.2" />
      <stop offset="100%" style="stop-color:{stroke};stop-opacity:0.1" />
    </linearGradient>
  </defs>
  <path fill="{stroke}" fill-rule="evenodd" d="M26 8.75h2a2 2 0 1 0 0-4h-8a2 2 0 0 0 0 4h2v1.084c-10.761.91-19.44 9.119-20.952 19.64c-.44 3.053 2.118 5.276 4.788 5.276h4.356a3.1 3.1 0 0 1-.986 1.393c-.797.636-1.94.918-3.325 1.032c-1.883.155-3.561 1.427-3.945 3.344a2.28 2.28 0 0 0 2.235 2.731H43.83a2.28 2.28 0 0 0 2.235-2.731c-.384-1.917-2.062-3.19-3.945-3.344c-1.384-.114-2.528-.396-3.325-1.032a3.1 3.1 0 0 1-.986-1.393h4.348c2.67 0 5.227-2.223 4.788-5.276C45.43 18.956 36.758 10.75 26 9.834z" fill-opacity="0.15"/>
  <g fill="none" stroke="{stroke}" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5">
    <path d="M24 10c10.582 0 19.337 7.828 20.789 18.009c.233 1.64-1.128 2.991-2.785 2.991H5.996c-1.657 0-3.019-1.35-2.785-2.991C4.663 17.828 13.417 10 24 10"/>
    <path d="M24 15c5.756 0 10.755 3.242 13.27 8m4.875 14.091c1.21.016 2.51.423 2.77 1.604c.053.239.085.507.085.805s-.032.566-.085.805c-.26 1.181-1.56 1.588-2.77 1.604C39.416 41.944 33.582 42 24 42s-15.416-.056-18.145-.091c-1.21-.016-2.51-.423-2.77-1.604C3.032 40.066 3 39.798 3 39.5s.032-.566.085-.805c.26-1.181 1.56-1.588 2.77-1.604C8.584 37.056 14.418 37 24 37s15.416.056 18.145.091M24 4v6m4-6h-8"/>
  </g>
  {notification_dot}
</svg>'''

# Notification dot SVG
NOTIFICATION_DOT = '''<circle cx="42" cy="12" r="5" fill="{dot_fill}" stroke="white" stroke-width="2"/>'''

# Simple filled bell for menu bar
SVG_MENU_BAR = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 48 48">
  <g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="3">
    <path d="M24 10c10.582 0 19.337 7.828 20.789 18.009c.233 1.64-1.128 2.991-2.785 2.991H5.996c-1.657 0-3.019-1.35-2.785-2.991C4.663 17.828 13.417 10 24 10"/>
    <path d="M24 15c5.756 0 10.755 3.242 13.27 8m4.875 14.091c1.21.016 2.51.423 2.77 1.604c.053.239.085.507.085.805s-.032.566-.085.805c-.26 1.181-1.56 1.588-2.77 1.604C39.416 41.944 33.582 42 24 42s-15.416-.056-18.145-.091c-1.21-.016-2.51-.423-2.77-1.604C3.032 40.066 3 39.798 3 39.5s.032-.566.085-.805c.26-1.181 1.56-1.588 2.77-1.604C8.584 37.056 14.418 37 24 37s15.416.056 18.145.091M24 4v6m4-6h-8"/>
  </g>
</svg>'''

ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024]

def create_svg(state: str, has_notification: bool = False) -> str:
    """Create SVG content for a specific state."""
    colors = COLORS[state]

    # Use filled variant for better visual
    svg_template = SVG_FILLED

    # Add notification dot if needed
    if has_notification:
        dot_element = NOTIFICATION_DOT.format(dot_fill=colors['dot_fill'])
    else:
        dot_element = ''

    svg_content = svg_template.format(
        stroke=colors['stroke'],
        fill=colors['fill'],
        fill_opacity=colors['fill_opacity'],
        notification_dot=dot_element
    )

    return svg_content

def create_menu_bar_svg() -> str:
    """Create menu bar icon SVG (template style)."""
    return SVG_MENU_BAR

def save_svg(content: str, output_path: Path):
    """Save SVG content to file."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(content)

def convert_svg_to_png(svg_path: Path, size: int, output_path: Path):
    """Convert SVG to PNG using sips."""
    cmd = [
        'sips',
        '-s', 'format', 'png',
        '-z', str(size), str(size),
        str(svg_path.absolute()),
        '--out', str(output_path.absolute())
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Warning: sips failed for {svg_path}: {result.stderr}")
    except Exception as e:
        print(f"Error converting {svg_path}: {e}")

def generate_app_icons():
    """Generate all app icon variants."""
    base_dir = Path('Notimanager/Resources/Assets.xcassets')

    variants = [
        ('default', False, 'AppIcon'),
        ('enabled', False, 'AppIcon-Enabled'),
        ('disabled', False, 'AppIcon-Disabled'),
        ('notification', True, 'AppIcon-Notification'),
    ]

    for state, has_notification, name in variants:
        print(f"Generating {name}...")

        svg_content = create_svg(state, has_notification)
        svg_path = base_dir / f'{name}.svg'
        save_svg(svg_content, svg_path)

        for size in ICON_SIZES:
            png_path = base_dir / f'{name}_{size}x{size}.png'
            convert_svg_to_png(svg_path, size, png_path)

    print("\n✅ App icons generated!")

def generate_menu_bar_icons():
    """Generate menu bar icons."""
    menu_bar_dir = Path('Notimanager/Resources/MenuBarIcon')
    menu_bar_dir.mkdir(parents=True, exist_ok=True)

    svg_content = create_menu_bar_svg()
    svg_path = menu_bar_dir / 'MenuBarIcon.svg'
    save_svg(svg_content, svg_path)

    for scale in [1, 2]:
        size = 16 * scale
        png_path = menu_bar_dir / f'MenuBarIcon@{scale}x.png'
        convert_svg_to_png(svg_path, size, png_path)

    print("✅ Menu bar icons generated!")

def create_appiconset():
    """Create AppIcon.appiconset structure."""
    appicon_dir = Path('Notimanager/Resources/Assets.xcassets/AppIcon.appiconset')

    # Remove old files
    if appicon_dir.exists():
        import shutil
        shutil.rmtree(appicon_dir)

    appicon_dir.mkdir(parents=True, exist_ok=True)

    contents = '''{
  "images" : [
    {"filename" : "AppIcon_16x16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16"},
    {"filename" : "AppIcon_32x32.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16"},
    {"filename" : "AppIcon_32x32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32"},
    {"filename" : "AppIcon_64x64.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32"},
    {"filename" : "AppIcon_128x128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128"},
    {"filename" : "AppIcon_256x256.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128"},
    {"filename" : "AppIcon_256x256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256"},
    {"filename" : "AppIcon_512x512.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256"},
    {"filename" : "AppIcon_512x512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512"},
    {"filename" : "AppIcon_1024x1024.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512"}
  ],
  "info" : {"author" : "xcode", "version" : 1}
}'''

    with open(appicon_dir / 'Contents.json', 'w') as f:
        f.write(contents)

    print("✅ AppIcon.appiconset created!")

def copy_default_icons():
    """Copy default icons to AppIcon.appiconset."""
    appicon_dir = Path('Notimanager/Resources/Assets.xcassets/AppIcon.appiconset')
    base_dir = Path('Notimanager/Resources/Assets.xcassets')

    for size in ICON_SIZES:
        src = base_dir / f'AppIcon_{size}x{size}.png'
        dst = appicon_dir / f'AppIcon_{size}x{size}.png'
        if src.exists():
            import shutil
            shutil.copy(src, dst)

    print("✅ Default icons copied to AppIcon.appiconset!")

if __name__ == '__main__':
    print("🎨 Generating Notimanager icons with Streamline Plump design...\n")

    create_appiconset()
    generate_app_icons()
    copy_default_icons()
    generate_menu_bar_icons()

    print("\n🎉 All icons generated successfully!")
    print("\n📁 Icons generated using Streamline Plump bell icons")
    print("   License: CC BY 4.0 - https://creativecommons.org/licenses/by/4.0/")
    print("\n✅ Next: Build the app to see icons in action")
