pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "panels"
import "services"
import "widgets"

PanelWindow {
    id: bar

    required property var modelData
    required property var appContext
    readonly property var settings: appContext.settings
    readonly property var theme: appContext.theme
    readonly property var compositor: appContext.compositor
    readonly property var notificationServer: appContext.notificationServer
    readonly property bool settingsOpen: appContext.settingsWindow
                                         ? appContext.settingsWindow.visible
                                         : false
    readonly property bool notificationsOpen: notificationPanelLoader.item ? notificationPanelLoader.item.visible : false
    readonly property bool anyPanelOpen: panelCoordinator.hasActivePanel
    readonly property var trackedNotifications: notificationServer.trackedNotifications ? notificationServer.trackedNotifications.values : []
    readonly property int notificationCount: trackedNotifications.length
    property bool backgroundPhaseReady: false
    property bool interactionPhaseReady: false
    property bool startupComplete: false
    property bool barHovered: false
    property int lastWorkspaceId: -1
    readonly property int reservedEdgeSize: settings.reserveSpace ? Math.max(0, Math.round(settings.barHeight + settings.screenMargin)) : 0
    readonly property real autohideOffset: {
        if (!settings.barAutohide || barHovered || settingsOpen) return 0;
        const offset = Math.max(0, settings.barHeight - theme.spacingXS);
        return settings.barPosition === "bottom" ? offset : -offset;
    }

    PanelCoordinator {
        id: panelCoordinator
    }

    PanelAdapter {
        panelId: "clock"
        coordinator: panelCoordinator
        panel: clockPanelLoader.item
    }

    PanelAdapter {
        panelId: "dashboard"
        coordinator: panelCoordinator
        panel: dashboardPanelLoader.item
    }

    PanelAdapter {
        panelId: "notepad"
        coordinator: panelCoordinator
        panel: notepadPanelLoader.item
    }

    PanelAdapter {
        panelId: "clipboard"
        coordinator: panelCoordinator
        panel: clipboardPanelLoader.item
    }

    PanelAdapter {
        panelId: "processes"
        coordinator: panelCoordinator
        panel: processPanelLoader.item
    }

    PanelAdapter {
        panelId: "notifications"
        coordinator: panelCoordinator
        panel: notificationPanelLoader.item
    }

    PanelAdapter {
        panelId: "launcher"
        coordinator: panelCoordinator
        panel: launcherPanelLoader.item
    }

    PanelAdapter {
        panelId: "moduleDetails"
        coordinator: panelCoordinator
        panel: moduleDetailsPanelLoader.item
    }

    function combinedModules() {
        return Array.from(settings.leftModules || [])
                    .concat(Array.from(settings.centerModules || []))
                    .concat(Array.from(settings.rightModules || []));
    }

    function ensureInteractionPhase() {
        interactionPhaseReady = true;
    }

    function closeAllPanels() {
        appContext.closeSettings();
        panelCoordinator.closeAll();
    }

    function closeToolPanels() {
        panelCoordinator.close("notepad");
        panelCoordinator.close("clipboard");
        panelCoordinator.close("processes");
        panelCoordinator.close("notifications");
        panelCoordinator.close("launcher");
    }

    function closeNotifications() {
        panelCoordinator.close("notifications");
    }

    function closeClock() {
        panelCoordinator.close("clock");
    }

    function closeControls() {
        panelCoordinator.close("dashboard");
    }

    function closeNotepad() {
        panelCoordinator.close("notepad");
    }

    function closeClipboard() {
        panelCoordinator.close("clipboard");
    }

    function closeProcessList() {
        panelCoordinator.close("processes");
    }

    function closeLauncher() {
        panelCoordinator.close("launcher");
    }

    function closeModuleDetails() {
        panelCoordinator.close("moduleDetails");
    }

    function showOsd(kind, value) {
        ensureInteractionPhase();
        const type = String(kind || "volume");
        const allowed = ["volume", "mute", "brightness", "keyboard", "capsLock", "numLock", "media", "battery"];
        if (allowed.indexOf(type) < 0)
            return;
        const amount = Math.max(0, Math.min(1, Number(value) || 0.72));
        const icon = type === "brightness" ? "󰃠"
                   : type === "keyboard" ? "󰌌"
                   : type === "capsLock" ? "󰘲"
                   : type === "numLock" ? "󰎠"
                   : type === "media" ? "󰝚"
                   : type === "battery" ? "󰁹"
                   : "󰕾";
        if (osdLoader.item)
            osdLoader.item.show(icon, amount, type, type.charAt(0).toUpperCase() + type.slice(1));
    }

    function showTooltip(text) {
        ensureInteractionPhase();
        if (tooltipHostLoader.item)
            tooltipHostLoader.item.show(text, null);
    }

    function hideTooltip() {
        if (tooltipHostLoader.item)
            tooltipHostLoader.item.hide();
    }

    function openModuleTab(moduleName, tabName) {
        ensureInteractionPhase();
        panelCoordinator.open("moduleDetails", null, {
            "moduleName": moduleName,
            "tabName": tabName
        });
    }

    function showSettings(anchorItem) {
        appContext.rememberBar(bar);
        ensureInteractionPhase();
        panelCoordinator.closeAll();
        appContext.toggleSettings("overview", bar);
    }

    function showNotifications(anchorItem) {
        appContext.closeSettings();
        ensureInteractionPhase();
        panelCoordinator.toggle("notifications", anchorItem);
    }

    function showClock(anchorItem) {
        appContext.closeSettings();
        ensureInteractionPhase();
        panelCoordinator.toggle("clock", anchorItem);
    }

    function showControls(anchorItem) {
        appContext.closeSettings();
        ensureInteractionPhase();
        panelCoordinator.toggle("dashboard", anchorItem);
    }

    function showNotepad(anchorItem) {
        appContext.closeSettings();
        ensureInteractionPhase();
        panelCoordinator.toggle("notepad", anchorItem);
    }

    function showClipboard(anchorItem) {
        appContext.closeSettings();
        ensureInteractionPhase();
        panelCoordinator.toggle("clipboard", anchorItem);
    }

    function showProcessList(anchorItem) {
        appContext.closeSettings();
        ensureInteractionPhase();
        panelCoordinator.toggle("processes", anchorItem);
    }

    function showLauncher(anchorItem) {
        appContext.closeSettings();
        ensureInteractionPhase();
        panelCoordinator.toggle("launcher", anchorItem);
    }

    function showLauncherQuery(query) {
        appContext.closeSettings();
        ensureInteractionPhase();
        panelCoordinator.open("launcher", null, { "query": query });
    }

    function showModuleDetails(moduleName, anchorItem) {
        const name = String(moduleName || "");
        if (name === "launcher" || name === "apps" || name === "appLauncher") {
            showLauncher(anchorItem);
            return;
        }
        if (name === "notepad" || name === "scratchpad" || name === "notes") {
            showNotepad(anchorItem);
            return;
        }
        if (name === "clipboard" || name === "cliphist" || name === "clip") {
            showClipboard(anchorItem);
            return;
        }
        if (name === "processes" || name === "processList" || name === "tasks") {
            showProcessList(anchorItem);
            return;
        }

        appContext.closeSettings();
        ensureInteractionPhase();
        panelCoordinator.toggle("moduleDetails", anchorItem, { "moduleName": moduleName });
    }

    function openSettingsPage(page) {
        appContext.rememberBar(bar);
        ensureInteractionPhase();
        panelCoordinator.closeAll();
        appContext.openSettings(page, bar);
    }

    function openModuleDetails(moduleName) {
        const name = String(moduleName || "");
        if (name === "launcher" || name === "apps" || name === "appLauncher") {
            showLauncher(null);
            return;
        }
        if (name === "notepad" || name === "scratchpad" || name === "notes") {
            showNotepad(null);
            return;
        }
        if (name === "clipboard" || name === "cliphist" || name === "clip") {
            showClipboard(null);
            return;
        }
        if (name === "processes" || name === "processList" || name === "tasks") {
            showProcessList(null);
            return;
        }

        appContext.closeSettings();
        ensureInteractionPhase();
        panelCoordinator.open("moduleDetails", null, { "moduleName": moduleName });
    }

    function focusedWorkspaceData() {
        const list = Array.from(compositor.workspaces || []);
        for (let i = 0; i < list.length; i++) {
            if (list[i].focused) return list[i];
        }
        return list.length > 0 ? list[0] : null;
    }

    function updateWorkspaceToast() {
        const workspace = focusedWorkspaceData();
        const id = workspace ? Number(workspace.id) : -1;
        if (id < 0) return;

        if (lastWorkspaceId < 0) {
            lastWorkspaceId = id;
            return;
        }

        if (startupComplete && id !== lastWorkspaceId) {
            const label = "Workspace " + String(workspace.label || workspace.index || id);
            if (workspaceToastLoader.item)
                workspaceToastLoader.item.show(label);
        }

        lastWorkspaceId = id;
    }

    screen: modelData
    visible: true
    anchors.top: settings.barPosition !== "bottom"
    anchors.bottom: settings.barPosition === "bottom"
    anchors.left: true
    anchors.right: true
    margins.top: settings.barPosition === "bottom" ? 0 : settings.screenMargin
    margins.bottom: settings.barPosition === "bottom" ? settings.screenMargin : 0
    margins.left: settings.screenMargin
    margins.right: settings.screenMargin
    implicitHeight: settings.barHeight
    exclusiveZone: bar.reservedEdgeSize
    aboveWindows: true
    color: theme.transparent

    WlrLayershell.keyboardFocus: bar.anyPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onAnyPanelOpenChanged: if (bar.anyPanelOpen) escapeKeyHandler.forceActiveFocus()

    Item {
        id: escapeKeyHandler

        anchors.fill: parent
        focus: bar.anyPanelOpen
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape && bar.anyPanelOpen) {
                bar.closeAllPanels();
                event.accepted = true;
            }
        }
    }

    Item {
        id: barContent

        anchors.fill: parent
        y: bar.autohideOffset
        opacity: bar.startupComplete ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Math.round(theme.motionOpen + theme.motionFast)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: theme.motionOpen
                easing.type: Easing.OutExpo
            }
        }

        Rectangle {
            id: fallbackBackdrop

            anchors.fill: parent
            radius: settings.effectiveGroupRadius
            color: settings.effectiveBlurEnabled ? theme.alpha(theme.surfaceContainerHigh, 0.16) : theme.transparent
            antialiasing: true

            Behavior on color {
                ColorAnimation { duration: settings.motionNormal }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
                color: settings.effectiveBlurEnabled ? theme.alpha(theme.border, 0.15) : theme.transparent
                antialiasing: true

                Behavior on color {
                    ColorAnimation { duration: settings.motionNormal }
                }
            }
        }

        Item {
            id: layout

            anchors.fill: parent

            readonly property real sectionGap: settings.effectiveGroupSpacing
            readonly property real leftEdge: leftSection.visible ? leftSection.x + leftSection.width + sectionGap : 0
            readonly property real rightEdge: rightSection.visible ? rightSection.x - centerSection.width - sectionGap : width - centerSection.width

            BarSection {
                id: leftSection

                theme: bar.theme
                settings: bar.settings
                appContext: bar.appContext
                compositor: bar.compositor
                panelWindow: bar
                osd: osdLoader.item
                tooltipHost: tooltipHostLoader.item
                notificationCount: bar.notificationCount
                notificationOpen: bar.notificationsOpen
                modules: settings.leftModules
                active: settings.barStyle === "islands" || leftSection.opacity > 0
                backgroundReady: bar.backgroundPhaseReady
                interactionReady: bar.interactionPhaseReady
                settingsOpen: bar.settingsOpen
                contentAlignment: "left"
                visible: leftSection.hasContent && (settings.barStyle === "islands" || opacity > 0)
                opacity: settings.barStyle === "islands" ? 1 : 0
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onSettingsRequested: function(anchorItem) { bar.showSettings(anchorItem); }
                onNotificationsRequested: function(anchorItem) { bar.showNotifications(anchorItem); }
                onClockRequested: function(anchorItem) { bar.showClock(anchorItem); }
                onControlsRequested: function(anchorItem) { bar.showControls(anchorItem); }
                onModuleDetailsRequested: function(moduleName, anchorItem) { bar.showModuleDetails(moduleName, anchorItem); }
            }

            BarSection {
                id: centerSection

                theme: bar.theme
                settings: bar.settings
                appContext: bar.appContext
                compositor: bar.compositor
                panelWindow: bar
                osd: osdLoader.item
                tooltipHost: tooltipHostLoader.item
                notificationCount: bar.notificationCount
                notificationOpen: bar.notificationsOpen
                modules: settings.centerModules
                active: settings.barStyle === "islands" || centerSection.opacity > 0
                backgroundReady: bar.backgroundPhaseReady
                interactionReady: bar.interactionPhaseReady
                settingsOpen: bar.settingsOpen
                contentAlignment: "center"
                visible: centerSection.hasContent && (settings.barStyle === "islands" || opacity > 0)
                opacity: settings.barStyle === "islands" ? 1 : 0
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round(Math.max(layout.leftEdge,
                                       Math.min((parent.width - width) / 2, layout.rightEdge)))
                onSettingsRequested: function(anchorItem) { bar.showSettings(anchorItem); }
                onNotificationsRequested: function(anchorItem) { bar.showNotifications(anchorItem); }
                onClockRequested: function(anchorItem) { bar.showClock(anchorItem); }
                onControlsRequested: function(anchorItem) { bar.showControls(anchorItem); }
                onModuleDetailsRequested: function(moduleName, anchorItem) { bar.showModuleDetails(moduleName, anchorItem); }
            }

            BarSection {
                id: rightSection

                theme: bar.theme
                settings: bar.settings
                appContext: bar.appContext
                compositor: bar.compositor
                panelWindow: bar
                osd: osdLoader.item
                tooltipHost: tooltipHostLoader.item
                notificationCount: bar.notificationCount
                notificationOpen: bar.notificationsOpen
                modules: settings.rightModules
                active: settings.barStyle === "islands" || rightSection.opacity > 0
                backgroundReady: bar.backgroundPhaseReady
                interactionReady: bar.interactionPhaseReady
                settingsOpen: bar.settingsOpen
                contentAlignment: "right"
                visible: rightSection.hasContent && (settings.barStyle === "islands" || opacity > 0)
                opacity: settings.barStyle === "islands" ? 1 : 0
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onSettingsRequested: function(anchorItem) { bar.showSettings(anchorItem); }
                onNotificationsRequested: function(anchorItem) { bar.showNotifications(anchorItem); }
                onClockRequested: function(anchorItem) { bar.showClock(anchorItem); }
                onControlsRequested: function(anchorItem) { bar.showControls(anchorItem); }
                onModuleDetailsRequested: function(moduleName, anchorItem) { bar.showModuleDetails(moduleName, anchorItem); }
            }

            Surface {
                id: solidSurface

                anchors.fill: parent
                visible: settings.barStyle === "solid" || opacity > 0
                opacity: settings.barStyle === "solid" ? 1 : 0
                theme: bar.theme
                settings: bar.settings
                surfaceColor: theme.alpha(theme.surface, settings.barOpacity)
                outlineColor: settings.barBorderEnabled ? theme.border : theme.transparent
                outlineWidth: settings.barBorderEnabled ? settings.barBorderThickness : 0
                surfaceRadius: settings.barBorderEnabled ? Math.round(settings.effectiveRadiusS) : 0
                clip: true

                Behavior on opacity {
                    NumberAnimation { duration: settings.motionNormal; easing.type: solidSurface.opacity > 0 ? Easing.OutCubic : Easing.InCubic }
                }

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: settings.effectiveGroupPadding
                    anchors.rightMargin: settings.effectiveGroupPadding

                    ModuleStrip {
                        id: solidLeft

                        theme: bar.theme
                        settings: bar.settings
                        appContext: bar.appContext
                        compositor: bar.compositor
                        panelWindow: bar
                        osd: osdLoader.item
                        tooltipHost: tooltipHostLoader.item
                        notificationCount: bar.notificationCount
                        notificationOpen: bar.notificationsOpen
                        modules: settings.leftModules
                        active: settings.barStyle === "solid" || solidSurface.opacity > 0
                        backgroundReady: bar.backgroundPhaseReady
                        interactionReady: bar.interactionPhaseReady
                        settingsOpen: bar.settingsOpen
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        onSettingsRequested: function(anchorItem) { bar.showSettings(anchorItem); }
                        onNotificationsRequested: function(anchorItem) { bar.showNotifications(anchorItem); }
                        onClockRequested: function(anchorItem) { bar.showClock(anchorItem); }
                        onControlsRequested: function(anchorItem) { bar.showControls(anchorItem); }
                        onModuleDetailsRequested: function(moduleName, anchorItem) { bar.showModuleDetails(moduleName, anchorItem); }
                    }

                    ModuleStrip {
                        id: solidCenter

                        theme: bar.theme
                        settings: bar.settings
                        appContext: bar.appContext
                        compositor: bar.compositor
                        panelWindow: bar
                        osd: osdLoader.item
                        tooltipHost: tooltipHostLoader.item
                        notificationCount: bar.notificationCount
                        notificationOpen: bar.notificationsOpen
                        modules: settings.centerModules
                        active: settings.barStyle === "solid" || solidSurface.opacity > 0
                        backgroundReady: bar.backgroundPhaseReady
                        interactionReady: bar.interactionPhaseReady
                        settingsOpen: bar.settingsOpen
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.round((parent.width - width) / 2)
                        onSettingsRequested: function(anchorItem) { bar.showSettings(anchorItem); }
                        onNotificationsRequested: function(anchorItem) { bar.showNotifications(anchorItem); }
                        onClockRequested: function(anchorItem) { bar.showClock(anchorItem); }
                        onControlsRequested: function(anchorItem) { bar.showControls(anchorItem); }
                        onModuleDetailsRequested: function(moduleName, anchorItem) { bar.showModuleDetails(moduleName, anchorItem); }
                    }

                    ModuleStrip {
                        id: solidRight

                        theme: bar.theme
                        settings: bar.settings
                        appContext: bar.appContext
                        compositor: bar.compositor
                        panelWindow: bar
                        osd: osdLoader.item
                        tooltipHost: tooltipHostLoader.item
                        notificationCount: bar.notificationCount
                        notificationOpen: bar.notificationsOpen
                        modules: settings.rightModules
                        active: settings.barStyle === "solid" || solidSurface.opacity > 0
                        backgroundReady: bar.backgroundPhaseReady
                        interactionReady: bar.interactionPhaseReady
                        settingsOpen: bar.settingsOpen
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        onSettingsRequested: function(anchorItem) { bar.showSettings(anchorItem); }
                        onNotificationsRequested: function(anchorItem) { bar.showNotifications(anchorItem); }
                        onClockRequested: function(anchorItem) { bar.showClock(anchorItem); }
                        onControlsRequested: function(anchorItem) { bar.showControls(anchorItem); }
                        onModuleDetailsRequested: function(moduleName, anchorItem) { bar.showModuleDetails(moduleName, anchorItem); }
                    }
                }
            }

            Surface {
                id: pillSurface

                visible: settings.barStyle === "pill" || opacity > 0
                opacity: settings.barStyle === "pill" ? 1 : 0
                width: Math.min(parent.width, pillStrip.implicitWidth + settings.effectiveGroupPadding * 2)
                height: settings.barHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                theme: bar.theme
                settings: bar.settings
                surfaceColor: theme.alpha(theme.surface, settings.barOpacity)
                outlineColor: settings.barBorderEnabled ? theme.border : theme.transparent
                outlineWidth: settings.barBorderEnabled ? settings.barBorderThickness : 0
                surfaceRadius: Math.min(Math.round(settings.effectiveRadiusXL), Math.floor(settings.barHeight / 2))
                clip: true

                Behavior on opacity {
                    NumberAnimation { duration: settings.motionNormal; easing.type: pillSurface.opacity > 0 ? Easing.OutCubic : Easing.InCubic }
                }

                Behavior on width {
                    enabled: settings.motionNormal > 0
                    SpringAnimation { spring: 4.0; damping: 0.82; epsilon: 0.2 }
                }

                ModuleStrip {
                    id: pillStrip

                    theme: bar.theme
                    settings: bar.settings
                    appContext: bar.appContext
                    compositor: bar.compositor
                    panelWindow: bar
                    osd: osdLoader.item
                    tooltipHost: tooltipHostLoader.item
                    notificationCount: bar.notificationCount
                    notificationOpen: bar.notificationsOpen
                    modules: bar.combinedModules()
                    active: settings.barStyle === "pill" || pillSurface.opacity > 0
                    backgroundReady: bar.backgroundPhaseReady
                    interactionReady: bar.interactionPhaseReady
                    settingsOpen: bar.settingsOpen
                    anchors.centerIn: parent
                    onSettingsRequested: function(anchorItem) { bar.showSettings(anchorItem); }
                    onNotificationsRequested: function(anchorItem) { bar.showNotifications(anchorItem); }
                    onClockRequested: function(anchorItem) { bar.showClock(anchorItem); }
                    onControlsRequested: function(anchorItem) { bar.showControls(anchorItem); }
                    onModuleDetailsRequested: function(moduleName, anchorItem) { bar.showModuleDetails(moduleName, anchorItem); }
                }
            }
        }
    }

    HoverHandler {
        onHoveredChanged: bar.barHovered = hovered
    }

    Loader {
        id: clockPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            ClockPanel {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: dashboardPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            DashboardPanel {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
                systemStatsService: bar.appContext.systemStatsService
                networkService: bar.appContext.networkService
                batteryService: bar.appContext.batteryService
                mediaService: bar.appContext.mediaService
                onProcessesRequested: function(anchorItem) { bar.showProcessList(anchorItem); }
            }
        }
    }

    Loader {
        id: notepadPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            NotepadPanel {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: clipboardPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            ClipboardPanel {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: processPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            ProcessPanel {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: notificationPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            NotificationPanel {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
                notifications: bar.trackedNotifications
            }
        }
    }

    Loader {
        id: launcherPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            LauncherPanel {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: moduleDetailsPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            ModuleDetailsPanel {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
                systemStatsService: bar.appContext.systemStatsService
                networkService: bar.appContext.networkService
                batteryService: bar.appContext.batteryService
                mediaService: bar.appContext.mediaService
                powerProfileService: bar.appContext.powerProfileService
            }
        }
    }

    Loader {
        id: osdLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            Osd {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: workspaceToastLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            WorkspaceToast {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: tooltipHostLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            TooltipHost {
                theme: bar.theme
                settings: bar.settings
                panelWindow: bar
            }
        }
    }

    Timer {
        id: backgroundPhaseTimer

        interval: 300
        running: true
        repeat: false
        onTriggered: bar.backgroundPhaseReady = true
    }

    Timer {
        id: interactionPhaseTimer

        interval: 600
        running: true
        repeat: false
        onTriggered: bar.interactionPhaseReady = true
    }

    Connections {
        target: compositor
        function onWorkspacesChanged() { bar.updateWorkspaceToast(); }
    }

    Component.onCompleted: {
        updateWorkspaceToast();
        startupComplete = true;
    }

    component PanelAdapter: QtObject {
        id: adapter

        required property string panelId
        required property var coordinator
        property var panel
        readonly property bool panelOpen: panel ? Boolean(panel.panelOpen || panel.visible) : false

        function openFromCoordinator(anchorItem, payload) {
            if (!panel)
                return false;
            const data = payload || {};
            if (panelId === "moduleDetails") {
                if (data.tabName)
                    panel.openTab(String(data.moduleName || ""), String(data.tabName), anchorItem);
                else
                    panel.open(String(data.moduleName || ""), anchorItem);
            } else if (panelId === "launcher" && data.query !== undefined) {
                panel.openQuery(String(data.query));
            } else {
                panel.open(anchorItem);
            }
            return true;
        }

        function closeFromCoordinator() {
            if (!panel || typeof panel.close !== "function")
                return false;
            panel.close();
            return true;
        }

        Component.onCompleted: coordinator.register(panelId, adapter)
        Component.onDestruction: coordinator.unregister(panelId, adapter)
    }

    component ModuleStrip: Row {
        id: strip

        property var theme
        property var settings
        property var appContext
        property var compositor
        property var panelWindow
        property var osd
        property var tooltipHost
        property int notificationCount: 0
        property bool notificationOpen: false
        property var modules: []
        property bool active: true
        property bool backgroundReady: true
        property bool interactionReady: true
        property bool settingsOpen: false
        readonly property var moduleList: Array.from(modules || [])

        signal settingsRequested(var anchorItem)
        signal notificationsRequested(var anchorItem)
        signal clockRequested(var anchorItem)
        signal controlsRequested(var anchorItem)
        signal moduleDetailsRequested(string moduleName, var anchorItem)

        width: implicitWidth
        height: implicitHeight
        spacing: settings.effectiveContentSpacing

        Behavior on width {
            enabled: settings && settings.motionNormal > 0
            SpringAnimation { spring: 4.0; damping: 0.82; epsilon: 0.2 }
        }

        Repeater {
            model: strip.moduleList.length

            ModuleHost {
                required property int index

                theme: strip.theme
                settings: strip.settings
                appContext: strip.appContext
                compositor: strip.compositor
                panelWindow: strip.panelWindow
                osd: strip.osd
                tooltipHost: strip.tooltipHost
                notificationCount: strip.notificationCount
                notificationOpen: strip.notificationOpen
                moduleName: String(strip.moduleList[index])
                active: strip.active
                backgroundReady: strip.backgroundReady
                interactionReady: strip.interactionReady
                settingsOpen: strip.settingsOpen
                onSettingsRequested: function(anchorItem) { strip.settingsRequested(anchorItem); }
                onNotificationsRequested: function(anchorItem) { strip.notificationsRequested(anchorItem); }
                onClockRequested: function(anchorItem) { strip.clockRequested(anchorItem); }
                onControlsRequested: function(anchorItem) { strip.controlsRequested(anchorItem); }
                onModuleDetailsRequested: function(moduleName, anchorItem) { strip.moduleDetailsRequested(moduleName, anchorItem); }
            }
        }
    }
}
