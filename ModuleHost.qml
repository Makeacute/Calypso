pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property var theme
    property var settings
    property var appContext
    property var compositor
    property var panelWindow
    property var osd
    property var tooltipHost
    property int notificationCount: 0
    property bool notificationOpen: false
    property string moduleName: ""
    property bool active: true
    property bool backgroundReady: true
    property bool interactionReady: true
    property bool settingsOpen: false
    readonly property string moduleType: settings ? settings.moduleId(moduleName) : moduleName
    readonly property var moduleSettings: settings && typeof settings.instanceSettings === "function"
                                                  ? settings.instanceSettings(moduleName) || ({})
                                                  : ({})
    readonly property url moduleSource: settings && settings.registry
                                                ? settings.registry.sourceUrl(moduleType)
                                                : ""
    readonly property bool moduleEnabled: active && phaseReady(moduleName) && moduleSource.toString().length > 0 && settings && settings.enabled(moduleName)
    readonly property real loadedWidth: itemWidth()
    readonly property real loadedHeight: itemHeight()
    readonly property bool moduleVisible: moduleEnabled && loader.status === Loader.Ready && loadedWidth > 0 && loadedHeight > 0

    signal settingsRequested(var anchorItem)
    signal notificationsRequested(var anchorItem)
    signal clockRequested(var anchorItem)
    signal controlsRequested(var anchorItem)
    signal moduleDetailsRequested(string moduleName, var anchorItem)

    visible: moduleVisible
    width: moduleVisible ? loadedWidth : 0
    height: moduleVisible ? loadedHeight : 0
    implicitWidth: width
    implicitHeight: height
    clip: true

    Behavior on height {
        enabled: settings && settings.motionNormal > 0
        NumberAnimation { duration: settings.motionNormal; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
        NumberAnimation { duration: settings ? settings.motionNormal : 0; easing.type: Easing.OutCubic }
    }

    Loader {
        id: loader

        anchors.centerIn: parent
        active: root.moduleEnabled
        onLoaded: root.applyInjectedProperties()
    }

    Binding {
        target: loader.item
        property: "systemStatsService"
        value: root.appContext ? root.appContext.systemStatsService : null
        when: loader.item && (root.moduleType === "cpu" || root.moduleType === "memory")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: loader.item
        property: "networkService"
        value: root.appContext ? root.appContext.networkService : null
        when: loader.item && root.moduleType === "network"
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: loader.item
        property: "batteryService"
        value: root.appContext ? root.appContext.batteryService : null
        when: loader.item && root.moduleType === "battery"
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: loader.item
        property: "mediaService"
        value: root.appContext ? root.appContext.mediaService : null
        when: loader.item && root.moduleType === "media"
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: loader.item
        property: "powerProfileService"
        value: root.appContext ? root.appContext.powerProfileService : null
        when: loader.item && root.moduleType === "powerProfile"
        restoreMode: Binding.RestoreBindingOrValue
    }

    Connections {
        target: loader.item
        ignoreUnknownSignals: true

        function onDetailsRequested(anchorItem, requestedModule) {
            root.moduleDetailsRequested(String(requestedModule || root.moduleType), anchorItem);
        }

        function onRequested(anchorItem) {
            if (root.moduleType === "clock")
                root.clockRequested(anchorItem);
            else if (root.moduleType === "dashboard")
                root.controlsRequested(anchorItem);
            else if (root.moduleType === "settings")
                root.settingsRequested(anchorItem);
        }

        function onNotificationsRequested(anchorItem) {
            root.notificationsRequested(anchorItem);
        }

        function onTriggerRequested(panelId, anchorItem) {
            root.moduleDetailsRequested(String(panelId || root.moduleType), anchorItem);
        }
    }

    function setItemProperty(name, value) {
        const item = loader.item;
        if (!item)
            return;
        try {
            item[name] = value;
        } catch (error) {
            console.warn("Unable to inject " + name + " into " + moduleType + ": " + error);
        }
    }

    function initialProperties() {
        const values = {
            "theme": theme,
            "settings": settings,
            "systemStatsService": appContext ? appContext.systemStatsService : null,
            "networkService": appContext ? appContext.networkService : null,
            "batteryService": appContext ? appContext.batteryService : null,
            "mediaService": appContext ? appContext.mediaService : null,
            "powerProfileService": appContext ? appContext.powerProfileService : null,
            "moduleInstanceId": moduleName,
            "moduleSettings": moduleSettings,
            "compositor": compositor,
            "panelWindow": panelWindow,
            "osd": osd,
            "tooltipHost": tooltipHost,
            "settingsOpen": settingsOpen,
            "notificationOpen": notificationOpen,
            "notificationCount": notificationCount
        };
        const result = {};
        const names = settings && settings.registry ? settings.registry.injectionNames(moduleType) : [];
        for (let i = 0; i < names.length; i++)
            result[names[i]] = values[names[i]];
        return result;
    }

    function configureSource() {
        if (moduleSource.toString().length > 0)
            loader.setSource(moduleSource, initialProperties());
        else
            loader.source = "";
    }

    function applyInjectedProperties() {
        const values = initialProperties();
        const names = Object.keys(values);
        for (let i = 0; i < names.length; i++)
            setItemProperty(names[i], values[names[i]]);
    }

    Component.onCompleted: configureSource()
    onModuleSourceChanged: configureSource()
    onThemeChanged: applyInjectedProperties()
    onSettingsChanged: applyInjectedProperties()
    onAppContextChanged: applyInjectedProperties()
    onModuleSettingsChanged: applyInjectedProperties()
    onCompositorChanged: applyInjectedProperties()
    onPanelWindowChanged: applyInjectedProperties()
    onOsdChanged: applyInjectedProperties()
    onTooltipHostChanged: applyInjectedProperties()
    onSettingsOpenChanged: applyInjectedProperties()
    onNotificationOpenChanged: applyInjectedProperties()
    onNotificationCountChanged: applyInjectedProperties()

    function itemWidth() {
        const item = loader.item;
        if (!item) return 0;
        return item.width > 0 ? item.width : Math.max(0, item.implicitWidth);
    }

    function itemHeight() {
        const item = loader.item;
        return item ? Math.max(item.implicitHeight, item.height) : 0;
    }

    function loadPhase(name) {
        if (settings && settings.registry)
            return settings.registry.loadPhase(name);
        if (name === "workspaces" || name === "focusedWindow" || name === "clock" || name === "time")
            return 1;
        if (name === "settings" || name === "controls" || name === "controlCenter" || name === "quickControls" || name === "dashboard"
                || name === "launcher" || name === "apps" || name === "appLauncher"
                || name === "notepad" || name === "scratchpad" || name === "notes"
                || name === "clipboard" || name === "cliphist" || name === "clip"
                || name === "processes" || name === "processList" || name === "tasks")
            return 3;
        return 2;
    }

    function phaseReady(name) {
        const phase = loadPhase(name);
        if (phase <= 1) return true;
        if (phase === 2) return backgroundReady;
        return interactionReady;
    }

}
