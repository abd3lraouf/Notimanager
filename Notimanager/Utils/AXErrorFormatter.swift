//
//  AXErrorFormatter.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Utility for formatting Accessibility API errors into human-readable strings
//

import ApplicationServices

/// Utility for converting AXError values to human-readable strings
@available(macOS 10.15, *)
public enum AXErrorFormatter {

    // MARK: - Error Formatting

    /// Converts an AXError to a human-readable string
    /// - Parameter error: The AXError to format
    /// - Returns: A human-readable string representation
    public static func string(from error: AXError) -> String {
        switch error {
        case .success:
            return "success"
        case .failure:
            return "failure"
        case .illegalArgument:
            return "illegalArgument"
        case .invalidUIElement:
            return "invalidUIElement"
        case .invalidUIElementObserver:
            return "invalidUIElementObserver"
        case .cannotComplete:
            return "cannotComplete"
        case .attributeUnsupported:
            return "attributeUnsupported"
        case .actionUnsupported:
            return "actionUnsupported"
        case .notificationUnsupported:
            return "notificationUnsupported"
        case .notImplemented:
            return "notImplemented"
        case .notificationAlreadyRegistered:
            return "notificationAlreadyRegistered"
        case .notificationNotRegistered:
            return "notificationNotRegistered"
        case .apiDisabled:
            return "apiDisabled"
        case .noValue:
            return "noValue"
        case .parameterizedAttributeUnsupported:
            return "parameterizedAttributeUnsupported"
        case .notEnoughPrecision:
            return "notEnoughPrecision"
        @unknown default:
            return "unknown(\(error.rawValue))"
        }
    }

    // MARK: - Descriptive Messages

    /// Returns a user-friendly description for common errors
    /// - Parameter error: The AXError to describe
    /// - Returns: A user-friendly description
    public static func description(for error: AXError) -> String {
        switch error {
        case .apiDisabled:
            return "Accessibility API is disabled. Please grant accessibility permissions."
        case .invalidUIElement:
            return "The UI element is invalid or no longer exists."
        case .attributeUnsupported:
            return "This attribute is not supported by the element."
        case .actionUnsupported:
            return "This action is not supported by the element."
        case .notImplemented:
            return "This functionality is not implemented."
        case .notificationUnsupported:
            return "This notification type is not supported."
        default:
            return string(from: error)
        }
    }

    // MARK: - Error Checking

    /// Checks if an error indicates a permission issue
    /// - Parameter error: The AXError to check
    /// - Returns: True if the error is related to permissions
    public static func isPermissionError(_ error: AXError) -> Bool {
        return error == .apiDisabled || error == .invalidUIElementObserver
    }

    /// Checks if an error is recoverable
    /// - Parameter error: The AXError to check
    /// - Returns: True if the error might be temporary/recoverable
    public static func isRecoverable(_ error: AXError) -> Bool {
        switch error {
        case .cannotComplete, .notEnoughPrecision:
            return true
        default:
            return false
        }
    }

    /// Checks if an error should trigger a retry
    /// - Parameter error: The AXError to check
    /// - Returns: True if the operation should be retried
    public static func shouldRetry(_ error: AXError) -> Bool {
        switch error {
        case .cannotComplete, .notEnoughPrecision:
            return true
        case .noValue:
            return true // Element might not be ready yet
        default:
            return false
        }
    }
}

// MARK: - AXError Extensions

extension AXError {

    /// Human-readable string representation
    public var readableDescription: String {
        return AXErrorFormatter.string(from: self)
    }

    /// User-friendly description
    public var userDescription: String {
        return AXErrorFormatter.description(for: self)
    }

    /// Whether this is a permission error
    public var isPermissionError: Bool {
        return AXErrorFormatter.isPermissionError(self)
    }

    /// Whether this error is recoverable
    public var isRecoverable: Bool {
        return AXErrorFormatter.isRecoverable(self)
    }

    /// Whether the operation should be retried
    public var shouldRetry: Bool {
        return AXErrorFormatter.shouldRetry(self)
    }
}
