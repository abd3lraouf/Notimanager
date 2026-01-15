---
tags: [architecture]
summary: architecture implementation decisions and patterns
relevantTo: [architecture]
importance: 0.7
relatedFiles: []
usageStats:
  loaded: 2
  referenced: 1
  successfulFeatures: 1
---
# architecture

#### [Gotcha] Technology stack assumptions based on feature descriptions can be dangerously incorrect - 'error boundaries with recovery suggestions' immediately suggested React, but the codebase was actually Swift/macOS using Cocoa/AppKit (2026-01-15)
- **Situation:** Task requested error boundary components, a React-specific pattern
- **Root cause:** Feature terminology can be framework-agnostic but implementation is tightly coupled to platform
- **How to avoid:** Exploration phase revealed mismatch early; would have wasted effort writing React components

### When implementing a framework-specific pattern in a different technology, identify equivalent native mechanisms rather than porting foreign concepts (2026-01-15)
- **Context:** React error boundaries don't exist in Swift/macOS
- **Why:** Error boundaries rely on React's component lifecycle and error propogation; Swift has different error handling with try/catch, Result types, and delegation
- **Rejected:** Attempting to shoehorn React's boundary pattern into Swift
- **Trade-offs:** Native error handling will be more idiomatic but requires rethinking the user-facing error recovery UX
- **Breaking if changed:** Forcing React patterns into Swift would fight the language and framework conventions