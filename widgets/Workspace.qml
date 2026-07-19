import QtQuick

Item {
    id: root

    property var theme
    property var settings
    property var compositor
    property var workspaces: compositor ? compositor.workspaces : []
    property var windows: compositor ? compositor.windows : []
    property int openedWindowWorkspaceId: compositor ? compositor.openedWindowWorkspaceId : -1
    property int openedWindowSerial: compositor ? compositor.openedWindowSerial : 0
    property var displayedWorkspaces: visibleWorkspaces()
    property var windowCounts: windowCountMap()
    property int focusedIndex: focusedWorkspaceIndex()
    property int focusedWorkspaceIdValue: focusedWorkspaceId()
    property int layoutRevision: 0
    property bool windowCountsReady: false
    property real indicatorX: 0
    property real indicatorWidth: 0
    property bool indicatorVisible: false
    property bool indicatorAnimationsEnabled: false
    property int indicatorWorkspaceId: -1
    property bool scrollReady: true

    width: implicitWidth
    height: implicitHeight
    implicitWidth: workspaceRow.implicitWidth
    implicitHeight: settings.moduleHeight

    function focusedOutput(list) {
        for (let i = 0; i < list.length; i++) {
            if (list[i].focused)
                return list[i].monitor;
        }
        return list.length > 0 ? list[0].monitor : "";
    }

    function visibleWorkspaces() {
        const output = focusedOutput(workspaces);
        return workspaces.filter(workspace => workspace.monitor === output).sort((a, b) => a.index - b.index);
    }

    function focusedWorkspaceIndex() {
        for (let i = 0; i < displayedWorkspaces.length; i++) {
            if (displayedWorkspaces[i].focused)
                return i;
        }
        return displayedWorkspaces.length > 0 ? 0 : -1;
    }

    function focusedWorkspaceId() {
        if (focusedIndex < 0 || focusedIndex >= displayedWorkspaces.length)
            return -1;
        return Number(displayedWorkspaces[focusedIndex].id);
    }

    function label(workspace) {
        if (!settings.workspaceShowNumbers && !workspace.name)
            return "";
        return workspace.label || String(workspace.index);
    }

    function workspaceWindowCount(workspace) {
        if (!workspace)
            return 0;
        return Number(windowCounts[String(workspace.id)] || 0);
    }

    function windowCountMap() {
        const counts = {};

        for (let i = 0; i < workspaces.length; i++) {
            counts[String(workspaces[i].id)] = 0;
        }

        for (let i = 0; i < windows.length; i++) {
            const key = String(windows[i].workspaceId);
            counts[key] = (counts[key] || 0) + 1;
        }

        return counts;
    }

    function rememberWindowCounts() {
        windowCountsReady = true;
    }

    function focusWorkspace(workspace) {
        if (compositor) compositor.focusWorkspace(workspace);
    }

    function focusWorkspaceOffset(offset) {
        const list = Array.from(displayedWorkspaces || []);
        if (list.length <= 1)
            return;

        let nextIndex = focusedIndex >= 0 ? focusedIndex + offset : (offset > 0 ? 0 : list.length - 1);

        if (settings.workspaceScrollWrap) {
            nextIndex = (nextIndex + list.length) % list.length;
        } else {
            nextIndex = Math.max(0, Math.min(list.length - 1, nextIndex));
        }

        if (nextIndex === focusedIndex)
            return;

        focusWorkspace(list[nextIndex]);
    }

    function handleWheel(wheel) {
        if (!settings.workspaceScrollEnabled)
            return;

        const angle = wheel.angleDelta ? wheel.angleDelta.y : 0;
        const pixel = wheel.pixelDelta ? wheel.pixelDelta.y : 0;
        const delta = angle !== 0 ? angle : pixel;

        if (delta === 0)
            return;

        wheel.accepted = true;

        if (!scrollReady)
            return;

        scrollReady = false;
        scrollCooldown.restart();
        focusWorkspaceOffset(delta < 0 ? 1 : -1);
    }

    function focusedItem() {
        const revision = layoutRevision;
        return focusedIndex >= 0 ? workspaceRepeater.itemAt(focusedIndex) : null;
    }

    function updateFocusIndicator(reason) {
        const item = focusedItem();
        const id = focusedWorkspaceIdValue;
        const focusChanged = indicatorWorkspaceId >= 0 && id >= 0 && id !== indicatorWorkspaceId;
        const style = settings.workspaceIndicatorStyle;
        const compactWidth = style === "dot" ? Math.max(4, settings.effectiveContentSpacing)
                                             : style === "underline" ? Math.max(settings.moduleHeight * 0.62, settings.effectiveIconSize)
                                                                      : 0;
        const targetWidth = item ? (style === "pill" ? item.width : Math.min(item.width, compactWidth)) : 0;

        if (reason === "focus" && focusChanged && settings.motionSpatial > 0) {
            indicatorAnimationsEnabled = true;
        } else if (reason === "layout") {
            indicatorAnimationsEnabled = false;
        }

        indicatorVisible = item !== null && id >= 0;
        indicatorX = item ? item.x + (item.width - targetWidth) / 2 : 0;
        indicatorWidth = targetWidth;
        indicatorWorkspaceId = id;
    }

    function triggerWorkspacePulse(workspaceId) {
        for (let i = 0; i < workspaceRepeater.count; i++) {
            const item = workspaceRepeater.itemAt(i);
            if (item && item.workspaceData && Number(item.workspaceData.id) === Number(workspaceId)) {
                item.pulse();
                return;
            }
        }
    }

    property string pendingIndicatorUpdateReason: "layout"

    function scheduleFocusIndicatorUpdate(reason) {
        pendingIndicatorUpdateReason = reason;
        focusIndicatorUpdateTimer.restart();
    }

    Timer {
        id: focusIndicatorUpdateTimer

        interval: 0
        repeat: false
        onTriggered: root.updateFocusIndicator(root.pendingIndicatorUpdateReason)
    }

    Timer {
        id: scrollCooldown

        interval: Math.max(90, settings.motionFast)
        repeat: false
        onTriggered: root.scrollReady = true
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onWheel: function(wheel) { root.handleWheel(wheel); }
    }

    Rectangle {
        id: focusIndicator

        x: root.indicatorX
        y: settings.workspaceIndicatorStyle === "underline" ? settings.moduleHeight - Math.max(2, settings.effectiveContentSpacing / 2)
                                                            : settings.workspaceIndicatorStyle === "dot" ? settings.moduleHeight - Math.max(4, settings.effectiveContentSpacing)
                                                                                                         : 0
        width: root.indicatorWidth
        height: settings.workspaceIndicatorStyle === "pill" ? settings.moduleHeight
                                                            : settings.workspaceIndicatorStyle === "dot" ? Math.max(4, settings.effectiveContentSpacing)
                                                                                                        : Math.max(2, settings.effectiveContentSpacing / 2)
        visible: root.indicatorVisible
        radius: height / 2
        color: theme.surfaceActive
        border.color: theme.transparent
        border.width: 0
        antialiasing: true
        opacity: visible ? 1 : 0

        Behavior on x {
            SpringAnimation {
                spring: 7.0
                damping: 0.55
                epsilon: 0.2
            }
        }

        Behavior on width {
            SpringAnimation {
                spring: 7.0
                damping: 0.55
                epsilon: 0.2
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: settings.motionNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: settings.motionNormal
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: settings.effectiveGroupPadding / 2
            anchors.leftMargin: settings.effectiveContentSpacing / 2
            anchors.rightMargin: settings.effectiveContentSpacing / 2
            height: parent.height / 2
            radius: parent.radius
            color: theme.gloss
            visible: settings.workspaceIndicatorStyle === "pill"
            antialiasing: true
        }
    }

    Row {
        id: workspaceRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: settings.itemSpacing
        z: 1

        Repeater {
            id: workspaceRepeater

            model: root.displayedWorkspaces.length

            Rectangle {
                id: workspacePill

                property var workspaceData: root.displayedWorkspaces[index]
                property bool focused: workspaceData && workspaceData.focused
                property bool active: workspaceData && workspaceData.active
                property bool urgent: workspaceData && workspaceData.urgent
                property int windowCount: root.workspaceWindowCount(workspaceData)
                property bool occupied: windowCount > 0
                property bool pulsing: pulseAnimation.running
                property real pulseScale: 1
                property real pulseWash: 0

                function pulse() {
                    pulseAnimation.restart();
                }

                width: Math.max(settings.workspaceMinWidth, labelText.visible ? labelText.implicitWidth + settings.effectivePillPadding * 2 : settings.moduleHeight)
                height: settings.moduleHeight
                radius: settings.effectivePillRadius
                color: urgent ? theme.alpha(theme.urgent, 0.18) : pulseWash > 0 ? theme.alpha(theme.accent, 0.10 * pulseWash) : hoverArea.containsMouse ? theme.surfaceHover : theme.transparent
                border.color: urgent ? theme.alpha(theme.urgent, 0.44) : theme.transparent
                border.width: urgent ? 1 : 0
                scale: Math.max(pulseScale, hoverArea.containsMouse ? 1.012 : 1)
                transformOrigin: Item.Center
                z: pulsing ? 2 : 1
                antialiasing: true

                Behavior on color {
                    ColorAnimation {
                        duration: settings.motionNormal
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: settings.motionNormal
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: settings.motionHover
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    id: labelText

                    anchors.centerIn: parent
                    text: root.label(workspacePill.workspaceData)
                    visible: text.length > 0
                    color: workspacePill.urgent ? theme.urgent : workspacePill.focused ? theme.text : theme.textMuted
                    opacity: workspacePill.urgent || workspacePill.focused ? 1 : 0.55
                    font.family: settings.fontFamily
                    font.pixelSize: settings.effectiveFontSize
                    font.weight: workspacePill.focused ? Font.Bold : Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Behavior on color {
                        ColorAnimation {
                            duration: settings.motionNormal
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: settings.motionNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    id: occupiedMarker

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: settings.effectiveGroupPadding / 2
                    width: workspacePill.focused ? settings.effectiveIconSize * 0.62 : settings.effectiveContentSpacing
                    height: Math.max(1, settings.effectiveContentSpacing / 2)
                    radius: height / 2
                    color: workspacePill.focused ? theme.accent : workspacePill.active ? theme.text : theme.textMuted
                    opacity: settings.workspaceShowOccupied && workspacePill.occupied ? (workspacePill.focused ? 0.95 : 0.68) : 0
                    scale: workspacePill.occupied ? (workspacePill.pulsing ? 1.16 : 1) : 0
                    antialiasing: true

                    Behavior on opacity {
                        NumberAnimation {
                            duration: settings.motionFast
                            easing.type: workspacePill.occupied ? Easing.OutCubic : Easing.InCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: settings.motionFast
                            easing.type: workspacePill.occupied ? Easing.OutBack : Easing.InCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: settings.motionNormal
                        }
                    }
                }

                MouseArea {
                    id: hoverArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(workspacePill.workspaceData)
                    onWheel: function(wheel) { root.handleWheel(wheel); }
                }

                Component.onCompleted: root.layoutRevision += 1
                onWidthChanged: root.layoutRevision += 1
                onXChanged: root.layoutRevision += 1

                SequentialAnimation {
                    id: pulseAnimation

                    ParallelAnimation {
                        NumberAnimation {
                            target: workspacePill
                            property: "pulseScale"
                            to: 1.025
                            duration: settings.motionFast
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            target: workspacePill
                            property: "pulseWash"
                            to: 1
                            duration: settings.motionFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: workspacePill
                            property: "pulseScale"
                            to: 1
                            duration: settings.motionPulse
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            target: workspacePill
                            property: "pulseWash"
                            to: 0
                            duration: settings.motionPulse
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    onWindowCountsChanged: rememberWindowCounts()
    onDisplayedWorkspacesChanged: {
        if (!root.indicatorAnimationsEnabled)
            root.scheduleFocusIndicatorUpdate("layout");
    }
    onFocusedWorkspaceIdValueChanged: root.scheduleFocusIndicatorUpdate("focus")
    onLayoutRevisionChanged: {
        if (!root.indicatorAnimationsEnabled)
            root.scheduleFocusIndicatorUpdate("layout");
    }
    onOpenedWindowSerialChanged: {
        if (!windowCountsReady || openedWindowWorkspaceId < 0)
            return;
        triggerWorkspacePulse(openedWindowWorkspaceId);
    }
    Component.onCompleted: {
        rememberWindowCounts();
        root.scheduleFocusIndicatorUpdate("layout");
    }
}
