//
//  HelpSettingsView.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  SwiftUI Help/About settings view following Blip Settings design system.
//  Refined wording for clarity and marketing appeal.
//

import SwiftUI

struct HelpSettingsView: View {
    @Environment(\.openURL) var openURL

    private let viewModel = AboutViewModel()

    var body: some View {
        VStack(spacing: 16) {
            // App Info Card
            appInfoCard

            // Links Card
            linksCard

            // Support Card
            supportCard
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
    }

    // MARK: - App Info Card

    private var appInfoCard: some View {
        BlipCard {
            VStack(spacing: 0) {
                // App icon and name
                HStack(spacing: 16) {
                    // App icon
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.versionDisplayString)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)

                        Text(viewModel.creditsDisplayString)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Links Card

    private var linksCard: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Personal GitHub
                BlipHelpRow(
                    service: "Created by",
                    handle: "@\(viewModel.githubUsername)",
                    buttonTitle: "Visit Profile…",
                    buttonIcon: "arrow.up.right",
                    iconImage: nil,
                    action: { openURL(viewModel.personalGitHubURL) }
                )

                BlipSeparator()

                // Repository
                BlipHelpRow(
                    service: "Open Source",
                    handle: "View on GitHub",
                    buttonTitle: "View Code…",
                    buttonIcon: "arrow.up.right",
                    iconImage: nil,
                    action: { openURL(viewModel.repositoryURL) }
                )
            }
        }
    }

    // MARK: - Support Card

    private var supportCard: some View {
        BlipCard {
            VStack(spacing: 0) {
                // Report a bug
                BlipHelpRow(
                    service: "Report an Issue",
                    handle: "Submit an issue on GitHub",
                    buttonTitle: "Report…",
                    buttonIcon: "arrow.up.right",
                    iconImage: nil,
                    action: { openURL(URL(string: "\(viewModel.repositoryURL)/issues")!) }
                )

                BlipSeparator()

                // License
                BlipHelpRow(
                    service: "License",
                    handle: viewModel.license,
                    buttonTitle: "View License…",
                    buttonIcon: "arrow.up.right",
                    iconImage: nil,
                    action: { openURL(viewModel.licenseURL) }
                )

                BlipSeparator()

                // Copyright
                HStack(spacing: 12) {
                    BlipIconView(systemName: "c.circle", color: .gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Copyright")
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)

                        Text(viewModel.copyright)
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
}

// MARK: - Preview

#Preview {
    HelpSettingsView()
}