pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Scope {
    id: root

    property bool _available: false
    property string _lastError: ""
    property string _probeError: ""

    readonly property bool available: _available
    readonly property bool connected: _available
    readonly property bool reconnecting: availabilityProbe.running
    readonly property string healthStatus: reconnecting ? "connecting"
                                                       : available ? "ready"
                                                                   : "unavailable"
    readonly property string lastError: _lastError

    readonly property int profileValue: PowerProfiles.profile
    readonly property string profile: profileName(profileValue)
    readonly property bool hasPerformanceProfile: PowerProfiles.hasPerformanceProfile
    readonly property var availableProfiles: hasPerformanceProfile
                                                 ? ["power-saver", "balanced", "performance"]
                                                 : ["power-saver", "balanced"]
    readonly property int degradationReasonValue: PowerProfiles.degradationReason
    readonly property string degradationReason: degradationReasonName(degradationReasonValue)
    readonly property var holds: PowerProfiles.holds

    signal actionFailed(string action, string message)

    function profileName(value) {
        if (value === PowerProfile.PowerSaver)
            return "power-saver";
        if (value === PowerProfile.Performance)
            return "performance";
        return "balanced";
    }

    function profileValueForName(name) {
        const value = String(name || "");
        if (value === "power-saver")
            return PowerProfile.PowerSaver;
        if (value === "performance")
            return PowerProfile.Performance;
        if (value === "balanced")
            return PowerProfile.Balanced;
        return -1;
    }

    function degradationReasonName(value) {
        if (value === PerformanceDegradationReason.LapDetected)
            return "lap-detected";
        if (value === PerformanceDegradationReason.HighTemperature)
            return "high-operating-temperature";
        return "";
    }

    function refreshAvailability() {
        if (availabilityProbe.running)
            return;

        _probeError = "";
        availabilityProbe.running = true;
    }

    function setProfile(name) {
        const requested = profileValueForName(name);
        if (requested < 0) {
            actionFailed("setProfile", "Unknown power profile: " + String(name || ""));
            return false;
        }
        if (!available) {
            actionFailed("setProfile", "power-profiles-daemon is unavailable");
            return false;
        }
        if (requested === PowerProfile.Performance && !hasPerformanceProfile) {
            actionFailed("setProfile", "The performance profile is unavailable");
            return false;
        }

        try {
            PowerProfiles.profile = requested;
            return true;
        } catch (error) {
            _lastError = String(error);
            actionFailed("setProfile", _lastError);
            return false;
        }
    }

    function cycleProfile() {
        const profiles = Array.from(availableProfiles || []);
        const index = profiles.indexOf(profile);
        const nextIndex = index >= 0 ? (index + 1) % profiles.length : 0;
        return profiles.length > 0 && setProfile(profiles[nextIndex]);
    }

    Process {
        id: availabilityProbe

        command: [
            "busctl",
            "--system",
            "get-property",
            "org.freedesktop.UPower.PowerProfiles",
            "/org/freedesktop/UPower/PowerProfiles",
            "org.freedesktop.UPower.PowerProfiles",
            "ActiveProfile"
        ]
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: root._probeError = text.trim()
        }
        onExited: function(exitCode) {
            root._available = exitCode === 0;
            root._lastError = root._available ? "" : (root._probeError || "power-profiles-daemon is unavailable");
        }
    }

    Connections {
        target: PowerProfiles

        function onProfileChanged() {
            root.refreshAvailability();
        }
    }

    Component.onCompleted: refreshAvailability()
}
