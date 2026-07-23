.pragma library

var flatPaths = {
    "performanceMode": "app.performanceMode",
    "reduceMotion": "app.reduceMotion",

    "barHeight": "bar.height",
    "screenMargin": "bar.screenMargin",
    "reserveSpace": "bar.reserveSpace",
    "groupPadding": "bar.groupPadding",
    "pillPadding": "bar.pillPadding",
    "groupSpacing": "bar.groupSpacing",
    "itemSpacing": "bar.itemSpacing",
    "groupRadius": "bar.groupRadius",
    "pillRadius": "bar.pillRadius",
    "barStyle": "bar.style",
    "barPosition": "bar.position",
    "barBlur": "bar.blur",
    "barOpacity": "bar.opacity",
    "barBorderEnabled": "bar.borderEnabled",
    "barBorderThickness": "bar.borderThickness",
    "barAutohide": "bar.autohide",
    "widgetStyle": "bar.widgetStyle",

    "themeRecipe": "theme.recipe",
    "visualPreset": "theme.visualPreset",
    "surfaceStyle": "theme.surfaceStyle",
    "pillStyle": "theme.pillStyle",
    "hoverEffect": "theme.hoverEffect",
    "popupMotion": "theme.popupMotion",
    "animationProfile": "theme.animationProfile",
    "settingsPreset": "theme.settingsPreset",
    "iconMorphTransitions": "theme.iconMorphTransitions",
    "spacingScale": "theme.spacingScale",
    "radiusScale": "theme.radiusScale",
    "animationMs": "theme.animationMs",
    "motionFast": "theme.motionFast",
    "motionNormal": "theme.motionNormal",
    "motionHover": "theme.motionHover",
    "motionPulse": "theme.motionPulse",
    "motionBreath": "theme.motionBreath",
    "motionOpen": "theme.motionOpen",
    "motionClose": "theme.motionClose",
    "motionSpatial": "theme.motionSpatial",
    "motionEmphasis": "theme.motionEmphasis",
    "panelOpacity": "theme.panelOpacity",
    "blurEnabled": "theme.blurEnabled",
    "fontFamily": "theme.fontFamily",
    "fontFamilySans": "theme.fontFamilySans",
    "fontFamilyMono": "theme.fontFamilyMono",
    "fontFamilyIcon": "theme.fontFamilyIcon",
    "fontSize": "theme.fontSize",
    "iconSize": "theme.iconSize",
    "palettePath": "theme.palettePath",
    "paletteSource": "theme.paletteSource",
    "manualAccent": "theme.manualAccent",
    "customPaletteJson": "theme.customPaletteJson",
    "matugenEnabled": "theme.matugenEnabled",
    "matugenMode": "theme.matugenMode",
    "matugenScheme": "theme.matugenScheme",

    "settingsPanelWidth": "panels.settings.width",
    "settingsPanelGap": "panels.settings.gap",
    "settingsPanelPage": "panels.settings.page",
    "settingsPanelMode": "panels.settings.mode",
    "settingsPanelAnchor": "panels.settings.anchor",
    "settingsPanelDensity": "panels.settings.density",
    "settingsChangedFooter": "panels.settings.changedFooter",
    "settingsPreviewEnabled": "panels.settings.previewEnabled",
    "osdEnabled": "panels.osd.enabled",
    "osdPosition": "panels.osd.position",
    "osdStyle": "panels.osd.style",
    "osdTimeout": "panels.osd.timeout",
    "osdSize": "panels.osd.size",
    "osdOpacity": "panels.osd.opacity",
    "osdShowIcon": "panels.osd.showIcon",
    "osdShowPercent": "panels.osd.showPercent",
    "osdVolume": "panels.osd.volume",
    "osdBrightness": "panels.osd.brightness",
    "osdKeyboardBacklight": "panels.osd.keyboardBacklight",
    "osdCapsLock": "panels.osd.capsLock",
    "osdNumLock": "panels.osd.numLock",
    "osdMedia": "panels.osd.media",
    "osdBattery": "panels.osd.battery",
    "calendarWeekStart": "panels.clock.weekStart",
    "clockPanelShowWeek": "panels.clock.showWeek",
    "clockPanelShowDayOfYear": "panels.clock.showDayOfYear",
    "clockPanelShowTimezone": "panels.clock.showTimezone",
    "dashboardPanelWidth": "panels.dashboard.width",
    "dashboardShowMedia": "panels.dashboard.showMedia",
    "dashboardShowWeather": "panels.dashboard.showWeather",
    "dashboardGrowFromTrigger": "panels.dashboard.growFromTrigger",
    "dashboardQuickToggles": "panels.dashboard.quickToggles",
    "dashboardPerformanceModules": "panels.dashboard.performanceModules",
    "notepadPanelWidth": "panels.notepad.width",
    "notepadFilePath": "panels.notepad.filePath",
    "notepadAutosaveMs": "panels.notepad.autosaveMs",
    "clipboardPanelWidth": "panels.clipboard.width",
    "clipboardMaxItems": "panels.clipboard.maxItems",
    "processPanelWidth": "panels.processes.width",
    "processListLimit": "panels.processes.listLimit",
    "notificationsPanelWidth": "panels.notifications.width",
    "notificationsMaxVisible": "panels.notifications.maxVisible",
    "notificationsGroupByApp": "panels.notifications.groupByApp",
    "notificationsGroupsExpanded": "panels.notifications.groupsExpanded",
    "notificationsShowBody": "panels.notifications.showBody",
    "notificationsShowImages": "panels.notifications.showImages",
    "notificationsShowActions": "panels.notifications.showActions",
    "launcherPanelWidth": "panels.launcher.width",
    "launcherMaxResults": "panels.launcher.maxResults",
    "launcherSearchPlaceholder": "panels.launcher.searchPlaceholder",
    "launcherUseFuzzy": "panels.launcher.useFuzzy",
    "launcherSortMode": "panels.launcher.sortMode",
    "launcherShowIcons": "panels.launcher.showIcons",
    "launcherShowDescriptions": "panels.launcher.showDescriptions",
    "launcherCompactRows": "panels.launcher.compactRows",
    "launcherVimKeybinds": "panels.launcher.vimKeybinds",
    "launcherCloseOnLaunch": "panels.launcher.closeOnLaunch",
    "launcherFavorites": "panels.launcher.favorites",
    "launcherHiddenApps": "panels.launcher.hiddenApps",
    "modulePopupPinned": "panels.modulePopup.pinned",
    "modulePopupDefaultTab": "panels.modulePopup.defaultTab",
    "modulePopupShowGauge": "panels.modulePopup.showGauge",
    "modulePopupShowSparkline": "panels.modulePopup.showSparkline",
    "modulePopupHistorySamples": "panels.modulePopup.historySamples",
    "modulePopupNetworkScaleKib": "panels.modulePopup.networkScaleKib",

    "polling": "services.polling",
    "compositor": "services.compositor",
    "clipboardBackend": "services.clipboard.backend",
    "wallpaperDirectory": "services.wallpaper.directory",
    "wallpaperRecursive": "services.wallpaper.recursive",
    "currentWallpaper": "services.wallpaper.current",
    "wallpaperFavorites": "services.wallpaper.favorites",
    "wallpaperBackend": "services.wallpaper.backend",
    "wallpaperResizeMode": "services.wallpaper.resizeMode",
    "wallpaperCropGravity": "services.wallpaper.cropGravity",
    "wallpaperApplyColors": "services.wallpaper.applyColors",
    "wallpaperTransition": "services.wallpaper.transition",
    "wallpaperTransitionDuration": "services.wallpaper.transitionDuration",
    "wallpaperTransitionFps": "services.wallpaper.transitionFps",
    "wallpaperTransitionPosition": "services.wallpaper.transitionPosition",
    "wallpaperTransitionAngle": "services.wallpaper.transitionAngle",
    "wallpaperTransitionBezier": "services.wallpaper.transitionBezier",
    "wallpaperRandomMode": "services.wallpaper.randomMode",
    "wallpaperSelectedPreview": "services.wallpaper.selectedPreview",
    "wallpaperLastError": "services.wallpaper.lastError",
    "wallpaperLastApplied": "services.wallpaper.lastApplied",
    "wallpaperLastPalette": "services.wallpaper.lastPalette",

    "tooltipDelay": "ui.tooltipDelay",
    "tooltipsEnabled": "ui.tooltipsEnabled",
    "workspaceToastTimeout": "ui.workspaceToastTimeout"
};

var moduleSettings = {
    "workspaceIndicatorStyle": ["workspaces", "indicatorStyle"],
    "workspaceMinWidth": ["workspaces", "minWidth"],
    "workspaceShowNumbers": ["workspaces", "showNumbers"],
    "workspaceShowOccupied": ["workspaces", "showOccupied"],
    "workspaceShowAppIcons": ["workspaces", "showAppIcons"],
    "workspaceMaxAppIcons": ["workspaces", "maxAppIcons"],
    "workspaceScrollEnabled": ["workspaces", "scrollEnabled"],
    "workspaceScrollWrap": ["workspaces", "scrollWrap"],
    "focusedWindowMaxWidth": ["focusedWindow", "maxWidth"],
    "focusedWindowShowTitle": ["focusedWindow", "showTitle"],
    "focusedWindowDisplayMode": ["focusedWindow", "displayMode"],
    "clockFormat": ["clock", "format"],
    "clockShowSeconds": ["clock", "showSeconds"],
    "audioShowPercentage": ["audio", "showPercentage"],
    "audioShowDeviceName": ["audio", "showDeviceName"],
    "networkInterfaceName": ["network", "interfaceName"],
    "networkShowSpeed": ["network", "showSpeed"],
    "batteryShowPercentage": ["battery", "showPercentage"],
    "batteryCriticalThreshold": ["battery", "criticalThreshold"],
    "cpuShowGraph": ["cpu", "showGraph"],
    "memoryShowGraph": ["memory", "showGraph"],
    "brightnessShowPercentage": ["brightness", "showPercentage"],
    "brightnessStep": ["brightness", "step"],
    "powerProfileShowLabel": ["powerProfile", "showLabel"],
    "mediaShowControls": ["media", "showControls"],
    "mediaMaxWidth": ["media", "maxWidth"],
    "mediaMaxTitleLength": ["media", "maxTitleLength"],
    "trayCompact": ["tray", "compact"],
    "trayIconSize": ["tray", "iconSize"],
    "trayMaxVisible": ["tray", "maxVisible"]
};

function moduleInstance(type, enabled, settings) {
    return { "type": type, "enabled": enabled, "settings": settings || {} };
}

function create(home, configHome) {
    var configRoot = configHome && configHome.length > 0
        ? configHome
        : home + "/.config";

    return {
        "version": 4,
        "app": {
            "performanceMode": false,
            "reduceMotion": false
        },
        "bar": {
            "height": 32,
            "screenMargin": 8,
            "reserveSpace": true,
            "groupPadding": 4,
            "pillPadding": 8,
            "groupSpacing": 6,
            "itemSpacing": 5,
            "groupRadius": 12,
            "pillRadius": 9,
            "style": "islands",
            "position": "top",
            "blur": true,
            "opacity": 0.85,
            "borderEnabled": false,
            "borderThickness": 1,
            "autohide": false,
            "widgetStyle": "iconAndText"
        },
        "theme": {
            "recipe": "custom",
            "visualPreset": "noctaliaQuiet",
            "surfaceStyle": "translucent",
            "pillStyle": "soft",
            "hoverEffect": "wash",
            "popupMotion": "slide",
            "animationProfile": "Physical",
            "settingsPreset": "Balanced",
            "iconMorphTransitions": true,
            "spacingScale": 1.0,
            "radiusScale": 1.0,
            "animationMs": 160,
            "motionFast": 80,
            "motionNormal": 160,
            "motionHover": 100,
            "motionPulse": 220,
            "motionBreath": 1800,
            "motionOpen": 220,
            "motionClose": 180,
            "motionSpatial": 200,
            "motionEmphasis": 240,
            "panelOpacity": 97,
            "blurEnabled": false,
            "fontFamily": "JetBrainsMono Nerd Font",
            "fontFamilySans": "DejaVu Sans",
            "fontFamilyMono": "JetBrainsMono Nerd Font",
            "fontFamilyIcon": "JetBrainsMono Nerd Font",
            "fontSize": 12,
            "iconSize": 16,
            "palettePath": configRoot + "/quickshell/palette.json",
            "paletteSource": "wallpaper",
            "manualAccent": "#90a4c8",
            "customPaletteJson": "",
            "matugenEnabled": true,
            "matugenMode": "dark",
            "matugenScheme": "scheme-tonal-spot"
        },
        "modules": {
            "left": ["workspaces", "media"],
            "center": ["clock"],
            "right": ["audio", "network", "battery", "cpu", "memory", "tray", "settings"],
            "instances": {
                "settings": moduleInstance("settings", true),
                "workspaces": moduleInstance("workspaces", true, {
                    "indicatorStyle": "pill", "minWidth": 26, "showNumbers": true,
                    "showOccupied": true, "showAppIcons": false, "maxAppIcons": 4,
                    "scrollEnabled": true, "scrollWrap": true
                }),
                "focusedWindow": moduleInstance("focusedWindow", true, {
                    "maxWidth": 280, "showTitle": false, "displayMode": "allWorkspaceApps"
                }),
                "cpu": moduleInstance("cpu", true, { "showGraph": false }),
                "memory": moduleInstance("memory", true, { "showGraph": false }),
                "network": moduleInstance("network", true, { "interfaceName": "", "showSpeed": false }),
                "bluetooth": moduleInstance("bluetooth", true),
                "audio": moduleInstance("audio", true, { "showPercentage": true, "showDeviceName": false }),
                "brightness": moduleInstance("brightness", false, { "showPercentage": true, "step": 5 }),
                "powerProfile": moduleInstance("powerProfile", false, { "showLabel": true }),
                "media": moduleInstance("media", true, {
                    "showControls": true, "maxWidth": 180, "maxTitleLength": 36
                }),
                "battery": moduleInstance("battery", true, {
                    "showPercentage": true, "criticalThreshold": 15
                }),
                "caffeine": moduleInstance("caffeine", false),
                "clock": moduleInstance("clock", true, { "format": "HH:mm", "showSeconds": false }),
                "dashboard": moduleInstance("dashboard", false),
                "launcher": moduleInstance("launcher", false),
                "notepad": moduleInstance("notepad", false),
                "clipboard": moduleInstance("clipboard", false),
                "processes": moduleInstance("processes", false),
                "tray": moduleInstance("tray", false, { "compact": true, "iconSize": 16, "maxVisible": 6 })
            }
        },
        "panels": {
            "settings": {
                "width": 780, "gap": 8, "page": "overview", "mode": "auto",
                "anchor": "button", "density": "balanced", "changedFooter": true,
                "previewEnabled": true
            },
            "osd": {
                "enabled": true, "position": "rightCenter", "style": "vertical",
                "timeout": 1500, "size": 1.0, "opacity": 0.96, "showIcon": true,
                "showPercent": true, "volume": true, "brightness": true,
                "keyboardBacklight": true, "capsLock": true, "numLock": true,
                "media": true, "battery": true
            },
            "clock": {
                "weekStart": 1, "showWeek": true, "showDayOfYear": true,
                "showTimezone": true
            },
            "dashboard": {
                "width": 420, "showMedia": true, "showWeather": false,
                "growFromTrigger": true,
                "quickToggles": ["wifi", "bluetooth", "mic", "dnd"],
                "performanceModules": ["cpu", "memory", "network", "battery"]
            },
            "notepad": { "width": 420, "filePath": "", "autosaveMs": 600 },
            "clipboard": { "width": 460, "maxItems": 20 },
            "processes": { "width": 520, "listLimit": 12 },
            "notifications": {
                "width": 460, "maxVisible": 24, "groupByApp": true,
                "groupsExpanded": true, "showBody": true, "showImages": true,
                "showActions": true
            },
            "launcher": {
                "width": 520, "maxResults": 12, "searchPlaceholder": "Search apps",
                "useFuzzy": true, "sortMode": "relevance", "showIcons": true,
                "showDescriptions": true, "compactRows": false, "vimKeybinds": false,
                "closeOnLaunch": true, "favorites": [], "hiddenApps": []
            },
            "modulePopup": {
                "pinned": false, "defaultTab": "Overview", "showGauge": true,
                "showSparkline": true, "historySamples": 24, "networkScaleKib": 10240
            }
        },
        "services": {
            "polling": {
                "cpuMs": 30000, "memoryMs": 5000, "networkMs": 5000,
                "mediaMs": 2000, "dashboardMediaMs": 500, "dashboardStateMs": 5000,
                "processListMs": 5000, "batteryFallbackMs": 30000, "clockMs": 1000,
                "brightnessMs": 15000, "powerProfileMs": 30000
            },
            "compositor": {
                "backend": "auto", "preferred": ["niri", "hyprland"],
                "showUnsupportedModules": false
            },
            "clipboard": { "backend": "auto" },
            "wallpaper": {
                "directory": home + "/Pictures/Wallpapers", "recursive": true,
                "current": "", "favorites": [], "backend": "awww", "resizeMode": "crop",
                "cropGravity": "center", "applyColors": true, "transition": "grow",
                "transitionDuration": 1.0, "transitionFps": 60,
                "transitionPosition": "center", "transitionAngle": 45,
                "transitionBezier": ".54,0,.34,.99", "randomMode": "any",
                "selectedPreview": "", "lastError": "", "lastApplied": "", "lastPalette": ""
            }
        },
        "ui": {
            "tooltipDelay": 600,
            "tooltipsEnabled": true,
            "workspaceToastTimeout": 1000
        },
        "migration": {
            "sourceVersion": 3,
            "migratedAt": "",
            "unmapped": {}
        }
    };
}
