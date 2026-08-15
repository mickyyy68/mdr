import AppKit
import SwiftUI

/// A color in OKLCH space. `l` is perceptual lightness (0...1), `c` is chroma,
/// `h` is hue in degrees (0..<360).
internal struct OKLCH: Equatable {
    var l: CGFloat
    var c: CGFloat
    var h: CGFloat
}

/// Pure color math: sRGB, linear RGB, and OKLCH conversions plus WCAG contrast.
internal enum ColorMath {
    // MARK: sRGB <-> linear RGB

    static func toLinear(_ component: CGFloat) -> CGFloat {
        component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }

    static func fromLinear(_ component: CGFloat) -> CGFloat {
        component <= 0.0031308 ? 12.92 * component : 1.055 * pow(component, 1 / 2.4) - 0.055
    }

    // MARK: linear RGB <-> OKLCH

    /// Björn Ottosson's OKLab conversion, presented as LCH.
    static func okLCH(r: CGFloat, g: CGFloat, b: CGFloat) -> OKLCH {
        let l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
        let m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
        let s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
        let l3 = pow(l, 1 / 3), m3 = pow(m, 1 / 3), s3 = pow(s, 1 / 3)
        let L = 0.2104542553 * l3 + 0.7936177850 * m3 - 0.0040720468 * s3
        let a = 1.9779984951 * l3 - 2.4285922050 * m3 + 0.4505937099 * s3
        let b2 = 0.0259040371 * l3 + 0.7827717662 * m3 - 0.8086757660 * s3
        let chroma = hypot(a, b2)
        let hue = (atan2(b2, a) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        return OKLCH(l: L, c: chroma, h: hue)
    }

    static func rgb(from okLCH: OKLCH) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let a = okLCH.c * cos(okLCH.h * .pi / 180)
        let b = okLCH.c * sin(okLCH.h * .pi / 180)
        let l_ = okLCH.l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = okLCH.l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = okLCH.l - 0.0894841775 * a - 1.2914855480 * b
        let l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_
        let r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        let g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        let blue = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
        return (r: r, g: g, b: blue)
    }

    // MARK: Relative luminance & WCAG contrast

    static func luminance(okLCH: OKLCH) -> CGFloat {
        let rgb = rgb(from: okLCH)
        // Clamp so out-of-gamut components match the final sRGB color.
        func clamp(_ x: CGFloat) -> CGFloat { min(max(x, 0), 1) }
        return 0.2126 * clamp(rgb.r) + 0.7152 * clamp(rgb.g) + 0.0722 * clamp(rgb.b)
    }

    static func contrast(_ a: OKLCH, _ b: OKLCH) -> CGFloat {
        let la = luminance(okLCH: a), lb = luminance(okLCH: b)
        let hi = max(la, lb), lo = min(la, lb)
        return (hi + 0.05) / (lo + 0.05)
    }
}

internal func okLCH(from color: Color) -> OKLCH {
    let ns = NSColor(color).usingColorSpace(.sRGB) ?? .black
    return ColorMath.okLCH(
        r: ColorMath.toLinear(ns.redComponent),
        g: ColorMath.toLinear(ns.greenComponent),
        b: ColorMath.toLinear(ns.blueComponent)
    )
}

internal func color(from okLCH: OKLCH) -> Color {
    let rgb = ColorMath.rgb(from: okLCH)
    // Quantize to 8-bit sRGB so derived colors survive hex serialization exactly.
    func quantize(_ x: CGFloat) -> CGFloat { (clamp(ColorMath.fromLinear(x)) * 255).rounded() / 255 }
    func clamp(_ x: CGFloat) -> CGFloat { min(max(x, 0), 1) }
    return Color(
        .sRGB,
        red: quantize(rgb.r),
        green: quantize(rgb.g),
        blue: quantize(rgb.b),
        opacity: 1
    )
}

/// Derives a complete 19-role palette from a background and an accent color,
/// T3-Code style: surfaces climb a lightness ramp off the background, every
/// text role is contrast-solved against its surface, and the syntax colors
/// are derived from the accent hue.
public enum PaletteDerivation {
    public static func derive(background: Color, accent: Color) -> Palette {
        let bg = okLCH(from: background)
        let ac = okLCH(from: accent)
        let dark = bg.l <= 0.55

        func neutral(_ l: CGFloat) -> OKLCH { OKLCH(l: l, c: 0.015, h: bg.h) }
        func tinted(_ l: CGFloat, chromaScale: CGFloat) -> OKLCH {
            OKLCH(l: l, c: max(ac.c * chromaScale, 0.02), h: ac.h)
        }

        // Surfaces: a perceptual ramp off the background (lighter for dark
        // backgrounds, darker for light ones).
        let shift: CGFloat = dark ? 0.03 : -0.03
        let card = OKLCH(l: bg.l + shift, c: max(bg.c, 0.02), h: bg.h)
        let secondary = OKLCH(l: bg.l + shift * 2, c: max(bg.c, 0.02), h: bg.h)
        let muted = card
        let border = OKLCH(l: bg.l + shift * (14.0 / 3.0), c: 0.02, h: bg.h)
        let accentSurface = tinted(bg.l + shift * (5.0 / 3.0), chromaScale: 0.35)

        // Text roles, each contrast-solved against the surface it sits on.
        let foreground = solve(neutral(dark ? 0.96 : 0.04), on: bg)
        let cardForeground = solve(neutral(dark ? 0.96 : 0.04), on: card)
        let secondaryForeground = solve(neutral(dark ? 0.7 : 0.3), on: secondary)
        let mutedForeground = solve(neutral(dark ? 0.62 : 0.4), on: muted)
        let accentForeground = solve(neutral(dark ? 0.96 : 0.04), on: accentSurface)
        let primary = solve(tinted(dark ? max(ac.l, 0.55) : min(ac.l, 0.5), chromaScale: 1), on: bg)
        let destructive = solve(OKLCH(l: 0.52, c: 0.2, h: 25), on: bg)

        // Syntax colors against the code-block surface.
        let syntaxPlain = solve(neutral(dark ? 0.9 : 0.12), on: secondary)
        let syntaxComment = solve(neutral(dark ? 0.55 : 0.5), on: secondary)
        let syntaxKeyword = solve(primary, on: secondary)
        let syntaxString = solve(tinted(dark ? 0.75 : 0.35, chromaScale: 0.9), on: secondary)
        let syntaxType = solve(tinted(dark ? 0.7 : 0.4, chromaScale: 0.75), on: secondary)
        let syntaxNumber = solve(OKLCH(l: 0.75, c: 0.15, h: 75), on: secondary)

        return Palette(
            background: color(from: bg),
            foreground: color(from: foreground),
            card: color(from: card),
            cardForeground: color(from: cardForeground),
            secondary: color(from: secondary),
            secondaryForeground: color(from: secondaryForeground),
            muted: color(from: muted),
            mutedForeground: color(from: mutedForeground),
            accent: color(from: accentSurface),
            accentForeground: color(from: accentForeground),
            primary: color(from: primary),
            destructive: color(from: destructive),
            border: color(from: border),
            syntaxKeyword: color(from: syntaxKeyword),
            syntaxString: color(from: syntaxString),
            syntaxComment: color(from: syntaxComment),
            syntaxType: color(from: syntaxType),
            syntaxNumber: color(from: syntaxNumber),
            syntaxPlain: color(from: syntaxPlain)
        )
    }

    /// WCAG contrast ratio between two colors (used by tests).
    internal static func wcagContrast(_ a: Color, _ b: Color) -> CGFloat {
        ColorMath.contrast(okLCH(from: a), okLCH(from: b))
    }

    /// Pushes `base`'s lightness away from `surface` until WCAG contrast is at
    /// least 4.6 (leaving headroom for 8-bit quantization to land ≥ 4.5),
    /// preserving chroma and hue.
    private static func solve(_ base: OKLCH, on surface: OKLCH) -> OKLCH {
        let lightText = surface.l <= 0.5
        var lo: CGFloat = 0
        var hi: CGFloat = 1
        for _ in 0..<12 {
            let mid = (lo + hi) / 2
            let candidate = OKLCH(l: mid, c: base.c, h: base.h)
            let ok = ColorMath.contrast(candidate, surface) >= 4.6
            if lightText {
                ok ? (hi = mid) : (lo = mid)
            } else {
                ok ? (lo = mid) : (hi = mid)
            }
        }
        return OKLCH(l: lightText ? hi : lo, c: base.c, h: base.h)
    }
}