import QtQuick

Pill {
    id: root

    property bool settingsOpen: false
    property bool notificationOpen: false
    property int notificationCount: 0

    signal requested(var anchorItem)
    signal notificationsRequested(var anchorItem)

    icon: ""
    active: settingsOpen || notificationOpen
    clickable: true
    minimumWidth: Math.max(settings.moduleHeight, settings.effectiveIconSize + settings.effectivePillPadding * 2)
    onClicked: requested(root)
    onRightClicked: notificationsRequested(root)
    tooltipText: root.notificationCount > 0 ? "Settings / " + root.notificationCount + " notifications" : "Settings"

    Rectangle {
        id: badge

        visible: root.notificationCount > 0 || opacity > 0
        width: root.notificationCount > 9
               ? Math.max(settings.effectiveSpacingM, badgeText.implicitWidth + settings.effectiveSpacingXS)
               : settings.effectiveSpacingM
        height: settings.effectiveSpacingM
        radius: height / 2
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -settings.effectiveBorderWidth
        anchors.rightMargin: -settings.effectiveBorderWidth
        color: theme.urgent
        border.color: theme.alpha(theme.surface, 0.7)
        border.width: settings.effectiveBorderWidth
        opacity: root.notificationCount > 0 ? 1 : 0
        scale: root.notificationCount > 0 ? 1 : 0.7
        antialiasing: true

        Behavior on opacity {
            NumberAnimation { duration: settings.motionNormal; easing.type: root.notificationCount > 0 ? Easing.OutCubic : Easing.InCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic }
        }

        Text {
            id: badgeText

            anchors.centerIn: parent
            visible: root.notificationCount > 1
            text: root.notificationCount > 99 ? "99+" : String(root.notificationCount)
            color: theme.surface
            font.family: settings.fontFamilyMono
            font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.65))
            font.weight: Font.DemiBold
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.notificationCount > 0
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: function(mouse) {
                root.notificationsRequested(root);
                mouse.accepted = true;
            }
        }
    }
}
