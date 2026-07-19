import Quickshell
import QtQuick

PopupWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property var anchorItem: null
    property int panelWidth: settings ? settings.settingsPanelWidth : 380
    property bool panelOpen: false
    property bool panelClosing: false
    property date now: new Date()
    property int viewedMonth: now.getMonth()
    property int viewedYear: now.getFullYear()
    property date selectedDate: new Date(now.getFullYear(), now.getMonth(), now.getDate())
    property real monthOpacity: 1

    function clampedX(value) {
        const maxX = panelWindow ? Math.max(0, panelWindow.width - panelWidth) : 0;
        return Math.max(0, Math.min(maxX, value));
    }

    function anchoredX() {
        if (anchorItem && typeof anchorItem.mapToItem === "function") {
            const point = anchorItem.mapToItem(null, 0, 0);
            return clampedX(point.x + anchorItem.width / 2 - panelWidth / 2);
        }

        return panelWindow ? clampedX(panelWindow.width - panelWidth) : 0;
    }

    function toggle(anchor) {
        if (panelOpen) {
            close();
        } else {
            open(anchor);
        }
    }

    function open(anchor) {
        closeTimer.stop();
        anchorItem = anchor || null;
        now = new Date();
        panelClosing = false;
        panelOpen = true;
    }

    function close() {
        if (!panelOpen && !panelClosing) return;

        panelClosing = true;
        panelOpen = false;
        closeTimer.restart();
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    function monthTitle() {
        return Qt.formatDateTime(new Date(viewedYear, viewedMonth, 1), "MMMM yyyy");
    }

    function selectedTitle() {
        return Qt.formatDateTime(selectedDate, "dddd, MMMM d");
    }

    function selectedTime() {
        return Qt.formatDateTime(now, settings.clockShowSeconds ? "HH:mm:ss" : "HH:mm");
    }

    function dayOfYear(date) {
        const start = new Date(date.getFullYear(), 0, 0);
        return Math.floor((date - start) / 86400000);
    }

    function weekNumber(date) {
        const target = new Date(date.valueOf());
        const day = (target.getDay() + 6) % 7;
        target.setDate(target.getDate() - day + 3);
        const firstThursday = new Date(target.getFullYear(), 0, 4);
        return 1 + Math.round((target - firstThursday) / 604800000);
    }

    function weekStart() {
        return Math.max(0, Math.min(6, Number(settings.calendarWeekStart) || 0));
    }

    function dayNameModel() {
        const names = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
        const start = weekStart();
        const next = [];

        for (let i = 0; i < 7; i++) {
            next.push(names[(start + i) % 7]);
        }

        return next;
    }

    function daysModel() {
        const first = new Date(viewedYear, viewedMonth, 1);
        const startOffset = (first.getDay() - weekStart() + 7) % 7;
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const days = [];

        for (let i = 0; i < 42; i++) {
            const date = new Date(viewedYear, viewedMonth, 1 - startOffset + i);
            days.push({
                "date": date,
                "day": date.getDate(),
                "inMonth": date.getMonth() === viewedMonth,
                "today": sameDay(date, today),
                "selected": sameDay(date, selectedDate)
            });
        }

        return days;
    }

    function previousMonth() {
        const date = new Date(viewedYear, viewedMonth - 1, 1);
        viewedMonth = date.getMonth();
        viewedYear = date.getFullYear();
    }

    function nextMonth() {
        const date = new Date(viewedYear, viewedMonth + 1, 1);
        viewedMonth = date.getMonth();
        viewedYear = date.getFullYear();
    }

    function returnToToday() {
        const today = new Date();
        viewedMonth = today.getMonth();
        viewedYear = today.getFullYear();
        selectedDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    }

    function availableHeight() {
        const screenHeight = panelWindow && panelWindow.screen && panelWindow.screen.height ? panelWindow.screen.height : 720;
        return Math.max(clockFrame.implicitHeight, screenHeight - settings.barHeight - settings.screenMargin * 3 - settings.settingsPanelGap);
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -clockFrame.implicitHeight - settings.settingsPanelGap : panelWindow.height + settings.settingsPanelGap) : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: availableHeight()
    visible: panelOpen || panelClosing
    grabFocus: anchorItem !== null
    color: "transparent"

    Timer {
        id: closeTimer

        interval: root.settings ? Math.max(1, root.settings.motionClose) : 1
        repeat: false
        onTriggered: root.panelClosing = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.panelOpen
        onTriggered: root.now = new Date()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.panelOpen
        onPressed: function(mouse) {
            root.close();
            mouse.accepted = true;
        }
        onWheel: function(wheel) {
            root.close();
            wheel.accepted = true;
        }
    }

    Surface {
        id: clockFrame

        x: root.anchoredX()
        width: root.panelWidth
        height: content.implicitHeight + settings.panelPadding * 2
        y: root.panelOpen ? 0 : -Math.max(settings.effectiveContentSpacing * 2, settings.effectiveGroupPadding * 2)
        implicitHeight: height
        theme: root.theme
        settings: root.settings
        surfaceColor: theme.alpha(theme.surfacePanel, settings.panelOpacity / 100)
        outlineColor: theme.outlineSubtle
        outlineWidth: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
        surfaceRadius: settings.panelRadius
        clip: true
        opacity: root.panelOpen ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: root.panelOpen ? settings.motionOpen : settings.motionClose
                easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.panelOpen ? settings.motionOpen : settings.motionClose
                easing.type: root.panelOpen ? Easing.OutExpo : Easing.InCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: function(mouse) { mouse.accepted = true; }
            onWheel: function(wheel) { wheel.accepted = true; }
        }

        Column {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: settings.panelPadding
            spacing: settings.panelPadding

            Rectangle {
                width: parent.width
                height: Math.max(settings.controlHeight * 2, todayColumn.implicitHeight + settings.effectivePillPadding * 2)
                radius: settings.panelRadius
                color: theme.surfaceActive
                border.color: theme.outlineActive
                border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
                antialiasing: true

                Column {
                    id: todayColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: settings.effectivePillPadding * 2
                    anchors.rightMargin: settings.effectivePillPadding * 2
                    spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.5))

                    Text {
                        width: parent.width
                        text: root.selectedTime()
                        color: theme.text
                        font.family: settings.fontFamily
                        font.pixelSize: Math.round(settings.effectiveFontSize * 1.9)
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: root.selectedTitle()
                        color: theme.textMuted
                        elide: Text.ElideRight
                        font.family: settings.fontFamily
                        font.pixelSize: settings.effectiveFontSize
                    }
                }
            }

            Row {
                width: parent.width
                height: settings.controlHeight
                spacing: settings.effectiveContentSpacing

                Text {
                    width: parent.width - previousButton.width - todayButton.width - nextButton.width - parent.spacing * 3
                    height: parent.height
                    text: root.monthTitle()
                    color: theme.text
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    font.family: settings.fontFamily
                    font.pixelSize: Math.round(settings.effectiveFontSize * 1.12)
                    font.weight: Font.DemiBold
                }

                PanelIconButton {
                    id: previousButton

                    theme: root.theme
                    settings: root.settings
                    icon: ""
                    onPressed: root.previousMonth()
                }

                PanelIconButton {
                    id: todayButton

                    theme: root.theme
                    settings: root.settings
                    icon: "󰃭"
                    onPressed: root.returnToToday()
                }

                PanelIconButton {
                    id: nextButton

                    theme: root.theme
                    settings: root.settings
                    icon: ""
                    onPressed: root.nextMonth()
                }
            }

            Grid {
                id: dayNameGrid

                width: parent.width
                columns: 7
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.55))

                Repeater {
                    model: root.dayNameModel()

                    Text {
                        width: Math.floor((dayNameGrid.width - dayNameGrid.spacing * 6) / 7)
                        height: settings.controlHeight
                        text: String(modelData)
                        color: theme.accent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: settings.fontFamily
                        font.pixelSize: Math.round(settings.effectiveFontSize * 0.9)
                        font.weight: Font.DemiBold
                    }
                }
            }

    Grid {
                id: dayGrid

                width: parent.width
                columns: 7
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.55))
                opacity: root.monthOpacity
                property int cellSize: Math.floor((width - spacing * 6) / 7)

                Repeater {
                    model: root.daysModel()

                    Rectangle {
                        width: dayGrid.cellSize
                        height: dayGrid.cellSize
                        radius: settings.effectivePillRadius
                        color: modelData.selected ? theme.surfaceActive
                                                  : modelData.today ? theme.alpha(theme.accent, 0.32)
                                                                    : dayHover.containsMouse ? theme.surfaceHover
                                                                                            : theme.transparent
                        border.color: modelData.selected ? theme.outlineActive : theme.transparent
                        border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
                        antialiasing: true
                        scale: dayHover.containsMouse ? 1.012 : 1

                        Behavior on color {
                            ColorAnimation { duration: settings.motionNormal }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: settings.motionNormal }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: String(modelData.day)
                            color: modelData.selected ? theme.text
                                                      : modelData.inMonth ? theme.text
                                                                          : theme.textMuted
                            opacity: modelData.inMonth ? 1 : 0.42
                            font.family: settings.fontFamily
                            font.pixelSize: settings.effectiveFontSize
                            font.weight: modelData.today || modelData.selected ? Font.DemiBold : Font.Medium
                        }

                        MouseArea {
                            id: dayHover

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedDate = modelData.date
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: Math.max(settings.controlHeight, statsRow.implicitHeight + settings.effectivePillPadding)
                visible: settings.clockPanelShowWeek || settings.clockPanelShowDayOfYear || settings.clockPanelShowTimezone
                radius: settings.effectivePillRadius
                color: theme.alpha(theme.text, 0.035)
                border.color: theme.outlineSubtle
                border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
                antialiasing: true

                Row {
                    id: statsRow

                    anchors.centerIn: parent
                    spacing: settings.effectivePillPadding

                    StatText {
                        visible: settings.clockPanelShowWeek
                        theme: root.theme
                        settings: root.settings
                        label: "Week"
                        value: String(root.weekNumber(root.selectedDate))
                    }

                    StatText {
                        visible: settings.clockPanelShowDayOfYear
                        theme: root.theme
                        settings: root.settings
                        label: "Day"
                        value: String(root.dayOfYear(root.selectedDate))
                    }

                    StatText {
                        visible: settings.clockPanelShowTimezone
                        theme: root.theme
                        settings: root.settings
                        label: "TZ"
                        value: Qt.formatDateTime(root.now, "t")
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: monthFade

        ScriptAction { script: root.monthOpacity = 0.45 }
        NumberAnimation {
            target: root
            property: "monthOpacity"
            to: 1
            duration: theme.motionNormal
            easing.type: Easing.OutCubic
        }
    }

    onViewedMonthChanged: monthFade.restart()
    onViewedYearChanged: monthFade.restart()

    component PanelIconButton: Rectangle {
        id: button

        property var theme
        property var settings
        property string icon: ""

        signal pressed()

        width: settings.controlHeight
        height: settings.controlHeight
        radius: settings.effectivePillRadius
        color: hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.text, 0.035)
        border.color: hover.containsMouse ? theme.outlineActive : theme.outlineSubtle
        border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
        antialiasing: true
        scale: hover.containsMouse ? 1.012 : 1

        Behavior on color {
            ColorAnimation { duration: settings.motionNormal }
        }

        Behavior on border.color {
            ColorAnimation { duration: settings.motionNormal }
        }

        Behavior on scale {
            NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            text: button.icon
            color: theme.text
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveIconSize
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.pressed()
        }
    }

    component StatText: Column {
        property var theme
        property var settings
        property string label: ""
        property string value: ""

        spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.4))

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: label
            color: theme.textMuted
            font.family: settings.fontFamily
            font.pixelSize: Math.round(settings.effectiveFontSize * 0.82)
            font.weight: Font.Medium
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: value
            color: theme.text
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.DemiBold
        }
    }
}
