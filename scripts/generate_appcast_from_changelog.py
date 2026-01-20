#!/usr/bin/env python3
"""
Generate Sparkle appcast.xml from CHANGELOG.md.

This script parses CHANGELOG.md to extract all released versions
and generates a complete appcast.xml with entries for each version.
"""

import argparse
import re
import sys
from datetime import datetime


def parse_changelog(changelog_path):
    """Parse CHANGELOG.md and extract version information.

    Args:
        changelog_path: Path to CHANGELOG.md

    Returns:
        List of dicts with version info: {version, date, content}
    """
    with open(changelog_path, 'r', encoding='utf-8') as f:
        content = f.read()

    versions = []

    # Find all version sections: ## [X.Y.Z] - YYYY-MM-DD
    pattern = r'^## \[([0-9.]+)\] - (\d{4}-\d{2}-\d{2})'
    matches = list(re.finditer(pattern, content, re.MULTILINE))

    for i, match in enumerate(matches):
        version = match.group(1)
        date_str = match.group(2)

        # Extract content for this version (until next version or EOF)
        start_pos = match.end()
        if i + 1 < len(matches):
            end_pos = matches[i + 1].start()
        else:
            end_pos = len(content)

        version_content = content[start_pos:end_pos].strip()

        versions.append({
            'version': version,
            'date': date_str,
            'content': version_content
        })

    return versions


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
            html_lines.append(f'<h4>{text}</h4>')

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

    # Wrap list items
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


def parse_current_appcast(appcast_path):
    """Parse current appcast.xml to extract enclosure info.

    Args:
        appcast_path: Path to appcast.xml

    Returns:
        Dict with enclosure info: {url, length, type, ed_signature}
    """
    with open(appcast_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract enclosure info
    url_match = re.search(r'url="([^"]+)"', content)
    length_match = re.search(r'length="(\d+)"', content)
    type_match = re.search(r'type="([^"]+)"', content)
    sig_match = re.search(r'sparkle:edSignature="([^"]+)"', content)

    return {
        'url': url_match.group(1) if url_match else '',
        'length': length_match.group(1) if length_match else '0',
        'type': type_match.group(1) if type_match else 'application/octet-stream',
        'ed_signature': sig_match.group(1) if sig_match else ''
    }


def generate_appcast_item(version_info, enclosure_info, is_current=False):
    """Generate an appcast <item> element for a version.

    Args:
        version_info: Dict with version, date, content
        enclosure_info: Dict with url, length, type, ed_signature
        is_current: If True, use real enclosure info; if False, use placeholder

    Returns:
        XML string for the <item>
    """
    version = version_info['version']
    date_str = version_info['date']

    # Convert markdown content to HTML
    html_content = markdown_to_html(version_info['content'])

    # Style for HTML
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
{html_content}
</body>
</html>'''

    # Escape for CDATA
    styled_html = styled_html.replace(']]>', ']]]]><![CDATA[>')

    # Parse date to RFC 2822
    try:
        dt = datetime.strptime(date_str, '%Y-%m-%d')
        pub_date = dt.strftime('%a, %d %b %Y %H:%M:%S +0000')
    except:
        pub_date = date_str

    # For current version, use real enclosure info
    # For old versions, use placeholder URLs
    if is_current:
        enclosure_url = enclosure_info['url']
        enclosure_length = enclosure_info['length']
        enclosure_sig = enclosure_info['ed_signature']
    else:
        # Placeholder URL - Sparkle won't download old versions anyway
        enclosure_url = f"https://github.com/abd3lraouf/Notimanager/releases/download/v{version}/Notimanager-{version}.dmg"
        enclosure_length = "0"
        enclosure_sig = ""

    enclosure_attr = f'url="{enclosure_url}" length="{enclosure_length}" type="{enclosure_info["type"]}"'
    if enclosure_sig:
        enclosure_attr += f' sparkle:edSignature="{enclosure_sig}"'

    return f'''        <item>
            <title>{version}</title>
            <pubDate>{pub_date}</pubDate>
            <sparkle:version>{version}</sparkle:version>
            <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <enclosure {enclosure_attr}/>
<description><![CDATA[{styled_html}]]></description>
        </item>'''


def main():
    parser = argparse.ArgumentParser(description='Generate appcast from CHANGELOG.md')
    parser.add_argument('--changelog', required=True, help='Path to CHANGELOG.md')
    parser.add_argument('--current-appcast', required=True, help='Path to current appcast.xml')
    parser.add_argument('--output', required=True, help='Output path for appcast.xml')
    parser.add_argument('--current-version', required=True, help='Current version being released')

    args = parser.parse_args()

    # Parse changelog
    versions = parse_changelog(args.changelog)
    print(f"Found {len(versions)} versions in CHANGELOG.md")

    # Parse current appcast for enclosure info
    enclosure_info = parse_current_appcast(args.current_appcast)

    # Generate appcast items
    items = []
    for v in versions:
        is_current = (v['version'] == args.current_version)
        item = generate_appcast_item(v, enclosure_info, is_current=is_current)
        items.append(item)

    # Build complete appcast
    appcast_content = f'''<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
        <title>Notimanager</title>
{chr(10).join(items)}
    </channel>
</rss>'''

    # Write output
    with open(args.output, 'w', encoding='utf-8') as f:
        f.write(appcast_content)

    print(f"✅ Generated appcast with {len(items)} versions")
    print(f"   Output: {args.output}")


if __name__ == '__main__':
    main()
