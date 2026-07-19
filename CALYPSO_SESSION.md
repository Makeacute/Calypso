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

## Phase 3 Dashboard Module

Date: 2026-07-19

### Files Changed

- `DashboardPanel.qml`
- `Bar.qml`
- `ModuleHost.qml`
- `Settings.qml`
- `SettingsPanel.qml`
- `settings.example.json`
- `README.md`
- `CALYPSO_SESSION.md`

### Features Added

- Added `DashboardPanel.qml` as a compact standalone dashboard surface triggered by the dashboard/controls bar module.
- Added dashboard quick toggles for Wi-Fi, Bluetooth, mic, and DND, with unavailable DND shown disabled because no supported notification-control backend is installed.
- Added an open-only media card backed by `playerctl`, with playback controls and a scrubber.
- Added compact CPU, memory, network, and battery rows using miniature gauge/sparkline treatment and existing module polling intervals.
- Added settings keys for dashboard width, media/weather visibility, grow-from-trigger motion, quick-toggle order, performance-row order, and dashboard open-only polling.
- Added `openDashboard`/`closeDashboard` IPC aliases while preserving `openControls`/`closeControls`.

### Decisions Made

- Kept Dashboard as its own module after user correction; normal module clicks and `openModule` continue to use `ModuleDetailsPanel.qml`.
- Kept `controls`, `controlCenter`, and `quickControls` as aliases for the canonical `dashboard` module id so old configs continue to work.
- Skipped weather data integration because no existing weather source is present; the optional weather card only reports that no source is configured.
- Used `wf-recorder` for motion capture and `ffmpeg` for frame extraction because direct `ffmpeg` Wayland capture is unavailable on this setup.

### Verification

- Validated `settings.json` and `settings.example.json` with `python3 -m json.tool`.
- Captured dashboard screenshot at `/tmp/calypso-phase3-dashboard-module-final.png`.
- Captured restored per-module network popup at `/tmp/calypso-phase3-module-network-final.png`, confirming module UIs were not replaced by the dashboard.
- Temporarily added the dashboard trigger to the right bar section, recorded grow-from-trigger motion via `ydotool` click at `/tmp/calypso-phase3-dashboard-grow.mp4`, and reviewed `/tmp/calypso-phase3-dashboard-grow-contact.png`.
- Recorded reduce-motion dashboard trigger at `/tmp/calypso-phase3-dashboard-grow-reduce-motion.mp4` and reviewed `/tmp/calypso-phase3-dashboard-grow-reduce-contact.png`; original `settings.json` was restored afterward.
- Fresh instance `zqx21g9fit` loaded successfully after the dashboard routing fix.
- Closed-dashboard 60 second sample on PID `137051`: `1.730s` CPU time, `2.883%` of one core.
- Open-dashboard 60 second sample on PID `137051`: `1.630s` CPU time, `2.717%` of one core.
- Current log had no Calypso/QML warnings; only the known external Qt portal registration warning remained.

## Phase 4 Standalone Popovers

Date: 2026-07-19

### Files Changed

- `Bar.qml`
- `DashboardPanel.qml`
- `ModuleHost.qml`
- `Settings.qml`
- `SettingsPanel.qml`
- `NotepadPanel.qml`
- `ClipboardPanel.qml`
- `ProcessPanel.qml`
- `widgets/Notepad.qml`
- `widgets/Clipboard.qml`
- `widgets/Processes.qml`
- `settings.example.json`
- `README.md`
- `CALYPSO_SESSION.md`

### Features Added

- Added standalone notepad, clipboard history, and process-list popovers, each triggered by its own bar module rather than being embedded into the dashboard.
- Added lazy bar widgets for `notepad`, `clipboard`, and `processes`, with aliases and module metadata in the existing module registry.
- Added `openNotepad`, `openClipboard`, and `openProcesses` IPC commands.
- Added notepad autosave to a configurable local path, defaulting to `${XDG_STATE_HOME:-$HOME/.local/state}/calypso/notepad.txt`.
- Added cliphist-backed clipboard history with real image thumbnail extraction for image entries, plus a guarded CopyQ fallback.
- Added process sorting by CPU or memory and temperature reporting; temperature shows unavailable because `sensors` is not installed on this system.
- Added Settings Panel controls for notepad path/debounce, clipboard backend/item count, and process list poll interval/row count/panel width.
- Added a dashboard CPU-row handoff that opens the process popover as its own surface; normal module popups remain handled by `ModuleDetailsPanel.qml`.

### Decisions Made

- Kept the new popover modules disabled by default so the user's existing bar layout is unchanged.
- Preferred `cliphist` over CopyQ in `clipboardBackend: "auto"` because `copyq count` can block when the daemon is not ready on this session.
- Kept process polling open-only and configurable through `polling.processListMs`.
- Did not add a temperature dependency because `sensors` is not installed; this needs a flake/system dependency before live temperatures can be shown.

### Verification

- Confirmed `copyq`, `cliphist`, `wl-copy`, and `wl-paste` are installed; confirmed `sensors` is not installed.
- Seeded cliphist with a text item and the provided PNG test image; verified `cliphist decode` produced `/run/user/1000/calypso-clipboard/2.png`.
- Validated `settings.json` and `settings.example.json` with `python3 -m json.tool`.
- Current Quickshell instance `yo3gudfit` loaded successfully on PID `4786`.
- Captured notepad screenshot at `/tmp/calypso-phase4-notepad-current.png`.
- Captured clipboard screenshot at `/tmp/calypso-phase4-clipboard-current.png`; it shows cliphist text history and a real PNG thumbnail.
- Captured process-list screenshot at `/tmp/calypso-phase4-processes-current.png`; it shows CPU/memory sorting and `Temp Unavailable`.
- Attempted `ydotool` actual clicks earlier in this session, but virtual clicks did not reach Niri despite the daemon/socket being present; panel motion was therefore triggered through IPC for recording.
- Recorded cropped motion clips with `wf-recorder`: `/tmp/calypso-phase4-notepad-motion-current.mp4`, `/tmp/calypso-phase4-clipboard-motion-current.mp4`, and `/tmp/calypso-phase4-processes-motion-current.mp4`.
- Reviewed contact sheets: `/tmp/calypso-phase4-notepad-motion-current-contact.png`, `/tmp/calypso-phase4-clipboard-motion-current-contact.png`, and `/tmp/calypso-phase4-processes-motion-current-contact.png`; all surfaces were framed and opened smoothly from the bar edge.
- Recorded reduce-motion notepad check at `/tmp/calypso-phase4-notepad-reduce-motion-current.mp4`; reviewed `/tmp/calypso-phase4-notepad-reduce-motion-current-contact.png` and confirmed the transition collapses to a near-instant appearance.
- Notepad open idle sample on PID `4786`: `0.850s` CPU time over `60.021s`, `1.416%` of one core.
- Clipboard open idle sample on PID `4786`: `1.080s` CPU time over `60.023s`, `1.799%` of one core.
- Processes open idle sample on PID `4786`: `1.510s` CPU time over `60.041s`, `2.515%` of one core.
- Final log window had no Calypso/QML warnings or errors.

## Phase 4.5 Workspace App System Icons

Date: 2026-07-19

### Files Changed

- `services/NiriService.qml`
- `widgets/AppIconImage.qml`
- `widgets/AppIconResolver.qml`
- `widgets/FocusedWindow.qml`
- `widgets/Workspace.qml`
- `CALYPSO_SESSION.md`

### Features Added

- Replaced the focused-window/workspace-app module's Nerd Font glyph icons with Quickshell `IconImage` system-theme icons.
- Replaced the per-workspace app glyph path in `Workspace.qml` with the same centered system-icon renderer.
- Added shared `AppIconResolver` and `AppIconImage` components with exact desktop-entry lookup, conservative app-id icon mapping, `Quickshell.hasThemeIcon()` guards, and token-styled initial fallbacks.
- Removed the clipped empty focused-window pill and app-entry fade that caused a generic/blank ghost icon to appear during app launch in `barStyle: islands`.
- Cached desktop entries, icon names, icon paths, and display names per app ID so icon-theme lookup does not repeat on every compositor window update.
- Removed the old Niri known-window `WindowOpenedOrChanged` pre-sync path so title-only events are filtered in-process instead of repeatedly spawning `niri msg windows`.

### Decisions Made

- Kept this as a standalone Phase 4.5 change, separate from the staged Phase 4 popover work.
- Removed fuzzy `DesktopEntries.heuristicLookup()` from the app-id path because short IDs such as `code` can resolve to unrelated theme/action icons.
- Kept focus/active styling on the pill surface instead of tinting app icons, preserving real app icon colors.
- Kept the focused-window module hidden on workspaces with no windows; no empty placeholder pill is reserved.

### Verification

- Verified the current Quickshell instance `yo3gudfit` hot-reloaded the Phase 4.5 files without QML errors.
- Validated `settings.json` and `settings.example.json` with `python3 -m json.tool`.
- Captured current terminal system-icon state at `/tmp/calypso-phase45-system-icons-current-full.png` and `/tmp/calypso-phase45-system-icons-current-crop.png`.
- Spawned temporary `librewolf`, `code`, and `footclient` app-id windows; captured `/tmp/calypso-phase45-system-icons-test-full-6.png` and `/tmp/calypso-phase45-system-icons-test-crop-6.png`.
- Confirmed terminal/LibreWolf render as centered system images. The fake `code` app ID has no installed/resolvable system icon in this session, so it renders the neutral `C` fallback instead of a Nerd Font glyph or Qt missing-image tile.
- Captured the corrected terminal icon placement at `/tmp/calypso-phase45-system-icons-centered-after-yfix.png`.
- Closed temporary test windows `67`, `68`, and `69`.
- Reproduced the empty-workspace app-spawn transition before the final fix at `/tmp/calypso-empty-spawn-contact-before-fix.png`.
- Captured the final app-spawn transition after removing the ghost empty pill and Niri pre-sync path at `/tmp/calypso-empty-spawn-contact-after-niri-fix.png`; the first visible app frame is the terminal system icon.
- Captured current focused-window zoom at `/tmp/calypso-phase45-current-center-cached-4x.png`.
- Temporarily enabled `workspaceShowAppIcons` and captured `/tmp/calypso-phase45-workspace-pill-system-icons-enabled.png` plus zoom `/tmp/calypso-phase45-workspace-pill-system-icons-enabled-zoom.png`; per-workspace app icons render as centered system images.
- Temporarily tested `barStyle` `islands`/`solid`/`pill` and `barPosition` `top`/`bottom`, restored `settings.json`, and captured `/tmp/calypso-phase45-layout-matrix.png`; full-width bottom checks include `/tmp/calypso-phase45-islands-bottom-fullwidth-slow.png` and `/tmp/calypso-phase45-pill-bottom-fullscreen-slow.png`.
- Idle CPU samples on PID `4786`: noisy pre-cache/pre-event-fix samples were `5.187%`, `2.068%`, and `3.508%` of one core; final post-cache/post-event-fix sample was `0.920s` CPU over `60.443s`, `1.522%` of one core, with the ending `top` line at `0.0%`.
- Final log window had no Calypso/QML warnings or errors.

## Phase 5 Notification Drawer

Date: 2026-07-19

### Files Changed

- `Bar.qml`
- `BarSection.qml`
- `ModuleHost.qml`
- `NotificationPanel.qml`
- `Settings.qml`
- `SettingsPanel.qml`
- `widgets/SettingsButton.qml`
- `settings.example.json`
- `README.md`
- `CALYPSO_SESSION.md`

### Features Added

- Moved notification tracking to a shared `NotificationServer` in `Bar.qml`, keeping the settings button as the count badge/trigger instead of a second notification owner.
- Added `NotificationPanel.qml`, a separate notification drawer with app grouping, expand/collapse state, notification bodies, optional images, dismiss buttons, and app-provided action buttons via `NotificationAction.invoke()`.
- Added badge/right-click notification access from `SettingsButton.qml` while preserving normal left-click settings behavior.
- Added notification drawer settings for width, max cards, grouping, default expansion, body rendering, image rendering, and action rendering.
- Added `openNotifications` and `closeNotifications` IPC helpers for verification and future keybind use.

### Decisions Made

- Kept notifications as their own drawer, separate from the Phase 3 dashboard.
- Kept the drawer lazy-loaded in the interaction phase; only the notification service itself is always present so the badge count stays live.
- Used Quickshell 0.3.0's existing notification action API instead of adding a helper daemon or external notification history dependency.
- Kept body markup disabled and rendered bodies as plain text to avoid unsafe/unexpected markup handling.

### Verification

- Validated `settings.json` and `settings.example.json` with `python3 -m json.tool`.
- Confirmed local Quickshell notification metadata exposes `NotificationAction.invoke()`, body, image, app, urgency, and dismiss APIs.
- Triggered three real DBus notifications with `busctl`: two from `Calypso Mail` and one from `Calypso Chat`; the drawer grouped the mail notifications and rendered action buttons for actionable notifications.
- Captured empty drawer screenshot at `/tmp/calypso-phase5-notifications-empty.png`.
- Captured grouped/action drawer screenshot at `/tmp/calypso-phase5-notifications-grouped-final.png`.
- Captured layout matrix with the drawer open across `barStyle` `islands`/`solid`/`pill` and `barPosition` `top`/`bottom` at `/tmp/calypso-phase5-layout-matrix.png`, then restored the user's `solid`/`top` settings.
- Recorded drawer open motion via IPC-triggered screen frames assembled with `ffmpeg`: `/tmp/calypso-phase5-notification-drawer-motion.mp4`; reviewed contact sheet `/tmp/calypso-phase5-notification-drawer-motion-contact.png`.
- Recorded reduce-motion drawer open check at `/tmp/calypso-phase5-notification-drawer-reduce-motion.mp4`; reviewed `/tmp/calypso-phase5-notification-drawer-reduce-motion-contact.png` and confirmed the drawer appears without the normal eased slide.
- Idle CPU sample with notification drawer closed on PID `4786`: `0.860s` CPU over `60.000s`, `1.433%` of one core.
- Idle CPU sample with notification drawer open on PID `4786`: `0.880s` CPU over `60.000s`, `1.467%` of one core.
- Fixed a transient delegate-width binding warning in `NotificationPanel.qml`; the fresh final log tail had no Calypso/QML warnings or errors.

## Phase 6 Live Slider Updates

Date: 2026-07-19

### Files Changed

- `ModuleDetailsPanel.qml`
- `CALYPSO_SESSION.md`

### Features Added

- Updated the module-details `SliderRow` used by audio and brightness so value text and knob position follow a local `liveValue` while the pointer is dragging.
- Added latest-command queuing for module action commands so brightness dragging does not drop the final requested brightness when a previous `brightnessctl` process is still running.

### Decisions Made

- Kept this scoped to `ModuleDetailsPanel.qml`, where the current volume and brightness sliders live.
- Did not add a new timer or polling interval; this remains event/drag driven.
- Kept audio volume writes routed through the existing PipeWire binding and brightness writes routed through the existing `brightnessctl` command path.

### Verification

- Validated `settings.json` and `settings.example.json` with `python3 -m json.tool`.
- Captured audio live-slider screenshot at `/tmp/calypso-phase6-audio-live-slider.png`.
- Captured brightness live-slider screenshot at `/tmp/calypso-phase6-brightness-live-slider-final.png`.
- Attempted a real ydotool drag and recorded `/tmp/calypso-phase6-audio-drag-motion.mp4` plus contact sheet `/tmp/calypso-phase6-audio-drag-contact.png`; ydotool still did not reliably deliver the drag through Niri in this session, so this was not treated as a real input success.
- Ran an active audio live-update stress check with the panel open and restored volume afterward. A high-rate external `wpctl` stream measured `3.000s` CPU over `15.001s`, `19.999%` of one core; a lower-rate stream measured `1.390s` CPU over `15.004s`, `9.264%` of one core.
- Post-update idle sample on PID `4786`: `0.280s` CPU over `15.000s`, `1.867%` of one core.
- Confirmed final audio volume was restored to `0.15`.
- Final log window had no Calypso/QML warnings or errors.
