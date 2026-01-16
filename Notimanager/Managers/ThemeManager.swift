//
//  ThemeManager.swift
//  Notimanager
//
//  Manages app theming with support for light/dark mode and custom themes.
//  Persists user theme preferences and applies themes across the app.
//

import AppKit

/// Available app themes
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    /// Icon symbol name for UI
    var iconSymbol: String {
        switch self {
        case .system:
            return "desktopcomputer"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }

    /// NSAppearance for this theme
    var appearance: NSAppearance? {
        switch self {
        case .system:
            return nil // Use system appearance
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }

    /// Whether this theme follows system settings
    var isSystem: Bool {
        return self == .system
    }
}

/// Manages theme selection and application
class ThemeManager {

    // MARK: - Singleton

    static let shared = ThemeManager()

    // MARK: - Properties

    private(set) var currentTheme: AppTheme

    // MARK: - Notifications

    static let themeDidChangeNotification = Notification.Name("themeDidChange")

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let selectedTheme = "selectedTheme"
    }

    // MARK: - Initialization

    private init() {
        // Load saved theme or default to system
        let savedThemeRaw = UserDefaults.standard.string(forKey: Keys.selectedTheme) ?? AppTheme.system.rawValue
        self.currentTheme = AppTheme(rawValue: savedThemeRaw) ?? .system

        // Apply initial theme
        applyTheme(currentTheme, animated: false)

        // Observe system appearance changes when in system mode
        observeSystemAppearanceChanges()
    }

    // MARK: - Theme Management

    /// Sets the current theme and persists it
    /// - Parameter theme: The theme to apply
    func setTheme(_ theme: AppTheme) {
        guard theme != currentTheme else { return }

        let oldTheme = currentTheme
        currentTheme = theme

        // Persist preference
        UserDefaults.standard.set(theme.rawValue, forKey: Keys.selectedTheme)

        // Apply theme
        applyTheme(theme, animated: true)

        // Notify observers
        NotificationCenter.default.post(
            name: Self.themeDidChangeNotification,
            object: self,
            userInfo: [
                "oldTheme": oldTheme,
                "newTheme": theme
            ]
        )

        #if DEBUG
        print("[ThemeManager] Theme changed to: \(theme.displayName)")
        #endif
    }

    /// Applies a theme to the application
    /// - Parameters:
    ///   - theme: The theme to apply
    ///   - animated: Whether to animate the transition
    private func applyTheme(_ theme: AppTheme, animated: Bool) {
        DispatchQueue.main.async {
            if let appearance = theme.appearance {
                // Apply specific appearance
                NSApp.appearance = appearance
            } else {
                // Reset to system appearance
                NSApp.appearance = nil
            }

            // Update all windows
            if animated {
                self.animateThemeChange()
            }

            // Force redraw of all windows
            NSApp.windows.forEach { window in
                window.appearance = NSApp.appearance
                window.contentViewController?.view.needsDisplay = true
            }
        }
    }

    /// Animates the theme transition
    private func animateThemeChange() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true

            NSApp.windows.forEach { window in
                window.animator().alphaValue = 0.9
            }
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                NSApp.windows.forEach { window in
                    window.animator().alphaValue = 1.0
                }
            }
        }
    }

    /// Returns whether dark mode is currently active
    var isDarkMode: Bool {
        switch currentTheme {
        case .system:
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        case .light:
            return false
        case .dark:
            return true
        }
    }

    // MARK: - System Appearance Observation

    private func observeSystemAppearanceChanges() {
        // Monitor system appearance changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemAppearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    @objc private func systemAppearanceChanged() {
        // Only trigger update if we're in system mode
        guard currentTheme == .system else { return }

        #if DEBUG
        print("[ThemeManager] System appearance changed")
        #endif

        // Notify observers that system appearance changed
        NotificationCenter.default.post(
            name: AppearanceManager.appearanceDidChangeNotification,
            object: self
        )
    }

    // MARK: - Color Helpers

    /// Returns a color that adapts to the current theme
    /// - Parameters:
    ///   - light: The light mode color
    ///   - dark: The dark mode color
    /// - Returns: Appropriate color for current theme
    func color(light: NSColor, dark: NSColor) -> NSColor {
        return isDarkMode ? dark : light
    }

    /// Returns the appropriate text color for the current theme
    var textColor: NSColor {
        return isDarkMode ? .labelColor : .labelColor
    }

    /// Returns the appropriate background color for the current theme
    var backgroundColor: NSColor {
        return isDarkMode ? .windowBackgroundColor : .windowBackgroundColor
    }
}

// MARK: - NSView Extension for Theme Support

extension NSView {

    /// Applies theme-aware coloring to the view
    func applyThemeColoring() {
        needsDisplay = true
    }
}

// MARK: - Theme Preview Colors

extension ThemeManager {

    /// Color palette for theme preview
    struct ThemePreviewColors {
        let background: NSColor
        let card: NSColor
        let text: NSColor
        let accent: NSColor
        let border: NSColor
    }

    /// Returns preview colors for a given theme
    /// - Parameter theme: The theme to get colors for
    /// - Returns: Color palette for preview
    func previewColors(for theme: AppTheme) -> ThemePreviewColors {
        let isDark: Bool
        switch theme {
        case .system:
            isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        case .light:
            isDark = false
        case .dark:
            isDark = true
        }

        return ThemePreviewColors(
            background: isDark ? NSColor(hex: "#1E1E1E") : NSColor(hex: "#F5F5F7"),
            card: isDark ? NSColor(hex: "#2D2D2D") : NSColor(hex: "#FFFFFF"),
            text: isDark ? NSColor(hex: "#FFFFFF") : NSColor(hex: "#000000"),
            accent: NSColor.controlAccentColor,
            border: isDark ? NSColor(hex: "#404040") : NSColor(hex: "#E0E0E0")
        )
    }
}

// MARK: - NSColor Extension for Hex Support

extension NSColor {
    /// Creates a color from a hex string
    /// - Parameter hex: Hex color string (e.g., "#FF0000")
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
