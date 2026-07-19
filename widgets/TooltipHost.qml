pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

PopupWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property var anchorItem: null
    property string tooltipText: ""
    property bool open: false

    function clampedX(value) {
        const maxX = panelWindow ? Math.max(0, panelWindow.width - tooltipSurface.width) : 0;
        return Math.max(0, Math.min(maxX, value));
    }

    function anchoredX() {
        if (anchorItem && typeof anchorItem.mapToItem === "function") {
            const point = anchorItem.mapToItem(null, 0, 0);
            return clampedX(point.x + anchorItem.width / 2 - tooltipSurface.width / 2);
        }
        return panelWindow ? clampedX(panelWindow.width - tooltipSurface.width) : 0;
    }

    function show(text, anchor) {
        const next = String(text || "").trim();
        if (next.length <= 0) return;
        tooltipText = next;
        anchorItem = anchor || null;
        open = true;
    }

    function hide(text) {
        if (text !== undefined && String(text || "") !== tooltipText) return;
        open = false;
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -tooltipSurface.height - settings.effectiveSpacingS : panelWindow.height + settings.effectiveSpacingS) : 0
    implicitWidth: panelWindow ? panelWindow.width : tooltipSurface.width
    implicitHeight: tooltipSurface.height
    visible: open || tooltipSurface.opacity > 0
    color: "transparent"

    Rectangle {
        id: tooltipSurface

        x: root.anchoredX()
        y: root.open ? 0 : (settings.barPosition === "bottom" ? settings.effectiveSpacingXS : -settings.effectiveSpacingXS)
        width: tooltipLabel.implicitWidth + settings.effectivePillPadding * 2
        height: tooltipLabel.implicitHeight + settings.effectiveSpacingS
        radius: settings.effectivePillRadius
        color: theme.surface
        border.color: theme.outlineSubtle
        border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
        opacity: root.open ? 1 : 0
        antialiasing: true

        Behavior on opacity {
            NumberAnimation { duration: theme.motionNormal; easing.type: root.open ? Easing.OutCubic : Easing.InCubic }
        }

        Behavior on y {
            NumberAnimation { duration: theme.motionHover; easing.type: root.open ? Easing.OutCubic : Easing.InCubic }
        }

        Text {
            id: tooltipLabel

            anchors.centerIn: parent
            text: root.tooltipText
            color: theme.textMuted
            font.family: settings.fontFamilySans
            font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.86))
            font.weight: Font.Medium
        }
    }
}
