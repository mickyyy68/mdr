import Testing
@testable import MDReaderCore

struct ThemePresetTests {
    @Test func allCasesOrdering() {
        #expect(ThemePreset.allCases.map(\.rawValue) == ["linear", "midnight", "forest", "ember"])
    }

    @Test func derivedPresetsDifferFromLinear() {
        for preset in ThemePreset.allCases where preset != .linear {
            #expect(preset.theme.palette != Theme.linear.palette)
            #expect(preset.theme.lightPalette != nil)
        }
    }

    @Test func presetsCarryLightVariants() {
        for preset in ThemePreset.allCases {
            #expect(preset.theme.palette(for: .light) != preset.theme.palette(for: .dark))
            #expect(preset.theme.label == preset.label)
        }
    }

    @Test func lightPalettesArePairwiseDistinct() {
        let palettes = ThemePreset.allCases.compactMap { $0.theme.lightPalette }
        for i in palettes.indices {
            for j in palettes.indices where j > i {
                #expect(palettes[i] != palettes[j])
            }
        }
    }

    @Test func presetsArePairwiseDistinct() {
        let palettes = ThemePreset.allCases.map { $0.theme.palette }
        for i in palettes.indices {
            for j in palettes.indices where j > i {
                #expect(palettes[i] != palettes[j])
            }
        }
    }

    @Test func presetSurvivesSerializeLoadMerge() throws {
        for preset in ThemePreset.allCases {
            let override = ThemeOverride(theme: preset.theme)
            #expect(try Theme.merged(with: override) == preset.theme)
        }
    }
}