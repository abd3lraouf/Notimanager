//
//  AboutSettingsViewController.swift
//  Notimanager
//
//  About settings pane with semantic typography and improved accessibility
//

import Cocoa
import Settings

final class AboutSettingsViewController: NSViewController, SettingsPane {

    // MARK: - SettingsPane Conformance

    let paneIdentifier = Settings.PaneIdentifier.about
    let paneTitle = NSLocalizedString("About", comment: "Settings pane title")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")!
        } else {
            return NSImage(named: NSImage.infoName)!
        }
    }

    // MARK: - Properties

    private let viewModel = AboutViewModel()

    // MARK: - UI Components

    private var iconView: NSImageView!
    private var appNameLabel: NSTextField!
    private var versionLabel: NSTextField!
    private var copyrightLabel: NSTextField!
    private var creditLabel: NSTextField!
    private var linkButton: NSButton!

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateInfo()
        setupAccessibility()
        preferredContentSize = NSSize(width: Layout.settingsWindowWidth, height: 300)
    }

    // MARK: - Setup

    private func setupUI() {
        // Main container using Auto Layout
        let contentStack = createContentStack()
        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.pt40),
            contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStack.widthAnchor.constraint(equalToConstant: 280)
        ])
    }

    private func createContentStack() -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // App Icon - standard 64pt size
        iconView = NSImageView()
        iconView.image = NSImage(named: "AppIcon")
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.wantsLayer = true
        iconView.layer?.cornerRadius = Layout.mediumCornerRadius
        iconView.layer?.masksToBounds = true
        containerView.addSubview(iconView)

        // App Name - using semantic typography
        appNameLabel = NSTextField(labelWithString: "")
        appNameLabel.font = Typography.title2
        appNameLabel.alignment = .center
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(appNameLabel)

        // Version - using semantic typography
        versionLabel = NSTextField(labelWithString: "")
        versionLabel.font = Typography.body
        versionLabel.alignment = .center
        versionLabel.textColor = Colors.secondaryLabel
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(versionLabel)

        // Divider line
        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = Colors.separator.cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(divider)

        // Copyright - using semantic typography
        copyrightLabel = NSTextField(labelWithString: "")
        copyrightLabel.font = Typography.caption2
        copyrightLabel.alignment = .center
        copyrightLabel.textColor = Colors.tertiaryLabel
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(copyrightLabel)

        // Credits - using semantic typography
        creditLabel = NSTextField(labelWithString: "")
        creditLabel.font = Typography.caption2
        creditLabel.alignment = .center
        creditLabel.textColor = Colors.tertiaryLabel
        creditLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(creditLabel)

        // Link button
        linkButton = NSButton()
        linkButton.title = ""
        linkButton.bezelStyle = .regularSquare
        linkButton.isBordered = false
        linkButton.focusRingType = .none
        linkButton.target = self
        linkButton.action = #selector(openLink)
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(linkButton)

        // Setup button styling
        setupLinkButton()

        NSLayoutConstraint.activate([
            // Icon - 64pt standard size
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),

            // App name
            appNameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: Spacing.pt12),
            appNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            appNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            // Version
            versionLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: Spacing.pt4),
            versionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            versionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            // Divider
            divider.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: Spacing.pt16),
            divider.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            divider.widthAnchor.constraint(equalToConstant: 200),
            divider.heightAnchor.constraint(equalToConstant: Border.thin),

            // Copyright
            copyrightLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: Spacing.pt16),
            copyrightLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt8),
            copyrightLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt8),

            // Credits
            creditLabel.topAnchor.constraint(equalTo: copyrightLabel.bottomAnchor, constant: Spacing.pt4),
            creditLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt8),
            creditLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt8),

            // Link button
            linkButton.topAnchor.constraint(equalTo: creditLabel.bottomAnchor, constant: Spacing.pt8),
            linkButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            linkButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    private func setupLinkButton() {
        let username = viewModel.githubUsername
        linkButton.title = username

        let attributedTitle = NSAttributedString(
            string: username,
            attributes: [
                .foregroundColor: NSColor.linkColor,
                .font: Typography.caption2,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .cursor: NSCursor.pointingHand
            ]
        )
        linkButton.attributedTitle = attributedTitle

        // Improved accessibility
        linkButton.setAccessibilityTitle("View \(username) on GitHub")
        linkButton.setAccessibilityHelp("Opens the developer's GitHub profile in your browser")
    }

    private func populateInfo() {
        appNameLabel.stringValue = viewModel.appName
        versionLabel.stringValue = viewModel.versionDisplayString
        copyrightLabel.stringValue = viewModel.copyright
        creditLabel.stringValue = viewModel.creditsDisplayString
    }

    // MARK: - Accessibility

    private func setupAccessibility() {
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.group)
        view.setAccessibilityLabel("About Notimanager")

        // Icon accessibility
        iconView.setAccessibilityLabel("Notimanager application icon")
        iconView.setAccessibilityRole(.image)

        // Labels are static text
        appNameLabel.setAccessibilityRole(.staticText)
        versionLabel.setAccessibilityRole(.staticText)
        copyrightLabel.setAccessibilityRole(.staticText)
        creditLabel.setAccessibilityRole(.staticText)
    }

    // MARK: - Actions

    @objc private func openLink() {
        NSWorkspace.shared.open(viewModel.githubURL)
    }
}

// MARK: - Previews

#if DEBUG

import SwiftUI

/// SwiftUI wrapper for Xcode previews
@available(macOS 11.0, *)
struct AboutSettingsViewController_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            // Light mode preview
            AboutSettingsViewControllerRepresentable()
                .previewDisplayName("Light Mode")
                .frame(width: Layout.settingsWindowWidth, height: 400)
                .preferredColorScheme(.light)

            // Dark mode preview
            AboutSettingsViewControllerRepresentable()
                .previewDisplayName("Dark Mode")
                .frame(width: Layout.settingsWindowWidth, height: 400)
                .preferredColorScheme(.dark)

            // With reduced transparency
            AboutSettingsViewControllerRepresentable()
                .previewDisplayName("Reduced Transparency")
                .frame(width: Layout.settingsWindowWidth, height: 400)
        }
    }
}

/// NSViewController wrapper for SwiftUI previews
@available(macOS 11.0, *)
private struct AboutSettingsViewControllerRepresentable: NSViewControllerRepresentable {

    func makeNSViewController(context: Context) -> AboutSettingsViewController {
        return AboutSettingsViewController()
    }

    func updateNSViewController(_ nsViewController: AboutSettingsViewController, context: Context) {
        // No updates needed
    }
}

#endif
