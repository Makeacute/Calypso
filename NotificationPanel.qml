pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import QtQuick
import "widgets"

PopupWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property var anchorItem: null
    property var notifications: []
    property bool panelOpen: false
    property bool panelClosing: false
    property var expandedGroups: ({})
    readonly property int panelWidth: settings ? Math.round(Math.min(panelWindow ? panelWindow.width : settings.effectiveSpacingXL * 20, Math.max(settings.effectiveSpacingXL * 15, settings.notificationsPanelWidth))) : 420
    readonly property var groups: groupedNotifications()

    function notificationList() {
        const source = Array.from(notifications || []);
        const limit = Math.max(1, Number(settings ? settings.notificationsMaxVisible : 0) || 24);
        return source.slice(0, limit);
    }

    function appLabel(notification) {
        const app = String(notification && notification.appName ? notification.appName : "");
        if (app.length > 0) return app;
        const desktop = String(notification && notification.desktopEntry ? notification.desktopEntry : "");
        return desktop.length > 0 ? desktop.replace(/\.desktop$/i, "") : "Notifications";
    }

    function groupedNotifications() {
        const source = notificationList();
        if (!settings || !settings.notificationsGroupByApp) {
            return source.map(notification => ({
                "key": "notification-" + String(notification ? notification.id : ""),
                "app": appLabel(notification),
                "items": [notification]
            }));
        }

        const order = [];
        const map = {};
        for (let i = 0; i < source.length; i++) {
            const notification = source[i];
            const app = appLabel(notification);
            const key = app.toLowerCase();
            if (!map[key]) {
                map[key] = { "key": key, "app": app, "items": [] };
                order.push(key);
            }
            map[key].items.push(notification);
        }

        return order.map(key => map[key]);
    }

    function isExpanded(group) {
        const key = String(group && group.key ? group.key : "");
        if (expandedGroups[key] !== undefined) return expandedGroups[key];
        return settings ? settings.notificationsGroupsExpanded : true;
    }

    function setExpanded(group, value) {
        const key = String(group && group.key ? group.key : "");
        const next = Object.assign({}, expandedGroups || {});
        next[key] = value;
        expandedGroups = next;
    }

    function toggleGroup(group) {
        setExpanded(group, !isExpanded(group));
    }

    function clampedX(value) {
        const maxX = panelWindow ? Math.max(0, panelWindow.width - panelWidth) : 0;
        return Math.max(0, Math.min(maxX, value));
    }

    function anchoredX() {
        if (anchorItem && typeof anchorItem.mapToItem === "function") {
            const point = anchorItem.mapToItem(null, 0, 0);
            return clampedX(point.x + anchorItem.width / 2 - panelWidth / 2);
        }

        return panelWindow ? clampedX(panelWindow.width - panelWidth) : 0;
    }

    function imageSource(notification) {
        const raw = String(notification && notification.image ? notification.image : "");
        if (raw.length <= 0) return "";
        if (raw.indexOf("file://") === 0 || raw.indexOf("image://") === 0 || raw.indexOf("qrc:") === 0) return raw;
        if (raw.charAt(0) === "/") return "file://" + raw;
        return raw;
    }

    function iconSource(notification) {
        const desktop = String(notification && notification.desktopEntry ? notification.desktopEntry : "");
        const appIcon = String(notification && notification.appIcon ? notification.appIcon : "");
        const app = appLabel(notification);
        const resolved = iconResolver.source(desktop.length > 0 ? desktop : appIcon.length > 0 ? appIcon : app);
        if (resolved.length > 0) return resolved;
        if (appIcon.length > 0 && Quickshell.hasThemeIcon(appIcon)) return Quickshell.iconPath(appIcon, true);
        return "";
    }

    function urgencyColor(notification) {
        const urgency = Number(notification && notification.urgency !== undefined ? notification.urgency : 1);
        if (urgency >= 2) return theme.error;
        if (urgency <= 0) return theme.secondary;
        return theme.primary;
    }

    function dismiss(notification) {
        if (notification && typeof notification.dismiss === "function")
            notification.dismiss();
    }

    function invokeAction(action, notification) {
        if (action && typeof action.invoke === "function")
            action.invoke();
        if (notification && !notification.resident)
            dismiss(notification);
    }

    function clearAll() {
        const list = notificationList();
        for (let i = 0; i < list.length; i++)
            dismiss(list[i]);
    }

    function toggle(anchor) {
        if (panelOpen) close();
        else open(anchor);
    }

    function open(anchor) {
        closeTimer.stop();
        anchorItem = anchor || null;
        panelClosing = false;
        panelOpen = true;
    }

    function close() {
        if (!panelOpen && !panelClosing) return;
        panelClosing = true;
        panelOpen = false;
        closeTimer.restart();
    }

    AppIconResolver {
        id: iconResolver
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -notificationFrame.height - settings.settingsPanelGap : panelWindow.height + settings.settingsPanelGap) : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: notificationFrame.height
    visible: panelOpen || panelClosing
    grabFocus: anchorItem !== null
    color: "transparent"

    Timer {
        id: closeTimer

        interval: root.settings ? Math.max(1, root.settings.motionClose) : 1
        repeat: false
        onTriggered: root.panelClosing = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.panelOpen
        onPressed: function(mouse) {
            root.close();
            mouse.accepted = true;
        }
        onWheel: function(wheel) {
            root.close();
            wheel.accepted = true;
        }
    }

    Surface {
        id: notificationFrame

        x: root.anchoredX()
        y: root.panelOpen ? 0 : -Math.max(settings.effectiveContentSpacing * 2, settings.effectiveGroupPadding * 2)
        width: root.panelWidth
        height: content.implicitHeight + settings.panelPadding * 2
        theme: root.theme
        settings: root.settings
        surfaceColor: theme.alpha(theme.surfaceContainerHigh, settings.panelOpacity / 100)
        outlineColor: theme.outlineSubtle
        outlineWidth: settings.effectiveBorderWidth
        surfaceRadius: settings.panelRadius
        clip: true
        opacity: root.panelOpen ? 1 : 0

        Behavior on y { NumberAnimation { duration: root.panelOpen ? settings.motionOpen : settings.motionClose; easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic } }
        Behavior on opacity { NumberAnimation { duration: root.panelOpen ? settings.motionOpen : settings.motionClose; easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: function(mouse) { mouse.accepted = true; }
            onWheel: function(wheel) { wheel.accepted = true; }
        }

        Column {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: settings.panelPadding
            spacing: settings.effectiveContentSpacing

            Row {
                width: parent.width
                height: settings.controlHeight
                spacing: settings.effectiveContentSpacing

                Text {
                    width: settings.controlHeight
                    height: parent.height
                    text: "󰂚"
                    color: theme.primary
                    font.family: settings.fontFamilyIcon
                    font.pixelSize: settings.effectiveIconSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Column {
                    width: parent.width - settings.controlHeight - clearButton.width - parent.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                    Text {
                        width: parent.width
                        text: "Notifications"
                        color: theme.text
                        elide: Text.ElideRight
                        font.family: settings.fontFamilySans
                        font.pixelSize: Math.round(settings.effectiveFontSize * 1.06)
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: root.notificationList().length > 0 ? root.notificationList().length + " queued" : "No queued notifications"
                        color: theme.textMuted
                        elide: Text.ElideRight
                        font.family: settings.fontFamilySans
                        font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                    }
                }

                CompactButton {
                    id: clearButton

                    theme: root.theme
                    settings: root.settings
                    icon: "󰆴"
                    enabled: root.notificationList().length > 0
                    onPressed: root.clearAll()
                }
            }

            Flickable {
                width: parent.width
                height: Math.min(groupList.implicitHeight, settings.controlHeight * 10)
                contentWidth: width
                contentHeight: groupList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: groupList

                    width: parent.width
                    spacing: settings.effectiveContentSpacing

                    InfoRow {
                        width: parent.width
                        theme: root.theme
                        settings: root.settings
                        visible: root.groups.length <= 0
                        label: "Inbox"
                        value: "clear"
                    }

                    Repeater {
                        model: root.groups

                        NotificationGroup {
                            required property var modelData

                            width: parent.width
                            theme: root.theme
                            settings: root.settings
                            group: modelData
                            expanded: root.isExpanded(modelData)
                            onToggleRequested: root.toggleGroup(modelData)
                        }
                    }
                }
            }
        }
    }

    component NotificationGroup: Column {
        id: groupRoot

        property var theme
        property var settings
        property var group: ({})
        property bool expanded: true

        signal toggleRequested()

        spacing: settings.effectiveContentSpacing

        Rectangle {
            width: parent.width
            height: settings.controlHeight
            radius: settings.effectivePillRadius
            color: groupHover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceContainer, 0.48)
            border.color: theme.outlineSubtle
            border.width: settings.effectiveBorderWidth
            antialiasing: true

            Row {
                anchors.fill: parent
                anchors.margins: settings.effectiveGroupPadding
                spacing: settings.effectiveContentSpacing

                Text {
                    width: settings.controlHeight
                    height: parent.height
                    text: groupRoot.expanded ? "󰅀" : "󰅂"
                    color: theme.textMuted
                    font.family: settings.fontFamilyIcon
                    font.pixelSize: settings.effectiveIconSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width - settings.controlHeight - countBadge.width - parent.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(groupRoot.group.app || "Notifications")
                    color: theme.text
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    id: countBadge

                    width: countText.implicitWidth + settings.effectivePillPadding
                    height: Math.max(countText.implicitHeight + settings.effectiveGroupPadding, settings.effectiveSpacingM)
                    anchors.verticalCenter: parent.verticalCenter
                    radius: height / 2
                    color: theme.surfaceActive
                    border.color: theme.outlineSubtle
                    border.width: settings.effectiveBorderWidth
                    antialiasing: true

                    Text {
                        id: countText

                        anchors.centerIn: parent
                        text: String(Array.from(groupRoot.group.items || []).length)
                        color: theme.primary
                        font.family: settings.fontFamilyMono
                        font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.72))
                        font.weight: Font.DemiBold
                    }
                }
            }

            MouseArea {
                id: groupHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: groupRoot.toggleRequested()
            }
        }

        Column {
            width: parent.width
            spacing: settings.effectiveContentSpacing
            visible: groupRoot.expanded

            Repeater {
                model: groupRoot.expanded ? Array.from(groupRoot.group.items || []) : []

                NotificationCard {
                    required property var modelData

                    width: groupRoot.width
                    theme: groupRoot.theme
                    settings: groupRoot.settings
                    notification: modelData
                }
            }
        }
    }

    component NotificationCard: Rectangle {
        id: card

        property var theme
        property var settings
        property var notification
        readonly property string imageUrl: root.imageSource(notification)
        readonly property bool hasImage: settings.notificationsShowImages && imageUrl.length > 0
        readonly property var actions: settings.notificationsShowActions ? Array.from(notification && notification.actions ? notification.actions : []) : []
        readonly property color accentColor: root.urgencyColor(notification)

        implicitHeight: cardColumn.implicitHeight + settings.effectiveContentSpacing * 2
        radius: settings.effectivePillRadius
        color: cardHover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceContainer, 0.56)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        clip: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }

        Column {
            id: cardColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: settings.effectiveContentSpacing
            spacing: settings.effectiveContentSpacing

            Row {
                width: parent.width
                spacing: settings.effectiveContentSpacing

                Rectangle {
                    width: settings.controlHeight
                    height: width
                    radius: settings.effectivePillRadius
                    color: theme.alpha(card.accentColor, 0.18)
                    border.color: theme.alpha(card.accentColor, 0.32)
                    border.width: settings.effectiveBorderWidth
                    antialiasing: true
                    clip: true

                    IconImage {
                        anchors.fill: parent
                        anchors.margins: settings.effectiveGroupPadding
                        implicitSize: settings.effectiveIconSize
                        source: root.iconSource(card.notification)
                        asynchronous: true
                        mipmap: true
                        visible: source.length > 0 && status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.iconSource(card.notification).length <= 0
                        text: "󰂚"
                        color: card.accentColor
                        font.family: settings.fontFamilyIcon
                        font.pixelSize: settings.effectiveIconSize
                    }
                }

                Column {
                    width: parent.width - settings.controlHeight - dismissButton.width - parent.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                    Text {
                        width: parent.width
                        text: String(card.notification && card.notification.summary ? card.notification.summary : root.appLabel(card.notification))
                        color: theme.text
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        font.family: settings.fontFamilySans
                        font.pixelSize: settings.effectiveFontSize
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: root.appLabel(card.notification)
                        color: theme.textMuted
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        font.family: settings.fontFamilySans
                        font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                    }
                }

                CompactButton {
                    id: dismissButton

                    theme: card.theme
                    settings: card.settings
                    icon: ""
                    onPressed: root.dismiss(card.notification)
                }
            }

            Text {
                width: parent.width
                visible: settings.notificationsShowBody && String(card.notification && card.notification.body ? card.notification.body : "").length > 0
                text: String(card.notification && card.notification.body ? card.notification.body : "")
                color: theme.textMuted
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                font.family: settings.fontFamilySans
                font.pixelSize: Math.max(9, settings.effectiveFontSize - 1)
            }

            Image {
                width: parent.width
                height: card.hasImage ? Math.min(parent.width * 0.42, settings.controlHeight * 5) : 0
                visible: card.hasImage
                source: card.imageUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                clip: true
            }

            Flow {
                width: parent.width
                spacing: settings.effectiveContentSpacing
                visible: card.actions.length > 0

                Repeater {
                    model: card.actions

                    ActionButton {
                        required property var modelData

                        theme: card.theme
                        settings: card.settings
                        label: String(modelData && modelData.text ? modelData.text : "Action")
                        onPressed: root.invokeAction(modelData, card.notification)
                    }
                }
            }
        }

        MouseArea { id: cardHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
    }

    component CompactButton: Rectangle {
        id: button

        property var theme
        property var settings
        property string icon: ""

        signal pressed()

        width: settings.controlHeight
        height: settings.controlHeight
        radius: settings.effectivePillRadius
        color: hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceContainer, 0.42)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        opacity: enabled ? 1 : 0.45
        antialiasing: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }

        Text {
            anchors.centerIn: parent
            text: button.icon
            color: theme.text
            font.family: settings.fontFamilyIcon
            font.pixelSize: settings.effectiveIconSize
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.pressed()
        }
    }

    component ActionButton: Rectangle {
        id: action

        property var theme
        property var settings
        property string label: ""

        signal pressed()

        width: Math.min(labelText.implicitWidth + settings.effectivePillPadding * 2, parent ? parent.width : labelText.implicitWidth)
        height: settings.controlHeight
        radius: settings.effectivePillRadius
        color: hover.containsMouse ? theme.surfaceActive : theme.alpha(theme.primary, 0.14)
        border.color: theme.alpha(theme.primary, 0.28)
        border.width: settings.effectiveBorderWidth
        antialiasing: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }

        Text {
            id: labelText
            anchors.centerIn: parent
            width: parent.width - settings.effectivePillPadding * 2
            text: action.label
            color: theme.primary
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: settings.fontFamilySans
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.pressed()
        }
    }

    component InfoRow: Rectangle {
        id: info

        property var theme
        property var settings
        property string label: ""
        property string value: ""

        implicitHeight: settings.controlHeight * 1.55
        radius: settings.effectivePillRadius
        color: theme.alpha(theme.surfaceContainer, 0.42)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true

        Row {
            anchors.fill: parent
            anchors.margins: settings.effectiveContentSpacing
            spacing: settings.effectiveContentSpacing

            Text {
                width: settings.controlHeight
                height: parent.height
                text: "󰂚"
                color: theme.textMuted
                font.family: settings.fontFamilyIcon
                font.pixelSize: settings.effectiveIconSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Column {
                width: parent.width - settings.controlHeight - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                Text {
                    width: parent.width
                    text: info.label
                    color: theme.text
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: info.value
                    color: theme.textMuted
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                }
            }
        }
    }
}
