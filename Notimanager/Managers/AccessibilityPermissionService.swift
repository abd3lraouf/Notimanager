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
import CryptoKit
import CommonCrypto

/// Service for managing accessibility permissions
@available(macOS 10.15, *)
class AccessibilityPermissionService {

    // MARK: - Singleton

    static let shared = AccessibilityPermissionService()

    // MARK: - Constants

    private let codeSignatureKey = "dev.abd3lraouf.notimanager.lastCodeSignature"

    // MARK: - Initialization

    private init() {
        // Check for code signature changes on init
        _ = checkForSignatureChange()
    }

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

    // MARK: - Code Signature Tracking

    /// Gets the current code signature hash of the app
    /// - Returns: SHA256 hash of the code signature, or nil if unable to retrieve
    private func getCurrentCodeSignature() -> String? {
        guard Bundle.main.bundlePath != nil else { return nil }

        let task = Process()
        task.launchPath = "/usr/bin/codesign"
        task.arguments = ["-d", "-r", "-", Bundle.main.bundlePath ?? ""]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            // We'll hash the entire output to get a stable identifier
            return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        } catch {
            return nil
        }
    }

    /// Checks if the code signature has changed since last run
    /// - Returns: True if the signature has changed
    private func checkForSignatureChange() -> Bool {
        let currentSignature = getCurrentCodeSignature()
        let lastSignature = UserDefaults.standard.string(forKey: codeSignatureKey)

        if let current = currentSignature, let last = lastSignature {
            let hasChanged = current != last

            if hasChanged {
                LoggingService.shared.info(
                    "Code signature has changed. Old: \(last.prefix(16))... New: \(current.prefix(16))...",
                    category: "AccessibilityPermission"
                )

                // Store the new signature
                UserDefaults.standard.set(current, forKey: codeSignatureKey)

                return true
            }
        } else if let current = currentSignature {
            // First time storing signature
            UserDefaults.standard.set(current, forKey: codeSignatureKey)
        }

        return false
    }

    /// Checks if permissions appear to be in a stale state due to code signature change
    /// This happens when the app is in System Settings but AXIsProcessTrusted returns false
    /// - Returns: True if permissions are likely stale due to signature mismatch
    func isPermissionStateStale() -> Bool {
        // If we just detected a signature change, the state is stale
        let signatureChanged = checkForSignatureChange()

        // Check if the app appears in accessibility settings but doesn't report as trusted
        // This is a strong indicator of stale TCC database
        let isInSystemSettings = checkIfAppIsInAccessibilitySettings()
        let isNotTrusted = !AXIsProcessTrusted()

        let isStale = signatureChanged || (isInSystemSettings && isNotTrusted)

        if isStale {
            LoggingService.shared.warning(
                "Detected stale permission state - signature changed: \(signatureChanged), in settings but not trusted: \(isInSystemSettings && isNotTrusted)",
                category: "AccessibilityPermission"
            )
        }

        return isStale
    }

    /// Checks if the app appears in System Settings > Privacy & Security > Accessibility
    /// This uses tccutil to query the TCC database
    /// - Returns: True if the app appears in accessibility settings
    private func checkIfAppIsInAccessibilitySettings() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }

        let task = Process()
        task.launchPath = "/usr/bin/tccutil"
        task.arguments = ["list", "Accessibility"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return false }

            // Check if our bundle ID appears in the list
            return output.contains(bundleID)
        } catch {
            return false
        }
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
    @MainActor
    func startPermissionPolling(interval: TimeInterval = 1.0, onChange: @escaping (PermissionStatus) -> Void) -> Timer {
        var lastStatus = getPermissionStatus()

        return Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
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
