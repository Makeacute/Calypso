pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import "services"
import "widgets"

PanelWindow {
    id: bar

    required property var modelData
    readonly property bool settingsOpen: settingsPanelLoader.item ? settingsPanelLoader.item.visible : false
    readonly property bool notificationsOpen: notificationPanelLoader.item ? notificationPanelLoader.item.visible : false
    readonly property bool anyPanelOpen: panelIsOpen(settingsPanelLoader)
                                      || panelIsOpen(clockPanelLoader)
                                      || panelIsOpen(dashboardPanelLoader)
                                      || panelIsOpen(moduleDetailsPanelLoader)
                                      || panelIsOpen(notepadPanelLoader)
                                      || panelIsOpen(clipboardPanelLoader)
                                      || panelIsOpen(processPanelLoader)
                                      || panelIsOpen(notificationPanelLoader)
                                      || panelIsOpen(launcherPanelLoader)
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

    function combinedModules() {
        return Array.from(settings.leftModules || [])
                    .concat(Array.from(settings.centerModules || []))
                    .concat(Array.from(settings.rightModules || []));
    }

    function ensureInteractionPhase() {
        interactionPhaseReady = true;
    }

    function closeLoadedPanel(loader) {
        const item = loader.item;
        if (item && typeof item.close === "function")
            item.close();
    }

    function panelIsOpen(loader) {
        const item = loader.item;
        return item && (item.panelOpen || item.visible);
    }

    function closeAllPanels() {
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeToolPanels();
    }

    function closeToolPanels() {
        closeLoadedPanel(notepadPanelLoader);
        closeLoadedPanel(clipboardPanelLoader);
        closeLoadedPanel(processPanelLoader);
        closeLoadedPanel(notificationPanelLoader);
        closeLoadedPanel(launcherPanelLoader);
    }

    function showSettings(anchorItem) {
        ensureInteractionPhase();
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeToolPanels();
        if (settingsPanelLoader.item)
            settingsPanelLoader.item.toggle(anchorItem);
    }

    function showNotifications(anchorItem) {
        ensureInteractionPhase();
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeLoadedPanel(notepadPanelLoader);
        closeLoadedPanel(clipboardPanelLoader);
        closeLoadedPanel(processPanelLoader);
        closeLoadedPanel(launcherPanelLoader);
        if (notificationPanelLoader.item)
            notificationPanelLoader.item.toggle(anchorItem);
    }

    function showClock(anchorItem) {
        ensureInteractionPhase();
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeToolPanels();
        if (clockPanelLoader.item)
            clockPanelLoader.item.toggle(anchorItem);
    }

    function showControls(anchorItem) {
        ensureInteractionPhase();
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeToolPanels();
        if (dashboardPanelLoader.item)
            dashboardPanelLoader.item.toggle(anchorItem);
    }

    function showNotepad(anchorItem) {
        ensureInteractionPhase();
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeLoadedPanel(notificationPanelLoader);
        closeLoadedPanel(launcherPanelLoader);
        closeLoadedPanel(clipboardPanelLoader);
        closeLoadedPanel(processPanelLoader);
        if (notepadPanelLoader.item)
            notepadPanelLoader.item.toggle(anchorItem);
    }

    function showClipboard(anchorItem) {
        ensureInteractionPhase();
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeLoadedPanel(notificationPanelLoader);
        closeLoadedPanel(launcherPanelLoader);
        closeLoadedPanel(notepadPanelLoader);
        closeLoadedPanel(processPanelLoader);
        if (clipboardPanelLoader.item)
            clipboardPanelLoader.item.toggle(anchorItem);
    }

    function showProcessList(anchorItem) {
        ensureInteractionPhase();
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeLoadedPanel(notificationPanelLoader);
        closeLoadedPanel(launcherPanelLoader);
        closeLoadedPanel(notepadPanelLoader);
        closeLoadedPanel(clipboardPanelLoader);
        if (processPanelLoader.item)
            processPanelLoader.item.toggle(anchorItem);
        closeLoadedPanel(dashboardPanelLoader);
    }

    function showLauncher(anchorItem) {
        ensureInteractionPhase();
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeLoadedPanel(notepadPanelLoader);
        closeLoadedPanel(clipboardPanelLoader);
        closeLoadedPanel(processPanelLoader);
        closeLoadedPanel(notificationPanelLoader);
        if (launcherPanelLoader.item)
            launcherPanelLoader.item.toggle(anchorItem);
    }

    function showLauncherQuery(query) {
        ensureInteractionPhase();
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeLoadedPanel(notepadPanelLoader);
        closeLoadedPanel(clipboardPanelLoader);
        closeLoadedPanel(processPanelLoader);
        closeLoadedPanel(notificationPanelLoader);
        if (launcherPanelLoader.item)
            launcherPanelLoader.item.openQuery(query);
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

        ensureInteractionPhase();
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeToolPanels();
        if (moduleDetailsPanelLoader.item)
            moduleDetailsPanelLoader.item.toggle(moduleName, anchorItem);
    }

    function openSettingsPage(page) {
        ensureInteractionPhase();
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeLoadedPanel(moduleDetailsPanelLoader);
        closeToolPanels();
        if (settingsPanelLoader.item)
            settingsPanelLoader.item.openPage(page);
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

        ensureInteractionPhase();
        closeLoadedPanel(settingsPanelLoader);
        closeLoadedPanel(clockPanelLoader);
        closeLoadedPanel(dashboardPanelLoader);
        closeToolPanels();
        if (moduleDetailsPanelLoader.item)
            moduleDetailsPanelLoader.item.open(moduleName, null);
    }

    IpcHandler {
        target: "calypso"

        function openSettings(): void {
            bar.openSettingsPage("overview");
        }

        function closeSettings(): void {
            bar.closeLoadedPanel(settingsPanelLoader);
        }

        function openNotifications(): void {
            bar.showNotifications(null);
        }

        function closeNotifications(): void {
            bar.closeLoadedPanel(notificationPanelLoader);
        }

        function openClock(): void {
            bar.showClock(null);
        }

        function closeClock(): void {
            bar.closeLoadedPanel(clockPanelLoader);
        }

        function openControls(): void {
            bar.showControls(null);
        }

        function closeControls(): void {
            bar.closeLoadedPanel(dashboardPanelLoader);
        }

        function openDashboard(): void {
            bar.showControls(null);
        }

        function closeDashboard(): void {
            bar.closeLoadedPanel(dashboardPanelLoader);
        }

        function openNotepad(): void {
            bar.showNotepad(null);
        }

        function closeNotepad(): void {
            bar.closeLoadedPanel(notepadPanelLoader);
        }

        function openClipboard(): void {
            bar.showClipboard(null);
        }

        function closeClipboard(): void {
            bar.closeLoadedPanel(clipboardPanelLoader);
        }

        function openProcesses(): void {
            bar.showProcessList(null);
        }

        function closeProcesses(): void {
            bar.closeLoadedPanel(processPanelLoader);
        }

        function openLauncher(): void {
            bar.showLauncher(null);
        }

        function openLauncherQuery(query: string): void {
            bar.showLauncherQuery(query);
        }

        function closeLauncher(): void {
            bar.closeLoadedPanel(launcherPanelLoader);
        }

        function openSettingsPage(page: string): void {
            bar.openSettingsPage(page);
        }

        function openSettingsDetail(moduleName: string): void {
            bar.ensureInteractionPhase();
            bar.closeLoadedPanel(clockPanelLoader);
            bar.closeLoadedPanel(dashboardPanelLoader);
            bar.closeLoadedPanel(moduleDetailsPanelLoader);
            bar.closeToolPanels();
            if (settingsPanelLoader.item)
                settingsPanelLoader.item.openModuleOptions(moduleName);
        }

        function showOsd(kind: string, value: real): void {
            bar.ensureInteractionPhase();
            const type = String(kind || "volume");
            const allowed = ["volume", "mute", "brightness", "keyboard", "capsLock", "numLock", "media", "battery"];
            if (allowed.indexOf(type) < 0) return;
            const amount = Math.max(0, Math.min(1, Number(value) || 0.72));
            const icon = type === "brightness" ? "󰃠" : type === "keyboard" ? "󰌌" : type === "capsLock" ? "󰘲" : type === "numLock" ? "󰎠" : type === "media" ? "󰝚" : type === "battery" ? "󰁹" : "󰕾";
            if (osdLoader.item)
                osdLoader.item.show(icon, amount, type, type.charAt(0).toUpperCase() + type.slice(1));
        }

        function showTooltip(text: string): void {
            bar.ensureInteractionPhase();
            if (tooltipHostLoader.item)
                tooltipHostLoader.item.show(text, null);
        }

        function hideTooltip(): void {
            if (tooltipHostLoader.item)
                tooltipHostLoader.item.hide();
        }

        function openModule(moduleName: string): void {
            bar.openModuleDetails(moduleName);
        }

        function openModuleTab(moduleName: string, tabName: string): void {
            bar.ensureInteractionPhase();
            bar.closeLoadedPanel(settingsPanelLoader);
            bar.closeLoadedPanel(clockPanelLoader);
            bar.closeLoadedPanel(dashboardPanelLoader);
            bar.closeToolPanels();
            if (moduleDetailsPanelLoader.item)
                moduleDetailsPanelLoader.item.openTab(moduleName, tabName, null);
        }

        function closeModule(): void {
            bar.closeLoadedPanel(moduleDetailsPanelLoader);
        }

        function randomWallpaper(): void {
            bar.ensureInteractionPhase();
            if (settingsPanelLoader.item)
                settingsPanelLoader.item.applyRandomWallpaper();
        }

        function previewWallpaper(path: string): void {
            bar.ensureInteractionPhase();
            if (settingsPanelLoader.item)
                settingsPanelLoader.item.openWallpaperPreview(path);
        }

        function applyWallpaper(path: string): void {
            bar.ensureInteractionPhase();
            if (settingsPanelLoader.item)
                settingsPanelLoader.item.applyWallpaperPath(path);
        }

        function setBarStyle(value: string): void {
            settings.setEnum("barStyle", value, ["islands", "solid", "pill"], "islands");
        }

        function setBarPosition(value: string): void {
            settings.setEnum("barPosition", value, ["top", "bottom"], "top");
        }

        function setWidgetStyle(value: string): void {
            settings.setEnum("widgetStyle", value, ["iconOnly", "iconAndText", "expanded"], "iconAndText");
        }

        function setBarHeight(value: int): void {
            settings.setNumber("barHeight", value, 24, 56);
        }

        function setSettingsWidth(value: int): void {
            settings.setNumber("settingsPanelWidth", value, 640, 960);
        }

        function setSettingsDensity(value: string): void {
            settings.setSettingsPanelDensity(value);
        }

        function setSettingsAnchor(value: string): void {
            settings.setEnum("settingsPanelAnchor", value, ["button", "left", "center", "right"], "button");
        }

        function setThemeRecipe(value: string): void {
            settings.setThemeRecipe(value);
        }

        function setSpacingScale(value: real): void {
            settings.setReal("spacingScale", value, 0.5, 2.0, 0.1);
        }

        function setReduceMotion(value: bool): void {
            settings.setReduceMotion(value);
        }

        function setModuleEnabled(moduleName: string, value: bool): void {
            settings.setModuleEnabled(moduleName, value);
        }

        function setSectionModules(section: string, modulesCsv: string): void {
            const modules = String(modulesCsv || "")
                .split(",")
                .map(item => item.trim())
                .filter(item => item.length > 0);
            settings.setSectionModules(section, modules);
        }
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

    Settings {
        id: settings
    }

    Theme {
        id: theme

        settings: settings
    }

    CompositorService {
        id: compositor

        settings: settings
    }

    NotificationServer {
        id: notificationServer

        keepOnReload: true
        persistenceSupported: true
        bodySupported: settings.notificationsShowBody
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: settings.notificationsShowImages
        actionsSupported: settings.notificationsShowActions
        actionIconsSupported: false
        imageSupported: settings.notificationsShowImages

        onNotification: function(notification) {
            if (notification && !notification.transient)
                notification.tracked = true;
        }
    }

    screen: modelData
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
    color: "transparent"

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

                theme: theme
                settings: settings
                compositor: compositor
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

                theme: theme
                settings: settings
                compositor: compositor
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

                theme: theme
                settings: settings
                compositor: compositor
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
                theme: theme
                settings: settings
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

                        theme: theme
                        settings: settings
                        compositor: compositor
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

                        theme: theme
                        settings: settings
                        compositor: compositor
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

                        theme: theme
                        settings: settings
                        compositor: compositor
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
                theme: theme
                settings: settings
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

                    theme: theme
                    settings: settings
                    compositor: compositor
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
        id: settingsPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            SettingsPanel {
                theme: theme
                settings: settings
                panelWindow: bar
                osd: osdLoader.item
            }
        }
    }

    Loader {
        id: clockPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            ClockPanel {
                theme: theme
                settings: settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: dashboardPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            DashboardPanel {
                theme: theme
                settings: settings
                panelWindow: bar
                onProcessesRequested: function(anchorItem) { bar.showProcessList(anchorItem); }
            }
        }
    }

    Loader {
        id: notepadPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            NotepadPanel {
                theme: theme
                settings: settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: clipboardPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            ClipboardPanel {
                theme: theme
                settings: settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: processPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            ProcessPanel {
                theme: theme
                settings: settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: notificationPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            NotificationPanel {
                theme: theme
                settings: settings
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
                theme: theme
                settings: settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: moduleDetailsPanelLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            ModuleDetailsPanel {
                theme: theme
                settings: settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: osdLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            Osd {
                theme: theme
                settings: settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: workspaceToastLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            WorkspaceToast {
                theme: theme
                settings: settings
                panelWindow: bar
            }
        }
    }

    Loader {
        id: tooltipHostLoader

        active: bar.interactionPhaseReady
        sourceComponent: Component {
            TooltipHost {
                theme: theme
                settings: settings
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

    component ModuleStrip: Row {
        id: strip

        property var theme
        property var settings
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
