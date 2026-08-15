# Linear Design Markdown Reader

A markdown reader with a *Linear-inspired* dark palette — muted navy surfaces, an indigo **accent**, and subtle borders.

## Features

- Rendered markdown in a native SwiftUI window
- Code blocks with **syntax highlighting**
- Tables, quotes, and nested lists
- Clickable links — `https://linear.app` opens in your browser
- Inline code like `mdreader sample.md` is highlighted

## Sample Code

```swift
import SwiftUI

struct Sample: View {
    let title: String

    var body: some View {
        // Greeting message
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

1. Read the file
2. Parse the markdown
3. Render with Linear tokens

## Blockquote

> Great design is invisible. The palette carries the brand.

## Table

| Token        | Value      | Purpose      |
| ------------ | ---------- | ------------ |
| background   | `#191A24`  | App surface  |
| primary      | `#6B77FF`  | Accent color |
| mutedForeground | `#9B9EAB` | Secondary text |

---

Built with swift-markdown, SwiftUI, and the Linear design system.
