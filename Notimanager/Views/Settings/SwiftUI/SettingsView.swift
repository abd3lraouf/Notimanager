//
//  SettingsView.swift
//  Notimanager
//
//  Created on 2026-01-18.
//  Standalone SettingsView with custom toolbar and top-aligned layout.
//

import SwiftUI

struct SettingsView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case general, interception, advanced, help
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .general: return SettingsStrings.Tabs.general
            case .interception: return SettingsStrings.Tabs.notifications
            case .advanced: return SettingsStrings.Tabs.advanced
            case .help: return SettingsStrings.Tabs.help
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .interception: return "app.dashed"
            case .advanced: return "slider.horizontal.3"
            case .help: return "lifepreserver"
            }
        }
    }

    @AppStorage("selectedSettingsTab") private var selectedTab: Tab = .general

    var body: some View {
        VStack(spacing: 0) {
            // Compact Toolbar
            toolbarView
            
            Divider()
            
            // Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    contentView
                        .padding(0) // Cards have their own padding
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: 480, height: 520) // Compact window
        .background(Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF7/255.0))
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHelpTab)) { _ in
            selectedTab = .help
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsFromAppKit)) { notification in
            if let tabName = notification.object as? String,
               let tab = Tab(rawValue: tabName.lowercased()) {
                selectedTab = tab
            }
        }
    }
    
    private var toolbarView: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                            .symbolRenderingMode(.monochrome)
                        
                        Text(tab.title)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 48) // Compact toolbar
        .background(Color.white)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsView(viewModel: DependencyContainer.shared.makeGeneralSettingsViewModel())
        case .interception:
            InterceptionSettingsView(viewModel: DependencyContainer.shared.makeInterceptionSettingsViewModel())
        case .advanced:
            AdvancedSettingsView(viewModel: DependencyContainer.shared.makeAdvancedSettingsViewModel())
        case .help:
            HelpSettingsView()
        }
    }
}
