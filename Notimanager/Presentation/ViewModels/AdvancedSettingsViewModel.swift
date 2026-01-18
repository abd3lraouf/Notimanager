//
//  AdvancedSettingsViewModel.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  MVI ViewModel for Advanced Settings.
//

import Foundation
import Combine
import SwiftUI

// MARK: - State

struct AdvancedSettingsState: Equatable {
    var debugMode: Bool = false

    // Logging control state
    var isLoggingEnabled: Bool = false
    var logFilesCount: Int = 0
    var totalLogSize: String = "0 KB"
    var lastLogModifiedDate: String = "Never"

    // Logging statistics - using FileLogger.LogLevel
    var logLevelCounts: [FileLogger.LogLevel: Int] = [.debug: 0, .info: 0, .warning: 0, .error: 0]

    // Alert state
    var showClearLogsAlert: Bool = false
}

// MARK: - Intent

enum AdvancedSettingsIntent {
    case toggleDebugMode
    case toggleLogging
    case clearAllLogs
    case confirmClearAllLogs
    case cancelClearAllLogs
    case refreshLogStats
    case showDiagnostics
    case showPermissions
    case openLogsDirectory
    case openConsoleApp
    case showLogViewer
}

// MARK: - ViewModel

class AdvancedSettingsViewModel: BaseViewModel<AdvancedSettingsState, AdvancedSettingsIntent> {
    
    private let settingsUseCases: UpdateSettingsUseCase
    private let systemUseCases: SystemUseCases
    private let settingsRepository: SettingsRepository
    
    init(
        settingsUseCases: UpdateSettingsUseCase,
        systemUseCases: SystemUseCases,
        settingsRepository: SettingsRepository
    ) {
        self.settingsUseCases = settingsUseCases
        self.systemUseCases = systemUseCases
        self.settingsRepository = settingsRepository
        
        super.init(initialState: AdvancedSettingsState())
        
        setupObservers()
    }
    
    private func setupObservers() {
        settingsRepository.debugMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.debugMode = val } }
            .store(in: &cancellables)
    }
    
    override func process(_ intent: AdvancedSettingsIntent) {
        switch intent {
        case .toggleDebugMode:
            settingsUseCases.setDebugMode(!state.debugMode)

        case .toggleLogging:
            toggleLogging()

        case .clearAllLogs:
            updateState { $0.showClearLogsAlert = true }

        case .confirmClearAllLogs:
            confirmClearAllLogs()

        case .cancelClearAllLogs:
            updateState { $0.showClearLogsAlert = false }

        case .refreshLogStats:
            refreshLogStats()

        case .showDiagnostics:
            systemUseCases.showDiagnostics()

        case .showPermissions:
            systemUseCases.showPermissions()

        case .openLogsDirectory:
            systemUseCases.openLogsDirectory()

        case .openConsoleApp:
            systemUseCases.openConsoleApp()

        case .showLogViewer:
            systemUseCases.showLogViewer()
        }
    }

    // MARK: - Logging Control

    private func toggleLogging() {
        Task { @MainActor in
            let newValue = !state.isLoggingEnabled

            if newValue {
                // Enable logging
                LoggingService.shared.isFileLoggingEnabled = true
                updateState { $0.isLoggingEnabled = true }
                refreshLogStats()
            } else {
                // Disable logging
                LoggingService.shared.isFileLoggingEnabled = false
                updateState { $0.isLoggingEnabled = false }
                // Reset stats
                updateState {
                    $0.logFilesCount = 0
                    $0.totalLogSize = "0 KB"
                    $0.lastLogModifiedDate = "Never"
                    $0.logLevelCounts = [.debug: 0, .info: 0, .warning: 0, .error: 0]
                }
            }
        }
    }

    private func confirmClearAllLogs() {
        updateState { $0.showClearLogsAlert = false }
        LoggingService.shared.clearAllLogs()
        refreshLogStats()
    }

    private func refreshLogStats() {
        Task { @MainActor in
            await updateLogStats()
        }
    }

    private func updateLogStats() async {
        // Get stats from FileLogger
        let logFiles = await FileLogger.shared.getLogFiles()
        let totalLogSize = await FileLogger.shared.getTotalLogSize()
        let levelCounts = await FileLogger.shared.getLogLevelCounts()

        updateState {
            $0.logFilesCount = logFiles.count
            $0.totalLogSize = formatFileSize(totalLogSize)
            $0.lastLogModifiedDate = getLastModifiedLogDate(logFiles)
            $0.logLevelCounts = levelCounts
        }
    }

    private func formatFileSize(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.1f MB", mb)
        }
    }

    private func getLastModifiedLogDate(_ files: [URL]) -> String {
        guard let latestFile = files.first else { return "Never" }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: latestFile.path)
            if let modDate = attributes[.modificationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: modDate)
            }
        } catch {
            return "Unknown"
        }

        return "Never"
    }
}
