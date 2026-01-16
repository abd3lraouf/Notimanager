//
//  NotificationPosition.swift
//  Notimanager
//
//  Created on 2025-01-16.
//  Updated to use only 4 corner positions with directional menu icons
//

import Foundation

enum NotificationPosition: String, CaseIterable, Codable {
    case topLeft = "top-left"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomRight = "bottom-right"

    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }

    var iconName: String {
        switch self {
        case .topLeft: return "top-left"
        case .topRight: return "top-right"
        case .bottomLeft: return "bottom-left"
        case .bottomRight: return "bottom-right"
        }
    }

    var gridPosition: (row: Int, col: Int) {
        switch self {
        case .topLeft: return (0, 0)
        case .topRight: return (0, 1)
        case .bottomLeft: return (1, 0)
        case .bottomRight: return (1, 1)
        }
    }
}
