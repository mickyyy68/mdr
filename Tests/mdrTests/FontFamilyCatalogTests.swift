import Testing
@testable import MDReaderCore

struct FontFamilyCatalogTests {
    @Test func systemFontOptionComesFirst() {
        let options = FontFamilyCatalog.options(loadable: [])
        #expect(options.first?.familyName == nil)
        #expect(options.first?.displayName == "System (SF Pro)")
    }

    @Test func interIsAlwaysOfferedEvenWhenNotInstalled() {
        let options = FontFamilyCatalog.options(loadable: [])
        #expect(options.contains { $0.familyName == "Inter" })
    }

    @Test func unloadableFamiliesAreDropped() {
        let options = FontFamilyCatalog.options(loadable: [])
        #expect(!options.contains { $0.familyName == "Helvetica Neue" })
        #expect(!options.contains { $0.familyName == "Menlo" })
    }

    @Test func loadableFamiliesAreKeptCaseInsensitively() {
        let options = FontFamilyCatalog.options(loadable: ["helvetica neue", "MENLO"])
        #expect(options.contains { $0.familyName == "Helvetica Neue" })
        #expect(options.contains { $0.familyName == "Menlo" })
    }

    @Test func displayNamesAreUnique() {
        let options = FontFamilyCatalog.options(loadable: ["georgia", "palatino"])
        #expect(Set(options.map(\.displayName)).count == options.count)
    }
}
