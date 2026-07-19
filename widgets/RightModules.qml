import QtQuick

Group {
    id: root

    property var panelWindow
    property bool settingsOpen: false
    property bool hasContent: contentRow.implicitWidth > 0

    signal settingsRequested()

    visible: hasContent || opacity > 0
    opacity: hasContent ? 1 : 0
    scale: hasContent ? 1 : 0.96

    Row {
        id: contentRow

        spacing: settings.itemSpacing

        Repeater {
            model: settings.rightModules

            Loader {
                id: moduleLoader

                active: settings.enabled(String(modelData))
                property bool shown: active && item !== null && item.visible

                visible: shown || opacity > 0
                opacity: shown ? 1 : 0
                scale: shown ? 1 : 0.96
                sourceComponent: root.componentFor(String(modelData))

                Behavior on opacity {
                    NumberAnimation { duration: settings.motionNormal; easing.type: moduleLoader.shown ? Easing.OutCubic : Easing.InCubic }
                }

                Behavior on scale {
                    NumberAnimation { duration: settings.motionNormal; easing.type: moduleLoader.shown ? Easing.OutCubic : Easing.InCubic }
                }
            }
        }

        Pill {
            id: settingsPill

            property bool shown: root.settings.enabled("settings")

            theme: root.theme
            settings: root.settings
            icon: ""
            active: root.settingsOpen
            clickable: true
            minimumWidth: Math.max(settings.moduleHeight, settings.effectiveIconSize + settings.effectivePillPadding * 2)
            visible: shown || opacity > 0
            opacity: shown ? 1 : 0
            onClicked: root.settingsRequested()

            transform: Scale {
                origin.x: settingsPill.width / 2
                origin.y: settingsPill.height / 2
                xScale: settingsPill.shown ? 1 : 0.96
                yScale: settingsPill.shown ? 1 : 0.96

                Behavior on xScale {
                    NumberAnimation { duration: settings.motionNormal; easing.type: settingsPill.shown ? Easing.OutCubic : Easing.InCubic }
                }

                Behavior on yScale {
                    NumberAnimation { duration: settings.motionNormal; easing.type: settingsPill.shown ? Easing.OutCubic : Easing.InCubic }
                }
            }
        }
    }

    function componentFor(name) {
        if (name === "tray") return trayComponent;
        if (name === "cpu") return cpuComponent;
        if (name === "memory" || name === "ram") return memoryComponent;
        if (name === "audio" || name === "volume") return audioComponent;
        if (name === "network" || name === "net") return networkComponent;
        if (name === "battery" || name === "bat") return batteryComponent;
        if (name === "clock" || name === "time") return clockComponent;
        return null;
    }

    Component { id: trayComponent; Tray { theme: root.theme; settings: root.settings; panelWindow: root.panelWindow } }
    Component { id: cpuComponent; Cpu { theme: root.theme; settings: root.settings } }
    Component { id: memoryComponent; Memory { theme: root.theme; settings: root.settings } }
    Component { id: audioComponent; Audio { theme: root.theme; settings: root.settings } }
    Component { id: networkComponent; Network { theme: root.theme; settings: root.settings } }
    Component { id: batteryComponent; Battery { theme: root.theme; settings: root.settings } }
    Component { id: clockComponent; Clock { theme: root.theme; settings: root.settings } }
}
