import QtQuick

Rectangle {
    id: root

    property var theme
    property var settings
    property string text: ""
    property string tone: "neutral"
    readonly property color toneColor: tone === "good" ? theme.good : tone === "warning" ? theme.warning : tone === "error" ? theme.error : theme.textMuted

    implicitWidth: label.implicitWidth + theme.spacingM
    implicitHeight: label.implicitHeight + theme.spacingS
    radius: theme.radiusS
    color: theme.alpha(toneColor, theme.settingsBadgeFillOpacity)
    border.color: theme.alpha(toneColor, theme.settingsBadgeOutlineOpacity)
    border.width: theme.settingsBorderWidth

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.toneColor
        font.family: settings.fontFamilySans
        font.pixelSize: theme.settingsCaptionFontSize
        font.weight: Font.DemiBold
    }
}
