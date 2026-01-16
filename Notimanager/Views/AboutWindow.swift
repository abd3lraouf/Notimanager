//
//  AboutWindow.swift
//  Notimanager
//
//  Modern about window following Apple's Human Interface Guidelines.
//  Features Liquid Glass design with proper accessibility support.
//

import AppKit

/// Modern about window with Liquid Glass effects
/// Following Apple HIG for About windows
final class AboutWindow: NSWindow {

    // MARK: - Properties

    private let viewModel = AboutViewModel()
    private var contentStackView: NSStackView!

    // MARK: - Initialization

    init() {
        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: Layout.aboutWindowWidth,
                height: Layout.aboutWindowHeight
            ),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent()
        setupAccessibility()
    }

    // MARK: - Setup

    private func setupWindow() {
        title = String(format: NSLocalizedString("About %@", comment: "About window title"), viewModel.appName)
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true

        // Configure accessibility
        AccessibilityManager.shared.configureWindow(self, title: title)
    }

    private func setupContent() {
        // Background using Liquid Glass Card
        let backgroundView = LiquidGlassCard(
            frame: NSRect(x: 0, y: 0, width: frame.width, height: frame.height)
        )
        backgroundView.material = .underWindowBackground
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .followsWindowActiveState

        contentView = backgroundView

        // Create scrollable stack view for content
        let scrollView = NSScrollView(frame: NSRect(
            x: Spacing.pt24,
            y: Spacing.pt24,
            width: frame.width - (Spacing.pt48),
            height: frame.height - (Spacing.pt48)
        ))
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false
        scrollView.contentView.drawsBackground = false
        backgroundView.addSubview(scrollView)

        contentStackView = NSStackView()
        contentStackView.orientation = .vertical
        contentStackView.spacing = Spacing.pt24
        contentStackView.alignment = .centerX
        contentStackView.distribution = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentStackView

        // Add sections
        contentStackView.addArrangedSubview(createIconSection())
        contentStackView.addArrangedSubview(createInfoSection())
        contentStackView.addArrangedSubview(createLinksSection())
        contentStackView.addArrangedSubview(createLegalSection())

        // Setup constraints
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor, constant: Spacing.pt16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.contentView.bottomAnchor, constant: -Spacing.pt16)
        ])
    }

    private func setupAccessibility() {
        contentView?.setAccessibilityLabel(String(format: NSLocalizedString("About %@", comment: "Accessibility label"), viewModel.appName))
        contentView?.setAccessibilityRole(.group)
        contentStackView?.setAccessibilityRole(.group)
    }

    // MARK: - Section Builders

    private func createIconSection() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconSize: CGFloat = 80
        let iconView = NSImageView()
        iconView.image = NSImage(named: "AppIcon")
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.wantsLayer = true
        iconView.layer?.cornerRadius = Layout.cardCornerRadius
        iconView.layer?.masksToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // Shadow for depth
        iconView.wantsLayer = true
        iconView.layer?.shadowColor = Colors.glassShadow.cgColor
        iconView.layer?.shadowOpacity = 1.0
        iconView.layer?.shadowOffset = NSSize(width: 0, height: 2)
        iconView.layer?.shadowRadius = 8

        container.addSubview(iconView)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),
            container.heightAnchor.constraint(equalToConstant: iconSize)
        ])

        // Accessibility
        iconView.setAccessibilityLabel(NSLocalizedString("App icon", comment: "Accessibility label"))
        iconView.setAccessibilityRole(.image)

        return container
    }

    private func createInfoSection() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = Spacing.pt8
        stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false

        // App name
        let appNameLabel = createLabel(
            viewModel.appName,
            font: Typography.title2,
            color: Colors.label
        )
        stack.addArrangedSubview(appNameLabel)

        // Version and build
        let versionLabel = createLabel(
            String(format: NSLocalizedString("Version %@ (Build %@)", comment: "Version display"), viewModel.version, viewModel.build),
            font: Typography.body,
            color: Colors.secondaryLabel
        )
        stack.addArrangedSubview(versionLabel)

        // Description
        let descLabel = createLabel(
            NSLocalizedString("Position your macOS notifications anywhere on your screen.", comment: "App description"),
            font: Typography.body,
            color: Colors.secondaryLabel
        )
        descLabel.alignment = .center
        descLabel.lineBreakMode = .byWordWrapping
        stack.addArrangedSubview(descLabel)

        // Credits
        let creditsLabel = createLabel(
            viewModel.creditsDisplayString,
            font: Typography.caption1,
            color: Colors.tertiaryLabel
        )
        stack.addArrangedSubview(creditsLabel)

        return stack
    }

    private func createLinksSection() -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = Spacing.pt12
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false

        // GitHub button
        let githubBtn = createLinkButton(
            title: NSLocalizedString("GitHub", comment: "GitHub link button"),
            iconName: "link"
        )
        githubBtn.target = self
        githubBtn.action = #selector(openGithub)
        stack.addArrangedSubview(githubBtn)

        // Website button (if available)
        if let websiteURL = viewModel.websiteURL {
            let websiteBtn = createLinkButton(
                title: NSLocalizedString("Website", comment: "Website link button"),
                iconName: "globe"
            )
            objc_setAssociatedObject(websiteBtn, "websiteURL", websiteURL as NSURL, .OBJC_ASSOCIATION_RETAIN)
            websiteBtn.target = self
            websiteBtn.action = #selector(openWebsite(_:))
            stack.addArrangedSubview(websiteBtn)
        }

        // Configure accessibility
        AccessibilityManager.shared.configureButton(
            githubBtn,
            label: String(format: NSLocalizedString("View %@ on GitHub", comment: "Accessibility label"), viewModel.githubUsername)
        )
        githubBtn.toolTip = String(format: NSLocalizedString("Opens %@'s GitHub profile in your default browser", comment: "Tooltip"), viewModel.githubUsername)

        if let websiteBtn = stack.arrangedSubviews.count > 1 ? stack.arrangedSubviews[1] as? NSButton : nil {
            AccessibilityManager.shared.configureButton(
                websiteBtn,
                label: NSLocalizedString("Visit project website", comment: "Accessibility label")
            )
            websiteBtn.toolTip = NSLocalizedString("Opens the project website in your default browser", comment: "Tooltip")
        }

        return stack
    }

    private func createLegalSection() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = Spacing.pt4
        stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Copyright
        let copyrightLabel = createLabel(
            viewModel.copyright,
            font: Typography.caption2,
            color: Colors.tertiaryLabel
        )
        copyrightLabel.alignment = .center
        stack.addArrangedSubview(copyrightLabel)

        // License information
        let licenseLabel = createLabel(
            NSLocalizedString("Released under the MIT License", comment: "License information"),
            font: Typography.caption2,
            color: Colors.tertiaryLabel
        )
        licenseLabel.alignment = .center
        stack.addArrangedSubview(licenseLabel)

        return stack
    }

    // MARK: - Helper Methods

    private func createLabel(_ text: String, font: NSFont, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.isEditable = false
        label.isSelectable = true // Allow selecting text for copying
        label.drawsBackground = false
        label.isBordered = false
        label.lineBreakMode = .byWordWrapping
        label.cell?.truncatesLastVisibleLine = false
        label.cell?.wraps = true

        // Accessibility
        label.setAccessibilityRole(.staticText)
        label.setAccessibilityEnabled(true)

        return label
    }

    private func createLinkButton(title: String, iconName: String?) -> NSButton {
        let button = NSButton()
        button.title = title
        button.bezelStyle = .rounded
        button.font = Typography.body
        button.controlSize = .regular

        // Add icon if available (macOS 11+)
        if #available(macOS 11.0, *), let iconName = iconName {
            if let icon = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
                button.image = icon
            }
        }

        return button
    }

    // MARK: - Actions

    @objc private func openGithub() {
        NSWorkspace.shared.open(viewModel.githubURL)
        AccessibilityManager.shared.announce(String(format: NSLocalizedString("Opening GitHub profile for %@", comment: "Accessibility announcement"), viewModel.githubUsername))
    }

    @objc private func openWebsite(_ sender: NSButton) {
        guard let url = objc_getAssociatedObject(sender, "websiteURL") as? URL else {
            return
        }
        NSWorkspace.shared.open(url)
        AccessibilityManager.shared.announce(NSLocalizedString("Opening project website", comment: "Accessibility announcement"))
    }

    // MARK: - Factory Methods

    static func show() {
        let window = AboutWindow()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
