import AppKit
import MDReaderCore
import SwiftUI

/// The settings page in T3 Code's shape: a settings sidebar, an Appearance
/// section with Color scheme tiles and a theme library grid, plus the floating
/// theme editor and the paste-JSON import dialog. The whole page wears the
/// active theme — and the editor's draft while editing.
@MainActor
struct SettingsView: View {
    private let configURL: URL
    private let onBack: @MainActor () -> Void
    @ObservedObject private var store: ThemeStore

    @State private var editorSession: ThemeEditorSession?
    @State private var draftValue: Theme = .linear
    @State private var isShowingImport = false
    @State private var isConfirmingReset = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var hoveredMode: ThemeAppearanceMode?
    @State private var isBackHovering = false
    @State private var statusTask: Task<Void, Never>?

    init(configURL: URL, store: ThemeStore, onBack: @escaping @MainActor () -> Void) {
        self.configURL = configURL
        self.onBack = onBack
        self._store = ObservedObject(wrappedValue: store)
    }

    /// The chrome the page renders in: the editor's draft while editing,
    /// otherwise the applied theme, resolved for the effective appearance.
    private var chrome: Theme {
        (editorSession != nil ? draftValue : store.theme)
            .resolved(for: store.effectiveAppearance)
    }

    private var editorDraftBinding: Binding<Theme> {
        Binding(
            get: { draftValue },
            set: { draftValue = $0 }
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                HStack(spacing: 0) {
                    sidebar
                    Rectangle()
                        .fill(chrome.palette.border.opacity(0.7))
                        .frame(width: 1)
                    content
                }
                .background(chrome.palette.background)
                if let session = editorSession {
                    ThemeEditorPanel(
                        draft: editorDraftBinding,
                        chrome: chrome,
                        session: session,
                        initialAppearance: store.effectiveAppearance,
                        dragBounds: CGSize(width: geo.size.width, height: geo.size.height),
                        bodyMaxHeight: editorBodyMaxHeight(in: geo.size.height),
                        onSave: saveEditorDraft,
                        onClose: closeEditor
                    )
                    .id(session.id)
                    .padding(16)
                    .zIndex(10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .confirmationDialog("Reset the theme?", isPresented: $isConfirmingReset) {
                Button("Reset", role: .destructive) {
                    resetTheme()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("mdr goes back to the Linear defaults. You can bring your theme back by importing its JSON file.")
            }
            .sheet(isPresented: $isShowingImport) {
                ThemeImportView(store: store, configURL: configURL, isPresented: $isShowingImport) { message in
                    showStatus(message)
                }
            }
            .onExitCommand {
                if editorSession != nil { closeEditor() }
            }
        }
        .onDisappear {
            statusTask?.cancel()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            navItem
            Spacer()
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .medium))
                    Text("Back")
                        .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                }
                .foregroundColor(chrome.palette.mutedForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(
                    RoundedRectangle(cornerRadius: chrome.radius.md)
                        .fill(isBackHovering ? chrome.palette.accent.opacity(0.1) : .clear)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isBackHovering = $0 }
            .help("Back to the document")
            .padding(8)
        }
        .frame(width: 240)
        .background(chrome.palette.secondary.opacity(0.3))
    }

    private var navItem: some View {
        HStack(spacing: 8) {
            Image(systemName: "paintpalette")
                .font(.system(size: 13, weight: .medium))
            Text("Appearance")
                .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
        }
        .foregroundColor(chrome.palette.foreground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(RoundedRectangle(cornerRadius: chrome.radius.md).fill(chrome.palette.accent.opacity(0.6)))
        .padding(8)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                        .font(chrome.fonts.font(20, weight: .semibold))
                        .tracking(-0.5)
                        .foregroundColor(chrome.palette.foreground)

                    Text("Choose how \(CLI.name) looks. Use a built-in theme or make your own.")
                        .font(chrome.fonts.font(13))
                        .foregroundColor(chrome.palette.mutedForeground)
                        .padding(.horizontal, 12)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Color scheme")
                        .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                        .tracking(-0.1)
                        .foregroundColor(chrome.palette.foreground)
                        .padding(.horizontal, 12)

                    modeTiles

                    themesHeader

                    VStack(alignment: .leading, spacing: 4) {
                        if let statusMessage {
                            Text(statusMessage)
                                .font(chrome.fonts.font(chrome.fonts.caption))
                                .foregroundColor(chrome.palette.mutedForeground)
                                .transition(.opacity)
                        }
                        if let errorMessage {
                            Text(errorMessage)
                                .font(chrome.fonts.font(chrome.fonts.caption))
                                .foregroundColor(chrome.palette.destructive)
                                .transition(.opacity)
                        }
                    }
                    .frame(minHeight: 18, alignment: .topLeading)

                    themeGrid
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 48)
            .frame(maxWidth: 896, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var themesHeader: some View {
        HStack(spacing: 8) {
            Text("Themes")
                .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                .tracking(-0.1)
                .foregroundColor(chrome.palette.foreground)
            Spacer()
            OutlinedButton(chrome: chrome, systemImage: "plus", title: "Create theme", action: createTheme)
            OutlinedButton(chrome: chrome, systemImage: "square.and.arrow.down", title: "Import theme") {
                isShowingImport = true
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - Color scheme tiles

    private var modeTiles: some View {
        HStack(spacing: 12) {
            ForEach(ThemeAppearanceMode.allCases, id: \.self) { mode in
                modeTile(mode)
            }
        }
        .padding(.horizontal, 12)
    }

    private func modeTile(_ mode: ThemeAppearanceMode) -> some View {
        let isActive = store.appearanceMode == mode
        let isHovering = hoveredMode == mode
        return Button {
            store.appearanceMode = mode
        } label: {
            VStack(spacing: 6) {
                tileWireframe(mode)
                Text(modeLabel(mode))
                    .font(chrome.fonts.font(12, weight: .medium))
                    .foregroundColor(isActive ? chrome.palette.foreground : chrome.palette.mutedForeground)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isActive
                            ? chrome.palette.accent.opacity(0.3)
                            : (isHovering ? chrome.palette.accent.opacity(0.1) : chrome.palette.card.opacity(0.6))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isActive ? chrome.palette.primary.opacity(0.9) : chrome.palette.border,
                        lineWidth: 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.12), value: isActive)
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .onHover { hovering in
            if hovering {
                hoveredMode = mode
            } else if hoveredMode == mode {
                hoveredMode = nil
            }
        }
        .help(mode == .system ? "Follow the system appearance" : "Use \(mode.rawValue) mode")
        .accessibilityLabel(mode == .system ? "Follow the system appearance" : "Use \(mode.rawValue) mode")
    }

    private func modeLabel(_ mode: ThemeAppearanceMode) -> String {
        switch mode {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    private func tileWireframe(_ mode: ThemeAppearanceMode) -> some View {
        Group {
            switch mode {
            case .system:
                ZStack {
                    ThemeWireframe(
                        colors: ThemePreviewRoles(theme: chromeSource, appearance: .light),
                        clip: .left
                    )
                    ThemeWireframe(
                        colors: ThemePreviewRoles(theme: chromeSource, appearance: .dark),
                        clip: .right
                    )
                }
            case .light:
                ThemeWireframe(colors: ThemePreviewRoles(theme: chromeSource, appearance: .light))
            case .dark:
                ThemeWireframe(colors: ThemePreviewRoles(theme: chromeSource, appearance: .dark))
            }
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
    }

    private var chromeSource: Theme {
        editorSession != nil ? draftValue : store.theme
    }

    // MARK: - Theme grid

    private var themeGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 272), spacing: 8)],
            spacing: 8
        ) {
            ForEach(ThemePreset.allCases, id: \.self) { preset in
                presetCard(preset)
            }
            customCard
        }
        .padding(.horizontal, 12)
    }

    private func presetCard(_ preset: ThemePreset) -> some View {
        ThemeLibraryCard(
            chrome: chrome,
            label: preset.label,
            theme: preset.theme,
            isActive: store.theme == preset.theme,
            isActiveMode: { appearance in
                store.theme == preset.theme && isCurrentAppearance(appearance)
            },
            onUse: { applyTheme(preset.theme, message: "Applied \(preset.label)") },
            onUseMode: { appearance in
                applyTheme(preset.theme, message: "Applied \(preset.label) for \(appearance.rawValue) mode")
                store.appearanceMode = appearance == .light ? .light : .dark
            }
        )
    }

    private var customCard: some View {
        let isCustomActive = !ThemePreset.allCases.contains { store.theme == $0.theme }
        return ThemeLibraryCard(
            chrome: chrome,
            label: store.theme.label ?? "Custom theme",
            theme: store.theme,
            isActive: isCustomActive,
            isActiveMode: { appearance in
                isCustomActive && isCurrentAppearance(appearance)
            },
            onUse: {},
            onUseMode: { appearance in
                store.appearanceMode = appearance == .light ? .light : .dark
            },
            onEdit: {
                openEditor(seed: store.theme, isEditing: true)
            },
            onExport: exportTheme,
            onRemove: { isConfirmingReset = true }
        )
    }

    private func isCurrentAppearance(_ appearance: ThemeAppearance) -> Bool {
        switch store.appearanceMode {
        case .light: appearance == .light
        case .dark: appearance == .dark
        case .system: appearance == store.effectiveAppearance
        }
    }

    // MARK: - Actions

    private func applyTheme(_ theme: Theme, message: String) {
        do {
            let target = store.sourceURL ?? configURL
            try ThemePersistence.save(theme, to: target)
            store.sourceURL = target
            store.theme = theme
            showStatus(message)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func createTheme() {
        openEditor(seed: store.theme, isEditing: false)
    }

    private func openEditor(seed: Theme, isEditing: Bool) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            editorSession = ThemeEditorSession(
                id: UUID(),
                isEditing: isEditing,
                initialName: isEditing ? (seed.label ?? "") : ""
            )
            draftValue = seed
        }
    }

    private func closeEditor() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            editorSession = nil
        }
    }

    private func saveEditorDraft(_ theme: Theme) throws {
        let target = store.sourceURL ?? configURL
        try ThemePersistence.save(theme, to: target)
        store.sourceURL = target
        store.theme = theme
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            editorSession = nil
        }
        showStatus("\(theme.label ?? "Theme") saved")
    }

    private func resetTheme() {
        if let source = store.sourceURL, source == CLI.defaultThemePath {
            do {
                try ThemePersistence.delete(at: source)
            } catch {
                showError(error.localizedDescription)
                return
            }
        }
        store.sourceURL = nil
        store.theme = .linear
        showStatus("Reset to defaults")
    }

    private func exportTheme() {
        do {
            let data = try ThemePersistence.data(for: store.theme)
            guard let json = String(data: data, encoding: .utf8) else { return }
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(json, forType: .string)
            showStatus("Theme JSON copied to clipboard")
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Feedback

    /// Shows a transient status; success feedback dismisses itself like a toast.
    private func showStatus(_ message: String) {
        statusTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            statusMessage = message
            errorMessage = nil
        }
        statusTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                statusMessage = nil
            }
        }
    }

    /// Shows a persistent error; it clears on the next action.
    private func showError(_ message: String) {
        statusTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            errorMessage = message
            statusMessage = nil
        }
    }

    /// Keeps the editor's body within the window for any window size.
    private func editorBodyMaxHeight(in windowHeight: CGFloat) -> CGFloat {
        max(220, min(640, windowHeight - 190))
    }
}