import MDReaderCore
import SwiftUI

/// A small bordered action button with a hover highlight, used for
/// page-level actions (Create theme, Import theme, Choose files).
struct OutlinedButton: View {
    let chrome: Theme
    var systemImage: String?
    let title: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(title)
                    .font(chrome.fonts.font(chrome.fonts.caption, weight: .medium))
            }
            .foregroundColor(chrome.palette.foreground)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? chrome.palette.accent.opacity(0.12) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(chrome.palette.border, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
