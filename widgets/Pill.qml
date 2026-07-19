import QtQuick

Rectangle {
    id: root

    property var theme
    property var settings
    property string icon: ""
    property string text: ""
    property string detailText: ""
    property string tooltipText: ""
    property var tooltipHost: null
    property bool active: false
    property bool selected: active
    property bool urgent: false
    property bool danger: false
    property bool muted: false
    property bool compact: false
    property bool hoverable: true
    property bool clickable: false
    property bool detailsOnClick: false
    property string detailsModuleName: ""
    property bool scrollable: false
    property string pillStyle: settings ? settings.pillStyle : "soft"
    property string hoverEffect: settings ? settings.hoverEffect : "wash"
    property int minimumWidth: 0
    property int maximumTextWidth: 180
    property int contentSpacing: settings.effectiveContentSpacing
    property int iconOpticalOffsetX: -Math.max(1, Math.round(settings.effectiveIconSize * 0.10))
    property color accentColor: theme.accent
    property real progress: -1
    property color progressColor: theme.alpha(accentColor, 0.16)
    property bool showGraph: false
    property var graphValues: []
    property color graphColor: accentColor
    property bool textPulseOnChange: false
    property real textPulseMinimumOpacity: 0.6
    property int textPulseDuration: Math.max(0, Math.round(settings.motionPulse * 0.55))
    property bool iconFadeOnChange: false
    property int iconFadeDuration: settings.motionNormal
    property bool iconPulseActive: false
    property real iconPulseMinimumOpacity: 0.7
    property int iconPulseDuration: settings ? settings.motionBreath : 0
    property real textPulseOpacity: 1
    property real iconFadeOpacity: 1
    property real iconPulseOpacity: 1
    property bool pulseAnimationsEnabled: !settings || settings.motionPulse > 0
    property string displayedIcon: icon
    property string pendingIcon: icon
    property bool ready: false
    readonly property bool iconOnlyMode: settings && settings.widgetStyle === "iconOnly"
    readonly property bool expandedMode: settings && settings.widgetStyle === "expanded"
    readonly property bool stackedDetailMode: expandedMode
                                               && detailText.length > 0
                                               && settings.moduleHeight >= Math.round(settings.effectiveFontSize * 2.2)
    readonly property string shownText: iconOnlyMode ? "" : expandedMode && detailText.length > 0 && !stackedDetailMode ? text + " / " + detailText : text
    readonly property string shownDetailText: stackedDetailMode ? detailText : ""

    signal clicked(var mouse)
    signal rightClicked(var mouse)
    signal middleClicked(var mouse)
    signal scrolled(int steps, var wheel)
    signal detailsRequested(var anchorItem, string moduleName)

    function effectiveTooltipText() {
        if (tooltipText.length > 0) return tooltipText;
        if (shownText.length > 0 && shownDetailText.length > 0) return shownText + " - " + shownDetailText;
        if (shownText.length > 0) return shownText;
        return "";
    }

    function neutralColor() {
        if (muted) return theme.alpha(theme.textMuted, pillStyle === "filled" ? 0.16 : 0.10);
        if (pillStyle === "filled") return theme.alpha(theme.accent, 0.12);
        if (pillStyle === "outlined") return theme.alpha(theme.text, 0.025);
        if (pillStyle === "flat") return theme.transparent;
        return theme.alpha(theme.text, 0.035);
    }

    function hoverColor() {
        if (!hoverable || hoverEffect === "none") return neutralColor();
        if (pillStyle === "filled") return theme.alpha(theme.accent, 0.18);
        if (pillStyle === "outlined") return theme.alpha(theme.text, 0.055);
        return theme.surfaceHover;
    }

    function pillColor() {
        if (danger || urgent) return theme.alpha(theme.urgent, 0.18);
        if (selected) return pillStyle === "filled" ? theme.alpha(accentColor, 0.28) : theme.surfaceActive;
        if (hoverArea.containsMouse) return hoverColor();
        return neutralColor();
    }

    function pillBorderColor() {
        if (danger || urgent) return theme.alpha(theme.urgent, 0.44);
        if (selected) return theme.alpha(accentColor, 0.34);
        if (pillStyle === "outlined") return theme.outlineSubtle;
        if (pillStyle === "filled") return theme.alpha(accentColor, 0.20);
        return theme.transparent;
    }

    function hoverScale() {
        if (!hoverable || !hoverArea.containsMouse || settings.motionHover <= 0) return 1;
        if (clickable || detailsOnClick || scrollable) return 1.015;
        return hoverEffect === "scale" ? 1.015 : 1;
    }

    function textFontFamily(value) {
        return /[0-9%./:+-]/.test(String(value || "")) ? settings.fontFamilyMono : settings.fontFamilySans;
    }

    implicitWidth: Math.max(minimumWidth, content.implicitWidth + (compact ? settings.effectivePillPadding : settings.effectivePillPadding * 2))
    implicitHeight: settings.moduleHeight
    width: implicitWidth
    height: implicitHeight
    radius: settings.effectivePillRadius
    color: pillColor()
    border.color: pillBorderColor()
    border.width: settings.effectiveBorderWidth
    antialiasing: true
    opacity: enabled ? 1 : 0.55
    scale: hoverScale()

    Behavior on color {
        ColorAnimation { duration: settings.motionNormal }
    }

    Behavior on border.color {
        ColorAnimation { duration: settings.motionNormal }
    }

    Behavior on opacity {
        NumberAnimation { duration: settings.motionNormal; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic }
    }

    Behavior on width {
        enabled: settings.motionNormal > 0
        SpringAnimation { spring: 4.0; damping: 0.82; epsilon: 0.2 }
    }

    onTextChanged: {
        if (ready && textPulseOnChange && text.length > 0) {
            textPulse.restart();
        }
    }

    onIconChanged: {
        if (!ready || !iconFadeOnChange) {
            displayedIcon = icon;
            pendingIcon = icon;
            return;
        }

        pendingIcon = icon;
        iconFade.restart();
    }

    onIconPulseActiveChanged: {
        if (!iconPulseActive) {
            iconPulse.stop();
            iconPulseOpacity = 1;
        }
    }

    onPulseAnimationsEnabledChanged: {
        if (!pulseAnimationsEnabled) {
            iconPulse.stop();
            iconPulseOpacity = 1;
        }
    }

    Item {
        id: progressClip

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.border.width
        anchors.topMargin: root.border.width
        anchors.bottomMargin: root.border.width
        width: root.progress >= 0 ? Math.max(0, parent.width - root.border.width * 2) * Math.max(0, Math.min(1, root.progress)) : 0
        opacity: root.progress >= 0 ? 1 : 0
        visible: opacity > 0 || width > 0
        clip: true

        Rectangle {
            id: progressFill

            x: 0
            y: 0
            width: Math.max(0, root.width - root.border.width * 2)
            height: parent.height
            radius: Math.max(0, root.radius - root.border.width)
            color: root.progressColor
            antialiasing: true

            Behavior on color {
                ColorAnimation { duration: settings.motionNormal }
            }
        }

        Behavior on width {
            NumberAnimation { duration: settings.motionNormal; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: settings.motionNormal; easing.type: root.progress >= 0 ? Easing.OutCubic : Easing.InCubic }
        }
    }

    Row {
        id: content

        anchors.centerIn: parent
        height: parent.height
        spacing: (textStack.visible || graphRow.visible) && iconLabel.visible ? root.contentSpacing : 0

        Text {
            id: iconLabel

            visible: root.displayedIcon.length > 0 || root.icon.length > 0
            height: content.height
            text: root.displayedIcon
            color: root.danger || root.urgent ? theme.urgent
                               : root.selected ? root.accentColor
                                             : root.muted ? theme.textMuted : theme.text
            opacity: root.iconFadeOpacity * root.iconPulseOpacity
            font.family: settings.fontFamilyIcon
            font.pixelSize: settings.effectiveIconSize
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            transform: Translate { x: root.iconOpticalOffsetX }

            Behavior on color {
                ColorAnimation { duration: settings.motionNormal }
            }
        }

        Item {
            id: textLabel

            visible: root.shownText.length > 0 || root.shownDetailText.length > 0 || opacity > 0
            width: Math.min(textStack.naturalWidth, root.maximumTextWidth)
            height: content.height
            opacity: root.shownText.length > 0 || root.shownDetailText.length > 0 ? root.textPulseOpacity : 0
            scale: root.shownText.length > 0 || root.shownDetailText.length > 0 ? 1 : 0.96

            Behavior on opacity {
                NumberAnimation { duration: settings.motionNormal; easing.type: opacity > 0 ? Easing.OutCubic : Easing.InCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: settings.motionNormal; easing.type: scale >= 1 ? Easing.OutCubic : Easing.InCubic }
            }

            Column {
                id: textStack

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                readonly property real naturalWidth: Math.max(mainText.implicitWidth, detailLine.implicitWidth)
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))
                visible: root.shownText.length > 0 || root.shownDetailText.length > 0 || opacity > 0
                opacity: root.shownText.length > 0 || root.shownDetailText.length > 0 ? 1 : 0

                Text {
                    id: mainText

                    width: parent.width
                    text: root.shownText
                    color: root.danger || root.urgent ? theme.urgent : root.muted ? theme.textMuted : theme.text
                    font.family: root.textFontFamily(root.shownText)
                    font.pixelSize: root.shownDetailText.length > 0 ? Math.max(9, Math.round(settings.effectiveFontSize * 0.92)) : settings.effectiveFontSize
                    font.weight: root.selected ? Font.DemiBold : Font.Medium
                    elide: Text.ElideRight
                    maximumLineCount: 1

                    Behavior on color {
                        ColorAnimation { duration: settings.motionNormal }
                    }
                }

                Text {
                    id: detailLine

                    width: parent.width
                    visible: root.shownDetailText.length > 0 || opacity > 0
                    text: root.shownDetailText
                    color: root.muted ? theme.alpha(theme.textMuted, 0.72) : theme.textMuted
                    opacity: root.shownDetailText.length > 0 ? 1 : 0
                    font.family: root.textFontFamily(root.shownDetailText)
                    font.pixelSize: Math.max(8, Math.round(settings.effectiveFontSize * 0.72))
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    maximumLineCount: 1

                    Behavior on color {
                        ColorAnimation { duration: settings.motionNormal }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: settings.motionNormal; easing.type: opacity > 0 ? Easing.OutCubic : Easing.InCubic }
                    }
                }
            }
        }

        Row {
            id: graphRow

            visible: root.showGraph && root.graphValues.length > 0
            spacing: Math.max(1, Math.round(settings.effectiveContentSpacing / 3))
            height: Math.max(4, Math.round(settings.moduleHeight * 0.46))

            Repeater {
                model: root.showGraph ? root.graphValues.length : 0

                Item {
                    required property int index

                    readonly property real barValue: Math.max(0.05, Math.min(1, Number(root.graphValues[index]) || 0))

                    width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.65))
                    height: graphRow.height

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Math.max(1, parent.height * parent.barValue)
                        radius: width / 2
                        color: root.graphColor
                        opacity: 0.82
                        antialiasing: true

                        Behavior on height {
                            NumberAnimation { duration: settings.motionFast; easing.type: Easing.OutCubic }
                        }

                        Behavior on color {
                            ColorAnimation { duration: settings.motionNormal }
                        }
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: textPulse

        NumberAnimation {
            target: root
            property: "textPulseOpacity"
            to: root.textPulseMinimumOpacity
            duration: Math.max(0, Math.round(root.textPulseDuration / 2))
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "textPulseOpacity"
            to: 1
            duration: Math.max(0, Math.round(root.textPulseDuration / 2))
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: iconFade

        NumberAnimation {
            target: root
            property: "iconFadeOpacity"
            to: 0
            duration: Math.max(0, Math.round(root.iconFadeDuration / 2))
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: root.displayedIcon = root.pendingIcon
        }

        NumberAnimation {
            target: root
            property: "iconFadeOpacity"
            to: 1
            duration: Math.max(0, Math.round(root.iconFadeDuration / 2))
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: iconPulse

        running: root.iconPulseActive && root.pulseAnimationsEnabled
        loops: Animation.Infinite

        NumberAnimation {
            target: root
            property: "iconPulseOpacity"
            to: root.iconPulseMinimumOpacity
            duration: Math.max(0, Math.round(root.iconPulseDuration / 2))
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "iconPulseOpacity"
            to: 1
            duration: Math.max(0, Math.round(root.iconPulseDuration / 2))
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        acceptedButtons: root.clickable || root.detailsOnClick ? Qt.LeftButton | Qt.RightButton | Qt.MiddleButton : Qt.NoButton
        cursorShape: root.clickable || root.detailsOnClick ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true
        onEntered: {
            if (root.settings.tooltipsEnabled && root.tooltipHost && root.effectiveTooltipText().length > 0)
                tooltipTimer.restart();
        }
        onExited: {
            tooltipTimer.stop();
            if (root.tooltipHost)
                root.tooltipHost.hide(root.effectiveTooltipText());
        }
        onClicked: function(mouse) {
            tooltipTimer.stop();
            if (root.tooltipHost)
                root.tooltipHost.hide(root.effectiveTooltipText());
            if (mouse.button === Qt.RightButton) {
                root.rightClicked(mouse);
            } else if (mouse.button === Qt.MiddleButton) {
                root.middleClicked(mouse);
            } else if (root.detailsOnClick && root.detailsModuleName.length > 0) {
                root.detailsRequested(root, root.detailsModuleName);
            } else {
                root.clicked(mouse);
            }
        }
        onWheel: function(wheel) {
            if (!root.scrollable) return;

            const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
            if (delta === 0) return;

            const steps = Math.max(-1, Math.min(1, Math.round(delta / 120) || (delta > 0 ? 1 : -1)));
            root.scrolled(steps, wheel);
            wheel.accepted = true;
        }
    }

    Timer {
        id: tooltipTimer

        interval: settings.tooltipDelay
        repeat: false
        onTriggered: if (root.settings.tooltipsEnabled && root.tooltipHost) root.tooltipHost.show(root.effectiveTooltipText(), root)
    }

    Component.onCompleted: {
        displayedIcon = icon;
        pendingIcon = icon;
        ready = true;
    }
}
