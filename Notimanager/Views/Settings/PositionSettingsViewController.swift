//
//  PositionSettingsViewController.swift
//  Notimanager
//
//  Position settings pane following MonitorControl's design
//

import Cocoa
import Settings

final class PositionSettingsViewController: NSViewController, SettingsPane {

    // MARK: - SettingsPane Conformance

    let paneIdentifier = Settings.PaneIdentifier.position
    let paneTitle = NSLocalizedString("Position", comment: "Settings pane title")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: "Position")!
        } else {
            return NSImage(named: NSImage.infoName)!
        }
    }

    // MARK: - UI Components

    private var headerLabel: NSTextField!
    private var descriptionLabel: NSTextField!
    private var positionGridView: PositionGridView!
    private var testNotificationButton: NSButton!
    private var testStatusLabel: NSTextField!
    private var testStatusContainer: NSVisualEffectView!

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
        let view = NSView()
        view.frame = NSRect(x: 0, y: 0, width: 500, height: 520)
        self.view = view

        setupUI()
    }

    private func setupUI() {
        // Section Header
        let header = NSTextField(labelWithString: NSLocalizedString("Notification Position", comment: "Position settings header"))
        header.font = Typography.title2
        header.textColor = Colors.label
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        self.headerLabel = header

        // Section Description
        let description = NSTextField(wrappingLabelWithString: NSLocalizedString(
            "Choose where notifications should appear on your screen. Select a position below to change it.",
            comment: "Position settings description"
        ))
        description.font = Typography.body
        description.textColor = Colors.secondaryLabel
        description.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(description)
        self.descriptionLabel = description

        // Position Grid Container
        let gridView = PositionGridView(selection: currentPosition) { [weak self] newPosition in
            self?.handlePositionChange(newPosition)
        }
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        self.positionGridView = gridView

        // Test Notification Section Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separator)

        // Test Notification Button
        let testBtn = NSButton(
            title: NSLocalizedString("Send Test Notification", comment: "Test button title"),
            target: self,
            action: #selector(sendTestNotificationClicked(_:))
        )
        testBtn.bezelStyle = .rounded
        testBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(testBtn)
        self.testNotificationButton = testBtn

        // Test Status Container (for visual polish)
        let statusContainer = NSVisualEffectView()
        statusContainer.material = .contentBackground
        statusContainer.blendingMode = .withinWindow
        statusContainer.state = .active
        statusContainer.wantsLayer = true
        statusContainer.layer?.cornerRadius = Layout.smallCornerRadius
        statusContainer.layer?.borderWidth = Border.thin
        statusContainer.layer?.borderColor = Colors.separator.withAlphaComponent(0.3).cgColor
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.isHidden = true
        view.addSubview(statusContainer)
        self.testStatusContainer = statusContainer

        // Test Status Label
        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = Typography.callout
        statusLabel.textColor = Colors.secondaryLabel
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(statusLabel)
        self.testStatusLabel = statusLabel

        // Constraints using DesignTokens spacing
        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.pt32),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.pt32),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.pt32),

            // Description
            descriptionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: Spacing.pt8),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.pt32),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.pt32),

            // Grid - centered with consistent margins
            positionGridView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: Spacing.pt24),
            positionGridView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            positionGridView.widthAnchor.constraint(equalToConstant: Layout.gridSize * 3 + Layout.gridSpacing * 2),
            positionGridView.heightAnchor.constraint(equalToConstant: Layout.gridSize * 3 + Layout.gridSpacing * 2),

            // Separator
            separator.topAnchor.constraint(equalTo: positionGridView.bottomAnchor, constant: Spacing.pt32),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.pt32),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.pt32),

            // Test Button
            testNotificationButton.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: Spacing.pt20),
            testNotificationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testNotificationButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),

            // Status Container
            testStatusContainer.topAnchor.constraint(equalTo: testNotificationButton.bottomAnchor, constant: Spacing.pt12),
            testStatusContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.pt32),
            testStatusContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.pt32),
            testStatusContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -Spacing.pt32),

            // Status Label (padded inside container)
            testStatusLabel.topAnchor.constraint(equalTo: testStatusContainer.topAnchor, constant: Spacing.pt12),
            testStatusLabel.leadingAnchor.constraint(equalTo: testStatusContainer.leadingAnchor, constant: Spacing.pt16),
            testStatusLabel.trailingAnchor.constraint(equalTo: testStatusContainer.trailingAnchor, constant: -Spacing.pt16),
            testStatusLabel.bottomAnchor.constraint(equalTo: testStatusContainer.bottomAnchor, constant: -Spacing.pt12)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: 500, height: 520)
        setupTestNotification()
        setupAccessibility()
    }

    // MARK: - Accessibility

    private func setupAccessibility() {
        // Configure view accessibility
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.group)
        view.setAccessibilityLabel("Position Settings")

        // Header and description are not interactive, but provide context
        headerLabel.setAccessibilityElement(false)
        descriptionLabel.setAccessibilityElement(false)

        // Status container should announce changes
        testStatusContainer.setAccessibilityElement(true)
        testStatusContainer.setAccessibilityRole(.staticText)
        testStatusContainer.setAccessibilityLabel("Test notification status")
    }

    // MARK: - Position Handling

    private func handlePositionChange(_ newPosition: NotificationPosition) {
        currentPosition = newPosition
        logger.log("Position changed to: \(newPosition.displayName)")

        // Notify configuration change
        NotificationCenter.default.post(
            name: NSNotification.Name("NotificationPositionDidChange"),
            object: nil,
            userInfo: ["position": newPosition]
        )
    }

    private func setupTestNotification() {
        // Set initial state
        updateTestStatus(.idle)

        // Observe test notification status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTestNotificationStatusChanged(_:)),
            name: NSNotification.Name("TestNotificationStatusChanged"),
            object: nil
        )
    }

    private func updateTestStatus(_ status: TestNotificationStatus) {
        switch status {
        case .idle:
            testStatusContainer?.isHidden = true
            testNotificationButton?.isEnabled = true
        case .checkingPermissions, .sending, .waitingForInterception:
            testStatusContainer?.isHidden = false
            testStatusLabel?.stringValue = status.localizedDescription
            testStatusLabel?.textColor = status.color
            testNotificationButton?.isEnabled = false
            // Announce status for accessibility
            AccessibilityManager.shared.announce(status.localizedDescription)
        case .interceptedSuccessfully, .notIntercepted, .permissionDenied, .permissionError, .sendingFailed, .unknownStatus:
            testStatusContainer?.isHidden = false
            testStatusLabel?.stringValue = status.localizedDescription
            testStatusLabel?.textColor = status.color
            testNotificationButton?.isEnabled = true
            // Announce status for accessibility
            AccessibilityManager.shared.announce(status.localizedDescription)
        }
    }

    // MARK: - Actions

    @IBAction func sendTestNotificationClicked(_ sender: NSButton) {
        testNotificationService.sendTestNotification()
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
            return NSLocalizedString("Test notification intercepted successfully!", comment: "Test status")
        case .notIntercepted:
            return NSLocalizedString("Test notification was not intercepted.", comment: "Test status")
        case .permissionDenied:
            return NSLocalizedString("Notification permission denied.", comment: "Test status")
        case .permissionError(let message):
            return NSLocalizedString("Permission error: \(message)", comment: "Test status")
        case .sendingFailed(let message):
            return NSLocalizedString("Sending failed: \(message)", comment: "Test status")
        case .unknownStatus:
            return NSLocalizedString("Unknown status", comment: "Test status")
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
