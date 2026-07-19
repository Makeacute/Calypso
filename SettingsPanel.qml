pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "services"

PopupWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property var osd: null
    property var anchorItem: null
    property bool panelOpen: false
    property bool panelClosing: false
    property string activePage: settings ? settings.settingsPanelPage : "overview"
    property string detailPage: ""
    property string searchText: ""
    property bool wallpaperFavoritesOnly: false
    property string selectedWallpaperPath: settings ? settings.wallpaperSelectedPreview : ""
    property int settingsChangeCount: 0
    property var dependencyStatus: ({})
    readonly property bool detailOpen: detailPage.length > 0
    readonly property real sidebarWidth: Math.min(Math.round(panelWidth * 0.24), settings ? settings.effectiveSpacingXL * 7 : 168)
    readonly property int panelWidth: settings ? Math.round(Math.min(availableWidth(), Math.max(settings.settingsPanelWidth, settings.effectiveSpacingXL * 29))) : 780
    readonly property var pages: [
        { "id": "overview", "label": "Overview", "icon": "󰕮", "tags": "status theme bar shortcuts" },
        { "id": "appearance", "label": "Appearance", "icon": "󰸌", "tags": "style position opacity blur border anchor preset" },
        { "id": "layout", "label": "Layout", "icon": "󰙀", "tags": "spacing radius height margin padding width modules" },
        { "id": "modules", "label": "Modules", "icon": "󱂬", "tags": "left center right reorder visibility" },
        { "id": "widgets", "label": "Widgets", "icon": "󰃭", "tags": "clock audio network battery cpu memory media tray" },
        { "id": "osd", "label": "OSD", "icon": "󰕾", "tags": "volume brightness function keys overlay" },
        { "id": "wallpaper", "label": "Wallpaper", "icon": "󰸉", "tags": "matugen awww colors transition random" },
        { "id": "motion", "label": "Motion", "icon": "󱡫", "tags": "animation reduce performance tooltip toast" },
        { "id": "advanced", "label": "Advanced", "icon": "󰒓", "tags": "palette compositor schema popup diagnostics" }
    ]

    signal closeRequested()

    function availableWidth() {
        const screenWidth = panelWindow && panelWindow.width ? panelWindow.width : 960;
        return Math.max(settings ? settings.effectiveSpacingXL * 18 : 432, screenWidth);
    }

    function availableHeight() {
        const screenHeight = panelWindow && panelWindow.screen && panelWindow.screen.height ? panelWindow.screen.height : 720;
        const chrome = settings ? settings.barHeight + settings.screenMargin * 3 + settings.settingsPanelGap : 64;
        const target = Math.round(screenHeight * 0.84);
        return Math.min(screenHeight - chrome, Math.max(settings ? settings.effectiveSpacingXL * 21 : 504, target));
    }

    function clampedX(value) {
        const maxX = panelWindow ? Math.max(0, panelWindow.width - panelWidth) : 0;
        return Math.max(0, Math.min(maxX, value));
    }

    function anchoredX() {
        const mode = settings ? String(settings.settingsPanelAnchor || "button") : "button";
        if (mode === "left") return clampedX(0);
        if (mode === "center") return clampedX((panelWindow ? panelWindow.width : panelWidth) / 2 - panelWidth / 2);
        if (mode === "right") return clampedX((panelWindow ? panelWindow.width : panelWidth) - panelWidth);

        if (anchorItem && typeof anchorItem.mapToItem === "function") {
            const point = anchorItem.mapToItem(null, 0, 0);
            return clampedX(point.x + anchorItem.width / 2 - panelWidth / 2);
        }

        return clampedX((panelWindow ? panelWindow.width : panelWidth) - panelWidth);
    }

    function pageLabel(pageId) {
        for (let i = 0; i < pages.length; i++) {
            if (pages[i].id === pageId) return pages[i].label;
        }
        return "Settings";
    }

    function pageIcon(pageId) {
        for (let i = 0; i < pages.length; i++) {
            if (pages[i].id === pageId) return pages[i].icon;
        }
        return "󰒓";
    }

    function displayLabel(value) {
        const text = String(value || "");
        if (text === "iconOnly") return "Icon only";
        if (text === "iconAndText") return "Icon + text";
        if (text === "allWorkspaceApps") return "Workspace apps";
        if (text === "focusedTitle") return "Focused title";
        if (text === "rightCenter") return "Right center";
        if (text === "leftCenter") return "Left center";
        if (text === "topCenter") return "Top center";
        if (text === "bottomCenter") return "Bottom center";
        if (text === "topRight") return "Top right";
        if (text === "bottomRight") return "Bottom right";
        if (text === "noctaliaQuiet") return "Noctalia quiet";
        if (text === "frostedMinimal") return "Frosted minimal";
        if (text === "materialMorphing") return "Material morphing";
        if (text === "scheme-tonal-spot") return "Tonal spot";
        if (text === "scheme-vibrant") return "Vibrant";
        if (text === "scheme-content") return "Content";
        if (text === "scheme-expressive") return "Expressive";
        if (text === "scheme-fidelity") return "Fidelity";
        if (text === "scheme-neutral") return "Neutral";
        if (text === "scheme-monochrome") return "Monochrome";
        if (text === "custom") return "Custom";
        if (text === "calypsoDefault") return "Calypso";
        if (text === "compactGlass") return "Compact glass";
        if (text === "materialSoft") return "Material soft";
        if (text === "denseIslands") return "Dense islands";
        if (text === "minimalSolid") return "Minimal solid";
        if (text === "focusMode") return "Focus";
        if (text === "dominantColor") return "Color-biased";

        const cleaned = text.replace(/^scheme-/, "").replace(/([a-z])([A-Z])/g, "$1 $2").replace(/-/g, " ");
        return cleaned.length > 0 ? cleaned.charAt(0).toUpperCase() + cleaned.slice(1) : text;
    }

    function pageMatches(page) {
        const q = searchText.toLowerCase().trim();
        if (q.length <= 0) return true;
        return String(page.label + " " + page.tags).toLowerCase().indexOf(q) >= 0;
    }

    function pageExists(pageId) {
        for (let i = 0; i < pages.length; i++) {
            if (pages[i].id === pageId) return true;
        }
        return false;
    }

    function showPage(page) {
        detailPage = "";
        activePage = pageExists(page) ? page : "overview";
        if (contentFlick) contentFlick.contentY = 0;
    }

    function openPage(page) {
        open(null);
        showPage(String(page || "overview"));
    }

    function openModuleOptions(moduleName) {
        open(null);
        activePage = "widgets";
        openDetail(String(moduleName || ""));
    }

    function applyRandomWallpaper() {
        if (wallpaper.wallpapers.length <= 0)
            wallpaper.scan();
        wallpaper.applyRandom(false);
    }

    function wallpaperEntry(path) {
        const wanted = String(path || "");
        const list = Array.from(wallpaper.wallpapers || []);
        for (let i = 0; i < list.length; i++) {
            if (String(list[i].path || "") === wanted) return list[i];
        }
        return null;
    }

    function activeWallpaperEntry() {
        let entry = wallpaperEntry(selectedWallpaperPath);
        if (entry) return entry;
        entry = wallpaperEntry(settings ? settings.currentWallpaper : "");
        if (entry) return entry;
        return wallpaper.wallpapers.length > 0 ? wallpaper.wallpapers[0] : null;
    }

    function selectWallpaper(path) {
        const next = String(path || "");
        selectedWallpaperPath = next;
        if (settings) settings.setString("wallpaperSelectedPreview", next);
    }

    function openWallpaperPreview(path) {
        openPage("wallpaper");
        selectWallpaper(path);
    }

    function applyWallpaperPath(path) {
        const next = String(path || "");
        if (next.length <= 0) return;
        selectWallpaper(next);
        wallpaper.apply(next, true);
    }

    function applySelectedWallpaper() {
        const entry = activeWallpaperEntry();
        if (entry) applyWallpaperPath(entry.path);
    }

    function favoriteSelectedWallpaper() {
        const entry = activeWallpaperEntry();
        if (entry) wallpaper.toggleFavorite(entry.path);
    }

    function dependencyValue(name) {
        const value = dependencyStatus ? dependencyStatus[String(name || "")] : "";
        return String(value || "unknown");
    }

    function dependencyOk(name) {
        return dependencyValue(name) === "found";
    }

    function dependencySummary() {
        const tools = ["awww", "matugen", "jq"];
        let ok = 0;
        for (let i = 0; i < tools.length; i++) {
            if (dependencyOk(tools[i])) ok++;
        }
        return ok + "/" + tools.length + " tools";
    }

    function refreshDependencyStatus() {
        if (!settings || dependencyProc.running) return;
        dependencyStatus = ({ "status": "checking" });
        dependencyProc.command = [
            "sh",
            "-c",
            "for c in awww matugen jq ffmpeg ffprobe grim ydotool; do if command -v \"$c\" >/dev/null 2>&1; then printf '%s=found\\n' \"$c\"; else printf '%s=missing\\n' \"$c\"; fi; done; if pgrep -f 'awww-daemon' >/dev/null 2>&1; then printf 'awwwDaemon=found\\n'; else printf 'awwwDaemon=missing\\n'; fi; dir=$1; palette=$2; [ -d \"$dir\" ] && printf 'wallpaperDir=found\\n' || printf 'wallpaperDir=missing\\n'; [ -f \"$palette\" ] && printf 'palette=found\\n' || printf 'palette=missing\\n'",
            "sh",
            settings.wallpaperDirectory,
            settings.palettePath
        ];
        dependencyProc.running = true;
    }

    function clearChangeCount() {
        settingsChangeCount = 0;
    }

    function openDetail(page) {
        detailPage = page;
        if (contentFlick) contentFlick.contentY = 0;
    }

    function back() {
        detailPage = "";
        if (contentFlick) contentFlick.contentY = 0;
    }

    function activeTitle() {
        if (detailOpen && settings) return settings.moduleLabel(detailPage);
        return pageLabel(activePage);
    }

    function activeSubtitle() {
        if (detailOpen && settings) return settings.moduleCategory(detailPage) + " / " + settings.moduleCost(detailPage);
        if (activePage === "wallpaper") return wallpaper.wallpapers.length + " images";
        if (activePage === "osd") return settings.osdEnabled ? displayLabel(settings.osdPosition) : "disabled";
        if (activePage === "appearance") return displayLabel(settings.barStyle) + " / " + displayLabel(settings.barPosition);
        if (activePage === "modules") return settings.leftModules.length + " / " + settings.centerModules.length + " / " + settings.rightModules.length;
        return "Calypso";
    }

    function componentForPage(page) {
        if (page === "appearance") return appearancePage;
        if (page === "layout") return layoutPage;
        if (page === "modules") return modulesPage;
        if (page === "widgets") return widgetsPage;
        if (page === "osd") return osdPage;
        if (page === "wallpaper") return wallpaperPage;
        if (page === "motion") return motionPage;
        if (page === "advanced") return advancedPage;
        return overviewPage;
    }

    function componentForDetail(page) {
        if (page === "clock") return clockDetail;
        if (page === "audio") return audioDetail;
        if (page === "network") return networkDetail;
        if (page === "battery") return batteryDetail;
        if (page === "cpu") return cpuDetail;
        if (page === "memory") return memoryDetail;
        if (page === "media") return mediaDetail;
        if (page === "brightness") return brightnessDetail;
        if (page === "focusedWindow") return focusedWindowDetail;
        if (page === "workspaces") return workspaceDetail;
        if (page === "powerProfile") return powerProfileDetail;
        if (page === "tray") return trayDetail;
        return genericDetail;
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
        if (wallpaper.wallpapers.length <= 0)
            wallpaper.scan();
        if (selectedWallpaperPath.length <= 0 && settings && settings.wallpaperSelectedPreview.length > 0)
            selectedWallpaperPath = settings.wallpaperSelectedPreview;
        refreshDependencyStatus();
    }

    function close() {
        if (!panelOpen && !panelClosing) return;

        panelClosing = true;
        panelOpen = false;
        closeTimer.restart();
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -implicitHeight - settings.settingsPanelGap : panelWindow.height + settings.settingsPanelGap) : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: availableHeight()
    visible: panelOpen || panelClosing
    grabFocus: anchorItem !== null
    color: "transparent"
    onVisibleChanged: if (!visible) closeRequested()

    WallpaperService {
        id: wallpaper

        settings: root.settings
        osd: root.osd
    }

    Process {
        id: dependencyProc

        stdout: StdioCollector {
            onStreamFinished: {
                const next = ({});
                const lines = String(text || "").split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    const index = line.indexOf("=");
                    if (index > 0)
                        next[line.slice(0, index)] = line.slice(index + 1);
                }
                root.dependencyStatus = next;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: if (String(text || "").trim().length > 0 && root.settings) root.settings.setString("wallpaperLastError", String(text || "").trim())
        }
    }

    Connections {
        target: root.settings
        function onChanged() {
            if (root.panelOpen) root.settingsChangeCount += 1;
        }
        function onWallpaperDirectoryChanged() { root.refreshDependencyStatus(); }
        function onPalettePathChanged() { root.refreshDependencyStatus(); }
        function onWallpaperSelectedPreviewChanged() {
            if (root.settings && root.settings.wallpaperSelectedPreview.length > 0)
                root.selectedWallpaperPath = root.settings.wallpaperSelectedPreview;
        }
    }

    Connections {
        target: wallpaper
        function onWallpapersChanged() {
            if (root.selectedWallpaperPath.length <= 0) {
                const entry = root.activeWallpaperEntry();
                if (entry) root.selectWallpaper(entry.path);
            }
        }
    }

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
        id: settingsFrame

        x: root.anchoredX()
        width: root.panelWidth
        height: parent.height
        y: root.panelOpen ? 0 : (settings.barPosition === "bottom" ? theme.spacingM : -theme.spacingM)
        theme: root.theme
        settings: root.settings
        surfaceColor: theme.alpha(theme.surfacePanel, settings.panelOpacity / 100)
        outlineColor: theme.outlineSubtle
        outlineWidth: settings.effectiveBorderWidth
        surfaceRadius: settings.panelRadius
        clip: true
        opacity: root.panelOpen ? 1 : 0

        Behavior on x {
            NumberAnimation { duration: settings.motionNormal; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            NumberAnimation {
                duration: root.panelOpen ? theme.motionOpen : theme.motionClose
                easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.panelOpen ? theme.motionOpen : theme.motionClose
                easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: function(mouse) { mouse.accepted = true; }
            onWheel: function(wheel) { wheel.accepted = true; }
        }

        Row {
            anchors.fill: parent
            anchors.margins: settings.panelPadding
            anchors.bottomMargin: settings.panelPadding + (changedFooter.visible ? changedFooter.height + settings.effectiveContentSpacing : 0)
            spacing: settings.effectiveSpacingM

            Column {
                id: sidebar

                width: root.sidebarWidth
                height: parent.height
                spacing: settings.effectiveSpacingM

                Row {
                    width: parent.width
                    height: settings.controlHeight
                    spacing: settings.effectiveContentSpacing

                    Rectangle {
                        width: settings.controlHeight
                        height: width
                        radius: settings.effectivePillRadius
                        color: theme.surfaceActive
                        border.color: theme.outlineActive
                        border.width: settings.effectiveBorderWidth
                        antialiasing: true

                        Text {
                            anchors.centerIn: parent
                            text: "󰣇"
                            color: theme.accent
                            font.family: settings.fontFamily
                            font.pixelSize: settings.effectiveIconSize
                        }
                    }

                    Column {
                        width: parent.width - settings.controlHeight - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                        Text {
                            width: parent.width
                            text: "Calypso"
                            color: theme.text
                            elide: Text.ElideRight
                            font.family: settings.fontFamily
                            font.pixelSize: Math.round(settings.effectiveFontSize * 1.18)
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            text: settings.settingsPreset + " / " + settings.animationProfile
                            color: theme.textMuted
                            elide: Text.ElideRight
                            font.family: settings.fontFamily
                            font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.78))
                        }
                    }
                }

                SearchBox {
                    width: parent.width
                    theme: root.theme
                    settings: root.settings
                    text: root.searchText
                    onTextRequested: function(text) { root.searchText = text; }
                }

                Flickable {
                    width: parent.width
                    height: parent.height - y
                    contentWidth: width
                    contentHeight: navColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Column {
                        id: navColumn

                        width: parent.width
                        spacing: settings.effectiveContentSpacing

                        Repeater {
                            model: root.pages

                            NavButton {
                                required property var modelData

                                width: navColumn.width
                                theme: root.theme
                                settings: root.settings
                                icon: String(modelData.icon)
                                label: String(modelData.label)
                                selected: !root.detailOpen && root.activePage === String(modelData.id)
                                visible: root.pageMatches(modelData)
                                onPressed: root.showPage(String(modelData.id))
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: settings.effectiveBorderWidth
                height: parent.height
                radius: width / 2
                color: theme.alpha(theme.border, 0.3)
                antialiasing: true
            }

            Column {
                id: pageArea

                width: parent.width - sidebar.width - parent.spacing * 2 - settings.effectiveBorderWidth
                height: parent.height
                spacing: settings.effectiveSpacingM

                Rectangle {
                    id: pageHeader

                    width: parent.width
                    height: Math.max(settings.controlHeight + settings.effectivePillPadding * 2, titleColumn.implicitHeight + settings.effectivePillPadding * 2)
                    radius: settings.effectiveRadiusM
                    color: theme.alpha(theme.surfaceStrong, 0.42)
                    border.color: theme.outlineSubtle
                    border.width: settings.effectiveBorderWidth
                    antialiasing: true
                    clip: true

                    Behavior on color { ColorAnimation { duration: settings.motionNormal } }
                    Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.8))
                        color: theme.accent
                        opacity: root.detailOpen ? 0.55 : 0.85
                        antialiasing: true
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.45))
                        color: theme.gloss
                        antialiasing: true
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: settings.effectivePillPadding
                        spacing: settings.effectiveContentSpacing

                        IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            visible: root.detailOpen
                            onPressed: root.back()
                        }

                        Rectangle {
                            width: settings.controlHeight
                            height: width
                            radius: settings.effectivePillRadius
                            color: theme.surfaceActive
                            border.color: theme.outlineActive
                            border.width: settings.effectiveBorderWidth
                            antialiasing: true

                            Text {
                                anchors.centerIn: parent
                                text: root.detailOpen ? settings.moduleIcon(root.detailPage) : root.pageIcon(root.activePage)
                                color: theme.accent
                                font.family: settings.fontFamily
                                font.pixelSize: settings.effectiveIconSize
                            }
                        }

                        Column {
                            id: titleColumn

                            width: parent.width - closeButton.width - parent.spacing * 3 - settings.controlHeight - (root.detailOpen ? settings.controlHeight + parent.spacing : 0)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                            Text {
                                width: parent.width
                                text: root.activeTitle()
                                color: theme.text
                                elide: Text.ElideRight
                                font.family: settings.fontFamily
                                font.pixelSize: Math.round(settings.effectiveFontSize * 1.32)
                                font.weight: Font.DemiBold
                            }

                            Row {
                                width: parent.width
                                spacing: settings.effectiveContentSpacing

                                Text {
                                    width: Math.min(implicitWidth, parent.width)
                                    text: root.activeSubtitle()
                                    color: theme.textMuted
                                    elide: Text.ElideRight
                                    font.family: settings.fontFamily
                                    font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.82))
                                }

                                Rectangle {
                                    visible: !root.detailOpen
                                    width: statusText.implicitWidth + settings.effectivePillPadding
                                    height: Math.max(statusText.implicitHeight + settings.effectiveGroupPadding, settings.effectiveSpacingM)
                                    radius: height / 2
                                    color: theme.alpha(theme.accent, 0.12)
                                    border.color: theme.alpha(theme.accent, 0.24)
                                    border.width: settings.effectiveBorderWidth
                                    antialiasing: true

                                    Text {
                                        id: statusText
                                        anchors.centerIn: parent
                                        text: settings.reduceMotion ? "instant" : "live"
                                        color: theme.accent
                                        font.family: settings.fontFamily
                                        font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.72))
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }

                        IconButton {
                            id: closeButton

                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            onPressed: root.close()
                        }
                    }
                }

                Flickable {
                    id: contentFlick

                    width: parent.width
                    height: parent.height - y
                    contentWidth: width
                    contentHeight: contentColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Column {
                        id: contentColumn

                        width: contentFlick.width
                        spacing: settings.panelPadding

                        Loader {
                            id: pageLoader

                            width: parent.width
                            sourceComponent: root.detailOpen ? root.componentForDetail(root.detailPage) : root.componentForPage(root.activePage)
                        }
                    }
                }
            }
        }

        ChangedFooter {
            id: changedFooter

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: settings.panelPadding
            theme: root.theme
            settings: root.settings
            changeCount: root.settingsChangeCount
            visible: settings.settingsChangedFooter && root.panelOpen && root.settingsChangeCount > 0
            onClearRequested: root.clearChangeCount()
            onCloseRequested: root.close()
        }
    }

    Component {
        id: overviewPage

        Column {
            width: pageLoader.width
            spacing: settings.panelPadding

            OverviewHero { width: parent.width; theme: root.theme; settings: root.settings }
            ShellPreview { width: parent.width; theme: root.theme; settings: root.settings }
            PresetDeck { width: parent.width; theme: root.theme; settings: root.settings }
            PalettePreview { width: parent.width; theme: root.theme; settings: root.settings }

            Flow {
                width: parent.width
                spacing: settings.effectiveContentSpacing

                QuickCard { theme: root.theme; settings: root.settings; icon: "󰸌"; title: "Appearance"; detail: root.displayLabel(settings.barStyle) + " / " + root.displayLabel(settings.barPosition); onPressed: root.showPage("appearance") }
                QuickCard { theme: root.theme; settings: root.settings; icon: "󰙀"; title: "Layout"; detail: settings.barHeight + "h / " + settings.spacingScale.toFixed(1) + "x"; onPressed: root.showPage("layout") }
                QuickCard { theme: root.theme; settings: root.settings; icon: "󰕾"; title: "OSD"; detail: settings.osdEnabled ? root.displayLabel(settings.osdPosition) : "off"; onPressed: root.showPage("osd") }
                QuickCard { theme: root.theme; settings: root.settings; icon: "󰸉"; title: "Wallpaper"; detail: wallpaper.wallpapers.length + " images / " + root.dependencySummary(); onPressed: root.showPage("wallpaper") }
                QuickCard { theme: root.theme; settings: root.settings; icon: "󱡫"; title: "Motion"; detail: settings.reduceMotion ? "instant" : settings.animationProfile; onPressed: root.showPage("motion") }
                QuickCard { theme: root.theme; settings: root.settings; icon: "󱂬"; title: "Modules"; detail: settings.rightModules.length + " right"; onPressed: root.showPage("modules") }
            }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Session"

                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Performance mode"; checked: settings.performanceMode; onToggled: function(checked) { settings.setValue("performanceMode", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Reduce motion"; checked: settings.reduceMotion; onToggled: function(checked) { settings.setReduceMotion(checked); } }

                Row {
                    width: parent.width
                    spacing: settings.effectiveContentSpacing

                    ActionButton { theme: root.theme; settings: root.settings; icon: "󰐊"; label: "Test OSD"; onPressed: if (root.osd) root.osd.show("󰕾", 0.72, "volume", "Volume") }
                    ActionButton { theme: root.theme; settings: root.settings; icon: "󰒲"; label: "Random wallpaper"; onPressed: root.applyRandomWallpaper() }
                }
            }
        }
    }

    Component {
        id: appearancePage

        Column {
            width: pageLoader.width
            spacing: settings.panelPadding

            ShellPreview { width: parent.width; theme: root.theme; settings: root.settings }
            PresetDeck { width: parent.width; theme: root.theme; settings: root.settings }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Bar"

                StyleSelectorRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Style"; value: settings.barStyle; choices: ["islands", "solid", "pill"]; onChoiceRequested: function(choice) { settings.setEnum("barStyle", choice, choices, "islands"); } }
                StyleSelectorRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Position"; value: settings.barPosition; choices: ["top", "bottom"]; onChoiceRequested: function(choice) { settings.setEnum("barPosition", choice, choices, "top"); } }
                StyleSelectorRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Settings anchor"; value: settings.settingsPanelAnchor; choices: ["button", "left", "center", "right"]; onChoiceRequested: function(choice) { settings.setEnum("settingsPanelAnchor", choice, choices, "button"); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Background opacity"; value: settings.barOpacity; minimum: 0.5; maximum: 1.0; step: 0.05; suffix: ""; onValueRequested: function(value) { settings.setReal("barOpacity", value, minimum, maximum, step); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Blur background"; checked: settings.barBlur; onToggled: function(checked) { settings.setValue("barBlur", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Border"; checked: settings.barBorderEnabled; onToggled: function(checked) { settings.setValue("barBorderEnabled", checked); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; visible: settings.barBorderEnabled; label: "Border thickness"; value: settings.barBorderThickness; minimum: 1; maximum: 4; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("barBorderThickness", value, minimum, maximum); } }
            }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Presets"

                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Density"; value: settings.settingsPreset; choices: ["Balanced", "Compact", "Roomy"]; onChoiceRequested: function(choice) { settings.setSettingsPreset(choice); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Visual preset"; value: settings.visualPreset; choices: ["noctaliaQuiet", "frostedMinimal", "materialMorphing"]; onChoiceRequested: function(choice) { settings.setVisualPreset(choice); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Surface"; value: settings.surfaceStyle; choices: ["solid", "translucent", "outlined", "frosted"]; onChoiceRequested: function(choice) { settings.setEnum("surfaceStyle", choice, choices, "translucent"); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Pills"; value: settings.pillStyle; choices: ["flat", "soft", "outlined", "filled"]; onChoiceRequested: function(choice) { settings.setEnum("pillStyle", choice, choices, "soft"); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Hover"; value: settings.hoverEffect; choices: ["none", "wash", "scale"]; onChoiceRequested: function(choice) { settings.setEnum("hoverEffect", choice, choices, "wash"); } }
            }
        }
    }

    Component {
        id: layoutPage

        Column {
            width: pageLoader.width
            spacing: settings.panelPadding

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Scale"

                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Spacing scale"; value: settings.spacingScale; minimum: 0.5; maximum: 2.0; step: 0.1; suffix: "x"; onValueRequested: function(value) { settings.setReal("spacingScale", value, minimum, maximum, step); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Radius scale"; value: settings.radiusScale; minimum: 0.5; maximum: 2.0; step: 0.1; suffix: "x"; onValueRequested: function(value) { settings.setReal("radiusScale", value, minimum, maximum, step); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Font size"; value: settings.fontSize; minimum: 10; maximum: 18; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("fontSize", value, minimum, maximum); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Icon size"; value: settings.iconSize; minimum: 12; maximum: 24; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("iconSize", value, minimum, maximum); } }
            }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Geometry"

                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Reserve space"; checked: settings.reserveSpace; onToggled: function(checked) { settings.setValue("reserveSpace", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Autohide"; checked: settings.barAutohide; onToggled: function(checked) { settings.setValue("barAutohide", checked); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Bar height"; value: settings.barHeight; minimum: 24; maximum: 48; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("barHeight", value, minimum, maximum); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Screen margin"; value: settings.screenMargin; minimum: 0; maximum: 24; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("screenMargin", value, minimum, maximum); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Group spacing"; value: settings.groupSpacing; minimum: 0; maximum: 20; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("groupSpacing", value, minimum, maximum); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Item spacing"; value: settings.itemSpacing; minimum: 0; maximum: 16; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("itemSpacing", value, minimum, maximum); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Group padding"; value: settings.groupPadding; minimum: 2; maximum: 10; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("groupPadding", value, minimum, maximum); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Pill padding"; value: settings.pillPadding; minimum: 4; maximum: 18; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("pillPadding", value, minimum, maximum); } }
            }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Panels"

                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Settings density"; value: settings.settingsPanelDensity; choices: ["compact", "balanced", "roomy"]; onChoiceRequested: function(choice) { settings.setSettingsPanelDensity(choice); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Settings width"; value: settings.settingsPanelWidth; minimum: 640; maximum: 960; step: 20; suffix: "px"; onValueRequested: function(value) { settings.setNumber("settingsPanelWidth", value, minimum, maximum); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Panel gap"; value: settings.settingsPanelGap; minimum: 0; maximum: 24; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("settingsPanelGap", value, minimum, maximum); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Live preview"; checked: settings.settingsPreviewEnabled; onToggled: function(checked) { settings.setValue("settingsPreviewEnabled", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Change footer"; checked: settings.settingsChangedFooter; onToggled: function(checked) { settings.setValue("settingsChangedFooter", checked); } }
            }
        }
    }

    Component {
        id: modulesPage

        Column {
            width: pageLoader.width
            spacing: settings.panelPadding

            ShellPreview { width: parent.width; theme: root.theme; settings: root.settings; visible: settings.settingsPreviewEnabled }

            Flow {
                width: parent.width
                spacing: settings.panelPadding

                ModuleSection { width: parent.width >= settings.effectiveSpacingXL * 42 ? (parent.width - parent.spacing * 2) / 3 : parent.width; theme: root.theme; settings: root.settings; sectionName: "left"; title: "Left"; modules: settings.leftModules }
                ModuleSection { width: parent.width >= settings.effectiveSpacingXL * 42 ? (parent.width - parent.spacing * 2) / 3 : parent.width; theme: root.theme; settings: root.settings; sectionName: "center"; title: "Center"; modules: settings.centerModules }
                ModuleSection { width: parent.width >= settings.effectiveSpacingXL * 42 ? (parent.width - parent.spacing * 2) / 3 : parent.width; theme: root.theme; settings: root.settings; sectionName: "right"; title: "Right"; modules: settings.rightModules }
            }

            UnusedModulesDock { width: parent.width; theme: root.theme; settings: root.settings }
        }
    }

    Component {
        id: widgetsPage

        Column {
            width: pageLoader.width
            spacing: settings.panelPadding

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Display"

                StyleSelectorRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Widget style"; value: settings.widgetStyle; choices: ["iconOnly", "iconAndText", "expanded"]; onChoiceRequested: function(choice) { settings.setEnum("widgetStyle", choice, choices, "iconAndText"); } }
            }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Widgets"

                Repeater {
                    model: settings.availableModules

                    WidgetRow {
                        required property string modelData

                        width: parent.width
                        theme: root.theme
                        settings: root.settings
                        moduleName: modelData
                        onConfigureRequested: function(moduleName) { root.openDetail(moduleName); }
                    }
                }
            }
        }
    }

    Component {
        id: osdPage

        Column {
            width: pageLoader.width
            spacing: settings.panelPadding

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Overlay"

                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.osdEnabled; onToggled: function(checked) { settings.setValue("osdEnabled", checked); } }
                StyleSelectorRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Position"; value: settings.osdPosition; choices: ["rightCenter", "leftCenter", "topCenter", "bottomCenter", "topRight", "bottomRight"]; onChoiceRequested: function(choice) { settings.setEnum("osdPosition", choice, choices, "rightCenter"); } }
                StyleSelectorRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Style"; value: settings.osdStyle; choices: ["vertical", "horizontal", "minimal"]; onChoiceRequested: function(choice) { settings.setEnum("osdStyle", choice, choices, "vertical"); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Timeout"; value: settings.osdTimeout; minimum: 700; maximum: 3000; step: 100; suffix: "ms"; onValueRequested: function(value) { settings.setNumber("osdTimeout", value, minimum, maximum); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Size"; value: settings.osdSize; minimum: 0.75; maximum: 1.5; step: 0.05; suffix: "x"; onValueRequested: function(value) { settings.setReal("osdSize", value, minimum, maximum, step); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Opacity"; value: settings.osdOpacity; minimum: 0.55; maximum: 1.0; step: 0.05; suffix: ""; onValueRequested: function(value) { settings.setReal("osdOpacity", value, minimum, maximum, step); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Icon"; checked: settings.osdShowIcon; onToggled: function(checked) { settings.setValue("osdShowIcon", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Percentage"; checked: settings.osdShowPercent; onToggled: function(checked) { settings.setValue("osdShowPercent", checked); } }
            }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Events"

                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Volume keys"; checked: settings.osdVolume; onToggled: function(checked) { settings.setValue("osdVolume", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Brightness keys"; checked: settings.osdBrightness; onToggled: function(checked) { settings.setValue("osdBrightness", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Keyboard backlight"; checked: settings.osdKeyboardBacklight; onToggled: function(checked) { settings.setValue("osdKeyboardBacklight", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Media"; checked: settings.osdMedia; onToggled: function(checked) { settings.setValue("osdMedia", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Battery"; checked: settings.osdBattery; onToggled: function(checked) { settings.setValue("osdBattery", checked); } }

                Row {
                    width: parent.width
                    spacing: settings.effectiveContentSpacing

                    ActionButton { theme: root.theme; settings: root.settings; icon: "󰕾"; label: "Volume"; onPressed: if (root.osd) root.osd.show("󰕾", 0.72, "volume", "Volume") }
                    ActionButton { theme: root.theme; settings: root.settings; icon: "󰃠"; label: "Brightness"; onPressed: if (root.osd) root.osd.show("󰃠", 0.48, "brightness", "Brightness") }
                }
            }
        }
    }

    Component {
        id: wallpaperPage

        Column {
            width: pageLoader.width
            spacing: settings.panelPadding

            WallpaperPreviewCard { width: parent.width; theme: root.theme; settings: root.settings }
            DependencyHealth { width: parent.width; theme: root.theme; settings: root.settings }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Wallpaper"

                Row {
                    width: parent.width
                    spacing: settings.effectiveContentSpacing

                    ActionButton { theme: root.theme; settings: root.settings; icon: "󰑐"; label: "Scan"; onPressed: wallpaper.scan() }
                    ActionButton { theme: root.theme; settings: root.settings; icon: "󰒲"; label: "Random"; onPressed: root.applyRandomWallpaper() }
                    ActionButton { theme: root.theme; settings: root.settings; icon: "󰐊"; label: "Apply selected"; enabled: root.activeWallpaperEntry() !== null; onPressed: root.applySelectedWallpaper() }
                    ActionButton { theme: root.theme; settings: root.settings; icon: ""; label: "Favorite"; enabled: root.activeWallpaperEntry() !== null; onPressed: root.favoriteSelectedWallpaper() }
                    ActionButton { theme: root.theme; settings: root.settings; icon: root.wallpaperFavoritesOnly ? "󰈈" : "󰈇"; label: root.wallpaperFavoritesOnly ? "All" : "Favorites"; onPressed: root.wallpaperFavoritesOnly = !root.wallpaperFavoritesOnly }
                }

                TextInputRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Directory"; value: settings.wallpaperDirectory; onTextRequested: function(text) { settings.setString("wallpaperDirectory", text); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Random mode"; value: settings.wallpaperRandomMode; choices: ["any", "favorites", "dominantColor", "light", "dark"]; onChoiceRequested: function(choice) { settings.setEnum("wallpaperRandomMode", choice, choices, "any"); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Recursive scan"; checked: settings.wallpaperRecursive; onToggled: function(checked) { settings.setValue("wallpaperRecursive", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Apply colors"; checked: settings.wallpaperApplyColors; onToggled: function(checked) { settings.setValue("wallpaperApplyColors", checked); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Matugen"; checked: settings.matugenEnabled; onToggled: function(checked) { settings.setValue("matugenEnabled", checked); } }
            }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Transition"

                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Backend"; value: settings.wallpaperBackend; choices: ["awww"]; onChoiceRequested: function(choice) { settings.setEnum("wallpaperBackend", choice, choices, "awww"); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Type"; value: settings.wallpaperTransition; choices: ["none", "simple", "fade", "wipe", "wave", "grow", "center", "any", "outer", "random"]; onChoiceRequested: function(choice) { settings.setEnum("wallpaperTransition", choice, choices, "grow"); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Resize"; value: settings.wallpaperResizeMode; choices: ["crop", "fit", "stretch", "no"]; onChoiceRequested: function(choice) { settings.setEnum("wallpaperResizeMode", choice, choices, "crop"); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Gravity"; value: settings.wallpaperCropGravity; choices: ["center", "top", "bottom", "left", "right"]; onChoiceRequested: function(choice) { settings.setEnum("wallpaperCropGravity", choice, choices, "center"); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Duration"; value: settings.wallpaperTransitionDuration; minimum: 0.1; maximum: 5.0; step: 0.1; suffix: "s"; onValueRequested: function(value) { settings.setReal("wallpaperTransitionDuration", value, minimum, maximum, step); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "FPS"; value: settings.wallpaperTransitionFps; minimum: 24; maximum: 120; step: 6; suffix: ""; onValueRequested: function(value) { settings.setNumber("wallpaperTransitionFps", value, minimum, maximum); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Angle"; value: settings.wallpaperTransitionAngle; minimum: 0; maximum: 360; step: 15; suffix: "deg"; onValueRequested: function(value) { settings.setNumber("wallpaperTransitionAngle", value, minimum, maximum); } }
                TextInputRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Position"; value: settings.wallpaperTransitionPosition; onTextRequested: function(text) { settings.setString("wallpaperTransitionPosition", text); } }
                TextInputRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Bezier"; value: settings.wallpaperTransitionBezier; onTextRequested: function(text) { settings.setString("wallpaperTransitionBezier", text); } }
            }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Colors"

                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Mode"; value: settings.matugenMode; choices: ["dark", "light"]; onChoiceRequested: function(choice) { settings.setEnum("matugenMode", choice, choices, "dark"); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Scheme"; value: settings.matugenScheme; choices: ["scheme-tonal-spot", "scheme-vibrant", "scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-neutral", "scheme-monochrome"]; onChoiceRequested: function(choice) { settings.setEnum("matugenScheme", choice, choices, "scheme-tonal-spot"); } }
                TextInputRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Palette file"; value: settings.palettePath; onTextRequested: function(text) { settings.setString("palettePath", text); } }
                InfoRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Last palette"; value: settings.wallpaperLastPalette.length > 0 ? settings.wallpaperLastPalette : "none" }
                InfoRow { width: parent.width; theme: root.theme; settings: root.settings; visible: settings.wallpaperLastError.length > 0; label: "Last error"; value: settings.wallpaperLastError }
            }

            SectionHeader { width: parent.width; theme: root.theme; settings: root.settings; title: wallpaper.scanning ? "Scanning" : "Wallpapers" }

            Flow {
                width: parent.width
                spacing: settings.effectiveContentSpacing

                Repeater {
                    model: wallpaper.filtered(root.searchText, root.wallpaperFavoritesOnly)

                    WallpaperTile {
                        required property var modelData

                        width: Math.max(settings.effectiveSpacingXL * 6, (parent.width - parent.spacing * 2) / 3)
                        theme: root.theme
                        settings: root.settings
                        entry: modelData
                        selected: root.selectedWallpaperPath === modelData.path
                        busy: wallpaper.applying && settings.currentWallpaper === modelData.path
                        onApplyRequested: root.selectWallpaper(modelData.path)
                        onFavoriteRequested: wallpaper.toggleFavorite(modelData.path)
                    }
                }
            }
        }
    }

    Component {
        id: motionPage

        Column {
            width: pageLoader.width
            spacing: settings.panelPadding

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Motion"

                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Profile"; value: settings.animationProfile; choices: ["Physical", "Snappy", "Calm", "Instant"]; onChoiceRequested: function(choice) { settings.setAnimationProfile(choice); } }
                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Reduce motion"; checked: settings.reduceMotion; onToggled: function(checked) { settings.setReduceMotion(checked); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Popup motion"; value: settings.popupMotion; choices: ["none", "fade", "slide"]; onChoiceRequested: function(choice) { settings.setEnum("popupMotion", choice, choices, "slide"); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Base duration"; value: settings.animationBaseMs; minimum: 0; maximum: 400; step: 10; suffix: "ms"; onValueRequested: function(value) { settings.setAnimationMs(value); } }
            }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Hints"

                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Tooltips"; checked: settings.tooltipsEnabled; onToggled: function(checked) { settings.setValue("tooltipsEnabled", checked); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Tooltip delay"; value: settings.tooltipDelay; minimum: 250; maximum: 1500; step: 50; suffix: "ms"; onValueRequested: function(value) { settings.setNumber("tooltipDelay", value, minimum, maximum); } }
                SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Workspace toast"; value: settings.workspaceToastTimeout; minimum: 500; maximum: 2500; step: 100; suffix: "ms"; onValueRequested: function(value) { settings.setNumber("workspaceToastTimeout", value, minimum, maximum); } }
            }
        }
    }

    Component {
        id: advancedPage

        Column {
            width: pageLoader.width
            spacing: settings.panelPadding

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Module popups"

                ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Pinned popups"; checked: settings.modulePopupPinned; onToggled: function(checked) { settings.setValue("modulePopupPinned", checked); } }
                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Default tab"; value: settings.modulePopupDefaultTab; choices: ["Overview", "Controls", "Diagnostics"]; onChoiceRequested: function(choice) { settings.setEnum("modulePopupDefaultTab", choice, choices, "Overview"); } }
            }

            SectionBlock {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "System"

                ChoiceRow {
                    width: parent.width
                    theme: root.theme
                    settings: root.settings
                    label: "Compositor"
                    value: settings.compositorBackend
                    choices: ["auto", "niri", "hyprland"]
                    onChoiceRequested: function(choice) { settings.setObjectValue("compositor", "backend", choice); }
                }

                ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Palette source"; value: settings.paletteSource; choices: ["wallpaper", "manual", "file"]; onChoiceRequested: function(choice) { settings.setEnum("paletteSource", choice, choices, "wallpaper"); } }
                TextInputRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Manual accent"; value: settings.manualAccent; onTextRequested: function(text) { settings.setString("manualAccent", text); } }
                InfoRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Schema"; value: String(settings.version) }
                InfoRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Palette"; value: settings.palettePath }
                InfoRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Current wallpaper"; value: settings.currentWallpaper.length > 0 ? settings.currentWallpaper : "none" }
            }
        }
    }

    Component {
        id: clockDetail
        WidgetDetailBase {
            moduleName: "clock"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("clock"); onToggled: function(checked) { settings.setModuleEnabled("clock", checked); } }
            TextInputRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Format"; value: settings.clockFormat; onTextRequested: function(text) { settings.setClockFormat(text); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show seconds"; checked: settings.clockShowSeconds; onToggled: function(checked) { settings.setClockShowSeconds(checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Week number"; checked: settings.clockPanelShowWeek; onToggled: function(checked) { settings.setValue("clockPanelShowWeek", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Day of year"; checked: settings.clockPanelShowDayOfYear; onToggled: function(checked) { settings.setValue("clockPanelShowDayOfYear", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Timezone"; checked: settings.clockPanelShowTimezone; onToggled: function(checked) { settings.setValue("clockPanelShowTimezone", checked); } }
        }
    }

    Component {
        id: audioDetail
        WidgetDetailBase {
            moduleName: "audio"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("audio"); onToggled: function(checked) { settings.setModuleEnabled("audio", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show percentage"; checked: settings.audioShowPercentage; onToggled: function(checked) { settings.setValue("audioShowPercentage", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Device name"; checked: settings.audioShowDeviceName; onToggled: function(checked) { settings.setValue("audioShowDeviceName", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Volume OSD"; checked: settings.osdVolume; onToggled: function(checked) { settings.setValue("osdVolume", checked); } }
            ActionButton { theme: root.theme; settings: root.settings; icon: "󰕾"; label: "Test OSD"; onPressed: if (root.osd) root.osd.show("󰕾", 0.72, "volume", "Volume") }
        }
    }

    Component {
        id: networkDetail
        WidgetDetailBase {
            moduleName: "network"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("network"); onToggled: function(checked) { settings.setModuleEnabled("network", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show speed"; checked: settings.networkShowSpeed; onToggled: function(checked) { settings.setValue("networkShowSpeed", checked); } }
            TextInputRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Interface"; value: settings.networkInterfaceName; onTextRequested: function(text) { settings.setString("networkInterfaceName", text); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Polling"; value: settings.networkPollMs; minimum: 2000; maximum: 30000; step: 500; suffix: "ms"; onValueRequested: function(value) { settings.setPollingInterval("networkMs", value, minimum, maximum); } }
        }
    }

    Component {
        id: batteryDetail
        WidgetDetailBase {
            moduleName: "battery"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("battery"); onToggled: function(checked) { settings.setModuleEnabled("battery", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show percentage"; checked: settings.batteryShowPercentage; onToggled: function(checked) { settings.setValue("batteryShowPercentage", checked); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Critical threshold"; value: settings.batteryCriticalThreshold; minimum: 5; maximum: 30; step: 1; suffix: "%"; onValueRequested: function(value) { settings.setNumber("batteryCriticalThreshold", value, minimum, maximum); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Fallback polling"; value: settings.batteryFallbackPollMs; minimum: 10000; maximum: 120000; step: 5000; suffix: "ms"; onValueRequested: function(value) { settings.setPollingInterval("batteryFallbackMs", value, minimum, maximum); } }
        }
    }

    Component {
        id: cpuDetail
        WidgetDetailBase {
            moduleName: "cpu"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("cpu"); onToggled: function(checked) { settings.setModuleEnabled("cpu", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Graph on bar"; checked: settings.cpuShowGraph; onToggled: function(checked) { settings.setValue("cpuShowGraph", checked); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Polling"; value: settings.cpuPollMs; minimum: 5000; maximum: 60000; step: 1000; suffix: "ms"; onValueRequested: function(value) { settings.setPollingInterval("cpuMs", value, minimum, maximum); } }
        }
    }

    Component {
        id: memoryDetail
        WidgetDetailBase {
            moduleName: "memory"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("memory"); onToggled: function(checked) { settings.setModuleEnabled("memory", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Graph on bar"; checked: settings.memoryShowGraph; onToggled: function(checked) { settings.setValue("memoryShowGraph", checked); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Polling"; value: settings.memoryPollMs; minimum: 1000; maximum: 30000; step: 500; suffix: "ms"; onValueRequested: function(value) { settings.setPollingInterval("memoryMs", value, minimum, maximum); } }
        }
    }

    Component {
        id: mediaDetail
        WidgetDetailBase {
            moduleName: "media"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("media"); onToggled: function(checked) { settings.setModuleEnabled("media", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Transport controls"; checked: settings.mediaShowControls; onToggled: function(checked) { settings.setValue("mediaShowControls", checked); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Title length"; value: settings.mediaMaxTitleLength; minimum: 12; maximum: 80; step: 1; suffix: " chars"; onValueRequested: function(value) { settings.setNumber("mediaMaxTitleLength", value, minimum, maximum); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Max width"; value: settings.mediaMaxWidth; minimum: 80; maximum: 320; step: 10; suffix: "px"; onValueRequested: function(value) { settings.setNumber("mediaMaxWidth", value, minimum, maximum); } }
        }
    }

    Component {
        id: brightnessDetail
        WidgetDetailBase {
            moduleName: "brightness"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("brightness"); onToggled: function(checked) { settings.setModuleEnabled("brightness", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show percentage"; checked: settings.brightnessShowPercentage; onToggled: function(checked) { settings.setValue("brightnessShowPercentage", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Brightness OSD"; checked: settings.osdBrightness; onToggled: function(checked) { settings.setValue("osdBrightness", checked); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Scroll step"; value: settings.brightnessStep; minimum: 1; maximum: 20; step: 1; suffix: "%"; onValueRequested: function(value) { settings.setNumber("brightnessStep", value, minimum, maximum); } }
        }
    }

    Component {
        id: focusedWindowDetail
        WidgetDetailBase {
            moduleName: "focusedWindow"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("focusedWindow"); onToggled: function(checked) { settings.setModuleEnabled("focusedWindow", checked); } }
            ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Display"; value: settings.focusedWindowDisplayMode; choices: ["allWorkspaceApps", "iconsOnly", "focusedTitle"]; onChoiceRequested: function(choice) { settings.setEnum("focusedWindowDisplayMode", choice, choices, "allWorkspaceApps"); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show title"; checked: settings.focusedWindowShowTitle; onToggled: function(checked) { settings.setValue("focusedWindowShowTitle", checked); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Title width"; value: settings.focusedWindowMaxWidth; minimum: 120; maximum: 520; step: 20; suffix: "px"; onValueRequested: function(value) { settings.setNumber("focusedWindowMaxWidth", value, minimum, maximum); } }
        }
    }

    Component {
        id: workspaceDetail
        WidgetDetailBase {
            moduleName: "workspaces"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("workspaces"); onToggled: function(checked) { settings.setModuleEnabled("workspaces", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show numbers"; checked: settings.workspaceShowNumbers; onToggled: function(checked) { settings.setValue("workspaceShowNumbers", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Occupied marker"; checked: settings.workspaceShowOccupied; onToggled: function(checked) { settings.setValue("workspaceShowOccupied", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Scroll switch"; checked: settings.workspaceScrollEnabled; onToggled: function(checked) { settings.setValue("workspaceScrollEnabled", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Wrap scroll"; checked: settings.workspaceScrollWrap; onToggled: function(checked) { settings.setValue("workspaceScrollWrap", checked); } }
            ChoiceRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Indicator"; value: settings.workspaceIndicatorStyle; choices: ["pill", "underline", "dot"]; onChoiceRequested: function(choice) { settings.setEnum("workspaceIndicatorStyle", choice, choices, "pill"); } }
        }
    }

    Component {
        id: powerProfileDetail
        WidgetDetailBase {
            moduleName: "powerProfile"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("powerProfile"); onToggled: function(checked) { settings.setModuleEnabled("powerProfile", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show label"; checked: settings.powerProfileShowLabel; onToggled: function(checked) { settings.setValue("powerProfileShowLabel", checked); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Polling"; value: settings.powerProfilePollMs; minimum: 10000; maximum: 120000; step: 5000; suffix: "ms"; onValueRequested: function(value) { settings.setPollingInterval("powerProfileMs", value, minimum, maximum); } }
        }
    }

    Component {
        id: trayDetail
        WidgetDetailBase {
            moduleName: "tray"
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled("tray"); onToggled: function(checked) { settings.setModuleEnabled("tray", checked); } }
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Compact"; checked: settings.trayCompact; onToggled: function(checked) { settings.setValue("trayCompact", checked); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Visible icons"; value: settings.trayMaxVisible; minimum: 2; maximum: 12; step: 1; suffix: ""; onValueRequested: function(value) { settings.setNumber("trayMaxVisible", value, minimum, maximum); } }
            SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Icon size"; value: settings.trayIconSize; minimum: 12; maximum: 24; step: 1; suffix: "px"; onValueRequested: function(value) { settings.setNumber("trayIconSize", value, minimum, maximum); } }
        }
    }

    Component {
        id: genericDetail
        WidgetDetailBase {
            moduleName: root.detailPage
            ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled(root.detailPage); onToggled: function(checked) { settings.setModuleEnabled(root.detailPage, checked); } }
        }
    }

    component WidgetDetailBase: SectionBlock {
        property string moduleName: ""
        default property alias controls: detailControls.data

        width: pageLoader.width
        theme: root.theme
        settings: root.settings
        title: settings.moduleLabel(moduleName)

        Column {
            id: detailControls

            width: parent.width
            spacing: settings.effectiveContentSpacing

            ActionButton {
                theme: root.theme
                settings: root.settings
                icon: ""
                label: "Return to widgets"
                onPressed: root.back()
            }
        }
    }

    component SectionHeader: Column {
        id: header

        property var theme
        property var settings
        property string title: ""

        spacing: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.5))

        Row {
            width: parent.width
            height: Math.max(settings.effectiveSpacingL, titleText.implicitHeight)
            spacing: settings.effectiveContentSpacing

            Rectangle {
                width: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.75))
                height: parent.height
                radius: width / 2
                color: theme.accent
                opacity: 0.72
                antialiasing: true
            }

            Text {
                id: titleText
                width: parent.width - parent.spacing - settings.effectiveGroupPadding
                anchors.verticalCenter: parent.verticalCenter
                text: header.title
                color: theme.text
                elide: Text.ElideRight
                font.family: settings.fontFamily
                font.pixelSize: Math.round(settings.effectiveFontSize * 1.08)
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            width: parent.width
            height: settings.effectiveBorderWidth
            radius: height / 2
            color: theme.alpha(theme.border, 0.3)
            antialiasing: true
        }
    }

    component SectionBlock: Rectangle {
        id: block

        property var theme
        property var settings
        property string title: ""
        default property alias content: body.data

        implicitHeight: sectionShell.implicitHeight + settings.effectivePillPadding * 2
        radius: settings.effectiveRadiusM
        color: theme.alpha(theme.surfaceStrong, 0.36)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        clip: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.45))
            color: theme.gloss
            antialiasing: true
        }

        Column {
            id: sectionShell

            x: settings.effectivePillPadding
            y: settings.effectivePillPadding
            width: parent.width - settings.effectivePillPadding * 2
            spacing: settings.effectiveContentSpacing

            Row {
                width: parent.width
                height: Math.max(settings.effectiveSpacingL, sectionTitle.implicitHeight)
                spacing: settings.effectiveContentSpacing

                Rectangle {
                    width: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.75))
                    height: parent.height
                    radius: width / 2
                    color: theme.accent
                    opacity: 0.72
                    antialiasing: true
                }

                Text {
                    id: sectionTitle

                    width: parent.width - parent.spacing - settings.effectiveGroupPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: block.title
                    color: theme.text
                    elide: Text.ElideRight
                    font.family: settings.fontFamily
                    font.pixelSize: Math.round(settings.effectiveFontSize * 1.02)
                    font.weight: Font.DemiBold
                }
            }

            Rectangle {
                width: parent.width
                height: settings.effectiveBorderWidth
                radius: height / 2
                color: theme.alpha(theme.border, 0.24)
                antialiasing: true
            }

            Column {
                id: body

                width: parent.width
                spacing: settings.effectiveContentSpacing
            }
        }
    }

    component PalettePreview: Flow {
        id: paletteRoot

        property var theme
        property var settings

        spacing: settings.effectiveContentSpacing

        Swatch { theme: paletteRoot.theme; settings: paletteRoot.settings; label: "Accent"; swatchColor: theme.accent }
        Swatch { theme: paletteRoot.theme; settings: paletteRoot.settings; label: "Surface"; swatchColor: theme.surfacePanel }
        Swatch { theme: paletteRoot.theme; settings: paletteRoot.settings; label: "Text"; swatchColor: theme.text }
        Swatch { theme: paletteRoot.theme; settings: paletteRoot.settings; label: "Urgent"; swatchColor: theme.urgent }
    }

    component ShellPreview: Rectangle {
        id: previewRoot

        property var theme
        property var settings

        implicitHeight: Math.max(settings.effectiveSpacingXL * 4.2, previewText.implicitHeight + settings.effectivePillPadding * 2)
        radius: settings.effectiveRadiusM
        color: theme.alpha(theme.surfaceStrong, 0.30)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        clip: true
        visible: settings.settingsPreviewEnabled

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Column {
            id: previewText

            anchors.left: parent.left
            anchors.leftMargin: settings.effectivePillPadding * 2
            anchors.right: previewCanvas.left
            anchors.rightMargin: settings.effectiveSpacingM
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.5))

            Text {
                width: parent.width
                text: "Live shell preview"
                color: theme.text
                elide: Text.ElideRight
                font.family: settings.fontFamily
                font.pixelSize: Math.round(settings.effectiveFontSize * 1.04)
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: root.displayLabel(settings.themeRecipe) + " / " + root.displayLabel(settings.settingsPanelAnchor)
                color: theme.textMuted
                elide: Text.ElideRight
                font.family: settings.fontFamily
                font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.78))
            }
        }

        Rectangle {
            id: previewCanvas

            anchors.right: parent.right
            anchors.rightMargin: settings.effectivePillPadding * 2
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(settings.effectiveSpacingXL * 8, parent.width * 0.42)
            height: Math.max(settings.effectiveSpacingXL * 2.3, settings.controlHeight * 2)
            radius: settings.effectiveRadiusM
            color: theme.alpha(theme.surfaceStrong, 0.22)
            border.color: theme.outlineSubtle
            border.width: settings.effectiveBorderWidth
            antialiasing: true
            clip: true

            Rectangle {
                visible: settings.barPosition === "top"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: settings.effectiveBorderWidth
                color: theme.alpha(theme.text, 0.08)
            }

            Rectangle {
                visible: settings.barPosition === "bottom"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: settings.effectiveBorderWidth
                color: theme.alpha(theme.text, 0.08)
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                height: settings.controlHeight
                y: settings.barPosition === "bottom" ? parent.height - height - settings.effectiveSpacingS : settings.effectiveSpacingS

                Rectangle {
                    visible: settings.barStyle === "solid"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: settings.effectiveSpacingS
                    anchors.rightMargin: settings.effectiveSpacingS
                    height: Math.round(settings.controlHeight * 0.72)
                    radius: settings.effectiveRadiusS
                    color: theme.alpha(theme.accent, 0.18)
                    border.color: settings.barBorderEnabled ? theme.border : theme.alpha(theme.accent, 0.24)
                    border.width: settings.effectiveBorderWidth
                    antialiasing: true
                }

                Rectangle {
                    visible: settings.barStyle === "pill"
                    anchors.centerIn: parent
                    width: settings.effectiveSpacingXL * 5.4
                    height: Math.round(settings.controlHeight * 0.76)
                    radius: height / 2
                    color: theme.alpha(theme.accent, 0.18)
                    border.color: settings.barBorderEnabled ? theme.border : theme.alpha(theme.accent, 0.24)
                    border.width: settings.effectiveBorderWidth
                    antialiasing: true
                }

                Row {
                    visible: settings.barStyle === "islands"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: settings.effectiveSpacingS
                    anchors.rightMargin: settings.effectiveSpacingS
                    spacing: settings.effectiveContentSpacing

                    Rectangle { width: settings.effectiveSpacingXL * 2.8; height: Math.round(settings.controlHeight * 0.76); radius: height / 2; color: theme.alpha(theme.accent, 0.18); border.color: settings.barBorderEnabled ? theme.border : theme.alpha(theme.accent, 0.24); border.width: settings.effectiveBorderWidth; antialiasing: true }
                    Item { width: Math.max(0, parent.width - settings.effectiveSpacingXL * 6.7 - parent.spacing * 2); height: 1 }
                    Rectangle { width: settings.effectiveSpacingXL * 1.9; height: Math.round(settings.controlHeight * 0.76); radius: height / 2; color: theme.alpha(theme.accent, 0.18); border.color: settings.barBorderEnabled ? theme.border : theme.alpha(theme.accent, 0.24); border.width: settings.effectiveBorderWidth; antialiasing: true }
                    Rectangle { width: settings.effectiveSpacingXL * 2.0; height: Math.round(settings.controlHeight * 0.76); radius: height / 2; color: theme.alpha(theme.accent, 0.18); border.color: settings.barBorderEnabled ? theme.border : theme.alpha(theme.accent, 0.24); border.width: settings.effectiveBorderWidth; antialiasing: true }
                }
            }
        }
    }

    component PresetDeck: SectionBlock {
        id: deck

        theme: root.theme
        settings: root.settings
        title: "Look recipes"

        Flow {
            width: parent.width
            spacing: settings.effectiveContentSpacing

            Repeater {
                model: Array.from(settings.themeRecipes || [])

                PresetCard {
                    required property var modelData

                    width: Math.max(settings.effectiveSpacingXL * 8.1, (parent.width - parent.spacing) / 2)
                    theme: root.theme
                    settings: root.settings
                    recipe: modelData
                    selected: settings.themeRecipe === String(modelData.id)
                    onPressed: settings.setThemeRecipe(String(modelData.id))
                }
            }
        }
    }

    component PresetCard: Rectangle {
        id: recipeCard

        property var theme
        property var settings
        property var recipe
        property bool selected: false

        signal pressed()

        implicitHeight: settings.controlHeight + settings.effectiveSpacingL
        radius: settings.effectiveRadiusM
        color: selected ? theme.surfaceActive : hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceStrong, 0.26)
        border.color: selected ? theme.outlineActive : hover.containsMouse ? theme.outlineSubtle : theme.transparent
        border.width: settings.effectiveBorderWidth
        scale: selected ? 1.012 : hover.containsMouse ? 1.006 : 1
        antialiasing: true
        clip: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on scale { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }

        Row {
            anchors.fill: parent
            anchors.margins: settings.effectiveGroupPadding
            spacing: settings.effectiveContentSpacing

            Rectangle {
                width: settings.controlHeight
                height: width
                anchors.verticalCenter: parent.verticalCenter
                radius: settings.effectivePillRadius
                color: theme.alpha(theme.accent, selected ? 0.20 : 0.10)
                border.color: theme.alpha(theme.accent, selected ? 0.36 : 0.18)
                border.width: settings.effectiveBorderWidth
                antialiasing: true

                Text {
                    anchors.centerIn: parent
                    text: String(recipe.icon || "󰣇")
                    color: selected ? theme.accent : theme.textMuted
                    font.family: settings.fontFamily
                    font.pixelSize: settings.effectiveIconSize
                }
            }

            Column {
                width: parent.width - settings.controlHeight - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                Text { width: parent.width; text: String(recipe.label || "Recipe"); color: selected ? theme.text : theme.text; elide: Text.ElideRight; font.family: settings.fontFamily; font.pixelSize: settings.effectiveFontSize; font.weight: Font.DemiBold }
                Text { width: parent.width; text: String(recipe.detail || ""); color: theme.textMuted; elide: Text.ElideRight; font.family: settings.fontFamily; font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.76)) }
            }
        }

        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: recipeCard.pressed() }
    }

    component OverviewHero: Rectangle {
        id: hero

        property var theme
        property var settings

        implicitHeight: Math.max(settings.effectiveSpacingXL * 5, heroText.implicitHeight + settings.effectivePillPadding * 2)
        radius: settings.effectiveRadiusM
        color: theme.alpha(theme.surfaceStrong, 0.42)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.9))
            color: theme.accent
            opacity: 0.85
            antialiasing: true
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.5))
            color: theme.gloss
            antialiasing: true
        }

        Column {
            id: heroText

            anchors.left: parent.left
            anchors.right: statusColumn.left
            anchors.leftMargin: settings.effectivePillPadding * 2
            anchors.rightMargin: settings.effectiveSpacingM
            anchors.verticalCenter: parent.verticalCenter
            spacing: settings.effectiveContentSpacing

            Text {
                width: parent.width
                text: "Calypso control surface"
                color: theme.text
                elide: Text.ElideRight
                font.family: settings.fontFamily
                font.pixelSize: Math.round(settings.effectiveFontSize * 1.38)
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: root.displayLabel(settings.barStyle) + " bar, " + root.displayLabel(settings.widgetStyle).toLowerCase() + " widgets, " + (settings.reduceMotion ? "instant motion" : settings.animationProfile.toLowerCase() + " motion")
                color: theme.textMuted
                elide: Text.ElideRight
                font.family: settings.fontFamily
                font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.86))
            }

            Flow {
                width: parent.width
                spacing: settings.effectiveContentSpacing

                ActionButton { theme: hero.theme; settings: hero.settings; icon: "󰸌"; label: root.displayLabel(settings.visualPreset); selected: true; onPressed: root.showPage("appearance") }
                ActionButton { theme: hero.theme; settings: hero.settings; icon: "󰙀"; label: root.displayLabel(settings.settingsPreset); onPressed: root.showPage("layout") }
                ActionButton { theme: hero.theme; settings: hero.settings; icon: "󰸉"; label: root.displayLabel(settings.paletteSource); onPressed: root.showPage("wallpaper") }
            }
        }

        Column {
            id: statusColumn

            anchors.right: parent.right
            anchors.rightMargin: settings.effectivePillPadding * 2
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(settings.effectiveSpacingXL * 6, parent.width * 0.28)
            spacing: settings.effectiveContentSpacing

            MetricChip { width: parent.width; theme: hero.theme; settings: hero.settings; label: "Bar"; value: settings.barHeight + "px / " + settings.barPosition }
            MetricChip { width: parent.width; theme: hero.theme; settings: hero.settings; label: "Modules"; value: settings.leftModules.length + "-" + settings.centerModules.length + "-" + settings.rightModules.length }
            MetricChip { width: parent.width; theme: hero.theme; settings: hero.settings; label: "OSD"; value: settings.osdEnabled ? root.displayLabel(settings.osdPosition) : "off" }
        }
    }

    component MetricChip: Rectangle {
        id: metric

        property var theme
        property var settings
        property string label: ""
        property string value: ""

        implicitHeight: Math.max(settings.controlHeight, labelText.implicitHeight + valueText.implicitHeight + settings.effectiveGroupPadding)
        radius: settings.effectivePillRadius
        color: theme.alpha(theme.text, 0.035)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true

        Text {
            id: labelText
            anchors.left: parent.left
            anchors.leftMargin: settings.effectivePillPadding
            anchors.verticalCenter: parent.verticalCenter
            text: metric.label
            color: theme.textMuted
            font.family: settings.fontFamily
            font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.72))
            font.weight: Font.Medium
        }

        Text {
            id: valueText
            anchors.right: parent.right
            anchors.rightMargin: settings.effectivePillPadding
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - labelText.implicitWidth - settings.effectivePillPadding * 3
            text: metric.value
            color: theme.text
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            font.family: settings.fontFamily
            font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.82))
            font.weight: Font.DemiBold
        }
    }

    component Swatch: Rectangle {
        id: swatchRoot

        property var theme
        property var settings
        property string label: ""
        property color swatchColor: theme.accent

        implicitWidth: chip.width + labelText.implicitWidth + settings.effectivePillPadding * 3
        implicitHeight: settings.controlHeight
        radius: settings.effectivePillRadius
        color: theme.alpha(theme.text, 0.035)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true

        Rectangle {
            id: chip

            anchors.left: parent.left
            anchors.leftMargin: settings.effectivePillPadding
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(settings.controlHeight * 0.55)
            height: width
            radius: width / 2
            color: swatchRoot.swatchColor
            border.color: theme.alpha(theme.text, 0.24)
            border.width: settings.effectiveBorderWidth
            antialiasing: true
            Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        }

        Text {
            id: labelText

            anchors.left: chip.right
            anchors.leftMargin: settings.effectiveContentSpacing
            anchors.verticalCenter: parent.verticalCenter
            text: swatchRoot.label
            color: theme.text
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
        }
    }

    component QuickCard: Rectangle {
        id: card

        property var theme
        property var settings
        property string icon: ""
        property string title: ""
        property string detail: ""

        signal pressed()

        implicitWidth: Math.max(settings.effectiveSpacingXL * 8, (pageLoader.width - settings.panelPadding) / 2)
        implicitHeight: settings.effectiveSpacingXL * 3.2
        radius: settings.effectiveRadiusM
        color: hover.containsMouse ? theme.alpha(theme.surfaceStrong, 0.62) : theme.alpha(theme.surfaceStrong, 0.34)
        border.color: hover.containsMouse ? theme.outlineActive : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        scale: hover.containsMouse ? 1.012 : 1
        antialiasing: true
        clip: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on scale { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.75))
            color: theme.accent
            opacity: hover.containsMouse ? 0.88 : 0.48
            antialiasing: true

            Behavior on opacity { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }
        }

        Row {
            anchors.fill: parent
            anchors.margins: settings.effectivePillPadding
            spacing: settings.effectiveContentSpacing

            Rectangle {
                width: settings.controlHeight
                height: width
                anchors.verticalCenter: parent.verticalCenter
                radius: settings.effectivePillRadius
                color: theme.surfaceActive
                border.color: theme.alpha(theme.accent, 0.22)
                border.width: settings.effectiveBorderWidth
                antialiasing: true

                Text {
                    anchors.centerIn: parent
                    text: card.icon
                    color: theme.accent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: settings.fontFamily
                    font.pixelSize: settings.effectiveIconSize
                }
            }

            Column {
                width: parent.width - settings.controlHeight - arrow.width - parent.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.3))

                Text { width: parent.width; text: card.title; color: theme.text; elide: Text.ElideRight; font.family: settings.fontFamily; font.pixelSize: settings.effectiveFontSize; font.weight: Font.DemiBold }
                Text { width: parent.width; text: card.detail; color: theme.textMuted; elide: Text.ElideRight; font.family: settings.fontFamily; font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.78)) }
            }

            Text {
                id: arrow

                width: settings.effectiveIconSize
                height: parent.height
                text: ""
                color: hover.containsMouse ? theme.accent : theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: settings.fontFamily
                font.pixelSize: Math.max(8, Math.round(settings.effectiveIconSize * 0.75))

                Behavior on color { ColorAnimation { duration: settings.motionNormal } }
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.pressed()
        }
    }

    component IconButton: Rectangle {
        id: button

        property var theme
        property var settings
        property string icon: ""

        signal pressed()

        implicitWidth: settings.controlHeight
        implicitHeight: settings.controlHeight
        width: implicitWidth
        height: implicitHeight
        radius: settings.effectivePillRadius
        color: hover.containsMouse ? theme.surfaceHover : theme.transparent
        border.color: hover.containsMouse ? theme.outlineSubtle : theme.transparent
        border.width: settings.effectiveBorderWidth
        opacity: visible ? (enabled ? 1 : 0.35) : 0
        scale: hover.containsMouse && enabled ? 1.015 : 1
        antialiasing: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on scale { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: button.icon
            color: theme.text
            font.family: settings.fontFamily
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

    component NavButton: Rectangle {
        id: navRoot

        property var theme
        property var settings
        property string icon: ""
        property string label: ""
        property bool selected: false

        signal pressed()

        implicitHeight: settings.controlHeight + Math.round(settings.effectiveGroupPadding * 0.45)
        radius: settings.effectivePillRadius
        color: selected ? theme.surfaceActive : hover.containsMouse ? theme.surfaceHover : theme.transparent
        border.color: selected ? theme.outlineActive : hover.containsMouse ? theme.outlineSubtle : theme.transparent
        border.width: settings.effectiveBorderWidth
        scale: selected ? 1.01 : hover.containsMouse ? 1.006 : 1
        antialiasing: true
        clip: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on scale { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.65))
            height: selected ? parent.height - settings.effectiveGroupPadding : settings.effectiveSpacingM
            radius: width / 2
            color: selected ? theme.accent : theme.transparent
            antialiasing: true

            Behavior on height { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: settings.effectivePillPadding
            anchors.rightMargin: settings.effectivePillPadding
            spacing: settings.effectiveContentSpacing

            Rectangle {
                width: settings.controlHeight - settings.effectiveGroupPadding
                height: width
                anchors.verticalCenter: parent.verticalCenter
                radius: settings.effectivePillRadius
                color: navRoot.selected ? theme.alpha(theme.accent, 0.16) : theme.alpha(theme.text, 0.035)
                antialiasing: true

                Text {
                    anchors.centerIn: parent
                    text: navRoot.icon
                    color: navRoot.selected ? theme.accent : theme.textMuted
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.family: settings.fontFamily
                    font.pixelSize: settings.effectiveIconSize
                }
            }

            Text {
                width: parent.width - settings.controlHeight - parent.spacing
                height: parent.height
                text: navRoot.label
                color: navRoot.selected ? theme.text : theme.textMuted
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                font.family: settings.fontFamily
                font.pixelSize: settings.effectiveFontSize
                font.weight: navRoot.selected ? Font.DemiBold : Font.Medium
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: navRoot.pressed()
        }
    }

    component SearchBox: Rectangle {
        id: search

        property var theme
        property var settings
        property string text: ""

        signal textRequested(string text)

        implicitHeight: settings.controlHeight
        radius: settings.effectivePillRadius
        color: editor.activeFocus ? theme.surfaceHover : theme.alpha(theme.surfaceStrong, 0.32)
        border.color: editor.activeFocus ? theme.outlineActive : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        clip: true
        antialiasing: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: settings.effectivePillPadding
            anchors.verticalCenter: parent.verticalCenter
            text: "󰍉"
            color: theme.textMuted
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveIconSize
        }

        TextInput {
            id: editor

            anchors.left: parent.left
            anchors.leftMargin: settings.effectivePillPadding * 2 + settings.effectiveIconSize
            anchors.right: clearButton.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            text: search.text
            color: theme.text
            selectionColor: theme.accentSoft
            selectedTextColor: theme.text
            clip: true
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            verticalAlignment: TextInput.AlignVCenter
            onTextEdited: search.textRequested(editor.text)
        }

        IconButton {
            id: clearButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            theme: search.theme
            settings: search.settings
            icon: ""
            visible: search.text.length > 0
            onPressed: search.textRequested("")
        }
    }

    component ToggleSwitch: Rectangle {
        id: switchRoot

        property var theme
        property var settings
        property bool checked: false
        readonly property real knobMargin: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.5))

        signal toggled(bool checked)

        implicitWidth: Math.round(settings.controlHeight * 1.72)
        implicitHeight: Math.round(settings.controlHeight * 0.72)
        radius: height / 2
        color: checked ? theme.accent : theme.surfaceHover
        border.color: checked ? theme.alpha(theme.accent, 0.48) : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        opacity: enabled ? 1 : 0.35
        antialiasing: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Rectangle {
            width: parent.height - switchRoot.knobMargin * 2
            height: width
            radius: width / 2
            x: switchRoot.checked ? parent.width - width - switchRoot.knobMargin : switchRoot.knobMargin
            y: switchRoot.knobMargin
            color: theme.controlKnob
            antialiasing: true

            Behavior on x {
                enabled: settings.motionNormal > 0
                SpringAnimation { spring: 4.0; damping: 0.8; epsilon: 0.2 }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: switchRoot.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: switchRoot.toggled(!switchRoot.checked)
        }
    }

    component ToggleRow: Item {
        id: toggleRoot

        property var theme
        property var settings
        property string label: ""
        property bool checked: false

        signal toggled(bool checked)

        implicitHeight: Math.max(settings.controlHeight + settings.effectiveGroupPadding, labelText.implicitHeight + settings.effectiveGroupPadding)

        Rectangle {
            anchors.fill: parent
            radius: settings.effectivePillRadius
            color: hover.containsMouse ? theme.surfaceHover : theme.transparent
            border.color: hover.containsMouse ? theme.outlineSubtle : theme.transparent
            border.width: settings.effectiveBorderWidth
            antialiasing: true

            Behavior on color { ColorAnimation { duration: settings.motionNormal } }
            Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }
        }

        Text {
            id: labelText
            anchors.left: parent.left
            anchors.leftMargin: settings.effectiveGroupPadding
            anchors.right: toggle.left
            anchors.rightMargin: settings.effectivePillPadding
            anchors.verticalCenter: parent.verticalCenter
            text: toggleRoot.label
            color: toggleRoot.enabled ? theme.text : theme.textMuted
            elide: Text.ElideRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.Medium
        }

        ToggleSwitch {
            id: toggle
            anchors.right: parent.right
            anchors.rightMargin: settings.effectiveGroupPadding
            anchors.verticalCenter: parent.verticalCenter
            enabled: toggleRoot.enabled
            theme: toggleRoot.theme
            settings: toggleRoot.settings
            checked: toggleRoot.checked
            onToggled: function(checked) { toggleRoot.toggled(checked); }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            enabled: toggleRoot.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: toggleRoot.toggled(!toggleRoot.checked)
        }
    }

    component SliderRow: Item {
        id: sliderRoot

        property var theme
        property var settings
        property string label: ""
        property real value: 0
        property real minimum: 0
        property real maximum: 100
        property real step: 1
        property string suffix: ""

        signal valueRequested(real value)

        function clamped(number) { return Math.max(minimum, Math.min(maximum, number)); }
        function snapped(number) {
            const safeStep = step > 0 ? step : 1;
            return clamped(minimum + Math.round((number - minimum) / safeStep) * safeStep);
        }
        function ratio() {
            if (maximum <= minimum) return 0;
            return (clamped(value) - minimum) / (maximum - minimum);
        }
        function displayText() {
            const decimals = step < 0.1 ? 2 : step < 1 ? 1 : 0;
            return Number(value).toFixed(decimals).replace(/\.0+$/, "").replace(/(\.\d*[1-9])0+$/, "$1") + suffix;
        }

        implicitHeight: labelText.implicitHeight + settings.effectiveContentSpacing + settings.controlHeight + settings.effectiveGroupPadding
        opacity: enabled ? 1 : 0.45

        Text {
            id: labelText
            anchors.left: parent.left
            anchors.right: valueText.left
            anchors.rightMargin: settings.effectiveContentSpacing
            anchors.top: parent.top
            text: sliderRoot.label
            color: theme.text
            elide: Text.ElideRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.Medium
        }

        Text {
            id: valueText
            anchors.right: parent.right
            anchors.top: parent.top
            width: Math.round(settings.effectiveFontSize * 6)
            text: sliderRoot.displayText()
            color: theme.accent
            horizontalAlignment: Text.AlignRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.DemiBold
        }

        Item {
            id: trackArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: labelText.bottom
            anchors.topMargin: settings.effectiveContentSpacing
            height: settings.controlHeight

            Rectangle {
                id: track
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.82))
                radius: height / 2
                color: theme.alpha(theme.text, 0.12)
                antialiasing: true

                Rectangle {
                    width: Math.max(0, knob.x + knob.width / 2)
                    height: parent.height
                    radius: parent.radius
                    color: theme.alpha(theme.accent, 0.38)
                    antialiasing: true
                    Behavior on width { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: settings.motionNormal } }
                }
            }

            Rectangle {
                id: knob
                width: Math.round(settings.controlHeight * 0.58)
                height: width
                radius: width / 2
                x: sliderRoot.ratio() * Math.max(0, trackArea.width - width)
                anchors.verticalCenter: parent.verticalCenter
                color: theme.accent
                border.color: theme.alpha(theme.text, 0.32)
                border.width: settings.effectiveBorderWidth
                antialiasing: true
                Behavior on x { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: settings.motionNormal } }
            }

            MouseArea {
                anchors.fill: parent
                enabled: sliderRoot.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                function commit(mouseX) {
                    if (trackArea.width <= 0) return;
                    const bounded = Math.max(0, Math.min(trackArea.width, mouseX));
                    const raw = sliderRoot.minimum + (bounded / trackArea.width) * (sliderRoot.maximum - sliderRoot.minimum);
                    sliderRoot.valueRequested(sliderRoot.snapped(raw));
                }
                onPressed: function(mouse) { commit(mouse.x); }
                onPositionChanged: function(mouse) { if (pressed) commit(mouse.x); }
            }
        }
    }

    component TextInputRow: Item {
        id: inputRoot

        property var theme
        property var settings
        property string label: ""
        property string value: ""

        signal textRequested(string text)

        implicitHeight: labelText.implicitHeight + settings.effectiveContentSpacing + settings.controlHeight + settings.effectiveGroupPadding

        Text {
            id: labelText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            text: inputRoot.label
            color: theme.text
            elide: Text.ElideRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.Medium
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: labelText.bottom
            anchors.topMargin: settings.effectiveContentSpacing
            height: settings.controlHeight
            radius: settings.effectivePillRadius
            color: editor.activeFocus ? theme.surfaceHover : theme.alpha(theme.surfaceStrong, 0.32)
            border.color: editor.activeFocus ? theme.outlineActive : theme.outlineSubtle
            border.width: settings.effectiveBorderWidth
            antialiasing: true
            clip: true
            Behavior on color { ColorAnimation { duration: settings.motionNormal } }
            Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

            TextInput {
                id: editor
                anchors.fill: parent
                anchors.leftMargin: settings.effectivePillPadding
                anchors.rightMargin: settings.effectivePillPadding
                text: inputRoot.value
                color: theme.text
                selectionColor: theme.accentSoft
                selectedTextColor: theme.text
                font.family: settings.fontFamily
                font.pixelSize: settings.effectiveFontSize
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                onTextEdited: inputRoot.textRequested(editor.text)
            }
        }
    }

    component InfoRow: Item {
        id: info

        property var theme
        property var settings
        property string label: ""
        property string value: ""

        implicitHeight: Math.max(settings.controlHeight, valueText.implicitHeight) + settings.effectiveGroupPadding

        Rectangle {
            anchors.fill: parent
            radius: settings.effectivePillRadius
            color: theme.alpha(theme.text, 0.025)
            border.color: theme.transparent
            border.width: settings.effectiveBorderWidth
            antialiasing: true
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: settings.effectiveGroupPadding
            anchors.right: valueText.left
            anchors.rightMargin: settings.effectiveContentSpacing
            anchors.verticalCenter: parent.verticalCenter
            text: info.label
            color: theme.textMuted
            elide: Text.ElideRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
        }

        Text {
            id: valueText
            anchors.right: parent.right
            anchors.rightMargin: settings.effectiveGroupPadding
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.62
            text: info.value
            color: theme.text
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.Medium
        }
    }

    component ChoiceRow: Column {
        id: choiceRoot

        property var theme
        property var settings
        property string label: ""
        property string value: ""
        property var choices: []

        signal choiceRequested(string choice)

        spacing: settings.effectiveContentSpacing

        Text { width: parent.width; text: choiceRoot.label; color: theme.text; elide: Text.ElideRight; font.family: settings.fontFamily; font.pixelSize: settings.effectiveFontSize; font.weight: Font.Medium }

        Flow {
            width: parent.width
            spacing: settings.effectiveContentSpacing

            Repeater {
                model: Array.from(choiceRoot.choices || [])
                ActionButton {
                    required property var modelData

                    theme: choiceRoot.theme
                    settings: choiceRoot.settings
                    label: root.displayLabel(String(modelData))
                    selected: String(modelData) === choiceRoot.value
                    onPressed: choiceRoot.choiceRequested(String(modelData))
                }
            }
        }
    }

    component StyleSelectorRow: Column {
        id: selectorRoot

        property var theme
        property var settings
        property string label: ""
        property string value: ""
        property var choices: []

        signal choiceRequested(string choice)

        spacing: settings.effectiveContentSpacing

        Text { width: parent.width; text: selectorRoot.label; color: theme.text; elide: Text.ElideRight; font.family: settings.fontFamily; font.pixelSize: settings.effectiveFontSize; font.weight: Font.Medium }

        Flow {
            width: parent.width
            spacing: settings.effectiveContentSpacing

            Repeater {
                model: Array.from(selectorRoot.choices || [])
                PreviewChoice {
                    required property var modelData

                    theme: selectorRoot.theme
                    settings: selectorRoot.settings
                    choice: String(modelData)
                    selected: String(modelData) === selectorRoot.value
                    onPressed: selectorRoot.choiceRequested(choice)
                }
            }
        }
    }

    component PreviewChoice: Rectangle {
        id: preview

        property var theme
        property var settings
        property string choice: ""
        property bool selected: false

        signal pressed()

        implicitWidth: Math.round(settings.effectiveSpacingXL * 4.2)
        implicitHeight: settings.controlHeight + settings.effectiveSpacingL
        radius: settings.effectivePillRadius
        color: selected ? theme.surfaceActive : hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.text, 0.035)
        border.color: selected ? theme.outlineActive : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        scale: selected ? 1.015 : hover.containsMouse ? 1.01 : 1
        antialiasing: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on scale { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: settings.effectiveSpacingS
            height: settings.effectiveSpacingL

            Rectangle { visible: preview.choice === "solid"; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: settings.effectiveSpacingS; anchors.rightMargin: settings.effectiveSpacingS; height: Math.max(3, settings.effectiveSpacingXS); radius: settings.effectiveRadiusS; color: theme.accent }
            Rectangle { visible: preview.choice === "pill" || preview.choice === "center"; anchors.centerIn: parent; width: settings.effectiveSpacingXL * 2; height: Math.max(3, settings.effectiveSpacingXS); radius: settings.effectiveRadiusS; color: theme.accent }
            Rectangle { visible: preview.choice === "top" || preview.choice === "bottom"; anchors.horizontalCenter: parent.horizontalCenter; y: preview.choice === "top" ? 0 : parent.height - height; width: settings.effectiveSpacingXL * 2.1; height: Math.max(3, settings.effectiveSpacingXS); radius: settings.effectiveRadiusS; color: theme.accent }
            Rectangle { visible: preview.choice === "left" || preview.choice === "right"; anchors.verticalCenter: parent.verticalCenter; x: preview.choice === "left" ? settings.effectiveSpacingS : parent.width - width - settings.effectiveSpacingS; width: settings.effectiveSpacingXS; height: settings.effectiveSpacingL; radius: width / 2; color: theme.accent }
            Row {
                visible: preview.choice === "islands" || preview.choice === "button"
                anchors.centerIn: parent
                spacing: settings.effectiveSpacingXS
                Repeater {
                    model: 3

                    Rectangle {
                        required property int index

                        width: index === 1 ? settings.effectiveSpacingL : settings.effectiveSpacingM
                        height: Math.max(3, settings.effectiveSpacingXS)
                        radius: settings.effectiveRadiusS
                        color: theme.accent
                    }
                }
            }
            Row {
                visible: preview.choice === "iconOnly" || preview.choice === "iconAndText" || preview.choice === "expanded" || preview.choice === "vertical" || preview.choice === "horizontal" || preview.choice === "minimal"
                anchors.centerIn: parent
                spacing: settings.effectiveSpacingXS
                Rectangle { width: settings.effectiveSpacingS; height: width; radius: width / 2; color: theme.accent }
                Rectangle { visible: preview.choice !== "iconOnly" && preview.choice !== "vertical"; width: settings.effectiveSpacingL; height: Math.max(3, settings.effectiveSpacingXS); radius: height / 2; color: theme.textMuted }
                Rectangle { visible: preview.choice === "expanded" || preview.choice === "horizontal"; width: settings.effectiveSpacingM; height: Math.max(2, settings.effectiveSpacingXS * 0.65); radius: height / 2; color: theme.alpha(theme.textMuted, 0.65) }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: settings.effectiveSpacingXS
            text: root.displayLabel(preview.choice)
            color: selected ? theme.text : theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: settings.fontFamily
            font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.82))
            font.weight: selected ? Font.DemiBold : Font.Medium
        }

        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: preview.pressed() }
    }

    component ActionButton: Rectangle {
        id: button

        property var theme
        property var settings
        property string icon: ""
        property string label: ""
        property bool selected: false

        signal pressed()

        implicitWidth: content.implicitWidth + settings.effectivePillPadding * 2
        implicitHeight: settings.controlHeight
        radius: settings.effectivePillRadius
        color: selected ? theme.surfaceActive : hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceStrong, 0.30)
        border.color: selected ? theme.outlineActive : hover.containsMouse ? theme.outlineActive : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        opacity: enabled ? 1 : 0.35
        scale: hover.containsMouse && enabled ? 1.015 : 1
        antialiasing: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on scale { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }

        Row {
            id: content
            anchors.centerIn: parent
            height: parent.height
            spacing: button.icon.length > 0 && button.label.length > 0 ? settings.effectiveContentSpacing : 0

            Text { visible: button.icon.length > 0; height: parent.height; text: button.icon; color: button.selected ? theme.accent : theme.text; verticalAlignment: Text.AlignVCenter; font.family: settings.fontFamily; font.pixelSize: settings.effectiveIconSize }
            Text { visible: button.label.length > 0; height: parent.height; text: button.label; color: button.selected ? theme.text : theme.textMuted; verticalAlignment: Text.AlignVCenter; font.family: settings.fontFamily; font.pixelSize: settings.effectiveFontSize; font.weight: button.selected ? Font.DemiBold : Font.Medium }
        }

        MouseArea { id: hover; anchors.fill: parent; enabled: button.enabled; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: button.pressed() }
    }

    component ChangedFooter: Rectangle {
        id: footer

        property var theme
        property var settings
        property int changeCount: 0

        signal clearRequested()
        signal closeRequested()

        implicitHeight: settings.controlHeight + settings.effectiveGroupPadding * 2
        height: visible ? implicitHeight : 0
        radius: settings.effectiveRadiusM
        color: theme.alpha(theme.surfacePanel, 0.94)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        opacity: visible ? 1 : 0
        antialiasing: true
        clip: true

        Behavior on opacity { NumberAnimation { duration: settings.motionNormal; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: settings.motionNormal; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Row {
            anchors.fill: parent
            anchors.margins: settings.effectiveGroupPadding
            spacing: settings.effectiveContentSpacing

            Rectangle {
                width: settings.controlHeight
                height: width
                anchors.verticalCenter: parent.verticalCenter
                radius: settings.effectivePillRadius
                color: theme.surfaceActive
                border.color: theme.outlineActive
                border.width: settings.effectiveBorderWidth
                antialiasing: true

                Text {
                    anchors.centerIn: parent
                    text: "󰏫"
                    color: theme.accent
                    font.family: settings.fontFamily
                    font.pixelSize: settings.effectiveIconSize
                }
            }

            Column {
                width: Math.max(0, parent.width - settings.controlHeight - clearButton.width - closeButton.width - parent.spacing * 3)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                Text { width: parent.width; text: changeCount + " live setting changes"; color: theme.text; elide: Text.ElideRight; font.family: settings.fontFamily; font.pixelSize: settings.effectiveFontSize; font.weight: Font.DemiBold }
                Text { width: parent.width; text: "Stored automatically in settings.json"; color: theme.textMuted; elide: Text.ElideRight; font.family: settings.fontFamily; font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.76)) }
            }

            ActionButton { id: clearButton; theme: footer.theme; settings: footer.settings; icon: "󰆴"; label: "Clear"; onPressed: footer.clearRequested() }
            ActionButton { id: closeButton; theme: footer.theme; settings: footer.settings; icon: ""; label: "Close"; onPressed: footer.closeRequested() }
        }
    }

    component StatusBadge: Rectangle {
        id: badge

        property var theme
        property var settings
        property string status: ""

        function fill() {
            if (status === "disabled" || status === "missing") return theme.alpha(theme.text, 0.045);
            if (status === "polling" || status === "timer") return theme.alpha(theme.warning, 0.14);
            if (status === "found" || status === "live") return theme.alpha(theme.accent, 0.14);
            return theme.alpha(theme.text, 0.055);
        }

        function stroke() {
            if (status === "disabled" || status === "missing") return theme.outlineSubtle;
            if (status === "polling" || status === "timer") return theme.alpha(theme.warning, 0.32);
            if (status === "found" || status === "live") return theme.alpha(theme.accent, 0.32);
            return theme.outlineSubtle;
        }

        function label() {
            if (status === "found") return "ok";
            if (status === "missing") return "missing";
            return status.length > 0 ? status : "unknown";
        }

        implicitWidth: badgeText.implicitWidth + settings.effectivePillPadding
        implicitHeight: Math.max(badgeText.implicitHeight + settings.effectiveGroupPadding, settings.effectiveSpacingM)
        radius: height / 2
        color: fill()
        border.color: stroke()
        border.width: settings.effectiveBorderWidth
        antialiasing: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: badge.label()
            color: badge.status === "disabled" || badge.status === "missing" ? theme.textMuted : theme.text
            font.family: settings.fontFamily
            font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.70))
            font.weight: Font.DemiBold
        }
    }

    component WallpaperPreviewCard: Rectangle {
        id: wallpaperCard

        property var theme
        property var settings
        readonly property var entry: root.activeWallpaperEntry()
        readonly property string path: entry ? String(entry.path || "") : ""

        implicitHeight: Math.max(settings.effectiveSpacingXL * 5.4, settings.controlHeight * 4)
        radius: settings.effectiveRadiusM
        color: theme.alpha(theme.surfaceStrong, 0.34)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        visible: path.length > 0
        antialiasing: true
        clip: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Image {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(settings.effectiveSpacingXL * 7.2, parent.width * 0.38)
            source: "file://" + wallpaperCard.path
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Math.round(width)
            sourceSize.height: Math.round(height)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(settings.effectiveBorderWidth, Math.round(settings.effectiveGroupPadding * 0.85))
            color: theme.accent
            opacity: settings.currentWallpaper === wallpaperCard.path ? 0.88 : 0.45
            antialiasing: true
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: Math.max(settings.effectiveSpacingXL * 7.2, parent.width * 0.38) + settings.effectiveSpacingM
            anchors.right: parent.right
            anchors.rightMargin: settings.effectivePillPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: settings.effectiveContentSpacing

            Row {
                width: parent.width
                spacing: settings.effectiveContentSpacing

                StatusBadge { theme: wallpaperCard.theme; settings: wallpaperCard.settings; status: settings.currentWallpaper === wallpaperCard.path ? "live" : "selected" }
                StatusBadge { theme: wallpaperCard.theme; settings: wallpaperCard.settings; status: wallpaperCard.entry && wallpaperCard.entry.favorite ? "favorite" : "local" }
            }

            Text {
                width: parent.width
                text: wallpaperCard.entry ? String(wallpaperCard.entry.name || "") : ""
                color: theme.text
                elide: Text.ElideMiddle
                font.family: settings.fontFamily
                font.pixelSize: Math.round(settings.effectiveFontSize * 1.12)
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: wallpaperCard.entry ? String(wallpaperCard.entry.folder || "") : ""
                color: theme.textMuted
                elide: Text.ElideMiddle
                font.family: settings.fontFamily
                font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.78))
            }

            Flow {
                width: parent.width
                spacing: settings.effectiveContentSpacing

                ActionButton { theme: wallpaperCard.theme; settings: wallpaperCard.settings; icon: "󰐊"; label: "Apply"; enabled: wallpaperCard.path.length > 0; onPressed: root.applySelectedWallpaper() }
                ActionButton { theme: wallpaperCard.theme; settings: wallpaperCard.settings; icon: wallpaperCard.entry && wallpaperCard.entry.favorite ? "" : ""; label: "Favorite"; enabled: wallpaperCard.path.length > 0; onPressed: root.favoriteSelectedWallpaper() }
                ActionButton { theme: wallpaperCard.theme; settings: wallpaperCard.settings; icon: "󰒲"; label: "Random"; onPressed: root.applyRandomWallpaper() }
            }
        }
    }

    component DependencyHealth: SectionBlock {
        id: health

        theme: root.theme
        settings: root.settings
        title: "Wallpaper engine"

        Flow {
            width: parent.width
            spacing: settings.effectiveContentSpacing

            ToolStatus { theme: root.theme; settings: root.settings; label: "awww"; status: root.dependencyValue("awww") }
            ToolStatus { theme: root.theme; settings: root.settings; label: "daemon"; status: root.dependencyValue("awwwDaemon") }
            ToolStatus { theme: root.theme; settings: root.settings; label: "matugen"; status: root.dependencyValue("matugen") }
            ToolStatus { theme: root.theme; settings: root.settings; label: "jq"; status: root.dependencyValue("jq") }
            ToolStatus { theme: root.theme; settings: root.settings; label: "palette"; status: root.dependencyValue("palette") }
            ToolStatus { theme: root.theme; settings: root.settings; label: "directory"; status: root.dependencyValue("wallpaperDir") }
            ActionButton { theme: root.theme; settings: root.settings; icon: dependencyProc.running ? "󰑐" : "󰑓"; label: "Refresh"; enabled: !dependencyProc.running; onPressed: root.refreshDependencyStatus() }
        }
    }

    component ToolStatus: Rectangle {
        id: tool

        property var theme
        property var settings
        property string label: ""
        property string status: "unknown"

        implicitWidth: toolText.implicitWidth + badge.implicitWidth + settings.effectivePillPadding * 2 + settings.effectiveContentSpacing
        implicitHeight: settings.controlHeight
        radius: settings.effectivePillRadius
        color: theme.alpha(theme.surfaceStrong, 0.26)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true

        Row {
            anchors.centerIn: parent
            spacing: settings.effectiveContentSpacing

            Text {
                id: toolText
                text: tool.label
                color: theme.text
                font.family: settings.fontFamily
                font.pixelSize: settings.effectiveFontSize
                font.weight: Font.DemiBold
            }

            StatusBadge {
                id: badge
                theme: tool.theme
                settings: tool.settings
                status: tool.status
            }
        }
    }

    component ModuleSection: SectionBlock {
        id: section

        property string sectionName: "right"
        property var modules: []

        theme: root.theme
        settings: root.settings

        InfoRow {
            width: parent.width
            theme: root.theme
            settings: root.settings
            visible: Array.from(section.modules || []).length <= 0
            label: "Empty"
            value: "Add modules below"
        }

        Repeater {
            model: Array.from(section.modules || []).length

            ModuleRow {
                required property int index
                width: parent.width
                theme: root.theme
                settings: root.settings
                sectionName: section.sectionName
                moduleName: String(section.modules[index])
                indexInSection: index
                moduleCount: section.modules.length
            }
        }
    }

    component UnusedModulesDock: SectionBlock {
        id: dock

        theme: root.theme
        settings: root.settings
        title: "Available modules"

        InfoRow {
            width: parent.width
            theme: root.theme
            settings: root.settings
            visible: settings.unusedModules().length <= 0
            label: "All modules"
            value: "already placed"
        }

        Flow {
            width: parent.width
            spacing: settings.effectiveContentSpacing
            visible: settings.unusedModules().length > 0

            Repeater {
                model: settings.unusedModules()

                ActionButton {
                    required property var modelData

                    theme: root.theme
                    settings: root.settings
                    icon: settings.moduleIcon(String(modelData))
                    label: settings.moduleLabel(String(modelData))
                    onPressed: settings.addModuleToDefault(String(modelData))
                }
            }
        }
    }

    component ModuleRow: Item {
        id: moduleRoot

        property var theme
        property var settings
        property string sectionName: ""
        property string moduleName: ""
        property int indexInSection: 0
        property int moduleCount: 0

        implicitHeight: Math.max(settings.controlHeight + settings.effectiveSpacingS, controls.implicitHeight + settings.effectiveGroupPadding * 2)

        Rectangle {
            anchors.fill: parent
            radius: settings.effectivePillRadius
            color: hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceStrong, 0.24)
            border.color: hover.containsMouse ? theme.outlineActive : theme.outlineSubtle
            border.width: settings.effectiveBorderWidth
            antialiasing: true
            Behavior on color { ColorAnimation { duration: settings.motionNormal } }
            Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: settings.effectivePillPadding
            anchors.verticalCenter: parent.verticalCenter
            width: settings.controlHeight
            height: width
            radius: settings.effectivePillRadius
            color: settings.enabled(moduleRoot.moduleName) ? theme.surfaceActive : theme.alpha(theme.text, 0.035)
            border.color: settings.enabled(moduleRoot.moduleName) ? theme.alpha(theme.accent, 0.24) : theme.outlineSubtle
            border.width: settings.effectiveBorderWidth
            antialiasing: true

            Text {
                anchors.centerIn: parent
                text: settings.moduleIcon(moduleRoot.moduleName)
                color: settings.enabled(moduleRoot.moduleName) ? theme.accent : theme.textMuted
                font.family: settings.fontFamily
                font.pixelSize: settings.effectiveIconSize
            }
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: settings.effectivePillPadding + settings.controlHeight + settings.effectiveContentSpacing
            anchors.right: controls.left
            anchors.rightMargin: settings.effectiveContentSpacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

            Text {
                width: parent.width
                text: settings.moduleLabel(moduleRoot.moduleName)
                color: settings.enabled(moduleRoot.moduleName) ? theme.text : theme.textMuted
                elide: Text.ElideRight
                font.family: settings.fontFamily
                font.pixelSize: settings.effectiveFontSize
                font.weight: Font.DemiBold
                Behavior on color { ColorAnimation { duration: settings.motionNormal } }
            }

            Text {
                width: parent.width
                text: settings.moduleCategory(moduleRoot.moduleName) + " / " + moduleRoot.sectionName + " slot " + String(moduleRoot.indexInSection + 1)
                color: theme.textMuted
                elide: Text.ElideRight
                font.family: settings.fontFamily
                font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.76))
            }
        }

        Row {
            id: controls
            anchors.right: parent.right
            anchors.rightMargin: settings.effectivePillPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: settings.effectiveContentSpacing

            StatusBadge { theme: moduleRoot.theme; settings: moduleRoot.settings; status: moduleRoot.settings.moduleStatus(moduleRoot.moduleName) }
            IconButton { theme: moduleRoot.theme; settings: moduleRoot.settings; icon: ""; enabled: moduleRoot.indexInSection > 0; onPressed: moduleRoot.settings.moveModule(moduleRoot.sectionName, moduleRoot.indexInSection, -1) }
            IconButton { theme: moduleRoot.theme; settings: moduleRoot.settings; icon: ""; enabled: moduleRoot.indexInSection < moduleRoot.moduleCount - 1; onPressed: moduleRoot.settings.moveModule(moduleRoot.sectionName, moduleRoot.indexInSection, 1) }
            ToggleSwitch { theme: moduleRoot.theme; settings: moduleRoot.settings; checked: moduleRoot.settings.enabled(moduleRoot.moduleName); onToggled: function(checked) { moduleRoot.settings.setModuleEnabled(moduleRoot.moduleName, checked); } }
            IconButton { theme: moduleRoot.theme; settings: moduleRoot.settings; icon: ""; onPressed: moduleRoot.settings.removeModule(moduleRoot.sectionName, moduleRoot.indexInSection) }
        }

        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
    }

    component WidgetRow: Rectangle {
        id: row

        property var theme
        property var settings
        property string moduleName: ""

        signal configureRequested(string moduleName)

        implicitHeight: settings.controlHeight + settings.effectiveSpacingL
        radius: settings.effectivePillRadius
        color: hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceStrong, 0.24)
        border.color: hover.containsMouse ? theme.outlineActive : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Row {
            anchors.fill: parent
            anchors.margins: settings.effectiveGroupPadding
            spacing: settings.effectiveContentSpacing

            Rectangle {
                width: settings.controlHeight
                height: width
                anchors.verticalCenter: parent.verticalCenter
                radius: settings.effectivePillRadius
                color: settings.enabled(row.moduleName) ? theme.surfaceActive : theme.alpha(theme.text, 0.035)
                border.color: settings.enabled(row.moduleName) ? theme.alpha(theme.accent, 0.24) : theme.outlineSubtle
                border.width: settings.effectiveBorderWidth
                antialiasing: true

                Text {
                    anchors.centerIn: parent
                    text: settings.moduleIcon(row.moduleName)
                    color: settings.enabled(row.moduleName) ? theme.accent : theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: settings.fontFamily
                    font.pixelSize: settings.effectiveIconSize
                }
            }

            Column {
                width: Math.max(settings.effectiveSpacingXL * 5, parent.width - settings.controlHeight - actionCluster.width - parent.spacing * 2)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))
                Text { width: parent.width; text: settings.moduleLabel(row.moduleName); color: theme.text; elide: Text.ElideRight; font.family: settings.fontFamily; font.pixelSize: settings.effectiveFontSize; font.weight: Font.DemiBold }
                Row {
                    width: parent.width
                    spacing: settings.effectiveContentSpacing

                    Text {
                        width: Math.min(implicitWidth, parent.width)
                        text: settings.moduleCategory(row.moduleName)
                        color: theme.textMuted
                        elide: Text.ElideRight
                        font.family: settings.fontFamily
                        font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.78))
                    }

                    Rectangle {
                        width: costText.implicitWidth + settings.effectivePillPadding
                        height: Math.max(costText.implicitHeight + settings.effectiveGroupPadding, settings.effectiveSpacingM)
                        radius: height / 2
                        color: theme.alpha(theme.text, 0.045)
                        border.color: theme.outlineSubtle
                        border.width: settings.effectiveBorderWidth
                        antialiasing: true

                        Text {
                            id: costText
                            anchors.centerIn: parent
                            text: settings.moduleCost(row.moduleName)
                            color: theme.textMuted
                            font.family: settings.fontFamily
                            font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.70))
                            font.weight: Font.Medium
                        }
                    }
                }
            }
            Row {
                id: actionCluster

                anchors.verticalCenter: parent.verticalCenter
                spacing: settings.effectiveContentSpacing

                StatusBadge { theme: row.theme; settings: row.settings; status: row.settings.moduleStatus(row.moduleName) }
                ActionButton { theme: row.theme; settings: row.settings; icon: "󰒓"; label: "Options"; onPressed: row.configureRequested(row.moduleName) }
                ToggleSwitch { theme: row.theme; settings: row.settings; checked: settings.enabled(row.moduleName); onToggled: function(checked) { settings.setModuleEnabled(row.moduleName, checked); } }
            }
        }

        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
    }

    component WallpaperTile: Rectangle {
        id: tile

        property var theme
        property var settings
        property var entry
        property bool busy: false
        property bool selected: false

        signal applyRequested()
        signal favoriteRequested()

        implicitHeight: width * 0.62
        radius: settings.effectiveRadiusM
        color: theme.alpha(theme.text, 0.035)
        border.color: entry.current ? theme.outlineActive : selected ? theme.alpha(theme.accent, 0.42) : hover.containsMouse ? theme.outlineSubtle : theme.transparent
        border.width: entry.current || selected ? settings.effectiveBorderWidth * 2 : settings.effectiveBorderWidth
        scale: selected ? 1.01 : hover.containsMouse ? 1.006 : 1
        clip: true
        antialiasing: true

        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on scale { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }

        Image {
            anchors.fill: parent
            anchors.margins: settings.effectiveBorderWidth
            source: "file://" + String(tile.entry.path || "")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Math.round(tile.width)
            sourceSize.height: Math.round(tile.height)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.max(settings.controlHeight, settings.effectiveSpacingXL)
            color: theme.alpha(theme.base, 0.72)

            Text {
                anchors.left: parent.left
                anchors.right: favoriteButton.left
                anchors.leftMargin: settings.effectivePillPadding
                anchors.rightMargin: settings.effectiveContentSpacing
                anchors.verticalCenter: parent.verticalCenter
                text: String(tile.entry.name || "")
                color: theme.text
                elide: Text.ElideMiddle
                font.family: settings.fontFamily
                font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.78))
                font.weight: Font.Medium
            }

            IconButton {
                id: favoriteButton
                anchors.right: parent.right
                anchors.rightMargin: settings.effectiveGroupPadding
                anchors.verticalCenter: parent.verticalCenter
                theme: tile.theme
                settings: tile.settings
                icon: tile.entry.favorite ? "" : ""
                onPressed: tile.favoriteRequested()
            }
        }

        Text {
            anchors.centerIn: parent
            visible: tile.busy || tile.selected
            text: tile.busy ? "󰑐" : "󰐊"
            color: theme.text
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveIconSize
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.applyRequested()
        }
    }
}
