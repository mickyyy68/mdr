import AppKit
import MDReaderCore
import SwiftUI

/// A token-editing row in T3 Code's shape: label on the left, a color swatch
/// that opens the picker popover and a hex field on the right. Selecting the
/// row (click on the label) highlights it for the editor's Inspect flow.
struct ColorField: View {
    let chrome: Theme
    let label: String
    let color: Color
    var selected = false
    let onToggleSelect: () -> Void
    let onChange: (Color) -> Void

    @State private var isShowingPicker = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggleSelect) {
                Text(label)
                    .font(chrome.fonts.font(chrome.fonts.body))
                    .foregroundColor(selected ? chrome.palette.foreground : chrome.palette.mutedForeground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                isShowingPicker = true
            } label: {
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(chrome.palette.foreground.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Choose \(label) color")
            .accessibilityLabel("Choose \(label) color")
            .popover(isPresented: $isShowingPicker) {
                ColorPickerPanel(chrome: chrome, label: label, color: color, onChange: onChange)
            }

            HexField(chrome: chrome, label: label, color: color, onChange: onChange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: chrome.radius.md)
                .fill(selected ? chrome.palette.accent.opacity(0.6) : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: chrome.radius.md)
                .stroke(selected ? chrome.palette.primary.opacity(0.9) : .clear, lineWidth: 1)
        )
    }
}

/// A hex text field with a leading color dot, right-aligned like T3 Code's.
struct HexField: View {
    let chrome: Theme
    let label: String
    let color: Color
    let onChange: (Color) -> Void

    @State private var hexText: String
    @State private var isEditing = false

    init(chrome: Theme, label: String, color: Color, onChange: @escaping (Color) -> Void) {
        self.chrome = chrome
        self.label = label
        self.color = color
        self.onChange = onChange
        _hexText = State(initialValue: color.hexString)
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
            TextField("", text: $hexText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(chrome.palette.foreground)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .onSubmit(commit)
                .onChange(of: hexText) { newValue in
                    guard isEditing else { return }
                    if let parsed = Color(hexString: newValue) {
                        onChange(parsed)
                    }
                }
        }
        .padding(.horizontal, 8)
        .frame(width: 112, height: 32)
        .background(chrome.palette.secondary.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: chrome.radius.md))
        .onChange(of: color) { newColor in
            guard !isEditing else { return }
            hexText = newColor.hexString
        }
        .onTapGesture { isEditing = true }
        .onAppear { isEditing = false }
    }

    private func commit() {
        guard let parsed = Color(hexString: hexText) else {
            hexText = color.hexString
            return
        }
        onChange(parsed)
        isEditing = false
    }
}

/// The color picker popover in T3 Code's layout: a header with the current
/// color, an SV plane, a hue bar, and HEX + RGB fields.
struct ColorPickerPanel: View {
    let chrome: Theme
    let label: String
    let color: Color
    let onChange: (Color) -> Void

    @State private var hue: Double
    @State private var saturation: Double
    @State private var brightness: Double
    @State private var hexText: String
    @State private var rgbText: String
    @State private var isEditingText = false

    init(chrome: Theme, label: String, color: Color, onChange: @escaping (Color) -> Void) {
        self.chrome = chrome
        self.label = label
        self.color = color
        self.onChange = onChange
        let hsb = Self.hsb(from: color)
        _hue = State(initialValue: hsb.h)
        _saturation = State(initialValue: hsb.s)
        _brightness = State(initialValue: hsb.b)
        _hexText = State(initialValue: color.hexString)
        _rgbText = State(initialValue: Self.rgbString(from: color))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 12) {
                SVPlane(hue: hue, saturation: $saturation, brightness: $brightness)
                    .onChange(of: saturation) { _ in commitCurrentColor() }
                    .onChange(of: brightness) { _ in commitCurrentColor() }
                HueBar(hue: $hue)
                    .onChange(of: hue) { _ in commitCurrentColor() }
                HStack(spacing: 8) {
                    valueField("HEX", text: $hexText) { Self.hex(from: $0) }
                    valueField("RGB", text: $rgbText) { Self.rgb(from: $0) }
                }
            }
            .padding(12)
        }
        .frame(width: 288)
        .background(chrome.palette.background)
        .onChange(of: color) { newColor in
            guard !isEditingText else { return }
            hexText = newColor.hexString
            rgbText = Self.rgbString(from: newColor)
            let hsb = Self.hsb(from: newColor)
            hue = hsb.h
            saturation = hsb.s
            brightness = hsb.b
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(chrome.fonts.font(chrome.fonts.body, weight: .semibold))
                    .foregroundColor(chrome.palette.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("Choose a color")
                    .font(chrome.fonts.font(chrome.fonts.label))
                    .foregroundColor(chrome.palette.mutedForeground)
            }
            Spacer()
            Circle()
                .fill(currentColor)
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(chrome.palette.border.opacity(0.7)).frame(height: 1)
        }
    }

    private func valueField(
        _ title: String, text: Binding<String>, convert: @escaping (String) -> Color?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(chrome.palette.mutedForeground)
                .padding(.horizontal, 4)
            HStack(spacing: 6) {
                Circle()
                    .fill(currentColor)
                    .frame(width: 14, height: 14)
                TextField("", text: text)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(chrome.palette.foreground)
                    .textFieldStyle(.plain)
                    .onChange(of: text.wrappedValue) { newValue in
                        guard isEditingText, let parsed = convert(newValue) else { return }
                        apply(parsed)
                    }
                    .onTapGesture { isEditingText = true }
            }
            .padding(.horizontal, 8)
            .frame(height: 32)
            .background(chrome.palette.card)
            .clipShape(RoundedRectangle(cornerRadius: chrome.radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: chrome.radius.md)
                    .stroke(chrome.palette.border.opacity(0.8), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var currentColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private func commitCurrentColor() {
        guard !isEditingText else { return }
        hexText = currentColor.hexString
        rgbText = Self.rgbString(from: currentColor)
        onChange(currentColor)
    }

    private func apply(_ color: Color) {
        let hsb = Self.hsb(from: color)
        hue = hsb.h
        saturation = hsb.s
        brightness = hsb.b
        hexText = color.hexString
        rgbText = Self.rgbString(from: color)
        onChange(color)
    }

    private static func hsb(from color: Color) -> (h: Double, s: Double, b: Double) {
        guard let ns = NSColor(color).usingColorSpace(.sRGB) else { return (0, 0, 0) }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h, s, b)
    }

    private static func rgbString(from color: Color) -> String {
        guard let ns = NSColor(color).usingColorSpace(.sRGB) else { return "0, 0, 0" }
        let r = lround(Double(ns.redComponent) * 255)
        let g = lround(Double(ns.greenComponent) * 255)
        let b = lround(Double(ns.blueComponent) * 255)
        return "\(r), \(g), \(b)"
    }

    private static func hex(from text: String) -> Color? {
        Color(hexString: text)
    }

    private static func rgb(from text: String) -> Color? {
        let channels = text
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .split(whereSeparator: { $0 == "," || $0.isWhitespace })
            .compactMap { Int($0) }
        guard channels.count == 3, channels.allSatisfy({ (0...255).contains($0) }) else { return nil }
        return Color(
            .sRGB,
            red: Double(channels[0]) / 255,
            green: Double(channels[1]) / 255,
            blue: Double(channels[2]) / 255,
            opacity: 1
        )
    }
}

/// A saturation/brightness plane for a fixed hue, with a T3-style thumb.
private struct SVPlane: View {
    let hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color(hue: hue, saturation: 1, brightness: 1))
                LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top)
                LinearGradient(colors: [.white, .clear], startPoint: .leading, endPoint: .trailing)
                Circle()
                    .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.4), radius: 1)
                    .offset(
                        x: saturation * (geo.size.width - 12),
                        y: (1 - brightness) * (geo.size.height - 12)
                    )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        saturation = min(max(value.location.x / geo.size.width, 0), 1)
                        brightness = min(max(1 - value.location.y / geo.size.height, 0), 1)
                    }
            )
        }
        .frame(height: 128)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .accessibilityLabel("Saturation and brightness")
    }
}

/// A hue selection bar with a rainbow track and a pure-hue thumb.
private struct HueBar: View {
    @Binding var hue: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 10)
                Circle()
                    .fill(Color(hue: hue, saturation: 1, brightness: 1))
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.4), radius: 1)
                    .offset(x: hue * (geo.size.width - 16))
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        hue = min(max(value.location.x / geo.size.width, 0), 1)
                    }
            )
        }
        .frame(height: 24)
        .accessibilityLabel("Hue")
    }
}

/// A validated numeric field (spacing, radius, font sizes): positive and finite.
struct NumberField: View {
    let chrome: Theme
    let label: String
    let value: CGFloat
    let onChange: (CGFloat) -> Void

    @State private var text: String

    init(chrome: Theme, label: String, value: CGFloat, onChange: @escaping (CGFloat) -> Void) {
        self.chrome = chrome
        self.label = label
        self.value = value
        self.onChange = onChange
        _text = State(initialValue: String(format: "%g", Double(value)))
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(chrome.fonts.font(chrome.fonts.body))
                .foregroundColor(chrome.palette.mutedForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            TextField("", text: $text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(chrome.palette.foreground)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 8)
                .frame(width: 64, height: 32)
                .background(chrome.palette.secondary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: chrome.radius.md))
                .onSubmit(commit)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func commit() {
        guard let value = Double(text), value.isFinite, value > 0 else {
            text = String(format: "%g", Double(self.value))
            return
        }
        onChange(CGFloat(value))
    }
}