//
//  MenuBarState.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  MVI State for MenuBar.
//

import Foundation
import SwiftUI // For Color

struct MenuBarState: Equatable {
    var isEnabled: Bool = true
    var currentPosition: NotificationPosition = .topRight
    var isMenuBarIconHidden: Bool = false
    var iconColor: IconColor = .normal

    // Derived State
    var iconName: String {
        let prefix = isEnabled ? "MenuBarIcon" : "MenuBarIcon-disabled"
        return prefix + "-" + currentPosition.iconName
    }
}
