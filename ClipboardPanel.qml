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
    property var entries: []
    property string backend: ""
    property string statusText: "Ready"
    readonly property int panelWidth: settings ? Math.round(Math.min(panelWindow ? panelWindow.width : settings.effectiveSpacingXL * 20, Math.max(settings.effectiveSpacingXL * 16, settings.clipboardPanelWidth))) : 460

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

    function refresh() {
        if (refreshProc.running) return;
        statusText = "Loading";
        const mode = shellQuote(settings ? settings.clipboardBackend : "auto");
        const limit = Math.max(1, Number(settings ? settings.clipboardMaxItems : 0) || 20);
        refreshProc.command = ["sh", "-c",
            "mode=" + mode + "; limit=" + limit + "; sep=$(printf '\\037'); "
            + "use=; if [ \"$mode\" = cliphist ] || { [ \"$mode\" = auto ] && command -v cliphist >/dev/null 2>&1; }; then use=cliphist; elif [ \"$mode\" = copyq ] || { [ \"$mode\" = auto ] && command -v copyq >/dev/null 2>&1; }; then use=copyq; fi; "
            + "printf 'backend=%s\\n' \"${use:-none}\"; "
            + "if [ \"$use\" = cliphist ]; then dir=\"${XDG_RUNTIME_DIR:-/tmp}/calypso-clipboard\"; mkdir -p \"$dir\"; "
            + "cliphist list 2>/dev/null | head -n \"$limit\" | while IFS=\"$(printf '\\t')\" read -r id preview; do "
            + "[ -z \"$preview\" ] && preview=\"$id\"; clean=$(printf '%s' \"$preview\" | tr '\\037\\r\\n' '   ' | sed 's/[[:space:]][[:space:]]*/ /g'); kind=text; path=; "
            + "case \"$clean\" in *image/*|*'[image'*|*PNG*|*JPEG*|*png*|*jpeg*) kind=image; safe=$(printf '%s' \"$id\" | tr -cd '[:alnum:]_.-'); [ -z \"$safe\" ] && safe=item; out=\"$dir/$safe.png\"; if printf '%s' \"$id\" | cliphist decode > \"$out\" 2>/dev/null && [ -s \"$out\" ]; then path=\"$out\"; else path=; fi;; esac; "
            + "printf 'entry=%s%s%s%s%s%s%s\\n' \"$id\" \"$sep\" \"$kind\" \"$sep\" \"$clean\" \"$sep\" \"$path\"; done; "
            + "elif [ \"$use\" = copyq ]; then cq() { if command -v timeout >/dev/null 2>&1; then timeout 1 copyq \"$@\"; else copyq \"$@\"; fi; }; count=$(cq count 2>/dev/null || echo 0); i=0; while [ \"$i\" -lt \"$count\" ] && [ \"$i\" -lt \"$limit\" ]; do preview=$(cq read \"$i\" 2>/dev/null | head -c 180 | tr '\\037\\r\\n' '   ' | sed 's/[[:space:]][[:space:]]*/ /g'); [ -z \"$preview\" ] && preview='Binary item'; printf 'entry=%s%s%s%s%s%s\\n' \"$i\" \"$sep\" text \"$sep\" \"$preview\" \"$sep\"; i=$((i+1)); done; "
            + "else printf 'status=No clipboard history backend\\n'; fi"
        ];
        refreshProc.running = true;
    }

    function parseEntries(text) {
        const next = [];
        const lines = String(text || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.indexOf("backend=") === 0) {
                backend = line.slice(8);
            } else if (line.indexOf("status=") === 0) {
                statusText = line.slice(7);
            } else if (line.indexOf("entry=") === 0) {
                const parts = line.slice(6).split("\u001f");
                next.push({
                    "id": parts[0] || "",
                    "kind": parts[1] || "text",
                    "preview": parts[2] || "",
                    "path": parts[3] || ""
                });
            }
        }
        entries = next;
        if (entries.length > 0) statusText = entries.length + " items";
        else if (statusText === "Loading") statusText = "Empty";
    }

    function copyEntry(id) {
        if (copyProc.running || backend.length <= 0) return;
        const quoted = shellQuote(id);
        if (backend === "cliphist") {
            copyProc.command = ["sh", "-c", "printf %s " + quoted + " | cliphist decode | wl-copy"];
        } else if (backend === "copyq") {
            copyProc.command = ["sh", "-c", "if command -v timeout >/dev/null 2>&1; then timeout 1 copyq select " + quoted + "; else copyq select " + quoted + "; fi"];
        } else {
            return;
        }
        statusText = "Copied";
        copyProc.running = true;
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -clipboardFrame.height - settings.settingsPanelGap : panelWindow.height + settings.settingsPanelGap) : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: clipboardFrame.height
    visible: panelOpen || panelClosing
    grabFocus: panelOpen
    color: "transparent"

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

    Process {
        id: refreshProc

        stdout: StdioCollector { onStreamFinished: root.parseEntries(text) }
        stderr: StdioCollector { onStreamFinished: if (text.length > 0) root.statusText = "Backend error" }
    }

    Process {
        id: copyProc

        stdout: StdioCollector {}
        stderr: StdioCollector { onStreamFinished: if (text.length > 0) root.statusText = "Copy failed" }
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
        id: clipboardFrame

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

            HeaderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                icon: "󰅌"
                title: "Clipboard"
                detail: root.backend.length > 0 ? root.backend : "history"
                status: root.statusText
                onRefreshRequested: root.refresh()
            }

            Flickable {
                width: parent.width
                height: Math.min(clipboardList.implicitHeight, settings.controlHeight * 8)
                contentWidth: width
                contentHeight: clipboardList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: clipboardList

                    width: parent.width
                    spacing: settings.effectiveContentSpacing

                    Repeater {
                        model: root.entries

                        ClipboardRow {
                            required property var modelData

                            width: parent.width
                            theme: root.theme
                            settings: root.settings
                            entry: modelData
                            onPressed: root.copyEntry(String(entry.id || ""))
                        }
                    }
                }
            }
        }
    }

    component HeaderRow: Row {
        id: header

        property var theme
        property var settings
        property string icon: ""
        property string title: ""
        property string detail: ""
        property string status: ""

        signal refreshRequested()

        height: settings.controlHeight
        spacing: settings.effectiveContentSpacing

        Text {
            width: settings.controlHeight
            height: parent.height
            text: header.icon
            color: theme.primary
            font.family: settings.fontFamilyIcon
            font.pixelSize: settings.effectiveIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Column {
            width: parent.width - settings.controlHeight * 2 - status.width - parent.spacing * 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

            Text {
                width: parent.width
                text: header.title
                color: theme.text
                elide: Text.ElideRight
                font.family: settings.fontFamilySans
                font.pixelSize: Math.round(settings.effectiveFontSize * 1.06)
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: header.detail
                color: theme.textMuted
                elide: Text.ElideRight
                font.family: settings.fontFamilySans
                font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
            }
        }

        Text {
            id: status

            width: settings.effectiveSpacingXL * 3
            height: parent.height
            text: header.status
            color: theme.textMuted
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            font.family: settings.fontFamilySans
            font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
        }

        Rectangle {
            width: settings.controlHeight
            height: settings.controlHeight
            radius: settings.effectivePillRadius
            color: refreshHover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceContainer, 0.42)
            border.color: theme.outlineSubtle
            border.width: settings.effectiveBorderWidth
            antialiasing: true

            Text {
                anchors.centerIn: parent
                text: "󰑐"
                color: theme.text
                font.family: settings.fontFamilyIcon
                font.pixelSize: settings.effectiveIconSize
            }

            MouseArea {
                id: refreshHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: header.refreshRequested()
            }
        }
    }

    component ClipboardRow: Rectangle {
        id: row

        property var theme
        property var settings
        property var entry: ({})
        readonly property bool imageEntry: String(entry.kind || "") === "image" && String(entry.path || "").length > 0

        signal pressed()

        implicitHeight: imageEntry ? settings.controlHeight * 2.25 : settings.controlHeight * 1.55
        radius: settings.effectivePillRadius
        color: hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceContainer, 0.42)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        clip: true

        Row {
            anchors.fill: parent
            anchors.margins: settings.effectiveContentSpacing
            spacing: settings.effectiveContentSpacing

            Rectangle {
                width: row.imageEntry ? parent.height : settings.controlHeight
                height: parent.height
                radius: settings.effectivePillRadius
                color: theme.alpha(row.imageEntry ? theme.primary : theme.secondary, 0.16)
                border.color: theme.outlineSubtle
                border.width: settings.effectiveBorderWidth
                antialiasing: true
                clip: true

                Image {
                    anchors.fill: parent
                    visible: row.imageEntry
                    source: row.imageEntry ? "file://" + String(row.entry.path || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: !row.imageEntry
                    text: "󰅌"
                    color: theme.secondary
                    font.family: settings.fontFamilyIcon
                    font.pixelSize: settings.effectiveIconSize
                }
            }

            Column {
                width: parent.width - parent.spacing - (row.imageEntry ? parent.height : settings.controlHeight)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                Text {
                    width: parent.width
                    text: String(row.entry.preview || "")
                    color: theme.text
                    elide: Text.ElideRight
                    maximumLineCount: row.imageEntry ? 2 : 1
                    wrapMode: Text.Wrap
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                    font.weight: Font.Medium
                }

                Text {
                    width: parent.width
                    text: row.imageEntry ? "Image item" : "Text item"
                    color: theme.textMuted
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                }
            }
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.pressed()
        }
    }
}
