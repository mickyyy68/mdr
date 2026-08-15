import Foundation
import Testing
@testable import MDReaderCore

struct ThemeSerializationTests {
    @Test func linearRoundTripsThroughOverride() throws {
        #expect(try Theme.merged(with: ThemeOverride(theme: .linear)) == Theme.linear)
    }

    @Test func serializedLinearMatchesBootstrapConfig() throws {
        let bootstrap = try JSONDecoder().decode(ThemeOverride.self, from: Theme.defaultConfigData())
        let serialized = try JSONEncoder().encode(ThemeOverride(theme: .linear))
        let decoded = try JSONDecoder().decode(ThemeOverride.self, from: serialized)
        #expect(decoded == bootstrap)
    }

    @Test func presetRoundTripsThroughFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdr-serialization-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        try ThemePersistence.save(.preset(.midnight), to: url)
        #expect(try Theme.load(from: url) == .preset(.midnight))
    }

    @Test func missingFamilyKeyMeansSystemFont() throws {
        let data = Data(#"{"fonts":{}}"#.utf8)
        let theme = try Theme.merged(withData: data, label: "fonts only")
        #expect(theme.fonts.family == nil)
    }

    @Test func explicitFamilyKeyStillApplies() throws {
        let data = Data(#"{"fonts":{"family":"SF Mono"}}"#.utf8)
        let theme = try Theme.merged(withData: data, label: "fonts only")
        #expect(theme.fonts.family == "SF Mono")
    }

    @Test func systemFontFamilyRoundTripsThroughFile() throws {
        var theme = Theme.linear
        theme.fonts.family = nil
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdr-serialization-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        try ThemePersistence.save(theme, to: url)
        #expect(try Theme.load(from: url).fonts.family == nil)
    }
}