import QtQuick

Pill {
    id: root

    property date now: new Date()
    readonly property string effectiveClockFormat: moduleSettings.format === undefined
                                                       ? (settings ? settings.clockFormat : "HH:mm")
                                                       : String(moduleSettings.format)

    signal requested(var anchorItem)

    icon: "󰥔"
    text: Qt.formatDateTime(now, effectiveClockFormat)
    detailText: settings.widgetStyle === "expanded" ? Qt.formatDateTime(now, "ddd, MMM d") : ""
    active: true
    clickable: true
    textPulseOnChange: true
    textPulseMinimumOpacity: 0.4
    textPulseDuration: Math.max(0, theme.motionNormal)
    maximumTextWidth: theme.moduleClockWidth
    onClicked: requested(root)

    function formatNeedsSubminuteUpdates() {
        const format = String(effectiveClockFormat || "");
        return format.indexOf("s") >= 0 || format.indexOf("z") >= 0;
    }

    function nextInterval() {
        if (formatNeedsSubminuteUpdates()) return settings.clockPollMs;

        const date = new Date();
        return Math.max(250, 60000 - date.getSeconds() * 1000 - date.getMilliseconds() + 20);
    }

    function refresh() {
        now = new Date();
        clockTimer.interval = nextInterval();
        clockTimer.restart();
    }

    Timer {
        id: clockTimer

        interval: settings.clockPollMs
        repeat: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
    onEffectiveClockFormatChanged: root.refresh()
}
