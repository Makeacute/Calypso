import QtQuick
import Quickshell.Io

Item {
    id: root

    property var theme
    property var settings
    property var tooltipHost
    property string playerName: ""
    property string status: ""
    property string title: ""
    property string artist: ""
    readonly property bool hasPlayer: playerName.length > 0
    readonly property bool playing: status === "Playing"
    readonly property bool canPrevious: hasPlayer
    readonly property bool canToggle: hasPlayer
    readonly property bool canNext: hasPlayer

    visible: hasPlayer || opacity > 0
    opacity: hasPlayer ? 1 : 0
    x: hasPlayer ? 0 : -theme.spacingXL
    scale: hasPlayer ? 1 : 0.96
    implicitWidth: hasPlayer || opacity > 0 ? content.implicitWidth : 0
    implicitHeight: hasPlayer || opacity > 0 ? root.settings.moduleHeight : 0
    width: implicitWidth
    height: implicitHeight

    Behavior on opacity {
        NumberAnimation { duration: settings.motionNormal; easing.type: root.hasPlayer ? Easing.OutExpo : Easing.InCubic }
    }

    Behavior on x {
        NumberAnimation { duration: settings.motionOpen; easing.type: root.hasPlayer ? Easing.OutExpo : Easing.InCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: settings.motionNormal; easing.type: root.hasPlayer ? Easing.OutCubic : Easing.InCubic }
    }

    function cleanText(value) {
        return String(value || "").trim();
    }

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\\''") + "'";
    }

    function clearPlayer() {
        playerName = "";
        status = "";
        title = "";
        artist = "";
    }

    function updateMetadata(text) {
        const line = String(text || "").trim().split("\n")[0] || "";
        if (line.length <= 0) {
            clearPlayer();
            return;
        }

        const parts = line.split("|");
        playerName = cleanText(parts[0]);
        status = cleanText(parts[1]);
        title = cleanText(parts[2]);
        artist = cleanText(parts[3]);
    }

    function refresh() {
        if (metadataProc.running) return;

        metadataProc.command = [
            "sh",
            "-c",
            "command -v playerctl >/dev/null 2>&1 && playerctl metadata --format '{{playerName}}|{{status}}|{{title}}|{{artist}}' 2>/dev/null || true"
        ];
        metadataProc.running = true;
    }

    function runAction(action) {
        if (!hasPlayer || actionProc.running) return;
        actionProc.command = ["sh", "-c", "playerctl -p " + shellQuote(playerName) + " " + action + " >/dev/null 2>&1 || true"];
        actionProc.running = true;
    }

    function trackText() {
        if (!hasPlayer) return "";

        const safeTitle = cleanText(title);
        const safeArtist = cleanText(artist);
        const identity = cleanText(playerName);
        const maxLength = Math.max(4, settings.mediaMaxTitleLength);
        let label = "";

        if (safeTitle.length > 0 && safeArtist.length > 0) label = safeTitle + " - " + safeArtist;
        else if (safeTitle.length > 0) label = safeTitle;
        else if (safeArtist.length > 0) label = safeArtist;
        else if (identity.length > 0) label = identity;
        else label = "Media";

        return label.length > maxLength ? label.slice(0, maxLength - 2) + ".." : label;
    }

    Row {
        id: content

        visible: root.hasPlayer || root.opacity > 0
        spacing: root.settings.itemSpacing
        height: root.settings.moduleHeight

        Pill {
            theme: root.theme
            settings: root.settings
            tooltipHost: root.tooltipHost
            icon: root.playing ? "" : ""
            text: root.trackText()
            detailText: settings.widgetStyle === "expanded" && root.hasPlayer ? root.playerName : ""
            active: root.playing
            muted: !root.playing
            clickable: root.canToggle
            iconMorphOnChange: settings.iconMorphTransitions
            textPulseOnChange: true
            maximumTextWidth: settings.mediaMaxWidth
            onClicked: root.runAction("play-pause")
        }

        Pill {
            theme: root.theme
            settings: root.settings
            tooltipHost: root.tooltipHost
            visible: settings.mediaShowControls
            icon: ""
            enabled: root.canPrevious
            muted: !root.canPrevious
            clickable: root.canPrevious
            minimumWidth: root.settings.moduleHeight
            onClicked: root.runAction("previous")
        }

        Pill {
            theme: root.theme
            settings: root.settings
            tooltipHost: root.tooltipHost
            visible: settings.mediaShowControls
            icon: root.playing ? "" : ""
            active: root.playing
            enabled: root.canToggle
            muted: !root.canToggle
            clickable: root.canToggle
            iconMorphOnChange: settings.iconMorphTransitions
            minimumWidth: root.settings.moduleHeight
            onClicked: root.runAction("play-pause")
        }

        Pill {
            theme: root.theme
            settings: root.settings
            tooltipHost: root.tooltipHost
            visible: settings.mediaShowControls
            icon: ""
            enabled: root.canNext
            muted: !root.canNext
            clickable: root.canNext
            minimumWidth: root.settings.moduleHeight
            onClicked: root.runAction("next")
        }
    }

    Process {
        id: metadataProc

        stdout: StdioCollector { onStreamFinished: root.updateMetadata(text) }
        stderr: StdioCollector {}
    }

    Process {
        id: actionProc

        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: root.refresh()
    }

    Timer {
        interval: settings.mediaPollMs
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
