import MDReaderCore
import SwiftUI

/// The reader window's SwiftUI root: the document content with a floating
/// settings button, or the settings view with a back button.
@MainActor
struct ReaderView: View {
    private let document: DocumentLoader.LoadedDocument
    @ObservedObject private var store: ThemeStore
    @ObservedObject private var model: ReaderViewModel

    init(document: DocumentLoader.LoadedDocument, store: ThemeStore, model: ReaderViewModel) {
        self.document = document
        self._store = ObservedObject(wrappedValue: store)
        self._model = ObservedObject(wrappedValue: model)
    }

    var body: some View {
        Group {
            if model.isShowingSettings {
                SettingsView(configURL: CLI.defaultThemePath, store: store) {
                    model.isShowingSettings = false
                }
            } else {
                MarkdownReaderView(document: document, theme: store.resolvedTheme)
                    .overlay(alignment: .topLeading) {
                        settingsButton
                    }
            }
        }
    }

    private var settingsButton: some View {
        Button {
            model.isShowingSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(store.resolvedTheme.fonts.font(store.resolvedTheme.fonts.body))
                .foregroundColor(store.resolvedTheme.palette.mutedForeground)
                .frame(width: 28, height: 28)
                .background(Circle().fill(store.resolvedTheme.palette.secondary))
        }
        .buttonStyle(.plain)
        .help("Settings")
        .accessibilityLabel("Settings")
        .padding(store.resolvedTheme.spacing.lg)
    }
}