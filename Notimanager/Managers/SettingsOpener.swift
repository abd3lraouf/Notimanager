//
//  SettingsOpener.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Bridge between AppKit and SwiftUI for opening Settings using @Environment(\.openSettings)
//

import SwiftUI
import AppKit
import Combine

protocol SettingsOpening {
    func openSettings(tab: String)
}

/// Global settings opener that can be called from AppKit
/// Handles opening mechanism robustly whether window is open or closed
@available(macOS 14.0, *)
class SettingsOpener: ObservableObject, SettingsOpening {
    static let shared = SettingsOpener()

    /// Buffer for storing the requested tab when window is not yet active
    var pendingTab: String? = nil

    private init() {}

    /// Opens settings to the specified tab
    /// Delegates to SettingsWindowController to show the custom window
    func openSettings(tab: String = "general") {
        LoggingService.shared.debug("SettingsOpener: Requested to open settings tab: \(tab)", category: "Settings")
        
        Task { @MainActor in
            // Use custom window controller to avoid Dock icon (activation policy change)
            SettingsWindowController.shared.show(tab: tab)
            
            LoggingService.shared.debug("SettingsOpener: Delegated to SettingsWindowController", category: "Settings")
        }
    }
}

/// View modifier that captures openSettings environment and responds to requests
struct SettingsHandler: ViewModifier {
    // Legacy support or internal navigation only
    func body(content: Content) -> some View {
        content
            .onAppear {
                 // No-op for custom window approach
            }
            .onReceive(NotificationCenter.default.publisher(for: .openSettingsFromAppKit)) { notification in
                // Handle tab switching within the view
                if let targetTab = notification.object as? String {
                     // The logic to actually switch tabs is inside SettingsView using .onReceive
                     // We just ensure we propagate if needed, but SettingsView likely handles it.
                }
            }
    }
    
    // ... helper methods removed as they are no longer needed ...
}

// Extension remains but handler is largely empty now
extension View {
    func handleSettingsRequests() -> some View {
        self.modifier(SettingsHandler())
    }
}

