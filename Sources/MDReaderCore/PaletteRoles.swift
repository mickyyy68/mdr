import SwiftUI

/// A token role the advanced theme editor exposes; the label is what the
/// filter matches. Color roles carry a writable palette key path; the other
/// kinds edit font, spacing, and radius tokens directly.
public struct PaletteRole: Identifiable {
    public enum Kind {
        case color(WritableKeyPath<Palette, Color>)
        case font(WritableKeyPath<FontConfig, CGFloat>)
        case spacing(WritableKeyPath<Spacing, CGFloat>)
        case radius(WritableKeyPath<Radius, CGFloat>)
        case family
    }

    public let id: String
    public let label: String
    public let kind: Kind

    public init(_ id: String, _ label: String, _ kind: Kind) {
        self.id = id
        self.label = label
        self.kind = kind
    }

    /// The palette color this role edits, when it is a color role.
    public var keyPath: WritableKeyPath<Palette, Color>? {
        if case .color(let keyPath) = kind { return keyPath }
        return nil
    }
}

/// The labeled groups the advanced editor lists roles in.
public enum PaletteRoleGroup: String, CaseIterable, Identifiable {
    case foundation
    case brand
    case syntax
    case fonts
    case spacing
    case radius

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .foundation: "Foundation"
        case .brand: "Brand & content"
        case .syntax: "Syntax"
        case .fonts: "Fonts"
        case .spacing: "Spacing"
        case .radius: "Radius"
        }
    }

    public var roles: [PaletteRole] {
        switch self {
        case .foundation:
            [
                PaletteRole("background", "Background", .color(\.background)),
                PaletteRole("surface", "Surface", .color(\.card)),
                PaletteRole("raised-surface", "Raised surface", .color(\.secondary)),
                PaletteRole("overlay", "Overlay", .color(\.muted)),
                PaletteRole("text", "Text", .color(\.foreground)),
                PaletteRole("card-text", "Card text", .color(\.cardForeground)),
                PaletteRole("muted-text", "Muted text", .color(\.mutedForeground)),
                PaletteRole("border", "Border", .color(\.border)),
            ]
        case .brand:
            [
                PaletteRole("primary", "Primary", .color(\.primary)),
                PaletteRole("accent", "Accent", .color(\.accent)),
                PaletteRole("accent-foreground", "Accent foreground", .color(\.accentForeground)),
                PaletteRole("secondary-foreground", "Secondary foreground", .color(\.secondaryForeground)),
                PaletteRole("destructive", "Destructive", .color(\.destructive)),
            ]
        case .syntax:
            [
                PaletteRole("syntax-keyword", "Keyword", .color(\.syntaxKeyword)),
                PaletteRole("syntax-string", "String", .color(\.syntaxString)),
                PaletteRole("syntax-comment", "Comment", .color(\.syntaxComment)),
                PaletteRole("syntax-type", "Type", .color(\.syntaxType)),
                PaletteRole("syntax-number", "Number", .color(\.syntaxNumber)),
                PaletteRole("syntax-plain", "Plain", .color(\.syntaxPlain)),
            ]
        case .fonts:
            [
                PaletteRole("family", "Font family", .family),
                PaletteRole("heading1", "Heading 1", .font(\.heading1)),
                PaletteRole("heading2", "Heading 2", .font(\.heading2)),
                PaletteRole("heading3", "Heading 3", .font(\.heading3)),
                PaletteRole("heading4", "Heading 4", .font(\.heading4)),
                PaletteRole("heading5", "Heading 5", .font(\.heading5)),
                PaletteRole("body", "Body", .font(\.body)),
                PaletteRole("caption", "Caption", .font(\.caption)),
                PaletteRole("code", "Code", .font(\.code)),
                PaletteRole("inline-code", "Inline code", .font(\.inlineCode)),
                PaletteRole("label", "Label", .font(\.label)),
                PaletteRole("line-spacing", "Line spacing", .font(\.lineSpacing)),
            ]
        case .spacing:
            [
                PaletteRole("spacing-xs", "XS", .spacing(\.xs)),
                PaletteRole("spacing-sm", "SM", .spacing(\.sm)),
                PaletteRole("spacing-md", "MD", .spacing(\.md)),
                PaletteRole("spacing-lg", "LG", .spacing(\.lg)),
                PaletteRole("spacing-xl", "XL", .spacing(\.xl)),
                PaletteRole("spacing-xxl", "XXL", .spacing(\.xxl)),
            ]
        case .radius:
            [
                PaletteRole("radius-sm", "SM", .radius(\.sm)),
                PaletteRole("radius-md", "MD", .radius(\.md)),
                PaletteRole("radius-lg", "LG", .radius(\.lg)),
            ]
        }
    }
}
