import QtQuick
import "../controls" as Controls

Item {
    id: root

    property var appContext
    property var settings
    property var theme
    property var registry
    property var targetScreen
    property var controller

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: page.implicitHeight + theme.settingsPagePadding * theme.settingsPagePaddingFactor
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: page

            width: Math.min(parent.width - theme.settingsPagePadding * theme.settingsPagePaddingFactor, theme.settingsPageMaxWidth)
            x: (parent.width - width) / 2
            y: theme.settingsPagePadding
            spacing: theme.spacingXL

            Controls.PageHeading {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Panels"
                subtitle: "Configure transient drawers, overlays, and focused workflows."
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "On-screen display"
                detail: "Shared overlays for volume, brightness, media, keyboard, and battery events."
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Enable OSD"
                checked: settings.osdEnabled
                onToggled: function (checked) {
                    controller.performChange("OSD enabled", function () {
                        settings.setValue("osdEnabled", checked);
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                enabled: settings.osdEnabled
                theme: root.theme
                settings: root.settings
                label: "Style"
                value: settings.osdStyle
                options: [
                    {
                        "label": "Vertical",
                        "value": "vertical"
                    },
                    {
                        "label": "Horizontal",
                        "value": "horizontal"
                    },
                    {
                        "label": "Compact",
                        "value": "compact"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("OSD style", function () {
                        settings.setEnum("osdStyle", value, ["vertical", "horizontal", "compact"], "vertical");
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                enabled: settings.osdEnabled
                theme: root.theme
                settings: root.settings
                label: "Position"
                value: settings.osdPosition
                options: [
                    {
                        "label": "Right",
                        "value": "rightCenter"
                    },
                    {
                        "label": "Left",
                        "value": "leftCenter"
                    },
                    {
                        "label": "Top",
                        "value": "topCenter"
                    },
                    {
                        "label": "Bottom",
                        "value": "bottomCenter"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("OSD position", function () {
                        settings.setEnum("osdPosition", value, ["rightCenter", "leftCenter", "topCenter", "bottomCenter", "topRight", "bottomRight"], "rightCenter");
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                enabled: settings.osdEnabled
                theme: root.theme
                settings: root.settings
                label: "Timeout"
                value: settings.osdTimeout
                minimum: theme.settingsOsdTimeoutMin
                maximum: theme.settingsOsdTimeoutMax
                step: theme.settingsDurationStep
                suffix: " ms"
                onValueRequested: function (value) {
                    controller.performChange("OSD timeout", function () {
                        settings.setNumber("osdTimeout", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                enabled: settings.osdEnabled
                theme: root.theme
                settings: root.settings
                label: "Opacity"
                value: settings.osdOpacity
                minimum: theme.settingsOpacityMin
                maximum: theme.settingsOpacityMax
                step: theme.settingsOpacityStep
                decimals: theme.settingsOpacityDecimals
                onValueRequested: function (value) {
                    controller.performChange("OSD opacity", function () {
                        settings.setReal("osdOpacity", value, minimum, maximum, step);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                enabled: settings.osdEnabled
                theme: root.theme
                settings: root.settings
                label: "Show icon"
                checked: settings.osdShowIcon
                onToggled: function (checked) {
                    controller.performChange("OSD icon", function () {
                        settings.setValue("osdShowIcon", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                enabled: settings.osdEnabled
                theme: root.theme
                settings: root.settings
                label: "Show percentage"
                checked: settings.osdShowPercent
                onToggled: function (checked) {
                    controller.performChange("OSD percentage", function () {
                        settings.setValue("osdShowPercent", checked);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Dashboard"
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Panel width"
                value: settings.dashboardPanelWidth
                minimum: theme.settingsPanelWidthMin
                maximum: theme.settingsPanelWidthMax
                step: theme.settingsDimensionStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Dashboard width", function () {
                        settings.setNumber("dashboardPanelWidth", value, minimum, maximum);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Show media"
                checked: settings.dashboardShowMedia
                onToggled: function (checked) {
                    controller.performChange("Dashboard media", function () {
                        settings.setValue("dashboardShowMedia", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Show weather"
                checked: settings.dashboardShowWeather
                onToggled: function (checked) {
                    controller.performChange("Dashboard weather", function () {
                        settings.setValue("dashboardShowWeather", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Grow from trigger"
                checked: settings.dashboardGrowFromTrigger
                onToggled: function (checked) {
                    controller.performChange("Dashboard origin", function () {
                        settings.setValue("dashboardGrowFromTrigger", checked);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Notifications"
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Drawer width"
                value: settings.notificationsPanelWidth
                minimum: theme.settingsPanelWidthMin
                maximum: theme.settingsPanelWidthMax
                step: theme.settingsDimensionStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Notification width", function () {
                        settings.setNumber("notificationsPanelWidth", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Maximum notifications"
                value: settings.notificationsMaxVisible
                minimum: theme.settingsNotificationCountMin
                maximum: theme.settingsNotificationCountMax
                step: theme.settingsCountStep
                onValueRequested: function (value) {
                    controller.performChange("Notification count", function () {
                        settings.setNumber("notificationsMaxVisible", value, minimum, maximum);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Group by application"
                checked: settings.notificationsGroupByApp
                onToggled: function (checked) {
                    controller.performChange("Notification grouping", function () {
                        settings.setValue("notificationsGroupByApp", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Show message body"
                checked: settings.notificationsShowBody
                onToggled: function (checked) {
                    controller.performChange("Notification body", function () {
                        settings.setValue("notificationsShowBody", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Show images"
                checked: settings.notificationsShowImages
                onToggled: function (checked) {
                    controller.performChange("Notification images", function () {
                        settings.setValue("notificationsShowImages", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Show actions"
                checked: settings.notificationsShowActions
                onToggled: function (checked) {
                    controller.performChange("Notification actions", function () {
                        settings.setValue("notificationsShowActions", checked);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Launcher"
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Panel width"
                value: settings.launcherPanelWidth
                minimum: theme.settingsLauncherWidthMin
                maximum: theme.settingsLauncherWidthMax
                step: theme.settingsDimensionStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Launcher width", function () {
                        settings.setNumber("launcherPanelWidth", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Maximum results"
                value: settings.launcherMaxResults
                minimum: theme.settingsLauncherResultsMin
                maximum: theme.settingsLauncherResultsMax
                step: theme.settingsCountStep
                onValueRequested: function (value) {
                    controller.performChange("Launcher result count", function () {
                        settings.setNumber("launcherMaxResults", value, minimum, maximum);
                    });
                }
            }

            Controls.TextRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Search placeholder"
                value: settings.launcherSearchPlaceholder
                onValueRequested: function (value) {
                    controller.performChange("Launcher placeholder", function () {
                        settings.setString("launcherSearchPlaceholder", value);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Fuzzy search"
                checked: settings.launcherUseFuzzy
                onToggled: function (checked) {
                    controller.performChange("Launcher fuzzy search", function () {
                        settings.setValue("launcherUseFuzzy", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Show descriptions"
                checked: settings.launcherShowDescriptions
                onToggled: function (checked) {
                    controller.performChange("Launcher descriptions", function () {
                        settings.setValue("launcherShowDescriptions", checked);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Utilities"
                detail: "Notepad, clipboard, and process panel dimensions and limits."
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Notepad width"
                value: settings.notepadPanelWidth
                minimum: theme.settingsPanelWidthMin
                maximum: theme.settingsPanelWidthMax
                step: theme.settingsDimensionStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Notepad width", function () {
                        settings.setNumber("notepadPanelWidth", value, minimum, maximum);
                    });
                }
            }

            Controls.TextRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Notepad file"
                description: "Leave empty to use the default path."
                value: settings.notepadFilePath
                placeholderText: "Default"
                onValueRequested: function (value) {
                    controller.performChange("Notepad file", function () {
                        settings.setString("notepadFilePath", value);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Clipboard width"
                value: settings.clipboardPanelWidth
                minimum: theme.settingsPanelWidthMin
                maximum: theme.settingsPanelWidthMax
                step: theme.settingsDimensionStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Clipboard width", function () {
                        settings.setNumber("clipboardPanelWidth", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Clipboard items"
                value: settings.clipboardMaxItems
                minimum: theme.settingsClipboardCountMin
                maximum: theme.settingsClipboardCountMax
                step: theme.settingsCountStep
                onValueRequested: function (value) {
                    controller.performChange("Clipboard item count", function () {
                        settings.setNumber("clipboardMaxItems", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Process panel width"
                value: settings.processPanelWidth
                minimum: theme.settingsProcessWidthMin
                maximum: theme.settingsProcessWidthMax
                step: theme.settingsDimensionStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Process panel width", function () {
                        settings.setNumber("processPanelWidth", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Process rows"
                value: settings.processListLimit
                minimum: theme.settingsProcessCountMin
                maximum: theme.settingsProcessCountMax
                step: theme.settingsCountStep
                onValueRequested: function (value) {
                    controller.performChange("Process row count", function () {
                        settings.setNumber("processListLimit", value, minimum, maximum);
                    });
                }
            }
        }
    }
}
