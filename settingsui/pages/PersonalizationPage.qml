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
                title: "Personalization"
                subtitle: "Tune palette adaptation, surfaces, typography, density, and motion."
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Visual language"
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Visual preset"
                value: settings.visualPreset
                options: [
                    {
                        "label": "Noctalia quiet",
                        "value": "noctaliaQuiet"
                    },
                    {
                        "label": "Frosted minimal",
                        "value": "frostedMinimal"
                    },
                    {
                        "label": "Material morphing",
                        "value": "materialMorphing"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Visual preset", function () {
                        settings.setVisualPreset(value);
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Surface style"
                value: settings.surfaceStyle
                options: [
                    {
                        "label": "Translucent",
                        "value": "translucent"
                    },
                    {
                        "label": "Frosted",
                        "value": "frosted"
                    },
                    {
                        "label": "Solid",
                        "value": "solid"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Surface style", function () {
                        settings.setEnum("surfaceStyle", value, ["translucent", "frosted", "solid"], "translucent");
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Pill style"
                value: settings.pillStyle
                options: [
                    {
                        "label": "Soft",
                        "value": "soft"
                    },
                    {
                        "label": "Filled",
                        "value": "filled"
                    },
                    {
                        "label": "Flat",
                        "value": "flat"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Pill style", function () {
                        settings.setEnum("pillStyle", value, ["soft", "filled", "flat"], "soft");
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Hover effect"
                value: settings.hoverEffect
                options: [
                    {
                        "label": "Wash",
                        "value": "wash"
                    },
                    {
                        "label": "Scale",
                        "value": "scale"
                    },
                    {
                        "label": "None",
                        "value": "none"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Hover effect", function () {
                        settings.setEnum("hoverEffect", value, ["wash", "scale", "none"], "wash");
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Palette"
                detail: "Theme.qml remains responsible for fallback colors when external palettes are absent."
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Palette source"
                value: settings.paletteSource
                options: [
                    {
                        "label": "Wallpaper",
                        "value": "wallpaper"
                    },
                    {
                        "label": "Stylix",
                        "value": "stylix"
                    },
                    {
                        "label": "Manual",
                        "value": "manual"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Palette source", function () {
                        settings.setEnum("paletteSource", value, ["wallpaper", "stylix", "manual"], "wallpaper");
                    });
                }
            }

            Controls.TextRow {
                width: parent.width
                visible: settings.paletteSource === "manual"
                theme: root.theme
                settings: root.settings
                label: "Manual accent"
                description: "Hex color used by the theme adapter."
                value: settings.manualAccent
                placeholderText: "Hex color"
                onValueRequested: function (value) {
                    controller.performChange("Manual accent", function () {
                        settings.setString("manualAccent", value);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Matugen colors"
                description: "Generate the Material palette from the selected wallpaper."
                checked: settings.matugenEnabled
                onToggled: function (checked) {
                    controller.performChange("Matugen", function () {
                        settings.setValue("matugenEnabled", checked);
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                enabled: settings.matugenEnabled
                theme: root.theme
                settings: root.settings
                label: "Color mode"
                value: settings.matugenMode
                options: [
                    {
                        "label": "Dark",
                        "value": "dark"
                    },
                    {
                        "label": "Light",
                        "value": "light"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Matugen mode", function () {
                        settings.setEnum("matugenMode", value, ["dark", "light"], "dark");
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                enabled: settings.matugenEnabled
                theme: root.theme
                settings: root.settings
                label: "Color scheme"
                value: settings.matugenScheme
                options: [
                    {
                        "label": "Tonal spot",
                        "value": "scheme-tonal-spot"
                    },
                    {
                        "label": "Vibrant",
                        "value": "scheme-vibrant"
                    },
                    {
                        "label": "Content",
                        "value": "scheme-content"
                    },
                    {
                        "label": "Expressive",
                        "value": "scheme-expressive"
                    },
                    {
                        "label": "Neutral",
                        "value": "scheme-neutral"
                    },
                    {
                        "label": "Monochrome",
                        "value": "scheme-monochrome"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Matugen scheme", function () {
                        settings.setString("matugenScheme", value);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Wallpaper"
            }

            Controls.TextRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Wallpaper directory"
                value: settings.wallpaperDirectory
                onValueRequested: function (value) {
                    controller.performChange("Wallpaper directory", function () {
                        settings.setString("wallpaperDirectory", value);
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Backend"
                value: settings.wallpaperBackend
                options: [
                    {
                        "label": "Awww",
                        "value": "awww"
                    },
                    {
                        "label": "Swww",
                        "value": "swww"
                    },
                    {
                        "label": "None",
                        "value": "none"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Wallpaper backend", function () {
                        settings.setString("wallpaperBackend", value);
                    });
                }
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Resize mode"
                value: settings.wallpaperResizeMode
                options: [
                    {
                        "label": "Crop",
                        "value": "crop"
                    },
                    {
                        "label": "Fit",
                        "value": "fit"
                    },
                    {
                        "label": "Stretch",
                        "value": "stretch"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Wallpaper resize mode", function () {
                        settings.setString("wallpaperResizeMode", value);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Recursive discovery"
                checked: settings.wallpaperRecursive
                onToggled: function (checked) {
                    controller.performChange("Wallpaper recursion", function () {
                        settings.setValue("wallpaperRecursive", checked);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Apply wallpaper colors"
                checked: settings.wallpaperApplyColors
                onToggled: function (checked) {
                    controller.performChange("Wallpaper colors", function () {
                        settings.setValue("wallpaperApplyColors", checked);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Density and type"
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Density preset"
                value: settings.settingsPreset
                options: [
                    {
                        "label": "Compact",
                        "value": "Compact"
                    },
                    {
                        "label": "Balanced",
                        "value": "Balanced"
                    },
                    {
                        "label": "Roomy",
                        "value": "Roomy"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Density preset", function () {
                        settings.setSettingsPreset(value);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Spacing scale"
                value: settings.spacingScale
                minimum: theme.settingsScaleMin
                maximum: theme.settingsScaleMax
                step: theme.settingsScaleStep
                suffix: "x"
                decimals: theme.settingsScaleDecimals
                onValueRequested: function (value) {
                    controller.performChange("Spacing scale", function () {
                        settings.setReal("spacingScale", value, minimum, maximum, step);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Radius scale"
                value: settings.radiusScale
                minimum: theme.settingsScaleMin
                maximum: theme.settingsScaleMax
                step: theme.settingsScaleStep
                suffix: "x"
                decimals: theme.settingsScaleDecimals
                onValueRequested: function (value) {
                    controller.performChange("Radius scale", function () {
                        settings.setReal("radiusScale", value, minimum, maximum, step);
                    });
                }
            }

            Controls.TextRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Interface font"
                value: settings.fontFamilySans
                onValueRequested: function (value) {
                    controller.performChange("Interface font", function () {
                        settings.setString("fontFamilySans", value);
                    });
                }
            }

            Controls.TextRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Monospace font"
                value: settings.fontFamilyMono
                onValueRequested: function (value) {
                    controller.performChange("Monospace font", function () {
                        settings.setString("fontFamilyMono", value);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Font size"
                value: settings.fontSize
                minimum: theme.settingsFontSizeMin
                maximum: theme.settingsFontSizeMax
                step: theme.settingsCountStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Font size", function () {
                        settings.setNumber("fontSize", value, minimum, maximum);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Icon size"
                value: settings.iconSize
                minimum: theme.settingsIconSizeMin
                maximum: theme.settingsIconSizeMax
                step: theme.settingsCountStep
                suffix: " px"
                onValueRequested: function (value) {
                    controller.performChange("Icon size", function () {
                        settings.setNumber("iconSize", value, minimum, maximum);
                    });
                }
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Motion"
                detail: "All Calypso animations derive from motion tokens and collapse under reduced motion."
            }

            Controls.ChoiceRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Animation profile"
                value: settings.animationProfile
                options: [
                    {
                        "label": "Physical",
                        "value": "Physical"
                    },
                    {
                        "label": "Snappy",
                        "value": "Snappy"
                    },
                    {
                        "label": "Calm",
                        "value": "Calm"
                    },
                    {
                        "label": "Instant",
                        "value": "Instant"
                    }
                ]
                onSelected: function (value) {
                    controller.performChange("Animation profile", function () {
                        settings.setAnimationProfile(value);
                    });
                }
            }

            Controls.SliderRow {
                width: parent.width
                enabled: !settings.reduceMotion
                theme: root.theme
                settings: root.settings
                label: "Base duration"
                value: settings.animationBaseMs
                minimum: theme.settingsAnimationDurationMin
                maximum: theme.settingsAnimationDurationMax
                step: theme.settingsDurationStep
                suffix: " ms"
                onValueRequested: function (value) {
                    controller.performChange("Animation duration", function () {
                        settings.setAnimationMs(value);
                    });
                }
            }

            Controls.ToggleRow {
                width: parent.width
                theme: root.theme
                settings: root.settings
                label: "Reduce motion"
                checked: settings.reduceMotion
                onToggled: function (checked) {
                    controller.performChange("Reduce motion", function () {
                        settings.setReduceMotion(checked);
                    });
                }
            }
        }
    }
}
