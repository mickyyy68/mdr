# mdr — Markdown Reader

A native SwiftUI renderer with a dark, muted palette: indigo accents and subtle borders. Open any file with `swift run mdr sample.md`.

## Features

- Rendered markdown in a native SwiftUI window
- Code blocks with syntax highlighting
- Tables, quotes, and nested lists
- Links open in your browser — try [swift.org](https://www.swift.org)
- Inline code like `MarkdownViewBuilder` is highlighted
- Themes: swap the palette with `--theme theme.json`

## Sample code

```swift
import SwiftUI

struct ReaderDemo: View {
    let title: String

    var body: some View {
        Text("Hello, \(title)!")
            .font(.title2.weight(.semibold))
            .foregroundColor(Color.accentColor)
    }
}
```

## Lists

- Muted background `#191A24`
- Indigo primary `#6B77FF`
- Soft borders on cards

1. Load the file
2. Parse the markdown AST
3. Render with design tokens

### Nested lists

- Block elements
  - Headings, paragraphs, and rules
- Inline styles
  - **Bold**, *italic*, ~~strikethrough~~, and `code`

## Blockquote

> Great design is invisible. The palette carries the brand.

## Design tokens

The default theme; override any value with `--theme`.

| Token           | Value     | Purpose       |
| --------------- | --------- | ------------- |
| background      | `#191A24` | App surface   |
| primary         | `#6B77FF` | Accent color  |
| foreground      | `#F2F3F5` | Primary text  |
| mutedForeground | `#9B9EAB` | Secondary text |

---

Built with `swift-markdown`, SwiftUI, and a configurable theme system.