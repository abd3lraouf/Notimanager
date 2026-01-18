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
            .frame(width: 28, height: 28)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .medium))
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
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color.color.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: systemName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(color.color)
                }

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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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
    let subtitle: String?
    let buttonTitle: String
    var buttonIcon: String? = nil
    let action: () -> Void

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

            Button(action: action) {
                HStack(spacing: 6) {
                    Text(buttonTitle)
                        .font(.system(size: 13, weight: .medium))

                    if let buttonIcon = buttonIcon {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF5/255.0))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Blip Settings Row (Help)

struct BlipHelpRow: View {
    let service: String
    let handle: String
    let buttonTitle: String
    var buttonIcon: String? = nil
    var iconImage: String? = nil
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Custom brand icon or fallback
            if let imageName = iconImage, let uiImage = NSImage(named: imageName) {
                Image(nsImage: uiImage)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                BlipIconView(systemName: "questionmark.circle", color: .blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(service)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                
                Text(handle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: action) {
                HStack(spacing: 6) {
                    Text(buttonTitle)
                        .font(.system(size: 13, weight: .medium))
                    
                    if let buttonIcon = buttonIcon {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF5/255.0))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Blip Settings Row (Info)

struct BlipInfoRow: View {
    let systemName: String
    let color: BlipIconColor
    let title: String
    let subtitle: String
    let buttonTitle: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BlipIconView(systemName: systemName, color: color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
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
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Blip Separator

struct BlipSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 0xE5/255.0, green: 0xE5/255.0, blue: 0xE5/255.0))
            .frame(height: 1)
            .padding(.leading, 52) // Aligns with text (28pt icon + 12pt spacing + 14pt left padding - adjusted)
    }
}

// MARK: - Blip Settings Row (Picker)

struct BlipPickerRow<T: Hashable & CaseIterable>: View where T.AllCases: RandomAccessCollection {
    let systemName: String
    let color: BlipIconColor
    let title: String
    var subtitle: String?
    @Binding var selection: T
    let displayValue: (T) -> String

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

            Picker("", selection: $selection) {
                ForEach(T.allCases, id: \.self) { option in
                    Text(displayValue(option))
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
            .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(displayValue(selection))
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
        )
    }
}
