# New Widgets Schema

Agent 3 additive feature pass for the Quickshell bar overhaul. Tray already exists. Disk is intentionally excluded and should not be added in this merge.

## Missing Widget Confirmation

Existing widgets before this pass: `workspaces`, `focusedWindow`, `cpu`, `memory`, `audio`, `network`, `battery`, `clock`, `tray`, and `settings`.

New feasible widgets added: `media`, `bluetooth`, and `caffeine`.

Deferred: notification indicator/history. Quickshell 0.3.0 provides `Quickshell.Services.Notifications.NotificationServer`, but it is a notification server/tracked-notification API rather than a passive history API for an existing daemon. This config also does not yet have a shared popover/history surface. Adding a notification daemon inside an unwired bar widget would be invasive and could conflict with the user's existing notification service.

## `media`

- File: `widgets/Media.qml`
- Module key: `media`
- Aliases suggested for `ModuleHost`: `mpris`, `player`
- Default module list placement: right section, near audio; suggested right list order: `network`, `bluetooth`, `audio`, `media`, `battery`, `caffeine`, `clock`, `tray`
- Default visibility entry: `"media": true`
- Per-module settings: none required. Optional future setting: `mediaMaxWidth` default `220`; optional `mediaShowControls` default `true`.
- SettingsPanel controls required: normal module visibility toggle and section add/remove/reorder controls. If optional settings are added later, use a stepper/slider for max width and a switch for controls.
- Dependencies and fallback behavior: uses `playerctl` through `Quickshell.Io.Process` on a configurable lightweight poll interval. It picks the first active player reported by `playerctl -l`, displays metadata from `playerctl metadata`, and has zero implicit size when no player exists. Previous/play-next actions are routed back through `playerctl`; failures are silent so missing players do not create QML warnings.
- Exact `ModuleHost.qml` merge registration:

```qml
if (name === "media" || name === "mpris" || name === "player") return mediaComponent;
```

```qml
Component { id: mediaComponent; Media { theme: root.theme; settings: root.settings } }
```

## `bluetooth`

- File: `widgets/BluetoothStatus.qml`
- Module key: `bluetooth`
- Aliases suggested for `ModuleHost`: `bt`
- Default module list placement: right section, near network; suggested right list order: `network`, `bluetooth`, `audio`, `media`, `battery`, `caffeine`, `clock`, `tray`
- Default visibility entry: `"bluetooth": true`
- Per-module settings: none required.
- SettingsPanel controls required: normal module visibility toggle and section add/remove/reorder controls.
- Dependencies and fallback behavior: uses `Quickshell.Bluetooth`. Shows `none` when no adapter is present, `off` when disabled, `blocked` when blocked, `on` when enabled with no devices, one connected device name when exactly one device is connected, and a compact device count for multiple connections.
- Exact `ModuleHost.qml` merge registration:

```qml
if (name === "bluetooth" || name === "bt") return bluetoothComponent;
```

```qml
Component { id: bluetoothComponent; BluetoothStatus { theme: root.theme; settings: root.settings } }
```

## `caffeine`

- File: `widgets/Caffeine.qml`
- Module key: `caffeine`
- Aliases suggested for `ModuleHost`: `idleInhibitor`, `idle`
- Default module list placement: right section, near clock or battery; suggested right list order: `network`, `bluetooth`, `audio`, `media`, `battery`, `caffeine`, `clock`, `tray`
- Default visibility entry: `"caffeine": false`
- Per-module settings: none required. Optional future setting: `caffeineDefaultEnabled` default `false` if persistent startup behavior is wanted.
- SettingsPanel controls required: normal module visibility toggle and section add/remove/reorder controls.
- Dependencies and fallback behavior: uses `Quickshell.Wayland._IdleInhibitor.IdleInhibitor`. The widget toggles a local inhibited state. It binds the inhibitor to `panelWindow`, so it must receive `panelWindow` from `ModuleHost`. If no panel window is passed, the pill still toggles visually but does not enable the Wayland inhibitor.
- Exact `ModuleHost.qml` merge registration:

```qml
if (name === "caffeine" || name === "idleInhibitor" || name === "idle") return caffeineComponent;
```

```qml
Component { id: caffeineComponent; Caffeine { theme: root.theme; settings: root.settings; panelWindow: root.panelWindow } }
```

## Settings Merge Additions

Suggested `settings.json` additions for the merge step:

```json
"availableModules": [
  "workspaces",
  "focusedWindow",
  "cpu",
  "memory",
  "audio",
  "media",
  "network",
  "bluetooth",
  "battery",
  "caffeine",
  "clock",
  "tray",
  "settings"
],
"moduleVisibility": {
  "media": true,
  "bluetooth": true,
  "caffeine": false
}
```

Suggested `Settings.qml` label/icon additions:

```qml
"media": "Media",
"bluetooth": "Bluetooth",
"caffeine": "Caffeine"
```

```qml
"media": "󰝚",
"bluetooth": "󰂯",
"caffeine": "󰅶"
```
