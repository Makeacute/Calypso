import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    id: root

    property var theme
    property var settings
    property string moduleInstanceId: ""
    property var moduleSettings: ({})
    property var panelWindow
    property var trayItems: SystemTray.items.values
    property int maxVisible: Math.max(1, moduleSettings.maxVisible === undefined ? settings.trayMaxVisible : Number(moduleSettings.maxVisible))
    readonly property bool compact: moduleSettings.compact === undefined ? settings.trayCompact : Boolean(moduleSettings.compact)
    readonly property int instanceIconSize: moduleSettings.iconSize === undefined ? settings.effectiveTrayIconSize : Number(moduleSettings.iconSize)
    property var visibleItems: Array.from(trayItems || []).slice(0, maxVisible)
    property var hiddenItems: Array.from(trayItems || []).slice(maxVisible)
    property bool hasItems: trayItems.length > 0
    property bool overflowOpen: false

    function popupX() {
        if (!panelWindow || !overflowButton.visible) return 0;
        const point = overflowButton.mapToItem(null, 0, 0);
        return Math.max(0, Math.min(panelWindow.width - overflowPopupSurface.width, point.x + overflowButton.width / 2 - overflowPopupSurface.width / 2));
    }

    function popupY() {
        if (!panelWindow) return 0;
        if (settings.barPosition === "bottom") return -overflowPopupSurface.height - settings.settingsPanelGap;
        return panelWindow.height + settings.settingsPanelGap;
    }

    spacing: settings.effectiveContentSpacing
    visible: hasItems || opacity > 0
    opacity: hasItems ? 1 : 0
    scale: hasItems ? 1 : 0.96

    Behavior on opacity {
        NumberAnimation { duration: settings.motionNormal; easing.type: root.hasItems ? Easing.OutCubic : Easing.InCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: settings.motionNormal; easing.type: root.hasItems ? Easing.OutCubic : Easing.InCubic }
    }

    Repeater {
        model: root.visibleItems

        TrayButton {
            theme: root.theme
            settings: root.settings
            panelWindow: root.panelWindow
            itemData: modelData
            compact: root.compact
            iconSize: root.instanceIconSize
        }
    }

    Rectangle {
        id: overflowButton

        visible: root.hiddenItems.length > 0
        width: settings.moduleHeight
        height: width
        radius: settings.effectivePillRadius
        color: overflowMouse.containsMouse || root.overflowOpen ? theme.surfaceHover : theme.transparent
        border.color: root.overflowOpen ? theme.outlineActive : theme.transparent
        border.width: settings.effectiveBorderWidth
        scale: overflowMouse.containsMouse ? 1.015 : 1
        antialiasing: true

        Behavior on color {
            ColorAnimation { duration: settings.motionNormal }
        }

        Behavior on border.color {
            ColorAnimation { duration: settings.motionNormal }
        }

        Behavior on scale {
            NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            text: "+" + root.hiddenItems.length
            color: theme.textMuted
            font.family: settings.fontFamily
            font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.85))
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: overflowMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.overflowOpen = !root.overflowOpen
        }
    }

    PopupWindow {
        id: overflowPopup

        anchor.window: root.panelWindow
        anchor.rect.x: 0
        anchor.rect.y: root.popupY()
        implicitWidth: root.panelWindow ? root.panelWindow.width : overflowPopupSurface.width
        implicitHeight: overflowPopupSurface.height
        visible: root.overflowOpen && root.hiddenItems.length > 0
        color: theme.transparent

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: function(mouse) {
                root.overflowOpen = false;
                mouse.accepted = true;
            }
        }

        Rectangle {
            id: overflowPopupSurface

            x: root.popupX()
            y: root.overflowOpen ? 0 : (settings.barPosition === "bottom" ? settings.effectiveSpacingM : -settings.effectiveSpacingM)
            width: Math.max(settings.moduleHeight + settings.effectivePillPadding * 2, overflowColumn.implicitWidth + settings.effectivePillPadding * 2)
            height: overflowColumn.implicitHeight + settings.effectivePillPadding * 2
            radius: settings.effectiveRadiusL
            color: theme.alpha(theme.surfaceContainerHigh, settings.barOpacity)
            border.color: settings.barBorderEnabled ? theme.border : theme.outlineSubtle
            border.width: settings.barBorderEnabled ? settings.barBorderThickness : settings.effectiveBorderWidth
            opacity: root.overflowOpen ? 1 : 0
            antialiasing: true

            Behavior on y {
                NumberAnimation { duration: settings.motionNormal; easing.type: root.overflowOpen ? Easing.OutCubic : Easing.InCubic }
            }

            Behavior on opacity {
                NumberAnimation { duration: settings.motionNormal; easing.type: root.overflowOpen ? Easing.OutCubic : Easing.InCubic }
            }

            Column {
                id: overflowColumn

                anchors.centerIn: parent
                spacing: settings.effectiveContentSpacing

                Repeater {
                    model: root.hiddenItems

                    TrayButton {
                        theme: root.theme
                        settings: root.settings
                        panelWindow: root.panelWindow
                        itemData: modelData
                        compact: root.compact
                        iconSize: root.instanceIconSize
                    }
                }
            }
        }
    }

    component TrayButton: Rectangle {
        id: trayItem

        property var theme
        property var settings
        property var panelWindow
        property var itemData
        property bool compact: true
        property int iconSize: settings.effectiveTrayIconSize

        width: compact ? settings.moduleHeight : Math.max(settings.moduleHeight, iconSize + settings.effectivePillPadding * 2)
        height: width
        radius: settings.effectivePillRadius
        color: hoverArea.containsMouse ? theme.surfaceHover : theme.transparent
        border.color: itemData && itemData.status === Status.NeedsAttention ? theme.urgent : theme.transparent
        border.width: settings.effectiveBorderWidth
        opacity: itemData ? 1 : 0
        antialiasing: true
        scale: hoverArea.containsMouse ? 1.015 : 1

        Behavior on opacity {
            NumberAnimation { duration: settings.motionNormal; easing.type: opacity > 0 ? Easing.OutCubic : Easing.InCubic }
        }

        Behavior on color {
            ColorAnimation { duration: settings.motionNormal }
        }

        Behavior on border.color {
            ColorAnimation { duration: settings.motionNormal }
        }

        Behavior on scale {
            NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic }
        }

        IconImage {
            anchors.centerIn: parent
            implicitSize: trayItem.iconSize
            width: trayItem.iconSize
            height: trayItem.iconSize
            source: trayItem.itemData ? trayItem.itemData.icon : ""
            asynchronous: true
        }

        MouseArea {
            id: hoverArea

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
                if (!trayItem.itemData) return;
                if (mouse.button === Qt.MiddleButton) {
                    trayItem.itemData.secondaryActivate();
                } else if (mouse.button === Qt.RightButton && trayItem.itemData.hasMenu) {
                    const point = trayItem.mapToItem(null, 0, trayItem.height);
                    trayItem.itemData.display(trayItem.panelWindow, point.x, point.y);
                } else {
                    trayItem.itemData.activate();
                }
            }
        }
    }
}
