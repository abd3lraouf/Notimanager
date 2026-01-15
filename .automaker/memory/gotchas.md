---
tags: [gotcha, mistake, edge-case, bug, warning]
summary: Mistakes and edge cases to avoid
relevantTo: [error, bug, fix, issue, problem]
importance: 0.9
relatedFiles: []
usageStats:
  loaded: 26
  referenced: 7
  successfulFeatures: 7
---
# Gotchas

Mistakes and edge cases to avoid. These are lessons learned from past issues.

---



#### [Gotcha] File discovery commands returning empty results should trigger immediate directory context checks - find commands failing silently can mislead about project structure (2026-01-15)
- **Situation:** Initial find commands returned no results, suggesting empty directory
- **Root cause:** Working directory might be incorrect, or files might be in unexpected subdirectories (like Notimanager/)
- **How to avoid:** Added pwd and ls checks added clarity but wasted initial commands