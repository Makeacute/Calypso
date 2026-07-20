pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Item {
    id: root

    visible: false
    width: 0
    height: 0
    property bool applyingThemeRecipe: false

    signal changed()

    function localPath(url) {
        const value = String(url);
        return value.startsWith("file://") ? decodeURIComponent(value.slice(7)) : value;
    }

    function clamp(value, minimum, maximum) {
        const number = Number(value);
        if (!Number.isFinite(number)) return minimum;
        return Math.max(minimum, Math.min(maximum, Math.round(number)));
    }

    function setValue(name, value) {
        adapter[name] = value;
        markThemeRecipeCustom(name);
    }

    function setString(name, value) {
        adapter[name] = String(value);
        markThemeRecipeCustom(name);
    }

    function setNumber(name, value, minimum, maximum) {
        adapter[name] = clamp(value, minimum, maximum);
        markThemeRecipeCustom(name);
    }

    function clampReal(value, minimum, maximum) {
        const number = Number(value);
        if (!Number.isFinite(number)) return minimum;
        return Math.max(minimum, Math.min(maximum, number));
    }

    function setReal(name, value, minimum, maximum, step) {
        const safeStep = Number(step) > 0 ? Number(step) : 0;
        let next = clampReal(value, minimum, maximum);
        if (safeStep > 0) {
            next = minimum + Math.round((next - minimum) / safeStep) * safeStep;
            next = clampReal(next, minimum, maximum);
        }
        adapter[name] = Math.round(next * 1000) / 1000;
        markThemeRecipeCustom(name);
    }

    function setEnum(name, value, allowed, fallback) {
        const text = String(value || fallback || "");
        adapter[name] = allowed.indexOf(text) >= 0 ? text : fallback;
        markThemeRecipeCustom(name);
    }

    function markThemeRecipeCustom(name) {
        if (applyingThemeRecipe || !adapter || adapter.themeRecipe === "custom") return;

        const key = String(name || "");
        const tracked = [
            "barStyle", "barPosition", "barBlur", "barOpacity", "barBorderEnabled", "barBorderThickness",
            "widgetStyle", "surfaceStyle", "pillStyle", "hoverEffect", "visualPreset", "settingsPreset",
            "spacingScale", "radiusScale", "barHeight", "screenMargin", "groupPadding", "pillPadding",
            "groupSpacing", "itemSpacing", "settingsPanelDensity", "settingsPanelWidth", "settingsPanelAnchor"
        ];
        if (tracked.indexOf(key) >= 0)
            adapter.themeRecipe = "custom";
    }

    function applyMotionTokens(baseValue) {
        const base = clamp(baseValue, 0, 500);
        const scale = base === 0 ? 0 : base / 160;
        adapter.motionFast = Math.round(80 * scale);
        adapter.motionNormal = Math.round(160 * scale);
        adapter.motionHover = Math.round(100 * scale);
        adapter.motionPulse = Math.round(220 * scale);
        adapter.motionBreath = Math.round(1800 * scale);
        adapter.motionOpen = Math.round(220 * scale);
        adapter.motionClose = Math.round(180 * scale);
        adapter.motionSpatial = Math.round(200 * scale);
        adapter.motionEmphasis = Math.round(240 * scale);
    }

    function setAnimationMs(value) {
        const next = clamp(value, 0, 500);
        adapter.animationMs = next;
        if (!adapter.reduceMotion) applyMotionTokens(next);
    }

    function setReduceMotion(value) {
        adapter.reduceMotion = value;
        if (value) {
            adapter.motionHover = 0;
            adapter.motionFast = 0;
            adapter.motionNormal = 0;
            adapter.motionSpatial = 0;
            adapter.motionPulse = 0;
            adapter.motionBreath = 0;
            adapter.motionOpen = 0;
            adapter.motionClose = 0;
            adapter.motionEmphasis = 0;
        } else {
            applyMotionTokens(adapter.animationMs);
        }
    }

    function setPollingInterval(name, value, minimum, maximum) {
        const polling = Object.assign({}, adapter.polling || {});
        polling[name] = clamp(value, minimum, maximum);
        adapter.polling = polling;
    }

    function setStringList(name, values) {
        adapter[name] = Array.from(values || []).map(value => String(value));
    }

    function setObjectValue(objectName, key, value) {
        const next = Object.assign({}, adapter[objectName] || {});
        next[key] = value;
        adapter[objectName] = next;
    }

    function toggleStringInList(name, value) {
        const current = Array.from(adapter[name] || []);
        const text = String(value || "");
        const index = current.indexOf(text);
        if (index >= 0) current.splice(index, 1);
        else current.push(text);
        adapter[name] = current;
    }

    function includesString(name, value) {
        return Array.from(adapter[name] || []).indexOf(String(value || "")) >= 0;
    }

    function normalizedStringList(values) {
        return Array.from(values || []).map(value => String(value || "").trim()).filter(value => value.length > 0);
    }

    function supplementalModuleRegistry() {
        return [
            { "id": "dashboard", "label": "Dashboard", "icon": "󰒓", "category": "Shell", "aliases": ["controls", "controlCenter", "quickControls"], "defaultSection": "right", "defaultVisible": false, "configurable": false, "cost": "lazy", "capabilities": [] },
            { "id": "launcher", "label": "Launcher", "icon": "󰀻", "category": "Shell", "aliases": ["apps", "appLauncher"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "lazy", "capabilities": ["desktopEntries", "fuzzySearch"] },
            { "id": "notepad", "label": "Notepad", "icon": "󰎞", "category": "Shell", "aliases": ["scratchpad", "notes"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "lazy", "capabilities": ["autosave"] },
            { "id": "clipboard", "label": "Clipboard", "icon": "󰅌", "category": "Shell", "aliases": ["cliphist", "clip"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "open polling", "capabilities": ["history", "images"] },
            { "id": "processes", "label": "Processes", "icon": "󰒋", "category": "System", "aliases": ["processList", "tasks"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "open polling", "capabilities": ["sort", "temperature"] }
        ];
    }

    function mergedModuleRegistry(source) {
        const merged = Array.from(source || []);
        const seen = {};
        for (let i = 0; i < merged.length; i++)
            seen[String(merged[i].id || "")] = true;

        const supplemental = supplementalModuleRegistry();
        for (let j = 0; j < supplemental.length; j++) {
            const id = String(supplemental[j].id || "");
            if (!seen[id]) {
                merged.push(supplemental[j]);
                seen[id] = true;
            }
        }
        return merged;
    }

    function mergedAvailableModules(source) {
        const merged = [];
        const sourceModules = Array.from(source || []);
        for (let i = 0; i < sourceModules.length; i++) {
            const id = moduleId(sourceModules[i]);
            if (merged.indexOf(id) < 0)
                merged.push(id);
        }

        const supplemental = supplementalModuleRegistry();
        for (let j = 0; j < supplemental.length; j++) {
            const id = String(supplemental[j].id || "");
            if (merged.indexOf(id) < 0)
                merged.push(id);
        }
        return merged;
    }

    function moduleEntry(moduleName) {
        const entries = Array.from(moduleRegistry || []);
        for (let i = 0; i < entries.length; i++) {
            if (entries[i].id === moduleName) return entries[i];
            const aliases = Array.from(entries[i].aliases || []);
            if (aliases.indexOf(moduleName) >= 0) return entries[i];
        }

        return {
            "id": String(moduleName),
            "label": String(moduleName),
            "icon": "󰀻",
            "category": "Other",
            "aliases": [],
            "defaultSection": "right",
            "defaultVisible": false,
            "configurable": false,
            "cost": "unknown",
            "capabilities": []
        };
    }

    function moduleId(moduleName) {
        return String(moduleEntry(moduleName).id || moduleName);
    }

    function moduleDefaultSection(moduleName) {
        const section = String(moduleEntry(moduleName).defaultSection || "right");
        return section === "left" || section === "center" || section === "right" ? section : "right";
    }

    function moduleStatus(moduleName) {
        if (!enabled(moduleName)) return "disabled";

        const cost = String(moduleCost(moduleName) || "").toLowerCase();
        if (cost.indexOf("polling") >= 0) return "polling";
        if (cost.indexOf("event") >= 0) return "live";
        if (cost.indexOf("timer") >= 0) return "timer";
        if (cost.indexOf("lazy") >= 0) return "lazy";
        if (cost.indexOf("local") >= 0) return "local";
        return cost.length > 0 ? cost : "unknown";
    }

    function moduleUsed(moduleName) {
        const target = moduleId(moduleName);
        const modules = sectionModules("left").concat(sectionModules("center")).concat(sectionModules("right"));
        for (let i = 0; i < modules.length; i++) {
            if (moduleId(modules[i]) === target)
                return true;
        }
        return false;
    }

    function unusedModules() {
        const modules = Array.from(availableModules || []);
        const unused = [];
        for (let i = 0; i < modules.length; i++) {
            if (!moduleUsed(modules[i])) unused.push(modules[i]);
        }
        return unused;
    }

    function setClockFormat(value) {
        const next = String(value || "HH:mm");
        adapter.clockFormat = next;
        adapter.clockShowSeconds = next.indexOf("s") >= 0 || next.indexOf("z") >= 0;
    }

    function setClockShowSeconds(value) {
        adapter.clockShowSeconds = value;
        const current = String(adapter.clockFormat || "HH:mm");

        if (value) {
            if (current.indexOf("s") < 0 && current.indexOf("z") < 0) {
                adapter.clockFormat = current.length > 0 ? current + ":ss" : "HH:mm:ss";
            }
        } else if (current === "HH:mm:ss") {
            adapter.clockFormat = "HH:mm";
        } else if (current.indexOf(":ss") >= 0) {
            adapter.clockFormat = current.replace(":ss", "");
        }
    }

    function setVisualPreset(value) {
        const preset = String(value || "noctaliaQuiet");
        adapter.visualPreset = preset;
        markThemeRecipeCustom("visualPreset");

        if (preset === "frostedMinimal") {
            adapter.surfaceStyle = "frosted";
            adapter.pillStyle = "soft";
            adapter.hoverEffect = "wash";
            adapter.popupMotion = "slide";
        } else if (preset === "materialMorphing") {
            adapter.surfaceStyle = "translucent";
            adapter.pillStyle = "filled";
            adapter.hoverEffect = "scale";
            adapter.popupMotion = "slide";
        } else {
            adapter.surfaceStyle = "translucent";
            adapter.pillStyle = "soft";
            adapter.hoverEffect = "wash";
            adapter.popupMotion = "slide";
        }
    }

    function setAnimationProfile(value) {
        const profile = String(value || "Physical");
        adapter.animationProfile = profile;

        if (profile === "Instant") {
            setReduceMotion(true);
        } else {
            if (adapter.reduceMotion) adapter.reduceMotion = false;
            if (profile === "Snappy") setAnimationMs(120);
            else if (profile === "Calm") setAnimationMs(220);
            else setAnimationMs(160);
        }
    }

    function setSettingsPreset(value) {
        const preset = String(value || "Balanced");
        adapter.settingsPreset = preset;
        markThemeRecipeCustom("settingsPreset");

        if (preset === "Compact") {
            adapter.settingsPanelDensity = "compact";
            adapter.barHeight = 28;
            adapter.groupPadding = 3;
            adapter.pillPadding = 6;
            adapter.groupSpacing = 4;
            adapter.itemSpacing = 4;
            adapter.spacingScale = 0.85;
            adapter.radiusScale = 0.9;
        } else if (preset === "Roomy") {
            adapter.settingsPanelDensity = "roomy";
            adapter.barHeight = 38;
            adapter.groupPadding = 5;
            adapter.pillPadding = 10;
            adapter.groupSpacing = 8;
            adapter.itemSpacing = 6;
            adapter.spacingScale = 1.18;
            adapter.radiusScale = 1.08;
        } else {
            adapter.settingsPanelDensity = "balanced";
            adapter.barHeight = 32;
            adapter.groupPadding = 4;
            adapter.pillPadding = 8;
            adapter.groupSpacing = 6;
            adapter.itemSpacing = 5;
            adapter.spacingScale = 1.0;
            adapter.radiusScale = 1.0;
        }
    }

    function setSettingsPanelDensity(value) {
        const density = String(value || "balanced");
        if (density === "compact") {
            adapter.settingsPanelWidth = 700;
            setSettingsPreset("Compact");
        } else if (density === "roomy") {
            adapter.settingsPanelWidth = 900;
            setSettingsPreset("Roomy");
        } else {
            adapter.settingsPanelWidth = 780;
            setSettingsPreset("Balanced");
        }
    }

    function setThemeRecipe(value) {
        const recipe = String(value || "calypsoDefault");
        adapter.themeRecipe = recipe;

        if (recipe === "custom") {
            return;
        }

        applyingThemeRecipe = true;

        if (recipe === "compactGlass") {
            adapter.settingsPanelWidth = 700;
            setSettingsPreset("Compact");
            setVisualPreset("frostedMinimal");
            adapter.barStyle = "islands";
            adapter.widgetStyle = "iconOnly";
            adapter.surfaceStyle = "frosted";
            adapter.pillStyle = "soft";
            adapter.barOpacity = 0.78;
            adapter.barBlur = true;
            adapter.barBorderEnabled = false;
        } else if (recipe === "materialSoft") {
            adapter.settingsPanelWidth = 780;
            setSettingsPreset("Balanced");
            setVisualPreset("materialMorphing");
            adapter.barStyle = "pill";
            adapter.widgetStyle = "iconAndText";
            adapter.surfaceStyle = "translucent";
            adapter.pillStyle = "filled";
            adapter.barOpacity = 0.84;
            adapter.barBlur = true;
            adapter.wallpaperApplyColors = true;
            adapter.matugenEnabled = true;
        } else if (recipe === "denseIslands") {
            adapter.settingsPanelWidth = 700;
            setSettingsPreset("Compact");
            setVisualPreset("noctaliaQuiet");
            adapter.barStyle = "islands";
            adapter.widgetStyle = "iconAndText";
            adapter.spacingScale = 0.8;
            adapter.radiusScale = 0.9;
            adapter.barHeight = 26;
            adapter.barOpacity = 0.88;
            adapter.barBorderEnabled = false;
        } else if (recipe === "minimalSolid") {
            adapter.settingsPanelWidth = 700;
            setSettingsPreset("Compact");
            setVisualPreset("frostedMinimal");
            adapter.barStyle = "solid";
            adapter.widgetStyle = "iconOnly";
            adapter.surfaceStyle = "solid";
            adapter.pillStyle = "flat";
            adapter.barOpacity = 0.92;
            adapter.barBlur = false;
            adapter.barBorderEnabled = false;
        } else if (recipe === "focusMode") {
            adapter.settingsPanelWidth = 700;
            setSettingsPreset("Compact");
            setVisualPreset("noctaliaQuiet");
            adapter.barStyle = "pill";
            adapter.widgetStyle = "iconOnly";
            adapter.surfaceStyle = "translucent";
            adapter.pillStyle = "soft";
            adapter.barOpacity = 0.74;
            adapter.performanceMode = false;
        } else {
            adapter.settingsPanelWidth = 780;
            setSettingsPreset("Balanced");
            setVisualPreset("noctaliaQuiet");
            adapter.barStyle = "islands";
            adapter.widgetStyle = "iconAndText";
            adapter.surfaceStyle = "translucent";
            adapter.pillStyle = "soft";
            adapter.barOpacity = 0.85;
            adapter.barBlur = true;
            adapter.barBorderEnabled = false;
        }

        applyingThemeRecipe = false;
    }

    function pollInterval(name, fallback) {
        const polling = adapter.polling || {};
        return Math.max(250, Number(polling[name]) || fallback);
    }

    function enabled(moduleName) {
        if (moduleName === "settings") return adapter.showSettingsButton;

        const visibility = adapter.moduleVisibility || {};
        const id = moduleId(moduleName);
        if (visibility[id] !== undefined) return visibility[id] !== false;
        if (visibility[moduleName] !== undefined) return visibility[moduleName] !== false;
        return true;
    }

    function setModuleEnabled(moduleName, value) {
        if (moduleName === "settings") {
            adapter.showSettingsButton = value;
            return;
        }

        const visibility = Object.assign({}, adapter.moduleVisibility || {});
        visibility[moduleEntry(moduleName).id] = value;
        adapter.moduleVisibility = visibility;
    }

    function sectionKey(section) {
        if (section === "left") return "leftModules";
        if (section === "center") return "centerModules";
        return "rightModules";
    }

    function sectionModules(section) {
        if (section === "left") return Array.from(adapter.leftModules || []);
        if (section === "center") return Array.from(adapter.centerModules || []);
        return Array.from(adapter.rightModules || []);
    }

    function setSectionModules(section, modules) {
        const next = Array.from(modules || []);

        if (section === "left") {
            adapter.leftModules = next;
        } else if (section === "center") {
            adapter.centerModules = next;
        } else {
            adapter.rightModules = next;
        }
    }

    function hasModule(section, moduleName) {
        const target = moduleId(moduleName);
        const modules = sectionModules(section);
        for (let i = 0; i < modules.length; i++) {
            if (moduleId(modules[i]) === target)
                return true;
        }
        return false;
    }

    function canAddModule(section, moduleName) {
        return availableModules.indexOf(moduleName) >= 0 && !hasModule(section, moduleName);
    }

    function addModule(section, moduleName) {
        if (!canAddModule(section, moduleName)) return;

        const modules = sectionModules(section);
        modules.push(moduleName);
        setSectionModules(section, modules);
    }

    function addModuleToDefault(moduleName) {
        addModule(moduleDefaultSection(moduleName), moduleName);
    }

    function removeModule(section, index) {
        const modules = sectionModules(section);
        if (index < 0 || index >= modules.length) return;

        modules.splice(index, 1);
        setSectionModules(section, modules);
    }

    function moveModule(section, index, direction) {
        const modules = sectionModules(section);
        const nextIndex = index + direction;

        if (index < 0 || nextIndex < 0 || index >= modules.length || nextIndex >= modules.length) return;

        const current = modules[index];
        modules[index] = modules[nextIndex];
        modules[nextIndex] = current;
        setSectionModules(section, modules);
    }

    function moduleLabel(moduleName) {
        return moduleEntry(moduleName).label;
    }

    function moduleIcon(moduleName) {
        return moduleEntry(moduleName).icon;
    }

    function moduleCategory(moduleName) {
        return moduleEntry(moduleName).category;
    }

    function moduleCost(moduleName) {
        return moduleEntry(moduleName).cost;
    }

    property int version: adapter.version
    property int barHeight: adapter.barHeight
    property int screenMargin: adapter.screenMargin
    property bool reserveSpace: adapter.reserveSpace
    property bool showSettingsButton: adapter.showSettingsButton
    property int settingsPanelWidth: adapter.settingsPanelWidth
    property int settingsPanelGap: adapter.settingsPanelGap
    property int groupPadding: adapter.groupPadding
    property int pillPadding: adapter.pillPadding
    property int groupSpacing: adapter.groupSpacing
    property int itemSpacing: adapter.itemSpacing
    property int groupRadius: adapter.groupRadius
    property int pillRadius: adapter.pillRadius
    property string settingsPanelPage: adapter.settingsPanelPage
    property string settingsPanelMode: adapter.settingsPanelMode
    property string settingsPanelAnchor: adapter.settingsPanelAnchor
    property string settingsPanelDensity: adapter.settingsPanelDensity
    property bool settingsChangedFooter: adapter.settingsChangedFooter
    property bool settingsPreviewEnabled: adapter.settingsPreviewEnabled
    property string themeRecipe: adapter.themeRecipe
    property var themeRecipes: adapter.themeRecipes
    property string visualPreset: adapter.visualPreset
    property string surfaceStyle: adapter.surfaceStyle
    property string pillStyle: adapter.pillStyle
    property string hoverEffect: adapter.hoverEffect
    property string popupMotion: adapter.popupMotion
    property string workspaceIndicatorStyle: adapter.workspaceIndicatorStyle
    property bool iconMorphTransitions: adapter.iconMorphTransitions
    property real spacingScale: adapter.spacingScale
    property real radiusScale: adapter.radiusScale
    property string barStyle: adapter.barStyle
    property string barPosition: adapter.barPosition
    property bool barBlur: adapter.barBlur
    property real barOpacity: adapter.barOpacity
    property bool barBorderEnabled: adapter.barBorderEnabled
    property int barBorderThickness: adapter.barBorderThickness
    property string widgetStyle: adapter.widgetStyle
    property int trayMaxVisible: adapter.trayMaxVisible
    property bool barAutohide: adapter.barAutohide
    property string animationProfile: adapter.animationProfile
    property string settingsPreset: adapter.settingsPreset
    property int osdTimeout: adapter.osdTimeout
    property bool osdEnabled: adapter.osdEnabled
    property string osdPosition: adapter.osdPosition
    property string osdStyle: adapter.osdStyle
    property real osdSize: adapter.osdSize
    property real osdOpacity: adapter.osdOpacity
    property bool osdShowIcon: adapter.osdShowIcon
    property bool osdShowPercent: adapter.osdShowPercent
    property bool osdVolume: adapter.osdVolume
    property bool osdBrightness: adapter.osdBrightness
    property bool osdKeyboardBacklight: adapter.osdKeyboardBacklight
    property bool osdCapsLock: adapter.osdCapsLock
    property bool osdNumLock: adapter.osdNumLock
    property bool osdMedia: adapter.osdMedia
    property bool osdBattery: adapter.osdBattery
    property int tooltipDelay: adapter.tooltipDelay
    property bool tooltipsEnabled: adapter.tooltipsEnabled
    property int workspaceToastTimeout: adapter.workspaceToastTimeout
    property bool reduceMotion: adapter.reduceMotion
    property bool performanceMode: adapter.performanceMode
    property int animationBaseMs: adapter.animationMs
    property int animationMs: reduceMotion || performanceMode ? 0 : adapter.animationMs
    property string fontFamilySans: adapter.fontFamilySans && adapter.fontFamilySans.length > 0 ? adapter.fontFamilySans : adapter.fontFamily
    property string fontFamilyMono: adapter.fontFamilyMono && adapter.fontFamilyMono.length > 0 ? adapter.fontFamilyMono : fontFamilySans
    property string fontFamilyIcon: adapter.fontFamilyIcon && adapter.fontFamilyIcon.length > 0 ? adapter.fontFamilyIcon : fontFamilySans
    property string fontFamily: adapter.fontFamily
    property int fontSize: adapter.fontSize
    property int iconSize: adapter.iconSize
    property int trayIconSize: adapter.trayIconSize
    readonly property real effectiveSpacingXS: 4 * spacingScale
    readonly property real effectiveSpacingS: 8 * spacingScale
    readonly property real effectiveSpacingM: 12 * spacingScale
    readonly property real effectiveSpacingL: 16 * spacingScale
    readonly property real effectiveSpacingXL: 24 * spacingScale
    readonly property real effectiveRadiusS: 6 * radiusScale
    readonly property real effectiveRadiusM: 10 * radiusScale
    readonly property real effectiveRadiusL: 16 * radiusScale
    readonly property real effectiveRadiusXL: 24 * radiusScale
    property int effectiveGroupPadding: Math.max(2, Math.min(Math.round(groupPadding * spacingScale), Math.floor(barHeight / 8)))
    property int moduleHeight: Math.max(18, barHeight - effectiveGroupPadding * 2)
    property int effectiveGroupRadius: Math.min(Math.round(groupRadius * radiusScale), Math.floor(barHeight / 2))
    property int effectivePillRadius: Math.min(Math.round(pillRadius * radiusScale), Math.floor(moduleHeight / 2))
    property int effectivePillPadding: Math.max(5, Math.min(Math.round(pillPadding * spacingScale), Math.floor(moduleHeight / 2)))
    property int effectiveContentSpacing: Math.max(3, Math.min(Math.round(itemSpacing * spacingScale), Math.floor(moduleHeight / 4)))
    property int effectiveGroupSpacing: Math.max(0, Math.round(groupSpacing * spacingScale))
    property int effectiveBorderWidth: Math.max(1, Math.round(effectiveGroupPadding * 0.25))
    property int controlHeight: Math.max(26, Math.min(32, moduleHeight + 6))
    property int panelPadding: Math.round(effectiveSpacingM)
    property int panelRadius: Math.min(Math.round(effectiveRadiusL), Math.round(barHeight * 0.70))
    property int effectiveFontSize: Math.min(fontSize, Math.max(10, moduleHeight - 8))
    property int effectiveIconSize: Math.min(iconSize, Math.max(12, moduleHeight - 6))
    property int effectiveTrayIconSize: Math.min(trayIconSize, Math.max(12, moduleHeight - 6))
    property int motionHover: reduceMotion || performanceMode ? 0 : adapter.motionHover
    property int motionFast: reduceMotion || performanceMode ? 0 : adapter.motionFast
    property int motionNormal: reduceMotion || performanceMode ? 0 : adapter.motionNormal
    property int motionSpatial: reduceMotion || performanceMode ? 0 : adapter.motionSpatial
    property int motionPulse: reduceMotion || performanceMode ? 0 : adapter.motionPulse
    property int motionBreath: reduceMotion || performanceMode ? 0 : adapter.motionBreath
    property int motionOpen: reduceMotion || performanceMode || popupMotion === "none" ? 0 : adapter.motionOpen
    property int motionClose: reduceMotion || performanceMode || popupMotion === "none" ? 0 : adapter.motionClose
    property int motionEmphasis: reduceMotion || performanceMode ? 0 : adapter.motionEmphasis
    property int panelOpacity: adapter.panelOpacity
    property bool blurEnabled: adapter.blurEnabled
    property bool effectiveBlurEnabled: barBlur && !performanceMode
    property int workspaceMinWidth: adapter.workspaceMinWidth
    property int focusedWindowMaxWidth: adapter.focusedWindowMaxWidth
    property bool focusedWindowShowTitle: adapter.focusedWindowShowTitle
    property string clockFormat: adapter.clockFormat
    property bool clockShowSeconds: adapter.clockShowSeconds
    property int calendarWeekStart: adapter.calendarWeekStart
    property bool clockPanelShowWeek: adapter.clockPanelShowWeek
    property bool clockPanelShowDayOfYear: adapter.clockPanelShowDayOfYear
    property bool clockPanelShowTimezone: adapter.clockPanelShowTimezone
    property bool audioShowPercentage: adapter.audioShowPercentage
    property bool audioShowDeviceName: adapter.audioShowDeviceName
    property string networkInterfaceName: adapter.networkInterfaceName
    property bool networkShowSpeed: adapter.networkShowSpeed
    property bool batteryShowPercentage: adapter.batteryShowPercentage
    property int batteryCriticalThreshold: adapter.batteryCriticalThreshold
    property bool cpuShowGraph: adapter.cpuShowGraph
    property bool memoryShowGraph: adapter.memoryShowGraph
    property bool brightnessShowPercentage: adapter.brightnessShowPercentage
    property int brightnessStep: adapter.brightnessStep
    property bool powerProfileShowLabel: adapter.powerProfileShowLabel
    property bool mediaShowControls: adapter.mediaShowControls
    property int mediaMaxWidth: adapter.mediaMaxWidth
    property int mediaMaxTitleLength: adapter.mediaMaxTitleLength
    property int dashboardPanelWidth: adapter.dashboardPanelWidth
    property bool dashboardShowMedia: adapter.dashboardShowMedia
    property bool dashboardShowWeather: adapter.dashboardShowWeather
    property bool dashboardGrowFromTrigger: adapter.dashboardGrowFromTrigger
    property var dashboardQuickToggles: adapter.dashboardQuickToggles
    property var dashboardPerformanceModules: adapter.dashboardPerformanceModules
    property int notepadPanelWidth: adapter.notepadPanelWidth
    property string notepadFilePath: adapter.notepadFilePath
    property int notepadAutosaveMs: adapter.notepadAutosaveMs
    property int clipboardPanelWidth: adapter.clipboardPanelWidth
    property string clipboardBackend: adapter.clipboardBackend
    property int clipboardMaxItems: adapter.clipboardMaxItems
    property int processPanelWidth: adapter.processPanelWidth
    property int processListLimit: adapter.processListLimit
    property int notificationsPanelWidth: adapter.notificationsPanelWidth
    property int notificationsMaxVisible: adapter.notificationsMaxVisible
    property bool notificationsGroupByApp: adapter.notificationsGroupByApp
    property bool notificationsGroupsExpanded: adapter.notificationsGroupsExpanded
    property bool notificationsShowBody: adapter.notificationsShowBody
    property bool notificationsShowImages: adapter.notificationsShowImages
    property bool notificationsShowActions: adapter.notificationsShowActions
    property int launcherPanelWidth: adapter.launcherPanelWidth
    property int launcherMaxResults: adapter.launcherMaxResults
    property string launcherSearchPlaceholder: adapter.launcherSearchPlaceholder
    property bool launcherUseFuzzy: adapter.launcherUseFuzzy
    property string launcherSortMode: adapter.launcherSortMode
    property bool launcherShowIcons: adapter.launcherShowIcons
    property bool launcherShowDescriptions: adapter.launcherShowDescriptions
    property bool launcherCompactRows: adapter.launcherCompactRows
    property bool launcherVimKeybinds: adapter.launcherVimKeybinds
    property bool launcherCloseOnLaunch: adapter.launcherCloseOnLaunch
    property var launcherFavorites: normalizedStringList(adapter.launcherFavorites)
    property var launcherHiddenApps: normalizedStringList(adapter.launcherHiddenApps)
    property bool trayCompact: adapter.trayCompact
    property string focusedWindowDisplayMode: adapter.focusedWindowDisplayMode
    property bool workspaceShowNumbers: adapter.workspaceShowNumbers
    property bool workspaceShowOccupied: adapter.workspaceShowOccupied
    property bool workspaceShowAppIcons: adapter.workspaceShowAppIcons
    property int workspaceMaxAppIcons: adapter.workspaceMaxAppIcons
    property bool workspaceScrollEnabled: adapter.workspaceScrollEnabled
    property bool workspaceScrollWrap: adapter.workspaceScrollWrap
    property bool modulePopupPinned: adapter.modulePopupPinned
    property string modulePopupDefaultTab: adapter.modulePopupDefaultTab
    property bool modulePopupShowGauge: adapter.modulePopupShowGauge
    property bool modulePopupShowSparkline: adapter.modulePopupShowSparkline
    property int modulePopupHistorySamples: adapter.modulePopupHistorySamples
    property int modulePopupNetworkScaleKib: adapter.modulePopupNetworkScaleKib
    property string palettePath: adapter.palettePath
    property string paletteSource: adapter.paletteSource
    property string manualAccent: adapter.manualAccent
    property string customPaletteJson: adapter.customPaletteJson
    property string wallpaperDirectory: adapter.wallpaperDirectory
    property bool wallpaperRecursive: adapter.wallpaperRecursive
    property string currentWallpaper: adapter.currentWallpaper
    property var wallpaperFavorites: adapter.wallpaperFavorites
    property string wallpaperBackend: adapter.wallpaperBackend
    property string wallpaperResizeMode: adapter.wallpaperResizeMode
    property string wallpaperCropGravity: adapter.wallpaperCropGravity
    property bool wallpaperApplyColors: adapter.wallpaperApplyColors
    property string wallpaperTransition: reduceMotion ? "none" : adapter.wallpaperTransition
    property real wallpaperTransitionDuration: adapter.wallpaperTransitionDuration
    property int wallpaperTransitionFps: adapter.wallpaperTransitionFps
    property string wallpaperTransitionPosition: adapter.wallpaperTransitionPosition
    property int wallpaperTransitionAngle: adapter.wallpaperTransitionAngle
    property string wallpaperTransitionBezier: adapter.wallpaperTransitionBezier
    property string wallpaperRandomMode: adapter.wallpaperRandomMode
    property string wallpaperSelectedPreview: adapter.wallpaperSelectedPreview
    property bool matugenEnabled: adapter.matugenEnabled
    property string matugenMode: adapter.matugenMode
    property string matugenScheme: adapter.matugenScheme
    property string wallpaperLastError: adapter.wallpaperLastError
    property string wallpaperLastApplied: adapter.wallpaperLastApplied
    property string wallpaperLastPalette: adapter.wallpaperLastPalette
    property var compositor: adapter.compositor
    property string compositorBackend: (adapter.compositor && adapter.compositor.backend) ? adapter.compositor.backend : "auto"
    property var moduleRegistry: mergedModuleRegistry(adapter.moduleRegistry)
    property var availableModules: mergedAvailableModules(adapter.availableModules)
    property var leftModules: adapter.leftModules
    property var centerModules: adapter.centerModules
    property var rightModules: adapter.rightModules
    property int cpuPollMs: pollInterval("cpuMs", 30000)
    property int memoryPollMs: pollInterval("memoryMs", 5000)
    property int networkPollMs: pollInterval("networkMs", 5000)
    property int mediaPollMs: pollInterval("mediaMs", 2000)
    property int dashboardMediaPollMs: pollInterval("dashboardMediaMs", 500)
    property int dashboardStatePollMs: pollInterval("dashboardStateMs", 5000)
    property int processListPollMs: pollInterval("processListMs", 5000)
    property int batteryFallbackPollMs: pollInterval("batteryFallbackMs", 30000)
    property int clockPollMs: pollInterval("clockMs", 1000)
    property int brightnessPollMs: pollInterval("brightnessMs", 15000)
    property int powerProfilePollMs: pollInterval("powerProfileMs", 30000)

    FileView {
        id: settingsFile

        path: root.localPath(Qt.resolvedUrl("settings.json"))
        watchChanges: true
        blockLoading: true
        printErrors: true
        onFileChanged: reload()
        onAdapterUpdated: {
            root.changed();
            saveTimer.restart();
        }

        JsonAdapter {
            id: adapter

            property int version: 3
            property int barHeight: 32
            property int screenMargin: 8
            property bool reserveSpace: true
            property bool showSettingsButton: true
            property int settingsPanelWidth: 780
            property int settingsPanelGap: 8
            property int groupPadding: 4
            property int pillPadding: 8
            property int groupSpacing: 6
            property int itemSpacing: 5
            property int groupRadius: 12
            property int pillRadius: 9
            property string settingsPanelPage: "overview"
            property string settingsPanelMode: "auto"
            property string settingsPanelAnchor: "button"
            property string settingsPanelDensity: "balanced"
            property bool settingsChangedFooter: true
            property bool settingsPreviewEnabled: true
            property string themeRecipe: "custom"
            property var themeRecipes: [
                { "id": "custom", "label": "Custom", "icon": "󰘦", "detail": "Current manual mix" },
                { "id": "calypsoDefault", "label": "Calypso", "icon": "󰣇", "detail": "Balanced islands" },
                { "id": "compactGlass", "label": "Compact glass", "icon": "󰖟", "detail": "Small frosted islands" },
                { "id": "materialSoft", "label": "Material soft", "icon": "󰸌", "detail": "Wallpaper-aware pill" },
                { "id": "denseIslands", "label": "Dense islands", "icon": "󰙀", "detail": "Tight three-group bar" },
                { "id": "minimalSolid", "label": "Minimal solid", "icon": "󰝘", "detail": "One quiet strip" },
                { "id": "focusMode", "label": "Focus", "icon": "󰌵", "detail": "Centered essentials" }
            ]
            property string visualPreset: "noctaliaQuiet"
            property string surfaceStyle: "translucent"
            property string pillStyle: "soft"
            property string hoverEffect: "wash"
            property string popupMotion: "slide"
            property string animationProfile: "Physical"
            property string settingsPreset: "Balanced"
            property string workspaceIndicatorStyle: "pill"
            property bool iconMorphTransitions: true
            property real spacingScale: 1.0
            property real radiusScale: 1.0
            property string barStyle: "islands"
            property string barPosition: "top"
            property bool barBlur: true
            property real barOpacity: 0.85
            property bool barBorderEnabled: false
            property int barBorderThickness: 1
            property string widgetStyle: "iconAndText"
            property int trayMaxVisible: 6
            property bool barAutohide: false
            property bool osdEnabled: true
            property string osdPosition: "rightCenter"
            property string osdStyle: "vertical"
            property int osdTimeout: 1500
            property real osdSize: 1.0
            property real osdOpacity: 0.96
            property bool osdShowIcon: true
            property bool osdShowPercent: true
            property bool osdVolume: true
            property bool osdBrightness: true
            property bool osdKeyboardBacklight: true
            property bool osdCapsLock: true
            property bool osdNumLock: true
            property bool osdMedia: true
            property bool osdBattery: true
            property int tooltipDelay: 600
            property bool tooltipsEnabled: true
            property int workspaceToastTimeout: 1000
            property int animationMs: 160
            property bool reduceMotion: false
            property bool performanceMode: false
            property int motionFast: 80
            property int motionNormal: 160
            property int motionHover: 100
            property int motionPulse: 220
            property int motionBreath: 1800
            property int motionOpen: 220
            property int motionClose: 180
            property int motionSpatial: 200
            property int motionEmphasis: 240
            property int panelOpacity: 97
            property bool blurEnabled: false
            property string fontFamily: "JetBrainsMono Nerd Font"
            property string fontFamilySans: "DejaVu Sans"
            property string fontFamilyMono: "JetBrainsMono Nerd Font"
            property string fontFamilyIcon: "JetBrainsMono Nerd Font"
            property int fontSize: 12
            property int iconSize: 16
            property int trayIconSize: 16
            property int workspaceMinWidth: 26
            property int focusedWindowMaxWidth: 280
            property bool focusedWindowShowTitle: false
            property string clockFormat: "HH:mm"
            property bool clockShowSeconds: false
            property int calendarWeekStart: 1
            property bool clockPanelShowWeek: true
            property bool clockPanelShowDayOfYear: true
            property bool clockPanelShowTimezone: true
            property bool audioShowPercentage: true
            property bool audioShowDeviceName: false
            property string networkInterfaceName: ""
            property bool networkShowSpeed: false
            property bool batteryShowPercentage: true
            property int batteryCriticalThreshold: 15
            property bool cpuShowGraph: false
            property bool memoryShowGraph: false
            property bool brightnessShowPercentage: true
            property int brightnessStep: 5
            property bool powerProfileShowLabel: true
            property bool mediaShowControls: true
            property int mediaMaxWidth: 180
            property int mediaMaxTitleLength: 36
            property int dashboardPanelWidth: 420
            property bool dashboardShowMedia: true
            property bool dashboardShowWeather: false
            property bool dashboardGrowFromTrigger: true
            property var dashboardQuickToggles: ["wifi", "bluetooth", "mic", "dnd"]
            property var dashboardPerformanceModules: ["cpu", "memory", "network", "battery"]
            property int notepadPanelWidth: 420
            property string notepadFilePath: ""
            property int notepadAutosaveMs: 600
            property int clipboardPanelWidth: 460
            property string clipboardBackend: "auto"
            property int clipboardMaxItems: 20
            property int processPanelWidth: 520
            property int processListLimit: 12
            property int notificationsPanelWidth: 460
            property int notificationsMaxVisible: 24
            property bool notificationsGroupByApp: true
            property bool notificationsGroupsExpanded: true
            property bool notificationsShowBody: true
            property bool notificationsShowImages: true
            property bool notificationsShowActions: true
            property int launcherPanelWidth: 520
            property int launcherMaxResults: 12
            property string launcherSearchPlaceholder: "Search apps"
            property bool launcherUseFuzzy: true
            property string launcherSortMode: "relevance"
            property bool launcherShowIcons: true
            property bool launcherShowDescriptions: true
            property bool launcherCompactRows: false
            property bool launcherVimKeybinds: false
            property bool launcherCloseOnLaunch: true
            property var launcherFavorites: []
            property var launcherHiddenApps: []
            property bool trayCompact: true
            property string focusedWindowDisplayMode: "allWorkspaceApps"
            property bool workspaceShowNumbers: true
            property bool workspaceShowOccupied: true
            property bool workspaceShowAppIcons: false
            property int workspaceMaxAppIcons: 4
            property bool workspaceScrollEnabled: true
            property bool workspaceScrollWrap: true
            property bool modulePopupPinned: false
            property string modulePopupDefaultTab: "Overview"
            property bool modulePopupShowGauge: true
            property bool modulePopupShowSparkline: true
            property int modulePopupHistorySamples: 24
            property int modulePopupNetworkScaleKib: 10240
            property string palettePath: "/home/lucian/.config/quickshell/palette.json"
            property string paletteSource: "wallpaper"
            property string manualAccent: "#90a4c8"
            property string customPaletteJson: ""
            property string wallpaperDirectory: "/home/lucian/Pictures/Wallpapers"
            property bool wallpaperRecursive: true
            property string currentWallpaper: ""
            property var wallpaperFavorites: []
            property string wallpaperBackend: "awww"
            property string wallpaperResizeMode: "crop"
            property string wallpaperCropGravity: "center"
            property bool wallpaperApplyColors: true
            property string wallpaperTransition: "grow"
            property real wallpaperTransitionDuration: 1.0
            property int wallpaperTransitionFps: 60
            property string wallpaperTransitionPosition: "center"
            property int wallpaperTransitionAngle: 45
            property string wallpaperTransitionBezier: ".54,0,.34,.99"
            property string wallpaperRandomMode: "any"
            property string wallpaperSelectedPreview: ""
            property bool matugenEnabled: true
            property string matugenMode: "dark"
            property string matugenScheme: "scheme-tonal-spot"
            property string wallpaperLastError: ""
            property string wallpaperLastApplied: ""
            property string wallpaperLastPalette: ""
            property var moduleRegistry: [
                { "id": "settings", "label": "Settings", "icon": "", "category": "Shell", "aliases": [], "defaultSection": "left", "defaultVisible": true, "configurable": false, "cost": "low", "capabilities": [] },
                { "id": "workspaces", "label": "Workspaces", "icon": "󰧨", "category": "Compositor", "aliases": [], "defaultSection": "center", "defaultVisible": true, "configurable": true, "cost": "event", "capabilities": ["workspaces", "focusWorkspace"] },
                { "id": "focusedWindow", "label": "Workspace apps", "icon": "󰣆", "category": "Compositor", "aliases": [], "defaultSection": "center", "defaultVisible": true, "configurable": true, "cost": "event", "capabilities": ["windows", "focusWindow"] },
                { "id": "cpu", "label": "CPU", "icon": "", "category": "System", "aliases": [], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "polling", "capabilities": [] },
                { "id": "memory", "label": "Memory", "icon": "", "category": "System", "aliases": ["ram"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "polling", "capabilities": [] },
                { "id": "network", "label": "Network", "icon": "󰤨", "category": "System", "aliases": ["net"], "defaultSection": "right", "defaultVisible": true, "configurable": true, "cost": "polling", "capabilities": [] },
                { "id": "bluetooth", "label": "Bluetooth", "icon": "󰂯", "category": "System", "aliases": ["bt"], "defaultSection": "right", "defaultVisible": true, "configurable": false, "cost": "event", "capabilities": [] },
                { "id": "audio", "label": "Audio", "icon": "󰕾", "category": "Controls", "aliases": ["volume"], "defaultSection": "right", "defaultVisible": true, "configurable": true, "cost": "event", "capabilities": [] },
                { "id": "brightness", "label": "Brightness", "icon": "󰃠", "category": "Controls", "aliases": ["backlight"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "slow polling", "capabilities": [] },
                { "id": "powerProfile", "label": "Power profile", "icon": "󰓅", "category": "Controls", "aliases": ["power"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "slow polling", "capabilities": [] },
                { "id": "media", "label": "Media", "icon": "󰝚", "category": "Media", "aliases": ["mpris", "player"], "defaultSection": "right", "defaultVisible": true, "configurable": true, "cost": "event", "capabilities": [] },
                { "id": "battery", "label": "Battery", "icon": "󰁹", "category": "System", "aliases": ["bat"], "defaultSection": "right", "defaultVisible": true, "configurable": true, "cost": "event", "capabilities": [] },
                { "id": "caffeine", "label": "Caffeine", "icon": "󰅶", "category": "Controls", "aliases": ["idleInhibitor", "idle"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "local", "capabilities": [] },
                { "id": "clock", "label": "Clock", "icon": "󰥔", "category": "Shell", "aliases": ["time"], "defaultSection": "right", "defaultVisible": true, "configurable": true, "cost": "timer", "capabilities": [] },
                { "id": "dashboard", "label": "Dashboard", "icon": "󰒓", "category": "Shell", "aliases": ["controls", "controlCenter", "quickControls"], "defaultSection": "right", "defaultVisible": false, "configurable": false, "cost": "lazy", "capabilities": [] },
                { "id": "launcher", "label": "Launcher", "icon": "󰀻", "category": "Shell", "aliases": ["apps", "appLauncher"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "lazy", "capabilities": ["desktopEntries", "fuzzySearch"] },
                { "id": "notepad", "label": "Notepad", "icon": "󰎞", "category": "Shell", "aliases": ["scratchpad", "notes"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "lazy", "capabilities": ["autosave"] },
                { "id": "clipboard", "label": "Clipboard", "icon": "󰅌", "category": "Shell", "aliases": ["cliphist", "clip"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "open polling", "capabilities": ["history", "images"] },
                { "id": "processes", "label": "Processes", "icon": "󰒋", "category": "System", "aliases": ["processList", "tasks"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "open polling", "capabilities": ["sort", "temperature"] },
                { "id": "tray", "label": "Tray", "icon": "󰒲", "category": "System", "aliases": [], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "event", "capabilities": [] }
            ]
            property var availableModules: ["workspaces", "focusedWindow", "cpu", "memory", "network", "bluetooth", "audio", "brightness", "powerProfile", "media", "battery", "caffeine", "clock", "dashboard", "launcher", "notepad", "clipboard", "processes", "tray", "settings"]
            property var leftModules: ["workspaces", "media"]
            property var centerModules: ["clock"]
            property var rightModules: ["audio", "network", "battery", "cpu", "memory", "tray", "settings"]
            property var moduleVisibility: ({
                "workspaces": true,
                "focusedWindow": true,
                "cpu": true,
                "memory": true,
                "audio": true,
                "brightness": false,
                "powerProfile": false,
                "media": true,
                "network": true,
                "bluetooth": true,
                "battery": true,
                "caffeine": false,
                "clock": true,
                "dashboard": false,
                "launcher": false,
                "notepad": false,
                "clipboard": false,
                "processes": false,
                "tray": false
            })
            property var polling: ({
                "cpuMs": 30000,
                "memoryMs": 5000,
                "networkMs": 5000,
                "mediaMs": 2000,
                "dashboardMediaMs": 500,
                "dashboardStateMs": 5000,
                "processListMs": 5000,
                "batteryFallbackMs": 30000,
                "clockMs": 1000,
                "brightnessMs": 15000,
                "powerProfileMs": 30000
            })
            property var compositor: ({
                "backend": "auto",
                "preferred": ["niri", "hyprland"],
                "showUnsupportedModules": false
            })
        }
    }

    Timer {
        id: saveTimer

        interval: 80
        repeat: false
        onTriggered: settingsFile.writeAdapter()
    }
}
