pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "services"

Scope {
    id: root

    property var bars: []
    property var lastInvokingBar: null
    property bool settingsWindowRequested: false
    readonly property var settings: settingsObject
    readonly property var settingsWindow: settingsWindowLoader.item
    readonly property var theme: themeObject
    readonly property var compositor: compositorObject
    readonly property var moduleRegistry: moduleRegistryObject
    readonly property var notificationServer: notificationServerObject
    readonly property var appInfo: appInfoObject
    readonly property var mediaService: mediaServiceObject
    readonly property var powerProfileService: powerProfileServiceObject
    readonly property var batteryService: batteryServiceObject
    readonly property var networkService: networkServiceObject
    readonly property var systemStatsService: systemStatsServiceObject
    readonly property var wallpaperService: wallpaperServiceObject
    readonly property var trackedNotifications: notificationServerObject.trackedNotifications
                                                ? notificationServerObject.trackedNotifications.values
                                                : []

    function focusedMonitorName() {
        const workspaces = Array.from(compositorObject.workspaces || []);
        for (let i = 0; i < workspaces.length; i++) {
            if (workspaces[i].focused)
                return String(workspaces[i].monitor || "");
        }
        return "";
    }

    function barForScreenName(name) {
        const candidates = Array.from(bars || []);
        const target = String(name || "");
        for (let i = 0; i < candidates.length; i++) {
            const candidate = candidates[i];
            if (candidate && candidate.screen && String(candidate.screen.name || "") === target)
                return candidate;
        }
        return null;
    }

    function primaryBar() {
        const focused = barForScreenName(focusedMonitorName());
        if (focused) return focused;
        if (lastInvokingBar) return lastInvokingBar;
        const candidates = Array.from(bars || []);
        return candidates.length > 0 ? candidates[0] : null;
    }

    function rememberBar(candidate) {
        if (candidate)
            lastInvokingBar = candidate;
    }

    function settingsScreen(candidate) {
        const source = candidate || primaryBar();
        return source && source.screen ? source.screen : null;
    }

    function openSettings(page, candidate) {
        const source = candidate || primaryBar();
        rememberBar(source);
        settingsWindowRequested = true;
        Qt.callLater(function() {
            if (settingsWindowLoader.item)
                settingsWindowLoader.item.openFor(settingsScreen(source), page || "overview");
        });
    }

    function openSettingsModule(moduleName, candidate) {
        const source = candidate || primaryBar();
        rememberBar(source);
        settingsWindowRequested = true;
        Qt.callLater(function() {
            if (settingsWindowLoader.item)
                settingsWindowLoader.item.openModuleFor(settingsScreen(source), moduleName);
        });
    }

    function toggleSettings(page, candidate) {
        const source = candidate || primaryBar();
        rememberBar(source);
        if (settingsWindowLoader.item && settingsWindowLoader.item.visible) {
            settingsWindowLoader.item.toggleFor(settingsScreen(source), page || "overview");
            return;
        }
        openSettings(page, source);
    }

    function closeSettings() {
        if (settingsWindowLoader.item)
            settingsWindowLoader.item.close();
    }

    function releaseSettingsWindow() {
        Qt.callLater(function() {
            if (!settingsWindowLoader.item || !settingsWindowLoader.item.visible)
                settingsWindowRequested = false;
        });
    }

    AppInfo {
        id: appInfoObject
    }

    ModuleRegistry {
        id: moduleRegistryObject
    }

    SettingsStore {
        id: settingsObject

        registry: moduleRegistryObject
    }

    Theme {
        id: themeObject

        settings: settingsObject
    }

    LazyLoader {
        id: settingsWindowLoader

        active: root.settingsWindowRequested
        component: SettingsWindow {
            appContext: root
        }
    }

    CompositorService {
        id: compositorObject

        settings: settingsObject
    }

    NotificationServer {
        id: notificationServerObject

        keepOnReload: true
        persistenceSupported: true
        bodySupported: settingsObject.notificationsShowBody
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: settingsObject.notificationsShowImages
        actionsSupported: settingsObject.notificationsShowActions
        actionIconsSupported: false
        imageSupported: settingsObject.notificationsShowImages

        onNotification: function(notification) {
            if (notification && !notification.transient)
                notification.tracked = true;
        }
    }

    MediaService {
        id: mediaServiceObject
    }

    PowerProfileService {
        id: powerProfileServiceObject
    }

    BatteryService {
        id: batteryServiceObject

        fallbackPollMs: settingsObject.batteryFallbackPollMs
    }

    NetworkService {
        id: networkServiceObject

        performanceMode: settingsObject.performanceMode
        interfaceName: settingsObject.networkInterfaceName
        reconnectIntervalMs: settingsObject.networkPollMs
        throughputIntervalMs: settingsObject.networkPollMs
    }

    SystemStatsService {
        id: systemStatsServiceObject

        performanceMode: settingsObject.performanceMode
        sampleIntervalMs: Math.min(settingsObject.cpuPollMs, settingsObject.memoryPollMs)
        historyLimit: settingsObject.modulePopupHistorySamples
    }

    WallpaperService {
        id: wallpaperServiceObject

        settings: settingsObject
    }

    CalypsoIPC {
        appContext: root
    }
}
