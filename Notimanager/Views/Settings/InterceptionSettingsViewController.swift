//
//  PositionSettingsViewController.swift
//  Notimanager
//
//  Interception settings pane with position preview and testing controls
//  Allows users to configure notification interception and test with different notification types
//

import Cocoa
import Settings
import UserNotifications

final class InterceptionSettingsViewController: NSViewController, SettingsPane {

    // MARK: - ConfigurationObserver Conformance

    private var observerToken: Any?

    // MARK: - SettingsPane Conformance

    let paneIdentifier = Settings.PaneIdentifier.position
    let paneTitle = NSLocalizedString("Interception", comment: "Settings pane title")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "hand.tap", accessibilityDescription: "Interception")!
        } else {
            return NSImage(named: NSImage.actionTemplateName)!
        }
    }

    // MARK: - UI Components

    private var scrollView: NSScrollView!
    private var contentView: NSView!

    // Interception Controls Section
    private var interceptionSection: NSView!
    private var interceptNotificationsCheckboxRow: LiquidGlassCheckboxRow!
    private var interceptWidgetsCheckboxRow: LiquidGlassCheckboxRow!

    // Position Preview Section
    private var positionPreviewSection: NSView!
    private var positionGridContainer: NSView!
    private var positionGridView: PositionGridView!

    // Test Section
    private var testSection: NSView!
    private var testBannerButton: NSButton!
    private var testWidgetButton: NSButton!
    private var testStatusContainer: NSView!
    private var testStatusLabel: NSTextField!

    // MARK: - Properties

    private let configurationManager = ConfigurationManager.shared
    private let testNotificationService = TestNotificationService.shared
    private let logger = LoggingService.shared

    private var currentPosition: NotificationPosition {
        get { configurationManager.currentPosition }
        set { configurationManager.currentPosition = newValue }
    }

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView

        self.view = scrollView

        setupUI()
    }

    private func setupUI() {
        // === Interception Controls Section ===
        interceptionSection = createInterceptionSection()
        contentView.addSubview(interceptionSection)

        // === Position Preview Section ===
        positionPreviewSection = createPositionPreviewSection()
        contentView.addSubview(positionPreviewSection)

        // === Test Section ===
        testSection = createTestSection()
        contentView.addSubview(testSection)

        // === Constraints ===
        setupConstraints()

        // === Initial State ===
    }

    // MARK: - Section Creation

    private func createInterceptionSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("Notification Interception", comment: "Section header"))
        containerView.addSubview(header)

        let contentContainer = NSView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentContainer)

        // Intercept Normal Notifications
        interceptNotificationsCheckboxRow = LiquidGlassCheckboxRow(
            title: NSLocalizedString("Normal notifications", comment: "Checkbox label"),
            description: NSLocalizedString("Intercept standard system notification banners and alerts", comment: "Description text"),
            initialState: .off,
            action: #selector(interceptNotificationsClicked(_:)),
            target: self
        )
        interceptNotificationsCheckboxRow.checkboxButton.setAccessibilityIdentifier("interceptNotificationsCheckbox")
        interceptNotificationsCheckboxRow.checkboxButton.setAccessibilityRole(.checkBox)
        contentContainer.addSubview(interceptNotificationsCheckboxRow)

        // Add separator
        let separator1 = LiquidGlassSeparator()
        separator1.setAccessibilityRole(.splitGroup)
        contentContainer.addSubview(separator1)

        // Intercept Widgets
        interceptWidgetsCheckboxRow = LiquidGlassCheckboxRow(
            title: NSLocalizedString("Widgets", comment: "Checkbox label"),
            description: NSLocalizedString("Intercept Notification Center and interactive widgets", comment: "Description text"),
            initialState: .off,
            action: #selector(interceptWidgetsClicked(_:)),
            target: self
        )
        interceptWidgetsCheckboxRow.checkboxButton.setAccessibilityIdentifier("interceptWidgetsCheckbox")
        interceptWidgetsCheckboxRow.checkboxButton.setAccessibilityRole(.checkBox)
        contentContainer.addSubview(interceptWidgetsCheckboxRow)

        // Setup constraints
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: containerView.topAnchor),
            header.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            header.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            interceptNotificationsCheckboxRow.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt16),
            interceptNotificationsCheckboxRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            interceptNotificationsCheckboxRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            separator1.topAnchor.constraint(equalTo: interceptNotificationsCheckboxRow.bottomAnchor, constant: Spacing.pt12),
            separator1.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            separator1.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            interceptWidgetsCheckboxRow.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: Spacing.pt12),
            interceptWidgetsCheckboxRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            interceptWidgetsCheckboxRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            interceptWidgetsCheckboxRow.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),

            contentContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt16),
            contentContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),
            contentContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Spacing.pt16)
        ])

        return containerView
    }

    private func createPositionPreviewSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Section Header
        let header = SettingsSectionHeader(title: NSLocalizedString("Position Preview", comment: "Section header"))
        containerView.addSubview(header)

        // Section Description
        let description = NSTextField(wrappingLabelWithString: NSLocalizedString(
            "See exactly where notifications will appear.",
            comment: "Position preview description"
        ))
        description.font = Typography.body
        description.textColor = Colors.secondaryLabel
        description.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(description)

        // Position Grid Container
        positionGridContainer = NSView()
        positionGridContainer.wantsLayer = true
        positionGridContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        positionGridContainer.layer?.cornerRadius = Layout.cardCornerRadius
        positionGridContainer.layer?.masksToBounds = false // Don't clip shadows and overflow
        positionGridContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(positionGridContainer)

        // Position Grid View
        let gridView = PositionGridView(selection: currentPosition) { [weak self] newPosition in
            self?.handlePositionChange(newPosition)
        }
        gridView.translatesAutoresizingMaskIntoConstraints = false
        positionGridContainer.addSubview(gridView)
        self.positionGridView = gridView

        // Setup constraints
        NSLayoutConstraint.activate([
            // Header
            header.topAnchor.constraint(equalTo: containerView.topAnchor),
            header.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            header.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            // Description
            description.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt8),
            description.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            description.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            // Grid Container
            positionGridContainer.topAnchor.constraint(equalTo: description.bottomAnchor, constant: Spacing.pt16),
            positionGridContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            positionGridContainer.widthAnchor.constraint(equalToConstant: Layout.gridSize * 2 + Layout.gridSpacing + Spacing.pt48),
            positionGridContainer.heightAnchor.constraint(equalToConstant: Layout.gridSize * 2 + Layout.gridSpacing + Spacing.pt48),

            // Grid View - centered in container
            gridView.centerXAnchor.constraint(equalTo: positionGridContainer.centerXAnchor),
            gridView.centerYAnchor.constraint(equalTo: positionGridContainer.centerYAnchor),

            // Grid Container - set bottom anchor
            positionGridContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Spacing.pt12)
        ])

        return containerView
    }

    private func createTestSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("Test Interception", comment: "Section header"))
        containerView.addSubview(header)

        let description = NSTextField(wrappingLabelWithString: NSLocalizedString(
            "Send test notifications to verify interception is working.",
            comment: "Test section description"
        ))
        description.font = Typography.body
        description.textColor = Colors.secondaryLabel
        description.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(description)

        // Create button stack view
        let buttonStackView = NSStackView()
        buttonStackView.orientation = .horizontal
        buttonStackView.spacing = Spacing.pt8
        buttonStackView.alignment = .top
        buttonStackView.distribution = .fill
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStackView)

        // Test Banner Notification Button
        testBannerButton = createTestButton(
            title: NSLocalizedString("Banner", comment: "Button label"),
            isPrimary: true,
            action: #selector(testBannerClicked(_:))
        )
        buttonStackView.addArrangedSubview(testBannerButton)

        // Test Widget Update Button
        testWidgetButton = createTestButton(
            title: NSLocalizedString("Widget", comment: "Button label"),
            isPrimary: false,
            action: #selector(testWidgetClicked(_:))
        )
        buttonStackView.addArrangedSubview(testWidgetButton)

        // Set equal widths for buttons
        testBannerButton.widthAnchor.constraint(equalToConstant: 110).isActive = true
        testWidgetButton.widthAnchor.constraint(equalToConstant: 110).isActive = true

        // Status Container
        testStatusContainer = NSView()
        testStatusContainer.wantsLayer = true
        testStatusContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        testStatusContainer.layer?.cornerRadius = Layout.mediumCornerRadius
        testStatusContainer.translatesAutoresizingMaskIntoConstraints = false
        testStatusContainer.isHidden = true
        containerView.addSubview(testStatusContainer)

        // Status Label
        testStatusLabel = NSTextField(labelWithString: "")
        testStatusLabel.font = Typography.callout
        testStatusLabel.textColor = Colors.secondaryLabel
        testStatusLabel.alignment = .center
        testStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        testStatusContainer.addSubview(testStatusLabel)

        // Setup constraints
        NSLayoutConstraint.activate([
            // Header
            header.topAnchor.constraint(equalTo: containerView.topAnchor),
            header.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            header.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            // Description
            description.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Spacing.pt8),
            description.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            description.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            // Button stack view
            buttonStackView.topAnchor.constraint(equalTo: description.bottomAnchor, constant: Spacing.pt12),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            buttonStackView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -Spacing.pt32),

            // Status Container
            testStatusContainer.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: Spacing.pt12),
            testStatusContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt32),
            testStatusContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt32),
            testStatusContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Spacing.pt16),

            // Status Label
            testStatusLabel.topAnchor.constraint(equalTo: testStatusContainer.topAnchor, constant: Spacing.pt12),
            testStatusLabel.leadingAnchor.constraint(equalTo: testStatusContainer.leadingAnchor, constant: Spacing.pt16),
            testStatusLabel.trailingAnchor.constraint(equalTo: testStatusContainer.trailingAnchor, constant: -Spacing.pt16),
            testStatusLabel.bottomAnchor.constraint(equalTo: testStatusContainer.bottomAnchor, constant: -Spacing.pt12)
        ])

        return containerView
    }

    private func createTestButton(title: String, isPrimary: Bool, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 10.14, *) {
            button.bezelStyle = isPrimary ? .rounded : .regularSquare
            button.keyEquivalent = isPrimary ? "\r" : ""
        }

        button.font = Typography.body

        button.setAccessibilityTitle(title)
        button.setAccessibilityHelp("Sends a test notification")

        return button
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Content view
            contentView.widthAnchor.constraint(equalToConstant: Layout.settingsWindowWidth),

            // Interception Section
            interceptionSection.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.pt16),
            interceptionSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            interceptionSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Position Preview Section
            positionPreviewSection.topAnchor.constraint(equalTo: interceptionSection.bottomAnchor, constant: Spacing.pt20),
            positionPreviewSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            positionPreviewSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Test Section
            testSection.topAnchor.constraint(equalTo: positionPreviewSection.bottomAnchor, constant: Spacing.pt20),
            testSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            testSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            testSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.pt24)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: Layout.settingsWindowWidth, height: 600)
        populateSettings()
        setupTestNotification()
        setupAccessibility()
        setupConfigurationObserver()
    }

    // MARK: - Setup

    private func populateSettings() {
        // Interception settings
        interceptNotificationsCheckboxRow.checkboxButton.state = configurationManager.interceptNotifications ? .on : .off
        interceptWidgetsCheckboxRow.checkboxButton.state = configurationManager.interceptWidgets ? .on : .off

        // Position settings are handled by PositionGridView
    }

    private func setupTestNotification() {
        updateTestStatus(.idle)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTestNotificationStatusChanged(_:)),
            name: NSNotification.Name("TestNotificationStatusChanged"),
            object: nil
        )
    }

    private func setupAccessibility() {
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.group)
        view.setAccessibilityLabel("Interception Settings")
    }

    private func setupConfigurationObserver() {
        // Observe UserDefaults changes for position to update UI when position changes from menu
        observerToken = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleUserDefaultsDidChange()
        }
    }

    private func handleUserDefaultsDidChange() {
        // Update grid selection when position changes from menu
        positionGridView?.updateSelection(to: configurationManager.currentPosition)
    }

    // MARK: - Position Handling

    private func handlePositionChange(_ newPosition: NotificationPosition) {
        currentPosition = newPosition
        logger.log("Position changed to: \(newPosition.displayName)")

        AccessibilityManager.shared.announce("Notification position changed to \(newPosition.displayName)")

        // Show system notification after a short delay to ensure configuration is fully updated
        // This prevents the notification from appearing at the old position
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sendSystemNotification(for: newPosition)
        }

        // Note: ConfigurationManager automatically notifies all observers via its observer pattern
        // and saves to UserDefaults, so we don't need to post additional notifications here
    }

    private func sendSystemNotification(for position: NotificationPosition) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Position Changed", comment: "Notification title")
        content.body = String(format: NSLocalizedString("Notifications will appear in the %@.", comment: "Notification body"), position.displayName)
        content.sound = .default

        // Create unique identifier with timestamp to prevent any collisions
        let uniqueId = "position-change-\(position.rawValue)-\(Date().timeIntervalSince1970)-\(UUID().uuidString)"

        let request = UNNotificationRequest(
            identifier: uniqueId,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                LoggingService.shared.error("Failed to send position change notification: \(error)")
            }
        }
    }

    // MARK: - Test Status

    private func updateTestStatus(_ status: TestNotificationStatus) {
        switch status {
        case .idle:
            testStatusContainer?.isHidden = true
            testBannerButton?.isEnabled = true
            testWidgetButton?.isEnabled = true
        case .checkingPermissions, .sending, .waitingForInterception:
            testStatusContainer?.isHidden = false
            testStatusLabel?.stringValue = status.localizedDescription
            testStatusLabel?.textColor = status.color
            testBannerButton?.isEnabled = false
            testWidgetButton?.isEnabled = false
            AccessibilityManager.shared.announce(status.localizedDescription)
        case .interceptedSuccessfully, .notIntercepted, .permissionDenied, .permissionError, .sendingFailed, .unknownStatus:
            testStatusContainer?.isHidden = false
            testStatusLabel?.stringValue = status.localizedDescription
            testStatusLabel?.textColor = status.color
            testBannerButton?.isEnabled = true
            testWidgetButton?.isEnabled = true
            AccessibilityManager.shared.announce(status.localizedDescription)
        }
    }

    // MARK: - Actions

    @objc func interceptNotificationsClicked(_ sender: NSButton) {
        let shouldIntercept = sender.state == .on
        configurationManager.interceptNotifications = shouldIntercept
        logger.log("Normal notification interception \(shouldIntercept ? "enabled" : "disabled")")
        AccessibilityManager.shared.announce("Normal notification interception \(shouldIntercept ? "enabled" : "disabled")")
    }

    @objc func interceptWidgetsClicked(_ sender: NSButton) {
        let shouldIntercept = sender.state == .on
        configurationManager.interceptWidgets = shouldIntercept
        logger.log("Widget interception \(shouldIntercept ? "enabled" : "disabled")")
        AccessibilityManager.shared.announce("Widget interception \(shouldIntercept ? "enabled" : "disabled")")
    }

    @objc func testBannerClicked(_ sender: NSButton) {
        testNotificationService.sendTestNotification(to: currentPosition)
    }

    @objc func testWidgetClicked(_ sender: NSButton) {
        testNotificationService.sendWidgetTestNotification(to: currentPosition)
    }

    @objc private func handleTestNotificationStatusChanged(_ notification: Notification) {
        if let status = notification.userInfo?["status"] as? TestNotificationStatus {
            updateTestStatus(status)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - TestNotificationStatus Extension

private extension TestNotificationStatus {
    var localizedDescription: String {
        switch self {
        case .idle:
            return ""
        case .checkingPermissions:
            return NSLocalizedString("Checking permissions...", comment: "Test status")
        case .sending:
            return NSLocalizedString("Sending test notification...", comment: "Test status")
        case .waitingForInterception:
            return NSLocalizedString("Waiting for interception...", comment: "Test status")
        case .interceptedSuccessfully:
            return NSLocalizedString("✓ Test notification intercepted successfully!", comment: "Test status")
        case .notIntercepted:
            return NSLocalizedString("✗ Test notification was not intercepted.", comment: "Test status")
        case .permissionDenied:
            return NSLocalizedString("✗ Notification permission denied.", comment: "Test status")
        case .permissionError(let message):
            return NSLocalizedString("✗ Permission error: \(message)", comment: "Test status")
        case .sendingFailed(let message):
            return NSLocalizedString("✗ Sending failed: \(message)", comment: "Test status")
        case .unknownStatus:
            return NSLocalizedString("✗ Unknown status", comment: "Test status")
        }
    }

    var color: NSColor {
        switch self {
        case .idle:
            return .labelColor
        case .checkingPermissions, .sending, .waitingForInterception:
            return .systemBlue
        case .interceptedSuccessfully:
            return .systemGreen
        case .notIntercepted, .permissionDenied, .permissionError, .sendingFailed, .unknownStatus:
            return .systemRed
        }
    }
}
