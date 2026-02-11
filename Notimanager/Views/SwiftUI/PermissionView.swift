//
//  PermissionView.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  SwiftUI Permission View - Minimal, Blip design system.
//

import SwiftUI

struct PermissionView: View {
    @StateObject private var viewModel: PermissionViewModel
    @State private var pollingTimer: Timer?

    init(viewModel: PermissionViewModel = PermissionViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    headerSection

                    permissionStatusCard

                    // Stale permission warning (only shown when needed)
                    if viewModel.isPermissionStale && !viewModel.isAccessibilityGranted {
                        stalePermissionCard
                    }

                    // Clear permission card (always shown as utility)
                    clearPermissionCard

                    actionCard
                }
                .padding(12)
            }
        }
        .frame(width: 480, height: 520)
        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
        .onAppear {
            startPermissionPolling()
        }
        .onDisappear {
            pollingTimer?.invalidate()
            pollingTimer = nil
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)

            Text(headerTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            Text(headerSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private var headerTitle: String {
        viewModel.isAccessibilityGranted ? "All Set" : "Accessibility"
    }

    private var headerSubtitle: String {
        if viewModel.isAccessibilityGranted {
            return "Notimanager is ready to use"
        } else {
            return "Required to move notifications"
        }
    }

    // MARK: - Permission Status Card

    private var permissionStatusCard: some View {
        BlipCard {
            HStack(spacing: 12) {
                BlipIconView(systemName: statusIcon, color: statusColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text(statusTitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)

                    Text(statusMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    private var statusIcon: String {
        if viewModel.isAccessibilityGranted {
            return "checkmark.circle.fill"
        } else if viewModel.isPermissionStale {
            return "arrow.triangle.2.circlepath"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: BlipIconColor {
        if viewModel.isAccessibilityGranted {
            return .green
        } else if viewModel.isPermissionStale {
            return .orange
        } else {
            return .orange
        }
    }

    private var statusTitle: String {
        if viewModel.isAccessibilityGranted {
            return "Permission Granted"
        } else if viewModel.isPermissionStale {
            return "Update Detected"
        } else {
            return "Permission Required"
        }
    }

    private var statusMessage: String {
        if viewModel.isAccessibilityGranted {
            return "Ready to restart"
        } else if viewModel.isPermissionStale {
            return "Please re-grant permission"
        } else {
            return "Required to reposition notifications"
        }
    }

    // MARK: - Stale Permission Card

    private var stalePermissionCard: some View {
        BlipCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(BlipIconColor.orange.color)

                    Text("How to fix")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                }

                staleStep(number: "1", text: "Open System Settings")
                staleStep(number: "2", text: "Remove Notimanager (click −)")
                staleStep(number: "3", text: "Add Notimanager back (click +)")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    private func staleStep(number: String, text: String) -> some View {
        HStack(spacing: 6) {
            Text(number)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 14, height: 14)
                .background(Capsule().fill(BlipIconColor.orange.color))

            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Clear Permission Card

    private var clearPermissionCard: some View {
        BlipCard {
            BlipActionRow(
                systemName: "trash",
                color: .gray,
                title: "Clear Permission",
                subtitle: "Remove from System Settings",
                buttonTitle: "Clear",
                action: {
                    viewModel.clearAccessibilityPermission()
                }
            )
        }
    }

    // MARK: - Action Card

    private var actionCard: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Primary action
                BlipActionRow(
                    systemName: viewModel.isAccessibilityGranted ? "arrow.clockwise" : "gearshape.fill",
                    color: .blue,
                    title: viewModel.isAccessibilityGranted ? "Restart Notimanager" : "Open System Settings",
                    subtitle: viewModel.isAccessibilityGranted ? "Apply changes" : "Grant accessibility permission",
                    buttonTitle: viewModel.isAccessibilityGranted ? "Restart" : "Open",
                    action: {
                        if viewModel.isAccessibilityGranted {
                            viewModel.restartApp()
                        } else {
                            viewModel.openAccessibilitySettings()
                        }
                    }
                )

                // Quit button (only when permission not granted)
                if !viewModel.isAccessibilityGranted {
                    BlipSeparator()

                    BlipActionRow(
                        systemName: "power",
                        color: .red,
                        title: "Quit Notimanager",
                        subtitle: nil,
                        buttonTitle: "Quit",
                        action: {
                            NSApp.terminate(nil)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Permission Polling

    private func startPermissionPolling() {
        pollingTimer?.invalidate()

        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak viewModel] _ in
            guard let viewModel = viewModel else { return }

            let isNowGranted = AXIsProcessTrusted()

            if isNowGranted && !viewModel.isAccessibilityGranted {
                DispatchQueue.main.async {
                    viewModel.updatePermissionStatus(granted: true)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PermissionView()
        .frame(width: 480, height: 520)
}
