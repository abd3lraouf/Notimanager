//
//  NotificationRepository.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Domain Layer: Interface for notification operations.
//

import Foundation

protocol NotificationRepository {
    func moveAllNotifications()
    func sendTestNotification()
    func sendWidgetTestNotification()
}
