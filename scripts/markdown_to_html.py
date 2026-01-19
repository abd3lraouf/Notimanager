#!/usr/bin/env python3
"""
Convert Markdown to HTML for Sparkle release notes.

This script converts Markdown changelog content to HTML format suitable for
embedding in Sparkle's appcast.xml <description> field.
"""

import sys
import re


def markdown_to_html(markdown_content: str) -> str:
    """Convert Markdown content to HTML.

    Args:
        markdown_content: Raw Markdown content

    Returns:
        HTML content with basic styling
    """
    html_lines = []

    for line in markdown_content.split('\n'):
        # Headers: ## [2.0.5] - 2026-01-18 -> <h3>Version 2.0.5</h3>
        if line.startswith('## '):
            # Remove ## and clean up version notation
            header_text = line[3:].strip()

            # Skip [Unreleased] header
            if 'Unreleased' in header_text:
                continue

            # Extract version from brackets: [2.0.5] - 2026-01-18 -> 2.0.5
            version_match = re.search(r'\[(\d+\.\d+\.\d+)\]', header_text)
            if version_match:
                version = version_match.group(1)
                header_text = f'Version {version}'
            else:
                # Fallback: just strip brackets and clean up
                header_text = header_text.strip('[]')
                # Remove date portion if present
                header_text = re.sub(r'\s*-\s*\d{4}-\d{2}-\d{2}', '', header_text)
                header_text = header_text.strip()

            html_lines.append(f'<h3>{header_text}</h3>')

        # Subheaders: ### ✨ New Features -> <h4>✨ New Features</h4>
        elif line.startswith('### '):
            subheader_text = line[4:].strip()
            html_lines.append(f'<h4>{subheader_text}</h4>')

        # List items: - Item text -> <li>Item text</li>
        # Also handle indented sub-items (spaces followed by -)
        elif re.match(r'^\s*-\s+', line) or re.match(r'^\s*\*\s+', line):
            item_text = re.sub(r'^\s*[-*]\s+', '', line).strip()
            # Handle bold text: **text** -> <strong>text</strong>
            item_text = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', item_text)
            # Handle inline code: `text` -> <code>text</code>
            item_text = re.sub(r'`(.*?)`', r'<code>\1</code>', item_text)
            html_lines.append(f'<li>{item_text}</li>')

        # Empty line -> break or close list
        elif not line.strip():
            # Just add a line break for spacing
            html_lines.append('')

        # Skip other content (dates, links, etc.)
        else:
            # Skip date lines like " - 2026-01-18"
            if re.match(r'^\s*-\s*\d{4}-\d{2}-\d{2}', line):
                continue
            # Skip unreleased section
            if line == '## [Unreleased]':
                continue
            # Skip description lines
            if line in ['All notable changes to Notimanager will be documented in this file.',
                       'The format is based on [Keep a Changelog]',
                       'and this project adheres to [Semantic Versioning].']:
                continue
            # Preserve other content as paragraph
            if line.strip():
                escaped = line.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
                html_lines.append(f'<p>{escaped}</p>')

    # Wrap list items in <ul> tags
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


def main():
    """Main entry point."""
    if len(sys.argv) != 2:
        print('Usage: markdown_to_html.py <input.md>', file=sys.stderr)
        sys.exit(1)

    input_file = sys.argv[1]

    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            markdown_content = f.read()

        html_content = markdown_to_html(markdown_content)
        print(html_content)

    except FileNotFoundError:
        print(f'Error: File not found: {input_file}', file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f'Error: {e}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
