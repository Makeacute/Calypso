pragma ComponentBehavior: Bound

import QtQuick

Rectangle {
    id: root

    property var theme
    property var settings
    property string surfaceStyle: settings ? settings.surfaceStyle : "translucent"
    property color surfaceColor: theme ? theme.surface : "transparent"
    property color outlineColor: theme ? theme.outlineSubtle : "transparent"
    property int outlineWidth: 1
    property int surfaceRadius: settings ? settings.effectiveGroupRadius : 12
    property bool animateColors: true

    function effectiveSurfaceColor() {
        if (!theme) return "transparent";

        if (surfaceStyle === "solid") return theme.surfaceStrong;
        if (surfaceStyle === "outlined") return theme.alpha(surfaceColor, 0.58);
        if (surfaceStyle === "frosted") return theme.alpha(theme.surfacePanel, settings ? settings.panelOpacity / 100 : 0.94);
        return surfaceColor;
    }

    function effectiveOutlineColor() {
        if (!theme) return "transparent";

        if (surfaceStyle === "solid") return theme.alpha(outlineColor, 0.22);
        if (surfaceStyle === "outlined") return theme.outlineActive;
        if (surfaceStyle === "frosted") return theme.alpha(theme.border, 0.34);
        return outlineColor;
    }

    function effectiveOutlineWidth() {
        if (surfaceStyle === "outlined") return Math.max(outlineWidth, 1);
        return outlineWidth;
    }

    radius: surfaceRadius
    color: effectiveSurfaceColor()
    border.color: effectiveOutlineColor()
    border.width: effectiveOutlineWidth()
    antialiasing: true

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Math.max(1, root.radius * 0.45)
        anchors.rightMargin: Math.max(1, root.radius * 0.45)
        height: root.surfaceStyle === "frosted" ? Math.max(1, root.border.width) : 0
        radius: height / 2
        color: root.theme ? root.theme.alpha(root.theme.text, 0.10) : "transparent"
        visible: height > 0
        antialiasing: true
    }

    Behavior on color {
        enabled: root.animateColors
        ColorAnimation { duration: root.settings ? root.settings.motionNormal : 0 }
    }

    Behavior on border.color {
        enabled: root.animateColors
        ColorAnimation { duration: root.settings ? root.settings.motionNormal : 0 }
    }
}
