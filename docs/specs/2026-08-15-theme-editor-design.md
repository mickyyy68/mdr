# Theme Editor & Library — Design

- **Status:** Approved
- **Date:** 2026-08-15

## Goal

Rebuild the Settings page as a T3-Code-style theme experience for mdr: a live
document preview driven by the draft theme, a guided/advanced theme editor, a
small theme library (presets + your custom theme), and JSON import/export.
Adapted from T3 Code's theme settings (`pingdotgg/t3code`,
`apps/web/src/components/settings/` and `themePalette.ts`).

## Current state

- Settings (`Sources/mdr/SettingsView.swift`) is a guidance-only page.
- Design tokens are `Sendable` value structs in `MDReaderCore` (`Palette`,
  `Spacing`, `Radius`, `FontConfig`) composed into `Theme`; `ThemeOverride` is
  the partial, Codable config format; `Theme.load/merged/resolve` read
  `theme.json` (`~/.config/mdr/theme.json`, overridable via `--theme`).
- Themes apply at launch; reader windows capture an immutable `Theme`.

## Decisions (agreed with the user)

1. **Everything**: editor (guided + advanced), split live preview, theme library
   with cards, JSON import/export — built in phases.
2. **Split preview**: Settings is a split view — the open document renders with
   the draft theme on one side, editor controls on the other.
3. **Persistence**: a single `theme.json` remains the source of truth. Save
   writes the draft and applies it immediately. Launched via `--theme`, save
   writes back to that file instead of the default path.
4. **Custom color picker**: swatch trigger + hex field + SV/hue picker in a
   popover, T3-style.
5. **Guided mode**: derives the whole palette from Background + Accent via a
   testable OKLCH derivation in `MDReaderCore`.
6. **Advanced mode**: all colors (grouped into sections) plus fonts, spacing,
   and radius.
7. **Library model** (single-file constraint): built-in **preset** cards + one
   **Custom** card backed by `theme.json`. No multi-theme storage folder.
8. **AGENTS.md is updated as part of this work**: the reader/editor and
   dark-only lines are amended to reflect that mdr is a reader of documents with
   configurable appearance (dark-first; no appearance-mode switching).

## Review resolutions

Three reviewers audited this design against the codebase and the T3 reference.
Resolutions incorporated below: import gets a public data-validation API
(`Theme.merged(withData:)`); source-file resolution moves into core
(`Theme.resolveWithSource`); file I/O moves into a testable core
`ThemePersistence`; `SettingsView` is `@MainActor`; `ThemeStore.sourceURL` is
`var`; `ThemeError` gains `writeFailed` and `unsupportedFormat`; apply/import
write immediately while Edit stages a draft; back-from-editor discards (with
confirmation); Reset never deletes an explicit `--theme` file and always
confirms; foreign-format JSON is rejected instead of silently becoming Linear;
phases were re-ordered so Phase 2 ships the editor directly.

## Architecture

### `MDReaderCore` (pure logic, all additions testable)

**`ColorDerivation.swift` (create).**
- `Color.hexString` — sRGB → `#RRGGBB` via `NSColor(color).usingColorSpace(.sRGB)`
  and `lround` (byte-exact; deterministic regardless of display).
- Internal OKLCH ↔ sRGB conversions.
- `PaletteDerivation.derive(background:accent:) -> Palette`: complete 19-role
  palette from two seeds. Lightness polarity is detected from the background
  (`> 0.55` → light: dark text; else dark: light text). Surfaces climb a
  lightness ramp off the background; every text role is contrast-solved against
  its own surface (≥ 4.5 where applicable); `primary` is the accent
  (lightness-adjusted for contrast); `accentForeground` is black/white by accent
  luminance; `destructive` is a fixed red; syntax colors derive from the accent
  hue (keyword = accent, string = lighter accent, comment = muted, number =
  amber, type = accent-tinted, plain = foreground). Spacing/radius/fonts keep
  Linear defaults.

**`Theme.swift` (modify).**
- `ThemeOverride(theme:)` — serialize a resolved `Theme` back to a full
  (all-keys) override; round-trips resolved values exactly.
- `Theme.merged(withData: Data, label: String) throws -> Theme` — public,
  file-less decode/validate path for paste-import; reuses the existing private
  `decode` mapping; `label` feeds error paths (e.g. `"pasted JSON"`).
- `Theme.resolveWithSource(explicit:defaultFile:) -> (theme: Theme, source: URL?)`
  — resolves precedence (explicit flag → default file if present → defaults)
  and reports which file produced the theme (or `nil`). `resolve` delegates to
  it so the executable never duplicates `fileExists` logic.
- `Theme.preset(_:)` + `ThemePreset` — a plain `Sendable, CaseIterable` enum
  (`linear`, `midnight`, `forest`, `ember`) with a computed `theme` property
  (no associated values, so `allCases` synthesizes for the library grid).
  Presets are resolved `Theme`s stored as `static let` (Sendable → concurrency
  safe). Pinned seeds: `midnight` = background `#0B0E14` / accent `#7C3AED`;
  `forest` = `#0A0F0D` / `#34D399`; `ember` = `#120C0A` / `#F97316`. `linear`
  is the canonical defaults.
- `ThemeError` — add `writeFailed(path: String, underlying: String)` and
  `unsupportedFormat`. Keep existing cases unchanged (`fileNotFound`,
  `invalidJSON`, `invalidColor`, `invalidValue`).

**`ThemePersistence.swift` (create).** `save(_ theme: Theme, to url: URL)` —
create parent directories, write pretty JSON of `ThemeOverride(theme:)`
atomically; `delete(at url: URL)`. Both throw `ThemeError.writeFailed`.
Moved into core so save/reset/export serialization is unit-testable
(`mdrTests` cannot import the executable).

### Executable (`Sources/mdr/`)

**`ThemeStore.swift` (create).** `@MainActor final class ThemeStore:
ObservableObject` with `@Published var theme: Theme` and `var sourceURL: URL?`
(mutable — updated to the written path after the first Save). One instance per
process, built by `MDReaderApp` from `Theme.resolveWithSource`.

**`MDReaderApp.swift` (modify).** Build the `ThemeStore` from
`resolveWithSource` and pass it to `runReader`/`AppDelegate`. Theme load
failures at launch remain fatal (current behavior).

**`AppDelegate.swift` (modify).** Own the store; pass it to every `ReaderView`;
subscribe to store changes and update each window's `backgroundColor` so the
chrome follows the theme.

**`ReaderView.swift` (modify).** `@MainActor`; observe the store via
`@ObservedObject`; render `MarkdownReaderView(document:theme: store.theme)`;
pass the store + window document into `SettingsView`.

**`SettingsView.swift` (rewrite; `@MainActor`).** Two-level navigation
`library → editor → (back) → library → (back) → document`. Top bar: circular
back button (pops one level), and a **Save** button + transient status line
("Saved to …") when in the editor.

- **Library** — intro line; preset **cards** (each with a preview ball built
  from `background`, `card`, `secondary`, `primary`, `syntaxKeyword`, `border`;
  single dark ball) and the **Custom** card (active theme) with Edit, Export
  (copy JSON), Reset (with confirmation; no-op if no file; never deletes an
  explicit `--theme` file — reverts the session to Linear instead), Reveal in
  Finder (targets `sourceURL ?? default`, disabled when missing), and an
  **Import** button. A subtle footer keeps the AI-assistant hint.
- **Semantics**: clicking **Apply** on a preset writes its resolved override to
  `sourceURL ?? default` and updates the store immediately. **Edit** on any card
  opens the editor seeded with that theme as a draft (the preset-Edit path is
  the "duplicate" affordance — no write until Save). **Import** validates and
  writes immediately on success.
- **Editor** — split view: left is the live `MarkdownReaderView` rendered with
  the draft; right is a scrollable control column. **Default mode**: advanced
  when a config file exists at `sourceURL`, else guided. **Guided**: Background
  + Accent fields; any change regenerates the palette via `PaletteDerivation`.
  **Advanced**: colors grouped into sections (Surfaces, Brand & content,
  Syntax, Borders — purely visual grouping; each role edits independently),
  then **Fonts** (family + the named size roles **including `lineSpacing`**),
  **Spacing**, and **Radius** as validated numeric fields. Switching to guided
  regenerates the palette from the draft's background + accent (documented).
- **Live preview**: updates on every change; intermediate invalid text keeps
  the last valid value; hex fields accept only `#RRGGBB`; numeric fields show an
  inline validation message (reusing `ThemeError.invalidValue` text) and block
  Save until valid; font family is validated against `NSFont(name:)` on Save
  with an inline warning (fallback remains documented behavior).
- **Draft lifecycle**: back-from-editor discards the draft (confirmation dialog
  when there are unsaved changes); reopening the editor re-seeds from
  `store.theme`. The reader document behind Settings always shows `store.theme`.
  Drafts are per-window and isolated; a Save from any window applies globally
  (other open editors may hold stale drafts — accepted for a small app).
- **Color picker** — reusable `ColorPickerField` (label + swatch + hex) opening
  a popover `ColorPickerPanel` (SV plane, hue bar, hex field).

**`ThemeImportView.swift` (create).** Paste-`ThemeOverride`-JSON dialog:
state resets on open; Add disabled when empty; validates via
`Theme.merged(withData:label:)`; shows the resulting `ThemeError` inline
(dismissible). Foreign-format JSON (no known top-level keys, or T3/VS Code
shapes) is rejected with `ThemeError.unsupportedFormat`.

## Data flow

- Open → `ThemeStore` built from `resolveWithSource`.
- Edit → `draft` (a `Theme` copy) mutated by the editor → left pane renders
  `draft` live.
- Save → `ThemeOverride(draft)` encoded → `ThemePersistence.save` to
  `sourceURL ?? CLI.defaultThemePath` → `sourceURL` updated → store applied →
  pop to library + "Saved" status.
- Apply preset / Import → validate → `ThemePersistence.save` → store applied
  immediately.
- Reset → confirm → if source is the default path, `ThemePersistence.delete`;
  always revert the session to `.linear`. Under `--theme`, the file is never
  deleted.
- Export → `ThemeOverride(store.theme)` JSON copied to the pasteboard.

## Error handling

Editor/import/save errors reuse `ThemeError` (`mdr:`-prefixed `LocalizedError`)
and render inline as red text in the settings page; they do not exit the
process. I/O failures (save, delete, directory creation) surface
`ThemeError.writeFailed`. This is a deliberate, documented divergence from
AGENTS.md's stderr/exit rule for interactive settings.

## Testing

- `ColorDerivationTests` — OKLCH round-trip; derivation determinism; contrast
  ≥ 4.5 for every text role against its own surface; extreme seeds (near-black,
  near-white, zero-chroma backgrounds) produce finite, readable palettes.
- `ThemePresetTests` — presets resolve, are distinct, and survive
  serialize→load→merge unchanged; `ThemePreset.allCases` ordering.
- `ThemeSerializationTests` — `ThemeOverride(theme:)` round-trips through
  `load`/`merged`; and `ThemeOverride(theme: .linear)` decodes equal to
  `Theme.defaultConfigData()` (guards `hexString` drift; `defaultConfigData`
  stays as the bootstrap/test API).
- `ThemePersistenceTests` — save creates parent dirs, writes round-trippable
  JSON; save/delete failures throw `writeFailed`.
- `ThemeImportTests` — `merged(withData:)` accepts valid override JSON; rejects
  malformed JSON, invalid values, and foreign-format JSON (`unsupportedFormat`).
- Existing suites stay green; build stays warning-free.

## Acceptance criteria

- **Phase 2**: opening Settings shows the editor shell; changing
  Background/Accent regenerates the palette and the left preview updates;
  every advanced role/font/spacing/radius field round-trips Save→relaunch
  unchanged; Save writes atomically and all open windows re-render; back from
  the editor with unsaved changes prompts; editing then quitting without Save
  leaves `theme.json` untouched.
- **Phase 3**: clicking a preset updates the Custom card, persists, re-renders;
  Reset confirms and (default path) deletes then reverts to Linear; under
  `--theme` Reset never deletes the file; Export copies valid round-trippable
  JSON; malformed/foreign pasted JSON shows the inline error; two-window case:
  Save in one window updates the other window's document on return.

## Phases

1. **Core**: `ColorDerivation`, `PaletteDerivation`, `ThemeOverride(theme:)`,
   `merged(withData:)`, `resolveWithSource`, `ThemePreset`, `ThemePersistence`,
   `ThemeError` additions + tests.
2. **Editor + live preview**: `ThemeStore`; `MDReaderApp`/`AppDelegate`/
   `ReaderView` wiring; `SettingsView` becomes the editor directly (guided/
   advanced, custom color picker, Save/apply, draft lifecycle + confirmation,
   status line, inline errors).
3. **Library + import/export**: library landing (preset + custom cards, preview
   balls, Apply/Edit/Reset/Reveal, reset confirmation), import dialog, export,
   AGENTS.md update.

## Non-goals

- No System/Light/Dark appearance tiles or runtime theme-switching mode; mdr is
  dark-first (a theme may itself be light).
- No multi-theme storage folder; one `theme.json` + presets.
- No VS Code theme import, no drag-and-drop, no marketplace/theme search, no
  usage inspector.
- No live file watching; reloading happens at launch or on explicit Save.
- The theme editor edits appearance only — it is not a document editor.