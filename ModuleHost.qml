pragma ComponentBehavior: Bound

import QtQuick
import "widgets"

Item {
    id: root

    property var theme
    property var settings
    property var compositor
    property var panelWindow
    property var osd
    property var tooltipHost
    property string moduleName: ""
    property bool active: true
    property bool backgroundReady: true
    property bool interactionReady: true
    property bool settingsOpen: false
    readonly property Component selectedComponent: componentFor(moduleName)
    readonly property bool moduleEnabled: active && phaseReady(moduleName) && selectedComponent !== null && settings && settings.enabled(moduleName)
    readonly property real loadedWidth: itemWidth()
    readonly property real loadedHeight: itemHeight()
    readonly property bool moduleVisible: moduleEnabled && loader.status === Loader.Ready && loadedWidth > 0 && loadedHeight > 0

    signal settingsRequested(var anchorItem)
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
        sourceComponent: root.selectedComponent
    }

    function itemWidth() {
        const item = loader.item;
        if (!item) return 0;
        return item.width > 0 ? item.width : Math.max(0, item.implicitWidth);
    }

    function itemHeight() {
        const item = loader.item;
        return item ? Math.max(item.implicitHeight, item.height) : 0;
    }

    function componentFor(name) {
        if (name === "workspaces") return workspacesComponent;
        if (name === "focusedWindow") return focusedWindowComponent;
        if (name === "cpu") return cpuComponent;
        if (name === "memory" || name === "ram") return memoryComponent;
        if (name === "audio" || name === "volume") return audioComponent;
        if (name === "brightness" || name === "backlight") return brightnessComponent;
        if (name === "powerProfile" || name === "power") return powerProfileComponent;
        if (name === "media" || name === "mpris" || name === "player") return mediaComponent;
        if (name === "network" || name === "net") return networkComponent;
        if (name === "bluetooth" || name === "bt") return bluetoothComponent;
        if (name === "battery" || name === "bat") return batteryComponent;
        if (name === "caffeine" || name === "idleInhibitor" || name === "idle") return caffeineComponent;
        if (name === "clock" || name === "time") return clockComponent;
        if (name === "controls" || name === "controlCenter" || name === "quickControls") return controlsComponent;
        if (name === "tray") return trayComponent;
        if (name === "settings") return settingsComponent;
        return null;
    }

    function loadPhase(name) {
        if (name === "workspaces" || name === "focusedWindow" || name === "clock" || name === "time")
            return 1;
        if (name === "settings" || name === "controls" || name === "controlCenter" || name === "quickControls")
            return 3;
        return 2;
    }

    function phaseReady(name) {
        const phase = loadPhase(name);
        if (phase <= 1) return true;
        if (phase === 2) return backgroundReady;
        return interactionReady;
    }

    Component { id: workspacesComponent; Workspace { theme: root.theme; settings: root.settings; compositor: root.compositor } }
    Component { id: focusedWindowComponent; FocusedWindow { theme: root.theme; settings: root.settings; compositor: root.compositor } }
    Component { id: cpuComponent; Cpu { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost; onDetailsRequested: function(anchorItem, moduleName) { root.moduleDetailsRequested(moduleName, anchorItem); } } }
    Component { id: memoryComponent; Memory { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost; onDetailsRequested: function(anchorItem, moduleName) { root.moduleDetailsRequested(moduleName, anchorItem); } } }
    Component { id: audioComponent; Audio { theme: root.theme; settings: root.settings; osd: root.osd; tooltipHost: root.tooltipHost; onDetailsRequested: function(anchorItem, moduleName) { root.moduleDetailsRequested(moduleName, anchorItem); } } }
    Component { id: brightnessComponent; Brightness { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost; onDetailsRequested: function(anchorItem, moduleName) { root.moduleDetailsRequested(moduleName, anchorItem); } } }
    Component { id: powerProfileComponent; PowerProfile { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost } }
    Component { id: mediaComponent; Media { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost } }
    Component { id: networkComponent; Network { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost; onDetailsRequested: function(anchorItem, moduleName) { root.moduleDetailsRequested(moduleName, anchorItem); } } }
    Component { id: bluetoothComponent; BluetoothStatus { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost; onDetailsRequested: function(anchorItem, moduleName) { root.moduleDetailsRequested(moduleName, anchorItem); } } }
    Component { id: batteryComponent; Battery { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost; onDetailsRequested: function(anchorItem, moduleName) { root.moduleDetailsRequested(moduleName, anchorItem); } } }
    Component { id: caffeineComponent; Caffeine { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost; panelWindow: root.panelWindow } }
    Component { id: clockComponent; Clock { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost; onRequested: function(anchorItem) { root.clockRequested(anchorItem); } } }
    Component { id: controlsComponent; ControlCenterButton { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost; onRequested: function(anchorItem) { root.controlsRequested(anchorItem); } } }
    Component { id: trayComponent; Tray { theme: root.theme; settings: root.settings; panelWindow: root.panelWindow } }
    Component { id: settingsComponent; SettingsButton { theme: root.theme; settings: root.settings; tooltipHost: root.tooltipHost; settingsOpen: root.settingsOpen; onRequested: function(anchorItem) { root.settingsRequested(anchorItem); } } }
}
