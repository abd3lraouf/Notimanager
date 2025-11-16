import ApplicationServices
import Cocoa
import os.log
import UserNotifications

enum NotificationPosition: String, CaseIterable {
    case topLeft, topMiddle, topRight
    case middleLeft, deadCenter, middleRight
    case bottomLeft, bottomMiddle, bottomRight

    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topMiddle: return "Top Middle"
        case .topRight: return "Top Right"
        case .middleLeft: return "Middle Left"
        case .deadCenter: return "Middle"
        case .middleRight: return "Middle Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomMiddle: return "Bottom Middle"
        case .bottomRight: return "Bottom Right"
        }
    }
}

class NotificationMover: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let notificationCenterBundleID: String = "com.apple.notificationcenterui"
    private let paddingAboveDock: CGFloat = 30
    private var axObserver: AXObserver?
    private var statusItem: NSStatusItem?
    private var isMenuBarIconHidden: Bool = UserDefaults.standard.bool(forKey: "isMenuBarIconHidden")
    private let logger: Logger = .init(subsystem: "dev.abd3lraouf.notimanager", category: "NotificationMover")
    private var debugMode: Bool = UserDefaults.standard.bool(forKey: "debugMode")
    private let launchAgentPlistPath: String = NSHomeDirectory() + "/Library/LaunchAgents/dev.abd3lraouf.notimanager.plist"
    private var settingsWindow: NSWindow?
    private var testStatusLabel: NSTextField?
    private var lastNotificationTime: Date?
    private var notificationWasIntercepted: Bool = false

    private var cachedInitialNotifSize: CGSize?
    private var cachedInitialPadding: CGFloat?

    private var widgetMonitorTimer: Timer?
    private var lastWidgetWindowCount: Int = 0
    private var pollingEndTime: Date?
    private let osVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion

    private var hasLoggedEmptyWidget: Bool = false

    private lazy var notificationSubroles: [String] = {
        if osVersion.majorVersion >= 26 {
            // macOS 26+ may use new subrole naming
            debugLog("macOS 26+ detected - using expanded subrole search")
            return [
                "AXNotificationCenterBanner",
                "AXNotificationCenterAlert",
                "AXNotification",
                "AXBanner",
                "AXAlert",
                "AXSystemDialog",
                "AXNotificationBanner",  // Potential macOS 26 name
                "AXNotificationAlert",   // Potential macOS 26 name
                "AXFloatingPanel",       // Alternative structure
                "AXPanel"                // Simplified panel name
            ]
        } else if osVersion.majorVersion >= 15 {
            // macOS 15-25 subroles
            return [
                "AXNotificationCenterBanner",
                "AXNotificationCenterAlert",
                "AXNotification",  // Potential new name
                "AXBanner",        // Potential simplified name
                "AXAlert",         // Potential simplified name
                "AXSystemDialog"   // Potential alternative
            ]
        } else {
            return ["AXNotificationCenterBanner", "AXNotificationCenterAlert"]
        }
    }()

    private var currentPosition: NotificationPosition = {
        guard let rawValue: String = UserDefaults.standard.string(forKey: "notificationPosition"),
              let position = NotificationPosition(rawValue: rawValue)
        else {
            return .topMiddle
        }
        return position
    }()

    fileprivate func debugLog(_ message: String) {
        guard debugMode else { return }
        logger.info("\(message, privacy: .public)")
    }

    func applicationDidFinishLaunching(_: Notification) {
        logSystemInfo()
        requestNotificationPermissions()
        checkAccessibilityPermissions()
        setupObserver()
        if !isMenuBarIconHidden {
            setupStatusItem()
        }
        moveAllNotifications()
    }

    private func requestNotificationPermissions() {
        debugLog("Requesting notification permissions...")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                self.debugLog("Error requesting notification permissions: \(error)")
            } else {
                self.debugLog("Notification permissions granted: \(granted)")
            }
        }
    }

    func applicationWillBecomeActive(_: Notification) {
        guard isMenuBarIconHidden else { return }
        isMenuBarIconHidden = false
        UserDefaults.standard.set(false, forKey: "isMenuBarIconHidden")
        setupStatusItem()
    }

    func applicationWillTerminate(_: Notification) {
        // Clean up timers
        permissionPollingTimer?.invalidate()
        widgetMonitorTimer?.invalidate()
        debugLog("App terminating - cleaned up timers")
    }

    private var permissionWindow: NSWindow?
    private var permissionPollingTimer: Timer?
    private var statusLabel: NSTextField?
    private var statusIndicator: NSTextField?
    private var requestButton: NSButton?

    private func checkAccessibilityPermissions() {
        // Check current permission status without prompting
        let isCurrentlyTrusted = AXIsProcessTrusted()
        debugLog("Accessibility permission check - Currently trusted: \(isCurrentlyTrusted)")

        if isCurrentlyTrusted {
            debugLog("✓ Accessibility permissions already granted")
            return
        }

        // Not trusted - show permission status window
        debugLog("Accessibility permissions not granted - showing status window")
        showPermissionStatusWindow()
    }

    private func showPermissionStatusWindow() {
        // Create window if it doesn't exist
        if permissionWindow == nil {
            // Golden ratio dimensions (φ ≈ 1.618)
            let phi: CGFloat = 1.618
            let windowWidth: CGFloat = 520

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: 460),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Notimanager Setup"
            window.titlebarAppearsTransparent = true
            window.level = .floating
            window.isMovableByWindowBackground = true

            let contentView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: 460))
            contentView.material = .hudWindow
            contentView.blendingMode = .behindWindow
            contentView.state = .active

            // Golden ratio based spacing
            let baseUnit: CGFloat = 20 // Base spacing unit

            // Calculate positions using golden ratio
            let bottomMargin = baseUnit * phi // ~32
            let spacing1 = baseUnit * 1.5 // ~30 (button to card)
            let spacing2 = baseUnit * phi // ~32 (card to subtitle)
            let spacing3 = baseUnit // 20 (subtitle to title)
            let spacing4 = baseUnit * 1.25 // ~25 (title to icon)

            let buttonHeight: CGFloat = 44 // Apple's recommended touch target
            let statusCardHeight: CGFloat = 72
            let iconSize: CGFloat = 100 // Larger, more prominent

            // Bottom-up layout calculation
            var yPos = bottomMargin
            let buttonY = yPos

            yPos += buttonHeight + spacing1
            let statusCardY = yPos

            yPos += statusCardHeight + spacing2
            let subtitleY = yPos
            let subtitleHeight: CGFloat = 44

            yPos += subtitleHeight + spacing3
            let titleY = yPos
            let titleHeight: CGFloat = 36

            yPos += titleHeight + spacing4
            let iconY = yPos

            // App Icon with refined styling (golden ratio proportions)
            let iconContainer = NSView(frame: NSRect(x: (windowWidth - iconSize) / 2, y: iconY, width: iconSize, height: iconSize))
            iconContainer.wantsLayer = true

            // Subtle gradient with golden ratio opacity
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
            gradientLayer.colors = [
                NSColor.white.cgColor,
                NSColor.white.withAlphaComponent(0.92).cgColor
            ]
            gradientLayer.locations = [0.0, 1.0]

            // Golden ratio based corner radius
            let cornerRadius = iconSize / phi / 1.5 // ~24
            gradientLayer.cornerRadius = cornerRadius
            iconContainer.layer?.addSublayer(gradientLayer)

            // Refined shadow with depth
            iconContainer.layer?.shadowColor = NSColor.black.cgColor
            iconContainer.layer?.shadowOpacity = 0.18
            iconContainer.layer?.shadowOffset = CGSize(width: 0, height: 6)
            iconContainer.layer?.shadowRadius = 16
            iconContainer.layer?.cornerRadius = cornerRadius
            iconContainer.layer?.masksToBounds = false

            contentView.addSubview(iconContainer)

            // Icon inset using golden ratio
            let iconInset = iconSize / phi / 3 // ~13
            let iconView = NSImageView(frame: NSRect(x: iconInset, y: iconInset, width: iconSize - (iconInset * 2), height: iconSize - (iconInset * 2)))
            if let icon = NSImage(named: "icon") {
                iconView.image = icon
                iconView.imageScaling = .scaleProportionallyDown
            }
            iconContainer.addSubview(iconView)

            // Title with refined typography
            let sideMargin = baseUnit * 2 // 40
            let titleLabel = NSTextField(labelWithString: "Welcome to Notimanager")
            titleLabel.frame = NSRect(x: sideMargin, y: titleY, width: windowWidth - (sideMargin * 2), height: titleHeight)
            titleLabel.alignment = .center
            titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)
            titleLabel.textColor = .labelColor
            titleLabel.isBezeled = false
            titleLabel.isEditable = false
            titleLabel.isSelectable = false
            titleLabel.drawsBackground = false
            contentView.addSubview(titleLabel)

            // Subtitle with optimal line height
            let subtitleMargin = baseUnit * 3 // 60
            let subtitleLabel = NSTextField(wrappingLabelWithString: "Position your notifications anywhere on screen. Grant Accessibility permission to get started.")
            subtitleLabel.frame = NSRect(x: subtitleMargin, y: subtitleY, width: windowWidth - (subtitleMargin * 2), height: subtitleHeight)
            subtitleLabel.alignment = .center
            subtitleLabel.font = .systemFont(ofSize: 14)
            subtitleLabel.textColor = .secondaryLabelColor
            subtitleLabel.maximumNumberOfLines = 2
            subtitleLabel.lineBreakMode = .byWordWrapping
            subtitleLabel.isBezeled = false
            subtitleLabel.isEditable = false
            subtitleLabel.isSelectable = false
            subtitleLabel.drawsBackground = false
            subtitleLabel.lineBreakMode = .byWordWrapping
            subtitleLabel.usesSingleLineMode = false
            subtitleLabel.cell?.wraps = true
            contentView.addSubview(subtitleLabel)

            // Status indicator with refined glassmorphism
            let cardMargin = baseUnit * 2.5 // 50
            let statusCard = NSVisualEffectView(frame: NSRect(x: cardMargin, y: statusCardY, width: windowWidth - (cardMargin * 2), height: statusCardHeight))
            statusCard.material = NSVisualEffectView.Material.contentBackground
            statusCard.blendingMode = NSVisualEffectView.BlendingMode.withinWindow
            statusCard.state = NSVisualEffectView.State.active
            statusCard.wantsLayer = true

            // Golden ratio corner radius
            let cardCornerRadius = statusCardHeight / phi / 1.2 // ~16
            statusCard.layer?.cornerRadius = cardCornerRadius
            statusCard.layer?.borderWidth = 0.5
            statusCard.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.25).cgColor

            // Subtle inner shadow effect
            statusCard.layer?.shadowColor = NSColor.black.cgColor
            statusCard.layer?.shadowOpacity = 0.05
            statusCard.layer?.shadowOffset = CGSize(width: 0, height: 2)
            statusCard.layer?.shadowRadius = 4

            contentView.addSubview(statusCard)

            // Status icon with better proportions
            let iconPadding = baseUnit * 1.2 // ~24
            let statusIconSize: CGFloat = 36
            let statusIconView = NSImageView(frame: NSRect(x: iconPadding, y: (statusCardHeight - statusIconSize) / 2, width: statusIconSize, height: statusIconSize))
            if let warningImage = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Warning") {
                statusIconView.image = warningImage
                statusIconView.contentTintColor = .systemOrange
                statusIconView.imageScaling = .scaleProportionallyDown
            }
            statusCard.addSubview(statusIconView)

            // Status text with better vertical centering
            let textX = iconPadding + statusIconSize + baseUnit
            let statusTitle = NSTextField(labelWithString: "Accessibility Permission Required")
            statusTitle.frame = NSRect(x: textX, y: (statusCardHeight - 20) / 2, width: statusCard.frame.width - textX - baseUnit, height: 20)
            statusTitle.font = .systemFont(ofSize: 15, weight: .medium)
            statusTitle.textColor = .labelColor
            statusTitle.isBezeled = false
            statusTitle.isEditable = false
            statusTitle.isSelectable = false
            statusTitle.drawsBackground = false
            statusCard.addSubview(statusTitle)

            let statusTitleRef = statusTitle

            // Buttons with golden ratio proportions
            let buttonMargin = baseUnit * 2.5 // 50
            let buttonSpacing = baseUnit * 0.8 // ~16
            let totalButtonWidth = windowWidth - (buttonMargin * 2)

            // Primary button takes phi/(phi+1) of space ≈ 61.8%
            let primaryButtonWidth = totalButtonWidth * (phi / (phi + 1)) - (buttonSpacing / 2)
            let secondaryButtonWidth = totalButtonWidth - primaryButtonWidth - buttonSpacing

            let requestBtn = NSButton(frame: NSRect(x: buttonMargin, y: buttonY, width: primaryButtonWidth, height: buttonHeight))
            requestBtn.title = "Open System Settings"
            requestBtn.bezelStyle = NSButton.BezelStyle.rounded
            requestBtn.controlSize = NSControl.ControlSize.large
            requestBtn.keyEquivalent = "\r"
            requestBtn.target = self
            requestBtn.action = #selector(requestAccessibilityPermission)
            contentView.addSubview(requestBtn)
            requestButton = requestBtn

            // Secondary button - Clear Permission (always visible)
            let clearBtn = NSButton(frame: NSRect(x: buttonMargin + primaryButtonWidth + buttonSpacing, y: buttonY, width: secondaryButtonWidth, height: buttonHeight))
            clearBtn.title = "Clear Permission"
            clearBtn.bezelStyle = NSButton.BezelStyle.rounded
            clearBtn.controlSize = NSControl.ControlSize.large
            clearBtn.target = self
            clearBtn.action = #selector(resetAccessibilityPermission)
            contentView.addSubview(clearBtn)

            // Restart button (initially hidden, shown when permission granted)
            let restartButtonWidth: CGFloat = 200
            let resetBtn = NSButton(frame: NSRect(x: (windowWidth - restartButtonWidth) / 2, y: buttonY, width: restartButtonWidth, height: buttonHeight))
            resetBtn.title = "Restart App"
            resetBtn.bezelStyle = NSButton.BezelStyle.rounded
            resetBtn.controlSize = NSControl.ControlSize.large
            resetBtn.keyEquivalent = "\r" // Make it the default action when permission is granted
            resetBtn.target = self
            resetBtn.action = #selector(restartApp)
            resetBtn.isHidden = true
            contentView.addSubview(resetBtn)

            window.contentView = contentView
            permissionWindow = window

            // Store references for updates
            objc_setAssociatedObject(window, "statusCard", statusCard, .OBJC_ASSOCIATION_RETAIN)
            objc_setAssociatedObject(window, "statusIconView", statusIconView, .OBJC_ASSOCIATION_RETAIN)
            objc_setAssociatedObject(window, "statusTitleRef", statusTitleRef, .OBJC_ASSOCIATION_RETAIN)
            objc_setAssociatedObject(window, "resetBtn", resetBtn, .OBJC_ASSOCIATION_RETAIN)

            // Start polling for status updates
            startPermissionPolling()
        }

        permissionWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func resetAccessibilityPermission() {
        debugLog("User requested to clear accessibility permissions")

        let alert = NSAlert()
        alert.messageText = "Clear Permission?"
        alert.informativeText = """
        This will clear Notimanager's accessibility permission.

        What happens next:
        • Accessibility permission will be reset
        • You'll need to grant permission again
        • The app will continue running

        This is useful for troubleshooting permission issues.
        """
        alert.alertStyle = .warning
        alert.icon = NSImage(systemSymbolName: "trash", accessibilityDescription: "Clear")
        alert.addButton(withTitle: "Clear Permission")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            debugLog("Clearing accessibility permissions...")

            // Run tccutil to reset permissions
            let task = Process()
            task.launchPath = "/usr/bin/tccutil"
            task.arguments = ["reset", "Accessibility", "dev.abd3lraouf.notimanager"]

            do {
                try task.run()
                task.waitUntilExit()

                debugLog("Permission cleared successfully")

                // Update UI to show permission required state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let success = NSAlert()
                    success.messageText = "Permission Cleared"
                    success.informativeText = "Accessibility permission has been reset.\n\nYou can grant it again using the button below."
                    success.alertStyle = .informational
                    success.runModal()

                    // Update the permission window to show "permission required" state
                    self.updatePermissionStatus(granted: false)

                    // Start polling again in case user wants to grant permission
                    self.startPermissionPolling()
                }
            } catch {
                debugLog("Failed to clear permission: \(error)")
                showError("Failed to clear permission: \(error.localizedDescription)")
            }
        }
    }

    @objc private func requestAccessibilityPermission() {
        debugLog("User requested accessibility permission")

        // Show system prompt
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)

        // Update UI
        requestButton?.title = "Waiting..."
        requestButton?.isEnabled = false

        // Update status title
        if let window = permissionWindow,
           let statusTitleRef = objc_getAssociatedObject(window, "statusTitleRef") as? NSTextField {
            statusTitleRef.stringValue = "Waiting for permission..."
            statusTitleRef.textColor = .secondaryLabelColor
        }

        // Polling will detect when permission is granted
    }

    private func startPermissionPolling() {
        permissionPollingTimer?.invalidate()
        debugLog("Starting permission status polling...")

        permissionPollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let isGranted = AXIsProcessTrusted()

            if isGranted {
                self.debugLog("✓ Accessibility permission granted!")
                self.updatePermissionStatus(granted: true)
                self.permissionPollingTimer?.invalidate()
                // Restart button will be shown by updatePermissionStatus
            } else {
                self.updatePermissionStatus(granted: false)
            }
        }
    }


    @objc private func restartApp() {
        debugLog("Restarting app...")

        let task = Process()
        task.launchPath = "/usr/bin/open"
        // Use -n to force a new instance and -a to specify the app
        task.arguments = ["-n", "-a", Bundle.main.bundlePath]

        do {
            try task.run()
            debugLog("New instance launched, waiting before quit...")

            // Wait longer to ensure new instance starts before we quit
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.debugLog("Terminating current instance...")
                NSApplication.shared.terminate(nil)
            }
        } catch {
            debugLog("Failed to relaunch: \(error)")
            showError("Failed to restart app: \(error.localizedDescription)")
        }
    }

    private func updatePermissionStatus(granted: Bool) {
        DispatchQueue.main.async {
            guard let window = self.permissionWindow else { return }

            // Get stored references
            guard let statusCard = objc_getAssociatedObject(window, "statusCard") as? NSVisualEffectView,
                  let statusIconView = objc_getAssociatedObject(window, "statusIconView") as? NSImageView,
                  let statusTitleRef = objc_getAssociatedObject(window, "statusTitleRef") as? NSTextField,
                  let resetBtn = objc_getAssociatedObject(window, "resetBtn") as? NSButton else {
                return
            }

            if granted {
                // Update to success state
                if let successImage = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Success") {
                    statusIconView.image = successImage
                    statusIconView.contentTintColor = .systemGreen
                }

                statusTitleRef.stringValue = "Permission Granted! ✓"
                statusTitleRef.textColor = .systemGreen

                statusCard.layer?.borderColor = NSColor.systemGreen.withAlphaComponent(0.5).cgColor

                // Hide main buttons, show restart button
                self.requestButton?.isHidden = true

                // Get clear button and hide it too
                if let contentView = window.contentView {
                    for view in contentView.subviews {
                        if let button = view as? NSButton, button.title == "Clear Permission" {
                            button.isHidden = true
                        }
                    }
                }

                resetBtn.isHidden = false
            } else {
                // Update to waiting state
                if let warningImage = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Warning") {
                    statusIconView.image = warningImage
                    statusIconView.contentTintColor = .systemOrange
                }

                statusTitleRef.stringValue = "Accessibility Permission Required"
                statusTitleRef.textColor = .labelColor

                statusCard.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.3).cgColor

                // Show main buttons, hide restart
                self.requestButton?.isHidden = false
                self.requestButton?.isEnabled = true
                self.requestButton?.title = "Open System Settings"

                // Show clear button
                if let contentView = window.contentView {
                    for view in contentView.subviews {
                        if let button = view as? NSButton, button.title == "Clear Permission" {
                            button.isHidden = false
                        }
                    }
                }

                resetBtn.isHidden = true
            }
        }
    }

    func setupStatusItem() {
        guard !isMenuBarIconHidden else {
            statusItem = nil
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button: NSStatusBarButton = statusItem?.button, let menuBarIcon = NSImage(named: "MenuBarIcon") {
            menuBarIcon.isTemplate = true
            button.image = menuBarIcon
        }
        statusItem?.menu = createMenu()
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        // Quick position selector
        for position: NotificationPosition in NotificationPosition.allCases {
            let item = NSMenuItem(title: position.displayName, action: #selector(changePosition(_:)), keyEquivalent: "")
            item.representedObject = position
            item.state = position == currentPosition ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Main actions
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About Notimanager", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Notimanager", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        return menu
    }

    @objc private func openKofi() {
        NSWorkspace.shared.open(URL(string: "https://ko-fi.com/wadegrimridge")!)
    }

    @objc private func openBuyMeACoffee() {
        NSWorkspace.shared.open(URL(string: "https://www.buymeacoffee.com/wadegrimridge")!)
    }

    @objc private func showPermissionStatus() {
        debugLog("User requested to view permission status")
        showPermissionStatusWindow()
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            createSettingsWindow()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createSettingsWindow() {
        // Golden ratio for beautiful proportions (φ ≈ 1.618)
        let phi: CGFloat = 1.618
        let windowWidth: CGFloat = 600
        let windowHeight: CGFloat = 780

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Notimanager"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.delegate = self

        // Liquid glass background
        let contentView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        contentView.material = .hudWindow
        contentView.blendingMode = .behindWindow
        contentView.state = .active
        contentView.wantsLayer = true

        // Golden ratio spacing system
        let baseUnit: CGFloat = 12.0
        let spacing1 = baseUnit * phi // ~19.4px (small spacing)
        let spacing2 = baseUnit * phi * phi // ~31.4px (medium spacing)
        let margin = spacing2 // ~31px
        let cardPadding = spacing1 // ~19px

        var yPos: CGFloat = windowHeight - 84 // Start below titlebar with golden ratio

        // === NOTIFICATION POSITION SECTION ===
        let positionCardHeight: CGFloat = 330
        let positionSectionCard = createLiquidGlassCard(
            x: margin,
            y: 0,
            width: windowWidth - (margin * 2),
            height: positionCardHeight
        )

        // Section header
        let positionLabel = NSTextField(labelWithString: "Notification Position")
        positionLabel.frame = NSRect(x: cardPadding, y: positionCardHeight - 36, width: positionSectionCard.frame.width - (cardPadding * 2), height: 28)
        positionLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        positionLabel.textColor = .labelColor
        positionSectionCard.addSubview(positionLabel)

        // Position grid selector (3x3 grid) with golden ratio sizing
        let gridSize: CGFloat = 80
        let gridSpacing: CGFloat = spacing1
        let totalGridWidth = (gridSize * 3) + (gridSpacing * 2)
        let gridStartX: CGFloat = (positionSectionCard.frame.width - totalGridWidth) / 2
        let gridStartY: CGFloat = cardPadding + 10

        for (index, position) in NotificationPosition.allCases.enumerated() {
            let row = index / 3
            let col = index % 3
            let x = gridStartX + CGFloat(col) * (gridSize + gridSpacing)
            let y = gridStartY + CGFloat(2 - row) * (gridSize + gridSpacing)

            // Create button container for liquid glass effect
            let buttonContainer = NSVisualEffectView(frame: NSRect(x: x, y: y, width: gridSize, height: gridSize))
            buttonContainer.material = position == currentPosition ? .selection : .underWindowBackground
            buttonContainer.blendingMode = .withinWindow
            buttonContainer.state = .active
            buttonContainer.wantsLayer = true

            let cornerRadius: CGFloat = gridSize / phi / 1.2 // ~14px with golden ratio
            buttonContainer.layer?.cornerRadius = cornerRadius
            buttonContainer.layer?.borderWidth = position == currentPosition ? 2.5 : 1
            buttonContainer.layer?.borderColor = position == currentPosition
                ? NSColor.controlAccentColor.cgColor
                : NSColor.separatorColor.withAlphaComponent(0.4).cgColor

            // Add subtle shadow
            buttonContainer.shadow = NSShadow()
            buttonContainer.shadow?.shadowColor = NSColor.black.withAlphaComponent(position == currentPosition ? 0.15 : 0.08)
            buttonContainer.shadow?.shadowOffset = NSSize(width: 0, height: -1)
            buttonContainer.shadow?.shadowBlurRadius = position == currentPosition ? 6 : 3

            // Create clickable button overlay
            let button = NSButton(frame: NSRect(x: 0, y: 0, width: gridSize, height: gridSize))
            button.title = ""
            button.bezelStyle = .shadowlessSquare
            button.isBordered = false
            button.tag = index
            button.target = self
            button.action = #selector(settingsPositionChanged(_:))
            button.toolTip = position.displayName
            button.wantsLayer = true
            button.layer?.backgroundColor = .clear

            if let icon = getPositionIcon(for: position) {
                let iconSize: CGFloat = 32
                let iconPadding = (gridSize - iconSize) / 2
                let iconView = NSImageView(frame: NSRect(x: iconPadding, y: iconPadding, width: iconSize, height: iconSize))
                iconView.image = icon
                iconView.contentTintColor = position == currentPosition ? .controlAccentColor : .tertiaryLabelColor
                iconView.imageScaling = .scaleProportionallyDown
                button.addSubview(iconView)
            }

            buttonContainer.addSubview(button)
            positionSectionCard.addSubview(buttonContainer)
        }

        positionSectionCard.frame.origin.y = yPos - positionCardHeight
        contentView.addSubview(positionSectionCard)
        yPos = positionSectionCard.frame.origin.y - spacing2

        // === TEST & PERMISSIONS SECTION ===
        let testPermCardHeight: CGFloat = 180
        let testPermCard = createLiquidGlassCard(
            x: margin,
            y: 0,
            width: windowWidth - (margin * 2),
            height: testPermCardHeight
        )

        var innerY: CGFloat = testPermCardHeight - 36

        // Test Notification subsection
        let testLabel = NSTextField(labelWithString: "Test Notification")
        testLabel.frame = NSRect(x: cardPadding, y: innerY, width: testPermCard.frame.width - (cardPadding * 2), height: 24)
        testLabel.font = .systemFont(ofSize: 15, weight: .medium)
        testPermCard.addSubview(testLabel)
        innerY -= 40

        let testButton = NSButton(frame: NSRect(x: cardPadding, y: innerY, width: 140, height: 32))
        testButton.title = "Send Test"
        testButton.bezelStyle = .rounded
        testButton.controlSize = .large
        testButton.target = self
        testButton.action = #selector(sendTestNotification)
        testPermCard.addSubview(testButton)

        let statusLabel = NSTextField(labelWithString: "Not tested yet")
        statusLabel.frame = NSRect(x: cardPadding + 150, y: innerY + 8, width: testPermCard.frame.width - cardPadding - 160, height: 18)
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .tertiaryLabelColor
        testPermCard.addSubview(statusLabel)
        testStatusLabel = statusLabel
        innerY -= 42

        // Subtle separator
        let separator = NSBox(frame: NSRect(x: cardPadding, y: innerY, width: testPermCard.frame.width - (cardPadding * 2), height: 1))
        separator.boxType = .separator
        separator.alphaValue = 0.3
        testPermCard.addSubview(separator)
        innerY -= 30

        // Permission subsection
        let isGranted = AXIsProcessTrusted()
        let permLabel = NSTextField(labelWithString: "Accessibility")
        permLabel.frame = NSRect(x: cardPadding, y: innerY, width: 150, height: 24)
        permLabel.font = .systemFont(ofSize: 15, weight: .medium)
        testPermCard.addSubview(permLabel)

        let permStatusLabel = NSTextField(labelWithString: isGranted ? "Granted" : "Required")
        permStatusLabel.frame = NSRect(x: cardPadding + 120, y: innerY + 2, width: 120, height: 18)
        permStatusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        permStatusLabel.textColor = isGranted ? .systemGreen : .systemOrange
        testPermCard.addSubview(permStatusLabel)
        innerY -= 36

        if isGranted {
            let clearBtn = NSButton(frame: NSRect(x: testPermCard.frame.width - cardPadding - 230, y: innerY, width: 110, height: 28))
            clearBtn.title = "Clear"
            clearBtn.bezelStyle = .rounded
            clearBtn.controlSize = .small
            clearBtn.target = self
            clearBtn.action = #selector(settingsResetPermission)
            testPermCard.addSubview(clearBtn)

            let restartBtn = NSButton(frame: NSRect(x: testPermCard.frame.width - cardPadding - 110, y: innerY, width: 110, height: 28))
            restartBtn.title = "Restart App"
            restartBtn.bezelStyle = .rounded
            restartBtn.controlSize = .small
            restartBtn.target = self
            restartBtn.action = #selector(settingsRestartApp)
            testPermCard.addSubview(restartBtn)
        } else {
            let requestBtn = NSButton(frame: NSRect(x: testPermCard.frame.width - cardPadding - 180, y: innerY, width: 180, height: 28))
            requestBtn.title = "Open System Settings"
            requestBtn.bezelStyle = .rounded
            requestBtn.controlSize = .small
            requestBtn.target = self
            requestBtn.action = #selector(showPermissionStatus)
            testPermCard.addSubview(requestBtn)
        }

        testPermCard.frame.origin.y = yPos - testPermCardHeight
        contentView.addSubview(testPermCard)
        yPos = testPermCard.frame.origin.y - spacing2

        // === PREFERENCES SECTION ===
        let prefsCardHeight: CGFloat = 140
        let prefsCard = createLiquidGlassCard(
            x: margin,
            y: 0,
            width: windowWidth - (margin * 2),
            height: prefsCardHeight
        )

        innerY = prefsCardHeight - 36

        let prefsLabel = NSTextField(labelWithString: "Preferences")
        prefsLabel.frame = NSRect(x: cardPadding, y: innerY, width: prefsCard.frame.width - (cardPadding * 2), height: 24)
        prefsLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        prefsCard.addSubview(prefsLabel)
        innerY -= 34

        let launchCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(settingsLaunchToggled(_:)))
        launchCheckbox.frame = NSRect(x: cardPadding, y: innerY, width: prefsCard.frame.width - (cardPadding * 2), height: 20)
        launchCheckbox.state = FileManager.default.fileExists(atPath: launchAgentPlistPath) ? .on : .off
        launchCheckbox.font = .systemFont(ofSize: 13)
        prefsCard.addSubview(launchCheckbox)
        innerY -= 28

        let debugCheckbox = NSButton(checkboxWithTitle: "Debug mode", target: self, action: #selector(settingsDebugToggled(_:)))
        debugCheckbox.frame = NSRect(x: cardPadding, y: innerY, width: prefsCard.frame.width - (cardPadding * 2), height: 20)
        debugCheckbox.state = debugMode ? .on : .off
        debugCheckbox.font = .systemFont(ofSize: 13)
        prefsCard.addSubview(debugCheckbox)
        innerY -= 28

        let hideIconCheckbox = NSButton(checkboxWithTitle: "Hide menu bar icon", target: self, action: #selector(settingsHideIconToggled(_:)))
        hideIconCheckbox.frame = NSRect(x: cardPadding, y: innerY, width: prefsCard.frame.width - (cardPadding * 2), height: 20)
        hideIconCheckbox.state = isMenuBarIconHidden ? .on : .off
        hideIconCheckbox.font = .systemFont(ofSize: 13)
        prefsCard.addSubview(hideIconCheckbox)

        prefsCard.frame.origin.y = yPos - prefsCardHeight
        contentView.addSubview(prefsCard)
        yPos = prefsCard.frame.origin.y - spacing2

        // === ABOUT SECTION ===
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let aboutCardHeight: CGFloat = 110
        let aboutCard = createLiquidGlassCard(
            x: margin,
            y: 0,
            width: windowWidth - (margin * 2),
            height: aboutCardHeight
        )

        innerY = aboutCardHeight - 36

        let versionLabel = NSTextField(labelWithString: "Notimanager v\(version)")
        versionLabel.frame = NSRect(x: cardPadding, y: innerY, width: aboutCard.frame.width - (cardPadding * 2), height: 22)
        versionLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        aboutCard.addSubview(versionLabel)
        innerY -= 26

        let madeByLabel = NSTextField(labelWithString: "Made with ❤️  by Wade Grimridge")
        madeByLabel.frame = NSRect(x: cardPadding, y: innerY, width: aboutCard.frame.width - (cardPadding * 2), height: 18)
        madeByLabel.font = .systemFont(ofSize: 12)
        madeByLabel.textColor = .tertiaryLabelColor
        aboutCard.addSubview(madeByLabel)
        innerY -= 36

        let kofiBtn = NSButton(frame: NSRect(x: cardPadding, y: innerY, width: 150, height: 28))
        kofiBtn.title = "Support on Ko-fi"
        kofiBtn.bezelStyle = .rounded
        kofiBtn.controlSize = .small
        kofiBtn.target = self
        kofiBtn.action = #selector(openKofi)
        aboutCard.addSubview(kofiBtn)

        let coffeeBtn = NSButton(frame: NSRect(x: cardPadding + 160, y: innerY, width: 160, height: 28))
        coffeeBtn.title = "Buy Me a Coffee"
        coffeeBtn.bezelStyle = .rounded
        coffeeBtn.controlSize = .small
        coffeeBtn.target = self
        coffeeBtn.action = #selector(openBuyMeACoffee)
        aboutCard.addSubview(coffeeBtn)

        aboutCard.frame.origin.y = yPos - aboutCardHeight
        contentView.addSubview(aboutCard)

        window.contentView = contentView
        settingsWindow = window
    }

    private func createLiquidGlassCard(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSVisualEffectView {
        let phi: CGFloat = 1.618

        // Create liquid glass card
        let card = NSVisualEffectView(frame: NSRect(x: x, y: y, width: width, height: height))
        card.material = .underWindowBackground
        card.blendingMode = .withinWindow
        card.state = .active
        card.wantsLayer = true

        // Golden ratio corner radius
        let cornerRadius = height / phi / 3.5 // Dynamic based on card height
        card.layer?.cornerRadius = min(cornerRadius, 16) // Cap at 16px
        card.layer?.borderWidth = 0.5
        card.layer?.borderColor = NSColor.white.withAlphaComponent(0.1).cgColor

        // Enhanced shadow for depth
        card.shadow = NSShadow()
        card.shadow?.shadowColor = NSColor.black.withAlphaComponent(0.12)
        card.shadow?.shadowOffset = NSSize(width: 0, height: -3)
        card.shadow?.shadowBlurRadius = 12

        // Inner glow effect
        let innerGlow = CALayer()
        innerGlow.frame = card.bounds
        innerGlow.cornerRadius = card.layer!.cornerRadius
        innerGlow.borderWidth = 1
        innerGlow.borderColor = NSColor.white.withAlphaComponent(0.05).cgColor
        innerGlow.masksToBounds = true
        card.layer?.insertSublayer(innerGlow, at: 0)

        return card
    }

    private func getPositionIcon(for position: NotificationPosition) -> NSImage? {
        let symbolName: String
        switch position {
        case .topLeft: symbolName = "arrow.up.left"
        case .topMiddle: symbolName = "arrow.up"
        case .topRight: symbolName = "arrow.up.right"
        case .middleLeft: symbolName = "arrow.left"
        case .deadCenter: symbolName = "circle.fill"
        case .middleRight: symbolName = "arrow.right"
        case .bottomLeft: symbolName = "arrow.down.left"
        case .bottomMiddle: symbolName = "arrow.down"
        case .bottomRight: symbolName = "arrow.down.right"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: position.displayName)?
            .withSymbolConfiguration(config)
    }

    @objc private func settingsPositionChanged(_ sender: NSButton) {
        let position = NotificationPosition.allCases[sender.tag]
        currentPosition = position
        UserDefaults.standard.set(position.rawValue, forKey: "notificationPosition")

        cachedInitialNotifSize = nil
        cachedInitialPadding = nil

        debugLog("Position changed to: \(position.displayName)")
        moveAllNotifications()

        // Update all button container styling
        if let window = settingsWindow, let contentView = window.contentView {
            // Find the position card and update button containers
            for card in contentView.subviews {
                if let effectView = card as? NSVisualEffectView {
                    for containerView in effectView.subviews {
                        if let buttonContainer = containerView as? NSVisualEffectView {
                            // Check if this container has a button with a valid tag
                            for subview in buttonContainer.subviews {
                                if let button = subview as? NSButton, button.tag >= 0 && button.tag < NotificationPosition.allCases.count {
                                    let isSelected = button.tag == sender.tag

                                    // Update container material and appearance
                                    buttonContainer.material = isSelected ? .selection : .underWindowBackground
                                    buttonContainer.layer?.borderWidth = isSelected ? 2.5 : 1
                                    buttonContainer.layer?.borderColor = isSelected
                                        ? NSColor.controlAccentColor.cgColor
                                        : NSColor.separatorColor.withAlphaComponent(0.4).cgColor

                                    // Update shadow
                                    buttonContainer.shadow?.shadowColor = NSColor.black.withAlphaComponent(isSelected ? 0.15 : 0.08)
                                    buttonContainer.shadow?.shadowBlurRadius = isSelected ? 6 : 3

                                    // Update icon color
                                    for iconSubview in button.subviews {
                                        if let iconView = iconSubview as? NSImageView {
                                            iconView.contentTintColor = isSelected ? .controlAccentColor : .tertiaryLabelColor
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Update menu
        statusItem?.menu = createMenu()
    }

    @objc private func settingsLaunchToggled(_ sender: NSButton) {
        let shouldEnable = sender.state == .on

        if shouldEnable {
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>dev.abd3lraouf.notimanager</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(Bundle.main.executablePath!)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
            </dict>
            </plist>
            """
            do {
                try plistContent.write(toFile: launchAgentPlistPath, atomically: true, encoding: .utf8)
                debugLog("Launch at login enabled")
            } catch {
                sender.state = .off
                showError("Failed to enable launch at login: \(error.localizedDescription)")
            }
        } else {
            do {
                try FileManager.default.removeItem(atPath: launchAgentPlistPath)
                debugLog("Launch at login disabled")
            } catch {
                sender.state = .on
                showError("Failed to disable launch at login: \(error.localizedDescription)")
            }
        }
    }

    @objc private func settingsDebugToggled(_ sender: NSButton) {
        debugMode = sender.state == .on
        UserDefaults.standard.set(debugMode, forKey: "debugMode")
        debugLog("Debug mode \(debugMode ? "enabled" : "disabled") - no restart needed!")
    }

    @objc private func settingsHideIconToggled(_ sender: NSButton) {
        if sender.state == .on {
            let alert = NSAlert()
            alert.messageText = "Hide Menu Bar Icon"
            alert.informativeText = "The menu bar icon will be hidden. To show it again, launch Notimanager from Applications."
            alert.addButton(withTitle: "Hide Icon")
            alert.addButton(withTitle: "Cancel")

            if alert.runModal() == .alertFirstButtonReturn {
                isMenuBarIconHidden = true
                UserDefaults.standard.set(true, forKey: "isMenuBarIconHidden")
                statusItem = nil
                settingsWindow?.close()
            } else {
                sender.state = .off
            }
        } else {
            isMenuBarIconHidden = false
            UserDefaults.standard.set(false, forKey: "isMenuBarIconHidden")
            setupStatusItem()
        }
    }

    @objc private func settingsResetPermission() {
        debugLog("User clicked clear settings from settings window")

        // Call the main reset function
        resetAccessibilityPermission()
    }

    @objc private func settingsRestartApp() {
        debugLog("User clicked restart from settings")

        // Close settings window
        settingsWindow?.close()
        settingsWindow = nil

        restartApp()
    }

    @objc private func sendTestNotification() {
        debugLog("Sending test notification...")

        // Update status to checking
        testStatusLabel?.stringValue = "Checking permissions..."
        testStatusLabel?.textColor = .secondaryLabelColor

        // Check current notification authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    // Permission granted, send the notification
                    self.debugLog("Notification permission is granted, sending test...")
                    self.performSendTestNotification()

                case .denied:
                    // Permission denied, show helpful message
                    self.debugLog("Notification permission denied by user")
                    self.showNotificationPermissionDeniedAlert()

                case .notDetermined:
                    // Permission not yet requested, request it now
                    self.debugLog("Notification permission not determined, requesting...")
                    self.requestAndSendTestNotification()

                @unknown default:
                    self.debugLog("Unknown notification authorization status")
                    self.testStatusLabel?.stringValue = "✗ Unknown permission status"
                    self.testStatusLabel?.textColor = .systemRed
                }
            }
        }
    }

    private func performSendTestNotification() {
        // Reset tracking
        notificationWasIntercepted = false
        lastNotificationTime = Date()

        // Update status to waiting
        testStatusLabel?.stringValue = "Sending test notification..."
        testStatusLabel?.textColor = .secondaryLabelColor

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Notimanager Test"
        content.body = "If you see this at \(currentPosition.displayName), it's working! 🎯"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        // Send the notification
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.debugLog("Failed to send test notification: \(error)")
                    self.testStatusLabel?.stringValue = "✗ Failed to send"
                    self.testStatusLabel?.textColor = .systemRed
                } else {
                    self.debugLog("Test notification sent successfully")
                    self.testStatusLabel?.stringValue = "Waiting for notification..."
                    self.testStatusLabel?.textColor = .systemOrange

                    // Check after 2 seconds if it was intercepted
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.updateTestStatus()
                    }
                }
            }
        }
    }

    private func requestAndSendTestNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.debugLog("Error requesting notification permission: \(error)")
                    self.testStatusLabel?.stringValue = "✗ Permission error"
                    self.testStatusLabel?.textColor = .systemRed
                    return
                }

                if granted {
                    self.debugLog("Notification permission granted, sending test...")
                    self.performSendTestNotification()
                } else {
                    self.debugLog("User denied notification permission")
                    self.showNotificationPermissionDeniedAlert()
                }
            }
        }
    }

    private func showNotificationPermissionDeniedAlert() {
        testStatusLabel?.stringValue = "✗ Permission denied"
        testStatusLabel?.textColor = .systemRed

        let alert = NSAlert()
        alert.messageText = "Notification Permission Denied"
        alert.informativeText = """
        Notimanager needs notification permission to send test notifications.

        To enable notifications:
        1. Open System Settings
        2. Go to Notifications
        3. Find Notimanager in the list
        4. Enable "Allow Notifications"
        """
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "bell.slash.fill", accessibilityDescription: "Notifications Disabled")
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            // Open System Settings to Notifications
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func updateTestStatus() {
        if notificationWasIntercepted {
            testStatusLabel?.stringValue = "✓ Intercepted & moved successfully!"
            testStatusLabel?.textColor = .systemGreen
            debugLog("Test notification was successfully intercepted")
        } else {
            testStatusLabel?.stringValue = "⚠ Not intercepted (check permissions)"
            testStatusLabel?.textColor = .systemOrange
            debugLog("Test notification was NOT intercepted")
        }
    }

    @objc private func toggleMenuBarIcon(_: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = "Hide Menu Bar Icon"
        alert.informativeText = "The menu bar icon will be hidden. To show it again, launch Notimanager again."
        alert.addButton(withTitle: "Hide Icon")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        isMenuBarIconHidden = true
        UserDefaults.standard.set(true, forKey: "isMenuBarIconHidden")
        statusItem = nil
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let isEnabled = FileManager.default.fileExists(atPath: launchAgentPlistPath)

        if isEnabled {
            do {
                try FileManager.default.removeItem(atPath: launchAgentPlistPath)
                sender.state = .off
            } catch {
                showError("Failed to disable launch at login: \(error.localizedDescription)")
            }
        } else {
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>dev.abd3lraouf.notimanager</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(Bundle.main.executablePath!)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
            </dict>
            </plist>
            """
            do {
                try plistContent.write(toFile: launchAgentPlistPath, atomically: true, encoding: .utf8)
                sender.state = .on
            } catch {
                showError("Failed to enable launch at login: \(error.localizedDescription)")
            }
        }
    }

    @objc private func toggleDebugMode(_ sender: NSMenuItem) {
        let newDebugMode = !debugMode
        UserDefaults.standard.set(newDebugMode, forKey: "debugMode")

        let alert = NSAlert()
        alert.messageText = "Debug Mode \(newDebugMode ? "Enabled" : "Disabled")"
        alert.informativeText = "Please restart Notimanager for debug mode changes to take effect.\n\nLogs can be viewed in Console.app by filtering for 'Notimanager'."
        alert.addButton(withTitle: "Restart Now")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            // Relaunch app
            let task = Process()
            task.launchPath = Bundle.main.executablePath
            task.launch()
            NSApplication.shared.terminate(nil)
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.runModal()
    }

    @objc private func changePosition(_ sender: NSMenuItem) {
        guard let position: NotificationPosition = sender.representedObject as? NotificationPosition else { return }
        let oldPosition: NotificationPosition = currentPosition
        currentPosition = position
        UserDefaults.standard.set(position.rawValue, forKey: "notificationPosition")

        sender.menu?.items.forEach { item in
            item.state = (item.representedObject as? NotificationPosition) == position ? .on : .off
        }

        cachedInitialNotifSize = nil
        cachedInitialPadding = nil

        debugLog("Position changed: \(oldPosition.displayName) → \(position.displayName)")
        moveAllNotifications()
    }

    private func cacheInitialNotificationData(notifSize: CGSize) {
        if let existingSize = cachedInitialNotifSize {
            debugLog("Cache already exists: \(existingSize) - validating against new size: \(notifSize)")
            if existingSize != notifSize {
                debugLog("⚠️ SIZE MISMATCH DETECTED - clearing stale cache")
                cachedInitialNotifSize = nil
                cachedInitialPadding = nil
                // Fall through to recache with new size
            } else {
                // Size matches, cache is valid
                return
            }
        }

        let padding: CGFloat = 16.0

        cachedInitialNotifSize = notifSize
        cachedInitialPadding = padding

        debugLog("Initial notification cached - size: \(notifSize), padding: \(padding)")
    }

    func moveNotification(_ window: AXUIElement) {
        debugLog("=== moveNotification CALLED ===")
        debugLog("macOS Version: \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")
        debugLog("Current position setting: \(currentPosition.displayName)")
        debugLog("Searching for notification subroles: \(notificationSubroles)")

        // Log window attributes first
        dumpElementHierarchy(window, label: "Window Element")

        guard currentPosition != .topRight else { return }

        // if let identifier: String = getWindowIdentifier(window), identifier.hasPrefix("widget") {
        //     return
        // }

        if hasNotificationCenterUI() {
            debugLog("Skipping move - Notification Center UI detected")
            return
        }

        guard let windowSize: CGSize = getSize(of: window) else {
            debugLog("❌ FAILED: Could not get window size")
            dumpElementHierarchy(window, label: "Failed Window")
            return
        }
        debugLog("✓ Window size: \(windowSize)")

        guard let bannerContainer: AXUIElement = findElementWithSubrole(root: window, targetSubroles: notificationSubroles)
            ?? findNotificationElementFallback(root: window) else {
            debugLog("❌ FAILED: Could not find banner container with target subroles")
            debugLog("❌ All discovery strategies failed")
            debugLog("🔍 Performing detailed element analysis for debugging:")
            dumpElementHierarchy(window, label: "Window Without Banner", maxDepth: 10)
            collectAllSubrolesInHierarchy(window)
            return
        }
        debugLog("✓ Found banner container")
        logElementDetails(bannerContainer, label: "Banner Container")

        guard let notifSize: CGSize = getSize(of: bannerContainer)
        else {
            debugLog("Failed to get notification dimensions or find banner container")
            return
        }

        if cachedInitialNotifSize == nil {
            cacheInitialNotificationData(notifSize: notifSize)
        }

        let newPosition: (x: CGFloat, y: CGFloat) = calculateNewPosition(
            notifSize: cachedInitialNotifSize!,
            padding: cachedInitialPadding!
        )

        // Determine which element to position based on macOS version
        let elementToPosition = getPositionableElement(window: window, banner: bannerContainer)
        debugLog("Positioning element type: \(elementToPosition === window ? "window" : "banner")")

        setPosition(elementToPosition, x: newPosition.x, y: newPosition.y)

        // Verify position was actually set
        if !verifyPositionSet(elementToPosition, expected: CGPoint(x: newPosition.x, y: newPosition.y)) {
            debugLog("⚠️ Position verification failed - notification may not have moved")
        }

        pollingEndTime = Date().addingTimeInterval(6.5)
        debugLog("Moved notification to \(currentPosition.displayName) at (\(newPosition.x), \(newPosition.y))")

        // Track for test notification
        if let lastTest = lastNotificationTime, Date().timeIntervalSince(lastTest) < 5 {
            notificationWasIntercepted = true
            debugLog("✅ Test notification was intercepted and moved!")
        }
    }

    private func moveAllNotifications() {
        guard let pid: pid_t = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else {
            debugLog("Cannot find Notification Center process")
            return
        }

        let app: AXUIElement = AXUIElementCreateApplication(pid)
        var windowsRef: AnyObject?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows: [AXUIElement] = windowsRef as? [AXUIElement]
        else {
            debugLog("Failed to get notification windows")
            return
        }

        for window in windows {
            moveNotification(window)
        }
    }

    @objc func showAbout() {
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.center()
        aboutWindow.title = "About Notimanager"
        aboutWindow.delegate = self

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 180))

        let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        let copyright: String = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? ""

        let elements: [(NSView, CGFloat)] = [
            (createIconView(), 165),
            (createLabel("Notimanager", font: .boldSystemFont(ofSize: 16)), 110),
            (createLabel("Version \(version)"), 90),
            (createLabel("Made with <3 by Wade"), 70),
            (createTwitterButton(), 40),
            (createLabel(copyright, color: .secondaryLabelColor, size: 11), 20),
        ]

        for (view, y) in elements {
            view.frame = NSRect(x: 0, y: y, width: 300, height: 20)
            if view.subviews.first is NSImageView {
                // Icon container
                view.frame = NSRect(x: 100, y: y, width: 100, height: 100)
            }
            contentView.addSubview(view)
        }

        aboutWindow.contentView = contentView
        aboutWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

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

    private func createLabel(_ text: String, font: NSFont = .systemFont(ofSize: 12), color: NSColor = .labelColor, size _: CGFloat = 12) -> NSTextField {
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

    @objc private func openTwitter() {
        NSWorkspace.shared.open(URL(string: "https://x.com/WadeGrimridge")!)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    func setupObserver() {
        guard let pid: pid_t = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else {
            debugLog("Failed to setup observer - Notification Center not found")
            return
        }

        let app: AXUIElement = AXUIElementCreateApplication(pid)
        var observer: AXObserver?
        let createResult = AXObserverCreate(pid, observerCallback, &observer)
        guard createResult == .success else {
            debugLog("❌ Failed to create AXObserver: \(axErrorToString(createResult))")
            return
        }
        axObserver = observer

        let selfPtr: UnsafeMutableRawPointer = Unmanaged.passUnretained(self).toOpaque()
        let addResult = AXObserverAddNotification(observer!, app, kAXWindowCreatedNotification as CFString, selfPtr)
        guard addResult == .success else {
            debugLog("❌ Failed to add notification observer: \(axErrorToString(addResult))")
            return
        }
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer!), .defaultMode)

        debugLog("Observer setup complete for Notification Center (PID: \(pid))")

        widgetMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.checkForWidgetChanges()
        }
    }

    private func getWindowIdentifier(_ element: AXUIElement) -> String? {
        var identifierRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute as CFString, &identifierRef)
        guard result == .success else {
            if result != .noValue {
                debugLog("Failed to get identifier attribute: \(axErrorToString(result))")
            }
            return nil
        }
        return identifierRef as? String
    }

    private func checkForWidgetChanges() {
        guard let pollingEnd: Date = pollingEndTime, Date() < pollingEnd else {
            return
        }

        let hasNCUI: Bool = hasNotificationCenterUI()
        let currentNCState: Int = hasNCUI ? 1 : 0

        if lastWidgetWindowCount != currentNCState {
            debugLog("Notification Center state changed (\(lastWidgetWindowCount) → \(currentNCState)) - triggering move")
            if !hasNCUI {
                moveAllNotifications()
            }
        }

        lastWidgetWindowCount = currentNCState
    }

    private func hasNotificationCenterUI() -> Bool {
        guard let pid: pid_t = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == notificationCenterBundleID
        })?.processIdentifier else { return false }

        let app: AXUIElement = AXUIElementCreateApplication(pid)
        return findElementWithWidgetIdentifier(root: app) != nil
    }

    private func findElementWithWidgetIdentifier(root: AXUIElement) -> AXUIElement? {
        if let identifier: String = getWindowIdentifier(root), identifier.hasPrefix("widget-local") {
            // Verify this is an actual widget panel (significant size) not just an empty overlay container
            if let size = getSize(of: root), size.width > 200 && size.height > 200 {
                debugLog("✓ Found actual Notification Center widget panel: \(identifier), size: \(size)")
                hasLoggedEmptyWidget = false // Reset for next session
                return root
            } else {
                if !hasLoggedEmptyWidget {
                    debugLog("Ignoring empty widget container: \(identifier), size too small or unavailable")
                    hasLoggedEmptyWidget = true
                }
                return nil
            }
        }

        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children: [AXUIElement] = childrenRef as? [AXUIElement] else { return nil }

        for child: AXUIElement in children {
            if let found: AXUIElement = findElementWithWidgetIdentifier(root: child) {
                return found
            }
        }
        return nil
    }

    private func getPosition(of element: AXUIElement) -> CGPoint? {
        var positionValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        guard result == .success else {
            debugLog("❌ Failed to get position attribute: \(axErrorToString(result))")
            return nil
        }
        guard let posVal: AnyObject = positionValue, AXValueGetType(posVal as! AXValue) == .cgPoint else {
            debugLog("❌ Position value has incorrect type")
            return nil
        }
        var position = CGPoint.zero
        AXValueGetValue(posVal as! AXValue, .cgPoint, &position)
        return position
    }

    private func calculateNewPosition(
        notifSize: CGSize,
        padding: CGFloat
    ) -> (x: CGFloat, y: CGFloat) {
        let screenWidth: CGFloat = NSScreen.main!.frame.width
        let screenHeight: CGFloat = NSScreen.main!.frame.height
        let dockSize: CGFloat = NSScreen.main!.frame.height - NSScreen.main!.visibleFrame.height

        debugLog("Calculating absolute position - screen: \(screenWidth)×\(screenHeight), notifSize: \(notifSize), padding: \(padding), dockSize: \(dockSize)")

        let newX: CGFloat
        let newY: CGFloat

        // Calculate X coordinate (horizontal position)
        switch currentPosition {
        case .topLeft, .middleLeft, .bottomLeft:
            newX = padding
        case .topMiddle, .bottomMiddle, .deadCenter:
            newX = (screenWidth - notifSize.width) / 2
        case .topRight, .middleRight, .bottomRight:
            newX = screenWidth - notifSize.width - padding
        }

        // Calculate Y coordinate (vertical position) - macOS uses bottom-left origin
        switch currentPosition {
        case .topLeft, .topMiddle, .topRight:
            newY = screenHeight - notifSize.height - padding
        case .middleLeft, .middleRight, .deadCenter:
            newY = (screenHeight - notifSize.height) / 2
        case .bottomLeft, .bottomMiddle, .bottomRight:
            newY = dockSize + paddingAboveDock
        }

        debugLog("Calculated absolute position - x: \(newX), y: \(newY)")
        return (newX, newY)
    }

    private func getWindowTitle(_ element: AXUIElement) -> String? {
        var titleRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)
        guard result == .success else {
            if result != .noValue {
                debugLog("Failed to get title attribute: \(axErrorToString(result))")
            }
            return nil
        }
        return titleRef as? String
    }

    private func getSize(of element: AXUIElement) -> CGSize? {
        let maxRetries = 2
        for attempt in 0...maxRetries {
            var sizeValue: AnyObject?
            let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)

            guard result == .success else {
                if attempt < maxRetries {
                    debugLog("⚠️ Size retrieval attempt \(attempt + 1) failed: \(axErrorToString(result)) - retrying...")
                    usleep(10000) // 10ms delay before retry
                    continue
                }
                debugLog("❌ Failed to get size attribute after \(maxRetries + 1) attempts: \(axErrorToString(result))")
                return nil
            }

            guard let sizeVal: AnyObject = sizeValue, AXValueGetType(sizeVal as! AXValue) == .cgSize else {
                debugLog("❌ Size value has incorrect type")
                return nil
            }

            var size = CGSize.zero
            AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)

            if attempt > 0 {
                debugLog("✓ Size retrieved successfully on attempt \(attempt + 1): \(size)")
            }
            return size
        }
        return nil
    }

    private func setPosition(_ element: AXUIElement, x: CGFloat, y: CGFloat) {
        var point = CGPoint(x: x, y: y)
        let value: AXValue = AXValueCreate(.cgPoint, &point)!
        let result = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value)
        guard result == .success else {
            debugLog("❌ Failed to set position attribute: \(axErrorToString(result))")
            return
        }
    }

    private func getPositionableElement(window: AXUIElement, banner: AXUIElement) -> AXUIElement {
        // On all macOS versions, we need to position the banner element directly
        // The window element position doesn't affect the actual notification content position
        debugLog("Positioning banner element (notification content)")
        return banner
    }

    private func verifyPositionSet(_ element: AXUIElement, expected: CGPoint) -> Bool {
        guard let actualPosition = getPosition(of: element) else {
            debugLog("❌ Could not verify position - getPosition failed")
            return false
        }

        let tolerance: CGFloat = 2.0 // Allow 2px variance
        let xMatch = abs(actualPosition.x - expected.x) <= tolerance
        let yMatch = abs(actualPosition.y - expected.y) <= tolerance

        if xMatch && yMatch {
            debugLog("✓ Position verified: \(actualPosition)")
            return true
        } else {
            debugLog("❌ Position mismatch - Expected: \(expected), Actual: \(actualPosition)")
            return false
        }
    }

    private func findElementWithSubrole(root: AXUIElement, targetSubroles: [String]) -> AXUIElement? {
        // Helper structure to track candidates with metadata
        struct Candidate {
            let element: AXUIElement
            let depth: Int
            let subrole: String
            let size: CGSize
            let score: Int

            init(element: AXUIElement, depth: Int, subrole: String, size: CGSize) {
                self.element = element
                self.depth = depth
                self.subrole = subrole
                self.size = size

                // Calculate score: depth is primary factor, then subrole specificity, then size accuracy
                var score = depth * 100  // Deeper = higher score

                // Bonus for specific notification subroles
                if subrole == "AXNotificationCenterBanner" || subrole == "AXNotificationCenterAlert" ||
                   subrole == "AXNotificationBanner" || subrole == "AXNotificationAlert" {
                    score += 50
                }

                // Bonus for size closer to typical notification (350×65 is common)
                if size.width >= 300 && size.width <= 450 && size.height >= 55 && size.height <= 85 {
                    score += 30
                }

                self.score = score
            }
        }

        // Recursive search function that collects all candidates
        func searchRecursive(_ element: AXUIElement, currentDepth: Int, candidates: inout [Candidate]) {
            guard currentDepth < 15 else {
                debugLog("⚠️ Max depth (15) reached - stopping recursion")
                return
            }

            // Check if current element has matching subrole
            var subroleRef: AnyObject?
            let result = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef)

            if result == .success, let subrole = subroleRef as? String {
                debugLog("  \(String(repeating: "→", count: currentDepth)) Depth \(currentDepth): Found subrole '\(subrole)'")

                if targetSubroles.contains(subrole) {
                    debugLog("    🔍 Matched target subrole '\(subrole)' at depth \(currentDepth) - validating size...")

                    // Validate size - notifications are typically 200-800px wide, 60-200px tall
                    if let size = getSize(of: element) {
                        let isNotificationSized = size.width >= 200 && size.width <= 800 &&
                                                   size.height >= 60 && size.height <= 200

                        debugLog("    📏 Size: \(size.width)×\(size.height) - Valid: \(isNotificationSized ? "✓" : "✗") (expected 200-800w × 60-200h)")

                        if isNotificationSized {
                            let candidate = Candidate(element: element, depth: currentDepth, subrole: subrole, size: size)
                            debugLog("    ✅ CANDIDATE FOUND at depth \(currentDepth): '\(subrole)', size \(size.width)×\(size.height), score: \(candidate.score)")
                            candidates.append(candidate)
                            // CRITICAL: Don't return - keep searching children for deeper matches
                        } else {
                            debugLog("    ❌ Size validation FAILED - skipping but continuing search")
                        }
                    } else {
                        debugLog("    ⚠️ Could not retrieve size - skipping but continuing search")
                    }
                }
            } else if result != .noValue {
                debugLog("  \(String(repeating: "→", count: currentDepth)) Depth \(currentDepth): No subrole (\(axErrorToString(result)))")
            }

            // ALWAYS search children regardless of whether we found a match at this level
            var childrenRef: AnyObject?
            if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
               let children = childrenRef as? [AXUIElement] {
                if !children.isEmpty {
                    debugLog("  \(String(repeating: "→", count: currentDepth)) Searching \(children.count) children at depth \(currentDepth + 1)...")
                }
                for child in children {
                    searchRecursive(child, currentDepth: currentDepth + 1, candidates: &candidates)
                }
            }
        }

        // Start search
        debugLog("🔍 Starting depth-aware element search for subroles: \(targetSubroles)")
        var candidates: [Candidate] = []
        searchRecursive(root, currentDepth: 0, candidates: &candidates)

        // Select best candidate (highest score = deepest + most specific)
        if candidates.isEmpty {
            debugLog("❌ No valid candidates found in element tree")
            return nil
        }

        debugLog("📊 Found \(candidates.count) candidate(s):")
        for (index, candidate) in candidates.enumerated() {
            debugLog("   [\(index + 1)] Depth: \(candidate.depth), Subrole: '\(candidate.subrole)', Size: \(candidate.size.width)×\(candidate.size.height), Score: \(candidate.score)")
        }

        let bestCandidate = candidates.max(by: { $0.score < $1.score })!
        debugLog("✅ SELECTED BEST CANDIDATE: Depth \(bestCandidate.depth), Subrole '\(bestCandidate.subrole)', Size: \(bestCandidate.size.width)×\(bestCandidate.size.height), Score: \(bestCandidate.score)")

        return bestCandidate.element
    }

    private func findNotificationElementFallback(root: AXUIElement) -> AXUIElement? {
        debugLog("Attempting fallback notification discovery...")

        // Strategy 0: Find by identifier "AXNotificationListItems" (macOS 26.1+)
        if let element = findElementByIdentifier(root: root, identifier: "AXNotificationListItems") {
            debugLog("✓ Fallback Strategy 0: Found via AXNotificationListItems identifier")
            logElementDetails(element, label: "Fallback AXNotificationListItems")
            return element
        }

        // Strategy 1: Find by role = "AXGroup" and reasonable size (with max bounds)
        if let element = findElementByRoleAndSize(root: root, role: "AXGroup", minWidth: 300, minHeight: 60, maxWidth: 800, maxHeight: 300) {
            debugLog("✓ Fallback Strategy 1: Found via AXGroup+size heuristic")
            logElementDetails(element, label: "Fallback AXGroup")
            return element
        }

        // Strategy 2: Find by role = "AXScrollArea" (macOS 26 potential structure)
        if let element = findElementByRoleAndSize(root: root, role: "AXScrollArea", minWidth: 300, minHeight: 60, maxWidth: 800, maxHeight: 300) {
            debugLog("✓ Fallback Strategy 2: Found via AXScrollArea+size heuristic")
            logElementDetails(element, label: "Fallback AXScrollArea")
            return element
        }

        // Strategy 3: Find any sizeable element with specific roles (expanded for macOS 26)
        let fallbackRoles = ["AXGroup", "AXScrollArea", "AXLayoutArea", "AXSplitGroup", "AXUnknown"]
        for role in fallbackRoles {
            if let element = findElementByRoleAndSize(root: root, role: role, minWidth: 280, minHeight: 50, maxWidth: 800, maxHeight: 300) {
                debugLog("✓ Fallback Strategy 3: Found via \(role)+relaxed size heuristic")
                logElementDetails(element, label: "Fallback \(role)")
                return element
            }
        }

        // Strategy 4: Find deepest element with significant size (notification-sized)
        if let element = findDeepestSizedElement(root: root, minWidth: 280, maxWidth: 800, maxHeight: 300) {
            debugLog("✓ Fallback Strategy 4: Found via deepest element heuristic")
            logElementDetails(element, label: "Fallback Deepest")
            return element
        }

        // Strategy 5: Last resort - find ANY element with notification-like dimensions
        if let element = findAnyElementWithSize(root: root, minWidth: 250, maxWidth: 600, minHeight: 40, maxHeight: 200) {
            debugLog("⚠️ Fallback Strategy 5: Found via dimension-only heuristic (last resort)")
            logElementDetails(element, label: "Fallback Dimensions-Only")
            return element
        }

        debugLog("❌ All fallback strategies failed")
        return nil
    }

    private func findElementByIdentifier(root: AXUIElement, identifier: String, currentDepth: Int = 0, maxDepth: Int = 10) -> AXUIElement? {
        guard currentDepth < maxDepth else { return nil }

        // Check if current element has the target identifier
        if let elemIdentifier = getWindowIdentifier(root), elemIdentifier == identifier {
            return root
        }

        // Search children
        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            if let found = findElementByIdentifier(root: child, identifier: identifier, currentDepth: currentDepth + 1, maxDepth: maxDepth) {
                return found
            }
        }
        return nil
    }

    private func findElementByRoleAndSize(root: AXUIElement, role: String, minWidth: CGFloat, minHeight: CGFloat, maxWidth: CGFloat = .infinity, maxHeight: CGFloat = .infinity) -> AXUIElement? {
        var roleRef: AnyObject?
        if AXUIElementCopyAttributeValue(root, kAXRoleAttribute as CFString, &roleRef) == .success,
           let elementRole = roleRef as? String,
           elementRole == role,
           let size = getSize(of: root),
           size.width >= minWidth && size.height >= minHeight && size.width <= maxWidth && size.height <= maxHeight {
            return root
        }

        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            if let found = findElementByRoleAndSize(root: child, role: role, minWidth: minWidth, minHeight: minHeight, maxWidth: maxWidth, maxHeight: maxHeight) {
                return found
            }
        }
        return nil
    }

    private func findDeepestSizedElement(root: AXUIElement, minWidth: CGFloat, maxWidth: CGFloat = .infinity, maxHeight: CGFloat = .infinity, currentDepth: Int = 0, maxDepth: Int = 10) -> AXUIElement? {
        guard currentDepth < maxDepth else { return nil }

        var deepestElement: AXUIElement?
        var maxFoundDepth = currentDepth

        var childrenRef: AnyObject?
        if AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findDeepestSizedElement(root: child, minWidth: minWidth, maxWidth: maxWidth, maxHeight: maxHeight, currentDepth: currentDepth + 1, maxDepth: maxDepth) {
                    if currentDepth + 1 > maxFoundDepth {
                        deepestElement = found
                        maxFoundDepth = currentDepth + 1
                    }
                }
            }
        }

        if deepestElement == nil,
           let size = getSize(of: root),
           size.width >= minWidth && size.width <= maxWidth && size.height <= maxHeight {
            return root
        }

        return deepestElement
    }

    private func findAnyElementWithSize(root: AXUIElement, minWidth: CGFloat, maxWidth: CGFloat, minHeight: CGFloat, maxHeight: CGFloat) -> AXUIElement? {
        if let size = getSize(of: root),
           size.width >= minWidth && size.width <= maxWidth &&
           size.height >= minHeight && size.height <= maxHeight {
            return root
        }

        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            if let found = findAnyElementWithSize(root: child, minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight) {
                return found
            }
        }
        return nil
    }

    private func logElementDetails(_ element: AXUIElement, label: String) {
        var details: [String] = []

        var roleRef: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success,
           let role = roleRef as? String {
            details.append("role=\(role)")
        }

        var subroleRef: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef) == .success,
           let subrole = subroleRef as? String {
            details.append("subrole=\(subrole)")
        }

        if let size = getSize(of: element) {
            details.append("size=\(size.width)×\(size.height)")
        }

        if let position = getPosition(of: element) {
            details.append("position=(\(position.x), \(position.y))")
        }

        debugLog("📍 [\(label)] \(details.joined(separator: ", "))")
    }

    private func collectAllSubrolesInHierarchy(_ element: AXUIElement, depth: Int = 0, maxDepth: Int = 10, foundSubroles: inout Set<String>) {
        guard depth < maxDepth else { return }

        var subroleRef: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef) == .success,
           let subrole = subroleRef as? String {
            foundSubroles.insert(subrole)
        }

        var childrenRef: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement] {
            for child in children {
                collectAllSubrolesInHierarchy(child, depth: depth + 1, maxDepth: maxDepth, foundSubroles: &foundSubroles)
            }
        }
    }

    private func collectAllSubrolesInHierarchy(_ element: AXUIElement) {
        var foundSubroles = Set<String>()
        collectAllSubrolesInHierarchy(element, foundSubroles: &foundSubroles)

        if foundSubroles.isEmpty {
            debugLog("🔍 No subroles found in element hierarchy")
        } else {
            debugLog("🔍 All subroles found in hierarchy: \(foundSubroles.sorted().joined(separator: ", "))")
            debugLog("💡 If notifications aren't moving, please report these subroles for macOS \(osVersion.majorVersion) compatibility")
        }
    }

    fileprivate func dumpElementHierarchy(_ element: AXUIElement, label: String, depth: Int = 0, maxDepth: Int = 5) {
        guard depth < maxDepth else { return }
        
        let indent = String(repeating: "  ", count: depth)
        var info: [String] = []
        
        // Get role
        var roleRef: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success,
           let role = roleRef as? String {
            info.append("role=\(role)")
        }
        
        // Get subrole
        var subroleRef: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef) == .success,
           let subrole = subroleRef as? String {
            info.append("subrole=\(subrole)")
        }
        
        // Get size
        if let size = getSize(of: element) {
            info.append("size=\(size.width)×\(size.height)")
        }
        
        // Get identifier
        if let identifier = getWindowIdentifier(element) {
            info.append("id=\(identifier)")
        }
        
        debugLog("\(indent)[\(label) depth=\(depth)] \(info.joined(separator: ", "))")
        
        // Recurse to children
        var childrenRef: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement] {
            for (index, child) in children.enumerated() {
                dumpElementHierarchy(child, label: "Child[\(index)]", depth: depth + 1, maxDepth: maxDepth)
            }
        }
    }

    private func axErrorToString(_ error: AXError) -> String {
        switch error {
        case .success: return "success"
        case .failure: return "failure"
        case .illegalArgument: return "illegalArgument"
        case .invalidUIElement: return "invalidUIElement"
        case .invalidUIElementObserver: return "invalidUIElementObserver"
        case .cannotComplete: return "cannotComplete"
        case .attributeUnsupported: return "attributeUnsupported"
        case .actionUnsupported: return "actionUnsupported"
        case .notificationUnsupported: return "notificationUnsupported"
        case .notImplemented: return "notImplemented"
        case .notificationAlreadyRegistered: return "notificationAlreadyRegistered"
        case .notificationNotRegistered: return "notificationNotRegistered"
        case .apiDisabled: return "apiDisabled"
        case .noValue: return "noValue"
        case .parameterizedAttributeUnsupported: return "parameterizedAttributeUnsupported"
        case .notEnoughPrecision: return "notEnoughPrecision"
        @unknown default: return "unknown(\(error.rawValue))"
        }
    }

    private func logSystemInfo() {
        debugLog("=== SYSTEM INFORMATION ===")
        debugLog("macOS Version: \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")
        debugLog("Notimanager Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
        debugLog("Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        debugLog("Current Position: \(currentPosition.displayName)")
        debugLog("Debug Mode: \(debugMode ? "ON" : "OFF")")
    }
}

private func observerCallback(observer _: AXObserver, element: AXUIElement, notification: CFString, context: UnsafeMutableRawPointer?) {
    let mover: NotificationMover = Unmanaged<NotificationMover>.fromOpaque(context!).takeUnretainedValue()

    let notificationString: String = notification as String

    mover.debugLog("=== WINDOW CREATED NOTIFICATION RECEIVED ===")
    mover.dumpElementHierarchy(element, label: "Created Window")

    if notificationString == kAXWindowCreatedNotification as String {
        mover.moveNotification(element)
    }
}

@main
struct NotimanagerApp {
    static func main() {
        let app: NSApplication = .shared
        let delegate: NotificationMover = .init()
        app.delegate = delegate
        app.run()
    }
}
