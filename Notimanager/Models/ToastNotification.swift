//
//  ToastNotification.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Unified toast notification system for background operations
//

import Foundation
import AppKit

// MARK: - Toast Notification Type

/// The type of toast notification
enum ToastNotificationType: String, CaseIterable, Codable {
    case success
    case error
    case info
    
    var displayName: String {
        switch self {
        case .success:
            return "Success"
        case .error:
            return "Error"
        case .info:
            return "Info"
        }
    }
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var color: NSColor {
        switch self {
        case .success:
            return Colors.success
        case .error:
            return Colors.error
        case .info:
            return Colors.info
        }
    }
    
    var defaultDuration: TimeInterval {
        switch self {
        case .success:
            return 3.0
        case .error:
            return 5.0
        case .info:
            return 4.0
        }
    }
}

// MARK: - Toast Notification Model

/// Represents a single toast notification
struct ToastNotification: Identifiable, Equatable {
    let id: UUID
    let type: ToastNotificationType
    let title: String
    let message: String?
    let duration: TimeInterval
    let timestamp: Date
    
    init(
        type: ToastNotificationType,
        title: String,
        message: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration ?? type.defaultDuration
        self.timestamp = Date()
    }
    
    /// Creates a success toast
    static func success(_ title: String, message: String? = nil, duration: TimeInterval? = nil) -> ToastNotification {
        ToastNotification(type: .success, title: title, message: message, duration: duration)
    }
    
    /// Creates an error toast
    static func error(_ title: String, message: String? = nil, duration: TimeInterval? = nil) -> ToastNotification {
        ToastNotification(type: .error, title: title, message: message, duration: duration)
    }
    
    /// Creates an info toast
    static func info(_ title: String, message: String? = nil, duration: TimeInterval? = nil) -> ToastNotification {
        ToastNotification(type: .info, title: title, message: message, duration: duration)
    }
}

// MARK: - Toast Notification Delegate

/// Delegate for toast notification callbacks
protocol ToastNotificationDelegate: AnyObject {
    /// Called when a toast is shown
    func toastDidShow(_ toast: ToastNotification)
    
    /// Called when a toast is dismissed
    func toastDidDismiss(_ toast: ToastNotification)
    
    /// Called when a toast is about to expire
    func toastWillExpire(_ toast: ToastNotification)
}