//
//  GeneralSettingsViewModel.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  MVI ViewModel for General Settings.
//

import Foundation
import Combine
import SwiftUI

// MARK: - State

struct GeneralSettingsState: Equatable {
    var isEnabled: Bool = true
    var isMenuBarIconHidden: Bool = false
    var iconColor: IconColor = .normal
    var openSettingsAtLaunch: Bool = true
    var showHideConfirmation: Bool = false
    var showQuitConfirmation: Bool = false
    
    // Updates
    var automaticallyChecksForUpdates: Bool = false
    var isCheckingForUpdates: Bool = false
    var updateStatusMessage: String? = nil
    var lastUpdateCheck: String = "Never"
}

// MARK: - Intent

enum GeneralSettingsIntent {
    case setEnabled(Bool)
    case toggleMenuBarIconVisibility(Bool) // The toggle UI state
    case confirmHideMenuBarIcon
    case cancelHideMenuBarIcon
    case setIconColor(IconColor)
    case setOpenSettingsAtLaunch(Bool)
    case setAutomaticallyChecksForUpdates(Bool)
    case checkForUpdates
    case requestQuit
    case confirmQuit
    case cancelQuit
}

// MARK: - ViewModel

class GeneralSettingsViewModel: BaseViewModel<GeneralSettingsState, GeneralSettingsIntent> {
    
    private let settingsUseCases: UpdateSettingsUseCase
    private let systemUseCases: SystemUseCases
    
    // We observe the repository to sync state (SSOT)
    private let settingsRepository: SettingsRepository
    
    init(
        settingsUseCases: UpdateSettingsUseCase,
        systemUseCases: SystemUseCases,
        settingsRepository: SettingsRepository
    ) {
        self.settingsUseCases = settingsUseCases
        self.systemUseCases = systemUseCases
        self.settingsRepository = settingsRepository
        
        super.init(initialState: GeneralSettingsState())
        
        setupObservers()
        loadUpdateState()
    }
    
    private func setupObservers() {
        // Observe Repository (SSOT) -> Update View State
        settingsRepository.isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.isEnabled = val } }
            .store(in: &self.cancellables)
            
        settingsRepository.isMenuBarIconHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.isMenuBarIconHidden = val } }
            .store(in: &self.cancellables)
            
        settingsRepository.iconColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.iconColor = val } }
            .store(in: &self.cancellables)
            
        settingsRepository.openSettingsAtLaunch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in self?.updateState { $0.openSettingsAtLaunch = val } }
            .store(in: &self.cancellables)
    }
    
    private func loadUpdateState() {
        // In a real app, this might come from a repository too
        updateState {
            $0.automaticallyChecksForUpdates = UpdateManager.shared.automaticallyChecksForUpdates
            $0.lastUpdateCheck = UpdateManager.shared.formattedLastCheckDate()
        }
    }
    
    override func process(_ intent: GeneralSettingsIntent) {
        switch intent {
        case .setEnabled(let enabled):
            settingsUseCases.setEnabled(enabled)
            
        case .toggleMenuBarIconVisibility(let toggleState):
            // toggleState == true means user wants to HIDE (toggle ON)
            // Only show confirmation if:
            // 1. User wants to hide (toggleState == true)
            // 2. Icon is not already hidden (state doesn't match)
            // 3. Confirmation is not already showing
            if toggleState && !state.isMenuBarIconHidden && !state.showHideConfirmation {
                updateState { $0.showHideConfirmation = true }
            } else if !toggleState && state.isMenuBarIconHidden {
                // User wants to show the icon (toggle OFF) - no confirmation needed
                settingsUseCases.setMenuBarIconHidden(false)
            }
            // If toggleState matches current state, do nothing (prevents duplicate triggers)
            
        case .confirmHideMenuBarIcon:
            updateState { $0.showHideConfirmation = false }
            settingsUseCases.setMenuBarIconHidden(true)
            
        case .cancelHideMenuBarIcon:
            updateState { $0.showHideConfirmation = false }
            // The Binding in View will naturally revert if state didn't change
            
        case .setIconColor(let color):
            settingsUseCases.setIconColor(color)
            
        case .setOpenSettingsAtLaunch(let enabled):
            settingsUseCases.setOpenSettingsAtLaunch(enabled)
            
        case .setAutomaticallyChecksForUpdates(let enabled):
            // This is side-effecty, should ideally be in UseCase
            UpdateManager.shared.automaticallyChecksForUpdates = enabled
            updateState { $0.automaticallyChecksForUpdates = enabled }
            
        case .checkForUpdates:
            checkForUpdates()
            
        case .requestQuit:
            updateState { $0.showQuitConfirmation = true }
            
        case .confirmQuit:
            systemUseCases.quitApp()
            
        case .cancelQuit:
            updateState { $0.showQuitConfirmation = false }
        }
    }
    
    private func checkForUpdates() {
        updateState {
            $0.isCheckingForUpdates = true
            $0.updateStatusMessage = "Checking…"
        }
        
        systemUseCases.checkForUpdates()
        
        // Simulate completion or listen to UpdateManager delegate (omitted for brevity)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.updateState {
                $0.updateStatusMessage = nil
                $0.lastUpdateCheck = UpdateManager.shared.formattedLastCheckDate()
                $0.isCheckingForUpdates = false
            }
        }
    }
}
