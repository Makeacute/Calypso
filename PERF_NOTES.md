# Performance Notes

Checked on 2026-07-17 after final integration and the Calypso visual/settings pass.

## Audit Tooling

- `tools/calypso-perf-audit` writes timestamped reports to `perf-reports/` without editing `settings.json` or reloading Quickshell.
- The audit captures a settings snapshot, JSON validation, optional `qmllint`, process summary, sampled CPU/RSS/fd/thread counts, per-thread CPU deltas, child processes, and journal tails.
- Use `--pid` when temporary Quickshell test instances are running next to the live Calypso process.
- Module-by-module tests should still preserve an exact pre-test `settings.json`, toggle only one module per batch, and restore the original settings afterward.
- Latest smoke tooling check: `perf-reports/calypso-20260717-170104` auto-selected PID `28785` and produced formatted process, sample, settings, and thread reports. This was a two-second script check, not a stable idle benchmark.

## Runtime Performance Controls

- `performanceMode` is persisted in `settings.json` and defaults to `false`.
- When enabled, performance mode makes effective motion tokens zero, suppresses the bar blur fallback, disables the shared pill pulse animation, and removes shared pill hover scale at runtime without overwriting saved animation or blur settings.
- The settings panel now exposes CPU, memory, network, battery fallback, clock, brightness, and power-profile polling intervals under `Performance`.
- The quick controls popup lazy-loads its content only while open, so hidden controls do not instantiate their own fallback timers.

## Timer Audit

- `Settings.qml` `saveTimer`: necessary one-shot debounce for JSON writes after settings changes. `80ms` is intentionally short and not active while idle.
- `services/NiriService.qml` `restartTimer`: necessary one-shot stream restart backoff after the Niri event stream exits. `1500ms` is reasonable and event-replaceable only if Quickshell/Niri exposes a better reconnect primitive.
- `widgets/Cpu.qml`: necessary polling because `/proc/stat` has no event stream. `cpuMs` default is `2500ms`, reasonable for a bar metric.
- `widgets/Memory.qml`: necessary polling because `/proc/meminfo` has no event stream. `memoryMs` default is `5000ms`, reasonable.
- `widgets/Network.qml`: route/device status is polled through `ip -j route get 1.1.1.1`. `networkMs` default is `5000ms`, acceptable but event replacement through NetworkManager or netlink would be cleaner if this grows.
- `widgets/Battery.qml`: UPower is event-backed when available. The `batteryFallbackMs` timer only runs without UPower and defaults to `30000ms`, reasonable.
- `widgets/Clock.qml`: necessary timer for formatted time. Fixed to use a one-shot minute-aligned timer for minute-level formats such as `HH:mm`; it uses `clockMs` for formats containing second or millisecond tokens.
- `ClockPanel.qml`: its one-second `now` timer now runs only while the panel is open.
- `widgets/Brightness.qml`: visible-only slow fallback polling through `brightnessMs`, default `15000ms`; scroll uses `brightnessctl` for explicit user actions.
- `widgets/PowerProfile.qml`: visible-only slow polling through `powerProfileMs`, default `30000ms`; click cycles profiles through `powerprofilesctl`.
- `widgets/Workspace.qml`: workspace wheel navigation uses a one-shot debounce timer only while handling a wheel gesture.
- `ModuleDetailsPanel.qml`: structured module detail collectors run only while the popup is open. CPU and network refresh more frequently while visible; other live readouts use a slower visible-only refresh.

No hidden polling was found in the media, Bluetooth, caffeine, tray, focused-window, workspace, audio, or quick controls trigger widgets.

## Niri Event Stream

Fixed:
- `WindowFocusChanged` no longer rebuilds/clones the whole `windows` array. It now updates only `focusedWindow`, which is what the focused-window widget uses for highlighting. This avoids broad model churn on common focus changes.
- `WindowsChanged` now refreshes `seenWindowIds`, preventing later opened/changed events from being misclassified after a full window-list event.

Left as acceptable:
- Window open/change/close still rebuilds the window list with an O(n) pass. That is proportional to the changed list and only runs on actual window events.
- Workspace activation still rebuilds workspace objects for the target output. This is small and tied to workspace focus events.

## Repaint And Relayout Audit

Fixed:
- `widgets/Workspace.qml` now computes window counts once per Niri windows/workspaces update and each workspace pill reads an O(1) cached count. Previously every workspace delegate scanned all windows.
- Workspace new-window pulse is tied to `openedWindowSerial`; the previous generic count-increase pulse could double-trigger for the same opened-window event.
- `widgets/Clock.qml` no longer wakes/repaints every second for the default minute-only clock format.

Checked:
- `BarSection.qml` and `ModuleHost.qml` do not animate width, avoiding section movement on focused-window churn.
- `Workspace.qml` keeps focus-indicator x/width animation gated to focus changes and uses local pulse animation for new windows.
- `FocusedWindow.qml` delegates animate entry/hover/color only. Title mode can still change section width because it intentionally reveals the active title.
- `Tray.qml` uses asynchronous `IconImage`; icon reloads are driven by tray item model changes.
- `Media.qml` hides cleanly with zero implicit size when no MPRIS player exists.
- `ControlCenterPanel.qml` uses a `Loader` that activates only while the panel is open.
- `Surface.qml` and `Pill.qml` now centralize visual styles so preset changes are token-driven instead of duplicated per widget.

## Effects Audit

No native blur, shader, `MultiEffect`, `DropShadow`, or layer effects are active. No blur/effects import was available in the project, so `blurEnabled` uses a cheap translucent bar fallback with a subtle border line. Shadow color tokens exist in `Theme.qml` but are not applied to always-visible UI.

## Idle CPU

Idle CPU was checked after reload with `ps`, `top -H`, and direct `/proc/<pid>/stat` tick deltas while leaving Quickshell running.

- Final measured instance: PID `25774`, Niri event stream child was alive as `/run/current-system/sw/bin/niri msg --json event-stream`.
- Runtime logs were clean after reload and after workspace/window smoke tests.
- A full default widget set measured about `3.6%` of one core after a clean restart.
- The final default visibility profile keeps the workspace strip, clock, and settings button visible while leaving heavier widgets present in the settings panel but disabled by default.
- With that lean default profile, a 120-second `/proc/<pid>/stat` sample measured `0.467%` of one core.
- A two-sample `top` check showed the second sample at `0.2%` CPU for the Quickshell process.

## Remaining Tradeoffs

- Clock formats containing second or millisecond tokens still wake according to `polling.clockMs`.
- Network status uses an `ip` subprocess every 5 seconds. This is acceptable for now; an event-backed network service would be better if more network detail is added.
- Brightness and power profile use CLI subprocesses for explicit actions and slow visible-only status reads. Native service bindings would be cleaner if Quickshell grows them locally.
- CPU and memory metrics intentionally poll procfs. Their intervals are conservative and user-configurable in `settings.json`; the modules are disabled by default for lower idle cost.
- Enabling the full right-side widget set raises idle CPU on this machine because visible QML surfaces add render-thread cost even when logs are clean.
- `widgets/RightModules.qml` is legacy and not used by the current `BarSection`/`ModuleHost` path, but it was left in place to avoid removing shared work during this pass.
