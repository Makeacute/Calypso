# Calypso Session Report

Date: 2026-07-18

## Files Changed

- `Theme.qml`
- `Settings.qml`
- `settings.json`
- `palette.json`
- `Bar.qml`
- `BarSection.qml`
- `ModuleHost.qml`
- `Surface.qml`
- `SettingsPanel.qml`
- `ModuleDetailsPanel.qml`
- `ClockPanel.qml`
- `ControlCenterPanel.qml`
- `services/CompositorService.qml`
- `services/NiriService.qml`
- `services/WallpaperService.qml`
- `widgets/Audio.qml`
- `widgets/Battery.qml`
- `widgets/BluetoothStatus.qml`
- `widgets/Brightness.qml`
- `widgets/Caffeine.qml`
- `widgets/Clock.qml`
- `widgets/Cpu.qml`
- `widgets/FocusedWindow.qml`
- `widgets/Group.qml`
- `widgets/Media.qml`
- `widgets/Memory.qml`
- `widgets/Network.qml`
- `widgets/Osd.qml`
- `widgets/Pill.qml`
- `widgets/PowerProfile.qml`
- `widgets/SettingsButton.qml`
- `widgets/TooltipHost.qml`
- `widgets/Tray.qml`
- `widgets/Workspace.qml`
- `widgets/WorkspaceToast.qml`
- `README.md`
- `NEW_WIDGETS_SCHEMA.md`

## Features Added

- Added global motion, spacing, radius, opacity, widget, popup, OSD, wallpaper, Matugen, tooltip, autohide, and module registry settings.
- Added robust theme fallbacks so `palette.json` can be missing or malformed without breaking the bar.
- Added live bar styles: islands, solid, and pill.
- Added live bar top/bottom positioning.
- Added live module order controls for left, center, and right sections.
- Added widget display modes: icon only, icon and text, expanded.
- Rebuilt the settings panel into a multi-page customization app with sidebar search, detail pages, return button, preview selectors, sliders, toggles, and module controls.
- Added configurable settings panel anchoring.
- Added redesigned module detail popups for audio, network, battery, CPU, and memory.
- Added hardware OSD for volume, mute, brightness, keyboard, media, and battery events.
- Removed wallpaper and workspace from the OSD path. Workspace feedback now uses its own toast; wallpaper state is persistent status in the settings UI.
- Added function-key volume OSD through PipeWire default sink change tracking.
- Added wallpaper selector with recursive scanning, favorites, random apply, transition controls, and `awww` backend.
- Added Matugen palette generation from the selected wallpaper and live reload through `Theme.qml`.
- Added `playerctl`-backed media widget with active-player detection, title display, and previous/play-next controls.
- Added notification badge on the settings button through Quickshell notification tracking.
- Added tooltips for non-obvious widgets.
- Added tray overflow popup behavior.
- Added bar autohide settings and animation path.
- Added polished calendar states in the clock panel.
- Added README coverage for the redesign, module system, settings keys, wallpaper pipeline, and animation model.

## Bugs Fixed

- Fixed module detail popups showing invalid `QuickshellScreenInfo(...)` strings for network address data.
- Fixed bar widening so width expansion animates instead of only narrowing smoothly.
- Fixed expanded widget mode overflowing vertically on short bars by falling back to inline detail text.
- Fixed stale `osdWorkspace` configuration and removed workspace/wallpaper OSD controls.
- Fixed stale `Quickshell.Services.Mpris` usage after local MPRIS service warnings by switching media display to `playerctl`.
- Fixed Niri `focus-window` command syntax by using `--id`.
- Fixed Qt signal-handler deprecation warning in `SettingsPanel.qml`.
- Fixed required repeater index/model warnings in settings, pill graph, and focused-window components.
- Fixed high idle CPU caused by Niri terminal-title event spam by ignoring known-window title-only changes when title rendering is disabled and reconciling windows on a delayed sync.

## Decisions Made

- Wallpaper changes are not OSD events because they are persistent visual state, not short-lived hardware feedback.
- Workspace switching uses `WorkspaceToast` instead of OSD so the OSD remains reserved for hardware/media-style changes.
- Media uses `playerctl` instead of direct Quickshell MPRIS bindings because the local Quickshell MPRIS service emitted DBus warnings with the available mpv setup.
- Known-window Niri title updates are filtered unless `focusedWindowShowTitle` is enabled. This preserves useful title display when requested and keeps animated terminal titles from driving idle CPU.
- The launch-time `qt.qpa.services` host portal warning remains external to Calypso. Quickshell exposes no app-id/portal launch option in `--help`; Calypso/QML logs are clean after launch.

## Verification

- `settings.json` validated with `json_pp`.
- Palette fallback verified by temporarily removing `palette.json`, reloading, confirming the bar rendered, then restoring the file.
- Bar styles visually verified with screenshots: islands, solid, pill, bottom position, icon-only mode, expanded mode, and height widening.
- Settings panel visually verified: OSD page, wallpaper page, and audio detail page with return button.
- Module detail UI visually verified for audio, network, battery, CPU, and memory.
- OSD visually verified for volume and auto-hide.
- Workspace toast visually verified by switching workspace 1 to workspace 2 and back.
- Notification badge verified with a raw `org.freedesktop.Notifications.Notify` DBus call and cleared with `CloseNotification`.
- Wallpaper random apply verified through `quickshell ipc call calypso randomWallpaper`; `settings.json` recorded applied wallpaper and Matugen palette timestamps with no error.
- Media widget verified with mpv plus mpv-mpris and `playerctl`; the widget appeared during playback and disappeared after the player exited.
- Final idle sample on PID 16910: `0.79s` CPU time over 60 seconds while Quickshell was running and Niri was receiving terminal title events.
- Final log window after launch had no Calypso/QML warnings. The only launch warning was the external Qt portal registration warning.
- Quickshell is running under the user service `calypso-quickshell.service`.

## Second-Pass Settings Redesign

- Reworked `SettingsPanel.qml` visual hierarchy without changing the settings storage contract.
- Added an integrated page header with an accent rail, icon tile, live state chip, and stronger title/subtitle grouping.
- Replaced flat section blocks with card-like sections that have gloss highlights, accent rails, separators, and clearer spacing.
- Added an overview hero with live status chips for visual preset, density, palette source, bar geometry, module distribution, and OSD position.
- Redesigned navigation rows with icon tiles, selected rails, stronger hover states, and clearer active state.
- Redesigned quick cards, module rows, widget rows, info rows, search, buttons, sliders, and toggles to share the same polished control-surface language.
- Added user-facing labels for internal enum values such as `iconAndText`, `rightCenter`, `materialMorphing`, and Matugen scheme names.
- Visually verified the Overview, Widgets, and Wallpaper pages with screenshots after reload.
- Revalidated `settings.json` and confirmed no new Calypso/QML warnings after the redesign reloads.

## Phase 0 Exclusive Zone Fix

Date: 2026-07-19

### Files Changed

- `Bar.qml`
- `CALYPSO_SESSION.md`

### Bugs Fixed

- Fixed the bar's reserved screen area when `barAutohide` is enabled. The `PanelWindow.exclusiveZone` now stays bound to the bar footprint instead of dropping to zero while hidden.

### Decisions Made

- Kept the exclusive zone reserved during autohide hide/show transitions to prevent Niri from resizing tiled windows during hover reveal.
- Included `screenMargin` in the reserved edge size because the bar surface is inset from the screen edge; reserving only `barHeight` would still allow overlap by the margin amount.

### Verification

- Validated `settings.json` with `python3 -m json.tool settings.json`.
- Verified tiled Niri window geometry for all bar styles (`islands`, `solid`, `pill`), both positions (`top`, `bottom`), and `barAutohide` on/off. The focused tiled window stayed at `1356x728` in every state, including autohide hidden and shown samples.
- Captured screenshots for each style/position/autohide combination in `/tmp/calypso-phase0-20260719-134755`.
- Restarted Quickshell after verification. The fresh log had no Calypso/QML warnings; only the known external Qt portal registration warning remained.

## Phase 0.5 Staged Shell Boot

Date: 2026-07-19

### Files Changed

- `Bar.qml`
- `BarSection.qml`
- `ModuleHost.qml`
- `CALYPSO_SESSION.md`

### Features Added

- Added startup phase gates for bar modules: core modules load immediately, non-core/background modules load after `300ms`, and interaction-only modules load after `600ms`.
- Converted settings, clock, control center, module details, OSD, workspace toast, and tooltip hosts from eager construction to `Loader { active: false }` surfaces activated by the interaction phase.
- Added on-demand activation so IPC and early clicks can open late-loaded surfaces before the `600ms` timer fires.

### Decisions Made

- Kept workspaces, focused windows, and clock in the immediate phase so first paint still has compositor context and a useful center section.
- Delayed settings/controls modules because settings currently owns notification tracking and controls are not needed for first paint.

### Verification

- Baseline daemonized launch elapsed time: `3628ms` in `/tmp/calypso-phase05-baseline-20260719-140954`.
- After staged loading, daemonized launch elapsed time: `3345ms` in `/tmp/calypso-phase05-after-20260719-141534`.
- Verified late-loaded SettingsPanel and OSD through IPC screenshots at `/tmp/calypso-phase05-settings.png` and `/tmp/calypso-phase05-osd.png`.
- Validated `settings.json` with `python3 -m json.tool settings.json`.
- Fully-loaded 60 second idle sample on PID `72488`: `4.360s` CPU time, `7.267%` of one core.
- Fresh log had no Calypso/QML warnings; only the known external Qt portal registration warning remained.
