import QtQuick

Rectangle {
    id: root

    default property alias content: row.data

    property var theme
    property var settings

    width: implicitWidth
    height: implicitHeight
    implicitWidth: row.implicitWidth + settings.effectiveGroupPadding * 2
    implicitHeight: settings.barHeight
    radius: settings.effectiveGroupRadius
    color: theme.surface
    border.color: theme.outlineSubtle
    border.width: settings.effectiveBorderWidth
    antialiasing: true

    Behavior on color {
        ColorAnimation { duration: settings.motionNormal }
    }

    Behavior on border.color {
        ColorAnimation { duration: settings.motionNormal }
    }

    Behavior on opacity {
        NumberAnimation { duration: settings.motionNormal; easing.type: opacity > 0 ? Easing.OutCubic : Easing.InCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: settings.motionHover; easing.type: scale >= 1 ? Easing.OutCubic : Easing.InCubic }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: settings.effectiveContentSpacing
    }
}
