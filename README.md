# Calypso

Calypso is a lightweight Quickshell bar for Niri. Its design priorities are polished visuals, physical-feeling motion, and low idle cost: event-driven services are preferred, polling is explicit and configurable, and visual effects stay tokenized.

## Structure

- `shell.qml`: creates one `Bar` per Quickshell screen.
- `Bar.qml`: owns settings, theme, compositor service, bar layout modes, popups, OSD, tooltip host, and workspace toast.
- `Theme.qml`: Stylix palette adapter, safe dark fallbacks, color helpers, motion tokens, spacing tokens, and radius tokens.
- `Settings.qml`: JSON adapter, derived sizing, motion compatibility values, module layout helpers, and schema defaults.
- `Surface.qml`: shared rounded/translucent surface primitive.
- `BarSection.qml`: island surface for one module section.
- `ModuleHost.qml`: module id to widget component registry.
- `SettingsPanel.qml`: live customization panel for appearance, layout, modules, widgets, behavior, and performance.
- `ClockPanel.qml`, `ControlCenterPanel.qml`, `ModuleDetailsPanel.qml`: anchored popups.
- `services/`: compositor, Niri event-stream, and wallpaper/palette services.
- `widgets/`: bar modules plus shared overlays such as `Osd.qml`, `TooltipHost.qml`, and `WorkspaceToast.qml`.
- `tools/calypso-perf-audit`: read-only performance snapshot helper.

## Design System

Colors come from `Theme.qml`. `Theme.alpha(color, opacity)` is the shared alpha helper. If `~/.config/stylix/palette.json` is missing or malformed, Calypso falls back to a complete dark palette.

Motion is centralized:

```qml
theme.motionFast
theme.motionNormal
theme.motionHover
theme.motionPulse
theme.motionBreath
theme.motionOpen
theme.motionClose
```

`settings.reduceMotion` sets `theme.motionScale` to `0`, collapsing token-derived animations to instant state changes.

Spacing and radius scale globally through:

```json
"spacingScale": 1.0,
"radiusScale": 1.0
```

Use `theme.spacingXS/S/M/L/XL`, `theme.radiusS/M/L/XL`, or the existing `settings.effective*` values. Do not hardcode colors, pixel sizes, or animation durations in new widgets.

## Bar Modes

`settings.barStyle` controls the bar container without changing module components:

- `islands`: separate floating left, center, and right groups.
- `solid`: one continuous full-width strip.
- `pill`: one centered island containing all configured modules.

`settings.barPosition` supports `top` and `bottom`. Anchored popups move above the bar in bottom mode. `settings.barAutohide` slides the bar content off edge while preserving a hover target.

## Wallpaper And Colors

The wallpaper selector scans `wallpaperDirectory`, optionally recursively, and applies images through `awww`. Transitions are controlled by `wallpaperTransition`, `wallpaperTransitionDuration`, `wallpaperTransitionFps`, `wallpaperTransitionPosition`, `wallpaperTransitionAngle`, and `wallpaperTransitionBezier`.

When `wallpaperApplyColors` and `matugenEnabled` are true, Calypso runs `matugen image` and writes a Base16-compatible `palette.json`. `Theme.qml` watches that file and falls back to a dark palette if it is missing or malformed.

## Notifications

`SettingsButton.qml` uses Quickshell's notification service to track non-transient desktop notifications and shows a small badge on the settings button while notifications are present. The badge is count-only; Calypso does not render notification popups.

## Adding A Widget

1. Add `widgets/MyWidget.qml`. Prefer `Pill` for compact bar modules.
2. Register the id in `ModuleHost.qml`.
3. Add module metadata to `Settings.qml` `moduleRegistry`.
4. Add the id to `availableModules`, `moduleVisibility`, and a default section list in `settings.json` if it should be available by default.
5. Add settings-panel controls only for behavior the widget actually supports.

Widgets should support `settings.widgetStyle`:

- `iconOnly`: icon only.
- `iconAndText`: icon plus compact value.
- `expanded`: icon, value, and lightweight detail text.

`Pill.qml` handles icon/text hiding, animated width, hover scale, color transitions, scroll/click routing, and delayed tooltips.

## Settings Keys

Core layout:

- `barStyle`, `barPosition`, `barAutohide`
- `barHeight`, `screenMargin`, `reserveSpace`
- `leftModules`, `centerModules`, `rightModules`, `moduleVisibility`

Appearance:

- `barBlur`, `barOpacity`, `barBorderEnabled`, `barBorderThickness`
- `spacingScale`, `radiusScale`
- `fontFamily`, `fontSize`, `iconSize`, `trayIconSize`
- `widgetStyle`

Behavior and motion:

- `reduceMotion`, `performanceMode`, `animationMs`
- `motionFast`, `motionNormal`, `motionHover`, `motionPulse`, `motionBreath`, `motionOpen`, `motionClose`, `motionSpatial`, `motionEmphasis`
- `osdEnabled`, `osdPosition`, `osdStyle`, `osdSize`, `osdOpacity`, `osdTimeout`
- `osdShowIcon`, `osdShowPercent`, `osdVolume`, `osdBrightness`, `osdKeyboardBacklight`, `osdMedia`, `osdBattery`
- `tooltipDelay`, `tooltipsEnabled`, `workspaceToastTimeout`

Widget options:

- `clockFormat`, `clockShowSeconds`, `calendarWeekStart`
- `audioShowPercentage`, `audioShowDeviceName`
- `networkShowSpeed`, `networkInterfaceName`
- `batteryShowPercentage`, `batteryCriticalThreshold`
- `mediaShowControls`, `mediaMaxWidth`, `mediaMaxTitleLength`
- `cpuShowGraph`, `memoryShowGraph`
- `brightnessShowPercentage`, `brightnessStep`
- `powerProfileShowLabel`
- `trayCompact`, `trayMaxVisible`
- workspace and focused-window display options

Wallpaper:

- `palettePath`, `paletteSource`, `manualAccent`
- `wallpaperDirectory`, `wallpaperRecursive`, `currentWallpaper`, `wallpaperFavorites`
- `wallpaperBackend`, `wallpaperResizeMode`, `wallpaperCropGravity`
- `wallpaperApplyColors`, `matugenEnabled`, `matugenMode`, `matugenScheme`
- `wallpaperTransition`, `wallpaperTransitionDuration`, `wallpaperTransitionFps`, `wallpaperTransitionPosition`, `wallpaperTransitionAngle`, `wallpaperTransitionBezier`
- `wallpaperLastApplied`, `wallpaperLastPalette`, `wallpaperLastError`

Polling:

- `polling.cpuMs`
- `polling.memoryMs`
- `polling.networkMs`
- `polling.batteryFallbackMs`
- `polling.clockMs`
- `polling.brightnessMs`
- `polling.powerProfileMs`

## Verification

Useful checks:

```sh
python3 -m json.tool settings.json >/dev/null
quickshell list --all
tail -n 120 /run/user/1000/quickshell/by-id/<instance>/log.qslog | strings | rg 'WARN|ERROR'
niri msg --json workspaces
niri msg --json windows
top -b -n 1 -p <quickshell-pid>
```

`qmllint` is available on this system, but without Quickshell/Qt import metadata it emits unresolved-import noise. Treat runtime logs as the authoritative warning source.
