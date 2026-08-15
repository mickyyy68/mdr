import MDReaderCore
import SwiftUI

/// The reader window's SwiftUI root: the document content with a floating
/// settings button, or the settings view with a back button.
@MainActor
struct ReaderView: View {
    private let document: DocumentLoader.LoadedDocument
    private let theme: Theme
    @ObservedObject private var model: ReaderViewModel

    init(document: DocumentLoader.LoadedDocument, theme: Theme, model: ReaderViewModel) {
        self.document = document
        self.theme = theme
        self._model = ObservedObject(wrappedValue: model)
    }

    var body: some View {
        Group {
            if model.isShowingSettings {
                SettingsView(configURL: CLI.defaultThemePath) {
                    model.isShowingSettings = false
                }
            } else {
                MarkdownReaderView(document: document, theme: theme)
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
                .font(theme.fonts.font(theme.fonts.body))
                .foregroundColor(theme.palette.mutedForeground)
                .frame(width: 28, height: 28)
                .background(Circle().fill(theme.palette.secondary))
        }
        .buttonStyle(.plain)
        .help("Settings")
        .accessibilityLabel("Settings")
        .padding(theme.spacing.lg)
    }
}