# AGENTS.md

Guidance for AI agents working in this repository.

## Project overview

**mdr** ("Markdown Reader") is a simple CLI tool that opens a native SwiftUI
window rendering a markdown file. It reads one or more markdown files from disk
and displays them with a dark design system inspired by Linear's design tokens.

The app is deliberately small: it renders markdown, nothing more. Appearance is
configurable (design tokens, themes) — document content is not editable.

## Commands

```bash
swift build               # build the project
swift test                # run the swift-testing suite
swift run mdr file.md     # open file.md in the reader (one or more files)
swift run mdr --help      # usage; --version prints the version
swift run mdr --theme theme.json file.md   # load design tokens from a JSON config
```

## Architecture

Two targets with a single dependency direction:
`mdr` (executable) → `MDReaderCore` (library) → `swift-markdown`.

- `Sources/MDReaderCore/` — pure, testable logic exposed through a public API:
  - `DesignSystem.swift` — `Palette`, `Spacing`, `Radius`, `FontConfig` (Linear-sourced tokens)
  - `Theme.swift` — config-driven design tokens (`Theme`, `ThemeOverride`, `ThemeError`; `--theme` JSON overrides Linear defaults)
  - `ColorDerivation.swift` — OKLCH color math and `PaletteDerivation` (guided two-color derivation)
  - `ThemePersistence.swift` — theme config file save/delete/export
  - `FontFamilyCatalog.swift` — curated font-family options for the editor
  - `PaletteRoles.swift` — advanced editor token roles (`PaletteRole`, `PaletteRoleGroup`)
  - `CLI.swift` — argument parsing (`Command`, `CLIError`)
  - `DocumentLoader.swift` — file loading with UTF-8/16/Latin-1 fallback
  - `CodeHighlighter.swift` — scanner-based code tokenizer
  - `MarkdownRenderer.swift` — markdown AST → SwiftUI views (`MarkdownViewBuilder`, `MarkdownReaderView`)
- `Sources/mdr/` — thin app shell: `MDReaderApp.swift` (`@main` entry point), `AppDelegate.swift` (windows, main menu, appearance mode), `ThemeStore.swift` (session theme + appearance mode), `ReaderView.swift` (window root), `ReaderViewModel.swift` (settings/import presentation), `SettingsView.swift` (page shell: mode tiles, theme grid, editor overlay), `ThemeEditorPanel.swift` (floating draggable editor), `ThemeLibraryCard.swift` (library cards), `ThemePreviewViews.swift` (preview balls and wireframes), `ColorPicker.swift` (token fields + picker popover), `ThemeImportView.swift` (paste-JSON import), `OutlinedButton.swift` (shared bordered action button)
- `Tests/mdrTests/` — swift-testing unit tests for core logic

Dependency rule: pure logic belongs in `MDReaderCore`; AppKit/UI glue belongs in
the executable. Anything the executable must call is declared `public` on the
core; everything else stays `internal`.

## Documentation

- `AGENTS.md` is the source of truth for architecture, commands, conventions,
  and known limitations. Any change that affects those updates `AGENTS.md` as
  part of the same change — no separate ask required. The guardrail "Do not
  create documentation files unless asked" covers creating new files; it does
  not excuse leaving this one stale.
- `docs/specs/` designs stay consistent with the code: a change that
  contradicts an approved spec updates or supersedes the spec in the same
  change.
- `docs/bugs/` notes are dated, point-in-time records: they are never swept
  or retroactively edited by this rule. Add a note only when asked to
  document a bug.

## Conventions and guardrails (strict)

- Swift 6 with strict concurrency. The build must stay warning-free.
- Run `swift test` before finishing work; the suite must pass.
- Follow existing style: enums as namespaces, switch-based dispatch, explicit
  access modifiers, minimal comments.
- Keep the executable thin. New logic goes into `MDReaderCore` with tests.
- No scope creep: mdr is a reader, not a document editor. It does not edit
  markdown content; appearance configuration (the theme editor in Settings) is
  in scope. Do not add unrequested features, options, or infrastructure.
- Match the existing design system when extending UI; keep the dark, Linear-based look.
- Errors are `LocalizedError`, reported to stderr with an `mdr:` prefix, exiting
  nonzero on failure. Interactive settings errors render inline instead of
  exiting — that divergence is deliberate.
- Only commit when asked. Do not create documentation files (README, etc.)
  unless asked. No emojis.

## Maintenance

- `swift-markdown` is pinned to `exact: 0.8.0`. Upgrading it is a deliberate act
  and should land as its own change with a full `swift test` run.
- `Package.resolved` is committed and is the build source of truth.
- Bug notes and known issues live in `docs/bugs/` (dated files, same
  convention as `docs/specs/`).
- Known limitations and non-goals:
  - Parsing and rendering run synchronously on the main thread; fine for typical
    files, but very large files will lag.
  - Images load synchronously from disk or URL.
  - Dark-first design. Appearance-mode switching (System/Light/Dark) is
    supported and persists; themes can ship both light and dark palettes.
  - No editing, search, or table-of-contents features.