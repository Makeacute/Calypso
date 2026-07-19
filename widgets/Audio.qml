import QtQuick
import Quickshell.Services.Pipewire

Pill {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property var osd: null
    property bool hasAudio: sink && sink.audio
    property real volume: hasAudio ? sink.audio.volume : 0
    property bool isMuted: hasAudio ? sink.audio.muted : true

    icon: audioIcon()
    text: audioText()
    detailText: settings.widgetStyle === "expanded" ? audioDeviceName() : ""
    muted: isMuted || !hasAudio
    progress: hasAudio ? Math.max(0, Math.min(1, volume)) : -1
    progressColor: isMuted ? theme.alpha(theme.textMuted, 0.10) : theme.alpha(theme.accent, 0.16)
    iconMorphOnChange: settings.iconMorphTransitions
    textPulseOnChange: hasAudio && text.length > 0
    maximumTextWidth: settings.audioShowDeviceName ? 140 : 54
    detailsOnClick: true
    detailsModuleName: "audio"
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
        if (settings.audioShowPercentage) parts.push(Math.round(volume * 100) + "%");

        if (settings.audioShowDeviceName) {
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

        if (osd && typeof osd.show === "function") {
            osd.show(audioIconFor(next, false), next);
        }
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
