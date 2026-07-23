pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    property bool migrationComplete: false
    property string migrationError: ""

    function localPath(url) {
        const value = String(url);
        return value.startsWith("file://") ? decodeURIComponent(value.slice(7)) : value;
    }

    Process {
        id: migrationProcess

        command: [
            root.localPath(Qt.resolvedUrl("tools/calypso-migrate-settings")),
            root.localPath(Qt.resolvedUrl("settings.json"))
        ]
        running: true
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: root.migrationError = text.trim()
        }
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.migrationComplete = true;
                return;
            }
            console.error("Calypso settings migration failed: " + (root.migrationError || "exit " + exitCode));
        }
    }

    LazyLoader {
        active: root.migrationComplete
        component: AppRuntime {}
    }
}
