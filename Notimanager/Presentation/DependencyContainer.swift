//
//  DependencyContainer.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Composition Root / Dependency Injection Container.
//

import Foundation

@available(macOS 10.15, *)
class DependencyContainer {
    
    static let shared = DependencyContainer()
    
    // Repositories
    let settingsRepository: SettingsRepository
    let systemRepository: SystemRepository
    let notificationRepository: NotificationRepository
    
    // Use Cases
    let settingsUseCases: UpdateSettingsUseCase
    let systemUseCases: SystemUseCases
    let notificationUseCases: NotificationUseCases
    
    private init() {
        // Data Layer
        self.settingsRepository = SettingsRepositoryImpl()
        self.systemRepository = SystemRepositoryImpl()
        self.notificationRepository = NotificationRepositoryImpl()
        
        // Domain Layer
        self.settingsUseCases = UpdateSettingsUseCase(
            repository: settingsRepository,
            systemRepository: systemRepository,
            notificationRepository: notificationRepository
        )
        self.systemUseCases = SystemUseCases(repository: systemRepository)
        self.notificationUseCases = NotificationUseCases(repository: notificationRepository)
    }
    
    // ViewModel Factories
    func makeGeneralSettingsViewModel() -> GeneralSettingsViewModel {
        return GeneralSettingsViewModel(
            settingsUseCases: settingsUseCases,
            systemUseCases: systemUseCases,
            settingsRepository: settingsRepository
        )
    }
    
    func makeAdvancedSettingsViewModel() -> AdvancedSettingsViewModel {
        return AdvancedSettingsViewModel(
            settingsUseCases: settingsUseCases,
            systemUseCases: systemUseCases,
            settingsRepository: settingsRepository
        )
    }
    
    func makeInterceptionSettingsViewModel() -> InterceptionSettingsViewModel {
        return InterceptionSettingsViewModel(
            settingsUseCases: settingsUseCases,
            notificationUseCases: notificationUseCases,
            settingsRepository: settingsRepository
        )
    }

    func makeMenuBarViewModel() -> MenuBarViewModel {
        return MenuBarViewModel(
            settingsUseCases: settingsUseCases,
            systemUseCases: systemUseCases,
            settingsRepository: settingsRepository
        )
    }
}
