# Calypso

Calypso is a Quickshell bar and shell toolkit for Niri. It prioritizes low idle
cost, polished visuals, and physical-feeling motion.

## Requirements

- Quickshell 0.3 or newer
- Niri
- Nerd Font glyph coverage
- PipeWire for audio controls
- Optional: `awww` and Matugen for wallpaper-derived colors
- Optional: power-profiles-daemon for power profile controls

Run the shell directly:

```sh
quickshell -p ~/.config/quickshell --no-duplicate
```

Open the settings application:

```sh
quickshell ipc call calypso openSettings
```

## Architecture

- `shell.qml` gates startup on settings migration.
- `AppRuntime.qml` creates one `Bar` per screen.
- `AppContext.qml` owns settings, theme, notifications, compositor state, the
  settings window, IPC, and shared long-running services.
- `SettingsStore.qml` exposes the v4 nested store plus the compatibility facade
  used by existing widgets.
- `SettingsWindow.qml` and `settingsui/` implement the dedicated live settings
  application with search, undo/redo, module placement, and service health.
- `ModuleRegistry.qml` is the source of truth for module metadata, aliases,
  loading phase, injection contract, and QML source.
- `ModuleHost.qml` loads registered modules generically.
- `panels/PanelCoordinator.qml` gives anchored surfaces one focus owner.
- `services/` contains event-driven media, battery, network, power profile,
  compositor, notification, system-stat, and wallpaper integrations.
- `Theme.qml` adapts Stylix/Matugen colors and owns all visual and motion tokens.

The settings window is a normal desktop window. On Niri, Calypso resolves its
window ID when opened, moves that exact window to the floating layout, sizes it,
and centers it. No persistent compositor rule is required.

## Settings Schema

Schema v4 groups settings by ownership:

```json
{
  "version": 4,
  "app": {},
  "bar": {},
  "theme": {},
  "modules": {
    "left": [],
    "center": [],
    "right": [],
    "instances": {}
  },
  "panels": {},
  "services": {},
  "ui": {},
  "migration": {}
}
```

Placement lanes contain stable instance IDs. Each entry in
`modules.instances` stores its module type, enabled state, and instance settings.
This permits more than one instance of a reusable module without coupling
placement to implementation metadata.

Changes save atomically after a short debounce. The settings application keeps a
50-operation undo/redo history and coalesces slider gestures into one operation.

### Migration

Startup runs `tools/calypso-migrate-settings` before creating the shell. A v3
file is migrated exactly once and its original bytes are retained beside it as
`settings.v3.<timestamp>.json`. Malformed and unsupported files are not
overwritten.

Manual migration and rollback:

```sh
tools/calypso-migrate-settings settings.json
tools/calypso-migrate-settings settings.json --rollback settings.v3.<timestamp>.json
```

## Design System

Widgets use `theme.*` and `settings.effective*` values for colors, dimensions,
spacing, radii, and motion. `Theme.qml` remains usable when the configured
palette is missing or malformed by falling back to its complete dark palette.

All token-derived animation collapses when `settings.reduceMotion` is enabled.
`settings.performanceMode` also disables expensive effects and service sampling
that is not needed for core behavior.

Modules support:

- `iconOnly`
- `iconAndText`
- `expanded`

The bar supports `islands`, `solid`, and `pill` layouts at both the top and
bottom screen edges.

## Shared Services

CPU and memory share one consumer-gated sampler. Network throughput sampling is
also consumer-gated. Widgets and persistent panels increment service consumers
only while they need samples and release them on close or destruction.

Media uses native MPRIS events. Battery uses UPower with a configurable sysfs
fallback. Network state follows `ip monitor` and reconnects. Power profiles use
power-profiles-daemon when available. Each service exposes health state and its
last error to the settings Overview.

Polling fallbacks live under `services.polling` in `settings.json`; no widget
owns an unconfigurable background interval.

## Adding A Module

1. Add `widgets/MyModule.qml`; prefer `Pill.qml` for compact modules.
2. Add one entry to `ModuleRegistry.qml` with source, aliases, category, loading
   phase, default section, cost, and capabilities.
3. Add an instance default to `settingscore/SettingsDefaults.js`.
4. Add the instance ID to a default lane in `settings.example.json` when it
   should ship enabled.
5. Add module-specific settings controls to `settingsui/ModuleConfig.qml`.
6. Verify every widget style, bar style, and bar position.

`ModuleHost.qml` does not need a component switch entry.

## IPC

The global `calypso` target routes monitor-specific surfaces to the focused
screen and keeps settings as one application window.

Examples:

```sh
quickshell ipc call calypso openSettingsPage modules
quickshell ipc call calypso openSettingsDetail network
quickshell ipc call calypso openDashboard
quickshell ipc call calypso openLauncherQuery firefox
quickshell ipc call calypso setBarStyle islands
quickshell ipc call calypso setBarPosition bottom
quickshell ipc call calypso setWidgetStyle expanded
```

## Verification

```sh
python3 -m json.tool settings.json >/dev/null
python3 -m json.tool settings.example.json >/dev/null
python3 -m unittest discover -s tests/migration -p 'test_*.py' -v
git diff --check
tail -n 120 /run/user/1000/quickshell/by-id/<instance>/log.qslog \
  | strings | rg 'WARN|ERROR'
```

For animation, polling, or persistent-surface work, compare at least 60 seconds
of idle CPU against a baseline with the surface closed and open.
