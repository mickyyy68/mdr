import Testing
@testable import MDReaderCore

struct CLIArgumentParserTests {
    @Test func noArgumentsShowsHelp() throws {
        #expect(try CLI.parse([]) == .showHelp)
    }

    @Test func parsesFilePaths() throws {
        #expect(try CLI.parse(["a.md", "b.md"]) == .readFiles(["a.md", "b.md"]))
    }

    @Test func helpFlags() throws {
        #expect(try CLI.parse(["-h"]) == .showHelp)
        #expect(try CLI.parse(["--help"]) == .showHelp)
        #expect(try CLI.parse(["file.md", "-h"]) == .showHelp)
    }

    @Test func versionFlags() throws {
        #expect(try CLI.parse(["-v"]) == .showVersion)
        #expect(try CLI.parse(["--version"]) == .showVersion)
    }

    @Test func unknownOptionThrows() {
        #expect(throws: CLIError.unknownOption("--bogus")) {
            try CLI.parse(["--bogus"])
        }
        #expect(throws: CLIError.unknownOption("-x")) {
            try CLI.parse(["a.md", "-x"])
        }
    }

    @Test func dashedPathsAreRejected() {
        #expect(throws: CLIError.self) {
            try CLI.parse(["-fancy"])
        }
    }
}