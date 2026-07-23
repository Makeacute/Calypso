import QtQuick

Rectangle {
    id: root

    property var theme
    property var settings
    property string icon: ""
    property string tooltip: ""
    property bool checked: false
    signal pressed

    implicitWidth: theme.settingsIconButtonSize
    implicitHeight: theme.settingsIconButtonSize
    radius: theme.radiusM
    color: checked ? theme.surfaceActive : pointer.containsMouse ? theme.surfaceHover : theme.transparent
    border.color: checked ? theme.outlineActive : theme.transparent
    border.width: theme.settingsBorderWidth
    opacity: enabled ? theme.settingsEnabledOpacity : theme.settingsDisabledOpacity
    antialiasing: true

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.checked ? root.theme.accent : root.theme.text
        font.family: root.settings.fontFamilyIcon
        font.pixelSize: root.theme.settingsIconSize
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.pressed()
    }

    Rectangle {
        z: theme.settingsOverlayZ
        visible: pointer.containsMouse && root.tooltip.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: theme.spacingXS
        width: tooltipText.implicitWidth + theme.spacingM
        height: tooltipText.implicitHeight + theme.spacingS
        radius: theme.radiusS
        color: theme.surfaceStrong
        border.color: theme.outlineSubtle
        border.width: theme.settingsBorderWidth

        Text {
            id: tooltipText

            anchors.centerIn: parent
            text: root.tooltip
            color: theme.text
            font.family: settings.fontFamilySans
            font.pixelSize: theme.settingsCaptionFontSize
        }
    }
}
