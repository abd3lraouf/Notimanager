//
//  BlipSettingsRow.swift
//  Notimanager
//
//  SwiftUI Blip Settings row component with vibrant colored icons.
//  Following Blip Settings design system specifications.
//

import SwiftUI

// MARK: - Blip Icon Colors

enum BlipIconColor {
    case green      // Launch at login, startup settings
    case red        // Sound effects, destructive actions
    case purple     // Auto-accept, smart features
    case blue       // Files, storage, data settings
    case gray       // Inactive, info, secondary settings
    case orange     // Warnings, cautious settings
    case cyan       // Sync, cloud settings

    var color: Color {
        switch self {
        case .green: return Color(red: 0x32/255.0, green: 0xD7/255.0, blue: 0x4B/255.0)
        case .red: return Color(red: 0xFF/255.0, green: 0x37/255.0, blue: 0x5F/255.0)
        case .purple: return Color(red: 0xBF/255.0, green: 0x5A/255.0, blue: 0xF2/255.0)
        case .blue: return Color(red: 0x00/255.0, green: 0x7A/255.0, blue: 0xFF/255.0)
        case .gray: return Color(red: 0x8E/255.0, green: 0x8E/255.0, blue: 0x93/255.0)
        case .orange: return Color(red: 0xFF/255.0, green: 0x95/255.0, blue: 0x00/255.0)
        case .cyan: return Color(red: 0x32/255.0, green: 0xAD/255.0, blue: 0xE6/255.0)
        }
    }
}

// MARK: - Blip Icon View

struct BlipIconView: View {
    let systemName: String
    let color: BlipIconColor

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(color.color)
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }
    }
}

// MARK: - Blip Settings Row (Toggle)

struct BlipToggleRow: View {
    let systemName: String
    let color: BlipIconColor
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            BlipIconView(systemName: systemName, color: color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

// MARK: - Blip Settings Row (Action)

struct BlipActionRow: View {
    let systemName: String
    let color: BlipIconColor
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BlipIconView(systemName: systemName, color: color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Blip Separator

struct BlipSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 0xE5/255.0, green: 0xE5/255.0, blue: 0xE5/255.0))
            .frame(height: 1)
            .padding(.leading, 60) // Aligns with text, not icon
    }
}

// MARK: - Blip Card

struct BlipCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}
