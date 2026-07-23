import QtQuick

Rectangle {
    id: root

    property var theme
    property var settings
    property string icon: ""
    property string label: ""
    property bool selected: false
    property bool compact: false
    signal pressed

    implicitWidth: compact ? theme.settingsCompactNavWidth : theme.settingsSidebarWidth
    implicitHeight: theme.settingsNavItemHeight
    radius: theme.radiusL
    color: selected ? theme.surfaceActive : pointer.containsMouse ? theme.surfaceHover : theme.transparent
    border.color: selected ? theme.outlineActive : theme.transparent
    border.width: theme.settingsBorderWidth

    Row {
        anchors.centerIn: parent
        height: parent.height
        spacing: theme.spacingS

        Item {
            width: theme.settingsIconSize
            height: parent.height

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.selected ? theme.accent : theme.textMuted
                font.family: settings.fontFamilyIcon
                font.pixelSize: theme.settingsIconSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Text {
            visible: !root.compact
            height: parent.height
            text: root.label
            color: root.selected ? theme.text : theme.textMuted
            font.family: settings.fontFamilySans
            font.pixelSize: theme.settingsBodyFontSize
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.pressed()
    }
}
