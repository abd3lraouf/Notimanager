//
//  SettingsUseCases.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Domain Layer: Use cases for modifying settings.
//

import Foundation

class UpdateSettingsUseCase {
    private let repository: SettingsRepository
    private let systemRepository: SystemRepository
    private let notificationRepository: NotificationRepository
    
    init(
        repository: SettingsRepository,
        systemRepository: SystemRepository,
        notificationRepository: NotificationRepository
    ) {
        self.repository = repository
        self.systemRepository = systemRepository
        self.notificationRepository = notificationRepository
    }
    
    func setEnabled(_ enabled: Bool) {
        repository.setEnabled(enabled)
        systemRepository.donateActivity(type: .toggleEnabled(enabled))
    }
    
    func setPosition(_ position: NotificationPosition) {
        repository.setPosition(position)
        systemRepository.donateActivity(type: .changePosition(position))
        notificationRepository.moveAllNotifications()
    }
    
    func setMenuBarIconHidden(_ hidden: Bool) {
        repository.setMenuBarIconHidden(hidden)
    }
    
    func setIconColor(_ color: IconColor) {
        repository.setIconColor(color)
    }
    
    func setDebugMode(_ enabled: Bool) {
        repository.setDebugMode(enabled)
    }
    
    func setOpenSettingsAtLaunch(_ enabled: Bool) {
        repository.setOpenSettingsAtLaunch(enabled)
    }
    
    func updateInterception(notifications: Bool, widgets: Bool, appleWidgets: Bool) {
        repository.setInterception(
            notifications: notifications,
            widgets: widgets,
            appleWidgets: appleWidgets
        )
    }
}
