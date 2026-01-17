//
//  InterceptionSettingsView.swift
//  Notimanager
//
//  SwiftUI Interception Settings view following Blip Settings design system.
//

import SwiftUI

struct InterceptionSettingsView: View {
    @AppStorage("interceptNotifications") private var interceptNotifications = false
    @AppStorage("interceptWidgets") private var interceptWidgets = false
    @State private var selectedPosition: NotificationPosition = .topRight
    @State private var testStatusMessage: String = ""
    @State private var testStatusColor: Color = .primary

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Interception Section
                interceptionSection

                // Position Preview Section
                positionPreviewSection

                // Test Section
                testSection
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
        .frame(width: 540)
    }

    private var interceptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTIFICATION INTERCEPTION")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            BlipCard {
                VStack(spacing: 0) {
                    // Intercept Normal Notifications - Purple icon
                    BlipToggleRow(
                        systemName: "bell.badge",
                        color: .purple,
                        title: "Normal notifications",
                        subtitle: "Intercept standard system notification banners and alerts",
                        isOn: $interceptNotifications
                    )

                    BlipSeparator()

                    // Intercept Widgets - Purple icon
                    BlipToggleRow(
                        systemName: "square.grid.2x2",
                        color: .purple,
                        title: "Widgets",
                        subtitle: "Intercept Notification Center and interactive widgets",
                        isOn: $interceptWidgets
                    )
                }
            }
        }
    }

    private var positionPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("POSITION PREVIEW")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            Text("See exactly where notifications will appear.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            // Position Grid Preview (simplified white card)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
                .frame(height: 200)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                .overlay {
                    VStack {
                        Text("Position: \(selectedPosition.displayName)")
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
                }
                .padding(.horizontal, 20)
        }
    }

    private var testSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TEST INTERCEPTION")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            Text("Send test notifications to verify interception is working.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button("Banner") {
                    // Test action
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Button("Widget") {
                    // Test action
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)

            if !testStatusMessage.isEmpty {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white)
                    .overlay {
                        Text(testStatusMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(testStatusColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
            }
        }
    }
}
