import QtQuick

Pill {
    id: root

    property string panelId: "launcher"
    property var coordinator: null
    property var panel: null
    readonly property var triggerProfile: profileFor(panelId)
    readonly property bool panelOpen: coordinator && panelId.length > 0
                                      ? coordinator.isActive(panelId)
                                      : panel && panel.panelOpen

    signal triggerRequested(string panelId, var anchorItem)

    function profileFor(id) {
        const profiles = {
            "launcher": {
                "icon": "󰀻",
                "text": "Apps",
                "detail": "Launcher",
                "tooltip": "App launcher"
            },
            "notepad": {
                "icon": "󰎞",
                "text": "Note",
                "detail": "Scratchpad",
                "tooltip": "Notepad"
            },
            "clipboard": {
                "icon": "󰅌",
                "text": "Clip",
                "detail": "History",
                "tooltip": "Clipboard history"
            },
            "process": {
                "icon": "󰒋",
                "text": "Proc",
                "detail": "Tasks",
                "tooltip": "Processes"
            },
            "processes": {
                "icon": "󰒋",
                "text": "Proc",
                "detail": "Tasks",
                "tooltip": "Processes"
            },
            "settings": {
                "icon": "",
                "text": "Settings",
                "detail": "Preferences",
                "tooltip": "Settings"
            }
        };
        return profiles[String(id || "")] || {
            "icon": "",
            "text": String(id || ""),
            "detail": "",
            "tooltip": String(id || "")
        };
    }

    function trigger() {
        if (coordinator && panelId.length > 0)
            return coordinator.toggle(panelId, root);
        if (panel && typeof panel.toggle === "function") {
            panel.toggle(root);
            return true;
        }
        triggerRequested(panelId, root);
        return true;
    }

    icon: triggerProfile.icon
    text: triggerProfile.text
    detailText: triggerProfile.detail
    tooltipText: triggerProfile.tooltip
    active: panelOpen
    clickable: true
    minimumWidth: Math.max(settings.moduleHeight,
                           settings.effectiveIconSize + settings.effectivePillPadding * 2)
    onClicked: trigger()
}
