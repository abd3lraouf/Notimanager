//
//  WidgetPreviewOverlay.swift
//  Notimanager
//
//  Redesigned widget preview that shows notification position relative to the grid
//  Displays a visual indicator of where notifications will appear on screen
//

import AppKit
import Cocoa

/// Visual indicator showing where notifications will appear with interception status
class WidgetPreviewOverlay: NSView {

    // MARK: - UI Components

    private let positionIndicator: NSView
    private let previewBox: NSView
    private let interceptionBadge: InterceptionBadge
    private let positionLabel: NSTextField

    // MARK: - Properties

    private var currentPosition: NotificationPosition = .topRight
    private var isInterceptionEnabled: Bool = true

    // MARK: - Initialization

    init() {
        // Create preview box (the "notification")
        previewBox = NSView()
        previewBox.wantsLayer = true
        previewBox.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        previewBox.layer?.cornerRadius = 8
        previewBox.translatesAutoresizingMaskIntoConstraints = false

        // Create position indicator (dot showing where it will appear)
        positionIndicator = NSView()
        positionIndicator.wantsLayer = true
        positionIndicator.layer?.backgroundColor = NSColor.systemBlue.cgColor
        positionIndicator.layer?.cornerRadius = 6
        positionIndicator.translatesAutoresizingMaskIntoConstraints = false

        // Create interception badge
        interceptionBadge = InterceptionBadge()

        // Create position label
        positionLabel = NSTextField(labelWithString: "")
        positionLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        positionLabel.textColor = .secondaryLabelColor
        positionLabel.alignment = .center
        positionLabel.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: .zero)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false
        translatesAutoresizingMaskIntoConstraints = false

        // Add subviews
        addSubview(previewBox)
        addSubview(positionIndicator)
        addSubview(interceptionBadge)
        addSubview(positionLabel)

        // Setup constraints
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Preview box (small representation of a notification)
            previewBox.widthAnchor.constraint(equalToConstant: 40),
            previewBox.heightAnchor.constraint(equalToConstant: 40),
            previewBox.centerXAnchor.constraint(equalTo: centerXAnchor),
            previewBox.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Position indicator (dot)
            positionIndicator.widthAnchor.constraint(equalToConstant: 12),
            positionIndicator.heightAnchor.constraint(equalToConstant: 12),
            positionIndicator.centerXAnchor.constraint(equalTo: previewBox.centerXAnchor),
            positionIndicator.centerYAnchor.constraint(equalTo: previewBox.centerYAnchor),

            // Interception badge (top right of preview box)
            interceptionBadge.widthAnchor.constraint(equalToConstant: 20),
            interceptionBadge.heightAnchor.constraint(equalToConstant: 20),
            interceptionBadge.trailingAnchor.constraint(equalTo: trailingAnchor),
            interceptionBadge.topAnchor.constraint(equalTo: topAnchor),

            // Position label (below preview box)
            positionLabel.topAnchor.constraint(equalTo: previewBox.bottomAnchor, constant: 8),
            positionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            positionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            positionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }

    // MARK: - Public Methods

    /// Updates the preview based on position and interception settings
    func updatePreview(position: NotificationPosition, interceptWidgets: Bool) {
        self.currentPosition = position
        self.isInterceptionEnabled = interceptWidgets

        // Update position indicator to show where notification will appear
        updatePositionIndicator()

        // Update interception badge
        interceptionBadge.updateStatus(isIntercepting: interceptWidgets)

        // Update preview box styling
        previewBox.layer?.backgroundColor = interceptWidgets
            ? NSColor.controlAccentColor.cgColor
            : NSColor.systemGray.cgColor

        // Update position label
        positionLabel.stringValue = position.displayName

        // Animate the change
        animatePositionChange()
    }

    private func updatePositionIndicator() {
        // Position the indicator dot relative to the preview box
        // This shows where on the "screen" (preview box) the notification will appear

        let indicatorSize: CGFloat = 12
        let padding: CGFloat = 4

        // Remove existing constraints
        positionIndicator.constraints.forEach { $0.isActive = false }

        switch currentPosition {
        case .topLeft:
            NSLayoutConstraint.activate([
                positionIndicator.leadingAnchor.constraint(equalTo: previewBox.leadingAnchor, constant: padding),
                positionIndicator.topAnchor.constraint(equalTo: previewBox.topAnchor, constant: padding)
            ])
        case .topRight:
            NSLayoutConstraint.activate([
                positionIndicator.trailingAnchor.constraint(equalTo: previewBox.trailingAnchor, constant: -padding),
                positionIndicator.topAnchor.constraint(equalTo: previewBox.topAnchor, constant: padding)
            ])
        case .bottomLeft:
            NSLayoutConstraint.activate([
                positionIndicator.leadingAnchor.constraint(equalTo: previewBox.leadingAnchor, constant: padding),
                positionIndicator.bottomAnchor.constraint(equalTo: previewBox.bottomAnchor, constant: -padding)
            ])
        case .bottomRight:
            NSLayoutConstraint.activate([
                positionIndicator.trailingAnchor.constraint(equalTo: previewBox.trailingAnchor, constant: -padding),
                positionIndicator.bottomAnchor.constraint(equalTo: previewBox.bottomAnchor, constant: -padding)
            ])
        }

        // Update indicator color based on interception
        positionIndicator.layer?.backgroundColor = isInterceptionEnabled
            ? NSColor.systemGreen.cgColor
            : NSColor.systemOrange.cgColor
    }

    // MARK: - Animation

    private func animatePositionChange() {
        guard AppearanceManager.shared.shouldAnimate else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Animation.springResponse
            context.timingFunction = Animation.defaultCurve
            context.allowsImplicitAnimation = true

            // Subtle pulse animation
            let scale: CGFloat = 1.1
            previewBox.layer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))

            DispatchQueue.main.asyncAfter(deadline: .now() + Animation.springResponse) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = Animation.springResponse
                    context.timingFunction = Animation.defaultCurve
                    context.allowsImplicitAnimation = true
                    self.previewBox.layer?.setAffineTransform(.identity)
                }
            }
        }
    }
}

// MARK: - Interception Badge

/// Badge showing interception status with icon and color
class InterceptionBadge: NSView {

    private let backgroundLayer: CAShapeLayer
    private let iconLayer: CAShapeLayer
    private var status: InterceptionStatus = .intercepting

    enum InterceptionStatus {
        case intercepting
        case notIntercepting
    }

    init() {
        backgroundLayer = CAShapeLayer()
        iconLayer = CAShapeLayer()

        super.init(frame: .zero)

        setupBadge()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBadge() {
        wantsLayer = true
        layer?.addSublayer(backgroundLayer)
        layer?.addSublayer(iconLayer)

        updateStatus(isIntercepting: true)
    }

    func updateStatus(isIntercepting: Bool) {
        status = isIntercepting ? .intercepting : .notIntercepting

        let color: CGColor = isIntercepting ? NSColor.systemGreen.cgColor : NSColor.systemRed.cgColor

        // Update background
        backgroundLayer.fillColor = NSColor.windowBackgroundColor.cgColor
        backgroundLayer.strokeColor = color
        backgroundLayer.lineWidth = 2

        // Update icon
        iconLayer.strokeColor = color
        iconLayer.fillColor = NSColor.clear.cgColor
        iconLayer.lineWidth = 2

        // Trigger layout update
        needsLayout = true
        layout()
    }

    override func layout() {
        super.layout()

        let size = bounds.width
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        // Draw background circle
        backgroundLayer.path = CGPath(ellipseIn: CGRect(x: 2, y: 2, width: size - 4, height: size - 4), transform: nil)

        // Draw icon
        let iconPath: CGPath
        switch status {
        case .intercepting:
            // Checkmark
            iconPath = {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: center.x - 3, y: center.y))
                path.addLine(to: CGPoint(x: center.x, y: center.y + 3))
                path.addLine(to: CGPoint(x: center.x + 4, y: center.y - 4))
                return path
            }()
        case .notIntercepting:
            // X mark
            iconPath = {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: center.x - 2, y: center.y - 2))
                path.addLine(to: CGPoint(x: center.x + 2, y: center.y + 2))
                path.move(to: CGPoint(x: center.x + 2, y: center.y - 2))
                path.addLine(to: CGPoint(x: center.x - 2, y: center.y + 2))
                return path
            }()
        }

        iconLayer.path = iconPath
        iconLayer.lineCap = .round
        iconLayer.lineJoin = .round
    }
}
