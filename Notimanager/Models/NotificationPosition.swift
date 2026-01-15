//
//  NotificationPosition.swift
//  Notimanager
//
//  Created on 2025-11-16.
//  Refactored on 2025-01-15 to add icon and grid position properties
//

import Foundation

enum NotificationPosition: String, CaseIterable, Codable {
    case topLeft = "top-left"
    case topMiddle = "top-middle"
    case topRight = "top-right"
    case middleLeft = "middle-left"
    case deadCenter = "dead-center"
    case middleRight = "middle-right"
    case bottomLeft = "bottom-left"
    case bottomMiddle = "bottom-middle"
    case bottomRight = "bottom-right"

    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topMiddle: return "Top Middle"
        case .topRight: return "Top Right"
        case .middleLeft: return "Middle Left"
        case .deadCenter: return "Center"
        case .middleRight: return "Middle Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomMiddle: return "Bottom Middle"
        case .bottomRight: return "Bottom Right"
        }
    }

    var iconName: String {
        switch self {
        case .topLeft: return "arrow.up.left"
        case .topMiddle: return "arrow.up"
        case .topRight: return "arrow.up.right"
        case .middleLeft: return "arrow.left"
        case .deadCenter: return "circle.fill"
        case .middleRight: return "arrow.right"
        case .bottomLeft: return "arrow.down.left"
        case .bottomMiddle: return "arrow.down"
        case .bottomRight: return "arrow.down.right"
        }
    }

    var gridPosition: (row: Int, col: Int) {
        switch self {
        case .topLeft: return (0, 0)
        case .topMiddle: return (0, 1)
        case .topRight: return (0, 2)
        case .middleLeft: return (1, 0)
        case .deadCenter: return (1, 1)
        case .middleRight: return (1, 2)
        case .bottomLeft: return (2, 0)
        case .bottomMiddle: return (2, 1)
        case .bottomRight: return (2, 2)
        }
    }
}
