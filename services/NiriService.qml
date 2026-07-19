import QtQuick
import Quickshell.Io

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var workspaces: []
    property var windows: []
    property var focusedWindow: ({})
    property var settings
    property var seenWindowIds: ({})
    property int openedWindowWorkspaceId: -1
    property int openedWindowSerial: 0

    function restart() {
        if (eventStream.running) {
            eventStream.running = false;
        }
        restartTimer.restart();
    }

    function sync() {
        if (!workspacesProc.running) workspacesProc.running = true;
        if (!windowsProc.running) windowsProc.running = true;
    }

    function parseWorkspaces(text) {
        try {
            const parsed = JSON.parse(String(text || "[]"));
            workspaces = Array.isArray(parsed) ? parsed : [];
        } catch (error) {
            console.warn("Failed to parse niri workspaces:", error);
        }
    }

    function parseWindows(text) {
        try {
            const parsed = JSON.parse(String(text || "[]"));
            windows = Array.isArray(parsed) ? parsed : [];
            rememberSeenWindows(windows);
            updateFocusedWindow();
        } catch (error) {
            console.warn("Failed to parse niri windows:", error);
        }
    }

    function rememberSeenWindows(windowList) {
        const next = Object.assign({}, seenWindowIds || {});

        for (let i = 0; i < windowList.length; i++) {
            next[String(windowList[i].id)] = true;
        }

        seenWindowIds = next;
    }

    function trackWindowTitles() {
        return settings && settings.focusedWindowShowTitle;
    }

    function sameLayout(left, right) {
        return JSON.stringify(left || {}) === JSON.stringify(right || {});
    }

    function isTitleOnlyChange(current, incoming) {
        if (!current || !incoming) return false;

        return Number(current.id) === Number(incoming.id)
            && Number(current.workspace_id) === Number(incoming.workspace_id)
            && String(current.app_id || "") === String(incoming.app_id || "")
            && current.is_focused === incoming.is_focused
            && current.is_floating === incoming.is_floating
            && current.is_urgent === incoming.is_urgent
            && sameLayout(current.layout, incoming.layout)
            && String(current.title || "") !== String(incoming.title || "");
    }

    function applyWorkspaceActivated(id, focused) {
        const workspaceId = Number(id);
        const isFocused = focused !== false;
        let targetOutput = "";

        for (let i = 0; i < workspaces.length; i++) {
            if (Number(workspaces[i].id) === workspaceId) {
                targetOutput = String(workspaces[i].output || "");
                break;
            }
        }

        if (targetOutput.length === 0) {
            sync();
            return;
        }

        const next = [];
        for (let i = 0; i < workspaces.length; i++) {
            const workspace = Object.assign({}, workspaces[i]);
            const sameOutput = String(workspace.output || "") === targetOutput;
            const sameWorkspace = Number(workspace.id) === workspaceId;

            if (sameOutput) {
                workspace.is_focused = isFocused && sameWorkspace;
                workspace.is_active = sameWorkspace;
            }

            next.push(workspace);
        }

        workspaces = next;
    }

    function applyWindowOpenedOrChanged(windowData) {
        if (!windowData) return;

        const id = Number(windowData.id);
        const key = String(id);
        const isNewWindow = !(seenWindowIds || {})[key];
        const next = [];
        let replaced = false;

        for (let i = 0; i < windows.length; i++) {
            if (Number(windows[i].id) === id) {
                if (!trackWindowTitles() && isTitleOnlyChange(windows[i], windowData))
                    return;
                next.push(windowData);
                replaced = true;
            } else {
                next.push(windows[i]);
            }
        }

        if (!replaced) next.push(windowData);

        windows = next;
        if (isNewWindow) {
            const seen = Object.assign({}, seenWindowIds || {});
            seen[key] = true;
            seenWindowIds = seen;
            openedWindowWorkspaceId = Number(windowData.workspace_id);
            openedWindowSerial += 1;
        }
        updateFocusedWindow();
    }

    function applyWindowClosed(id) {
        const closedId = Number(id);
        const seen = Object.assign({}, seenWindowIds || {});
        delete seen[String(closedId)];
        seenWindowIds = seen;
        windows = windows.filter(window => Number(window.id) !== closedId);
        updateFocusedWindow();
    }

    function updateFocusedWindow() {
        for (let i = 0; i < windows.length; i++) {
            if (windows[i].is_focused) {
                focusedWindow = windows[i];
                return;
            }
        }
        focusedWindow = {};
    }

    function applyFocusedWindowId(id) {
        const focusedId = Number(id);
        const next = [];
        let nextFocused = {};
        let changed = false;

        for (let i = 0; i < windows.length; i++) {
            const shouldFocus = Number(windows[i].id) === focusedId;
            const wasFocused = windows[i].is_focused === true;

            if (shouldFocus !== wasFocused) {
                const windowData = Object.assign({}, windows[i]);
                windowData.is_focused = shouldFocus;
                next.push(windowData);
                changed = true;
                if (shouldFocus) nextFocused = windowData;
            } else {
                next.push(windows[i]);
                if (shouldFocus) nextFocused = windows[i];
            }
        }

        if (changed) windows = next;
        focusedWindow = nextFocused;
    }

    function handleLine(line) {
        const trimmed = String(line || "").trim();
        if (trimmed.length === 0) return;

        try {
            const event = JSON.parse(trimmed);

            if (event.WorkspacesChanged) {
                workspaces = event.WorkspacesChanged.workspaces || [];
            }

            if (event.WorkspaceActivated) {
                const data = event.WorkspaceActivated;
                applyWorkspaceActivated(data.id, data.focused);
            }

            if (event.WindowsChanged) {
                windows = event.WindowsChanged.windows || [];
                rememberSeenWindows(windows);
                updateFocusedWindow();
            }

            if (event.WindowOpenedOrChanged) {
                applyWindowOpenedOrChanged(event.WindowOpenedOrChanged.window);
            }

            if (event.WindowClosed) {
                const data = event.WindowClosed;
                applyWindowClosed(data.id ?? data.window_id ?? data.window);
            }

            if (event.WindowFocusChanged) {
                const data = event.WindowFocusChanged;
                const id = data.id ?? data.window_id ?? data.window ?? null;
                if (id === null) {
                    focusedWindow = {};
                } else {
                    applyFocusedWindowId(id);
                }
            }
        } catch (error) {
            console.warn("Failed to parse niri event:", error);
        }
    }

    Process {
        id: eventStream

        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(data) {
                root.handleLine(data);
            }
        }
        stderr: SplitParser {}
        onExited: restartTimer.restart()
    }

    Process {
        id: workspacesProc

        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: root.parseWorkspaces(text)
        }
        stderr: StdioCollector {}
    }

    Process {
        id: windowsProc

        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector {
            onStreamFinished: root.parseWindows(text)
        }
        stderr: StdioCollector {}
    }

    Timer {
        id: restartTimer

        interval: 1500
        repeat: false
        onTriggered: {
            root.sync();
            eventStream.running = true;
        }
    }
    Component.onCompleted: root.sync()
}
