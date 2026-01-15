//
//  ModernSettingsWindow.swift
//  Notimanager
//
//  Modern settings window with sidebar navigation and appearance pane.
//  Features tabbed interface with theme customization.
//

import AppKit

/// Settings pane tabs
enum SettingsPane: String, CaseIterable {
    case general = "General"
    case appearance = "Appearance"
    case about = "About"

    var icon: String {
        switch self {
        case .general:
            return "slider.horizontal.3"
        case .appearance:
            return "paintbrush"
        case .about:
            return "info.circle"
        }
    }
}

/// Modern settings window with sidebar
class ModernSettingsWindow: NSWindow {

    // MARK: - Properties

    private weak var mover: NotificationMover?
    private var currentPane: SettingsPane = .general

    // Sidebar
    private let sidebarContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        return view
    }()

    private let sidebarScrollView = NSScrollView()
    private var sidebarButtons: [NSButton] = []

    // Content area
    private let contentPaneView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        return view
    }()

    private var currentPaneView: NSView?

    // MARK: - Initialization

    init(mover: NotificationMover) {
        self.mover = mover

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupSidebar()
        setupContentView()
        switchToPane(.general)
        setupAccessibility()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupWindow() {
        title = "Settings"
        titlebarAppearsTransparent = false
        isMovableByWindowBackground = false

        // Enable full-size content with title bar
        standardWindowButton(.closeButton)?.isHidden = false
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        minSize = NSSize(width: 600, height: 450)

        AccessibilityManager.shared.configureWindow(self, title: "Settings")
    }

    private func setupSidebar() {
        // Sidebar container
        sidebarContainer.wantsLayer = true
        sidebarContainer.layer?.backgroundColor = Colors.controlBackgroundColor.cgColor

        let sidebarWidth: CGFloat = 200
        sidebarContainer.translatesAutoresizingMaskIntoConstraints = false
        self.contentView?.addSubview(sidebarContainer)

        NSLayoutConstraint.activate([
            sidebarContainer.leadingAnchor.constraint(equalTo: self.contentView!.leadingAnchor),
            sidebarContainer.topAnchor.constraint(equalTo: self.contentView!.topAnchor),
            sidebarContainer.bottomAnchor.constraint(equalTo: self.contentView!.bottomAnchor),
            sidebarContainer.widthAnchor.constraint(equalToConstant: sidebarWidth)
        ])

        // Header
        let headerLabel = NSTextField(labelWithString: "Settings")
        headerLabel.font = Typography.headline
        headerLabel.textColor = Colors.label
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        sidebarContainer.addSubview(headerLabel)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: sidebarContainer.topAnchor, constant: Spacing.pt20),
            headerLabel.leadingAnchor.constraint(equalTo: sidebarContainer.leadingAnchor, constant: Spacing.pt16),
            headerLabel.trailingAnchor.constraint(equalTo: sidebarContainer.trailingAnchor, constant: -Spacing.pt16)
        ])

        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        sidebarContainer.addSubview(separator)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: Spacing.pt12),
            separator.leadingAnchor.constraint(equalTo: sidebarContainer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: sidebarContainer.trailingAnchor)
        ])

        // Scroll view for buttons
        sidebarScrollView.hasVerticalScroller = true
        sidebarScrollView.hasHorizontalScroller = false
        sidebarScrollView.autohidesScrollers = true
        sidebarScrollView.borderType = .noBorder
        sidebarScrollView.drawsBackground = false
        sidebarScrollView.translatesAutoresizingMaskIntoConstraints = false
        sidebarContainer.addSubview(sidebarScrollView)

        let sidebarDocumentView = NSView()
        sidebarDocumentView.translatesAutoresizingMaskIntoConstraints = false
        sidebarScrollView.documentView = sidebarDocumentView

        NSLayoutConstraint.activate([
            sidebarScrollView.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: Spacing.pt8),
            sidebarScrollView.leadingAnchor.constraint(equalTo: sidebarContainer.leadingAnchor),
            sidebarScrollView.trailingAnchor.constraint(equalTo: sidebarContainer.trailingAnchor),
            sidebarScrollView.bottomAnchor.constraint(equalTo: sidebarContainer.bottomAnchor, constant: -1)
        ])

        // Create sidebar buttons
        var yPos: CGFloat = 0
        for pane in SettingsPane.allCases {
            let button = createSidebarButton(for: pane)
            button.translatesAutoresizingMaskIntoConstraints = false
            sidebarDocumentView.addSubview(button)
            sidebarButtons.append(button)

            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: sidebarDocumentView.topAnchor, constant: yPos),
                button.leadingAnchor.constraint(equalTo: sidebarDocumentView.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: sidebarDocumentView.trailingAnchor),
                button.heightAnchor.constraint(equalToConstant: 36)
            ])

            yPos += 36
        }

        sidebarDocumentView.frame = NSRect(x: 0, y: 0, width: sidebarWidth, height: yPos)
    }

    private func createSidebarButton(for pane: SettingsPane) -> NSButton {
        let button = NSButton()
        button.title = pane.rawValue
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.imagePosition = .imageLeading
        button.alignment = .left
        button.font = Typography.body

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.image = NSImage(systemSymbolName: pane.icon, accessibilityDescription: pane.rawValue)?
            .withSymbolConfiguration(config)

        button.target = self
        button.action = #selector(sidebarButtonTapped(_:))

        // Store pane identifier
        button.identifier = NSUserInterfaceItemIdentifier(pane.rawValue)

        // Style
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        button.layer?.backgroundColor = .clear

        // Hover tracking
        let trackingArea = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp],
            owner: button,
            userInfo: nil
        )
        button.addTrackingArea(trackingArea)

        return button
    }

    private func setupContentView() {
        contentPaneView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView?.addSubview(contentPaneView)

        NSLayoutConstraint.activate([
            contentPaneView.topAnchor.constraint(equalTo: self.contentView!.topAnchor),
            contentPaneView.leadingAnchor.constraint(equalTo: sidebarContainer.trailingAnchor),
            contentPaneView.trailingAnchor.constraint(equalTo: self.contentView!.trailingAnchor),
            contentPaneView.bottomAnchor.constraint(equalTo: self.contentView!.bottomAnchor)
        ])

        // Background
        contentPaneView.layer?.backgroundColor = Colors.windowBackgroundColor.cgColor
    }

    // MARK: - Pane Switching

    @objc private func sidebarButtonTapped(_ sender: NSButton) {
        guard let paneName = sender.identifier?.rawValue,
              let pane = SettingsPane.allCases.first(where: { $0.rawValue == paneName }) else {
            return
        }

        switchToPane(pane)
    }

    private func switchToPane(_ pane: SettingsPane) {
        currentPane = pane

        // Update sidebar button appearance
        for button in sidebarButtons {
            let isSelected = button.identifier?.rawValue == pane.rawValue

            if isSelected {
                button.layer?.backgroundColor = Colors.accent.withAlphaComponent(0.1).cgColor
                button.contentTintColor = Colors.accent
            } else {
                button.layer?.backgroundColor = .clear
                button.contentTintColor = Colors.label
            }
        }

        // Remove current pane
        currentPaneView?.removeFromSuperview()

        // Create and add new pane
        switch pane {
        case .general:
            currentPaneView = createGeneralPane()
        case .appearance:
            currentPaneView = createAppearancePane()
        case .about:
            currentPaneView = createAboutPane()
        }

        if let paneView = currentPaneView {
            paneView.translatesAutoresizingMaskIntoConstraints = false
            contentPaneView.addSubview(paneView)

            NSLayoutConstraint.activate([
                paneView.topAnchor.constraint(equalTo: contentPaneView.topAnchor, constant: Spacing.pt20),
                paneView.leadingAnchor.constraint(equalTo: contentPaneView.leadingAnchor, constant: Spacing.pt20),
                paneView.trailingAnchor.constraint(equalTo: contentPaneView.trailingAnchor, constant: -Spacing.pt20),
                paneView.bottomAnchor.constraint(equalTo: contentPaneView.bottomAnchor, constant: -Spacing.pt20)
            ])
        }

        // Animate transition
        if let paneView = currentPaneView {
            paneView.alphaValue = 0
            AnimationHelper.fade(paneView, to: 1.0)
        }
    }

    // MARK: - Pane Creation

    private func createGeneralPane() -> NSView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: documentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 460)
        ])

        var yPos: CGFloat = 440

        // Add sections
        yPos = addPositionSection(to: container, at: yPos) - Spacing.pt24
        yPos = addTestSection(to: container, at: yPos) - Spacing.pt24
        yPos = addPreferencesSection(to: container, at: yPos) - Spacing.pt24
        _ = addLaunchSection(to: container, at: yPos)

        return scrollView
    }

    private func createAppearancePane() -> NSView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: documentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 460)
        ])

        var yPos: CGFloat = 450

        yPos = addThemeSection(to: container, at: yPos) - Spacing.pt24
        _ = addAccentColorSection(to: container, at: yPos)

        return scrollView
    }

    private func createAboutPane() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = Colors.contentBackground.cgColor
        container.layer?.cornerRadius = Layout.cardCornerRadius

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // Icon
        let iconView = NSImageView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))
        if let icon = NSImage(named: "icon") {
            iconView.image = icon
        }
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)

        // Version label
        let versionLabel = NSTextField(labelWithString: "Notimanager v\(version)")
        versionLabel.font = Typography.title2
        versionLabel.alignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(versionLabel)

        // Build label
        let buildLabel = NSTextField(labelWithString: "Build \(build)")
        buildLabel.font = Typography.body
        buildLabel.textColor = Colors.secondaryLabel
        buildLabel.alignment = .center
        buildLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(buildLabel)

        // Credits
        let creditsLabel = NSTextField(labelWithString: "Made with ❤️ by Wade Grimridge")
        creditsLabel.font = Typography.caption1
        creditsLabel.textColor = Colors.tertiaryLabel
        creditsLabel.alignment = .center
        creditsLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(creditsLabel)

        // Support buttons
        let kofiButton = NSButton(title: "Support on Ko-fi", target: self, action: #selector(openKofi))
        kofiButton.bezelStyle = .rounded
        kofiButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(kofiButton)

        let coffeeButton = NSButton(title: "Buy Me a Coffee", target: self, action: #selector(openBuyMeACoffee))
        coffeeButton.bezelStyle = .rounded
        coffeeButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(coffeeButton)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: Spacing.pt40),

            versionLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            versionLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: Spacing.pt16),

            buildLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            buildLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: Spacing.pt4),

            creditsLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            creditsLabel.topAnchor.constraint(equalTo: buildLabel.bottomAnchor, constant: Spacing.pt32),

            kofiButton.centerXAnchor.constraint(equalTo: container.centerXAnchor, constant: -75),
            kofiButton.topAnchor.constraint(equalTo: creditsLabel.bottomAnchor, constant: Spacing.pt32),
            kofiButton.widthAnchor.constraint(equalToConstant: 120),

            coffeeButton.centerXAnchor.constraint(equalTo: container.centerXAnchor, constant: 75),
            coffeeButton.topAnchor.constraint(equalTo: creditsLabel.bottomAnchor, constant: Spacing.pt32),
            coffeeButton.widthAnchor.constraint(equalToConstant: 140)
        ])

        return container
    }

    // MARK: - Section Builders

    private func addPositionSection(to container: NSView, at yPos: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 300
        let card = LiquidGlassCard.settingsCard(
            frame: NSRect(
                x: Spacing.pt16,
                y: yPos - cardHeight,
                width: 428,
                height: cardHeight
            )
        )

        let headerLabel = NSTextField(labelWithString: "Notification Position")
        headerLabel.font = Typography.headline
        headerLabel.frame = NSRect(x: Spacing.pt16, y: cardHeight - Spacing.pt32, width: 396, height: 24)
        card.addSubview(headerLabel)

        let positionGrid = createPositionGrid()
        let gridWidth = (Layout.gridSize * 3) + (Layout.gridSpacing * 2)
        positionGrid.frame = NSRect(
            x: (card.frame.width - gridWidth) / 2,
            y: Spacing.pt16,
            width: gridWidth,
            height: gridWidth
        )
        card.addSubview(positionGrid)

        container.addSubview(card)
        AccessibilityManager.shared.configureSection(card, title: "Notification Position")

        return yPos - cardHeight
    }

    private func addTestSection(to container: NSView, at yPos: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 150
        let card = LiquidGlassCard.settingsCard(
            frame: NSRect(x: Spacing.pt16, y: yPos - cardHeight, width: 428, height: cardHeight)
        )

        let headerLabel = NSTextField(labelWithString: "Test Notification")
        headerLabel.font = Typography.headline
        headerLabel.frame = NSRect(x: Spacing.pt16, y: cardHeight - Spacing.pt32, width: 396, height: 24)
        card.addSubview(headerLabel)

        let testButton = NSButton(
            frame: NSRect(x: Spacing.pt16, y: cardHeight - 85, width: 130, height: 30)
        )
        testButton.title = "Send Test"
        testButton.bezelStyle = .rounded
        testButton.target = self
        testButton.action = #selector(sendTest)
        card.addSubview(testButton)

        let helperLabel = NSTextField(
            wrappingLabelWithString: "For best results, test with real notifications from Calendar, Mail, or Messages"
        )
        helperLabel.font = Typography.caption1
        helperLabel.textColor = Colors.secondaryLabel
        helperLabel.frame = NSRect(x: Spacing.pt16, y: Spacing.pt16, width: 396, height: 40)
        card.addSubview(helperLabel)

        container.addSubview(card)

        return yPos - cardHeight
    }

    private func addPreferencesSection(to container: NSView, at yPos: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 140
        let card = LiquidGlassCard.settingsCard(
            frame: NSRect(x: Spacing.pt16, y: yPos - cardHeight, width: 428, height: cardHeight)
        )

        let headerLabel = NSTextField(labelWithString: "Preferences")
        headerLabel.font = Typography.headline
        headerLabel.frame = NSRect(x: Spacing.pt16, y: cardHeight - Spacing.pt32, width: 396, height: 24)
        card.addSubview(headerLabel)

        let enabledCheckbox = NSButton(
            checkboxWithTitle: "Enable notification positioning",
            target: self,
            action: #selector(enabledToggled(_:))
        )
        enabledCheckbox.state = mover?.internalIsEnabled ?? true ? .on : .off
        enabledCheckbox.frame = NSRect(x: Spacing.pt16, y: cardHeight - 65, width: 396, height: 20)
        card.addSubview(enabledCheckbox)

        let debugCheckbox = NSButton(
            checkboxWithTitle: "Debug mode",
            target: self,
            action: #selector(debugToggled(_:))
        )
        debugCheckbox.state = mover?.internalDebugMode ?? false ? .on : .off
        debugCheckbox.frame = NSRect(x: Spacing.pt16, y: cardHeight - 40, width: 396, height: 20)
        card.addSubview(debugCheckbox)

        container.addSubview(card)

        return yPos - cardHeight
    }

    private func addLaunchSection(to container: NSView, at yPos: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 80
        let card = LiquidGlassCard.settingsCard(
            frame: NSRect(x: Spacing.pt16, y: yPos - cardHeight, width: 428, height: cardHeight)
        )

        let headerLabel = NSTextField(labelWithString: "Startup")
        headerLabel.font = Typography.headline
        headerLabel.frame = NSRect(x: Spacing.pt16, y: cardHeight - Spacing.pt32, width: 396, height: 24)
        card.addSubview(headerLabel)

        let launchCheckbox = NSButton(
            checkboxWithTitle: "Launch at login",
            target: self,
            action: #selector(launchToggled(_:))
        )
        launchCheckbox.state = FileManager.default.fileExists(
            atPath: mover?.internalLaunchAgentPlistPath ?? ""
        ) ? .on : .off
        launchCheckbox.frame = NSRect(x: Spacing.pt16, y: cardHeight - Spacing.pt32, width: 396, height: 20)
        card.addSubview(launchCheckbox)

        container.addSubview(card)

        return yPos - cardHeight
    }

    private func addThemeSection(to container: NSView, at yPos: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 180
        let card = LiquidGlassCard.settingsCard(
            frame: NSRect(x: Spacing.pt16, y: yPos - cardHeight, width: 428, height: cardHeight)
        )

        let headerLabel = NSTextField(labelWithString: "App Theme")
        headerLabel.font = Typography.headline
        headerLabel.frame = NSRect(x: Spacing.pt16, y: cardHeight - Spacing.pt32, width: 396, height: 24)
        card.addSubview(headerLabel)

        let descriptionLabel = NSTextField(
            wrappingLabelWithString: "Choose how Notimanager should appear. You can match your system settings or override with a specific theme."
        )
        descriptionLabel.font = Typography.caption1
        descriptionLabel.textColor = Colors.secondaryLabel
        descriptionLabel.frame = NSRect(x: Spacing.pt16, y: cardHeight - 70, width: 396, height: 34)
        card.addSubview(descriptionLabel)

        let themePicker = ThemePicker(
            currentTheme: ThemeManager.shared.currentTheme,
            onThemeChange: { [weak self] theme in
                self?.handleThemeChange(theme)
            }
        )
        themePicker.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(themePicker)

        NSLayoutConstraint.activate([
            themePicker.topAnchor.constraint(equalTo: card.topAnchor, constant: cardHeight - 140),
            themePicker.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            themePicker.widthAnchor.constraint(equalToConstant: 396),
            themePicker.heightAnchor.constraint(equalToConstant: 100)
        ])

        container.addSubview(card)

        return yPos - cardHeight
    }

    private func addAccentColorSection(to container: NSView, at yPos: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 120
        let card = LiquidGlassCard.settingsCard(
            frame: NSRect(x: Spacing.pt16, y: yPos - cardHeight, width: 428, height: cardHeight)
        )

        let headerLabel = NSTextField(labelWithString: "Accent Color")
        headerLabel.font = Typography.headline
        headerLabel.frame = NSRect(x: Spacing.pt16, y: cardHeight - Spacing.pt32, width: 396, height: 24)
        card.addSubview(headerLabel)

        let infoLabel = NSTextField(
            wrappingLabelWithString: "The accent color is controlled by your macOS system settings. Go to System Settings › Appearance to customize it."
        )
        infoLabel.font = Typography.caption1
        infoLabel.textColor = Colors.secondaryLabel
        infoLabel.frame = NSRect(x: Spacing.pt16, y: Spacing.pt16, width: 396, height: 50)
        card.addSubview(infoLabel)

        container.addSubview(card)

        return yPos - cardHeight
    }

    // MARK: - Position Grid

    private func createPositionGrid() -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true

        for (index, position) in NotificationPosition.allCases.enumerated() {
            let row = 2 - (index / 3)
            let col = index % 3

            let button = createPositionButton(
                position: position,
                isSelected: position == (mover?.internalCurrentPosition ?? .topMiddle)
            )

            let x = CGFloat(col) * (Layout.gridSize + Layout.gridSpacing)
            let y = CGFloat(row) * (Layout.gridSize + Layout.gridSpacing)
            button.frame = NSRect(x: x, y: y, width: Layout.gridSize, height: Layout.gridSize)

            containerView.addSubview(button)
        }

        let totalWidth = (Layout.gridSize * 3) + (Layout.gridSpacing * 2)
        containerView.frame = NSRect(x: 0, y: 0, width: totalWidth, height: totalWidth)

        return containerView
    }

    private func createPositionButton(position: NotificationPosition, isSelected: Bool) -> NSView {
        let containerView = NSVisualEffectView()
        containerView.wantsLayer = true
        containerView.material = isSelected ? .selection : .underWindowBackground
        containerView.blendingMode = .withinWindow
        containerView.state = .active

        let cornerRadius = Layout.gridSize / 1.618 / 1.2
        containerView.layer?.cornerRadius = cornerRadius
        containerView.layer?.borderWidth = isSelected ? Border.focus : Border.thin
        containerView.layer?.borderColor = isSelected
            ? Colors.accent.cgColor
            : Colors.separator.withAlphaComponent(0.4).cgColor

        if isSelected {
            containerView.shadow = Shadow.elevated()
        } else {
            containerView.shadow = Shadow.card()
        }

        let button = NSButton(frame: NSRect(x: 0, y: 0, width: Layout.gridSize, height: Layout.gridSize))
        button.title = ""
        button.bezelStyle = .shadowlessSquare
        button.isBordered = false
        button.target = self
        button.action = #selector(positionButtonTapped(_:))
        button.wantsLayer = true
        button.layer?.backgroundColor = .clear
        button.toolTip = position.displayName

        // Add icon
        let iconSize: CGFloat = 32
        let iconPadding = (Layout.gridSize - iconSize) / 2
        let iconView = NSImageView(frame: NSRect(x: iconPadding, y: iconPadding, width: iconSize, height: iconSize))
        let config = NSImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        iconView.image = NSImage(
            systemSymbolName: position.symbolName,
            accessibilityDescription: position.displayName
        )?.withSymbolConfiguration(config)
        iconView.contentTintColor = isSelected ? Colors.accent : Colors.tertiaryLabel
        iconView.imageScaling = .scaleProportionallyDown
        button.addSubview(iconView)

        containerView.addSubview(button)

        // Store position
        objc_setAssociatedObject(button, "position", position.rawValue as NSString, .OBJC_ASSOCIATION_RETAIN)

        return containerView
    }

    // MARK: - Actions

    @objc private func positionButtonTapped(_ sender: NSButton) {
        guard let positionString = objc_getAssociatedObject(sender, "position") as? String,
              let position = NotificationPosition(rawValue: positionString) else {
            return
        }

        mover?.updatePosition(to: position)

        // Refresh the position grid
        if let currentPaneView = currentPaneView,
           let scrollView = currentPaneView as? NSScrollView,
           let documentView = scrollView.documentView,
           let container = documentView.subviews.first {
            // Remove and recreate position section
            container.subviews.first?.removeFromSuperview()
        }

        AccessibilityManager.shared.announceSettingChange(
            setting: "Notification position",
            value: position.displayName
        )
    }

    @objc private func sendTest() {
        mover?.internalSendTestNotification()
    }

    @objc private func enabledToggled(_ sender: NSButton) {
        let isEnabled = sender.state == .on
        mover?.internalSetIsEnabled(isEnabled)
        AccessibilityManager.shared.announceSettingChange(
            setting: "Notification positioning",
            value: isEnabled ? "enabled" : "disabled"
        )
    }

    @objc private func debugToggled(_ sender: NSButton) {
        let isDebug = sender.state == .on
        mover?.internalSetDebugMode(isDebug)
        AccessibilityManager.shared.announceSettingChange(
            setting: "Debug mode",
            value: isDebug ? "enabled" : "disabled"
        )
    }

    @objc private func launchToggled(_ sender: NSButton) {
        let shouldLaunch = sender.state == .on
        mover?.internalSetLaunchAtLogin(shouldLaunch)
        AccessibilityManager.shared.announceSettingChange(
            setting: "Launch at login",
            value: shouldLaunch ? "enabled" : "disabled"
        )
    }

    private func handleThemeChange(_ theme: AppTheme) {
        ThemeManager.shared.setTheme(theme)
    }

    @objc private func openKofi() {
        if let url = URL(string: "https://ko-fi.com/wadegrimridge") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openBuyMeACoffee() {
        if let url = URL(string: "https://www.buymeacoffee.com/wadegrimridge") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Accessibility

    private func setupAccessibility() {
        self.contentView?.setAccessibilityLabel("Settings window")
        self.contentView?.setAccessibilityRole(.group)
    }
}

// MARK: - NotificationPosition Extension

extension NotificationPosition {
    var symbolName: String {
        switch self {
        case .topLeft:
            return "arrow.up.left"
        case .topMiddle:
            return "arrow.up"
        case .topRight:
            return "arrow.up.right"
        case .middleLeft:
            return "arrow.left"
        case .deadCenter:
            return "circle.fill"
        case .middleRight:
            return "arrow.right"
        case .bottomLeft:
            return "arrow.down.left"
        case .bottomMiddle:
            return "arrow.down"
        case .bottomRight:
            return "arrow.down.right"
        }
    }
}
