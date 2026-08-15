import Foundation

/// The action a user requested via the command line.
public enum Command: Equatable {
    case readFiles([String], themePath: String?)
    case showHelp
    case showVersion
}

public enum CLIError: Error, Equatable {
    case unknownOption(String)
    case missingValue(String)
}

extension CLIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknownOption(let option):
            return "mdr: unknown option '\(option)'"
        case .missingValue(let option):
            return "mdr: option '\(option)' requires a value"
        }
    }
}

public enum CLI {
    public static let name = "mdr"
    public static let version = "1.0.0"

    /// The config file loaded automatically when no `--theme` is given.
    public static var defaultThemePath: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("mdr")
            .appendingPathComponent("theme.json")
    }

    public static let usage = """
    \(name) — native SwiftUI markdown reader (Linear design)

    Usage:
      \(name) [options] file.md [file2.md ...]

    Options:
      -h, --help           Show this help
      -v, --version        Show version
      -t, --theme <path>   Load design tokens from a JSON config
                           (defaults to ~/.config/mdr/theme.json)
    """

    /// Parses command-line arguments (excluding the executable path).
    public static func parse(_ arguments: [String]) throws -> Command {
        guard !arguments.isEmpty else { return .showHelp }

        var files: [String] = []
        var themePath: String?
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "-h", "--help":
                return .showHelp
            case "-v", "--version":
                return .showVersion
            case "-t", "--theme":
                guard index + 1 < arguments.count else {
                    throw CLIError.missingValue("--theme")
                }
                index += 1
                themePath = arguments[index]
            default:
                if argument.hasPrefix("-") {
                    throw CLIError.unknownOption(argument)
                }
                files.append(argument)
            }
            index += 1
        }
        return .readFiles(files, themePath: themePath)
    }
}