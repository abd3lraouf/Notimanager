//
//  InterceptionSettingsViewController.swift
//  Notimanager
//
//  Interception settings pane following Apple HIG standards with Liquid Glass design
//  Allows users to configure what types of notifications to intercept
//

import Cocoa
import Settings
import SwiftUI

final class InterceptionSettingsViewController: NSViewController, SettingsPane {

    // MARK: - SettingsPane Conformance

    let paneIdentifier = Settings.PaneIdentifier.interception
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

    // Notification Types Section
    private var notificationTypesSectionView: NSView!
    private var interceptNotificationsCheckboxRow: LiquidGlassCheckboxRow!
    private var interceptWindowPopupsCheckboxRow: LiquidGlassCheckboxRow!
    private var interceptWidgetsCheckboxRow: LiquidGlassCheckboxRow!

    // Apple Widgets Section (conditionally shown)
    private var appleWidgetsSectionView: NSView?
    private var includeAppleWidgetsCheckboxRow: LiquidGlassCheckboxRow?

    // Test Section
    private var testSectionView: NSView!
    private var testWidgetButton: NSButton!
    private var testStatusLabel: NSTextField!

    // MARK: - Properties

    private let configurationManager: ConfigurationManager
    private let logger: LoggingService
    private let testNotificationService: TestNotificationService

    // MARK: - Lifecycle

    init(
        configurationManager: ConfigurationManager = .shared,
        logger: LoggingService = .shared,
        testNotificationService: TestNotificationService = .shared
    ) {
        self.configurationManager = configurationManager
        self.logger = logger
        self.testNotificationService = testNotificationService
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
        // === Notification Types Section ===
        notificationTypesSectionView = createNotificationTypesSection()
        contentView.addSubview(notificationTypesSectionView)

        // === Apple Widgets Section (conditionally added) ===
        if configurationManager.interceptWidgets {
            createAppleWidgetsSection()
        }

        // === Test Section ===
        testSectionView = createTestSection()
        contentView.addSubview(testSectionView)

        // === Constraints ===
        setupConstraints()
    }

    private func createNotificationTypesSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("Notification Types", comment: "Section header"))
        containerView.addSubview(header)

        let contentContainer = NSView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentContainer)

        // Intercept Normal Notifications
        interceptNotificationsCheckboxRow = LiquidGlassCheckboxRow(
            title: NSLocalizedString("Normal notifications", comment: "Checkbox label"),
            description: NSLocalizedString("Intercept standard system notification banners and alerts from apps like Calendar, Mail, and Messages", comment: "Description text"),
            initialState: .off,
            action: #selector(interceptNotificationsClicked(_:)),
            target: self
        )
        interceptNotificationsCheckboxRow.checkboxButton.setAccessibilityIdentifier("interceptNotificationsCheckbox")
        interceptNotificationsCheckboxRow.checkboxButton.setAccessibilityRole(.checkbox)
        interceptNotificationsCheckboxRow.checkboxButton.setAccessibilityHelp("When enabled, Notimanager will intercept and reposition standard system notifications from apps like Calendar, Mail, and Messages.")
        contentContainer.addSubview(interceptNotificationsCheckboxRow)

        // Add separator
        let separator1 = LiquidGlassSeparator()
        separator1.setAccessibilityRole(.separator)
        contentContainer.addSubview(separator1)

        // Intercept Window Popups
        interceptWindowPopupsCheckboxRow = LiquidGlassCheckboxRow(
            title: NSLocalizedString("Window popups", comment: "Checkbox label"),
            description: NSLocalizedString("Intercept floating window notifications and system dialogs", comment: "Description text"),
            initialState: .off,
            action: #selector(interceptWindowPopupsClicked(_:)),
            target: self
        )
        interceptWindowPopupsCheckboxRow.checkboxButton.setAccessibilityIdentifier("interceptWindowPopupsCheckbox")
        interceptWindowPopupsCheckboxRow.checkboxButton.setAccessibilityRole(.checkbox)
        interceptWindowPopupsCheckboxRow.checkboxButton.setAccessibilityHelp("When enabled, Notimanager will intercept floating windows and dialog boxes that appear as notifications.")
        contentContainer.addSubview(interceptWindowPopupsCheckboxRow)

        // Add separator
        let separator2 = LiquidGlassSeparator()
        separator2.setAccessibilityRole(.separator)
        contentContainer.addSubview(separator2)

        // Intercept Widgets
        interceptWidgetsCheckboxRow = LiquidGlassCheckboxRow(
            title: NSLocalizedString("Widgets", comment: "Checkbox label"),
            description: NSLocalizedString("Intercept Notification Center and interactive widgets. Enable this to reposition widget updates.", comment: "Description text"),
            initialState: .off,
            action: #selector(interceptWidgetsClicked(_:)),
            target: self
        )
        interceptWidgetsCheckboxRow.checkboxButton.setAccessibilityIdentifier("interceptWidgetsCheckbox")
        interceptWidgetsCheckboxRow.checkboxButton.setAccessibilityRole(.checkbox)
        interceptWidgetsCheckboxRow.checkboxButton.setAccessibilityHelp("When enabled, Notimanager will intercept and reposition widget updates from Notification Center and interactive widgets.")
        contentContainer.addSubview(interceptWidgetsCheckboxRow)

        // Setup constraints for content
        NSLayoutConstraint.activate([
            interceptNotificationsCheckboxRow.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            interceptNotificationsCheckboxRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            interceptNotificationsCheckboxRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            separator1.topAnchor.constraint(equalTo: interceptNotificationsCheckboxRow.bottomAnchor, constant: Spacing.pt24),
            separator1.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            separator1.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            interceptWindowPopupsCheckboxRow.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: Spacing.pt24),
            interceptWindowPopupsCheckboxRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            interceptWindowPopupsCheckboxRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            separator2.topAnchor.constraint(equalTo: interceptWindowPopupsCheckboxRow.bottomAnchor, constant: Spacing.pt24),
            separator2.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            separator2.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            interceptWidgetsCheckboxRow.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: Spacing.pt24),
            interceptWidgetsCheckboxRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            interceptWidgetsCheckboxRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            interceptWidgetsCheckboxRow.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
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

    private func createAppleWidgetsSection() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.appleWidgetsSectionView = containerView

        let header = SettingsSectionHeader(title: NSLocalizedString("Apple Widgets", comment: "Section header"))
        containerView.addSubview(header)

        let contentContainer = NSView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentContainer)

        // Include Apple Widgets
        includeAppleWidgetsCheckboxRow = LiquidGlassCheckboxRow(
            title: NSLocalizedString("Include Apple widgets", comment: "Checkbox label"),
            description: NSLocalizedString("Also intercept built-in Apple widgets when widget interception is enabled", comment: "Description text"),
            initialState: .off,
            action: #selector(includeAppleWidgetsClicked(_:)),
            target: self
        )
        includeAppleWidgetsCheckboxRow!.checkboxButton.setAccessibilityIdentifier("includeAppleWidgetsCheckbox")
        includeAppleWidgetsCheckboxRow!.checkboxButton.setAccessibilityRole(.checkbox)
        includeAppleWidgetsCheckboxRow!.checkboxButton.setAccessibilityHelp("When enabled, Notimanager will also intercept and reposition built-in Apple widgets alongside third-party widgets.")
        contentContainer.addSubview(includeAppleWidgetsCheckboxRow!)

        // Setup constraints for content
        NSLayoutConstraint.activate([
            includeAppleWidgetsCheckboxRow!.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            includeAppleWidgetsCheckboxRow!.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            includeAppleWidgetsCheckboxRow!.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            includeAppleWidgetsCheckboxRow!.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
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

        contentView.addSubview(containerView)
    }

    private func createTestSection() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let header = SettingsSectionHeader(title: NSLocalizedString("Test", comment: "Section header"))
        containerView.addSubview(header)

        let contentContainer = NSView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentContainer)

        // Test button with modern styling
        testWidgetButton = NSButton()
        testWidgetButton.title = NSLocalizedString("Send Widget Test Notification", comment: "Button label")
        testWidgetButton.target = self
        testWidgetButton.action = #selector(testWidgetButtonClicked(_:))
        testWidgetButton.translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 10.14, *) {
            testWidgetButton.bezelStyle = .rounded
            testWidgetButton.keyEquivalent = ""
        } else {
            testWidgetButton.bezelStyle = .rounded
        }

        testWidgetButton.font = Typography.body
        testWidgetButton.sizeToFit()

        // Accessibility
        testWidgetButton.setAccessibilityTitle(NSLocalizedString("Send Widget Test Notification", comment: "Button accessibility title"))
        testWidgetButton.setAccessibilityHelp(NSLocalizedString("Sends a test notification styled like a widget update", comment: "Button accessibility help"))

        contentContainer.addSubview(testWidgetButton)

        // Status label for feedback
        testStatusLabel = NSTextField(labelWithString: NSLocalizedString("Ready to test", comment: "Status label"))
        testStatusLabel.font = Typography.caption1
        testStatusLabel.textColor = Colors.secondaryLabel
        testStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        testStatusLabel.setAccessibilityRole(.staticText)
        contentContainer.addSubview(testStatusLabel)

        // Setup constraints for content
        NSLayoutConstraint.activate([
            testWidgetButton.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            testWidgetButton.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            testWidgetButton.trailingAnchor.constraint(lessThanOrEqualTo: contentContainer.trailingAnchor),
            testWidgetButton.heightAnchor.constraint(equalToConstant: Layout.regularButtonHeight),

            testStatusLabel.topAnchor.constraint(equalTo: testWidgetButton.bottomAnchor, constant: Spacing.pt12),
            testStatusLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            testStatusLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            testStatusLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
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

    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = []

        // Content view width constraint (minimum width for proper layout)
        constraints += [
            contentView.widthAnchor.constraint(equalToConstant: Layout.settingsWindowWidth),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 500)
        ]

        // Notification Types Section
        constraints += [
            notificationTypesSectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.pt24),
            notificationTypesSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            notificationTypesSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ]

        // Build constraint chain for middle sections
        var previousSection: NSView = notificationTypesSectionView

        // Apple Widgets Section (if exists)
        if let appleWidgetsSection = appleWidgetsSectionView {
            constraints += [
                appleWidgetsSection.topAnchor.constraint(equalTo: previousSection.bottomAnchor, constant: Spacing.pt32),
                appleWidgetsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                appleWidgetsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ]
            previousSection = appleWidgetsSection
        }

        // Test Section
        constraints += [
            testSectionView.topAnchor.constraint(equalTo: previousSection.bottomAnchor, constant: Spacing.pt32),
            testSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            testSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            testSectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.pt32)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: Layout.settingsWindowWidth, height: 500)
        populateSettings()
    }

    // MARK: - Populate Settings

    private func populateSettings() {
        // Intercept notifications
        let shouldInterceptNotifications = configurationManager.interceptNotifications
        interceptNotificationsCheckboxRow.checkboxButton.state = shouldInterceptNotifications ? .on : .off

        // Intercept window popups
        let shouldInterceptWindowPopups = configurationManager.interceptWindowPopups
        interceptWindowPopupsCheckboxRow.checkboxButton.state = shouldInterceptWindowPopups ? .on : .off

        // Intercept widgets
        let shouldInterceptWidgets = configurationManager.interceptWidgets
        interceptWidgetsCheckboxRow.checkboxButton.state = shouldInterceptWidgets ? .on : .off

        // Include Apple widgets (conditionally)
        if let checkboxRow = includeAppleWidgetsCheckboxRow {
            let shouldIncludeAppleWidgets = configurationManager.includeAppleWidgets
            checkboxRow.checkboxButton.state = shouldIncludeAppleWidgets ? .on : .off
        }
    }

    // MARK: - Actions

    @objc func interceptNotificationsClicked(_ sender: NSButton) {
        let shouldIntercept = sender.state == .on
        configurationManager.interceptNotifications = shouldIntercept
        logger.log("Normal notification interception \(shouldIntercept ? "enabled" : "disabled")")
        AccessibilityManager.shared.announce("Normal notification interception \(shouldIntercept ? "enabled" : "disabled")")
    }

    @objc func interceptWindowPopupsClicked(_ sender: NSButton) {
        let shouldIntercept = sender.state == .on
        configurationManager.interceptWindowPopups = shouldIntercept
        logger.log("Window popup interception \(shouldIntercept ? "enabled" : "disabled")")
        AccessibilityManager.shared.announce("Window popup interception \(shouldIntercept ? "enabled" : "disabled")")
    }

    @objc func interceptWidgetsClicked(_ sender: NSButton) {
        let shouldIntercept = sender.state == .on
        configurationManager.interceptWidgets = shouldIntercept
        logger.log("Widget interception \(shouldIntercept ? "enabled" : "disabled")")

        // Show or hide Apple Widgets section based on widget interception state
        // Animate the transition with smooth spring physics
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true

            if shouldIntercept {
                if appleWidgetsSectionView == nil {
                    createAppleWidgetsSection()
                    setupConstraints()

                    // Populate the new checkbox
                    if let checkboxRow = includeAppleWidgetsCheckboxRow {
                        let shouldIncludeAppleWidgets = configurationManager.includeAppleWidgets
                        checkboxRow.checkboxButton.state = shouldIncludeAppleWidgets ? .on : .off
                    }
                }
                appleWidgetsSectionView?.isHidden = false
                appleWidgetsSectionView?.alphaValue = 0
                appleWidgetsSectionView?.alphaValue = 1.0
            } else {
                appleWidgetsSectionView?.alphaValue = 0
                appleWidgetsSectionView?.isHidden = true
            }
        }

        AccessibilityManager.shared.announce("Widget interception \(shouldIntercept ? "enabled" : "disabled")")
    }

    @objc func includeAppleWidgetsClicked(_ sender: NSButton) {
        let shouldInclude = sender.state == .on
        configurationManager.includeAppleWidgets = shouldInclude
        logger.log("Apple widgets inclusion \(shouldInclude ? "enabled" : "disabled")")

        // Provide additional context for this setting
        if shouldInclude {
            AccessibilityManager.shared.announce("Apple widgets will now be intercepted along with third-party widgets")
        } else {
            AccessibilityManager.shared.announce("Only third-party widgets will be intercepted")
        }
    }

    @objc func testWidgetButtonClicked(_ sender: NSButton) {
        logger.log("Sending widget test notification")

        // Disable button during test
        testWidgetButton.isEnabled = false
        testStatusLabel.stringValue = NSLocalizedString("Sending test notification...", comment: "Status message")
        testStatusLabel.textColor = .systemOrange

        // Send widget test notification
        testNotificationService.sendWidgetTestNotification(to: configurationManager.currentPosition)

        // Re-enable button after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.testWidgetButton.isEnabled = true
            self?.testStatusLabel.stringValue = NSLocalizedString("Test notification sent! Check for notification.", comment: "Status message")
            self?.testStatusLabel.textColor = .systemGreen

            // Reset status after additional delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                self?.testStatusLabel.stringValue = NSLocalizedString("Ready to test", comment: "Status label")
                self?.testStatusLabel.textColor = Colors.secondaryLabel
            }
        }

        // Announce for accessibility
        AccessibilityManager.shared.announce("Sending widget test notification to \(configurationManager.currentPosition.displayName)")
    }
}
