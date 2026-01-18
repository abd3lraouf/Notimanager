//
//  GeneralSettingsView.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Refactored to use GeneralSettingsViewModel (MVI).
//

import SwiftUI
import LaunchAtLogin
import Sparkle
import ServiceManagement

struct GeneralSettingsView: View {
    @StateObject private var viewModel: GeneralSettingsViewModel
    
    init(viewModel: GeneralSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 12) {
            // System Section
            systemSection

            // Updates Section
            updatesSection

            // Application Section
            applicationSection
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
        .alert(SettingsStrings.Alerts.hideMenuBarIconTitle, isPresented: Binding(
            get: { viewModel.state.showHideConfirmation },
            set: { _ in }
        )) {
            Button(SettingsStrings.Alerts.cancel, role: .cancel) {
                viewModel.process(.cancelHideMenuBarIcon)
            }
            Button(SettingsStrings.Alerts.hide, role: .destructive) {
                viewModel.process(.confirmHideMenuBarIcon)
            }
        } message: {
            Text(SettingsStrings.Alerts.hideMenuBarIconMessage)
        }
        .alert(SettingsStrings.Alerts.quitAppTitle, isPresented: Binding(
            get: { viewModel.state.showQuitConfirmation },
            set: { _ in }
        )) {
            Button(SettingsStrings.Alerts.cancel, role: .cancel) {
                viewModel.process(.cancelQuit)
            }
            Button(SettingsStrings.General.quit, role: .destructive) {
                viewModel.process(.confirmQuit)
            }
        } message: {
            Text(SettingsStrings.Alerts.quitAppMessage)
        }
    }

    private var systemSection: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Enable
                BlipToggleRow(
                    systemName: "bell.badge",
                    color: .blue,
                    title: SettingsStrings.General.enablePositioning,
                    subtitle: nil,
                    isOn: Binding(
                        get: { viewModel.state.isEnabled },
                        set: { viewModel.process(.setEnabled($0)) }
                    )
                )

                BlipSeparator()

                // Launch at login
                if #available(macOS 13.0, *) {
                    HStack(spacing: 12) {
                        BlipIconView(systemName: "power", color: .green)

                        Text(SettingsStrings.General.launchAtLogin)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            SMAppService.openSystemSettingsLoginItems()
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Open System Settings")

                        LaunchAtLogin.Toggle()
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    Group {
                        BlipSeparator()
                    }
                }

                // Hide Menu Bar Icon
                BlipToggleRow(
                    systemName: "menubar.rectangle",
                    color: .gray,
                    title: SettingsStrings.General.hideMenuBarIcon,
                    subtitle: nil,
                    isOn: Binding(
                        get: { viewModel.state.isMenuBarIconHidden },
                        set: { viewModel.process(.toggleMenuBarIconVisibility($0)) }
                    )
                )

                // Icon Color - only show when menu bar icon is visible
                if !viewModel.state.isMenuBarIconHidden {
                    BlipSeparator()

                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(viewModel.state.iconColor.color)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: "paintpalette.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(SettingsStrings.General.iconColor)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)

                            Text(SettingsStrings.General.iconColorSubtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Picker("", selection: Binding(
                            get: { viewModel.state.iconColor },
                            set: { viewModel.process(.setIconColor($0)) }
                        )) {
                            ForEach(IconColor.allCases) { color in
                                Text(color.displayName).tag(color)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(minWidth: 140)
                        .labelsHidden()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    BlipSeparator()
                } else {
                    BlipSeparator()
                }

                // Open Settings at Launch
                BlipToggleRow(
                    systemName: "gearshape",
                    color: .blue,
                    title: SettingsStrings.General.openSettingsAtLaunch,
                    subtitle: nil,
                    isOn: Binding(
                        get: { viewModel.state.openSettingsAtLaunch },
                        set: { viewModel.process(.setOpenSettingsAtLaunch($0)) }
                    )
                )
            }
        }
    }

    private var updatesSection: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Automatically check and download updates
                BlipToggleRow(
                    systemName: "arrow.down.circle",
                    color: .blue,
                    title: SettingsStrings.General.automaticUpdates,
                    subtitle: nil,
                    isOn: Binding(
                        get: { viewModel.state.automaticallyChecksForUpdates },
                        set: { viewModel.process(.setAutomaticallyChecksForUpdates($0)) }
                    )
                )

                BlipSeparator()

                // Check for Updates Now button
                BlipInfoRow(
                    systemName: "arrow.down.circle",
                    color: .blue,
                    title: "Notimanager v\(UpdateManager.shared.currentAppVersion)",
                    subtitle: viewModel.state.updateStatusMessage ?? "Last checked: \(viewModel.state.lastUpdateCheck)",
                    buttonTitle: viewModel.state.isCheckingForUpdates ? SettingsStrings.General.checking : SettingsStrings.General.checkNow,
                    disabled: viewModel.state.isCheckingForUpdates,
                    action: {
                        viewModel.process(.checkForUpdates)
                    }
                )
            }
        }
    }

    private var applicationSection: some View {
        BlipCard {
            BlipActionRow(
                systemName: "power",
                color: .red,
                title: SettingsStrings.General.quitApp,
                subtitle: nil,
                buttonTitle: SettingsStrings.General.quit,
                action: {
                    viewModel.process(.requestQuit)
                }
            )
        }
    }
}