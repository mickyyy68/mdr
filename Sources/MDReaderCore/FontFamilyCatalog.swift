import Foundation

/// A font family choice the theme editor offers; `familyName` is `nil` for
/// the system (SF Pro) font, which `FontConfig.font` resolves directly.
public struct FontFamilyOption: Identifiable, Sendable, Equatable {
    public let displayName: String
    public let familyName: String?

    public init(displayName: String, familyName: String?) {
        self.displayName = displayName
        self.familyName = familyName
    }

    public var id: String { displayName }
}

/// The curated font families the editor lists, filtered to what the renderer
/// can actually load. Pure data; the executable supplies the loadable set from
/// AppKit, and the catalog keeps the `nil` system-font entry and `"Inter"`
/// (special-cased by `FontConfig.font`) even when the system lacks them.
public enum FontFamilyCatalog {
    /// The offered options in display order, filtered to `loadable` families.
    /// Matching is case-insensitive; `loadable` entries may be any case.
    public static func options(loadable: Set<String>) -> [FontFamilyOption] {
        let loadable = Set(loadable.map { $0.lowercased() })
        return candidates
            .filter { option in
                guard let family = option.family else { return true }
                return family == "Inter" || loadable.contains(family.lowercased())
            }
            .map { FontFamilyOption(displayName: $0.display, familyName: $0.family) }
    }

    private static let candidates: [(display: String, family: String?)] = [
        ("System (SF Pro)", nil),
        ("Inter", "Inter"),
        ("Helvetica Neue", "Helvetica Neue"),
        ("Avenir Next", "Avenir Next"),
        ("Gill Sans", "Gill Sans"),
        ("Optima", "Optima"),
        ("Futura", "Futura"),
        ("Georgia", "Georgia"),
        ("Palatino", "Palatino"),
        ("American Typewriter", "American Typewriter"),
        ("Menlo", "Menlo"),
        ("Monaco", "Monaco"),
        ("Courier New", "Courier New"),
    ]
}
