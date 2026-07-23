pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool performanceMode: false
    property int consumerCount: 0
    property int sampleIntervalMs: 5000
    property int historyLimit: 60

    property bool _sampling: false
    property bool _cpuDone: false
    property bool _memoryDone: false
    property bool _cpuAvailable: false
    property bool _memoryAvailable: false
    property string _lastError: ""
    property real _previousCpuTotal: 0
    property real _previousCpuIdle: 0
    property real _cpuUsage: 0
    property real _memoryUsedPercent: 0
    property real _memoryTotalBytes: 0
    property real _memoryAvailableBytes: 0
    property real _memoryUsedBytes: 0
    property var _cpuHistory: []
    property var _memoryHistory: []
    property double _lastSampleTimestamp: 0

    readonly property bool active: consumerCount > 0 && !performanceMode && sampleIntervalMs > 0
    readonly property bool sampling: _sampling
    readonly property bool available: _cpuAvailable && _memoryAvailable
    readonly property bool connected: available
    readonly property bool reconnecting: active && !available
    readonly property string healthStatus: performanceMode ? "suspended"
                                                       : !active ? "idle"
                                                                 : sampling ? "sampling"
                                                                            : available ? "ready"
                                                                                        : "unavailable"
    readonly property string lastError: _lastError

    readonly property real cpuUsage: _cpuUsage
    readonly property real cpuUsageNormalized: _cpuUsage / 100
    readonly property var cpuHistory: _cpuHistory
    readonly property real memoryUsedPercent: _memoryUsedPercent
    readonly property real memoryUsedNormalized: _memoryUsedPercent / 100
    readonly property real memoryTotalBytes: _memoryTotalBytes
    readonly property real memoryAvailableBytes: _memoryAvailableBytes
    readonly property real memoryUsedBytes: _memoryUsedBytes
    readonly property var memoryHistory: _memoryHistory
    readonly property double lastSampleTimestamp: _lastSampleTimestamp

    signal sampled(real cpuUsage, real memoryUsedPercent)

    function addConsumer() {
        consumerCount += 1;
    }

    function removeConsumer() {
        consumerCount = Math.max(0, consumerCount - 1);
    }

    function appendHistory(history, value) {
        const next = Array.from(history || []);
        next.push(Math.max(0, Math.min(1, value)));
        const limit = Math.max(1, historyLimit);
        while (next.length > limit)
            next.shift();
        return next;
    }

    function sampleNow() {
        if (_sampling)
            return false;

        _sampling = true;
        _cpuDone = false;
        _memoryDone = false;
        _lastError = "";
        if (cpuStatFile.path.length === 0)
            cpuStatFile.path = "/proc/stat";
        else
            cpuStatFile.reload();
        if (memoryInfoFile.path.length === 0)
            memoryInfoFile.path = "/proc/meminfo";
        else
            memoryInfoFile.reload();
        return true;
    }

    function parseCpu(text) {
        const firstLine = String(text || "").split("\n")[0].trim();
        const fields = firstLine.split(/\s+/).slice(1).map(Number);
        if (fields.length < 5 || fields.some(function(value) {
            return !Number.isFinite(value);
        })) {
            _cpuAvailable = false;
            _lastError = "Invalid /proc/stat data";
            return;
        }

        let total = 0;
        for (let i = 0; i < fields.length; i++)
            total += fields[i];
        const idle = fields[3] + (fields[4] || 0);

        if (_previousCpuTotal > 0) {
            const totalDelta = total - _previousCpuTotal;
            const idleDelta = idle - _previousCpuIdle;
            if (totalDelta > 0) {
                _cpuUsage = Math.max(0, Math.min(100, (1 - idleDelta / totalDelta) * 100));
                _cpuHistory = appendHistory(_cpuHistory, _cpuUsage / 100);
            }
        }

        _previousCpuTotal = total;
        _previousCpuIdle = idle;
        _cpuAvailable = true;
    }

    function parseMemory(text) {
        const lines = String(text || "").split("\n");
        let totalKiB = 0;
        let availableKiB = 0;

        for (let i = 0; i < lines.length; i++) {
            const fields = lines[i].trim().split(/\s+/);
            if (fields[0] === "MemTotal:")
                totalKiB = Number(fields[1]) || 0;
            else if (fields[0] === "MemAvailable:")
                availableKiB = Number(fields[1]) || 0;
        }

        if (totalKiB <= 0 || availableKiB < 0) {
            _memoryAvailable = false;
            _lastError = "Invalid /proc/meminfo data";
            return;
        }

        _memoryTotalBytes = totalKiB * 1024;
        _memoryAvailableBytes = availableKiB * 1024;
        _memoryUsedBytes = Math.max(0, _memoryTotalBytes - _memoryAvailableBytes);
        _memoryUsedPercent = Math.max(0, Math.min(100, _memoryUsedBytes / _memoryTotalBytes * 100));
        _memoryHistory = appendHistory(_memoryHistory, _memoryUsedPercent / 100);
        _memoryAvailable = true;
    }

    function finishPart(part) {
        if (part === "cpu")
            _cpuDone = true;
        else
            _memoryDone = true;

        if (!_cpuDone || !_memoryDone)
            return;

        _sampling = false;
        _lastSampleTimestamp = Date.now();
        sampled(_cpuUsage, _memoryUsedPercent);
    }

    onActiveChanged: {
        if (active)
            sampleNow();
    }

    FileView {
        id: cpuStatFile

        path: ""
        watchChanges: false
        blockLoading: true
        printErrors: false
        onLoaded: {
            root.parseCpu(text());
            root.finishPart("cpu");
        }
        onLoadFailed: function(error) {
            root._cpuAvailable = false;
            root._lastError = "Failed to read /proc/stat: " + FileViewError.toString(error);
            root.finishPart("cpu");
        }
    }

    FileView {
        id: memoryInfoFile

        path: ""
        watchChanges: false
        blockLoading: true
        printErrors: false
        onLoaded: {
            root.parseMemory(text());
            root.finishPart("memory");
        }
        onLoadFailed: function(error) {
            root._memoryAvailable = false;
            root._lastError = "Failed to read /proc/meminfo: " + FileViewError.toString(error);
            root.finishPart("memory");
        }
    }

    Timer {
        interval: root.sampleIntervalMs
        running: root.active
        repeat: true
        onTriggered: root.sampleNow()
    }

    Component.onCompleted: {
        if (active)
            Qt.callLater(sampleNow);
    }
}
