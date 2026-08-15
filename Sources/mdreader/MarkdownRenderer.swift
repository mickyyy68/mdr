import SwiftUI
import AppKit
import Markdown

// MARK: - Markdown view builder

/// Renders a swift-markdown AST into SwiftUI views using the Linear design system.
struct MarkdownViewBuilder {
    let baseURL: URL

    // MARK: Blocks

    func blockView(_ markup: Markup) -> AnyView {
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

    func childrenBlocks(_ container: Markup) -> AnyView {
        let children = Array(container.children)
        return AnyView(
            ForEach(children.indices, id: \.self) { index in
                blockView(children[index])
            }
        )
    }

    // MARK: Headings

    private func headingView(_ heading: Heading) -> some View {
        let size: CGFloat = switch heading.level {
        case 1: 26
        case 2: 20
        case 3: 17
        case 4: 15
        default: 14
        }
        let weight: Font.Weight = heading.level <= 2 ? .bold : .semibold
        var attrs = baseAttrs(font: Fonts.inter(size, weight: weight), color: Palette.foreground)
        return Text(attributed(heading, attrs: &attrs))
            .padding(.top, heading.level == 1 ? Spacing.sm : Spacing.xs)
            .textSelection(.enabled)
    }

    // MARK: Paragraphs

    @ViewBuilder
    private func paragraphView(_ paragraph: Paragraph) -> some View {
        let children = Array(paragraph.children)
        if children.count == 1, let image = children.first as? Markdown.Image {
            imageView(image)
        } else {
            var attrs = baseAttrs(font: Fonts.inter(15), color: Palette.cardForeground)
            Text(attributed(paragraph, attrs: &attrs))
                .lineSpacing(3)
                .textSelection(.enabled)
        }
    }

    // MARK: Lists

    private func unorderedListView(_ list: UnorderedList) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(Array(list.children.enumerated()), id: \.offset) { _, child in
                listItemRow(child, marker: bulletMarker)
            }
        }
    }

    private func orderedListView(_ list: OrderedList) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(Array(list.children.enumerated()), id: \.offset) { index, child in
                listItemRow(child, marker: numberMarker(index + 1))
            }
        }
    }

    private var bulletMarker: some View {
        Text("•")
            .font(Fonts.inter(15, weight: .bold))
            .foregroundColor(Palette.primary)
    }

    private func numberMarker(_ number: Int) -> some View {
        Text("\(number).")
            .font(Fonts.inter(15))
            .foregroundColor(Palette.mutedForeground)
    }

    private func listItemRow(_ item: Markup, marker: some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
            marker
            childrenBlocks(item)
        }
    }

    // MARK: Code

    private func codeBlockView(_ codeBlock: CodeBlock) -> some View {
        let language = codeBlock.language ?? ""
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            if !language.isEmpty {
                Text(language)
                    .font(Fonts.inter(11, weight: .medium))
                    .foregroundColor(Palette.mutedForeground)
                    .textCase(.lowercase)
            }
            Text(highlight(codeBlock.code))
                .textSelection(.enabled)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.md).fill(Palette.secondary))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Palette.border.opacity(0.7), lineWidth: 1)
        )
    }

    // MARK: Quotes

    private func quoteView(_ quote: BlockQuote) -> some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Palette.primary.opacity(0.5))
                .frame(width: 3)
            childrenBlocks(quote)
        }
        .padding(.leading, Spacing.md)
    }

    // MARK: Rules

    private func ruleView() -> some View {
        Rectangle()
            .fill(Palette.border.opacity(0.6))
            .frame(height: 1)
    }

    // MARK: Tables

    private func tableView(_ table: Markdown.Table) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(table.children.enumerated()), id: \.offset) { _, row in
                if row is Markdown.Table.Head {
                    tableRowView(row, header: true)
                    Divider().overlay(Palette.border.opacity(0.6))
                } else {
                    tableRowView(row, header: false)
                }
            }
        }
        .padding(Spacing.lg)
        .background(RoundedRectangle(cornerRadius: Radius.md).fill(Palette.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Palette.border.opacity(0.7), lineWidth: 1)
        )
    }

    private func tableRowView(_ row: Markup, header: Bool) -> some View {
        Grid(alignment: .leading, horizontalSpacing: Spacing.xl, verticalSpacing: Spacing.sm) {
            ForEach(Array(row.children.enumerated()), id: \.offset) { _, cell in
                GridRow {
                    if header {
                        var attrs = baseAttrs(font: Fonts.inter(13, weight: .semibold), color: Palette.foreground)
                        Text(attributed(cell, attrs: &attrs))
                    } else {
                        var attrs = baseAttrs(font: Fonts.inter(13), color: Palette.cardForeground)
                        Text(attributed(cell, attrs: &attrs))
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: Images

    @ViewBuilder
    private func imageView(_ image: Markdown.Image) -> some View {
        if let src = image.source {
            let url: URL? = src.hasPrefix("http://") || src.hasPrefix("https://")
                ? URL(string: src)
                : baseURL.appendingPathComponent(src)
            if let url, let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 640)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }
        }
    }

    // MARK: Inline attributes

    private func baseAttrs(font: Font, color: Color) -> AttributeContainer {
        var attrs = AttributeContainer()
        attrs.font = font
        attrs.foregroundColor = color
        return attrs
    }

    /// Recursively builds an AttributedString for inline content.
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
            attrs.strikethroughStyle = Text.LineStyle(pattern: .solid)
            return attributed(strike, attrs: &attrs)

        case let code as InlineCode:
            var codeAttrs = AttributeContainer()
            codeAttrs.font = .system(size: 12.5, weight: .medium, design: .monospaced)
            codeAttrs.foregroundColor = Palette.syntaxKeyword
            codeAttrs.backgroundColor = Palette.secondary
            return AttributedString(code.code, attributes: codeAttrs)

        case let link as Markdown.Link:
            attrs.foregroundColor = Palette.primary
            attrs.underlineStyle = Text.LineStyle(pattern: .solid)
            if let dest = link.destination, let url = URL(string: dest) {
                attrs.link = url
            }
            let label = attributed(link, attrs: &attrs)
            if label == AttributedString(), let dest = link.destination {
                return AttributedString(dest, attributes: attrs)
            }
            return label

        case _ as SoftBreak, _ as LineBreak:
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

    // MARK: Code highlighting

    private func highlight(_ code: String) -> AttributedString {
        let keywordPattern = "\\b(func|var|let|if|else|for|while|return|class|struct|enum|import|guard|case|switch|public|private|internal|static|final|extension|protocol|typealias|in|do|catch|throws|try|nil|true|false|self|init|deinit|where|async|await|actor|open|fileprivate|defer|break|continue|default|fallthrough|repeat|super|lazy|mutating|override|required|convenience|infix|postfix|prefix|operator|precedencegroup|function|const|def|from|new|this|typeof|of|with|as|or|and|not|null|undefined|export|default)\\b"
        let patterns: [(NSRegularExpression, Color)] = [
            (try! NSRegularExpression(pattern: "//[^\\n]*|/\\*[\\s\\S]*?\\*/"), Palette.syntaxComment),
            (try! NSRegularExpression(pattern: "\"\"\"[\\s\\S]*?\"\"\"|'(?:\\\\.|[^'\\\\])*'|\"(?:\\\\.|[^\"\\\\])*\""), Palette.syntaxString),
            (try! NSRegularExpression(pattern: "\\b\\d+(\\.\\d+)?\\b"), Palette.syntaxNumber),
            (try! NSRegularExpression(pattern: keywordPattern), Palette.syntaxKeyword),
        ]
        let fullRange = NSRange(code.startIndex..., in: code)
        var tokens: [(NSRange, Color)] = []
        for (regex, color) in patterns {
            for match in regex.matches(in: code, range: fullRange) {
                tokens.append((match.range, color))
            }
        }
        tokens.sort { $0.0.location < $1.0.location }

        var result = AttributedString()
        var fontAttrs = AttributeContainer()
        fontAttrs.font = .system(size: 13, design: .monospaced)
        result.mergeAttributes(fontAttrs)

        var cursor = 0
        for (range, color) in tokens where range.location >= cursor {
            let start = code.index(code.startIndex, offsetBy: range.location)
            let end = code.index(start, offsetBy: range.length)
            if range.location > cursor {
                let gapEnd = code.index(code.startIndex, offsetBy: range.location)
                var plain = AttributeContainer()
                plain.foregroundColor = Palette.syntaxPlain
                result.append(AttributedString(String(code[code.index(code.startIndex, offsetBy: cursor)..<gapEnd]), attributes: plain))
            }
            var colored = AttributeContainer()
            colored.foregroundColor = color
            result.append(AttributedString(String(code[start..<end]), attributes: colored))
            cursor = range.location + range.length
        }
        if cursor < code.count {
            var plain = AttributeContainer()
            plain.foregroundColor = Palette.syntaxPlain
            result.append(AttributedString(String(code[code.index(code.startIndex, offsetBy: cursor)...]), attributes: plain))
        }
        return result
    }
}

// MARK: - Root view

struct MarkdownReaderView: View {
    let document: Document
    let builder: MarkdownViewBuilder

    init(sourceURL: URL, content: String) {
        self.document = Document(parsing: content)
        self.builder = MarkdownViewBuilder(
            baseURL: sourceURL.deletingLastPathComponent()
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ForEach(Array(document.children.enumerated()), id: \.offset) { _, child in
                    builder.blockView(child)
                }
            }
            .padding(Spacing.xxl)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Palette.background)
    }
}
