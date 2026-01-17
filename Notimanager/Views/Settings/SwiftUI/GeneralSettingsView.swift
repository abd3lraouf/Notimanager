//
//  GeneralSettingsView.swift
//  Notimanager
//
//  SwiftUI General Settings view following Blip Settings design system.
//  Solid white cards, vibrant colored icons, standardized spacing.
//

import SwiftUI
import LaunchAtLogin

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("isEnabled") private var isEnabled = false
    @AppStorage("isMenuBarIconHidden") private var isMenuBarIconHidden = false
    @AppStorage("automaticallyChecksForUpdates") private var checkForUpdates = false
    @AppStorage("automaticallyDownloadsUpdates") private var downloadUpdates = false

    @State private var showQuitConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // System Section
                systemSection

                // Updates Section
                updatesSection

                // Application Section
                applicationSection
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
        .frame(width: 540)
    }

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STARTUP & MENU")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            BlipCard {
                VStack(spacing: 0) {
                    // Launch at login - Green icon
                    if #available(macOS 13.0, *) {
                        HStack(spacing: 12) {
                            BlipIconView(systemName: "power", color: .green)

                            Text("Start at login")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)

                            Spacer()

                            LaunchAtLogin.Toggle()
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Group {
                            BlipSeparator()
                        }
                    }

                    // Enable Notification Positioning - Green icon
                    BlipToggleRow(
                        systemName: "hand.tap",
                        color: .green,
                        title: "Enable notification positioning",
                        subtitle: "Allow Notimanager to reposition your notifications",
                        isOn: $isEnabled
                    )

                    BlipSeparator()

                    // Hide Menu Bar Icon - Gray icon
                    BlipToggleRow(
                        systemName: "menubar.rectangle",
                        color: .gray,
                        title: "Hide menu bar icon",
                        subtitle: "Hide the menu bar icon. Access settings from Launchpad or Applications.",
                        isOn: $isMenuBarIconHidden
                    )
                }
            }
        }
    }

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UPDATES")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            BlipCard {
                VStack(spacing: 0) {
                    // Automatically check and download updates - Blue icon
                    BlipToggleRow(
                        systemName: "arrow.down.circle",
                        color: .blue,
                        title: "Automatically check and download updates",
                        subtitle: "Notimanager will check for updates and download them automatically",
                        isOn: $checkForUpdates
                    )

                    BlipSeparator()

                    // Check for Updates Now button - Blue icon
                    HStack(spacing: 12) {
                        BlipIconView(systemName: "arrow.clockwise", color: .blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Check for updates now")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)

                            Text("See if a new version is available")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Check Now…") {
                            // Trigger update check
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

    private var applicationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APPLICATION")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            BlipCard {
                BlipActionRow(
                    systemName: "power",
                    color: .red,
                    title: "Quit Notimanager",
                    subtitle: "Completely quit the Notimanager application",
                    buttonTitle: "Quit",
                    action: {
                        showQuitConfirmation = true
                    }
                )
            }
        }
    }
}

// MARK: - Quit Confirmation Dialog

struct QuitConfirmationDialog: View {
    @Binding var isPresented: Bool
    let confirmAction: () -> Void

    var body: some View {
        Button("Quit") {
            confirmAction()
        }
        .alert("Quit Notimanager?", isPresented: $isPresented) {
            Button("Quit", role: .destructive) {
                confirmAction()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will completely quit Notimanager. Notification positioning will stop working until you relaunch the app.")
        }
    }
}
