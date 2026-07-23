import QtQuick

Item {
    id: root

    property var theme
    property var settings
    property string label: ""
    property string description: ""
    property string value: ""
    property var options: []
    signal selected(string value)

    implicitHeight: Math.max(labels.implicitHeight, choices.implicitHeight)

    Column {
        id: labels

        anchors.left: parent.left
        anchors.right: choices.left
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

    Flow {
        id: choices

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, theme.settingsChoiceMaxWidth)
        spacing: theme.spacingXS

        Repeater {
            model: root.options

            Rectangle {
                id: optionChip

                required property var modelData

                width: optionLabel.implicitWidth + theme.spacingL
                height: theme.settingsControlHeight
                radius: theme.radiusM
                color: root.value === String(modelData.value) ? theme.surfaceActive : optionPointer.containsMouse ? theme.surfaceHover : theme.surfaceMuted
                border.color: root.value === String(modelData.value) ? theme.outlineActive : theme.outlineSubtle
                border.width: theme.settingsBorderWidth

                Text {
                    id: optionLabel

                    anchors.centerIn: parent
                    text: String(optionChip.modelData.label)
                    color: root.value === String(optionChip.modelData.value) ? theme.accent : theme.text
                    font.family: settings.fontFamilySans
                    font.pixelSize: theme.settingsCaptionFontSize
                    font.weight: root.value === String(optionChip.modelData.value) ? Font.DemiBold : Font.Normal
                }

                MouseArea {
                    id: optionPointer

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(String(optionChip.modelData.value))
                }
            }
        }
    }
}
