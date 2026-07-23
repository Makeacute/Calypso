pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Scope {
    id: root

    property string selectedPlayerId: ""

    readonly property var players: Mpris.players.values
    readonly property var player: resolvePlayer()
    readonly property bool available: true
    readonly property bool connected: players.length > 0
    readonly property bool reconnecting: false
    readonly property string healthStatus: connected ? "active" : "idle"
    readonly property string lastError: ""

    readonly property bool hasPlayer: player !== null
    readonly property string playerId: hasPlayer ? String(player.dbusName || "") : ""
    readonly property string playerName: hasPlayer ? String(player.identity || player.dbusName || "") : ""
    readonly property string identity: playerName
    readonly property string desktopEntry: hasPlayer ? String(player.desktopEntry || "") : ""
    readonly property string playbackStatus: hasPlayer
                                                     ? MprisPlaybackState.toString(player.playbackState)
                                                     : "Stopped"
    readonly property string status: playbackStatus
    readonly property bool playing: hasPlayer && player.isPlaying
    readonly property string title: hasPlayer ? String(player.trackTitle || "") : ""
    readonly property string artist: hasPlayer ? String(player.trackArtist || "") : ""
    readonly property string album: hasPlayer ? String(player.trackAlbum || "") : ""
    readonly property string albumArtist: hasPlayer ? String(player.trackAlbumArtist || "") : ""
    readonly property string artUrl: hasPlayer ? String(player.trackArtUrl || "") : ""
    readonly property real position: hasPlayer && player.positionSupported ? Number(player.position) || 0 : 0
    readonly property real length: hasPlayer && player.lengthSupported ? Number(player.length) || 0 : 0
    readonly property real volume: hasPlayer && player.volumeSupported ? Number(player.volume) || 0 : 0
    readonly property bool canPlay: hasPlayer && player.canPlay
    readonly property bool canPause: hasPlayer && player.canPause
    readonly property bool canToggle: hasPlayer && player.canTogglePlaying
    readonly property bool canPrevious: hasPlayer && player.canGoPrevious
    readonly property bool canNext: hasPlayer && player.canGoNext
    readonly property bool canSeek: hasPlayer && player.canSeek
    readonly property bool canSetVolume: hasPlayer && player.volumeSupported

    signal actionFailed(string action, string message)

    function resolvePlayer() {
        const list = Array.from(players || []);

        if (selectedPlayerId.length > 0) {
            for (let i = 0; i < list.length; i++) {
                if (String(list[i].dbusName || "") === selectedPlayerId)
                    return list[i];
            }
        }

        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying)
                return list[i];
        }

        return list.length > 0 ? list[0] : null;
    }

    function selectPlayer(id) {
        const requested = String(id || "");
        if (requested.length === 0) {
            selectedPlayerId = "";
            return true;
        }

        const list = Array.from(players || []);
        for (let i = 0; i < list.length; i++) {
            if (String(list[i].dbusName || "") === requested) {
                selectedPlayerId = requested;
                return true;
            }
        }

        actionFailed("selectPlayer", "Unknown MPRIS player: " + requested);
        return false;
    }

    function invoke(action, capability, callback) {
        if (!hasPlayer || !capability) {
            actionFailed(action, "The active player does not support this action");
            return false;
        }

        try {
            callback();
            return true;
        } catch (error) {
            actionFailed(action, String(error));
            return false;
        }
    }

    function play() {
        return invoke("play", canPlay, function() {
            player.play();
        });
    }

    function pause() {
        return invoke("pause", canPause, function() {
            player.pause();
        });
    }

    function togglePlaying() {
        return invoke("togglePlaying", canToggle, function() {
            player.togglePlaying();
        });
    }

    function previous() {
        return invoke("previous", canPrevious, function() {
            player.previous();
        });
    }

    function next() {
        return invoke("next", canNext, function() {
            player.next();
        });
    }

    function stop() {
        return invoke("stop", hasPlayer && player.canControl, function() {
            player.stop();
        });
    }

    function seek(offsetSeconds) {
        const offset = Number(offsetSeconds);
        if (!Number.isFinite(offset))
            return false;
        return invoke("seek", canSeek, function() {
            player.seek(offset);
        });
    }

    function setPosition(positionSeconds) {
        const nextPosition = Number(positionSeconds);
        if (!Number.isFinite(nextPosition))
            return false;
        return invoke("setPosition", canSeek && player.positionSupported, function() {
            player.position = Math.max(0, nextPosition);
        });
    }

    function setVolume(value) {
        const nextVolume = Number(value);
        if (!Number.isFinite(nextVolume))
            return false;
        return invoke("setVolume", canSetVolume, function() {
            player.volume = Math.max(0, Math.min(1, nextVolume));
        });
    }
}
