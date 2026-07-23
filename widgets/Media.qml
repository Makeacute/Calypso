import QtQuick

Item {
    id: root

    property var theme
    property var settings
    property var tooltipHost
    property var mediaService
    property string moduleInstanceId: "media"
    property var moduleSettings: ({})
    readonly property bool showControls: moduleSettings.showControls === undefined
                                             ? settings.mediaShowControls
                                             : Boolean(moduleSettings.showControls)
    readonly property int maximumWidth: moduleSettings.maxWidth === undefined
                                            ? settings.mediaMaxWidth
                                            : Number(moduleSettings.maxWidth)
    readonly property int maximumTitleLength: moduleSettings.maxTitleLength === undefined
                                                  ? settings.mediaMaxTitleLength
                                                  : Number(moduleSettings.maxTitleLength)
    readonly property string playerName: mediaService ? String(mediaService.playerName || "") : ""
    readonly property string status: mediaService ? String(mediaService.status || "") : ""
    readonly property string title: mediaService ? String(mediaService.title || "") : ""
    readonly property string artist: mediaService ? String(mediaService.artist || "") : ""
    readonly property bool hasPlayer: mediaService ? Boolean(mediaService.hasPlayer) : false
    readonly property bool playing: mediaService ? Boolean(mediaService.playing) : false
    readonly property bool canPrevious: mediaService ? Boolean(mediaService.canPrevious) : false
    readonly property bool canToggle: mediaService ? Boolean(mediaService.canToggle) : false
    readonly property bool canNext: mediaService ? Boolean(mediaService.canNext) : false

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

    function runAction(action) {
        if (!mediaService || !hasPlayer)
            return;
        if (action === "play-pause")
            mediaService.togglePlaying();
        else if (action === "previous")
            mediaService.previous();
        else if (action === "next")
            mediaService.next();
    }

    function trackText() {
        if (!hasPlayer) return "";

        const safeTitle = cleanText(title);
        const safeArtist = cleanText(artist);
        const identity = cleanText(playerName);
        const maxLength = Math.max(4, maximumTitleLength);
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
            maximumTextWidth: root.maximumWidth
            onClicked: root.runAction("play-pause")
        }

        Pill {
            theme: root.theme
            settings: root.settings
            tooltipHost: root.tooltipHost
            visible: root.showControls
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
            visible: root.showControls
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
            visible: root.showControls
            icon: ""
            enabled: root.canNext
            muted: !root.canNext
            clickable: root.canNext
            minimumWidth: root.settings.moduleHeight
            onClicked: root.runAction("next")
        }
    }

}
