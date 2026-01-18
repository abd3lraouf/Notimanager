//  DiagnosticViewController.swift
//  Notimanager
//
//  Replaced with SwiftUI DiagnosticView.
//  This file kept for compatibility during transition.
//

import Cocoa

/// Deprecated: Use DiagnosticView (SwiftUI) instead
class DiagnosticViewController: NSViewController {
    init(viewModel: DiagnosticViewModel = DiagnosticViewModel()) {
        super.init(nibName: nil, bundle: nil)
        // Redirect to SwiftUI view
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // Create a simple placeholder view
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))

        let label = NSTextField(labelWithString: "Diagnostic window moved to SwiftUI")
        label.frame = NSRect(x: 20, y: 20, width: 360, height: 20)
        label.alignment = .center
        view.addSubview(label)
    }
}
