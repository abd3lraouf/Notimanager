//
//  SettingsRepositoryImpl.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Data Layer: Implementation of SettingsRepository using ConfigurationManager.
//

import Combine
import Foundation

class SettingsRepositoryImpl: SettingsRepository {
    private let configManager: ConfigurationManager
    
    init(configManager: ConfigurationManager = .shared) {
        self.configManager = configManager
    }
    
    var isEnabled: AnyPublisher<Bool, Never> {
        configManager.$isEnabled.eraseToAnyPublisher()
    }
    
    var currentPosition: AnyPublisher<NotificationPosition, Never> {
        configManager.$currentPosition.eraseToAnyPublisher()
    }
    
    var isMenuBarIconHidden: AnyPublisher<Bool, Never> {
        configManager.$isMenuBarIconHidden.eraseToAnyPublisher()
    }
    
    var iconColor: AnyPublisher<IconColor, Never> {
        configManager.$iconColor.eraseToAnyPublisher()
    }
    
    var debugMode: AnyPublisher<Bool, Never> {
        configManager.$debugMode.eraseToAnyPublisher()
    }
    
    var openSettingsAtLaunch: AnyPublisher<Bool, Never> {
        configManager.$openSettingsAtLaunch.eraseToAnyPublisher()
    }
    
    var interceptNotifications: AnyPublisher<Bool, Never> {
        configManager.$interceptNotifications.eraseToAnyPublisher()
    }
    
    var interceptWidgets: AnyPublisher<Bool, Never> {
        configManager.$interceptWidgets.eraseToAnyPublisher()
    }
    
    var includeAppleWidgets: AnyPublisher<Bool, Never> {
        configManager.$includeAppleWidgets.eraseToAnyPublisher()
    }
    
    func setEnabled(_ enabled: Bool) {
        configManager.isEnabled = enabled
    }
    
    func setPosition(_ position: NotificationPosition) {
        configManager.currentPosition = position
    }
    
    func setMenuBarIconHidden(_ hidden: Bool) {
        configManager.isMenuBarIconHidden = hidden
    }
    
    func setIconColor(_ color: IconColor) {
        configManager.iconColor = color
    }
    
    func setDebugMode(_ enabled: Bool) {
        configManager.debugMode = enabled
    }
    
    func setOpenSettingsAtLaunch(_ enabled: Bool) {
        configManager.openSettingsAtLaunch = enabled
    }
    
    func setInterception(notifications: Bool, widgets: Bool, appleWidgets: Bool) {
        configManager.interceptNotifications = notifications
        configManager.interceptWidgets = widgets
        configManager.includeAppleWidgets = appleWidgets
    }
}
