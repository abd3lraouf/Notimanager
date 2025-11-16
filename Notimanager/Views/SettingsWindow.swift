//
//  SettingsWindow.swift
//  Notimanager
//
//  Modern settings window using the new design system.
//  Features Liquid Glass effects, full accessibility, and smooth animations.
//

import AppKit

/// Modern settings window with Liquid Glass design and full accessibility
class SettingsWindow: NSWindow {

    // MARK: - Properties

    private let scrollView = NSScrollView()
    private let documentView = NSView()
    private var positionGridView: NSView?

    // Reference to NotificationMover for callbacks
    private weak var mover: NotificationMover?

    // MARK: - Initialization

    init(mover: NotificationMover) {
        self.mover = mover

        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: Layout.settingsWindowWidth,
                height: Layout.settingsViewportHeight
            ),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupScrollView()
        setupContent()
        setupAccessibility()
        setupAppearanceObservation()
    }

    // MARK: - Setup

    private func setupWindow() {
        title = "Notimanager"
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        level = .floating
        minSize = NSSize(width: Layout.settingsWindowWidth, height: 500)

        // Configure accessibility
        AccessibilityManager.shared.configureWindow(self, title: "Settings")
    }

    private func setupScrollView() {
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Configure accessibility
        AccessibilityManager.shared.configureScrollView(scrollView)

        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        // Replace the content view
        contentView?.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView!.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor)
        ])
    }

    private func setupContent() {
        // Set document view frame
        documentView.frame = NSRect(
            x: 0,
            y: 0,
            width: Layout.settingsWindowWidth,
            height: Layout.settingsContentHeight
        )

        var yPos = Layout.settingsContentHeight - Spacing.pt48

        // Create sections
        yPos = addPositionSection(at: yPos) - Spacing.pt24
        yPos = addTestSection(at: yPos) - Spacing.pt24
        yPos = addPreferencesSection(at: yPos) - Spacing.pt24
        _ = addAboutSection(at: yPos)

        // Setup constraints
        NSLayoutConstraint.activate([
            documentView.widthAnchor.constraint(equalToConstant: Layout.settingsWindowWidth),
            documentView.heightAnchor.constraint(equalToConstant: Layout.settingsContentHeight)
        ])
    }

    private func setupAccessibility() {
        // Set up accessibility for the settings window
        documentView.setAccessibilityLabel("Settings content")
        documentView.setAccessibilityRole(.group)
    }

    private func setupAppearanceObservation() {
        // Observe appearance changes to update UI
        NotificationCenter.default.addObserver(
            forName: AppearanceManager.appearanceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateForAppearanceChanges()
        }
    }

    // MARK: - Section Builders

    private func addPositionSection(at yPos: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 300
        let card = LiquidGlassCard.settingsCard(
            frame: NSRect(
                x: Spacing.pt24,
                y: yPos - cardHeight,
                width: Layout.settingsWindowWidth - (Spacing.pt24 * 2),
                height: cardHeight
            )
        )

        // Section header
        let headerLabel = createHeaderLabel(
            "Notification Position",
            frame: NSRect(x: Spacing.pt16, y: cardHeight - Spacing.pt32, width: card.frame.width - (Spacing.pt16 * 2), height: Spacing.pt24)
        )
        card.addSubview(headerLabel)

        // Position grid
        let positionGrid = createPositionGrid(selection: mover?.internalCurrentPosition ?? .topMiddle) { [weak self] newPosition in
            self?.positionChanged(to: newPosition)
        }

        let gridWidth = (Layout.gridSize * 3) + (Layout.gridSpacing * 2)
        let gridHeight = (Layout.gridSize * 3) + (Layout.gridSpacing * 2)
        let gridX = (card.frame.width - gridWidth) / 2

        positionGrid.frame = NSRect(x: gridX, y: Spacing.pt16, width: gridWidth, height: gridHeight)
        card.addSubview(positionGrid)

        // Store reference for updates
        positionGridView = positionGrid
        documentView.addSubview(card)

        AccessibilityManager.shared.configureSection(card, title: "Notification Position")

        return yPos - cardHeight
    }

    private func addTestSection(at yPos: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 170
        let card = LiquidGlassCard.settingsCard(
            frame: NSRect(
                x: Spacing.pt24,
                y: yPos - cardHeight,
                width: Layout.settingsWindowWidth - (Spacing.pt24 * 2),
                height: cardHeight
            )
        )

        var innerY = cardHeight - Spacing.pt32

        // Test Notification header
        let testLabel = createHeaderLabel(
            "Test Notification",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: card.frame.width - (Spacing.pt16 * 2), height: Spacing.pt24)
        )
        card.addSubview(testLabel)
        innerY -= Spacing.pt36

        // Test button
        let testButton = createButton(
            "Send Test",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: 130, height: Layout.regularButtonHeight)
        )
        testButton.action = #selector(NotificationMover.internalSendTestNotification)
        testButton.target = mover
        card.addSubview(testButton)

        // Status label
        let statusLabel = NSTextField(labelWithString: "Not tested yet")
        statusLabel.frame = NSRect(x: Spacing.pt16 + 140, y: innerY + Spacing.pt8, width: card.frame.width - Spacing.pt16 - 150, height: Spacing.pt16)
        statusLabel.font = Typography.caption1
        statusLabel.textColor = Colors.secondaryLabel
        card.addSubview(statusLabel)

        innerY -= Spacing.pt28

        // Helper text
        let helperText = createLabel(
            "For best results, test with real notifications from Calendar, Mail, or Messages",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: card.frame.width - (Spacing.pt16 * 2), height: Spacing.pt32)
        )
        helperText.font = Typography.caption2
        helperText.textColor = Colors.secondaryLabel
        helperText.lineBreakMode = .byWordWrapping
        card.addSubview(helperText)
        innerY -= Spacing.pt44

        // Separator
        let separator = NSBox(frame: NSRect(x: Spacing.pt16, y: innerY, width: card.frame.width - (Spacing.pt16 * 2), height: 1))
        separator.boxType = .separator
        separator.alphaValue = 0.25
        card.addSubview(separator)
        innerY -= Spacing.pt24

        // Accessibility section
        let isGranted = AXIsProcessTrusted()

        let permLabel = createHeaderLabel(
            "Accessibility",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: 150, height: Spacing.pt24)
        )
        card.addSubview(permLabel)

        let permStatusLabel = createLabel(
            isGranted ? "Granted" : "Required",
            frame: NSRect(x: Spacing.pt16 + 110, y: innerY + Spacing.pt2, width: 120, height: Spacing.pt16)
        )
        permStatusLabel.font = Typography.subheadline
        permStatusLabel.textColor = isGranted ? Colors.success : Colors.warning
        card.addSubview(permStatusLabel)
        innerY -= Spacing.pt32

        // Action buttons
        if isGranted {
            let clearBtn = createButton(
                "Clear",
                frame: NSRect(x: card.frame.width - Spacing.pt16 - 220, y: innerY, width: 105, height: Layout.smallButtonHeight)
            )
            clearBtn.controlSize = .small
            clearBtn.action = #selector(NotificationMover.internalSettingsResetPermission)
            clearBtn.target = mover
            card.addSubview(clearBtn)

            let restartBtn = createButton(
                "Restart App",
                frame: NSRect(x: card.frame.width - Spacing.pt16 - 105, y: innerY, width: 105, height: Layout.smallButtonHeight)
            )
            restartBtn.controlSize = .small
            restartBtn.action = #selector(NotificationMover.internalSettingsRestartApp)
            restartBtn.target = mover
            card.addSubview(restartBtn)
        } else {
            let requestBtn = createButton(
                "Open System Settings",
                frame: NSRect(x: card.frame.width - Spacing.pt16 - 170, y: innerY, width: 170, height: Layout.smallButtonHeight)
            )
            requestBtn.controlSize = .small
            requestBtn.action = #selector(NotificationMover.internalShowPermissionStatus)
            requestBtn.target = mover
            card.addSubview(requestBtn)
        }

        documentView.addSubview(card)

        AccessibilityManager.shared.configureSection(card, title: "Test and Permissions")

        return yPos - cardHeight
    }

    private func addPreferencesSection(at yPos: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 175
        let card = LiquidGlassCard.settingsCard(
            frame: NSRect(
                x: Spacing.pt24,
                y: yPos - cardHeight,
                width: Layout.settingsWindowWidth - (Spacing.pt24 * 2),
                height: cardHeight
            )
        )

        var innerY = cardHeight - Spacing.pt32

        // Preferences header
        let prefsLabel = createHeaderLabel(
            "Preferences",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: card.frame.width - (Spacing.pt16 * 2), height: Spacing.pt24)
        )
        card.addSubview(prefsLabel)
        innerY -= Spacing.pt32

        // Checkboxes
        let enabledCheckbox = createCheckbox(
            "Enable notification positioning",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: card.frame.width - (Spacing.pt16 * 2), height: Spacing.pt20)
        )
        enabledCheckbox.state = mover?.internalIsEnabled ?? true ? .on : .off
        enabledCheckbox.action = #selector(NotificationMover.internalSettingsEnabledToggled(_:))
        enabledCheckbox.target = mover
        card.addSubview(enabledCheckbox)
        innerY -= Spacing.pt32

        let launchCheckbox = createCheckbox(
            "Launch at login",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: card.frame.width - (Spacing.pt16 * 2), height: Spacing.pt20)
        )
        launchCheckbox.state = FileManager.default.fileExists(atPath: mover?.internalLaunchAgentPlistPath ?? "") ? .on : .off
        launchCheckbox.action = #selector(NotificationMover.internalSettingsLaunchToggled(_:))
        launchCheckbox.target = mover
        card.addSubview(launchCheckbox)
        innerY -= Spacing.pt32

        let debugCheckbox = createCheckbox(
            "Debug mode",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: card.frame.width - (Spacing.pt16 * 2), height: Spacing.pt20)
        )
        debugCheckbox.state = mover?.internalDebugMode ?? false ? .on : .off
        debugCheckbox.action = #selector(NotificationMover.internalSettingsDebugToggled(_:))
        debugCheckbox.target = mover
        card.addSubview(debugCheckbox)
        innerY -= Spacing.pt32

        let hideIconCheckbox = createCheckbox(
            "Hide menu bar icon",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: card.frame.width - (Spacing.pt16 * 2), height: Spacing.pt20)
        )
        hideIconCheckbox.state = mover?.internalIsMenuBarIconHidden ?? false ? .on : .off
        hideIconCheckbox.action = #selector(NotificationMover.internalSettingsHideIconToggled(_:))
        hideIconCheckbox.target = mover
        card.addSubview(hideIconCheckbox)

        documentView.addSubview(card)

        AccessibilityManager.shared.configureSection(card, title: "Preferences")

        return yPos - cardHeight
    }

    private func addAboutSection(at yPos: CGFloat) -> CGFloat {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let cardHeight: CGFloat = 95
        let card = LiquidGlassCard.settingsCard(
            frame: NSRect(
                x: Spacing.pt24,
                y: yPos - cardHeight,
                width: Layout.settingsWindowWidth - (Spacing.pt24 * 2),
                height: cardHeight
            )
        )

        var innerY = cardHeight - Spacing.pt32

        // Version
        let versionLabel = createHeaderLabel(
            "Notimanager v\(version)",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: card.frame.width - (Spacing.pt16 * 2), height: Spacing.pt24)
        )
        card.addSubview(versionLabel)
        innerY -= Spacing.pt24

        // Credits
        let madeByLabel = createLabel(
            "Made with ❤️ by Wade Grimridge",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: card.frame.width - (Spacing.pt16 * 2), height: Spacing.pt16)
        )
        madeByLabel.font = Typography.caption1
        madeByLabel.textColor = Colors.tertiaryLabel
        card.addSubview(madeByLabel)
        innerY -= Spacing.pt32

        // Support buttons
        let kofiBtn = createButton(
            "Support on Ko-fi",
            frame: NSRect(x: Spacing.pt16, y: innerY, width: 145, height: Layout.smallButtonHeight)
        )
        kofiBtn.controlSize = .small
        kofiBtn.action = #selector(NotificationMover.internalOpenKofi)
        kofiBtn.target = mover
        card.addSubview(kofiBtn)

        let coffeeBtn = createButton(
            "Buy Me a Coffee",
            frame: NSRect(x: Spacing.pt16 + 155, y: innerY, width: 155, height: Layout.smallButtonHeight)
        )
        coffeeBtn.controlSize = .small
        coffeeBtn.action = #selector(NotificationMover.internalOpenBuyMeACoffee)
        coffeeBtn.target = mover
        card.addSubview(coffeeBtn)

        documentView.addSubview(card)

        AccessibilityManager.shared.configureSection(card, title: "About")

        return yPos - cardHeight
    }

    // MARK: - Helper Methods

    private func createPositionGrid(selection: NotificationPosition, onChange: @escaping (NotificationPosition) -> Void) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true

        let positions = NotificationPosition.allCases
        var buttons: [NSView] = []

        for (index, position) in positions.enumerated() {
            let row = 2 - (index / 3)
            let col = index % 3

            let button = createPositionButton(
                position: position,
                isSelected: position == selection,
                action: onChange
            )

            let x = CGFloat(col) * (Layout.gridSize + Layout.gridSpacing)
            let y = CGFloat(row) * (Layout.gridSize + Layout.gridSpacing)
            button.frame = NSRect(x: x, y: y, width: Layout.gridSize, height: Layout.gridSize)

            buttons.append(button)
            containerView.addSubview(button)
        }

        let totalWidth = (Layout.gridSize * 3) + (Layout.gridSpacing * 2)
        let totalHeight = totalWidth
        containerView.frame = NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight)

        return containerView
    }

    private func createPositionButton(
        position: NotificationPosition,
        isSelected: Bool,
        action: @escaping (NotificationPosition) -> Void
    ) -> NSView {
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
        button.tag = NotificationPosition.allCases.firstIndex(of: position) ?? 0
        button.target = self
        button.action = #selector(handlePositionButtonTap(_:))
        button.wantsLayer = true
        button.layer?.backgroundColor = .clear
        button.toolTip = position.displayName

        // Add icon
        if let icon = getPositionIcon(for: position) {
            let iconSize: CGFloat = 32
            let iconPadding = (Layout.gridSize - iconSize) / 2
            let iconView = NSImageView(frame: NSRect(x: iconPadding, y: iconPadding, width: iconSize, height: iconSize))
            iconView.image = icon
            iconView.contentTintColor = isSelected ? Colors.accent : Colors.tertiaryLabel
            iconView.imageScaling = .scaleProportionallyDown
            button.addSubview(iconView)
        }

        containerView.addSubview(button)

        // Store position in button for action handler
        objc_setAssociatedObject(button, "position", position.rawValue as NSString, .OBJC_ASSOCIATION_RETAIN)

        return containerView
    }

    @objc private func handlePositionButtonTap(_ sender: NSButton) {
        guard let positionString = objc_getAssociatedObject(sender, "position") as? String,
              let position = NotificationPosition(rawValue: positionString) else {
            return
        }

        positionChanged(to: position)

        // Update all buttons in the grid
        if let grid = positionGridView,
           let card = grid.superview {
            for subview in grid.subviews {
                if let effectView = subview as? NSVisualEffectView,
                   let button = effectView.subviews.first as? NSButton {
                    let buttonPositionString = objc_getAssociatedObject(button, "position") as? String
                    let isSelected = buttonPositionString == position.rawValue

                    effectView.material = isSelected ? .selection : .underWindowBackground
                    effectView.layer?.borderWidth = isSelected ? Border.focus : Border.thin
                    effectView.layer?.borderColor = isSelected
                        ? Colors.accent.cgColor
                        : Colors.separator.withAlphaComponent(0.4).cgColor

                    if isSelected {
                        effectView.shadow = Shadow.elevated()
                    } else {
                        effectView.shadow = Shadow.card()
                    }

                    if let iconView = button.subviews.first as? NSImageView {
                        iconView.contentTintColor = isSelected ? Colors.accent : Colors.tertiaryLabel
                    }
                }
            }
        }
    }

    private func getPositionIcon(for position: NotificationPosition) -> NSImage? {
        let symbolName: String
        switch position {
        case .topLeft:
            symbolName = "arrow.up.left"
        case .topMiddle:
            symbolName = "arrow.up"
        case .topRight:
            symbolName = "arrow.up.right"
        case .middleLeft:
            symbolName = "arrow.left"
        case .deadCenter:
            symbolName = "circle.fill"
        case .middleRight:
            symbolName = "arrow.right"
        case .bottomLeft:
            symbolName = "arrow.down.left"
        case .bottomMiddle:
            symbolName = "arrow.down"
        case .bottomRight:
            symbolName = "arrow.down.right"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        return NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: position.displayName
        )?.withSymbolConfiguration(config)
    }

    private func createHeaderLabel(_ text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.frame = frame
        label.font = Typography.headline
        label.textColor = Colors.label
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        return label
    }

    private func createLabel(_ text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.frame = frame
        label.font = Typography.body
        label.textColor = Colors.label
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        return label
    }

    private func createButton(_ title: String, frame: NSRect) -> NSButton {
        let button = NSButton(frame: frame)
        button.title = title
        button.bezelStyle = .rounded
        button.font = Typography.body
        return button
    }

    private func createCheckbox(_ title: String, frame: NSRect) -> NSButton {
        let checkbox = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        checkbox.frame = frame
        checkbox.font = Typography.body
        return checkbox
    }

    // MARK: - Actions

    private func positionChanged(to newPosition: NotificationPosition) {
        mover?.updatePosition(to: newPosition)
        AccessibilityManager.shared.announceSettingChange(
            setting: "Notification position",
            value: newPosition.displayName
        )
    }

    // MARK: - Appearance Updates

    private func updateForAppearanceChanges() {
        // Update cards for appearance changes
        for subview in documentView.subviews {
            if let card = subview as? LiquidGlassCard {
                card.updateForHighContrast(AppearanceManager.shared.isHighContrast)
                card.updateForReduceTransparency(AppearanceManager.shared.isReduceTransparency)
            }
        }
    }

    // MARK: - Public Methods

    /// Updates the position grid selection
    func updatePositionSelection(_ position: NotificationPosition) {
        guard let grid = positionGridView else { return }

        for subview in grid.subviews {
            if let effectView = subview as? NSVisualEffectView,
               let button = effectView.subviews.first as? NSButton {
                let buttonPositionString = objc_getAssociatedObject(button, "position") as? String
                let isSelected = buttonPositionString == position.rawValue

                effectView.material = isSelected ? .selection : .underWindowBackground
                effectView.layer?.borderWidth = isSelected ? Border.focus : Border.thin
                effectView.layer?.borderColor = isSelected
                    ? Colors.accent.cgColor
                    : Colors.separator.withAlphaComponent(0.4).cgColor

                if isSelected {
                    effectView.shadow = Shadow.elevated()
                } else {
                    effectView.shadow = Shadow.card()
                }

                if let iconView = button.subviews.first as? NSImageView {
                    iconView.contentTintColor = isSelected ? Colors.accent : Colors.tertiaryLabel
                }
            }
        }
    }
}
