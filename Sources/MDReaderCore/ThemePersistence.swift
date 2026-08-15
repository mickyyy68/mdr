import Foundation

/// File I/O for the theme config, kept in the core so save/reset/export
/// serialization is unit-testable. Every failure surfaces as `ThemeError.writeFailed`.
public enum ThemePersistence {
    /// The pretty `ThemeOverride` JSON for a theme (used by export).
    public static func data(for theme: Theme) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(ThemeOverride(theme: theme))
    }

    /// Writes a theme to `url` as pretty `ThemeOverride` JSON, creating parent
    /// directories as needed.
    public static func save(_ theme: Theme, to url: URL) throws {
        let jsonData: Data
        do {
            jsonData = try data(for: theme)
        } catch {
            throw ThemeError.writeFailed(path: url.path, underlying: error.localizedDescription)
        }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try jsonData.write(to: url, options: .atomic)
        } catch {
            throw ThemeError.writeFailed(path: url.path, underlying: error.localizedDescription)
        }
    }

    /// Removes the theme config file at `url`. A missing file is a no-op.
    public static func delete(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw ThemeError.writeFailed(path: url.path, underlying: error.localizedDescription)
        }
    }
}