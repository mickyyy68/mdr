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
}