//
//  AnimationHelper.swift
//  Notimanager
//
//  Provides consistent animation utilities with respect to
//  accessibility preferences (reduce motion).
//

import AppKit

/// Helper class for creating consistent, accessible animations
class AnimationHelper {

    // MARK: - Fade Animations

    /// Animates the opacity of a view
    /// - Parameters:
    ///   - view: The view to animate
    ///   - toAlpha: The target opacity
    ///   - duration: Animation duration (uses default if not specified)
    ///   - completion: Optional completion handler
    static func fade(
        _ view: NSView,
        to alpha: CGFloat,
        duration: TimeInterval = Animation.normal,
        completion: (() -> Void)? = nil
    ) {
        AppearanceManager.shared.animateIfNeeded {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = AppearanceManager.shared.adaptiveDuration(normal: duration)
                context.timingFunction = Animation.easeInEaseOut
                view.animator().alphaValue = alpha
            }
            completion?()
        }
    }

    /// Fades a view in
    /// - Parameters:
    ///   - view: The view to fade in
    ///   - duration: Animation duration
    ///   - completion: Optional completion handler
    static func fadeIn(
        _ view: NSView,
        duration: TimeInterval = Animation.normal,
        completion: (() -> Void)? = nil
    ) {
        view.alphaValue = 0
        fade(view, to: 1.0, duration: duration, completion: completion)
    }

    /// Fades a view out
    /// - Parameters:
    ///   - view: The view to fade out
    ///   - duration: Animation duration
    ///   - completion: Optional completion handler
    static func fadeOut(
        _ view: NSView,
        duration: TimeInterval = Animation.normal,
        completion: (() -> Void)? = nil
    ) {
        fade(view, to: 0.0, duration: duration, completion: completion)
    }

    // MARK: - Scale Animations

    /// Animates the scale of a view
    /// - Parameters:
    ///   - view: The view to scale
    ///   - scale: The target scale
    ///   - duration: Animation duration
    ///   - completion: Optional completion handler
    static func scale(
        _ view: NSView,
        to scale: CGFloat,
        duration: TimeInterval = Animation.fast,
        completion: (() -> Void)? = nil
    ) {
        AppearanceManager.shared.animateIfNeeded {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = AppearanceManager.shared.adaptiveDuration(normal: duration)
                context.timingFunction = Animation.easeInEaseOut
                context.allowsImplicitAnimation = true

                let transform = CGAffineTransform(scaleX: scale, y: scale)
                view.layer?.setAffineTransform(transform)
            }
            completion?()
        }
    }

    /// Scales a view up (pop effect)
    static func scaleUp(_ view: NSView, completion: (() -> Void)? = nil) {
        scale(view, to: 1.05, duration: Animation.fast) {
            scale(view, to: 1.0, duration: Animation.fast, completion: completion)
        }
    }

    /// Scales a view down (press effect)
    static func scaleDown(_ view: NSView, completion: (() -> Void)? = nil) {
        scale(view, to: 0.95, duration: Animation.fast) {
            scale(view, to: 1.0, duration: Animation.fast, completion: completion)
        }
    }

    // MARK: - Position Animations

    /// Animates the position of a view
    /// - Parameters:
    ///   - view: The view to animate
    ///   - toPoint: The target position
    ///   - duration: Animation duration
    ///   - completion: Optional completion handler
    static func position(
        _ view: NSView,
        to point: CGPoint,
        duration: TimeInterval = Animation.normal,
        completion: (() -> Void)? = nil
    ) {
        AppearanceManager.shared.animateIfNeeded {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = AppearanceManager.shared.adaptiveDuration(normal: duration)
                context.timingFunction = Animation.defaultCurve
                view.animator().setFrameOrigin(point)
            }
            completion?()
        }
    }

    /// Animates the frame of a view
    /// - Parameters:
    ///   - view: The view to animate
    ///   - toFrame: The target frame
    ///   - duration: Animation duration
    ///   - completion: Optional completion handler
    static func frame(
        _ view: NSView,
        to toFrame: NSRect,
        duration: TimeInterval = Animation.normal,
        completion: (() -> Void)? = nil
    ) {
        AppearanceManager.shared.animateIfNeeded {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = AppearanceManager.shared.adaptiveDuration(normal: duration)
                context.timingFunction = Animation.defaultCurve
                view.animator().frame = toFrame
            }
            completion?()
        }
    }

    // MARK: - Spring Animations

    /// Performs a spring animation
    /// - Parameters:
    ///   - changes: The changes to animate
    ///   - completion: Optional completion handler
    static func spring(_ changes: @escaping () -> Void, completion: (() -> Void)? = nil) {
        AppearanceManager.shared.animateIfNeeded {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Animation.springResponse
                context.timingFunction = CASpringTimingFunction(
                    dampingRatio: Animation.springDamping,
                    initialResponse: Animation.springResponse
                )
                context.allowsImplicitAnimation = true
                changes()
            }
            completion?()
        }
    }

    // MARK: - Composite Animations

    /// Performs multiple animations simultaneously
    /// - Parameters:
    ///   - duration: Animation duration
    ///   - animations: Array of animation blocks
    ///   - completion: Optional completion handler
    static func parallel(
        duration: TimeInterval = Animation.normal,
        animations: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        AppearanceManager.shared.animateIfNeeded {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = AppearanceManager.shared.adaptiveDuration(normal: duration)
                context.timingFunction = Animation.easeInEaseOut
                context.allowsImplicitAnimation = true
                animations()
            }
            completion?()
        }
    }

    /// Performs animations sequentially
    /// - Parameters:
    ///   - animations: Array of (duration, animation) tuples
    ///   - completion: Optional completion handler
    static func sequential(
        _ animations: [(duration: TimeInterval, animation: () -> Void)],
        completion: (() -> Void)? = nil
    ) {
        guard !animations.isEmpty else {
            completion?()
            return
        }

        let (duration, animation) = animations[0]
        let remaining = Array(animations.dropFirst())

        AppearanceManager.shared.animateIfNeeded {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = AppearanceManager.shared.adaptiveDuration(normal: duration)
                context.timingFunction = Animation.easeInEaseOut
                context.allowsImplicitAnimation = true
                animation()
            }
            if remaining.isEmpty {
                completion?()
            } else {
                sequential(remaining, completion: completion)
            }
        }
    }

    // MARK: - Transition Animations

    /// Performs a flip transition between two views
    /// - Parameters:
    ///   - fromView: The view to flip from
    ///   - toView: The view to flip to
    ///   - duration: Animation duration
    ///   - completion: Optional completion handler
    static func flip(
        from fromView: NSView,
        to toView: NSView,
        duration: TimeInterval = Animation.normal,
        completion: (() -> Void)? = nil
    ) {
        AppearanceManager.shared.animateIfNeeded {
            // Fade out from view
            fadeOut(fromView, duration: duration / 2) {
                // Swap views
                fromView.isHidden = true
                toView.isHidden = false
                // Fade in to view
                fadeIn(toView, duration: duration / 2, completion: completion)
            }
        }
    }

    /// Performs a crossfade between two views
    /// - Parameters:
    ///   - fromView: The view to crossfade from
    ///   - toView: The view to crossfade to
    ///   - duration: Animation duration
    ///   - completion: Optional completion handler
    static func crossfade(
        from fromView: NSView,
        to toView: NSView,
        duration: TimeInterval = Animation.normal,
        completion: (() -> Void)? = nil
    ) {
        AppearanceManager.shared.animateIfNeeded {
            toView.alphaValue = 0
            toView.isHidden = false

            NSAnimationContext.runAnimationGroup { context in
                context.duration = AppearanceManager.shared.adaptiveDuration(normal: duration)
                context.timingFunction = Animation.easeInEaseOut

                fromView.animator().alphaValue = 0
                toView.animator().alphaValue = 1
            }
            fromView.isHidden = true
            fromView.alphaValue = 1
            completion?()
        }
    }

    // MARK: - Delayed Execution

    /// Executes a block after a delay, respecting reduce motion
    /// - Parameters:
    ///   - delay: The delay time
    ///   - block: The block to execute
    static func delayed(delay: TimeInterval, block: @escaping () -> Void) {
        if AppearanceManager.shared.isReduceMotion {
            block()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
        }
    }
}

// MARK: - CASpringTimingFunction

/// Custom spring timing function for smooth animations
class CASpringTimingFunction: CAMediaTimingFunction {

    /// Creates a spring timing function
    /// - Parameters:
    ///   - dampingRatio: The damping ratio (0-1)
    ///   - initialResponse: The initial response time
    init(dampingRatio: CGFloat, initialResponse: CGFloat) {
        // Approximate spring behavior using cubic bezier
        let controlPoint1: Float = 0.25
        let controlPoint2: Float = 0.1 - (Float(dampingRatio) * 0.05)
        super.init(controlPoints: controlPoint1, controlPoint1, controlPoint2, controlPoint2)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: - NSView Extensions for Animation

extension NSView {

    /// Adds a spring animation to the view
    /// - Parameter changes: The changes to animate
    func springAnimate(_ changes: @escaping () -> Void, completion: (() -> Void)? = nil) {
        AnimationHelper.spring(changes, completion: completion)
    }

    /// Scales the view with a spring animation
    /// - Parameters:
    ///   - scale: The target scale
    ///   - completion: Optional completion handler
    func springScale(to scale: CGFloat, completion: (() -> Void)? = nil) {
        AnimationHelper.spring {
            self.layer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
        }
        completion?()
    }
}
