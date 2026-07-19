import QtQuick
import Quickshell.Io

Pill {
    id: root

    property real usedPercent: 0
    property var usageHistory: []

    icon: ""
    text: settings.memoryShowGraph ? "" : Math.round(usedPercent) + "%"
    detailText: settings.widgetStyle === "expanded" ? Math.round(usedPercent) + "% used" : ""
    active: usedPercent >= 75
    urgent: usedPercent >= 90
    progress: settings.memoryShowGraph ? -1 : usedPercent / 100
    progressColor: theme.alpha(graphColor, 0.16)
    textPulseOnChange: !settings.memoryShowGraph
    maximumTextWidth: settings.memoryShowGraph ? 96 : 52
    showGraph: settings.memoryShowGraph
    graphValues: usageHistory
    graphColor: urgent ? theme.urgent : active ? theme.warning : theme.accent
    detailsOnClick: true
    detailsModuleName: "memory"

    function refresh() {
        meminfoFile.reload();
    }

    function rememberUsage(value) {
        const next = Array.from(usageHistory || []);
        next.push(Math.max(0, Math.min(1, value / 100)));

        while (next.length > 12) next.shift();
        usageHistory = next;
    }

    function updateFromMeminfo(meminfo) {
        const lines = String(meminfo || "").split("\n");
        let total = 0;
        let available = 0;

        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split(/\s+/);
            if (parts[0] === "MemTotal:") total = Number(parts[1]);
            if (parts[0] === "MemAvailable:") available = Number(parts[1]);
        }

        if (total > 0 && available > 0) {
            usedPercent = Math.max(0, Math.min(100, (1 - available / total) * 100));
            rememberUsage(usedPercent);
        }
    }

    FileView {
        id: meminfoFile

        path: "/proc/meminfo"
        watchChanges: false
        blockLoading: true
        printErrors: false
        onLoaded: root.updateFromMeminfo(text())
    }

    Timer {
        interval: settings.memoryPollMs
        running: root.visible && settings.memoryPollMs > 0
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
