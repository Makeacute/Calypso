import QtQuick
import Quickshell.Io

Item {
    id: root

    property var settings: null

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

    FileView {
        id: paletteFile

        path: settings && settings.palettePath && settings.palettePath.length > 0 ? settings.palettePath : "/home/lucian/.config/quickshell/palette.json"
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
