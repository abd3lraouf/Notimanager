//
//  KeyboardNavigationManager.swift
//  Notimanager
//
//  Manages keyboard navigation throughout the app including
//  tab order, keyboard shortcuts, and arrow key navigation.
//

import AppKit

/// Manages keyboard navigation for windows and views
class KeyboardNavigationManager: NSObject {

    // MARK: - Singleton

    static let shared = KeyboardNavigationManager()

    private override init() {
        super.init()
    }

    // MARK: - Properties

    private var focusMap: [String: NSView] = [:]
    private var currentWindow: NSWindow?
    private var currentFocusIndex: Int = 0
    private var focusOrder: [NSView] = []

    // MARK: - Window Setup

    /// Sets up keyboard navigation for a window
    /// - Parameter window: The window to configure
    func setupKeyboardNavigation(for window: NSWindow) {
        currentWindow = window

        // Enable full keyboard access
        UserDefaults.standard.set(true, forKey: "AppleKeyboardUIMode")

        // Setup tab navigation
        setupTabNavigation(for: window)

        // Setup keyboard shortcuts
        setupKeyboardShortcuts(for: window)

        // Make the window accept key events
        window.makeKeyAndOrderFront(nil)
    }

    private func setupTabNavigation(for window: NSWindow) {
        // Set initial first responder if available
        if !focusOrder.isEmpty {
            window.initialFirstResponder = focusOrder.first
        }
    }

    private func setupKeyboardShortcuts(for window: NSWindow) {
        // Global shortcuts are handled by menu items in MainMenu.xib
        // This method can be extended for window-specific shortcuts
    }

    // MARK: - Focus Management

    /// Registers a view for keyboard navigation
    /// - Parameters:
    ///   - view: The view to register
    ///   - key: A unique identifier for the view
    func registerView(_ view: NSView, forKey key: String) {
        focusMap[key] = view
    }

    /// Sets the focus order for tab navigation
    /// - Parameter views: Array of views in tab order
    func setFocusOrder(_ views: [NSView]) {
        focusOrder = views
    }

    /// Moves focus to the next view in the tab order
    @discardableResult
    func moveFocusForward() -> Bool {
        guard let window = currentWindow else { return false }

        // Find next valid view
        for i in 0..<focusOrder.count {
            if focusOrder[i].acceptsFirstResponder && !focusOrder[i].isHidden {
                window.makeFirstResponder(focusOrder[i])
                return true
            }
        }
        return false
    }

    /// Moves focus to the previous view in the tab order
    @discardableResult
    func moveFocusBackward() -> Bool {
        guard let window = currentWindow else { return false }

        // Find previous valid view
        for i in stride(from: focusOrder.count - 1, through: 0, by: -1) {
            if focusOrder[i].acceptsFirstResponder && !focusOrder[i].isHidden {
                window.makeFirstResponder(focusOrder[i])
                return true
            }
        }
        return false
    }

    /// Moves focus to a specific view
    /// - Parameters:
    ///   - key: The identifier of the view
    /// - Returns: True if focus was moved successfully
    @discardableResult
    func moveFocus(to key: String) -> Bool {
        guard let view = focusMap[key],
              view.acceptsFirstResponder,
              let window = currentWindow else {
            return false
        }

        window.makeFirstResponder(view)
        return true
    }

    /// Moves focus to a specific view directly
    /// - Parameter view: The view to focus
    /// - Returns: True if focus was moved successfully
    @discardableResult
    func moveFocus(to view: NSView) -> Bool {
        guard view.acceptsFirstResponder,
              let window = currentWindow else {
            return false
        }

        window.makeFirstResponder(view)
        return true
    }

    // MARK: - Grid Navigation

    /// Sets up arrow key navigation for a grid of items
    /// - Parameters:
    ///   - views: 2D array of views representing the grid
    ///   - containerView: The container view
    func setupGridNavigation(views: [[NSView]], in containerView: NSView) {
        // Map grid positions to views
        for (row, rowViews) in views.enumerated() {
            for (col, view) in rowViews.enumerated() {
                // Store position info for navigation
                view.identifier = NSUserInterfaceItemIdentifier("grid_\(row)_\(col)")
            }
        }
    }

    /// Navigates within a grid using arrow keys
    /// - Parameters:
    ///   - currentView: The currently focused view
    ///   - direction: The direction to move
    ///   - grid: The grid of views
    /// - Returns: The next view to focus, or nil if at boundary
    func navigateGrid(
        from currentView: NSView,
        direction: NavigationDirection,
        in grid: [[NSView]]
    ) -> NSView? {
        // Find current position
        guard let (currentRow, currentCol) = findPosition(of: currentView, in: grid) else {
            return nil
        }

        var nextRow = currentRow
        var nextCol = currentCol

        switch direction {
        case .up:
            nextRow = max(0, currentRow - 1)
        case .down:
            nextRow = min(grid.count - 1, currentRow + 1)
        case .left:
            nextCol = max(0, currentCol - 1)
        case .right:
            nextCol = min(grid[currentRow].count - 1, currentCol + 1)
        }

        return grid[nextRow][nextCol]
    }

    private func findPosition(of view: NSView, in grid: [[NSView]]) -> (Int, Int)? {
        for (row, rowViews) in grid.enumerated() {
            if let col = rowViews.firstIndex(where: { $0 == view }) {
                return (row, col)
            }
        }
        return nil
    }

    // MARK: - Navigation Direction

    enum NavigationDirection {
        case up
        case down
        case left
        case right
    }

    // MARK: - Shortcuts

    /// Registers a keyboard shortcut
    /// - Parameters:
    ///   - keyEquivalent: The keyboard shortcut (e.g., "s", "w")
    ///   - modifierMask: The modifier keys (e.g., .command)
    ///   - action: The action to perform
    func registerShortcut(
        keyEquivalent: String,
        modifierMask: NSEvent.ModifierFlags,
        action: @escaping () -> Void
    ) {
        // This would typically be done via menu items or local event monitors
        // For implementation, create menu items dynamically
        _ = (
            keyEquivalent: keyEquivalent,
            modifierMask: modifierMask,
            action: action
        )
    }

    private struct Shortcut {
        let keyEquivalent: String
        let modifierMask: NSEvent.ModifierFlags
        let action: () -> Void
    }

    // MARK: - Escape Key Handling

    /// Sets up escape key handling
    /// - Parameter action: The action to perform when escape is pressed
    func setupEscapeKey(in window: NSWindow, action: @escaping () -> Void) {
        // Escape key monitoring via local event monitor
        // Note: In production, store monitor reference for cleanup
        let _ = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak window] event in
            guard let window = window,
                  event.window == window,
                  event.keyCode == 53 // Escape key
            else {
                return event
            }

            action()
            return nil // Consume the event
        }
    }
}

// MARK: - NSView Extensions for Keyboard Navigation

extension NSView {

    /// Makes this view the first responder
    func becomeFirstResponder() {
        if let window = window {
            window.makeFirstResponder(self)
        }
    }

    /// Gets the next key view in the chain
    var nextKeyView: NSView? {
        return window?.firstResponder as? NSView
    }

    /// Checks if this view can receive keyboard focus
    var canReceiveFocus: Bool {
        return acceptsFirstResponder && !isHidden && !isHiddenOrHasHiddenAncestor
    }
}

// MARK: - Focus Ring Support

extension NSView {

    /// Enables custom focus ring drawing
    func drawFocusRing() {
        // Subclasses can override to draw custom focus rings
        let focusRingPath = NSBezierPath(rect: bounds.insetBy(dx: -2, dy: -2))
        NSColor.keyboardFocusIndicatorColor.setStroke()
        focusRingPath.lineWidth = Layout.focusRingWidth
        focusRingPath.stroke()
    }
}

// MARK: - Arrow Key Handler

/// A helper class for handling arrow key navigation in custom views
class ArrowKeyNavigationHandler: NSObject {

    private let onArrowKeyPressed: (KeyboardNavigationManager.NavigationDirection) -> Void

    init(onArrowKeyPressed: @escaping (KeyboardNavigationManager.NavigationDirection) -> Void) {
        self.onArrowKeyPressed = onArrowKeyPressed
        super.init()
    }

    /// Handles a key event and calls the appropriate handler
    @discardableResult
    func handleKeyEvent(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 126: // Up arrow
            onArrowKeyPressed(.up)
            return true
        case 125: // Down arrow
            onArrowKeyPressed(.down)
            return true
        case 123: // Left arrow
            onArrowKeyPressed(.left)
            return true
        case 124: // Right arrow
            onArrowKeyPressed(.right)
            return true
        default:
            return false
        }
    }
}

// MARK: - Tab Stop Support

extension NSView {

    /// Sets whether this view is a tab stop
    var isTabStop: Bool {
        get {
            return acceptsFirstResponder
        }
        set {
            // This would require overriding in specific view types
            // For NSButton, NSControl, etc., this is automatic
        }
    }

    /// Gets all tabbable views in the hierarchy
    func tabbableViews() -> [NSView] {
        var views: [NSView] = []

        if acceptsFirstResponder && !isHidden {
            views.append(self)
        }

        for subview in subviews {
            views.append(contentsOf: subview.tabbableViews())
        }

        return views
    }
}
