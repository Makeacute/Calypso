pragma ComponentBehavior: Bound

import QtQuick

Surface {
    id: root

    property var compositor
    property var panelWindow
    property var osd
    property var tooltipHost
    property var modules: []
    property bool active: true
    property bool backgroundReady: true
    property bool interactionReady: true
    property bool settingsOpen: false
    property string contentAlignment: "center"
    readonly property var moduleList: Array.from(modules || [])
    readonly property bool hasContent: contentRow.implicitWidth > 0

    signal settingsRequested(var anchorItem)
    signal clockRequested(var anchorItem)
    signal controlsRequested(var anchorItem)
    signal moduleDetailsRequested(string moduleName, var anchorItem)

    visible: moduleList.length > 0 && hasContent
    width: hasContent ? implicitWidth : 0
    height: implicitHeight
    implicitWidth: hasContent ? contentRow.implicitWidth + settings.effectiveGroupPadding * 2 : 0
    implicitHeight: settings.barHeight
    clip: true
    surfaceColor: theme.alpha(theme.surface, settings.barOpacity)
    outlineColor: settings.barBorderEnabled ? theme.border : theme.transparent
    outlineWidth: settings.barBorderEnabled ? settings.barBorderThickness : 0
    surfaceRadius: Math.min(Math.round(settings.effectiveRadiusL), Math.floor(settings.barHeight / 2))

    Behavior on opacity {
        NumberAnimation { duration: settings.motionNormal; easing.type: opacity > 0 ? Easing.OutCubic : Easing.InCubic }
    }

    Behavior on width {
        enabled: settings.motionNormal > 0
        SpringAnimation { spring: 4.0; damping: 0.82; epsilon: 0.2 }
    }

    Row {
        id: contentRow

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.contentAlignment === "left" ? parent.left : undefined
        anchors.leftMargin: settings.effectiveGroupPadding
        anchors.right: root.contentAlignment === "right" ? parent.right : undefined
        anchors.rightMargin: settings.effectiveGroupPadding
        anchors.horizontalCenter: root.contentAlignment === "center" ? parent.horizontalCenter : undefined
        spacing: settings.effectiveContentSpacing

        Repeater {
            model: root.moduleList.length

            ModuleHost {
                required property int index

                theme: root.theme
                settings: root.settings
                compositor: root.compositor
                panelWindow: root.panelWindow
                osd: root.osd
                tooltipHost: root.tooltipHost
                moduleName: String(root.moduleList[index])
                active: root.active
                backgroundReady: root.backgroundReady
                interactionReady: root.interactionReady
                settingsOpen: root.settingsOpen
                onSettingsRequested: function(anchorItem) { root.settingsRequested(anchorItem); }
                onClockRequested: function(anchorItem) { root.clockRequested(anchorItem); }
                onControlsRequested: function(anchorItem) { root.controlsRequested(anchorItem); }
                onModuleDetailsRequested: function(moduleName, anchorItem) { root.moduleDetailsRequested(moduleName, anchorItem); }
            }
        }
    }
}
