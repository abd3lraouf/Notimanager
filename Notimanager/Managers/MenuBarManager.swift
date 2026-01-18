//
//  MenuBarManager.swift
//  Notimanager
//
//  Created on 2025-01-17.
//  Observes configuration changes to update menu bar state
//

import AppKit
import SwiftUI
import Combine

/// Manages the menu bar state and observes configuration changes.
/// UI is now handled by MenuBarExtra in NotimanagerApp.swift
@available(macOS 10.15, *)
class MenuBarManager: NSObject, ObservableObject {
    static let shared = MenuBarManager()

    // Observe configuration changes
    private var cancellables = Set<AnyCancellable>()

    // Track previous values to avoid logging duplicate initial subscriptions
    private var previousIsHidden: Bool?
    private var previousIsEnabled: Bool?
    private var previousPosition: NotificationPosition?
    private var previousColor: IconColor?

    private override init() {
        super.init()
        setupObservers()
    }

    private func setupObservers() {
        LoggingService.shared.debug("MenuBarManager: Setting up observers", category: "MenuBar")

        // Observers are kept to trigger objectWillChange if needed,
        // though SwiftUI's @ObservedObject ConfigurationManager.shared usually handles this in Views.

        ConfigurationManager.shared.$isMenuBarIconHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isHidden in
                guard let self = self else { return }
                // Only log if value actually changed
                if self.previousIsHidden != isHidden {
                    LoggingService.shared.debug("MenuBarManager: isMenuBarIconHidden changed to \(isHidden)", category: "MenuBar")
                    self.previousIsHidden = isHidden
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)

        ConfigurationManager.shared.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                guard let self = self else { return }
                // Only log if value actually changed
                if self.previousIsEnabled != isEnabled {
                    LoggingService.shared.debug("MenuBarManager: isEnabled changed to \(isEnabled)", category: "MenuBar")
                    self.previousIsEnabled = isEnabled
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)

        ConfigurationManager.shared.$currentPosition
            .receive(on: DispatchQueue.main)
            .sink { [weak self] position in
                guard let self = self else { return }
                // Only log if value actually changed
                if self.previousPosition != position {
                    LoggingService.shared.debug("MenuBarManager: currentPosition changed to \(position.displayName)", category: "MenuBar")
                    self.previousPosition = position
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)

        ConfigurationManager.shared.$iconColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] color in
                guard let self = self else { return }
                // Only log if value actually changed
                if self.previousColor != color {
                    LoggingService.shared.debug("MenuBarManager: iconColor changed to \(color.displayName)", category: "MenuBar")
                    self.previousColor = color
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
}