# Quickshell Bar Refactor Plan

Prepared by Agent 1 on 2026-07-17 after reading `RESEARCH_NOTES.md` and every file currently under `/home/lucian/.config/quickshell`.

## Current Structure

- `shell.qml`: creates one `Bar` per `Quickshell.screens` entry.
- `Bar.qml`: owns `Settings`, `Theme`, and `NiriService`, creates left/center/right `BarSection` instances, and anchors `SettingsPanel`.
- `BarSection.qml`: section surface and `Repeater` over configured module ids.
- `ModuleHost.qml`: maps module ids to widget components and injects `theme`, `settings`, `niri`, and `panelWindow`.
- `Settings.qml`: JSON-backed config singleton with layout arrays, visibility, sizing, typography, polling intervals, and module label/icon helpers.
- `Theme.qml`: Stylix palette adapter with derived colors and alpha helper.
- `services/NiriService.qml`: event-stream-based source of Niri workspaces/windows/focused window state, with sync fallback after actions or stream restart.
- `SettingsPanel.qml`: popup settings surface with inline local controls for module lists, toggles, steppers, and buttons.

## Dependency Map

| File | Depends on | Provides / Notes |
| --- | --- | --- |
| `widgets/Pill.qml` | `Theme`, `Settings` | Base interactive rectangle for compact icon/text modules. Exposes active/urgent/muted/clickable state and hover feedback. |
| `widgets/Group.qml` | `Theme`, `Settings` | Older group/surface primitive with row content. Similar chrome to `BarSection`. |
| `BarSection.qml` | `Theme`, `Settings`, `NiriService`, `ModuleHost`, `panelWindow` | Section island and module layout. Must not size from `visible` or animate width on window churn. |
| `ModuleHost.qml` | `Theme`, `Settings`, optional `NiriService`, widgets directory, `panelWindow` | Module registry/resolver. Creates `Workspace`, `FocusedWindow`, metric widgets, tray, clock, settings button. |
| `SettingsPanel.qml` | `Quickshell`, `Theme`, `Settings`, `panelWindow` | Popup settings UI. Contains duplicated local `IconButton`, `ToggleRow`, `StepperRow`, `ModuleSection`, `ModuleRow`, and `AddButton`. |
| `widgets/Workspace.qml` | `Theme`, `Settings`, `NiriService`, `niri msg` commands | Workspace indicator, focus action, occupancy marker, and local new-window pulse. Correctly limits indicator movement animation to focus changes. |
| `widgets/FocusedWindow.qml` | `Theme`, `Settings`, `NiriService`, `niri msg` commands | Shows all windows on focused workspace and focuses clicked windows. App icon/name mapping is inline. |
| `widgets/Cpu.qml` | `Pill`, `Settings`, `/proc/stat` via `Process` | Polled CPU percent metric. |
| `widgets/Memory.qml` | `Pill`, `Settings`, `/proc/meminfo` via `Process` | Polled memory percent metric. |
| `widgets/Audio.qml` | `Pill`, `Settings`, Pipewire service | Event-backed default sink volume/mute display. |
| `widgets/Network.qml` | `Pill`, `Settings`, `ip -j route get` via `Process` | Polled network route/device display. |
| `widgets/Battery.qml` | `Pill`, `Settings`, UPower, `/sys/class/power_supply/BAT1` fallback | Battery percent/state display with fallback polling. |
| `widgets/Clock.qml` | `Pill`, `Settings`, `Timer` | Formatted clock. |
| `widgets/Tray.qml` | `Theme`, `Settings`, `panelWindow`, SystemTray, IconImage | Tray item row. Uses custom rectangles, not `Pill`. |
| `widgets/SettingsButton.qml` | `Pill`, `Settings` | Button module that emits `requested`. |
| `widgets/RightModules.qml` | `Group`, `Pill`, `Settings`, metric widgets, tray | Legacy/unused right-side loader path duplicating `ModuleHost` mapping. Prefer section-driven path. |

## Duplicated Logic

- Surface chrome is repeated in `BarSection.qml`, `widgets/Group.qml`, and `SettingsPanel.qml`: radius, surface color, border, antialiasing, and color animation.
- Pill-like rectangles are repeated in `Workspace.qml`, `FocusedWindow.qml`, `Tray.qml`, and several inline `SettingsPanel.qml` controls.
- Text/icon styling is repeated across nearly every widget: font family, effective font/icon sizes, muted/accent color choices, alignment.
- Module registration is duplicated between `ModuleHost.qml`, `Settings.qml` label/icon helpers, `settings.json` `availableModules`, and the legacy `widgets/RightModules.qml`.
- Polling process shape is repeated in `Cpu.qml`, `Memory.qml`, `Network.qml`, and battery fallback.
- Niri command execution and fallback `niri.sync()` are duplicated in `Workspace.qml` and `FocusedWindow.qml`.
- App id to icon/name mapping is inline in `FocusedWindow.qml`; if future widgets need app identity, this should move.

## Missing Shared Primitives

- `Surface.qml`: common rectangle for section/panel surfaces with clamped radius, border, antialiasing, and theme-derived colors.
- Expanded `Pill.qml`: add state-oriented API such as `selected`, `disabled`, `danger`, `compact`, `contentSpacing`, secondary/middle click signals, and optional tooltip text.
- `IconText.qml` or `Glyph.qml`: consistent Nerd Font optical sizing, muted/accent colors, and vertical centering.
- `IconButton.qml`: extract only when used outside `SettingsPanel`; the local version is fine until visual work needs it elsewhere.
- `MetricPill.qml`: common icon/value/warning contract for CPU, memory, battery, network, and audio while keeping data collection in each widget/service.
- `ModuleRegistry` data in `Settings.qml`: one list of entries with id, label, icon, aliases, supported sections, default visibility, and component id. `ModuleHost` can continue resolving components until the list grows.
- Motion tokens: derive `motionFast`, `motionNormal`, `motionSpatial`, and popup open/close durations from `animationMs` rather than scattering raw durations.

## Layout Bug Audit

- `ModuleHost.qml` previously used `width: visible ? loadedWidth : 0` and animated `width`. This was a sizing-from-visible risk and caused parent section/layout movement whenever a loaded widget width changed, including focused-window churn. It now sizes from `moduleVisible` directly and no longer has a width behavior.
- `BarSection.qml` previously animated `width`, so every child width change could move the center/right section. It now computes visibility from configured modules plus row content, sets width without using `visible`, and does not animate width.
- `Bar.qml` center placement still directly depends on section widths. This is fine after removing section/host width behaviors, but future visual work must avoid reintroducing width animation at this level.
- `Workspace.qml` keeps focus indicator animation gated to `reason === "focus"` and uses local pulse for new windows. Preserve that policy.
- `FocusedWindow.qml` still animates individual app pill width/entry. Agent 2 should evaluate whether this causes unacceptable section movement with title mode enabled; do not solve it by animating `BarSection`.

## Theme Resilience

- `Theme.qml` uses `JsonAdapter` defaults for all Base16 colors, so missing palette keys have sane fallbacks.
- Low-risk fix applied: palette hex values are now validated with a six-digit hex regexp before becoming QML colors. Malformed strings fall back instead of producing invalid colors.
- If `~/.config/stylix/palette.json` is missing or not yet written, current defaults should keep the bar usable. If the entire file is malformed, `FileView`/`JsonAdapter` should retain defaults; `printErrors` is currently false, so this fails quietly.
- Later improvement: expose a `paletteReady`/`paletteFallbackActive` property only for diagnostics, not for layout decisions.

## Settings-System Additions Worth Making

- Add motion tokens derived from `animationMs`: fast hover, normal color, spatial layout, popup open, popup close.
- Replace separate `availableModules`, `moduleLabel()`, and `moduleIcon()` structures with module metadata entries.
- Add settings for bar density, panel style, workspace indicator style, focused-window display mode, and possibly tray compact/expanded behavior.
- Add an advanced settings section for polling intervals and animation scale to reduce accidental performance regressions.
- Keep `settings.json` section arrays as the public layout contract for now. Defer schema migration until module metadata is ready.

## Implementation Sequence

### Agent 2: Visual/System Primitive Pass

1. Add `Surface.qml` and apply it to `BarSection.qml` and `SettingsPanel.qml`; only replace `Group.qml` if it remains used.
2. Expand `Pill.qml` state API while keeping all current properties backward compatible.
3. Move workspace/focused-window/tray pill chrome toward the shared primitive without changing their data semantics.
4. Add motion tokens in `Settings.qml` or `Theme.qml` and replace repeated raw animation durations. Keep workspace focus-only indicator animation.
5. Polish `SettingsPanel.qml` grouping and controls, but keep settings schema changes minimal.

### Agent 3: Feature Widget Pass

1. Keep `NiriService.qml` event-driven; do not introduce polling for Niri state.
2. Add optional per-module interaction contract only after `Pill.qml` supports secondary/middle actions.
3. Factor metric widgets through `MetricPill.qml` if doing feature work on CPU/memory/network/battery/audio.
4. Move app icon/name lookup from `FocusedWindow.qml` only if another widget needs it.
5. Leave `settings.json` schema migration to the merge phase unless a feature strictly requires it.

### Merge Agent

1. Reconcile any `Pill.qml`, `BarSection.qml`, `ModuleHost.qml`, and `SettingsPanel.qml` edits from Agents 1/2/3 manually; do not revert concurrent changes.
2. Remove or retire `widgets/RightModules.qml` only after confirming no import path uses it.
3. If module metadata lands, migrate `settings.json` conservatively and preserve existing user layout arrays.
4. Run JSON validation and QML lint with `.qmlls.ini` import paths if available.
5. Coordinate one Quickshell reload/log check after merge.

### Agent 4: Validation/Regression Pass

1. Test small bar heights around 24-28 px for clipping, border rings, and hover scale artifacts.
2. Test missing, malformed, and partially written Stylix palette files.
3. Test module enable/disable and left/center/right moves for empty-section behavior.
4. Test Niri workspace focus, window open/close, and focused-window title mode for layout churn.
5. Capture screenshots/logs after coordinator reload and file precise regressions for follow-up.

## Edits Already Applied By Agent 1

- `Theme.qml`: validate palette strings before converting them to colors.
- `ModuleHost.qml`: remove width-from-`visible` sizing and width animation.
- `BarSection.qml`: remove section width animation and avoid deriving width from `visible`.
