//
//  DiagnosticView.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  SwiftUI Diagnostic View with MVI pattern.
//  Redesigned with Blip design system.
//

import SwiftUI

struct DiagnosticView: View {
    @StateObject private var viewModel: DiagnosticViewModel

    init(viewModel: DiagnosticViewModel = DiagnosticViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            headerCard

            // Test buttons
            diagnosticButtonsCard

            // Output log
            outputLogCard
        }
        .padding(12)
        .frame(minWidth: 750, maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
        .onAppear {
            viewModel.log("🚀 Diagnostic window initialized")
            viewModel.log("⚠️ Send a notification, then click the test buttons to diagnose issues\n")
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        BlipCard {
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0xBF/255.0, green: 0x5A/255.0, blue: 0xF2/255.0))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "stethoscope")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notification API Diagnostics")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)

                        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
                        Text("macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Diagnostic Buttons Card

    private var diagnosticButtonsCard: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Core Diagnostics Group
                DiagnosticActionRow(
                    icon: "magnifyingglass",
                    color: .blue,
                    title: "Scan All Windows",
                    subtitle: "Find notification-sized windows on screen",
                    action: { viewModel.scanWindows() }
                )

                BlipSeparator()

                DiagnosticActionRow(
                    icon: "accessibility",
                    color: .purple,
                    title: "Test Accessibility API",
                    subtitle: "Check AX elements from Notification Center",
                    action: { viewModel.testAccessibilityAPI() }
                )

                BlipSeparator()

                DiagnosticActionRow(
                    icon: "location",
                    color: .green,
                    title: "Try Set Position",
                    subtitle: "Attempt to move notification elements",
                    action: { viewModel.trySetPosition() }
                )

                BlipSeparator()

                DiagnosticActionRow(
                    icon: "checkmark.circle",
                    color: .green,
                    title: "Verify Position",
                    subtitle: "Confirm position changes were applied",
                    action: { viewModel.testPositionVerification() }
                )

                BlipSeparator()

                DiagnosticActionRow(
                    icon: "arrow.triangle.2.circlepath",
                    color: .orange,
                    title: "Test Stabilization",
                    subtitle: "Check for animating notification windows",
                    action: { viewModel.testStabilization() }
                )

                BlipSeparator()

                DiagnosticActionRow(
                    icon: "puzzlepiece.extension",
                    color: .cyan,
                    title: "Test Widget Detection",
                    subtitle: "Search for widget panel elements",
                    action: { viewModel.testWidgetDetection() }
                )

                BlipSeparator()

                DiagnosticActionRow(
                    icon: "doc.text.magnifyingglass",
                    color: .blue,
                    title: "Analyze NC Panel",
                    subtitle: "Inspect Notification Center panel structure",
                    action: { viewModel.analyzeNCPanel() }
                )

                BlipSeparator()

                DiagnosticActionRow(
                    icon: "rectangle.stack",
                    color: .purple,
                    title: "Test Multi-Notification",
                    subtitle: "Check notification stacking behavior",
                    action: { viewModel.testMultipleNotifications() }
                )

                BlipSeparator()

                // Utility Row
                HStack(spacing: 12) {
                    Button(action: { viewModel.clearOutput() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .medium))
                            Text("Clear Output")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF5/255.0))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: { viewModel.sendTestNotification() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bell.badge")
                                .font(.system(size: 12, weight: .medium))
                            Text("Send Test Notification")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 0x00/255.0, green: 0x7A/255.0, blue: 0xFF/255.0))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Output Log Card

    private var outputLogCard: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0x8E/255.0, green: 0x8E/255.0, blue: 0x93/255.0))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "terminal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                        }

                    Text("Output Log")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()
                    .background(Color(red: 0xE5/255.0, green: 0xE5/255.0, blue: 0xE5/255.0))

                // Log content
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(viewModel.output)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .id("logOutput")
                    }
                    .onChange(of: viewModel.output) { _ in
                        withAnimation {
                            proxy.scrollTo("logOutput", anchor: .bottom)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .background(Color(red: 0xFA/255.0, green: 0xFA/255.0, blue: 0xFA/255.0))
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Diagnostic Action Row

struct DiagnosticActionRow: View {
    let icon: String
    let color: BlipIconColor
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color.color.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(color.color)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "play.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DiagnosticView()
        .frame(width: 700, height: 700)
}
