import AppKit
import MDReaderCore
import SwiftUI
import UniformTypeIdentifiers

/// Paste-JSON / file theme import, T3-Code style: a drop zone for theme files,
/// a Choose files picker, and a Theme JSON editor. Validates against the core
/// `Theme.merged(withData:)` path, shows inline errors, and applies on success.
@MainActor
struct ThemeImportView: View {
    @ObservedObject var store: ThemeStore
    let configURL: URL
    @Binding var isPresented: Bool

    @State private var json = ""
    @State private var fileName: String?
    @State private var errorMessage: String?
    @State private var isDropTarget = false

    /// Theme files are a few KB; anything larger is not a theme file.
    private static let maxThemeFileBytes = 256 * 1024

    private var chrome: Theme { store.resolvedTheme }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add a theme")
                .font(chrome.fonts.font(18, weight: .semibold))
                .tracking(-0.3)
                .foregroundColor(chrome.palette.foreground)

            divider

            dropZone

            VStack(alignment: .leading, spacing: 8) {
                Text("Theme JSON")
                    .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                    .foregroundColor(chrome.palette.foreground)
                TextEditor(text: $json)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(chrome.palette.foreground)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 288)
                    .background(chrome.palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(chrome.palette.border.opacity(0.8), lineWidth: 1)
                    )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(chrome.fonts.font(chrome.fonts.caption))
                    .foregroundColor(chrome.palette.destructive)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                .foregroundColor(chrome.palette.foreground)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 6).fill(.clear))
                Button(action: addTheme) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add theme")
                            .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                    }
                    .foregroundColor(chrome.palette.accentForeground)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(RoundedRectangle(cornerRadius: 6).fill(chrome.palette.primary))
                }
                .buttonStyle(.plain)
                .disabled(json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }
        }
        .padding(24)
        .frame(width: 560)
        .background(chrome.palette.background)
        .onAppear {
            json = ""
            fileName = nil
            errorMessage = nil
        }
    }

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(chrome.palette.border.opacity(0.8)).frame(height: 1)
            Text("or import a file")
                .font(chrome.fonts.font(11, weight: .medium))
                .tracking(0.6)
                .foregroundColor(chrome.palette.mutedForeground)
            Rectangle().fill(chrome.palette.border.opacity(0.8)).frame(height: 1)
        }
    }

    private var dropZone: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Theme file")
                    .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                    .foregroundColor(chrome.palette.foreground)
                Text(fileName ?? "Drop T3 Code or VS Code .json files")
                    .font(chrome.fonts.font(chrome.fonts.caption))
                    .foregroundColor(chrome.palette.mutedForeground)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button("Choose files", action: chooseFiles)
                .buttonStyle(.plain)
                .font(chrome.fonts.font(chrome.fonts.caption, weight: .medium))
                .foregroundColor(chrome.palette.foreground)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(.clear))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(chrome.palette.border.opacity(0.7), lineWidth: 1))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(chrome.palette.secondary.opacity(0.2)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropTarget ? chrome.palette.primary.opacity(0.9) : chrome.palette.border.opacity(0.8),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                )
        )
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTarget) { providers in
            readDroppedFiles(providers)
            return true
        }
    }

    // MARK: - Actions

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = true
        panel.message = "Choose a theme JSON file"
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            if !readFile(url) { return }
        }
    }

    private func readDroppedFiles(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in
                    self.readFile(url)
                }
            }
        }
    }

    /// Returns `false` when reading failed (the error is shown inline).
    @discardableResult
    private func readFile(_ url: URL) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = attributes[.size] as? Int ?? 0
            guard size <= Self.maxThemeFileBytes else {
                errorMessage = "That file is too large to be a theme (\(size) bytes)."
                return false
            }
            let text = try String(contentsOf: url, encoding: .utf8)
            json = text
            fileName = url.lastPathComponent
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Could not read that file. Paste the JSON below instead."
            return false
        }
    }

    private func addTheme() {
        let data = Data(json.utf8)
        do {
            let theme = try Theme.merged(withData: data, label: fileName ?? "pasted JSON")
            let target = store.sourceURL ?? configURL
            try ThemePersistence.save(theme, to: target)
            store.sourceURL = target
            store.theme = theme
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}