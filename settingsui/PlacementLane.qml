import QtQuick
import "controls" as Controls

Rectangle {
    id: root

    property var theme
    property var settings
    property var controller
    property string sectionName: "left"
    property string title: "Left"
    property string icon: ""
    readonly property var modules: settings ? settings.sectionModules(sectionName) : []

    function adjacentSection(direction) {
        const sections = ["left", "center", "right"];
        const index = sections.indexOf(sectionName) + direction;
        return index >= 0 && index < sections.length ? sections[index] : "";
    }

    function moveAcross(instanceId, direction) {
        const target = adjacentSection(direction);
        if (target.length <= 0)
            return;
        settings.moveModuleInstance(instanceId, target, settings.sectionModules(target).length);
    }

    function openInstance(instanceId) {
        controller.openModuleFor(controller.targetScreen, settings.moduleType(instanceId));
        controller.selectedModule = instanceId;
        controller.configurePage();
    }

    implicitHeight: laneContent.implicitHeight + theme.spacingL * theme.settingsLanePaddingFactor
    radius: theme.radiusM
    color: theme.surfaceMuted
    border.color: theme.outlineSubtle
    border.width: theme.settingsBorderWidth

    Column {
        id: laneContent

        anchors.fill: parent
        anchors.margins: theme.spacingL
        spacing: theme.spacingS

        Row {
            width: parent.width
            spacing: theme.spacingS

            Text {
                text: root.icon
                color: theme.accent
                font.family: settings.fontFamilyIcon
                font.pixelSize: theme.settingsIconSize
            }

            Text {
                width: parent.width - parent.spacing - theme.settingsIconSize
                text: root.title
                color: theme.text
                font.family: settings.fontFamilySans
                font.pixelSize: theme.settingsSectionFontSize
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            width: parent.width
            height: theme.settingsBorderWidth
            color: theme.outlineSubtle
        }

        Text {
            width: parent.width
            visible: root.modules.length === 0
            text: "No modules placed"
            color: theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            font.family: settings.fontFamilySans
            font.pixelSize: theme.settingsCaptionFontSize
        }

        Repeater {
            model: root.modules

            Item {
                id: moduleRow

                required property string modelData
                required property int index
                readonly property int typeCount: root.settings.moduleInstanceIds(modelData).length

                width: laneContent.width
                height: moduleContent.implicitHeight + theme.spacingS

                Column {
                    id: moduleContent

                    width: parent.width
                    spacing: theme.spacingXS

                    Row {
                        width: parent.width
                        spacing: theme.spacingS

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.settings.moduleIcon(moduleRow.modelData)
                            color: root.settings.instanceEnabled(moduleRow.modelData) ? theme.accent : theme.textMuted
                            font.family: settings.fontFamilyIcon
                            font.pixelSize: theme.settingsIconSize
                        }

                        Column {
                            width: parent.width - theme.settingsIconSize - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: theme.spacingXS

                            Text {
                                width: parent.width
                                text: root.settings.instanceDisplayLabel(moduleRow.modelData)
                                color: theme.text
                                elide: Text.ElideRight
                                font.family: settings.fontFamilySans
                                font.pixelSize: theme.settingsCaptionFontSize
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                visible: moduleRow.typeCount > 1
                                text: moduleRow.modelData
                                color: theme.textMuted
                                elide: Text.ElideMiddle
                                font.family: settings.fontFamilyMono
                                font.pixelSize: theme.settingsCaptionFontSize
                            }
                        }
                    }

                    Flow {
                        width: parent.width
                        spacing: theme.spacingXS

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            tooltip: "Move earlier"
                            enabled: moduleRow.index > 0
                            onPressed: root.controller.performChange("Move " + root.settings.instanceDisplayLabel(moduleRow.modelData), function () {
                                root.settings.moveModule(root.sectionName, moduleRow.index, -1);
                            })
                        }

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            tooltip: "Move later"
                            enabled: moduleRow.index < root.modules.length - 1
                            onPressed: root.controller.performChange("Move " + root.settings.instanceDisplayLabel(moduleRow.modelData), function () {
                                root.settings.moveModule(root.sectionName, moduleRow.index, 1);
                            })
                        }

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            tooltip: "Move to previous lane"
                            enabled: root.adjacentSection(-1).length > 0
                            onPressed: root.controller.performChange("Move " + root.settings.instanceDisplayLabel(moduleRow.modelData) + " across", function () {
                                root.moveAcross(moduleRow.modelData, -1);
                            })
                        }

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            tooltip: "Move to next lane"
                            enabled: root.adjacentSection(1).length > 0
                            onPressed: root.controller.performChange("Move " + root.settings.instanceDisplayLabel(moduleRow.modelData) + " across", function () {
                                root.moveAcross(moduleRow.modelData, 1);
                            })
                        }

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            tooltip: "Duplicate instance"
                            enabled: root.settings.moduleReusable(moduleRow.modelData)
                            onPressed: root.controller.performChange("Duplicate " + root.settings.instanceDisplayLabel(moduleRow.modelData), function () {
                                root.settings.duplicateModuleInstance(moduleRow.modelData, root.sectionName, moduleRow.index + 1);
                            })
                        }

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: root.settings.instanceEnabled(moduleRow.modelData) ? "" : ""
                            tooltip: root.settings.instanceEnabled(moduleRow.modelData) ? "Disable instance" : "Enable instance"
                            checked: root.settings.instanceEnabled(moduleRow.modelData)
                            onPressed: root.controller.performChange("Toggle " + root.settings.instanceDisplayLabel(moduleRow.modelData), function () {
                                root.settings.setInstanceEnabled(moduleRow.modelData, !root.settings.instanceEnabled(moduleRow.modelData));
                            })
                        }

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            tooltip: "Configure instance"
                            enabled: root.settings.moduleEntry(moduleRow.modelData).configurable !== false
                            onPressed: root.openInstance(moduleRow.modelData)
                        }

                        Controls.IconButton {
                            theme: root.theme
                            settings: root.settings
                            icon: ""
                            tooltip: "Delete instance"
                            onPressed: root.controller.performChange("Delete " + root.settings.instanceDisplayLabel(moduleRow.modelData), function () {
                                root.settings.deleteModuleInstance(moduleRow.modelData);
                            })
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: theme.settingsBorderWidth
                    color: theme.outlineSubtle
                }
            }
        }
    }
}
