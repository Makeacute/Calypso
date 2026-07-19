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

## Phase 1 Tonal Surfaces And Font Roles

Date: 2026-07-19

### Files Changed

- `Theme.qml`
- `Settings.qml`
- `Surface.qml`
- `Bar.qml`
- `ClockPanel.qml`
- `ControlCenterPanel.qml`
- `ModuleDetailsPanel.qml`
- `SettingsPanel.qml`
- `widgets/Osd.qml`
- `widgets/Pill.qml`
- `widgets/SettingsButton.qml`
- `widgets/TooltipHost.qml`
- `widgets/Tray.qml`
- `widgets/Workspace.qml`
- `widgets/WorkspaceToast.qml`
- `settings.example.json`
- `README.md`
- `CALYPSO_SESSION.md`

### Features Added

- Added explicit tonal roles in `Theme.qml`: `surfaceContainer`, `surfaceContainerHigh`, `primary`, `secondary`, `tertiary`, `outlineVariant`, and `error`, while preserving compatibility aliases such as `accent`, `urgent`, and `surfacePanel`.
- Added font role settings: `fontFamilySans`, `fontFamilyMono`, and `fontFamilyIcon`, with migration fallback to the existing `fontFamily`.
- Updated shared bar pills, OSD, clock hero text, module detail hero/value cards, tooltips, workspace labels, and notification badge text to use role-specific fonts.
- Moved elevated panel/card surfaces toward `surfaceContainer` and `surfaceContainerHigh` tokens.

### Decisions Made

- Kept legacy `settings.fontFamily` mapped to the original blanket font so unpatched glyph-heavy call sites remain compatible during the role migration.
- Used `DejaVu Sans` as the default Sans role because `Inter` is not installed on this system; kept `JetBrainsMono Nerd Font` for Mono and Icon roles.

### Verification

- Validated `settings.json` and `settings.example.json` with `python3 -m json.tool`.
- Restarted Quickshell and captured normal render screenshot at `/tmp/calypso-phase1-normal.png`.
- Temporarily removed `palette.json`, restarted Quickshell, confirmed fallback render, captured `/tmp/calypso-phase1-palette-fallback.png`, then restored `palette.json`.
- Fresh logs had no Calypso/QML warnings; only the known external Qt portal registration warning remained.

## Phase 1.5 OSD Visual Pass

Date: 2026-07-19

### Files Changed

- `Bar.qml`
- `Settings.qml`
- `SettingsPanel.qml`
- `widgets/Osd.qml`
- `settings.example.json`
- `README.md`
- `CALYPSO_SESSION.md`

### Features Added

- Redesigned OSD fill visuals around a tonal pill track using `surfaceContainer`, `outlineVariant`, `primary`, `error`, and muted text colors.
- Added `capsLock` and `numLock` OSD types, settings keys `osdCapsLock` and `osdNumLock`, SettingsPanel toggles, and IPC trigger support.
- Added event-backed `FileView` watchers for `/sys/class/leds/*capslock*/brightness` and `/sys/class/leds/*numlock*/brightness`.
- Lock OSD states display `ON`/`OFF` rather than fake percentages.

### Decisions Made

- Used sysfs LED state as the real lock source because it exists on this machine and avoids polling.
- Kept the existing `osdTimeout` and reveal/hide timing unchanged.

### Verification

- Validated `settings.json` and `settings.example.json` with `python3 -m json.tool`.
- Captured volume and brightness screenshots: `/tmp/calypso-phase15-osd-volume.png`, `/tmp/calypso-phase15-osd-brightness.png`.
- Attempted caps/num trigger with `ydotool key 58:1 58:0` and `ydotool key 69:1 69:0`; this virtual input path did not flip the hardware LED files, so the watcher did not fire in that test.
- Verified caps/num visuals through IPC screenshots: `/tmp/calypso-phase15-osd-capslock-ipc.png`, `/tmp/calypso-phase15-osd-numlock-ipc.png`, `/tmp/calypso-phase15-osd-capslock-off-ipc.png`.
- Confirmed auto-hide with `/tmp/calypso-phase15-osd-after-hide.png`.
- Recorded OSD motion clip at `/tmp/calypso-phase15-osd-motion.mp4`; visual review showed the existing reveal/fill motion without snap.
- 60 second idle sample on PID `76614`: `7.700s` CPU time, `12.833%` of one core. A follow-up `top` check showed Quickshell around `4.7%` then `7.8%`; logs stayed clean.
- Fresh logs had no Calypso/QML warnings; only the known external Qt portal registration warning remained.

## Phase 2A Module Popup Gauges

Date: 2026-07-19

### Files Changed

- `ModuleDetailsPanel.qml`
- `Settings.qml`
- `settings.example.json`
- `README.md`
- `CALYPSO_SESSION.md`

### Features Added

- Replaced the CPU, memory, network, and battery popup hero bars with circular Canvas gauges.
- Added compact sparkline history for the same four popup hero metrics using the existing popup refresh cadence instead of a new poller.
- Added configurable popup gauge keys: `modulePopupShowGauge`, `modulePopupShowSparkline`, `modulePopupHistorySamples`, and `modulePopupNetworkScaleKib`.
- Mapped target module gauge severity to `theme.primary`, `theme.warning`, and `theme.error`.

### Decisions Made

- Kept the existing Overview / Controls / Diagnostics tab structure unchanged.
- Used the existing module details timer for history samples so Phase 2A adds no new background polling.
- Network gauge progress is normalized against `modulePopupNetworkScaleKib`; value text shows combined RX/TX throughput.

### Verification

- Validated `settings.json` and `settings.example.json` with `python3 -m json.tool`.
- Captured target popup screenshots in `/tmp/calypso-phase2a-20260719/`: `cpu.png`, `memory.png`, `network.png`, and `battery.png`.
- Simulated high CPU load with two short-lived `yes` processes and captured `/tmp/calypso-phase2a-20260719/cpu-high-load.png`; the CPU gauge reached `100%` and shifted to the error tone.
- Restarted Quickshell after the QML reload fix. Fresh instance `jvs1pw6fit` loaded successfully.
- Closed-popup 60 second idle sample on PID `76614`: `4.690s` CPU time, `7.817%` of one core.
- Fresh log after restart had no Calypso/QML warnings; only the known external Qt portal registration warning remained.

## Phase 2B Bar Module Redesign

Date: 2026-07-19

### Files Changed

- `Settings.qml`
- `settings.example.json`
- `README.md`
- `widgets/Pill.qml`
- `widgets/Workspace.qml`
- `widgets/Network.qml`
- `widgets/Battery.qml`
- `widgets/Audio.qml`
- `widgets/Media.qml`
- `CALYPSO_SESSION.md`

### Features Added

- Added per-workspace app icons inside workspace pills using the existing normalized Niri window list.
- Added settings defaults for `workspaceShowAppIcons`, `workspaceMaxAppIcons`, and `iconMorphTransitions`.
- Updated the network pill to show separate down/up rates when `networkShowSpeed` is enabled.
- Added opt-in icon morph transitions to `Pill.qml` and enabled them for media play/pause, network online/offline, and audio mute/unmute.
- Added a custom content color hook to `Pill.qml` and used it so battery icon/text color shifts through primary, warning, and error tones based on the configured critical threshold.
- Removed the always-visible charging icon pulse from battery to avoid idle breathing animation.
- Fixed expanded graph pills with empty primary text so they no longer render a leading slash.

### Decisions Made

- Reused the existing CPU and memory bar graph path because `Cpu.qml` and `Memory.qml` already feed `showGraph`/`graphValues` into `Pill`.
- Reused the existing tray context-menu path: `TrayButton` already calls `itemData.display(...)` on right-click when `hasMenu` is exposed.
- Did not add desktop-file icon lookup for workspace icons in this phase; the workspace pill uses the same lightweight app-id glyph mapping style already used by `FocusedWindow.qml`.

### Verification

- Validated `settings.json` and `settings.example.json` with `python3 -m json.tool`.
- Captured bar screenshots for all widget styles with graph/speed paths temporarily enabled, then restored the original config: `/tmp/calypso-phase2b-20260719/bar-iconOnly.png`, `bar-iconAndText.png`, and `bar-expanded-recheck.png`.
- Verified network down/up speed text and CPU/memory graph pills rendered in the bar screenshots.
- Temporarily raised `batteryCriticalThreshold` and captured warning/error color checks: `/tmp/calypso-phase2b-20260719/battery-warning-tone.png` and `battery-error-tone.png`; original config was restored.
- `ffmpeg` could not capture the Wayland session directly (`kmsgrab` failed with no DRM device, and this build has no Wayland/PipeWire input). Used `wf-recorder` for screen capture and `ffmpeg` for frame extraction.
- Motion clips captured: audio mute/unmute via `wpctl` at `/tmp/calypso-phase2b-20260719/audio-morph-wpctl.mp4`; network online/offline via controlled interface setting change at `network-morph.mp4`; media play/pause via ydotool media key at `media-morph-key-long.mp4`; reduce-motion media check at `media-morph-reduce-motion.mp4`.
- ydotool media key was verified to change `playerctl` state `Playing -> Paused -> Playing`. ydotool mute key did not change PipeWire mute state on this session, so audio morph used `wpctl`; no safe ydotool trigger was available for Wi-Fi online/offline without toggling radios.
- 60 second idle sample on PID `84079`: `0.890s` CPU time, `1.483%` of one core.
- Current log window had no Calypso/QML warnings.

## Phase 2C Settings Panel Redesign

Date: 2026-07-19

### Files Changed

- `SettingsPanel.qml`
- `CALYPSO_SESSION.md`

### Features Added

- Replaced Overview status chips with elevated stat cards using icon, value, and tonal surface treatment.
- Added Layout-page font role pickers for Sans, Mono, and Icon roles with live preview tiles sourced from `fc-list`.
- Added settings controls for Phase 2A/2B options: module popup gauges/sparklines/history, workspace app icons/max icons, and icon morph transitions.
- Added a page transition for SettingsPanel page/detail changes using `settings.motionNormal`; `reduceMotion` collapses it to an instant swap.

### Decisions Made

- Kept font discovery lazy: the `fc-list` scan runs when SettingsPanel opens, not at shell startup or while the panel is closed.
- Used the existing `settings.setString` path for picker selections so old configs keep loading through `Settings.qml` fallbacks.

### Verification

- Validated `settings.json` and `settings.example.json` with `python3 -m json.tool`.
- Captured screenshots: `/tmp/calypso-phase2c-20260719/overview.png`, `layout-fonts.png`, `detail-network.png`, and `detail-workspaces.png`.
- Verified `fc-list` is installed and returns real local families including `CaskaydiaCove Nerd Font`, `DejaVu Sans`, `JetBrainsMono Nerd Font`, `Material Symbols Rounded`, `Noto Color Emoji`, and `Rubik`.
- Tried to select a font tile through `ydotool`; the virtual click did not reach the Quickshell popup on this session, so the picker was verified by rendered tile list, code path inspection, and restored settings state rather than a successful synthetic click.
- Recorded page transition motion at `/tmp/calypso-phase2c-20260719/page-transition-motion.mp4`; reviewed extracted contact sheet `page-transition-motion-contact.png`.
- Recorded reduce-motion transition at `/tmp/calypso-phase2c-20260719/page-transition-reduce-motion.mp4`; reviewed `page-transition-reduce-motion-contact.png` and confirmed the page swap collapsed to instant.
- `ffmpeg` still cannot capture this Wayland session directly, so `wf-recorder` was used for screen capture and `ffmpeg` for frame extraction.
- Restarted Quickshell after verification churn. Fresh instance `8k72ze8fit` loaded successfully.
- Fresh closed-panel 60 second idle sample on PID `103112`: `0.950s` CPU time, `1.583%` of one core.
- Fresh log had no Calypso/QML warnings; only the known external Qt portal registration warning remained.
