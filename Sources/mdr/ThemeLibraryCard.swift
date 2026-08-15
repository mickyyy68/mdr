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
    /// Whether this card holds the user's saved theme, shown as a badge so a
    /// custom theme named like a preset is distinguishable at a glance.
    var isCustom = false
    var onEdit: (() -> Void)?
    var onExport: (() -> Void)?
    var onRemove: (() -> Void)?

    @State private var isHovering = false
    @State private var hoveredAppearance: ThemeAppearance?

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
                .stroke(isActive ? chrome.palette.primary.opacity(0.9) : chrome.palette.border, lineWidth: 1)
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
        let isActive = isActiveMode(appearance)
        return Button {
            onUseMode(appearance)
        } label: {
            ZStack {
                ThemePreviewBall(
                    colors: ThemePreviewRoles(theme: theme, appearance: appearance),
                    appearance: appearance
                )
                if isActive {
                    Circle()
                        .stroke(chrome.palette.primary.opacity(0.9), lineWidth: 2)
                        .frame(width: 60, height: 60)
                        .transition(.opacity)
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
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .frame(width: 68, height: 68)
            .scaleEffect(hoveredAppearance == appearance ? 1.08 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoveredAppearance)
        .animation(.easeOut(duration: 0.15), value: isActive)
        .onHover { hovering in
            if hovering {
                hoveredAppearance = appearance
            } else if hoveredAppearance == appearance {
                hoveredAppearance = nil
            }
        }
        .help("Use for \(appearance.rawValue) mode only")
        .accessibilityLabel("Use \(label) \(appearance.rawValue) mode")
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Button(action: onUse) {
                HStack(spacing: 6) {
                    Text(label)
                        .font(chrome.fonts.font(chrome.fonts.body, weight: .medium))
                        .foregroundColor(chrome.palette.foreground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if isCustom && !label.localizedCaseInsensitiveContains("custom") {
                        customBadge
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCustom ? "\(label), custom theme" : label)
            if let onEdit {
                ghostAction("pencil", label: "Edit theme") { onEdit() }
            }
            if let onExport {
                ghostAction("doc.on.clipboard", label: "Copy theme JSON to clipboard") { onExport() }
            }
            if let onRemove {
                ghostAction("trash", label: "Remove theme", destructive: true) { onRemove() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var customBadge: some View {
        Text("Custom")
            .font(chrome.fonts.font(chrome.fonts.label, weight: .medium))
            .foregroundColor(chrome.palette.foreground)
            .padding(.horizontal, 6)
            .frame(height: 18)
            .background(
                RoundedRectangle(cornerRadius: chrome.radius.sm)
                    .fill(chrome.palette.secondary.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: chrome.radius.sm)
                    .stroke(chrome.palette.border.opacity(0.8), lineWidth: 1)
            )
    }

    private func ghostAction(_ systemImage: String, label: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        GhostActionButton(
            chrome: chrome,
            systemImage: systemImage,
            label: label,
            destructive: destructive,
            action: action
        )
    }
}

/// A 24pt ghost icon button with a hover highlight, as in the card footer.
private struct GhostActionButton: View {
    let chrome: Theme
    let systemImage: String
    let label: String
    var destructive = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(
                    isHovering
                        ? (destructive ? chrome.palette.destructive : chrome.palette.foreground)
                        : chrome.palette.mutedForeground
                )
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isHovering
                                ? (destructive ? chrome.palette.destructive.opacity(0.15) : chrome.palette.accent.opacity(0.1))
                                : .clear
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .onHover { isHovering = $0 }
    }
}