import QtQuick

Item {
    id: root

    property var theme
    property var settings
    property string label: ""
    property string description: ""
    property bool checked: false
    signal toggled(bool checked)

    implicitHeight: Math.max(theme.settingsRowMinHeight, labels.implicitHeight)
    opacity: enabled ? theme.settingsEnabledOpacity : theme.settingsDisabledOpacity

    Column {
        id: labels

        anchors.left: parent.left
        anchors.right: toggle.left
        anchors.rightMargin: theme.spacingL
        anchors.verticalCenter: parent.verticalCenter
        spacing: theme.spacingXS

        Text {
            width: parent.width
            text: root.label
            color: theme.text
            wrapMode: Text.Wrap
            font.family: settings.fontFamilySans
            font.pixelSize: theme.settingsBodyFontSize
        }

        Text {
            width: parent.width
            visible: root.description.length > 0
            text: root.description
            color: theme.textMuted
            wrapMode: Text.Wrap
            font.family: settings.fontFamilySans
            font.pixelSize: theme.settingsCaptionFontSize
        }
    }

    Rectangle {
        id: toggle

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: theme.settingsSwitchWidth
        height: theme.settingsSwitchHeight
        radius: theme.settingsSwitchRadius
        color: root.checked ? theme.accent : theme.surfaceMuted
        border.color: root.checked ? theme.accent : theme.outlineSubtle
        border.width: theme.settingsBorderWidth

        Rectangle {
            x: root.checked ? parent.width - width - theme.settingsSwitchInset : theme.settingsSwitchInset
            anchors.verticalCenter: parent.verticalCenter
            width: theme.settingsSwitchKnobSize
            height: width
            radius: theme.settingsSwitchKnobRadius
            color: theme.controlKnob
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
