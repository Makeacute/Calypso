import QtQuick
import Quickshell

QtObject {
    function localPath(url) {
        const value = String(url);
        return value.startsWith("file://") ? decodeURIComponent(value.slice(7)) : value;
    }

    readonly property string name: "Calypso"
    readonly property string releaseChannel: "Development"
    readonly property int schemaVersion: 4
    readonly property string description: "A low-cost Quickshell bar for Niri"
    readonly property string repository: "https://github.com/Makeacute/Calypso"
    readonly property string settingsPath: localPath(Qt.resolvedUrl("settings.json"))
    readonly property string configDirectory: settingsPath.slice(0, settingsPath.lastIndexOf("/"))
}
