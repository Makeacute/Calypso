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
    readonly property var healthEntries: [
        {
            "label": "Compositor",
            "value": serviceState(controller ? controller.optional(appContext, "compositor", null) : null),
            "icon": "󰍹"
        },
        {
            "label": "Notifications",
            "value": serviceState(controller ? controller.optional(appContext, "notificationServer", null) : null),
            "icon": "󰂚"
        },
        {
            "label": "Media",
            "value": serviceState(controller ? controller.optional(appContext, "mediaService", null) : null),
            "icon": "󰝚"
        },
        {
            "label": "Power profiles",
            "value": serviceState(controller ? controller.optional(appContext, "powerProfileService", null) : null),
            "icon": "󰓅"
        },
        {
            "label": "Battery",
            "value": serviceState(controller ? controller.optional(appContext, "batteryService", null) : null),
            "icon": "󰁹"
        },
        {
            "label": "Network",
            "value": serviceState(controller ? controller.optional(appContext, "networkService", null) : null),
            "icon": "󰤨"
        },
        {
            "label": "System stats",
            "value": serviceState(controller ? controller.optional(appContext, "systemStatsService", null) : null),
            "icon": "󰍛"
        },
        {
            "label": "Module registry",
            "value": registry && registry.entries ? String(registry.entries.length) + " registered" : "Unavailable",
            "icon": "󱂬"
        },
        {
            "label": "Theme adapter",
            "value": theme ? "Available" : "Unavailable",
            "icon": "󰸌"
        }
    ]

    function serviceState(service) {
        if (!service)
            return "Unavailable";
        const health = controller.optional(service, "healthStatus", undefined);
        if (health !== undefined)
            return String(health);
        const connected = controller.optional(service, "connected", undefined);
        if (connected !== undefined)
            return connected ? "Connected" : "Disconnected";
        const ready = controller.optional(service, "ready", undefined);
        if (ready !== undefined)
            return ready ? "Ready" : "Unavailable";
        const running = controller.optional(service, "running", undefined);
        if (running !== undefined)
            return running ? "Running" : "Stopped";
        return "Available";
    }

    function healthTone(value) {
        const normalized = String(value).toLowerCase();
        if (normalized.indexOf("unavailable") >= 0 || normalized.indexOf("disconnected") >= 0 || normalized.indexOf("stopped") >= 0)
            return "warning";
        return "good";
    }

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
                title: "Overview"
                subtitle: "A compact view of this Calypso development configuration."
            }

            Item {
                width: parent.width
                implicitHeight: identityContent.implicitHeight

                Column {
                    id: identityContent

                    width: parent.width
                    spacing: theme.spacingM

                    Row {
                        width: parent.width
                        spacing: theme.spacingM

                        Rectangle {
                            width: theme.settingsOverviewIdentitySize
                            height: width
                            radius: theme.radiusL
                            color: theme.surfaceActive
                            border.color: theme.outlineActive
                            border.width: theme.settingsBorderWidth

                            Text {
                                anchors.centerIn: parent
                                text: "󰣇"
                                color: theme.accent
                                font.family: settings.fontFamilyIcon
                                font.pixelSize: theme.settingsOverviewIconSize
                            }
                        }

                        Column {
                            width: parent.width - theme.settingsOverviewIdentitySize - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: theme.spacingXS

                            Text {
                                width: parent.width
                                text: appInfo ? String(controller.optional(appInfo, "name", "Calypso")) + " " + String(controller.optional(appInfo, "releaseChannel", "Development")) : "Calypso Development"
                                color: theme.text
                                font.family: settings.fontFamilySans
                                font.pixelSize: theme.settingsOverviewTitleFontSize
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                text: "Schema " + (appInfo ? String(controller.optional(appInfo, "schemaVersion", "Unavailable")) : settings ? String(settings.version) : "Unavailable")
                                color: theme.textMuted
                                font.family: settings.fontFamilyMono
                                font.pixelSize: theme.settingsCaptionFontSize
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: theme.settingsBorderWidth
                        color: theme.outlineSubtle
                    }

                    Grid {
                        id: summaryGrid

                        width: parent.width
                        columns: root.width < theme.settingsOverviewCompactBreakpoint ? 1 : 2
                        columnSpacing: theme.spacingXL
                        rowSpacing: theme.spacingS

                        Repeater {
                            model: [
                                {
                                    "label": "Repository",
                                    "value": appInfo ? String(controller.optional(appInfo, "repository", "Unavailable")) : "Unavailable"
                                },
                                {
                                    "label": "Config",
                                    "value": appInfo ? String(controller.optional(appInfo, "settingsPath", controller.optional(appInfo, "configDirectory", "Unavailable"))) : "Unavailable"
                                },
                                {
                                    "label": "Bar",
                                    "value": settings ? settings.barStyle + " / " + settings.barPosition + " / " + settings.widgetStyle : "Unavailable"
                                },
                                {
                                    "label": "Theme",
                                    "value": settings ? settings.themeRecipe + " / " + settings.paletteSource : "Unavailable"
                                },
                                {
                                    "label": "Modules",
                                    "value": settings ? String(settings.leftModules.length + settings.centerModules.length + settings.rightModules.length) + " placed" : "Unavailable"
                                },
                                {
                                    "label": "Screen",
                                    "value": targetScreen && targetScreen.name ? String(targetScreen.name) : "Unavailable"
                                }
                            ]

                            Row {
                                id: summaryRow

                                required property var modelData

                                width: (summaryGrid.width - summaryGrid.columnSpacing * (summaryGrid.columns - 1)) / summaryGrid.columns
                                spacing: theme.spacingM

                                Text {
                                    width: theme.settingsOverviewLabelWidth
                                    text: String(summaryRow.modelData.label)
                                    color: theme.textMuted
                                    font.family: settings.fontFamilySans
                                    font.pixelSize: theme.settingsCaptionFontSize
                                }

                                Text {
                                    width: parent.width - theme.settingsOverviewLabelWidth - parent.spacing
                                    text: String(summaryRow.modelData.value)
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

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Service health"
                detail: "Optional context services report Unavailable when they are not exposed."
            }

            Grid {
                id: healthGrid

                width: parent.width
                columns: root.width < theme.settingsOverviewCompactBreakpoint ? 1 : 2
                columnSpacing: theme.spacingM
                rowSpacing: theme.spacingM

                Repeater {
                    model: root.healthEntries

                    Rectangle {
                        id: healthCard

                        required property var modelData

                        width: (healthGrid.width - healthGrid.columnSpacing * (healthGrid.columns - 1)) / healthGrid.columns
                        height: theme.settingsHealthItemHeight
                        radius: theme.radiusM
                        color: theme.surfaceMuted
                        border.color: theme.outlineSubtle
                        border.width: theme.settingsBorderWidth

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: theme.spacingL
                            anchors.rightMargin: theme.spacingL
                            spacing: theme.spacingM

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(healthCard.modelData.icon)
                                color: theme.accent
                                font.family: settings.fontFamilyIcon
                                font.pixelSize: theme.settingsIconSize
                            }

                            Text {
                                width: parent.width - healthStatus.width - parent.spacing * theme.settingsHealthSpacingCount - theme.settingsIconSize
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(healthCard.modelData.label)
                                color: theme.text
                                elide: Text.ElideRight
                                font.family: settings.fontFamilySans
                                font.pixelSize: theme.settingsBodyFontSize
                            }

                            Controls.StatusBadge {
                                id: healthStatus

                                anchors.verticalCenter: parent.verticalCenter
                                theme: root.theme
                                settings: root.settings
                                text: String(healthCard.modelData.value)
                                tone: root.healthTone(text)
                            }
                        }
                    }
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Current configuration"
                detail: settings ? settings.settingsPreset + " density, " + settings.animationProfile + " motion, " + (settings.performanceMode ? "performance mode" : "full effects") : "Unavailable"
            }
        }
    }
}
