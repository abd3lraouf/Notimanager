#!/usr/bin/env python3
"""
Cleanup script to remove redundant methods from NotificationMover.swift.
This script removes methods that have been extracted to AXElementManager service.
"""

import re

# Read the file
with open('Notimanager/Managers/NotificationMover.swift', 'r') as f:
    content = f.read()

# List of methods to remove (with their signatures)
methods_to_remove = [
    # Widget monitoring methods (dead code)
    'private func getWindowIdentifier',
    'private func checkForWidgetChanges',
    'private func hasNotificationCenterUI',
    'private func findElementWithWidgetIdentifier',
    # Position calculation (unused)
    'private func calculateNewPosition',
    # Window title (unused, in AXElementManager)
    'private func getWindowTitle',
    # Element properties (in AXElementManager)
    'private func getPosition',
    'private func getSize',
    'private func setPosition',
    # Element selection (in AXElementManager)
    'private func getPositionableElement',
    'private func verifyPositionSet',
    # Element finding (in AXElementManager)
    'private func findElementBySubrole',
    'private func findNotificationElementFallback',
    'private func findElementByIdentifier',
    'private func findElementByRoleAndSize',
    'private func findDeepestSizedElement',
    'private func findAnyElementWithSize',
    # Debug utilities (in AXElementManager)
    'private func logElementDetails',
    'private func collectAllSubrolesInHierarchy',
    'fileprivate func dumpElementHierarchy',
]

# Keep track of removed methods
removed_count = 0

# For each method, find its definition and remove it
for method_signature in methods_to_remove:
    # Find the method - look for the signature with proper indentation
    pattern = rf'\n    {method_signature}\('

    if re.search(pattern, content):
        # Find the method body
        match = re.search(pattern, content)
        if match:
            start = match.start()

            # Find the end of the method by counting braces
            brace_count = 0
            found_opening_brace = False
            i = start
            while i < len(content):
                if content[i] == '{':
                    brace_count += 1
                    found_opening_brace = True
                elif content[i] == '}':
                    brace_count -= 1
                    if found_opening_brace and brace_count == 0:
                        # Found the end of the method
                        # Check if the next non-whitespace line is another method or empty
                        j = i + 1
                        while j < len(content) and content[j] in ['\n', ' ', '\t']:
                            j += 1

                        # Remove the method
                        content = content[:start] + '\n' + content[j+1:]
                        removed_count += 1
                        print(f"✓ Removed: {method_signature}")
                        break
                i += 1

# Write the cleaned content back
with open('Notimanager/Managers/NotificationMover.swift', 'w') as f:
    f.write(content)

print(f"\n✅ Cleanup complete! Removed {removed_count} methods.")
