import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var settings: null
    readonly property string defaultPalettePath: {
        const configHome = Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config";
        return configHome + "/stylix/palette.json";
    }

    visible: false
    width: 0
    height: 0

    function clean(value, fallback) {
        const fallbackText = String(fallback || "").replace("#", "");
        const text = String(value || fallbackText).replace("#", "");
        return /^[0-9a-fA-F]{6}$/.test(text) ? text : fallbackText;
    }

    function hex(value, fallback) {
        return "#" + clean(value, fallback);
    }

    function alpha(colorValue, amount) {
        const opacity = Math.max(0, Math.min(1, Number(amount)));
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity);
    }

    property color base: hex(palette.base00, "1c1b1c")
    property color mantle: hex(palette.base01, "252426")
    property color surface: alpha(Qt.lighter(base, 1.18), 0.92)
    property color surfaceContainer: alpha(Qt.lighter(base, 1.26), 0.94)
    property color surfaceContainerHigh: alpha(Qt.lighter(base, 1.36), 0.97)
    property color surfaceStrong: surfaceContainerHigh
    property color surfaceMuted: alpha(Qt.lighter(base, 1.14), 0.58)
    property color primary: hex(palette.base0D, "90a4c8")
    property color secondary: hex(palette.base0C, "929292")
    property color tertiary: hex(palette.base0E, "c678dd")
    property color error: hex(palette.base08, "e06c75")
    property color surfaceHover: alpha(text, 0.08)
    property color surfacePressed: alpha(text, 0.12)
    property color surfaceActive: alpha(primary, 0.20)
    property color surfacePanel: surfaceContainerHigh
    property color borderBase: hex(palette.base03, "777777")
    property color outlineVariant: alpha(borderBase, 0.16)
    property color border: outlineVariant
    property color outlineSubtle: outlineVariant
    property color outlineActive: alpha(primary, 0.36)
    property color text: hex(palette.base05, "c8c8c8")
    property color textMuted: hex(palette.base03, "9a9d99")
    property color accent: primary
    property color accentSoft: alpha(primary, 0.24)
    property color accentSofter: alpha(primary, 0.14)
    property color urgent: error
    property color warning: hex(palette.base0A, "c8b36d")
    property color good: hex(palette.base0B, "9fbf8f")
    property color gloss: alpha(Qt.rgba(1, 1, 1, 1), 0.06)
    property color controlKnob: hex(palette.base07, "ffffff")
    property color shadow: Qt.rgba(0, 0, 0, 0.28)
    property color shadowSubtle: Qt.rgba(0, 0, 0, 0.18)
    property color transparent: Qt.rgba(0, 0, 0, 0)
    property real motionScale: settings && settings.reduceMotion ? 0 : 1
    readonly property real motionFast: 80 * motionScale
    readonly property real motionNormal: 160 * motionScale
    readonly property real motionHover: 100 * motionScale
    readonly property real motionPulse: 220 * motionScale
    readonly property real motionBreath: 1800 * motionScale
    readonly property real motionOpen: 220 * motionScale
    readonly property real motionClose: 180 * motionScale
    readonly property real motionSpatial: 200 * motionScale
    readonly property real motionEmphasis: 240 * motionScale
    property real spacingScale: settings ? settings.spacingScale : 1.0
    property real radiusScale: settings ? settings.radiusScale : 1.0
    readonly property real spacingXS: 4 * spacingScale
    readonly property real spacingS: 8 * spacingScale
    readonly property real spacingM: 12 * spacingScale
    readonly property real spacingL: 16 * spacingScale
    readonly property real spacingXL: 24 * spacingScale
    readonly property real radiusS: 6 * radiusScale
    readonly property real radiusM: 10 * radiusScale
    readonly property real radiusL: 16 * radiusScale
    readonly property real radiusXL: 24 * radiusScale

    // Settings application geometry and control tokens.
    readonly property int settingsWindowWidth: 960
    readonly property int settingsWindowHeight: 680
    readonly property int settingsWindowMinWidth: 720
    readonly property int settingsWindowMinHeight: 520
    readonly property int moduleValueWidth: 52
    readonly property int moduleBatteryValueWidth: 54
    readonly property int moduleGraphWidth: 96
    readonly property int moduleNetworkSpeedWidth: 132
    readonly property int moduleNetworkLabelWidth: 180
    readonly property int modulePowerProfileWidth: 102
    readonly property int moduleClockWidth: 150
    readonly property int moduleAudioDeviceWidth: 140
    readonly property int settingsCompactBreakpoint: 820
    readonly property int settingsModuleLanesBreakpoint: 900
    readonly property int settingsOverviewCompactBreakpoint: 760
    readonly property int settingsDiagnosticsBreakpoint: 620
    readonly property int settingsSidebarWidth: 208
    readonly property int settingsCompactNavWidth: 64
    readonly property int settingsCompactNavHeight: 56
    readonly property int settingsHeaderHeight: 56
    readonly property int settingsPageMaxWidth: 760
    readonly property int settingsPagePadding: Math.round(spacingXL)
    readonly property int settingsSearchMinWidth: 220
    readonly property int settingsSearchResultsWidth: 420
    readonly property int settingsSearchResultsMaxHeight: 360
    readonly property int settingsSearchResultHeight: 48
    readonly property int settingsSearchMaxResults: 10
    readonly property int settingsSearchTextInset: Math.round(spacingM * 2 + settingsIconSize)
    readonly property int settingsIdentityWidth: 252
    readonly property int settingsCompactIdentityWidth: 180
    readonly property int settingsIdentityIconSize: 44
    readonly property int settingsOverviewIdentitySize: 64
    readonly property int settingsOverviewIconSize: 28
    readonly property int settingsOverviewLabelWidth: 132
    readonly property int settingsDiagnosticsLabelWidth: 112
    readonly property int settingsHealthItemHeight: 44
    readonly property int settingsNavItemHeight: 42
    readonly property int settingsCatalogRowHeight: 52
    readonly property int settingsModuleRowHeight: 48
    readonly property int settingsCatalogIconSize: 30
    readonly property int settingsCatalogLabelMinWidth: 128
    readonly property int settingsModuleLabelMinWidth: 112
    readonly property int settingsControlHeight: 36
    readonly property int settingsRowMinHeight: 48
    readonly property int settingsIconButtonSize: 34
    readonly property int settingsIconSize: 18
    readonly property int settingsChoiceMaxWidth: 300
    readonly property int settingsTextFieldWidth: 300
    readonly property int settingsSliderWidth: 220
    readonly property int settingsSliderHitHeight: 32
    readonly property int settingsSliderTrackHeight: 4
    readonly property int settingsSliderTrackRadius: 2
    readonly property int settingsSliderHandleSize: 16
    readonly property int settingsSliderHandleRadius: 8
    readonly property int settingsSwitchWidth: 42
    readonly property int settingsSwitchHeight: 24
    readonly property int settingsSwitchRadius: 12
    readonly property int settingsSwitchInset: 3
    readonly property int settingsSwitchKnobSize: 18
    readonly property int settingsSwitchKnobRadius: 9
    readonly property int settingsStatusDotSize: 8
    readonly property int settingsStatusDotRadius: 4
    readonly property int settingsHeaderFontSize: 20
    readonly property int settingsPageTitleFontSize: 22
    readonly property int settingsOverviewTitleFontSize: 24
    readonly property int settingsSectionFontSize: 14
    readonly property int settingsBodyFontSize: 13
    readonly property int settingsCaptionFontSize: 11
    readonly property int settingsBorderWidth: 1
    readonly property int settingsOverlayZ: 100
    readonly property int settingsHeaderSpacingCount: 3
    readonly property int settingsHealthSpacingCount: 2
    readonly property int settingsCatalogSpacingCount: 2
    readonly property int settingsModuleActionCount: 3
    readonly property int settingsModuleButtonCount: 4
    readonly property real settingsSidebarPaddingFactor: 0.75
    readonly property real settingsCompactNavPaddingFactor: 0.5
    readonly property real settingsLanePaddingFactor: 0.75
    readonly property real settingsPagePaddingFactor: 2
    readonly property real settingsSearchEdgeFactor: 1.5
    readonly property real settingsBadgeFillOpacity: 0.16
    readonly property real settingsBadgeOutlineOpacity: 0.32
    readonly property real settingsEnabledOpacity: 1
    readonly property real settingsDisabledOpacity: 0.45

    // Descriptor validation and stepping tokens.
    readonly property int settingsHistoryLimit: 50
    readonly property int settingsBarHeightMin: 24
    readonly property int settingsBarHeightMax: 56
    readonly property int settingsScreenMarginMin: 0
    readonly property int settingsScreenMarginMax: 48
    readonly property int settingsBorderThicknessMin: 0
    readonly property int settingsBorderThicknessMax: 4
    readonly property int settingsGroupPaddingMin: 0
    readonly property int settingsGroupPaddingMax: 12
    readonly property int settingsPillPaddingMin: 0
    readonly property int settingsPillPaddingMax: 20
    readonly property int settingsGroupSpacingMin: 0
    readonly property int settingsGroupSpacingMax: 24
    readonly property int settingsItemSpacingMin: 0
    readonly property int settingsItemSpacingMax: 20
    readonly property int settingsPanelWidthMin: 320
    readonly property int settingsPanelWidthMax: 960
    readonly property int settingsLauncherWidthMin: 360
    readonly property int settingsLauncherWidthMax: 900
    readonly property int settingsProcessWidthMin: 360
    readonly property int settingsProcessWidthMax: 900
    readonly property int settingsFocusedWindowWidthMin: 100
    readonly property int settingsFocusedWindowWidthMax: 600
    readonly property int settingsMediaWidthMin: 80
    readonly property int settingsMediaWidthMax: 500
    readonly property int settingsBatteryThresholdMin: 1
    readonly property int settingsBatteryThresholdMax: 50
    readonly property int settingsBrightnessStepMin: 1
    readonly property int settingsBrightnessStepMax: 20
    readonly property int settingsLauncherResultsMin: 4
    readonly property int settingsLauncherResultsMax: 50
    readonly property int settingsNotificationCountMin: 1
    readonly property int settingsNotificationCountMax: 100
    readonly property int settingsClipboardCountMin: 5
    readonly property int settingsClipboardCountMax: 100
    readonly property int settingsProcessCountMin: 5
    readonly property int settingsProcessCountMax: 100
    readonly property int settingsTrayCountMin: 1
    readonly property int settingsTrayCountMax: 20
    readonly property int settingsOsdTimeoutMin: 200
    readonly property int settingsOsdTimeoutMax: 5000
    readonly property int settingsCpuPollMin: 1000
    readonly property int settingsCpuPollMax: 60000
    readonly property int settingsMemoryPollMin: 1000
    readonly property int settingsMemoryPollMax: 60000
    readonly property int settingsNetworkPollMin: 1000
    readonly property int settingsNetworkPollMax: 60000
    readonly property int settingsMediaPollMin: 500
    readonly property int settingsMediaPollMax: 30000
    readonly property int settingsBatteryPollMin: 10000
    readonly property int settingsBatteryPollMax: 120000
    readonly property int settingsBrightnessPollMin: 5000
    readonly property int settingsBrightnessPollMax: 120000
    readonly property int settingsProcessPollMin: 2000
    readonly property int settingsProcessPollMax: 30000
    readonly property int settingsHistorySamplesMin: 8
    readonly property int settingsHistorySamplesMax: 64
    readonly property int settingsAnimationDurationMin: 0
    readonly property int settingsAnimationDurationMax: 500
    readonly property int settingsFontSizeMin: 10
    readonly property int settingsFontSizeMax: 18
    readonly property int settingsIconSizeMin: 12
    readonly property int settingsIconSizeMax: 24
    readonly property int settingsTooltipDelayMin: 250
    readonly property int settingsTooltipDelayMax: 1500
    readonly property int settingsToastTimeoutMin: 500
    readonly property int settingsToastTimeoutMax: 2500
    readonly property int settingsCountStep: 1
    readonly property int settingsDimensionStep: 2
    readonly property int settingsDurationStep: 100
    readonly property int settingsPollStep: 500
    readonly property int settingsSlowPollStep: 5000
    readonly property real settingsScaleMin: 0.5
    readonly property real settingsScaleMax: 2
    readonly property real settingsScaleStep: 0.1
    readonly property int settingsScaleDecimals: 1
    readonly property real settingsOpacityMin: 0
    readonly property real settingsOpacityMax: 1
    readonly property real settingsOpacityStep: 0.05
    readonly property int settingsOpacityDecimals: 2

    FileView {
        id: paletteFile

        path: settings && settings.palettePath && settings.palettePath.length > 0 ? settings.palettePath : root.defaultPalettePath
        watchChanges: true
        blockLoading: true
        printErrors: false
        onFileChanged: reload()

        JsonAdapter {
            id: palette

            property string base00: "1c1b1c"
            property string base01: "474647"
            property string base02: "696f68"
            property string base03: "9a9d99"
            property string base04: "bababa"
            property string base05: "c8c8c8"
            property string base06: "c4c4c4"
            property string base07: "c7c7c7"
            property string base08: "e06c75"
            property string base09: "d19a66"
            property string base0A: "c8b36d"
            property string base0B: "98c379"
            property string base0C: "929292"
            property string base0D: "90a4c8"
            property string base0E: "c678dd"
            property string base0F: "be5046"
        }
    }
}
