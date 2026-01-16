//
//  MonitorDelegate.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Protocol for monitor service callbacks to the coordinator.
//

import AppKit
import Foundation

/// Protocol for monitor service callbacks
@available(macOS 10.15, *)
protocol MonitorDelegate: AnyObject {

    /// Called when a new notification is detected
    /// - Parameters:
    ///   - element: The AXUIElement of the notification
    ///   - size: The size of the notification
    func monitorDidDetectNotification(_ element: AXUIElement, size: CGSize)

    /// Called when a notification is dismissed
    /// - Parameter element: The AXUIElement of the dismissed notification
    func monitorDidDismissNotification(_ element: AXUIElement)

    /// Called when all notifications should be moved (e.g., after widget closes)
    func monitorShouldMoveAllNotifications()
}
