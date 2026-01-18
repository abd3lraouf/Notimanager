//
//  MenuBarViewModel.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  MVI ViewModel for MenuBar.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Intent

enum MenuBarIntent {
    case toggleEnabled
    case setEnabled(Bool)
    case changePosition(NotificationPosition)
    case toggleMenuBarIconVisibility
    case setMenuBarIconHidden(Bool)
    case setIconColor(IconColor)
    case checkForUpdates
    case showAbout
    case quitApp
}

// MARK: - ViewModel

class MenuBarViewModel: BaseViewModel<MenuBarState, MenuBarIntent> {
    
    private let settingsUseCases: UpdateSettingsUseCase
    private let systemUseCases: SystemUseCases
    private let settingsRepository: SettingsRepository // To observe state changes
    
    init(
        settingsUseCases: UpdateSettingsUseCase,
        systemUseCases: SystemUseCases,
        settingsRepository: SettingsRepository
    ) {
        self.settingsUseCases = settingsUseCases
        self.systemUseCases = systemUseCases
        self.settingsRepository = settingsRepository
        
        super.init(initialState: MenuBarState())
        
        setupObservers()
    }
    
    private func setupObservers() {
        settingsRepository.isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.isEnabled = val } }
            .store(in: &cancellables)

        settingsRepository.currentPosition
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.currentPosition = val } }
            .store(in: &cancellables)

        settingsRepository.isMenuBarIconHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.isMenuBarIconHidden = val } }
            .store(in: &cancellables)

        settingsRepository.iconColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.iconColor = val } }
            .store(in: &cancellables)
    }
    
    override func process(_ intent: MenuBarIntent) {
        switch intent {
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
            
        case .checkForUpdates:
            systemUseCases.checkForUpdates()
            
        case .showAbout:
            systemUseCases.showAbout()
            
        case .quitApp:
            systemUseCases.quitApp()
        }
    }
}
