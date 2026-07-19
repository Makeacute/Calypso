import QtQuick
import Quickshell.Wayland._IdleInhibitor

Pill {
    id: root

    property var panelWindow: null
    property bool inhibited: false

    icon: inhibited ? "󰅶" : "󰾪"
    text: inhibited ? "on" : "off"
    detailText: settings.widgetStyle === "expanded" ? "idle inhibit" : ""
    active: inhibited
    muted: !inhibited
    clickable: true
    iconFadeOnChange: true
    textPulseOnChange: true
    minimumWidth: 0
    maximumTextWidth: 34
    onClicked: function(mouse) {
        inhibited = !inhibited;
    }

    IdleInhibitor {
        enabled: root.inhibited && root.panelWindow !== null
        window: root.panelWindow
    }
}
