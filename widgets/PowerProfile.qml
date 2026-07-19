import QtQuick
import Quickshell.Io

Pill {
    id: root

    property bool available: false
    property string profile: ""
    readonly property var cycleProfiles: ["power-saver", "balanced", "performance"]
    readonly property int pollMs: settingPollMs("powerProfilePollMs", "powerProfileMs", 30000)

    icon: profileIcon(profile)
    text: available && settings.powerProfileShowLabel ? profile : ""
    detailText: settings.widgetStyle === "expanded" && available ? "power profile" : ""
    active: available && profile !== "balanced"
    muted: !available
    clickable: available && !setProc.running
    accentColor: profile === "power-saver" ? theme.good
                 : profile === "performance" ? theme.warning
                                               : theme.accent
    iconFadeOnChange: true
    textPulseOnChange: available
    maximumTextWidth: 102
    onClicked: function(mouse) {
        cycleProfile();
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

    function settingPollMs(propertyName, pollingName, fallback) {
        const direct = settingValue(propertyName, undefined);
        if (direct !== undefined) {
            const number = Number(direct);
            if (Number.isFinite(number)) return Math.max(1000, Math.min(300000, Math.round(number)));
        }

        if (settings && typeof settings.pollInterval === "function") {
            const value = Number(settings.pollInterval(pollingName, fallback));
            if (Number.isFinite(value)) return Math.max(1000, Math.min(300000, Math.round(value)));
        }

        return fallback;
    }

    function profileIcon(value) {
        if (value === "power-saver") return "";
        if (value === "performance") return "";
        if (value === "balanced") return "";
        return "󰚥";
    }

    function updateFromRead(output) {
        const value = String(output || "").trim().split(/\s+/)[0] || "";
        available = value.length > 0;
        profile = available ? value : "";
    }

    function refresh() {
        if (!readProc.running) readProc.running = true;
    }

    function cycleProfile() {
        if (!available || setProc.running) return;

        const index = cycleProfiles.indexOf(profile);
        const next = index >= 0 ? cycleProfiles[(index + 1) % cycleProfiles.length] : cycleProfiles[0];
        profile = next;
        setProc.command = ["powerprofilesctl", "set", next];
        setProc.running = true;
    }

    Process {
        id: readProc

        command: ["sh", "-c", "command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl get 2>/dev/null || true"]
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
