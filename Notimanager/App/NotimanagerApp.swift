//
//  NotimanagerApp.swift
//  Notimanager
//
//  Created on 2025-11-16.
//

import Cocoa

@main
struct NotimanagerApp {
    // Keep delegate alive for the lifetime of the app
    private static let delegate = NotificationMover()

    static func main() {
        let app: NSApplication = .shared
        app.delegate = delegate
        app.run()
    }
}
