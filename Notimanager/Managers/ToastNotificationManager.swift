//
//  ToastNotificationManager.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  Manages the display and lifecycle of toast notifications
//

import AppKit
import Foundation
import os.log

// MARK: - Toast Notification Manager

/// Manages the display queue and lifecycle of toast notifications
class ToastNotificationManager {
    
    // MARK: - Singleton
    
    static let shared = ToastNotificationManager()
    
    private init() {
        // Private initializer for singleton
    }
    
    // MARK: - Properties

    /// Queue of toasts waiting to be displayed
    private var toastQueue: [ToastNotification] = []

    /// Currently displayed toast
    private var currentToast: ToastNotification?

    /// Timer for auto-dismissing current toast
    private var dismissTimer: Timer?

    /// Window for displaying toasts
    private var toastWindow: NSWindow?

    /// View for the current toast (kept alive to prevent deallocation while window shows it)
    private var currentToastView: ToastNotificationView?
    
    /// Delegate for toast callbacks
    weak var delegate: ToastNotificationDelegate?
    
    /// Maximum number of toasts to keep in queue
    private let maxQueueSize = 5
    
    /// Logging service
    private let logger = LoggingService.shared
    
    /// Whether the manager is currently showing a toast
    private var isShowingToast: Bool {
        return currentToast != nil
    }
    
    // MARK: - Public API
    
    /// Shows a toast notification
    /// - Parameter toast: The toast to show
    func show(_ toast: ToastNotification) {
        logger.debug("Showing toast: \(toast.title)")
        
        // Add to queue
        toastQueue.append(toast)
        
        // Trim queue if too long
        if toastQueue.count > maxQueueSize {
            toastQueue.removeFirst()
            logger.debug("Toast queue trimmed, removed oldest toast")
        }
        
        // Process queue
        processQueue()
    }
    
    /// Shows a success toast
    /// - Parameters:
    ///   - title: The title of the toast
    ///   - message: Optional detailed message
    ///   - duration: Optional custom duration
    func showSuccess(_ title: String, message: String? = nil, duration: TimeInterval? = nil) {
        let toast = ToastNotification.success(title, message: message, duration: duration)
        show(toast)
    }
    
    /// Shows an error toast
    /// - Parameters:
    ///   - title: The title of the toast
    ///   - message: Optional detailed message
    ///   - duration: Optional custom duration
    func showError(_ title: String, message: String? = nil, duration: TimeInterval? = nil) {
        let toast = ToastNotification.error(title, message: message, duration: duration)
        show(toast)
    }
    
    /// Shows an info toast
    /// - Parameters:
    ///   - title: The title of the toast
    ///   - message: Optional detailed message
    ///   - duration: Optional custom duration
    func showInfo(_ title: String, message: String? = nil, duration: TimeInterval? = nil) {
        let toast = ToastNotification.info(title, message: message, duration: duration)
        show(toast)
    }
    
    /// Dismisses the current toast immediately
    func dismissCurrentToast() {
        guard let toast = currentToast else { return }
        
        logger.debug("Dismissing toast: \(toast.title)")
        dismissToast(toast)
    }
    
    /// Clears all pending toasts
    func clearAllToasts() {
        logger.debug("Clearing all toasts")
        
        // Dismiss current toast
        if let currentToast = currentToast {
            dismissToast(currentToast)
        }
        
        // Clear queue
        toastQueue.removeAll()
    }
    
    /// Gets the current queue count
    var queueCount: Int {
        return toastQueue.count
    }
    
    /// Gets the currently displayed toast
    var currentToastNotification: ToastNotification? {
        return currentToast
    }
    
    // MARK: - Private Methods
    
    /// Processes the toast queue and shows the next toast if available
    private func processQueue() {
        guard !isShowingToast && !toastQueue.isEmpty else { return }
        
        // Get the next toast
        let nextToast = toastQueue.removeFirst()
        showToast(nextToast)
    }
    
    /// Shows a specific toast
    /// - Parameter toast: The toast to show
    private func showToast(_ toast: ToastNotification) {
        currentToast = toast

        // Create and configure toast view (store strongly to prevent deallocation)
        let toastView = ToastNotificationView(toast: toast)
        currentToastView = toastView

        // Calculate window size
        let windowSize = toastView.fittingSize

        // Calculate position (top right of screen with margin)
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowX = screenRect.maxX - windowSize.width - Spacing.pt20
        let windowY = screenRect.maxY - windowSize.height - Spacing.pt20

        let windowFrame = NSRect(
            x: windowX,
            y: windowY,
            width: windowSize.width,
            height: windowSize.height
        )

        // Create window
        toastWindow = NSWindow(
            contentRect: windowFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        guard let window = toastWindow else { return }

        // Configure window
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.ignoresMouseEvents = false

        // Set content
        window.contentView = toastView

        // Show window with animation
        window.alphaValue = 0.0
        window.makeKeyAndOrderFront(nil)

        // Animate in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.normal
            context.timingFunction = Animation.easeOut
            window.animator().alphaValue = 1.0
        }

        // Start dismiss timer
        startDismissTimer(for: toast)

        // Notify delegate
        delegate?.toastDidShow(toast)

        logger.debug("Toast shown: \(toast.title)")
    }
    
    /// Dismisses a specific toast
    /// - Parameter toast: The toast to dismiss
    private func dismissToast(_ toast: ToastNotification) {
        guard let window = toastWindow else { return }

        // Stop dismiss timer immediately to prevent race conditions
        dismissTimer?.invalidate()
        dismissTimer = nil

        // Animate out with proper cleanup
        NSAnimationContext.runAnimationGroup { [weak self] context in
            guard let self = self else { return }

            context.duration = Animation.fast
            context.timingFunction = Animation.easeIn
            context.completionHandler = { [weak self] in
                // Close window if it still exists
                self?.toastWindow?.close()
                self?.cleanupAfterDismissal(of: toast)
            }
            window.animator().alphaValue = 0.0
        }
    }
    
    /// Starts the dismiss timer for a toast
    /// - Parameter toast: The toast to set timer for
    private func startDismissTimer(for toast: ToastNotification) {
        dismissTimer?.invalidate()

        dismissTimer = Timer.scheduledTimer(withTimeInterval: toast.duration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // Only dismiss if this is still the current toast (prevents stale timer callbacks)
            if self.currentToast?.id == toast.id {
                self.delegate?.toastWillExpire(toast)
                self.dismissToast(toast)
            }
        }
    }
    
    /// Cleans up after a toast is dismissed
    /// - Parameter toast: The toast that was dismissed
    private func cleanupAfterDismissal(of toast: ToastNotification) {
        currentToast = nil
        toastWindow = nil
        currentToastView = nil  // Clear the view reference to release it

        // Notify delegate (with weak self to prevent potential retain cycles)
        delegate?.toastDidDismiss(toast)

        logger.debug("Toast dismissed: \(toast.title)")

        // Process next toast in queue (use weak self to prevent crashes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.processQueue()
        }
    }
}

// MARK: - Toast Notification View

/// A view that displays a single toast notification
class ToastNotificationView: NSView {

    // MARK: - Properties

    private let toast: ToastNotification
    private var card: LiquidGlassCard!
    private var iconImageView: NSImageView!
    private var titleLabel: NSTextField!
    private var messageLabel: NSTextField?
    private var stackView: NSStackView!

    // MARK: - Initialization

    init(toast: ToastNotification) {
        self.toast = toast
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        // Create card
        card = LiquidGlassCard(style: .elevated)

        // Create icon with safe fallback
        iconImageView = NSImageView()
        iconImageView.wantsLayer = true
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: Layout.mediumIcon, weight: .medium)
            iconImageView.symbolConfiguration = config
            iconImageView.image = NSImage(systemSymbolName: toast.type.icon, accessibilityDescription: toast.type.displayName)
            if iconImageView.image == nil {
                iconImageView.image = NSImage(size: NSSize(width: 20, height: 20))
            }
        } else {
            iconImageView.image = NSImage(size: NSSize(width: 20, height: 20))
        }

        // Set contentTintColor after image is set
        if iconImageView.image != nil {
            iconImageView.contentTintColor = toast.type.color
        }

        // Create title label
        titleLabel = NSTextField(labelWithString: toast.title)
        titleLabel.font = Typography.headline
        titleLabel.textColor = Colors.label
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = .clear
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Create message label if needed
        if let message = toast.message {
            let field = NSTextField(wrappingLabelWithString: message)
            field.font = Typography.body
            field.textColor = Colors.secondaryLabel
            field.isEditable = false
            field.isBordered = false
            field.backgroundColor = .clear
            field.translatesAutoresizingMaskIntoConstraints = false
            field.maximumNumberOfLines = 2
            field.cell?.truncatesLastVisibleLine = true
            messageLabel = field
        }

        // Create stack view
        let arrangedSubviews: [NSView] = [iconImageView, titleLabel]
        stackView = NSStackView(views: arrangedSubviews)
        stackView.orientation = .horizontal
        stackView.spacing = Spacing.pt12
        stackView.alignment = .centerY
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        setupLayout()
        setupAccessibility()
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        // Add card as subview
        addSubview(card)
        
        // Add stack view to card
        card.addSubview(stackView)
        
        // Add message label if exists
        if let messageLabel = messageLabel {
            addSubview(messageLabel)
        }
        
        // Layout constraints
        card.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        // Card constraints
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Stack view constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: card.topAnchor, constant: Spacing.pt16),
            stackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Spacing.pt16),
            stackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Spacing.pt16)
        ])
        
        // Message label constraints if exists
        if let messageLabel = messageLabel {
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: Spacing.pt4),
                messageLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Spacing.pt16),
                messageLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Spacing.pt16),
                messageLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Spacing.pt16)
            ])
        } else {
            // If no message, expand stack view to fill card
            stackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Spacing.pt16).isActive = true
        }
        
        // Update card frame
        card.frame = bounds
    }
    
    private func setupAccessibility() {
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("\(toast.type.displayName): \(toast.title)")
        if let message = toast.message {
            setAccessibilityHelp(message)
        }
    }
    
    // MARK: - Layout
    
    override var fittingSize: NSSize {
        let contentWidth: CGFloat = 320
        let contentHeight: CGFloat = messageLabel != nil ? 80 : 56
        return NSSize(width: contentWidth, height: contentHeight)
    }
    
    override func layout() {
        super.layout()
        card.frame = bounds
    }
}