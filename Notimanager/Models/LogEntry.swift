//
//  LogEntry.swift
//  Notimanager
//
//  Created on 2026-01-18.
//  Model representing a parsed log entry.
//

import Foundation

struct LogEntry: Identifiable, Equatable, Hashable {
    let id = UUID()
    let timestamp: Date
    let level: FileLogger.LogLevel
    let category: String
    let message: String
    let originalText: String
    
    // For fast filtering
    var filterText: String {
        return "\(category) \(message)".lowercased()
    }
}

struct LogFilterOptions: Equatable {
    var searchText: String = ""
    var levels: Set<FileLogger.LogLevel> = [.debug, .info, .warning, .error]
    var startDate: Date? = nil
    var endDate: Date? = nil
    var categories: Set<String> = []
    
    var isFiltering: Bool {
        return !searchText.isEmpty || 
               levels.count < 4 || 
               startDate != nil || 
               endDate != nil ||
               !categories.isEmpty
    }
}
