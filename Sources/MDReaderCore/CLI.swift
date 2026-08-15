import Foundation

/// The action a user requested via the command line.
public enum Command: Equatable {
    case readFiles([String])
    case showHelp
    case showVersion
}

public enum CLIError: Error, Equatable {
    case unknownOption(String)
}

extension CLIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknownOption(let option):
            return "mdreader: unknown option '\(option)'"
        }
    }
}

public enum CLI {
    public static let name = "mdreader"
    public static let version = "1.0.0"

    public static let usage = """
    \(name) — native SwiftUI markdown reader (Linear design)

    Usage:
      \(name) [options] file.md [file2.md ...]

    Options:
      -h, --help      Show this help
      -v, --version   Show version
    """

    /// Parses command-line arguments (excluding the executable path).
    public static func parse(_ arguments: [String]) throws -> Command {
        guard !arguments.isEmpty else { return .showHelp }

        var files: [String] = []
        for argument in arguments {
            switch argument {
            case "-h", "--help":
                return .showHelp
            case "-v", "--version":
                return .showVersion
            default:
                if argument.hasPrefix("-") {
                    throw CLIError.unknownOption(argument)
                }
                files.append(argument)
            }
        }
        return .readFiles(files)
    }
}