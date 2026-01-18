//
//  NotificationPositioningService.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Service for calculating notification positions based on current settings.
//  Extracted from NotificationMover to separate positioning logic.
//

import AppKit
import Foundation

/// Service for calculating notification positions based on current settings
@available(macOS 10.15, *)
class NotificationPositioningService {

    // MARK: - Singleton

    static let shared = NotificationPositioningService()

    private init() {}

    // MARK: - Position Calculation

    /// Calculates the target position for a notification
    /// - Parameters:
    ///   - notifSize: The size of the notification
    ///   - padding: The padding from screen edges
    ///   - currentPosition: The desired position
    ///   - screenBounds: The screen bounds (defaults to main screen)
    /// - Returns: A CGPoint representing the target position
    func calculatePosition(
        notifSize: CGSize,
        padding: CGFloat,
        currentPosition: NotificationPosition,
        screenBounds: CGRect = NSScreen.main!.frame
    ) -> CGPoint {

        // 1. Identify Target Screen
        let screen = NSScreen.screens.first { $0.frame.contains(screenBounds.origin) } ?? NSScreen.main!
        
        // 2. Delegate to pure calculation method
        return calculatePosition(
            currentPosition: currentPosition,
            notifSize: notifSize,
            padding: padding,
            visibleFrame: screen.visibleFrame,
            fullFrame: screen.frame
        )
    }

    /// Internal pure calculation method (testable)
    func calculatePosition(
        currentPosition: NotificationPosition,
        notifSize: CGSize,
        padding: CGFloat,
        visibleFrame: CGRect,
        fullFrame: CGRect
    ) -> CGPoint {
        
        // Detailed Debug Logging
        LoggingService.shared.debug("--- Position Calculation Start ---", category: "Positioning")
        LoggingService.shared.debug("Target Position: \(currentPosition.displayName)", category: "Positioning")
        LoggingService.shared.debug("Notification Size: \(Int(notifSize.width))x\(Int(notifSize.height))", category: "Positioning")
        LoggingService.shared.debug("Padding: \(Int(padding))", category: "Positioning")

        // Use the Strategy Pattern (OCP)
        let strategy = PositionStrategyFactory.makeStrategy(for: currentPosition)
        let point = strategy.calculatePosition(
            notifSize: notifSize,
            padding: padding,
            visibleFrame: visibleFrame,
            fullFrame: fullFrame
        )

        LoggingService.shared.debug("Calculated Position: (\(Int(point.x)), \(Int(point.y)))", category: "Positioning")
        LoggingService.shared.debug("--- Position Calculation End ---", category: "Positioning")

        return point
    }

    /// Validates if a position is within screen bounds
    /// - Parameters:
    ///   - position: The position to validate
    ///   - notifSize: The notification size
    ///   - screenBounds: The screen bounds
    /// - Returns: True if valid, false otherwise
    func validatePosition(
        _ position: CGPoint,
        for notifSize: CGSize,
        in screenBounds: CGRect
    ) -> Bool {

        // Check if position is within screen bounds with padding consideration
        let minX: CGFloat = 20 // Minimum margin from left edge
        let maxX: CGFloat = screenBounds.width - 20 // Minimum margin from right edge

        let minY: CGFloat = 20 // Minimum margin from top edge
        let maxY: CGFloat = screenBounds.height - 20 // Minimum margin from bottom edge

        let isValidX = (position.x >= minX && position.x <= maxX &&
                       position.x + notifSize.width <= maxX + 20) // Allow some overflow
        let isValidY = (position.y >= minY && position.y <= maxY &&
                       position.y + notifSize.height <= maxY + 20)

        return isValidX && isValidY
    }

    /// Applies a position to a notification element
    /// - Parameters:
    ///   - element: The AXUIElement to position
    ///   - position: The target position
    /// - Returns: True if successful
    func applyPosition(to element: AXUIElement, at position: CGPoint) -> Bool {
        AXElementManager.shared.setPosition(of: element, x: position.x, y: position.y)
    }

    // MARK: - Position Calculation Helpers

    /// Calculates position with automatic padding detection
    /// - Parameters:
    ///   - notifSize: The notification size
    ///   - currentPosition: The current position setting
    ///   - screenBounds: The screen bounds
    ///   - paddingAboveDock: Padding above dock (from config)
    /// - Returns: Calculated position
    func calculatePositionWithAutoPadding(
        notifSize: CGSize,
        currentPosition: NotificationPosition,
        screenBounds: CGRect = NSScreen.main!.frame,
        paddingAboveDock: CGFloat = 30
    ) -> CGPoint {

        return calculatePosition(
            notifSize: notifSize,
            padding: getPaddingForPosition(currentPosition, screenSize: screenBounds.size),
            currentPosition: currentPosition,
            screenBounds: screenBounds
        )
    }

    /// Gets the appropriate padding for a position
    /// - Parameters:
    ///   - position: The position setting
    ///   - screenSize: The screen size
    /// - Returns: Padding value for that position
    func getPaddingForPosition(
        _ position: NotificationPosition,
        screenSize: CGSize
    ) -> CGFloat {

        // Dynamic padding based on screen size
        let basePadding: CGFloat = 30

        switch position {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return basePadding
        }
    }

    /// Gets the dock height for position calculation
    /// - Returns: The dock height in points
    func getDockHeight() -> CGFloat {
        // Use visible frame origin to get actual dock height
        return NSScreen.main!.visibleFrame.origin.y
    }

    // MARK: - Stacked Position Calculation

    /// Calculates the target position for a notification with stacking offset
    /// - Parameters:
    ///   - notifSize: The size of the notification
    ///   - padding: The padding from screen edges
    ///   - currentPosition: The desired position
    ///   - stackIndex: The index in the stack (0 = base position, 1 = first offset, etc.)
    ///   - stackSpacing: The vertical spacing between stacked notifications
    ///   - screenBounds: The screen bounds (defaults to main screen)
    /// - Returns: A CGPoint representing the target position with stack offset
    func calculateStackedPosition(
        notifSize: CGSize,
        padding: CGFloat,
        currentPosition: NotificationPosition,
        stackIndex: Int = 0,
        stackSpacing: CGFloat = 16,
        screenBounds: CGRect = NSScreen.main!.frame
    ) -> CGPoint {

        // Get the base position
        let basePosition = calculatePosition(
            notifSize: notifSize,
            padding: padding,
            currentPosition: currentPosition,
            screenBounds: screenBounds
        )

        // Apply stacking offset based on position
        // Each stacked notification needs full height + spacing to avoid overlap
        let totalOffset = (notifSize.height + stackSpacing) * CGFloat(stackIndex)
        
        let stackedY: CGFloat
        switch currentPosition {
        case .topLeft, .topRight:
            // For top positions: stack downward (increase Y in Quartz coordinates)
            // Newer notifications (index 0) at top, older ones pushed down
            stackedY = basePosition.y + totalOffset

        case .bottomLeft, .bottomRight:
            // For bottom positions: stack upward (decrease Y in Quartz coordinates)
            // Newer notifications (index 0) at bottom, older ones pushed up
            stackedY = basePosition.y - totalOffset
        }

        return CGPoint(x: basePosition.x, y: stackedY)
    }
}

// MARK: - Position Grid Extension

extension NotificationPosition {

    /// Convert grid position to screen coordinates
    /// - Parameters:
    ///   - gridPosition: The grid position (row, col)
    ///   - screenBounds: The screen bounds
    ///   - notifSize: The notification size
    ///   - padding: Padding from edges
    /// - Returns: Screen coordinates for the position
    func toScreenCoordinates(
        gridPosition: (row: Int, col: Int),
        screenBounds: CGRect,
        notifSize: CGSize,
        padding: CGFloat
    ) -> CGPoint {

        // 1. Identify Target Screen
        let screen = NSScreen.screens.first { $0.frame.contains(screenBounds.origin) } ?? NSScreen.main!
        
        // 2. Get Metrics
        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        
        // 3. Convert Boundaries
        let safeTop = fullFrame.maxY - visibleFrame.maxY
        let safeBottom = fullFrame.maxY - visibleFrame.minY
        let safeLeft = visibleFrame.minX
        let safeRight = visibleFrame.maxX
        let safeWidth = visibleFrame.width
        let safeHeight = visibleFrame.height
        
        let newX: CGFloat
        let newY: CGFloat

        // 4. Calculate X
        switch gridPosition.col {
        case 0: // Left
            newX = safeLeft + padding
        case 1: // Center
            newX = safeLeft + (safeWidth - notifSize.width) / 2
        case 2: // Right
            newX = safeRight - notifSize.width - padding
        default: 
            newX = 0
        }

        // 5. Calculate Y
        switch gridPosition.row {
        case 0: // Top
            newY = safeTop + padding
        case 1: // Middle
            newY = safeTop + (safeHeight - notifSize.height) / 2
        case 2: // Bottom
            newY = safeBottom - notifSize.height - padding
        default: 
            newY = 0
        }

        return CGPoint(x: newX, y: newY)
    }

    /// Get screen position from grid position
    /// - Parameters:
    ///   - screenBounds: The screen bounds
    ///   - notifSize: The notification size
    ///   - padding: Padding from edges
    /// - Returns: Screen coordinates
    func toScreenCoordinates(
        screenBounds: CGRect,
        notifSize: CGSize,
        padding: CGFloat = 30
    ) -> CGPoint {

        return toScreenCoordinates(
            gridPosition: gridPosition,
            screenBounds: screenBounds,
            notifSize: notifSize,
            padding: padding
        )
    }
}
