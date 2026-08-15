import SwiftUI

/// Linear design system — tokens from Linear's official design system (dark theme).
///
/// Source: Linear's globals.css design tokens (oklch), converted to sRGB hex.
enum Palette {
    // MARK: Surfaces
    static let background = Color(hex: 0x191A24)
    static let foreground = Color(hex: 0xFFFFFF)
    static let card = Color(hex: 0x1F202D)
    static let cardForeground = Color(hex: 0xF8FAFC)
    static let secondary = Color(hex: 0x272A3A)
    static let secondaryForeground = Color(hex: 0x868798)
    static let muted = Color(hex: 0x1F202D)
    static let mutedForeground = Color(hex: 0x9B9EAB)
    static let accent = Color(hex: 0x31323F)
    static let accentForeground = Color(hex: 0xF8FAFC)

    // MARK: Brand
    static let primary = Color(hex: 0x6B77FF)
    static let destructive = Color(hex: 0x7F1D1D)

    // MARK: Stroke
    static let border = Color(hex: 0x38394C)

    // MARK: Code syntax highlighting (Linear-adjacent hues)
    static let syntaxKeyword = Color(hex: 0x6B77FF)
    static let syntaxString = Color(hex: 0xA5B4FC)
    static let syntaxComment = Color(hex: 0x6B7280)
    static let syntaxType = Color(hex: 0x8B93E7)
    static let syntaxNumber = Color(hex: 0xFBBF24)
    static let syntaxPlain = Color(hex: 0xE5E7EB)
}

extension Color {
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

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum Radius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 6
    static let lg: CGFloat = 8
}

enum Fonts {
    /// Linear uses Inter. Falls back to the system font when unavailable.
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let names: [(String, Font.Weight)] = [
            ("Inter-Bold", .bold),
            ("Inter-SemiBold", .semibold),
            ("Inter-Medium", .medium),
            ("Inter-Regular", .regular),
            ("Inter-Light", .light),
        ]
        if let (name, w) = names.first(where: { $0.1 == weight && NSFont(name: $0.0, size: size) != nil }) {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight)
    }

    static let mono = Font.system(.body, design: .monospaced)
}
