import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower

Pill {
    id: root

    property var device: UPower.displayDevice
    property bool upowerReady: device && device.isPresent
    property real fallbackPercent: 0
    property string fallbackState: ""
    property real percent: upowerReady ? normalizePercent(device.percentage) : fallbackPercent
    property int state: upowerReady ? device.state : UPowerDeviceState.Unknown
    property bool charging: upowerReady ? state === UPowerDeviceState.Charging || state === UPowerDeviceState.FullyCharged
                                  : fallbackState === "Charging" || fallbackState === "Full"
    property bool activelyCharging: upowerReady ? state === UPowerDeviceState.Charging : fallbackState === "Charging"
    property int criticalThreshold: Math.max(1, settings.batteryCriticalThreshold)

    icon: batteryIcon(percent, charging)
    text: settings.batteryShowPercentage ? Math.round(percent) + "%" : ""
    detailText: settings.widgetStyle === "expanded" ? timeRemainingText() : ""
    active: charging
    urgent: percent > 0 && percent <= criticalThreshold
    accentColor: batteryTone()
    customContentColor: true
    contentColor: batteryTone()
    progressColor: theme.alpha(batteryTone(), 0.16)
    textPulseOnChange: percent > 0 && settings.batteryShowPercentage
    maximumTextWidth: 54
    detailsOnClick: true
    detailsModuleName: "battery"

    function normalizePercent(value) {
        const number = Number(value) || 0;
        return number <= 1 ? number * 100 : number;
    }

    function batteryIcon(value, isCharging) {
        if (isCharging && value >= 95) return "󰂅";
        if (isCharging) return "󰂄";
        if (value >= 90) return "󰁹";
        if (value >= 70) return "󰂂";
        if (value >= 50) return "󰁿";
        if (value >= 30) return "󰁽";
        if (value >= criticalThreshold) return "󰁻";
        return "󰁺";
    }

    function batteryTone() {
        if (percent <= 0) return theme.textMuted;
        if (percent <= criticalThreshold) return theme.error;
        if (percent <= Math.min(100, criticalThreshold * 2)) return theme.warning;
        return theme.primary;
    }

    function timeRemainingText() {
        if (!upowerReady || !device) return "";

        const seconds = activelyCharging ? Number(device.timeToFull) : Number(device.timeToEmpty);
        if (!Number.isFinite(seconds) || seconds <= 0) return charging ? "charging" : "";

        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        if (hours <= 0) return minutes + "m";
        return hours + "h " + minutes + "m";
    }

    function refreshFallback() {
        capacityFile.reload();
        statusFile.reload();
    }

    FileView {
        id: capacityFile

        path: "/sys/class/power_supply/BAT1/capacity"
        watchChanges: true
        blockLoading: true
        printErrors: false
        onLoaded: root.fallbackPercent = Number(text().trim()) || 0
        onFileChanged: root.fallbackPercent = Number(text().trim()) || 0
    }

    FileView {
        id: statusFile

        path: "/sys/class/power_supply/BAT1/status"
        watchChanges: true
        blockLoading: true
        printErrors: false
        onLoaded: root.fallbackState = text().trim()
        onFileChanged: root.fallbackState = text().trim()
    }

    Timer {
        interval: settings.batteryFallbackPollMs
        running: !root.upowerReady
        repeat: true
        onTriggered: root.refreshFallback()
    }

    Component.onCompleted: root.refreshFallback()
}
