import AppKit
import Combine
import Foundation
import MDReaderCore

/// The app-wide, mutable theme and appearance mode. Owned by `AppDelegate`,
/// observed by every `ReaderView`, so a saved theme re-renders all open
/// windows immediately.
@MainActor
final class ThemeStore: ObservableObject {
    @Published var theme: Theme {
        didSet { onThemeChange?(theme) }
    }

    @Published var appearanceMode: ThemeAppearanceMode {
        didSet { onAppearanceModeChange?(appearanceMode) }
    }

    /// The config file that produced `theme` (`nil` when using defaults).
    /// Updated after the first Save so subsequent Saves/Reset target the file.
    var sourceURL: URL?

    /// Called on the main actor whenever the theme changes.
    var onThemeChange: (@MainActor (Theme) -> Void)?

    /// Called on the main actor whenever the appearance mode changes.
    var onAppearanceModeChange: (@MainActor (ThemeAppearanceMode) -> Void)?

    init(theme: Theme, sourceURL: URL?, appearanceMode: ThemeAppearanceMode = .system) {
        self.theme = theme
        self.sourceURL = sourceURL
        self.appearanceMode = appearanceMode
    }

    /// The appearance in effect: the chosen mode, or the system appearance.
    var effectiveAppearance: ThemeAppearance {
        appearanceMode.appearance(systemAppearance: Self.systemAppearance())
    }

    /// The theme with its palette pinned to the effective appearance, so
    /// renderers can use it as a single-palette theme.
    var resolvedTheme: Theme {
        theme.resolved(for: effectiveAppearance)
    }

    private static func systemAppearance() -> ThemeAppearance {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
    }
}