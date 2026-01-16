//
//  PermissionViewController.swift
//  Notimanager
//
//  Accessibility permission screen following Apple's Human Interface Guidelines.
//  Provides clear, focused UX with proper information hierarchy and isolation.
//

import Cocoa

/// Permission View Controller for Accessibility permissions
/// Follows Apple's HIG for permission requests with clear value proposition
final class PermissionViewController: NSViewController {

    // MARK: - Types

    private enum PermissionState {
        case notDetermined
        case denied
        case granted
    }

    // MARK: - Properties

    private let viewModel: PermissionViewModel
    private var window: NSWindow?
    private var permissionPollingTimer: Timer?
    private var currentState: PermissionState = .notDetermined

    // UI Components
    private var scrollView: NSScrollView!
    private var contentView: NSView!

    private var iconContainerView: NSView!
    private var iconView: NSImageView!

    private var titleLabel: NSTextField!
    private var descriptionLabel: NSTextField!

    private var permissionExplanationView: NSView!
    private var explanationIconView: NSImageView!
    private var explanationLabel: NSTextField!

    private var featureListView: NSView!
    private var featureStackView: NSStackView!

    private var statusContainerView: NSVisualEffectView!
    private var statusIconView: NSImageView!
    private var statusTitleLabel: NSTextField!
    private var statusMessageLabel: NSTextField!

    private var actionButton: NSButton!
    private var quitButton: NSButton!

    // MARK: - Initialization

    init(viewModel: PermissionViewModel = PermissionViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupViewModelBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updatePermissionState()
        startPermissionPolling()
    }

    deinit {
        permissionPollingTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupViewModelBindings() {
        viewModel.onPermissionStatusChanged = { [weak self] _ in
            self?.updatePermissionState()
        }

        viewModel.onPermissionRequested = { [weak self] in
            self?.showWaitingState()
        }
    }

    private func setupUI() {
        // Use scroll view for content that may exceed screen height
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .noBorder
        view.addSubview(scrollView)

        contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView

        // Build the permission screen
        setupIconSection()
        setupTitleSection()
        setupDescriptionSection()
        setupPermissionExplanationSection()
        setupFeatureListSection()
        setupStatusSection()
        setupActionButtonsSection()

        setupConstraints()
    }

    private func setupIconSection() {
        iconContainerView = NSView()
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconContainerView)

        iconContainerView.wantsLayer = true

        // Create gradient background for icon
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 96, height: 96)
        gradientLayer.colors = [
            NSColor.controlBackgroundColor.withAlphaComponent(0.8).cgColor,
            NSColor.controlBackgroundColor.withAlphaComponent(0.6).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = 22
        iconContainerView.layer = gradientLayer

        // Add subtle shadow
        iconContainerView.layer?.shadowColor = NSColor.black.withAlphaComponent(0.1).cgColor
        iconContainerView.layer?.shadowOffset = NSSize(width: 0, height: -2)
        iconContainerView.layer?.shadowRadius = 8
        iconContainerView.layer?.shadowOpacity = 1.0

        iconView = NSImageView()
        iconView.image = NSImage(named: "AppIcon")
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.addSubview(iconView)
    }

    private func setupTitleSection() {
        titleLabel = NSTextField(labelWithString: "Accessibility Permission")
        titleLabel.font = NSFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.alignment = .center
        titleLabel.textColor = Colors.label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
    }

    private func setupDescriptionSection() {
        descriptionLabel = NSTextField(wrappingLabelWithString: "Notimanager needs accessibility permission to reposition your notifications on screen.")
        descriptionLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.alignment = .center
        descriptionLabel.textColor = Colors.secondaryLabel
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(descriptionLabel)
    }

    private func setupPermissionExplanationSection() {
        permissionExplanationView = NSView()
        permissionExplanationView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(permissionExplanationView)

        // Explanation icon
        explanationIconView = NSImageView()
        if #available(macOS 11.0, *) {
            explanationIconView.image = NSImage(systemSymbolName: "info.circle.fill", accessibilityDescription: "Info")
        }
        explanationIconView.contentTintColor = Colors.info
        explanationIconView.imageScaling = .scaleProportionallyUpOrDown
        explanationIconView.translatesAutoresizingMaskIntoConstraints = false
        permissionExplanationView.addSubview(explanationIconView)

        // Explanation text
        explanationLabel = NSTextField(wrappingLabelWithString: "Accessibility is a macOS feature that lets apps move UI elements on your screen. Notimanager uses this to reposition your notifications.")
        explanationLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        explanationLabel.textColor = Colors.secondaryLabel
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false
        permissionExplanationView.addSubview(explanationLabel)

        NSLayoutConstraint.activate([
            explanationIconView.topAnchor.constraint(equalTo: permissionExplanationView.topAnchor),
            explanationIconView.leadingAnchor.constraint(equalTo: permissionExplanationView.leadingAnchor),
            explanationIconView.widthAnchor.constraint(equalToConstant: 16),
            explanationIconView.heightAnchor.constraint(equalToConstant: 16),

            explanationLabel.topAnchor.constraint(equalTo: permissionExplanationView.topAnchor, constant: 2),
            explanationLabel.leadingAnchor.constraint(equalTo: explanationIconView.trailingAnchor, constant: 8),
            explanationLabel.trailingAnchor.constraint(equalTo: permissionExplanationView.trailingAnchor),
            explanationLabel.bottomAnchor.constraint(equalTo: permissionExplanationView.bottomAnchor, constant: -2)
        ])
    }

    private func setupFeatureListSection() {
        featureListView = NSView()
        featureListView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(featureListView)

        let featureTitle = NSTextField(labelWithString: "What you'll be able to do:")
        featureTitle.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        featureTitle.textColor = Colors.label
        featureTitle.translatesAutoresizingMaskIntoConstraints = false
        featureListView.addSubview(featureTitle)

        featureStackView = NSStackView()
        featureStackView.orientation = .vertical
        featureStackView.spacing = 8
        featureStackView.translatesAutoresizingMaskIntoConstraints = false
        featureListView.addSubview(featureStackView)

        // Add feature items
        let features = [
            ("Move notifications to any corner of your screen", "arrow.up.left.and.arrow.down.right"),
            ("Keep notifications organized and out of the way", "rectangle.3.group"),
            ("Customize notification positioning", "slider.horizontal.3")
        ]

        for feature in features {
            let featureItem = createFeatureItem(title: feature.0, iconName: feature.1)
            featureStackView.addArrangedSubview(featureItem)
        }

        NSLayoutConstraint.activate([
            featureTitle.topAnchor.constraint(equalTo: featureListView.topAnchor),
            featureTitle.leadingAnchor.constraint(equalTo: featureListView.leadingAnchor),
            featureTitle.trailingAnchor.constraint(equalTo: featureListView.trailingAnchor),

            featureStackView.topAnchor.constraint(equalTo: featureTitle.bottomAnchor, constant: 12),
            featureStackView.leadingAnchor.constraint(equalTo: featureListView.leadingAnchor),
            featureStackView.trailingAnchor.constraint(equalTo: featureListView.trailingAnchor),
            featureStackView.bottomAnchor.constraint(equalTo: featureListView.bottomAnchor)
        ])
    }

    private func createFeatureItem(title: String, iconName: String) -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let iconView = NSImageView()
        if #available(macOS 11.0, *) {
            iconView.image = NSImage(systemSymbolName: iconName, accessibilityDescription: title)
        }
        iconView.contentTintColor = Colors.accent
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconView)

        let label = NSTextField(wrappingLabelWithString: title)
        label.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = Colors.label
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 1),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -1)
        ])

        return containerView
    }

    private func setupStatusSection() {
        statusContainerView = NSVisualEffectView()
        statusContainerView.material = .contentBackground
        statusContainerView.state = .active
        statusContainerView.wantsLayer = true
        statusContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusContainerView)

        // Configure appearance
        statusContainerView.layer?.cornerRadius = 10
        statusContainerView.layer?.borderWidth = 0.5
        statusContainerView.layer?.borderColor = Colors.separator.cgColor

        statusIconView = NSImageView()
        statusIconView.imageScaling = .scaleProportionallyUpOrDown
        statusIconView.translatesAutoresizingMaskIntoConstraints = false
        statusContainerView.addSubview(statusIconView)

        statusTitleLabel = NSTextField(labelWithString: "")
        statusTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        statusTitleLabel.textColor = Colors.label
        statusTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainerView.addSubview(statusTitleLabel)

        statusMessageLabel = NSTextField(wrappingLabelWithString: "")
        statusMessageLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        statusMessageLabel.textColor = Colors.secondaryLabel
        statusMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainerView.addSubview(statusMessageLabel)

        NSLayoutConstraint.activate([
            statusIconView.topAnchor.constraint(equalTo: statusContainerView.topAnchor, constant: 12),
            statusIconView.leadingAnchor.constraint(equalTo: statusContainerView.leadingAnchor, constant: 12),
            statusIconView.widthAnchor.constraint(equalToConstant: 24),
            statusIconView.heightAnchor.constraint(equalToConstant: 24),

            statusTitleLabel.topAnchor.constraint(equalTo: statusContainerView.topAnchor, constant: 12),
            statusTitleLabel.leadingAnchor.constraint(equalTo: statusIconView.trailingAnchor, constant: 10),
            statusTitleLabel.trailingAnchor.constraint(equalTo: statusContainerView.trailingAnchor, constant: -12),

            statusMessageLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 4),
            statusMessageLabel.leadingAnchor.constraint(equalTo: statusTitleLabel.leadingAnchor),
            statusMessageLabel.trailingAnchor.constraint(equalTo: statusTitleLabel.trailingAnchor),
            statusMessageLabel.bottomAnchor.constraint(equalTo: statusContainerView.bottomAnchor, constant: -12)
        ])
    }

    private func setupActionButtonsSection() {
        actionButton = NSButton()
        actionButton.bezelStyle = .rounded
        actionButton.controlSize = .large
        actionButton.keyEquivalent = "\r"
        actionButton.target = self
        actionButton.action = #selector(actionButtonClicked)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionButton)

        quitButton = NSButton()
        quitButton.title = "Quit Notimanager"
        quitButton.bezelStyle = .rounded
        quitButton.controlSize = .regular
        quitButton.target = self
        quitButton.action = #selector(quitButtonClicked)
        quitButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(quitButton)
    }

    private func setupConstraints() {
        let width: CGFloat = 480

        NSLayoutConstraint.activate([
            // Scroll view fills the view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content view width
            contentView.widthAnchor.constraint(equalToConstant: width),

            // Center content horizontally
            contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),

            // Icon section
            iconContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            iconContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 96),
            iconContainerView.heightAnchor.constraint(equalToConstant: 96),

            iconView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),

            // Title
            titleLabel.topAnchor.constraint(equalTo: iconContainerView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            // Description
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 48),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -48),

            // Permission explanation
            permissionExplanationView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            permissionExplanationView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 48),
            permissionExplanationView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -48),

            // Feature list
            featureListView.topAnchor.constraint(equalTo: permissionExplanationView.bottomAnchor, constant: 20),
            featureListView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 48),
            featureListView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -48),

            // Status section
            statusContainerView.topAnchor.constraint(equalTo: featureListView.bottomAnchor, constant: 24),
            statusContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            statusContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            statusContainerView.heightAnchor.constraint(equalToConstant: 72),

            // Action button
            actionButton.topAnchor.constraint(equalTo: statusContainerView.bottomAnchor, constant: 24),
            actionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 200),

            // Quit button
            quitButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 8),
            quitButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            quitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Actions

    @objc private func actionButtonClicked() {
        switch currentState {
        case .notDetermined, .denied:
            requestPermission()
        case .granted:
            restartApp()
        }
    }

    @objc private func quitButtonClicked() {
        NSApp.terminate(nil)
    }

    private func requestPermission() {
        viewModel.requestAccessibilityPermission()
    }

    private func restartApp() {
        viewModel.restartApp()
        window?.close()
    }

    // MARK: - State Management

    private func updatePermissionState() {
        let isGranted = viewModel.isAccessibilityGranted

        let newState: PermissionState = isGranted ? .granted : .denied
        guard newState != currentState else { return }

        currentState = newState

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.normal
            context.timingFunction = Animation.easeOut

            switch currentState {
            case .notDetermined:
                updateToNotDeterminedState()
            case .denied:
                updateToDeniedState()
            case .granted:
                updateToGrantedState()
            }
        }
    }

    private func updateToNotDeterminedState() {
        statusContainerView.layer?.borderColor = Colors.separator.cgColor
        statusContainerView.material = .contentBackground

        if #available(macOS 11.0, *) {
            statusIconView.image = NSImage(systemSymbolName: "exclamationmark.circle.fill", accessibilityDescription: "Required")
        } else {
            statusIconView.image = NSImage(named: NSImage.cautionName)
        }
        statusIconView.contentTintColor = Colors.warning

        statusTitleLabel.stringValue = "Permission Required"
        statusTitleLabel.textColor = Colors.label

        statusMessageLabel.stringValue = "Click below to open System Settings and grant accessibility permission."

        actionButton.title = "Open System Settings…"
        actionButton.isEnabled = true
        actionButton.keyEquivalent = "\r"

        quitButton.isHidden = false
    }

    private func updateToDeniedState() {
        statusContainerView.layer?.borderColor = Colors.error.withAlphaComponent(0.3).cgColor
        statusContainerView.material = .contentBackground

        if #available(macOS 11.0, *) {
            statusIconView.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Denied")
        } else {
            statusIconView.image = NSImage(named: NSImage.stopProgressTemplateName)
        }
        statusIconView.contentTintColor = Colors.error

        statusTitleLabel.stringValue = "Permission Denied"
        statusTitleLabel.textColor = Colors.error

        statusMessageLabel.stringValue = "Accessibility permission was denied. You can enable it in System Settings."

        actionButton.title = "Open System Settings…"
        actionButton.isEnabled = true
        actionButton.keyEquivalent = "\r"

        quitButton.isHidden = false
    }

    private func updateToGrantedState() {
        statusContainerView.layer?.borderColor = Colors.success.withAlphaComponent(0.3).cgColor
        statusContainerView.material = .contentBackground

        if #available(macOS 11.0, *) {
            statusIconView.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Granted")
        } else {
            statusIconView.image = NSImage(named: "NSApplicationIcon")
        }
        statusIconView.contentTintColor = Colors.success

        statusTitleLabel.stringValue = "Permission Granted"
        statusTitleLabel.textColor = Colors.success

        statusMessageLabel.stringValue = "Accessibility permission has been granted. Restart Notimanager to begin using it."

        actionButton.title = "Restart Notimanager"
        actionButton.isEnabled = true
        actionButton.keyEquivalent = "\r"

        quitButton.isHidden = true
    }

    private func showWaitingState() {
        statusTitleLabel.stringValue = "Opening System Settings…"
        statusTitleLabel.textColor = Colors.secondaryLabel

        statusMessageLabel.stringValue = "Grant accessibility permission, then return to this window."

        actionButton.title = "Waiting…"
        actionButton.isEnabled = false
        actionButton.keyEquivalent = ""
    }

    private func startPermissionPolling() {
        permissionPollingTimer?.invalidate()

        permissionPollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let isGranted = self.viewModel.isAccessibilityGranted

            if isGranted && self.currentState != .granted {
                self.viewModel.updatePermissionStatus(granted: true)
                self.permissionPollingTimer?.invalidate()
            }
        }
    }

    // MARK: - Window Management

    func showInWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 620),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Notimanager"
        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = true
        window.delegate = self

        window.contentView = view
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSWindowDelegate

extension PermissionViewController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // If permission is granted, close and restart. Otherwise, just order out.
        if currentState == .granted {
            return true
        } else {
            sender.orderOut(nil)
            return false
        }
    }
}

// MARK: - Previews

#if DEBUG

import SwiftUI

@available(macOS 11.0, *)
struct PermissionViewController_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            PermissionViewControllerRepresentable()
                .previewDisplayName("Permission Required")
                .frame(width: 480, height: 620)
                .preferredColorScheme(.light)

            PermissionViewControllerRepresentable()
                .previewDisplayName("Dark Mode")
                .frame(width: 480, height: 620)
                .preferredColorScheme(.dark)
        }
    }
}

@available(macOS 11.0, *)
private struct PermissionViewControllerRepresentable: NSViewControllerRepresentable {

    func makeNSViewController(context: Context) -> NSViewController {
        return PermissionViewController()
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        // No updates needed
    }
}

#endif
