//
//  PositionSettingsViewController.swift
//  Notimanager
//
//  Position settings pane with Liquid Glass design and improved UX
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

    private var scrollView: NSScrollView!
    private var contentView: NSView!
    private var headerLabel: NSTextField!
    private var descriptionLabel: NSTextField!
    private var positionGridContainer: LiquidGlassContainer!
    private var positionGridView: PositionGridView!
    private var testSeparator: LiquidGlassSeparator!
    private var testNotificationButton: NSButton!
    private var testStatusLabel: NSTextField!
    private var testStatusContainer: LiquidGlassContainer!

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
        // Section Header
        let header = NSTextField(labelWithString: NSLocalizedString("Notification Position", comment: "Position settings header"))
        header.font = Typography.title2
        header.textColor = Colors.label
        header.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(header)
        self.headerLabel = header

        // Section Description
        let description = NSTextField(wrappingLabelWithString: NSLocalizedString(
            "Choose where notifications should appear on your screen. Select a position below to change it.",
            comment: "Position settings description"
        ))
        description.font = Typography.body
        description.textColor = Colors.secondaryLabel
        description.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(description)
        self.descriptionLabel = description

        // Position Grid Container with Liquid Glass effect
        let gridGlassConfig = LiquidGlassMaterial(
            material: .titlebar,
            shadowIntensity: .medium,
            borderLuminance: 0.25,
            cornerRadius: Layout.cardCornerRadius
        )
        positionGridContainer = LiquidGlassContainer(material: gridGlassConfig)
        positionGridContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(positionGridContainer)

        // Position Grid View
        let gridView = PositionGridView(selection: currentPosition) { [weak self] newPosition in
            self?.handlePositionChange(newPosition)
        }
        gridView.translatesAutoresizingMaskIntoConstraints = false
        positionGridContainer.addSubview(gridView)
        self.positionGridView = gridView

        // Test Notification Section Separator
        testSeparator = LiquidGlassSeparator()
        testSeparator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(testSeparator)

        // Test Notification Button
        let testBtn = NSButton(
            title: NSLocalizedString("Send Test Notification", comment: "Test button title"),
            target: self,
            action: #selector(sendTestNotificationClicked(_:))
        )
        testBtn.bezelStyle = .rounded
        testBtn.translatesAutoresizingMaskIntoConstraints = false

        // Improved accessibility for test button
        testBtn.setAccessibilityTitle(NSLocalizedString("Send Test Notification", comment: "Test button title"))
        testBtn.setAccessibilityHelp(NSLocalizedString("Sends a test notification to verify interception is working", comment: "Accessibility help"))

        contentView.addSubview(testBtn)
        self.testNotificationButton = testBtn

        // Test Status Container with Liquid Glass effect
        let statusGlassConfig = LiquidGlassMaterial(
            material: .contentBackground,
            shadowIntensity: .subtle,
            borderLuminance: 0.15,
            cornerRadius: Layout.mediumCornerRadius
        )
        testStatusContainer = LiquidGlassContainer(material: statusGlassConfig)
        testStatusContainer.translatesAutoresizingMaskIntoConstraints = false
        testStatusContainer.isHidden = true
        contentView.addSubview(testStatusContainer)

        // Test Status Label
        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = Typography.callout
        statusLabel.textColor = Colors.secondaryLabel
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        testStatusContainer.addSubview(statusLabel)
        self.testStatusLabel = statusLabel

        // Setup constraints
        setupConstraints()

        // Configure grid container size
        NSLayoutConstraint.activate([
            gridView.centerXAnchor.constraint(equalTo: positionGridContainer.centerXAnchor),
            gridView.centerYAnchor.constraint(equalTo: positionGridContainer.centerYAnchor),
            positionGridContainer.widthAnchor.constraint(equalToConstant: Layout.gridSize * 2 + Layout.gridSpacing + Spacing.pt32),
            positionGridContainer.heightAnchor.constraint(equalToConstant: Layout.gridSize * 2 + Layout.gridSpacing + Spacing.pt32)
        ])
    }

    private func setupConstraints() {
        let leadingMargin: CGFloat = Spacing.pt32
        let trailingMargin: CGFloat = Spacing.pt32

        NSLayoutConstraint.activate([
            // Content view width constraint
            contentView.widthAnchor.constraint(equalToConstant: Layout.settingsWindowWidth),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 500),

            // Header
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.pt32),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingMargin),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -trailingMargin),

            // Description
            descriptionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: Spacing.pt8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingMargin),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -trailingMargin),

            // Grid Container - centered
            positionGridContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: Spacing.pt24),
            positionGridContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Separator
            testSeparator.topAnchor.constraint(equalTo: positionGridContainer.bottomAnchor, constant: Spacing.pt32),
            testSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingMargin),
            testSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -trailingMargin),

            // Test Button
            testNotificationButton.topAnchor.constraint(equalTo: testSeparator.bottomAnchor, constant: Spacing.pt20),
            testNotificationButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            testNotificationButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),

            // Status Container
            testStatusContainer.topAnchor.constraint(equalTo: testNotificationButton.bottomAnchor, constant: Spacing.pt12),
            testStatusContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingMargin),
            testStatusContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -trailingMargin),
            testStatusContainer.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Spacing.pt32),

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

        // Position grid should be accessible
        positionGridView.setAccessibilityLabel("Notification position grid")

        // Status container should announce changes
        testStatusContainer.setAccessibilityElement(true)
        testStatusContainer.setAccessibilityRole(.staticText)
        testStatusContainer.setAccessibilityLabel("Test notification status")
    }

    // MARK: - Position Handling

    private func handlePositionChange(_ newPosition: NotificationPosition) {
        currentPosition = newPosition
        logger.log("Position changed to: \(newPosition.displayName)")

        // Announce change for accessibility
        AccessibilityManager.shared.announce("Notification position changed to \(newPosition.displayName)")

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
