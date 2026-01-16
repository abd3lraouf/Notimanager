//
//  GeneralSettingsViewController.swift
//  Notimanager
//
//  General settings pane following Apple HIG standards with improved UX
//

import Cocoa
import Settings
import ServiceManagement

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
    private var systemSectionHeader: NSTextField!
    private var startAtLoginButton: NSButton!
    private var startAtLoginDescription: NSTextField!
    private var enabledButton: NSButton!
    private var enabledDescription: NSTextField!
    private var hideMenuBarIconButton: NSButton!
    private var hideMenuBarIconDescription: NSTextField!

    // Advanced Section
    private var advancedSectionHeader: NSTextField!
    private var debugModeButton: NSButton!
    private var debugModeDescription: NSTextField!

    // Tools Section
    private var toolsSectionHeader: NSTextField!
    private var diagnosticsButton: NSButton!
    private var permissionsButton: NSButton!

    // MARK: - Properties

    private let configurationManager = ConfigurationManager.shared
    private let launchAgentManager = LaunchAgentManager()
    private let logger = LoggingService.shared

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = NSView()
        view.frame = NSRect(x: 0, y: 0, width: Layout.settingsWindowWidth, height: 400)
        self.view = view

        setupUI()
    }

    private func setupUI() {
        // === System Section ===
        systemSectionHeader = createSectionHeader(NSLocalizedString("System", comment: "Section header"))
        view.addSubview(systemSectionHeader)

        // Start at login
        startAtLoginButton = createCheckbox(
            title: NSLocalizedString("Start at login", comment: "Checkbox label"),
            action: #selector(startAtLoginClicked(_:))
        )
        view.addSubview(startAtLoginButton)

        startAtLoginDescription = createDescriptionLabel(
            NSLocalizedString("Automatically launch Notimanager when you log in", comment: "Description text")
        )
        view.addSubview(startAtLoginDescription)

        // Enabled
        enabledButton = createCheckbox(
            title: NSLocalizedString("Enable notification positioning", comment: "Checkbox label"),
            action: #selector(enabledClicked(_:))
        )
        view.addSubview(enabledButton)

        enabledDescription = createDescriptionLabel(
            NSLocalizedString("Allow Notimanager to reposition your notifications", comment: "Description text")
        )
        view.addSubview(enabledDescription)

        // Hide Menu Bar Icon
        hideMenuBarIconButton = createCheckbox(
            title: NSLocalizedString("Hide menu bar icon", comment: "Checkbox label"),
            action: #selector(hideMenuBarIconClicked(_:))
        )
        view.addSubview(hideMenuBarIconButton)

        hideMenuBarIconDescription = createDescriptionLabel(
            NSLocalizedString("Hide the menu bar icon (launch app from Launchpad to access settings)", comment: "Description text")
        )
        view.addSubview(hideMenuBarIconDescription)

        // === Advanced Section ===
        advancedSectionHeader = createSectionHeader(NSLocalizedString("Advanced", comment: "Section header"))
        view.addSubview(advancedSectionHeader)

        debugModeButton = createCheckbox(
            title: NSLocalizedString("Debug mode", comment: "Checkbox label"),
            action: #selector(debugModeClicked(_:))
        )
        view.addSubview(debugModeButton)

        debugModeDescription = createDescriptionLabel(
            NSLocalizedString("Enable detailed logging for troubleshooting (requires restart)", comment: "Description text")
        )
        view.addSubview(debugModeDescription)

        // === Tools Section ===
        toolsSectionHeader = createSectionHeader(NSLocalizedString("Tools", comment: "Section header"))
        view.addSubview(toolsSectionHeader)

        // Diagnostics button
        diagnosticsButton = createActionButton(
            title: NSLocalizedString("Open Diagnostics…", comment: "Button label"),
            action: #selector(diagnosticsClicked(_:)),
            isPrimary: true
        )
        view.addSubview(diagnosticsButton)

        // Permissions button
        permissionsButton = createActionButton(
            title: NSLocalizedString("Accessibility Permissions…", comment: "Button label"),
            action: #selector(permissionsClicked(_:)),
            isPrimary: false
        )
        view.addSubview(permissionsButton)

        // === Constraints ===
        setupConstraints()
    }

    private func setupConstraints() {
        let leadingMargin: CGFloat = Spacing.pt32
        let trailingMargin: CGFloat = Spacing.pt32
        let checkboxSpacing: CGFloat = Spacing.pt4
        let controlGroupSpacing: CGFloat = Spacing.pt20
        let sectionSpacing: CGFloat = Spacing.pt28

        NSLayoutConstraint.activate([
            // System Section Header
            systemSectionHeader.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.pt24),
            systemSectionHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin),
            systemSectionHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            // Start at Login
            startAtLoginButton.topAnchor.constraint(equalTo: systemSectionHeader.bottomAnchor, constant: sectionSpacing),
            startAtLoginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin),
            startAtLoginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            startAtLoginDescription.topAnchor.constraint(equalTo: startAtLoginButton.bottomAnchor, constant: checkboxSpacing),
            startAtLoginDescription.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin + Spacing.pt20), // Indent for description
            startAtLoginDescription.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            // Enabled
            enabledButton.topAnchor.constraint(equalTo: startAtLoginDescription.bottomAnchor, constant: controlGroupSpacing),
            enabledButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin),
            enabledButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            enabledDescription.topAnchor.constraint(equalTo: enabledButton.bottomAnchor, constant: checkboxSpacing),
            enabledDescription.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin + Spacing.pt20),
            enabledDescription.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            // Hide Menu Bar Icon
            hideMenuBarIconButton.topAnchor.constraint(equalTo: enabledDescription.bottomAnchor, constant: controlGroupSpacing),
            hideMenuBarIconButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin),
            hideMenuBarIconButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            hideMenuBarIconDescription.topAnchor.constraint(equalTo: hideMenuBarIconButton.bottomAnchor, constant: checkboxSpacing),
            hideMenuBarIconDescription.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin + Spacing.pt20),
            hideMenuBarIconDescription.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            // Advanced Section Header
            advancedSectionHeader.topAnchor.constraint(equalTo: hideMenuBarIconDescription.bottomAnchor, constant: Spacing.pt32),
            advancedSectionHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin),
            advancedSectionHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            // Debug Mode
            debugModeButton.topAnchor.constraint(equalTo: advancedSectionHeader.bottomAnchor, constant: sectionSpacing),
            debugModeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin),
            debugModeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            debugModeDescription.topAnchor.constraint(equalTo: debugModeButton.bottomAnchor, constant: checkboxSpacing),
            debugModeDescription.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin + Spacing.pt20),
            debugModeDescription.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            // Tools Section Header
            toolsSectionHeader.topAnchor.constraint(equalTo: debugModeDescription.bottomAnchor, constant: Spacing.pt32),
            toolsSectionHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin),
            toolsSectionHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),

            // Buttons - horizontal layout with proper spacing
            diagnosticsButton.topAnchor.constraint(equalTo: toolsSectionHeader.bottomAnchor, constant: sectionSpacing),
            diagnosticsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingMargin),
            diagnosticsButton.widthAnchor.constraint(equalToConstant: 160),

            permissionsButton.topAnchor.constraint(equalTo: toolsSectionHeader.bottomAnchor, constant: sectionSpacing),
            permissionsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailingMargin),
            permissionsButton.leadingAnchor.constraint(greaterThanOrEqualTo: diagnosticsButton.trailingAnchor, constant: Spacing.pt12),
            permissionsButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -Spacing.pt24)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: Layout.settingsWindowWidth, height: 400)
        populateSettings()
    }

    // MARK: - Factory Methods

    /// Creates a section header with proper styling
    private func createSectionHeader(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = Typography.headline
        label.textColor = Colors.label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setAccessibilityRole(.staticText)
        label.setAccessibilityLabel(text)
        return label
    }

    /// Creates a checkbox with proper styling and accessibility
    private func createCheckbox(title: String, action: Selector) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: self, action: action)
        button.translatesAutoresizingMaskIntoConstraints = false

        // Use system font for checkbox
        button.font = Typography.body

        // Accessibility - NSButton already has correct role for checkbox
        button.setAccessibilityTitle(title)
        button.setAccessibilityHelp(title)

        return button
    }

    /// Creates a description label with proper styling
    private func createDescriptionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = Typography.caption1
        label.textColor = Colors.secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byWordWrapping

        // Accessibility
        label.setAccessibilityRole(.staticText)
        label.setAccessibilityLabel(text)

        return label
    }

    /// Creates an action button with modern styling
    private func createActionButton(title: String, action: Selector, isPrimary: Bool) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 10.14, *) {
            button.bezelStyle = isPrimary ? .rounded : .regularSquare
            button.keyEquivalent = isPrimary ? "\r" : "" // Return key for primary
        } else {
            button.bezelStyle = .rounded
        }

        button.font = Typography.body
        button.sizeToFit()

        // Accessibility
        button.setAccessibilityTitle(title)

        return button
    }

    // MARK: - Populate Settings

    private func populateSettings() {
        // Start at login
        let isLoginEnabled = isLoginItemEnabled()
        startAtLoginButton.state = isLoginEnabled ? .on : .off

        // Enabled state
        let isEnabled = configurationManager.isEnabled
        enabledButton.state = isEnabled ? .on : .off

        // Hide menu bar icon
        let isIconHidden = configurationManager.isMenuBarIconHidden
        hideMenuBarIconButton.state = isIconHidden ? .on : .off

        // Debug mode
        let isDebug = configurationManager.debugMode
        debugModeButton.state = isDebug ? .on : .off
    }

    // MARK: - Login Item Management

    private func isLoginItemEnabled() -> Bool {
        return launchAgentManager.isEnabled
    }

    // MARK: - Actions

    @objc func startAtLoginClicked(_ sender: NSButton) {
        let shouldEnable = sender.state == .on

        do {
            try launchAgentManager.setEnabled(shouldEnable)
            logger.log("Launch at login \(shouldEnable ? "enabled" : "disabled")")
        } catch {
            logger.error("Failed to set launch agent: \(error)")
            sender.state = shouldEnable ? .off : .on // Revert
        }
    }

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
            } else {
                // User cancelled - revert checkbox
                sender.state = .off
            }
        } else {
            // Show the icon
            configurationManager.isMenuBarIconHidden = false
            logger.log("Menu bar icon shown")
        }
    }

    @objc func debugModeClicked(_ sender: NSButton) {
        let isDebug = sender.state == .on
        configurationManager.debugMode = isDebug
        logger.log("Debug mode \(isDebug ? "enabled" : "disabled")")
    }

    @objc func diagnosticsClicked(_ sender: NSButton) {
        logger.log("Opening diagnostics window")
        NotificationMoverCoordinator().showDiagnostics()
    }

    @objc func permissionsClicked(_ sender: NSButton) {
        logger.log("Opening accessibility permissions window")
        NotificationMoverCoordinator().showPermissionWindowFromSettings()
    }
}
