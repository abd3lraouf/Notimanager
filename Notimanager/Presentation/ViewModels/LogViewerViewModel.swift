//
//  LogViewerViewModel.swift
//  Notimanager
//
//  Created on 2026-01-18.
//  MVI ViewModel for the Log Viewer.
//

import Foundation
import Combine
import SwiftUI

// MARK: - State

struct LogViewerState: Equatable {
    var allEntries: [LogEntry] = []
    var filteredEntries: [LogEntry] = []
    var filterOptions: LogFilterOptions = LogFilterOptions()
    
    // UI State
    var isLoading: Bool = false
    var selectedEntryId: UUID? = nil
    var showDeleteAlert: Bool = false
    
    // Stats
    var totalEntries: Int = 0
    var displayedEntries: Int = 0
    var errorCount: Int = 0
    var warningCount: Int = 0
    
    var isStreaming: Bool = false // Future feature
}

// MARK: - Intent

enum LogViewerIntent {
    case loadLogs
    case updateSearchText(String)
    case toggleLevel(FileLogger.LogLevel)
    case clearAllLogs
    case selectEntry(UUID?)
    case refresh
    case exportLogs
    case requestClearLogs
    case confirmClearLogs
    case cancelClearLogs
}

// MARK: - ViewModel

class LogViewerViewModel: BaseViewModel<LogViewerState, LogViewerIntent> {
    
    init() {
        super.init(initialState: LogViewerState())
        
        // Load initial data
        process(.loadLogs)
    }
    
    override func process(_ intent: LogViewerIntent) {
        switch intent {
        case .loadLogs, .refresh:
            loadLogs()
            
        case .updateSearchText(let text):
            updateState { $0.filterOptions.searchText = text }
            performFiltering()
            
        case .toggleLevel(let level):
            updateState { 
                if $0.filterOptions.levels.contains(level) {
                    $0.filterOptions.levels.remove(level)
                } else {
                    $0.filterOptions.levels.insert(level)
                }
            }
            performFiltering()
            
        case .clearAllLogs:
            clearAllLogs()
            
        case .selectEntry(let id):
            updateState { $0.selectedEntryId = id }
            
        case .exportLogs:
            exportLogs()
            
        case .requestClearLogs:
            updateState { $0.showDeleteAlert = true }
            
        case .confirmClearLogs:
            updateState { $0.showDeleteAlert = false }
            clearAllLogs()
            
        case .cancelClearLogs:
            updateState { $0.showDeleteAlert = false }
        }
    }
    
    private func loadLogs() {
        updateState { $0.isLoading = true }
        
        Task { @MainActor in
            let entries = await FileLogger.shared.getLogEntries(maxEntries: 5000)
            
            updateState {
                $0.allEntries = entries
                $0.isLoading = false
            }
            
            performFiltering()
        }
    }
    
    private func performFiltering() {
        let options = state.filterOptions
        let entries = state.allEntries
        
        Task { @MainActor in
            let filtered = entries.filter { entry in
                // Filter by Level
                if !options.levels.contains(entry.level) {
                    return false
                }
                
                // Filter by Search Text
                if !options.searchText.isEmpty {
                    if !entry.filterText.contains(options.searchText.lowercased()) {
                        return false
                    }
                }
                
                return true
            }
            
            updateState {
                $0.filteredEntries = filtered
                $0.totalEntries = entries.count
                $0.displayedEntries = filtered.count
                
                // Update basic stats
                $0.errorCount = entries.filter { $0.level == .error }.count
                $0.warningCount = entries.filter { $0.level == .warning }.count
            }
        }
    }
    
    private func clearAllLogs() {
        Task { @MainActor in
            await FileLogger.shared.clearAllLogs()
            loadLogs() // Reload (should be empty)
        }
    }
    
    private func exportLogs() {
        let text = state.filteredEntries.map { $0.originalText }.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
