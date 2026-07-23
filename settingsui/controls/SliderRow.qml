import QtQuick

Item {
    id: root

    property var theme
    property var settings
    property string label: ""
    property string description: ""
    property real value: minimum
    property real minimum: 0
    property real maximum: 1
    property real step: 1
    property string suffix: ""
    property int decimals: 0
    property real pendingValue: value
    readonly property real span: Math.max(Number.EPSILON, maximum - minimum)
    signal valueRequested(real value)

    implicitHeight: Math.max(labels.implicitHeight, sliderArea.implicitHeight)
    opacity: enabled ? theme.settingsEnabledOpacity : theme.settingsDisabledOpacity

    onValueChanged: {
        if (!pointer.pressed)
            pendingValue = value;
    }

    Column {
        id: labels

        anchors.left: parent.left
        anchors.right: sliderArea.left
        anchors.rightMargin: theme.spacingL
        anchors.verticalCenter: parent.verticalCenter
        spacing: theme.spacingXS

        Text {
            width: parent.width
            text: root.label
            color: theme.text
            wrapMode: Text.Wrap
            font.family: settings.fontFamilySans
            font.pixelSize: theme.settingsBodyFontSize
        }

        Text {
            width: parent.width
            visible: root.description.length > 0
            text: root.description
            color: theme.textMuted
            wrapMode: Text.Wrap
            font.family: settings.fontFamilySans
            font.pixelSize: theme.settingsCaptionFontSize
        }
    }

    Item {
        id: sliderArea

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: theme.settingsSliderWidth
        implicitHeight: theme.settingsRowMinHeight

        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            text: Number(root.pendingValue).toFixed(root.decimals) + root.suffix
            color: theme.text
            font.family: settings.fontFamilyMono
            font.pixelSize: theme.settingsCaptionFontSize
        }

        Rectangle {
            id: track

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: theme.settingsSliderTrackHeight
            radius: theme.settingsSliderTrackRadius
            color: theme.surfaceMuted

            Rectangle {
                width: Math.max(theme.settingsSliderTrackHeight, parent.width * (root.pendingValue - root.minimum) / root.span)
                height: parent.height
                radius: parent.radius
                color: theme.accent
            }

            Rectangle {
                x: Math.max(0, Math.min(parent.width - width, parent.width * (root.pendingValue - root.minimum) / root.span - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                width: theme.settingsSliderHandleSize
                height: width
                radius: theme.settingsSliderHandleRadius
                color: theme.controlKnob
                border.color: theme.accent
                border.width: theme.settingsBorderWidth
            }
        }

        MouseArea {
            id: pointer

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: theme.settingsSliderHitHeight
            enabled: root.enabled
            cursorShape: Qt.PointingHandCursor

            function updateValue(mouseX) {
                const raw = root.minimum + Math.max(0, Math.min(1, mouseX / width)) * root.span;
                const snapped = root.step > 0 ? root.minimum + Math.round((raw - root.minimum) / root.step) * root.step : raw;
                root.pendingValue = Math.max(root.minimum, Math.min(root.maximum, snapped));
            }

            onPressed: function (mouse) {
                updateValue(mouse.x);
            }
            onPositionChanged: function (mouse) {
                if (pressed)
                    updateValue(mouse.x);
            }
            onReleased: root.valueRequested(root.pendingValue)
        }
    }
}
