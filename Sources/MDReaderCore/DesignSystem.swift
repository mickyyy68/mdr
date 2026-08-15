import AppKit
import SwiftUI

/// Linear design system — tokens from Linear's official design system (dark theme).
///
/// Source: Linear's `globals.css` design tokens (oklch), converted to sRGB hex.
///
/// Tokens are value types so they can be composed into a `Theme` and overridden
/// at runtime; `linear` carries the canonical defaults.
public struct Palette: Equatable, Sendable {
    // MARK: Surfaces
    public var background: Color
    public var foreground: Color
    public var card: Color
    public var cardForeground: Color
    public var secondary: Color
    public var secondaryForeground: Color
    public var muted: Color
    public var mutedForeground: Color
    public var accent: Color
    public var accentForeground: Color

    // MARK: Brand
    public var primary: Color
    public var destructive: Color

    // MARK: Stroke
    public var border: Color

    // MARK: Code syntax highlighting (Linear-adjacent hues)
    public var syntaxKeyword: Color
    public var syntaxString: Color
    public var syntaxComment: Color
    public var syntaxType: Color
    public var syntaxNumber: Color
    public var syntaxPlain: Color

    /// The canonical Linear dark palette.
    public static let linear = Palette(
        background: Color(hex: 0x191A24),
        foreground: Color(hex: 0xFFFFFF),
        card: Color(hex: 0x1F202D),
        cardForeground: Color(hex: 0xF8FAFC),
        secondary: Color(hex: 0x272A3A),
        secondaryForeground: Color(hex: 0x868798),
        muted: Color(hex: 0x1F202D),
        mutedForeground: Color(hex: 0x9B9EAB),
        accent: Color(hex: 0x31323F),
        accentForeground: Color(hex: 0xF8FAFC),
        primary: Color(hex: 0x6B77FF),
        destructive: Color(hex: 0x7F1D1D),
        border: Color(hex: 0x38394C),
        syntaxKeyword: Color(hex: 0x6B77FF),
        syntaxString: Color(hex: 0xA5B4FC),
        syntaxComment: Color(hex: 0x6B7280),
        syntaxType: Color(hex: 0x8B93E7),
        syntaxNumber: Color(hex: 0xFBBF24),
        syntaxPlain: Color(hex: 0xE5E7EB)
    )
}

public extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Vertical rhythm tokens.
public struct Spacing: Equatable, Sendable {
    public var xs: CGFloat
    public var sm: CGFloat
    public var md: CGFloat
    public var lg: CGFloat
    public var xl: CGFloat
    public var xxl: CGFloat

    public static let linear = Spacing(xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32)
}

/// Corner radius tokens.
public struct Radius: Equatable, Sendable {
    public var sm: CGFloat
    public var md: CGFloat
    public var lg: CGFloat

    public static let linear = Radius(sm: 4, md: 6, lg: 8)
}

/// Typography tokens: an optional family plus named size roles.
public struct FontConfig: Equatable, Sendable {
    /// The font family to use. `nil` or `"Inter"` resolve to the per-weight
    /// Inter names below (with a system fallback); any other installed family
    /// is used directly with the requested weight.
    public var family: String?
    public var heading1: CGFloat
    public var heading2: CGFloat
    public var heading3: CGFloat
    public var heading4: CGFloat
    public var heading5: CGFloat
    public var body: CGFloat
    public var caption: CGFloat
    public var code: CGFloat
    public var inlineCode: CGFloat
    public var label: CGFloat
    public var lineSpacing: CGFloat

    /// The canonical Linear typography.
    public static let linear = FontConfig(
        family: "Inter",
        heading1: 26,
        heading2: 20,
        heading3: 17,
        heading4: 15,
        heading5: 14,
        body: 15,
        caption: 13,
        code: 13,
        inlineCode: 12.5,
        label: 11,
        lineSpacing: 3
    )

    private static let interNames: [Font.Weight: String] = [
        .light: "Inter-Light",
        .regular: "Inter-Regular",
        .medium: "Inter-Medium",
        .semibold: "Inter-SemiBold",
        .bold: "Inter-Bold",
    ]

    /// `true` when the Inter font family is installed; resolved once.
    private static let interAvailable = interNames.values.allSatisfy {
        NSFont(name: $0, size: 12) != nil
    }

    /// Resolves a font at `size` and `weight` according to the configured family.
    public func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let family, family != "Inter", NSFont(name: family, size: size) != nil {
            return .custom(family, size: size).weight(weight)
        }
        if Self.interAvailable, let name = Self.interNames[weight] {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight)
    }
}