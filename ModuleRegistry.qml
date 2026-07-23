pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: root

    readonly property var entries: [
        { "id": "settings", "label": "Settings", "icon": "", "category": "Shell", "aliases": [], "defaultSection": "left", "defaultVisible": true, "configurable": false, "reusable": false, "cost": "low", "capabilities": [], "loadPhase": 3, "source": "widgets/SettingsButton.qml" },
        { "id": "workspaces", "label": "Workspaces", "icon": "󰧨", "category": "Compositor", "aliases": [], "defaultSection": "center", "defaultVisible": true, "configurable": true, "reusable": false, "cost": "event", "capabilities": ["workspaces", "focusWorkspace"], "loadPhase": 1, "source": "widgets/Workspace.qml" },
        { "id": "focusedWindow", "label": "Workspace apps", "icon": "󰣆", "category": "Compositor", "aliases": [], "defaultSection": "center", "defaultVisible": true, "configurable": true, "reusable": false, "cost": "event", "capabilities": ["windows", "focusWindow"], "loadPhase": 1, "source": "widgets/FocusedWindow.qml" },
        { "id": "cpu", "label": "CPU", "icon": "", "category": "System", "aliases": [], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "polling", "capabilities": [], "loadPhase": 2, "source": "widgets/Cpu.qml" },
        { "id": "memory", "label": "Memory", "icon": "", "category": "System", "aliases": ["ram"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "polling", "capabilities": [], "loadPhase": 2, "source": "widgets/Memory.qml" },
        { "id": "network", "label": "Network", "icon": "󰤨", "category": "System", "aliases": ["net"], "defaultSection": "right", "defaultVisible": true, "configurable": true, "reusable": false, "cost": "polling", "capabilities": [], "loadPhase": 2, "source": "widgets/Network.qml" },
        { "id": "bluetooth", "label": "Bluetooth", "icon": "󰂯", "category": "System", "aliases": ["bt"], "defaultSection": "right", "defaultVisible": true, "configurable": true, "reusable": false, "cost": "event", "capabilities": [], "loadPhase": 2, "source": "widgets/BluetoothStatus.qml" },
        { "id": "audio", "label": "Audio", "icon": "󰕾", "category": "Controls", "aliases": ["volume"], "defaultSection": "right", "defaultVisible": true, "configurable": true, "cost": "event", "capabilities": [], "loadPhase": 2, "source": "widgets/Audio.qml" },
        { "id": "brightness", "label": "Brightness", "icon": "󰃠", "category": "Controls", "aliases": ["backlight"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "event", "capabilities": [], "loadPhase": 2, "source": "widgets/Brightness.qml" },
        { "id": "powerProfile", "label": "Power profile", "icon": "󰓅", "category": "Controls", "aliases": ["power"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "cost": "event", "capabilities": [], "loadPhase": 2, "source": "widgets/PowerProfile.qml" },
        { "id": "media", "label": "Media", "icon": "󰝚", "category": "Media", "aliases": ["mpris", "player"], "defaultSection": "right", "defaultVisible": true, "configurable": true, "cost": "event", "capabilities": [], "loadPhase": 2, "source": "widgets/Media.qml" },
        { "id": "battery", "label": "Battery", "icon": "󰁹", "category": "System", "aliases": ["bat"], "defaultSection": "right", "defaultVisible": true, "configurable": true, "cost": "event", "capabilities": [], "loadPhase": 2, "source": "widgets/Battery.qml" },
        { "id": "caffeine", "label": "Caffeine", "icon": "󰅶", "category": "Controls", "aliases": ["idleInhibitor", "idle"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "reusable": false, "cost": "local", "capabilities": [], "loadPhase": 2, "source": "widgets/Caffeine.qml" },
        { "id": "clock", "label": "Clock", "icon": "󰥔", "category": "Shell", "aliases": ["time"], "defaultSection": "center", "defaultVisible": true, "configurable": true, "cost": "timer", "capabilities": [], "loadPhase": 1, "source": "widgets/Clock.qml" },
        { "id": "dashboard", "label": "Dashboard", "icon": "󰒓", "category": "Shell", "aliases": ["controls", "controlCenter", "quickControls"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "reusable": false, "cost": "lazy", "capabilities": [], "loadPhase": 3, "source": "widgets/ControlCenterButton.qml" },
        { "id": "launcher", "label": "Launcher", "icon": "󰀻", "category": "Shell", "aliases": ["apps", "appLauncher"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "reusable": false, "cost": "lazy", "capabilities": ["desktopEntries", "fuzzySearch"], "loadPhase": 3, "source": "widgets/Launcher.qml" },
        { "id": "notepad", "label": "Notepad", "icon": "󰎞", "category": "Shell", "aliases": ["scratchpad", "notes"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "reusable": false, "cost": "lazy", "capabilities": ["autosave"], "loadPhase": 3, "source": "widgets/Notepad.qml" },
        { "id": "clipboard", "label": "Clipboard", "icon": "󰅌", "category": "Shell", "aliases": ["cliphist", "clip"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "reusable": false, "cost": "open polling", "capabilities": ["history", "images"], "loadPhase": 3, "source": "widgets/Clipboard.qml" },
        { "id": "processes", "label": "Processes", "icon": "󰒋", "category": "System", "aliases": ["processList", "tasks"], "defaultSection": "right", "defaultVisible": false, "configurable": true, "reusable": false, "cost": "open polling", "capabilities": ["sort", "temperature"], "loadPhase": 3, "source": "widgets/Processes.qml" },
        { "id": "tray", "label": "Tray", "icon": "󰒲", "category": "System", "aliases": [], "defaultSection": "right", "defaultVisible": false, "configurable": true, "reusable": false, "cost": "event", "capabilities": [], "loadPhase": 2, "source": "widgets/Tray.qml" }
    ]

    readonly property var availableTypes: entries.map(entry => entry.id)

    function entry(moduleName) {
        const name = String(moduleName || "");
        for (let i = 0; i < entries.length; i++) {
            const candidate = entries[i];
            if (candidate.id === name || Array.from(candidate.aliases || []).indexOf(name) >= 0)
                return candidate;
        }

        const separator = name.lastIndexOf("-");
        if (separator > 0)
            return entry(name.slice(0, separator));

        return null;
    }

    function canonicalId(moduleName) {
        const candidate = entry(moduleName);
        return candidate ? candidate.id : String(moduleName || "");
    }

    function loadPhase(moduleName) {
        const candidate = entry(moduleName);
        return candidate ? Number(candidate.loadPhase || 2) : 2;
    }

    function sourceUrl(moduleName) {
        const candidate = entry(moduleName);
        if (!candidate || !candidate.source)
            return "";
        return Qt.resolvedUrl(String(candidate.source));
    }

    function injectionNames(moduleName) {
        const type = canonicalId(moduleName);
        const names = ["theme", "settings"];
        if (type === "workspaces" || type === "focusedWindow")
            names.push("compositor");
        if (type === "cpu" || type === "memory")
            names.push("systemStatsService");
        if (type === "network")
            names.push("networkService");
        if (type === "battery")
            names.push("batteryService");
        if (type === "media")
            names.push("mediaService");
        if (type === "powerProfile")
            names.push("powerProfileService");
        if (type === "caffeine" || type === "tray")
            names.push("panelWindow");
        if (type !== "workspaces" && type !== "focusedWindow" && type !== "tray")
            names.push("tooltipHost");
        if (type === "settings")
            names.push("settingsOpen", "notificationOpen", "notificationCount");
        names.push("moduleInstanceId", "moduleSettings");
        return names;
    }
}
