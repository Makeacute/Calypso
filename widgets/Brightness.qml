import QtQuick
import Quickshell.Io

Pill {
    id: root

    property bool available: false
    property bool hasBrightnessctl: false
    property string deviceName: ""
    property real percent: 0
    property int rawCurrent: 0
    property int rawMax: 0
    readonly property bool showPercentage: moduleSettings.showPercentage === undefined
                                               ? settingBool("brightnessShowPercentage", true)
                                               : Boolean(moduleSettings.showPercentage)
    readonly property int stepPercent: moduleSettings.step === undefined
                                           ? settingNumber("brightnessStep", 5, 1, 25)
                                           : Math.max(1, Math.min(25, Math.round(Number(moduleSettings.step))))
    readonly property int minimumPercent: settingNumber("brightnessMinPercent", 1, 1, 99)
    readonly property int pollMs: settingPollMs("brightnessPollMs", "brightnessMs", 15000)

    icon: brightnessIcon(percent)
    text: available && showPercentage ? Math.round(percent) + "%" : ""
    detailText: settings.widgetStyle === "expanded" ? deviceName : ""
    muted: !available
    progress: available ? Math.max(0, Math.min(1, percent / 100)) : -1
    progressColor: theme.alpha(theme.accent, 0.16)
    scrollable: available && hasBrightnessctl && !setProc.running
    iconFadeOnChange: true
    textPulseOnChange: available && showPercentage
    maximumTextWidth: theme.moduleBatteryValueWidth
    detailsOnClick: true
    detailsModuleName: moduleInstanceId || "brightness"
    onScrolled: function(steps, wheel) {
        adjustBrightness(steps);
    }

    function settingValue(name, fallback) {
        if (!settings) return fallback;

        try {
            const value = settings[name];
            return value === undefined || value === null ? fallback : value;
        } catch (error) {
            return fallback;
        }
    }

    function settingBool(name, fallback) {
        const value = settingValue(name, fallback);
        if (typeof value === "boolean") return value;
        if (typeof value === "string") return value.toLowerCase() === "true";
        return Boolean(value);
    }

    function settingNumber(name, fallback, minimum, maximum) {
        const number = Number(settingValue(name, fallback));
        const bounded = Number.isFinite(number) ? number : fallback;
        return Math.max(minimum, Math.min(maximum, Math.round(bounded)));
    }

    function settingPollMs(propertyName, pollingName, fallback) {
        const direct = settingValue(propertyName, undefined);
        if (direct !== undefined) return settingNumber(propertyName, fallback, 1000, 300000);

        if (settings && typeof settings.pollInterval === "function") {
            const value = Number(settings.pollInterval(pollingName, fallback));
            if (Number.isFinite(value)) return Math.max(1000, Math.min(300000, Math.round(value)));
        }

        return fallback;
    }

    function brightnessIcon(value) {
        if (!available) return "󰃞";
        if (value < 34) return "󰃞";
        if (value < 67) return "󰃟";
        return "󰃠";
    }

    function clampPercent(value) {
        return Math.max(minimumPercent, Math.min(100, Math.round(Number(value) || 0)));
    }

    function updateState(isAvailable, canSet, name, current, maximum, valuePercent) {
        available = isAvailable;
        hasBrightnessctl = canSet;
        deviceName = name;
        rawCurrent = current;
        rawMax = maximum;
        percent = Math.max(0, Math.min(100, valuePercent));
    }

    function parseBrightnessctl(data) {
        const fields = String(data || "").trim().split(",");
        const percentIndex = fields.findIndex(field => field.indexOf("%") >= 0);
        const current = Number(fields[2]) || 0;
        let maximum = 0;
        let valuePercent = 0;

        if (percentIndex >= 0) {
            valuePercent = Number(fields[percentIndex].replace("%", "")) || 0;
            if (percentIndex + 1 < fields.length) maximum = Number(fields[percentIndex + 1]) || 0;
            if (maximum <= 0 && percentIndex > 3) maximum = Number(fields[3]) || 0;
        }

        if (maximum <= 0 && current > 0 && valuePercent > 0) {
            maximum = Math.round(current / Math.max(0.01, valuePercent / 100));
        }

        if (percentIndex < 0 && maximum > 0) valuePercent = current / maximum * 100;

        if (fields.length < 3 || (!Number.isFinite(valuePercent) && maximum <= 0)) {
            updateState(false, true, "", 0, 0, 0);
            return;
        }

        updateState(true, true, String(fields[0] || ""), current, maximum, valuePercent);
    }

    function updateFromRead(output) {
        const line = String(output || "").trim().split("\n")[0] || "";
        if (line.length === 0) {
            updateState(false, false, "", 0, 0, 0);
            return;
        }

        const parts = line.split("|");
        const origin = parts[0];

        if (origin === "brightnessctl") {
            parseBrightnessctl(parts.slice(1).join("|"));
            return;
        }

        if (origin === "sysfs" && parts.length >= 5) {
            const canSet = parts[1] === "1";
            const current = Number(parts[3]);
            const maximum = Number(parts[4]);
            if (Number.isFinite(current) && Number.isFinite(maximum) && maximum > 0) {
                updateState(true, canSet, parts[2], current, maximum, current / maximum * 100);
                return;
            }
        }

        if (origin === "missing" && parts.length >= 2) {
            updateState(false, parts[1] === "1", "", 0, 0, 0);
            return;
        }

        updateState(false, false, "", 0, 0, 0);
    }

    function refresh() {
        if (!readProc.running) readProc.running = true;
    }

    function adjustBrightness(steps) {
        if (!available || !hasBrightnessctl || setProc.running) return;

        const direction = Number(steps) || 0;
        if (direction === 0) return;

        const next = clampPercent(percent + direction * stepPercent);
        setProc.command = ["brightnessctl", "-c", "backlight", "set", next + "%"];
        setProc.running = true;
        percent = next;
    }

    Process {
        id: readProc

        command: [
            "sh",
            "-c",
            "hasctl=0; if command -v brightnessctl >/dev/null 2>&1; then hasctl=1; data=$(brightnessctl -m -c backlight info 2>/dev/null || true); if [ -n \"$data\" ]; then printf 'brightnessctl|%s\\n' \"$data\"; exit 0; fi; fi; for d in /sys/class/backlight/*; do [ -r \"$d/brightness\" ] || continue; [ -r \"$d/max_brightness\" ] || continue; cur=$(cat \"$d/brightness\" 2>/dev/null || true); max=$(cat \"$d/max_brightness\" 2>/dev/null || true); [ -n \"$cur\" ] && [ -n \"$max\" ] || continue; case \"$cur$max\" in *[!0-9]*) continue;; esac; [ \"$max\" -gt 0 ] 2>/dev/null || continue; printf 'sysfs|%s|%s|%s|%s\\n' \"$hasctl\" \"$(basename \"$d\")\" \"$cur\" \"$max\"; exit 0; done; printf 'missing|%s\\n' \"$hasctl\""
        ]
        stdout: StdioCollector {
            onStreamFinished: root.updateFromRead(text)
        }
        stderr: StdioCollector {}
    }

    Process {
        id: setProc

        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onRunningChanged: {
            if (!running) root.refresh();
        }
    }

    Timer {
        interval: root.pollMs
        running: root.visible && root.pollMs > 0
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
