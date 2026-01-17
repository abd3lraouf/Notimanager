//
//  DesignTokens.swift
//  Notimanager
//
//  Design system tokens for consistent styling across the app.
//  Based on modern macOS design principles and Liquid Glass aesthetics.
//

import AppKit

// MARK: - Spacing Tokens
/// 8pt grid system for consistent spacing
struct Spacing {
    static let pt2: CGFloat = 2
    static let pt4: CGFloat = 4
    static let pt8: CGFloat = 8
    static let pt12: CGFloat = 12
    static let pt16: CGFloat = 16
    static let pt20: CGFloat = 20
    static let pt24: CGFloat = 24
    static let pt28: CGFloat = 28
    static let pt32: CGFloat = 32
    static let pt36: CGFloat = 36
    static let pt40: CGFloat = 40
    static let pt44: CGFloat = 44
    static let pt48: CGFloat = 48
    static let pt50: CGFloat = 50
    static let pt60: CGFloat = 60
    static let pt64: CGFloat = 64
}

// MARK: - Typography Tokens
/// Semantic typography scale following Apple's Human Interface Guidelines
struct Typography {
    static let largeTitle = NSFont.systemFont(ofSize: 28, weight: .bold)
    static let title1 = NSFont.systemFont(ofSize: 22, weight: .bold)
    static let title2 = NSFont.systemFont(ofSize: 18, weight: .semibold)
    static let headline = NSFont.systemFont(ofSize: 15, weight: .semibold)
    static let subheadline = NSFont.systemFont(ofSize: 13, weight: .medium)
    static let body = NSFont.systemFont(ofSize: 13, weight: .regular)
    static let bodyEmphasized = NSFont.systemFont(ofSize: 13, weight: .medium)
    static let callout = NSFont.systemFont(ofSize: 12, weight: .regular)
    static let caption1 = NSFont.systemFont(ofSize: 12, weight: .regular)
    static let caption2 = NSFont.systemFont(ofSize: 11, weight: .regular)
    static let footnote = NSFont.systemFont(ofSize: 10, weight: .regular)
}

// MARK: - Color Tokens
/// Semantic color system that adapts to light/dark mode and accessibility settings
struct Colors {
    // Primary accent color (system blue by default, user customizable)
    static let accent = NSColor.controlAccentColor

    // Label colors (adapt to light/dark mode)
    static let label = NSColor.labelColor
    static let secondaryLabel = NSColor.secondaryLabelColor
    static let tertiaryLabel = NSColor.tertiaryLabelColor
    static let quaternaryLabel = NSColor.quaternaryLabelColor

    // Separator and borders
    static let separator = NSColor.separatorColor
    static let separatorOpaque = NSColor.separatorColor.withAlphaComponent(1.0)

    // Status colors
    static let success = NSColor.systemGreen
    static let warning = NSColor.systemOrange
    static let error = NSColor.systemRed
    static let info = NSColor.systemBlue

    // Background colors (semantic and adaptive)
    static let primaryBackground = NSColor.controlBackgroundColor
    static let secondaryBackground = NSColor.underPageBackgroundColor
    static let tertiaryBackground = NSColor.controlBackgroundColor
    static let groupedBackground = NSColor.windowBackgroundColor

    // Content backgrounds
    static let contentBackground = NSColor.textBackgroundColor
    static let selectedContent = NSColor.selectedTextBackgroundColor
    static let unemphasizedSelectedContent = NSColor.unemphasizedSelectedTextBackgroundColor

    // Liquid Glass effect colors
    static let glassTint = NSColor.white.withAlphaComponent(0.1)
    static let glassTintDark = NSColor.black.withAlphaComponent(0.2)
    static let glassBorder = NSColor.white.withAlphaComponent(0.15)
    static let glassBorderDark = NSColor.black.withAlphaComponent(0.3)
    static let glassShadow = NSColor.black.withAlphaComponent(0.1)
    static let glassHighlight = NSColor.white.withAlphaComponent(0.08)

    // Blip Settings colors
    static let blipBackgroundGray = NSColor(hex: "F5F5F7")  // Blip spec: light gray background
    static let blipCardWhite = NSColor.white  // Blip spec: pure white cards
    static let blipSeparator = NSColor(hex: "E5E5E5")  // Blip spec: subtle dividers
}

// MARK: - Blip Icon Colors
/// Vibrant brand colors for Blip Settings icon containers
struct BlipIconColors {
    /// Green - Launch at login, startup settings
    static let green = NSColor(hex: "32D74B")

    /// Red/Pink - Sound effects, destructive actions
    static let red = NSColor(hex: "FF375F")

    /// Purple - Auto-accept, smart features
    static let purple = NSColor(hex: "BF5AF2")

    /// Blue - Files, storage, data settings
    static let blue = NSColor(hex: "007AFF")

    /// Gray - Inactive, info, secondary settings
    static let gray = NSColor(hex: "8E8E93")

    /// Orange - Warnings, cautious settings
    static let orange = NSColor(hex: "FF9500")

    /// Cyan - Sync, cloud settings
    static let cyan = NSColor(hex: "32ADE6")
}

// MARK: - Layout Tokens
/// Standard layout dimensions and corner radii
struct Layout {
    // Corner radii
    static let smallCornerRadius: CGFloat = 6
    static let mediumCornerRadius: CGFloat = 10
    static let cardCornerRadius: CGFloat = 12  // Blip spec: 12pt (was 14)
    static let largeCornerRadius: CGFloat = 18

    // Focus ring
    static let focusRingWidth: CGFloat = 2.5
    static let focusRingOffset: CGFloat = 2

    // Window dimensions
    static let settingsWindowWidth: CGFloat = 540  // Blip spec: 540pt (was 580)
    static let settingsWindowHeight: CGFloat = 580  // Blip spec: 580pt minimum
    static let settingsViewportHeight: CGFloat = 650
    static let settingsContentHeight: CGFloat = 950

    static let permissionWindowWidth: CGFloat = 420
    static let permissionWindowHeight: CGFloat = 280

    static let aboutWindowWidth: CGFloat = 380
    static let aboutWindowHeight: CGFloat = 240

    // Icon sizes
    static let tinyIcon: CGFloat = 12
    static let smallIcon: CGFloat = 16
    static let mediumIcon: CGFloat = 20
    static let largeIcon: CGFloat = 24
    static let extraLargeIcon: CGFloat = 32
    static let hugeIcon: CGFloat = 48

    // Blip-specific icon dimensions
    static let blipIconSize: CGFloat = 32  // Blip spec: 32×32pt icon container
    static let blipIconCornerRadius: CGFloat = 6  // Blip spec: 6pt icon radius
    static let blipIconInnerSize: CGFloat = 18  // Blip spec: 18pt inner icon

    // Blip-specific row padding
    static let blipRowHorizontalPadding: CGFloat = 16  // Blip spec: 16pt H padding
    static let blipRowVerticalPadding: CGFloat = 12  // Blip spec: 12pt V padding

    // Grid
    static let gridSize: CGFloat = 76
    static let gridSpacing: CGFloat = 16

    // Button heights
    static let regularButtonHeight: CGFloat = 28
    static let largeButtonHeight: CGFloat = 32
    static let smallButtonHeight: CGFloat = 24

    // Card heights
    static let pt72: CGFloat = 72
}

// MARK: - Animation Tokens
/// Consistent animation timing and curves
struct Animation {
    static let instant: TimeInterval = 0.08
    static let fast: TimeInterval = 0.15
    static let normal: TimeInterval = 0.25
    static let slow: TimeInterval = 0.35
    static let slower: TimeInterval = 0.5

    // Spring parameters
    static let springDamping: CGFloat = 0.75
    static let springVelocity: CGFloat = 0.5
    static let springResponse: CGFloat = 0.35

    // Timing functions
    static let easeIn = CAMediaTimingFunction(name: .easeIn)
    static let easeOut = CAMediaTimingFunction(name: .easeOut)
    static let easeInEaseOut = CAMediaTimingFunction(name: .easeInEaseOut)
    static let defaultCurve = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
}

// MARK: - Shadow Tokens
/// Predefined shadow styles for different elevation levels
struct Shadow {
    /// Subtle shadow for cards
    static func card() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = Colors.glassShadow
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        shadow.shadowBlurRadius = 8
        return shadow
    }

    /// Elevated shadow for raised elements
    static func elevated() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.15)
        shadow.shadowOffset = NSSize(width: 0, height: -4)
        shadow.shadowBlurRadius = 16
        return shadow
    }

    /// Modal/popup shadow
    static func modal() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        shadow.shadowOffset = NSSize(width: 0, height: -8)
        shadow.shadowBlurRadius = 32
        return shadow
    }

    /// Minimal shadow for inline elements
    static func subtle() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.05)
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 4
        return shadow
    }
}

// MARK: - Blip Shadow Tokens
/// Blip Settings-specific shadows for card elevation
struct BlipShadow {
    /// Blip card shadow - dual layer for ambient occlusion effect
    /// Primary shadow: opacity 0.06, radius 8pt, y: 2pt
    /// Secondary shadow: opacity 0.04, radius 4pt, y: 1pt
    static func card() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.06)  // Blip spec: 0.06
        shadow.shadowOffset = NSSize(width: 0, height: 2)  // Blip spec: y: 2pt (downward)
        shadow.shadowBlurRadius = 8  // Blip spec: radius 8pt
        return shadow
    }

    /// Ambient secondary shadow (requires CALayer for dual shadows)
    static func cardAmbient() -> (color: NSColor, offset: CGSize, radius: CGFloat, opacity: CGFloat) {
        return (
            NSColor.black,
            CGSize(width: 0, height: 1),  // Blip spec: y: 1pt
            4,  // Blip spec: radius 4pt
            0.04  // Blip spec: opacity 0.04
        )
    }

    /// Stronger shadow for elevated/hovered Blip cards
    static func cardElevated() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.08)  // Slightly stronger
        shadow.shadowOffset = NSSize(width: 0, height: 3)
        shadow.shadowBlurRadius = 12
        return shadow
    }
}

// MARK: - Border Tokens
/// Standard border widths and styles
struct Border {
    static let hairline: CGFloat = 0.5
    static let thin: CGFloat = 1.0
    static let medium: CGFloat = 1.5
    static let thick: CGFloat = 2.0
    static let focus: CGFloat = 2.5
}

// MARK: - Z-Index Layers
/// Visual stacking order for layered elements
struct ZIndex {
    static let background: Int = 0
    static let content: Int = 1
    static let overlay: Int = 10
    static let modal: Int = 100
    static let popover: Int = 200
    static let tooltip: Int = 1000
}
