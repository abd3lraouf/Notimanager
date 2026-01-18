//
//  SettingsRepository.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Domain Layer: Interface for accessing settings.
//

import Combine
import Foundation

protocol SettingsRepository {
    var isEnabled: AnyPublisher<Bool, Never> { get }
    var currentPosition: AnyPublisher<NotificationPosition, Never> { get }
    var isMenuBarIconHidden: AnyPublisher<Bool, Never> { get }
    var iconColor: AnyPublisher<IconColor, Never> { get }
    var debugMode: AnyPublisher<Bool, Never> { get }
    var openSettingsAtLaunch: AnyPublisher<Bool, Never> { get }
    var interceptNotifications: AnyPublisher<Bool, Never> { get }
    var interceptWidgets: AnyPublisher<Bool, Never> { get }
    var includeAppleWidgets: AnyPublisher<Bool, Never> { get }
    
    func setEnabled(_ enabled: Bool)
    func setPosition(_ position: NotificationPosition)
    func setMenuBarIconHidden(_ hidden: Bool)
    func setIconColor(_ color: IconColor)
    func setDebugMode(_ enabled: Bool)
    func setOpenSettingsAtLaunch(_ enabled: Bool)
    func setInterception(notifications: Bool, widgets: Bool, appleWidgets: Bool)
}
