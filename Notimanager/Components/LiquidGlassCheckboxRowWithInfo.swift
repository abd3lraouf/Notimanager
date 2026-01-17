//
//  LiquidGlassCheckboxRowWithInfo.swift
//  Notimanager
//
//  Enhanced checkbox row with optional info button for additional context
//  Part of the Liquid Glass Design System
//

import Cocoa

/// A checkbox row component with optional info button for additional help text
final class LiquidGlassCheckboxRowWithInfo: NSView {

    // MARK: - Properties

    private let checkbox: NSButton
    private let descriptionLabel: NSTextField?
    private let infoButton: InfoButton?

    public var checkboxButton: NSButton {
        return checkbox
    }

    // MARK: - Initialization

    public init(
        title: String,
        description: String? = nil,
        infoText: String? = nil,
        infoTitle: String? = nil,
        initialState: NSControl.StateValue = .off,
        action: Selector?,
        target: Any? = nil
    ) {
        // Create checkbox
        self.checkbox = NSButton(checkboxWithTitle: title, target: target, action: action)
        self.checkbox.state = initialState

        // Create description label
        if let description = description {
            self.descriptionLabel = NSTextField(wrappingLabelWithString: description)
        } else {
            self.descriptionLabel = nil
        }

        // Create info button if help text provided
        if let infoText = infoText {
            self.infoButton = InfoButton(helpText: infoText, helpTitle: infoTitle ?? title)
        } else {
            self.infoButton = nil
        }

        super.init(frame: .zero)
        setupRow()
    }

    required init?(coder: NSCoder) {
        self.checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        self.descriptionLabel = nil
        self.infoButton = nil
        super.init(coder: coder)
        setupRow()
    }

    // MARK: - Setup

    private func setupRow() {
        translatesAutoresizingMaskIntoConstraints = false

        // Configure checkbox
        checkbox.font = Typography.body
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkbox)

        // Configure description
        if let description = descriptionLabel {
            description.font = Typography.caption1
            description.textColor = Colors.secondaryLabel
            description.isEditable = false
            description.isBordered = false
            description.backgroundColor = .clear
            description.translatesAutoresizingMaskIntoConstraints = false
            description.lineBreakMode = .byWordWrapping
            addSubview(description)
        }

        // Add info button if present
        if let infoButton = infoButton {
            addSubview(infoButton)
        }

        // Layout
        setupLayout()
    }

    private func setupLayout() {
        var constraints: [NSLayoutConstraint] = []

        // Checkbox - anchor to top leading
        constraints += [
            checkbox.topAnchor.constraint(equalTo: topAnchor),
            checkbox.leadingAnchor.constraint(equalTo: leadingAnchor)
        ]

        if let infoButton = infoButton {
            // Info button - positioned after checkbox title
            constraints += [
                infoButton.centerYAnchor.constraint(equalTo: checkbox.centerYAnchor),
                infoButton.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: Spacing.pt4),
                infoButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
            ]

            // Description - below checkbox, with info button constraint
            if let description = descriptionLabel {
                constraints += [
                    description.topAnchor.constraint(equalTo: checkbox.bottomAnchor, constant: Spacing.pt4),
                    description.leadingAnchor.constraint(equalTo: leadingAnchor),
                    description.trailingAnchor.constraint(equalTo: trailingAnchor),
                    description.bottomAnchor.constraint(equalTo: bottomAnchor)
                ]
            } else {
                constraints += [
                    bottomAnchor.constraint(equalTo: checkbox.bottomAnchor, constant: -Spacing.pt4)
                ]
            }
        } else {
            // No info button - standard layout
            constraints += [
                checkbox.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
            ]

            if let description = descriptionLabel {
                constraints += [
                    description.topAnchor.constraint(equalTo: checkbox.bottomAnchor, constant: Spacing.pt4),
                    description.leadingAnchor.constraint(equalTo: leadingAnchor),
                    description.trailingAnchor.constraint(equalTo: trailingAnchor),
                    description.bottomAnchor.constraint(equalTo: bottomAnchor)
                ]
            } else {
                constraints += [
                    bottomAnchor.constraint(equalTo: checkbox.bottomAnchor, constant: -Spacing.pt4)
                ]
            }
        }

        NSLayoutConstraint.activate(constraints)
    }
}
