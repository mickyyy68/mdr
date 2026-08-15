import AppKit
import MDReaderCore
import SwiftUI

/// A guidance window for the design-token config file. It does not edit tokens
/// itself; it points users at the config file so an AI assistant can edit it.
struct SettingsView: View {
    private let configURL: URL
    private let style = Theme.linear

    @State private var configExists = false
    @State private var configContent = ""
    @State private var errorMessage: String?

    init(configURL: URL) {
        self.configURL = configURL
    }

    var body: some View {
        VStack(alignment: .leading, spacing: style.spacing.lg) {
            header
            Divider()
            guidance
            configPathRow
            actions
            if let errorMessage {
                Text(errorMessage)
                    .font(style.fonts.font(style.fonts.caption))
                    .foregroundColor(style.palette.destructive)
            }
            Divider()
            jsonPreview
        }
        .padding(style.spacing.lg)
        .frame(minWidth: 540, minHeight: 600, alignment: .topLeading)
        .background(style.palette.background)
        .onAppear(perform: refresh)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: style.spacing.xs) {
            Text("Design Tokens")
                .font(style.fonts.font(style.fonts.heading3, weight: .semibold))
                .foregroundColor(style.palette.foreground)
            Text("Customize colors, fonts, spacing, and radius.")
                .font(style.fonts.font(style.fonts.body))
                .foregroundColor(style.palette.mutedForeground)
        }
    }

    private var guidance: some View {
        VStack(alignment: .leading, spacing: style.spacing.xs) {
            Text("How to customize")
                .font(style.fonts.font(style.fonts.caption, weight: .semibold))
                .foregroundColor(style.palette.foreground)
            Text("The design tokens live in the theme config file below. Ask your AI coding assistant to read this file and change the colors, fonts, spacing, or radius for you. Save the file, then relaunch \(CLI.name) for the changes to take effect.")
                .font(style.fonts.font(style.fonts.caption))
                .foregroundColor(style.palette.cardForeground)
                .lineSpacing(style.fonts.lineSpacing)
        }
    }

    private var configPathRow: some View {
        VStack(alignment: .leading, spacing: style.spacing.xs) {
            Text("Config file")
                .font(style.fonts.font(style.fonts.caption, weight: .semibold))
                .foregroundColor(style.palette.foreground)
            Text(configURL.path)
                .font(style.fonts.font(style.fonts.caption).monospaced())
                .foregroundColor(style.palette.mutedForeground)
                .textSelection(.enabled)
        }
    }

    private var actions: some View {
        HStack(spacing: style.spacing.md) {
            Button("Create Config", action: createConfig)
                .disabled(configExists)
            Button("Reveal in Finder", action: revealInFinder)
                .disabled(!configExists)
            Spacer()
        }
    }

    private var jsonPreview: some View {
        Group {
            if configExists {
                ScrollView {
                    Text(configContent)
                        .font(style.fonts.font(style.fonts.caption).monospaced())
                        .foregroundColor(style.palette.cardForeground)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(style.spacing.md)
                }
            } else {
                VStack(spacing: style.spacing.xs) {
                    Text("No config file yet.")
                        .font(style.fonts.font(style.fonts.caption))
                        .foregroundColor(style.palette.mutedForeground)
                    Text("Click “Create Config” to generate one, then edit it.")
                        .font(style.fonts.font(style.fonts.caption))
                        .foregroundColor(style.palette.mutedForeground)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: style.radius.md).fill(style.palette.secondary))
        .overlay(
            RoundedRectangle(cornerRadius: style.radius.md)
                .stroke(style.palette.border.opacity(0.7), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func createConfig() {
        do {
            let directory = configURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Theme.defaultConfigData().write(to: configURL, options: .atomic)
            errorMessage = nil
            refresh()
        } catch {
            errorMessage = "mdr: could not create config: \(error.localizedDescription)"
        }
    }

    private func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([configURL])
    }

    private func refresh() {
        let exists = FileManager.default.fileExists(atPath: configURL.path)
        configExists = exists
        if exists {
            do {
                let data = try Data(contentsOf: configURL)
                configContent = String(data: data, encoding: .utf8) ?? ""
                errorMessage = nil
            } catch {
                configContent = ""
                errorMessage = "mdr: could not read config: \(error.localizedDescription)"
            }
        } else {
            configContent = ""
            errorMessage = nil
        }
    }
}