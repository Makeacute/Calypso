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

    function validEntry(entry) {
        if (!entry || entry.noDisplay) return false;
        if (String(entry.name || "").length <= 0) return false;
        return Array.from(entry.command || []).length > 0 || String(entry.execString || "").length > 0;
    }

    function filteredEntries() {
        const apps = allApplications();
        const search = query;
        const scored = [];
        for (let i = 0; i < apps.length; i++) {
            const entry = apps[i];
            if (!validEntry(entry)) continue;
            const score = fuzzyScore(entry, search);
            if (score < 0) continue;
            scored.push({ "entry": entry, "score": score });
        }

        scored.sort((a, b) => {
            if (b.score !== a.score) return b.score - a.score;
            return String(a.entry.name || "").localeCompare(String(b.entry.name || ""));
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
                            } else if (event.key === Qt.Key_Down) {
                                root.selectNext(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
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
                    text: "Search apps"
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

        implicitHeight: settings.controlHeight * 1.55
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
            spacing: settings.effectiveContentSpacing

            AppIconImage {
                width: settings.controlHeight
                height: settings.controlHeight
                theme: row.theme
                settings: row.settings
                iconSource: root.iconSource(row.entry)
                fallbackText: root.initial(row.entry)
            }

            Column {
                width: parent.width - settings.controlHeight - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                Text {
                    width: parent.width
                    text: String(row.entry && row.entry.name ? row.entry.name : "")
                    color: theme.text
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: String(row.entry && row.entry.comment ? row.entry.comment : row.entry && row.entry.genericName ? row.entry.genericName : "")
                    color: theme.textMuted
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.family: settings.fontFamilySans
                    font.pixelSize: Math.round(settings.effectiveFontSize * 0.84)
                }
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
