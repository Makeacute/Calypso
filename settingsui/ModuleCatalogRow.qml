import QtQuick
import "controls" as Controls

Item {
    id: root

    property var theme
    property var settings
    property var controller
    property var entry: ({})
    readonly property string moduleName: String(entry.id || "")
    readonly property string primaryInstanceId: settings ? settings.primaryInstanceId(moduleName) : ""
    readonly property string unplacedInstanceId: settings ? settings.unplacedModuleInstance(moduleName) : ""
    readonly property bool reusable: settings ? settings.moduleReusable(moduleName) : false
    readonly property bool primaryEnabled: primaryInstanceId.length > 0 && settings.instanceEnabled(primaryInstanceId)

    function addTo(section) {
        return settings.addCatalogModule(section, moduleName);
    }

    function ensurePrimary() {
        return settings.ensurePrimaryInstance(moduleName);
    }

    function openPrimary() {
        const instanceId = ensurePrimary();
        if (instanceId.length <= 0)
            return;
        controller.openModuleFor(controller.targetScreen, moduleName);
        controller.selectedModule = instanceId;
        controller.configurePage();
    }

    implicitHeight: theme.settingsCatalogRowHeight

    Row {
        anchors.fill: parent
        spacing: theme.spacingM

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: theme.settingsCatalogIconSize
            height: width
            radius: theme.radiusM
            color: theme.surfaceActive

            Text {
                anchors.centerIn: parent
                text: String(root.entry.icon || "󰀻")
                color: theme.accent
                font.family: settings.fontFamilyIcon
                font.pixelSize: theme.settingsIconSize
            }
        }

        Column {
            width: Math.max(theme.settingsCatalogLabelMinWidth, parent.width - theme.settingsCatalogIconSize - catalogActions.width - parent.spacing * theme.settingsCatalogSpacingCount)
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme.spacingXS

            Row {
                width: parent.width
                spacing: theme.spacingS

                Text {
                    text: String(root.entry.label || root.moduleName)
                    color: theme.text
                    font.family: settings.fontFamilySans
                    font.pixelSize: theme.settingsBodyFontSize
                    font.weight: Font.DemiBold
                }

                Controls.StatusBadge {
                    theme: root.theme
                    settings: root.settings
                    text: String(root.entry.cost || "unknown")
                    tone: String(root.entry.cost || "").indexOf("polling") >= 0 ? "warning" : root.primaryEnabled ? "good" : "neutral"
                }
            }

            Text {
                width: parent.width
                text: String(root.entry.category || "Other") + (Array.from(root.entry.capabilities || []).length > 0 ? " / " + Array.from(root.entry.capabilities || []).join(", ") : "")
                color: theme.textMuted
                elide: Text.ElideRight
                font.family: settings.fontFamilySans
                font.pixelSize: theme.settingsCaptionFontSize
            }
        }

        Row {
            id: catalogActions

            anchors.verticalCenter: parent.verticalCenter
            spacing: theme.spacingXS

            Controls.IconButton {
                theme: root.theme
                settings: root.settings
                icon: ""
                tooltip: root.reusable && root.unplacedInstanceId.length <= 0 ? "Add another to left lane" : "Add to left lane"
                enabled: settings.canAddCatalogModule("left", root.moduleName)
                onPressed: controller.performChange("Add " + root.entry.label + " to left", function () {
                    root.addTo("left");
                })
            }

            Controls.IconButton {
                theme: root.theme
                settings: root.settings
                icon: ""
                tooltip: root.reusable && root.unplacedInstanceId.length <= 0 ? "Add another to center lane" : "Add to center lane"
                enabled: settings.canAddCatalogModule("center", root.moduleName)
                onPressed: controller.performChange("Add " + root.entry.label + " to center", function () {
                    root.addTo("center");
                })
            }

            Controls.IconButton {
                theme: root.theme
                settings: root.settings
                icon: ""
                tooltip: root.reusable && root.unplacedInstanceId.length <= 0 ? "Add another to right lane" : "Add to right lane"
                enabled: settings.canAddCatalogModule("right", root.moduleName)
                onPressed: controller.performChange("Add " + root.entry.label + " to right", function () {
                    root.addTo("right");
                })
            }

            Controls.IconButton {
                theme: root.theme
                settings: root.settings
                icon: root.primaryEnabled ? "" : ""
                tooltip: root.primaryEnabled ? "Disable primary instance" : "Enable primary instance"
                checked: root.primaryEnabled
                onPressed: controller.performChange("Toggle " + root.entry.label, function () {
                    const instanceId = root.ensurePrimary();
                    settings.setInstanceEnabled(instanceId, !settings.instanceEnabled(instanceId));
                })
            }

            Controls.IconButton {
                theme: root.theme
                settings: root.settings
                icon: ""
                tooltip: "Configure module"
                enabled: root.entry.configurable !== false
                onPressed: root.openPrimary()
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
