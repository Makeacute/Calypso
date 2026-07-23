import QtQuick

Column {
    id: root

    property var theme
    property var settings
    property string title: ""
    property string subtitle: ""

    spacing: theme.spacingXS

    Text {
        width: root.width
        text: root.title
        color: theme.text
        wrapMode: Text.Wrap
        font.family: settings.fontFamilySans
        font.pixelSize: theme.settingsPageTitleFontSize
        font.weight: Font.DemiBold
    }

    Text {
        width: root.width
        text: root.subtitle
        visible: text.length > 0
        color: theme.textMuted
        wrapMode: Text.Wrap
        font.family: settings.fontFamilySans
        font.pixelSize: theme.settingsBodyFontSize
    }
}
