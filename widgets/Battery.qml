import QtQuick

Pill {
    id: root

    property var batteryService
    readonly property bool available: batteryService ? Boolean(batteryService.available) : false
    readonly property real percent: available ? Number(batteryService.percent) || 0 : 0
    readonly property bool charging: available ? Boolean(batteryService.charging) : false
    readonly property bool activelyCharging: available
                                                  ? Boolean(batteryService.activelyCharging)
                                                  : false
    readonly property bool showPercentage: moduleSettings.showPercentage === undefined
                                               ? settings.batteryShowPercentage
                                               : Boolean(moduleSettings.showPercentage)
    readonly property int criticalThreshold: Math.max(1, moduleSettings.criticalThreshold === undefined
                                                         ? settings.batteryCriticalThreshold
                                                         : Number(moduleSettings.criticalThreshold))

    icon: batteryIcon(percent, charging)
    text: showPercentage ? Math.round(percent) + "%" : ""
    detailText: settings.widgetStyle === "expanded" ? timeRemainingText() : ""
    active: charging
    urgent: percent > 0 && percent <= criticalThreshold
    accentColor: batteryTone()
    customContentColor: true
    contentColor: batteryTone()
    progressColor: theme.alpha(batteryTone(), 0.16)
    textPulseOnChange: percent > 0 && showPercentage
    maximumTextWidth: theme.moduleBatteryValueWidth
    detailsOnClick: true
    detailsModuleName: moduleInstanceId || "battery"

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
        if (!available) return "";

        const seconds = activelyCharging ? Number(batteryService.timeToFull)
                                         : Number(batteryService.timeToEmpty);
        if (!Number.isFinite(seconds) || seconds <= 0) return charging ? "charging" : "";

        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        if (hours <= 0) return minutes + "m";
        return hours + "h " + minutes + "m";
    }
}
