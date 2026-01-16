//
//  ToastNotificationService.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  High-level service for showing toast notifications
//

import Foundation
import AppKit

// MARK: - Toast Notification Service

/// A high-level service that provides a simple API for showing toast notifications
/// This is the main entry point for displaying toasts in the application
class ToastNotificationService {
    
    // MARK: - Singleton
    
    static let shared = ToastNotificationService()
    
    private init() {
        // Private initializer for singleton
    }
    
    // MARK: - Properties
    
    /// The underlying toast notification manager
    private let manager = ToastNotificationManager.shared
    
    /// Logging service
    private let logger = LoggingService.shared
    
    // MARK: - Public API
    
    /// Shows a toast notification for background operations
    /// - Parameters:
    ///   - type: The type of toast (success, error, info)
    ///   - title: The title of the toast
    ///   - message: Optional detailed message
    ///   - duration: Optional custom duration in seconds
    func showToast(
        type: ToastNotificationType,
        title: String,
        message: String? = nil,
        duration: TimeInterval? = nil
    ) {
        let toast = ToastNotification(
            type: type,
            title: title,
            message: message,
            duration: duration
        )
        
        manager.show(toast)
    }
    
    /// Shows a success toast notification
    /// Use this for successful completion of background operations
    /// - Parameters:
    ///   - operation: The name of the operation that succeeded
    ///   - details: Optional details about the success
    ///   - duration: Optional custom duration
    func showSuccess(
        operation: String,
        details: String? = nil,
        duration: TimeInterval? = nil
    ) {
        let title = "✅ \(operation) completed successfully"
        manager.showSuccess(title, message: details, duration: duration)
    }
    
    /// Shows an error toast notification
    /// Use this for failed background operations
    /// - Parameters:
    ///   - operation: The name of the operation that failed
    ///   - error: The error that occurred
    ///   - duration: Optional custom duration
    func showError(
        operation: String,
        error: Error,
        duration: TimeInterval? = nil
    ) {
        let title = "❌ \(operation) failed"
        let message = error.localizedDescription
        manager.showError(title, message: message, duration: duration)
    }
    
    /// Shows an error toast notification with a custom message
    /// - Parameters:
    ///   - operation: The name of the operation that failed
    ///   - errorMessage: Custom error message
    ///   - duration: Optional custom duration
    func showError(
        operation: String,
        errorMessage: String,
        duration: TimeInterval? = nil
    ) {
        let title = "❌ \(operation) failed"
        manager.showError(title, message: errorMessage, duration: duration)
    }
    
    /// Shows an info toast notification
    /// Use this for informational messages about background operations
    /// - Parameters:
    ///   - operation: The name of the operation
    ///   - message: The informational message
    ///   - duration: Optional custom duration
    func showInfo(
        operation: String,
        message: String,
        duration: TimeInterval? = nil
    ) {
        let title = "ℹ️ \(operation)"
        manager.showInfo(title, message: message, duration: duration)
    }
    
    /// Shows a progress toast notification
    /// Use this for indicating that a background operation is in progress
    /// - Parameters:
    ///   - operation: The name of the operation in progress
    ///   - details: Optional details about the progress
    func showProgress(
        operation: String,
        details: String? = nil
    ) {
        let title = "🔄 \(operation) in progress..."
        manager.showInfo(title, message: details, duration: nil)
    }
    
    /// Shows a toast for test generation operations
    /// - Parameters:
    ///   - success: Whether the test generation was successful
    ///   - count: Number of tests generated (if successful)
    ///   - error: Error if generation failed
    func showTestGenerationResult(
        success: Bool,
        count: Int? = nil,
        error: Error? = nil
    ) {
        if success {
            if let count = count {
                showSuccess(
                    operation: "Test generation",
                    details: "Successfully generated \(count) test\(count == 1 ? "" : "s")"
                )
            } else {
                showSuccess(
                    operation: "Test generation",
                    details: "Tests generated successfully"
                )
            }
        } else if let error = error {
            showError(
                operation: "Test generation",
                error: error
            )
        }
    }
    
    /// Shows a toast for data seeding operations
    /// - Parameters:
    ///   - success: Whether the data seeding was successful
    ///   - count: Number of records seeded (if successful)
    ///   - error: Error if seeding failed
    func showDataSeedingResult(
        success: Bool,
        count: Int? = nil,
        error: Error? = nil
    ) {
        if success {
            if let count = count {
                showSuccess(
                    operation: "Data seeding",
                    details: "Successfully seeded \(count) record\(count == 1 ? "" : "s")"
                )
            } else {
                showSuccess(
                    operation: "Data seeding",
                    details: "Data seeded successfully"
                )
            }
        } else if let error = error {
            showError(
                operation: "Data seeding",
                error: error
            )
        }
    }
    
    /// Shows a toast for report generation operations
    /// - Parameters:
    ///   - success: Whether the report generation was successful
    ///   - reportName: Name of the generated report (if successful)
    ///   - error: Error if generation failed
    func showReportGenerationResult(
        success: Bool,
        reportName: String? = nil,
        error: Error? = nil
    ) {
        if success {
            if let reportName = reportName {
                showSuccess(
                    operation: "Report generation",
                    details: "Successfully generated '\(reportName)' report"
                )
            } else {
                showSuccess(
                    operation: "Report generation",
                    details: "Report generated successfully"
                )
            }
        } else if let error = error {
            showError(
                operation: "Report generation",
                error: error
            )
        }
    }
    
    /// Dismisses all current toasts
    func dismissAllToasts() {
        manager.clearAllToasts()
    }
    
    /// Gets the current number of toasts in queue
    var queueCount: Int {
        return manager.queueCount
    }
    
    /// Gets the currently displayed toast (if any)
    var currentToast: ToastNotification? {
        return manager.currentToastNotification
    }
}

// MARK: - Convenience Extensions

extension ToastNotificationService {
    
    /// Shows a toast for generic background operations
    /// - Parameters:
    ///   - operationType: The type of operation (e.g., "Test Generation", "Data Seeding")
    ///   - success: Whether the operation was successful
    ///   - details: Details about the result
    ///   - error: Error if the operation failed
    func showBackgroundOperationResult(
        operationType: String,
        success: Bool,
        details: String? = nil,
        error: Error? = nil
    ) {
        if success {
            showSuccess(
                operation: operationType,
                details: details
            )
        } else if let error = error {
            showError(
                operation: operationType,
                error: error
            )
        }
    }
}