//
//  AboutWindow.swift
//  Notimanager
//
//  Modern about window with Liquid Glass design.
//

import AppKit

/// Modern about window with Liquid Glass effects
class AboutWindow: NSWindow {

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
        title = "About Notimanager"
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true

        // Configure accessibility
        AccessibilityManager.shared.configureWindow(self, title: "About")
    }

    private func setupContent() {
        // Background using Liquid Glass Card
        let backgroundView = LiquidGlassCard(
            frame: NSRect(x: 0, y: 0, width: frame.width, height: frame.height)
        )
        backgroundView.material = .underWindowBackground
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .active

        contentView = backgroundView

        var yPos = frame.height - Spacing.pt48

        // Add sections
        yPos = addIconSection(at: yPos) - Spacing.pt32
        yPos = addInfoSection(at: yPos) - Spacing.pt32
        _ = addLinksSection(at: yPos)
    }

    private func setupAccessibility() {
        contentView?.setAccessibilityLabel("About Notimanager")
        contentView?.setAccessibilityRole(.group)
    }

    // MARK: - Section Builders

    private func addIconSection(at yPos: CGFloat) -> CGFloat {
        let iconSize: CGFloat = Layout.hugeIcon

        let iconContainer = NSView(frame: NSRect(
            x: (frame.width - iconSize) / 2,
            y: yPos - iconSize,
            width: iconSize,
            height: iconSize
        ))
        iconContainer.wantsLayer = true

        // Gradient background using Liquid Glass effect
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = iconContainer.bounds
        gradientLayer.colors = [
            Colors.glassTint.cgColor,
            Colors.glassTint.withAlphaComponent(0.08).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]

        let cornerRadius: CGFloat = iconSize / 1.618 / 1.5
        gradientLayer.cornerRadius = cornerRadius
        iconContainer.layer?.addSublayer(gradientLayer)

        // Shadow using design tokens
        iconContainer.layer?.shadowColor = Colors.glassShadow.cgColor
        iconContainer.layer?.shadowOpacity = 1.0
        iconContainer.layer?.shadowOffset = NSSize(width: 0, height: 4)
        iconContainer.layer?.shadowRadius = 12
        iconContainer.layer?.cornerRadius = cornerRadius

        // Border
        iconContainer.layer?.borderWidth = Border.thin
        iconContainer.layer?.borderColor = Colors.glassBorder.cgColor

        // App icon
        let iconInset: CGFloat = iconSize / 1.618 / 3
        let iconView = NSImageView(frame: NSRect(
            x: iconInset,
            y: iconInset,
            width: iconSize - (iconInset * 2),
            height: iconSize - (iconInset * 2)
        ))

        if let icon = NSImage(named: "icon") {
            iconView.image = icon
            iconView.imageScaling = .scaleProportionallyDown
        }
        iconContainer.addSubview(iconView)
        contentView?.addSubview(iconContainer)

        return yPos - iconSize
    }

    private func addInfoSection(at yPos: CGFloat) -> CGFloat {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // Version
        let versionLabel = createLabel(
            "Notimanager v\(version) (build \(build))",
            font: Typography.title2
        )
        versionLabel.frame = NSRect(
            x: Spacing.pt24,
            y: yPos - Spacing.pt24,
            width: frame.width - (Spacing.pt24 * 2),
            height: Spacing.pt24
        )
        versionLabel.alignment = .center
        contentView?.addSubview(versionLabel)

        // Description
        let descLabel = createLabel(
            "Position your macOS notifications anywhere on your screen.",
            font: Typography.body
        )
        descLabel.textColor = Colors.secondaryLabel
        descLabel.frame = NSRect(
            x: Spacing.pt48,
            y: yPos - Spacing.pt48 - Spacing.pt4,
            width: frame.width - (Spacing.pt48 * 2),
            height: Spacing.pt20
        )
        descLabel.alignment = .center
        contentView?.addSubview(descLabel)

        // Credits
        let creditsLabel = createLabel(
            "Made with ❤️ by Wade Grimridge",
            font: Typography.caption1
        )
        creditsLabel.textColor = Colors.tertiaryLabel
        creditsLabel.frame = NSRect(
            x: Spacing.pt24,
            y: yPos - Spacing.pt48 - Spacing.pt24 - Spacing.pt8,
            width: frame.width - (Spacing.pt24 * 2),
            height: Spacing.pt16
        )
        creditsLabel.alignment = .center
        contentView?.addSubview(creditsLabel)

        return yPos - Spacing.pt48 - Spacing.pt32
    }

    private func addLinksSection(at yPos: CGFloat) -> CGFloat {
        let buttonHeight: CGFloat = Layout.regularButtonHeight
        let buttonSpacing: CGFloat = Spacing.pt12
        let buttonWidth = (frame.width - (Spacing.pt24 * 2) - buttonSpacing) / 2

        // Ko-fi button
        let kofiBtn = createLinkButton(
            "Support on Ko-fi",
            frame: NSRect(x: Spacing.pt24, y: yPos - buttonHeight, width: buttonWidth, height: buttonHeight),
            url: "https://ko-fi.com/wadegrimridge"
        )
        contentView?.addSubview(kofiBtn)

        // Buy Me a Coffee button
        let coffeeBtn = createLinkButton(
            "Buy Me a Coffee",
            frame: NSRect(x: Spacing.pt24 + buttonWidth + buttonSpacing, y: yPos - buttonHeight, width: buttonWidth, height: buttonHeight),
            url: "https://www.buymeacoffee.com/wadegrimridge"
        )
        contentView?.addSubview(coffeeBtn)

        // Configure accessibility
        AccessibilityManager.shared.configureButton(
            kofiBtn,
            label: "Support on Ko-fi"
        )
        kofiBtn.toolTip = "Opens developer's Ko-fi page in your default browser"

        AccessibilityManager.shared.configureButton(
            coffeeBtn,
            label: "Buy Me a Coffee"
        )
        coffeeBtn.toolTip = "Opens developer's Buy Me a Coffee page in your default browser"

        return yPos - buttonHeight - Spacing.pt32
    }

    // MARK: - Helper Methods

    private func createLabel(_ text: String, font: NSFont) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = Colors.label
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        return label
    }

    private func createLinkButton(_ title: String, frame: NSRect, url: String) -> NSButton {
        let button = NSButton(frame: frame)
        button.title = title
        button.bezelStyle = .rounded
        button.font = Typography.body
        button.target = self
        button.action = #selector(openLink(_:))

        // Store URL in button tag
        objc_setAssociatedObject(button, "linkURL", url as NSString, .OBJC_ASSOCIATION_RETAIN)

        return button
    }

    @objc private func openLink(_ sender: NSButton) {
        guard let url = objc_getAssociatedObject(sender, "linkURL") as? String,
              let urlObj = URL(string: url) else {
            return
        }

        NSWorkspace.shared.open(urlObj)
    }

    // MARK: - Factory Methods

    static func show() {
        let window = AboutWindow()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
