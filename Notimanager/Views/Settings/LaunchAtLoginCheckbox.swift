//
//  LaunchAtLoginCheckbox.swift
//  Notimanager
//
//  Created on 2025-01-16.
//  AppKit wrapper for LaunchAtLogin SwiftUI toggle
//

import AppKit
import SwiftUI
import LaunchAtLogin

/// AppKit wrapper view that hosts the LaunchAtLogin SwiftUI toggle
@available(macOS 13.0, *)
struct LaunchAtLoginCheckbox: NSViewRepresentable {

    func makeNSView(context: Context) -> NSView {
        let checkboxView = LaunchAtLoginCheckboxView()
        let hostingController = NSHostingController(rootView: checkboxView)
        return hostingController.view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No updates needed - the SwiftUI toggle handles its own state
    }
}

/// Extension to provide a more traditional AppKit-style checkbox if needed
@available(macOS 13.0, *)
final class LaunchAtLoginController: NSViewController {

    private var hostingController: NSHostingController<LaunchAtLoginCheckboxView>?

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let checkboxView = LaunchAtLoginCheckboxView()
        let hostingController = NSHostingController(rootView: checkboxView)
        self.hostingController = hostingController

        // Add the hosted view
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

/// SwiftUI view that matches the native macOS checkbox style with label and description
@available(macOS 13.0, *)
struct LaunchAtLoginCheckboxView: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.pt8) {
            LaunchAtLogin.Toggle()
                .toggleStyle(.checkbox)
                .labelsHidden()

            VStack(alignment: .leading, spacing: Spacing.pt2) {
                Text(NSLocalizedString("Start at login", comment: "Launch at login checkbox title"))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(nsColor: Colors.label))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(NSLocalizedString("Automatically launch Notimanager when you log in", comment: "Launch at login description"))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(nsColor: Colors.secondaryLabel))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NSLocalizedString("Start at login", comment: "Launch at login accessibility label"))
        .accessibilityHint(NSLocalizedString("Automatically launch Notimanager when you log in", comment: "Launch at login accessibility hint"))
    }
}
