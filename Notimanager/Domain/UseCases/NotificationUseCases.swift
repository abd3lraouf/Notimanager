//
//  NotificationUseCases.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Domain Layer: Use cases for notification actions.
//

import Foundation

class NotificationUseCases {
    private let repository: NotificationRepository
    
    init(repository: NotificationRepository) {
        self.repository = repository
    }
    
    func sendTestNotification() {
        repository.sendTestNotification()
    }
    
    func sendWidgetTestNotification() {
        repository.sendWidgetTestNotification()
    }
}
