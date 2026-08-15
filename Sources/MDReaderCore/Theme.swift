import Foundation
import SwiftUI

/// A fully-resolved set of design tokens.
///
/// `Theme.linear` is the canonical Linear look. `load` / `resolve` build themes
/// from a JSON config file that overrides a subset of the defaults; this is also
/// the seam where bundled preset themes can be introduced later (a preset is
/// just a named override merged in before the user's file).
public struct Theme: Equatable, Sendable {
    public var palette: Palette
    public var spacing: Spacing
    public var radius: Radius
    public var fonts: FontConfig

    public static let linear = Theme(palette: .linear, spacing: .linear, radius: .linear, fonts: .linear)

    /// Loads a theme from a JSON config file and merges it over the Linear defaults.
    public static func load(from url: URL) throws -> Theme {
        let path = url.path
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ThemeError.fileNotFound(path: path)
        }
        let override = try decode(data, file: path)
        return try apply(override, file: path)
    }

    /// Merges a partial override over the Linear defaults.
    public static func merged(with override: ThemeOverride) throws -> Theme {
        try apply(override, file: nil)
    }

    /// Resolves the active theme: an explicit `--theme` wins, then the default
    /// config file when present, then Linear defaults.
    public static func resolve(explicit: URL?, defaultFile: URL) throws -> Theme {
        if let explicit {
            return try load(from: explicit)
        }
        if FileManager.default.fileExists(atPath: defaultFile.path) {
            return try load(from: defaultFile)
        }
        return .linear
    }

    /// Pretty-printed JSON of a fully-specified Linear theme, used to bootstrap
    /// a user config file ("Create Config" in Settings).
    public static func defaultConfigData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(defaultOverride)
    }

    // MARK: - Decoding

    private static func decode(_ data: Data, file: String) throws -> ThemeOverride {
        do {
            return try JSONDecoder().decode(ThemeOverride.self, from: data)
        } catch let error as DecodingError {
            switch error {
            case .typeMismatch(_, let context):
                let key = context.codingPath.map(\.stringValue).joined(separator: ".")
                throw ThemeError.invalidValue(
                    key: key.isEmpty ? "theme" : key,
                    value: context.debugDescription,
                    path: file
                )
            default:
                throw ThemeError.invalidJSON(path: file)
            }
        } catch {
            throw ThemeError.invalidJSON(path: file)
        }
    }

    // MARK: - Merging

    private static func apply(_ override: ThemeOverride, file: String?) throws -> Theme {
        let palette = try mergedPalette(override.palette, file: file)
        let spacing = try mergedSpacing(override.spacing, file: file)
        let radius = try mergedRadius(override.radius, file: file)
        let fonts = try mergedFonts(override.fonts, file: file)
        return Theme(palette: palette, spacing: spacing, radius: radius, fonts: fonts)
    }

    private static func mergedPalette(_ override: PaletteOverride?, file: String?) throws -> Palette {
        guard let override else { return .linear }
        var palette = Palette.linear
        palette.background = try color(override.background, fallback: palette.background, key: "palette.background", file: file)
        palette.foreground = try color(override.foreground, fallback: palette.foreground, key: "palette.foreground", file: file)
        palette.card = try color(override.card, fallback: palette.card, key: "palette.card", file: file)
        palette.cardForeground = try color(override.cardForeground, fallback: palette.cardForeground, key: "palette.cardForeground", file: file)
        palette.secondary = try color(override.secondary, fallback: palette.secondary, key: "palette.secondary", file: file)
        palette.secondaryForeground = try color(override.secondaryForeground, fallback: palette.secondaryForeground, key: "palette.secondaryForeground", file: file)
        palette.muted = try color(override.muted, fallback: palette.muted, key: "palette.muted", file: file)
        palette.mutedForeground = try color(override.mutedForeground, fallback: palette.mutedForeground, key: "palette.mutedForeground", file: file)
        palette.accent = try color(override.accent, fallback: palette.accent, key: "palette.accent", file: file)
        palette.accentForeground = try color(override.accentForeground, fallback: palette.accentForeground, key: "palette.accentForeground", file: file)
        palette.primary = try color(override.primary, fallback: palette.primary, key: "palette.primary", file: file)
        palette.destructive = try color(override.destructive, fallback: palette.destructive, key: "palette.destructive", file: file)
        palette.border = try color(override.border, fallback: palette.border, key: "palette.border", file: file)
        palette.syntaxKeyword = try color(override.syntaxKeyword, fallback: palette.syntaxKeyword, key: "palette.syntaxKeyword", file: file)
        palette.syntaxString = try color(override.syntaxString, fallback: palette.syntaxString, key: "palette.syntaxString", file: file)
        palette.syntaxComment = try color(override.syntaxComment, fallback: palette.syntaxComment, key: "palette.syntaxComment", file: file)
        palette.syntaxType = try color(override.syntaxType, fallback: palette.syntaxType, key: "palette.syntaxType", file: file)
        palette.syntaxNumber = try color(override.syntaxNumber, fallback: palette.syntaxNumber, key: "palette.syntaxNumber", file: file)
        palette.syntaxPlain = try color(override.syntaxPlain, fallback: palette.syntaxPlain, key: "palette.syntaxPlain", file: file)
        return palette
    }

    private static func mergedSpacing(_ override: SpacingOverride?, file: String?) throws -> Spacing {
        guard let override else { return .linear }
        var spacing = Spacing.linear
        spacing.xs = try number(override.xs, fallback: spacing.xs, key: "spacing.xs", file: file)
        spacing.sm = try number(override.sm, fallback: spacing.sm, key: "spacing.sm", file: file)
        spacing.md = try number(override.md, fallback: spacing.md, key: "spacing.md", file: file)
        spacing.lg = try number(override.lg, fallback: spacing.lg, key: "spacing.lg", file: file)
        spacing.xl = try number(override.xl, fallback: spacing.xl, key: "spacing.xl", file: file)
        spacing.xxl = try number(override.xxl, fallback: spacing.xxl, key: "spacing.xxl", file: file)
        return spacing
    }

    private static func mergedRadius(_ override: RadiusOverride?, file: String?) throws -> Radius {
        guard let override else { return .linear }
        var radius = Radius.linear
        radius.sm = try number(override.sm, fallback: radius.sm, key: "radius.sm", file: file)
        radius.md = try number(override.md, fallback: radius.md, key: "radius.md", file: file)
        radius.lg = try number(override.lg, fallback: radius.lg, key: "radius.lg", file: file)
        return radius
    }

    private static func mergedFonts(_ override: FontOverride?, file: String?) throws -> FontConfig {
        guard let override else { return .linear }
        var fonts = FontConfig.linear
        if let family = override.family {
            fonts.family = family
        }
        fonts.heading1 = try number(override.heading1, fallback: fonts.heading1, key: "fonts.heading1", file: file)
        fonts.heading2 = try number(override.heading2, fallback: fonts.heading2, key: "fonts.heading2", file: file)
        fonts.heading3 = try number(override.heading3, fallback: fonts.heading3, key: "fonts.heading3", file: file)
        fonts.heading4 = try number(override.heading4, fallback: fonts.heading4, key: "fonts.heading4", file: file)
        fonts.heading5 = try number(override.heading5, fallback: fonts.heading5, key: "fonts.heading5", file: file)
        fonts.body = try number(override.body, fallback: fonts.body, key: "fonts.body", file: file)
        fonts.caption = try number(override.caption, fallback: fonts.caption, key: "fonts.caption", file: file)
        fonts.code = try number(override.code, fallback: fonts.code, key: "fonts.code", file: file)
        fonts.inlineCode = try number(override.inlineCode, fallback: fonts.inlineCode, key: "fonts.inlineCode", file: file)
        fonts.label = try number(override.label, fallback: fonts.label, key: "fonts.label", file: file)
        fonts.lineSpacing = try number(override.lineSpacing, fallback: fonts.lineSpacing, key: "fonts.lineSpacing", file: file)
        return fonts
    }

    private static func color(_ hex: String?, fallback: Color, key: String, file: String?) throws -> Color {
        guard let hex else { return fallback }
        guard let value = parseHex(hex) else {
            throw ThemeError.invalidColor(key: key, value: hex, path: file)
        }
        return Color(hex: value)
    }

    private static func number(_ value: CGFloat?, fallback: CGFloat, key: String, file: String?) throws -> CGFloat {
        guard let value else { return fallback }
        guard value.isFinite, value > 0 else {
            throw ThemeError.invalidValue(key: key, value: String(describing: value), path: file)
        }
        return value
    }

    /// Parses `#RRGGBB` (the `#` is optional) into an sRGB hex value.
    private static func parseHex(_ hex: String) -> UInt32? {
        var digits = hex
        if digits.hasPrefix("#") {
            digits.removeFirst()
        }
        guard digits.count == 6, digits.allSatisfy(\.isHexDigit) else { return nil }
        return UInt32(digits, radix: 16)
    }

    // MARK: - Bootstrap

    /// A fully-specified Linear override, encoded by `defaultConfigData`.
    private static let defaultOverride = ThemeOverride(
        palette: PaletteOverride(
            background: "#191A24",
            foreground: "#FFFFFF",
            card: "#1F202D",
            cardForeground: "#F8FAFC",
            secondary: "#272A3A",
            secondaryForeground: "#868798",
            muted: "#1F202D",
            mutedForeground: "#9B9EAB",
            accent: "#31323F",
            accentForeground: "#F8FAFC",
            primary: "#6B77FF",
            destructive: "#7F1D1D",
            border: "#38394C",
            syntaxKeyword: "#6B77FF",
            syntaxString: "#A5B4FC",
            syntaxComment: "#6B7280",
            syntaxType: "#8B93E7",
            syntaxNumber: "#FBBF24",
            syntaxPlain: "#E5E7EB"
        ),
        spacing: SpacingOverride(xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32),
        radius: RadiusOverride(sm: 4, md: 6, lg: 8),
        fonts: FontOverride(
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
    )
}

// MARK: - Config override model

/// A partial theme config as written in `theme.json`; every field is optional
/// and unspecified fields keep the Linear default.
public struct ThemeOverride: Codable, Equatable, Sendable {
    public var palette: PaletteOverride?
    public var spacing: SpacingOverride?
    public var radius: RadiusOverride?
    public var fonts: FontOverride?

    public init(palette: PaletteOverride? = nil, spacing: SpacingOverride? = nil, radius: RadiusOverride? = nil, fonts: FontOverride? = nil) {
        self.palette = palette
        self.spacing = spacing
        self.radius = radius
        self.fonts = fonts
    }
}

public struct PaletteOverride: Codable, Equatable, Sendable {
    public var background: String?
    public var foreground: String?
    public var card: String?
    public var cardForeground: String?
    public var secondary: String?
    public var secondaryForeground: String?
    public var muted: String?
    public var mutedForeground: String?
    public var accent: String?
    public var accentForeground: String?
    public var primary: String?
    public var destructive: String?
    public var border: String?
    public var syntaxKeyword: String?
    public var syntaxString: String?
    public var syntaxComment: String?
    public var syntaxType: String?
    public var syntaxNumber: String?
    public var syntaxPlain: String?

    public init(
        background: String? = nil, foreground: String? = nil, card: String? = nil,
        cardForeground: String? = nil, secondary: String? = nil, secondaryForeground: String? = nil,
        muted: String? = nil, mutedForeground: String? = nil, accent: String? = nil,
        accentForeground: String? = nil, primary: String? = nil, destructive: String? = nil,
        border: String? = nil, syntaxKeyword: String? = nil, syntaxString: String? = nil,
        syntaxComment: String? = nil, syntaxType: String? = nil, syntaxNumber: String? = nil,
        syntaxPlain: String? = nil
    ) {
        self.background = background
        self.foreground = foreground
        self.card = card
        self.cardForeground = cardForeground
        self.secondary = secondary
        self.secondaryForeground = secondaryForeground
        self.muted = muted
        self.mutedForeground = mutedForeground
        self.accent = accent
        self.accentForeground = accentForeground
        self.primary = primary
        self.destructive = destructive
        self.border = border
        self.syntaxKeyword = syntaxKeyword
        self.syntaxString = syntaxString
        self.syntaxComment = syntaxComment
        self.syntaxType = syntaxType
        self.syntaxNumber = syntaxNumber
        self.syntaxPlain = syntaxPlain
    }
}

public struct SpacingOverride: Codable, Equatable, Sendable {
    public var xs: CGFloat?
    public var sm: CGFloat?
    public var md: CGFloat?
    public var lg: CGFloat?
    public var xl: CGFloat?
    public var xxl: CGFloat?

    public init(xs: CGFloat? = nil, sm: CGFloat? = nil, md: CGFloat? = nil, lg: CGFloat? = nil, xl: CGFloat? = nil, xxl: CGFloat? = nil) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
    }
}

public struct RadiusOverride: Codable, Equatable, Sendable {
    public var sm: CGFloat?
    public var md: CGFloat?
    public var lg: CGFloat?

    public init(sm: CGFloat? = nil, md: CGFloat? = nil, lg: CGFloat? = nil) {
        self.sm = sm
        self.md = md
        self.lg = lg
    }
}

public struct FontOverride: Codable, Equatable, Sendable {
    public var family: String?
    public var heading1: CGFloat?
    public var heading2: CGFloat?
    public var heading3: CGFloat?
    public var heading4: CGFloat?
    public var heading5: CGFloat?
    public var body: CGFloat?
    public var caption: CGFloat?
    public var code: CGFloat?
    public var inlineCode: CGFloat?
    public var label: CGFloat?
    public var lineSpacing: CGFloat?

    public init(
        family: String? = nil, heading1: CGFloat? = nil, heading2: CGFloat? = nil,
        heading3: CGFloat? = nil, heading4: CGFloat? = nil, heading5: CGFloat? = nil,
        body: CGFloat? = nil, caption: CGFloat? = nil, code: CGFloat? = nil,
        inlineCode: CGFloat? = nil, label: CGFloat? = nil, lineSpacing: CGFloat? = nil
    ) {
        self.family = family
        self.heading1 = heading1
        self.heading2 = heading2
        self.heading3 = heading3
        self.heading4 = heading4
        self.heading5 = heading5
        self.body = body
        self.caption = caption
        self.code = code
        self.inlineCode = inlineCode
        self.label = label
        self.lineSpacing = lineSpacing
    }
}

// MARK: - Errors

public enum ThemeError: Error, Equatable {
    case fileNotFound(path: String)
    case invalidJSON(path: String)
    case invalidColor(key: String, value: String, path: String?)
    case invalidValue(key: String, value: String, path: String?)
}

extension ThemeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "mdr: cannot read theme '\(path)'"
        case .invalidJSON(let path):
            return "mdr: invalid theme JSON in '\(path)'"
        case .invalidColor(let key, let value, let path):
            return "mdr: invalid color '\(value)' for \(key)\(pathSuffix(path))"
        case .invalidValue(let key, let value, let path):
            return "mdr: invalid value for \(key)\(pathSuffix(path)): \(value)"
        }
    }

    private func pathSuffix(_ path: String?) -> String {
        path.map { " in '\($0)'" } ?? ""
    }
}