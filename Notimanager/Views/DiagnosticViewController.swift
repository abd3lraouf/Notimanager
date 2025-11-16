//
//  DiagnosticViewController.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  MVVM diagnostic view controller extracted from NotificationMover
//

import Cocoa

/// Diagnostic View Controller using MVVM architecture
class DiagnosticViewController: NSViewController {

    // MARK: - Properties

    private let viewModel: DiagnosticViewModel
    private var window: NSWindow?
    private var diagnosticTextView: NSTextView?

    // MARK: - Initialization

    init(viewModel: DiagnosticViewModel = DiagnosticViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupViewModelBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.log("🚀 Diagnostic window initialized")
        viewModel.log("⚠️ Send a notification, then click the test buttons to diagnose issues\n")
    }

    // MARK: - Setup

    private func setupViewModelBindings() {
        viewModel.onLogMessage = { [weak self] message in
            self?.appendLog(message)
        }

        viewModel.onOutputCleared = { [weak self] in
            self?.clearOutput()
        }
    }

    private func setupUI() {
        guard let contentView = view else { return }

        let windowWidth: CGFloat = 800
        let windowHeight: CGFloat = 600
        var yPos: CGFloat = windowHeight - 60

        // Title
        let titleLabel = NSTextField(labelWithString: "🔬 Notification API Diagnostics")
        titleLabel.frame = NSRect(x: 20, y: yPos, width: windowWidth - 40, height: 30)
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)
        yPos -= 50

        // System info
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let infoLabel = NSTextField(labelWithString: "macOS Version: \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")
        infoLabel.frame = NSRect(x: 20, y: yPos, width: windowWidth - 40, height: 20)
        infoLabel.alignment = .center
        infoLabel.textColor = .secondaryLabelColor
        contentView.addSubview(infoLabel)
        yPos -= 30

        // Test buttons section
        let buttonSection = NSView(frame: NSRect(x: 20, y: yPos - 150, width: windowWidth - 40, height: 150))
        buttonSection.wantsLayer = true
        buttonSection.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        buttonSection.layer?.cornerRadius = 8
        contentView.addSubview(buttonSection)

        var buttonY: CGFloat = 110
        let buttonWidth: CGFloat = (windowWidth - 80) / 2

        // Scan Windows button
        let scanButton = NSButton(frame: NSRect(x: 10, y: buttonY, width: buttonWidth, height: 32))
        scanButton.title = "🔍 Scan All Windows"
        scanButton.bezelStyle = .rounded
        scanButton.target = self
        scanButton.action = #selector(scanWindows)
        buttonSection.addSubview(scanButton)

        // Test Accessibility API button
        let axButton = NSButton(frame: NSRect(x: buttonWidth + 20, y: buttonY, width: buttonWidth, height: 32))
        axButton.title = "♿️ Test Accessibility API"
        axButton.bezelStyle = .rounded
        axButton.target = self
        axButton.action = #selector(testAccessibilityAPI)
        buttonSection.addSubview(axButton)
        buttonY -= 40

        // Try Set Position button
        let posButton = NSButton(frame: NSRect(x: 10, y: buttonY, width: buttonWidth, height: 32))
        posButton.title = "📍 Try Set Position"
        posButton.bezelStyle = .rounded
        posButton.target = self
        posButton.action = #selector(trySetPosition)
        buttonSection.addSubview(posButton)

        // Analyze NC Panel button
        let ncButton = NSButton(frame: NSRect(x: buttonWidth + 20, y: buttonY, width: buttonWidth, height: 32))
        ncButton.title = "📋 Analyze NC Panel"
        ncButton.bezelStyle = .rounded
        ncButton.target = self
        ncButton.action = #selector(analyzeNCPanel)
        buttonSection.addSubview(ncButton)
        buttonY -= 40

        // Clear button
        let clearButton = NSButton(frame: NSRect(x: 10, y: buttonY, width: buttonWidth, height: 32))
        clearButton.title = "🗑️ Clear Output"
        clearButton.bezelStyle = .rounded
        clearButton.target = self
        clearButton.action = #selector(clearOutputClicked)
        buttonSection.addSubview(clearButton)

        yPos -= 180

        // Output text view with scroll
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: windowWidth - 40, height: yPos - 40))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder

        let textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.textContainerInset = NSSize(width: 10, height: 10)
        scrollView.documentView = textView
        contentView.addSubview(scrollView)

        diagnosticTextView = textView
    }

    // MARK: - Actions

    @objc private func scanWindows() {
        viewModel.scanWindows()
    }

    @objc private func testAccessibilityAPI() {
        viewModel.testAccessibilityAPI()
    }

    @objc private func trySetPosition() {
        viewModel.trySetPosition()
    }

    @objc private func analyzeNCPanel() {
        viewModel.analyzeNCPanel()
    }

    @objc private func clearOutputClicked() {
        viewModel.clearOutput()
    }

    // MARK: - UI Updates

    private func appendLog(_ message: String) {
        guard let textView = diagnosticTextView else { return }

        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] \(message)\n"

        textView.string += line
        textView.scrollToEndOfDocument(nil)
    }

    private func clearOutput() {
        diagnosticTextView?.string = ""
    }

    // MARK: - Window Management

    func showInWindow() {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "API Diagnostics - macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self

        window.contentView = view
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSWindowDelegate

extension DiagnosticViewController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
