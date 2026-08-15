import Foundation
import Testing
@testable import MDReaderCore

struct ThemePersistenceTests {
    @Test func saveCreatesParentDirectories() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdr-persistence-\(UUID().uuidString)")
            .appendingPathComponent("nested")
            .appendingPathComponent("theme.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent().deletingLastPathComponent()) }

        try ThemePersistence.save(.linear, to: url)
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(try Theme.load(from: url) == .linear)
    }

    @Test func saveWritesRoundTrippableJSON() throws {
        let url = try temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let theme = Theme.preset(.ember)
        try ThemePersistence.save(theme, to: url)
        #expect(try Theme.load(from: url) == theme)
    }

    @Test func deleteRemovesFile() throws {
        let url = try temporaryFileURL()
        try ThemePersistence.save(.linear, to: url)

        try ThemePersistence.delete(at: url)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test func deleteMissingFileIsNoop() throws {
        let url = try temporaryFileURL()
        #expect(throws: Never.self) {
            try ThemePersistence.delete(at: url)
        }
    }

    @Test func saveToInvalidParentThrowsWriteFailed() throws {
        let blocker = try temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: blocker) }

        let url = blocker.appendingPathComponent("theme.json")
        do {
            try ThemePersistence.save(.linear, to: url)
            Issue.record("expected writeFailed")
        } catch let error as ThemeError {
            guard case .writeFailed(let path, _) = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
            #expect(path == url.path)
        }
    }

    private func temporaryFileURL() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdr-persistence-\(UUID().uuidString).json")
        try Data().write(to: url)
        return url
    }
}