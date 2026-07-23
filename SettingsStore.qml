pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "settingscore/SettingsDefaults.js" as Defaults

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var registry: null
    property bool applyingThemeRecipe: false
    property string settingsPath: localPath(Qt.resolvedUrl("settings.json"))
    property string saveState: "loading"
    property string error: ""
    readonly property bool canUndo: _undoStack.length > 0
    readonly property bool canRedo: _redoStack.length > 0

    readonly property string _home: Quickshell.env("HOME") || ""
    readonly property string _configHome: Quickshell.env("XDG_CONFIG_HOME") || ""
    readonly property var defaultDocument: Defaults.create(_home, _configHome)
    property var _undoStack: []
    property var _redoStack: []
    property int _transactionDepth: 0
    property var _transactionChanges: []
    property string _transactionLabel: ""
    property string _sliderPath: ""
    property bool _applyingHistory: false

    signal changed()

    function localPath(url) {
        const value = String(url);
        return value.startsWith("file://") ? decodeURIComponent(value.slice(7)) : value;
    }

    function clone(value) {
        if (value === undefined || value === null)
            return value;
        return JSON.parse(JSON.stringify(value));
    }

    function equal(left, right) {
        if (left === undefined || right === undefined)
            return left === right;
        return JSON.stringify(left) === JSON.stringify(right);
    }

    function normalizedPath(path) {
        return String(path || "").split(".").filter(part => part.length > 0).join(".");
    }

    function primaryInstanceId(moduleName) {
        const type = moduleType(moduleName);
        const instances = nestedAdapter.modules.instances || {};
        if (instances[moduleName])
            return String(moduleName);
        if (instances[type])
            return type;

        const ids = Object.keys(instances);
        for (let i = 0; i < ids.length; i++) {
            if (String(instances[ids[i]].type || ids[i]) === type)
                return ids[i];
        }
        return "";
    }

    function moduleInstanceIds(moduleName) {
        const type = moduleType(moduleName);
        const instances = nestedAdapter.modules.instances || {};
        return Object.keys(instances).filter(id => String(instances[id].type || id) === type);
    }

    function resolveModuleInstance(moduleName, createMissing) {
        const name = String(moduleName || "");
        if ((nestedAdapter.modules.instances || {})[name])
            return name;

        const primary = primaryInstanceId(name);
        if (primary.length > 0 || !createMissing)
            return primary;
        return createModuleInstance(name);
    }

    function ensurePrimaryInstance(moduleName) {
        return resolveModuleInstance(moduleName, true);
    }

    function compatibilityPath(name, createMissing) {
        const key = String(name || "");
        if (key === "version")
            return "version";
        if (key === "showSettingsButton") {
            const settingsId = primaryInstanceId("settings");
            return settingsId.length > 0 ? "modules.instances." + settingsId + ".enabled" : "";
        }
        if (key === "leftModules")
            return "modules.left";
        if (key === "centerModules")
            return "modules.center";
        if (key === "rightModules")
            return "modules.right";

        if (Defaults.flatPaths[key] !== undefined)
            return Defaults.flatPaths[key];

        const moduleSetting = Defaults.moduleSettings[key];
        if (moduleSetting !== undefined) {
            let instanceId = primaryInstanceId(moduleSetting[0]);
            if (instanceId.length <= 0 && createMissing)
                instanceId = createModuleInstance(moduleSetting[0]);
            return instanceId.length > 0
                ? "modules.instances." + instanceId + ".settings." + moduleSetting[1]
                : "";
        }
        return normalizedPath(key);
    }

    function get(path) {
        const resolved = compatibilityPath(path, false);
        if (resolved.length <= 0)
            return undefined;

        const parts = resolved.split(".");
        let cursor = nestedAdapter;
        for (let i = 0; i < parts.length; i++) {
            if (cursor === undefined || cursor === null)
                return undefined;
            cursor = cursor[parts[i]];
        }
        return cursor;
    }

    function defaultAt(path) {
        const key = String(path || "");
        const moduleSetting = Defaults.moduleSettings[key];
        if (moduleSetting !== undefined) {
            const instance = defaultDocument.modules.instances[moduleSetting[0]];
            return instance ? clone(instance.settings[moduleSetting[1]]) : undefined;
        }

        const resolved = Defaults.flatPaths[key] || normalizedPath(key);
        if (resolved === "showSettingsButton")
            return true;

        const instanceMatch = /^modules\.instances\.([^.]+)\.(.+)$/.exec(resolved);
        if (instanceMatch) {
            const instance = get("modules.instances." + instanceMatch[1]);
            const defaults = instance && defaultDocument.modules.instances[instance.type];
            if (!defaults)
                return undefined;
            const instanceParts = instanceMatch[2].split(".");
            let instanceCursor = defaults;
            for (let i = 0; i < instanceParts.length; i++) {
                if (instanceCursor === undefined || instanceCursor === null)
                    return undefined;
                instanceCursor = instanceCursor[instanceParts[i]];
            }
            return clone(instanceCursor);
        }

        const parts = resolved.split(".");
        let cursor = defaultDocument;
        for (let i = 0; i < parts.length; i++) {
            if (cursor === undefined || cursor === null)
                return undefined;
            cursor = cursor[parts[i]];
        }

        if (cursor !== undefined)
            return clone(cursor);
        return undefined;
    }

    function _setPlainObjectPath(object, parts, index, value) {
        const next = Object.assign({}, object || {});
        const key = parts[index];
        if (index === parts.length - 1) {
            next[key] = clone(value);
        } else {
            next[key] = _setPlainObjectPath(next[key], parts, index + 1, value);
        }
        return next;
    }

    function _assignPath(path, value) {
        const parts = normalizedPath(path).split(".");
        if (parts.length <= 0)
            return;

        if (parts.length === 1) {
            if (parts[0] === "version") {
                nestedAdapter.version = clone(value);
                return;
            }
            const group = nestedAdapter[parts[0]];
            const keys = Object.keys(value || {});
            for (let i = 0; i < keys.length; i++)
                group[keys[i]] = clone(value[keys[i]]);
            return;
        }

        const group = nestedAdapter[parts[0]];
        if (parts.length === 2) {
            group[parts[1]] = clone(value);
            return;
        }

        group[parts[1]] = _setPlainObjectPath(group[parts[1]], parts, 2, value);
    }

    function _appendTransactionChange(path, before, after) {
        const changes = Array.from(_transactionChanges || []);
        for (let i = 0; i < changes.length; i++) {
            if (changes[i].path === path) {
                changes[i] = {
                    "path": path,
                    "before": changes[i].before,
                    "after": clone(after)
                };
                _transactionChanges = changes;
                return;
            }
        }
        changes.push({ "path": path, "before": clone(before), "after": clone(after) });
        _transactionChanges = changes;
    }

    function _pushHistory(changes, label) {
        const meaningful = Array.from(changes || []).filter(change => !equal(change.before, change.after));
        if (meaningful.length <= 0)
            return;

        const undoStack = Array.from(_undoStack || []);
        undoStack.push({ "label": String(label || ""), "changes": meaningful });
        while (undoStack.length > 50)
            undoStack.shift();
        _undoStack = undoStack;
        _redoStack = [];
    }

    function beginTransaction(label) {
        if (_transactionDepth === 0) {
            _transactionChanges = [];
            _transactionLabel = String(label || "");
        }
        _transactionDepth++;
    }

    function endTransaction() {
        if (_transactionDepth <= 0)
            return;
        _transactionDepth--;
        if (_transactionDepth === 0) {
            _pushHistory(_transactionChanges, _transactionLabel);
            _transactionChanges = [];
            _transactionLabel = "";
        }
    }

    function cancelTransaction() {
        if (_transactionDepth <= 0)
            return;

        const changes = Array.from(_transactionChanges || []);
        _applyingHistory = true;
        for (let i = changes.length - 1; i >= 0; i--)
            _assignPath(changes[i].path, changes[i].before);
        _applyingHistory = false;
        _transactionDepth = 0;
        _transactionChanges = [];
        _transactionLabel = "";
    }

    function beginSliderChange(path) {
        if (_sliderPath.length > 0)
            endSliderChange();
        _sliderPath = compatibilityPath(path, true);
        beginTransaction("slider:" + _sliderPath);
    }

    function endSliderChange() {
        if (_sliderPath.length <= 0)
            return;
        _sliderPath = "";
        endTransaction();
    }

    function cancelSliderChange() {
        if (_sliderPath.length <= 0)
            return;
        _sliderPath = "";
        cancelTransaction();
    }

    function beginCoalescedChange(path) {
        beginSliderChange(path);
    }

    function endCoalescedChange() {
        endSliderChange();
    }

    function cancelCoalescedChange() {
        cancelSliderChange();
    }

    function set(path, value) {
        const resolved = compatibilityPath(path, true);
        if (resolved.length <= 0)
            return false;

        const themeTransaction = !applyingThemeRecipe
            && themeRecipe !== "custom"
            && _transactionDepth === 0
            && themeTrackedPath(resolved);
        if (themeTransaction)
            beginTransaction(resolved);

        const before = clone(get(resolved));
        if (equal(before, value)) {
            if (themeTransaction)
                endTransaction();
            return false;
        }

        _assignPath(resolved, value);
        if (!_applyingHistory) {
            if (_transactionDepth > 0)
                _appendTransactionChange(resolved, before, value);
            else
                _pushHistory([{ "path": resolved, "before": before, "after": clone(value) }], resolved);
        }
        markThemeRecipeCustom(resolved);
        if (themeTransaction)
            endTransaction();
        return true;
    }

    function reset(path) {
        const value = defaultAt(path);
        if (value === undefined)
            return false;
        return set(path, value);
    }

    function isModified(path) {
        const value = defaultAt(path);
        return value !== undefined && !equal(get(path), value);
    }

    function undo() {
        if (!canUndo)
            return false;

        const undoStack = Array.from(_undoStack);
        const operation = undoStack.pop();
        _undoStack = undoStack;
        _applyingHistory = true;
        for (let i = operation.changes.length - 1; i >= 0; i--)
            _assignPath(operation.changes[i].path, operation.changes[i].before);
        _applyingHistory = false;

        const redoStack = Array.from(_redoStack);
        redoStack.push(operation);
        _redoStack = redoStack;
        return true;
    }

    function redo() {
        if (!canRedo)
            return false;

        const redoStack = Array.from(_redoStack);
        const operation = redoStack.pop();
        _redoStack = redoStack;
        _applyingHistory = true;
        for (let i = 0; i < operation.changes.length; i++)
            _assignPath(operation.changes[i].path, operation.changes[i].after);
        _applyingHistory = false;

        const undoStack = Array.from(_undoStack);
        undoStack.push(operation);
        while (undoStack.length > 50)
            undoStack.shift();
        _undoStack = undoStack;
        return true;
    }

    function clearHistory() {
        _undoStack = [];
        _redoStack = [];
        _transactionDepth = 0;
        _transactionChanges = [];
        _transactionLabel = "";
        _sliderPath = "";
    }

    function clamp(value, minimum, maximum) {
        const number = Number(value);
        if (!Number.isFinite(number))
            return minimum;
        return Math.max(minimum, Math.min(maximum, Math.round(number)));
    }

    function clampReal(value, minimum, maximum) {
        const number = Number(value);
        if (!Number.isFinite(number))
            return minimum;
        return Math.max(minimum, Math.min(maximum, number));
    }

    function setValue(name, value) {
        return set(name, value);
    }

    function setString(name, value) {
        return set(name, String(value));
    }

    function setNumber(name, value, minimum, maximum) {
        return set(name, clamp(value, minimum, maximum));
    }

    function setReal(name, value, minimum, maximum, step) {
        const safeStep = Number(step) > 0 ? Number(step) : 0;
        let next = clampReal(value, minimum, maximum);
        if (safeStep > 0) {
            next = minimum + Math.round((next - minimum) / safeStep) * safeStep;
            next = clampReal(next, minimum, maximum);
        }
        return set(name, Math.round(next * 1000) / 1000);
    }

    function setEnum(name, value, allowed, fallback) {
        const text = String(value || fallback || "");
        return set(name, allowed.indexOf(text) >= 0 ? text : fallback);
    }

    function setPollingInterval(name, value, minimum, maximum) {
        return set("services.polling." + name, clamp(value, minimum, maximum));
    }

    function setStringList(name, values) {
        return set(name, Array.from(values || []).map(value => String(value)));
    }

    function setObjectValue(objectName, key, value) {
        if (objectName === "moduleVisibility") {
            setModuleEnabled(key, value);
            return;
        }
        const path = compatibilityPath(objectName, true);
        set(path + "." + key, value);
    }

    function toggleStringInList(name, value) {
        const current = Array.from(get(name) || []);
        const text = String(value || "");
        const index = current.indexOf(text);
        if (index >= 0)
            current.splice(index, 1);
        else
            current.push(text);
        set(name, current);
    }

    function includesString(name, value) {
        return Array.from(get(name) || []).indexOf(String(value || "")) >= 0;
    }

    function normalizedStringList(values) {
        return Array.from(values || [])
            .map(value => String(value || "").trim())
            .filter(value => value.length > 0);
    }

    function themeTrackedPath(path) {
        const tracked = [
            "bar.style", "bar.position", "bar.blur", "bar.opacity", "bar.borderEnabled",
            "bar.borderThickness", "bar.widgetStyle", "theme.surfaceStyle", "theme.pillStyle",
            "theme.hoverEffect", "theme.visualPreset", "theme.settingsPreset",
            "theme.spacingScale", "theme.radiusScale", "bar.height", "bar.screenMargin",
            "bar.groupPadding", "bar.pillPadding", "bar.groupSpacing", "bar.itemSpacing",
            "panels.settings.density", "panels.settings.width", "panels.settings.anchor"
        ];
        return tracked.indexOf(normalizedPath(path)) >= 0;
    }

    function markThemeRecipeCustom(name) {
        if (applyingThemeRecipe || themeRecipe === "custom")
            return;

        const path = compatibilityPath(name, false);
        if (themeTrackedPath(path))
            set("theme.recipe", "custom");
    }

    function applyMotionTokens(baseValue) {
        const base = clamp(baseValue, 0, 500);
        const scale = base === 0 ? 0 : base / 160;
        set("theme.motionFast", Math.round(80 * scale));
        set("theme.motionNormal", Math.round(160 * scale));
        set("theme.motionHover", Math.round(100 * scale));
        set("theme.motionPulse", Math.round(220 * scale));
        set("theme.motionBreath", Math.round(1800 * scale));
        set("theme.motionOpen", Math.round(220 * scale));
        set("theme.motionClose", Math.round(180 * scale));
        set("theme.motionSpatial", Math.round(200 * scale));
        set("theme.motionEmphasis", Math.round(240 * scale));
    }

    function setAnimationMs(value) {
        beginTransaction("animation");
        const next = clamp(value, 0, 500);
        set("theme.animationMs", next);
        if (!reduceMotion)
            applyMotionTokens(next);
        endTransaction();
    }

    function setReduceMotion(value) {
        beginTransaction("reduceMotion");
        set("app.reduceMotion", Boolean(value));
        if (value) {
            set("theme.motionHover", 0);
            set("theme.motionFast", 0);
            set("theme.motionNormal", 0);
            set("theme.motionSpatial", 0);
            set("theme.motionPulse", 0);
            set("theme.motionBreath", 0);
            set("theme.motionOpen", 0);
            set("theme.motionClose", 0);
            set("theme.motionEmphasis", 0);
        } else {
            applyMotionTokens(animationBaseMs);
        }
        endTransaction();
    }

    function setClockFormat(value) {
        beginTransaction("clockFormat");
        const next = String(value || "HH:mm");
        set("clockFormat", next);
        set("clockShowSeconds", next.indexOf("s") >= 0 || next.indexOf("z") >= 0);
        endTransaction();
    }

    function setClockShowSeconds(value) {
        beginTransaction("clockSeconds");
        set("clockShowSeconds", Boolean(value));
        const current = String(clockFormat || "HH:mm");
        if (value) {
            if (current.indexOf("s") < 0 && current.indexOf("z") < 0)
                set("clockFormat", current.length > 0 ? current + ":ss" : "HH:mm:ss");
        } else if (current === "HH:mm:ss") {
            set("clockFormat", "HH:mm");
        } else if (current.indexOf(":ss") >= 0) {
            set("clockFormat", current.replace(":ss", ""));
        }
        endTransaction();
    }

    function setVisualPreset(value) {
        beginTransaction("visualPreset");
        const preset = String(value || "noctaliaQuiet");
        set("theme.visualPreset", preset);
        if (preset === "frostedMinimal") {
            set("theme.surfaceStyle", "frosted");
            set("theme.pillStyle", "soft");
            set("theme.hoverEffect", "wash");
            set("theme.popupMotion", "slide");
        } else if (preset === "materialMorphing") {
            set("theme.surfaceStyle", "translucent");
            set("theme.pillStyle", "filled");
            set("theme.hoverEffect", "scale");
            set("theme.popupMotion", "slide");
        } else {
            set("theme.surfaceStyle", "translucent");
            set("theme.pillStyle", "soft");
            set("theme.hoverEffect", "wash");
            set("theme.popupMotion", "slide");
        }
        endTransaction();
    }

    function setAnimationProfile(value) {
        beginTransaction("animationProfile");
        const profile = String(value || "Physical");
        set("theme.animationProfile", profile);
        if (profile === "Instant") {
            setReduceMotion(true);
        } else {
            if (reduceMotion)
                set("app.reduceMotion", false);
            if (profile === "Snappy")
                setAnimationMs(120);
            else if (profile === "Calm")
                setAnimationMs(220);
            else
                setAnimationMs(160);
        }
        endTransaction();
    }

    function setSettingsPreset(value) {
        beginTransaction("settingsPreset");
        const preset = String(value || "Balanced");
        set("theme.settingsPreset", preset);
        if (preset === "Compact") {
            set("panels.settings.density", "compact");
            set("bar.height", 28);
            set("bar.groupPadding", 3);
            set("bar.pillPadding", 6);
            set("bar.groupSpacing", 4);
            set("bar.itemSpacing", 4);
            set("theme.spacingScale", 0.85);
            set("theme.radiusScale", 0.9);
        } else if (preset === "Roomy") {
            set("panels.settings.density", "roomy");
            set("bar.height", 38);
            set("bar.groupPadding", 5);
            set("bar.pillPadding", 10);
            set("bar.groupSpacing", 8);
            set("bar.itemSpacing", 6);
            set("theme.spacingScale", 1.18);
            set("theme.radiusScale", 1.08);
        } else {
            set("panels.settings.density", "balanced");
            set("bar.height", 32);
            set("bar.groupPadding", 4);
            set("bar.pillPadding", 8);
            set("bar.groupSpacing", 6);
            set("bar.itemSpacing", 5);
            set("theme.spacingScale", 1.0);
            set("theme.radiusScale", 1.0);
        }
        endTransaction();
    }

    function setSettingsPanelDensity(value) {
        beginTransaction("settingsDensity");
        const density = String(value || "balanced");
        if (density === "compact") {
            set("panels.settings.width", 700);
            setSettingsPreset("Compact");
        } else if (density === "roomy") {
            set("panels.settings.width", 900);
            setSettingsPreset("Roomy");
        } else {
            set("panels.settings.width", 780);
            setSettingsPreset("Balanced");
        }
        endTransaction();
    }

    function setThemeRecipe(value) {
        const recipe = String(value || "calypsoDefault");
        beginTransaction("themeRecipe");
        applyingThemeRecipe = true;
        set("theme.recipe", recipe);
        if (recipe === "custom") {
            applyingThemeRecipe = false;
            endTransaction();
            return;
        }

        if (recipe === "compactGlass") {
            set("panels.settings.width", 700);
            setSettingsPreset("Compact");
            setVisualPreset("frostedMinimal");
            set("bar.style", "islands");
            set("bar.widgetStyle", "iconOnly");
            set("theme.surfaceStyle", "frosted");
            set("theme.pillStyle", "soft");
            set("bar.opacity", 0.78);
            set("bar.blur", true);
            set("bar.borderEnabled", false);
        } else if (recipe === "materialSoft") {
            set("panels.settings.width", 780);
            setSettingsPreset("Balanced");
            setVisualPreset("materialMorphing");
            set("bar.style", "pill");
            set("bar.widgetStyle", "iconAndText");
            set("theme.surfaceStyle", "translucent");
            set("theme.pillStyle", "filled");
            set("bar.opacity", 0.84);
            set("bar.blur", true);
            set("services.wallpaper.applyColors", true);
            set("theme.matugenEnabled", true);
        } else if (recipe === "denseIslands") {
            set("panels.settings.width", 700);
            setSettingsPreset("Compact");
            setVisualPreset("noctaliaQuiet");
            set("bar.style", "islands");
            set("bar.widgetStyle", "iconAndText");
            set("theme.spacingScale", 0.8);
            set("theme.radiusScale", 0.9);
            set("bar.height", 26);
            set("bar.opacity", 0.88);
            set("bar.borderEnabled", false);
        } else if (recipe === "minimalSolid") {
            set("panels.settings.width", 700);
            setSettingsPreset("Compact");
            setVisualPreset("frostedMinimal");
            set("bar.style", "solid");
            set("bar.widgetStyle", "iconOnly");
            set("theme.surfaceStyle", "solid");
            set("theme.pillStyle", "flat");
            set("bar.opacity", 0.92);
            set("bar.blur", false);
            set("bar.borderEnabled", false);
        } else if (recipe === "focusMode") {
            set("panels.settings.width", 700);
            setSettingsPreset("Compact");
            setVisualPreset("noctaliaQuiet");
            set("bar.style", "pill");
            set("bar.widgetStyle", "iconOnly");
            set("theme.surfaceStyle", "translucent");
            set("theme.pillStyle", "soft");
            set("bar.opacity", 0.74);
            set("app.performanceMode", false);
        } else {
            set("panels.settings.width", 780);
            setSettingsPreset("Balanced");
            setVisualPreset("noctaliaQuiet");
            set("bar.style", "islands");
            set("bar.widgetStyle", "iconAndText");
            set("theme.surfaceStyle", "translucent");
            set("theme.pillStyle", "soft");
            set("bar.opacity", 0.85);
            set("bar.blur", true);
            set("bar.borderEnabled", false);
        }
        applyingThemeRecipe = false;
        endTransaction();
    }

    function pollInterval(name, fallback) {
        const polling = get("services.polling") || {};
        return Math.max(250, Number(polling[name]) || fallback);
    }

    function moduleInstance(instanceId) {
        const instance = (nestedAdapter.modules.instances || {})[String(instanceId || "")];
        return instance ? clone(instance) : null;
    }

    function instance(instanceId) {
        return moduleInstance(instanceId);
    }

    function moduleType(moduleName) {
        const name = String(moduleName || "");
        const instance = (nestedAdapter.modules.instances || {})[name];
        if (instance && instance.type)
            return String(instance.type);
        if (registry)
            return registry.canonicalId(name);
        return String(moduleEntry(name).id || name);
    }

    function moduleId(moduleName) {
        return moduleType(moduleName);
    }

    function instanceEnabled(instanceId) {
        const instance = (nestedAdapter.modules.instances || {})[String(instanceId || "")];
        return instance ? instance.enabled !== false : false;
    }

    function setInstanceEnabled(instanceId, value) {
        const id = String(instanceId || "");
        if (!(nestedAdapter.modules.instances || {})[id])
            return false;
        return set("modules.instances." + id + ".enabled", Boolean(value));
    }

    function instanceSettings(instanceId) {
        const value = moduleInstance(instanceId);
        return value ? clone(value.settings || {}) : null;
    }

    function instanceSetting(instanceId, name, fallback) {
        const id = String(instanceId || "");
        const key = String(name || "");
        const value = moduleInstance(id);
        if (!value || key.length <= 0)
            return fallback;
        const values = value.settings || {};
        if (Object.prototype.hasOwnProperty.call(values, key))
            return clone(values[key]);

        const defaults = defaultDocument.modules.instances[value.type];
        if (defaults && Object.prototype.hasOwnProperty.call(defaults.settings || {}, key))
            return clone(defaults.settings[key]);
        return fallback;
    }

    function setInstanceSetting(instanceId, name, value) {
        const id = String(instanceId || "");
        const key = String(name || "");
        if (!(nestedAdapter.modules.instances || {})[id] || key.length <= 0)
            return false;
        return set("modules.instances." + id + ".settings." + key, value);
    }

    function instanceOrdinal(instanceId) {
        const id = String(instanceId || "");
        const ids = moduleInstanceIds(id);
        const index = ids.indexOf(id);
        return index < 0 ? 0 : index + 1;
    }

    function instanceDisplayLabel(instanceId) {
        const id = String(instanceId || "");
        const label = String(moduleLabel(id) || id);
        const ids = moduleInstanceIds(id);
        if (ids.length <= 1)
            return label;
        return label + " #" + instanceOrdinal(id);
    }

    function moduleReusable(moduleName) {
        return moduleEntry(moduleName).reusable !== false;
    }

    function canAddModuleInstance(section, moduleName) {
        const lane = String(section || "");
        const type = moduleType(moduleName);
        if (lane !== "left" && lane !== "center" && lane !== "right")
            return false;
        if (availableModules.indexOf(type) < 0)
            return false;
        return moduleReusable(type) || moduleInstanceIds(type).length <= 0;
    }

    function unplacedModuleInstance(moduleName) {
        const placed = sectionModules("left").concat(sectionModules("center")).concat(sectionModules("right"));
        const ids = moduleInstanceIds(moduleName);
        for (let i = 0; i < ids.length; i++) {
            if (placed.indexOf(ids[i]) < 0)
                return ids[i];
        }
        return "";
    }

    function canAddCatalogModule(section, moduleName) {
        const lane = String(section || "");
        const type = moduleType(moduleName);
        if (lane !== "left" && lane !== "center" && lane !== "right")
            return false;
        if (availableModules.indexOf(type) < 0)
            return false;
        return unplacedModuleInstance(type).length > 0 || moduleReusable(type);
    }

    function allocateInstanceId(type, instances) {
        if (!instances[type])
            return type;
        let suffix = 2;
        while (instances[type + "-" + suffix])
            suffix++;
        return type + "-" + suffix;
    }

    function createModuleInstance(moduleName, enabledValue, settingsValue) {
        const type = moduleType(moduleName);
        if (type.length <= 0)
            return "";

        const instances = clone(nestedAdapter.modules.instances || {});
        const id = allocateInstanceId(type, instances);
        const defaultInstance = defaultDocument.modules.instances[type];
        instances[id] = {
            "type": type,
            "enabled": enabledValue === undefined
                ? (defaultInstance ? defaultInstance.enabled !== false : moduleEntry(type).defaultVisible !== false)
                : Boolean(enabledValue),
            "settings": settingsValue === undefined
                ? clone(defaultInstance ? defaultInstance.settings : {})
                : clone(settingsValue || {})
        };
        set("modules.instances", instances);
        return id;
    }

    function createInstance(moduleName, enabledValue, settingsValue) {
        return createModuleInstance(moduleName, enabledValue, settingsValue);
    }

    function addModuleInstance(section, moduleName, index) {
        beginTransaction("addInstance");
        const id = createModuleInstance(moduleName);
        if (id.length > 0) {
            const modules = sectionModules(section);
            const target = index === undefined
                ? modules.length
                : Math.max(0, Math.min(modules.length, Number(index)));
            modules.splice(target, 0, id);
            setSectionModules(section, modules);
        }
        endTransaction();
        return id;
    }

    function addInstance(section, moduleName, index) {
        return addModuleInstance(section, moduleName, index);
    }

    function addCatalogModule(section, moduleName, index) {
        if (!canAddCatalogModule(section, moduleName))
            return "";

        beginTransaction("addCatalogModule");
        let id = unplacedModuleInstance(moduleName);
        if (id.length <= 0)
            id = createModuleInstance(moduleName);
        if (id.length > 0) {
            const modules = sectionModules(section);
            const target = index === undefined
                ? modules.length
                : Math.max(0, Math.min(modules.length, Number(index)));
            modules.splice(target, 0, id);
            setSectionModules(section, modules);
        }
        endTransaction();
        return id;
    }

    function duplicateModuleInstance(instanceId, section, index) {
        const source = moduleInstance(instanceId);
        if (!source)
            return "";

        beginTransaction("duplicateInstance");
        const id = createModuleInstance(source.type, source.enabled, source.settings);
        let targetSection = String(section || "");
        let targetIndex = index;
        if (targetSection.length <= 0) {
            const sections = ["left", "center", "right"];
            for (let i = 0; i < sections.length; i++) {
                const modules = sectionModules(sections[i]);
                const sourceIndex = modules.indexOf(String(instanceId));
                if (sourceIndex >= 0) {
                    targetSection = sections[i];
                    targetIndex = sourceIndex + 1;
                    break;
                }
            }
        }
        if (targetSection.length > 0) {
            const modules = sectionModules(targetSection);
            const position = targetIndex === undefined
                ? modules.length
                : Math.max(0, Math.min(modules.length, Number(targetIndex)));
            modules.splice(position, 0, id);
            setSectionModules(targetSection, modules);
        }
        endTransaction();
        return id;
    }

    function duplicateInstance(instanceId, section, index) {
        return duplicateModuleInstance(instanceId, section, index);
    }

    function deleteModuleInstance(instanceId) {
        const id = String(instanceId || "");
        const instances = clone(nestedAdapter.modules.instances || {});
        if (!instances[id])
            return false;

        beginTransaction("deleteInstance");
        const sections = ["left", "center", "right"];
        for (let i = 0; i < sections.length; i++) {
            const modules = sectionModules(sections[i]).filter(value => value !== id);
            setSectionModules(sections[i], modules);
        }
        delete instances[id];
        set("modules.instances", instances);
        endTransaction();
        return true;
    }

    function deleteInstance(instanceId) {
        return deleteModuleInstance(instanceId);
    }

    function moveModuleInstance(instanceId, targetSection, targetIndex) {
        const id = String(instanceId || "");
        if (!(nestedAdapter.modules.instances || {})[id])
            return false;

        beginTransaction("moveInstance");
        const sections = ["left", "center", "right"];
        for (let i = 0; i < sections.length; i++)
            setSectionModules(sections[i], sectionModules(sections[i]).filter(value => value !== id));
        const target = sectionModules(targetSection);
        const position = Math.max(0, Math.min(target.length, Number(targetIndex)));
        target.splice(position, 0, id);
        setSectionModules(targetSection, target);
        endTransaction();
        return true;
    }

    function moveInstance(instanceId, targetSection, targetIndex) {
        return moveModuleInstance(instanceId, targetSection, targetIndex);
    }

    function enabled(moduleName) {
        const name = String(moduleName || "");
        if ((nestedAdapter.modules.instances || {})[name])
            return instanceEnabled(name);
        const id = primaryInstanceId(name);
        return id.length > 0 ? instanceEnabled(id) : true;
    }

    function setModuleEnabled(moduleName, value) {
        const name = String(moduleName || "");
        if ((nestedAdapter.modules.instances || {})[name])
            return setInstanceEnabled(name, value);

        const type = moduleType(name);
        const instances = nestedAdapter.modules.instances || {};
        const ids = Object.keys(instances).filter(id => instances[id].type === type);
        beginTransaction("moduleEnabled");
        if (ids.length <= 0)
            ids.push(createModuleInstance(type));
        for (let i = 0; i < ids.length; i++)
            setInstanceEnabled(ids[i], value);
        endTransaction();
        return true;
    }

    function sectionKey(section) {
        if (section === "left")
            return "leftModules";
        if (section === "center")
            return "centerModules";
        return "rightModules";
    }

    function sectionModules(section) {
        if (section === "left")
            return Array.from(nestedAdapter.modules.left || []);
        if (section === "center")
            return Array.from(nestedAdapter.modules.center || []);
        return Array.from(nestedAdapter.modules.right || []);
    }

    function setSectionModules(section, modules) {
        const requested = Array.from(modules || []);
        const instances = nestedAdapter.modules.instances || {};
        const claimed = {};
        const normalized = [];

        beginTransaction("sectionModules");
        for (let i = 0; i < requested.length; i++) {
            const value = String(requested[i] || "");
            if (instances[value] && !claimed[value]) {
                normalized.push(value);
                claimed[value] = true;
                continue;
            }

            const type = moduleType(value);
            const ids = Object.keys(nestedAdapter.modules.instances || {});
            let id = "";
            for (let j = 0; j < ids.length; j++) {
                const candidate = (nestedAdapter.modules.instances || {})[ids[j]];
                if (!claimed[ids[j]] && candidate.type === type) {
                    id = ids[j];
                    break;
                }
            }
            if (id.length <= 0)
                id = createModuleInstance(type);
            if (id.length > 0) {
                normalized.push(id);
                claimed[id] = true;
            }
        }

        const path = section === "left"
            ? "modules.left"
            : section === "center" ? "modules.center" : "modules.right";
        set(path, normalized);
        endTransaction();
    }

    function hasModule(section, moduleName) {
        const target = moduleType(moduleName);
        const modules = sectionModules(section);
        for (let i = 0; i < modules.length; i++) {
            if (moduleType(modules[i]) === target)
                return true;
        }
        return false;
    }

    function canAddModule(section, moduleName) {
        return availableModules.indexOf(moduleType(moduleName)) >= 0 && !hasModule(section, moduleName);
    }

    function addModule(section, moduleName) {
        if (!canAddModule(section, moduleName))
            return;

        const type = moduleType(moduleName);
        const placed = leftModules.concat(centerModules).concat(rightModules);
        const instances = nestedAdapter.modules.instances || {};
        const ids = Object.keys(instances);
        let id = "";
        for (let i = 0; i < ids.length; i++) {
            if (instances[ids[i]].type === type && placed.indexOf(ids[i]) < 0) {
                id = ids[i];
                break;
            }
        }

        beginTransaction("addModule");
        if (id.length <= 0)
            id = createModuleInstance(type);
        const modules = sectionModules(section);
        modules.push(id);
        setSectionModules(section, modules);
        endTransaction();
    }

    function addModuleToDefault(moduleName) {
        addModule(moduleDefaultSection(moduleName), moduleName);
    }

    function removeModule(section, index) {
        const modules = sectionModules(section);
        if (index < 0 || index >= modules.length)
            return;
        modules.splice(index, 1);
        setSectionModules(section, modules);
    }

    function moveModule(section, index, direction) {
        const modules = sectionModules(section);
        const nextIndex = index + direction;
        if (index < 0 || nextIndex < 0 || index >= modules.length || nextIndex >= modules.length)
            return;
        const current = modules[index];
        modules[index] = modules[nextIndex];
        modules[nextIndex] = current;
        setSectionModules(section, modules);
    }

    function supplementalModuleRegistry() {
        return [
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
        ];
    }

    function mergedModuleRegistry(source) {
        const merged = Array.from(source || []);
        const seen = {};
        for (let i = 0; i < merged.length; i++)
            seen[String(merged[i].id || "")] = true;
        const supplemental = supplementalModuleRegistry();
        for (let i = 0; i < supplemental.length; i++) {
            const id = String(supplemental[i].id || "");
            if (!seen[id]) {
                merged.push(supplemental[i]);
                seen[id] = true;
            }
        }
        return merged;
    }

    function mergedAvailableModules(source) {
        const merged = [];
        const modules = Array.from(source || []);
        for (let i = 0; i < modules.length; i++) {
            const id = moduleType(modules[i]);
            if (merged.indexOf(id) < 0)
                merged.push(id);
        }
        const supplemental = supplementalModuleRegistry();
        for (let i = 0; i < supplemental.length; i++) {
            if (merged.indexOf(supplemental[i].id) < 0)
                merged.push(supplemental[i].id);
        }
        return merged;
    }

    function moduleEntry(moduleName) {
        const name = String(moduleName || "");
        const knownInstance = (nestedAdapter.modules.instances || {})[name];
        const lookup = knownInstance ? String(knownInstance.type || name) : name;
        if (registry) {
            const registered = registry.entry(lookup);
            if (registered)
                return registered;
        }

        const entries = Array.from(moduleRegistry || []);
        for (let i = 0; i < entries.length; i++) {
            if (entries[i].id === lookup || Array.from(entries[i].aliases || []).indexOf(lookup) >= 0)
                return entries[i];
        }
        return {
            "id": lookup,
            "label": lookup,
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

    function moduleDefaultSection(moduleName) {
        const section = String(moduleEntry(moduleName).defaultSection || "right");
        return section === "left" || section === "center" || section === "right" ? section : "right";
    }

    function moduleStatus(moduleName) {
        if (!enabled(moduleName))
            return "disabled";
        const cost = String(moduleCost(moduleName) || "").toLowerCase();
        if (cost.indexOf("polling") >= 0)
            return "polling";
        if (cost.indexOf("event") >= 0)
            return "live";
        if (cost.indexOf("timer") >= 0)
            return "timer";
        if (cost.indexOf("lazy") >= 0)
            return "lazy";
        if (cost.indexOf("local") >= 0)
            return "local";
        return cost.length > 0 ? cost : "unknown";
    }

    function moduleUsed(moduleName) {
        const target = moduleType(moduleName);
        const modules = leftModules.concat(centerModules).concat(rightModules);
        for (let i = 0; i < modules.length; i++) {
            if (moduleType(modules[i]) === target)
                return true;
        }
        return false;
    }

    function unusedModules() {
        const unused = [];
        for (let i = 0; i < availableModules.length; i++) {
            if (!moduleUsed(availableModules[i]))
                unused.push(availableModules[i]);
        }
        return unused;
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

    function flatValue(name) {
        const value = get(name);
        if (value !== undefined)
            return value;
        return defaultAt(name);
    }

    property int version: flatValue("version")
    property int barHeight: flatValue("barHeight")
    property int screenMargin: flatValue("screenMargin")
    property bool reserveSpace: flatValue("reserveSpace")
    property bool showSettingsButton: enabled("settings")
    property int settingsPanelWidth: flatValue("settingsPanelWidth")
    property int settingsPanelGap: flatValue("settingsPanelGap")
    property int groupPadding: flatValue("groupPadding")
    property int pillPadding: flatValue("pillPadding")
    property int groupSpacing: flatValue("groupSpacing")
    property int itemSpacing: flatValue("itemSpacing")
    property int groupRadius: flatValue("groupRadius")
    property int pillRadius: flatValue("pillRadius")
    property string settingsPanelPage: flatValue("settingsPanelPage")
    property string settingsPanelMode: flatValue("settingsPanelMode")
    property string settingsPanelAnchor: flatValue("settingsPanelAnchor")
    property string settingsPanelDensity: flatValue("settingsPanelDensity")
    property bool settingsChangedFooter: flatValue("settingsChangedFooter")
    property bool settingsPreviewEnabled: flatValue("settingsPreviewEnabled")
    property string themeRecipe: flatValue("themeRecipe")
    property var themeRecipes: [
        { "id": "custom", "label": "Custom", "icon": "󰘦", "detail": "Current manual mix" },
        { "id": "calypsoDefault", "label": "Calypso", "icon": "󰣇", "detail": "Balanced islands" },
        { "id": "compactGlass", "label": "Compact glass", "icon": "󰖟", "detail": "Small frosted islands" },
        { "id": "materialSoft", "label": "Material soft", "icon": "󰸌", "detail": "Wallpaper-aware pill" },
        { "id": "denseIslands", "label": "Dense islands", "icon": "󰙀", "detail": "Tight three-group bar" },
        { "id": "minimalSolid", "label": "Minimal solid", "icon": "󰝘", "detail": "One quiet strip" },
        { "id": "focusMode", "label": "Focus", "icon": "󰌵", "detail": "Centered essentials" }
    ]
    property string visualPreset: flatValue("visualPreset")
    property string surfaceStyle: flatValue("surfaceStyle")
    property string pillStyle: flatValue("pillStyle")
    property string hoverEffect: flatValue("hoverEffect")
    property string popupMotion: flatValue("popupMotion")
    property string workspaceIndicatorStyle: flatValue("workspaceIndicatorStyle")
    property bool iconMorphTransitions: flatValue("iconMorphTransitions")
    property real spacingScale: flatValue("spacingScale")
    property real radiusScale: flatValue("radiusScale")
    property string barStyle: flatValue("barStyle")
    property string barPosition: flatValue("barPosition")
    property bool barBlur: flatValue("barBlur")
    property real barOpacity: flatValue("barOpacity")
    property bool barBorderEnabled: flatValue("barBorderEnabled")
    property int barBorderThickness: flatValue("barBorderThickness")
    property string widgetStyle: flatValue("widgetStyle")
    property int trayMaxVisible: flatValue("trayMaxVisible")
    property bool barAutohide: flatValue("barAutohide")
    property string animationProfile: flatValue("animationProfile")
    property string settingsPreset: flatValue("settingsPreset")
    property int osdTimeout: flatValue("osdTimeout")
    property bool osdEnabled: flatValue("osdEnabled")
    property string osdPosition: flatValue("osdPosition")
    property string osdStyle: flatValue("osdStyle")
    property real osdSize: flatValue("osdSize")
    property real osdOpacity: flatValue("osdOpacity")
    property bool osdShowIcon: flatValue("osdShowIcon")
    property bool osdShowPercent: flatValue("osdShowPercent")
    property bool osdVolume: flatValue("osdVolume")
    property bool osdBrightness: flatValue("osdBrightness")
    property bool osdKeyboardBacklight: flatValue("osdKeyboardBacklight")
    property bool osdCapsLock: flatValue("osdCapsLock")
    property bool osdNumLock: flatValue("osdNumLock")
    property bool osdMedia: flatValue("osdMedia")
    property bool osdBattery: flatValue("osdBattery")
    property int tooltipDelay: flatValue("tooltipDelay")
    property bool tooltipsEnabled: flatValue("tooltipsEnabled")
    property int workspaceToastTimeout: flatValue("workspaceToastTimeout")
    property bool reduceMotion: flatValue("reduceMotion")
    property bool performanceMode: flatValue("performanceMode")
    property int animationBaseMs: flatValue("animationMs")
    property int animationMs: reduceMotion || performanceMode ? 0 : animationBaseMs
    property string fontFamilySans: flatValue("fontFamilySans") && flatValue("fontFamilySans").length > 0 ? flatValue("fontFamilySans") : fontFamily
    property string fontFamilyMono: flatValue("fontFamilyMono") && flatValue("fontFamilyMono").length > 0 ? flatValue("fontFamilyMono") : fontFamilySans
    property string fontFamilyIcon: flatValue("fontFamilyIcon") && flatValue("fontFamilyIcon").length > 0 ? flatValue("fontFamilyIcon") : fontFamilySans
    property string fontFamily: flatValue("fontFamily")
    property int fontSize: flatValue("fontSize")
    property int iconSize: flatValue("iconSize")
    property int trayIconSize: flatValue("trayIconSize")
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
    property int motionHover: reduceMotion || performanceMode ? 0 : flatValue("motionHover")
    property int motionFast: reduceMotion || performanceMode ? 0 : flatValue("motionFast")
    property int motionNormal: reduceMotion || performanceMode ? 0 : flatValue("motionNormal")
    property int motionSpatial: reduceMotion || performanceMode ? 0 : flatValue("motionSpatial")
    property int motionPulse: reduceMotion || performanceMode ? 0 : flatValue("motionPulse")
    property int motionBreath: reduceMotion || performanceMode ? 0 : flatValue("motionBreath")
    property int motionOpen: reduceMotion || performanceMode || popupMotion === "none" ? 0 : flatValue("motionOpen")
    property int motionClose: reduceMotion || performanceMode || popupMotion === "none" ? 0 : flatValue("motionClose")
    property int motionEmphasis: reduceMotion || performanceMode ? 0 : flatValue("motionEmphasis")
    property int panelOpacity: flatValue("panelOpacity")
    property bool blurEnabled: flatValue("blurEnabled")
    property bool effectiveBlurEnabled: barBlur && !performanceMode
    property int workspaceMinWidth: flatValue("workspaceMinWidth")
    property int focusedWindowMaxWidth: flatValue("focusedWindowMaxWidth")
    property bool focusedWindowShowTitle: flatValue("focusedWindowShowTitle")
    property string clockFormat: flatValue("clockFormat")
    property bool clockShowSeconds: flatValue("clockShowSeconds")
    property int calendarWeekStart: flatValue("calendarWeekStart")
    property bool clockPanelShowWeek: flatValue("clockPanelShowWeek")
    property bool clockPanelShowDayOfYear: flatValue("clockPanelShowDayOfYear")
    property bool clockPanelShowTimezone: flatValue("clockPanelShowTimezone")
    property bool audioShowPercentage: flatValue("audioShowPercentage")
    property bool audioShowDeviceName: flatValue("audioShowDeviceName")
    property string networkInterfaceName: flatValue("networkInterfaceName")
    property bool networkShowSpeed: flatValue("networkShowSpeed")
    property bool batteryShowPercentage: flatValue("batteryShowPercentage")
    property int batteryCriticalThreshold: flatValue("batteryCriticalThreshold")
    property bool cpuShowGraph: flatValue("cpuShowGraph")
    property bool memoryShowGraph: flatValue("memoryShowGraph")
    property bool brightnessShowPercentage: flatValue("brightnessShowPercentage")
    property int brightnessStep: flatValue("brightnessStep")
    property bool powerProfileShowLabel: flatValue("powerProfileShowLabel")
    property bool mediaShowControls: flatValue("mediaShowControls")
    property int mediaMaxWidth: flatValue("mediaMaxWidth")
    property int mediaMaxTitleLength: flatValue("mediaMaxTitleLength")
    property int dashboardPanelWidth: flatValue("dashboardPanelWidth")
    property bool dashboardShowMedia: flatValue("dashboardShowMedia")
    property bool dashboardShowWeather: flatValue("dashboardShowWeather")
    property bool dashboardGrowFromTrigger: flatValue("dashboardGrowFromTrigger")
    property var dashboardQuickToggles: flatValue("dashboardQuickToggles")
    property var dashboardPerformanceModules: flatValue("dashboardPerformanceModules")
    property int notepadPanelWidth: flatValue("notepadPanelWidth")
    property string notepadFilePath: flatValue("notepadFilePath")
    property int notepadAutosaveMs: flatValue("notepadAutosaveMs")
    property int clipboardPanelWidth: flatValue("clipboardPanelWidth")
    property string clipboardBackend: flatValue("clipboardBackend")
    property int clipboardMaxItems: flatValue("clipboardMaxItems")
    property int processPanelWidth: flatValue("processPanelWidth")
    property int processListLimit: flatValue("processListLimit")
    property int notificationsPanelWidth: flatValue("notificationsPanelWidth")
    property int notificationsMaxVisible: flatValue("notificationsMaxVisible")
    property bool notificationsGroupByApp: flatValue("notificationsGroupByApp")
    property bool notificationsGroupsExpanded: flatValue("notificationsGroupsExpanded")
    property bool notificationsShowBody: flatValue("notificationsShowBody")
    property bool notificationsShowImages: flatValue("notificationsShowImages")
    property bool notificationsShowActions: flatValue("notificationsShowActions")
    property int launcherPanelWidth: flatValue("launcherPanelWidth")
    property int launcherMaxResults: flatValue("launcherMaxResults")
    property string launcherSearchPlaceholder: flatValue("launcherSearchPlaceholder")
    property bool launcherUseFuzzy: flatValue("launcherUseFuzzy")
    property string launcherSortMode: flatValue("launcherSortMode")
    property bool launcherShowIcons: flatValue("launcherShowIcons")
    property bool launcherShowDescriptions: flatValue("launcherShowDescriptions")
    property bool launcherCompactRows: flatValue("launcherCompactRows")
    property bool launcherVimKeybinds: flatValue("launcherVimKeybinds")
    property bool launcherCloseOnLaunch: flatValue("launcherCloseOnLaunch")
    property var launcherFavorites: normalizedStringList(flatValue("launcherFavorites"))
    property var launcherHiddenApps: normalizedStringList(flatValue("launcherHiddenApps"))
    property bool trayCompact: flatValue("trayCompact")
    property string focusedWindowDisplayMode: flatValue("focusedWindowDisplayMode")
    property bool workspaceShowNumbers: flatValue("workspaceShowNumbers")
    property bool workspaceShowOccupied: flatValue("workspaceShowOccupied")
    property bool workspaceShowAppIcons: flatValue("workspaceShowAppIcons")
    property int workspaceMaxAppIcons: flatValue("workspaceMaxAppIcons")
    property bool workspaceScrollEnabled: flatValue("workspaceScrollEnabled")
    property bool workspaceScrollWrap: flatValue("workspaceScrollWrap")
    property bool modulePopupPinned: flatValue("modulePopupPinned")
    property string modulePopupDefaultTab: flatValue("modulePopupDefaultTab")
    property bool modulePopupShowGauge: flatValue("modulePopupShowGauge")
    property bool modulePopupShowSparkline: flatValue("modulePopupShowSparkline")
    property int modulePopupHistorySamples: flatValue("modulePopupHistorySamples")
    property int modulePopupNetworkScaleKib: flatValue("modulePopupNetworkScaleKib")
    property string palettePath: flatValue("palettePath")
    property string paletteSource: flatValue("paletteSource")
    property string manualAccent: flatValue("manualAccent")
    property string customPaletteJson: flatValue("customPaletteJson")
    property string wallpaperDirectory: flatValue("wallpaperDirectory")
    property bool wallpaperRecursive: flatValue("wallpaperRecursive")
    property string currentWallpaper: flatValue("currentWallpaper")
    property var wallpaperFavorites: flatValue("wallpaperFavorites")
    property string wallpaperBackend: flatValue("wallpaperBackend")
    property string wallpaperResizeMode: flatValue("wallpaperResizeMode")
    property string wallpaperCropGravity: flatValue("wallpaperCropGravity")
    property bool wallpaperApplyColors: flatValue("wallpaperApplyColors")
    property string wallpaperTransition: reduceMotion ? "none" : flatValue("wallpaperTransition")
    property real wallpaperTransitionDuration: flatValue("wallpaperTransitionDuration")
    property int wallpaperTransitionFps: flatValue("wallpaperTransitionFps")
    property string wallpaperTransitionPosition: flatValue("wallpaperTransitionPosition")
    property int wallpaperTransitionAngle: flatValue("wallpaperTransitionAngle")
    property string wallpaperTransitionBezier: flatValue("wallpaperTransitionBezier")
    property string wallpaperRandomMode: flatValue("wallpaperRandomMode")
    property string wallpaperSelectedPreview: flatValue("wallpaperSelectedPreview")
    property bool matugenEnabled: flatValue("matugenEnabled")
    property string matugenMode: flatValue("matugenMode")
    property string matugenScheme: flatValue("matugenScheme")
    property string wallpaperLastError: flatValue("wallpaperLastError")
    property string wallpaperLastApplied: flatValue("wallpaperLastApplied")
    property string wallpaperLastPalette: flatValue("wallpaperLastPalette")
    property var compositor: flatValue("compositor")
    property string compositorBackend: compositor && compositor.backend ? compositor.backend : "auto"
    property var moduleRegistry: registry ? registry.entries : mergedModuleRegistry([])
    property var availableModules: registry ? registry.availableTypes : mergedAvailableModules(Object.keys(nestedAdapter.modules.instances || {}).map(id => moduleType(id)))
    property var moduleInstances: nestedAdapter.modules.instances
    property var instanceIds: Object.keys(moduleInstances || {})
    property var leftModules: nestedAdapter.modules.left
    property var centerModules: nestedAdapter.modules.center
    property var rightModules: nestedAdapter.modules.right
    property var moduleVisibility: {
        const visibility = {};
        const instances = moduleInstances || {};
        const ids = Object.keys(instances);
        for (let i = 0; i < ids.length; i++) {
            const type = String(instances[ids[i]].type || ids[i]);
            if (visibility[type] === undefined)
                visibility[type] = instances[ids[i]].enabled !== false;
        }
        return visibility;
    }
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

        path: root.settingsPath
        watchChanges: true
        blockLoading: true
        atomicWrites: true
        printErrors: true
        onLoaded: {
            root.error = "";
            root.saveState = "idle";
            root.clearHistory();
        }
        onLoadFailed: function(loadError) {
            root.error = FileViewError.toString(loadError);
            root.saveState = "error";
        }
        onSaved: {
            root.error = "";
            root.saveState = "saved";
        }
        onSaveFailed: function(saveError) {
            root.error = FileViewError.toString(saveError);
            root.saveState = "error";
        }
        onFileChanged: reload()
        onAdapterUpdated: {
            root.changed();
            root.saveState = "pending";
            saveTimer.restart();
        }

        JsonAdapter {
            id: nestedAdapter

            property int version: root.defaultDocument.version
            property JsonObject app: JsonObject {
                property bool performanceMode: root.defaultDocument.app.performanceMode
                property bool reduceMotion: root.defaultDocument.app.reduceMotion
            }
            property JsonObject bar: JsonObject {
                property int height: root.defaultDocument.bar.height
                property int screenMargin: root.defaultDocument.bar.screenMargin
                property bool reserveSpace: root.defaultDocument.bar.reserveSpace
                property int groupPadding: root.defaultDocument.bar.groupPadding
                property int pillPadding: root.defaultDocument.bar.pillPadding
                property int groupSpacing: root.defaultDocument.bar.groupSpacing
                property int itemSpacing: root.defaultDocument.bar.itemSpacing
                property int groupRadius: root.defaultDocument.bar.groupRadius
                property int pillRadius: root.defaultDocument.bar.pillRadius
                property string style: root.defaultDocument.bar.style
                property string position: root.defaultDocument.bar.position
                property bool blur: root.defaultDocument.bar.blur
                property real opacity: root.defaultDocument.bar.opacity
                property bool borderEnabled: root.defaultDocument.bar.borderEnabled
                property int borderThickness: root.defaultDocument.bar.borderThickness
                property bool autohide: root.defaultDocument.bar.autohide
                property string widgetStyle: root.defaultDocument.bar.widgetStyle
            }
            property JsonObject theme: JsonObject {
                property string recipe: root.defaultDocument.theme.recipe
                property string visualPreset: root.defaultDocument.theme.visualPreset
                property string surfaceStyle: root.defaultDocument.theme.surfaceStyle
                property string pillStyle: root.defaultDocument.theme.pillStyle
                property string hoverEffect: root.defaultDocument.theme.hoverEffect
                property string popupMotion: root.defaultDocument.theme.popupMotion
                property string animationProfile: root.defaultDocument.theme.animationProfile
                property string settingsPreset: root.defaultDocument.theme.settingsPreset
                property bool iconMorphTransitions: root.defaultDocument.theme.iconMorphTransitions
                property real spacingScale: root.defaultDocument.theme.spacingScale
                property real radiusScale: root.defaultDocument.theme.radiusScale
                property int animationMs: root.defaultDocument.theme.animationMs
                property int motionFast: root.defaultDocument.theme.motionFast
                property int motionNormal: root.defaultDocument.theme.motionNormal
                property int motionHover: root.defaultDocument.theme.motionHover
                property int motionPulse: root.defaultDocument.theme.motionPulse
                property int motionBreath: root.defaultDocument.theme.motionBreath
                property int motionOpen: root.defaultDocument.theme.motionOpen
                property int motionClose: root.defaultDocument.theme.motionClose
                property int motionSpatial: root.defaultDocument.theme.motionSpatial
                property int motionEmphasis: root.defaultDocument.theme.motionEmphasis
                property int panelOpacity: root.defaultDocument.theme.panelOpacity
                property bool blurEnabled: root.defaultDocument.theme.blurEnabled
                property string fontFamily: root.defaultDocument.theme.fontFamily
                property string fontFamilySans: root.defaultDocument.theme.fontFamilySans
                property string fontFamilyMono: root.defaultDocument.theme.fontFamilyMono
                property string fontFamilyIcon: root.defaultDocument.theme.fontFamilyIcon
                property int fontSize: root.defaultDocument.theme.fontSize
                property int iconSize: root.defaultDocument.theme.iconSize
                property string palettePath: root.defaultDocument.theme.palettePath
                property string paletteSource: root.defaultDocument.theme.paletteSource
                property string manualAccent: root.defaultDocument.theme.manualAccent
                property string customPaletteJson: root.defaultDocument.theme.customPaletteJson
                property bool matugenEnabled: root.defaultDocument.theme.matugenEnabled
                property string matugenMode: root.defaultDocument.theme.matugenMode
                property string matugenScheme: root.defaultDocument.theme.matugenScheme
            }
            property JsonObject modules: JsonObject {
                property var left: root.clone(root.defaultDocument.modules.left)
                property var center: root.clone(root.defaultDocument.modules.center)
                property var right: root.clone(root.defaultDocument.modules.right)
                property var instances: root.clone(root.defaultDocument.modules.instances)
            }
            property JsonObject panels: JsonObject {
                property var settings: root.clone(root.defaultDocument.panels.settings)
                property var osd: root.clone(root.defaultDocument.panels.osd)
                property var clock: root.clone(root.defaultDocument.panels.clock)
                property var dashboard: root.clone(root.defaultDocument.panels.dashboard)
                property var notepad: root.clone(root.defaultDocument.panels.notepad)
                property var clipboard: root.clone(root.defaultDocument.panels.clipboard)
                property var processes: root.clone(root.defaultDocument.panels.processes)
                property var notifications: root.clone(root.defaultDocument.panels.notifications)
                property var launcher: root.clone(root.defaultDocument.panels.launcher)
                property var modulePopup: root.clone(root.defaultDocument.panels.modulePopup)
            }
            property JsonObject services: JsonObject {
                property var polling: root.clone(root.defaultDocument.services.polling)
                property var compositor: root.clone(root.defaultDocument.services.compositor)
                property var clipboard: root.clone(root.defaultDocument.services.clipboard)
                property var wallpaper: root.clone(root.defaultDocument.services.wallpaper)
            }
            property JsonObject ui: JsonObject {
                property int tooltipDelay: root.defaultDocument.ui.tooltipDelay
                property bool tooltipsEnabled: root.defaultDocument.ui.tooltipsEnabled
                property int workspaceToastTimeout: root.defaultDocument.ui.workspaceToastTimeout
            }
            property JsonObject migration: JsonObject {
                property int sourceVersion: root.defaultDocument.migration.sourceVersion
                property string migratedAt: root.defaultDocument.migration.migratedAt
                property var unmapped: root.clone(root.defaultDocument.migration.unmapped)
            }
        }
    }

    Timer {
        id: saveTimer

        interval: 80
        repeat: false
        onTriggered: {
            root.saveState = "saving";
            settingsFile.writeAdapter();
        }
    }
}
