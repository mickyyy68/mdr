import SwiftUI
import Testing
@testable import MDReaderCore

struct CodeHighlighterTests {
    /// Returns `(text, color)` runs of the highlighted code.
    private func runs(of code: String) -> [(String, Color)] {
        let attributed = CodeHighlighter.highlight(code, palette: Palette.linear)
        return attributed.runs.map { run in
            let string = String(attributed[run.range].characters)
            let color = run.attributes.foregroundColor ?? .clear
            return (string, color)
        }
    }

    @Test func highlightsKeywords() {
        let runs = runs(of: "func foo()")
        #expect(runs.contains { $0.0 == "func" && $0.1 == Palette.linear.syntaxKeyword })
    }

    @Test func highlightsStringsIncludingEscapes() {
        let runs = runs(of: #"let s = "a\"b""#)
        #expect(runs.contains { $0.0 == #""a\"b""# && $0.1 == Palette.linear.syntaxString })
    }

    @Test func highlightsLineComments() {
        let runs = runs(of: "// todo: fix\nlet x = 1")
        #expect(runs.contains { $0.0 == "// todo: fix" && $0.1 == Palette.linear.syntaxComment })
    }

    @Test func highlightsBlockComments() {
        let runs = runs(of: "/* multi\nline */ let x")
        #expect(runs.contains { $0.0 == "/* multi\nline */" && $0.1 == Palette.linear.syntaxComment })
    }

    @Test func highlightsNumbers() {
        let runs = runs(of: "let count = 42; let hex = 0xFF")
        #expect(runs.contains { $0.0 == "42" && $0.1 == Palette.linear.syntaxNumber })
        #expect(runs.contains { $0.0 == "0xFF" && $0.1 == Palette.linear.syntaxNumber })
    }

    @Test func leavesIdentifiersPlain() {
        let runs = runs(of: "fooBar baz")
        #expect(runs.contains { $0.0.contains("fooBar") && $0.1 == Palette.linear.syntaxPlain })
    }

    @Test func emptyCodeProducesEmptyResult() {
        #expect(CodeHighlighter.highlight("", palette: Palette.linear).characters.count == 0)
    }

    @Test func customPaletteColorsAreUsed() throws {
        let theme = try Theme.merged(with: ThemeOverride(palette: PaletteOverride(syntaxKeyword: "#FF0000")))
        let runs = CodeHighlighter.highlight("func foo()", palette: theme.palette)
        #expect(runs.runs.contains { $0.attributes.foregroundColor == Color(hex: 0xFF0000) })
    }
}