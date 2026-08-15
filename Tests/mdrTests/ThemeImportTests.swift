import Foundation
import SwiftUI
import Testing
@testable import MDReaderCore

struct ThemeImportTests {
    @Test func validOverrideImports() throws {
        let data = Data(##"{"palette":{"primary":"#123456"}}"##.utf8)
        let theme = try Theme.merged(withData: data, label: "pasted JSON")
        #expect(theme.palette.primary == Color(hex: 0x123456))
        #expect(theme.palette.background == Palette.linear.background)
    }

    @Test func malformedJSONThrowsInvalidJSON() {
        let data = Data("{ not json".utf8)
        #expect(throws: ThemeError.invalidJSON(path: "pasted JSON")) {
            try Theme.merged(withData: data, label: "pasted JSON")
        }
    }

    @Test func invalidValueThrows() {
        let data = Data(##"{"palette":{"primary":"#GGGGGG"}}"##.utf8)
        #expect(throws: ThemeError.invalidColor(key: "palette.primary", value: "#GGGGGG", path: "pasted JSON")) {
            try Theme.merged(withData: data, label: "pasted JSON")
        }
    }

    @Test func foreignFormatThrowsUnsupported() {
        let data = Data(#"{"version":1,"name":"Dracula","colors":{}}"#.utf8)
        #expect(throws: ThemeError.unsupportedFormat) {
            try Theme.merged(withData: data, label: "pasted JSON")
        }
    }

    @Test func emptyObjectThrowsUnsupported() {
        let data = Data("{}".utf8)
        #expect(throws: ThemeError.unsupportedFormat) {
            try Theme.merged(withData: data, label: "pasted JSON")
        }
    }
}