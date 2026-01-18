//
//  PermissionViewModel.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  ViewModel for permission screen - manages accessibility permission state.
//  Updated for SwiftUI with @Published properties.
//

import Foundation
import Combine
import Cocoa

/// ViewModel for PermissionView (SwiftUI)
@available(macOS 10.15, *)
class PermissionViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isAccessibilityGranted: Bool = false
    @Published var isWaitingForPermission: Bool = false

    // MARK: - Initialization

    init() {
        self.isAccessibilityGranted = AXIsProcessTrusted()
    }

    // MARK: - Permission Management

    func requestAccessibilityPermission() {
        debugLog("User requested accessibility permission")

        isWaitingForPermission = true

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func updatePermissionStatus(granted: Bool) {
        isAccessibilityGranted = granted
        isWaitingForPermission = false
    }

    func restartApp() {
        debugLog("Restarting app...")

        // Use the industry-standard AppRestart utility
        AppRestart.restart(delay: 0.5)
    }

    // MARK: - Helpers

    private func debugLog(_ message: String) {
        LoggingService.shared.debug(message)
    }
}
