# AGENTS.md

Guidance for AI agents working in this repository.

## Project overview

**mdr** ("Markdown Reader") is a simple CLI tool that opens a native SwiftUI
window rendering a markdown file. It reads one or more markdown files from disk
and displays them with a dark design system inspired by Linear's design tokens.

The app is deliberately small: it renders markdown, nothing more.

## Commands

```bash
swift build               # build the project
swift test                # run the swift-testing suite
swift run mdr file.md     # open file.md in the reader (one or more files)
swift run mdr --help      # usage; --version prints the version
```

## Architecture

Two targets with a single dependency direction:
`mdr` (executable) → `MDReaderCore` (library) → `swift-markdown`.

- `Sources/MDReaderCore/` — pure, testable logic exposed through a public API:
  - `DesignSystem.swift` — `Palette`, `Spacing`, `Radius`, `Fonts` (Linear-sourced tokens)
  - `CLI.swift` — argument parsing (`Command`, `CLIError`)
  - `DocumentLoader.swift` — file loading with UTF-8/16/Latin-1 fallback
  - `CodeHighlighter.swift` — scanner-based code tokenizer
  - `MarkdownRenderer.swift` — markdown AST → SwiftUI views (`MarkdownViewBuilder`, `MarkdownReaderView`)
- `Sources/mdr/` — thin app shell: `MDReaderApp.swift` (`@main` entry point), `AppDelegate.swift` (windows, main menu)
- `Tests/mdrTests/` — swift-testing unit tests for core logic

Dependency rule: pure logic belongs in `MDReaderCore`; AppKit/UI glue belongs in
the executable. Anything the executable must call is declared `public` on the
core; everything else stays `internal`.

## Conventions and guardrails (strict)

- Swift 6 with strict concurrency. The build must stay warning-free.
- Run `swift test` before finishing work; the suite must pass.
- Follow existing style: enums as namespaces, switch-based dispatch, explicit
  access modifiers, minimal comments.
- Keep the executable thin. New logic goes into `MDReaderCore` with tests.
- No scope creep: mdr is a reader, not an editor. Do not add unrequested
  features, options, or infrastructure.
- Match the existing design system when extending UI; keep the dark, Linear-based look.
- Errors are `LocalizedError`, reported to stderr with an `mdr:` prefix, exiting
  nonzero on failure.
- Only commit when asked. Do not create documentation files (README, etc.)
  unless asked. No emojis.

## Maintenance

- `swift-markdown` is pinned to `exact: 0.8.0`. Upgrading it is a deliberate act
  and should land as its own change with a full `swift test` run.
- `Package.resolved` is committed and is the build source of truth.
- Known limitations and non-goals:
  - Parsing and rendering run synchronously on the main thread; fine for typical
    files, but very large files will lag.
  - Images load synchronously from disk or URL.
  - Dark theme only; no theme switching.
  - No editing, search, or table-of-contents features.