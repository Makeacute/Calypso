pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "settingsui" as SettingsUi
import "settingsui/controls" as Controls

FloatingWindow {
    id: root

    property var appContext: null
    property var settings: appContext ? appContext.settings : null
    property var theme: appContext ? appContext.theme : null
    property var registry: appContext ? appContext.moduleRegistry : settings && settings.registry ? settings.registry : null
    readonly property var appInfo: appContext ? appContext.appInfo : null
    property var targetScreen: null
    property string activePage: "overview"
    property string selectedModule: ""
    property string searchText: ""
    property var undoStack: []
    property var redoStack: []
    property int niriWindowId: -1
    property int niriLookupAttempts: 0
    property bool gainedWindowFocus: false
    readonly property bool compact: width < theme.settingsCompactBreakpoint
    readonly property bool storeHistoryAvailable: settings && typeof settings.undo === "function" && typeof settings.redo === "function" && optional(settings, "canUndo", undefined) !== undefined && optional(settings, "canRedo", undefined) !== undefined
    readonly property bool canUndo: storeHistoryAvailable ? Boolean(settings.canUndo) : undoStack.length > 0
    readonly property bool canRedo: storeHistoryAvailable ? Boolean(settings.canRedo) : redoStack.length > 0
    readonly property var navigation: [
        {
            "id": "overview",
            "label": "Overview",
            "icon": "󰕮"
        },
        {
            "id": "bar",
            "label": "Bar",
            "icon": "󰓶"
        },
        {
            "id": "modules",
            "label": "Modules",
            "icon": "󱂬"
        },
        {
            "id": "panels",
            "label": "Panels",
            "icon": "󰕰"
        },
        {
            "id": "personalization",
            "label": "Personalization",
            "icon": "󰸌"
        },
        {
            "id": "system",
            "label": "System",
            "icon": "󰒓"
        }
    ]
    readonly property var historyKeys: ["themeRecipe", "settingsPreset", "visualPreset", "barStyle", "barPosition", "barHeight", "screenMargin", "reserveSpace", "barAutohide", "barBlur", "barOpacity", "barBorderEnabled", "barBorderThickness", "widgetStyle", "groupPadding", "pillPadding", "groupSpacing", "itemSpacing", "surfaceStyle", "pillStyle", "hoverEffect", "spacingScale", "radiusScale", "fontFamilySans", "fontFamilyMono", "fontFamilyIcon", "fontSize", "iconSize", "animationProfile", "animationBaseMs", "reduceMotion", "performanceMode", "osdEnabled", "osdPosition", "osdStyle", "osdTimeout", "osdSize", "osdOpacity", "osdShowIcon", "osdShowPercent", "dashboardPanelWidth", "dashboardShowMedia", "dashboardShowWeather", "dashboardGrowFromTrigger", "notificationsPanelWidth", "notificationsMaxVisible", "notificationsGroupByApp", "notificationsGroupsExpanded", "notificationsShowBody", "notificationsShowImages", "notificationsShowActions", "launcherPanelWidth", "launcherMaxResults", "launcherSearchPlaceholder", "launcherUseFuzzy", "launcherSortMode", "launcherShowIcons", "launcherShowDescriptions", "launcherCompactRows", "launcherVimKeybinds", "launcherCloseOnLaunch", "notepadPanelWidth", "notepadFilePath", "notepadAutosaveMs", "clipboardPanelWidth", "clipboardBackend", "clipboardMaxItems", "processPanelWidth", "processListLimit", "paletteSource", "manualAccent", "wallpaperDirectory", "wallpaperRecursive", "wallpaperBackend", "wallpaperResizeMode", "wallpaperCropGravity", "wallpaperApplyColors", "matugenEnabled", "matugenMode", "matugenScheme", "tooltipsEnabled", "tooltipDelay", "workspaceToastTimeout", "modulePopupPinned", "modulePopupDefaultTab", "modulePopupShowGauge", "modulePopupShowSparkline", "modulePopupHistorySamples", "modulePopupNetworkScaleKib", "compositorBackend", "clockFormat", "clockShowSeconds", "calendarWeekStart", "audioShowPercentage", "audioShowDeviceName", "networkInterfaceName", "networkShowSpeed", "batteryShowPercentage", "batteryCriticalThreshold", "cpuShowGraph", "memoryShowGraph", "brightnessShowPercentage", "brightnessStep", "powerProfileShowLabel", "mediaShowControls", "mediaMaxWidth", "mediaMaxTitleLength", "trayMaxVisible", "trayCompact", "trayIconSize", "focusedWindowDisplayMode", "focusedWindowMaxWidth", "focusedWindowShowTitle", "workspaceIndicatorStyle", "workspaceShowNumbers", "workspaceShowOccupied", "workspaceShowAppIcons", "workspaceMaxAppIcons", "workspaceScrollEnabled", "workspaceScrollWrap"]
    readonly property var searchResults: descriptorService.search(searchText, registry)

    visible: false
    title: "Calypso Settings"
    screen: targetScreen
    parentWindow: appContext ? appContext.lastInvokingBar : null
    implicitWidth: theme.settingsWindowWidth
    implicitHeight: theme.settingsWindowHeight
    minimumSize: Qt.size(theme.settingsWindowMinWidth, theme.settingsWindowMinHeight)
    color: theme.transparent

    function validPage(page) {
        const requested = String(page || "overview").toLowerCase();
        for (let i = 0; i < navigation.length; i++) {
            if (navigation[i].id === requested)
                return requested;
        }
        return "overview";
    }

    function openFor(screen, page) {
        targetScreen = screen || targetScreen;
        activePage = validPage(page);
        if (activePage !== "modules")
            selectedModule = "";
        searchText = "";
        niriLookupAttempts = 0;
        gainedWindowFocus = false;
        visible = true;
        niriLookupDelay.restart();
        content.forceActiveFocus();
        configurePage();
    }

    function openModuleFor(screen, moduleName) {
        selectedModule = registry && typeof registry.canonicalId === "function" ? registry.canonicalId(moduleName) : String(moduleName || "");
        openFor(screen, "modules");
        selectedModule = registry && typeof registry.canonicalId === "function" ? registry.canonicalId(moduleName) : String(moduleName || "");
        configurePage();
    }

    function toggleFor(screen, page) {
        const nextPage = validPage(page);
        if (visible && targetScreen === screen && activePage === nextPage) {
            close();
            return;
        }
        openFor(screen, nextPage);
    }

    function close() {
        searchText = "";
        visible = false;
        if (appContext && typeof appContext.releaseSettingsWindow === "function")
            appContext.releaseSettingsWindow();
    }

    function requestNiriFloating() {
        if (niriWindowLookup.running)
            return;
        niriLookupAttempts++;
        niriWindowLookup.running = true;
    }

    function showPage(page) {
        activePage = validPage(page);
        selectedModule = activePage === "modules" ? selectedModule : "";
        searchText = "";
        configurePage();
    }

    function pageSource(page) {
        if (page === "bar")
            return "settingsui/pages/BarPage.qml";
        if (page === "modules")
            return "settingsui/pages/ModulesPage.qml";
        if (page === "panels")
            return "settingsui/pages/PanelsPage.qml";
        if (page === "personalization")
            return "settingsui/pages/PersonalizationPage.qml";
        if (page === "system")
            return "settingsui/pages/SystemPage.qml";
        return "settingsui/pages/OverviewPage.qml";
    }

    function loadPage() {
        if (!pageLoader || !appContext || !settings || !theme)
            return;
        pageLoader.setSource(pageSource(activePage), {
            "appContext": appContext,
            "settings": settings,
            "theme": theme,
            "registry": registry,
            "targetScreen": targetScreen,
            "controller": root
        });
    }

    function configurePage() {
        const page = pageLoader.item;
        if (!page)
            return;
        page.appContext = appContext;
        page.settings = settings;
        page.theme = theme;
        page.registry = registry;
        page.targetScreen = targetScreen;
        page.controller = root;
    }

    onActivePageChanged: Qt.callLater(loadPage)
    onVisibleChanged: if (visible) Qt.callLater(requestNiriFloating)
    onBackingWindowVisibleChanged: if (backingWindowVisible) Qt.callLater(requestNiriFloating)
    Component.onCompleted: Qt.callLater(loadPage)

    Connections {
        target: content.Window.window
        ignoreUnknownSignals: true

        function onActiveChanged() {
            if (!target || !root.visible)
                return;
            if (target.active) {
                root.gainedWindowFocus = true;
                return;
            }
            if (root.gainedWindowFocus)
                root.close();
        }
    }

    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: root.visible
        context: Qt.WindowShortcut
        onActivated: root.close()
    }

    Process {
        id: niriWindowLookup

        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const windows = JSON.parse(text || "[]");
                    for (let i = 0; i < windows.length; i++) {
                        if (String(windows[i].title || "") === root.title) {
                            root.niriWindowId = Number(windows[i].id);
                            niriFloat.command = [
                                "niri", "msg", "action", "move-window-to-floating",
                                "--id", String(root.niriWindowId)
                            ];
                            niriFloat.running = true;
                            return;
                        }
                    }
                    if (root.niriLookupAttempts < 3)
                        niriLookupDelay.restart();
                } catch (error) {
                    console.warn("Unable to identify the Calypso settings window: " + error);
                }
            }
        }
    }

    Timer {
        id: niriLookupDelay

        interval: theme.motionFast
        repeat: false
        onTriggered: root.requestNiriFloating()
    }

    Process {
        id: niriFloat

        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode !== 0 || root.niriWindowId < 0)
                return;
            niriWidth.command = [
                "niri", "msg", "action", "set-window-width",
                "--id", String(root.niriWindowId), String(theme.settingsWindowWidth)
            ];
            niriWidth.running = true;
        }
    }

    Process {
        id: niriWidth

        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode !== 0 || root.niriWindowId < 0)
                return;
            niriHeight.command = [
                "niri", "msg", "action", "set-window-height",
                "--id", String(root.niriWindowId), String(theme.settingsWindowHeight)
            ];
            niriHeight.running = true;
        }
    }

    Process {
        id: niriHeight

        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode !== 0 || root.niriWindowId < 0)
                return;
            niriCenter.command = [
                "niri", "msg", "action", "center-window",
                "--id", String(root.niriWindowId)
            ];
            niriCenter.running = true;
        }
    }

    Process {
        id: niriCenter

        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    function optional(object, name, fallback) {
        if (!object)
            return fallback;
        try {
            const value = object[name];
            return value === undefined || value === null ? fallback : value;
        } catch (error) {
            return fallback;
        }
    }

    function saveStatus() {
        if (!settings)
            return "Unavailable";
        const state = String(optional(settings, "saveState", ""));
        if (state === "saved")
            return "Saved";
        if (state === "saving" || state === "pending")
            return "Saving";
        if (state === "loading")
            return "Loading";
        if (state === "error")
            return "Save error";
        if (state === "idle")
            return "Ready";

        const legacyStatus = String(optional(settings, "saveStatus", ""));
        if (legacyStatus.length > 0)
            return legacyStatus;
        if (optional(settings, "dirty", false))
            return "Saving";
        return "Saved automatically";
    }

    function clone(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function snapshot() {
        if (!settings)
            return null;
        const values = {};
        for (let i = 0; i < historyKeys.length; i++) {
            const key = historyKeys[i];
            const value = optional(settings, key, undefined);
            if (value !== undefined)
                values[key] = clone(value);
        }

        const visibility = {};
        const modules = settings.availableModules ? Array.from(settings.availableModules) : [];
        for (let moduleIndex = 0; moduleIndex < modules.length; moduleIndex++) {
            const moduleName = String(modules[moduleIndex]);
            visibility[moduleName] = settings.enabled(moduleName);
        }

        return {
            "values": values,
            "leftModules": clone(settings.sectionModules("left")),
            "centerModules": clone(settings.sectionModules("center")),
            "rightModules": clone(settings.sectionModules("right")),
            "visibility": visibility
        };
    }

    function restore(state) {
        if (!settings || !state)
            return;
        const keys = Object.keys(state.values || {});
        for (let i = 0; i < keys.length; i++)
            settings.setValue(keys[i], clone(state.values[keys[i]]));
        settings.setSectionModules("left", clone(state.leftModules || []));
        settings.setSectionModules("center", clone(state.centerModules || []));
        settings.setSectionModules("right", clone(state.rightModules || []));

        const moduleNames = Object.keys(state.visibility || {});
        for (let moduleIndex = 0; moduleIndex < moduleNames.length; moduleIndex++) {
            const moduleName = moduleNames[moduleIndex];
            settings.setModuleEnabled(moduleName, state.visibility[moduleName]);
        }
    }

    function performChange(label, operation) {
        if (!settings || typeof operation !== "function")
            return;

        if (storeHistoryAvailable) {
            const transactional = typeof settings.beginTransaction === "function" && typeof settings.endTransaction === "function";
            if (transactional)
                settings.beginTransaction(String(label || "Settings change"));
            try {
                operation();
            } finally {
                if (transactional)
                    settings.endTransaction();
            }
            return;
        }

        const before = snapshot();
        operation();
        const after = snapshot();
        if (JSON.stringify(before) === JSON.stringify(after))
            return;

        const nextUndo = Array.from(undoStack);
        nextUndo.push({
            "label": String(label || "Settings change"),
            "state": before
        });
        while (nextUndo.length > theme.settingsHistoryLimit)
            nextUndo.shift();
        undoStack = nextUndo;
        redoStack = [];
    }

    function undo() {
        if (storeHistoryAvailable) {
            settings.undo();
            return;
        }
        if (!canUndo)
            return;
        const current = snapshot();
        const nextUndo = Array.from(undoStack);
        const entry = nextUndo.pop();
        const nextRedo = Array.from(redoStack);
        nextRedo.push({
            "label": entry.label,
            "state": current
        });
        undoStack = nextUndo;
        redoStack = nextRedo;
        restore(entry.state);
    }

    function redo() {
        if (storeHistoryAvailable) {
            settings.redo();
            return;
        }
        if (!canRedo)
            return;
        const current = snapshot();
        const nextRedo = Array.from(redoStack);
        const entry = nextRedo.pop();
        const nextUndo = Array.from(undoStack);
        nextUndo.push({
            "label": entry.label,
            "state": current
        });
        redoStack = nextRedo;
        undoStack = nextUndo;
        restore(entry.state);
    }

    function activateSearchResult(entry) {
        if (!entry)
            return;
        if (entry.moduleName)
            openModuleFor(targetScreen, entry.moduleName);
        else
            showPage(entry.page);
    }

    SettingsUi.SettingDescriptors {
        id: descriptorService
    }

    Rectangle {
        id: content

        anchors.fill: parent
        radius: theme.radiusXL
        color: theme.base
        border.color: theme.outlineSubtle
        border.width: theme.settingsBorderWidth
        clip: true
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onPressed: function (event) {
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_F) {
                searchField.focusInput();
                event.accepted = true;
            } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_Z) {
                if (event.modifiers & Qt.ShiftModifier)
                    root.redo();
                else
                    root.undo();
                event.accepted = true;
            } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_Y) {
                root.redo();
                event.accepted = true;
            }
        }

        Column {
            anchors.fill: parent

            Item {
                id: header

                width: parent.width
                height: theme.settingsHeaderHeight

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: theme.spacingL
                    anchors.rightMargin: theme.spacingL
                    spacing: theme.spacingM

                    Row {
                        width: root.compact ? theme.settingsCompactIdentityWidth : theme.settingsIdentityWidth
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: theme.spacingS

                        Rectangle {
                            width: theme.settingsIdentityIconSize
                            height: width
                            radius: theme.radiusM
                            color: theme.surfaceActive
                            border.color: theme.outlineActive
                            border.width: theme.settingsBorderWidth

                            Text {
                                anchors.centerIn: parent
                                text: "󰣇"
                                color: theme.accent
                                font.family: settings.fontFamilyIcon
                                font.pixelSize: theme.settingsIconSize
                            }
                        }

                        Column {
                            width: parent.width - theme.settingsIdentityIconSize - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: theme.spacingXS

                            Text {
                                width: parent.width
                                text: (appInfo ? String(optional(appInfo, "name", "Calypso")) : "Calypso") + " Settings"
                                color: theme.text
                                elide: Text.ElideRight
                                font.family: settings.fontFamilySans
                                font.pixelSize: theme.settingsHeaderFontSize
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                visible: !root.compact
                                text: appInfo ? String(optional(appInfo, "releaseChannel", "Development")) : "Development"
                                color: theme.textMuted
                                font.family: settings.fontFamilySans
                                font.pixelSize: theme.settingsCaptionFontSize
                            }
                        }
                    }

                    Controls.SearchField {
                        id: searchField

                        width: Math.max(theme.settingsSearchMinWidth, parent.width - parent.spacing * theme.settingsHeaderSpacingCount - theme.settingsIdentityWidth - headerActions.width)
                        anchors.verticalCenter: parent.verticalCenter
                        theme: root.theme
                        settings: root.settings
                        text: root.searchText
                        onTextRequested: function (text) {
                            root.searchText = text;
                        }
                        onAccepted: {
                            if (root.searchResults.length > 0)
                                root.activateSearchResult(root.searchResults[0]);
                        }
                    }

                    Row {
                        id: headerActions

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: theme.spacingXS

                        Row {
                            visible: !root.compact
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: theme.spacingXS

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: theme.settingsStatusDotSize
                                height: width
                                radius: theme.settingsStatusDotRadius
                                color: settings ? theme.good : theme.warning
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.saveStatus()
                                color: theme.textMuted
                                font.family: settings.fontFamilySans
                                font.pixelSize: theme.settingsCaptionFontSize
                            }
                        }

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            tooltip: root.storeHistoryAvailable || root.undoStack.length === 0 ? "Undo" : "Undo " + root.undoStack[root.undoStack.length - 1].label
                            enabled: root.canUndo
                            onPressed: root.undo()
                        }

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            tooltip: root.storeHistoryAvailable || root.redoStack.length === 0 ? "Redo" : "Redo " + root.redoStack[root.redoStack.length - 1].label
                            enabled: root.canRedo
                            onPressed: root.redo()
                        }

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            tooltip: "Close"
                            onPressed: root.close()
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: theme.settingsBorderWidth
                    color: theme.outlineSubtle
                }
            }

            Item {
                width: parent.width
                height: parent.height - header.height

                Row {
                    anchors.fill: parent

                    Item {
                        id: sidebar

                        visible: !root.compact
                        width: visible ? theme.settingsSidebarWidth + theme.spacingL * theme.settingsSidebarPaddingFactor : 0
                        height: parent.height

                        Column {
                            anchors.fill: parent
                            anchors.margins: theme.spacingL
                            spacing: theme.spacingXS

                            Repeater {
                                model: root.navigation

                                Controls.NavButton {
                                    required property var modelData

                                    width: parent.width
                                    theme: root.theme
                                    settings: root.settings
                                    icon: String(modelData.icon)
                                    label: String(modelData.label)
                                    selected: root.activePage === String(modelData.id)
                                    onPressed: root.showPage(String(modelData.id))
                                }
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            width: theme.settingsBorderWidth
                            color: theme.outlineSubtle
                        }
                    }

                    Column {
                        width: parent.width - sidebar.width
                        height: parent.height

                        Flickable {
                            visible: root.compact
                            width: parent.width
                            height: visible ? theme.settingsCompactNavHeight : 0
                            contentWidth: compactNav.implicitWidth + theme.spacingL * theme.settingsCompactNavPaddingFactor
                            contentHeight: height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Row {
                                id: compactNav

                                x: theme.spacingL
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: theme.spacingXS

                                Repeater {
                                    model: root.navigation

                                    Controls.NavButton {
                                        required property var modelData

                                        compact: true
                                        theme: root.theme
                                        settings: root.settings
                                        icon: String(modelData.icon)
                                        label: String(modelData.label)
                                        selected: root.activePage === String(modelData.id)
                                        onPressed: root.showPage(String(modelData.id))
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: root.compact
                            width: parent.width
                            height: visible ? theme.settingsBorderWidth : 0
                            color: theme.outlineSubtle
                        }

                        Loader {
                            id: pageLoader

                            width: parent.width
                            height: parent.height - (root.compact ? theme.settingsCompactNavHeight + theme.settingsBorderWidth : 0)
                            onLoaded: root.configurePage()
                        }
                    }
                }
            }
        }

        Rectangle {
            z: theme.settingsOverlayZ
            visible: root.searchText.trim().length > 0
            x: searchField.mapToItem(content, 0, 0).x + (searchField.width - width) / 2
            y: header.height
            width: Math.min(theme.settingsSearchResultsWidth, content.width - theme.spacingL * theme.settingsSearchEdgeFactor)
            height: Math.min(resultsColumn.implicitHeight + theme.spacingM, theme.settingsSearchResultsMaxHeight)
            radius: theme.radiusM
            color: theme.surfaceStrong
            border.color: theme.outlineActive
            border.width: theme.settingsBorderWidth
            clip: true

            Flickable {
                anchors.fill: parent
                anchors.margins: theme.spacingS
                contentWidth: width
                contentHeight: resultsColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: resultsColumn

                    width: parent.width
                    spacing: theme.spacingXS

                    Text {
                        width: parent.width
                        visible: root.searchResults.length === 0
                        text: "No matching settings"
                        color: theme.textMuted
                        horizontalAlignment: Text.AlignHCenter
                        font.family: settings.fontFamilySans
                        font.pixelSize: theme.settingsBodyFontSize
                    }

                    Repeater {
                        model: root.searchResults.slice(0, theme.settingsSearchMaxResults)

                        Rectangle {
                            id: resultRow

                            required property var modelData

                            width: resultsColumn.width
                            height: theme.settingsSearchResultHeight
                            radius: theme.radiusS
                            color: resultPointer.containsMouse ? theme.surfaceHover : theme.transparent

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: theme.spacingM
                                anchors.rightMargin: theme.spacingM
                                spacing: theme.spacingM

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: String(resultRow.modelData.icon)
                                    color: theme.accent
                                    font.family: settings.fontFamilyIcon
                                    font.pixelSize: theme.settingsIconSize
                                }

                                Column {
                                    width: parent.width - parent.spacing - theme.settingsIconSize
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: theme.spacingXS

                                    Text {
                                        width: parent.width
                                        text: String(resultRow.modelData.title)
                                        color: theme.text
                                        elide: Text.ElideRight
                                        font.family: settings.fontFamilySans
                                        font.pixelSize: theme.settingsBodyFontSize
                                    }

                                    Text {
                                        width: parent.width
                                        text: String(resultRow.modelData.description)
                                        color: theme.textMuted
                                        elide: Text.ElideRight
                                        font.family: settings.fontFamilySans
                                        font.pixelSize: theme.settingsCaptionFontSize
                                    }
                                }
                            }

                            MouseArea {
                                id: resultPointer

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activateSearchResult(resultRow.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
