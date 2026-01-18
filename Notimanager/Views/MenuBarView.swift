//
//  MenuBarView.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Menu bar view using MVI pattern with MenuBarViewModel.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var viewModel: MenuBarViewModel
    let coordinator: CoordinatorAction?

    init(viewModel: MenuBarViewModel, coordinator: CoordinatorAction?) {
        self.viewModel = viewModel
        self.coordinator = coordinator
    }

    var body: some View {
        // Enable toggle
        Toggle("Enable Positioning", isOn: Binding(
            get: { viewModel.state.isEnabled },
            set: { viewModel.process(.setEnabled($0)) }
        ))
        .keyboardShortcut("e", modifiers: [.command])

        Divider()

        Menu(content: {
            ForEach(NotificationPosition.allCases, id: \.rawValue) { position in
                Button {
                    viewModel.process(.changePosition(position))
                } label: {
                    HStack {
                        Text(viewModel.state.currentPosition == position ? "✓" : "")
                        Text(position.displayName)
                    }
                }
            }
        }, label: {
            Text("Screen Corner \(viewModel.state.currentPosition.displayName)")
                .foregroundColor(.secondary)
        })

        Divider()

        // Custom SettingsLink that brings window to front
        PreferencesSettingsLink {
            Text("Preferences…")
        }
        .keyboardShortcut(",", modifiers: [.command])

        Button("Check for Updates…") {
            viewModel.process(.checkForUpdates)
        }

        Divider()

        // Custom SettingsLink that navigates to Help tab
        AboutSettingsLink {
            Text("About Notimanager")
        }

        Button("Quit Notimanager") {
            viewModel.process(.quitApp)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}

// MARK: - Settings Links

struct PreferencesSettingsLink: View {
    let label: () -> Text
    @Environment(\.openSettings) var openSettings

    var body: some View {
        Button(action: {
            // Post notification to bring Settings window to front
            NotificationCenter.default.post(name: .bringSettingsToFront, object: nil)
            // Then open settings using the environment value
            openSettings()
        }, label: label)
    }
}

struct AboutSettingsLink: View {
    let label: () -> Text
    @Environment(\.openSettings) var openSettings

    var body: some View {
        Button(action: {
            // Post notification BEFORE opening settings
            NotificationCenter.default.post(name: .navigateToHelpTab, object: nil)
            // Then open settings using the environment value
            openSettings()
        }, label: label)
    }
}
