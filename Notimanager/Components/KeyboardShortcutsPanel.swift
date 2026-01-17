//
//  KeyboardShortcutsPanel.swift
//  Notimanager
//
//  A modal panel displaying all available keyboard shortcuts
//  Part of the Liquid Glass Design System
//

import Cocoa
import AppKit

/// A modal panel that displays all keyboard shortcuts in an organized, searchable format
final class KeyboardShortcutsPanel: NSPanel {

    // MARK: - UI Components

    private var scrollView: NSScrollView!
    private var mainContainerView: NSView!
    private var searchField: NSSearchField!
    private var stackView: NSStackView!
    private var closeButton: NSButton!

    // MARK: - Properties

    private var allSections: [ShortcutSectionView] = []

    // MARK: - Initialization

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        setupPanel()
        setupUI()
        loadShortcuts()
    }

    // MARK: - Setup

    private func setupPanel() {
        title = NSLocalizedString("Keyboard Shortcuts", comment: "Panel title")
        isMovableByWindowBackground = true
        isFloatingPanel = false
        level = .floating
        center()

        // Set minimum size
        minSize = NSSize(width: 400, height: 400)
    }

    private func setupUI() {
        // Background
        mainContainerView = NSView()
        mainContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView = mainContainerView

        // Search field
        searchField = NSSearchField()
        searchField.placeholderString = NSLocalizedString("Search shortcuts…", comment: "Search field placeholder")
        searchField.delegate = self
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.focusRingType = .none
        mainContainerView.addSubview(searchField)

        // Scroll view for shortcuts
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        mainContainerView.addSubview(scrollView)

        // Container for shortcuts
        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        // Stack view for sections
        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = Spacing.pt16
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(stackView)

        // Close button (in style of standard macOS sheets)
        closeButton = NSButton()
        closeButton.title = NSLocalizedString("Close", comment: "Button title")
        closeButton.bezelStyle = .rounded
        closeButton.keyEquivalent = "\r"
        closeButton.target = self
        closeButton.action = #selector(closeClicked)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        mainContainerView.addSubview(closeButton)

        // Constraints
        NSLayoutConstraint.activate([
            // Search field
            searchField.topAnchor.constraint(equalTo: mainContainerView.topAnchor, constant: Spacing.pt20),
            searchField.leadingAnchor.constraint(equalTo: mainContainerView.leadingAnchor, constant: Spacing.pt20),
            searchField.trailingAnchor.constraint(equalTo: mainContainerView.trailingAnchor, constant: -Spacing.pt20),

            // Scroll view
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: Spacing.pt12),
            scrollView.leadingAnchor.constraint(equalTo: mainContainerView.leadingAnchor, constant: Spacing.pt20),
            scrollView.trailingAnchor.constraint(equalTo: mainContainerView.trailingAnchor, constant: -Spacing.pt20),

            // Stack view in scroll view
            stackView.topAnchor.constraint(equalTo: documentView.topAnchor, constant: Spacing.pt16),
            stackView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: Spacing.pt8),
            stackView.trailingAnchor.constraint(equalTo: documentView.trailingAnchor, constant: -Spacing.pt8),
            stackView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -Spacing.pt16),

            // Document view width
            documentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Close button
            closeButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: Spacing.pt12),
            closeButton.centerXAnchor.constraint(equalTo: mainContainerView.centerXAnchor),
            closeButton.bottomAnchor.constraint(equalTo: mainContainerView.bottomAnchor, constant: -Spacing.pt20),
            closeButton.heightAnchor.constraint(equalToConstant: Layout.regularButtonHeight)
        ])
    }

    private func loadShortcuts() {
        // Clear existing sections
        allSections.forEach { $0.removeFromSuperview() }
        allSections.removeAll()

        // Load shortcuts from reference
        for (category, shortcuts) in KeyboardShortcutReference.allShortcuts {
            let sectionView = ShortcutSectionView(category: category, shortcuts: shortcuts)
            stackView.addArrangedSubview(sectionView)
            allSections.append(sectionView)
        }
    }

    // MARK: - Actions

    @objc private func closeClicked() {
        close()
    }

    // MARK: - Search

    private func filterShortcuts(with searchText: String) {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces).lowercased()

        guard !trimmedSearch.isEmpty else {
            // Show all sections
            allSections.forEach { $0.isHidden = false }
            return
        }

        // Filter sections based on search
        for section in allSections {
            let hasMatchingShortcut = section.filterShortcuts(with: trimmedSearch)
            section.isHidden = !hasMatchingShortcut
        }
    }

    // MARK: - Show

    func show() {
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Focus search field after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.searchField.window?.makeFirstResponder(self?.searchField)
        }
    }
}

// MARK: - NSSearchFieldDelegate

extension KeyboardShortcutsPanel: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let searchField = obj.object as? NSSearchField else { return }
        filterShortcuts(with: searchField.stringValue)
    }
}

// MARK: - Shortcut Section View

private class ShortcutSectionView: NSView {

    // MARK: - UI Components

    private var titleLabel: NSTextField!
    private var shortcutsStackView: NSStackView!
    private var divider: NSView!

    // MARK: - Properties

    private var shortcutRows: [ShortcutRowView] = []

    // MARK: - Initialization

    init(category: String, shortcuts: [(name: String, key: String)]) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI(category: category, shortcuts: shortcuts)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(category: String, shortcuts: [(name: String, key: String)]) {
        // Title label
        titleLabel = NSTextField(labelWithString: category)
        titleLabel.font = Typography.subheadline
        titleLabel.textColor = Colors.secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Divider
        divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = Colors.separator.cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(divider)

        // Shortcuts stack view
        shortcutsStackView = NSStackView()
        shortcutsStackView.orientation = .vertical
        shortcutsStackView.spacing = Spacing.pt8
        shortcutsStackView.alignment = .leading
        shortcutsStackView.distribution = .fill
        shortcutsStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(shortcutsStackView)

        // Add shortcut rows
        for shortcut in shortcuts {
            let rowView = ShortcutRowView(name: shortcut.name, key: shortcut.key)
            shortcutsStackView.addArrangedSubview(rowView)
            shortcutRows.append(rowView)
        }

        // Constraints
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Divider
            divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Spacing.pt4),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: Border.hairline),

            // Shortcuts stack
            shortcutsStackView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: Spacing.pt8),
            shortcutsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.pt12),
            shortcutsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.pt12),
            shortcutsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.pt8)
        ])
    }

    // MARK: - Filtering

    func filterShortcuts(with searchText: String) -> Bool {
        var hasMatch = false

        for row in shortcutRows {
            let matches = row.matches(searchText: searchText)
            row.isHidden = !matches
            if matches {
                hasMatch = true
            }
        }

        return hasMatch
    }
}

// MARK: - Shortcut Row View

private class ShortcutRowView: NSView {

    // MARK: - UI Components

    private var nameLabel: NSTextField!
    private var keyBadge: KeyBadgeView!

    // MARK: - Initialization

    init(name: String, key: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI(name: name, key: key)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(name: String, key: String) {
        // Name label
        nameLabel = NSTextField(labelWithString: name)
        nameLabel.font = Typography.body
        nameLabel.textColor = Colors.label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        // Key badge
        keyBadge = KeyBadgeView(key: key)
        addSubview(keyBadge)

        // Constraints
        NSLayoutConstraint.activate([
            // Name label
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            // Key badge
            keyBadge.centerYAnchor.constraint(equalTo: centerYAnchor),
            keyBadge.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: Spacing.pt16),
            keyBadge.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Height
            heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    // MARK: - Matching

    func matches(searchText: String) -> Bool {
        let nameLower = nameLabel.stringValue.lowercased()
        let keyLower = keyBadge.key.lowercased()

        return nameLower.contains(searchText) || keyLower.contains(searchText)
    }
}

// MARK: - Key Badge View

private class KeyBadgeView: NSView {

    // MARK: - UI Components

    private var backgroundView: NSView!
    private var label: NSTextField!

    // MARK: - Properties

    let key: String

    // MARK: - Initialization

    init(key: String) {
        self.key = key
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        // Background
        backgroundView = NSView()
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        backgroundView.layer?.cornerRadius = Layout.smallCornerRadius
        backgroundView.layer?.borderWidth = Border.hairline
        backgroundView.layer?.borderColor = Colors.separator.cgColor
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        // Key label
        label = NSTextField(labelWithString: key)
        label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        label.textColor = Colors.label
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(label)

        // Constraints
        NSLayoutConstraint.activate([
            // Background
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.heightAnchor.constraint(equalToConstant: 24),

            // Label
            label.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: Spacing.pt8),
            label.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -Spacing.pt8)
        ])
    }
}
