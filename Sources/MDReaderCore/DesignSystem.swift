import AppKit
import SwiftUI

/// Linear design system — tokens from Linear's official design system (dark theme).
///
/// Source: Linear's `globals.css` design tokens (oklch), converted to sRGB hex.
public enum Palette {
    // MARK: Surfaces
    public static let background = Color(hex: 0x191A24)
    public static let foreground = Color(hex: 0xFFFFFF)
    public static let card = Color(hex: 0x1F202D)
    public static let cardForeground = Color(hex: 0xF8FAFC)
    public static let secondary = Color(hex: 0x272A3A)
    public static let secondaryForeground = Color(hex: 0x868798)
    public static let muted = Color(hex: 0x1F202D)
    public static let mutedForeground = Color(hex: 0x9B9EAB)
    public static let accent = Color(hex: 0x31323F)
    public static let accentForeground = Color(hex: 0xF8FAFC)

    // MARK: Brand
    public static let primary = Color(hex: 0x6B77FF)
    public static let destructive = Color(hex: 0x7F1D1D)

    // MARK: Stroke
    public static let border = Color(hex: 0x38394C)

    // MARK: Code syntax highlighting (Linear-adjacent hues)
    public static let syntaxKeyword = Color(hex: 0x6B77FF)
    public static let syntaxString = Color(hex: 0xA5B4FC)
    public static let syntaxComment = Color(hex: 0x6B7280)
    public static let syntaxType = Color(hex: 0x8B93E7)
    public static let syntaxNumber = Color(hex: 0xFBBF24)
    public static let syntaxPlain = Color(hex: 0xE5E7EB)
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

public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

public enum Radius {
    public static let sm: CGFloat = 4
    public static let md: CGFloat = 6
    public static let lg: CGFloat = 8
}

public enum Fonts {
    private static let interNames: [Font.Weight: String] = [
        .light: "Inter-Light",
        .regular: "Inter-Regular",
        .medium: "Inter-Medium",
        .semibold: "Inter-SemiBold",
        .bold: "Inter-Bold",
    ]

    /// `true` when the Inter font family is installed; resolved once at launch.
    private static let interAvailable = interNames.values.allSatisfy {
        NSFont(name: $0, size: 12) != nil
    }

    /// Linear's typeface. Falls back to the system font when Inter is unavailable.
    public static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if interAvailable, let name = interNames[weight] {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight)
    }
}