pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

PopupWindow {
    id: root

    required property var theme
    required property var settings
    property var panelWindow: null
    property var coordinator: null
    property string panelId: ""
    property var registeredCoordinator: null
    property string registeredPanelId: ""
    property var anchorItem: null
    property bool panelOpen: false
    property bool panelClosing: false
    property real panelWidth: surface.implicitWidth
    property real panelHeight: surface.implicitHeight
    property real panelGap: theme.spacingS
    property real closedOffset: theme.spacingM
    property string fallbackAlignment: "right"
    property bool closeOnEscape: true
    property bool closeOnOutsideClick: true
    property bool closeOnFocusLoss: true
    property bool focusOnOpen: true
    property Item initialFocusItem: null
    default property alias panelContent: surface.contentData
    readonly property alias surfaceItem: surface
    readonly property alias panelContentItem: surface.contentItem
    readonly property bool coordinatorActive: coordinator
                                              ? coordinator.isActive(panelId)
                                              : panelOpen
    readonly property int openDuration: settings.performanceMode
                                        || settings.popupMotion === "none"
                                        ? 0
                                        : Math.round(theme.motionOpen)
    readonly property int closeDuration: settings.performanceMode
                                         || settings.popupMotion === "none"
                                         ? 0
                                         : Math.round(theme.motionClose)

    signal aboutToOpen(var anchorItem, var payload)
    signal panelOpened(var anchorItem, var payload)
    signal aboutToClose()
    signal panelClosed()
    signal focusRequested(var focusItem)

    function clampedX(value) {
        const availableWidth = panelWindow ? panelWindow.width : panelWidth;
        const maximumX = Math.max(0, availableWidth - panelWidth);
        return Math.max(0, Math.min(maximumX, value));
    }

    function fallbackX() {
        if (!panelWindow || fallbackAlignment === "left")
            return 0;
        if (fallbackAlignment === "center")
            return clampedX((panelWindow.width - panelWidth) / 2);
        return clampedX(panelWindow.width - panelWidth);
    }

    function anchoredX() {
        if (anchorItem && typeof anchorItem.mapToItem === "function") {
            const point = anchorItem.mapToItem(null, 0, 0);
            return clampedX(point.x + anchorItem.width / 2 - panelWidth / 2);
        }
        return fallbackX();
    }

    function requestInitialFocus() {
        if (!panelOpen || !focusOnOpen)
            return;

        const target = initialFocusItem || surface;
        if (target && typeof target.forceActiveFocus === "function")
            target.forceActiveFocus();
        focusRequested(target);
    }

    function open(anchor, payload) {
        if (coordinator && panelId.length > 0)
            return coordinator.open(panelId, anchor, payload);
        openFromCoordinator(anchor, payload);
        return true;
    }

    function toggle(anchor, payload) {
        if (coordinator && panelId.length > 0)
            return coordinator.toggle(panelId, anchor, payload);
        if (panelOpen) {
            closeFromCoordinator();
            return false;
        }
        openFromCoordinator(anchor, payload);
        return true;
    }

    function close() {
        if (coordinator && panelId.length > 0 && coordinator.isActive(panelId))
            return coordinator.close(panelId);
        return closeFromCoordinator();
    }

    function openFromCoordinator(anchor, payload) {
        closeTimer.stop();
        anchorItem = anchor || null;
        aboutToOpen(anchorItem, payload);
        panelOpen = true;
        panelClosing = false;
        panelOpened(anchorItem, payload);
        Qt.callLater(requestInitialFocus);
        return true;
    }

    function closeFromCoordinator() {
        if (!panelOpen && !panelClosing)
            return false;
        if (!panelOpen)
            return true;

        closeTimer.stop();
        aboutToClose();
        panelOpen = false;
        if (closeDuration <= 0) {
            panelClosing = false;
            panelClosed();
        } else {
            panelClosing = true;
            closeTimer.restart();
        }
        return true;
    }

    function dismissFromFocusLoss() {
        if (closeOnFocusLoss && panelOpen)
            close();
    }

    function syncRegistration() {
        if (registeredCoordinator
                && registeredPanelId.length > 0
                && (registeredCoordinator !== coordinator
                    || registeredPanelId !== panelId)) {
            registeredCoordinator.unregister(registeredPanelId, root);
            registeredCoordinator = null;
            registeredPanelId = "";
        }

        if (coordinator && panelId.length > 0
                && (registeredCoordinator !== coordinator
                    || registeredPanelId !== panelId)) {
            if (coordinator.register(panelId, root)) {
                registeredCoordinator = coordinator;
                registeredPanelId = panelId;
            }
        }
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow
                   ? (settings.barPosition === "bottom"
                      ? -panelHeight - panelGap
                      : panelWindow.height + panelGap)
                   : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: panelHeight
    visible: panelOpen || panelClosing
    grabFocus: panelOpen && focusOnOpen
    color: theme.transparent
    onClosed: dismissFromFocusLoss()

    Component.onCompleted: syncRegistration()

    Component.onDestruction: {
        if (registeredCoordinator && registeredPanelId.length > 0)
            registeredCoordinator.unregister(registeredPanelId, root);
    }

    onCoordinatorChanged: syncRegistration()
    onPanelIdChanged: syncRegistration()

    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: root.panelOpen && root.closeOnEscape
        context: Qt.WindowShortcut
        onActivated: root.close()
    }

    Timer {
        id: closeTimer

        interval: root.closeDuration
        repeat: false
        onTriggered: {
            root.panelClosing = false;
            root.panelClosed();
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.panelOpen && root.closeOnOutsideClick
        onPressed: function(mouse) {
            root.close();
            mouse.accepted = true;
        }
        onWheel: function(wheel) {
            root.close();
            wheel.accepted = true;
        }
    }

    PanelSurface {
        id: surface

        x: root.anchoredX()
        y: root.panelOpen
           ? 0
           : (root.settings.barPosition === "bottom"
              ? root.closedOffset
              : -root.closedOffset)
        width: root.panelWidth
        height: root.panelHeight
        theme: root.theme
        settings: root.settings
        opacity: root.panelOpen ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: root.panelOpen ? root.openDuration : root.closeDuration
                easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.panelOpen ? root.openDuration : root.closeDuration
                easing.type: root.panelOpen ? Easing.OutCubic : Easing.InCubic
            }
        }
    }
}
