//
//  ThemePicker.swift
//  Notimanager
//
//  A custom theme picker component with visual previews.
//

import AppKit

/// A theme picker component with visual previews
class ThemePicker: NSView {

    // MARK: - Properties

    private var themeOptions: [ThemeOptionView] = []
    private var currentSelection: AppTheme
    private let onThemeChange: (AppTheme) -> Void

    private let stackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = Spacing.pt12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initialization

    init(currentTheme: AppTheme, onThemeChange: @escaping (AppTheme) -> Void) {
        self.currentSelection = currentTheme
        self.onThemeChange = onThemeChange

        super.init(frame: .zero)

        setupView()
        createThemeOptions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = .clear

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    private func createThemeOptions() {
        for theme in AppTheme.allCases {
            let optionView = ThemeOptionView(
                theme: theme,
                isSelected: theme == currentSelection,
                onTap: { [weak self] in
                    self?.selectTheme(theme)
                }
            )
            optionView.translatesAutoresizingMaskIntoConstraints = false
            themeOptions.append(optionView)
            stackView.addArrangedSubview(optionView)

            NSLayoutConstraint.activate([
                optionView.widthAnchor.constraint(equalToConstant: 120)
            ])
        }
    }

    // MARK: - Theme Selection

    private func selectTheme(_ theme: AppTheme) {
        guard theme != currentSelection else { return }

        currentSelection = theme

        // Update all option views
        for optionView in themeOptions {
            optionView.setSelected(optionView.theme == theme)
        }

        // Trigger callback
        onThemeChange(theme)

        // Announce for accessibility
        AccessibilityManager.shared.announceSettingChange(
            setting: "Appearance",
            value: theme.displayName
        )
    }

    /// Updates the current theme selection
    /// - Parameter theme: The newly selected theme
    func updateSelection(_ theme: AppTheme) {
        currentSelection = theme
        for optionView in themeOptions {
            optionView.setSelected(optionView.theme == theme)
        }
    }
}

// MARK: - Theme Option View

/// A single theme option with preview
class ThemeOptionView: NSView {

    let theme: AppTheme
    private let onTap: () -> Void
    private var isSelected: Bool = false

    private let containerView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = Layout.mediumCornerRadius
        view.layer?.borderWidth = Border.thin
        view.layer?.borderColor = Colors.separator.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconView: NSImageView = {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let label: NSTextField = {
        let field = NSTextField(labelWithString: "")
        field.alignment = .center
        field.font = Typography.caption1
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let previewCard: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initialization

    init(theme: AppTheme, isSelected: Bool, onTap: @escaping () -> Void) {
        self.theme = theme
        self.onTap = onTap
        self.isSelected = isSelected

        super.init(frame: .zero)

        setupView()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true

        // Create clickable button
        let button = NSButton()
        button.title = ""
        button.bezelStyle = .shadowlessSquare
        button.isBordered = false
        button.target = self
        button.action = #selector(handleTap)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        containerView.addSubview(previewCard)
        containerView.addSubview(iconView)
        containerView.addSubview(label)
        addSubview(containerView)

        NSLayoutConstraint.activate([
            // Button fills entire view
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.pt8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.pt8),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.pt8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.pt8),

            // Preview card
            previewCard.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Spacing.pt12),
            previewCard.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            previewCard.widthAnchor.constraint(equalToConstant: 40),
            previewCard.heightAnchor.constraint(equalToConstant: 40),

            // Icon
            iconView.topAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: Spacing.pt8),
            iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Layout.largeIcon),
            iconView.heightAnchor.constraint(equalToConstant: Layout.largeIcon),

            // Label
            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: Spacing.pt4),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.pt4),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.pt4),
            label.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -Spacing.pt8)
        ])

        // Setup accessibility
        setupAccessibility()
    }

    private func setupAccessibility() {
        setAccessibilityElement(true)
        setAccessibilityLabel("\(theme.displayName) theme")
        setAccessibilityRole(.button)
        toolTip = "Switch to \(theme.displayName) appearance"

        if isSelected {
            setAccessibilityValue("Selected")
            setAccessibilityRole(.radioButton)
        }
    }

    // MARK: - Appearance

    private func updateAppearance() {
        let colors = ThemeManager.shared.previewColors(for: theme)

        // Update container
        containerView.layer?.backgroundColor = Colors.secondaryBackground.cgColor

        // Update selection state
        if isSelected {
            containerView.layer?.borderWidth = Border.focus
            containerView.layer?.borderColor = Colors.accent.cgColor
            containerView.layer?.backgroundColor = Colors.glassTint.cgColor
        } else {
            containerView.layer?.borderWidth = Border.thin
            containerView.layer?.borderColor = Colors.separator.cgColor
        }

        // Update preview card
        previewCard.layer?.backgroundColor = colors.card.cgColor
        previewCard.layer?.borderWidth = 1
        previewCard.layer?.borderColor = colors.border.cgColor

        // Add preview elements
        previewCard.subviews.forEach { $0.removeFromSuperview() }

        // Preview circle
        let circle = NSView()
        circle.wantsLayer = true
        circle.layer?.backgroundColor = colors.accent.cgColor
        circle.layer?.cornerRadius = 8
        circle.translatesAutoresizingMaskIntoConstraints = false
        previewCard.addSubview(circle)

        NSLayoutConstraint.activate([
            circle.centerYAnchor.constraint(equalTo: previewCard.centerYAnchor),
            circle.centerXAnchor.constraint(equalTo: previewCard.centerXAnchor),
            circle.widthAnchor.constraint(equalToConstant: 16),
            circle.heightAnchor.constraint(equalToConstant: 16)
        ])

        // Update icon
        let config = NSImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconView.image = NSImage(
            systemSymbolName: theme.iconSymbol,
            accessibilityDescription: theme.displayName
        )?.withSymbolConfiguration(config)

        iconView.contentTintColor = isSelected ? Colors.accent : Colors.secondaryLabel

        // Update label
        label.stringValue = theme.displayName
        label.textColor = isSelected ? Colors.accent : Colors.secondaryLabel
    }

    // MARK: - Selection

    func setSelected(_ selected: Bool) {
        isSelected = selected
        updateAppearance()

        // Update accessibility
        if isSelected {
            setAccessibilityValue("Selected")
            setAccessibilityRole(.radioButton)
            toolTip = "Currently selected \(theme.displayName) theme"
        } else {
            setAccessibilityValue(nil)
            setAccessibilityRole(.button)
            toolTip = "Switch to \(theme.displayName) theme"
        }
    }

    // MARK: - Actions

    @objc private func handleTap() {
        onTap()

        // Provide visual feedback
        if !isSelected {
            AnimationHelper.scaleDown(self) {
                AnimationHelper.scaleUp(self)
            }
        }
    }

    // MARK: - Hover State

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if !isSelected {
            AnimationHelper.scale(self, to: 1.02)
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if !isSelected {
            AnimationHelper.scale(self, to: 1.0)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        trackingAreas.forEach { removeTrackingArea($0) }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
}
