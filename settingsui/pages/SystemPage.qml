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
    readonly property var appInfo: appContext && controller ? controller.optional(appContext, "appInfo", null) : null

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
                title: "System"
                subtitle: "Performance, compositor integration, polling, and diagnostics."
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Runtime"
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Performance mode"
                description: "Disable expensive visual effects and token-derived motion."
                checked: settings.performanceMode
                onToggled: function (checked) {
                    controller.performChange("Performance mode", function () {
                        settings.setValue("performanceMode", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Reduce motion"
                description: "Collapse animation tokens to instant transitions."
                checked: settings.reduceMotion
                onToggled: function (checked) {
                    controller.performChange("Reduce motion", function () {
                        settings.setReduceMotion(checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Tooltips"
                checked: settings.tooltipsEnabled
                onToggled: function (checked) {
                    controller.performChange("Tooltips", function () {
                        settings.setValue("tooltipsEnabled", checked);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                enabled: settings.tooltipsEnabled
                theme: root.theme
                settings: root.settings
                label: "Tooltip delay"
                value: settings.tooltipDelay
                minimum: theme.settingsTooltipDelayMin
                maximum: theme.settingsTooltipDelayMax
                step: theme.settingsDurationStep
                suffix: " ms"
                onValueRequested: function (value) {
                    controller.performChange("Tooltip delay", function () {
                        settings.setNumber("tooltipDelay", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Workspace toast timeout"
                value: settings.workspaceToastTimeout
                minimum: theme.settingsToastTimeoutMin
                maximum: theme.settingsToastTimeoutMax
                step: theme.settingsDurationStep
                suffix: " ms"
                onValueRequested: function (value) {
                    controller.performChange("Workspace toast timeout", function () {
                        settings.setNumber("workspaceToastTimeout", value, minimum, maximum);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Compositor"
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Backend"
                description: "Automatic selection currently resolves to the available compositor service."
                value: settings.compositorBackend
                options: [
                    {
                        "label": "Automatic",
                        "value": "auto"
                    },
                    {
                        "label": "Niri",
                        "value": "niri"
                    },
                    {
                        "label": "Hyprland",
                        "value": "hyprland"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Compositor backend", function () {
                        settings.setObjectValue("compositor", "backend", value);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Polling"
                detail: "These are existing configurable fallback intervals; this settings window adds no poller."
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "CPU"
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

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Memory"
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

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Network"
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

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Media fallback"
                value: settings.mediaPollMs
                minimum: theme.settingsMediaPollMin
                maximum: theme.settingsMediaPollMax
                step: theme.settingsPollStep
                suffix: " ms"
                onValueRequested: function (value) {
                    controller.performChange("Media polling", function () {
                        settings.setPollingInterval("mediaMs", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Battery fallback"
                value: settings.batteryFallbackPollMs
                minimum: theme.settingsBatteryPollMin
                maximum: theme.settingsBatteryPollMax
                step: theme.settingsSlowPollStep
                suffix: " ms"
                onValueRequested: function (value) {
                    controller.performChange("Battery polling", function () {
                        settings.setPollingInterval("batteryFallbackMs", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Brightness fallback"
                value: settings.brightnessPollMs
                minimum: theme.settingsBrightnessPollMin
                maximum: theme.settingsBrightnessPollMax
                step: theme.settingsSlowPollStep
                suffix: " ms"
                onValueRequested: function (value) {
                    controller.performChange("Brightness polling", function () {
                        settings.setPollingInterval("brightnessMs", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Process list"
                value: settings.processListPollMs
                minimum: theme.settingsProcessPollMin
                maximum: theme.settingsProcessPollMax
                step: theme.settingsPollStep
                suffix: " ms"
                onValueRequested: function (value) {
                    controller.performChange("Process polling", function () {
                        settings.setPollingInterval("processListMs", value, minimum, maximum);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Module details"
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Pin details popup"
                checked: settings.modulePopupPinned
                onToggled: function (checked) {
                    controller.performChange("Pinned module details", function () {
                        settings.setValue("modulePopupPinned", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Show gauge"
                checked: settings.modulePopupShowGauge
                onToggled: function (checked) {
                    controller.performChange("Module gauge", function () {
                        settings.setValue("modulePopupShowGauge", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Show sparkline"
                checked: settings.modulePopupShowSparkline
                onToggled: function (checked) {
                    controller.performChange("Module sparkline", function () {
                        settings.setValue("modulePopupShowSparkline", checked);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "History samples"
                value: settings.modulePopupHistorySamples
                minimum: theme.settingsHistorySamplesMin
                maximum: theme.settingsHistorySamplesMax
                step: theme.settingsCountStep
                onValueRequested: function (value) {
                    controller.performChange("Module history samples", function () {
                        settings.setNumber("modulePopupHistorySamples", value, minimum, maximum);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Diagnostics"
            }

            Grid {
                id: diagnosticsGrid

                width: parent.width
                columns: root.width < theme.settingsDiagnosticsBreakpoint ? 1 : 2
                columnSpacing: theme.spacingXL
                rowSpacing: theme.spacingS

                Repeater {
                    model: [
                        {
                            "label": "Schema",
                            "value": appInfo ? String(controller.optional(appInfo, "schemaVersion", "Unavailable")) : settings ? String(settings.version) : "Unavailable"
                        },
                        {
                            "label": "Palette",
                            "value": settings ? settings.palettePath : "Unavailable"
                        },
                        {
                            "label": "Config",
                            "value": appInfo ? String(controller.optional(appInfo, "configDirectory", "Unavailable")) : "Unavailable"
                        },
                        {
                            "label": "Registry",
                            "value": registry && registry.entries ? String(registry.entries.length) + " entries" : "Unavailable"
                        },
                        {
                            "label": "Motion",
                            "value": settings && settings.reduceMotion ? "Reduced" : "Token driven"
                        },
                        {
                            "label": "Performance",
                            "value": settings && settings.performanceMode ? "Economy" : "Standard"
                        }
                    ]

                    Row {
                        id: diagnosticsRow

                        required property var modelData

                        width: (diagnosticsGrid.width - diagnosticsGrid.columnSpacing * (diagnosticsGrid.columns - 1)) / diagnosticsGrid.columns
                        spacing: theme.spacingM

                        Text {
                            width: theme.settingsDiagnosticsLabelWidth
                            text: String(diagnosticsRow.modelData.label)
                            color: theme.textMuted
                            font.family: settings.fontFamilySans
                            font.pixelSize: theme.settingsCaptionFontSize
                        }

                        Text {
                            width: parent.width - theme.settingsDiagnosticsLabelWidth - parent.spacing
                            text: String(diagnosticsRow.modelData.value)
                            color: theme.text
                            elide: Text.ElideMiddle
                            font.family: settings.fontFamilyMono
                            font.pixelSize: theme.settingsCaptionFontSize
                        }
                    }
                }
            }
        }
    }
}
