//
//  AccessibilityPermissionService.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Centralized accessibility permission management.
//  Extracts all AXIsProcessTrusted calls from NotificationMover.
//

import ApplicationServices
import AppKit
import Foundation

/// Service for managing accessibility permissions
@available(macOS 10.15, *)
class AccessibilityPermissionService {

    // MARK: - Singleton

    static let shared = AccessibilityPermissionService()

    private init() {}

    // MARK: - Permission Checking

    /// Checks if accessibility permissions are granted
    /// - Returns: True if granted
    func checkPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Checks if accessibility permissions are granted with optional prompt
    /// - Parameter showPrompt: Whether to show the system prompt
    /// - Returns: True if granted
    func checkPermissions(showPrompt: Bool) -> Bool {
        if showPrompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            return AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
        return AXIsProcessTrusted()
    }

    /// Requests accessibility permissions from the user
    /// - Parameter showPrompt: Whether to show the system prompt
    /// - Returns: True if permissions are granted
    func requestPermissions(showPrompt: Bool) -> Bool {
        if showPrompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            return AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
        return checkPermissions()
    }

    // MARK: - Permission Reset

    /// Resets accessibility permissions (for testing/troubleshooting)
    /// - Throws: Process error if reset fails
    func resetPermissions() throws {
        let bundleID = Bundle.main.bundleIdentifier ?? "dev.abd3lraouf.notimanager"

        let task = Process()
        task.launchPath = "/usr/bin/tccutil"
        task.arguments = ["reset", "Accessibility", bundleID]

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            throw PermissionError.resetFailed
        }
    }

    // MARK: - Permission Status

    /// Gets the current permission status
    /// - Returns: Permission status enum
    func getPermissionStatus() -> PermissionStatus {
        if AXIsProcessTrusted() {
            return .granted
        }
        return .denied
    }

    /// Gets trusted options with prompt flag
    /// - Parameter prompt: Whether to show prompt
    /// - Returns: CFDictionary of options
    func getTrustedOptions(prompt: Bool) -> CFDictionary {
        return [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
    }

    // MARK: - Permission Change Observation

    private var permissionObservers: [(PermissionStatus) -> Void] = []

    /// Observes permission changes
    /// - Parameter callback: Callback to execute when permissions change
    func observePermissionChanges(_ callback: @escaping (PermissionStatus) -> Void) {
        permissionObservers.append(callback)
    }

    /// Starts polling for permission changes
    /// - Parameter interval: Polling interval in seconds
    /// - Returns: Timer that can be invalidated to stop polling
    func startPermissionPolling(interval: TimeInterval = 1.0, onChange: @escaping (PermissionStatus) -> Void) -> Timer {
        var lastStatus = getPermissionStatus()

        return Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentStatus = self.getPermissionStatus()

            if currentStatus != lastStatus {
                lastStatus = currentStatus
                onChange(currentStatus)

                // Notify all observers
                self.permissionObservers.forEach { observer in
                    observer(currentStatus)
                }
            }
        }
    }

    // MARK: - Errors

    enum PermissionError: Error {
        case resetFailed
        case unknown
    }
}

// MARK: - AccessibilityPermissionProtocol Conformance

extension AccessibilityPermissionService: AccessibilityPermissionProtocol {

    func checkTrusted() -> Bool {
        return AXIsProcessTrusted()
    }

    func checkTrusted(withPrompt: Bool) -> Bool {
        return checkPermissions(showPrompt: withPrompt)
    }
}
