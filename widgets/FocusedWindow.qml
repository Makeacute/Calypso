import QtQuick

Item {
    id: root

    property var theme
    property var settings
    property var compositor
    property var workspaces: compositor ? compositor.workspaces : []
    property var windows: compositor ? compositor.windows : []
    property var focusedWindow: compositor ? compositor.focusedWindow : ({})
    property var workspaceWindows: currentWorkspaceWindows()

    width: implicitWidth
    height: implicitHeight
    implicitWidth: workspaceWindows.length > 0 ? appRow.implicitWidth : emptyPill.implicitWidth
    implicitHeight: settings.moduleHeight

    function focusedWorkspace() {
        for (let i = 0; i < workspaces.length; i++) {
            if (workspaces[i].focused) return workspaces[i];
        }

        for (let i = 0; i < workspaces.length; i++) {
            if (workspaces[i].active) return workspaces[i];
        }

        return workspaces.length > 0 ? workspaces[0] : null;
    }

    function currentWorkspaceWindows() {
        const workspace = focusedWorkspace();
        if (!workspace) return [];

        const workspaceId = Number(workspace.id);
        const workspaceList = Array.from(windows || [])
                                   .filter(window => Number(window.workspaceId) === workspaceId)
                                   .sort(compareWindows);

        if (settings.focusedWindowDisplayMode === "focusedTitle" && focusedWindow && focusedWindow.id !== undefined) {
            return [focusedWindow];
        }

        return workspaceList;
    }

    function compareWindows(left, right) {
        const leftKey = Number(left.orderKey) || 0;
        const rightKey = Number(right.orderKey) || 0;
        if (leftKey !== rightKey) return leftKey - rightKey;
        return Number(left.id) - Number(right.id);
    }

    function appIcon(id) {
        const key = String(id || "").toLowerCase();
        if (key.includes("firefox") || key.includes("librewolf") || key.includes("zen")) return "󰈹";
        if (key.includes("chrom") || key.includes("brave") || key.includes("vivaldi")) return "";
        if (key.includes("code") || key.includes("codium")) return "󰨞";
        if (key.includes("foot") || key.includes("kitty") || key.includes("alacritty") || key.includes("wezterm") || key.includes("terminal")) return "";
        if (key.includes("thunar") || key.includes("nautilus") || key.includes("dolphin") || key.includes("files")) return "";
        if (key.includes("obsidian")) return "󰠮";
        if (key.includes("spotify")) return "";
        if (key.includes("discord")) return "";
        if (key.includes("telegram")) return "";
        if (key.includes("steam")) return "";
        if (key.includes("mpv") || key.includes("vlc")) return "󰎁";
        if (key.includes("gimp") || key.includes("krita")) return "";
        return key.length > 0 ? "󰣆" : "󰇄";
    }

    function appName(id) {
        const text = String(id || "").replace(/\.desktop$/i, "").replace(/-/g, " ");
        if (text.length === 0) return "Desktop";
        return text.charAt(0).toUpperCase() + text.slice(1);
    }

    function cleanTitle(value) {
        return String(value || "").replace(/\s+/g, " ").trim();
    }

    function displayText(windowData) {
        const cleaned = cleanTitle(windowData ? windowData.title : "");
        if (cleaned.length > 0) return cleaned;
        return appName(windowData ? windowData.appId : "");
    }

    function focusWindow(windowData) {
        if (compositor) compositor.focusWindow(windowData);
    }

    Row {
        id: appRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: settings.effectiveContentSpacing
        visible: root.workspaceWindows.length > 0 || opacity > 0
        opacity: root.workspaceWindows.length > 0 ? 1 : 0
        scale: root.workspaceWindows.length > 0 ? 1 : 0.96

        Behavior on opacity {
            NumberAnimation { duration: settings.motionNormal; easing.type: root.workspaceWindows.length > 0 ? Easing.OutCubic : Easing.InCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: settings.motionNormal; easing.type: root.workspaceWindows.length > 0 ? Easing.OutCubic : Easing.InCubic }
        }

        Repeater {
            model: root.workspaceWindows.length

            Rectangle {
                id: appPill

                required property int index

                property var windowData: root.workspaceWindows[index]
                property bool focused: windowData && Number(windowData.id) === Number(root.focusedWindow.id)
                property bool showTitle: settings.focusedWindowDisplayMode === "focusedTitle" || (focused && settings.focusedWindowShowTitle && settings.focusedWindowDisplayMode !== "iconsOnly")
                property bool entered: false

                width: Math.max(settings.moduleHeight,
                                appContent.implicitWidth + settings.effectivePillPadding * 2)
                height: settings.moduleHeight
                y: 0
                radius: settings.effectivePillRadius
                color: focused ? theme.surfaceActive
                               : appHover.containsMouse ? theme.surfaceHover
                                                        : theme.alpha(theme.textMuted, 0.08)
                border.color: focused ? theme.outlineActive : theme.transparent
                border.width: settings.effectiveBorderWidth
                antialiasing: true
                opacity: entered ? 1 : 0
                scale: entered ? (appHover.containsMouse ? 1.012 : 1) : 0.92

                Component.onCompleted: entered = true

                Behavior on y {
                    NumberAnimation { duration: settings.motionFast; easing.type: Easing.OutCubic }
                }

                Behavior on opacity {
                    NumberAnimation { duration: settings.motionFast; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: settings.motionNormal }
                }

                Behavior on border.color {
                    ColorAnimation { duration: settings.motionNormal }
                }

                Behavior on scale {
                    NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic }
                }

                Row {
                    id: appContent

                    anchors.centerIn: parent
                    height: parent.height
                    spacing: appTitle.visible ? settings.effectiveContentSpacing : 0

                    Text {
                        height: appContent.height
                        text: root.appIcon(appPill.windowData ? appPill.windowData.appId : "")
                        color: appPill.focused ? theme.accent : theme.text
                        font.family: settings.fontFamily
                        font.pixelSize: settings.effectiveIconSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        transform: Translate { x: -Math.max(1, Math.round(settings.effectiveIconSize * 0.10)) }

                        Behavior on color {
                            ColorAnimation { duration: settings.motionNormal }
                        }
                    }

                    Text {
                        id: appTitle

                        visible: appPill.showTitle || opacity > 0
                        height: appContent.height
                        text: root.displayText(appPill.windowData)
                        color: theme.text
                        opacity: appPill.showTitle ? 1 : 0
                        scale: appPill.showTitle ? 1 : 0.96
                        font.family: settings.fontFamily
                        font.pixelSize: settings.effectiveFontSize
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        width: Math.min(implicitWidth, settings.focusedWindowMaxWidth)
                        verticalAlignment: Text.AlignVCenter

                        Behavior on color {
                            ColorAnimation { duration: settings.motionNormal }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: settings.motionNormal; easing.type: appPill.showTitle ? Easing.OutCubic : Easing.InCubic }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: settings.motionNormal; easing.type: appPill.showTitle ? Easing.OutCubic : Easing.InCubic }
                        }
                    }
                }

                MouseArea {
                    id: appHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWindow(appPill.windowData)
                }
            }
        }
    }

    Rectangle {
        id: emptyPill

        property bool shown: root.workspaceWindows.length === 0

        anchors.verticalCenter: parent.verticalCenter
        visible: shown || opacity > 0
        width: settings.moduleHeight
        height: settings.moduleHeight
        radius: settings.effectivePillRadius
        color: theme.surfaceMuted
        border.color: theme.transparent
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.92

        Behavior on color {
            ColorAnimation { duration: settings.motionNormal }
        }

        Behavior on border.color {
            ColorAnimation { duration: settings.motionNormal }
        }

        Behavior on opacity {
            NumberAnimation { duration: settings.motionNormal; easing.type: emptyPill.shown ? Easing.OutCubic : Easing.InCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: settings.motionNormal; easing.type: emptyPill.shown ? Easing.OutCubic : Easing.InCubic }
        }

        Text {
            anchors.centerIn: parent
            height: parent.height
            text: "󰇄"
            color: theme.textMuted
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            Behavior on color {
                ColorAnimation { duration: settings.motionNormal }
            }
        }
    }

}
