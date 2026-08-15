import AppKit
import SwiftUI
import Foundation

struct MDReaderDocument {
    let url: URL
    let content: String
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let documents: [MDReaderDocument]
    var windows: [NSWindow] = []

    init(documents: [MDReaderDocument]) {
        self.documents = documents
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        for doc in documents {
            let hosting = NSHostingController(
                rootView: MarkdownReaderView(sourceURL: doc.url, content: doc.content)
            )
            let window = NSWindow(contentViewController: hosting)
            window.title = doc.url.lastPathComponent
            window.titlebarAppearsTransparent = true
            window.setContentSize(NSSize(width: 900, height: 720))
            window.minSize = NSSize(width: 480, height: 360)
            window.backgroundColor = NSColor(Palette.background)
            window.center()
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let usage = """
    mdreader — native SwiftUI markdown reader (Linear design)

    Usage:
      mdreader [options] file.md [file2.md ...]

    Options:
      -h, --help      Show this help
      -v, --version   Show version
    """

func main() {
    let args = Array(CommandLine.arguments.dropFirst())
    var files: [String] = []

    for arg in args {
        switch arg {
        case "-h", "--help":
            print(usage)
            exit(0)
        case "-v", "--version":
            print("mdreader 0.1.0")
            exit(0)
        default:
            if arg.hasPrefix("-") {
                fputs("mdreader: unknown option '\(arg)'\n", stderr)
                fputs(usage, stderr)
                exit(1)
            }
            files.append(arg)
        }
    }

    if files.isEmpty {
        print(usage)
        exit(0)
    }

    var documents: [MDReaderDocument] = []
    for file in files {
        let url = URL(fileURLWithPath: file)
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            fputs("mdreader: cannot read '\(file)'\n", stderr)
            exit(1)
        }
        documents.append(MDReaderDocument(url: url, content: content))
    }

    let app = NSApplication.shared
    let delegate = AppDelegate(documents: documents)
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
}

main()
