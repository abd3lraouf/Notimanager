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

        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        let dockSize = screenBounds.origin.y // Use visible frame origin to get dock height

        let newX: CGFloat
        let newY: CGFloat

        // Calculate X coordinate (horizontal position)
        switch currentPosition {
        case .topLeft, .middleLeft, .bottomLeft:
            newX = padding
        case .topMiddle, .bottomMiddle, .deadCenter:
            newX = (screenWidth - notifSize.width) / 2
        case .topRight, .middleRight, .bottomRight:
            newX = screenWidth - notifSize.width - padding
        }

        // Calculate Y coordinate (vertical position) - macOS uses bottom-left origin
        switch currentPosition {
        case .topLeft, .topMiddle, .topRight:
            newY = screenHeight - notifSize.height - padding
        case .middleLeft, .middleRight, .deadCenter:
            newY = (screenHeight - notifSize.height) / 2
        case .bottomLeft, .bottomMiddle, .bottomRight:
            newY = dockSize + 30 // paddingAboveDock constant
        }

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
        let basePadding: CGFloat = 20

        switch position {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return basePadding

        case .topMiddle, .bottomMiddle:
            return basePadding

        case .middleLeft, .middleRight:
            return basePadding + 10

        case .deadCenter:
            return basePadding + 20

        case .middleLeft, .middleRight:
            return basePadding + 30
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

        let xMargin: CGFloat
        let yMargin: CGFloat

        // Calculate X margin
        switch gridPosition.col {
        case 0: xMargin = padding
        case 1: xMargin = (screenBounds.width - notifSize.width) / 2
        case 2: xMargin = screenBounds.width - notifSize.width - padding
        default: xMargin = 0
        }

        // Calculate Y margin
        let dockSize = screenBounds.origin.y // Use visible frame origin to get dock height
        switch gridPosition.row {
        case 0: yMargin = screenBounds.height - notifSize.height - padding
        case 1: yMargin = (screenBounds.height - notifSize.height) / 2
        case 2: yMargin = dockSize + 30
        default: yMargin = 0
        }

        return CGPoint(x: xMargin, y: yMargin)
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
