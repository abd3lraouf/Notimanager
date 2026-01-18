//
//  AppStore.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Implements UDF (Unidirectional Data Flow) and SSOT (Single Source of Truth).
//  Adheres to Clean Architecture by using UseCases and Repositories.
//

import Foundation
import Combine
import SwiftUI
import UserNotifications

// MARK: - App State

struct AppState: Equatable {
    var isEnabled: Bool
    var currentPosition: NotificationPosition
    var isMenuBarIconHidden: Bool
    var iconColor: IconColor
    var debugMode: Bool
    var openSettingsAtLaunch: Bool
    var interceptNotifications: Bool
    var interceptWidgets: Bool
    var includeAppleWidgets: Bool
    var testNotificationStatus: TestNotificationStatus = .idle
    
    // Derived/Computed State (ViewModel-like)
    var iconName: String {
        return "MenuBarIcon-" + currentPosition.iconName
    }
}

// MARK: - App Actions

enum AppAction {
    case toggleEnabled
    case setEnabled(Bool)
    case changePosition(NotificationPosition)
    case toggleMenuBarIconVisibility
    case setMenuBarIconHidden(Bool)
    case setIconColor(IconColor)
    case toggleDebugMode
    case setOpenSettingsAtLaunch(Bool)
    case checkForUpdates
    case openSettings
    case showAbout
    case showDiagnostics
    case showPermissions
    case sendTestNotification
    case sendTestWidget
    case quitApp
    case updateInterception(notifications: Bool, widgets: Bool, appleWidgets: Bool)
}

// MARK: - App Store

@available(macOS 10.15, *)
class AppStore: ObservableObject {
    
    static let shared = AppStore()
    
    @Published private(set) var state: AppState
    
    // Domain Layer: Use Cases
    private let settingsUseCases: UpdateSettingsUseCase
    private let systemUseCases: SystemUseCases
    private let notificationUseCases: NotificationUseCases
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Dependency Injection (Composition Root)
        // 1. Data Layer: Repositories
        let settingsRepo = SettingsRepositoryImpl()
        let systemRepo = SystemRepositoryImpl()
        let notificationRepo = NotificationRepositoryImpl()
        
        // 2. Domain Layer: Use Cases
        self.settingsUseCases = UpdateSettingsUseCase(
            repository: settingsRepo,
            systemRepository: systemRepo,
            notificationRepository: notificationRepo
        )
        self.systemUseCases = SystemUseCases(repository: systemRepo)
        self.notificationUseCases = NotificationUseCases(repository: notificationRepo)
        
        // Initialize state with default/initial values
        // We will receive actual values from the repository publishers immediately upon subscription
        self.state = AppState(
            isEnabled: true,
            currentPosition: .topRight,
            isMenuBarIconHidden: false,
            iconColor: .normal,
            debugMode: false,
            openSettingsAtLaunch: true,
            interceptNotifications: true,
            interceptWidgets: false,
            includeAppleWidgets: false
        )
        
        // Setup State Observation (Bind Data Layer -> Presentation Layer)
        setupObservers(settingsRepo: settingsRepo)
        
        // Set delegate for test notifications
        TestNotificationService.shared.delegate = self
    }
    
    private func setupObservers(settingsRepo: SettingsRepository) {
        settingsRepo.isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.state.isEnabled = val }
            .store(in: &cancellables)
            
        settingsRepo.currentPosition
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.state.currentPosition = val }
            .store(in: &cancellables)
            
        settingsRepo.isMenuBarIconHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.state.isMenuBarIconHidden = val }
            .store(in: &cancellables)
            
        settingsRepo.iconColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.state.iconColor = val }
            .store(in: &cancellables)
            
        settingsRepo.debugMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.state.debugMode = val }
            .store(in: &cancellables)
            
        settingsRepo.openSettingsAtLaunch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.state.openSettingsAtLaunch = val }
            .store(in: &cancellables)
            
        settingsRepo.interceptNotifications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.state.interceptNotifications = val }
            .store(in: &cancellables)
            
        settingsRepo.interceptWidgets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.state.interceptWidgets = val }
            .store(in: &cancellables)
            
        settingsRepo.includeAppleWidgets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.state.includeAppleWidgets = val }
            .store(in: &cancellables)
    }
    
    // Handle Intents (Actions)
    func dispatch(_ action: AppAction) {
        switch action {
        case .toggleEnabled:
            settingsUseCases.setEnabled(!state.isEnabled)
            
        case .setEnabled(let enabled):
            settingsUseCases.setEnabled(enabled)
            
        case .changePosition(let position):
            settingsUseCases.setPosition(position)
            
        case .toggleMenuBarIconVisibility:
            settingsUseCases.setMenuBarIconHidden(!state.isMenuBarIconHidden)
            
        case .setMenuBarIconHidden(let hidden):
            settingsUseCases.setMenuBarIconHidden(hidden)
            
        case .setIconColor(let color):
            settingsUseCases.setIconColor(color)
            
        case .toggleDebugMode:
            settingsUseCases.setDebugMode(!state.debugMode)
            
        case .setOpenSettingsAtLaunch(let open):
            settingsUseCases.setOpenSettingsAtLaunch(open)
            
        case .checkForUpdates:
            systemUseCases.checkForUpdates()
            
        case .openSettings:
            systemUseCases.openSettings()
            
        case .showAbout:
            systemUseCases.showAbout()
            
        case .showDiagnostics:
            systemUseCases.showDiagnostics()
            
        case .showPermissions:
            systemUseCases.showPermissions()
            
        case .sendTestNotification:
            notificationUseCases.sendTestNotification()
            
        case .sendTestWidget:
            notificationUseCases.sendWidgetTestNotification()
            
        case .quitApp:
            systemUseCases.quitApp()
            
        case .updateInterception(let notifications, let widgets, let appleWidgets):
            settingsUseCases.updateInterception(
                notifications: notifications,
                widgets: widgets,
                appleWidgets: appleWidgets
            )
        }
    }
}

// MARK: - TestNotificationServiceDelegate

@available(macOS 10.15, *)
extension AppStore: TestNotificationServiceDelegate {
    func testNotificationDidSend() {
        // Handled via status change
    }
    
    func testNotificationDidFail(error: Error) {
        // Handled via status change
    }
    
    func testNotificationStatusDidChange(_ status: TestNotificationStatus) {
        DispatchQueue.main.async {
            self.state.testNotificationStatus = status
        }
    }
    
    func notificationPermissionStatusDidChange(_ status: UNAuthorizationStatus) {
        // Can be used to update permission state in AppState if we add it
    }
}
