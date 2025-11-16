//
//  LiquidGlassCard.swift
//  Notimanager
//
//  A reusable card component implementing modern Liquid Glass aesthetics.
//  Inspired by iOS 26 Liquid Glass design language adapted for macOS.
//

import AppKit

/// A card with Liquid Glass visual effect - translucent, layered, with depth
class LiquidGlassCard: NSVisualEffectView {

    // MARK: - Types

    enum Style {
        case primary      // Main content cards
        case elevated     // Raised/prominent cards
        case subtle       // Background/secondary cards
        case interactive  // Cards that respond to user interaction
    }

    // MARK: - Properties

    private let style: Style
    private var highlightLayer: CALayer?
    private var borderLayer: CALayer?

    // MARK: - Initialization

    init(frame: NSRect = .zero, style: Style = .primary) {
        self.style = style
        super.init(frame: frame)
        setupAppearance()
    }

    required init?(coder: NSCoder) {
        self.style = .primary
        super.init(coder: coder)
        setupAppearance()
    }

    // MARK: - Setup

    private func setupAppearance() {
        wantsLayer = true
        material = .contentBackground
        blendingMode = .withinWindow
        state = .followsWindowActiveState

        switch style {
        case .primary:
            setupPrimaryStyle()
        case .elevated:
            setupElevatedStyle()
        case .subtle:
            setupSubtleStyle()
        case .interactive:
            setupInteractiveStyle()
        }

        setupAccessibility()
    }

    private func setupPrimaryStyle() {
        // Semi-transparent background
        layer?.backgroundColor = Colors.glassTint.cgColor

        // Rounded corners
        layer?.cornerRadius = Layout.cardCornerRadius

        // Subtle border
        layer?.borderWidth = Border.hairline
        layer?.borderColor = Colors.glassBorder.cgColor

        // Depth shadow
        shadow = Shadow.card()

        // Inner highlight for glass effect
        addInnerHighlight()
    }

    private func setupElevatedStyle() {
        // More opaque background for elevation
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.15).cgColor

        // Rounded corners
        layer?.cornerRadius = Layout.cardCornerRadius

        // Stronger border
        layer?.borderWidth = Border.thin
        layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor

        // Stronger shadow
        shadow = Shadow.elevated()

        // Inner highlight
        addInnerHighlight()
    }

    private func setupSubtleStyle() {
        // Minimal background
        layer?.backgroundColor = Colors.primaryBackground.withAlphaComponent(0.5).cgColor

        // Rounded corners
        layer?.cornerRadius = Layout.cardCornerRadius

        // Very subtle border
        layer?.borderWidth = Border.hairline
        layer?.borderColor = Colors.separator.withAlphaComponent(0.15).cgColor

        // Minimal shadow
        shadow = Shadow.subtle()
    }

    private func setupInteractiveStyle() {
        // Background that will respond to hover/click
        layer?.backgroundColor = Colors.glassTint.cgColor

        // Rounded corners
        layer?.cornerRadius = Layout.mediumCornerRadius

        // Border that changes with interaction
        layer?.borderWidth = Border.thin
        layer?.borderColor = Colors.glassBorder.cgColor

        // Shadow
        shadow = Shadow.card()

        // Inner highlight
        addInnerHighlight()
    }

    private func addInnerHighlight() {
        let highlight = CALayer()
        highlight.frame = bounds
        highlight.cornerRadius = layer?.cornerRadius ?? 0
        highlight.borderWidth = 1
        highlight.borderColor = Colors.glassHighlight.cgColor
        highlight.masksToBounds = true
        layer?.insertSublayer(highlight, at: 0)
        highlightLayer = highlight
    }

    // MARK: - Layout

    override func layout() {
        super.layout()
        highlightLayer?.frame = bounds
    }

    // MARK: - Accessibility

    private func setupAccessibility() {
        // Card container is not an accessible element itself
        // Child elements should be accessible
        setAccessibilityElement(false)
        setAccessibilityRole(.group)
    }

    // MARK: - Public Methods

    /// Updates the card's appearance for high contrast mode
    func updateForHighContrast(_ isHighContrast: Bool) {
        if isHighContrast {
            // Remove transparency and add stronger borders
            layer?.backgroundColor = Colors.primaryBackground.cgColor
            layer?.borderWidth = Border.medium
            layer?.borderColor = Colors.label.cgColor
        } else {
            // Restore glass effect
            setupAppearance()
        }
        needsLayout = true
    }

    /// Updates the card's appearance for reduce transparency mode
    func updateForReduceTransparency(_ isReduceTransparency: Bool) {
        if isReduceTransparency {
            // Remove transparency
            layer?.backgroundColor = Colors.primaryBackground.cgColor
            layer?.opacity = 1.0
        } else {
            // Restore glass effect
            setupAppearance()
        }
        needsLayout = true
    }

    /// Sets the selected state for interactive cards
    func setSelected(_ selected: Bool) {
        guard style == .interactive else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.fast
            context.timingFunction = Animation.easeInEaseOut

            if selected {
                layer?.borderColor = Colors.accent.cgColor
                layer?.borderWidth = Border.focus
                shadow = Shadow.elevated()
            } else {
                layer?.borderColor = Colors.glassBorder.cgColor
                layer?.borderWidth = Border.thin
                shadow = Shadow.card()
            }

            // Update accessibility
            if selected {
                setAccessibilityRole(.radioButton)
            } else {
                setAccessibilityRole(.button)
            }
        }
    }
}

// MARK: - Convenience Factory Methods

extension LiquidGlassCard {
    /// Creates a card for use in the settings window
    static func settingsCard(frame: CGRect) -> LiquidGlassCard {
        return LiquidGlassCard(frame: frame, style: .primary)
    }

    /// Creates a card for use in the permission window
    static func permissionCard(frame: CGRect) -> LiquidGlassCard {
        return LiquidGlassCard(frame: frame, style: .elevated)
    }

    /// Creates a card for interactive elements like buttons
    static func interactiveCard(frame: CGRect) -> LiquidGlassCard {
        return LiquidGlassCard(frame: frame, style: .interactive)
    }

    /// Creates a subtle background card
    static func subtleCard(frame: CGRect) -> LiquidGlassCard {
        return LiquidGlassCard(frame: frame, style: .subtle)
    }
}
