//
//  AppearanceManager.swift
//  Notimanager
//
//  Manages appearance changes including high contrast mode,
//  reduce transparency, and dark/light mode adaptations.
//

import AppKit

/// Manages system appearance settings and provides adaptive styling
class AppearanceManager {

    // MARK: - Singleton

    static let shared = AppearanceManager()

    private init() {
        observeAppearanceChanges()
        updateAppearanceSettings()
    }

    // MARK: - Properties

    private(set) var isHighContrast: Bool = false
    private(set) var isReduceTransparency: Bool = false
    private(set) var isReduceMotion: Bool = false
    private(set) var isInvertColors: Bool = false

    /// Appearance changed notification
    static let appearanceDidChangeNotification = Notification.Name("appearanceDidChange")

    // MARK: - Appearance Monitoring

    private func observeAppearanceChanges() {
        // Monitor for accessibility preference changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(appearanceChanged),
            name: NSNotification.Name("com.apple.accessibility.api.vo.focus"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appearanceChanged),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )

        // Monitor for appearance changes (dark/light mode)
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(appearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    @objc private func appearanceChanged() {
        let oldHighContrast = isHighContrast
        let oldReduceTransparency = isReduceTransparency
        let oldReduceMotion = isReduceMotion

        updateAppearanceSettings()

        // Only notify if something actually changed
        if oldHighContrast != isHighContrast ||
           oldReduceTransparency != isReduceTransparency ||
           oldReduceMotion != isReduceMotion {

            // Notify observers
            NotificationCenter.default.post(
                name: Self.appearanceDidChangeNotification,
                object: self,
                userInfo: [
                    "isHighContrast": isHighContrast,
                    "isReduceTransparency": isReduceTransparency,
                    "isReduceMotion": isReduceMotion
                ]
            )
        }
    }

    private func updateAppearanceSettings() {
        isHighContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        isReduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        isReduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        isInvertColors = NSWorkspace.shared.accessibilityDisplayShouldInvertColors

        #if DEBUG
        print("[AppearanceManager] High Contrast: \(isHighContrast), Reduce Transparency: \(isReduceTransparency), Reduce Motion: \(isReduceMotion)")
        #endif
    }

    // MARK: - Adaptive Colors

    /// Returns an adaptive color based on high contrast setting
    /// - Parameters:
    ///   - normal: The normal color
    ///   - highContrast: The high contrast variant
    /// - Returns: Appropriate color based on settings
    func adaptiveColor(normal: NSColor, highContrast: NSColor) -> NSColor {
        return isHighContrast ? highContrast : normal
    }

    /// Returns an adaptive background color
    /// - Parameters:
    ///   - normal: The normal background
    ///   - reducedTransparency: The solid background for reduce transparency mode
    /// - Returns: Appropriate background color
    func adaptiveBackgroundColor(normal: NSColor, reducedTransparency: NSColor) -> NSColor {
        return isReduceTransparency ? reducedTransparency : normal
    }

    /// Returns an adaptive alpha value
    /// - Parameters:
    ///   - normal: The normal alpha value
    ///   - reduced: The alpha value for reduce transparency mode
    /// - Returns: Appropriate alpha based on settings
    func adaptiveAlpha(normal: CGFloat, reduced: CGFloat = 1.0) -> CGFloat {
        return isReduceTransparency ? reduced : normal
    }

    // MARK: - Adaptive Shadows

    /// Returns an appropriate shadow based on accessibility settings
    /// - Parameters:
    ///   - normal: The normal shadow
    /// - Returns: Adaptive shadow (may be disabled in high contrast)
    func adaptiveShadow(normal: NSShadow) -> NSShadow? {
        if isHighContrast || isReduceTransparency {
            return nil // Shadows can be distracting in these modes
        }
        return normal
    }

    // MARK: - Visual Effect Materials

    /// Returns an appropriate visual effect material based on settings
    /// - Parameters:
    ///   - normal: The normal material
    ///   - solid: The solid material fallback
    /// - Returns: Appropriate material
    func adaptiveMaterial(normal: NSVisualEffectView.Material, solid: NSVisualEffectView.Material = .contentBackground) -> NSVisualEffectView.Material {
        return isReduceTransparency ? solid : normal
    }

    // MARK: - Border Adaptation

    /// Returns an adaptive border width
    /// - Parameters:
    ///   - normal: The normal border width
    ///   - highContrast: The border width for high contrast mode
    /// - Returns: Appropriate border width
    func adaptiveBorderWidth(normal: CGFloat, highContrast: CGFloat = 2.0) -> CGFloat {
        return isHighContrast ? highContrast : normal
    }

    /// Returns an adaptive border color
    /// - Parameters:
    ///   - normal: The normal border color
    ///   - highContrast: The high contrast border color
    /// - Returns: Appropriate border color
    func adaptiveBorderColor(normal: NSColor, highContrast: NSColor? = nil) -> NSColor {
        if isHighContrast {
            return highContrast ?? Colors.label
        }
        return normal
    }

    // MARK: - Animation Control

    /// Returns whether animations should be used
    var shouldAnimate: Bool {
        return !isReduceMotion
    }

    /// Executes animation only if reduce motion is disabled
    /// - Parameter animation: The animation block to execute
    func animateIfNeeded(_ animation: @escaping () -> Void) {
        if shouldAnimate {
            animation()
        } else {
            // Skip animation, just apply final state
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0
            animation()
            NSAnimationContext.endGrouping()
        }
    }

    /// Returns appropriate animation duration
    /// - Parameter normal: The normal duration
    /// - Returns: Adaptive duration (0 if reduce motion is enabled)
    func adaptiveDuration(normal: TimeInterval) -> TimeInterval {
        return shouldAnimate ? normal : 0
    }

    // MARK: - View Updates

    /// Updates a view's appearance based on current settings
    /// - Parameter view: The view to update
    func updateViewAppearance(_ view: NSView) {
        // Override in subclasses or use with specific view types
        if let card = view as? LiquidGlassCard {
            updateCardAppearance(card)
        }
    }

    /// Updates a card's appearance for accessibility
    /// - Parameter card: The card to update
    private func updateCardAppearance(_ card: LiquidGlassCard) {
        card.updateForHighContrast(isHighContrast)
        card.updateForReduceTransparency(isReduceTransparency)
    }

    // MARK: - Convenience Methods

    /// Checks if any accessibility features that affect appearance are enabled
    var hasAccessibilityAppearanceEnabled: Bool {
        return isHighContrast || isReduceTransparency || isInvertColors
    }

    /// Returns the current effective appearance
    var currentAppearance: NSAppearance {
        return NSApp.effectiveAppearance
    }

    /// Checks if dark mode is active
    var isDarkMode: Bool {
        return currentAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    /// Returns a color that adapts to light/dark mode
    func adaptiveColor(light: NSColor, dark: NSColor) -> NSColor {
        return isDarkMode ? dark : light
    }
}

// MARK: - NSView Extension for Appearance

extension NSView {

    /// Applies appearance manager updates to the view
    func applyAppearanceUpdates() {
        AppearanceManager.shared.updateViewAppearance(self)
    }

    /// Sets up automatic appearance change monitoring
    func observeAppearanceChanges(_ handler: @escaping (Notification) -> Void) {
        NotificationCenter.default.addObserver(
            forName: AppearanceManager.appearanceDidChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            handler(notification)
        }
    }
}

// MARK: - NSVisualEffectView Extension

extension NSVisualEffectView {

    /// Configures the visual effect view with adaptive appearance
    /// - Parameters:
    ///   - material: The preferred material
    ///   - blendingMode: The blending mode
    func configureAdaptive(material: NSVisualEffectView.Material, blendingMode: NSVisualEffectView.BlendingMode) {
        self.material = AppearanceManager.shared.adaptiveMaterial(normal: material)
        self.blendingMode = blendingMode
        self.state = .followsWindowActiveState
    }
}
