//
//  PositionGridButton.swift
//  Notimanager
//
//  A reusable button component for the notification position grid.
//  Features Liquid Glass styling, full accessibility, and smooth animations.
//

import AppKit

/// A grid button for selecting notification position with Liquid Glass styling
class PositionGridButton: NSView {

    // MARK: - Properties

    private let position: NotificationPosition
    private var isSelected: Bool
    private let action: (NotificationPosition) -> Void

    private var containerView: NSVisualEffectView!
    private var button: NSButton!
    private var iconView: NSImageView!
    private var highlightLayer: CALayer?

    // MARK: - Initialization

    init(
        position: NotificationPosition,
        isSelected: Bool,
        action: @escaping (NotificationPosition) -> Void
    ) {
        self.position = position
        self.isSelected = isSelected
        self.action = action
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        // Create container with glass effect
        setupContainer()

        // Create clickable button
        setupButton()

        // Create icon
        setupIcon()

        // Setup constraints
        setupConstraints()

        // Setup accessibility
        setupAccessibility()

        // Observe appearance changes
        observeAppearanceChanges()
    }

    private func setupContainer() {
        containerView = NSVisualEffectView()
        containerView.wantsLayer = true
        containerView.material = isSelected ? .selection : .underWindowBackground
        containerView.blendingMode = .withinWindow
        containerView.state = .active
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // Style based on selection state
        updateContainerStyle()
    }

    private func setupButton() {
        button = NSButton()
        button.title = ""
        button.bezelStyle = .shadowlessSquare
        button.isBordered = false
        button.target = self
        button.action = #selector(handleTap)
        button.wantsLayer = true
        button.layer?.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(button)

        // Setup button for accessibility
        button.setAccessibilityElement(false) // Container handles accessibility
    }

    private func setupIcon() {
        guard let icon = createIcon() else { return }

        iconView = NSImageView()
        iconView.image = icon
        iconView.contentTintColor = isSelected ? Colors.accent : Colors.tertiaryLabel
        iconView.imageScaling = .scaleProportionallyDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: Layout.extraLargeIcon,
            weight: .medium
        )
        button.addSubview(iconView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            button.topAnchor.constraint(equalTo: containerView.topAnchor),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            iconView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Layout.extraLargeIcon),
            iconView.heightAnchor.constraint(equalToConstant: Layout.extraLargeIcon)
        ])
    }

    private func createIcon() -> NSImage? {
        let symbolName: String
        switch position {
        case .topLeft:
            symbolName = "arrow.up.left"
        case .topMiddle:
            symbolName = "arrow.up"
        case .topRight:
            symbolName = "arrow.up.right"
        case .middleLeft:
            symbolName = "arrow.left"
        case .deadCenter:
            symbolName = "circle.fill"
        case .middleRight:
            symbolName = "arrow.right"
        case .bottomLeft:
            symbolName = "arrow.down.left"
        case .bottomMiddle:
            symbolName = "arrow.down"
        case .bottomRight:
            symbolName = "arrow.down.right"
        }

        let config = NSImage.SymbolConfiguration(pointSize: Layout.extraLargeIcon, weight: .medium)
        return NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: position.displayName
        )?.withSymbolConfiguration(config)
    }

    // MARK: - Accessibility

    private func setupAccessibility() {
        setAccessibilityElement(true)
        setAccessibilityLabel(position.displayName)
        setAccessibilityRole(isSelected ? .radioButton : .button)
        setAccessibilityIdentifier(position.rawValue)

        // Use tooltip for additional info
        toolTip = isSelected
            ? "Currently selected notification position. Press to confirm."
            : "Set notification position to \(position.displayName)"

        // Note: acceptsFirstResponder is determined by canBecomeFirstResponder
    }

    // MARK: - Appearance

    private func updateContainerStyle() {
        let cornerRadius = bounds.width / 1.618 / 1.2 // Golden ratio based

        containerView.layer?.cornerRadius = cornerRadius
        containerView.layer?.borderWidth = isSelected ? Border.focus : Border.thin
        containerView.layer?.borderColor = isSelected
            ? Colors.accent.cgColor
            : Colors.separator.withAlphaComponent(0.4).cgColor

        // Update shadow based on selection
        if isSelected {
            containerView.shadow = Shadow.elevated()
        } else {
            containerView.shadow = Shadow.card()
        }

        // Update icon tint
        iconView?.contentTintColor = isSelected ? Colors.accent : Colors.tertiaryLabel

        // Apply high contrast adjustments
        if AppearanceManager.shared.isHighContrast {
            containerView.layer?.borderWidth = Border.medium
            containerView.layer?.borderColor = Colors.label.cgColor
        }

        // Apply reduce transparency adjustments
        if AppearanceManager.shared.isReduceTransparency {
            containerView.material = .contentBackground
        }
    }

    private func observeAppearanceChanges() {
        NotificationCenter.default.addObserver(
            forName: AppearanceManager.appearanceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateContainerStyle()
        }
    }

    // MARK: - Actions

    @objc private func handleTap() {
        // Animate press
        AnimationHelper.scaleDown(self) {
            // Execute action
            self.action(self.position)

            // Announce change
            AccessibilityManager.shared.announce(
                "Notification position changed to \(self.position.displayName)"
            )

            // Restore scale
            AnimationHelper.scaleUp(self)
        }
    }

    // MARK: - Public Methods

    /// Updates the selected state of the button
    /// - Parameter selected: The new selected state
    func setSelected(_ selected: Bool, animated: Bool = true) {
        guard isSelected != selected else { return }

        isSelected = selected

        // Update accessibility role
        if selected {
            setAccessibilityRole(.radioButton)
        } else {
            setAccessibilityRole(.button)
        }

        // Update tooltip
        toolTip = selected
            ? "Currently selected notification position. Press to confirm."
            : "Set notification position to \(position.displayName)"

        // Animate change
        if animated && AppearanceManager.shared.shouldAnimate {
            updateContainerStyle()

            // Subtle pop animation
            AnimationHelper.spring {
                self.updateContainerStyle()
            }
        } else {
            updateContainerStyle()
        }

        needsLayout = true
    }

    /// Returns the notification position
    var notificationPosition: NotificationPosition {
        return position
    }

    // MARK: - Focus

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        guard let window = window else { return false }

        let result = window.makeFirstResponder(self)

        if result {
            // Show focus ring
            updateFocusRing(true)

            // Announce focus
            AccessibilityManager.shared.announce(position.displayName)
        }

        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()

        if result {
            updateFocusRing(false)
        }

        return result
    }

    private func updateFocusRing(_ hasFocus: Bool) {
        if hasFocus {
            let focusRing = CALayer()
            focusRing.frame = bounds.insetBy(dx: -Layout.focusRingOffset, dy: -Layout.focusRingOffset)
            focusRing.cornerRadius = layer?.cornerRadius ?? 0
            focusRing.borderWidth = Layout.focusRingWidth
            focusRing.borderColor = NSColor.keyboardFocusIndicatorColor.cgColor
            focusRing.masksToBounds = true
            layer?.addSublayer(focusRing)
            highlightLayer = focusRing
        } else {
            highlightLayer?.removeFromSuperlayer()
            highlightLayer = nil
        }
    }

    // MARK: - Key Events

    override func keyDown(with event: NSEvent) {
        // Handle space and return to activate
        if event.keyCode == 49 || event.keyCode == 36 { // Space or Return
            handleTap()
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Factory Methods

extension PositionGridButton {

    /// Creates a grid button for the specified position
    /// - Parameters:
    ///   - position: The notification position
    ///   - isSelected: Whether the position is currently selected
    ///   - action: The action to perform when tapped
    /// - Returns: A configured position grid button
    static func create(
        position: NotificationPosition,
        isSelected: Bool,
        action: @escaping (NotificationPosition) -> Void
    ) -> PositionGridButton {
        return PositionGridButton(
            position: position,
            isSelected: isSelected,
            action: action
        )
    }
}

// MARK: - Grid Container

/// A container view that manages a grid of position buttons
class PositionGridView: NSView {

    private var buttons: [PositionGridButton] = []
    private var currentSelection: NotificationPosition

    init(selection: NotificationPosition, onChange: @escaping (NotificationPosition) -> Void) {
        self.currentSelection = selection
        super.init(frame: .zero)
        setupGrid(onChange: onChange)
    }

    required init?(coder: NSCoder) {
        self.currentSelection = .topMiddle
        super.init(coder: coder)
        setupGrid { _ in }
    }

    private func setupGrid(onChange: @escaping (NotificationPosition) -> Void) {
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        let positions = NotificationPosition.allCases

        // Create 3x3 grid
        for (index, position) in positions.enumerated() {
            let button = PositionGridButton(
                position: position,
                isSelected: position == currentSelection,
                action: { [weak self] newPos in
                    self?.updateSelection(to: newPos, onChange: onChange)
                }
            )
            button.translatesAutoresizingMaskIntoConstraints = false
            buttons.append(button)
            addSubview(button)
        }

        // Setup constraints for grid layout
        setupGridConstraints()

        // Setup accessibility for the grid
        AccessibilityManager.shared.configureGrid(
            self,
            label: "Notification Position Grid",
            rowCount: 3,
            columnCount: 3
        )
    }

    private func setupGridConstraints() {
        let gridSize = Layout.gridSize
        let spacing = Layout.gridSpacing

        var constraints: [NSLayoutConstraint] = []

        for (index, button) in buttons.enumerated() {
            let row = 2 - (index / 3) // Top row first
            let col = index % 3

            let x = CGFloat(col) * (gridSize + spacing)
            let y = CGFloat(row) * (gridSize + spacing)

            constraints.append(contentsOf: [
                button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: x),
                button.topAnchor.constraint(equalTo: topAnchor, constant: y),
                button.widthAnchor.constraint(equalToConstant: gridSize),
                button.heightAnchor.constraint(equalToConstant: gridSize)
            ])
        }

        // Set container size
        let totalWidth = (gridSize * 3) + (spacing * 2)
        constraints.append(contentsOf: [
            widthAnchor.constraint(equalToConstant: totalWidth),
            heightAnchor.constraint(equalToConstant: totalWidth)
        ])

        NSLayoutConstraint.activate(constraints)
    }

    private func updateSelection(to position: NotificationPosition, onChange: @escaping (NotificationPosition) -> Void) {
        guard currentSelection != position else { return }

        _ = currentSelection // Track old selection for potential future use
        currentSelection = position

        // Update all buttons
        for button in buttons {
            button.setSelected(button.notificationPosition == position)
        }

        onChange(position)
    }

    /// Updates the current selection
    /// - Parameter position: The new selected position
    func updateSelection(to position: NotificationPosition) {
        guard currentSelection != position else { return }
        currentSelection = position

        for button in buttons {
            button.setSelected(button.notificationPosition == position)
        }
    }
}
