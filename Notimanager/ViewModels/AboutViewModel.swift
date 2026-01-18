//
//  AboutViewModel.swift
//  Notimanager
//
//  Created on 2025-01-15.
//  ViewModel for about screen - manages app information
//  Single source of truth for About screen content
//

import Cocoa

/// ViewModel for About screens - provides all about information
/// Following Apple HIG for About window content
final class AboutViewModel {

    // MARK: - Properties

    var appName: String {
        return "Notimanager"
    }

    var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var build: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var copyright: String {
        return Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? ""
    }

    var authorName: String {
        return "Abdelraouf Sabri"
    }

    var githubUsername: String {
        return "abd3lraouf"
    }

    /// Your personal GitHub profile URL
    var personalGitHubURL: URL {
        return URL(string: "https://github.com/\(githubUsername)")!
    }

    /// Notimanager repository URL
    var repositoryURL: URL {
        return URL(string: "https://github.com/\(githubUsername)/notimanager")!
    }

    var githubURL: URL {
        return repositoryURL
    }

    var websiteURL: URL? {
        return repositoryURL
    }

    var license: String {
        return "MIT"
    }

    /// License file URL on GitHub
    var licenseURL: URL {
        return URL(string: "\(repositoryURL)/blob/main/LICENSE")!
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Display Strings

    var versionDisplayString: String {
        return "\(appName) \(version)"
    }

    var buildDisplayString: String {
        return "Build \(build)"
    }

    var creditsDisplayString: String {
        return "Made with ❤️ by \(authorName)"
    }

    var fullVersionString: String {
        return "\(version) (\(build))"
    }
}
