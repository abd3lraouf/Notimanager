//
//  TestNotificationService.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Standalone service for test notification handling
//

import AppKit
import Foundation
import UserNotifications
import os.log

// MARK: - Test Notification Service Delegate

/// Delegate protocol for test notification service callbacks
@available(macOS 10.15, *)
protocol TestNotificationServiceDelegate: AnyObject {

    /// Called when test notification is sent successfully
    func testNotificationDidSend()

    /// Called when test notification fails to send
    /// - Parameter error: The error that occurred
    func testNotificationDidFail(error: Error)

    /// Called when test notification status changes
    /// - Parameter status: The new status message
    func testNotificationStatusDidChange(_ status: TestNotificationStatus)

    /// Called when notification permission status changes
    /// - Parameter status: The new authorization status
    func notificationPermissionStatusDidChange(_ status: UNAuthorizationStatus)
}

// MARK: - Test Notification Status

/// Represents the current state of test notification
enum TestNotificationStatus: Equatable {
    case idle
    case checkingPermissions
    case sending
    case waitingForInterception
    case interceptedSuccessfully
    case notIntercepted
    case permissionDenied
    case permissionError(String)
    case sendingFailed(String)
    case unknownStatus

    var displayMessage: String {
        switch self {
        case .idle:
            return "Not tested yet"
        case .checkingPermissions:
            return "Checking permissions..."
        case .sending:
            return "Sending test notification..."
        case .waitingForInterception:
            return "Waiting for notification..."
        case .interceptedSuccessfully:
            return "✓ Intercepted & moved successfully!"
        case .notIntercepted:
            return "ℹ️ Try a real notification (Calendar, Mail, Messages)"
        case .permissionDenied:
            return "✗ Permission denied"
        case .permissionError(let message):
            return "✗ \(message)"
        case .sendingFailed(let message):
            return "✗ \(message)"
        case .unknownStatus:
            return "✗ Unknown permission status"
        }
    }

    var textColor: NSColor {
        switch self {
        case .idle, .checkingPermissions, .sending:
            return .secondaryLabelColor
        case .waitingForInterception, .notIntercepted:
            return .systemOrange
        case .interceptedSuccessfully:
            return .systemGreen
        case .permissionDenied, .permissionError, .sendingFailed, .unknownStatus:
            return .systemRed
        }
    }
}

// MARK: - Test Notification Service

/// Standalone service for managing test notifications
/// Handles permission checking, notification sending, and interception tracking
@available(macOS 10.15, *)
class TestNotificationService {

    // MARK: - Singleton

    static let shared = TestNotificationService()

    private init() {
        // Private initializer for singleton
    }

    // MARK: - Properties

    /// Delegate for status callbacks
    weak var delegate: TestNotificationServiceDelegate?

    /// UNUserNotificationCenter instance
    private let notificationCenter = UNUserNotificationCenter.current()

    /// Logging service
    private let logger = LoggingService.shared

    /// Current test notification status
    private(set) var currentStatus: TestNotificationStatus = .idle {
        didSet {
            if currentStatus != oldValue {
                notifyStatusChange()
            }
        }
    }

    /// Timestamp when last test notification was sent
    private(set) var lastNotificationTime: Date?

    /// Whether the last test notification was intercepted
    private(set) var notificationWasIntercepted: Bool = false

    /// Current notification position setting
    var currentPosition: NotificationPosition = .topMiddle

    /// Time window for interception detection (seconds)
    let interceptionWindow: TimeInterval = 6.0

    /// Delay before checking interception status (seconds)
    let interceptionCheckDelay: TimeInterval = 5.0

    // MARK: - Public API

    /// Sends a test notification with permission checking
    /// - Parameter position: The target position for the notification
    func sendTestNotification(to position: NotificationPosition? = nil) {
        logger.debug("Sending test notification...")

        // Update position if provided
        if let position = position {
            currentPosition = position
        }

        // Update status
        currentStatus = .checkingPermissions

        // Check current notification authorization status
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    // Permission granted, send the notification
                    self.logger.debug("Notification permission is granted, sending test...")
                    self.performSendTestNotification()

                case .denied:
                    // Permission denied, show helpful message
                    self.logger.debug("Notification permission denied by user")
                    self.currentStatus = .permissionDenied
                    self.delegate?.notificationPermissionStatusDidChange(.denied)
                    self.showPermissionDeniedAlert()

                case .notDetermined:
                    // Permission not yet requested, request it now
                    self.logger.debug("Notification permission not determined, requesting...")
                    self.requestPermissionAndSend()

                @unknown default:
                    self.logger.debug("Unknown notification authorization status")
                    self.currentStatus = .unknownStatus
                }
            }
        }
    }

    /// Sends a simple test notification without permission checking
    /// Use this when permissions are already known to be granted
    /// - Parameter delay: Delay before sending (default: 1 second)
    func sendSimpleTestNotification(delay: TimeInterval = 1.0) {
        logger.debug("Sending simple test notification...")

        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "If you see this, Notimanager is working!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.logger.debug("Failed to send test notification: \(error.localizedDescription)")
                self.delegate?.testNotificationDidFail(error: error)
            } else {
                self.logger.debug("Test notification sent successfully")
                self.delegate?.testNotificationDidSend()
            }
        }
    }

    /// Checks if a notification should be counted as test notification interception
    /// - Parameters:
    ///   - windowSize: The size of the notification window
    ///   - timestamp: The timestamp of the notification
    /// - Returns: True if this is a test notification that should be tracked
    func shouldTrackAsTestNotification(windowSize: CGSize, timestamp: Date = Date()) -> Bool {
        // Check if we're within the interception window
        guard let lastTest = lastNotificationTime else { return false }
        let timeSinceTest = timestamp.timeIntervalSince(lastTest)

        guard timeSinceTest < interceptionWindow else { return false }

        // Only count banner-sized windows, not NC panel
        return windowSize.width < 600 && windowSize.height < 200
    }

    /// Records that a test notification was intercepted
    /// - Parameter success: Whether the interception was successful
    func recordInterception(success: Bool) {
        notificationWasIntercepted = success

        if success {
            logger.debug("✅ Test notification was intercepted and moved!")
            currentStatus = .interceptedSuccessfully
        } else {
            logger.debug("ℹ️ Test notification was NOT intercepted - may be in Notification Center panel")
            currentStatus = .notIntercepted
        }

        // Notify delegate
        delegate?.testNotificationStatusDidChange(currentStatus)
    }

    /// Resets the test notification state
    func reset() {
        notificationWasIntercepted = false
        lastNotificationTime = nil
        currentStatus = .idle
        logger.debug("Test notification state reset")
    }

    /// Returns the current interception status for UI display
    /// - Returns: Tuple of (wasIntercepted: Bool, timeSinceTest: TimeInterval?)
    func getInterceptionStatus() -> (Bool, TimeInterval?) {
        let timeSinceTest: TimeInterval?
        if let lastTest = lastNotificationTime {
            timeSinceTest = Date().timeIntervalSince(lastTest)
        } else {
            timeSinceTest = nil
        }
        return (notificationWasIntercepted, timeSinceTest)
    }

    // MARK: - Private Methods

    /// Performs the actual sending of the test notification
    private func performSendTestNotification() {
        // Reset tracking
        notificationWasIntercepted = false
        lastNotificationTime = Date()

        // Update status
        currentStatus = .sending

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Notimanager Test"
        content.body = "If you see this at \(currentPosition.displayName), it's working! 🎯"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        // Send the notification
        notificationCenter.add(request) { [weak self] error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.logger.debug("Failed to send test notification: \(error)")
                    self.currentStatus = .sendingFailed("Failed to send")
                    self.delegate?.testNotificationDidFail(error: error)
                } else {
                    self.logger.debug("Test notification sent successfully")
                    self.currentStatus = .waitingForInterception
                    self.delegate?.testNotificationDidSend()

                    // Check after delay if it was intercepted
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + self.interceptionCheckDelay
                    ) { [weak self] in
                        self?.checkInterceptionStatus()
                    }
                }
            }
        }
    }

    /// Requests notification permission and sends test if granted
    private func requestPermissionAndSend() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) {
            [weak self] granted, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.logger.debug("Error requesting notification permission: \(error)")
                    self.currentStatus = .permissionError("Permission error")
                    self.delegate?.testNotificationDidFail(error: error)
                    return
                }

                if granted {
                    self.logger.debug("Notification permission granted, sending test...")
                    self.delegate?.notificationPermissionStatusDidChange(.authorized)
                    self.performSendTestNotification()
                } else {
                    self.logger.debug("User denied notification permission")
                    self.currentStatus = .permissionDenied
                    self.delegate?.notificationPermissionStatusDidChange(.denied)
                    self.showPermissionDeniedAlert()
                }
            }
        }
    }

    /// Checks the interception status after the delay period
    private func checkInterceptionStatus() {
        if notificationWasIntercepted {
            currentStatus = .interceptedSuccessfully
            logger.debug("Test notification was successfully intercepted")
        } else {
            currentStatus = .notIntercepted
            logger.debug("Test notification was NOT intercepted - may be in Notification Center panel")
        }

        delegate?.testNotificationStatusDidChange(currentStatus)
    }

    /// Shows alert when notification permission is denied
    private func showPermissionDeniedAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let alert = NSAlert()
            alert.messageText = "Notification Permission Denied"
            alert.informativeText = """
            Notimanager needs notification permission to send test notifications.

            To enable notifications:
            1. Open System Settings
            2. Go to Notifications
            3. Find Notimanager in the list
            4. Enable "Allow Notifications"
            """
            alert.alertStyle = .informational
            alert.icon = NSImage(
                systemSymbolName: "bell.slash.fill",
                accessibilityDescription: "Notifications Disabled"
            )
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")

            if alert.runModal() == .alertFirstButtonReturn {
                // Open System Settings to Notifications
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    /// Notifies delegate of status change
    private func notifyStatusChange() {
        delegate?.testNotificationStatusDidChange(currentStatus)
    }
}

// MARK: - UI Support

extension TestNotificationService {

    /// Status label for displaying test results
    private weak var statusLabel: NSTextField?

    /// Sets the status label for UI updates
    /// - Parameter label: The label to update
    func setStatusLabel(_ label: NSTextField?) {
        objc_setAssociatedObject(self, &AssociatedKeys.statusLabel, label, .OBJC_ASSOCIATION_ASSIGN)
        updateStatusLabel()
    }

    /// Gets the current status label
    var currentStatusLabel: NSTextField? {
        objc_getAssociatedObject(self, &AssociatedKeys.statusLabel) as? NSTextField
    }

    /// Updates the status label with current status
    private func updateStatusLabel() {
        guard let label = currentStatusLabel else { return }

        DispatchQueue.main.async {
            label.stringValue = self.currentStatus.displayMessage
            label.textColor = self.currentStatus.textColor
        }
    }

    // Associated object keys for UI storage
    private struct AssociatedKeys {
        static var statusLabel: UInt8 = 0
    }
}

// MARK: - Convenience Extensions

extension TestNotificationService {

    /// Send test notification with closure callbacks
    /// - Parameters:
    ///   - position: Target position
    ///   - completion: Callback with result
    func sendTestNotification(
        to position: NotificationPosition? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Create temporary delegate
        class TemporaryDelegate: TestNotificationServiceDelegate {
            let completion: (Result<Void, Error>) -> Void

            init(completion: @escaping (Result<Void, Error>) -> Void) {
                self.completion = completion
            }

            func testNotificationDidSend() {
                completion(.success(()))
            }

            func testNotificationDidFail(error: Error) {
                completion(.failure(error))
            }

            func testNotificationStatusDidChange(_ status: TestNotificationStatus) {
                // Status changes are informational
            }

            func notificationPermissionStatusDidChange(_ status: UNAuthorizationStatus) {
                // Permission status changes are informational
            }
        }

        let tempDelegate = TemporaryDelegate(completion: completion)

        // Store original delegate
        let originalDelegate = delegate

        // Set temporary delegate
        delegate = tempDelegate

        // Send notification
        sendTestNotification(to: position)

        // Restore original delegate after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + interceptionCheckDelay + 1.0) { [weak self] in
            self?.delegate = originalDelegate
        }
    }
}
