//
//  AdvancedSettingsView.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Refactored to use AdvancedSettingsViewModel (MVI).
//  Improved wording for clarity and UX.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @StateObject private var viewModel: AdvancedSettingsViewModel
    @State private var isCommandCopied = false

    init(viewModel: AdvancedSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Developer Section
            developerSection

            // Tools Section
            toolsSection
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
        .alert("Clear All Logs?", isPresented: Binding(
            get: { viewModel.state.showClearLogsAlert },
            set: { _ in }
        )) {
            Button("Cancel", role: .cancel) {
                viewModel.process(.cancelClearAllLogs)
            }
            Button("Clear All Logs", role: .destructive) {
                viewModel.process(.confirmClearAllLogs)
            }
        } message: {
            Text("""
                This will permanently delete all log files.

                What will be deleted:
                • All log files in the logs directory
                • All log entries
                • This cannot be undone

                Total files affected: \(viewModel.state.logFilesCount)
                Total size: \(viewModel.state.totalLogSize)
                """)
        }
    }

    private var developerSection: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Developer Mode Toggle
                BlipToggleRow(
                    systemName: "ladybug",
                    color: .orange,
                    title: "Developer Mode",
                    subtitle: "Enable verbose logging for troubleshooting and advanced diagnostics.",
                    isOn: Binding(
                        get: { viewModel.state.debugMode },
                        set: { _ in viewModel.process(.toggleDebugMode) }
                    )
                )

                // Developer options shown only when debug mode is enabled
                if viewModel.state.debugMode {
                    BlipSeparator()

                    // File Logging Toggle
                    BlipToggleRow(
                        systemName: "doc.text",
                        color: .purple,
                        title: "File Logging",
                        subtitle: "Save log messages to files for debugging and analysis.",
                        isOn: Binding(
                            get: { viewModel.state.isLoggingEnabled },
                            set: { _ in viewModel.process(.toggleLogging) }
                        )
                    )

                    // Logging controls (shown when logging is enabled)
                    if viewModel.state.isLoggingEnabled {
                        BlipSeparator()

                        // Log Viewer Button
                        HStack(spacing: 12) {
                            BlipIconView(systemName: "list.bullet.rectangle", color: .purple)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Log Viewer")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)

                                Text("View, search, and analyze application logs.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                            
                            // Simple stats summary
                            if viewModel.state.logFilesCount > 0 {
                                Text(viewModel.state.totalLogSize)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .padding(.trailing, 8)
                            }

                            Button("Open Viewer…") {
                                viewModel.process(.showLogViewer)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    BlipSeparator()

                    // Open Logs Directory
                    HStack(spacing: 12) {
                        BlipIconView(systemName: "folder", color: .blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open Logs Directory")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)

                            Text("View application logs in Finder.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Open…") {
                            viewModel.process(.openLogsDirectory)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    BlipSeparator()

                    // Clear Logs
                    HStack(spacing: 12) {
                        BlipIconView(systemName: "trash", color: .red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear Logs")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)

                            Text("Delete all log files.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Clear…") {
                            viewModel.process(.clearAllLogs)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(viewModel.state.logFilesCount == 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    BlipSeparator()

                    // Open Console.app
                    HStack(spacing: 12) {
                        BlipIconView(systemName: "terminal", color: .purple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open Console.app")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)

                            Text("View system logs with predefined filters.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button {
                                copyConsoleCommand()
                            } label: {
                                Label(isCommandCopied ? "Copied" : "Copy Command", systemImage: isCommandCopied ? "checkmark" : "doc.on.doc")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Copy console command to clipboard")

                            Button("Open…") {
                                viewModel.process(.openConsoleApp)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private var toolsSection: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Diagnostics button
                HStack(spacing: 12) {
                    BlipIconView(systemName: "wrench.and.screwdriver", color: .green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("System Diagnostics")
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)

                        Text("View detailed system logs and configuration.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Open…") {
                        viewModel.process(.showDiagnostics)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                BlipSeparator()

                // Permissions button
                HStack(spacing: 12) {
                    BlipIconView(systemName: "hand.raised", color: .blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("System Permissions")
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)

                        Text("Manage app permissions and accessibility access.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Open…") {
                        viewModel.process(.showPermissions)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Helper Functions

    private func copyConsoleCommand() {
        let command = "log stream --predicate 'subsystem == \"dev.abd3lraouf.notimanager\"'"

        DispatchQueue.main.async {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(command, forType: .string)
            
            withAnimation {
                isCommandCopied = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isCommandCopied = false
                }
            }
        }
    }
}
