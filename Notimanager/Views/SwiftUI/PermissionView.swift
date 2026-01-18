//
//  PermissionView.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  SwiftUI Permission View with MVI pattern.
//  Redesigned with Blip design system.
//

import SwiftUI

struct PermissionView: View {
    @StateObject private var viewModel: PermissionViewModel
    @State private var pollingTimer: Timer?

    init(viewModel: PermissionViewModel = PermissionViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // App icon and title
                headerSection

                // Permission explanation card
                explanationCard

                // Features card
                featuresCard

                // Status card
                statusCard

                // Action buttons
                actionButtons
            }
            .padding(20)
            .frame(width: 420)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 480, minHeight: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)

            Text("Accessibility Permission")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)

            Text("Notimanager needs accessibility permission to reposition your notifications on screen.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    // MARK: - Explanation Card

    private var explanationCard: some View {
        BlipCard {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(red: 0x00/255.0, green: 0x7A/255.0, blue: 0xFF/255.0).opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0x00/255.0, green: 0x7A/255.0, blue: 0xFF/255.0))
                    }

                Text("Accessibility is a macOS feature that lets apps move UI elements on your screen. Notimanager uses this to reposition your notifications.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Features Card

    private var featuresCard: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0x32/255.0, green: 0xD7/255.0, blue: 0x4B/255.0).opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(red: 0x32/255.0, green: 0xD7/255.0, blue: 0x4B/255.0))
                        }

                    Text("What you'll be able to do")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                BlipSeparator()

                // Feature rows
                PermissionFeatureRow(
                    icon: "arrow.up.left.and.arrow.down.right",
                    title: "Move notifications to any corner"
                )

                BlipSeparator()

                PermissionFeatureRow(
                    icon: "rectangle.3.group",
                    title: "Keep notifications organized"
                )

                BlipSeparator()

                PermissionFeatureRow(
                    icon: "slider.horizontal.3",
                    title: "Customize positioning behavior"
                )
            }
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        BlipCard {
            HStack(spacing: 12) {
                // Status icon
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(statusIconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: statusIconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(statusIconColor)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(statusMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private var statusIconName: String {
        viewModel.isAccessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }

    private var statusIconColor: Color {
        viewModel.isAccessibilityGranted
            ? Color(red: 0x32/255.0, green: 0xD7/255.0, blue: 0x4B/255.0)
            : Color(red: 0xFF/255.0, green: 0x95/255.0, blue: 0x00/255.0)
    }

    private var statusTitle: String {
        viewModel.isAccessibilityGranted ? "Permission Granted" : "Permission Required"
    }

    private var statusMessage: String {
        viewModel.isAccessibilityGranted
            ? "Accessibility permission has been granted. Restart Notimanager to begin using it."
            : "Click below to open System Settings and grant accessibility permission."
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary action button
            Button(action: {
                if viewModel.isAccessibilityGranted {
                    viewModel.restartApp()
                } else {
                    viewModel.requestAccessibilityPermission()
                }
            }) {
                Text(viewModel.isAccessibilityGranted ? "Restart Notimanager" : "Open System Settings…")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 0x00/255.0, green: 0x7A/255.0, blue: 0xFF/255.0))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)

            // Quit button (only when permission not granted)
            if !viewModel.isAccessibilityGranted {
                Button("Quit Notimanager") {
                    NSApp.terminate(nil)
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Permission Polling

    private func startPermissionPolling() {
        // Invalidate existing timer if any
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

// MARK: - Permission Feature Row

struct PermissionFeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 0x00/255.0, green: 0x7A/255.0, blue: 0xFF/255.0))
                .frame(width: 20)

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(red: 0x32/255.0, green: 0xD7/255.0, blue: 0x4B/255.0))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    PermissionView()
        .frame(width: 480, height: 620)
}
