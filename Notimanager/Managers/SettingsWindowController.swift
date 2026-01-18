//
//  SettingsWindowController.swift
//  Notimanager
//
//  Created on 2026-01-18.
//  Manages a custom NSWindow for Settings to avoid Dock icon appearance
//

import AppKit
import SwiftUI

class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var settingsWindow: NSWindow?
    private var windowDelegate: NSWindowDelegate?

    private override init() {
        super.init()
    }

    func show(tab: String = "general") {
        if settingsWindow == nil {
            createWindow()
        }
        
        guard let window = settingsWindow else { return }
        
        // Bring to front
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Handle tab navigation via notification (SettingsView listens for this)
        // Give the window a moment to load content if it was just created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if tab == "help" {
                NotificationCenter.default.post(name: .navigateToHelpTab, object: nil)
            } else {
                NotificationCenter.default.post(name: .openSettingsFromAppKit, object: tab)
            }
        }
    }
    
    private func createWindow() {
        // Create the SwiftUI view
        // Ideally we should inject dependencies here same as in NotimanagerApp
        let settingsView = SettingsView()
            .environmentObject(AppStore.shared)
            // handleSettingsRequests is likely not needed for custom window but harmless
            //.handleSettingsRequests() 
        
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Notimanager Settings"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.minSize = NSSize(width: 480, height: 400)
        
        // Set an identifier for finding it later if needed
        window.identifier = NSUserInterfaceItemIdentifier("CustomSettingsWindow")
        
        self.settingsWindow = window
    }
    
    func windowWillClose(_ notification: Notification) {
        // Clean up or reset state if needed
        // We keep the window instance alive but hidden (standard macOS behavior)
        // or we could release it. Here we explicitly keep it as isReleasedWhenClosed = false
        NotificationCenter.default.post(name: .settingsWindowClosed, object: nil)
    }
}
