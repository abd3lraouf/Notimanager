//
//  SystemRepository.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Domain Layer: Interface for system-level operations.
//

import Foundation

protocol SystemRepository {
    func openSettings()
    func showAbout()
    func showDiagnostics()
    func showPermissions()
    func quitApp()
    func checkForUpdates()
    func donateActivity(type: ActivityType)
    func openLogsDirectory()
    func openConsoleApp()
    func showLogViewer()
}

enum ActivityType {
    case changePosition(NotificationPosition)
    case toggleEnabled(Bool) // Not used yet but good for completeness
}
