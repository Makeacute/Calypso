import QtQuick
import Quickshell.Services.Pipewire

Pill {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property bool hasAudio: sink && sink.audio
    property real volume: hasAudio ? sink.audio.volume : 0
    property bool isMuted: hasAudio ? sink.audio.muted : true
    readonly property bool showPercentage: moduleSettings.showPercentage === undefined
                                               ? settings.audioShowPercentage
                                               : Boolean(moduleSettings.showPercentage)
    readonly property bool showDeviceName: moduleSettings.showDeviceName === undefined
                                               ? settings.audioShowDeviceName
                                               : Boolean(moduleSettings.showDeviceName)

    icon: audioIcon()
    text: audioText()
    detailText: settings.widgetStyle === "expanded" && showDeviceName ? audioDeviceName() : ""
    muted: isMuted || !hasAudio
    progress: hasAudio ? Math.max(0, Math.min(1, volume)) : -1
    progressColor: isMuted ? theme.alpha(theme.textMuted, 0.10) : theme.alpha(theme.accent, 0.16)
    iconMorphOnChange: settings.iconMorphTransitions
    textPulseOnChange: hasAudio && text.length > 0
    maximumTextWidth: showDeviceName ? theme.moduleAudioDeviceWidth : theme.moduleBatteryValueWidth
    detailsOnClick: true
    detailsModuleName: moduleInstanceId || "audio"
    scrollable: hasAudio
    onScrolled: function(steps, wheel) {
        changeVolume(steps);
    }

    function audioIcon() {
        return audioIconFor(volume, isMuted);
    }

    function audioIconFor(value, muted) {
        if (!hasAudio || muted || value <= 0) return "󰖁";
        if (muted || value <= 0) return "󰖁";
        if (value < 0.35) return "󰕿";
        if (value < 0.70) return "󰖀";
        return "󰕾";
    }

    function audioDeviceName() {
        if (!sink) return "";

        const name = String(sink.description || sink.name || sink.nodeName || "").trim();
        if (name.length === 0) return "";
        return name.length > 18 ? name.slice(0, 18) : name;
    }

    function audioText() {
        if (!hasAudio) return "off";

        const parts = [];
        if (showPercentage) parts.push(Math.round(volume * 100) + "%");

        if (showDeviceName) {
            const name = audioDeviceName();
            if (name.length > 0) parts.push(name);
        }

        return parts.join(" ");
    }

    function changeVolume(steps) {
        if (!hasAudio || steps === 0) return;

        const next = Math.max(0, Math.min(1, volume + steps * 0.05));
        sink.audio.volume = next;

        if (next > 0 && sink.audio.muted) {
            sink.audio.muted = false;
        }
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
