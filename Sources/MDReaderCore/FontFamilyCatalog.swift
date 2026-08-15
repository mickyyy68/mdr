import AppKit
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
/// can actually load. The executable and the renderer share one loadability
/// probe, so they can never disagree on which families are offered or used.
public enum FontFamilyCatalog {
    /// Families that resolve via `NSFont(name:)`, keyed by lowercased display
    /// and PostScript name, probed once per process. `FontConfig.font` and
    /// `options(loadable:)` both consult this; `NSFont` lookup is
    /// case-insensitive and also accepts PostScript names, so both spellings
    /// are kept. A family the font manager does not enumerate is treated as
    /// unloadable.
    public static let loadableFamilies: Set<String> = {
        let loadable = NSFontManager.shared.availableFontFamilies.filter { NSFont(name: $0, size: 12) != nil }
        var names = Set(loadable.map { $0.lowercased() })
        for family in loadable {
            if let postScript = NSFont(name: family, size: 12)?.fontName {
                names.insert(postScript.lowercased())
            }
        }
        return names
    }()

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
