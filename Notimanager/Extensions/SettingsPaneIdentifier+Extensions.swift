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

    /// Advanced settings pane identifier
    static let advanced = Self("advanced")

    /// Interception settings pane identifier (uses position identifier for compatibility)
    static let position = Self("position")

    /// About settings pane identifier
    static let about = Self("about")
}
