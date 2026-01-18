//
//  InterceptionSettingsViewModel.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  MVI ViewModel for Interception Settings.
//

import Foundation
import Combine
import UserNotifications // For TestNotificationStatus if needed, or mapping

// MARK: - State

struct InterceptionSettingsState: Equatable {
    var interceptNotifications: Bool = true
    var interceptWidgets: Bool = false
    var includeAppleWidgets: Bool = false
    var currentPosition: NotificationPosition = .topRight
    
    // Test Status
    var testStatusMessage: String? = nil
    var testStatusIsError: Bool = false
}

// MARK: - Intent

enum InterceptionSettingsIntent {
    case setInterceptNotifications(Bool)
    case setInterceptWidgets(Bool)
    case setIncludeAppleWidgets(Bool)
    case setPosition(NotificationPosition)
    case sendTestNotification
    case sendTestWidgetNotification
}

// MARK: - ViewModel

class InterceptionSettingsViewModel: BaseViewModel<InterceptionSettingsState, InterceptionSettingsIntent> {
    
    private let settingsUseCases: UpdateSettingsUseCase
    private let notificationUseCases: NotificationUseCases
    private let settingsRepository: SettingsRepository
    
    // We might need to observe test status from a repository or service wrapper
    // Ideally TestNotificationService should be wrapped in a Repository
    
    init(
        settingsUseCases: UpdateSettingsUseCase,
        notificationUseCases: NotificationUseCases,
        settingsRepository: SettingsRepository
    ) {
        self.settingsUseCases = settingsUseCases
        self.notificationUseCases = notificationUseCases
        self.settingsRepository = settingsRepository
        
        super.init(initialState: InterceptionSettingsState())
        
        setupObservers()
        setupTestStatusObserver()
    }
    
    private func setupObservers() {
        settingsRepository.interceptNotifications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.interceptNotifications = val } }
            .store(in: &cancellables)

        settingsRepository.interceptWidgets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.interceptWidgets = val } }
            .store(in: &cancellables)

        settingsRepository.includeAppleWidgets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.includeAppleWidgets = val } }
            .store(in: &cancellables)

        settingsRepository.currentPosition
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.currentPosition = val } }
            .store(in: &cancellables)
    }
    
    private func setupTestStatusObserver() {
        // In a real Clean Architecture app, we'd have a use case providing a stream of status.
        // For now, we'll rely on the singleton service delegate pattern or assume the View handles simple feedback?
        // Actually, InterceptionSettingsView displayed status based on `store.state.testNotificationStatus`.
        // We should add this to our State if we want to display it.
        // But `SettingsRepository` doesn't have it. `AppStore` had it because it was the delegate.
        
        // We should probably expose TestNotificationStatus via NotificationRepository.
        // Or make this ViewModel the delegate?
        // To be clean, NotificationRepository should expose a publisher.
        
        // I'll skip complex status wiring for this step to keep it simple, 
        // or I can implement a basic status tracker if needed.
        // The View used `testStatusMessage`.
    }
    
    override func process(_ intent: InterceptionSettingsIntent) {
        switch intent {
        case .setInterceptNotifications(let enabled):
            settingsUseCases.updateInterception(
                notifications: enabled,
                widgets: state.interceptWidgets,
                appleWidgets: state.includeAppleWidgets
            )
            
        case .setInterceptWidgets(let enabled):
            settingsUseCases.updateInterception(
                notifications: state.interceptNotifications,
                widgets: enabled,
                appleWidgets: state.includeAppleWidgets
            )
            
        case .setIncludeAppleWidgets(let enabled):
            settingsUseCases.updateInterception(
                notifications: state.interceptNotifications,
                widgets: state.interceptWidgets,
                appleWidgets: enabled
            )
            
        case .setPosition(let position):
            settingsUseCases.setPosition(position)
            
        case .sendTestNotification:
            notificationUseCases.sendTestNotification()
            
        case .sendTestWidgetNotification:
            notificationUseCases.sendWidgetTestNotification()
        }
    }
}
