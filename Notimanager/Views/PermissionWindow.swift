//
//  PermissionWindow.swift
//  Notimanager
//
//  Modern permission request window with Liquid Glass design.
//  Provides clear guidance for granting accessibility permissions.
//

import AppKit

/// Modern permission window with Liquid Glass effects
class PermissionWindow: NSWindow {

    // MARK: - Properties

    private var scrollView: NSScrollView!
    private var documentView: NSView!
    private weak var coordinator: CoordinatorAction?

    private var statusIconView: NSImageView?
    private var statusTitleLabel: NSTextField?
    private var resetButton: NSButton?
    private var resetSettingsButton: NSButton?

    // Polling timer for permission status updates
    private var pollingTimer: Timer?
    private var pollingCount: Int = 0
    private let maxPollingAttempts: Int = 60 // 30 seconds (0.5s intervals)

    // MARK: - Initialization

    init(coordinator: CoordinatorAction) {
        self.coordinator = coordinator

        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: Layout.permissionWindowWidth,
                height: Layout.permissionWindowHeight
            ),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupScrollView()
        setupContent()
        setupAccessibility()
        setupAppearanceObservation()
        startPolling()
    }

    // MARK: - Setup

    private func setupWindow() {
        title = "Notimanager Setup"
        titlebarAppearsTransparent = true
        level = .floating
        isMovableByWindowBackground = true

        // Configure accessibility
        AccessibilityManager.shared.configureWindow(self, title: "Permission Setup")
    }

    private func setupScrollView() {
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: frame.width, height: frame.height))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        AccessibilityManager.shared.configureScrollView(scrollView)

        documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        // Add scroll view as content view
        if let contentView = contentView {
            contentView.addSubview(scrollView)
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
    }

    private func setupContent() {
        // Set document view frame
        documentView.frame = NSRect(
            x: 0,
            y: 0,
            width: frame.width,
            height: frame.height
        )

        var yPos = frame.height - Spacing.pt48

        // Add sections
        yPos = addIconSection(at: yPos) - Spacing.pt32
        yPos = addTitleSection(at: yPos) - Spacing.pt32
        yPos = addSubtitleSection(at: yPos) - Spacing.pt32
        yPos = addStatusSection(at: yPos) - Spacing.pt32
        _ = addButtonsSection(at: yPos)
    }

    private func setupAccessibility() {
        documentView.setAccessibilityLabel("Permission request")
        documentView.setAccessibilityRole(.group)
    }

    private func setupAppearanceObservation() {
        NotificationCenter.default.addObserver(
            forName: AppearanceManager.appearanceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateForAppearanceChanges()
        }
    }

    // MARK: - Section Builders

    private func addIconSection(at yPos: CGFloat) -> CGFloat {
        let iconSize: CGFloat = Layout.hugeIcon

        let iconContainer = NSView(frame: NSRect(
            x: (frame.width - iconSize) / 2,
            y: yPos - iconSize,
            width: iconSize,
            height: iconSize
        ))
        iconContainer.wantsLayer = true

        // Gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = iconContainer.bounds
        gradientLayer.colors = [
            NSColor.white.cgColor,
            NSColor.white.withAlphaComponent(0.92).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]

        let cornerRadius: CGFloat = iconSize / 1.618 / 1.5
        gradientLayer.cornerRadius = cornerRadius
        iconContainer.layer?.addSublayer(gradientLayer)

        // Shadow
        iconContainer.layer?.shadowColor = NSColor.black.cgColor
        iconContainer.layer?.shadowOpacity = 0.18
        iconContainer.layer?.shadowOffset = NSSize(width: 0, height: 6)
        iconContainer.layer?.shadowRadius = 16
        iconContainer.layer?.cornerRadius = cornerRadius

        // App icon
        let iconInset: CGFloat = iconSize / 1.618 / 3
        let iconView = NSImageView(frame: NSRect(
            x: iconInset,
            y: iconInset,
            width: iconSize - (iconInset * 2),
            height: iconSize - (iconInset * 2)
        ))

        if let icon = NSImage(named: "icon") {
            iconView.image = icon
            iconView.imageScaling = .scaleProportionallyDown
        }
        iconContainer.addSubview(iconView)
        documentView.addSubview(iconContainer)

        return yPos - iconSize
    }

    private func addTitleSection(at yPos: CGFloat) -> CGFloat {
        let titleHeight: CGFloat = Spacing.pt36
        let sideMargin: CGFloat = Spacing.pt40

        let titleLabel = NSTextField(labelWithString: "Welcome to Notimanager")
        titleLabel.frame = NSRect(
            x: sideMargin,
            y: yPos - titleHeight,
            width: frame.width - (sideMargin * 2),
            height: titleHeight
        )
        titleLabel.alignment = .center
        titleLabel.font = Typography.title1
        titleLabel.textColor = Colors.label
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.drawsBackground = false
        documentView.addSubview(titleLabel)

        return yPos - titleHeight
    }

    private func addSubtitleSection(at yPos: CGFloat) -> CGFloat {
        let subtitleHeight: CGFloat = Spacing.pt48
        let subtitleMargin: CGFloat = Spacing.pt60

        let subtitleLabel = NSTextField(
            wrappingLabelWithString: "Position your notifications anywhere on screen. Grant Accessibility permission to get started."
        )
        subtitleLabel.frame = NSRect(
            x: subtitleMargin,
            y: yPos - subtitleHeight,
            width: frame.width - (subtitleMargin * 2),
            height: subtitleHeight
        )
        subtitleLabel.alignment = .center
        subtitleLabel.font = Typography.body
        subtitleLabel.textColor = Colors.secondaryLabel
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.isEditable = false
        subtitleLabel.isSelectable = false
        subtitleLabel.drawsBackground = false
        documentView.addSubview(subtitleLabel)

        return yPos - subtitleHeight
    }

    private func addStatusSection(at yPos: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 72
        let cardMargin: CGFloat = Spacing.pt50

        let card = LiquidGlassCard.permissionCard(
            frame: NSRect(
                x: cardMargin,
                y: yPos - cardHeight,
                width: frame.width - (cardMargin * 2),
                height: cardHeight
            )
        )

        // Status icon
        let iconPadding: CGFloat = Spacing.pt24
        let statusIconSize: CGFloat = 36

        let statusIconView = NSImageView(frame: NSRect(
            x: iconPadding,
            y: (cardHeight - statusIconSize) / 2,
            width: statusIconSize,
            height: statusIconSize
        ))

        if let warningImage = NSImage(
            systemSymbolName: "exclamationmark.triangle.fill",
            accessibilityDescription: "Warning"
        ) {
            statusIconView.image = warningImage
            statusIconView.contentTintColor = Colors.warning
            statusIconView.imageScaling = .scaleProportionallyDown
        }

        card.addSubview(statusIconView)
        self.statusIconView = statusIconView

        // Status text
        let textX = iconPadding + statusIconSize + Spacing.pt20
        let statusTitle = NSTextField(labelWithString: "Accessibility Permission Required")
        statusTitle.frame = NSRect(
            x: textX,
            y: (cardHeight - Spacing.pt20) / 2,
            width: card.frame.width - textX - Spacing.pt20,
            height: Spacing.pt20
        )
        statusTitle.font = Typography.subheadline
        statusTitle.textColor = Colors.label
        statusTitle.isEditable = false
        statusTitle.isSelectable = false
        statusTitle.drawsBackground = false
        card.addSubview(statusTitle)

        self.statusTitleLabel = statusTitle

        documentView.addSubview(card)

        AccessibilityManager.shared.configureSection(card, title: "Permission Status")

        return yPos - cardHeight
    }

    private func addButtonsSection(at yPos: CGFloat) -> CGFloat {
        let buttonHeight: CGFloat = Layout.largeButtonHeight
        let buttonMargin: CGFloat = Spacing.pt50
        let buttonSpacing: CGFloat = Spacing.pt16
        let totalButtonWidth = frame.width - (buttonMargin * 2)

        // Calculate button widths using golden ratio
        let phi: CGFloat = 1.618
        let primaryButtonWidth = totalButtonWidth * (phi / (phi + 1)) - (buttonSpacing / 2)
        let secondaryButtonWidth = totalButtonWidth - primaryButtonWidth - buttonSpacing

        // Request button
        let requestBtn = NSButton(frame: NSRect(
            x: buttonMargin,
            y: yPos - buttonHeight,
            width: primaryButtonWidth,
            height: buttonHeight
        ))
        requestBtn.title = "Open System Settings"
        requestBtn.bezelStyle = .rounded
        requestBtn.controlSize = .large
        requestBtn.keyEquivalent = "\r"
        requestBtn.target = self
        requestBtn.action = #selector(requestPermission)

        documentView.addSubview(requestBtn)

        // Clear button
        let clearBtn = NSButton(frame: NSRect(
            x: buttonMargin + primaryButtonWidth + buttonSpacing,
            y: yPos - buttonHeight,
            width: secondaryButtonWidth,
            height: buttonHeight
        ))
        clearBtn.title = "Clear Permission"
        clearBtn.bezelStyle = .rounded
        clearBtn.controlSize = .large
        clearBtn.target = self
        clearBtn.action = #selector(clearPermission)
        documentView.addSubview(clearBtn)

        // Restart button (hidden initially)
        let restartBtn = NSButton(frame: NSRect(
            x: (frame.width - 200) / 2,
            y: yPos - buttonHeight,
            width: 200,
            height: buttonHeight
        ))
        restartBtn.title = "Restart App"
        restartBtn.bezelStyle = .rounded
        restartBtn.controlSize = .large
        restartBtn.keyEquivalent = "\r"
        restartBtn.target = self
        restartBtn.action = #selector(restartApp)
        restartBtn.isHidden = true
        documentView.addSubview(restartBtn)

        self.resetButton = restartBtn

        // Configure accessibility for buttons
        AccessibilityManager.shared.configureButton(
            requestBtn,
            label: "Open System Settings"
        )
        requestBtn.toolTip = "Opens macOS Accessibility settings to grant permission"

        AccessibilityManager.shared.configureButton(
            clearBtn,
            label: "Clear Permission"
        )
        clearBtn.toolTip = "Resets accessibility permission (useful for troubleshooting)"

        AccessibilityManager.shared.configureButton(
            restartBtn,
            label: "Restart App"
        )
        restartBtn.toolTip = "Restarts the app to apply changes"

        // Reset Settings Accessibility button (secondary action below main buttons)
        let resetSettingsYPos = yPos - buttonHeight - Spacing.pt12
        let resetSettingsBtnWidth: CGFloat = 240
        let resetSettingsBtn = NSButton(frame: NSRect(
            x: (frame.width - resetSettingsBtnWidth) / 2,
            y: resetSettingsYPos,
            width: resetSettingsBtnWidth,
            height: Layout.regularButtonHeight
        ))
        resetSettingsBtn.title = "Reset Settings Accessibility"
        resetSettingsBtn.bezelStyle = .regularSquare
        resetSettingsBtn.controlSize = .regular
        resetSettingsBtn.target = self
        resetSettingsBtn.action = #selector(resetSettingsAccessibility)
        documentView.addSubview(resetSettingsBtn)

        self.resetSettingsButton = resetSettingsBtn

        // Configure accessibility
        AccessibilityManager.shared.configureButton(
            resetSettingsBtn,
            label: "Reset Settings Accessibility"
        )
        resetSettingsBtn.toolTip = "Resets the accessibility settings for Notimanager in System Settings"

        return resetSettingsYPos - Layout.regularButtonHeight - Spacing.pt32
    }

    // MARK: - Permission Polling

    private func startPolling() {
        pollingCount = 0

        // Poll every 0.5 seconds
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.pollingCount += 1
            if self.pollingCount > self.maxPollingAttempts {
                self.stopPolling()
                return
            }

            self.checkPermissionStatus()
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func checkPermissionStatus() {
        let isGranted = AXIsProcessTrusted()
        updatePermissionStatus(granted: isGranted)

        if isGranted {
            stopPolling()
        }
    }

    // MARK: - UI Updates

    private func updatePermissionStatus(granted: Bool) {
        guard let statusIconView = statusIconView,
              let statusTitleLabel = statusTitleLabel,
              let resetBtn = resetButton else {
            return
        }

        if granted {
            // Update to granted state
            if let checkmarkImage = NSImage(
                systemSymbolName: "checkmark.circle.fill",
                accessibilityDescription: "Granted"
            ) {
                statusIconView.image = checkmarkImage
                statusIconView.contentTintColor = Colors.success
            }

            statusTitleLabel.stringValue = "Accessibility Permission Granted"
            statusTitleLabel.textColor = Colors.success

            // Show restart button, hide other buttons
            resetBtn.isHidden = false

            // Update accessibility
            AccessibilityManager.shared.announceStatus(
                "Accessibility permission granted. Restart the app to begin using Notimanager.",
                isImportant: true
            )
        } else {
            // Update to required state
            if let warningImage = NSImage(
                systemSymbolName: "exclamationmark.triangle.fill",
                accessibilityDescription: "Required"
            ) {
                statusIconView.image = warningImage
                statusIconView.contentTintColor = Colors.warning
            }

            statusTitleLabel.stringValue = "Accessibility Permission Required"
            statusTitleLabel.textColor = Colors.label

            // Hide restart button
            resetBtn.isHidden = true
        }
    }

    private func updateForAppearanceChanges() {
        // Update cards for appearance changes
        for subview in documentView.subviews {
            if let card = subview as? LiquidGlassCard {
                card.updateForHighContrast(AppearanceManager.shared.isHighContrast)
                card.updateForReduceTransparency(AppearanceManager.shared.isReduceTransparency)
            }
        }
    }

    // MARK: - Actions

    @objc private func requestPermission() {
        coordinator?.requestAccessibilityPermission()
    }

    @objc private func clearPermission() {
        coordinator?.resetAccessibilityPermission()
    }

    @objc private func restartApp() {
        AccessibilityManager.shared.announce("Restarting application...")

        // Small delay for announcement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
    }

    @objc private func resetSettingsAccessibility() {
        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Reset Settings Accessibility?", comment: "Alert title")
        alert.informativeText = NSLocalizedString(
            "This will reset Notimanager's accessibility setting in System Settings.\n\nYou will need to manually grant accessibility permission again after this reset.",
            comment: "Alert message"
        )
        alert.addButton(withTitle: NSLocalizedString("Reset", comment: "Button title"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Button title"))
        alert.alertStyle = .warning
        alert.showsSuppressionButton = false

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // User confirmed - execute reset
            do {
                let bundleID = Bundle.main.bundleIdentifier ?? "dev.abd3lraouf.notimanager"

                let task = Process()
                task.launchPath = "/usr/bin/tccutil"
                task.arguments = ["reset", "Accessibility", bundleID]

                try task.run()
                task.waitUntilExit()

                if task.terminationStatus == 0 {
                    // Show success alert
                    let successAlert = NSAlert()
                    successAlert.messageText = NSLocalizedString("Reset Complete", comment: "Success title")
                    successAlert.informativeText = NSLocalizedString(
                        "Accessibility setting has been reset. Please grant permission again in System Settings > Privacy & Security > Accessibility.",
                        comment: "Success message"
                    )
                    successAlert.addButton(withTitle: NSLocalizedString("OK", comment: "Button title"))
                    successAlert.alertStyle = .informational
                    successAlert.runModal()

                    // Update permission status
                    checkPermissionStatus()
                } else {
                    throw PermissionError.resetFailed
                }
            } catch {
                // Show error alert
                let errorAlert = NSAlert()
                errorAlert.messageText = NSLocalizedString("Reset Failed", comment: "Error title")
                errorAlert.informativeText = NSLocalizedString(
                    "Failed to reset accessibility setting. Please try again or reset manually in System Settings.",
                    comment: "Error message"
                )
                errorAlert.addButton(withTitle: NSLocalizedString("OK", comment: "Button title"))
                errorAlert.alertStyle = .critical
                errorAlert.runModal()
            }
        }
    }

    // MARK: - Errors

    enum PermissionError: Error {
        case resetFailed
    }

    // MARK: - Public Methods

    /// Updates the permission status display
    func updateStatus(granted: Bool) {
        updatePermissionStatus(granted: granted)

        if granted {
            stopPolling()
        }
    }

    /// Shows the permission window
    func show() {
        center()
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Announce window opened
        AccessibilityManager.shared.announce(
            "Permission window opened. Accessibility permission is required."
        )
    }
}
