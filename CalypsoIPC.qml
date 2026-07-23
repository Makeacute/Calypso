pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property var appContext
    readonly property var settings: appContext.settings

    function bar() {
        return appContext.primaryBar();
    }

    function withBar(callback) {
        const target = bar();
        if (target)
            callback(target);
    }

    IpcHandler {
        target: "calypso"

        function openSettings(): void {
            root.appContext.openSettings("overview", root.bar());
        }

        function closeSettings(): void {
            root.appContext.closeSettings();
        }

        function openNotifications(): void {
            root.withBar(target => target.showNotifications(null));
        }

        function closeNotifications(): void {
            root.withBar(target => target.closeNotifications());
        }

        function openClock(): void {
            root.withBar(target => target.showClock(null));
        }

        function closeClock(): void {
            root.withBar(target => target.closeClock());
        }

        function openControls(): void {
            root.withBar(target => target.showControls(null));
        }

        function closeControls(): void {
            root.withBar(target => target.closeControls());
        }

        function openDashboard(): void {
            root.withBar(target => target.showControls(null));
        }

        function closeDashboard(): void {
            root.withBar(target => target.closeControls());
        }

        function openNotepad(): void {
            root.withBar(target => target.showNotepad(null));
        }

        function closeNotepad(): void {
            root.withBar(target => target.closeNotepad());
        }

        function openClipboard(): void {
            root.withBar(target => target.showClipboard(null));
        }

        function closeClipboard(): void {
            root.withBar(target => target.closeClipboard());
        }

        function openProcesses(): void {
            root.withBar(target => target.showProcessList(null));
        }

        function closeProcesses(): void {
            root.withBar(target => target.closeProcessList());
        }

        function openLauncher(): void {
            root.withBar(target => target.showLauncher(null));
        }

        function openLauncherQuery(query: string): void {
            root.withBar(target => target.showLauncherQuery(query));
        }

        function closeLauncher(): void {
            root.withBar(target => target.closeLauncher());
        }

        function openSettingsPage(page: string): void {
            root.appContext.openSettings(page, root.bar());
        }

        function openSettingsDetail(moduleName: string): void {
            root.appContext.openSettingsModule(moduleName, root.bar());
        }

        function showOsd(kind: string, value: real): void {
            root.withBar(target => target.showOsd(kind, value));
        }

        function showTooltip(text: string): void {
            root.withBar(target => target.showTooltip(text));
        }

        function hideTooltip(): void {
            root.withBar(target => target.hideTooltip());
        }

        function openModule(moduleName: string): void {
            root.withBar(target => target.openModuleDetails(moduleName));
        }

        function openModuleTab(moduleName: string, tabName: string): void {
            root.withBar(target => target.openModuleTab(moduleName, tabName));
        }

        function closeModule(): void {
            root.withBar(target => target.closeModuleDetails());
        }

        function randomWallpaper(): void {
            root.appContext.wallpaperService.applyRandom(false);
        }

        function previewWallpaper(path: string): void {
            root.settings.setString("wallpaperSelectedPreview", path);
        }

        function applyWallpaper(path: string): void {
            root.appContext.wallpaperService.apply(path);
        }

        function setBarStyle(value: string): void {
            root.settings.setEnum("barStyle", value, ["islands", "solid", "pill"], "islands");
        }

        function setBarPosition(value: string): void {
            root.settings.setEnum("barPosition", value, ["top", "bottom"], "top");
        }

        function setWidgetStyle(value: string): void {
            root.settings.setEnum("widgetStyle", value, ["iconOnly", "iconAndText", "expanded"], "iconAndText");
        }

        function setBarHeight(value: int): void {
            root.settings.setNumber("barHeight", value, 24, 56);
        }

        function setBarAutohide(value: bool): void {
            root.settings.setValue("barAutohide", value);
        }

        function setSettingsWidth(value: int): void {
            root.settings.setNumber("settingsPanelWidth", value, 640, 960);
        }

        function setSettingsDensity(value: string): void {
            root.settings.setSettingsPanelDensity(value);
        }

        function setSettingsAnchor(value: string): void {
            root.settings.setEnum("settingsPanelAnchor", value, ["button", "left", "center", "right"], "button");
        }

        function setThemeRecipe(value: string): void {
            root.settings.setThemeRecipe(value);
        }

        function setSpacingScale(value: real): void {
            root.settings.setReal("spacingScale", value, 0.5, 2.0, 0.1);
        }

        function setReduceMotion(value: bool): void {
            root.settings.setReduceMotion(value);
        }

        function setModuleEnabled(moduleName: string, value: bool): void {
            root.settings.setModuleEnabled(moduleName, value);
        }

        function setSectionModules(section: string, modulesCsv: string): void {
            const modules = String(modulesCsv || "")
                .split(",")
                .map(item => item.trim())
                .filter(item => item.length > 0);
            root.settings.setSectionModules(section, modules);
        }
    }
}
