//
//  SettingsStrings.swift
//  Notimanager
//
//  Centralized string constants for Settings UI.
//  Following Apple HIG and localization best practices.
//

import Foundation

// MARK: - Settings Strings

enum SettingsStrings {
    
    // MARK: - Window
    
    static let windowTitle = "Notimanager Settings"
    
    // MARK: - Tabs
    
    enum Tabs {
        static let general = "General"
        static let notifications = "Notifications"
        static let advanced = "Advanced"
        static let help = "Help"
    }
    
    // MARK: - General Settings
    
    enum General {
        static let enablePositioning = "Enable Positioning"
        static let launchAtLogin = "Launch at Login"
        static let hideMenuBarIcon = "Hide Menu Bar Icon"
        static let iconColor = "Icon Color"
        static let iconColorSubtitle = "Choose a color for the menu bar icon."
        static let openSettingsAtLaunch = "Open Settings at Launch"
        static let automaticUpdates = "Automatic Updates"
        static let quitApp = "Quit Notimanager"
        static let checkForUpdates = "Check for Updates"
        static let checkNow = "Check Now"
        static let checking = "Checking…"
        static let quit = "Quit"
    }
    
    // MARK: - Notifications Settings
    
    enum Notifications {
        static let notificationBanners = "Notification Banners"
        static let widgetsAndAlerts = "Widgets & Alerts"
        static let screenCorner = "Screen Corner"
        static let testNotification = "Test Notification"
        static let testNotificationSubtitle = "Send a sample banner to preview positioning."
        static let testAlert = "Test Alert"
        static let testAlertSubtitle = "Send a sample alert to preview positioning."
        static let test = "Test"
    }
    
    // MARK: - Advanced Settings
    
    enum Advanced {
        static let developerMode = "Developer Mode"
        static let developerModeSubtitle = "Enable verbose logging for troubleshooting."
        static let fileLogging = "File Logging"
        static let fileLoggingSubtitle = "Save log messages to files."
        static let logStatistics = "Log Statistics"
        static let logStatisticsSubtitle = "Overview of log files and entries."
        static let openLogsDirectory = "Open Logs Directory"
        static let openLogsDirectorySubtitle = "View application logs in Finder."
        static let clearLogs = "Clear Logs"
        static let clearLogsSubtitle = "Delete all log files."
        static let openConsoleApp = "Open Console.app"
        static let openConsoleAppSubtitle = "View system logs with predefined filters."
        static let systemDiagnostics = "System Diagnostics"
        static let systemDiagnosticsSubtitle = "View detailed system logs and configuration."
        static let systemPermissions = "System Permissions"
        static let systemPermissionsSubtitle = "Manage app permissions and accessibility access."
        static let open = "Open…"
        static let clear = "Clear…"
        static let refresh = "Refresh"
        static let files = "Files"
        static let totalSize = "Total Size"
        static let lastModified = "Last Modified"
    }
    
    // MARK: - Alerts
    
    enum Alerts {
        static let hideMenuBarIconTitle = "Hide Menu Bar Icon?"
        static let hideMenuBarIconMessage = "The menu bar icon will be hidden. To show it again, launch Notimanager from Applications or Spotlight."
        static let hide = "Hide"
        static let cancel = "Cancel"
        
        static let quitAppTitle = "Quit Notimanager?"
        static let quitAppMessage = "This will completely quit Notimanager. Notification positioning will stop working until you relaunch the app."
        
        static let clearLogsTitle = "Clear All Logs?"
        static let clearLogsConfirm = "Clear All Logs"
    }
    
    // MARK: - Positions
    
    enum Positions {
        static let topLeft = "Top Left"
        static let topRight = "Top Right"
        static let bottomLeft = "Bottom Left"
        static let bottomRight = "Bottom Right"
    }
}
