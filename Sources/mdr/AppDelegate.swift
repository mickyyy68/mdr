import AppKit
import MDReaderCore
import SwiftUI

/// Owns the application lifecycle, main menu, and reader windows.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private struct WindowRecord {
        let window: NSWindow
        let model: ReaderViewModel
    }

    private let documents: [DocumentLoader.LoadedDocument]
    private let store: ThemeStore
    private var windowRecords: [WindowRecord] = []

    init(documents: [DocumentLoader.LoadedDocument], store: ThemeStore) {
        self.documents = documents
        self.store = store
        super.init()
        store.onThemeChange = { [weak self] _ in
            self?.updateWindows()
        }
        store.onAppearanceModeChange = { [weak self] mode in
            Self.persistAppearanceMode(mode)
            self?.updateWindows()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.appearanceMode = Self.loadAppearanceMode()
        configureMainMenu()
        for document in documents {
            openWindow(for: document)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // MARK: - Windows

    private func openWindow(for document: DocumentLoader.LoadedDocument) {
        let model = ReaderViewModel()
        let hostingController = NSHostingController(
            rootView: ReaderView(document: document, store: store, model: model)
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = document.url.lastPathComponent
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 900, height: 720))
        window.minSize = NSSize(width: 480, height: 360)
        window.center()
        window.makeKeyAndOrderFront(nil)
        windowRecords.append(WindowRecord(window: window, model: model))
        applyWindowStyle(window)
    }

    /// Keeps every window's background and `NSAppearance` aligned with the
    /// resolved theme and appearance mode.
    private func updateWindows() {
        for record in windowRecords {
            applyWindowStyle(record.window)
        }
    }

    private func applyWindowStyle(_ window: NSWindow) {
        window.backgroundColor = NSColor(store.resolvedTheme.palette.background)
        window.appearance = Self.nsAppearance(for: store.appearanceMode)
    }

    // MARK: - Appearance persistence

    private static let appearanceModeKey = "mdr:appearance-mode"

    private static func loadAppearanceMode() -> ThemeAppearanceMode {
        guard let raw = UserDefaults.standard.string(forKey: appearanceModeKey),
              let mode = ThemeAppearanceMode(rawValue: raw) else { return .system }
        return mode
    }

    private static func persistAppearanceMode(_ mode: ThemeAppearanceMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: appearanceModeKey)
    }

    /// The window `NSAppearance` for a mode: `nil` follows the system.
    private static func nsAppearance(for mode: ThemeAppearanceMode) -> NSAppearance? {
        switch mode {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    /// Shows the settings view in the key window. The Settings… menu item and
    /// ⌘, land here; the in-view gear button updates its own model directly.
    @objc private func showSettings(_ sender: Any?) {
        guard let keyWindow = NSApp.keyWindow,
              let record = windowRecords.first(where: { $0.window === keyWindow }) else { return }
        record.model.isShowingSettings = true
    }

    // MARK: - Menu

    private func configureMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu(title: CLI.name)
        appMenu.addItem(
            withTitle: "About \(CLI.name)",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Settings…",
            action: #selector(showSettings(_:)),
            keyEquivalent: ","
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Close Window",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )
        appMenu.addItem(
            withTitle: "Quit \(CLI.name)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }
}