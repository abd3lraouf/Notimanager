//
//  LiquidGlassComponents.swift
//  Notimanager
//
//  Liquid Glass Design System Components (2026)
//  A comprehensive material design system for macOS that creates depth,
//  translucency, and refractive visual effects following Apple's HIG.
//
//  Based on: Apple Human Interface Guidelines 2026
//  Design Language: Liquid Glass
//

import AppKit
import SwiftUI

// MARK: - Liquid Glass Material System

/// The foundation of all glass components - handles material, shadows, and borders
/// Creates the signature "Liquid Glass" effect with proper depth and light refraction
public struct LiquidGlassMaterial {

    let material: NSVisualEffectView.Material
    let shadowIntensity: ShadowIntensity
    let borderLuminance: Double
    let cornerRadius: CGFloat

    public enum ShadowIntensity {
        case subtle    // Floating elements (10pt elevation)
        case medium    // Cards (20pt elevation)
        case strong    // Modals (40pt elevation)
        case dramatic  // Overlays (60pt elevation)

        var radius: CGFloat {
            switch self {
            case .subtle: return 12
            case .medium: return 20
            case .strong: return 40
            case .dramatic: return 60
            }
        }

        var offset: CGFloat {
            switch self {
            case .subtle: return 4
            case .medium: return 8
            case .strong: return 16
            case .dramatic: return 24
            }
        }

        var opacity: Double {
            switch self {
            case .subtle: return 0.08
            case .medium: return 0.12
            case .strong: return 0.16
            case .dramatic: return 0.20
            }
        }

        var secondaryOpacity: Double {
            return opacity * 0.5
        }
    }

    public init(
        material: NSVisualEffectView.Material = .titlebar,
        shadowIntensity: ShadowIntensity = .medium,
        borderLuminance: Double = 0.2,
        cornerRadius: CGFloat = 14 // Default value instead of Layout.cardCornerRadius
    ) {
        self.material = material
        self.shadowIntensity = shadowIntensity
        self.borderLuminance = borderLuminance
        self.cornerRadius = cornerRadius
    }

    /// Creates the shadow for the glass effect
    public func createShadow() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(CGFloat(shadowIntensity.opacity))
        shadow.shadowOffset = NSSize(width: 0, height: -shadowIntensity.offset)
        shadow.shadowBlurRadius = shadowIntensity.radius
        return shadow
    }

    /// Creates the secondary ambient shadow for depth
    public func createSecondaryShadow() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(CGFloat(shadowIntensity.secondaryOpacity))
        shadow.shadowOffset = NSSize(width: 0, height: -shadowIntensity.offset / 2)
        shadow.shadowBlurRadius = shadowIntensity.radius / 2
        return shadow
    }

    /// Creates the refractive border gradient
    public func createBorderColor() -> NSColor {
        return NSColor.white.withAlphaComponent(borderLuminance)
    }

    /// Returns appropriate material based on transparency setting
    public func effectiveMaterial(reduceTransparency: Bool) -> NSVisualEffectView.Material {
        return reduceTransparency ? .contentBackground : material
    }
}

// MARK: - Liquid Glass Container View

/// A container view with Liquid Glass styling for macOS
/// Provides proper depth, shadows, and refractive borders
public class LiquidGlassContainer: NSVisualEffectView {

    private var hoverTrackingArea: NSTrackingArea?
    private var isHovered: Bool = false
    private var primaryShadowLayer: CALayer?
    private var ambientShadowLayer: CALayer?

    private let materialConfig: LiquidGlassMaterial
    private let reducedTransparency: Bool

    public init(
        material: LiquidGlassMaterial = LiquidGlassMaterial()
    ) {
        self.materialConfig = material
        self.reducedTransparency = AppearanceManager.shared.isReduceTransparency
        super.init(frame: .zero)

        setupGlass()
    }

    required init?(coder: NSCoder) {
        self.materialConfig = LiquidGlassMaterial()
        self.reducedTransparency = AppearanceManager.shared.isReduceTransparency
        super.init(coder: coder)
        setupGlass()
    }

    private func setupGlass() {
        wantsLayer = true
        self.material = materialConfig.effectiveMaterial(reduceTransparency: reducedTransparency)
        blendingMode = .withinWindow
        state = .active

        // Apply corner radius
        layer?.cornerRadius = materialConfig.cornerRadius
        layer?.masksToBounds = false

        // Apply dual shadows for ambient occlusion effect
        setupDualShadows()
        setAccessibilityElement(false)

        // Apply border
        updateBorder()

        // Setup hover tracking
        setupHoverTracking()
    }

    private func setupDualShadows() {
        guard let layer = self.layer else { return }

        // Primary shadow
        let primaryShadow = CALayer()
        primaryShadow.shadowColor = NSColor.black.withAlphaComponent(CGFloat(materialConfig.shadowIntensity.opacity)).cgColor
        primaryShadow.shadowOffset = CGSize(width: 0, height: -materialConfig.shadowIntensity.offset)
        primaryShadow.shadowRadius = materialConfig.shadowIntensity.radius
        primaryShadow.shadowOpacity = Float(materialConfig.shadowIntensity.opacity)
        primaryShadow.frame = bounds
        layer.addSublayer(primaryShadow)
        self.primaryShadowLayer = primaryShadow

        // Secondary ambient shadow (softer, closer) - creates depth through ambient occlusion
        let ambientShadow = CALayer()
        ambientShadow.shadowColor = NSColor.black.withAlphaComponent(CGFloat(materialConfig.shadowIntensity.secondaryOpacity)).cgColor
        ambientShadow.shadowOffset = CGSize(width: 0, height: -materialConfig.shadowIntensity.offset / 2)
        ambientShadow.shadowRadius = materialConfig.shadowIntensity.radius / 2
        ambientShadow.shadowOpacity = Float(materialConfig.shadowIntensity.secondaryOpacity)
        ambientShadow.frame = bounds
        layer.insertSublayer(ambientShadow, at: 0)
        self.ambientShadowLayer = ambientShadow

        // Apply shadow to the view itself
        shadow = materialConfig.createShadow()
    }

    public override func layout() {
        super.layout()
        primaryShadowLayer?.frame = bounds
        ambientShadowLayer?.frame = bounds
    }

    private func updateBorder() {
        let borderColor = NSColor.white.withAlphaComponent(
            isHovered ? materialConfig.borderLuminance * 1.5 : materialConfig.borderLuminance
        )
        layer?.borderColor = borderColor.cgColor
        layer?.borderWidth = 1.0
    }

    private func setupHoverTracking() {
        let options: NSTrackingArea.Options = [.mouseMoved, .activeInActiveApp, .inVisibleRect]
        hoverTrackingArea = NSTrackingArea(
            rect: .zero,
            options: options,
            owner: self,
            userInfo: nil
        )
        addTrackingArea(hoverTrackingArea!)
    }

    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isHovered = true
        updateBorder()
    }

    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
        updateBorder()
    }

    /// Updates the glass appearance when accessibility settings change
    public func updateAppearance() {
        self.material = materialConfig.effectiveMaterial(reduceTransparency: AppearanceManager.shared.isReduceTransparency)
        needsDisplay = true
    }
}

// MARK: - Settings Section Header

/// A styled section header for settings panes with proper typography and spacing
public class SettingsSectionHeader: NSView {

    private let titleLabel: NSTextField

    public init(title: String) {
        self.titleLabel = NSTextField(labelWithString: title.uppercased())
        super.init(frame: .zero)
        setupHeader()
    }

    required init?(coder: NSCoder) {
        self.titleLabel = NSTextField(labelWithString: "")
        super.init(coder: coder)
        setupHeader()
    }

    private func setupHeader() {
        translatesAutoresizingMaskIntoConstraints = false

        // Configure title label
        titleLabel.font = Typography.caption1
        titleLabel.textColor = Colors.secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setAccessibilityRole(.staticText)
        titleLabel.setAccessibilityLabel(titleLabel.stringValue)

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.pt4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.pt4),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
    }
}

// MARK: - Liquid Glass Checkbox Row

/// A complete checkbox row with label, description, and proper accessibility
public class LiquidGlassCheckboxRow: NSView {

    private let checkbox: NSButton
    private let titleLabel: NSTextField?
    private let descriptionLabel: NSTextField?

    public init(
        title: String,
        description: String? = nil,
        initialState: NSControl.StateValue = .off,
        action: Selector?,
        target: Any? = nil
    ) {
        // Create checkbox
        self.checkbox = NSButton(checkboxWithTitle: title, target: target, action: action)
        self.checkbox.state = initialState

        // Create title label (if separate from checkbox)
        self.titleLabel = nil

        // Create description label
        if let description = description {
            self.descriptionLabel = NSTextField(wrappingLabelWithString: description)
        } else {
            self.descriptionLabel = nil
        }

        super.init(frame: .zero)
        setupRow()
    }

    required init?(coder: NSCoder) {
        self.checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        self.titleLabel = nil
        self.descriptionLabel = nil
        super.init(coder: coder)
        setupRow()
    }

    private func setupRow() {
        translatesAutoresizingMaskIntoConstraints = false

        // Configure checkbox
        checkbox.font = Typography.body
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkbox)

        // Configure description
        if let description = descriptionLabel {
            description.font = Typography.caption1
            description.textColor = Colors.secondaryLabel
            description.translatesAutoresizingMaskIntoConstraints = false
            description.lineBreakMode = .byWordWrapping
            description.cell?.wraps = true
            description.cell?.isScrollable = false
            description.setAccessibilityRole(.staticText)
            addSubview(description)
        }

        setupConstraints()
        setupAccessibility()
    }

    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = [
            checkbox.topAnchor.constraint(equalTo: topAnchor),
            checkbox.leadingAnchor.constraint(equalTo: leadingAnchor),
            checkbox.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]

        if let description = descriptionLabel {
            constraints += [
                description.topAnchor.constraint(equalTo: checkbox.bottomAnchor, constant: Spacing.pt4),
                description.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.pt20),
                description.trailingAnchor.constraint(equalTo: trailingAnchor),
                description.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        } else {
            constraints.append(
                checkbox.bottomAnchor.constraint(equalTo: bottomAnchor)
            )
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func setupAccessibility() {
        let title = checkbox.title

        // Use compound label for checkbox with description
        // This provides complete context in one announcement
        if let description = descriptionLabel {
            let combinedLabel = "\(title). \(description.stringValue)"
            checkbox.setAccessibilityLabel(combinedLabel)
        } else {
            checkbox.setAccessibilityLabel(title)
        }

        // Help should explain impact, not repeat label
        // Only add help if there's meaningful additional context
        if let description = descriptionLabel {
            checkbox.setAccessibilityHelp("This setting affects how Notimanager handles notifications")
        }

        // Set proper role for clarity
        checkbox.setAccessibilityRole(.checkBox)

        // Description label should not be separately accessible
        // as its content is already included in the checkbox label
        descriptionLabel?.setAccessibilityElement(false)
    }

    /// Returns the checkbox button for external reference
    public var checkboxButton: NSButton {
        return checkbox
    }
}

// MARK: - Liquid Glass Button

/// A styled button with Liquid Glass appearance
public class LiquidGlassButton: NSButton {

    private var isHovered: Bool = false
    private var isPressed: Bool = false

    public init(title: String, isPrimary: Bool = false, target: Any?, action: Selector?) {
        super.init(frame: .zero)
        self.title = title
        self.target = target as? AnyObject
        self.action = action
        setupButton(isPrimary: isPrimary)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton(isPrimary: false)
    }

    private func setupButton(isPrimary: Bool) {
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 10.14, *) {
            bezelStyle = isPrimary ? .rounded : .regularSquare
            keyEquivalent = isPrimary ? "\r" : ""
        }

        font = Typography.body
        sizeToFit()

        setupHoverTracking()
    }

    private func setupHoverTracking() {
        let options: NSTrackingArea.Options = [.mouseMoved, .activeInActiveApp, .inVisibleRect]
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: options,
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard !isPressed else { return }
        isHovered = true
        updateHoverState()
    }

    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
        updateHoverState()
    }

    private func updateHoverState() {
        layer?.backgroundColor = isHovered ? NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor : NSColor.clear.cgColor
    }
}

// MARK: - Liquid Glass Separator

/// A styled separator that respects system appearance
public class LiquidGlassSeparator: NSBox {

    public init() {
        super.init(frame: .zero)
        setupSeparator()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSeparator()
    }

    private func setupSeparator() {
        boxType = .separator
        translatesAutoresizingMaskIntoConstraints = false
    }
}

// MARK: - SwiftUI Integration

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI wrapper for Liquid Glass material
@available(macOS 11.0, *)
public struct LiquidGlassMaterialView: ViewModifier {
    let material: NSVisualEffectView.Material
    let shadowIntensity: LiquidGlassMaterial.ShadowIntensity
    let borderLuminance: Double
    let cornerRadius: CGFloat

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isHovered = false

    public init(
        material: NSVisualEffectView.Material = .titlebar,
        shadowIntensity: LiquidGlassMaterial.ShadowIntensity = .medium,
        borderLuminance: Double = 0.2,
        cornerRadius: CGFloat = 14 // Default value instead of Layout.cardCornerRadius
    ) {
        self.material = material
        self.shadowIntensity = shadowIntensity
        self.borderLuminance = borderLuminance
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(reduceTransparency ? Color(nsColor: .windowBackgroundColor) : Color(nsColor: .controlBackgroundColor).opacity(0.8))
                    .shadow(
                        color: Color.black.opacity(isHovered ? shadowIntensity.opacity * 1.2 : shadowIntensity.opacity),
                        radius: isHovered ? shadowIntensity.radius * 1.2 : shadowIntensity.radius,
                        y: isHovered ? shadowIntensity.offset * 1.2 : shadowIntensity.offset
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(isHovered ? borderLuminance * 1.5 : borderLuminance),
                                .white.opacity((isHovered ? borderLuminance * 1.5 : borderLuminance) * 0.5),
                                .white.opacity((isHovered ? borderLuminance * 1.5 : borderLuminance) * 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

@available(macOS 11.0, *)
public extension View {
    /// Applies Liquid Glass material styling to the view
    func liquidGlassMaterial(
        material: NSVisualEffectView.Material = .titlebar,
        shadowIntensity: LiquidGlassMaterial.ShadowIntensity = .medium,
        borderLuminance: Double = 0.2,
        cornerRadius: CGFloat = 14
    ) -> some View {
        modifier(LiquidGlassMaterialView(
            material: material,
            shadowIntensity: shadowIntensity,
            borderLuminance: borderLuminance,
            cornerRadius: cornerRadius
        ))
    }
}

#endif
