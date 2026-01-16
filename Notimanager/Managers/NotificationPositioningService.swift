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
        LoggingService.shared.debug("--- Position Calculation Start ---")
        LoggingService.shared.debug("Target Position: \(currentPosition.displayName)")
        LoggingService.shared.debug("Notification Size: \(Int(notifSize.width))x\(Int(notifSize.height))")
        LoggingService.shared.debug("Screen Full Frame: \(fullFrame)")
        LoggingService.shared.debug("Screen Visible Frame: \(visibleFrame)")
        LoggingService.shared.debug("Padding: \(padding)")
        
        // 3. Convert Safe Boundaries to Quartz Coordinates (Top-Left Origin)
        // Cocoa Y=0 is Bottom. Quartz Y=0 is Top.
        // Q_Y = ScreenTopY_Cocoa - PointY_Cocoa
        
        // Screen Top Y in Cocoa is fullFrame.maxY
        
        // SafeTop (Quartz) = Distance from screen top to visible area top
        // Q_SafeTop = fullFrame.maxY - visibleFrame.maxY
        let safeTop = fullFrame.maxY - visibleFrame.maxY
        
        // SafeBottom (Quartz) = Distance from screen top to visible area bottom
        // Q_SafeBottom = fullFrame.maxY - visibleFrame.minY
        let safeBottom = fullFrame.maxY - visibleFrame.minY
        
        // SafeLeft/SafeRight (X is same in both)
        let safeLeft = visibleFrame.minX
        let safeRight = visibleFrame.maxX
        
        let safeWidth = visibleFrame.width
        let safeHeight = visibleFrame.height
        
        LoggingService.shared.debug("Safe Margins (Quartz): Top=\(safeTop), Bottom=\(safeBottom), Left=\(safeLeft), Right=\(safeRight)")

        let newX: CGFloat
        let newY: CGFloat

        // 4. Calculate X (Horizontal)
        switch currentPosition {
        case .topLeft, .bottomLeft:
            // Left: SafeLeft + Padding
            newX = safeLeft + padding

        case .topRight, .bottomRight:
            // Right: SafeRight - BannerWidth - Padding
            newX = safeRight - notifSize.width - padding
        }

        // 5. Calculate Y (Vertical)
        switch currentPosition {
        case .topLeft, .topRight:
            // Top: SafeTop + Padding
            newY = safeTop + padding

        case .bottomLeft, .bottomRight:
            // Bottom: SafeBottom - BannerHeight - Padding
            newY = safeBottom - notifSize.height - padding
        }

        LoggingService.shared.debug("Calculated Position: (\(Int(newX)), \(Int(newY)))")
        LoggingService.shared.debug("--- Position Calculation End ---")

        return CGPoint(x: newX, y: newY)
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
