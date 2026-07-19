import QtQuick
import Quickshell.Io

Pill {
    id: root

    property string device: ""
    property bool online: false
    property real rxBytes: 0
    property real txBytes: 0
    property real rxRate: 0
    property real txRate: 0
    property real previousSampleMs: 0

    icon: online ? networkIcon(device) : "󰤮"
    text: networkText()
    detailText: settings.widgetStyle === "expanded" && online ? speedText() : ""
    muted: !online
    iconFadeOnChange: true
    textPulseOnChange: true
    maximumTextWidth: settings.networkShowSpeed ? 88 : 72
    detailsOnClick: true
    detailsModuleName: "network"

    function networkIcon(name) {
        const value = String(name || "").toLowerCase();
        if (value.startsWith("wl") || value.includes("wifi") || value.includes("wlan")) return "󰤨";
        if (value.startsWith("en") || value.includes("eth")) return "󰈀";
        return "󰌘";
    }

    function shortDevice(name) {
        const value = String(name || "");
        return value.length > 8 ? value.slice(0, 8) : value;
    }

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\\''") + "'";
    }

    function configuredDevice() {
        return String(settings.networkInterfaceName || "").trim();
    }

    function speedText() {
        const total = Math.max(0, rxRate + txRate);
        if (total < 1024) return Math.round(total) + "B/s";
        if (total < 1024 * 1024) return Math.round(total / 1024) + "K/s";
        return (Math.round(total / 1024 / 1024 * 10) / 10) + "M/s";
    }

    function networkText() {
        if (!online) return "down";
        return settings.networkShowSpeed ? speedText() : shortDevice(device);
    }

    function refresh() {
        const requested = configuredDevice();
        if (requested.length > 0) {
            const quoted = shellQuote(requested);
            proc.command = [
                "sh",
                "-c",
                "test -d /sys/class/net/" + quoted + " && printf '[{\"dev\":\"%s\"}]\\n' " + quoted
            ];
        } else {
            proc.command = ["ip", "-j", "route", "get", "1.1.1.1"];
        }

        if (!proc.running) proc.running = true;
    }

    function refreshStats() {
        if (!settings.networkShowSpeed || !online || device.length === 0 || statsProc.running) return;

        const quoted = shellQuote(device);
        statsProc.command = [
            "sh",
            "-c",
            "cat /sys/class/net/" + quoted + "/statistics/rx_bytes /sys/class/net/" + quoted + "/statistics/tx_bytes"
        ];
        statsProc.running = true;
    }

    function updateStats(text) {
        const lines = String(text || "").trim().split(/\s+/).map(Number);
        if (lines.length < 2 || !Number.isFinite(lines[0]) || !Number.isFinite(lines[1])) return;

        const now = Date.now();
        if (previousSampleMs > 0) {
            const seconds = Math.max(0.001, (now - previousSampleMs) / 1000);
            rxRate = Math.max(0, (lines[0] - rxBytes) / seconds);
            txRate = Math.max(0, (lines[1] - txBytes) / seconds);
        }

        rxBytes = lines[0];
        txBytes = lines[1];
        previousSampleMs = now;
    }

    Process {
        id: proc

        command: ["ip", "-j", "route", "get", "1.1.1.1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text);
                    root.device = parsed.length > 0 ? String(parsed[0].dev || "") : "";
                    root.online = root.device.length > 0;
                    root.refreshStats();
                } catch (error) {
                    root.device = "";
                    root.online = false;
                    root.previousSampleMs = 0;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    root.device = "";
                    root.online = false;
                    root.previousSampleMs = 0;
                }
            }
        }
    }

    Process {
        id: statsProc

        stdout: StdioCollector {
            onStreamFinished: root.updateStats(text)
        }
        stderr: StdioCollector {}
    }

    Timer {
        interval: settings.networkPollMs
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
