import SwiftUI
import Testing
@testable import MDReaderCore

struct ColorDerivationTests {
    @Test func hexStringRoundTrips() {
        #expect(Color(hex: 0x123456).hexString == "#123456")
        #expect(Color(hex: 0xFFFFFF).hexString == "#FFFFFF")
        #expect(Color(hex: 0x000000).hexString == "#000000")
    }

    @Test func okLCHBlackAndWhite() {
        let black = okLCH(from: Color(hex: 0x000000))
        let white = okLCH(from: Color(hex: 0xFFFFFF))
        #expect(black.l < 0.001)
        #expect(white.l > 0.999)
    }

    @Test func neutralGrayHasZeroChroma() {
        let gray = okLCH(from: Color(hex: 0x808080))
        #expect(gray.c < 0.01)
    }

    @Test func linearRGBToOKLCHRoundTrips() {
        let samples: [(CGFloat, CGFloat, CGFloat)] = [
            (0.1, 0.4, 0.7), (0.9, 0.2, 0.3), (0.5, 0.5, 0.5), (0.0, 0.0, 0.0), (1.0, 1.0, 1.0),
        ]
        for (r, g, b) in samples {
            let ok = ColorMath.okLCH(r: r, g: g, b: b)
            let rgb = ColorMath.rgb(from: ok)
            #expect(abs(rgb.r - r) < 0.002)
            #expect(abs(rgb.g - g) < 0.002)
            #expect(abs(rgb.b - b) < 0.002)
        }
    }

    @Test func derivationIsDeterministic() {
        let a = PaletteDerivation.derive(background: Color(hex: 0x0B0E14), accent: Color(hex: 0x7C3AED))
        let b = PaletteDerivation.derive(background: Color(hex: 0x0B0E14), accent: Color(hex: 0x7C3AED))
        #expect(a == b)
    }

    @Test func derivedTextClearsWCAGContrast() {
        let seeds: [(UInt32, UInt32)] = [
            (0x0B0E14, 0x7C3AED),
            (0x0A0F0D, 0x34D399),
            (0x120C0A, 0xF97316),
            (0x191A24, 0x6B77FF),
            (0x000000, 0xFFFFFF),
            (0xFFFFFF, 0x6B77FF),
            (0x1A1B2E, 0x888888),
        ]
        for (bg, ac) in seeds {
            let p = PaletteDerivation.derive(background: Color(hex: bg), accent: Color(hex: ac))
            #expect(contrast(p.foreground, p.background) >= 4.4)
            #expect(contrast(p.cardForeground, p.card) >= 4.4)
            #expect(contrast(p.secondaryForeground, p.secondary) >= 4.4)
            #expect(contrast(p.mutedForeground, p.muted) >= 4.4)
            #expect(contrast(p.accentForeground, p.accent) >= 4.4)
            #expect(contrast(p.syntaxPlain, p.secondary) >= 4.4)
            #expect(contrast(p.syntaxComment, p.secondary) >= 4.4)
            #expect(contrast(p.syntaxKeyword, p.secondary) >= 4.4)
            #expect(contrast(p.syntaxString, p.secondary) >= 4.4)
            #expect(contrast(p.syntaxType, p.secondary) >= 4.4)
            #expect(contrast(p.syntaxNumber, p.secondary) >= 4.4)
        }
    }

    @Test func lightBackgroundYieldsDarkText() {
        let p = PaletteDerivation.derive(background: Color(hex: 0xFFFFFF), accent: Color(hex: 0x6B77FF))
        #expect(contrast(p.foreground, p.background) >= 4.5)
    }

    private func contrast(_ a: Color, _ b: Color) -> CGFloat {
        PaletteDerivation.wcagContrast(a, b)
    }
}