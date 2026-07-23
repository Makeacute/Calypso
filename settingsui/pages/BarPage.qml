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
                title: "Bar"
                subtitle: "Shape the bar, its screen relationship, and module presentation."
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Composition"
                detail: "Recipes coordinate layout and appearance. Individual changes remain editable."
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Recipe"
                value: settings.themeRecipe
                options: [
                    {
                        "label": "Calypso",
                        "value": "calypsoDefault"
                    },
                    {
                        "label": "Compact glass",
                        "value": "compactGlass"
                    },
                    {
                        "label": "Material soft",
                        "value": "materialSoft"
                    },
                    {
                        "label": "Dense islands",
                        "value": "denseIslands"
                    },
                    {
                        "label": "Minimal solid",
                        "value": "minimalSolid"
                    },
                    {
                        "label": "Focus",
                        "value": "focusMode"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Bar recipe", function () {
                        settings.setThemeRecipe(value);
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Bar style"
                description: "Choose separated islands, one solid strip, or a centered pill."
                value: settings.barStyle
                options: [
                    {
                        "label": "Islands",
                        "value": "islands"
                    },
                    {
                        "label": "Solid",
                        "value": "solid"
                    },
                    {
                        "label": "Pill",
                        "value": "pill"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Bar style", function () {
                        settings.setEnum("barStyle", value, ["islands", "solid", "pill"], "islands");
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Position"
                value: settings.barPosition
                options: [
                    {
                        "label": "Top",
                        "value": "top"
                    },
                    {
                        "label": "Bottom",
                        "value": "bottom"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Bar position", function () {
                        settings.setEnum("barPosition", value, ["top", "bottom"], "top");
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Widget style"
                description: "Every bar module adapts to these three presentation modes."
                value: settings.widgetStyle
                options: [
                    {
                        "label": "Icon only",
                        "value": "iconOnly"
                    },
                    {
                        "label": "Icon + text",
                        "value": "iconAndText"
                    },
                    {
                        "label": "Expanded",
                        "value": "expanded"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Widget style", function () {
                        settings.setEnum("widgetStyle", value, ["iconOnly", "iconAndText", "expanded"], "iconAndText");
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Screen behavior"
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Reserve space"
                description: "Maintain the exclusive zone so tiled windows avoid the bar."
                checked: settings.reserveSpace
                onToggled: function (checked) {
                    controller.performChange("Reserve bar space", function () {
                        settings.setValue("reserveSpace", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Auto-hide"
                description: "Slide the bar away when it is not in use."
                checked: settings.barAutohide
                onToggled: function (checked) {
                    controller.performChange("Bar auto-hide", function () {
                        settings.setValue("barAutohide", checked);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Height"
                value: settings.barHeight
                minimum: theme.settingsBarHeightMin
                maximum: theme.settingsBarHeightMax
                step: theme.settingsCountStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Bar height", function () {
                        settings.setNumber("barHeight", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Screen margin"
                value: settings.screenMargin
                minimum: theme.settingsScreenMarginMin
                maximum: theme.settingsScreenMarginMax
                step: theme.settingsCountStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Screen margin", function () {
                        settings.setNumber("screenMargin", value, minimum, maximum);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Surface"
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Blur"
                description: "Use compositor blur unless performance mode disables it."
                checked: settings.barBlur
                onToggled: function (checked) {
                    controller.performChange("Bar blur", function () {
                        settings.setValue("barBlur", checked);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Opacity"
                value: settings.barOpacity
                minimum: theme.settingsOpacityMin
                maximum: theme.settingsOpacityMax
                step: theme.settingsOpacityStep
                decimals: theme.settingsOpacityDecimals
                onValueRequested: function (value) {
                    controller.performChange("Bar opacity", function () {
                        settings.setReal("barOpacity", value, minimum, maximum, step);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Border"
                checked: settings.barBorderEnabled
                onToggled: function (checked) {
                    controller.performChange("Bar border", function () {
                        settings.setValue("barBorderEnabled", checked);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                visible: settings.barBorderEnabled
                theme: root.theme
                settings: root.settings
                label: "Border thickness"
                value: settings.barBorderThickness
                minimum: theme.settingsBorderThicknessMin
                maximum: theme.settingsBorderThicknessMax
                step: theme.settingsCountStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Border thickness", function () {
                        settings.setNumber("barBorderThickness", value, minimum, maximum);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Internal layout"
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Group spacing"
                value: settings.groupSpacing
                minimum: theme.settingsGroupSpacingMin
                maximum: theme.settingsGroupSpacingMax
                step: theme.settingsCountStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Group spacing", function () {
                        settings.setNumber("groupSpacing", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Item spacing"
                value: settings.itemSpacing
                minimum: theme.settingsItemSpacingMin
                maximum: theme.settingsItemSpacingMax
                step: theme.settingsCountStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Item spacing", function () {
                        settings.setNumber("itemSpacing", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Group padding"
                value: settings.groupPadding
                minimum: theme.settingsGroupPaddingMin
                maximum: theme.settingsGroupPaddingMax
                step: theme.settingsCountStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Group padding", function () {
                        settings.setNumber("groupPadding", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Pill padding"
                value: settings.pillPadding
                minimum: theme.settingsPillPaddingMin
                maximum: theme.settingsPillPaddingMax
                step: theme.settingsCountStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Pill padding", function () {
                        settings.setNumber("pillPadding", value, minimum, maximum);
                    });
                }
            }
        }
    }
}
