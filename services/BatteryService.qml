pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Scope {
    id: root

    property int fallbackPollMs: 30000
    property var _fallbackBatteries: []
    property real _fallbackPercent: 0
    property string _fallbackState: "Unknown"
    property string _lastError: ""
    property string _scanError: ""

    readonly property var upowerDevices: UPower.devices.values
    readonly property var fallbackBatteries: _fallbackBatteries
    readonly property var nativeDevice: resolveNativeDevice()
    readonly property bool nativeAvailable: nativeDevice !== null
    readonly property bool fallbackAvailable: fallbackBatteries.length > 0
    readonly property bool available: nativeAvailable || fallbackAvailable
    readonly property bool connected: available
    readonly property bool reconnecting: !available && !nativeAvailable && fallbackPollMs > 0
    readonly property string healthStatus: nativeAvailable ? "ready"
                                                       : fallbackScan.running ? "connecting"
                                                                              : fallbackAvailable ? "fallback"
                                                                                                  : "unavailable"
    readonly property string lastError: _lastError
    readonly property string source: nativeAvailable ? "upower"
                                                     : fallbackAvailable ? "sysfs"
                                                                         : "none"

    readonly property real percent: nativeAvailable
                                        ? normalizePercent(nativeDevice.percentage)
                                        : _fallbackPercent
    readonly property int state: nativeAvailable ? nativeDevice.state : UPowerDeviceState.Unknown
    readonly property string stateName: nativeAvailable
                                            ? UPowerDeviceState.toString(nativeDevice.state)
                                            : _fallbackState
    readonly property bool charging: nativeAvailable
                                         ? state === UPowerDeviceState.Charging
                                           || state === UPowerDeviceState.FullyCharged
                                           || state === UPowerDeviceState.PendingCharge
                                         : stateName === "Charging" || stateName === "Full"
    readonly property bool activelyCharging: nativeAvailable
                                                 ? state === UPowerDeviceState.Charging
                                                 : stateName === "Charging"
    readonly property bool onBattery: nativeAvailable ? UPower.onBattery : stateName === "Discharging"
    readonly property real timeToEmpty: nativeAvailable ? Number(nativeDevice.timeToEmpty) || 0 : 0
    readonly property real timeToFull: nativeAvailable ? Number(nativeDevice.timeToFull) || 0 : 0
    readonly property real energy: nativeAvailable ? Number(nativeDevice.energy) || 0 : 0
    readonly property real energyCapacity: nativeAvailable ? Number(nativeDevice.energyCapacity) || 0 : 0
    readonly property real changeRate: nativeAvailable ? Number(nativeDevice.changeRate) || 0 : 0
    readonly property bool healthSupported: nativeAvailable && nativeDevice.healthSupported
    readonly property real healthPercent: healthSupported
                                               ? normalizePercent(nativeDevice.healthPercentage)
                                               : 0
    readonly property string model: nativeAvailable ? String(nativeDevice.model || "") : ""
    readonly property int batteryCount: nativeAvailable ? nativeBatteryCount() : fallbackBatteries.length

    signal refreshed()

    function normalizePercent(value) {
        const number = Number(value) || 0;
        return Math.max(0, Math.min(100, number <= 1 ? number * 100 : number));
    }

    function resolveNativeDevice() {
        const display = UPower.displayDevice;
        if (display && display.ready && display.isPresent)
            return display;

        const devices = Array.from(upowerDevices || []);
        for (let i = 0; i < devices.length; i++) {
            const device = devices[i];
            if (device.ready && device.isPresent && device.isLaptopBattery)
                return device;
        }
        for (let i = 0; i < devices.length; i++) {
            const device = devices[i];
            if (device.ready && device.isPresent && device.type === UPowerDeviceType.Battery
                    && device.powerSupply)
                return device;
        }
        return null;
    }

    function nativeBatteryCount() {
        const devices = Array.from(upowerDevices || []);
        let count = 0;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].ready && devices[i].isPresent
                    && (devices[i].isLaptopBattery
                        || (devices[i].type === UPowerDeviceType.Battery && devices[i].powerSupply)))
                count += 1;
        }
        return Math.max(1, count);
    }

    function parseFallback(text) {
        const lines = String(text || "").trim().split("\n");
        const batteries = [];
        let weightedCurrent = 0;
        let weightedFull = 0;
        let percentTotal = 0;
        let chargingCount = 0;
        let dischargingCount = 0;
        let fullCount = 0;

        for (let i = 0; i < lines.length; i++) {
            if (lines[i].trim().length === 0)
                continue;

            const fields = lines[i].split("\t");
            if (fields.length < 7)
                continue;

            const entry = {
                "path": fields[0],
                "name": fields[0].split("/").pop(),
                "percent": normalizePercent(fields[1]),
                "state": fields[2] || "Unknown",
                "current": Number(fields[3]) || 0,
                "full": Number(fields[4]) || 0,
                "present": fields[5] !== "0",
                "model": fields[6] || ""
            };
            if (!entry.present)
                continue;

            batteries.push(entry);
            percentTotal += entry.percent;
            if (entry.full > 0 && entry.current >= 0) {
                weightedCurrent += entry.current;
                weightedFull += entry.full;
            }
            if (entry.state === "Charging")
                chargingCount += 1;
            else if (entry.state === "Discharging")
                dischargingCount += 1;
            else if (entry.state === "Full")
                fullCount += 1;
        }

        _fallbackBatteries = batteries;
        if (batteries.length === 0) {
            _fallbackPercent = 0;
            _fallbackState = "Unknown";
            return;
        }

        _fallbackPercent = weightedFull > 0
                ? normalizePercent(weightedCurrent / weightedFull)
                : percentTotal / batteries.length;
        _fallbackState = chargingCount > 0 ? "Charging"
                                          : dischargingCount > 0 ? "Discharging"
                                                                : fullCount === batteries.length ? "Full"
                                                                                                : "Unknown";
    }

    function refresh() {
        if (!fallbackScan.running) {
            _scanError = "";
            fallbackScan.running = true;
        }
    }

    Process {
        id: fallbackScan

        command: [
            "sh",
            "-c",
            "for d in /sys/class/power_supply/*; do [ -d \"$d\" ] || continue; [ \"$(cat \"$d/type\" 2>/dev/null)\" = Battery ] || continue; present=$(cat \"$d/present\" 2>/dev/null || printf 1); capacity=$(cat \"$d/capacity\" 2>/dev/null || printf 0); state=$(cat \"$d/status\" 2>/dev/null || printf Unknown); current=$(cat \"$d/energy_now\" 2>/dev/null || cat \"$d/charge_now\" 2>/dev/null || printf 0); full=$(cat \"$d/energy_full\" 2>/dev/null || cat \"$d/charge_full\" 2>/dev/null || printf 0); model=$(cat \"$d/model_name\" 2>/dev/null || true); printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$d\" \"$capacity\" \"$state\" \"$current\" \"$full\" \"$present\" \"$model\"; done"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.parseFallback(text)
        }
        stderr: StdioCollector {
            onStreamFinished: root._scanError = text.trim()
        }
        onExited: function(exitCode) {
            root._lastError = exitCode === 0 ? "" : (root._scanError || "Failed to scan sysfs batteries");
            root.refreshed();
        }
    }

    Timer {
        interval: root.fallbackPollMs
        running: !root.nativeAvailable && root.fallbackPollMs > 0
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
