import QtQuick

Item {
    id: root

    property var theme
    property var settings
    property string label: ""
    property string description: ""
    property string value: ""
    property string placeholderText: ""
    signal valueRequested(string value)

    implicitHeight: Math.max(labels.implicitHeight, editor.implicitHeight)

    Column {
        id: labels

        anchors.left: parent.left
        anchors.right: editor.left
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
        id: editor

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: theme.settingsTextFieldWidth
        implicitHeight: theme.settingsControlHeight
        radius: theme.radiusM
        color: theme.surfaceMuted
        border.color: input.activeFocus ? theme.outlineActive : theme.outlineSubtle
        border.width: theme.settingsBorderWidth

        TextInput {
            id: input

            anchors.fill: parent
            anchors.leftMargin: theme.spacingM
            anchors.rightMargin: theme.spacingM
            verticalAlignment: TextInput.AlignVCenter
            text: root.value
            color: theme.text
            selectionColor: theme.accentSoft
            selectedTextColor: theme.text
            clip: true
            font.family: settings.fontFamilyMono
            font.pixelSize: theme.settingsCaptionFontSize
            onAccepted: {
                root.valueRequested(text);
                focus = false;
            }
            onActiveFocusChanged: {
                if (!activeFocus && text !== root.value)
                    root.valueRequested(text);
            }
        }

        Text {
            anchors.left: input.left
            anchors.verticalCenter: input.verticalCenter
            visible: input.text.length === 0 && !input.activeFocus
            text: root.placeholderText
            color: theme.textMuted
            font.family: settings.fontFamilyMono
            font.pixelSize: theme.settingsCaptionFontSize
        }
    }
}
