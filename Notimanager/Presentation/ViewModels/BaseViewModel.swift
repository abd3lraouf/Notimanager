//
//  BaseViewModel.swift
//  Notimanager
//
//  Created on 2026-01-17.
//  Base class for MVI ViewModels in the Presentation Layer.
//

import Foundation
import Combine

/// Base class for MVI ViewModels
/// - Parameters:
///   - S: State type (must be Equatable)
///   - I: Intent type
@available(macOS 10.15, *)
class BaseViewModel<S: Equatable, I>: ObservableObject {
    
    @Published private(set) var state: S
    var cancellables = Set<AnyCancellable>()
    
    init(initialState: S) {
        self.state = initialState
    }
    
    /// Handle user intents
    func process(_ intent: I) {
        fatalError("process(_:) has not been implemented")
    }
    
    /// Update state safely on main thread
    func updateState(_ mutation: (inout S) -> Void) {
        var newState = state
        mutation(&newState)
        
        if newState != state {
            DispatchQueue.main.async {
                self.state = newState
            }
        }
    }
    
    /// Store cancellables
    func store(_ cancellable: AnyCancellable) {
        cancellable.store(in: &cancellables)
    }
}
