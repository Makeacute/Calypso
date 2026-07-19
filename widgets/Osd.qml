pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

PanelWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property string osdIcon: ""
    property string osdLabel: ""
    property string osdType: "generic"
    property real osdValue: 0
    property bool open: false
    property real reveal: open ? 1 : 0
    property bool initialized: false
    property real lastVolume: -1
    property bool lastMuted: false
    property string backlightPath: ""
    property real lastBrightness: -1

    function clamp01(value) {
        return Math.max(0, Math.min(1, Number(value) || 0));
    }

    function enabledFor(type) {
        if (!settings || !settings.osdEnabled) return false;
        if (type === "workspace" || type === "wallpaper") return false;
        if (type === "volume" || type === "mute") return settings.osdVolume;
        if (type === "brightness") return settings.osdBrightness;
        if (type === "keyboard") return settings.osdKeyboardBacklight;
        if (type === "media") return settings.osdMedia;
        if (type === "battery") return settings.osdBattery;
        return true;
    }

    function show(icon, value, type, label) {
        const nextType = String(type || "volume");
        if (!enabledFor(nextType)) return;

        osdIcon = String(icon || "");
        osdValue = clamp01(value);
        osdType = nextType;
        osdLabel = String(label || "");
        open = true;
        hideTimer.restart();
    }

    function audioIcon(value, muted) {
        if (muted || value <= 0) return "󰖁";
        if (value < 0.35) return "󰕿";
        if (value < 0.70) return "󰖀";
        return "󰕾";
    }

    function brightnessIcon(value) {
        if (value < 0.34) return "󰃞";
        if (value < 0.67) return "󰃟";
        return "󰃠";
    }

    function defaultLabel() {
        if (osdLabel.length > 0) return osdLabel;
        if (osdType === "mute") return "Muted";
        if (osdType === "brightness") return "Brightness";
        if (osdType === "battery") return "Battery";
        if (osdType === "media") return "Media";
        return "Volume";
    }

    function surfaceWidth() {
        const scale = settings ? settings.osdSize : 1;
        if (settings && settings.osdStyle === "vertical")
            return Math.round(settings.effectiveSpacingXL * 1.65 * scale);
        if (settings && settings.osdStyle === "minimal")
            return Math.round(settings.effectiveSpacingXL * 4.4 * scale);
        return Math.round(settings.effectiveSpacingXL * 9.6 * scale);
    }

    function surfaceHeight() {
        const scale = settings ? settings.osdSize : 1;
        if (settings && settings.osdStyle === "vertical")
            return Math.round(settings.effectiveSpacingXL * 7.8 * scale);
        if (settings && settings.osdStyle === "minimal")
            return Math.round(settings.effectiveSpacingXL * 2.2 * scale);
        return Math.round(settings.effectiveSpacingXL * 2.9 * scale);
    }

    function surfaceX(widthValue) {
        const margin = settings ? settings.effectiveSpacingL : 16;
        const pos = settings ? settings.osdPosition : "rightCenter";
        if (pos === "leftCenter") return margin;
        if (pos === "topRight" || pos === "bottomRight" || pos === "rightCenter")
            return Math.max(margin, width - widthValue - margin);
        return Math.max(margin, (width - widthValue) / 2);
    }

    function surfaceY(heightValue) {
        const margin = settings ? settings.effectiveSpacingL : 16;
        const pos = settings ? settings.osdPosition : "rightCenter";
        if (pos === "topCenter" || pos === "topRight") return margin;
        if (pos === "bottomCenter" || pos === "bottomRight")
            return Math.max(margin, height - heightValue - margin);
        return Math.max(margin, (height - heightValue) / 2);
    }

    function updateBacklightPath(text) {
        const path = String(text || "").trim().split("\n")[0] || "";
        backlightPath = path;
        brightnessFile.path = path;
        if (path.length > 0 && !brightnessReadProc.running)
            brightnessReadProc.running = true;
    }

    function updateBrightness(text) {
        const parts = String(text || "").trim().split(/\s+/).map(Number);
        if (parts.length < 2 || !Number.isFinite(parts[0]) || !Number.isFinite(parts[1]) || parts[1] <= 0)
            return;

        const value = clamp01(parts[0] / parts[1]);
        if (initialized && lastBrightness >= 0 && Math.abs(value - lastBrightness) > 0.004)
            show(brightnessIcon(value), value, "brightness", "Brightness");
        lastBrightness = value;
    }

    screen: panelWindow ? panelWindow.screen : Quickshell.screens[0]
    visible: open || reveal > 0.001
    focusable: false
    color: "transparent"
    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "calypso-osd"

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    Connections {
        target: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return;
            const next = root.clamp01(Pipewire.defaultAudioSink.audio.volume);
            const muted = Pipewire.defaultAudioSink.audio.muted;
            if (root.initialized && root.lastVolume >= 0 && Math.abs(next - root.lastVolume) > 0.004)
                root.show(root.audioIcon(next, muted), next, muted ? "mute" : "volume", muted ? "Muted" : "Volume");
            root.lastVolume = next;
            root.lastMuted = muted;
        }

        function onMutedChanged() {
            if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return;
            const next = root.clamp01(Pipewire.defaultAudioSink.audio.volume);
            const muted = Pipewire.defaultAudioSink.audio.muted;
            if (root.initialized && muted !== root.lastMuted)
                root.show(root.audioIcon(next, muted), next, muted ? "mute" : "volume", muted ? "Muted" : "Volume");
            root.lastVolume = next;
            root.lastMuted = muted;
        }
    }

    Timer {
        id: initTimer

        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                root.lastVolume = root.clamp01(Pipewire.defaultAudioSink.audio.volume);
                root.lastMuted = Pipewire.defaultAudioSink.audio.muted;
            }
            root.initialized = true;
        }
    }

    Timer {
        id: hideTimer

        interval: settings ? settings.osdTimeout : 1500
        repeat: false
        onTriggered: root.open = false
    }

    Process {
        id: backlightDiscovery

        command: ["sh", "-c", "p=$(find -L /sys/class/backlight -maxdepth 2 -name brightness 2>/dev/null | head -1); [ -n \"$p\" ] && printf '%s\\n' \"$p\""]
        running: true
        stdout: StdioCollector { onStreamFinished: root.updateBacklightPath(text) }
        stderr: StdioCollector {}
    }

    FileView {
        id: brightnessFile

        path: ""
        watchChanges: true
        printErrors: false
        onFileChanged: if (!brightnessReadProc.running) brightnessReadProc.running = true
    }

    Process {
        id: brightnessReadProc

        command: [
            "sh",
            "-c",
            root.backlightPath.length > 0
                ? "p='" + root.backlightPath.replace(/'/g, "'\\''") + "'; if [ -r \"$p\" ]; then d=$(dirname \"$p\"); cat \"$p\" \"$d/max_brightness\" 2>/dev/null; fi"
                : ""
        ]
        stdout: StdioCollector { onStreamFinished: root.updateBrightness(text) }
        stderr: StdioCollector {}
    }

    Timer {
        interval: settings ? Math.max(settings.motionOpen, Math.round(settings.osdTimeout / 2)) : 1000
        running: root.backlightPath.length > 0 && settings && settings.osdEnabled && settings.osdBrightness
        repeat: true
        onTriggered: if (!brightnessReadProc.running) brightnessReadProc.running = true
    }

    Behavior on reveal {
        NumberAnimation {
            duration: root.open ? theme.motionOpen : theme.motionClose
            easing.type: root.open ? Easing.OutExpo : Easing.InCubic
        }
    }

    Rectangle {
        id: pill

        readonly property bool vertical: settings && settings.osdStyle === "vertical"
        readonly property bool minimal: settings && settings.osdStyle === "minimal"
        readonly property real slideDistance: settings ? settings.effectiveSpacingM : 12

        width: root.surfaceWidth()
        height: root.surfaceHeight()
        x: root.surfaceX(width)
        y: root.surfaceY(height) + (1 - root.reveal) * (settings && (settings.osdPosition === "bottomCenter" || settings.osdPosition === "bottomRight") ? slideDistance : -slideDistance)
        radius: pill.vertical ? Math.min(width / 2, Math.round(settings.effectiveRadiusXL)) : settings.effectiveRadiusL
        color: theme.alpha(theme.surfaceContainerHigh, settings.osdOpacity)
        border.color: settings.barBorderEnabled ? theme.border : theme.outlineSubtle
        border.width: settings.barBorderEnabled ? settings.barBorderThickness : settings.effectiveBorderWidth
        opacity: root.reveal
        scale: 0.96 + root.reveal * 0.04
        antialiasing: true
        clip: true

        Behavior on color { ColorAnimation { duration: theme.motionNormal } }
        Behavior on x { NumberAnimation { duration: theme.motionNormal; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: theme.motionNormal; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: theme.motionNormal; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: theme.motionNormal; easing.type: Easing.OutCubic } }

        Item {
            anchors.fill: parent
            anchors.margins: settings.effectiveSpacingM
            visible: pill.vertical

            Text {
                width: parent.width
                visible: settings.osdShowPercent
                text: Math.round(root.osdValue * 100) + "%"
                color: theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                font.family: settings.fontFamilyMono
                font.pixelSize: Math.max(9, Math.round(settings.effectiveFontSize * 0.92))
                font.weight: Font.Bold
            }

            Rectangle {
                id: verticalTrack

                width: Math.max(settings.effectiveBorderWidth * 4, Math.round(settings.effectiveSpacingS * 0.75))
                anchors.top: parent.top
                anchors.bottom: iconLabel.top
                anchors.topMargin: settings.osdShowPercent ? settings.effectiveFontSize * 1.55 : 0
                anchors.bottomMargin: settings.effectiveSpacingM
                anchors.horizontalCenter: parent.horizontalCenter
                radius: width / 2
                color: theme.alpha(theme.text, 0.12)
                border.color: theme.outlineSubtle
                border.width: settings.effectiveBorderWidth
                clip: true
                antialiasing: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: settings.effectiveBorderWidth
                    height: Math.max(0, (parent.height - settings.effectiveBorderWidth * 2) * root.osdValue)
                    radius: width / 2
                    color: root.osdType === "mute" ? theme.textMuted : theme.accent
                    antialiasing: true
                    Behavior on height { NumberAnimation { duration: theme.motionHover; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: theme.motionNormal } }
                }
            }

            Text {
                id: iconLabel

                anchors.bottom: parent.bottom
                width: parent.width
                visible: settings.osdShowIcon
                text: root.osdIcon
                color: root.osdType === "mute" ? theme.textMuted : theme.accent
                horizontalAlignment: Text.AlignHCenter
                font.family: settings.fontFamilyIcon
                font.pixelSize: settings.effectiveIconSize
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: settings.effectiveSpacingM
            spacing: settings.effectiveSpacingM
            visible: !pill.vertical

            Text {
                visible: settings.osdShowIcon
                width: settings.controlHeight
                height: parent.height
                text: root.osdIcon
                color: root.osdType === "mute" ? theme.textMuted : theme.accent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: settings.fontFamilyIcon
                font.pixelSize: settings.effectiveIconSize
            }

            Column {
                width: parent.width - (settings.osdShowIcon ? settings.controlHeight + parent.spacing : 0)
                       - (settings.osdShowPercent ? settings.effectiveFontSize * 4.2 + parent.spacing : 0)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.45))

                Text {
                    width: parent.width
                    visible: !pill.minimal
                    text: root.defaultLabel()
                    color: theme.text
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    width: parent.width
                    height: Math.max(settings.effectiveBorderWidth * 3, Math.round(settings.effectiveSpacingS * 0.72))
                    radius: height / 2
                    color: theme.alpha(theme.text, 0.12)
                    antialiasing: true
                    clip: true

                    Rectangle {
                        width: parent.width * root.osdValue
                        height: parent.height
                        radius: parent.radius
                        color: root.osdType === "mute" ? theme.textMuted : theme.accent
                        antialiasing: true
                        Behavior on width { NumberAnimation { duration: theme.motionHover; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: theme.motionNormal } }
                    }
                }
            }

            Text {
                visible: settings.osdShowPercent
                width: settings.effectiveFontSize * 4.2
                height: parent.height
                text: Math.round(root.osdValue * 100) + "%"
                color: theme.textMuted
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                font.family: settings.fontFamilyMono
                font.pixelSize: Math.round(settings.effectiveFontSize * 1.08)
                font.weight: Font.Bold
            }
        }
    }
}
