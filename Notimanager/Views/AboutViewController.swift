//
//  AboutViewController.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  MVVM about view controller extracted from NotificationMover
//

import Cocoa

/// About View Controller using MVVM architecture
class AboutViewController: NSViewController {

    // MARK: - Properties

    private let viewModel: AboutViewModel
    private var window: NSWindow?

    // MARK: - Initialization

    init(viewModel: AboutViewModel = AboutViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        let contentView = view

        let version: String = viewModel.version
        let copyright: String = viewModel.copyright

        let elements: [(NSView, CGFloat)] = [
            (createIconView(), 165),
            (createLabel("Notimanager", font: .boldSystemFont(ofSize: 16)), 110),
            (createLabel("Version \(version)"), 90),
            (createLabel("Made with <3 by Wade"), 70),
            (createTwitterButton(), 40),
            (createLabel(copyright, color: .secondaryLabelColor, size: 11), 20),
        ]

        for (viewElement, y) in elements {
            if let iconView = viewElement as? NSView, iconView.subviews.first is NSImageView {
                // Icon container
                viewElement.frame = NSRect(x: 100, y: y, width: 100, height: 100)
            } else {
                viewElement.frame = NSRect(x: 0, y: y, width: 300, height: 20)
            }
            contentView.addSubview(viewElement)
        }
    }

    // MARK: - UI Creation Helpers

    private func createIconView() -> NSView {
        let iconContainer = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        iconContainer.wantsLayer = true
        iconContainer.layer?.backgroundColor = NSColor.white.cgColor
        iconContainer.layer?.cornerRadius = 20

        let iconImageView = NSImageView(frame: NSRect(x: 10, y: 10, width: 80, height: 80))
        if let iconImage = NSImage(named: "icon") {
            iconImageView.image = iconImage
            iconImageView.imageScaling = .scaleProportionallyDown
        }
        iconContainer.addSubview(iconImageView)
        return iconContainer
    }

    private func createLabel(_ text: String, font: NSFont = .systemFont(ofSize: 12), color: NSColor = .labelColor, size: CGFloat = 12) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.alignment = .center
        label.font = font
        label.textColor = color
        return label
    }

    private func createTwitterButton() -> NSButton {
        let button = NSButton()
        button.title = "@WadeGrimridge"
        button.bezelStyle = .inline
        button.isBordered = false
        button.target = self
        button.action = #selector(openTwitter)
        button.attributedTitle = NSAttributedString(string: "@WadeGrimridge", attributes: [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ])
        return button
    }

    // MARK: - Actions

    @objc private func openTwitter() {
        viewModel.openTwitter()
    }

    // MARK: - Window Management

    func showInWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "About Notimanager"
        window.delegate = self

        window.contentView = view
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSWindowDelegate

extension AboutViewController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
