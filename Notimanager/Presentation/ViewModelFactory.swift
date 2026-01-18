//
//  ViewModelFactory.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Factory for creating ViewModels with dependencies.
//

import Foundation

@available(macOS 10.15, *)
class ViewModelFactory {
    
    static let shared = ViewModelFactory()
    
    // Repositories (for direct VM access if needed, or use cases)
    private let settingsRepository: SettingsRepository
    private let systemRepository: SystemRepository
    private let notificationRepository: NotificationRepository
    
    // Use Cases
    private let settingsUseCases: UpdateSettingsUseCase
    private let systemUseCases: SystemUseCases
    private let notificationUseCases: NotificationUseCases
    
    private init() {
        // Data Layer Repositories
        self.settingsRepository = SettingsRepositoryImpl()
        self.systemRepository = SystemRepositoryImpl()
        self.notificationRepository = NotificationRepositoryImpl()
        
        // Domain Layer Use Cases
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
