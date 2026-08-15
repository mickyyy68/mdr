import AppKit
import MDReaderCore
import SwiftUI

/// The floating theme editor, T3-Code style: a draggable, minimizable panel
/// that paints its draft over the settings page while open. Guided mode edits
/// two colors and derives the rest; advanced mode exposes every role in
/// labeled groups, filterable by name.
struct ThemeEditorPanel: View {
    @Binding var draft: Theme
    let chrome: Theme
    let session: ThemeEditorSession
    let initialAppearance: ThemeAppearance
    let onSave: (Theme) throws -> Void
    let onClose: () -> Void

    @State private var name: String
    @State private var activeAppearance: ThemeAppearance
    @State private var isAdvanced = false
    @State private var roleQuery = ""
    @State private var selectedRole: PaletteRole?
    @State private var simpleDirty: Set<ThemeAppearance> = []
    @State private var errorMessage: String?
    @State private var isMinimized = false

    init(
        draft: Binding<Theme>,
        chrome: Theme,
        session: ThemeEditorSession,
        initialAppearance: ThemeAppearance,
        onSave: @escaping (Theme) throws -> Void,
        onClose: @escaping () -> Void
    ) {
        self._draft = draft
        self.chrome = chrome
        self.session = session
        self.initialAppearance = initialAppearance
        self.onSave = onSave
        self.onClose = onClose
        _name = State(initialValue: session.initialName)
        _activeAppearance = State(initialValue: initialAppearance)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if !isMinimized {
                bodyScroll
                footer
            }
        }
        .frame(width: 416)
        .background(chrome.palette.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(chrome.palette.border.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, y: 8)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 1) {
                Text(session.isEditing ? "Edit theme" : "Create theme")
                    .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                    .foregroundColor(chrome.palette.foreground)
                Text(subtitle)
                    .font(chrome.fonts.font(chrome.fonts.caption))
                    .foregroundColor(chrome.palette.mutedForeground)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: inspect) {
                HStack(spacing: 4) {
                    Image(systemName: "eyedropper")
                        .font(.system(size: 11, weight: .medium))
                    Text("Inspect")
                        .font(chrome.fonts.font(chrome.fonts.caption, weight: .medium))
                }
                .foregroundColor(chrome.palette.foreground)
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(RoundedRectangle(cornerRadius: 6).fill(chrome.palette.accent.opacity(0.6)))
            }
            .buttonStyle(.plain)
            .help("Pick a color from the screen")
            Button {
                isMinimized.toggle()
            } label: {
                Image(systemName: isMinimized ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(chrome.palette.mutedForeground)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help(isMinimized ? "Expand the theme editor" : "Minimize the theme editor")
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(chrome.palette.mutedForeground)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Close the theme editor")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(chrome.palette.border.opacity(0.7)).frame(height: 1)
        }
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        if let selectedRole { return selectedRole.label }
        return "Select a color below"
    }

    // MARK: - Body

    private var bodyScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                nameField
                if let errorMessage {
                    Text(errorMessage)
                        .font(chrome.fonts.font(chrome.fonts.body))
                        .foregroundColor(chrome.palette.destructive)
                }
                appearanceField
                colorsHeader
                colorFields
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .frame(maxHeight: 640)
    }

    private var nameField: some View {
        HStack(spacing: 12) {
            Text("Theme name")
                .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                .foregroundColor(chrome.palette.foreground)
            TextField(session.isEditing ? "Theme name" : "e.g. Aurora", text: $name)
                .font(chrome.fonts.font(chrome.fonts.body))
                .foregroundColor(chrome.palette.foreground)
                .textFieldStyle(.plain)
                .padding(.horizontal, 8)
                .frame(height: 32)
                .background(chrome.palette.secondary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: chrome.radius.md))
                .onChange(of: name) { _ in errorMessage = nil }
        }
    }

    private var appearanceField: some View {
        HStack(spacing: 12) {
            Text("Appearance")
                .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                .foregroundColor(chrome.palette.foreground)
            HStack(spacing: 8) {
                ForEach(ThemeAppearance.allCases, id: \.self) { appearance in
                    Button {
                        activeAppearance = appearance
                    } label: {
                        Text(appearance == .light ? "Light" : "Dark")
                            .font(chrome.fonts.font(chrome.fonts.caption, weight: .medium))
                            .foregroundColor(
                                activeAppearance == appearance
                                    ? chrome.palette.foreground
                                    : chrome.palette.mutedForeground
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: chrome.radius.md)
                                    .fill(
                                        activeAppearance == appearance
                                            ? chrome.palette.accent.opacity(0.6)
                                            : .clear
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: chrome.radius.md)
                                    .stroke(
                                        activeAppearance == appearance
                                            ? chrome.palette.primary.opacity(0.9)
                                            : chrome.palette.border.opacity(0.7),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var colorsHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Colors")
                    .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                    .foregroundColor(chrome.palette.foreground)
                if !isAdvanced {
                    Text("Two colors, rest derived")
                        .font(chrome.fonts.font(chrome.fonts.caption))
                        .foregroundColor(chrome.palette.mutedForeground)
                }
            }
            Spacer()
            if isAdvanced {
                TextField("Filter colors", text: $roleQuery)
                    .font(chrome.fonts.font(chrome.fonts.caption))
                    .foregroundColor(chrome.palette.foreground)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8)
                    .frame(height: 26)
                    .background(chrome.palette.secondary.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: chrome.radius.sm))
                    .frame(maxWidth: 140)
            }
            HStack(spacing: 6) {
                Text("Advanced")
                    .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                    .foregroundColor(chrome.palette.foreground)
                Toggle("", isOn: $isAdvanced)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(chrome.palette.primary)
                    .labelsHidden()
                    .onChange(of: isAdvanced) { advanced in
                        if !advanced { enterGuidedMode() }
                    }
            }
        }
    }

    private var colorFields: some View {
        VStack(spacing: 0) {
            if isAdvanced {
                advancedGroups
            } else {
                guidedFields
            }
        }
    }

    private var guidedFields: some View {
        VStack(spacing: 0) {
            guidedColorField("Background", \.background)
            guidedColorField("Accent", \.primary)
        }
    }

    private func guidedColorField(_ label: String, _ keyPath: WritableKeyPath<Palette, Color>) -> some View {
        ColorField(
            chrome: chrome,
            label: label,
            color: currentPalette[keyPath: keyPath],
            selected: selectedRole?.keyPath == keyPath
        ) {
            selectedRole = PaletteRole("guided-\(label.lowercased())", label, .color(keyPath))
        } onChange: { color in
            var palette = currentPalette
            palette[keyPath: keyPath] = color
            setPalette(PaletteDerivation.derive(background: palette.background, accent: palette.primary), for: activeAppearance)
            simpleDirty.insert(activeAppearance)
        }
    }

    private var advancedGroups: some View {
        let query = roleQuery.trimmingCharacters(in: .whitespaces).lowercased()
        let groups = PaletteRoleGroup.allCases.filter { group in
            guard !query.isEmpty else { return true }
            return group.roles.contains { $0.label.lowercased().contains(query) }
        }
        return VStack(spacing: 20) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.title)
                        .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                        .foregroundColor(chrome.palette.foreground)
                    VStack(spacing: 0) {
                        ForEach(group.roles) { role in
                            roleField(role)
                        }
                    }
                }
            }
            if groups.isEmpty {
                Text("No matches.")
                    .font(chrome.fonts.font(chrome.fonts.caption))
                    .foregroundColor(chrome.palette.mutedForeground)
            }
        }
    }

    private func roleField(_ role: PaletteRole) -> some View {
        Group {
            if let keyPath = role.keyPath {
                ColorField(
                    chrome: chrome,
                    label: role.label,
                    color: currentPalette[keyPath: keyPath],
                    selected: selectedRole?.keyPath == keyPath
                ) {
                    selectedRole = role
                } onChange: { color in
                    var palette = currentPalette
                    palette[keyPath: keyPath] = color
                    setPalette(palette, for: activeAppearance)
                }
            } else {
                numericRoleField(role)
            }
        }
    }

    private func numericRoleField(_ role: PaletteRole) -> some View {
        Group {
            switch role.kind {
            case .font(let keyPath):
                NumberField(
                    chrome: chrome,
                    label: role.label,
                    value: draft.fonts[keyPath: keyPath]
                ) { newValue in
                    draft.fonts[keyPath: keyPath] = newValue
                }
            case .spacing(let keyPath):
                NumberField(
                    chrome: chrome,
                    label: role.label,
                    value: draft.spacing[keyPath: keyPath]
                ) { newValue in
                    draft.spacing[keyPath: keyPath] = newValue
                }
            case .radius(let keyPath):
                NumberField(
                    chrome: chrome,
                    label: role.label,
                    value: draft.radius[keyPath: keyPath]
                ) { newValue in
                    draft.radius[keyPath: keyPath] = newValue
                }
            case .family:
                familyField
            case .color:
                EmptyView()
            }
        }
    }

    private var familyField: some View {
        HStack(spacing: 8) {
            Text("Font family")
                .font(chrome.fonts.font(chrome.fonts.body))
                .foregroundColor(chrome.palette.mutedForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Inter", text: familyBinding)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(chrome.palette.foreground)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 8)
                .frame(width: 112, height: 32)
                .background(chrome.palette.secondary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: chrome.radius.md))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var familyBinding: Binding<String> {
        Binding(
            get: { draft.fonts.family ?? "" },
            set: { draft.fonts.family = $0.isEmpty ? nil : $0 }
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button("Cancel", action: onClose)
                .buttonStyle(.plain)
                .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                .foregroundColor(chrome.palette.foreground)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 6).fill(.clear))
            Button(action: save) {
                HStack(spacing: 4) {
                    if !session.isEditing {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    Text(session.isEditing ? "Save changes" : "Create theme")
                        .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                }
                .foregroundColor(chrome.palette.accentForeground)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 6).fill(chrome.palette.primary))
            }
            .buttonStyle(.plain)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .overlay(alignment: .top) {
            Rectangle().fill(chrome.palette.border.opacity(0.7)).frame(height: 1)
        }
    }

    // MARK: - Helpers

    private var currentPalette: Palette {
        draft.palette(for: activeAppearance)
    }

    private func setPalette(_ palette: Palette, for appearance: ThemeAppearance) {
        if appearance == .dark {
            draft.palette = palette
        } else {
            draft.lightPalette = palette
        }
    }

    /// Returning to guided mode regenerates both appearances from their
    /// two-color seeds, matching what a save from guided mode will produce.
    private func enterGuidedMode() {
        for appearance in ThemeAppearance.allCases {
            var palette = draft.palette(for: appearance)
            palette = PaletteDerivation.derive(background: palette.background, accent: palette.primary)
            setPalette(palette, for: appearance)
            simpleDirty.insert(appearance)
        }
        selectedRole = nil
    }

    private func inspect() {
        NSColorSampler().show { sampled in
            guard let sampled else { return }
            Task { @MainActor in
                let role = selectedRole ?? PaletteRoleGroup.allCases.flatMap(\.roles).first { $0.label == "Accent" }
                guard let role, let keyPath = role.keyPath else { return }
                selectedRole = role
                var palette = currentPalette
                palette[keyPath: keyPath] = Color(nsColor: sampled)
                setPalette(palette, for: activeAppearance)
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = "Name your theme first."
            return
        }
        var theme = draft
        theme.label = trimmed
        if !isAdvanced {
            for appearance in ThemeAppearance.allCases where simpleDirty.contains(appearance) {
                var palette = theme.palette(for: appearance)
                palette = PaletteDerivation.derive(background: palette.background, accent: palette.primary)
                setPaletteIn(&theme, palette, for: appearance)
            }
        }
        do {
            try onSave(theme)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setPaletteIn(_ theme: inout Theme, _ palette: Palette, for appearance: ThemeAppearance) {
        if appearance == .dark {
            theme.palette = palette
        } else {
            theme.lightPalette = palette
        }
    }
}

/// The theme editor's open session, owned by `SettingsView`.
struct ThemeEditorSession {
    let id: UUID
    let isEditing: Bool
    let initialName: String
}

// MARK: - Palette role groups

/// A color role the advanced editor exposes; the label is what the filter matches.
struct PaletteRole: Identifiable {
    enum Kind {
        case color(WritableKeyPath<Palette, Color>)
        case font(WritableKeyPath<FontConfig, CGFloat>)
        case spacing(WritableKeyPath<Spacing, CGFloat>)
        case radius(WritableKeyPath<Radius, CGFloat>)
        case family
    }

    let id: String
    let label: String
    let kind: Kind

    init(_ id: String, _ label: String, _ kind: Kind) {
        self.id = id
        self.label = label
        self.kind = kind
    }

    var keyPath: WritableKeyPath<Palette, Color>? {
        if case .color(let keyPath) = kind { return keyPath }
        return nil
    }
}

enum PaletteRoleGroup: String, CaseIterable, Identifiable {
    case foundation
    case brand
    case syntax
    case fonts
    case spacing
    case radius

    var id: String { rawValue }

    var title: String {
        switch self {
        case .foundation: "Foundation"
        case .brand: "Brand & content"
        case .syntax: "Syntax"
        case .fonts: "Fonts"
        case .spacing: "Spacing"
        case .radius: "Radius"
        }
    }

    var roles: [PaletteRole] {
        switch self {
        case .foundation:
            [
                PaletteRole("background", "Background", .color(\.background)),
                PaletteRole("surface", "Surface", .color(\.card)),
                PaletteRole("raised-surface", "Raised surface", .color(\.secondary)),
                PaletteRole("overlay", "Overlay", .color(\.muted)),
                PaletteRole("text", "Text", .color(\.foreground)),
                PaletteRole("card-text", "Card text", .color(\.cardForeground)),
                PaletteRole("muted-text", "Muted text", .color(\.mutedForeground)),
                PaletteRole("border", "Border", .color(\.border)),
            ]
        case .brand:
            [
                PaletteRole("primary", "Primary", .color(\.primary)),
                PaletteRole("accent", "Accent", .color(\.accent)),
                PaletteRole("accent-foreground", "Accent foreground", .color(\.accentForeground)),
                PaletteRole("secondary-foreground", "Secondary foreground", .color(\.secondaryForeground)),
                PaletteRole("destructive", "Destructive", .color(\.destructive)),
            ]
        case .syntax:
            [
                PaletteRole("syntax-keyword", "Keyword", .color(\.syntaxKeyword)),
                PaletteRole("syntax-string", "String", .color(\.syntaxString)),
                PaletteRole("syntax-comment", "Comment", .color(\.syntaxComment)),
                PaletteRole("syntax-type", "Type", .color(\.syntaxType)),
                PaletteRole("syntax-number", "Number", .color(\.syntaxNumber)),
                PaletteRole("syntax-plain", "Plain", .color(\.syntaxPlain)),
            ]
        case .fonts:
            [
                PaletteRole("family", "Font family", .family),
                PaletteRole("heading1", "Heading 1", .font(\.heading1)),
                PaletteRole("heading2", "Heading 2", .font(\.heading2)),
                PaletteRole("heading3", "Heading 3", .font(\.heading3)),
                PaletteRole("heading4", "Heading 4", .font(\.heading4)),
                PaletteRole("heading5", "Heading 5", .font(\.heading5)),
                PaletteRole("body", "Body", .font(\.body)),
                PaletteRole("caption", "Caption", .font(\.caption)),
                PaletteRole("code", "Code", .font(\.code)),
                PaletteRole("inline-code", "Inline code", .font(\.inlineCode)),
                PaletteRole("label", "Label", .font(\.label)),
                PaletteRole("line-spacing", "Line spacing", .font(\.lineSpacing)),
            ]
        case .spacing:
            [
                PaletteRole("spacing-xs", "XS", .spacing(\.xs)),
                PaletteRole("spacing-sm", "SM", .spacing(\.sm)),
                PaletteRole("spacing-md", "MD", .spacing(\.md)),
                PaletteRole("spacing-lg", "LG", .spacing(\.lg)),
                PaletteRole("spacing-xl", "XL", .spacing(\.xl)),
                PaletteRole("spacing-xxl", "XXL", .spacing(\.xxl)),
            ]
        case .radius:
            [
                PaletteRole("radius-sm", "SM", .radius(\.sm)),
                PaletteRole("radius-md", "MD", .radius(\.md)),
                PaletteRole("radius-lg", "LG", .radius(\.lg)),
            ]
        }
    }
}