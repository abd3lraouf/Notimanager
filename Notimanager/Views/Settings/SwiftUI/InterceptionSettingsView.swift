//
//  InterceptionSettingsView.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Refactored to use InterceptionSettingsViewModel (MVI).
//

import SwiftUI
import UserNotifications

struct InterceptionSettingsView: View {
    @StateObject private var viewModel: InterceptionSettingsViewModel
    
    init(viewModel: InterceptionSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Interception Section
            interceptionSection

            // Position Preview Section
            positionPreviewSection

            // Test Section
            testSection
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
    }

    private var interceptionSection: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Intercept Normal Notifications
                BlipToggleRow(
                    systemName: "bell.badge",
                    color: .purple,
                    title: SettingsStrings.Notifications.notificationBanners,
                    subtitle: nil,
                    isOn: Binding(
                        get: { viewModel.state.interceptNotifications },
                        set: { viewModel.process(.setInterceptNotifications($0)) }
                    )
                )

                BlipSeparator()

                // Intercept Widgets
                BlipToggleRow(
                    systemName: "square.grid.2x2",
                    color: .purple,
                    title: SettingsStrings.Notifications.widgetsAndAlerts,
                    subtitle: nil,
                    isOn: Binding(
                        get: { viewModel.state.interceptWidgets },
                        set: { viewModel.process(.setInterceptWidgets($0)) }
                    )
                )

                BlipSeparator()

                // Notification Direction
                BlipPickerRow(
                    systemName: "arrow.up.forward.app",
                    color: .blue,
                    title: SettingsStrings.Notifications.screenCorner,
                    subtitle: nil,
                    selection: Binding(
                        get: { viewModel.state.currentPosition },
                        set: { viewModel.process(.setPosition($0)) }
                    ),
                    displayValue: { $0.displayName }
                )
            }
        }
    }

    private var positionPreviewSection: some View {
        // Position Preview Card
        BlipCard {
            ZStack(alignment: positionAlignment) {
                // Background
                Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0)

                // Sample notification preview
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.purple)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(.primary.opacity(0.3))
                            .frame(width: 120, height: 8)

                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(.primary.opacity(0.2))
                            .frame(width: 80, height: 6)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(viewModel.state.currentPosition.edgeInsets)
            }
            .frame(height: 160)
        }
    }

    private var testSection: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Test Banner
                HStack(spacing: 12) {
                    BlipIconView(systemName: "bell", color: .blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(SettingsStrings.Notifications.testNotification)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)

                        Text(SettingsStrings.Notifications.testNotificationSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(SettingsStrings.Notifications.test) {
                        viewModel.process(.sendTestNotification)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                BlipSeparator()

                // Test Widget
                HStack(spacing: 12) {
                    BlipIconView(systemName: "square.grid.2x2", color: .purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(SettingsStrings.Notifications.testAlert)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)

                        Text(SettingsStrings.Notifications.testAlertSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(SettingsStrings.Notifications.test) {
                        viewModel.process(.sendTestWidgetNotification)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
    }

    private var positionAlignment: Alignment {
        switch viewModel.state.currentPosition {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
}

// MARK: - Notification Position Extensions

extension NotificationPosition {
    var edgeInsets: CGFloat {
        switch self {
        case .topLeft, .topRight: return 24
        case .bottomLeft, .bottomRight: return 24
        }
    }
}