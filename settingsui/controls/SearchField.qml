import QtQuick

Rectangle {
    id: root

    property var theme
    property var settings
    property string text: ""
    property string placeholderText: "Search settings"
    signal textRequested(string text)
    signal accepted

    implicitHeight: theme.settingsControlHeight
    radius: theme.radiusM
    color: theme.surfaceMuted
    border.color: input.activeFocus ? theme.outlineActive : theme.outlineSubtle
    border.width: theme.settingsBorderWidth

    Text {
        anchors.left: parent.left
        anchors.leftMargin: theme.spacingM
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        color: input.activeFocus ? theme.accent : theme.textMuted
        font.family: settings.fontFamilyIcon
        font.pixelSize: theme.settingsIconSize
    }

    TextInput {
        id: input

        anchors.left: parent.left
        anchors.leftMargin: theme.settingsSearchTextInset
        anchors.right: clearButton.left
        anchors.rightMargin: theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: theme.text
        selectionColor: theme.accentSoft
        selectedTextColor: theme.text
        clip: true
        font.family: settings.fontFamilySans
        font.pixelSize: theme.settingsBodyFontSize
        onTextEdited: root.textRequested(text)
        onAccepted: root.accepted()
    }

    Text {
        anchors.left: input.left
        anchors.verticalCenter: input.verticalCenter
        visible: input.text.length === 0 && !input.activeFocus
        text: root.placeholderText
        color: theme.textMuted
        font.family: settings.fontFamilySans
        font.pixelSize: theme.settingsBodyFontSize
    }

    IconButton {
        id: clearButton

        anchors.right: parent.right
        anchors.rightMargin: theme.spacingXS
        anchors.verticalCenter: parent.verticalCenter
        theme: root.theme
        settings: root.settings
        icon: ""
        tooltip: "Clear search"
        visible: root.text.length > 0
        onPressed: {
            root.textRequested("");
            input.forceActiveFocus();
        }
    }

    function focusInput() {
        input.forceActiveFocus();
        input.selectAll();
    }
}
