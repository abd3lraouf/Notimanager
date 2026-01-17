//
//  AdvancedSettingsView.swift
//  Notimanager
//
//  SwiftUI Advanced Settings view following Blip Settings design system.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @AppStorage("debugMode") private var debugMode = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Developer Section
                developerSection

                // Tools Section
                toolsSection

                // Reference Section
                referenceSection
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
        .frame(width: 540)
    }

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DEVELOPER")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            BlipCard {
                BlipToggleRow(
                    systemName: "ladybug",
                    color: .orange,
                    title: "Debug mode",
                    subtitle: "Enable detailed logging for troubleshooting",
                    isOn: $debugMode
                )
            }
        }
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOOLS")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            BlipCard {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        BlipIconView(systemName: "wrench.and.screwdriver", color: .green)

                        Text("Open Diagnostics")
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)

                        Spacer()

                        Button("Open…") {
                            // Open diagnostics
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    HStack(spacing: 12) {
                        BlipIconView(systemName: "hand.raised", color: .blue)

                        Text("Permissions")
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)

                        Spacer()

                        Button("Open…") {
                            // Open permissions
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REFERENCE")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            Text("View and search all available keyboard shortcuts.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            BlipCard {
                HStack(spacing: 12) {
                    BlipIconView(systemName: "keyboard", color: .gray)

                    Text("Keyboard Shortcuts")
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button("View…") {
                        // Open shortcuts panel
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 20)
        }
    }
}
