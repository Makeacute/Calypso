import QtQuick
import "controls" as Controls

Column {
    id: root

    property var theme
    property var settings
    property var controller
    property string moduleName: ""
    property string instanceId: ""
    readonly property string moduleType: settings && moduleName.length > 0 ? settings.moduleType(instanceId.length > 0 ? instanceId : moduleName) : ""
    readonly property var entry: settings && moduleType.length > 0 ? settings.moduleEntry(moduleType) : ({})
    readonly property bool valid: instanceId.length > 0

    function resolveTarget() {
        if (!settings || moduleName.length <= 0) {
            instanceId = "";
            return;
        }

        const existing = settings.resolveModuleInstance(moduleName, false);
        if (existing.length > 0) {
            instanceId = existing;
            return;
        }

        const create = function () {
            root.instanceId = settings.ensurePrimaryInstance(root.moduleName);
        };
        if (controller)
            controller.performChange("Create " + settings.moduleLabel(moduleName), create);
        else
            create();
    }

    function setting(name, fallback) {
        return valid ? settings.instanceSetting(instanceId, name, fallback) : fallback;
    }

    function setSetting(name, value) {
        return valid && settings.setInstanceSetting(instanceId, name, value);
    }

    function setNumberSetting(name, value, minimum, maximum) {
        return setSetting(name, settings.clamp(value, minimum, maximum));
    }

    onModuleNameChanged: Qt.callLater(resolveTarget)
    Component.onCompleted: Qt.callLater(resolveTarget)

    Connections {
        target: root.settings

        function onChanged() {
            if (root.instanceId.length > 0 && !root.settings.moduleInstance(root.instanceId))
                Qt.callLater(root.resolveTarget);
        }
    }

    spacing: theme.spacingM

    Controls.SectionHeader {
        width: parent.width
        theme: root.theme
        settings: root.settings
        title: valid ? settings.instanceDisplayLabel(instanceId) + " settings" : "Module settings"
        detail: valid ? instanceId + " / " + String(entry.category || "Other") + " / " + String(entry.cost || "unknown") + (Array.from(entry.capabilities || []).length > 0 ? " / " + Array.from(entry.capabilities || []).join(", ") : "") : "Choose a configurable module from the catalog."
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.valid
        theme: root.theme
        settings: root.settings
        label: "Enabled"
        description: "Keep this module active wherever it is placed."
        checked: settings.instanceEnabled(root.instanceId)
        onToggled: function (checked) {
            controller.performChange("Toggle " + root.entry.label, function () {
                settings.setInstanceEnabled(root.instanceId, checked);
            });
        }
    }

    Controls.ChoiceRow {
        width: parent.width
        visible: root.moduleType === "focusedWindow"
        theme: root.theme
        settings: root.settings
        label: "Display mode"
        value: root.setting("displayMode", "allWorkspaceApps")
        options: [
            {
                "label": "Workspace apps",
                "value": "allWorkspaceApps"
            },
            {
                "label": "Focused title",
                "value": "focusedTitle"
            }
        ]
        onSelected: function (value) {
            controller.performChange("Focused window display mode", function () {
                root.setSetting("displayMode", ["allWorkspaceApps", "focusedTitle"].indexOf(value) >= 0 ? value : "allWorkspaceApps");
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "focusedWindow"
        theme: root.theme
        settings: root.settings
        label: "Show focused title"
        checked: root.setting("showTitle", false)
        onToggled: function (checked) {
            controller.performChange("Focused window title", function () {
                root.setSetting("showTitle", checked);
            });
        }
    }

    Controls.SliderRow {
        width: parent.width
        visible: root.moduleType === "focusedWindow"
        theme: root.theme
        settings: root.settings
        label: "Maximum title width"
        value: root.setting("maxWidth", theme.settingsFocusedWindowWidthMin)
        minimum: theme.settingsFocusedWindowWidthMin
        maximum: theme.settingsFocusedWindowWidthMax
        step: theme.settingsDimensionStep
        suffix: " px"
        onValueRequested: function (value) {
            controller.performChange("Focused window width", function () {
                root.setNumberSetting("maxWidth", value, minimum, maximum);
            });
        }
    }

    Controls.TextRow {
        width: parent.width
        visible: root.moduleType === "clock"
        theme: root.theme
        settings: root.settings
        label: "Clock format"
        description: "Qt date and time format."
        value: root.setting("format", "HH:mm")
        placeholderText: "HH:mm"
        onValueRequested: function (value) {
            controller.performChange("Clock format", function () {
                const next = String(value || "HH:mm");
                settings.beginTransaction("clockFormat:" + root.instanceId);
                root.setSetting("format", next);
                root.setSetting("showSeconds", next.indexOf("s") >= 0 || next.indexOf("z") >= 0);
                settings.endTransaction();
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "clock"
        theme: root.theme
        settings: root.settings
        label: "Show seconds"
        checked: root.setting("showSeconds", false)
        onToggled: function (checked) {
            controller.performChange("Clock seconds", function () {
                root.setSetting("showSeconds", checked);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "audio"
        theme: root.theme
        settings: root.settings
        label: "Show percentage"
        checked: root.setting("showPercentage", true)
        onToggled: function (checked) {
            controller.performChange("Audio percentage", function () {
                root.setSetting("showPercentage", checked);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "audio"
        theme: root.theme
        settings: root.settings
        label: "Show device name"
        checked: root.setting("showDeviceName", false)
        onToggled: function (checked) {
            controller.performChange("Audio device name", function () {
                root.setSetting("showDeviceName", checked);
            });
        }
    }

    Controls.TextRow {
        width: parent.width
        visible: root.moduleType === "network"
        theme: root.theme
        settings: root.settings
        label: "Interface"
        description: "Leave empty for automatic selection."
        value: root.setting("interfaceName", "")
        placeholderText: "Automatic"
        onValueRequested: function (value) {
            controller.performChange("Network interface", function () {
                root.setSetting("interfaceName", String(value));
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "network"
        theme: root.theme
        settings: root.settings
        label: "Show speed"
        checked: root.setting("showSpeed", false)
        onToggled: function (checked) {
            controller.performChange("Network speed", function () {
                root.setSetting("showSpeed", checked);
            });
        }
    }

    Controls.SliderRow {
        width: parent.width
        visible: root.moduleType === "network"
        theme: root.theme
        settings: root.settings
        label: "Polling"
        value: settings.networkPollMs
        minimum: theme.settingsNetworkPollMin
        maximum: theme.settingsNetworkPollMax
        step: theme.settingsPollStep
        suffix: " ms"
        onValueRequested: function (value) {
            controller.performChange("Network polling", function () {
                settings.setPollingInterval("networkMs", value, minimum, maximum);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "battery"
        theme: root.theme
        settings: root.settings
        label: "Show percentage"
        checked: root.setting("showPercentage", true)
        onToggled: function (checked) {
            controller.performChange("Battery percentage", function () {
                root.setSetting("showPercentage", checked);
            });
        }
    }

    Controls.SliderRow {
        width: parent.width
        visible: root.moduleType === "battery"
        theme: root.theme
        settings: root.settings
        label: "Critical threshold"
        value: root.setting("criticalThreshold", theme.settingsBatteryThresholdMin)
        minimum: theme.settingsBatteryThresholdMin
        maximum: theme.settingsBatteryThresholdMax
        step: theme.settingsCountStep
        suffix: "%"
        onValueRequested: function (value) {
            controller.performChange("Battery threshold", function () {
                root.setNumberSetting("criticalThreshold", value, minimum, maximum);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "cpu"
        theme: root.theme
        settings: root.settings
        label: "Show graph"
        checked: root.setting("showGraph", false)
        onToggled: function (checked) {
            controller.performChange("CPU graph", function () {
                root.setSetting("showGraph", checked);
            });
        }
    }

    Controls.SliderRow {
        width: parent.width
        visible: root.moduleType === "cpu"
        theme: root.theme
        settings: root.settings
        label: "Polling"
        value: settings.cpuPollMs
        minimum: theme.settingsCpuPollMin
        maximum: theme.settingsCpuPollMax
        step: theme.settingsPollStep
        suffix: " ms"
        onValueRequested: function (value) {
            controller.performChange("CPU polling", function () {
                settings.setPollingInterval("cpuMs", value, minimum, maximum);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "memory"
        theme: root.theme
        settings: root.settings
        label: "Show graph"
        checked: root.setting("showGraph", false)
        onToggled: function (checked) {
            controller.performChange("Memory graph", function () {
                root.setSetting("showGraph", checked);
            });
        }
    }

    Controls.SliderRow {
        width: parent.width
        visible: root.moduleType === "memory"
        theme: root.theme
        settings: root.settings
        label: "Polling"
        value: settings.memoryPollMs
        minimum: theme.settingsMemoryPollMin
        maximum: theme.settingsMemoryPollMax
        step: theme.settingsPollStep
        suffix: " ms"
        onValueRequested: function (value) {
            controller.performChange("Memory polling", function () {
                settings.setPollingInterval("memoryMs", value, minimum, maximum);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "brightness"
        theme: root.theme
        settings: root.settings
        label: "Show percentage"
        checked: root.setting("showPercentage", true)
        onToggled: function (checked) {
            controller.performChange("Brightness percentage", function () {
                root.setSetting("showPercentage", checked);
            });
        }
    }

    Controls.SliderRow {
        width: parent.width
        visible: root.moduleType === "brightness"
        theme: root.theme
        settings: root.settings
        label: "Scroll step"
        value: root.setting("step", theme.settingsBrightnessStepMin)
        minimum: theme.settingsBrightnessStepMin
        maximum: theme.settingsBrightnessStepMax
        step: theme.settingsCountStep
        suffix: "%"
        onValueRequested: function (value) {
            controller.performChange("Brightness step", function () {
                root.setNumberSetting("step", value, minimum, maximum);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "media"
        theme: root.theme
        settings: root.settings
        label: "Show controls"
        checked: root.setting("showControls", true)
        onToggled: function (checked) {
            controller.performChange("Media controls", function () {
                root.setSetting("showControls", checked);
            });
        }
    }

    Controls.SliderRow {
        width: parent.width
        visible: root.moduleType === "media"
        theme: root.theme
        settings: root.settings
        label: "Maximum width"
        value: root.setting("maxWidth", theme.settingsMediaWidthMin)
        minimum: theme.settingsMediaWidthMin
        maximum: theme.settingsMediaWidthMax
        step: theme.settingsDimensionStep
        suffix: " px"
        onValueRequested: function (value) {
            controller.performChange("Media width", function () {
                root.setNumberSetting("maxWidth", value, minimum, maximum);
            });
        }
    }

    Controls.SliderRow {
        width: parent.width
        visible: root.moduleType === "tray"
        theme: root.theme
        settings: root.settings
        label: "Visible icons"
        value: root.setting("maxVisible", theme.settingsTrayCountMin)
        minimum: theme.settingsTrayCountMin
        maximum: theme.settingsTrayCountMax
        step: theme.settingsCountStep
        onValueRequested: function (value) {
            controller.performChange("Tray icon count", function () {
                root.setNumberSetting("maxVisible", value, minimum, maximum);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "tray"
        theme: root.theme
        settings: root.settings
        label: "Compact overflow"
        checked: root.setting("compact", true)
        onToggled: function (checked) {
            controller.performChange("Compact tray", function () {
                root.setSetting("compact", checked);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "workspaces"
        theme: root.theme
        settings: root.settings
        label: "Show numbers"
        checked: root.setting("showNumbers", true)
        onToggled: function (checked) {
            controller.performChange("Workspace numbers", function () {
                root.setSetting("showNumbers", checked);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "workspaces"
        theme: root.theme
        settings: root.settings
        label: "Show application icons"
        checked: root.setting("showAppIcons", false)
        onToggled: function (checked) {
            controller.performChange("Workspace app icons", function () {
                root.setSetting("showAppIcons", checked);
            });
        }
    }

    Controls.ToggleRow {
        width: parent.width
        visible: root.moduleType === "powerProfile"
        theme: root.theme
        settings: root.settings
        label: "Show label"
        checked: root.setting("showLabel", true)
        onToggled: function (checked) {
            controller.performChange("Power profile label", function () {
                root.setSetting("showLabel", checked);
            });
        }
    }

    Text {
        width: parent.width
        visible: root.valid && root.entry.configurable === false
        text: "This module has no additional settings."
        color: theme.textMuted
        font.family: settings.fontFamilySans
        font.pixelSize: theme.settingsBodyFontSize
    }
}
