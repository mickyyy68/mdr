import Foundation
import Testing
@testable import MDReaderCore

struct DocumentLoaderTests {
    @Test func loadsUTF8File() throws {
        let url = try temporaryFile(content: "hello world".data(using: .utf8)!)
        defer { try? FileManager.default.removeItem(at: url) }

        let loaded = try DocumentLoader.load(url: url)
        #expect(loaded.content == "hello world")
        #expect(loaded.url == url)
    }

    @Test func loadsUTF16File() throws {
        let url = try temporaryFile(content: "héllo".data(using: .utf16)!)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(try DocumentLoader.load(url: url).content == "héllo")
    }

    @Test func loadsEmptyFile() throws {
        let url = try temporaryFile(content: Data())
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(try DocumentLoader.load(url: url).content.isEmpty)
    }

    @Test func missingFileThrows() {
        let url = URL(fileURLWithPath: "/nonexistent/does-not-exist.md")
        #expect(throws: DocumentLoader.LoadError.self) {
            try DocumentLoader.load(url: url)
        }
    }

    private func temporaryFile(content: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdr-test-\(UUID().uuidString).md")
        try content.write(to: url)
        return url
    }
}