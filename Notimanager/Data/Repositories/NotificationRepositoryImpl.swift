//
//  NotificationRepositoryImpl.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Data Layer: Implementation of NotificationRepository.
//

import Foundation

class NotificationRepositoryImpl: NotificationRepository {
    private let coordinator: NotificationMoverCoordinator
    private let testService: TestNotificationService
    
    init(
        coordinator: NotificationMoverCoordinator = NotificationMover.shared.coordinator,
        testService: TestNotificationService = .shared
    ) {
        self.coordinator = coordinator
        self.testService = testService
    }
    
    func moveAllNotifications() {
        coordinator.moveAllNotifications()
    }
    
    func sendTestNotification() {
        testService.sendTestNotification()
    }
    
    func sendWidgetTestNotification() {
        testService.sendWidgetTestNotification()
    }
}
