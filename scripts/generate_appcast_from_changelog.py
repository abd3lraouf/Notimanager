#!/usr/bin/env python3
"""
Generate Sparkle appcast.xml entries from CHANGELOG.md.

This script extracts release notes for a specific version from CHANGELOG.md
and appends it as a new <item> to an existing appcast.xml file.
This preserves historical signatures and version entries.
"""

import argparse
import os
import sys
import re
import datetime
import xml.etree.ElementTree as ET
from html import escape

# Sparkle namespace
SPARKLE_NS = {'sparkle': 'http://www.andymatuschak.org/xml-namespaces/sparkle'}
ET.register_namespace('sparkle', SPARKLE_NS['sparkle'])


def get_release_notes(changelog_path, version):
    """Extracts markdown notes for a version and converts to styled HTML.

    Args:
        changelog_path: Path to CHANGELOG.md
        version: Version string (e.g., "2.1.5")

    Returns:
        HTML string with styled release notes
    """
    try:
        with open(changelog_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Extract content for this version
        # Match: ## [X.Y.Z] - DATE
        pattern = rf'^## \[{re.escape(version)}\] - \d{{4}}-\d{{2}}-\d{{2}}'
        match = re.search(pattern, content, re.MULTILINE)

        if not match:
            print(f"⚠️  No entry found for version {version} in CHANGELOG.md")
            return "<p>No release notes available.</p>"

        # Find the end (next version header or EOF)
        start_pos = match.end()
        next_match = re.search(r'^## \[', content[start_pos:], re.MULTILINE)

        if next_match:
            end_pos = start_pos + next_match.start()
        else:
            end_pos = len(content)

        markdown_content = content[start_pos:end_pos].strip()

        # Convert markdown to HTML
        html = markdown_to_html(markdown_content)

        # Wrap with styled HTML document
        styled_html = f'''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif;
      padding: 16px;
      margin: 0;
      line-height: 1.5;
      color: #333;
      font-size: 13px;
    }}
    h3 {{
      font-size: 16px;
      font-weight: 600;
      margin-top: 20px;
      margin-bottom: 8px;
      color: #1d1d1f;
    }}
    h4 {{
      font-size: 13px;
      font-weight: 600;
      margin-top: 12px;
      margin-bottom: 6px;
      color: #6e6e73;
    }}
    ul {{
      margin: 0 0 12px 0;
      padding-left: 18px;
    }}
    li {{
      margin-bottom: 4px;
      font-size: 13px;
      color: #1d1d1f;
    }}
    code {{
      font-family: "SF Mono", Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
      font-size: 12px;
      background: #f5f5f7;
      padding: 2px 5px;
      border-radius: 3px;
    }}
    strong {{
      font-weight: 600;
    }}
  </style>
</head>
<body>
{html}
</body>
</html>'''

        return styled_html

    except Exception as e:
        print(f"❌ Error reading changelog: {e}")
        return "<p>No release notes available.</p>"


def markdown_to_html(markdown_content):
    """Convert markdown changelog content to HTML.

    Args:
        markdown_content: Markdown text

    Returns:
        HTML string
    """
    html_lines = []

    for line in markdown_content.split('\n'):
        # Subheaders: ### Category -> <h4>Category</h4>
        if line.startswith('### '):
            text = line[4:].strip()
            html_lines.append(f'<h4>{escape(text)}</h4>')

        # List items
        elif re.match(r'^\s*-\s+', line) or re.match(r'^\s*\*\s+', line):
            item_text = re.sub(r'^\s*[-*]\s+', '', line).strip()
            # Bold text
            item_text = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', item_text)
            # Inline code
            item_text = re.sub(r'`(.*?)`', r'<code>\1</code>', item_text)
            html_lines.append(f'<li>{item_text}</li>')

        # Empty line
        elif not line.strip():
            html_lines.append('')

    # Wrap list items in <ul>
    result = []
    in_list = False

    for line in html_lines:
        if line.startswith('<li>'):
            if not in_list:
                result.append('<ul>')
                in_list = True
            result.append(line)
        elif line:
            if in_list:
                result.append('</ul>')
                in_list = False
            result.append(line)
        else:
            result.append('')

    if in_list:
        result.append('</ul>')

    return '\n'.join(result)


def extract_version_date(changelog_path, version):
    """Extract the release date for a version from CHANGELOG.md.

    Args:
        changelog_path: Path to CHANGELOG.md
        version: Version string

    Returns:
        Date string in YYYY-MM-DD format or today's date
    """
    try:
        with open(changelog_path, 'r', encoding='utf-8') as f:
            content = f.read()

        pattern = rf'^## \[{re.escape(version)}\] - (\d{{4}}-\d{{2}}-\d{{2}})'
        match = re.search(pattern, content, re.MULTILINE)

        if match:
            return match.group(1)

        # Fallback to today if not found
        return datetime.datetime.now().strftime('%Y-%m-%d')

    except Exception as e:
        print(f"⚠️  Could not extract date for {version}: {e}")
        return datetime.datetime.now().strftime('%Y-%m-%d')


def update_appcast(appcast_path, version, url, signature, length, changelog_path):
    """Append a new version entry to an existing appcast.xml.

    Args:
        appcast_path: Path to existing appcast.xml (will be created if needed)
        version: Version string
        url: Download URL for the DMG
        signature: EdDSA signature
        length: File size in bytes
        changelog_path: Path to CHANGELOG.md
    """
    # Parse existing appcast or create new structure
    if os.path.exists(appcast_path) and os.path.getsize(appcast_path) > 0:
        try:
            tree = ET.parse(appcast_path)
            root = tree.getroot()
        except ET.ParseError as e:
            print(f"⚠️  Could not parse existing appcast: {e}")
            print("Creating new appcast structure...")
            root = ET.Element("rss", {
                "xmlns:sparkle": SPARKLE_NS['sparkle'],
                "version": "2.0"
            })
            ET.SubElement(root, "channel")
            tree = ET.ElementTree(root)
    else:
        print("📝 Creating new appcast.xml")
        root = ET.Element("rss", {
            "xmlns:sparkle": SPARKLE_NS['sparkle'],
            "version": "2.0"
        })
        ET.SubElement(root, "channel")
        tree = ET.ElementTree(root)

    # Get or create channel
    channel = root.find("channel")
    if channel is None:
        channel = ET.SubElement(root, "channel")

    # Add title if missing
    if channel.find("title") is None:
        title = ET.SubElement(channel, "title")
        title.text = "Notimanager"

    # Create new item
    item = ET.Element("item")

    # Title
    ET.SubElement(item, "title").text = version

    # Publication date
    date_str = extract_version_date(changelog_path, version)
    try:
        dt = datetime.datetime.strptime(date_str, '%Y-%m-%d')
        pub_date = dt.strftime('%a, %d %b %Y %H:%M:%S +0000')
    except:
        pub_date = datetime.datetime.now().strftime('%a, %d %b %Y %H:%M:%S +0000')

    ET.SubElement(item, "pubDate").text = pub_date

    # Sparkle version info
    ET.SubElement(item, "sparkle:version").text = version
    ET.SubElement(item, "sparkle:shortVersionString").text = version
    ET.SubElement(item, "sparkle:minimumSystemVersion").text = "14.0"

    # Description (HTML release notes)
    desc = ET.SubElement(item, "description")
    desc_html = get_release_notes(changelog_path, version)
    # Use CDATA for HTML content
    desc.text = desc_html  # ElementTree will handle escaping appropriately

    # Enclosure
    enclosure = ET.SubElement(item, "enclosure")
    enclosure.set("url", url)
    enclosure.set("length", str(length))
    enclosure.set("type", "application/octet-stream")
    if signature:
        enclosure.set(f"{{{SPARKLE_NS['sparkle']}}}edSignature", signature)

    # Insert at the top (right after title element)
    title_elem = channel.find("title")
    if title_elem is not None:
        title_idx = list(channel).index(title_elem)
        channel.insert(title_idx + 1, item)
    else:
        channel.insert(0, item)

    # Write with proper formatting
    # ElementTree doesn't pretty-print well, so we'll use a custom approach
    xml_str = ET.tostring(root, encoding="unicode")

    # Pretty print the XML
    from xml.dom import minidom

    dom = minidom.parseString(xml_str)
    pretty_xml = dom.toprettyxml(indent="    ", encoding="UTF-8")

    # Clean up minidom output (it adds extra newlines)
    pretty_lines = [line for line in pretty_xml.decode('utf-8').split('\n') if line.strip()]

    # Manually format with proper structure
    with open(appcast_path, 'w', encoding='utf-8') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write('<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">\n')
        f.write('    <channel>\n')

        # Write title
        title = channel.find("title")
        if title is not None:
            f.write(f'        <title>{escape(title.text)}</title>\n')

        # Write items (newest first)
        for item_elem in channel.findall("item"):
            # Get item values
            item_title = item_elem.find("title").text
            item_date = item_elem.find("pubDate").text
            item_ver = item_elem.find(f"{{{SPARKLE_NS['sparkle']}}}version")
            item_short = item_elem.find(f"{{{SPARKLE_NS['sparkle']}}}shortVersionString")
            item_min_os = item_elem.find(f"{{{SPARKLE_NS['sparkle']}}}minimumSystemVersion")
            item_desc = item_elem.find("description")
            item_enc = item_elem.find("enclosure")

            f.write('        <item>\n')
            f.write(f'            <title>{escape(item_title)}</title>\n')
            f.write(f'            <pubDate>{escape(item_date)}</pubDate>\n')

            if item_ver is not None:
                f.write(f'            <sparkle:version>{escape(item_ver.text)}</sparkle:version>\n')
            if item_short is not None:
                f.write(f'            <sparkle:shortVersionString>{escape(item_short.text)}</sparkle:shortVersionString>\n')
            if item_min_os is not None:
                f.write(f'            <sparkle:minimumSystemVersion>{escape(item_min_os.text)}</sparkle:minimumSystemVersion>\n')

            # Enclosure
            enc_url = item_enc.get("url", "")
            enc_len = item_enc.get("length", "0")
            enc_sig = item_enc.get(f"{{{SPARKLE_NS['sparkle']}}}edSignature", "")

            f.write('            <enclosure ')
            f.write(f'url="{escape(enc_url)}" ')
            f.write(f'length="{escape(enc_len)}" ')
            f.write(f'type="application/octet-stream"')
            if enc_sig:
                f.write(f' sparkle:edSignature="{escape(enc_sig)}"')
            f.write('/>\n')

            # Description with CDATA
            desc_text = item_desc.text if item_desc.text else ""
            f.write(f'<description><![CDATA[{desc_text}]]></description>\n')

            f.write('        </item>\n')

        f.write('    </channel>\n')
        f.write('</rss>\n')

    print(f"✅ Appended version {version} to {appcast_path}")
    print(f"   URL: {url}")
    print(f"   Size: {length} bytes")
    print(f"   Signature: {signature[:20]}..." if len(signature) > 20 else f"   Signature: {signature}")


def main():
    parser = argparse.ArgumentParser(
        description='Append a new version entry to appcast.xml from CHANGELOG.md',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python3 %(prog)s --changelog docs/CHANGELOG.md --appcast updates/appcast.xml \\
       --version 2.1.5 --url "https://..." --signature "abc123..." --length 1234567
        '''
    )

    parser.add_argument('--changelog', required=True,
                        help='Path to CHANGELOG.md')
    parser.add_argument('--appcast', required=True,
                        help='Path to existing appcast.xml (will be appended to)')
    parser.add_argument('--version', required=True,
                        help='Version string (e.g., 2.1.5)')
    parser.add_argument('--url', required=True,
                        help='Download URL for the DMG')
    parser.add_argument('--signature', required=True,
                        help='EdDSA signature for the DMG')
    parser.add_argument('--length', required=True,
                        help='File size in bytes')

    args = parser.parse_args()

    if not os.path.exists(args.changelog):
        print(f"❌ Error: CHANGELOG.md not found at {args.changelog}")
        sys.exit(1)

    update_appcast(
        appcast_path=args.appcast,
        version=args.version,
        url=args.url,
        signature=args.signature,
        length=args.length,
        changelog_path=args.changelog
    )


if __name__ == '__main__':
    main()
