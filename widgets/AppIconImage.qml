import QtQuick
import Quickshell.Widgets

Item {
    id: root

    property var theme
    property var settings
    property string iconSource: ""
    property string fallbackText: ""
    readonly property bool iconReady: appIcon.status === Image.Ready

    IconImage {
        id: appIcon

        anchors.fill: parent
        implicitSize: root.settings.effectiveIconSize
        source: root.iconSource
        visible: root.iconReady
        asynchronous: true
        mipmap: true
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.iconReady
        radius: root.settings.effectiveRadiusS
        color: root.theme.surfaceMuted
        border.color: root.theme.outlineSubtle
        border.width: root.settings.effectiveBorderWidth
        antialiasing: true

        Text {
            anchors.centerIn: parent
            text: root.fallbackText
            color: root.theme.textMuted
            font.family: root.settings.fontFamilySans
            font.pixelSize: Math.max(root.settings.effectiveContentSpacing * 2,
                                     Math.round(root.settings.effectiveFontSize * 0.82))
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
