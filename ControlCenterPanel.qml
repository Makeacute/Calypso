import Quickshell
import QtQuick
import "widgets"

PopupWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property var anchorItem: null
    property int panelWidth: settings ? Math.max(320, settings.settingsPanelWidth) : 380
    property bool panelOpen: false
    property bool panelClosing: false

    function clampedX(value) {
        const maxX = panelWindow ? Math.max(0, panelWindow.width - panelWidth) : 0;
        return Math.max(0, Math.min(maxX, value));
    }

    function anchoredX() {
        if (anchorItem && typeof anchorItem.mapToItem === "function") {
            const point = anchorItem.mapToItem(null, 0, 0);
            return clampedX(point.x + anchorItem.width / 2 - panelWidth / 2);
        }

        return panelWindow ? clampedX(panelWindow.width - panelWidth) : 0;
    }

    function toggle(anchor) {
        if (panelOpen) close();
        else open(anchor);
    }

    function open(anchor) {
        closeTimer.stop();
        anchorItem = anchor || null;
        panelClosing = false;
        panelOpen = true;
    }

    function close() {
        if (!panelOpen && !panelClosing) return;

        panelClosing = true;
        panelOpen = false;
        closeTimer.restart();
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -controlsFrame.implicitHeight - settings.settingsPanelGap : panelWindow.height + settings.settingsPanelGap) : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: controlsFrame.implicitHeight
    visible: panelOpen || panelClosing
    grabFocus: panelOpen
    color: "transparent"

    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: root.panelOpen
        context: Qt.WindowShortcut
        onActivated: root.close()
    }

    Timer {
        id: closeTimer

        interval: root.settings ? Math.max(1, root.settings.motionClose) : 1
        repeat: false
        onTriggered: root.panelClosing = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.panelOpen
        onPressed: function(mouse) {
            root.close();
            mouse.accepted = true;
        }
        onWheel: function(wheel) {
            root.close();
            wheel.accepted = true;
        }
    }

    Surface {
        id: controlsFrame

        x: root.anchoredX()
        width: root.panelWidth
        y: root.panelOpen ? 0 : -Math.max(settings.effectiveContentSpacing * 2, settings.effectiveGroupPadding * 2)
        implicitHeight: controlsColumn.implicitHeight + settings.panelPadding * 2
        height: implicitHeight
        theme: root.theme
        settings: root.settings
        surfaceColor: theme.alpha(theme.surfaceContainerHigh, settings.panelOpacity / 100)
        outlineColor: theme.outlineSubtle
        outlineWidth: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
        surfaceRadius: settings.panelRadius
        clip: true
        opacity: root.panelOpen ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: root.panelOpen ? settings.motionOpen : settings.motionClose
                easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.panelOpen ? settings.motionOpen : settings.motionClose
                easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: function(mouse) { mouse.accepted = true; }
            onWheel: function(wheel) { wheel.accepted = true; }
        }

        Column {
            id: controlsColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: settings.panelPadding
            spacing: settings.panelPadding

            Item {
                width: parent.width
                height: settings.controlHeight

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Quick controls"
                    color: theme.text
                    font.family: settings.fontFamily
                    font.pixelSize: Math.round(settings.effectiveFontSize * 1.18)
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰒓"
                    color: theme.accent
                    font.family: settings.fontFamily
                    font.pixelSize: settings.effectiveIconSize
                }
            }

            Loader {
                active: root.panelOpen
                width: parent.width
                sourceComponent: controlsContent
            }
        }
    }

    Component {
        id: controlsContent

        Flow {
            width: controlsColumn.width
            spacing: settings.effectiveContentSpacing

            Audio {
                theme: root.theme
                settings: root.settings
            }

            Brightness {
                theme: root.theme
                settings: root.settings
            }

            PowerProfile {
                theme: root.theme
                settings: root.settings
            }

            Media {
                theme: root.theme
                settings: root.settings
            }

            Caffeine {
                theme: root.theme
                settings: root.settings
                panelWindow: root.panelWindow
            }
        }
    }
}
