pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

PopupWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property var anchorItem: null
    property bool panelOpen: false
    property bool panelClosing: false
    property string sortMode: "cpu"
    property string temperature: ""
    property string statusText: "Ready"
    property var processes: []
    readonly property int panelWidth: settings ? Math.round(Math.min(panelWindow ? panelWindow.width : settings.effectiveSpacingXL * 22, Math.max(settings.effectiveSpacingXL * 18, settings.processPanelWidth))) : 520

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\\''") + "'";
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

        return panelWindow ? clampedX(panelWindow.width - panelWidth) : 0;
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
        refresh();
    }

    function close() {
        if (!panelOpen && !panelClosing) return;
        panelClosing = true;
        panelOpen = false;
        closeTimer.restart();
    }

    function setSort(mode) {
        const next = String(mode || "cpu");
        sortMode = next === "mem" ? "mem" : "cpu";
        refresh();
    }

    function refresh() {
        if (refreshProc.running) return;
        const limit = Math.max(4, Number(settings ? settings.processListLimit : 0) || 12);
        const sort = sortMode === "mem" ? "pmem" : "pcpu";
        statusText = "Loading";
        refreshProc.command = ["sh", "-c",
            "sep=$(printf '\\037'); limit=" + limit + "; sort=" + shellQuote(sort) + "; "
            + "if command -v sensors >/dev/null 2>&1; then temp=$(sensors 2>/dev/null | awk 'match($0, /\\+[0-9]+(\\.[0-9]+)?°?C/) { v=substr($0, RSTART, RLENGTH); gsub(/^\\+/, \"\", v); print v; exit }'); [ -n \"$temp\" ] && printf 'temperature=%s\\n' \"$temp\" || printf 'temperature=Unavailable\\n'; else printf 'temperature=Unavailable\\n'; fi; "
            + "ps -eo pid=,comm=,pcpu=,pmem= --sort=-$sort 2>/dev/null | head -n \"$limit\" | awk -v sep=\"$sep\" '{ name=$2; gsub(sep, \" \", name); printf \"proc=%s%s%s%s%s%s%s\\n\", $1, sep, name, sep, $3, sep, $4 }'"
        ];
        refreshProc.running = true;
    }

    function parseProcesses(text) {
        const next = [];
        const lines = String(text || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.indexOf("temperature=") === 0) {
                temperature = line.slice(12);
            } else if (line.indexOf("proc=") === 0) {
                const parts = line.slice(5).split("\u001f");
                next.push({
                    "pid": parts[0] || "",
                    "name": parts[1] || "",
                    "cpu": parts[2] || "0",
                    "mem": parts[3] || "0"
                });
            }
        }
        processes = next;
        statusText = processes.length + " tasks";
    }

    function metricWidth() {
        return settings.effectiveSpacingXL * 2.7;
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -processFrame.height - settings.settingsPanelGap : panelWindow.height + settings.settingsPanelGap) : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: processFrame.height
    visible: panelOpen || panelClosing
    grabFocus: anchorItem !== null
    color: "transparent"

    Timer {
        id: closeTimer

        interval: root.settings ? Math.max(1, root.settings.motionClose) : 1
        repeat: false
        onTriggered: root.panelClosing = false
    }

    Timer {
        interval: settings ? settings.processListPollMs : 5000
        running: root.panelOpen
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: refreshProc

        stdout: StdioCollector { onStreamFinished: root.parseProcesses(text) }
        stderr: StdioCollector { onStreamFinished: if (text.length > 0) root.statusText = "Read failed" }
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
        id: processFrame

        x: root.anchoredX()
        y: root.panelOpen ? 0 : -Math.max(settings.effectiveContentSpacing * 2, settings.effectiveGroupPadding * 2)
        width: root.panelWidth
        height: content.implicitHeight + settings.panelPadding * 2
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

            Row {
                width: parent.width
                height: settings.controlHeight
                spacing: settings.effectiveContentSpacing

                Text {
                    width: settings.controlHeight
                    height: parent.height
                    text: "󰒋"
                    color: theme.primary
                    font.family: settings.fontFamilyIcon
                    font.pixelSize: settings.effectiveIconSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Column {
                    width: parent.width - settings.controlHeight - sortRow.width - parent.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                    Text {
                        width: parent.width
                        text: "Processes"
                        color: theme.text
                        elide: Text.ElideRight
                        font.family: settings.fontFamilySans
                        font.pixelSize: Math.round(settings.effectiveFontSize * 1.06)
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: "Temp " + (root.temperature.length > 0 ? root.temperature : "Unavailable") + " / " + root.statusText
                        color: theme.textMuted
                        elide: Text.ElideRight
                        font.family: settings.fontFamilySans
                        font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                    }
                }

                Row {
                    id: sortRow

                    height: parent.height
                    spacing: settings.effectiveContentSpacing

                    SortButton { theme: root.theme; settings: root.settings; label: "CPU"; active: root.sortMode === "cpu"; onPressed: root.setSort("cpu") }
                    SortButton { theme: root.theme; settings: root.settings; label: "Mem"; active: root.sortMode === "mem"; onPressed: root.setSort("mem") }
                }
            }

            Rectangle {
                width: parent.width
                height: settings.controlHeight
                radius: settings.effectivePillRadius
                color: theme.alpha(theme.surfaceContainer, 0.34)
                border.color: theme.outlineSubtle
                border.width: settings.effectiveBorderWidth
                antialiasing: true

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: settings.effectiveContentSpacing
                    anchors.rightMargin: settings.effectiveContentSpacing

                    Text {
                        width: settings.effectiveSpacingXL * 2
                        height: parent.height
                        text: "PID"
                        color: theme.textMuted
                        font.family: settings.fontFamilyMono
                        font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: parent.width - settings.effectiveSpacingXL * 2 - root.metricWidth() * 2
                        height: parent.height
                        text: "Process"
                        color: theme.textMuted
                        font.family: settings.fontFamilySans
                        font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: root.metricWidth()
                        height: parent.height
                        text: "CPU"
                        color: theme.textMuted
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        font.family: settings.fontFamilyMono
                        font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                    }

                    Text {
                        width: root.metricWidth()
                        height: parent.height
                        text: "Mem"
                        color: theme.textMuted
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        font.family: settings.fontFamilyMono
                        font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.5))

                Repeater {
                    model: root.processes

                    ProcessRow {
                        required property var modelData

                        width: parent.width
                        theme: root.theme
                        settings: root.settings
                        process: modelData
                    }
                }
            }
        }
    }

    component SortButton: Rectangle {
        id: button

        property var theme
        property var settings
        property string label: ""
        property bool active: false

        signal pressed()

        width: settings.effectiveSpacingXL * 2.2
        height: settings.controlHeight
        radius: settings.effectivePillRadius
        color: active ? theme.primary : hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceContainer, 0.42)
        border.color: active ? theme.alpha(theme.primary, 0.60) : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true

        Text {
            anchors.centerIn: parent
            text: button.label
            color: button.active ? theme.surface : theme.text
            font.family: settings.fontFamilySans
            font.pixelSize: Math.max(9, settings.effectiveFontSize - 1)
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.pressed()
        }
    }

    component ProcessRow: Rectangle {
        id: row

        property var theme
        property var settings
        property var process: ({})

        implicitHeight: settings.controlHeight
        radius: settings.effectivePillRadius
        color: hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceContainer, 0.42)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        clip: true

        Row {
            anchors.fill: parent
            anchors.leftMargin: settings.effectiveContentSpacing
            anchors.rightMargin: settings.effectiveContentSpacing

            Text {
                width: settings.effectiveSpacingXL * 2
                height: parent.height
                text: String(row.process.pid || "")
                color: theme.textMuted
                elide: Text.ElideRight
                font.family: settings.fontFamilyMono
                font.pixelSize: Math.max(9, settings.effectiveFontSize - 1)
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                width: parent.width - settings.effectiveSpacingXL * 2 - root.metricWidth() * 2
                height: parent.height
                text: String(row.process.name || "")
                color: theme.text
                elide: Text.ElideRight
                font.family: settings.fontFamilySans
                font.pixelSize: settings.effectiveFontSize
                font.weight: Font.Medium
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                width: root.metricWidth()
                height: parent.height
                text: String(row.process.cpu || "0") + "%"
                color: root.sortMode === "cpu" ? theme.primary : theme.textMuted
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                font.family: settings.fontFamilyMono
                font.pixelSize: settings.effectiveFontSize
                font.weight: root.sortMode === "cpu" ? Font.Bold : Font.Medium
            }

            Text {
                width: root.metricWidth()
                height: parent.height
                text: String(row.process.mem || "0") + "%"
                color: root.sortMode === "mem" ? theme.primary : theme.textMuted
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                font.family: settings.fontFamilyMono
                font.pixelSize: settings.effectiveFontSize
                font.weight: root.sortMode === "mem" ? Font.Bold : Font.Medium
            }
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
}
