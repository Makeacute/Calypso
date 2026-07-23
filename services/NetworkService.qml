pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool enabled: true
    property bool performanceMode: false
    property string interfaceName: ""
    property string routeProbeAddress: "1.1.1.1"
    property int reconnectIntervalMs: 3000
    property int throughputIntervalMs: 5000
    property int consumerCount: 0

    property bool _backendAvailable: false
    property bool _monitorStarted: false
    property bool _refreshPending: false
    property bool _connectionRefreshPending: false
    property string _stateError: ""
    property string _connectionError: ""
    property string _lastError: ""
    property string _connectionProbeDevice: ""
    property real _previousRxBytes: 0
    property real _previousTxBytes: 0
    property real _previousSampleMs: 0

    readonly property bool available: _backendAvailable
    readonly property bool connected: _monitorStarted && eventMonitor.running
    readonly property bool reconnecting: enabled && !connected && reconnectTimer.running
    readonly property string healthStatus: connected ? "ready"
                                                    : reconnecting ? "reconnecting"
                                                                   : enabled ? "unavailable"
                                                                             : "disabled"
    readonly property string lastError: _lastError

    readonly property bool online: _online
    readonly property string device: _device
    readonly property string connectionName: _connectionName
    readonly property string connectionType: classifyDevice(device)
    readonly property real rxBytes: _rxBytes
    readonly property real txBytes: _txBytes
    readonly property real rxRate: _rxRate
    readonly property real txRate: _txRate
    readonly property bool throughputActive: throughputTimer.running
    readonly property bool samplingThroughput: statsProcess.running

    property bool _online: false
    property string _device: ""
    property string _connectionName: ""
    property real _rxBytes: 0
    property real _txBytes: 0
    property real _rxRate: 0
    property real _txRate: 0

    signal stateRefreshed()
    signal throughputSampled(real rxRate, real txRate)

    function classifyDevice(name) {
        const value = String(name || "").toLowerCase();
        if (value.startsWith("wl") || value.indexOf("wifi") >= 0 || value.indexOf("wlan") >= 0)
            return "wifi";
        if (value.startsWith("en") || value.indexOf("eth") >= 0)
            return "ethernet";
        if (value.length > 0)
            return "other";
        return "none";
    }

    function addConsumer() {
        consumerCount += 1;
    }

    function removeConsumer() {
        consumerCount = Math.max(0, consumerCount - 1);
    }

    function resetThroughput(clearTotals) {
        _previousRxBytes = 0;
        _previousTxBytes = 0;
        _previousSampleMs = 0;
        _rxRate = 0;
        _txRate = 0;
        if (clearTotals) {
            _rxBytes = 0;
            _txBytes = 0;
        }
    }

    function ensureMonitor() {
        if (enabled && !eventMonitor.running)
            eventMonitor.running = true;
    }

    function refresh() {
        if (stateProcess.running) {
            _refreshPending = true;
            return;
        }

        _refreshPending = false;
        _stateError = "";
        stateProcess.command = interfaceName.trim().length > 0
                ? ["ip", "-j", "link", "show", "dev", interfaceName.trim()]
                : ["ip", "-j", "route", "get", routeProbeAddress];
        stateProcess.running = true;
    }

    function applyState(text) {
        try {
            const parsed = JSON.parse(String(text || "[]"));
            const entry = parsed.length > 0 ? parsed[0] : null;
            let nextDevice = "";
            let nextOnline = false;

            if (entry && interfaceName.trim().length > 0) {
                nextDevice = String(entry.ifname || interfaceName.trim());
                const flags = Array.from(entry.flags || []);
                const operstate = String(entry.operstate || "").toUpperCase();
                nextOnline = flags.indexOf("UP") >= 0
                        && (flags.indexOf("LOWER_UP") >= 0 || operstate === "UP" || operstate === "UNKNOWN");
            } else if (entry) {
                nextDevice = String(entry.dev || "");
                nextOnline = nextDevice.length > 0 && nextDevice !== "lo";
            }

            if (_device !== nextDevice)
                resetThroughput(true);
            _device = nextDevice;
            _online = nextOnline;
            if (_online)
                refreshConnectionName();
            else
                _connectionName = "";
            _backendAvailable = true;
            _lastError = "";
            stateRefreshed();
        } catch (error) {
            _online = false;
            _device = "";
            resetThroughput(true);
            _lastError = "Failed to parse network state: " + String(error);
        }
    }

    function refreshConnectionName() {
        if (!online || device.length === 0) {
            _connectionName = "";
            return;
        }
        if (connectionProcess.running) {
            _connectionRefreshPending = true;
            return;
        }

        _connectionRefreshPending = false;
        _connectionError = "";
        _connectionProbeDevice = device;
        connectionProcess.command = [
            "sh",
            "-c",
            "command -v nmcli >/dev/null 2>&1 || exit 127; connection=$(nmcli -g GENERAL.CONNECTION --escape no device show \"$1\") || exit; ssid=$(nmcli -g 802-11-wireless.ssid --escape no connection show \"$connection\" 2>/dev/null); printf '%s\\n' \"${ssid:-$connection}\"",
            "sh",
            device
        ];
        connectionProcess.running = true;
    }

    function applyConnectionName(text) {
        if (_connectionProbeDevice !== device)
            return;
        const value = String(text || "").trim();
        _connectionName = value === "--" ? "" : value;
    }

    function sampleThroughput() {
        if (!throughputActive || statsProcess.running || device.length === 0)
            return;

        statsProcess.command = [
            "sh",
            "-c",
            "d=/sys/class/net/$1/statistics; cat \"$d/rx_bytes\" \"$d/tx_bytes\"",
            "sh",
            device
        ];
        statsProcess.running = true;
    }

    function applyThroughput(text) {
        const fields = String(text || "").trim().split(/\s+/).map(Number);
        if (fields.length < 2 || !Number.isFinite(fields[0]) || !Number.isFinite(fields[1]))
            return;

        const now = Date.now();
        if (_previousSampleMs > 0) {
            const elapsedSeconds = Math.max(0.001, (now - _previousSampleMs) / 1000);
            _rxRate = fields[0] >= _previousRxBytes
                    ? (fields[0] - _previousRxBytes) / elapsedSeconds
                    : 0;
            _txRate = fields[1] >= _previousTxBytes
                    ? (fields[1] - _previousTxBytes) / elapsedSeconds
                    : 0;
            throughputSampled(_rxRate, _txRate);
        }

        _rxBytes = fields[0];
        _txBytes = fields[1];
        _previousRxBytes = fields[0];
        _previousTxBytes = fields[1];
        _previousSampleMs = now;
    }

    onEnabledChanged: {
        if (enabled) {
            ensureMonitor();
            refresh();
        } else {
            reconnectTimer.stop();
            eventMonitor.running = false;
            _monitorStarted = false;
        }
    }
    onInterfaceNameChanged: refresh()
    onRouteProbeAddressChanged: refresh()

    Process {
        id: eventMonitor

        command: ["ip", "monitor", "link", "address", "route"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(data) {
                if (String(data || "").trim().length > 0)
                    root.refresh();
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function(data) {
                const message = String(data || "").trim();
                if (message.length > 0)
                    root._lastError = message;
            }
        }
        onStarted: {
            root._monitorStarted = true;
            root._backendAvailable = true;
            root._lastError = "";
            root.refresh();
        }
        onExited: function(exitCode) {
            root._monitorStarted = false;
            root._backendAvailable = false;
            if (root.enabled) {
                if (root._lastError.length === 0)
                    root._lastError = "ip monitor exited with code " + exitCode;
                if (root.reconnectIntervalMs > 0)
                    reconnectTimer.restart();
            }
        }
    }

    Process {
        id: stateProcess

        stdout: StdioCollector {
            onStreamFinished: root.applyState(text)
        }
        stderr: StdioCollector {
            onStreamFinished: root._stateError = text.trim()
        }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root._online = false;
                root._device = "";
                root.resetThroughput(true);
                root._lastError = root._stateError || "Failed to query network state";
            }
            if (root._refreshPending)
                root.refresh();
        }
    }

    Process {
        id: statsProcess

        stdout: StdioCollector {
            onStreamFinished: root.applyThroughput(text)
        }
        stderr: StdioCollector {}
    }

    Process {
        id: connectionProcess

        stdout: StdioCollector {
            onStreamFinished: root.applyConnectionName(text)
        }
        stderr: StdioCollector {
            onStreamFinished: root._connectionError = text.trim()
        }
        onExited: function(exitCode) {
            if (exitCode !== 0 && root._connectionProbeDevice === root.device)
                root._connectionName = "";
            if (root._connectionRefreshPending)
                root.refreshConnectionName();
        }
    }

    Timer {
        id: reconnectTimer

        interval: root.reconnectIntervalMs
        repeat: false
        onTriggered: root.ensureMonitor()
    }

    Timer {
        id: throughputTimer

        interval: root.throughputIntervalMs
        running: root.enabled
                 && root.consumerCount > 0
                 && !root.performanceMode
                 && root.online
                 && root.throughputIntervalMs > 0
        repeat: true
        onRunningChanged: {
            if (running)
                root.sampleThroughput();
            else
                root.resetThroughput(false);
        }
        onTriggered: root.sampleThroughput()
    }

    Component.onCompleted: {
        ensureMonitor();
        refresh();
    }
}
