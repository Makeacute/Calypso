# AGENTS.md — Calypso

Calypso is a Quickshell bar for Niri. Design priorities, in order: low idle cost,
polished visuals, physical-feeling motion. Read this fully before making changes.

## Non-negotiable rules

- Never hardcode colors, pixel sizes, spacing, radii, or animation durations in
  widget code. Always use `theme.*` tokens (`theme.motionFast/Normal/Hover/...`,
  `theme.spacingXS/S/M/L/XL`, `theme.radiusS/M/L/XL`) or `settings.effective*`
  values. If a token you need doesn't exist, add it to `Theme.qml` — don't inline
  a value "just this once."
- Every new widget must support all three `settings.widgetStyle` modes:
  `iconOnly`, `iconAndText`, `expanded`. Prefer `Pill.qml` for compact bar modules.
- Colors come from `Theme.qml`'s Matugen/Stylix adapter. Never assume
  `palette.json` exists — `Theme.qml` must keep working with its dark fallback
  if the file is missing or malformed. Test this by temporarily renaming
  `~/.config/stylix/palette.json` and confirming the bar still renders.
- `settings.reduceMotion` must collapse all token-derived animations to instant
  (via `theme.motionScale = 0`). Any new animated property must respect this,
  not bypass it with a hardcoded duration.
- Respect `settings.performanceMode` — new features that add continuous
  animation, polling, or rendering cost should degrade or disable under it.

## Performance discipline (read this before adding ANY animation or poller)

- Prefer event-driven services over polling. If polling is unavoidable, it must
  be configurable under the `polling.*` settings keys, not a fixed interval
  buried in code.
- No idle "breathing" or continuously-looping animation on always-visible
  elements. This project already had one idle-CPU bug caused by uncontrolled
  event spam (Niri terminal-title updates) — don't reintroduce that class of bug.
  Any animation on an always-visible element must be interaction-triggered, not
  time-looped.
- After adding or changing ANY animation, transition, or polling interval,
  verify idle CPU before considering the task done:
  `top -b -n 1 -p <quickshell-pid>` sampled over at least 60s of idle, compared
  against a baseline taken before your change.
- After adding a new persistent surface (a panel/drawer that can be left open,
  like a dashboard or notification view), sample idle CPU both with it closed
  AND left open — these are different cost profiles.
- Check the Quickshell log for new warnings after every change:
  `tail -n 120 /run/user/1000/quickshell/by-id/<instance>/log.qslog | strings | rg 'WARN|ERROR'`

## Architecture

- `shell.qml` creates one `Bar` per screen. `Bar.qml` owns settings, theme,
  compositor service, layout modes, popups, OSD, tooltip host, workspace toast.
- Services (`services/`) should be compositor-abstracted where reasonable — this
  project targets Niri specifically via `NiriService.qml`, but keep
  `CompositorService.qml` as the seam if that ever needs to change.
- Long-running integrations (notification service, audio, Niri event stream)
  should have reconnect/retry logic, not die silently on a compositor restart.
- Bar `PanelWindow` must set an explicit `exclusiveZone` matching bar height so
  windows tile correctly around it. This must stay correct across
  `barHeight`/`barPosition`/`barAutohide` changes, including mid-transition
  during autohide slide animations.
- Widget registration: add `widgets/X.qml` → register id in `ModuleHost.qml` →
  add metadata to `Settings.qml` `moduleRegistry` → add id to
  `availableModules`/`moduleVisibility`/a default section list in
  `settings.json` if it should ship enabled by default.

## Verification checklist (run before marking any task complete)

1. `python3 -m json.tool settings.json >/dev/null` — settings still valid JSON
2. Screenshot the change in context (not just the isolated widget)
3. Idle CPU sample per the performance section above, if animation/polling touched
4. Quickshell log check for new warnings
5. If the change affects layout: verify in all three `barStyle` modes
   (islands/solid/pill) and both `barPosition` values (top/bottom)

## What NOT to do without discussion first

- Don't add a new always-on background poller without adding a corresponding
  `polling.*` settings key.
- Don't restructure `settings.json` schema without a fallback/migration path —
  existing user configs must keep loading.
- Don't introduce a new top-level UI surface (dashboard, launcher, EQ panel)
  without checking in first — these are architecture decisions, not incremental
  widget tweaks.
