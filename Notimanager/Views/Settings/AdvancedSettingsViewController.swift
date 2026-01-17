//
//  AdvancedSettingsViewController.swift
//  Notimanager
//
//  Advanced settings pane following Blip Settings design system.
//  Uses NSHostingController to display SwiftUI AdvancedSettingsView.
//

import Cocoa
import Settings
import SwiftUI

final class AdvancedSettingsViewController: NSViewController, SettingsPane {

    // MARK: - SettingsPane Conformance

    let paneIdentifier = Settings.PaneIdentifier.advanced
    let paneTitle = NSLocalizedString("Advanced", comment: "Settings pane title")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: "Advanced")!
        } else {
            return NSImage(named: NSImage.advancedName)!
        }
    }

    // MARK: - Properties

    private var hostingController: NSHostingController<AdvancedSettingsView>!

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // Create SwiftUI view
        let settingsView = AdvancedSettingsView()
        hostingController = NSHostingController(rootView: settingsView)

        // Configure
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // Set as view
        view = hostingController.view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: 540, height: 380)
    }
}
