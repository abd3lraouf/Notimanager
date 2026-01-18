//
//  PositioningStrategy.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Implements OCP (Open/Closed Principle) for notification positioning.
//

import Foundation
import CoreGraphics

/// Protocol defining the strategy for calculating a notification's position.
/// Conforming types implement specific positioning logic (e.g. TopLeft, Center, Custom).
protocol PositioningStrategy {
    func calculatePosition(
        notifSize: CGSize,
        padding: CGFloat,
        visibleFrame: CGRect,
        fullFrame: CGRect
    ) -> CGPoint
}

// MARK: - Concrete Strategies

struct TopLeftStrategy: PositioningStrategy {
    func calculatePosition(notifSize: CGSize, padding: CGFloat, visibleFrame: CGRect, fullFrame: CGRect) -> CGPoint {
        let safeTop = fullFrame.maxY - visibleFrame.maxY
        let safeLeft = visibleFrame.minX
        
        let newX = safeLeft + padding
        let newY = safeTop + padding
        
        return CGPoint(x: newX, y: newY)
    }
}

struct TopRightStrategy: PositioningStrategy {
    func calculatePosition(notifSize: CGSize, padding: CGFloat, visibleFrame: CGRect, fullFrame: CGRect) -> CGPoint {
        let safeTop = fullFrame.maxY - visibleFrame.maxY
        let safeRight = visibleFrame.maxX
        
        let newX = safeRight - notifSize.width - padding
        let newY = safeTop + padding
        
        return CGPoint(x: newX, y: newY)
    }
}

struct BottomLeftStrategy: PositioningStrategy {
    func calculatePosition(notifSize: CGSize, padding: CGFloat, visibleFrame: CGRect, fullFrame: CGRect) -> CGPoint {
        let safeBottom = fullFrame.maxY - visibleFrame.minY
        let safeLeft = visibleFrame.minX
        
        let newX = safeLeft + padding
        let newY = safeBottom - notifSize.height - padding
        
        return CGPoint(x: newX, y: newY)
    }
}

struct BottomRightStrategy: PositioningStrategy {
    func calculatePosition(notifSize: CGSize, padding: CGFloat, visibleFrame: CGRect, fullFrame: CGRect) -> CGPoint {
        let safeBottom = fullFrame.maxY - visibleFrame.minY
        let safeRight = visibleFrame.maxX
        
        let newX = safeRight - notifSize.width - padding
        let newY = safeBottom - notifSize.height - padding
        
        return CGPoint(x: newX, y: newY)
    }
}

// MARK: - Strategy Factory

struct PositionStrategyFactory {
    static func makeStrategy(for position: NotificationPosition) -> PositioningStrategy {
        switch position {
        case .topLeft: return TopLeftStrategy()
        case .topRight: return TopRightStrategy()
        case .bottomLeft: return BottomLeftStrategy()
        case .bottomRight: return BottomRightStrategy()
        }
    }
}
