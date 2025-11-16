//
//  AboutViewModel.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  ViewModel for about screen - manages app information
//

import Cocoa

/// ViewModel for AboutViewController
class AboutViewModel {

    // MARK: - Properties

    var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var copyright: String {
        return Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? ""
    }

    var twitterURL: URL {
        return URL(string: "https://x.com/WadeGrimridge")!
    }

    var kofiURL: URL {
        return URL(string: "https://ko-fi.com/wadegrimridge")!
    }

    var buyMeACoffeeURL: URL {
        return URL(string: "https://www.buymeacoffee.com/wadegrimridge")!
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Actions

    func openTwitter() {
        NSWorkspace.shared.open(twitterURL)
    }

    func openKofi() {
        NSWorkspace.shared.open(kofiURL)
    }

    func openBuyMeACoffee() {
        NSWorkspace.shared.open(buyMeACoffeeURL)
    }
}
