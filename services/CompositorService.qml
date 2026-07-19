pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Item {
    id: root

    property var settings
    readonly property string backend: settings ? settings.compositorBackend : "auto"
    readonly property string id: "niri"
    readonly property bool available: true
    readonly property var workspaces: normalizeWorkspaces(niri.workspaces)
    readonly property var windows: normalizeWindows(niri.windows)
    readonly property var focusedWindow: normalizeWindow(niri.focusedWindow)
    readonly property int openedWindowWorkspaceId: niri.openedWindowWorkspaceId
    readonly property int openedWindowSerial: niri.openedWindowSerial

    function sync() {
        niri.sync();
    }

    function focusWorkspace(workspace) {
        if (!workspace || focusWorkspaceProc.running) return;

        const index = Number(workspace.index);
        if (!Number.isFinite(index)) return;

        focusWorkspaceProc.command = [
            "sh",
            "-c",
            "niri msg action focus-workspace " + index + "; status=$?; niri msg action close-overview >/dev/null 2>&1 || true; exit $status"
        ];
        focusWorkspaceProc.running = true;
    }

    function focusWindow(windowData) {
        if (!windowData || focusWindowProc.running) return;

        const windowId = Number(windowData.id);
        if (!Number.isFinite(windowId)) return;

        focusWindowProc.command = [
            "sh",
            "-c",
            "niri msg action focus-window --id " + windowId + "; status=$?; niri msg action close-overview >/dev/null 2>&1 || true; exit $status"
        ];
        focusWindowProc.running = true;
    }

    function normalizeWorkspaces(list) {
        const source = Array.from(list || []);
        const next = [];

        for (let i = 0; i < source.length; i++) {
            const workspace = source[i] || {};
            const index = Number(workspace.idx || workspace.id || i + 1);
            const name = String(workspace.name || "");
            next.push({
                "id": Number(workspace.id),
                "index": Number.isFinite(index) ? index : i + 1,
                "name": name,
                "label": name.length > 0 ? name : String(Number.isFinite(index) ? index : i + 1),
                "monitor": String(workspace.output || ""),
                "focused": workspace.is_focused === true,
                "active": workspace.is_active === true,
                "urgent": workspace.is_urgent === true,
                "raw": workspace
            });
        }

        return next;
    }

    function orderKey(windowData) {
        const layout = windowData ? windowData.layout : null;
        const pos = layout && layout.pos_in_scrolling_layout ? layout.pos_in_scrolling_layout : [0, 0];
        const x = Number(pos[0]) || 0;
        const y = Number(pos[1]) || 0;
        return x * 100000 + y;
    }

    function normalizeWindow(windowData) {
        if (!windowData) return {};

        const id = Number(windowData.id);
        if (!Number.isFinite(id)) return {};

        return {
            "id": id,
            "workspaceId": Number(windowData.workspace_id),
            "appId": String(windowData.app_id || ""),
            "title": String(windowData.title || ""),
            "focused": windowData.is_focused === true,
            "orderKey": orderKey(windowData),
            "raw": windowData
        };
    }

    function normalizeWindows(list) {
        const source = Array.from(list || []);
        const next = [];

        for (let i = 0; i < source.length; i++) {
            const normalized = normalizeWindow(source[i]);
            if (normalized.id !== undefined) next.push(normalized);
        }

        return next;
    }

    NiriService {
        id: niri

        settings: root.settings
    }

    Process {
        id: focusWorkspaceProc

        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.warn("Failed to focus workspace:", text.trim())
        }
        onExited: root.sync()
    }

    Process {
        id: focusWindowProc

        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.warn("Failed to focus window:", text.trim())
        }
        onExited: root.sync()
    }
}
