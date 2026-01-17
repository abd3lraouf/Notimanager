//
//  GeneralSettingsViewController.swift
//  Notimanager
//
//  General settings pane following Blip Settings design system.
//  Uses NSHostingController to display SwiftUI GeneralSettingsView.
//

import Cocoa
import Settings
import SwiftUI

final class GeneralSettingsViewController: NSViewController, SettingsPane {

    // MARK: - SettingsPane Conformance

    let paneIdentifier = Settings.PaneIdentifier.general
    let paneTitle = NSLocalizedString("General", comment: "Settings pane title")

    var toolbarItemIcon: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General")!
        } else {
            return NSImage(named: NSImage.actionTemplateName)!
        }
    }

    // MARK: - Properties

    private var hostingController: NSHostingController<GeneralSettingsView>!

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // Create SwiftUI view
        let settingsView = GeneralSettingsView()
        hostingController = NSHostingController(rootView: settingsView)

        // Configure
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // Set as view
        view = hostingController.view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: 540, height: 580)
    }
}
