pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property string label: ""
    property bool open: false
    property real reveal: open ? 1 : 0

    function show(text) {
        label = String(text || "");
        if (label.length <= 0) return;
        open = true;
        hideTimer.restart();
    }

    screen: panelWindow ? panelWindow.screen : Quickshell.screens[0]
    visible: open || reveal > 0.001
    focusable: false
    color: "transparent"
    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "calypso-workspace-toast"

    Behavior on reveal {
        NumberAnimation {
            duration: root.open ? theme.motionOpen : theme.motionClose
            easing.type: root.open ? Easing.OutExpo : Easing.InCubic
        }
    }

    Timer {
        id: hideTimer

        interval: settings.workspaceToastTimeout
        repeat: false
        onTriggered: root.open = false
    }

    Rectangle {
        id: toast

        width: toastText.implicitWidth + settings.effectivePillPadding * 2
        height: settings.controlHeight
        x: (parent.width - width) / 2
        y: settings.barPosition === "bottom"
           ? parent.height - height - settings.screenMargin - settings.barHeight - settings.effectiveSpacingM - (1 - root.reveal) * settings.effectiveSpacingM
           : settings.screenMargin + settings.barHeight + settings.effectiveSpacingM + (1 - root.reveal) * settings.effectiveSpacingM
        radius: settings.effectivePillRadius
        color: theme.alpha(theme.surfaceContainerHigh, settings.barOpacity)
        border.color: theme.outlineSubtle
        border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
        opacity: root.reveal
        scale: 0.96 + root.reveal * 0.04
        antialiasing: true

        Text {
            id: toastText

            anchors.centerIn: parent
            text: root.label
            color: theme.text
            font.family: settings.fontFamilySans
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.DemiBold
        }
    }
}
