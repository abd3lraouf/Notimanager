# Notimanager UX & Accessibility Enhancement Plan
## Liquid Glass Implementation & Modern Design System

### Executive Summary

This plan outlines the comprehensive enhancement of Notimanager's user experience, accessibility, and visual design to align with modern macOS design principles and Apple's Liquid Glass design language.

**Current State:**
- Single 27,000+ line file with all UI logic
- No accessibility labels or VoiceOver support
- No keyboard navigation beyond menu bar
- Inconsistent spacing and styling
- Basic glass effects using NSVisualEffectView

**Target State:**
- Modular, reusable UI component architecture
- Full accessibility support (VoiceOver, keyboard, high contrast)
- Modern Liquid Glass effects adapted for macOS
- Centralized design system with tokens
- Smooth animations and transitions
- Proper focus management

---

## Phase 1: Design System Foundation

### 1.1 Create DesignTokens.swift
**File:** `Notimanager/DesignSystem/DesignTokens.swift`

```swift
// Spacing tokens (8pt grid system)
struct Spacing {
    static let pt2: CGFloat = 2
    static let pt4: CGFloat = 4
    static let pt8: CGFloat = 8
    static let pt12: CGFloat = 12
    static let pt16: CGFloat = 16
    static let pt24: CGFloat = 24
    static let pt32: CGFloat = 32
    static let pt48: CGFloat = 48
    static let pt64: CGFloat = 64
}

// Typography tokens
struct Typography {
    static let largeTitle = NSFont.systemFont(ofSize: 28, weight: .bold)
    static let title1 = NSFont.systemFont(ofSize: 22, weight: .bold)
    static let title2 = NSFont.systemFont(ofSize: 18, weight: .semibold)
    static let headline = NSFont.systemFont(ofSize: 15, weight: .semibold)
    static let body = NSFont.systemFont(ofSize: 13, weight: .regular)
    static let bodyEmphasized = NSFont.systemFont(ofSize: 13, weight: .medium)
    static let caption1 = NSFont.systemFont(ofSize: 12, weight: .regular)
    static let caption2 = NSFont.systemFont(ofSize: 11, weight: .regular)
}

// Color tokens (semantic + adaptive)
struct Colors {
    // Primary colors
    static let accent = NSColor.controlAccentColor

    // Semantic colors
    static let label = NSColor.labelColor
    static let secondaryLabel = NSColor.secondaryLabelColor
    static let tertiaryLabel = NSColor.tertiaryLabelColor
    static let separator = NSColor.separatorColor

    // Status colors
    static let success = NSColor.systemGreen
    static let warning = NSColor.systemOrange
    static let error = NSColor.systemRed

    // Background colors (adaptive)
    static let primaryBackground = NSColor.controlBackgroundColor
    static let secondaryBackground = NSColor.unemphasizedSelectedContentBackgroundColor
    static let tertiaryBackground = NSColor.controlBackgroundColor

    // Glass effect colors
    static let glassTint = NSColor.white.withAlphaComponent(0.1)
    static let glassBorder = NSColor.white.withAlphaComponent(0.15)
    static let glassShadow = NSColor.black.withAlphaComponent(0.1)
}

// Layout tokens
struct Layout {
    static let cardCornerRadius: CGFloat = 14
    static let buttonCornerRadius: CGFloat = 8
    static let focusRingWidth: CGFloat = 2.5

    // Window dimensions
    static let settingsWindowWidth: CGFloat = 580
    static let settingsViewportHeight: CGFloat = 650
    static let settingsContentHeight: CGFloat = 950

    // Icon sizes
    static let smallIcon: CGFloat = 16
    static let mediumIcon: CGFloat = 24
    static let largeIcon: CGFloat = 32
}

// Animation tokens
struct Animation {
    static let fast: TimeInterval = 0.15
    static let normal: TimeInterval = 0.25
    static let slow: TimeInterval = 0.35

    static let springDamping: CGFloat = 0.75
    static let springVelocity: CGFloat = 0.5
}

// Shadow tokens
struct Shadow {
    static func card() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = Colors.glassShadow
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        shadow.shadowBlurRadius = 8
        return shadow
    }

    static func elevated() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.15)
        shadow.shadowOffset = NSSize(width: 0, height: -4)
        shadow.shadowBlurRadius = 16
        return shadow
    }
}
```

### 1.2 Create LiquidGlassCard.swift Component
**File:** `Notimanager/DesignSystem/LiquidGlassCard.swift`

A reusable card component that implements modern Liquid Glass aesthetics for macOS:

```swift
class LiquidGlassCard: NSVisualEffectView {
    enum Style {
        case primary      // Main cards
        case elevated     // Raised cards
        case subtle       // Background cards
    }

    private let style: Style
    private var highlightLayer: CALayer?

    init(frame: NSRect, style: Style = .primary) {
        self.style = style
        super.init(frame: frame)
        setupAppearance()
    }

    private func setupAppearance() {
        wantsLayer = true
        material = .contentBackground
        blendingMode = .withinWindow
        state = .followsWindowActiveState

        // Adaptive styling based on style
        switch style {
        case .primary:
            setupPrimaryStyle()
        case .elevated:
            setupElevatedStyle()
        case .subtle:
            setupSubtleStyle()
        }

        // Add accessibility
        setupAccessibility()
    }

    private func setupPrimaryStyle() {
        layer?.backgroundColor = Colors.glassTint.cgColor
        layer?.cornerRadius = Layout.cardCornerRadius
        layer?.borderWidth = 0.8
        layer?.borderColor = Colors.glassBorder.cgColor
        shadow = Shadow.card()
        addInnerHighlight()
    }

    private func setupElevatedStyle() {
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.15).cgColor
        layer?.cornerRadius = Layout.cardCornerRadius
        layer?.borderWidth = 1.0
        layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        shadow = Shadow.elevated()
        addInnerHighlight()
    }

    private func setupSubtleStyle() {
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.3).cgColor
        layer?.cornerRadius = Layout.cardCornerRadius
        layer?.borderWidth = 0.5
        layer?.borderColor = Colors.separator.withAlphaComponent(0.1).cgColor
    }

    private func addInnerHighlight() {
        let highlight = CALayer()
        highlight.frame = bounds
        highlight.cornerRadius = layer?.cornerRadius ?? 0
        highlight.borderWidth = 1
        highlight.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        highlight.masksToBounds = true
        layer?.insertSublayer(highlight, at: 0)
        highlightLayer = highlight
    }

    override func layout() {
        super.layout()
        highlightLayer?.frame = bounds
    }

    private func setupAccessibility() {
        setAccessibilityElement(false) // Container is not accessible
        setAccessibilityRole(.group)
    }
}
```

---

## Phase 2: Accessibility Implementation

### 2.1 Create AccessibilityManager.swift
**File:** `Notimanager/Managers/AccessibilityManager.swift`

Centralized accessibility management:

```swift
class AccessibilityManager {
    static let shared = AccessibilityManager()

    // VoiceOver announcement queue
    private var announcementQueue: [(String, NSAccessibility.NotificationType)] = []

    // Announce important state changes
    func announce(_ message: String, priority: NSAccessibility.NotificationType = .announcementRequested) {
        DispatchQueue.main.async {
            NSAccessibility.post(element: NSApp.accessibilityFocusedUIElement(), notification: priority)
            // Use NSAccessibility's announcement API
            let element = NSAccessibility.UnignoredElementForView(NSApp.keyWindow?.contentView ?? NSView())
            NSAccessibility.post(element: element, notification: .announcementRequested, userInfo: [
                NSAccessibility.NotificationUserInfoKey.announcement: message
            ])
        }
    }

    // Setup accessibility for buttons
    func configureButton(_ button: NSButton, label: String, hint: String? = nil) {
        button.setAccessibilityLabel(label)
        if let hint = hint {
            button.setAccessibilityHint(hint)
        }
        button.setAccessibilityRole(.button)
    }

    // Setup accessibility for checkboxes
    func configureCheckbox(_ checkbox: NSButton, label: String, hint: String? = nil) {
        checkbox.setAccessibilityLabel(label)
        if let hint = hint {
            checkbox.setAccessibilityHint(hint)
        }
        checkbox.setAccessibilityRole(.checkBox)
        checkbox.setAccessibilityTitle(label)
    }

    // Setup accessibility for cards/sections
    func configureSection(_ view: NSView, title: String) {
        view.setAccessibilityLabel(title)
        view.setAccessibilityRole(.group)
    }
}
```

### 2.2 Keyboard Navigation System
**File:** `Notimanager/Managers/KeyboardNavigationManager.swift`

```swift
class KeyboardNavigationManager: NSObject {
    static let shared = KeyboardNavigationManager()

    private var focusMap: [NSView.StringSelector: NSView] = [:]

    func setupKeyboardNavigation(in window: NSWindow) {
        // Setup tab navigation
        window.initialFirstResponder = focusMap.values.first

        // Setup keyboard shortcuts
        setupGlobalShortcuts()
    }

    func registerView(_ view: NSView, forKey key: String) {
        focusMap[NSView.StringSelector(key)] = view
    }

    private func setupGlobalShortcuts() {
        // Cmd+, for Settings
        // Cmd+D for Diagnostics
        // Space to toggle checkboxes
        // Return to activate buttons
        // Arrow keys for position grid
    }
}
```

---

## Phase 3: Component Refactoring

### 3.1 Create PositionGridButton.swift
**File:** `Notimanager/Components/PositionGridButton.swift`

Reusable position selection button with proper accessibility:

```swift
class PositionGridButton: NSView {
    private let position: NotificationPosition
    private let isSelected: Bool
    private let action: () -> Void

    private var container: NSVisualEffectView!
    private var button: NSButton!
    private var iconView: NSImageView!

    init(position: NotificationPosition, isSelected: Bool, action: @escaping () -> Void) {
        self.position = position
        self.isSelected = isSelected
        self.action = action
        super.init(frame: .zero)
        setup()
    }

    private func setup() {
        wantsLayer = true

        // Container with glass effect
        container = NSVisualEffectView()
        container.material = isSelected ? .selection : .underWindowBackground
        container.blendingMode = .withinWindow
        container.state = .active
        container.wantsLayer = true
        container.layer?.cornerRadius = 14
        container.layer?.borderWidth = isSelected ? 2.5 : 1
        container.layer?.borderColor = isSelected
            ? Colors.accent.cgColor
            : Colors.separator.withAlphaComponent(0.4).cgColor
        container.shadow = isSelected ? Shadow.elevated() : Shadow.card()

        addSubview(container)

        // Clickable button
        button = NSButton()
        button.title = ""
        button.bezelStyle = .shadowlessSquare
        button.isBordered = false
        button.target = self
        button.action = #selector(handleTap)
        button.wantsLayer = true
        button.layer?.backgroundColor = .clear
        container.addSubview(button)

        // Icon
        if let icon = createIcon() {
            iconView = NSImageView()
            iconView.image = icon
            iconView.contentTintColor = isSelected ? Colors.accent : Colors.tertiaryLabel
            iconView.imageScaling = .scaleProportionallyDown
            button.addSubview(iconView)
        }

        // Accessibility
        setupAccessibility()
    }

    private func createIcon() -> NSImage? {
        let symbolName: String
        switch position {
        case .topLeft: symbolName = "arrow.up.left"
        case .topMiddle: symbolName = "arrow.up"
        case .topRight: symbolName = "arrow.up.right"
        case .middleLeft: symbolName = "arrow.left"
        case .deadCenter: symbolName = "circle.fill"
        case .middleRight: symbolName = "arrow.right"
        case .bottomLeft: symbolName = "arrow.down.left"
        case .bottomMiddle: symbolName = "arrow.down"
        case .bottomRight: symbolName = "arrow.down.right"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: position.displayName)?
            .withSymbolConfiguration(config)
    }

    private func setupAccessibility() {
        setAccessibilityElement(true)
        setAccessibilityLabel(position.displayName)
        setAccessibilityHint(isSelected
            ? "Currently selected notification position"
            : "Set notification position to \(position.displayName)")
        setAccessibilityRole(.button)
        setAccessibilityIdentifier(position.rawValue)

        if isSelected {
            setAccessibilityTraits(.isSelected)
        }
    }

    @objc private func handleTap() {
        action()
        AccessibilityManager.shared.announce("Notification position changed to \(position.displayName)")
    }

    override func layout() {
        super.layout()
        container.frame = bounds
        button.frame = bounds

        let iconSize: CGFloat = 32
        let iconPadding = (bounds.width - iconSize) / 2
        iconView?.frame = NSRect(x: iconPadding, y: iconPadding, width: iconSize, height: iconSize)
    }
}
```

### 3.2 Create AnimatedSegmentedControl.swift
**File:** `Notimanager/Components/AnimatedSegmentedControl.swift`

Segmented control with smooth animations:

```swift
class AnimatedSegmentedControl: NSView {
    private var segments: [String] = []
    private var selectedIndex: Int = 0
    private var indicator: NSView!
    private var buttons: [NSButton] = []
    private var onChange: ((Int) -> Void)?

    var selectedSegmentIndex: Int {
        get { selectedIndex }
        set {
            guard newValue >= 0, newValue < segments.count else { return }
            selectedIndex = newValue
            updateSelection()
        }
    }

    func configure(segments: [String], onChange: @escaping (Int) -> Void) {
        self.segments = segments
        self.onChange = onChange
        setup()
    }

    private func setup() {
        wantsLayer = true

        // Background
        layer?.backgroundColor = Colors.tertiBackground.withAlphaComponent(0.5).cgColor
        layer?.cornerRadius = 8

        // Indicator
        indicator = NSView()
        indicator.wantsLayer = true
        indicator.layer?.backgroundColor = Colors.accent.withAlphaComponent(0.3).cgColor
        indicator.layer?.cornerRadius = 6
        addSubview(indicator)

        // Buttons
        for (index, segment) in segments.enumerated() {
            let button = NSButton()
            button.title = segment
            button.bezelStyle = .regularSquare
            button.isBordered = false
            button.target = self
            button.action = #selector(segmentTapped(_:))
            button.tag = index
            button.font = Typography.body
            addSubview(button)
            buttons.append(button)

            // Accessibility
            button.setAccessibilityLabel(segment)
            button.setAccessibilityRole(.radioButton)
            button.setAccessibilityValue(index == selectedIndex ? "true" : "false")
        }
    }

    @objc private func segmentTapped(_ sender: NSButton) {
        selectedSegmentIndex = sender.tag
        onChange?(sender.tag)
        AccessibilityManager.shared.announce("\(segments[sender.tag]) selected")
    }

    private func updateSelection() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.normal
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            indicator.animator().frame.origin.x = CGFloat(selectedIndex) * (bounds.width / CGFloat(segments.count))

            for (index, button) in buttons.enumerated() {
                button.setAccessibilityValue(index == selectedIndex ? "true" : "false")
            }
        }
    }
}
```

---

## Phase 4: Settings Window Refactoring

### 4.1 Create SettingsViewController.swift
**File:** `Notimanager/Views/SettingsViewController.swift`

Refactor settings into a proper view controller:

```swift
class SettingsViewController: NSViewController {
    private var scrollView: NSScrollView!
    private var contentView: NSView!

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(
            x: 0,
            y: 0,
            width: Layout.settingsWindowWidth,
            height: Layout.settingsViewportHeight
        ))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAccessibility()
        setupKeyboardNavigation()
    }

    private func setupUI() {
        // Scroll view
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Content view
        contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView

        // Build sections
        buildPositionSection()
        buildTestSection()
        buildPreferencesSection()
        buildAboutSection()

        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.widthAnchor.constraint(equalToConstant: Layout.settingsWindowWidth),
            contentView.heightAnchor.constraint(equalToConstant: Layout.settingsContentHeight)
        ])
    }

    private func setupAccessibility() {
        view.setAccessibilityLabel("Settings")
        view.setAccessibilityRole(.group)
    }

    private func setupKeyboardNavigation() {
        // Setup tab chain
    }
}
```

---

## Phase 5: Animations & Transitions

### 5.1 Create AnimationHelper.swift
**File:** `Notimanager/Utils/AnimationHelper.swift`

```swift
class AnimationHelper {
    // Smooth opacity transition
    static func fade(_ view: NSView, to alpha: CGFloat, duration: TimeInterval = Animation.normal) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            view.animator().alphaValue = alpha
        }
    }

    // Spring animation
    static func spring(_ view: NSView, changes: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.normal
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
            changes()
        }
    }

    // Scale animation
    static func scale(_ view: NSView, to scale: CGFloat, duration: TimeInterval = Animation.fast) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            view.layer?.setAffineTransform(transform)
        }
    }
}
```

---

## Phase 6: High Contrast Mode Support

### 6.1 Create AppearanceManager.swift
**File:** `Notimanager/Managers/AppearanceManager.swift`

```swift
class AppearanceManager {
    static let shared = AppearanceManager()

    private(set) var isHighContrast: Bool = false
    private(set) var isReduceTransparency: Bool = false

    init() {
        observeAppearanceChanges()
        updateAppearanceSettings()
    }

    private func observeAppearanceChanges() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(appearanceChanged),
            name: NSAccessibility.enhancedUserInterfaceNotification,
            object: nil
        )

        NotificationCenter.default().addObserver(
            self,
            selector: #selector(appearanceChanged),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
    }

    @objc private func appearanceChanged() {
        updateAppearanceSettings()
        NotificationCenter.default.post(name: .appearanceDidChange, object: self)
    }

    private func updateAppearanceSettings() {
        isHighContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        isReduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }

    // Adaptive color based on appearance settings
    func adaptiveColor(normal: NSColor, highContrast: NSColor) -> NSColor {
        return isHighContrast ? highContrast : normal
    }

    // Adaptive transparency
    func adaptiveAlpha(normal: CGFloat, reduced: CGFloat) -> CGFloat {
        return isReduceTransparency ? reduced : normal
    }
}

extension NSNotification.Name {
    static let appearanceDidChange = NSNotification.Name("appearanceDidChange")
}
```

---

## Implementation Tasks & Order

### Week 1: Foundation
1. ✅ Create DesignTokens.swift with all design constants
2. ✅ Create LiquidGlassCard.swift reusable component
3. ✅ Create AccessibilityManager.swift
4. ✅ Create AppearanceManager.swift

### Week 2: Components
5. ✅ Create PositionGridButton.swift with accessibility
6. ✅ Create AnimatedSegmentedControl.swift
7. ✅ Create AnimationHelper.swift
8. ✅ Create KeyboardNavigationManager.swift

### Week 3: Refactoring
9. ✅ Refactor settings window into SettingsViewController
10. ✅ Apply new design tokens to permission window
11. ✅ Apply new design tokens to about window
12. ✅ Refactor menu bar with improved accessibility

### Week 4: Polish
13. ✅ Add VoiceOver announcements for all state changes
14. ✅ Implement full keyboard navigation
15. ✅ Add high contrast mode variants
16. ✅ Add smooth animations throughout
17. ✅ Test with VoiceOver and keyboard only
18. ✅ Performance optimization

---

## Success Metrics

### Accessibility
- ✅ All elements have accessibility labels
- ✅ VoiceOver can navigate entire UI
- ✅ Keyboard only navigation works
- ✅ High contrast mode supported
- ✅ Reduce transparency supported

### Visual Quality
- ✅ Consistent spacing using design tokens
- ✅ Smooth animations (150-350ms)
- ✅ Proper Liquid Glass effects
- ✅ Clear visual hierarchy
- ✅ Responsive layout

### Code Quality
- ✅ Modular, reusable components
- ✅ Single responsibility principle
- ✅ Testable architecture
- ✅ Reduced NotificationMover.swift size by 60%

---

## Sources

- [Apple Official Announcement - Liquid Glass Design](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)
- [Designing custom UI with Liquid Glass on iOS 26](https://www.donnywals.com/designing-custom-ui-with-liquid-glass-on-ios-26/)
- [Apple Developer Design Gallery](https://developer.apple.com/design/new-design-gallery/)
- [Liquid Glass Is Cracked, and Usability Suffers](https://www.nngroup.com/articles/liquid-glass/)
