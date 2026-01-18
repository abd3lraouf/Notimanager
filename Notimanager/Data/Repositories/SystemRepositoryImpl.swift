//
//  SystemRepositoryImpl.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Data Layer: Implementation of SystemRepository.
//

import Foundation
import AppKit

class SystemRepositoryImpl: SystemRepository {
    
    // Dependencies
    private let coordinator: NotificationMoverCoordinator
    private let updateManager: UpdateManager
    private let activityManager: ActivityManager
    
    init(
        coordinator: NotificationMoverCoordinator = NotificationMover.shared.coordinator,
        updateManager: UpdateManager = .shared,
        activityManager: ActivityManager = .shared
    ) {
        self.coordinator = coordinator
        self.updateManager = updateManager
        self.activityManager = activityManager
    }
    
    func openSettings() {
        coordinator.showSettings()
    }
    
    func showAbout() {
        // Set the tab to 'help' (About screen) before opening settings
        UserDefaults.standard.set("help", forKey: "selectedSettingsTab")
        openSettings()
    }
    
    func showDiagnostics() {
        coordinator.showDiagnostics()
    }
    
    func showPermissions() {
        coordinator.showPermissionWindowFromSettings()
    }
    
    func quitApp() {
        coordinator.quit()
    }
    
    func checkForUpdates() {
        updateManager.checkForUpdates()
    }
    
    func donateActivity(type: ActivityType) {
        switch type {
        case .changePosition(let position):
            activityManager.donateChangePositionActivity(to: position)
        case .toggleEnabled(let enabled):
            activityManager.donateTogglePositioningActivity(isEnabled: enabled)
        }
    }

    func openLogsDirectory() {
        // Use LoggingService which will open the FileLogger's logs directory
        LoggingService.shared.openLogsDirectory()
    }

    func openConsoleApp() {
        // Open Console.app with the app's log stream filtered
        let bundleID = Bundle.main.bundleIdentifier ?? "dev.abd3lraouf.notimanager"
        let consoleAppURL = URL(fileURLWithPath: "/Applications/Utilities/Console.app")

        // Open Console.app
        NSWorkspace.shared.open(consoleAppURL)

        // Use AppleScript to filter by the app's subsystem after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let script = """
            tell application "Console"
                activate
            end tell
            """
            if let scriptObject = NSAppleScript(source: script) {
                var errorDict: NSDictionary?
                scriptObject.executeAndReturnError(&errorDict)
            }
        }
    }
    
    func showLogViewer() {
        UICoordinator.shared.showLogViewer()
    }
}
