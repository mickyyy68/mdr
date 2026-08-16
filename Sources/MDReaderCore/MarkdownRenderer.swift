import AppKit
import Markdown
import SwiftUI

/// Renders a parsed markdown AST into SwiftUI views using the design system.
public struct MarkdownViewBuilder {
    public let baseURL: URL
    public let theme: Theme

    public init(baseURL: URL, theme: Theme) {
        self.baseURL = baseURL
        self.theme = theme
    }

    // MARK: - Blocks

    public func blockView(_ markup: Markup) -> AnyView {
        switch markup {
        case let heading as Heading:
            return AnyView(headingView(heading))
        case let paragraph as Paragraph:
            return AnyView(paragraphView(paragraph))
        case let list as UnorderedList:
            return AnyView(unorderedListView(list))
        case let list as OrderedList:
            return AnyView(orderedListView(list))
        case let codeBlock as CodeBlock:
            return AnyView(codeBlockView(codeBlock))
        case let quote as BlockQuote:
            return AnyView(quoteView(quote))
        case _ as ThematicBreak:
            return AnyView(ruleView())
        case let table as Markdown.Table:
            return AnyView(tableView(table))
        default:
            return AnyView(EmptyView())
        }
    }

    public func childrenBlocks(_ container: Markup) -> AnyView {
        let children = Array(container.children)
        return AnyView(
            ForEach(children.indices, id: \.self) { index in
                blockView(children[index])
            }
        )
    }

    // MARK: - Headings

    private func headingView(_ heading: Heading) -> some View {
        let size: CGFloat = switch heading.level {
        case 1: theme.fonts.heading1
        case 2: theme.fonts.heading2
        case 3: theme.fonts.heading3
        case 4: theme.fonts.heading4
        default: theme.fonts.heading5
        }
        let weight: Font.Weight = heading.level <= 2 ? .bold : .semibold
        var attrs = baseAttrs(font: theme.fonts.font(size, weight: weight), color: theme.palette.foreground)
        return Text(attributed(heading, attrs: &attrs))
            .padding(.top, heading.level == 1 ? theme.spacing.sm : theme.spacing.xs)
            .textSelection(.enabled)
    }

    // MARK: - Paragraphs

    @ViewBuilder
    private func paragraphView(_ paragraph: Paragraph) -> some View {
        let children = Array(paragraph.children)
        if children.count == 1, let image = children.first as? Markdown.Image {
            imageView(image)
        } else {
            var attrs = baseAttrs(font: theme.fonts.font(theme.fonts.body), color: theme.palette.cardForeground)
            Text(attributed(paragraph, attrs: &attrs))
                .lineSpacing(theme.fonts.lineSpacing)
                .textSelection(.enabled)
        }
    }

    // MARK: - Lists

    private func unorderedListView(_ list: UnorderedList) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            ForEach(Array(list.children.enumerated()), id: \.offset) { _, child in
                listItemRow(child, marker: bulletMarker)
            }
        }
    }

    private func orderedListView(_ list: OrderedList) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            ForEach(Array(list.children.enumerated()), id: \.offset) { index, child in
                listItemRow(child, marker: numberMarker(index + 1))
            }
        }
    }

    private var bulletMarker: some View {
        Text("•")
            .font(theme.fonts.font(theme.fonts.body, weight: .bold))
            .foregroundColor(theme.palette.primary)
    }

    private func numberMarker(_ number: Int) -> some View {
        Text("\(number).")
            .font(theme.fonts.font(theme.fonts.body))
            .foregroundColor(theme.palette.mutedForeground)
    }

    private func listItemRow(_ item: Markup, marker: some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.spacing.md) {
            marker
            childrenBlocks(item)
        }
    }

    // MARK: - Code

    private func codeBlockView(_ codeBlock: CodeBlock) -> some View {
        let language = codeBlock.language ?? ""
        return VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if !language.isEmpty {
                Text(language)
                    .font(theme.fonts.font(theme.fonts.label, weight: .medium))
                    .foregroundColor(theme.palette.mutedForeground)
                    .textCase(.lowercase)
            }
            Text(CodeHighlighter.highlight(codeBlock.code, palette: theme.palette))
                .font(.system(size: theme.fonts.code, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: theme.radius.md).fill(theme.palette.secondary))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.md)
                .stroke(theme.palette.border.opacity(0.7), lineWidth: 1)
        )
    }

    // MARK: - Quotes

    private func quoteView(_ quote: BlockQuote) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.lg) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.palette.primary.opacity(0.5))
                .frame(width: 3)
            childrenBlocks(quote)
        }
        .padding(.leading, theme.spacing.md)
    }

    // MARK: - Rules

    private func ruleView() -> some View {
        Rectangle()
            .fill(theme.palette.border.opacity(0.6))
            .frame(height: 1)
    }

    // MARK: - Tables

    private func tableView(_ table: Markdown.Table) -> some View {
        let rows = Array(table.children)
        let indices = Array(rows.indices)
        let columnCount = max(1, table.maxColumnCount)
        return VStack(alignment: .leading, spacing: 0) {
            Grid(alignment: .leading, horizontalSpacing: theme.spacing.xl, verticalSpacing: theme.spacing.sm) {
                ForEach(indices, id: \.self) { index in
                    let row = rows[index]
                    let isHeader = row is Markdown.Table.Head
                    GridRow {
                        ForEach(Array(row.children.enumerated()), id: \.offset) { _, cell in
                            tableCellView(cell, header: isHeader)
                        }
                    }
                    if isHeader {
                        GridRow {
                            Divider().gridCellColumns(columnCount)
                        }
                    }
                }
            }
            .padding(theme.spacing.lg)
            .background(RoundedRectangle(cornerRadius: theme.radius.md).fill(theme.palette.card))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md)
                    .stroke(theme.palette.border.opacity(0.7), lineWidth: 1)
            )
        }
    }

    private func tableCellView(_ cell: Markup, header: Bool) -> SwiftUI.Text {
        if header {
            var attrs = baseAttrs(font: theme.fonts.font(theme.fonts.caption, weight: .semibold), color: theme.palette.foreground)
            return Text(attributed(cell, attrs: &attrs))
        } else {
            var attrs = baseAttrs(font: theme.fonts.font(theme.fonts.caption), color: theme.palette.cardForeground)
            return Text(attributed(cell, attrs: &attrs))
        }
    }

    // MARK: - Images

    @ViewBuilder
    private func imageView(_ image: Markdown.Image) -> some View {
        if let src = image.source {
            let url: URL? = src.hasPrefix("http://") || src.hasPrefix("https://")
                ? URL(string: src)
                : baseURL.appendingPathComponent(src)
            if let url, let nsImage = NSImage(contentsOf: url) {
                let altText = plainText(image)
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 640)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
                    .accessibilityLabel(altText.isEmpty ? "Image" : altText)
            }
        }
    }

    // MARK: - Inline attributes

    private func baseAttrs(font: Font, color: Color) -> AttributeContainer {
        var attrs = AttributeContainer()
        attrs.font = font
        attrs.foregroundColor = color
        return attrs
    }

    /// Recursively builds an `AttributedString` for inline content.
    private func attributed(_ markup: Markup, attrs: inout AttributeContainer) -> AttributedString {
        var result = AttributedString()
        for child in markup.children {
            result.append(inline(child, base: attrs))
        }
        return result
    }

    private func inline(_ markup: Markup, base: AttributeContainer) -> AttributedString {
        var attrs = base
        switch markup {
        case let text as Markdown.Text:
            return AttributedString(text.string, attributes: attrs)

        case let emphasis as Emphasis:
            attrs.font = attrs.font?.italic()
            return attributed(emphasis, attrs: &attrs)

        case let strong as Strong:
            attrs.font = attrs.font?.bold()
            return attributed(strong, attrs: &attrs)

        case let strike as Strikethrough:
            attrs.strikethroughStyle = SwiftUI.Text.LineStyle(pattern: .solid)
            return attributed(strike, attrs: &attrs)

        case let code as InlineCode:
            var codeAttrs = AttributeContainer()
            codeAttrs.font = .system(size: theme.fonts.inlineCode, weight: .medium, design: .monospaced)
            codeAttrs.foregroundColor = theme.palette.syntaxKeyword
            codeAttrs.backgroundColor = theme.palette.secondary
            return AttributedString(code.code, attributes: codeAttrs)

        case let link as Markdown.Link:
            attrs.foregroundColor = theme.palette.primary
            attrs.underlineStyle = SwiftUI.Text.LineStyle(pattern: .solid)
            if let dest = link.destination, let url = URL(string: dest) {
                attrs.link = url
            }
            let label = attributed(link, attrs: &attrs)
            if label == AttributedString(), let dest = link.destination {
                return AttributedString(dest, attributes: attrs)
            }
            return label

        case _ as SoftBreak:
            return AttributedString(" ", attributes: attrs)

        case _ as LineBreak:
            return AttributedString("\n", attributes: attrs)

        default:
            return AttributedString(plainText(markup), attributes: attrs)
        }
    }

    private func plainText(_ markup: Markup) -> String {
        if let text = markup as? Markdown.Text {
            return text.string
        }
        return markup.children.map { plainText($0) }.joined()
    }
}

// MARK: - Root view

public struct MarkdownReaderView: View {
    let document: Document
    let builder: MarkdownViewBuilder

    public init(document loaded: DocumentLoader.LoadedDocument, theme: Theme) {
        self.document = Document(parsing: loaded.content)
        self.builder = MarkdownViewBuilder(baseURL: loaded.url.deletingLastPathComponent(), theme: theme)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: builder.theme.spacing.lg) {
                ForEach(Array(document.children.enumerated()), id: \.offset) { _, child in
                    builder.blockView(child)
                }
            }
            .padding(builder.theme.spacing.xxl)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(builder.theme.palette.background)
    }
}