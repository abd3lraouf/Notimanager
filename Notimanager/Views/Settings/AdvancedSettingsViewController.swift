//
//  AdvancedSettingsViewController.swift
//  Notimanager
//
//  Advanced settings pane with developer tools and debugging options
//  Part of the Liquid Glass Design System
//

import Cocoa
import Settings
import SwiftUI

/// Advanced settings controller providing access to developer tools and system configuration
final class AdvancedSettingsViewController: NSViewController, SettingsPane {

    // MARK: - SettingsPane Conformance

    let paneIdentifier = Settings.PaneIdentifier.advanced
    let paneTitle = NSLocalizedString("Advanced", comment: "Settings pane title")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: "Advanced")!
        } else {
            return NSImage(named: NSImage.advancedName)!
        }
    }

    // MARK: - UI Components

    private var scrollView: NSScrollView!
    private var contentView: NSView!

    // Advanced Section
    private var advancedSectionView: NSView!
    private var debugModeCheckboxRow: LiquidGlassCheckboxRow!

    // Tools Section
    private var toolsSectionView: NSView!
    private var buttonStackView: NSStackView!

    // Keyboard Shortcuts Section
    private var shortcutsSectionView: NSView!
    private var shortcutsButton: NSButton!
    private var shortcutsPanel: KeyboardShortcutsPanel?

    // MARK: - Properties

    private let configurationManager: ConfigurationManager
    private let logger: LoggingService
    private let accessibilityManager: AccessibilityManager
    private let toastManager = ToastNotificationManager.shared

    // Button references
    private var diagnosticsButton: NSButton!
    private var permissionsButton: NSButton!
    private var originalDiagnosticsTitle: String?
    private var originalPermissionsTitle: String?

    // MARK: - Lifecycle

    init(
        configurationManager: ConfigurationManager = .shared,
        logger: LoggingService = .shared,
        accessibilityManager: AccessibilityManager = .shared
    ) {
        self.configurationManager = configurationManager
        self.logger = logger
        self.accessibilityManager = accessibilityManager
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
        // === Advanced Section ===
        advancedSectionView = createAdvancedSection()
        contentView.addSubview(advancedSectionView)

        // === Tools Section ===
        toolsSectionView = createToolsSection()
        contentView.addSubview(toolsSectionView)

        // === Keyboard Shortcuts Section ===
        shortcutsSectionView = createKeyboardShortcutsSection()
        contentView.addSubview(shortcutsSectionView)

        // === Constraints ===
        setupConstraints()
    }

    private func createAdvancedSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("Developer", comment: "Section header"))
        containerView.addSubview(header)

        // Debug Mode with info button
        debugModeCheckboxRow = LiquidGlassCheckboxRow(
            title: NSLocalizedString("Debug mode", comment: "Checkbox label"),
            description: NSLocalizedString("Enable detailed logging for troubleshooting", comment: "Description text"),
            initialState: .off,
            action: #selector(debugModeClicked(_:)),
            target: self
        )
        containerView.addSubview(debugModeCheckboxRow)

        // Info button for debug mode
        let debugInfoButton = InfoButton(
            helpText: NSLocalizedString(
                "Debug mode writes detailed logs to Console.app and helps diagnose issues with notification positioning. Only enable when troubleshooting problems.",
                comment: "Debug mode help text"
            ),
            helpTitle: NSLocalizedString("Debug Mode", comment: "Info button title")
        )
        debugInfoButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(debugInfoButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: containerView.topAnchor),
            header.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            header.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            debugModeCheckboxRow.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt8),
            debugModeCheckboxRow.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            debugModeCheckboxRow.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -60), // Maximum space for info button (32 + 4 + 20 + 4 padding)

            // Position info button next to checkbox (aligned with checkbox, not description)
            debugInfoButton.centerYAnchor.constraint(equalTo: debugModeCheckboxRow.topAnchor, constant: 10),
            debugInfoButton.leadingAnchor.constraint(equalTo: debugModeCheckboxRow.trailingAnchor, constant: Spacing.pt4),
            debugInfoButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            debugModeCheckboxRow.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Spacing.pt16)
        ])

        return containerView
    }

    private func createToolsSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("Tools", comment: "Section header"))
        containerView.addSubview(header)

        // Create button stack for better alignment
        buttonStackView = NSStackView()
        buttonStackView.orientation = .horizontal
        buttonStackView.spacing = Spacing.pt12
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStackView)

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
            header.topAnchor.constraint(equalTo: containerView.topAnchor),
            header.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            header.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            buttonStackView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt8),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Spacing.pt16),
            buttonStackView.heightAnchor.constraint(equalToConstant: Layout.regularButtonHeight)
        ])

        return containerView
    }

    private func createKeyboardShortcutsSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("Reference", comment: "Section header"))
        containerView.addSubview(header)

        // Description
        let description = NSTextField(wrappingLabelWithString: NSLocalizedString(
            "View and search all available keyboard shortcuts.",
            comment: "Shortcuts section description"
        ))
        description.font = Typography.body
        description.textColor = Colors.secondaryLabel
        description.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(description)

        // Keyboard shortcuts button
        shortcutsButton = createActionButton(
            title: NSLocalizedString("Keyboard Shortcuts…", comment: "Button label"),
            action: #selector(keyboardShortcutsClicked(_:)),
            isPrimary: true
        )
        containerView.addSubview(shortcutsButton)

        NSLayoutConstraint.activate([
            // Header
            header.topAnchor.constraint(equalTo: containerView.topAnchor),
            header.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            header.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            // Description
            description.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt8),
            description.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            description.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            // Button
            shortcutsButton.topAnchor.constraint(equalTo: description.bottomAnchor, constant: Spacing.pt12),
            shortcutsButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            shortcutsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Spacing.pt16),
            shortcutsButton.heightAnchor.constraint(equalToConstant: Layout.regularButtonHeight)
        ])

        return containerView
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Content view width constraint
            contentView.widthAnchor.constraint(equalToConstant: Layout.settingsWindowWidth),

            // Advanced Section
            advancedSectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.pt16),
            advancedSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            advancedSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Tools Section
            toolsSectionView.topAnchor.constraint(equalTo: advancedSectionView.bottomAnchor, constant: Spacing.pt20),
            toolsSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolsSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Keyboard Shortcuts Section
            shortcutsSectionView.topAnchor.constraint(equalTo: toolsSectionView.bottomAnchor, constant: Spacing.pt20),
            shortcutsSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shortcutsSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shortcutsSectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.pt24),

            // Ensure content view has a minimum height for proper scrolling
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 350)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: Layout.settingsWindowWidth, height: 380)
        populateSettings()
    }

    // MARK: - Button Creation Helper

    /// Creates a styled action button
    /// - Parameters:
    ///   - title: The button title
    ///   - action: The selector to call when button is clicked
    ///   - isPrimary: Whether this is the primary action button
    /// - Returns: Configured NSButton
    private func createActionButton(title: String, action: Selector, isPrimary: Bool) -> NSButton {
        let button = NSButton()
        button.title = title
        button.target = self
        button.action = action
        button.translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 10.14, *) {
            button.bezelStyle = isPrimary ? .rounded : .regularSquare
        } else {
            button.bezelStyle = isPrimary ? .rounded : .regularSquare
        }

        button.font = Typography.body

        if !isPrimary {
            button.keyEquivalent = ""
        }

        button.sizeToFit()

        return button
    }

    // MARK: - Populate Settings

    private func populateSettings() {
        // Debug mode
        let isDebug = configurationManager.debugMode
        debugModeCheckboxRow.checkboxButton.state = isDebug ? .on : .off
    }

    // MARK: - Actions

    @objc func debugModeClicked(_ sender: NSButton) {
        let isDebug = sender.state == .on
        configurationManager.debugMode = isDebug
        logger.log("Debug mode \(isDebug ? "enabled" : "disabled")")
        AccessibilityManager.shared.announce("Debug mode \(isDebug ? "enabled" : "disabled")")

        // Temporarily disable toast to test if it's causing the crash
        print("✅ Debug mode toggled to: \(isDebug)")
    }

    @objc func diagnosticsClicked(_ sender: NSButton) {
        logger.log("Opening diagnostics window")

        // Show loading state
        setButtonLoading(diagnosticsButton, loading: true)

        // Simulate brief loading and open diagnostics
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            NotificationMover.shared.coordinator.showDiagnostics()
            AccessibilityManager.shared.announce("Opening diagnostics")

            // Reset button state
            self.setButtonLoading(self.diagnosticsButton, loading: false)

            // Show toast
            DispatchQueue.main.async {
                self.toastManager.showSuccess(
                    NSLocalizedString("Diagnostics Opened", comment: "Toast title"),
                    message: NSLocalizedString("Diagnostics window is now available.", comment: "Toast message")
                )
            }
        }
    }

    @objc func permissionsClicked(_ sender: NSButton) {
        logger.log("Opening accessibility permissions window")

        // Show loading state
        setButtonLoading(permissionsButton, loading: true)

        // Simulate brief loading and open permissions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            NotificationMover.shared.coordinator.showPermissionWindowFromSettings()
            AccessibilityManager.shared.announce("Opening permissions")

            // Reset button state
            self.setButtonLoading(self.permissionsButton, loading: false)

            // Show toast
            DispatchQueue.main.async {
                self.toastManager.showInfo(
                    NSLocalizedString("Permissions", comment: "Toast title"),
                    message: NSLocalizedString("System Settings will open for accessibility permissions.", comment: "Toast message")
                )
            }
        }
    }

    @objc func keyboardShortcutsClicked(_ sender: NSButton) {
        logger.log("Opening keyboard shortcuts panel")

        // Create or reuse panel
        if shortcutsPanel == nil {
            shortcutsPanel = KeyboardShortcutsPanel()
        }

        shortcutsPanel?.show()
        AccessibilityManager.shared.announce("Opening keyboard shortcuts")
    }

    // MARK: - Loading State Helpers

    private func setButtonLoading(_ button: NSButton, loading: Bool) {
        if loading {
            // Store original title
            if button === diagnosticsButton && originalDiagnosticsTitle == nil {
                originalDiagnosticsTitle = button.title
            } else if button === permissionsButton && originalPermissionsTitle == nil {
                originalPermissionsTitle = button.title
            }

            // Set loading state
            button.title = NSLocalizedString("Opening…", comment: "Button loading state")
            button.isEnabled = false
        } else {
            // Restore original title
            if button === diagnosticsButton, let original = originalDiagnosticsTitle {
                button.title = original
                originalDiagnosticsTitle = nil
            } else if button === permissionsButton, let original = originalPermissionsTitle {
                button.title = original
                originalPermissionsTitle = nil
            }

            button.isEnabled = true
        }
    }
}
