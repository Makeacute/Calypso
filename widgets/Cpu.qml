import QtQuick
import Quickshell.Io

Pill {
    id: root

    property real usage: 0
    property real previousTotal: 0
    property real previousIdle: 0
    property var usageHistory: []

    icon: ""
    text: settings.cpuShowGraph ? "" : Math.round(usage) + "%"
    detailText: settings.widgetStyle === "expanded" ? Math.round(usage) + "% load" : ""
    active: usage >= 75
    urgent: usage >= 92
    progress: settings.cpuShowGraph ? -1 : usage / 100
    progressColor: theme.alpha(graphColor, 0.16)
    textPulseOnChange: !settings.cpuShowGraph
    maximumTextWidth: settings.cpuShowGraph ? 96 : 52
    showGraph: settings.cpuShowGraph
    graphValues: usageHistory
    graphColor: urgent ? theme.urgent : active ? theme.warning : theme.accent
    detailsOnClick: true
    detailsModuleName: "cpu"

    function refresh() {
        statFile.reload();
    }

    function rememberUsage(value) {
        const next = Array.from(usageHistory || []);
        next.push(Math.max(0, Math.min(1, value / 100)));

        while (next.length > 12) next.shift();
        usageHistory = next;
    }

    function updateFromStat(statText) {
        const firstLine = String(statText || "").split("\n")[0].trim();
        const fields = firstLine.split(/\s+/).slice(1).map(Number);
        if (fields.length < 5) return;

        let total = 0;
        for (let i = 0; i < fields.length; i++) total += fields[i];

        const idle = fields[3] + (fields[4] || 0);
        if (previousTotal > 0) {
            const totalDelta = total - previousTotal;
            const idleDelta = idle - previousIdle;
            if (totalDelta > 0) {
                usage = Math.max(0, Math.min(100, (1 - idleDelta / totalDelta) * 100));
                rememberUsage(usage);
            }
        }

        previousTotal = total;
        previousIdle = idle;
    }

    FileView {
        id: statFile

        path: "/proc/stat"
        watchChanges: false
        blockLoading: true
        printErrors: false
        onLoaded: root.updateFromStat(text())
    }

    Timer {
        interval: settings.cpuPollMs
        running: root.visible && settings.cpuPollMs > 0
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
