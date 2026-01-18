//
//  SystemUseCases.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Domain Layer: Use cases for system actions.
//

import Foundation

class SystemUseCases {
    private let repository: SystemRepository
    
    init(repository: SystemRepository) {
        self.repository = repository
    }
    
    func openSettings() {
        repository.openSettings()
    }
    
    func showAbout() {
        repository.showAbout()
    }
    
    func showDiagnostics() {
        repository.showDiagnostics()
    }
    
    func showPermissions() {
        repository.showPermissions()
    }
    
    func quitApp() {
        repository.quitApp()
    }
    
    func checkForUpdates() {
        repository.checkForUpdates()
    }

    func openLogsDirectory() {
        repository.openLogsDirectory()
    }

    func openConsoleApp() {
        repository.openConsoleApp()
    }
    
    func showLogViewer() {
        repository.showLogViewer()
    }
}
