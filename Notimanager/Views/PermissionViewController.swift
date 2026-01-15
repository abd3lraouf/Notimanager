//
//  PermissionViewController.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  MVVM permission view controller extracted from NotificationMover
//

import Cocoa

/// Permission View Controller using MVVM architecture
class PermissionViewController: NSViewController {

    // MARK: - Properties

    private let viewModel: PermissionViewModel
    private var window: NSWindow?
    private var permissionPollingTimer: Timer?

    private var statusCard: NSVisualEffectView?
    private var statusIconView: NSImageView?
    private var statusTitle: NSTextField?
    private var requestButton: NSButton?
    private var restartButton: NSButton?

    // MARK: - Initialization

    init(viewModel: PermissionViewModel = PermissionViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupViewModelBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 460))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startPermissionPolling()
    }

    deinit {
        permissionPollingTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupViewModelBindings() {
        viewModel.onPermissionStatusChanged = { [weak self] isGranted in
            self?.updatePermissionStatus(granted: isGranted)
        }

        viewModel.onPermissionRequested = { [weak self] in
            self?.updateUIForWaiting()
        }
    }

    private func setupUI() {
        let contentView = view

        // Golden ratio based spacing
        let phi: CGFloat = 1.618
        let baseUnit: CGFloat = 20
        let windowWidth: CGFloat = 520

        let bottomMargin = baseUnit * phi
        let spacing1 = baseUnit * 1.5
        let spacing2 = baseUnit * phi
        let spacing3 = baseUnit
        let spacing4 = baseUnit * 1.25

        let buttonHeight: CGFloat = 44
        let statusCardHeight: CGFloat = 72
        let iconSize: CGFloat = 100

        // Bottom-up layout calculation
        var yPos = bottomMargin
        let buttonY = yPos

        yPos += buttonHeight + spacing1
        let statusCardY = yPos

        yPos += statusCardHeight + spacing2
        let subtitleY = yPos
        let subtitleHeight: CGFloat = 44

        yPos += subtitleHeight + spacing3
        let titleY = yPos
        let titleHeight: CGFloat = 36

        yPos += titleHeight + spacing4
        let iconY = yPos

        // App Icon
        let iconContainer = createIconContainer(
            frame: NSRect(x: (windowWidth - iconSize) / 2, y: iconY, width: iconSize, height: iconSize)
        )
        contentView.addSubview(iconContainer)

        // Title
        let sideMargin = baseUnit * 2
        let titleLabel = NSTextField(labelWithString: "Welcome to Notimanager")
        titleLabel.frame = NSRect(x: sideMargin, y: titleY, width: windowWidth - (sideMargin * 2), height: titleHeight)
        titleLabel.alignment = .center
        titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.drawsBackground = false
        contentView.addSubview(titleLabel)

        // Subtitle
        let subtitleMargin = baseUnit * 3
        let subtitleLabel = NSTextField(wrappingLabelWithString: "Position your notifications anywhere on screen. Grant Accessibility permission to get started.")
        subtitleLabel.frame = NSRect(x: subtitleMargin, y: subtitleY, width: windowWidth - (subtitleMargin * 2), height: subtitleHeight)
        subtitleLabel.alignment = .center
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.isBezeled = false
        subtitleLabel.isEditable = false
        subtitleLabel.isSelectable = false
        subtitleLabel.drawsBackground = false
        contentView.addSubview(subtitleLabel)

        // Status Card
        let cardMargin = baseUnit * 2.5
        let statusCard = createStatusCard(
            frame: NSRect(x: cardMargin, y: statusCardY, width: windowWidth - (cardMargin * 2), height: statusCardHeight),
            isGranted: viewModel.isAccessibilityGranted
        )
        contentView.addSubview(statusCard)

        self.statusCard = statusCard

        // Buttons
        let buttonMargin = baseUnit * 2.5
        let buttonSpacing = baseUnit * 0.8
        let totalButtonWidth = windowWidth - (buttonMargin * 2)

        let primaryButtonWidth = totalButtonWidth * (phi / (phi + 1)) - (buttonSpacing / 2)
        let secondaryButtonWidth = totalButtonWidth - primaryButtonWidth - buttonSpacing

        let requestBtn = NSButton(frame: NSRect(x: buttonMargin, y: buttonY, width: primaryButtonWidth, height: buttonHeight))
        requestBtn.title = "Open System Settings"
        requestBtn.bezelStyle = .rounded
        requestBtn.controlSize = .large
        requestBtn.keyEquivalent = "\r"
        requestBtn.target = self
        requestBtn.action = #selector(requestPermission)
        contentView.addSubview(requestBtn)
        requestButton = requestBtn

        let clearBtn = NSButton(frame: NSRect(x: buttonMargin + primaryButtonWidth + buttonSpacing, y: buttonY, width: secondaryButtonWidth, height: buttonHeight))
        clearBtn.title = "Clear Permission"
        clearBtn.bezelStyle = .rounded
        clearBtn.controlSize = .large
        clearBtn.target = self
        clearBtn.action = #selector(resetPermission)
        contentView.addSubview(clearBtn)

        // Restart button (initially hidden)
        let restartButtonWidth: CGFloat = 200
        let resetBtn = NSButton(frame: NSRect(x: (windowWidth - restartButtonWidth) / 2, y: buttonY, width: restartButtonWidth, height: buttonHeight))
        resetBtn.title = "Restart App"
        resetBtn.bezelStyle = .rounded
        resetBtn.controlSize = .large
        resetBtn.keyEquivalent = "\r"
        resetBtn.target = self
        resetBtn.action = #selector(restartApp)
        resetBtn.isHidden = true
        contentView.addSubview(resetBtn)
        restartButton = resetBtn
    }

    private func createIconContainer(frame: NSRect) -> NSView {
        let phi: CGFloat = 1.618
        let iconSize = frame.width

        let iconContainer = NSView(frame: frame)
        iconContainer.wantsLayer = true

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
        gradientLayer.colors = [
            NSColor.white.cgColor,
            NSColor.white.withAlphaComponent(0.92).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]

        let cornerRadius = iconSize / phi / 1.5
        gradientLayer.cornerRadius = cornerRadius
        iconContainer.layer?.addSublayer(gradientLayer)

        iconContainer.layer?.shadowColor = NSColor.black.cgColor
        iconContainer.layer?.shadowOpacity = 0.18
        iconContainer.layer?.shadowOffset = CGSize(width: 0, height: 6)
        iconContainer.layer?.shadowRadius = 16
        iconContainer.layer?.cornerRadius = cornerRadius
        iconContainer.layer?.masksToBounds = false

        let iconInset = iconSize / phi / 3
        let iconView = NSImageView(frame: NSRect(x: iconInset, y: iconInset, width: iconSize - (iconInset * 2), height: iconSize - (iconInset * 2)))
        if let icon = NSImage(named: "icon") {
            iconView.image = icon
            iconView.imageScaling = .scaleProportionallyDown
        }
        iconContainer.addSubview(iconView)

        return iconContainer
    }

    private func createStatusCard(frame: NSRect, isGranted: Bool) -> NSVisualEffectView {
        let phi: CGFloat = 1.618
        let baseUnit: CGFloat = 20

        let statusCard = NSVisualEffectView(frame: frame)
        statusCard.material = .contentBackground
        statusCard.blendingMode = .withinWindow
        statusCard.state = .active
        statusCard.wantsLayer = true

        let cardCornerRadius = frame.height / phi / 1.2
        statusCard.layer?.cornerRadius = cardCornerRadius
        statusCard.layer?.borderWidth = 0.5
        statusCard.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.25).cgColor

        statusCard.layer?.shadowColor = NSColor.black.cgColor
        statusCard.layer?.shadowOpacity = 0.05
        statusCard.layer?.shadowOffset = CGSize(width: 0, height: 2)
        statusCard.layer?.shadowRadius = 4

        let iconPadding = baseUnit * 1.2
        let statusIconSize: CGFloat = 36
        let statusIconView = NSImageView(frame: NSRect(x: iconPadding, y: (frame.height - statusIconSize) / 2, width: statusIconSize, height: statusIconSize))

        let imageName = isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
        let tintColor = isGranted ? NSColor.systemGreen : NSColor.systemOrange

        if let warningImage = NSImage(systemSymbolName: imageName, accessibilityDescription: isGranted ? "Success" : "Warning") {
            statusIconView.image = warningImage
            statusIconView.contentTintColor = tintColor
            statusIconView.imageScaling = .scaleProportionallyDown
        }
        statusCard.addSubview(statusIconView)
        self.statusIconView = statusIconView

        let textX = iconPadding + statusIconSize + baseUnit
        let statusTitle = NSTextField(labelWithString: isGranted ? "Permission Granted! ✓" : "Accessibility Permission Required")
        statusTitle.frame = NSRect(x: textX, y: (frame.height - 20) / 2, width: frame.width - textX - baseUnit, height: 20)
        statusTitle.font = .systemFont(ofSize: 15, weight: .medium)
        statusTitle.textColor = isGranted ? .systemGreen : .labelColor
        statusTitle.isBezeled = false
        statusTitle.isEditable = false
        statusTitle.isSelectable = false
        statusTitle.drawsBackground = false
        statusCard.addSubview(statusTitle)
        self.statusTitle = statusTitle

        return statusCard
    }

    // MARK: - Actions

    @objc private func requestPermission() {
        viewModel.requestAccessibilityPermission()
    }

    @objc private func resetPermission() {
        viewModel.resetAccessibilityPermission()
    }

    @objc private func restartApp() {
        viewModel.restartApp()
        window?.close()
    }

    // MARK: - UI Updates

    private func updatePermissionStatus(granted: Bool) {
        guard let statusCard = statusCard,
              let statusIconView = statusIconView,
              let statusTitle = statusTitle else {
            return
        }

        if granted {
            if let successImage = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Success") {
                statusIconView.image = successImage
                statusIconView.contentTintColor = .systemGreen
            }

            statusTitle.stringValue = "Permission Granted! ✓"
            statusTitle.textColor = .systemGreen

            statusCard.layer?.borderColor = NSColor.systemGreen.withAlphaComponent(0.5).cgColor

            requestButton?.isHidden = true

            // Hide clear button
            let contentView = view
            for subview in contentView.subviews {
                if let button = subview as? NSButton, button.title == "Clear Permission" {
                    button.isHidden = true
                }
            }

            restartButton?.isHidden = false
        } else {
            if let warningImage = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Warning") {
                statusIconView.image = warningImage
                statusIconView.contentTintColor = .systemOrange
            }

            statusTitle.stringValue = "Accessibility Permission Required"
            statusTitle.textColor = .labelColor

            statusCard.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.3).cgColor

            requestButton?.isHidden = false
            requestButton?.isEnabled = true
            requestButton?.title = "Open System Settings"

            // Show clear button
            let contentView = view
            for subview in contentView.subviews {
                if let button = subview as? NSButton, button.title == "Clear Permission" {
                    button.isHidden = false
                }
            }

            restartButton?.isHidden = true
        }
    }

    private func updateUIForWaiting() {
        requestButton?.title = "Waiting..."
        requestButton?.isEnabled = false

        statusTitle?.stringValue = "Waiting for permission..."
        statusTitle?.textColor = .secondaryLabelColor
    }

    private func startPermissionPolling() {
        permissionPollingTimer?.invalidate()

        permissionPollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let isGranted = self.viewModel.isAccessibilityGranted

            if isGranted {
                self.viewModel.updatePermissionStatus(granted: true)
                self.permissionPollingTimer?.invalidate()
            } else {
                self.viewModel.updatePermissionStatus(granted: false)
            }
        }
    }

    // MARK: - Window Management

    func showInWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Notimanager Setup"
        window.titlebarAppearsTransparent = true
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.delegate = self

        let contentView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 520, height: 460))
        contentView.material = .hudWindow
        contentView.blendingMode = .behindWindow
        contentView.state = .active
        contentView.addSubview(view)

        window.contentView = contentView
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSWindowDelegate

extension PermissionViewController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
