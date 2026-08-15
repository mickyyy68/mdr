# Theme Settings — Design

- **Status:** Superseded
- **Date:** 2026-08-15
- **Superseded by:** the implemented in-app theme experience (see the "Theme
  Editor & Library — Design" spec and `Sources/mdr/SettingsView.swift`). The
  guidance-only Settings window with read-only JSON preview and "Create Config" /
  "Reveal in Finder" actions was replaced by a live appearance section (Color
  scheme tiles, theme library) with a guided/advanced floating editor and JSON
  import/export. Still in force: `theme.json` remains the single source of
  truth loaded at launch via `--theme`, partial overrides merge on top of
  Linear defaults, all tokens are configurable, and invalid configs print an
  `mdr:` error and exit nonzero.

## Goal

Let users customize the design system (colors, fonts, spacing, radius) through a
JSON config file, and provide a lightweight in-app Settings window (Cmd-,) that
guides the user to have an AI coding assistant read and edit that config file.

## Current state

All design tokens are static namespaces in `Sources/MDReaderCore/DesignSystem.swift`:
`Palette` (20 colors), `Spacing` (6 values), `Radius` (3 values), and `Fonts`
(Inter-with-system-fallback helper). They are referenced in ~50 places across
`MarkdownRenderer.swift`, `CodeHighlighter.swift`, and `Sources/mdr/AppDelegate.swift`.
There is no persistence layer and no runtime theme.

## Decisions (agreed with the user)

1. **Delivery:** JSON config file is the source of truth; a `--theme <path>` CLI
   flag points at it. An in-app Settings window is informational, not an editor:
   it tells the user they can ask an LLM to read and edit the config file.
2. **Default location:** `~/.config/mdr/theme.json` is auto-loaded when present;
   an explicit `--theme` overrides it.
3. **Override model:** partial overrides merge on top of Linear defaults.
4. **Scope:** all tokens are configurable — every color, font family and text
   size, spacing, radius.
5. **Validation:** an invalid config file prints an `mdr:` error and exits
   nonzero (existing error convention).
6. **Settings window contents:** guidance text + config path + read-only JSON
   preview + "Create Config" / "Reveal in Finder" actions. "Create Config" writes
   a full default theme file so an assistant has something to edit.
7. **Timing:** config is read at launch; changes apply on the next launch. No
   live reload or file watching.

## Config file schema

`theme.json` uses a flat, permissive shape. Every key is optional.

```json
{
  "palette": {
    "background": "#191A24",
    "foreground": "#FFFFFF",
    "card": "#1F202D",
    "cardForeground": "#F8FAFC",
    "secondary": "#272A3A",
    "secondaryForeground": "#868798",
    "muted": "#1F202D",
    "mutedForeground": "#9B9EAB",
    "accent": "#31323F",
    "accentForeground": "#F8FAFC",
    "primary": "#6B77FF",
    "destructive": "#7F1D1D",
    "border": "#38394C",
    "syntaxKeyword": "#6B77FF",
    "syntaxString": "#A5B4FC",
    "syntaxComment": "#6B7280",
    "syntaxType": "#8B93E7",
    "syntaxNumber": "#FBBF24",
    "syntaxPlain": "#E5E7EB"
  },
  "spacing": { "xs": 4, "sm": 8, "md": 12, "lg": 16, "xl": 24, "xxl": 32 },
  "radius": { "sm": 4, "md": 6, "lg": 8 },
  "fonts": {
    "family": "Inter",
    "heading1": 26, "heading2": 20, "heading3": 17, "heading4": 15,
    "heading5": 14, "body": 15, "caption": 13, "code": 13, "inlineCode": 12.5,
    "label": 11, "lineSpacing": 3
  }
}
```

Colors are `#RRGGBB` hex strings. Unknown keys are ignored (forward-compatible
with future additions); invalid values are rejected.

## Architecture

### `MDReaderCore`

**`DesignSystem.swift` (modify).** Convert `Palette`, `Spacing`, `Radius` from
static enums to value-type structs (instance properties) with a `static let
linear` default each. Replace the `Fonts` namespace with a `FontConfig` struct
holding `family: String?` plus the named size roles above (heading levels 1–5,
`body`, `caption`, `code`, `inlineCode`, `label`, `lineSpacing`) and a
`font(size:weight:) -> Font` method. Family resolution: `nil` or `"Inter"` keeps
the existing per-weight Inter name mapping with system fallback; any other
family uses `.custom(family, size:).weight(weight)` when that font is installed,
else the system font. Keep the `Color(hex:)` extension as-is.

**`Theme.swift` (create).**
- `Theme` struct: `palette`, `spacing`, `radius`, `fonts`, plus
  `static let linear` (all four `.linear` defaults).
- `ThemeOverride` (`Codable`): optional `palette`/`spacing`/`radius`/`fonts`
  subsections with optional fields (hex strings, `CGFloat`s, family string).
- `Theme.load(from url: URL) throws -> Theme`: decode an override, validate,
  merge over `.linear`.
- `Theme.resolve(explicit: URL?, defaultFile: URL?) throws -> Theme`: precedence
  explicit flag → default file (only if it exists) → Linear defaults.
- `Theme.defaultConfigData() throws -> Data`: pretty-printed JSON of a full
  Linear-default override, used by "Create Config".
- `ThemeError` (`LocalizedError`, `mdr:` prefix): `fileNotFound`,
  `invalidJSON`, `invalidColor(key, value)`, `invalidValue(key, value)`.

Precedent for placement: pure, testable logic in `MDReaderCore` per AGENTS.md;
loading/validation mirrors `DocumentLoader.swift`.

**`CLI.swift` (modify).** Change `Command.readFiles([String])` to
`readFiles([String], themePath: String?)`. Parse `-t`/`--theme <path>`, consuming
the following argument; `--theme` with no value throws
`CLIError.missingValue("--theme")` → `mdr: option '--theme' requires a path`.
Add `CLI.defaultThemePath: URL` (`~/.config/mdr/theme.json`).

**`CodeHighlighter.swift` (modify).** `color(for:palette:)` and
`highlight(_:palette:)` take a `Palette` instead of reading static syntax colors.

**`MarkdownRenderer.swift` (modify).** `MarkdownViewBuilder` takes a `theme:
Theme` in its `init(baseURL:theme:)`; `MarkdownReaderView` takes
`init(document:theme:)`. Replace every static token reference with the
corresponding `theme.palette.*`, `theme.spacing.*`, `theme.radius.*`, and
`theme.fonts.font(...)` call (including the `CodeHighlighter.highlight` call and
the inline-code and code-block font sizes).

### Executable (`Sources/mdr/`)

**`MDReaderApp.swift` (modify).** After CLI parsing, for `.readFiles` resolve the
theme via `Theme.resolve(explicit:defaultFile:)`, handling `ThemeError` with the
existing stderr + nonzero-exit pattern. Pass the theme into `runReader`.

**`AppDelegate.swift` (modify).** Accept the resolved `theme`; use
`theme.palette.background` for window backgrounds; add a "Settings…" item (⌘,)
to the app menu and wire it to open the settings window.

**`SettingsView.swift` (create).** A small SwiftUI view hosted in an `NSWindow`
created lazily by `AppDelegate`. Displays:
- guidance text explaining the LLM workflow (read the config, edit tokens, apply
  on next launch);
- the resolved config file path;
- a read-only, monospaced JSON preview of the config file (placeholder when none
  exists);
- "Create Config" (writes `Theme.defaultConfigData()` to the path, then
  refreshes) and "Reveal in Finder" (`NSWorkspace.activateFileViewerSelecting`).

AppKit/UI glue stays in the executable, consistent with AGENTS.md.

## Usage example

```bash
mdr --theme ~/my-theme.json doc.md       # explicit theme
mdr doc.md                               # auto-loads ~/.config/mdr/theme.json if present
```

Partial `~/my-theme.json`:

```json
{
  "palette": { "primary": "#7C3AED", "background": "#0B0E14" },
  "fonts": { "family": "SF Mono", "body": 16 }
}
```

Unspecified tokens keep Linear defaults. Cmd-, opens Settings, which surfaces the
same path and guidance for the AI-assistant workflow.

## Error behavior

| Case | Message (stderr) | Exit |
| --- | --- | --- |
| `--theme` missing value | `mdr: option '--theme' requires a path` | 1 |
| Theme file not found | `mdr: cannot read theme '<path>'` | 1 |
| Malformed JSON | `mdr: invalid theme JSON in '<path>'` | 1 |
| Bad color string | `mdr: invalid color '<value>' for palette.<key> in '<path>'` | 1 |
| Non-numeric spacing/radius/size | `mdr: invalid value '<value>' for <key> in '<path>'` | 1 |

`--help` and `--version` short-circuit before theme resolution, so they never
fail on a bad config.

## Testing

- `Tests/mdrTests/ThemeTests.swift` (create): full/partial overrides merge
  correctly; every invalid-value case throws `ThemeError`; `resolve` precedence
  (explicit flag wins, default file only when it exists); `defaultConfigData`
  round-trips through `Theme.load`.
- `Tests/mdrTests/CLIArgumentParserTests.swift` (modify): `--theme`/`-t` parsing,
  flag-then-files ordering, missing-value error.
- `Tests/mdrTests/CodeHighlighterTests.swift` (modify): reference
  `Palette.linear.syntax*` for expected colors.
- Build stays warning-free; full `swift test` suite passes.

## Non-goals

- No live reload or file watching; config applies at next launch.
- No in-app color pickers or token editors — the Settings window is guidance only.
- No per-document themes; one theme for the session.
- No theme-switching UI, no bundled theme presets.