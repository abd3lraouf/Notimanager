//
//  InfoButton.swift
//  Notimanager
//
//  An info button (ⓘ) that shows a tooltip or popover with additional information
//  Part of the Liquid Glass Design System
//

import Cocoa

/// A button that displays an info icon and shows a popover with help text when clicked
final class InfoButton: NSButton {

    // MARK: - Properties

    private let helpText: String
    private let helpTitle: String?
    private var popover: NSPopover?

    // MARK: - Initialization

    /// Creates an info button with the specified help text
    /// - Parameters:
    ///   - helpText: The text to display in the popover
    ///   - helpTitle: Optional title for the popover
    init(helpText: String, helpTitle: String? = nil) {
        self.helpText = helpText
        self.helpTitle = helpTitle

        super.init(frame: .zero)

        setupButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupButton() {
        // Set button to show info circle symbol
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "Info")
            image?.isTemplate = true
            symbolConfiguration = config
        } else {
            image = NSImage(named: NSImage.infoName)
        }

        isBordered = false
        bezelStyle = .regularSquare
        focusRingType = .none

        // Set size - use height constraint only, let width be flexible
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 20).isActive = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true

        // Set action
        target = self
        action = #selector(showPopover)

        // Accessibility
        setAccessibilityTitle(NSLocalizedString("More information", comment: "Accessibility label"))
        setAccessibilityHelp(helpText)
    }

    // MARK: - Actions

    @objc private func showPopover() {
        guard let window = window else { return }

        // Create popover if needed
        if popover == nil {
            popover = NSPopover()
            popover?.behavior = .transient
            popover?.contentViewController = PopoverViewController(helpText: helpText, helpTitle: helpTitle)
        }

        // Show popover
        guard let popover = popover else { return }

        // Position popover relative to button
        popover.show(relativeTo: bounds, of: self, preferredEdge: .maxX)

        // Accessibility announcement
        if let title = helpTitle {
            AccessibilityManager.shared.announce("\(title): \(helpText)")
        } else {
            AccessibilityManager.shared.announce(helpText)
        }
    }
}

// MARK: - Popover View Controller

private class PopoverViewController: NSViewController {

    private let helpText: String
    private let helpTitle: String?

    private var titleLabel: NSTextField!
    private var textLabel: NSTextField!

    init(helpText: String, helpTitle: String? = nil) {
        self.helpText = helpText
        self.helpTitle = helpTitle
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
    }

    private func setupUI() {
        // Title label (optional)
        if let title = helpTitle {
            titleLabel = NSTextField(labelWithString: title)
            titleLabel.font = Typography.headline
            titleLabel.textColor = Colors.label
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(titleLabel)
        }

        // Text label
        textLabel = NSTextField(wrappingLabelWithString: helpText)
        textLabel.font = Typography.body
        textLabel.textColor = Colors.secondaryLabel
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textLabel)

        // Layout
        let maxWidth: CGFloat = 320

        var constraints: [NSLayoutConstraint] = []

        // Title
        if let titleLabel = titleLabel {
            constraints += [
                titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.pt16),
                titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.pt16),
                titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.pt16),

                textLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Spacing.pt8)
            ]
        } else {
            constraints += [
                textLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Spacing.pt16)
            ]
        }

        // Text label
        constraints += [
            textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.pt16),
            textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.pt16),
            textLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.pt16),
            textLabel.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
