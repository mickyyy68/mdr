import MDReaderCore
import SwiftUI

/// A theme library card in T3 Code's shape: light/dark preview balls that
/// assign the theme to that appearance, a clickable card that applies the
/// theme, and ghost icon actions.
struct ThemeLibraryCard: View {
    let chrome: Theme
    let label: String
    let theme: Theme
    /// Whether the applied theme matches this card (drives the ring).
    let isActive: Bool
    /// Whether each appearance is currently owned by this theme.
    let isActiveMode: (ThemeAppearance) -> Bool
    let onUse: () -> Void
    let onUseMode: (ThemeAppearance) -> Void
    var onDuplicate: (() -> Void)?
    var onEdit: (() -> Void)?
    var onExport: (() -> Void)?
    var onRemove: (() -> Void)?

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            previewArea
            footer
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? chrome.palette.accent.opacity(0.3) : chrome.palette.card.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? chrome.palette.primary.opacity(0.9) : chrome.palette.border.opacity(0.7), lineWidth: 1)
        )
        .overlay(isHovering && !isActive ? RoundedRectangle(cornerRadius: 12).fill(chrome.palette.accent.opacity(0.1)) : nil)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: onUse)
        .onHover { isHovering = $0 }
    }

    private var previewArea: some View {
        HStack(spacing: 10) {
            modeBall(.light)
            modeBall(.dark)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
    }

    private func modeBall(_ appearance: ThemeAppearance) -> some View {
        Button {
            onUseMode(appearance)
        } label: {
            ZStack {
                ThemePreviewBall(
                    colors: ThemePreviewRoles(theme: theme, appearance: appearance),
                    appearance: appearance
                )
                if isActiveMode(appearance) {
                    Circle()
                        .stroke(chrome.palette.primary.opacity(0.9), lineWidth: 2)
                        .frame(width: 60, height: 60)
                    Circle()
                        .fill(chrome.palette.background)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(chrome.palette.border.opacity(0.7), lineWidth: 1))
                        .overlay {
                            Image(systemName: appearance == .light ? "sun.max.fill" : "moon.fill")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(chrome.palette.foreground)
                        }
                        .offset(x: 22, y: 22)
                }
            }
            .frame(width: 68, height: 68)
        }
        .buttonStyle(.plain)
        .help("Use for \(appearance.rawValue) mode only")
        .accessibilityLabel("Use \(label) \(appearance.rawValue) mode")
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Button(action: onUse) {
                Text(label)
                    .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                    .foregroundColor(chrome.palette.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if let onDuplicate {
                ghostAction("doc.on.doc", label: "Duplicate theme") { onDuplicate() }
            }
            if let onEdit {
                ghostAction("pencil", label: "Edit theme") { onEdit() }
            }
            if let onExport {
                ghostAction("square.and.arrow.up", label: "Export theme file") { onExport() }
            }
            if let onRemove {
                ghostAction("trash", label: "Remove theme", destructive: true) { onRemove() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func ghostAction(_ systemImage: String, label: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(destructive ? chrome.palette.destructive : chrome.palette.mutedForeground)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}