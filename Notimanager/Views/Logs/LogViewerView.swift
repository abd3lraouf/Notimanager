//
//  LogViewerView.swift
//  Notimanager
//
//  Created on 2026-01-18.
//  Main view for the Log Viewer window.
//

import SwiftUI

struct LogViewerView: View {
    @StateObject private var viewModel = LogViewerViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Stats
            statsHeaderView
            
            // Filter Bar
            filterBar
            
            // Main Log Table
            browserView
        }
        .frame(minWidth: 700, minHeight: 500)
        .toolbar { toolbarContent }
        .alert("Clear All Logs?", isPresented: Binding(
            get: { viewModel.state.showDeleteAlert },
            set: { if !$0 { viewModel.process(.cancelClearLogs) } }
        )) {
            Button("Clear All", role: .destructive) {
                viewModel.process(.confirmClearLogs)
            }
            Button("Cancel", role: .cancel) {
                viewModel.process(.cancelClearLogs)
            }
        } message: {
            Text("This action will permanently delete all log files from disk. It cannot be undone.")
        }
    }
    
    // MARK: - Sidebar
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack(spacing: 16) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Filter logs...", text: Binding(
                    get: { viewModel.state.filterOptions.searchText },
                    set: { val in viewModel.process(.updateSearchText(val)) }
                ))
                .textFieldStyle(.plain)
                
                if !viewModel.state.filterOptions.searchText.isEmpty {
                    Button(action: { viewModel.process(.updateSearchText("")) }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .frame(maxWidth: 300)
            
            Divider()
                .frame(height: 16)
            
            // Level Toggles
            HStack(spacing: 2) {
                ForEach([FileLogger.LogLevel.debug, .info, .warning, .error], id: \.self) { level in
                    Toggle(isOn: Binding(
                        get: { viewModel.state.filterOptions.levels.contains(level) },
                        set: { _ in viewModel.process(.toggleLevel(level)) }
                    )) {
                        Text(level.rawValue)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.state.filterOptions.levels.contains(level) ? .white : .primary)
                    }
                    .toggleStyle(.button)
                    .tint(levelColor(for: level))
                    .controlSize(.regular)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.1)), alignment: .bottom)
    }
    
    private var statsHeaderView: some View {
        HStack(spacing: 40) {
            Spacer()
            
            StatItem(title: "Total", value: "\(viewModel.state.totalEntries)", color: .primary)
            StatItem(title: "Displayed", value: "\(viewModel.state.displayedEntries)", color: .blue)
            StatItem(title: "Errors", value: "\(viewModel.state.errorCount)", color: .red)
            StatItem(title: "Warnings", value: "\(viewModel.state.warningCount)", color: .orange)
            
            Spacer()
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.1)), alignment: .bottom)
        .background(Color(red: 0xFA/255.0, green: 0xFA/255.0, blue: 0xFA/255.0))
    }
    

    
    private struct StatItem: View {
        let title: String
        let value: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
    }
    
    // MARK: - Browser
    
    private var browserView: some View {
        VStack(spacing: 0) {
            // Log Table (Search is now in FilterBar)
            
            // Log Table
            Table(viewModel.state.filteredEntries, selection: Binding(
                get: { viewModel.state.selectedEntryId },
                set: { id in viewModel.process(.selectEntry(id)) }
            )) {
                TableColumn("Timestamp") { entry in
                    Text(formatTimestamp(entry.timestamp))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .width(min: 140, max: 160)
                
                TableColumn("Level") { entry in
                    Text(entry.level.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(levelColor(for: entry.level).opacity(0.1))
                        .foregroundColor(levelColor(for: entry.level))
                        .cornerRadius(4)
                }
                .width(min: 60, max: 70)
                
                TableColumn("Category") { entry in
                    Text(entry.category)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .width(min: 80, max: 120)
                
                TableColumn("Message") { entry in
                    Text(entry.message)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }
        }
        .background(Color.white)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button(action: { viewModel.process(.refresh) }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        
        ToolbarItem(placement: .automatic) {
            Button(action: { viewModel.process(.exportLogs) }) {
                Label("Copy All", systemImage: "doc.on.doc")
            }
            .help("Copy filtered logs to clipboard")
        }
        
        ToolbarItem(placement: .automatic) {
            Button(action: { viewModel.process(.requestClearLogs) }) {
                Label("Clear", systemImage: "trash")
            }
            .disabled(viewModel.state.allEntries.isEmpty)
        }
    }
    
    // MARK: - Helpers
    
    private func levelColor(for level: FileLogger.LogLevel) -> Color {
        switch level {
        case .debug: return .blue
        case .info: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
