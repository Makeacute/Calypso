pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import Quickshell.Widgets
import "widgets"

PopupWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property var anchorItem: null
    property bool panelOpen: false
    property bool panelClosing: false
    property string query: ""
    property int selectedIndex: 0
    readonly property int panelWidth: settings ? Math.round(Math.min(panelWindow ? panelWindow.width : settings.effectiveSpacingXL * 24, Math.max(settings.effectiveSpacingXL * 16, settings.launcherPanelWidth))) : Math.round(theme ? theme.spacingXL * 20 : 0)
    readonly property int panelHeight: content.implicitHeight + settings.panelPadding * 2
    readonly property int closedOffset: Math.max(settings.effectiveContentSpacing * 2, settings.effectiveGroupPadding * 2)
    readonly property var entries: filteredEntries()

    function normalize(text) {
        return String(text || "").toLowerCase().replace(/[^a-z0-9]+/g, "");
    }

    function entryText(entry) {
        const parts = [
            String(entry && entry.name ? entry.name : ""),
            String(entry && entry.genericName ? entry.genericName : ""),
            String(entry && entry.comment ? entry.comment : ""),
            Array.from(entry && entry.keywords ? entry.keywords : []).join(" "),
            Array.from(entry && entry.categories ? entry.categories : []).join(" ")
        ];
        return parts.join(" ");
    }

    function fuzzyScore(entry, search) {
        const rawQuery = String(search || "").trim();
        if (rawQuery.length <= 0) return 1;

        const queryText = normalize(rawQuery);
        const nameText = normalize(entry && entry.name ? entry.name : "");
        const haystack = normalize(entryText(entry));
        if (queryText.length <= 0) return 1;
        if (haystack.indexOf(queryText) >= 0)
            return 1000 - haystack.indexOf(queryText) + (nameText.indexOf(queryText) === 0 ? 400 : 0);

        let cursor = 0;
        let gap = 0;
        for (let i = 0; i < queryText.length; i++) {
            const found = haystack.indexOf(queryText.charAt(i), cursor);
            if (found < 0) return -1;
            gap += found - cursor;
            cursor = found + 1;
        }

        return Math.max(1, 700 - gap * 8 - haystack.length * 0.25);
    }

    function allApplications() {
        return DesktopEntries.applications ? Array.from(DesktopEntries.applications.values || []) : [];
    }

    function appLabel(entry) {
        return String(entry && entry.name ? entry.name : "");
    }

    function appSubtitle(entry) {
        return String(entry && entry.comment ? entry.comment : entry && entry.genericName ? entry.genericName : "");
    }

    function entryKeys(entry) {
        return [
            String(entry && entry.id ? entry.id : ""),
            appLabel(entry),
            String(entry && entry.genericName ? entry.genericName : ""),
            String(entry && entry.comment ? entry.comment : ""),
            String(entry && entry.icon ? entry.icon : ""),
            String(entry && entry.startupClass ? entry.startupClass : ""),
            String(entry && entry.execString ? entry.execString : ""),
            Array.from(entry && entry.command ? entry.command : []).join(" ")
        ].filter(key => key.length > 0);
    }

    function matchesPattern(entry, pattern) {
        const needle = normalize(pattern);
        if (needle.length <= 0) return false;

        const keys = entryKeys(entry);
        for (let i = 0; i < keys.length; i++) {
            const key = normalize(keys[i]);
            if (key === needle || key.indexOf(needle) >= 0)
                return true;
        }
        return false;
    }

    function favoriteRank(entry) {
        const favorites = Array.from(settings ? settings.launcherFavorites : []);
        for (let i = 0; i < favorites.length; i++) {
            if (matchesPattern(entry, favorites[i]))
                return i;
        }
        return -1;
    }

    function hiddenBySettings(entry) {
        const hidden = Array.from(settings ? settings.launcherHiddenApps : []);
        for (let i = 0; i < hidden.length; i++) {
            if (matchesPattern(entry, hidden[i]))
                return true;
        }
        return false;
    }

    function validEntry(entry) {
        if (!entry || entry.noDisplay || hiddenBySettings(entry)) return false;
        if (String(entry.name || "").length <= 0) return false;
        return Array.from(entry.command || []).length > 0 || String(entry.execString || "").length > 0;
    }

    function substringScore(entry, search) {
        const rawQuery = String(search || "").trim();
        if (rawQuery.length <= 0) return 1;

        const queryText = normalize(rawQuery);
        const nameText = normalize(entry && entry.name ? entry.name : "");
        const haystack = normalize(entryText(entry));
        if (queryText.length <= 0) return 1;

        const nameIndex = nameText.indexOf(queryText);
        if (nameIndex >= 0)
            return 900 - nameIndex + (nameIndex === 0 ? 300 : 0);

        const haystackIndex = haystack.indexOf(queryText);
        return haystackIndex >= 0 ? 600 - haystackIndex : -1;
    }

    function matchScore(entry, search) {
        return settings && !settings.launcherUseFuzzy ? substringScore(entry, search) : fuzzyScore(entry, search);
    }

    function filteredEntries() {
        const apps = allApplications();
        const search = query;
        const hasSearch = String(search || "").trim().length > 0;
        const sortMode = String(settings ? settings.launcherSortMode : "relevance");
        const scored = [];
        for (let i = 0; i < apps.length; i++) {
            const entry = apps[i];
            if (!validEntry(entry)) continue;
            const score = matchScore(entry, search);
            if (score < 0) continue;
            scored.push({ "entry": entry, "score": score, "favoriteIndex": favoriteRank(entry) });
        }

        scored.sort((a, b) => {
            if (!hasSearch && a.favoriteIndex !== b.favoriteIndex) {
                if (a.favoriteIndex >= 0 && b.favoriteIndex >= 0) return a.favoriteIndex - b.favoriteIndex;
                if (a.favoriteIndex >= 0) return -1;
                if (b.favoriteIndex >= 0) return 1;
            }

            const nameCompare = appLabel(a.entry).localeCompare(appLabel(b.entry));
            if (sortMode === "alphabetical") return nameCompare;
            if (b.score !== a.score) return b.score - a.score;
            if (a.favoriteIndex !== b.favoriteIndex) {
                if (a.favoriteIndex >= 0 && b.favoriteIndex >= 0) return a.favoriteIndex - b.favoriteIndex;
                if (a.favoriteIndex >= 0) return -1;
                if (b.favoriteIndex >= 0) return 1;
            }
            return nameCompare;
        });

        const max = Math.max(1, Number(settings ? settings.launcherMaxResults : 0) || 12);
        return scored.slice(0, max).map(item => item.entry);
    }

    function clampedX(value) {
        const maxX = panelWindow ? Math.max(0, panelWindow.width - panelWidth) : 0;
        return Math.max(0, Math.min(maxX, value));
    }

    function anchoredX() {
        if (anchorItem && typeof anchorItem.mapToItem === "function") {
            const point = anchorItem.mapToItem(null, 0, 0);
            return clampedX(point.x + anchorItem.width / 2 - panelWidth / 2);
        }

        return panelWindow ? clampedX((panelWindow.width - panelWidth) / 2) : 0;
    }

    function iconSource(entry) {
        const icon = String(entry && entry.icon ? entry.icon : "");
        if (icon.length <= 0) return "";
        if (icon.charAt(0) === "/") return "file://" + icon;
        if (Quickshell.hasThemeIcon(icon)) return Quickshell.iconPath(icon, true);
        return "";
    }

    function initial(entry) {
        const name = String(entry && entry.name ? entry.name : "").replace(/[^A-Za-z0-9]/g, "");
        return name.length > 0 ? name.charAt(0).toUpperCase() : "";
    }

    function selectNext(delta) {
        const count = entries.length;
        if (count <= 0) {
            selectedIndex = 0;
            return;
        }
        selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + delta));
    }

    function launch(entry) {
        if (!entry || typeof entry.execute !== "function") return;
        entry.execute();
        if (!settings || settings.launcherCloseOnLaunch)
            close();
    }

    function launchSelected() {
        if (entries.length <= 0) return;
        launch(entries[Math.max(0, Math.min(entries.length - 1, selectedIndex))]);
    }

    function toggle(anchor) {
        if (panelOpen) close();
        else open(anchor);
    }

    function open(anchor) {
        closeTimer.stop();
        anchorItem = anchor || null;
        query = "";
        selectedIndex = 0;
        panelClosing = false;
        panelOpen = true;
        searchFocusTimer.restart();
    }

    function openQuery(text) {
        open(null);
        query = String(text || "");
        selectedIndex = 0;
    }

    function close() {
        if (!panelOpen && !panelClosing) return;
        panelClosing = true;
        panelOpen = false;
        closeTimer.restart();
    }

    onQueryChanged: selectedIndex = 0

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -panelHeight - settings.settingsPanelGap : panelWindow.height + settings.settingsPanelGap) : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: panelHeight
    visible: panelOpen || panelClosing
    grabFocus: panelOpen
    color: theme.transparent

    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: root.panelOpen
        context: Qt.WindowShortcut
        onActivated: root.close()
    }

    Timer {
        id: closeTimer

        interval: root.settings ? Math.max(1, root.settings.motionClose) : 1
        repeat: false
        onTriggered: root.panelClosing = false
    }

    Timer {
        id: searchFocusTimer

        interval: Math.max(1, settings ? settings.motionFast : 1)
        repeat: false
        onTriggered: searchField.forceActiveFocus()
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
        id: launcherFrame

        x: root.anchoredX()
        y: root.panelOpen ? 0 : (settings.barPosition === "bottom" ? root.closedOffset : -root.closedOffset)
        width: root.panelWidth
        height: root.panelHeight
        theme: root.theme
        settings: root.settings
        surfaceColor: theme.alpha(theme.surfaceContainerHigh, settings.panelOpacity / 100)
        outlineColor: theme.outlineSubtle
        outlineWidth: settings.effectiveBorderWidth
        surfaceRadius: settings.panelRadius
        clip: true
        opacity: root.panelOpen ? 1 : 0

        Behavior on y { NumberAnimation { duration: root.panelOpen ? settings.motionOpen : settings.motionClose; easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic } }
        Behavior on opacity { NumberAnimation { duration: root.panelOpen ? settings.motionOpen : settings.motionClose; easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: function(mouse) { mouse.accepted = true; }
            onWheel: function(wheel) { wheel.accepted = true; }
        }

        Column {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: settings.panelPadding
            spacing: settings.effectiveContentSpacing

            Rectangle {
                width: parent.width
                height: settings.controlHeight
                radius: settings.effectivePillRadius
                color: theme.alpha(theme.surfaceContainer, 0.58)
                border.color: searchField.activeFocus ? theme.outlineActive : theme.outlineSubtle
                border.width: settings.effectiveBorderWidth
                antialiasing: true
                clip: true

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: settings.effectiveContentSpacing
                    anchors.rightMargin: settings.effectiveContentSpacing
                    spacing: settings.effectiveContentSpacing

                    Text {
                        width: settings.controlHeight
                        height: parent.height
                        text: "󰍉"
                        color: searchField.activeFocus ? theme.primary : theme.textMuted
                        font.family: settings.fontFamilyIcon
                        font.pixelSize: settings.effectiveIconSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    TextInput {
                        id: searchField

                        width: parent.width - settings.controlHeight - parent.spacing
                        height: parent.height
                        text: root.query
                        color: theme.text
                        selectionColor: theme.alpha(theme.primary, 0.32)
                        selectedTextColor: theme.text
                        font.family: settings.fontFamilySans
                        font.pixelSize: settings.effectiveFontSize
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        onTextChanged: if (root.query !== text) root.query = text
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || (settings && settings.launcherVimKeybinds && (event.key === Qt.Key_J || event.key === Qt.Key_N) && (event.modifiers & Qt.ControlModifier)) || (settings && settings.launcherVimKeybinds && event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                                root.selectNext(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up || (settings && settings.launcherVimKeybinds && (event.key === Qt.Key_K || event.key === Qt.Key_P) && (event.modifiers & Qt.ControlModifier)) || (settings && settings.launcherVimKeybinds && (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))))) {
                                root.selectNext(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.launchSelected();
                                event.accepted = true;
                            }
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: settings.controlHeight + settings.effectiveContentSpacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchField.text.length <= 0
                    text: settings.launcherSearchPlaceholder
                    color: theme.textMuted
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                }
            }

            Flickable {
                width: parent.width
                height: Math.min(resultList.implicitHeight, settings.controlHeight * 9)
                contentWidth: width
                contentHeight: resultList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: resultList

                    width: parent.width
                    spacing: settings.effectiveContentSpacing

                    EmptyRow {
                        width: parent.width
                        theme: root.theme
                        settings: root.settings
                        visible: root.entries.length <= 0
                    }

                    Repeater {
                        model: root.entries

                        LauncherRow {
                            required property var modelData
                            required property int index

                            width: resultList.width
                            theme: root.theme
                            settings: root.settings
                            entry: modelData
                            rowIndex: index
                            selected: root.selectedIndex === index
                            onPressed: root.launch(modelData)
                        }
                    }
                }
            }
        }
    }

    component LauncherRow: Rectangle {
        id: row

        property var theme
        property var settings
        property var entry
        property bool selected: false
        property int rowIndex: 0

        signal pressed()

        readonly property bool showIcon: settings.launcherShowIcons
        readonly property bool showSubtitle: settings.launcherShowDescriptions && !settings.launcherCompactRows && root.appSubtitle(entry).length > 0
        readonly property bool favorite: root.favoriteRank(entry) >= 0
        readonly property int visibleGapCount: (showIcon ? 1 : 0) + (favorite ? 1 : 0)

        implicitHeight: settings.controlHeight + settings.effectiveContentSpacing * (settings.launcherCompactRows ? 2 : 3)
        radius: settings.effectivePillRadius
        color: selected ? theme.surfaceActive : hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceContainer, 0.46)
        border.color: selected ? theme.outlineActive : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        clip: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Row {
            anchors.fill: parent
            anchors.margins: settings.effectiveContentSpacing
            spacing: row.visibleGapCount > 0 ? settings.effectiveContentSpacing : 0

            Item {
                id: iconSlot

                width: visible ? settings.controlHeight : 0
                height: settings.controlHeight
                anchors.verticalCenter: parent.verticalCenter
                visible: row.showIcon

                AppIconImage {
                    anchors.fill: parent
                    theme: row.theme
                    settings: row.settings
                    iconSource: root.iconSource(row.entry)
                    fallbackText: root.initial(row.entry)
                }
            }

            Column {
                width: Math.max(0, parent.width - iconSlot.width - favoriteMark.width - parent.spacing * row.visibleGapCount)
                anchors.verticalCenter: parent.verticalCenter
                spacing: row.showSubtitle ? Math.max(settings.effectiveBorderWidth, settings.effectiveContentSpacing - settings.effectiveGroupPadding) : 0

                Text {
                    width: parent.width
                    text: root.appLabel(row.entry)
                    color: theme.text
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    height: visible ? implicitHeight : 0
                    visible: row.showSubtitle
                    text: root.appSubtitle(row.entry)
                    color: theme.textMuted
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.family: settings.fontFamilySans
                    font.pixelSize: Math.round(settings.effectiveFontSize * 0.84)
                }
            }

            Text {
                id: favoriteMark

                width: row.favorite ? settings.controlHeight : 0
                height: parent.height
                visible: row.favorite
                text: "󰓎"
                color: theme.primary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: settings.fontFamilyIcon
                font.pixelSize: settings.effectiveIconSize
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = row.rowIndex
            onClicked: row.pressed()
        }
    }

    component EmptyRow: Rectangle {
        id: empty

        property var theme
        property var settings

        implicitHeight: settings.controlHeight * 1.55
        radius: settings.effectivePillRadius
        color: theme.alpha(theme.surfaceContainer, 0.42)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true

        Row {
            anchors.fill: parent
            anchors.margins: settings.effectiveContentSpacing
            spacing: settings.effectiveContentSpacing

            Text {
                width: settings.controlHeight
                height: parent.height
                text: "󰍉"
                color: theme.textMuted
                font.family: settings.fontFamilyIcon
                font.pixelSize: settings.effectiveIconSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                width: parent.width - settings.controlHeight - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                text: "No matches"
                color: theme.textMuted
                elide: Text.ElideRight
                font.family: settings.fontFamilySans
                font.pixelSize: settings.effectiveFontSize
                font.weight: Font.Medium
            }
        }
    }
}
