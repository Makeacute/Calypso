import QtQuick

Item {
    id: root

    property var theme
    property var settings
    property string title: ""
    property string detail: ""

    implicitHeight: heading.implicitHeight

    Column {
        id: heading

        width: parent.width
        spacing: theme.spacingXS

        Text {
            width: parent.width
            text: root.title
            color: theme.text
            font.family: settings.fontFamilySans
            font.pixelSize: theme.settingsSectionFontSize
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            visible: root.detail.length > 0
            text: root.detail
            color: theme.textMuted
            wrapMode: Text.Wrap
            font.family: settings.fontFamilySans
            font.pixelSize: theme.settingsCaptionFontSize
        }

        Rectangle {
            width: parent.width
            height: theme.settingsBorderWidth
            color: theme.outlineSubtle
        }
    }
}
