//
//  PositionGridButton.swift
//  Notimanager
//
//  A reusable button component for the notification position grid.
//  Features Liquid Glass styling, smooth animations, and proper accessibility.
//

import AppKit
import QuartzCore

/// A grid button for selecting notification position with Liquid Glass styling and smooth animations
class PositionGridButton: NSView {

    // MARK: - Properties

    private let position: NotificationPosition
    private var isSelected: Bool
    private let action: (NotificationPosition) -> Void

    private var containerView: NSView!
    private var backgroundEffectView: NSVisualEffectView!
    private var button: NSButton!
    private var iconView: NSImageView!
    private var selectionRing: CAShapeLayer?
    private var hoverHighlight: CAShapeLayer?

    // Animation state
    private var isHovered: Bool = false
    private var isPressed: Bool = false
    private var currentScale: CGFloat = 1.0

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
        layer?.masksToBounds = false

        // Create container view
        setupContainer()

        // Create background effect view
        setupBackgroundView()

        // Create clickable button
        setupButton()

        // Create icon
        setupIcon()

        // Create selection ring
        setupSelectionRing()

        // Create hover highlight
        setupHoverHighlight()

        // Setup constraints
        setupConstraints()

        // Setup tracking areas for hover
        setupHoverTracking()

        // Setup accessibility
        setupAccessibility()

        // Apply initial style
        updateStyle()

        // Observe appearance changes
        observeAppearanceChanges()
    }

    private func setupContainer() {
        containerView = NSView()
        containerView.wantsLayer = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
    }

    private func setupBackgroundView() {
        backgroundEffectView = NSVisualEffectView()
        backgroundEffectView.wantsLayer = true
        backgroundEffectView.material = isSelected ? .selection : .titlebar
        backgroundEffectView.blendingMode = .withinWindow
        backgroundEffectView.state = .active
        backgroundEffectView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(backgroundEffectView)
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
        button.setAccessibilityElement(false)
    }

    private func setupIcon() {
        guard let icon = createIcon() else { return }

        iconView = NSImageView()
        iconView.image = icon
        iconView.contentTintColor = isSelected ? Colors.accent : Colors.tertiaryLabel
        iconView.imageScaling = .scaleNone
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: Layout.extraLargeIcon,
            weight: .medium
        )
        iconView.alignment = .center
        iconView.imageAlignment = .alignCenter
        iconView.wantsLayer = true
        button.addSubview(iconView)
    }

    private func setupSelectionRing() {
        let ring = CAShapeLayer()
        ring.fillColor = nil
        ring.strokeEnd = 0
        ring.lineCap = .round
        ring.strokeColor = Colors.accent.cgColor
        containerView.layer?.addSublayer(ring)
        selectionRing = ring
    }

    private func setupHoverHighlight() {
        let highlight = CAShapeLayer()
        highlight.fillColor = NSColor.white.withAlphaComponent(0.1).cgColor
        highlight.opacity = 0
        containerView.layer?.addSublayer(highlight)
        hoverHighlight = highlight
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            backgroundEffectView.topAnchor.constraint(equalTo: containerView.topAnchor),
            backgroundEffectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backgroundEffectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backgroundEffectView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

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

    private func setupHoverTracking() {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInActiveApp]
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: options,
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    private func createIcon() -> NSImage? {
        let symbolName: String
        switch position {
        case .topLeft:
            symbolName = "arrow.up.left"
        case .topRight:
            symbolName = "arrow.up.right"
        case .bottomLeft:
            symbolName = "arrow.down.left"
        case .bottomRight:
            symbolName = "arrow.down.right"
        }

        let config = NSImage.SymbolConfiguration(pointSize: Layout.extraLargeIcon, weight: .medium)
        return NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: position.displayName
        )?.withSymbolConfiguration(config)
    }

    // MARK: - Styling

    private func updateStyle() {
        let cornerRadius = bounds.width / 2.5

        // Update background view
        backgroundEffectView.layer?.cornerRadius = cornerRadius

        // Update border
        backgroundEffectView.layer?.borderWidth = isSelected ? 2.0 : 1.0
        backgroundEffectView.layer?.borderColor = isSelected
            ? Colors.accent.cgColor
            : NSColor.white.withAlphaComponent(0.15).cgColor

        // Update shadow based on state
        if isSelected {
            applyElevatedShadow()
        } else if isHovered {
            applyHoverShadow()
        } else {
            applyDefaultShadow()
        }

        // Update icon tint and scale
        let iconScale: CGFloat = isSelected ? 1.1 : 1.0
        iconView?.contentTintColor = isSelected ? Colors.accent : Colors.tertiaryLabel

        // Animate icon scale
        if let iconLayer = iconView?.layer {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Animation.springResponse
                context.timingFunction = Animation.defaultCurve
                context.allowsImplicitAnimation = true
                iconLayer.setAffineTransform(CGAffineTransform(scaleX: iconScale, y: iconScale))
            }
        }

        // Update selection ring
        updateSelectionRing(cornerRadius: cornerRadius)

        // Update hover highlight
        updateHoverHighlight(cornerRadius: cornerRadius)

        // Apply accessibility adjustments
        if AppearanceManager.shared.isHighContrast {
            backgroundEffectView.layer?.borderWidth = 2.0
            backgroundEffectView.layer?.borderColor = Colors.label.cgColor
        }

        if AppearanceManager.shared.isReduceTransparency {
            backgroundEffectView.material = .contentBackground
        }
    }

    private func applyDefaultShadow() {
        // Use consistent dual-shadow system
        containerView.applySubtleShadow()
    }

    private func applyHoverShadow() {
        // Use consistent dual-shadow system with medium intensity
        containerView.applyMediumShadow()
    }

    private func applyElevatedShadow() {
        // Selected state uses strong shadow with accent color tint
        // Apply the strong shadow with custom accent color
        guard containerView.wantsLayer else { return }

        let primaryConfig: (
            color: NSColor,
            offset: CGSize,
            radius: CGFloat,
            opacity: Float
        ) = (
            Colors.accent.withAlphaComponent(0.30),
            CGSize(width: 0, height: -6),
            20,
            0.30
        )

        let ambientConfig: (
            color: NSColor,
            offset: CGSize,
            radius: CGFloat,
            opacity: Float
        ) = (
            Colors.accent.withAlphaComponent(0.15),
            CGSize(width: 0, height: -3),
            10,
            0.15
        )

        // Apply primary shadow
        containerView.layer?.shadowColor = primaryConfig.color.cgColor
        containerView.layer?.shadowOffset = primaryConfig.offset
        containerView.layer?.shadowRadius = primaryConfig.radius
        containerView.layer?.shadowOpacity = primaryConfig.opacity

        // Create ambient shadow layer
        let ambientLayerName = "ambientShadow"
        containerView.layer?.sublayers?.removeAll(where: { $0.name == ambientLayerName })

        let ambientLayer = CALayer()
        ambientLayer.name = ambientLayerName
        ambientLayer.shadowColor = ambientConfig.color.cgColor
        ambientLayer.shadowOffset = ambientConfig.offset
        ambientLayer.shadowRadius = ambientConfig.radius
        ambientLayer.shadowOpacity = ambientConfig.opacity
        ambientLayer.frame = containerView.bounds
        containerView.layer?.insertSublayer(ambientLayer, at: 0)
    }

    private func updateSelectionRing(cornerRadius: CGFloat) {
        guard let ring = selectionRing else { return }

        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), xRadius: cornerRadius, yRadius: cornerRadius)
        ring.path = path.cgPath
        ring.lineWidth = 2.0
        ring.frame = bounds

        if isSelected {
            // Animate ring drawing
            let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeAnimation.fromValue = 0
            strokeAnimation.toValue = 1
            strokeAnimation.duration = Animation.springResponse
            strokeAnimation.timingFunction = Animation.defaultCurve
            ring.add(strokeAnimation, forKey: "strokeAnimation")
            ring.strokeEnd = 1
        } else {
            ring.strokeEnd = 0
            ring.removeAllAnimations()
        }
    }

    private func updateHoverHighlight(cornerRadius: CGFloat) {
        guard let highlight = hoverHighlight else { return }

        let path = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        highlight.path = path.cgPath

        let targetOpacity: CGFloat = isHovered && !isSelected ? 1.0 : 0.0
        highlight.opacity = Float(targetOpacity)
    }

    // MARK: - Accessibility

    private func setupAccessibility() {
        setAccessibilityElement(true)
        setAccessibilityLabel(position.displayName)
        setAccessibilityRole(isSelected ? .radioButton : .button)
        setAccessibilityIdentifier(position.rawValue)

        toolTip = isSelected
            ? "Currently selected notification position. Press to confirm."
            : "Set notification position to \(position.displayName)"
    }

    private func observeAppearanceChanges() {
        NotificationCenter.default.addObserver(
            forName: AppearanceManager.appearanceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateStyle()
        }
    }

    // MARK: - Mouse Events

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard !isPressed else { return }
        isHovered = true
        animateHoverIn()
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard !isPressed else { return }
        isHovered = false
        animateHoverOut()
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        isPressed = true
        animatePressDown()
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        guard isPressed else { return }
        isPressed = false
        animatePressUp()
    }

    // MARK: - Animations

    private func animateHoverIn() {
        guard AppearanceManager.shared.shouldAnimate else {
            updateStyle()
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.springResponse
            context.timingFunction = Animation.defaultCurve
            context.allowsImplicitAnimation = true

            // Subtle scale up
            let scale: CGFloat = isSelected ? 1.02 : 1.05
            containerView.layer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))

            updateStyle()
        }
    }

    private func animateHoverOut() {
        guard AppearanceManager.shared.shouldAnimate else {
            updateStyle()
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.springResponse
            context.timingFunction = Animation.defaultCurve
            context.allowsImplicitAnimation = true

            // Return to normal scale
            containerView.layer?.setAffineTransform(.identity)

            updateStyle()
        }
    }

    private func animatePressDown() {
        guard AppearanceManager.shared.shouldAnimate else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.instant
            context.timingFunction = Animation.defaultCurve
            context.allowsImplicitAnimation = true

            // Scale down with spring
            let scale: CGFloat = 0.92
            containerView.layer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))

            // Enhance shadow
            containerView.layer?.shadowRadius = 6
            containerView.layer?.shadowOffset = NSSize(width: 0, height: -2)
        }

        // Haptic feedback
        #if os(iOS)
        #else
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
        )
        #endif
    }

    private func animatePressUp() {
        guard AppearanceManager.shared.shouldAnimate else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.springResponse
            context.timingFunction = Animation.defaultCurve
            context.allowsImplicitAnimation = true

            // Bounce back
            let scale: CGFloat = isHovered ? 1.05 : 1.0
            containerView.layer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))

            updateStyle()
        }
    }

    private func animateSelectionChange() {
        guard AppearanceManager.shared.shouldAnimate else {
            updateStyle()
            return
        }

        // Trigger haptic feedback
        #if os(iOS)
        #else
        NSHapticFeedbackManager.defaultPerformer.perform(
            .levelChange,
            performanceTime: .default
        )
        #endif

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.springResponse
            context.timingFunction = Animation.defaultCurve
            context.allowsImplicitAnimation = true

            // Pop animation for selection
            let scale: CGFloat = isSelected ? 1.08 : 1.0
            containerView.layer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))

            // Animate icon
            if let iconLayer = iconView?.layer {
                iconLayer.setAffineTransform(CGAffineTransform(scaleX: scale * 1.1, y: scale * 1.1))
            }

            updateStyle()

            // Return to final scale after pop
            DispatchQueue.main.asyncAfter(deadline: .now() + Animation.springResponse) { [self] in
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = Animation.fast
                    context.timingFunction = Animation.defaultCurve
                    context.allowsImplicitAnimation = true

                    let finalScale: CGFloat = self.isSelected ? 1.02 : 1.0
                    containerView.layer?.setAffineTransform(CGAffineTransform(scaleX: finalScale, y: finalScale))

                    if let iconLayer = self.iconView?.layer {
                        let iconScale: CGFloat = self.isSelected ? 1.1 : 1.0
                        iconLayer.setAffineTransform(CGAffineTransform(scaleX: iconScale, y: iconScale))
                    }
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func handleTap() {
        action(position)

        // Announce change
        AccessibilityManager.shared.announce(
            "Notification position changed to \(position.displayName)"
        )
    }

    // MARK: - Public Methods

    /// Updates the selected state of the button
    /// - Parameters:
    ///   - selected: The new selected state
    ///   - animated: Whether to animate the change
    func setSelected(_ selected: Bool, animated: Bool = true) {
        guard isSelected != selected else { return }

        isSelected = selected

        // Update accessibility
        setAccessibilityRole(isSelected ? .radioButton : .button)
        toolTip = isSelected
            ? "Currently selected notification position. Press to confirm."
            : "Set notification position to \(position.displayName)"

        // Update material
        backgroundEffectView.material = isSelected ? .selection : .titlebar

        if animated {
            animateSelectionChange()
        } else {
            updateStyle()
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
            // Animate focus ring
            animateFocusIn()

            // Announce focus
            AccessibilityManager.shared.announce(position.displayName)
        }

        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()

        if result {
            animateFocusOut()
        }

        return result
    }

    private func animateFocusIn() {
        guard AppearanceManager.shared.shouldAnimate else { return }

        // Focus is handled by system, but we can add subtle animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.fast
            context.allowsImplicitAnimation = true
            backgroundEffectView.layer?.borderWidth = 2.0
        }
    }

    private func animateFocusOut() {
        guard AppearanceManager.shared.shouldAnimate else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.instant
            context.allowsImplicitAnimation = true
            updateStyle()
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

    // MARK: - Layout

    override func layout() {
        super.layout()

        // Update layers when layout changes
        updateStyle()
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Factory Methods

extension PositionGridButton {

    /// Creates a grid button for the specified position
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

/// A container view that manages a grid of position buttons with smooth transitions
class PositionGridView: NSView {

    private var buttons: [PositionGridButton] = []
    private var currentSelection: NotificationPosition

    init(selection: NotificationPosition, onChange: @escaping (NotificationPosition) -> Void) {
        self.currentSelection = selection
        super.init(frame: .zero)
        setupGrid(onChange: onChange)
    }

    required init?(coder: NSCoder) {
        self.currentSelection = .topRight
        super.init(coder: coder)
        setupGrid { _ in }
    }

    private func setupGrid(onChange: @escaping (NotificationPosition) -> Void) {
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        let positions = NotificationPosition.allCases

        // Create 2x2 grid
        for (_, position) in positions.enumerated() {
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
            rowCount: 2,
            columnCount: 2
        )
    }

    private func setupGridConstraints() {
        let gridSize = Layout.gridSize
        let spacing = Layout.gridSpacing

        var constraints: [NSLayoutConstraint] = []

        for (index, button) in buttons.enumerated() {
            let row = index / 2
            let col = index % 2

            let x = CGFloat(col) * (gridSize + spacing)
            let y = CGFloat(row) * (gridSize + spacing)

            constraints.append(contentsOf: [
                button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: x),
                button.topAnchor.constraint(equalTo: topAnchor, constant: y),
                button.widthAnchor.constraint(equalToConstant: gridSize),
                button.heightAnchor.constraint(equalToConstant: gridSize)
            ])
        }

        // Set container size for 2x2 grid
        let totalWidth = (gridSize * 2) + spacing
        constraints.append(contentsOf: [
            widthAnchor.constraint(equalToConstant: totalWidth),
            heightAnchor.constraint(equalToConstant: totalWidth)
        ])

        NSLayoutConstraint.activate(constraints)
    }

    private func updateSelection(to position: NotificationPosition, onChange: @escaping (NotificationPosition) -> Void) {
        guard currentSelection != position else { return }

        currentSelection = position

        // Update all buttons with animation
        for button in buttons {
            button.setSelected(button.notificationPosition == position, animated: true)
        }

        onChange(position)
    }

    /// Updates the current selection
    /// - Parameter position: The new selected position
    func updateSelection(to position: NotificationPosition) {
        guard currentSelection != position else { return }
        currentSelection = position

        for button in buttons {
            button.setSelected(button.notificationPosition == position, animated: true)
        }
    }
}
