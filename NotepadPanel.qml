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
    property bool loaded: false
    property bool suppressSave: false
    property string noteText: ""
    property string savedText: ""
    property string savingText: ""
    property string resolvedPath: ""
    property string saveStatus: ""
    readonly property int panelWidth: settings ? Math.round(Math.min(panelWindow ? panelWindow.width : settings.effectiveSpacingXL * 18, Math.max(settings.effectiveSpacingXL * 15, settings.notepadPanelWidth))) : 420

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\\''") + "'";
    }

    function pathPrefix() {
        return "path=" + shellQuote(settings ? settings.notepadFilePath : "") + "; "
            + "if [ -z \"$path\" ]; then state=\"${XDG_STATE_HOME:-$HOME/.local/state}/calypso\"; mkdir -p \"$state\"; path=\"$state/notepad.txt\"; "
            + "else case \"$path\" in ~/*) path=\"$HOME/${path#~/}\";; esac; mkdir -p \"$(dirname \"$path\")\"; fi; ";
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
        loadNote();
    }

    function close() {
        if (!panelOpen && !panelClosing) return;
        if (noteText !== savedText)
            saveNote();
        panelClosing = true;
        panelOpen = false;
        closeTimer.restart();
    }

    function loadNote() {
        if (loadProc.running) return;
        loaded = false;
        saveStatus = "Loading";
        loadProc.command = ["sh", "-c", pathPrefix() + "printf 'path=%s\\n' \"$path\"; if [ -r \"$path\" ]; then cat \"$path\"; fi"];
        loadProc.running = true;
    }

    function applyLoaded(text) {
        const raw = String(text || "");
        const newline = raw.indexOf("\n");
        let body = "";

        if (newline >= 0 && raw.slice(0, 5) === "path=") {
            resolvedPath = raw.slice(5, newline);
            body = raw.slice(newline + 1);
        } else {
            body = raw;
        }

        suppressSave = true;
        noteText = body;
        savedText = body;
        suppressSave = false;
        loaded = true;
        saveStatus = "Saved";
    }

    function saveNote() {
        if (!loaded || saveProc.running) return;
        saveTimer.stop();
        saveStatus = "Saving";
        savingText = noteText;
        saveProc.command = ["sh", "-c", pathPrefix() + "printf %s " + shellQuote(noteText) + " > \"$path\""];
        saveProc.running = true;
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -notepadFrame.height - settings.settingsPanelGap : panelWindow.height + settings.settingsPanelGap) : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: notepadFrame.height
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

    Timer {
        id: saveTimer

        interval: settings ? settings.notepadAutosaveMs : 600
        repeat: false
        onTriggered: root.saveNote()
    }

    Process {
        id: loadProc

        stdout: StdioCollector { onStreamFinished: root.applyLoaded(text) }
        stderr: StdioCollector { onStreamFinished: if (text.length > 0) root.saveStatus = "Load failed" }
    }

    Process {
        id: saveProc

        stdout: StdioCollector {}
        stderr: StdioCollector { onStreamFinished: if (text.length > 0) root.saveStatus = "Save failed" }
        onExited: {
            root.savedText = root.savingText;
            if (root.noteText !== root.savedText) {
                root.saveStatus = "Unsaved";
                saveTimer.restart();
            } else if (root.saveStatus !== "Save failed") {
                root.saveStatus = "Saved";
            }
        }
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
        id: notepadFrame

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
                    text: "󰎞"
                    color: theme.primary
                    font.family: settings.fontFamilyIcon
                    font.pixelSize: settings.effectiveIconSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Column {
                    width: parent.width - settings.controlHeight - statusText.width - parent.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                    Text {
                        width: parent.width
                        text: "Notepad"
                        color: theme.text
                        elide: Text.ElideRight
                        font.family: settings.fontFamilySans
                        font.pixelSize: Math.round(settings.effectiveFontSize * 1.06)
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: root.resolvedPath.length > 0 ? root.resolvedPath : "Local scratchpad"
                        color: theme.textMuted
                        elide: Text.ElideMiddle
                        font.family: settings.fontFamilySans
                        font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                    }
                }

                Text {
                    id: statusText

                    width: settings.effectiveSpacingXL * 2.8
                    height: parent.height
                    text: root.saveStatus
                    color: root.noteText === root.savedText ? theme.textMuted : theme.warning
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    font.family: settings.fontFamilySans
                    font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                width: parent.width
                height: Math.max(settings.effectiveSpacingXL * 8, settings.controlHeight * 6)
                radius: settings.effectivePillRadius
                color: theme.alpha(theme.surfaceContainer, 0.52)
                border.color: theme.outlineSubtle
                border.width: settings.effectiveBorderWidth
                antialiasing: true
                clip: true

                Flickable {
                    id: noteFlick

                    anchors.fill: parent
                    anchors.margins: settings.effectiveContentSpacing
                    contentWidth: width
                    contentHeight: Math.max(height, editor.implicitHeight)
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    TextEdit {
                        id: editor

                        width: noteFlick.width
                        text: root.noteText
                        color: theme.text
                        selectionColor: theme.alpha(theme.primary, 0.32)
                        selectedTextColor: theme.text
                        wrapMode: TextEdit.Wrap
                        font.family: settings.fontFamilySans
                        font.pixelSize: settings.effectiveFontSize
                        onTextChanged: {
                            if (root.suppressSave || !root.loaded || text === root.noteText) return;
                            root.noteText = text;
                            root.saveStatus = "Unsaved";
                            saveTimer.restart();
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: settings.effectiveContentSpacing
                    visible: editor.text.length <= 0 && root.loaded
                    text: "Scratchpad"
                    color: theme.textMuted
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                }
            }
        }
    }
}
