//
//  SettingsViewController.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  MVVM settings view controller extracted from NotificationMover
//

import Cocoa
import UserNotifications

/// Settings View Controller using MVVM architecture
class SettingsViewController: NSViewController {

    // MARK: - Properties

    private let viewModel: SettingsViewModel
    private var window: NSWindow?
    private var positionButtons: [NSVisualEffectView] = []
    private var testStatusLabel: NSTextField?

    // MARK: - Initialization

    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupViewModelBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 1020))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupViewModelBindings() {
        viewModel.onPositionChanged = { [weak self] position in
            self?.updatePositionUI(position)
        }

        viewModel.onEnabledChanged = { [weak self] enabled in
            self?.updateEnabledUI(enabled)
        }

        viewModel.onTestStatusChanged = { [weak self] status in
            self?.updateTestStatus(status)
        }
    }

    private func setupUI() {
        let contentView = view

        // Golden ratio spacing system
        let phi: CGFloat = 1.618
        let baseUnit: CGFloat = 12.0
        let spacing1 = baseUnit * phi
        let spacing2 = baseUnit * phi * phi
        let margin = spacing2
        let cardPadding = spacing1

        var yPos: CGFloat = 1020 - 84

        // Position Section
        let positionCard = createPositionSectionCard(frame: NSRect(x: margin, y: 0, width: 600 - (margin * 2), height: 330))
        positionCard.frame.origin.y = yPos - 330
        contentView.addSubview(positionCard)
        yPos = positionCard.frame.origin.y - spacing2

        // Test & Permissions Section
        let testPermCard = createTestPermissionsSectionCard(frame: NSRect(x: margin, y: 0, width: 600 - (margin * 2), height: 180))
        testPermCard.frame.origin.y = yPos - 180
        contentView.addSubview(testPermCard)
        yPos = testPermCard.frame.origin.y - spacing2

        // Preferences Section
        let prefsCard = createPreferencesSectionCard(frame: NSRect(x: margin, y: 0, width: 600 - (margin * 2), height: 168))
        prefsCard.frame.origin.y = yPos - 168
        contentView.addSubview(prefsCard)
        yPos = prefsCard.frame.origin.y - spacing2

        // About Section
        let aboutCard = createAboutSectionCard(frame: NSRect(x: margin, y: 0, width: 600 - (margin * 2), height: 110))
        aboutCard.frame.origin.y = yPos - 110
        contentView.addSubview(aboutCard)
    }

    // MARK: - Card Creation

    private func createPositionSectionCard(frame: NSRect) -> NSVisualEffectView {
        let card = createLiquidGlassCard(frame: frame)

        let cardPadding: CGFloat = 19.0
        var innerY = frame.height - 36

        // Section header
        let positionLabel = NSTextField(labelWithString: "Notification Position")
        positionLabel.frame = NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 28)
        positionLabel.font = .systemFont(ofSize: 15, weight: .medium)
        positionLabel.textColor = .labelColor
        card.addSubview(positionLabel)

        // Position grid selector
        let gridSize: CGFloat = 80
        let gridSpacing: CGFloat = 19.0
        let totalGridWidth = (gridSize * 3) + (gridSpacing * 2)
        let gridStartX: CGFloat = (frame.width - totalGridWidth) / 2
        let gridStartY: CGFloat = cardPadding + 10

        for (index, position) in NotificationPosition.allCases.enumerated() {
            let row = index / 3
            let col = index % 3
            let x = gridStartX + CGFloat(col) * (gridSize + gridSpacing)
            let y = gridStartY + CGFloat(2 - row) * (gridSize + gridSpacing)

            let buttonContainer = createPositionButton(
                position: position,
                frame: NSRect(x: x, y: y, width: gridSize, height: gridSize),
                isSelected: position == viewModel.currentPosition
            )
            positionButtons.append(buttonContainer)
            card.addSubview(buttonContainer)
        }

        return card
    }

    private func createPositionButton(position: NotificationPosition, frame: NSRect, isSelected: Bool) -> NSVisualEffectView {
        let phi: CGFloat = 1.618

        let buttonContainer = NSVisualEffectView(frame: frame)
        buttonContainer.material = isSelected ? .selection : .underWindowBackground
        buttonContainer.blendingMode = .withinWindow
        buttonContainer.state = .active
        buttonContainer.wantsLayer = true

        let cornerRadius: CGFloat = frame.width / phi / 1.2
        buttonContainer.layer?.cornerRadius = cornerRadius
        buttonContainer.layer?.borderWidth = isSelected ? 2.5 : 1
        buttonContainer.layer?.borderColor = isSelected
            ? NSColor.controlAccentColor.cgColor
            : NSColor.separatorColor.withAlphaComponent(0.4).cgColor

        buttonContainer.shadow = NSShadow()
        buttonContainer.shadow?.shadowColor = NSColor.black.withAlphaComponent(isSelected ? 0.15 : 0.08)
        buttonContainer.shadow?.shadowOffset = NSSize(width: 0, height: -1)
        buttonContainer.shadow?.shadowBlurRadius = isSelected ? 6 : 3

        let button = NSButton(frame: NSRect(x: 0, y: 0, width: frame.width, height: frame.height))
        button.title = ""
        button.bezelStyle = .shadowlessSquare
        button.isBordered = false
        button.tag = NotificationPosition.allCases.firstIndex(of: position) ?? 0
        button.target = self
        button.action = #selector(positionButtonClicked(_:))
        button.toolTip = position.displayName
        button.wantsLayer = true
        button.layer?.backgroundColor = .clear

        let iconSize: CGFloat = 32
        let iconPadding = (frame.width - iconSize) / 2
        let iconView = NSImageView(frame: NSRect(x: iconPadding, y: iconPadding, width: iconSize, height: iconSize))
        iconView.image = getPositionIcon(for: position)
        iconView.contentTintColor = isSelected ? .controlAccentColor : .tertiaryLabelColor
        iconView.imageScaling = .scaleProportionallyDown
        button.addSubview(iconView)

        buttonContainer.addSubview(button)
        return buttonContainer
    }

    private func createTestPermissionsSectionCard(frame: NSRect) -> NSVisualEffectView {
        let card = createLiquidGlassCard(frame: frame)
        let cardPadding: CGFloat = 19.0
        var innerY = frame.height - 36

        // Test Notification subsection
        let testLabel = NSTextField(labelWithString: "Test Notification")
        testLabel.frame = NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 24)
        testLabel.font = .systemFont(ofSize: 15, weight: .medium)
        card.addSubview(testLabel)
        innerY -= 40

        let testButton = NSButton(frame: NSRect(x: cardPadding, y: innerY, width: 140, height: 32))
        testButton.title = "Send Test"
        testButton.bezelStyle = .rounded
        testButton.controlSize = .large
        testButton.target = self
        testButton.action = #selector(sendTestNotification)
        card.addSubview(testButton)

        let statusLabel = NSTextField(labelWithString: "Not tested yet")
        statusLabel.frame = NSRect(x: cardPadding + 150, y: innerY + 8, width: frame.width - cardPadding - 160, height: 18)
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .tertiaryLabelColor
        card.addSubview(statusLabel)
        testStatusLabel = statusLabel
        innerY -= 32

        let helperText = NSTextField(wrappingLabelWithString: "💡 For best results, test with real notifications from Calendar, Mail, or Messages")
        helperText.frame = NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 32)
        helperText.font = .systemFont(ofSize: 11)
        helperText.textColor = .secondaryLabelColor
        helperText.maximumNumberOfLines = 2
        helperText.lineBreakMode = .byWordWrapping
        helperText.isBezeled = false
        helperText.isEditable = false
        helperText.isSelectable = false
        helperText.drawsBackground = false
        card.addSubview(helperText)
        innerY -= 52

        // Separator
        let separator = NSBox(frame: NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 1))
        separator.boxType = .separator
        separator.alphaValue = 0.3
        card.addSubview(separator)
        innerY -= 30

        // Permission subsection
        let isGranted = viewModel.isAccessibilityGranted
        let permLabel = NSTextField(labelWithString: "Accessibility")
        permLabel.frame = NSRect(x: cardPadding, y: innerY, width: 150, height: 24)
        permLabel.font = .systemFont(ofSize: 15, weight: .medium)
        card.addSubview(permLabel)

        let permStatusLabel = NSTextField(labelWithString: isGranted ? "Granted" : "Required")
        permStatusLabel.frame = NSRect(x: cardPadding + 120, y: innerY + 2, width: 120, height: 18)
        permStatusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        permStatusLabel.textColor = isGranted ? .systemGreen : .systemOrange
        card.addSubview(permStatusLabel)
        innerY -= 36

        if isGranted {
            let clearBtn = NSButton(frame: NSRect(x: frame.width - cardPadding - 230, y: innerY, width: 110, height: 28))
            clearBtn.title = "Clear"
            clearBtn.bezelStyle = .rounded
            clearBtn.controlSize = .small
            clearBtn.target = self
            clearBtn.action = #selector(resetPermission)
            card.addSubview(clearBtn)

            let restartBtn = NSButton(frame: NSRect(x: frame.width - cardPadding - 110, y: innerY, width: 110, height: 28))
            restartBtn.title = "Restart App"
            restartBtn.bezelStyle = .rounded
            restartBtn.controlSize = .small
            restartBtn.target = self
            restartBtn.action = #selector(restartApp)
            card.addSubview(restartBtn)
        } else {
            let requestBtn = NSButton(frame: NSRect(x: frame.width - cardPadding - 180, y: innerY, width: 180, height: 28))
            requestBtn.title = "Open System Settings"
            requestBtn.bezelStyle = .rounded
            requestBtn.controlSize = .small
            requestBtn.target = self
            requestBtn.action = #selector(requestPermission)
            card.addSubview(requestBtn)
        }

        return card
    }

    private func createPreferencesSectionCard(frame: NSRect) -> NSVisualEffectView {
        let card = createLiquidGlassCard(frame: frame)
        let cardPadding: CGFloat = 19.0
        var innerY = frame.height - 36

        let prefsLabel = NSTextField(labelWithString: "Preferences")
        prefsLabel.frame = NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 24)
        prefsLabel.font = .systemFont(ofSize: 15, weight: .medium)
        card.addSubview(prefsLabel)
        innerY -= 34

        let enabledCheckbox = NSButton(checkboxWithTitle: "Enable notification positioning", target: self, action: #selector(enabledToggled(_:)))
        enabledCheckbox.frame = NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 20)
        enabledCheckbox.state = viewModel.isEnabled ? .on : .off
        enabledCheckbox.font = .systemFont(ofSize: 13)
        card.addSubview(enabledCheckbox)
        innerY -= 34

        let launchCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(launchToggled(_:)))
        launchCheckbox.frame = NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 20)
        launchCheckbox.state = viewModel.isLaunchAtLoginEnabled ? .on : .off
        launchCheckbox.font = .systemFont(ofSize: 13)
        card.addSubview(launchCheckbox)
        innerY -= 28

        let debugCheckbox = NSButton(checkboxWithTitle: "Debug mode", target: self, action: #selector(debugToggled(_:)))
        debugCheckbox.frame = NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 20)
        debugCheckbox.state = viewModel.debugMode ? .on : .off
        debugCheckbox.font = .systemFont(ofSize: 13)
        card.addSubview(debugCheckbox)
        innerY -= 28

        let hideIconCheckbox = NSButton(checkboxWithTitle: "Hide menu bar icon", target: self, action: #selector(hideIconToggled(_:)))
        hideIconCheckbox.frame = NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 20)
        hideIconCheckbox.state = viewModel.isMenuBarIconHidden ? .on : .off
        hideIconCheckbox.font = .systemFont(ofSize: 13)
        card.addSubview(hideIconCheckbox)

        return card
    }

    private func createAboutSectionCard(frame: NSRect) -> NSVisualEffectView {
        let card = createLiquidGlassCard(frame: frame)
        let cardPadding: CGFloat = 19.0
        var innerY = frame.height - 36

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        let versionLabel = NSTextField(labelWithString: "Notimanager v\(version)")
        versionLabel.frame = NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 22)
        versionLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        card.addSubview(versionLabel)
        innerY -= 26

        let madeByLabel = NSTextField(labelWithString: "Made with ❤️  by Wade Grimridge")
        madeByLabel.frame = NSRect(x: cardPadding, y: innerY, width: frame.width - (cardPadding * 2), height: 18)
        madeByLabel.font = .systemFont(ofSize: 12)
        madeByLabel.textColor = .tertiaryLabelColor
        card.addSubview(madeByLabel)
        innerY -= 36

        let kofiBtn = NSButton(frame: NSRect(x: cardPadding, y: innerY, width: 150, height: 28))
        kofiBtn.title = "Support on Ko-fi"
        kofiBtn.bezelStyle = .rounded
        kofiBtn.controlSize = .small
        kofiBtn.target = self
        kofiBtn.action = #selector(openKofi)
        card.addSubview(kofiBtn)

        let coffeeBtn = NSButton(frame: NSRect(x: cardPadding + 160, y: innerY, width: 160, height: 28))
        coffeeBtn.title = "Buy Me a Coffee"
        coffeeBtn.bezelStyle = .rounded
        coffeeBtn.controlSize = .small
        coffeeBtn.target = self
        coffeeBtn.action = #selector(openBuyMeACoffee)
        card.addSubview(coffeeBtn)

        return card
    }

    private func createLiquidGlassCard(frame: NSRect) -> NSVisualEffectView {
        let phi: CGFloat = 1.618

        let card = NSVisualEffectView(frame: frame)
        card.material = .contentBackground
        card.blendingMode = .withinWindow
        card.state = .active
        card.wantsLayer = true

        let cornerRadius = frame.height / phi / 3.5
        card.layer?.cornerRadius = min(cornerRadius, 12)
        card.layer?.borderWidth = 0.5
        card.layer?.borderColor = NSColor.white.withAlphaComponent(0.1).cgColor

        card.shadow = NSShadow()
        card.shadow?.shadowColor = NSColor.black.withAlphaComponent(0.12)
        card.shadow?.shadowOffset = NSSize(width: 0, height: -3)
        card.shadow?.shadowBlurRadius = 12

        return card
    }

    // MARK: - Actions

    @objc private func positionButtonClicked(_ sender: NSButton) {
        let position = NotificationPosition.allCases[sender.tag]
        viewModel.updatePosition(to: position)
    }

    @objc private func sendTestNotification() {
        viewModel.sendTestNotification()
    }

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

    @objc private func enabledToggled(_ sender: NSButton) {
        viewModel.setEnabled(sender.state == .on)
    }

    @objc private func launchToggled(_ sender: NSButton) {
        viewModel.setLaunchAtLogin(sender.state == .on)
    }

    @objc private func debugToggled(_ sender: NSButton) {
        viewModel.setDebugMode(sender.state == .on)
    }

    @objc private func hideIconToggled(_ sender: NSButton) {
        viewModel.setMenuBarIconHidden(sender.state == .on)
    }

    @objc private func openKofi() {
        NSWorkspace.shared.open(URL(string: "https://ko-fi.com/wadegrimridge")!)
    }

    @objc private func openBuyMeACoffee() {
        NSWorkspace.shared.open(URL(string: "https://www.buymeacoffee.com/wadegrimridge")!)
    }

    // MARK: - UI Updates

    private func updatePositionUI(_ position: NotificationPosition) {
        for (index, buttonContainer) in positionButtons.enumerated() {
            let isSelected = index == NotificationPosition.allCases.firstIndex(of: position)

            buttonContainer.material = isSelected ? .selection : .underWindowBackground
            buttonContainer.layer?.borderWidth = isSelected ? 2.5 : 1
            buttonContainer.layer?.borderColor = isSelected
                ? NSColor.controlAccentColor.cgColor
                : NSColor.separatorColor.withAlphaComponent(0.4).cgColor

            buttonContainer.shadow?.shadowColor = NSColor.black.withAlphaComponent(isSelected ? 0.15 : 0.08)
            buttonContainer.shadow?.shadowBlurRadius = isSelected ? 6 : 3

            if let button = buttonContainer.subviews.first as? NSButton,
               let iconView = button.subviews.first as? NSImageView {
                iconView.contentTintColor = isSelected ? .controlAccentColor : .tertiaryLabelColor
            }
        }
    }

    private func updateEnabledUI(_ enabled: Bool) {
        // Update any UI that depends on enabled state
    }

    private func updateTestStatus(_ status: String) {
        testStatusLabel?.stringValue = status

        if status.contains("✓") {
            testStatusLabel?.textColor = .systemGreen
        } else if status.contains("✗") {
            testStatusLabel?.textColor = .systemRed
        } else if status.contains("ℹ️") {
            testStatusLabel?.textColor = .systemOrange
        } else {
            testStatusLabel?.textColor = .secondaryLabelColor
        }
    }

    // MARK: - Helpers

    private func getPositionIcon(for position: NotificationPosition) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        return NSImage(systemSymbolName: position.iconName, accessibilityDescription: position.displayName)?
            .withSymbolConfiguration(config)
    }

    // MARK: - Window Management

    func showInWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 1020),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Notimanager"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.level = .floating
        window.minSize = NSSize(width: 600, height: 1020)

        let contentView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 600, height: 1020))
        contentView.material = .sidebar
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

extension SettingsViewController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
