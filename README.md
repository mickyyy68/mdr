# mdr — Markdown Reader

A simple CLI tool that opens a native SwiftUI window rendering one or more
markdown files, with a dark, Linear-inspired design system and configurable
themes. See `AGENTS.md` for architecture and commands.

## Bundle

`mdr` is a bare executable, not an `.app` bundle: it ships no resources
(no images, fonts, or assets — SF Symbols and system fonts only), so the
single binary is the entire distribution.

| Artifact | Size |
|---|---|
| Release binary (`swift build -c release`) | 4.1 MB (arm64 Mach-O) |
| Debug binary | 6.2 MB |
| After `strip -x` | 1.9 MB — invalidates the code signature; re-sign with `codesign` before distributing |
| Universal (arm64 + x86_64) | roughly double; release builds are arm64-only |

Linkage: system frameworks only (AppKit, SwiftUI, Foundation, Combine,
CoreFoundation) plus the `/usr/lib/swift` runtime. `swift-markdown` is
statically linked; no third-party runtime dependencies.

## Performance

Measured on arm64 macOS with a release build (`/usr/bin/time -l`, `ps`).

| Scenario | RSS |
|---|---|
| 1 window, peak | 94.2 MB |
| 1 window, 3s → 6s | 96.2 → 96.1 MB (stable) |
| 3 windows | ~157 MB (~31 MB per extra window) |

The baseline is the cost of a bare AppKit/SwiftUI window; the per-window
cost dominates. Parsing and rendering run synchronously on the main thread
(a known limitation — fine for typical files, very large files will lag),
so RSS can spike transiently for very large documents. Settings/theme-editor
delta was not measured (UI automation blocked); it is a lightweight overlay
on the existing window and should be small.
