import AppKit
import Foundation
import MDReaderCore

@main
enum MDReaderApp {
    @MainActor
    static func main() {
        let command: Command
        do {
            command = try CLI.parse(Array(CommandLine.arguments.dropFirst()))
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            fputs(CLI.usage, stderr)
            exit(EXIT_FAILURE)
        }

        switch command {
        case .showHelp:
            print(CLI.usage)

        case .showVersion:
            print("\(CLI.name) \(CLI.version)")

        case .readFiles(let paths):
            do {
                let documents = try paths.map {
                    try DocumentLoader.load(url: URL(fileURLWithPath: $0))
                }
                runReader(documents: documents)
            } catch {
                fputs("\(error.localizedDescription)\n", stderr)
                exit(EXIT_FAILURE)
            }
        }
    }

    @MainActor
    private static func runReader(documents: [DocumentLoader.LoadedDocument]) {
        let application = NSApplication.shared
        let delegate = AppDelegate(documents: documents)
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        application.run()
    }
}