//
//  GeneralSettingsViewController.swift
//  Notimanager
//
//  General settings pane following Apple HIG standards with Liquid Glass design
//  Improved UX with proper visual hierarchy, accessibility, and depth
//

import Cocoa
import Settings
import ServiceManagement
import SwiftUI
import LaunchAtLogin

final class GeneralSettingsViewController: NSViewController, SettingsPane {

    // MARK: - SettingsPane Conformance

    let paneIdentifier = Settings.PaneIdentifier.general
    let paneTitle = NSLocalizedString("General", comment: "Settings pane title")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General")!
        } else {
            return NSImage(named: NSImage.actionTemplateName)!
        }
    }

    // MARK: - UI Components

    // System Section
    private var scrollView: NSScrollView!
    private var contentView: NSView!
    private var systemSectionView: NSView!
    private var launchAtLoginContainerView: NSView!
    private var enabledCheckboxRow: LiquidGlassCheckboxRow!
    private var hideMenuBarIconCheckboxRow: LiquidGlassCheckboxRow!

    // Advanced Section
    private var advancedSectionView: NSView!
    private var debugModeCheckboxRow: LiquidGlassCheckboxRow!

    // Tools Section
    private var toolsSectionView: NSView!
    private var buttonStackView: NSStackView!

    // Quit Section
    private var quitSectionView: NSView!
    private var quitButton: NSButton!

    // MARK: - Properties

    private let configurationManager: ConfigurationManager
    private let logger: LoggingService

    // MARK: - Lifecycle

    init(
        configurationManager: ConfigurationManager = .shared,
        logger: LoggingService = .shared
    ) {
        self.configurationManager = configurationManager
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // Create scroll view for better handling of smaller windows
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Create content view
        contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView

        // Set the view as the scroll view
        self.view = scrollView

        setupUI()
    }

    private func setupUI() {
        // === System Section ===
        systemSectionView = createSystemSection()
        contentView.addSubview(systemSectionView)

        // === Advanced Section ===
        advancedSectionView = createAdvancedSection()
        contentView.addSubview(advancedSectionView)

        // === Tools Section ===
        toolsSectionView = createToolsSection()
        contentView.addSubview(toolsSectionView)

        // === Quit Section ===
        quitSectionView = createQuitSection()
        contentView.addSubview(quitSectionView)

        // === Constraints ===
        setupConstraints()
    }

    private func createSystemSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("System", comment: "Section header"))
        containerView.addSubview(header)

        let contentContainer = NSView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentContainer)

        // Launch at login - Using SwiftUI LaunchAtLogin.Toggle (requires macOS 13+)
        if #available(macOS 13.0, *) {
            launchAtLoginContainerView = NSView()
            launchAtLoginContainerView.translatesAutoresizingMaskIntoConstraints = false
            contentContainer.addSubview(launchAtLoginContainerView)

            let checkboxView = LaunchAtLoginCheckbox()
            let hostingController = NSHostingController(rootView: checkboxView)
            launchAtLoginContainerView.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: launchAtLoginContainerView.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: launchAtLoginContainerView.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(lessThanOrEqualTo: launchAtLoginContainerView.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: launchAtLoginContainerView.bottomAnchor),
                hostingController.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
            ])
        }

        // Enable Notification Positioning
        enabledCheckboxRow = LiquidGlassCheckboxRow(
            title: NSLocalizedString("Enable notification positioning", comment: "Checkbox label"),
            description: NSLocalizedString("Allow Notimanager to reposition your notifications", comment: "Description text"),
            initialState: .off,
            action: #selector(enabledClicked(_:)),
            target: self
        )
        contentContainer.addSubview(enabledCheckboxRow)

        // Add separator
        let separator = LiquidGlassSeparator()
        contentContainer.addSubview(separator)

        // Hide Menu Bar Icon
        hideMenuBarIconCheckboxRow = LiquidGlassCheckboxRow(
            title: NSLocalizedString("Hide menu bar icon", comment: "Checkbox label"),
            description: NSLocalizedString("Hide the menu bar icon. Access settings from Launchpad or Applications.", comment: "Description text"),
            initialState: .off,
            action: #selector(hideMenuBarIconClicked(_:)),
            target: self
        )
        contentContainer.addSubview(hideMenuBarIconCheckboxRow)

        // Setup constraints for content
        // If there's a launch at login view, pin enabled checkbox to it, otherwise pin to contentContainer top
        if let launchView = launchAtLoginContainerView {
            NSLayoutConstraint.activate([
                launchView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                launchView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                launchView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

                enabledCheckboxRow.topAnchor.constraint(equalTo: launchView.bottomAnchor, constant: Spacing.pt24),
                enabledCheckboxRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                enabledCheckboxRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                enabledCheckboxRow.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                enabledCheckboxRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                enabledCheckboxRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: enabledCheckboxRow.bottomAnchor, constant: Spacing.pt24),
            separator.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            hideMenuBarIconCheckboxRow.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: Spacing.pt24),
            hideMenuBarIconCheckboxRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            hideMenuBarIconCheckboxRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            hideMenuBarIconCheckboxRow.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        // Setup container constraints
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: containerView.topAnchor),
            header.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            header.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            contentContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt16),
            contentContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),
            contentContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    private func createAdvancedSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("Advanced", comment: "Section header"))
        containerView.addSubview(header)

        let contentContainer = NSView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentContainer)

        debugModeCheckboxRow = LiquidGlassCheckboxRow(
            title: NSLocalizedString("Debug mode", comment: "Checkbox label"),
            description: NSLocalizedString("Enable detailed logging for troubleshooting", comment: "Description text"),
            initialState: .off,
            action: #selector(debugModeClicked(_:)),
            target: self
        )
        contentContainer.addSubview(debugModeCheckboxRow)

        NSLayoutConstraint.activate([
            debugModeCheckboxRow.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            debugModeCheckboxRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            debugModeCheckboxRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            debugModeCheckboxRow.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: containerView.topAnchor),
            header.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            header.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            contentContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt16),
            contentContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),
            contentContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    private func createToolsSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("Tools", comment: "Section header"))
        containerView.addSubview(header)

        let contentContainer = NSView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentContainer)

        // Create button stack for better alignment
        buttonStackView = NSStackView()
        buttonStackView.orientation = .horizontal
        buttonStackView.spacing = Spacing.pt12
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(buttonStackView)

        // Diagnostics button
        diagnosticsButton = createActionButton(
            title: NSLocalizedString("Open Diagnostics…", comment: "Button label"),
            action: #selector(diagnosticsClicked(_:)),
            isPrimary: true
        )
        buttonStackView.addArrangedSubview(diagnosticsButton)

        // Permissions button
        permissionsButton = createActionButton(
            title: NSLocalizedString("Permissions…", comment: "Button label"),
            action: #selector(permissionsClicked(_:)),
            isPrimary: false
        )
        buttonStackView.addArrangedSubview(permissionsButton)

        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            buttonStackView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: Layout.regularButtonHeight)
        ])

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: containerView.topAnchor),
            header.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            header.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            contentContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt16),
            contentContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),
            contentContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    private func createQuitSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("Application", comment: "Section header"))
        containerView.addSubview(header)

        let contentContainer = NSView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentContainer)

        // Quit button with destructive styling
        quitButton = NSButton()
        quitButton.title = NSLocalizedString("Quit Notimanager", comment: "Button label")
        quitButton.target = self
        quitButton.action = #selector(quitButtonClicked(_:))
        quitButton.translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 10.14, *) {
            quitButton.bezelStyle = .rounded
        } else {
            quitButton.bezelStyle = .rounded
        }

        quitButton.font = Typography.body

        // Use semantic color for destructive action (but not full destructive style to maintain visual consistency)
        quitButton.contentTintColor = .systemRed

        quitButton.sizeToFit()

        // Accessibility - mark as destructive action
        quitButton.setAccessibilityTitle(NSLocalizedString("Quit Notimanager", comment: "Button accessibility title"))
        quitButton.setAccessibilityHelp(NSLocalizedString("Completely quit the Notimanager application", comment: "Button accessibility help"))
        quitButton.setAccessibilityRole(.button)
        quitButton.setAccessibilityIdentifier("settingsQuitButton")

        contentContainer.addSubview(quitButton)

        // Setup constraints for content
        NSLayoutConstraint.activate([
            quitButton.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            quitButton.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            quitButton.trailingAnchor.constraint(lessThanOrEqualTo: contentContainer.trailingAnchor),
            quitButton.heightAnchor.constraint(equalToConstant: Layout.regularButtonHeight),
            quitButton.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        // Setup container constraints
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: containerView.topAnchor),
            header.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            header.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            contentContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt16),
            contentContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),
            contentContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    private var diagnosticsButton: NSButton!
    private var permissionsButton: NSButton!

    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = []

        // Content view width constraint (minimum width for proper layout)
        constraints += [
            contentView.widthAnchor.constraint(equalToConstant: Layout.settingsWindowWidth),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 500)
        ]

        // System Section
        constraints += [
            systemSectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.pt24),
            systemSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            systemSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ]

        // Advanced Section
        constraints += [
            advancedSectionView.topAnchor.constraint(equalTo: systemSectionView.bottomAnchor, constant: Spacing.pt32),
            advancedSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            advancedSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ]

        // Tools Section
        constraints += [
            toolsSectionView.topAnchor.constraint(equalTo: advancedSectionView.bottomAnchor, constant: Spacing.pt32),
            toolsSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolsSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ]

        // Quit Section
        constraints += [
            quitSectionView.topAnchor.constraint(equalTo: toolsSectionView.bottomAnchor, constant: Spacing.pt32),
            quitSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            quitSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            quitSectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.pt32)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: Layout.settingsWindowWidth, height: 500)
        populateSettings()
    }

    // MARK: - Factory Methods

    /// Creates an action button with modern styling
    private func createActionButton(title: String, action: Selector, isPrimary: Bool) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 10.14, *) {
            button.bezelStyle = isPrimary ? .rounded : .regularSquare
            button.keyEquivalent = isPrimary ? "\r" : ""
        } else {
            button.bezelStyle = .rounded
        }

        button.font = Typography.body
        button.sizeToFit()

        // Accessibility with improved context
        button.setAccessibilityTitle(title)
        button.setAccessibilityHelp("Opens \(title.lowercased())")

        return button
    }

    // MARK: - Populate Settings

    private func populateSettings() {
        // Enabled state
        let isEnabled = configurationManager.isEnabled
        enabledCheckboxRow.checkboxButton.state = isEnabled ? .on : .off

        // Hide menu bar icon
        let isIconHidden = configurationManager.isMenuBarIconHidden
        hideMenuBarIconCheckboxRow.checkboxButton.state = isIconHidden ? .on : .off

        // Debug mode
        let isDebug = configurationManager.debugMode
        debugModeCheckboxRow.checkboxButton.state = isDebug ? .on : .off
    }

    // MARK: - Actions

    @objc func enabledClicked(_ sender: NSButton) {
        let isEnabled = sender.state == .on
        configurationManager.isEnabled = isEnabled
        logger.log("Notification positioning \(isEnabled ? "enabled" : "disabled")")
    }

    @objc func hideMenuBarIconClicked(_ sender: NSButton) {
        let shouldHide = sender.state == .on

        if shouldHide {
            // Show confirmation dialog
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Hide Menu Bar Icon", comment: "Alert title")
            alert.informativeText = NSLocalizedString(
                "The menu bar icon will be hidden. To access settings again, launch Notimanager from Launchpad or Applications.",
                comment: "Alert message"
            )
            alert.addButton(withTitle: NSLocalizedString("Hide Icon", comment: "Button title"))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Button title"))
            alert.alertStyle = .warning

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                // User confirmed - hide the icon
                configurationManager.isMenuBarIconHidden = true
                logger.log("Menu bar icon hidden")
                AccessibilityManager.shared.announce("Menu bar icon hidden")
            } else {
                // User cancelled - revert checkbox
                sender.state = .off
            }
        } else {
            // Show the icon
            configurationManager.isMenuBarIconHidden = false
            logger.log("Menu bar icon shown")
            AccessibilityManager.shared.announce("Menu bar icon shown")
        }
    }

    @objc func debugModeClicked(_ sender: NSButton) {
        let isDebug = sender.state == .on
        configurationManager.debugMode = isDebug
        logger.log("Debug mode \(isDebug ? "enabled" : "disabled")")
    }

    @objc func diagnosticsClicked(_ sender: NSButton) {
        logger.log("Opening diagnostics window")
        NotificationMover.shared.coordinator.showDiagnostics()
    }

    @objc func permissionsClicked(_ sender: NSButton) {
        logger.log("Opening accessibility permissions window")
        NotificationMover.shared.coordinator.showPermissionWindowFromSettings()
    }

    @objc func quitButtonClicked(_ sender: NSButton) {
        logger.log("Quit button clicked")

        // Show confirmation alert
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Quit Notimanager?", comment: "Alert title")
        alert.informativeText = NSLocalizedString(
            "This will completely quit Notimanager. Notification positioning will stop working until you relaunch the app.",
            comment: "Alert message"
        )
        alert.addButton(withTitle: NSLocalizedString("Quit Notimanager", comment: "Button title"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Button title"))
        alert.alertStyle = .critical

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // User confirmed - quit the application
            logger.log("User confirmed quit - terminating application")
            AccessibilityManager.shared.announce("Quitting Notimanager")

            // Close settings window first
            if let window = self.view.window {
                window.close()
            }

            // Terminate the application
            NSApplication.shared.terminate(nil)
        }
    }
}
