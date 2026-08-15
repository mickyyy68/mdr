import Foundation

/// Loads markdown source from disk, tolerating common encodings.
public enum DocumentLoader {
    public struct LoadedDocument: Equatable {
        public let url: URL
        public let content: String

        public init(url: URL, content: String) {
            self.url = url
            self.content = content
        }
    }

    public enum LoadError: LocalizedError {
        case unreadable(URL)

        public var errorDescription: String? {
            switch self {
            case .unreadable(let url):
                return "mdreader: cannot read '\(url.path)'"
            }
        }
    }

    public static func load(url: URL) throws -> LoadedDocument {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LoadError.unreadable(url)
        }

        for encoding in [String.Encoding.utf8, .utf16, .isoLatin1] {
            if let content = String(data: data, encoding: encoding) {
                return LoadedDocument(url: url, content: content)
            }
        }
        throw LoadError.unreadable(url)
    }
}