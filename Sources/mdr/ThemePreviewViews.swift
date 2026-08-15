import AppKit
import MDReaderCore
import SwiftUI

/// The palette roles a theme preview shows, mapped from mdr's token roles.
struct ThemePreviewRoles {
    let sidebar: Color
    let canvas: Color
    let surface: Color
    let accentSurface: Color
    let accent: Color
    let messageSurface: Color
    let messageAction: Color

    init(theme: Theme, appearance: ThemeAppearance) {
        let palette = theme.palette(for: appearance)
        sidebar = palette.secondary
        canvas = palette.background
        surface = palette.card
        accentSurface = palette.accent
        accent = palette.accent
        messageSurface = palette.card
        messageAction = palette.primary
    }
}

/// A theme's light/dark ball: canvas-dominant base with a contained accent
/// glow, the preview identity T3 Code uses in its theme library.
struct ThemePreviewBall: View {
    let colors: ThemePreviewRoles
    let appearance: ThemeAppearance

    private var isDark: Bool { appearance == .dark }

    var body: some View {
        ZStack {
            Circle()
                .fill(base)
            RadialGradient(
                colors: [colors.accent, colors.accent.opacity(0.4), .clear],
                center: accentPosition,
                startRadius: 0,
                endRadius: 34
            )
            RadialGradient(
                colors: [colors.messageAction.opacity(0.45), colors.messageAction.opacity(0.1), .clear],
                center: actionPosition,
                startRadius: 0,
                endRadius: 34
            )
        }
        .blur(radius: 3)
        .scaleEffect(1.1)
        .clipShape(Circle())
        .overlay(Circle().stroke(edge, lineWidth: 1))
        .frame(width: 56, height: 56)
        .shadow(color: .black.opacity(isDark ? 0.18 : 0.08), radius: 2, y: 1)
    }

    /// The base carries the ball's light/dark identity, so it stays dominant.
    private var base: Color {
        colors.canvas.mixed(with: isDark ? Color(hex: 0x09090B) : .white, amount: 0.2)
    }

    private var edge: Color {
        isDark ? .white.opacity(0.14) : .black.opacity(0.10)
    }

    private var accentPosition: UnitPoint {
        isDark ? UnitPoint(x: 0.28, y: 0.78) : UnitPoint(x: 0.72, y: 0.22)
    }

    private var actionPosition: UnitPoint {
        isDark ? UnitPoint(x: 0.82, y: 0.18) : UnitPoint(x: 0.18, y: 0.82)
    }
}

/// A miniature of the app: a content column with a sidebar and a floating
/// side panel, used by the Color scheme tiles.
struct ThemeWireframe: View {
    let colors: ThemePreviewRoles
    /// When set, only the given half of the frame paints (for the System tile).
    var clip: Side?

    enum Side {
        case left
        case right
    }

    private var line: Color { Color(white: 0.5, opacity: 0.25) }

    var body: some View {
        ZStack {
            Rectangle().fill(colors.canvas)
            if clip == nil || clip == .left {
                pane.halfMask(leading: true)
            }
            if clip == nil || clip == .right {
                pane.halfMask(leading: false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(line.opacity(0.9), lineWidth: 1))
    }

    private var pane: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                Rectangle().fill(colors.canvas)
                Rectangle()
                    .fill(colors.sidebar)
                    .frame(width: w * 0.22)
                    .overlay(alignment: .trailing) { Rectangle().fill(line).frame(width: 1) }

                // Sidebar: search, then thread rows.
                rect(0.03, 0.08, 0.16, 0.08, colors.surface, 4, stroke: line)
                rect(0.03, 0.22, 0.16, 0.07, colors.accentSurface, 4)
                rect(0.03, 0.32, 0.16, 0.07, colors.messageSurface, 4).opacity(0.7)
                rect(0.03, 0.42, 0.16, 0.07, colors.messageSurface, 4).opacity(0.5)

                // Content: a message bubble and two text lines.
                rect(0.72, 0.11, 0.24, 0.09, colors.messageSurface, 8)
                rect(0.27, 0.28, 0.34, 0.05, line, 2)
                rect(0.27, 0.38, 0.26, 0.05, line, 2)

                // Composer: a surface bar with a prompt dot and send button.
                rect(0.26, 0.77, 0.68, 0.15, colors.surface, 6, stroke: line)
                Circle().fill(line).opacity(0.7)
                    .frame(width: w * 0.06, height: w * 0.06)
                    .offset(x: w * 0.285, y: h * 0.845)
                Circle().fill(colors.messageAction)
                    .frame(width: w * 0.04, height: w * 0.04)
                    .offset(x: w * 0.90, y: h * 0.845)

                // Side panel island with agent rows.
                rect(0.75, 0.08, 0.20, 0.46, colors.surface, 8, stroke: line)
                ForEach(0..<3, id: \.self) { row in
                    Circle()
                        .fill(row == 0 ? Color(hex: 0x34D399) : row == 1 ? colors.messageAction : Color(hex: 0xFBBF24))
                        .opacity(0.55)
                        .frame(width: w * 0.024, height: w * 0.024)
                        .offset(x: w * 0.785, y: h * (0.14 + CGFloat(row) * 0.15))
                    rect(0.80, 0.145 + CGFloat(row) * 0.15, 0.115, 0.05, line, 2)
                }
            }
        }
    }

    private func rect(
        _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
        _ fill: Color, _ radius: CGFloat, stroke: Color? = nil
    ) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: radius)
                .fill(stroke == nil ? fill : .clear)
                .overlay(
                    stroke.map { color in
                        RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: 1)
                    }
                )
                .frame(width: geo.size.width * w, height: geo.size.height * h)
                .offset(x: geo.size.width * x, y: geo.size.height * y)
        }
    }
}

private extension View {
    /// Keeps only the leading or trailing half of a frame (System tile halves).
    func halfMask(leading: Bool) -> some View {
        self.mask(alignment: leading ? .leading : .trailing) {
            Rectangle().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension Color {
    /// Mixes with `other` in sRGB space by `amount` (0...1).
    func mixed(with other: Color, amount: CGFloat) -> Color {
        guard let a = NSColor(self).usingColorSpace(.sRGB),
              let b = NSColor(other).usingColorSpace(.sRGB) else { return self }
        func mix(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x * (1 - amount) + y * amount }
        return Color(
            .sRGB,
            red: mix(a.redComponent, b.redComponent),
            green: mix(a.greenComponent, b.greenComponent),
            blue: mix(a.blueComponent, b.blueComponent),
            opacity: 1
        )
    }
}