//
//  ShadowHelper.swift
//  Notimanager
//
//  Consistent dual-shadow system for depth and ambient occlusion effects
//  Implements the 2026 Liquid Glass shadow standard
//

import AppKit
import QuartzCore

// MARK: - Shadow Helper

/// Helper class for creating consistent dual-shadow effects across the app
/// Implements ambient occlusion through layered shadows for proper depth perception
final class ShadowHelper {

    // MARK: - Shadow Styles

    /// Shadow intensity levels corresponding to elevation
    enum ShadowIntensity {
        case subtle    // 10pt elevation - badges, chips
        case medium    // 20pt elevation - cards, panels
        case strong    // 40pt elevation - modals, sheets
        case dramatic  // 60pt elevation - overlays, tooltips
    }

    // MARK: - Dual Shadow Application

    /// Applies a dual-shadow effect to a view's layer
    /// - Parameters:
    ///   - view: The view to apply shadows to
    ///   - intensity: The shadow intensity level
    ///   - animated: Whether to animate the shadow change
    static func applyDualShadow(to view: NSView, intensity: ShadowIntensity, animated: Bool = false) {
        if !view.wantsLayer {
            view.wantsLayer = true
            // Ensure layer is created before continuing
            view.layer = CALayer()
        }

        let shadowConfig = getShadowConfiguration(for: intensity)

        if animated {
            // Animate shadow changes
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Animation.fast
                context.allowsImplicitAnimation = true
                if let layer = view.layer {
                    updateLayerShadow(layer, primary: shadowConfig.primary, ambient: shadowConfig.ambient)
                }
            }
        } else {
            // Apply immediately
            if let layer = view.layer {
                updateLayerShadow(layer, primary: shadowConfig.primary, ambient: shadowConfig.ambient)
            }
        }
    }

    /// Removes shadows from a view
    static func removeShadow(from view: NSView, animated: Bool = false) {
        guard view.wantsLayer else { return }

        let removeBlock = {
            view.layer?.shadowColor = nil
            view.layer?.shadowOpacity = 0
            view.layer?.shadowRadius = 0
            view.layer?.shadowOffset = .zero

            // Remove ambient shadow layer if present
            view.layer?.sublayers?.removeAll(where: { $0.name == "ambientShadow" })
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Animation.fast
                context.allowsImplicitAnimation = true
                removeBlock()
            }
        } else {
            removeBlock()
        }
    }

    // MARK: - Private Helpers

    private static func updateLayerShadow(
        _ layer: CALayer,
        primary: ShadowConfig,
        ambient: ShadowConfig
    ) {
        // Apply primary shadow directly to the view's layer
        layer.shadowColor = primary.color.cgColor
        layer.shadowOffset = primary.offset
        layer.shadowRadius = primary.radius
        layer.shadowOpacity = Float(primary.opacity)

        // Add or update ambient shadow as a separate layer
        let ambientLayerName = "ambientShadow"

        // Remove existing ambient layer
        layer.sublayers?.removeAll(where: { $0.name == ambientLayerName })

        // Create new ambient shadow layer
        let ambientLayer = CALayer()
        ambientLayer.name = ambientLayerName
        ambientLayer.shadowColor = ambient.color.cgColor
        ambientLayer.shadowOffset = ambient.offset
        ambientLayer.shadowRadius = ambient.radius
        ambientLayer.shadowOpacity = Float(ambient.opacity)
        ambientLayer.frame = layer.bounds

        // Insert ambient shadow at the bottom
        layer.insertSublayer(ambientLayer, at: 0)
    }

    private static func getShadowConfiguration(for intensity: ShadowIntensity) -> (primary: ShadowConfig, ambient: ShadowConfig) {
        switch intensity {
        case .subtle:
            return (
                primary: ShadowConfig(
                    color: .black.withAlphaComponent(0.08),
                    offset: CGSize(width: 0, height: -2),
                    radius: 8,
                    opacity: 0.08
                ),
                ambient: ShadowConfig(
                    color: .black.withAlphaComponent(0.04),
                    offset: CGSize(width: 0, height: -1),
                    radius: 4,
                    opacity: 0.04
                )
            )

        case .medium:
            return (
                primary: ShadowConfig(
                    color: .black.withAlphaComponent(0.12),
                    offset: CGSize(width: 0, height: -4),
                    radius: 16,
                    opacity: 0.12
                ),
                ambient: ShadowConfig(
                    color: .black.withAlphaComponent(0.06),
                    offset: CGSize(width: 0, height: -2),
                    radius: 8,
                    opacity: 0.06
                )
            )

        case .strong:
            return (
                primary: ShadowConfig(
                    color: .black.withAlphaComponent(0.16),
                    offset: CGSize(width: 0, height: -8),
                    radius: 32,
                    opacity: 0.16
                ),
                ambient: ShadowConfig(
                    color: .black.withAlphaComponent(0.08),
                    offset: CGSize(width: 0, height: -4),
                    radius: 16,
                    opacity: 0.08
                )
            )

        case .dramatic:
            return (
                primary: ShadowConfig(
                    color: .black.withAlphaComponent(0.20),
                    offset: CGSize(width: 0, height: -12),
                    radius: 48,
                    opacity: 0.20
                ),
                ambient: ShadowConfig(
                    color: .black.withAlphaComponent(0.10),
                    offset: CGSize(width: 0, height: -6),
                    radius: 24,
                    opacity: 0.10
                )
            )
        }
    }

    // MARK: - Shadow Configuration

    private struct ShadowConfig {
        let color: NSColor
        let offset: CGSize
        let radius: CGFloat
        let opacity: Double
    }
}

// MARK: - CALayer Extension for Ambient Shadows

extension CALayer {

    /// Updates the ambient shadow layer when bounds change
    func updateAmbientShadowFrame() {
        guard let ambientLayer = sublayers?.first(where: { $0.name == "ambientShadow" }) else { return }
        ambientLayer.frame = bounds
    }
}

// MARK: - View Extensions for Easy Shadow Application

extension NSView {

    /// Apply subtle shadow (for badges, chips, raised buttons)
    func applySubtleShadow(animated: Bool = false) {
        ShadowHelper.applyDualShadow(to: self, intensity: .subtle, animated: animated)
    }

    /// Apply medium shadow (for cards, panels)
    func applyMediumShadow(animated: Bool = false) {
        ShadowHelper.applyDualShadow(to: self, intensity: .medium, animated: animated)
    }

    /// Apply strong shadow (for modals, sheets)
    func applyStrongShadow(animated: Bool = false) {
        ShadowHelper.applyDualShadow(to: self, intensity: .strong, animated: animated)
    }

    /// Apply dramatic shadow (for overlays, tooltips)
    func applyDramaticShadow(animated: Bool = false) {
        ShadowHelper.applyDualShadow(to: self, intensity: .dramatic, animated: animated)
    }

    /// Remove all shadows
    func removeShadow(animated: Bool = false) {
        ShadowHelper.removeShadow(from: self, animated: animated)
    }
}
