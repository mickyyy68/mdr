import AppKit
import MDReaderCore
import SwiftUI

/// Owns the application lifecycle, main menu, and reader windows.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let documents: [DocumentLoader.LoadedDocument]
    private let theme: Theme
    private var windows: [NSWindow] = []
    private var settingsWindow: NSWindow?

    init(documents: [DocumentLoader.LoadedDocument], theme: Theme) {
        self.documents = documents
        self.theme = theme
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
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
        let hostingController = NSHostingController(
            rootView: MarkdownReaderView(document: document, theme: theme)
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = document.url.lastPathComponent
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 900, height: 720))
        window.minSize = NSSize(width: 480, height: 360)
        window.backgroundColor = NSColor(theme.palette.background)
        window.center()
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }

    @objc private func openSettings(_ sender: Any?) {
        if settingsWindow == nil {
            let settingsView = SettingsView(configURL: CLI.defaultThemePath)
            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "\(CLI.name) Settings"
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 540, height: 600))
            window.minSize = NSSize(width: 480, height: 480)
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
            action: #selector(openSettings(_:)),
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