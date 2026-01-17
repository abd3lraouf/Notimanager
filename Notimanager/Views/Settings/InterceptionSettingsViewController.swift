//
//  InterceptionSettingsViewController.swift
//  Notimanager
//
//  Interception settings pane following Blip Settings design system.
//  Uses NSHostingController to display SwiftUI InterceptionSettingsView.
//

import Cocoa
import Settings
import SwiftUI

final class InterceptionSettingsViewController: NSViewController, SettingsPane {

    // MARK: - SettingsPane Conformance

    let paneIdentifier = Settings.PaneIdentifier.position
    let paneTitle = NSLocalizedString("Interception", comment: "Settings pane title")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "hand.tap", accessibilityDescription: "Interception")!
        } else {
            return NSImage(named: NSImage.actionTemplateName)!
        }
    }

    // MARK: - Properties

    private var hostingController: NSHostingController<InterceptionSettingsView>!

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // Create SwiftUI view
        let settingsView = InterceptionSettingsView()
        hostingController = NSHostingController(rootView: settingsView)

        // Configure
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // Set as view
        view = hostingController.view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: 540, height: 600)
    }
}
