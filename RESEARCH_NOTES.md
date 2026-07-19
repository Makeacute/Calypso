# Quickshell Bar Overhaul Research Notes

Reviewed on 2026-07-17 from temporary source clones and public pages. The main QML sources were `caelestia-dots/shell`, `end-4/dots-hyprland`, `doannc2212/quickshell-config`, and `bjarneo/quickshell`. Noctalia was also reviewed, but the current public `noctalia` / `noctalia-shell` source has moved away from QML into a native Wayland/OpenGL shell; its transferable ideas are configuration and widget-registry organization rather than QML component code. No code was copied.

Sources checked:
- https://github.com/noctalia-dev/noctalia
- https://github.com/noctalia-dev/noctalia-shell
- https://github.com/noctalia-dev/noctalia-qs
- https://github.com/caelestia-dots/shell at `00b2a0f`
- https://github.com/end-4/dots-hyprland at `446504a`
- https://github.com/doannc2212/quickshell-config at `4fa5e97`
- https://github.com/bjarneo/quickshell at `95bd0b9`

## Animation

Reusable patterns:
- Centralize motion names instead of scattering raw durations. Caelestia has wrapper animation types that distinguish spatial movement from color/opacity effects. end-4 exposes transition factories from a singleton style object. This makes a shell feel consistent without every widget inventing its own timing.
- Use faster color/opacity transitions than size or position transitions. Public configs commonly keep hover feedback around 80-180 ms, panel open/close around 150-250 ms, and larger spatial transitions a little longer.
- Separate enter/exit curves. Several configs use a softer open and a quicker close, especially for popups and panels.
- Animate local state, not whole layouts. Caelestia's workspace indicator animates its active indicator and small workspace contents, while loaders/popouts avoid keeping inactive UI live. This matches this repo's existing guardrail: `Workspace.qml` already gates focus indicator x/width animation to focus changes and keeps new-window feedback as a local pulse.
- Use delayed tooltips and hover feedback instead of large movement on hover. end-4 and bjarneo both use short hover delays or centralized tooltip overlays so sweeping across a bar does not flash every label.

How we could apply this here:
- Add motion tokens to `Settings.qml` or `Theme.qml`: `motionFast`, `motionNormal`, `motionSpatial`, plus easing choices. Keep `animationMs` as the user-facing scale, but derive named durations from it.
- Replace repeated `NumberAnimation { duration: settings.animationMs; easing.type: Easing.OutCubic }` in `Pill.qml`, `BarSection.qml`, `ModuleHost.qml`, `SettingsPanel.qml`, `Workspace.qml`, and `FocusedWindow.qml` with small local wrappers once the design stabilizes.
- Keep `Workspace.qml`'s current focus-only indicator animation policy. Do not animate `BarSection.qml` width or center positioning on every window open; reserve layout movement for module add/remove or workspace-focus changes.
- Add enter/exit asymmetry only to `SettingsPanel.qml` and future popouts: open can be 180-220 ms, close can be 120-160 ms. Bar pills should stay tighter.

## Primitives/Components

Reusable patterns:
- A small visual primitive set matters more than many bespoke widgets. The strongest configs define a base rectangle/surface, a button or state layer, text/icon helpers, and popup chrome.
- Caelestia's component layer separates `StyledRect`, clipping surfaces, state layers, icon text, and controls. end-4's Waffle family has a singleton look system plus button, menu, pane, switch, slider, tooltip, and shadow primitives. bjarneo keeps a smaller root-injected `Module` and `CardWindow` primitive for a compact bar.
- Button APIs usually expose state rather than style internals: `checked`, `selected`, `disabled`, `hover`, optional icon/text, alternate click, middle click, and tooltip.
- Popup/card primitives usually own keyboard focus, outside-click dismiss, anchor geometry, and reveal animation. Feature widgets only provide the body.
- Shared text/icon primitives handle optical offsets and font choices. This is useful with Nerd Font glyphs, where visual centering often differs from geometric centering.

How we could apply this here:
- Expand `widgets/Pill.qml` into the main low-level primitive rather than creating new one-off rectangles. Suggested API additions: `variant`, `selected`, `disabled`, `danger`, `tooltip`, `rightClicked`, `middleClicked`, `compact`, and `contentSpacing`.
- Extract the inline `IconButton`, `ToggleRow`, `StepperRow`, `ModuleRow`, and `AddButton` components from `SettingsPanel.qml` into separate reusable files only when they are needed outside settings. Until then, leave them local to avoid premature structure.
- Add a small `Surface.qml` primitive for `BarSection.qml` and `SettingsPanel.qml` that applies `theme.surface`, border, radius clamping, and antialiasing consistently. This reduces repeated border/radius logic and helps prevent scaled border artifacts.
- Add a `Tooltip.qml` or single tooltip overlay later, but keep it optional. Start with delayed hover state on `Pill.qml` so module code does not each implement tooltip timing.

## Effects

Reusable patterns:
- Most polished configs use translucency, layered alpha, and borders before reaching for heavy blur. end-4's Waffle look computes transparent layered colors and adds a subtle "acrylic" highlight line. Caelestia uses elevation/shadow primitives and turns GPU layer effects on only for specific surfaces.
- Blur is scoped. Caelestia enables blur/multieffect on special workspace transitions or larger background surfaces, not as a blanket effect on every pill. end-4 uses blur-style settings for panels/overlays, not tiny bar items.
- Shadows are subtle and often implemented as a 1 px ambient outline or a constrained rectangular shadow around popups. This avoids fuzzy artifacts around small scaled pills.
- Clipping and masks are deliberate. Rounded clipping is useful for popups and large surfaces, but small bar pills should avoid nested clipping unless content can overflow.
- Borders need to respect scale. If an item scales on hover, border width and radius should not expose an outer ring or clipped corner.

How we could apply this here:
- Keep `Theme.qml` as the source for alpha colors, but add named layers such as `surfaceHover`, `surfaceActive`, `surfacePanel`, `outlineSubtle`, and `shadowSubtle`. Keep these derived from the Stylix palette.
- Use translucency on `BarSection.qml` and `Pill.qml` through theme colors, not per-widget ad hoc `Qt.rgba` values.
- Avoid blur in the always-visible bar. If a future popup is added, scope blur/shadow to `SettingsPanel.qml` or popup windows only.
- In `Pill.qml` and `Workspace.qml`, prefer hover color/opacity over scale where the bar height is small. If scale remains, keep it tiny and avoid visible borders during scaled hover unless active/urgent.
- In `SettingsPanel.qml`, use a single shadow/outline around the panel surface rather than shadows on inner controls.

## Widgets

Reusable patterns:
- Bars feel richer when modules have direct but predictable interactions: left click opens/toggles, right click opens settings/details, middle click offers a quick action where useful, and scroll is limited to obvious continuous controls.
- Popouts are anchored to trigger items. Caelestia computes the current popout center from the hovered/tray item; bjarneo stores popup anchor coordinates from the clicked module. This makes menus feel connected without needing each module to own window geometry.
- System tray overflow and compact/expanded modes are common. Caelestia closes compact tray expansion when interacting elsewhere.
- Workspace widgets often use a separate active indicator under/behind static labels. This gives motion polish without relaying every workspace item.
- Focused window/task widgets should use stable item sizes and bounded title widths. bjarneo and end-4 use bounded labels and compact buttons; Caelestia uses optional window icons under workspaces.
- Services should be event-driven where possible, with polling only for data that has no event source. This matches the current `services/NiriService.qml` direction.

How we could apply this here:
- Keep `services/NiriService.qml` event-stream based. Do not replace it with polling. Its `sync()` fallback after actions is appropriate.
- Keep `FocusedWindow.qml` showing all windows on the focused workspace. Add optional right-click or middle-click actions later, but do not change its model semantics.
- Add per-module interaction contracts in `ModuleHost.qml`: each module can expose optional `tooltip`, `onSecondary`, `onTertiary`, and `settingsTarget` properties, while `Pill.qml` handles pointer plumbing.
- For `Workspace.qml`, keep the active indicator as a separate rectangle behind labels. Future polish should adjust indicator color, trail, and pulse, not animate the whole `Row`.
- For `Audio.qml`, `Network.qml`, `Battery.qml`, `Cpu.qml`, and `Memory.qml`, consider one shared compact metric pill layout: icon, optional value, warning state, tooltip/details. Keep polling intervals in `Settings.qml`.

## Settings/Customization

Reusable patterns:
- Mature shells separate raw config from UI organization. Caelestia has typed config sections; end-4's settings app groups pages into clear content sections and rows; Noctalia's current native shell uses TOML defaults, GUI-managed overrides, validation, and widget registries.
- Settings controls are domain-specific: segmented selections for modes, switches for booleans, steppers/sliders for numbers, and add/remove lists for modules.
- Advanced or risky options are hidden behind advanced sections. This keeps common layout choices easy without burying power users.
- Settings pages often show live preview or immediate apply. Quickshell configs typically bind controls directly to config state and rely on file hot reload/save debounce.
- Module customization works better when each module has metadata: id, label, icon, supported sections, default visibility, and optional settings.

How we could apply this here:
- `Settings.qml` already has the right foundation: `settings.json`, debounced save, module arrays, module labels/icons, and polling intervals. Keep this structure.
- Split `SettingsPanel.qml` visually into clearer sections: modules, layout, shape, typography, interaction, and performance. It can stay one QML file for now.
- Add segmented controls in `SettingsPanel.qml` for future choices like bar density, panel style, workspace indicator style, and focused-window mode. Keep steppers for numeric values.
- Move module metadata toward a single data list in `Settings.qml` instead of separate `availableModules`, `moduleLabel()`, and `moduleIcon()` maps. `ModuleHost.qml` can still own component resolution.
- Add an advanced section for polling intervals and animation scale so normal settings do not invite accidental performance regressions.

## Structure

Reusable patterns:
- Strong configs separate shell surfaces, services, style tokens, widgets, and settings. The names differ, but the shape is consistent: `services/` for data, `components/` or `looks/` for primitives, `modules/` or `widgets/` for features, and config/settings as a singleton.
- Module registration is usually declarative. Caelestia uses a config entry list plus delegate choices; end-4 uses loaders and panel families; Noctalia has explicit widget registries in the native codebase. This is easier to extend than long conditionals once the module count grows.
- Lazy loading is used for panels/popouts/heavy pages. Always-visible bar items stay lightweight.
- IPC is useful for toggling major surfaces, but bar internals should not depend on external scripts when Quickshell services already provide state.
- Multi-monitor handling is a first-class structure in public configs. Per-screen panel instances share services and style state but keep screen-local layout.

How we could apply this here:
- Keep the current structure: `Bar.qml` owns the panel, `BarSection.qml` owns section chrome, `ModuleHost.qml` maps ids to widgets, `Settings.qml` owns config, `Theme.qml` owns palette, and `services/NiriService.qml` owns Niri state.
- If module count grows, replace `ModuleHost.qml`'s `componentFor()` chain with a small registry object or list of entries. Do this only after adding enough modules to justify it.
- Consider adding a `components/` directory later for `Surface.qml`, `IconButton.qml`, `Tooltip.qml`, and maybe `Motion.qml`. Do not move existing files just for aesthetics.
- Keep `widgets/RightModules.qml` only if it is still used; otherwise prefer the section-driven `leftModules`, `centerModules`, and `rightModules` arrays already in `settings.json`.
- Do not introduce broad polling or global layout animation. Use loaders for future heavy popups, keep metric polling intervals explicit in `Settings.qml`, and keep Niri updates event-driven.

## Short Direction

The best fit for this project is not to clone Noctalia/Caelestia/end-4 visually. The reusable direction is a tighter local design system:

- `Theme.qml`: richer named color layers from Stylix.
- `Settings.qml`: named motion/density tokens plus module metadata.
- `Pill.qml`: one polished interactive primitive with consistent hover, active, warning, and pointer behavior.
- `BarSection.qml`: stable island surface with clamped size/radius and no surprise relayout animation.
- `Workspace.qml`: active indicator polish and local pulses only.
- `SettingsPanel.qml`: better grouped controls, optional advanced section, and future segmented choices.
- `ModuleHost.qml`: keep current section-driven registration, then move to a registry only when the module list becomes painful.
