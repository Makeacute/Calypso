import QtQuick

Rectangle {
    id: root

    required property var theme
    required property var settings
    default property alias contentData: contentHost.data
    readonly property alias contentItem: contentHost
    property real contentPadding: theme.spacingM
    property color surfaceColor: theme.surfacePanel
    property color outlineColor: theme.outlineSubtle
    property real outlineWidth: settings.effectiveBorderWidth
    property real surfaceRadius: theme.radiusL

    implicitWidth: contentHost.implicitWidth + contentPadding * 2
    implicitHeight: contentHost.implicitHeight + contentPadding * 2
    radius: surfaceRadius
    color: surfaceColor
    border.color: outlineColor
    border.width: outlineWidth
    clip: true
    antialiasing: true
    focus: true

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: function(mouse) { mouse.accepted = true; }
        onWheel: function(wheel) { wheel.accepted = true; }
    }

    Item {
        id: contentHost

        anchors.fill: parent
        anchors.margins: root.contentPadding
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
