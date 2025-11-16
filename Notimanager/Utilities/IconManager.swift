//
//  IconManager.swift
//  Notimanager
//
//  Manages app icon states and menu bar icon updates
//  Uses Streamline Plump bell icons (CC BY 4.0)
//

import AppKit

/// Manages app icon and menu bar icon states
class IconManager {

    // MARK: - Singleton

    static let shared = IconManager()

    private init() {}

    // MARK: - Properties

    private var currentIconState: IconState = .default

    // MARK: - Icon States

    enum IconState {
        case `default`    // Blue - normal state
        case enabled      // Green - positioning active
        case disabled     // Gray - positioning disabled
        case notification // Blue with red dot - detecting notifications
    }

    // MARK: - App Icon

    /// Updates the app icon based on current state
    /// - Parameter state: The icon state to display
    func updateAppIcon(to state: IconState) {
        guard state != currentIconState else { return }

        let iconName: String
        switch state {
        case .default:
            iconName = "AppIcon"
        case .enabled:
            iconName = "AppIcon-Enabled"
        case .disabled:
            iconName = "AppIcon-Disabled"
        case .notification:
            iconName = "AppIcon-Notification"
        }

        if let icon = NSImage(named: iconName) {
            NSApplication.shared.applicationIconImage = icon
            currentIconState = state
        }
    }

    /// Resets app icon to default state
    func resetAppIcon() {
        updateAppIcon(to: .default)
    }

    // MARK: - Menu Bar Icon

    /// Gets the appropriate menu bar icon for current state
    /// - Parameter isEnabled: Whether app is enabled
    /// - Returns: NSImage for menu bar (template style for dark/light mode)
    func getMenuBarIcon(isEnabled: Bool) -> NSImage? {
        let iconName = "MenuBarIcon"

        guard let icon = NSImage(named: iconName) else {
            return nil
        }

        // Template style means monochrome that adapts to dark/light mode
        icon.isTemplate = true

        return icon
    }

    /// Creates a menu bar icon with notification badge overlay
    /// - Parameter isEnabled: Whether app is enabled
    /// - Returns: NSImage with notification dot overlay
    func getMenuBarIconWithNotification(isEnabled: Bool) -> NSImage? {
        guard let baseIcon = getMenuBarIcon(isEnabled: isEnabled) else {
            return nil
        }

        let size = NSSize(width: 22, height: 22)
        let composedImage = NSImage(size: size)

        composedImage.lockFocus()

        // Draw base icon (non-template for composed image)
        baseIcon.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: baseIcon.size),
            operation: .copy,
            fraction: 1.0
        )

        // Draw notification dot (red circle with white border)
        let dotSize: CGFloat = 6
        let dotOrigin = NSPoint(x: size.width - dotSize, y: 0)

        let dotPath = NSBezierPath(ovalIn: NSRect(
            origin: dotOrigin,
            size: NSSize(width: dotSize, height: dotSize)
        ))

        NSColor.systemRed.setFill()
        dotPath.fill()

        // White border for visibility
        NSColor.white.setStroke()
        dotPath.lineWidth = 1.5
        dotPath.stroke()

        composedImage.unlockFocus()

        composedImage.isTemplate = false

        return composedImage
    }

    // MARK: - Alternative Filled Bell Icon

    /// Creates a filled bell icon using the Streamline filled design
    /// - Parameters:
    ///   - color: The fill/stroke color
    ///   - fillOpacity: Opacity of the fill (0.0-1.0)
    ///   - size: Icon size
    /// - Returns: NSImage with filled bell design
    func createFilledBellIcon(color: NSColor, fillOpacity: CGFloat = 0.15, size: NSSize = NSSize(width: 48, height: 48)) -> NSImage {
        let image = NSImage(size: size)

        image.lockFocus()

        let fillColor = color.withAlphaComponent(fillOpacity)

        // Draw bell body with fill
        let bellPath = NSBezierPath()
        bellPath.move(to: NSPoint(x: 24, y: 10))  // Top center
        bellPath.line(to: NSPoint(x: 24, y: 28))  // Middle
        bellPath.line(to: NSPoint(x: 44.789, y: 28)) // Right edge
        bellPath.line(to: NSPoint(x: 44.789, y: 28)) // Continue
        bellPath.line(to: NSPoint(x: 42, y: 42))   // Bottom right

        // Simplified bell shape
        let rect = NSRect(x: 4, y: 4, width: 40, height: 38)
        let roundedPath = NSBezierPath(roundedRect: rect, xRadius: 20, yRadius: 19)

        fillColor.setFill()
        roundedPath.fill()

        color.setStroke()
        roundedPath.lineWidth = 2.5
        roundedPath.stroke()

        // Draw clapper line
        let clapperPath = NSBezierPath()
        clapperPath.move(to: NSPoint(x: 18, y: 4))
        clapperPath.line(to: NSPoint(x: 30, y: 4))
        clapperPath.lineWidth = 2.5
        clapperPath.stroke()

        image.unlockFocus()

        return image
    }

    // MARK: - Position Indicator Icons

    /// Creates a small visual indicator showing notification position
    /// - Parameter position: The notification position
    /// - Returns: NSImage with position indicator
    func createPositionIndicator(for position: NotificationPosition) -> NSImage {
        let size = NSSize(width: 32, height: 32)
        let image = NSImage(size: size)

        image.lockFocus()

        // Draw background (rounded square)
        let bgRect = NSRect(origin: .zero, size: size)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 6, yRadius: 6)

        NSColor.windowBackgroundColor.setFill()
        bgPath.fill()

        NSColor.separatorColor.setStroke()
        bgPath.lineWidth = 1
        bgPath.stroke()

        // Draw position indicator (bell icon at correct position)
        let indicatorSize: CGFloat = 12
        var indicatorOrigin: NSPoint

        // Padding from edge
        let padding: CGFloat = 4

        switch position {
        case .topLeft:
            indicatorOrigin = NSPoint(x: padding, y: size.height - indicatorSize - padding)
        case .topMiddle:
            indicatorOrigin = NSPoint(x: (size.width - indicatorSize) / 2, y: size.height - indicatorSize - padding)
        case .topRight:
            indicatorOrigin = NSPoint(x: size.width - indicatorSize - padding, y: size.height - indicatorSize - padding)
        case .middleLeft:
            indicatorOrigin = NSPoint(x: padding, y: (size.height - indicatorSize) / 2)
        case .deadCenter:
            indicatorOrigin = NSPoint(x: (size.width - indicatorSize) / 2, y: (size.height - indicatorSize) / 2)
        case .middleRight:
            indicatorOrigin = NSPoint(x: size.width - indicatorSize - padding, y: (size.height - indicatorSize) / 2)
        case .bottomLeft:
            indicatorOrigin = NSPoint(x: padding, y: padding)
        case .bottomMiddle:
            indicatorOrigin = NSPoint(x: (size.width - indicatorSize) / 2, y: padding)
        case .bottomRight:
            indicatorOrigin = NSPoint(x: size.width - indicatorSize - padding, y: padding)
        }

        // Draw small bell indicator
        let indicatorRect = NSRect(origin: indicatorOrigin, size: NSSize(width: indicatorSize, height: indicatorSize))
        let bellPath = NSBezierPath(ovalIn: indicatorRect)

        NSColor.systemBlue.setFill()
        bellPath.fill()

        image.unlockFocus()

        return image
    }

    // MARK: - Status Icons

    /// Creates a status indicator icon (green/red circle)
    /// - Parameter isActive: Whether status is active
    /// - Returns: NSImage with status indicator
    func createStatusIcon(isActive: Bool) -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)

        image.lockFocus()

        let circlePath = NSBezierPath(ovalIn: NSRect(origin: .zero, size: size))

        if isActive {
            NSColor.systemGreen.setFill()
        } else {
            NSColor.systemRed.setFill()
        }

        circlePath.fill()

        image.unlockFocus()

        return image
    }

    /// Creates a small dot indicator (for status bar, etc)
    /// - Parameters:
    ///   - color: Dot color
    ///   - size: Dot diameter
    /// - Returns: NSImage with dot
    func createDotIndicator(color: NSColor, size: CGFloat = 8) -> NSImage {
        let imageSize = NSSize(width: size, height: size)
        let image = NSImage(size: imageSize)

        image.lockFocus()

        let dotPath = NSBezierPath(ovalIn: NSRect(origin: .zero, size: imageSize))
        color.setFill()
        dotPath.fill()

        image.unlockFocus()

        return image
    }
}
