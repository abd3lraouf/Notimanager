//
//  SettingsPaneIdentifier+Extensions.swift
//  Notimanager
//
//  Extension for Settings.PaneIdentifier following MonitorControl pattern
//

import Foundation
import Settings

// MARK: - Settings.PaneIdentifier Extension

extension Settings.PaneIdentifier {
    /// General settings pane identifier
    static let general = Self("general")

    /// Interception settings pane identifier
    static let interception = Self("interception")

    /// Position settings pane identifier
    static let position = Self("position")

    /// About settings pane identifier
    static let about = Self("about")
}
