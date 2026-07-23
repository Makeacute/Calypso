import QtQuick

Item {
    id: root

    property var theme
    property var settings
    property string moduleInstanceId: ""
    property var moduleSettings: ({})
    property var compositor
    readonly property string displayMode: moduleSettings.displayMode === undefined ? settings.focusedWindowDisplayMode : String(moduleSettings.displayMode)
    readonly property int maximumTitleWidth: moduleSettings.maxWidth === undefined ? settings.focusedWindowMaxWidth : Number(moduleSettings.maxWidth)
    readonly property bool showFocusedTitle: moduleSettings.showTitle === undefined ? settings.focusedWindowShowTitle : Boolean(moduleSettings.showTitle)
    property var workspaces: compositor ? compositor.workspaces : []
    property var windows: compositor ? compositor.windows : []
    property var focusedWindow: compositor ? compositor.focusedWindow : ({})
    property var workspaceWindows: currentWorkspaceWindows()

    width: implicitWidth
    height: implicitHeight
    implicitWidth: workspaceWindows.length > 0 ? Math.max(settings.moduleHeight, appRow.implicitWidth) : 0
    implicitHeight: settings.moduleHeight

    AppIconResolver {
        id: appIconResolver
    }

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

        if (displayMode === "focusedTitle" && focusedWindow && focusedWindow.id !== undefined) {
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

    function appName(id) {
        return appIconResolver.displayName(id);
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
        visible: root.workspaceWindows.length > 0
        opacity: 1

        Repeater {
            model: root.workspaceWindows.length

            Rectangle {
                id: appPill

                required property int index

                property var windowData: root.workspaceWindows[index]
                property bool focused: windowData && Number(windowData.id) === Number(root.focusedWindow.id)
                property bool showTitle: root.displayMode === "focusedTitle" || (focused && root.showFocusedTitle && root.displayMode !== "iconsOnly")

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
                scale: appHover.containsMouse ? 1.012 : 1

                Behavior on y {
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

                    AppIconImage {
                        width: settings.effectiveIconSize
                        height: settings.effectiveIconSize
                        y: Math.round((appContent.height - height) / 2)
                        theme: root.theme
                        settings: root.settings
                        iconSource: appIconResolver.source(appPill.windowData ? appPill.windowData.appId : "")
                        fallbackText: appIconResolver.initial(appPill.windowData ? appPill.windowData.appId : "")
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
                        width: Math.min(implicitWidth, root.maximumTitleWidth)
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

}
