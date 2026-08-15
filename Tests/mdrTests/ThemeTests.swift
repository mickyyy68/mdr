import Foundation
import SwiftUI
import Testing
@testable import MDReaderCore

struct ThemeTests {
    @Test func linearMatchesDefaults() {
        #expect(Theme.linear.palette == Palette.linear)
        #expect(Theme.linear.spacing == Spacing.linear)
        #expect(Theme.linear.radius == Radius.linear)
        #expect(Theme.linear.fonts == FontConfig.linear)
    }

    @Test func mergedPartialOverrideKeepsDefaults() throws {
        let theme = try Theme.merged(with: ThemeOverride(palette: PaletteOverride(primary: "#7C3AED")))
        #expect(theme.palette.primary == Color(hex: 0x7C3AED))
        #expect(theme.palette.background == Palette.linear.background)
        #expect(theme.spacing == Spacing.linear)
    }

    @Test func mergedOverrideCoversAllGroups() throws {
        let theme = try Theme.merged(with: ThemeOverride(
            palette: PaletteOverride(background: "#0B0E14", primary: "#7C3AED"),
            spacing: SpacingOverride(md: 20),
            radius: RadiusOverride(md: 10),
            fonts: FontOverride(family: "SF Mono", body: 17)
        ))
        #expect(theme.palette.primary == Color(hex: 0x7C3AED))
        #expect(theme.palette.background == Color(hex: 0x0B0E14))
        #expect(theme.spacing.md == 20)
        #expect(theme.radius.md == 10)
        #expect(theme.fonts.family == "SF Mono")
        #expect(theme.fonts.body == 17)
    }

    @Test func unknownKeysAreIgnored() throws {
        let data = Data(##"{"bogus": true, "palette": {"nonsense": "#000000"}}"##.utf8)
        let override = try JSONDecoder().decode(ThemeOverride.self, from: data)
        #expect(try Theme.merged(with: override) == Theme.linear)
    }

    @Test func loadValidPartialFile() throws {
        let url = try temporaryFile(content: Data(##"{"palette":{"primary":"#123456"}}"##.utf8))
        defer { try? FileManager.default.removeItem(at: url) }

        let theme = try Theme.load(from: url)
        #expect(theme.palette.primary == Color(hex: 0x123456))
        #expect(theme.palette.background == Palette.linear.background)
    }

    @Test func loadMissingFileThrows() {
        let url = URL(fileURLWithPath: "/nonexistent/theme.json")
        #expect(throws: ThemeError.fileNotFound(path: url.path)) {
            try Theme.load(from: url)
        }
    }

    @Test func loadMalformedJSONThrows() throws {
        let url = try temporaryFile(content: Data("{ not json".utf8))
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: ThemeError.invalidJSON(path: url.path)) {
            try Theme.load(from: url)
        }
    }

    @Test func loadInvalidHexThrows() throws {
        let url = try temporaryFile(content: Data(##"{"palette":{"primary":"#GGGGGG"}}"##.utf8))
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: ThemeError.invalidColor(key: "palette.primary", value: "#GGGGGG", path: url.path)) {
            try Theme.load(from: url)
        }
    }

    @Test func loadNonNumericSpacingThrows() throws {
        let url = try temporaryFile(content: Data(##"{"spacing":{"xs":"four"}}"##.utf8))
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            _ = try Theme.load(from: url)
            Issue.record("expected ThemeError")
        } catch let error as ThemeError {
            guard case .invalidValue(let key, _, _) = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
            #expect(key == "spacing.xs")
        }
    }

    @Test func loadNonPositiveNumberThrows() throws {
        let url = try temporaryFile(content: Data(##"{"radius":{"md":0}}"##.utf8))
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: ThemeError.invalidValue(key: "radius.md", value: "0.0", path: url.path)) {
            try Theme.load(from: url)
        }
    }

    @Test func resolveExplicitBeatsDefault() throws {
        let explicit = try temporaryFile(content: Data(##"{"palette":{"primary":"#111111"}}"##.utf8))
        defer { try? FileManager.default.removeItem(at: explicit) }
        let defaultFile = try temporaryFile(content: Data(##"{"palette":{"primary":"#222222"}}"##.utf8))
        defer { try? FileManager.default.removeItem(at: defaultFile) }

        let theme = try Theme.resolve(explicit: explicit, defaultFile: defaultFile)
        #expect(theme.palette.primary == Color(hex: 0x111111))
    }

    @Test func resolveUsesDefaultWhenNoExplicit() throws {
        let defaultFile = try temporaryFile(content: Data(##"{"palette":{"primary":"#222222"}}"##.utf8))
        defer { try? FileManager.default.removeItem(at: defaultFile) }

        let theme = try Theme.resolve(explicit: nil, defaultFile: defaultFile)
        #expect(theme.palette.primary == Color(hex: 0x222222))
    }

    @Test func resolveFallsBackToLinear() throws {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdr-missing-\(UUID().uuidString).json")

        #expect(try Theme.resolve(explicit: nil, defaultFile: missing) == Theme.linear)
    }

    @Test func defaultConfigRoundTripsToLinear() throws {
        let data = try Theme.defaultConfigData()
        let override = try JSONDecoder().decode(ThemeOverride.self, from: data)
        #expect(try Theme.merged(with: override) == Theme.linear)
    }

    private func temporaryFile(content: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdr-theme-\(UUID().uuidString).json")
        try content.write(to: url)
        return url
    }
}