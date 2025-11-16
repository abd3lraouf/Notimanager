#!/usr/bin/env python3
"""
Generate clean menu bar icons using the Streamline Plump bell icon.
"""

import subprocess
from pathlib import Path

# Simple SVG for menu bar - stroke only, no fill
SVG_MENU_BAR = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 48 48">
  <g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5">
    <path d="M24 10c10.582 0 19.337 7.828 20.789 18.009c.233 1.64-1.128 2.991-2.785 2.991H5.996c-1.657 0-3.019-1.35-2.785-2.991C4.663 17.828 13.417 10 24 10"/>
    <path d="M24 15c5.756 0 10.755 3.242 13.27 8m4.875 14.091c1.21.016 2.51.423 2.77 1.604c.053.239.085.507.085.805s-.032.566-.085.805c-.26 1.181-1.56 1.588-2.77 1.604C39.416 41.944 33.582 42 24 42s-15.416-.056-18.145-.091c-1.21-.016-2.51-.423-2.77-1.604C3.032 40.066 3 39.798 3 39.5s.032-.566.085-.805c.26-1.181 1.56-1.588 2.77-1.604C8.584 37.056 14.418 37 24 37s15.416.056 18.145.091M24 4v6m4-6h-8"/>
  </g>
</svg>'''

def save_svg(content: str, output_path: Path):
    """Save SVG content to file."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(content)

def convert_svg_to_png(svg_path: Path, width: int, height: int, output_path: Path):
    """Convert SVG to PNG using sips."""
    cmd = [
        'sips',
        '-s', 'format', 'png',
        '-z', str(width), str(height),
        str(svg_path.absolute()),
        '--out', str(output_path.absolute())
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Warning: sips failed: {result.stderr}")
    except Exception as e:
        print(f"Error: {e}")

def create_menu_bar_icons():
    """Generate menu bar icons."""
    menu_bar_dir = Path('Notimanager/Resources/MenuBarIcon')

    # Save SVG
    svg_path = menu_bar_dir / 'MenuBarIcon.svg'
    save_svg(SVG_MENU_BAR, svg_path)

    # Generate 1x (16x16)
    png_1x = menu_bar_dir / 'MenuBarIcon.png'
    convert_svg_to_png(svg_path, 16, 16, png_1x)

    # Generate 2x (32x32)
    png_2x = menu_bar_dir / 'MenuBarIcon@2x.png'
    convert_svg_to_png(svg_path, 32, 32, png_2x)

    print(f"✅ Generated menu bar icons:")
    print(f"   {png_1x} (16x16)")
    print(f"   {png_2x} (32x32)")

def create_iconset():
    """Create an iconset for generating icns."""
    iconset_dir = Path('Notimanager/Resources/Notimanager.iconset')

    # Remove old iconset
    if iconset_dir.exists():
        import shutil
        shutil.rmtree(iconset_dir)

    iconset_dir.mkdir(parents=True, exist_ok=True)

    # Icon sizes for macOS app icon
    sizes = [16, 32, 128, 256, 512, 1024]

    for size in sizes:
        # Copy from generated AppIcon
        source = Path('Notimanager/Resources/Assets.xcassets') / f'AppIcon_{size}x{size}.png'

        if source.exists():
            # 1x
            dest_1x = iconset_dir / f'icon_{size}x{size}.png'
            import shutil
            shutil.copy(source, dest_1x)

            # 2x (if not 1024)
            if size < 1024:
                dest_2x = iconset_dir / f'icon_{size*2}x{size*2}.png'
                size_2x = Path('Notimanager/Resources/Assets.xcassets') / f'AppIcon_{size*2}x{size*2}.png'
                if size_2x.exists():
                    shutil.copy(size_2x, dest_2x)

    # Create Contents.json
    contents = '''{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_64x64.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_1024x1024.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}'''

    with open(iconset_dir / 'Contents.json', 'w') as f:
        f.write(contents)

    print(f"✅ Created iconset at: {iconset_dir}")

def generate_icns():
    """Generate icns file from iconset using iconutil."""
    iconset_dir = Path('Notimanager/Resources/Notimanager.iconset')
    icns_output = Path('Notimanager/Resources/icon.icns')

    if iconset_dir.exists():
        cmd = ['iconutil', '-c', 'icns', str(iconset_dir), '-o', str(icns_output)]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ Generated icns: {icns_output}")
            else:
                print(f"Warning: iconutil failed: {result.stderr}")
                print("Tip: You can also let Xcode auto-generate the icns from the iconset")
        except Exception as e:
            print(f"Error: {e}")
            print("Note: Xcode will auto-generate icns from iconset during build")

if __name__ == '__main__':
    print("🎨 Generating clean menu bar icons...\n")

    create_menu_bar_icons()
    create_iconset()
    generate_icns()

    print("\n✅ Menu bar icons regenerated successfully!")
    print("\n📝 Note: Xcode will automatically generate icon.icns from the iconset during build.")
