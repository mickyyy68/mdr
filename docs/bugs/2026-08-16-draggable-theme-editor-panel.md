# Draggable theme editor panel janks during drag

Status: **open**

## Symptom

Dragging the theme editor panel (Settings → Create theme / Edit theme) by its
header is not fluid: the panel moves a pixel at a time, lags the cursor, and
can flash/flicker while in motion. Dragging is usable but visibly janky on
retina displays.

## Reproduction

1. `swift run mdr sample.md`
2. Open Settings (gears button or Cmd-,).
3. Click Create theme to open the floating editor panel.
4. Drag the panel header around the window; observe the stepped motion and
   occasional flicker. The effect is strongest in Advanced mode (many color
   rows) and on slow drags near the window edges.

## Environment

- macOS 13+ (observed on macOS 26), Swift 6, SwiftUI.
- Not reproducible in code review: requires interactive drag testing.

## Root-cause analysis so far

The drag went through three implementations, none fully smooth:

1. `dragOffset` as `@State` on `SettingsView`; every drag frame re-rendered the
   whole settings page (wireframe tiles, the LazyVGrid of gradient preview
   balls) — page-wide jank. Fixed by moving the offset into
   `ThemeEditorPanel`.
2. Panel-local `@State` + `DragGesture().onChanged` (default 10pt minimum
   distance). The 10pt recognition threshold caused a dead zone followed by a
   jump; each `.onChanged` state write re-evaluated the panel body per tick.
3. Current: `@GestureState` live delta + `@State` settled offset with
   `DragGesture(minimumDistance: 1)` (see `combinedOffset`, the header
   gesture, and `clamped` in `Sources/mdr/ThemeEditorPanel.swift`). Tracking
   from the first pixel works, but movement is still steppy and can flash.

Remaining hypotheses:

- The panel body re-evaluates per drag tick even with `@GestureState`; the
  body includes heavyweight SwiftUI controls (Menu, `FocusState` text fields,
  ~30 color rows in Advanced mode) whose re-creation per frame can drop below
  60 fps on slower GPUs.
- The `.shadow(color: .black.opacity(0.35), radius: 24, y: 8)` on the moving
  view is re-rasterized every frame; 24pt blur on a 416pt-wide view is costly
  and a plausible source of the flicker.
- A possible SwiftUI-on-macOS compositing artifact when `.offset` moves a
  view with a large blur shadow inside a `GeometryReader`/`ZStack`.

## Candidate fixes (not yet tried)

- Rasterize the panel content once and move the layer: `.drawingGroup()`
  inside the offset wrapper while dragging (watch for blurred text on scaled
  displays).
- Replace `DragGesture` with an `NSEvent.addLocalMonitorForEvents`-driven
  position while a header mouse-down is active (AppKit-grade tracking).
- Host the panel in its own transparent `NSWindow` overlay so SwiftUI never
  re-lays out the page during the drag.
- Shrink or drop the drag-time shadow (e.g. shadow only at rest, or smaller
  radius while dragging) to remove the per-frame rasterization cost.

## Related code

- `Sources/mdr/ThemeEditorPanel.swift` — `combinedOffset`, header
  `DragGesture`, `clamped`.
- `Sources/mdr/SettingsView.swift` — panel placement in the settings
  `GeometryReader`/`ZStack`, `bodyMaxHeight` clamp input.
