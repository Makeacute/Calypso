pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import Quickshell.Io
import "widgets"

PopupWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property var anchorItem: null
    property bool panelOpen: false
    property bool panelClosing: false
    property string selectedModule: ""
    property var quickState: ({})
    property var mediaData: ({})
    property var cpuData: ({})
    property var memoryData: ({})
    property var networkData: ({})
    property var batteryData: ({})
    property var cpuHistory: []
    property var memoryHistory: []
    property var networkHistory: []
    property var batteryHistory: []
    property real previousNetworkRx: 0
    property real previousNetworkTx: 0
    property real previousNetworkStamp: 0
    property real networkRxRate: 0
    property real networkTxRate: 0
    property real triggerX: anchoredX()
    property real triggerY: 0
    property real triggerScale: 0.18
    readonly property int panelWidth: settings ? Math.round(Math.min(panelWindow ? panelWindow.width : settings.dashboardPanelWidth, Math.max(settings.effectiveSpacingXL * 16, settings.dashboardPanelWidth))) : 420

    signal processesRequested(var anchorItem)

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\\''") + "'";
    }

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

    function updateTrigger(anchor) {
        anchorItem = anchor || null;

        if (anchorItem && typeof anchorItem.mapToItem === "function") {
            const point = anchorItem.mapToItem(null, 0, 0);
            triggerX = clampedX(point.x + anchorItem.width / 2 - panelWidth / 2);
            triggerY = settings && settings.barPosition === "bottom" ? Math.max(0, dashboardFrame.implicitHeight - anchorItem.height) : 0;
            triggerScale = Math.max(0.10, Math.min(0.42, Math.max(anchorItem.width, anchorItem.height) / Math.max(1, panelWidth)));
        } else {
            triggerX = anchoredX();
            triggerY = 0;
            triggerScale = 0.18;
        }
    }

    function toggle(anchor) {
        if (panelOpen) close();
        else open(anchor);
    }

    function open(anchor) {
        closeTimer.stop();
        updateTrigger(anchor);
        selectedModule = "";
        panelClosing = false;
        refreshAll();
        panelOpen = true;
    }

    function openModule(name, anchor) {
        closeTimer.stop();
        updateTrigger(anchor);
        selectedModule = String(name || "");
        panelClosing = false;
        refreshAll();
        panelOpen = true;
    }

    function close() {
        if (!panelOpen && !panelClosing) return;

        panelClosing = true;
        panelOpen = false;
        closeTimer.restart();
    }

    function configuredList(values, fallback) {
        const source = Array.from(values && values.length !== undefined ? values : fallback || []);
        const next = [];
        const seen = {};
        for (let i = 0; i < source.length; i++) {
            const value = String(source[i] || "").trim();
            if (value.length <= 0 || seen[value]) continue;
            seen[value] = true;
            next.push(value);
        }
        return next;
    }

    function quickToggles() {
        return configuredList(settings ? settings.dashboardQuickToggles : [], ["wifi", "bluetooth", "mic", "dnd"]);
    }

    function performanceModules() {
        return configuredList(settings ? settings.dashboardPerformanceModules : [], ["cpu", "memory", "network", "battery"]);
    }

    function parseKeyValues(text) {
        const data = {};
        const lines = String(text || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const index = lines[i].indexOf("=");
            if (index < 0) continue;
            data[lines[i].slice(0, index).trim()] = lines[i].slice(index + 1).trim();
        }
        return data;
    }

    function boolValue(data, key) {
        const value = String((data || {})[key] || "").toLowerCase();
        return value === "1" || value === "true" || value === "yes" || value === "on" || value === "enabled";
    }

    function numberValue(data, key, fallback) {
        const value = Number((data || {})[key]);
        return Number.isFinite(value) ? value : (fallback || 0);
    }

    function formatBytes(value) {
        const number = Math.max(0, Number(value) || 0);
        if (number < 1024) return Math.round(number) + " B";
        if (number < 1024 * 1024) return Math.round(number / 1024) + " KiB";
        if (number < 1024 * 1024 * 1024) return (Math.round(number / 1024 / 1024 * 10) / 10) + " MiB";
        return (Math.round(number / 1024 / 1024 / 1024 * 10) / 10) + " GiB";
    }

    function formatRate(value) {
        const number = Math.max(0, Number(value) || 0);
        if (number < 1024) return Math.round(number) + "B/s";
        if (number < 1024 * 1024) return Math.round(number / 1024) + "K/s";
        return (Math.round(number / 1024 / 1024 * 10) / 10) + "M/s";
    }

    function formatKib(value) {
        return formatBytes((Number(value) || 0) * 1024);
    }

    function historyLimit() {
        return Math.max(4, Number(settings ? settings.modulePopupHistorySamples : 0) || 24);
    }

    function rememberHistory(current, value) {
        const next = Array.from(current || []);
        next.push(Math.max(0, Math.min(1, Number(value) || 0)));
        while (next.length > historyLimit()) next.shift();
        return next;
    }

    function refreshAll() {
        refreshQuickState();
        refreshMedia();
        refreshCpu();
        refreshMemory();
        refreshNetwork();
        refreshBattery();
    }

    function refreshQuickState() {
        if (quickStateProc.running) return;

        quickStateProc.command = ["sh", "-c", "wifi_available=0; wifi_active=0; if command -v nmcli >/dev/null 2>&1; then wifi_available=1; [ \"$(nmcli -t radio wifi 2>/dev/null)\" = enabled ] && wifi_active=1; fi; bt_available=0; bt_active=0; if command -v bluetoothctl >/dev/null 2>&1; then bt_available=1; bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ { if ($2 == \"yes\") print \"bt_active=1\"; found=1 } END { if (!found) print \"bt_active=0\" }'; fi; mic_available=0; mic_active=0; mic_muted=1; if command -v wpctl >/dev/null 2>&1; then mic_available=1; mic=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true); printf '%s' \"$mic\" | grep -q '\\[MUTED\\]' || { mic_active=1; mic_muted=0; }; fi; dnd_available=0; dnd_active=0; if command -v makoctl >/dev/null 2>&1 || command -v swaync-client >/dev/null 2>&1 || command -v dunstctl >/dev/null 2>&1; then dnd_available=1; fi; printf 'wifi_available=%s\\nwifi_active=%s\\nbt_available=%s\\nmic_available=%s\\nmic_active=%s\\nmic_muted=%s\\ndnd_available=%s\\ndnd_active=%s\\n' \"$wifi_available\" \"$wifi_active\" \"$bt_available\" \"$mic_available\" \"$mic_active\" \"$mic_muted\" \"$dnd_available\" \"$dnd_active\""];
        quickStateProc.running = true;
    }

    function refreshMedia() {
        if (!settings || !settings.dashboardShowMedia || mediaProc.running) return;

        mediaProc.command = ["sh", "-c", "if ! command -v playerctl >/dev/null 2>&1; then printf 'available=0\\n'; exit 0; fi; if ! playerctl status >/dev/null 2>&1; then printf 'available=0\\n'; exit 0; fi; playerctl metadata --format 'available=1\\nplayer={{playerName}}\\nstatus={{status}}\\ntitle={{title}}\\nartist={{artist}}\\nalbum={{album}}\\nart={{mpris:artUrl}}\\nlength={{mpris:length}}' 2>/dev/null || printf 'available=0\\n'; printf 'position=%s\\n' \"$(playerctl position 2>/dev/null || echo 0)\""];
        mediaProc.running = true;
    }

    function refreshCpu() {
        if (cpuProc.running) return;
        cpuProc.command = ["sh", "-c", "read _ u n s i io irq sirq st rest < /proc/stat; total=$((u+n+s+i+io+irq+sirq+st)); idle=$((i+io)); sleep 0.12; read _ u2 n2 s2 i2 io2 irq2 sirq2 st2 rest < /proc/stat; total2=$((u2+n2+s2+i2+io2+irq2+sirq2+st2)); idle2=$((i2+io2)); dt=$((total2-total)); di=$((idle2-idle)); usage=0; [ \"$dt\" -gt 0 ] && usage=$((100*(dt-di)/dt)); read l1 l2 l3 rest < /proc/loadavg; printf 'usage=%s\\ncores=%s\\nload=%s %s %s\\n' \"$usage\" \"$(nproc)\" \"$l1\" \"$l2\" \"$l3\""];
        cpuProc.running = true;
    }

    function refreshMemory() {
        if (memoryProc.running) return;
        memoryProc.command = ["sh", "-c", "mt=$(awk '/MemTotal:/ {print $2}' /proc/meminfo); ma=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo); mu=$((mt-ma)); mp=0; [ \"$mt\" -gt 0 ] && mp=$((100*mu/mt)); printf 'mem_total=%s\\nmem_available=%s\\nmem_used=%s\\nmem_percent=%s\\n' \"$mt\" \"$ma\" \"$mu\" \"$mp\""];
        memoryProc.running = true;
    }

    function refreshNetwork() {
        if (networkProc.running) return;

        const requested = String(settings ? settings.networkInterfaceName : "").trim();
        const prefix = requested.length > 0 ? "dev=" + shellQuote(requested) : "dev=$(ip -o route get 1.1.1.1 2>/dev/null | sed -n 's/.* dev \\([^ ]*\\).*/\\1/p' | head -1)";
        networkProc.command = ["sh", "-c", prefix + "; if [ -z \"$dev\" ] || [ ! -d \"/sys/class/net/$dev\" ]; then printf 'online=0\\n'; exit 0; fi; rx=$(cat \"/sys/class/net/$dev/statistics/rx_bytes\" 2>/dev/null || echo 0); tx=$(cat \"/sys/class/net/$dev/statistics/tx_bytes\" 2>/dev/null || echo 0); state=$(cat \"/sys/class/net/$dev/operstate\" 2>/dev/null || echo unknown); printf 'online=1\\ndevice=%s\\nstate=%s\\nrx=%s\\ntx=%s\\n' \"$dev\" \"$state\" \"$rx\" \"$tx\""];
        networkProc.running = true;
    }

    function refreshBattery() {
        if (batteryProc.running) return;
        batteryProc.command = ["sh", "-c", "bat=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' | head -1); if [ -z \"$bat\" ]; then printf 'present=0\\n'; exit 0; fi; printf 'present=1\\n'; for f in status capacity power_now energy_now energy_full cycle_count; do [ -r \"$bat/$f\" ] && printf '%s=%s\\n' \"$f\" \"$(cat \"$bat/$f\")\"; done"];
        batteryProc.running = true;
    }

    function updateNetwork(data) {
        const rx = Number(data.rx) || 0;
        const tx = Number(data.tx) || 0;
        const now = Date.now();
        if (previousNetworkStamp > 0 && now > previousNetworkStamp && rx >= previousNetworkRx && tx >= previousNetworkTx) {
            const seconds = Math.max(0.001, (now - previousNetworkStamp) / 1000);
            networkRxRate = (rx - previousNetworkRx) / seconds;
            networkTxRate = (tx - previousNetworkTx) / seconds;
        }
        previousNetworkRx = rx;
        previousNetworkTx = tx;
        previousNetworkStamp = now;
        networkData = data;
        const scale = Math.max(1024, (Number(settings ? settings.modulePopupNetworkScaleKib : 0) || 10240) * 1024);
        networkHistory = rememberHistory(networkHistory, Math.min(1, (networkRxRate + networkTxRate) / scale));
    }

    function mediaProgress() {
        const length = numberValue(mediaData, "length", 0);
        const position = numberValue(mediaData, "position", 0) * 1000000;
        return length > 0 ? Math.max(0, Math.min(1, position / length)) : 0;
    }

    function mediaArtSource() {
        const art = String(mediaData.art || "").trim();
        if (art.length <= 0) return "";
        if (art.indexOf("://") >= 0) return art;
        return "file://" + art;
    }

    function runAction(command, refreshTarget) {
        if (actionProc.running) return;
        actionProc.command = ["sh", "-c", command];
        actionProc.refreshTarget = refreshTarget || "";
        actionProc.running = true;
    }

    function toggleQuick(kind) {
        if (kind === "wifi" && boolValue(quickState, "wifi_available")) {
            runAction("nmcli radio wifi " + (boolValue(quickState, "wifi_active") ? "off" : "on"), "quick");
        } else if (kind === "bluetooth" && boolValue(quickState, "bt_available")) {
            runAction("bluetoothctl power " + (boolValue(quickState, "bt_active") ? "off" : "on"), "quick");
        } else if (kind === "mic" && boolValue(quickState, "mic_available")) {
            runAction("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", "quick");
        }
    }

    function mediaAction(action) {
        if (!boolValue(mediaData, "available")) return;
        runAction("playerctl " + action + " >/dev/null 2>&1 || true", "media");
    }

    function seekMedia(ratio) {
        const length = numberValue(mediaData, "length", 0);
        if (!boolValue(mediaData, "available") || length <= 0) return;
        const seconds = Math.max(0, Math.min(length / 1000000, ratio * length / 1000000));
        runAction("playerctl position " + Math.round(seconds * 1000) / 1000 + " >/dev/null 2>&1 || true", "media");
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -dashboardFrame.height - settings.settingsPanelGap : panelWindow.height + settings.settingsPanelGap) : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: dashboardFrame.height
    visible: panelOpen || panelClosing
    grabFocus: anchorItem !== null
    color: "transparent"

    Timer {
        id: closeTimer

        interval: root.settings ? Math.max(1, root.settings.motionClose) : 1
        repeat: false
        onTriggered: root.panelClosing = false
    }

    Timer { interval: settings ? settings.dashboardStatePollMs : 5000; running: root.panelOpen; repeat: true; onTriggered: root.refreshQuickState() }
    Timer { interval: settings ? settings.dashboardMediaPollMs : 500; running: root.panelOpen && settings.dashboardShowMedia; repeat: true; onTriggered: root.refreshMedia() }
    Timer { interval: settings ? settings.cpuPollMs : 30000; running: root.panelOpen; repeat: true; onTriggered: root.refreshCpu() }
    Timer { interval: settings ? settings.memoryPollMs : 5000; running: root.panelOpen; repeat: true; onTriggered: root.refreshMemory() }
    Timer { interval: settings ? settings.networkPollMs : 5000; running: root.panelOpen; repeat: true; onTriggered: root.refreshNetwork() }
    Timer { interval: settings ? settings.batteryFallbackPollMs : 30000; running: root.panelOpen; repeat: true; onTriggered: root.refreshBattery() }

    Process {
        id: quickStateProc
        stdout: StdioCollector { onStreamFinished: root.quickState = root.parseKeyValues(text) }
        stderr: StdioCollector {}
    }

    Process {
        id: mediaProc
        stdout: StdioCollector { onStreamFinished: root.mediaData = root.parseKeyValues(text) }
        stderr: StdioCollector {}
    }

    Process {
        id: cpuProc
        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.parseKeyValues(text);
                root.cpuData = data;
                root.cpuHistory = root.rememberHistory(root.cpuHistory, root.numberValue(data, "usage", 0) / 100);
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: memoryProc
        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.parseKeyValues(text);
                root.memoryData = data;
                root.memoryHistory = root.rememberHistory(root.memoryHistory, root.numberValue(data, "mem_percent", 0) / 100);
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: networkProc
        stdout: StdioCollector { onStreamFinished: root.updateNetwork(root.parseKeyValues(text)) }
        stderr: StdioCollector {}
    }

    Process {
        id: batteryProc
        stdout: StdioCollector {
            onStreamFinished: {
                const data = root.parseKeyValues(text);
                root.batteryData = data;
                root.batteryHistory = root.rememberHistory(root.batteryHistory, root.numberValue(data, "capacity", 0) / 100);
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: actionProc

        property string refreshTarget: ""

        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            if (refreshTarget === "media") root.refreshMedia();
            else if (refreshTarget === "quick") root.refreshQuickState();
            refreshTarget = "";
        }
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
        id: dashboardFrame

        x: settings && settings.dashboardGrowFromTrigger ? (root.panelOpen ? root.anchoredX() : root.triggerX) : root.anchoredX()
        y: settings && settings.dashboardGrowFromTrigger ? (root.panelOpen ? 0 : root.triggerY) : 0
        width: root.panelWidth
        implicitHeight: dashboardColumn.implicitHeight + settings.panelPadding * 2
        height: implicitHeight
        scale: settings && settings.dashboardGrowFromTrigger ? (root.panelOpen ? 1 : root.triggerScale) : 1
        transformOrigin: Item.TopLeft
        theme: root.theme
        settings: root.settings
        surfaceColor: theme.alpha(theme.surfaceContainerHigh, settings.panelOpacity / 100)
        outlineColor: theme.outlineSubtle
        outlineWidth: settings.effectiveBorderWidth
        surfaceRadius: settings.panelRadius
        clip: true
        opacity: root.panelOpen ? 1 : 0

        Behavior on x { NumberAnimation { duration: settings.motionOpen; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: settings.motionOpen; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: settings.motionOpen; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: root.panelOpen ? settings.motionOpen : settings.motionClose; easing.type: root.panelOpen ? Easing.OutCubic : Easing.InCubic } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: function(mouse) { mouse.accepted = true; }
            onWheel: function(wheel) { wheel.accepted = true; }
        }

        Column {
            id: dashboardColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: settings.panelPadding
            spacing: settings.effectiveContentSpacing

            Flow {
                width: parent.width
                spacing: settings.effectiveContentSpacing

                Repeater {
                    model: root.quickToggles()

                    QuickTogglePill {
                        required property var modelData

                        width: (parent.width - parent.spacing * 3) / 4
                        theme: root.theme
                        settings: root.settings
                        kind: String(modelData)
                        active: root.toggleActive(String(modelData))
                        available: root.toggleAvailable(String(modelData))
                        onPressed: root.toggleQuick(kind)
                    }
                }
            }

            MediaPanel {
                visible: settings.dashboardShowMedia
                width: parent.width
                theme: root.theme
                settings: root.settings
            }

            Rectangle {
                visible: settings.dashboardShowWeather
                width: parent.width
                implicitHeight: settings.controlHeight * 1.65
                radius: settings.effectivePillRadius
                color: theme.alpha(theme.surfaceContainer, 0.42)
                border.color: theme.outlineSubtle
                border.width: settings.effectiveBorderWidth
                antialiasing: true
                clip: true

                Row {
                    anchors.fill: parent
                    anchors.margins: settings.effectiveContentSpacing
                    spacing: settings.effectiveContentSpacing

                    Text {
                        width: settings.controlHeight
                        height: parent.height
                        text: "󰖐"
                        color: theme.textMuted
                        font.family: settings.fontFamilyIcon
                        font.pixelSize: settings.effectiveIconSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Column {
                        width: parent.width - settings.controlHeight - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                        Text {
                            width: parent.width
                            text: "Weather unavailable"
                            color: theme.text
                            elide: Text.ElideRight
                            font.family: settings.fontFamilySans
                            font.pixelSize: settings.effectiveFontSize
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            text: "No weather source configured"
                            color: theme.textMuted
                            elide: Text.ElideRight
                            font.family: settings.fontFamilySans
                            font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: settings.effectiveContentSpacing

                Repeater {
                    model: root.performanceModules()

                    PerformanceRow {
                        required property var modelData

                        width: parent.width
                        theme: root.theme
                        settings: root.settings
                        moduleName: String(modelData)
                        selected: root.selectedModule === moduleName
                        onPressed: function(anchorItem) {
                            if (moduleName === "cpu") root.processesRequested(anchorItem);
                            else root.selectedModule = moduleName;
                        }
                    }
                }
            }
        }
    }

    function toggleAvailable(kind) {
        if (kind === "wifi") return boolValue(quickState, "wifi_available");
        if (kind === "bluetooth") return boolValue(quickState, "bt_available");
        if (kind === "mic") return boolValue(quickState, "mic_available");
        if (kind === "dnd") return boolValue(quickState, "dnd_available");
        return false;
    }

    function toggleActive(kind) {
        if (kind === "wifi") return boolValue(quickState, "wifi_active");
        if (kind === "bluetooth") return boolValue(quickState, "bt_active");
        if (kind === "mic") return boolValue(quickState, "mic_active");
        if (kind === "dnd") return boolValue(quickState, "dnd_active");
        return false;
    }

    function toggleLabel(kind) {
        if (kind === "wifi") return "Wi-Fi";
        if (kind === "bluetooth") return "BT";
        if (kind === "mic") return "Mic";
        if (kind === "dnd") return "DND";
        return kind;
    }

    function toggleIcon(kind) {
        if (kind === "wifi") return "󰤨";
        if (kind === "bluetooth") return "󰂯";
        if (kind === "mic") return "󰍬";
        if (kind === "dnd") return "󰂛";
        return "󰒓";
    }

    function metricData(name) {
        if (name === "cpu") return cpuData;
        if (name === "memory") return memoryData;
        if (name === "network") return networkData;
        if (name === "battery") return batteryData;
        return {};
    }

    function metricProgress(name) {
        if (name === "cpu") return numberValue(cpuData, "usage", 0) / 100;
        if (name === "memory") return numberValue(memoryData, "mem_percent", 0) / 100;
        if (name === "network") {
            const scale = Math.max(1024, (Number(settings ? settings.modulePopupNetworkScaleKib : 0) || 10240) * 1024);
            return Math.min(1, (networkRxRate + networkTxRate) / scale);
        }
        if (name === "battery") return numberValue(batteryData, "capacity", 0) / 100;
        return 0;
    }

    function metricHistory(name) {
        if (name === "cpu") return cpuHistory;
        if (name === "memory") return memoryHistory;
        if (name === "network") return networkHistory;
        if (name === "battery") return batteryHistory;
        return [];
    }

    function metricTitle(name) {
        return settings ? settings.moduleLabel(name) : name;
    }

    function metricValue(name) {
        if (name === "cpu") return Math.round(numberValue(cpuData, "usage", 0)) + "%";
        if (name === "memory") return Math.round(numberValue(memoryData, "mem_percent", 0)) + "%";
        if (name === "network") return boolValue(networkData, "online") ? formatRate(networkRxRate + networkTxRate) : "offline";
        if (name === "battery") return boolValue(batteryData, "present") ? Math.round(numberValue(batteryData, "capacity", 0)) + "%" : "none";
        return "";
    }

    function metricDetail(name) {
        if (name === "cpu") return numberValue(cpuData, "cores", 0) + " cores / " + String(cpuData.load || "load pending");
        if (name === "memory") return formatKib(numberValue(memoryData, "mem_used", 0)) + " of " + formatKib(numberValue(memoryData, "mem_total", 0));
        if (name === "network") return boolValue(networkData, "online") ? String(networkData.device || "net") + " / down " + formatRate(networkRxRate) + " up " + formatRate(networkTxRate) : "No route";
        if (name === "battery") return String(batteryData.status || "Battery");
        return "";
    }

    function metricAccent(name) {
        const progress = metricProgress(name);
        if (name === "battery") {
            const capacity = numberValue(batteryData, "capacity", 0);
            if (capacity > 0 && capacity <= settings.batteryCriticalThreshold) return theme.error;
            if (capacity > 0 && capacity <= settings.batteryCriticalThreshold * 2) return theme.warning;
            return theme.primary;
        }
        if (progress >= 0.9) return theme.error;
        if (progress >= 0.72) return theme.warning;
        return theme.primary;
    }

    component QuickTogglePill: Rectangle {
        id: toggle

        property var theme
        property var settings
        property string kind: ""
        property bool active: false
        property bool available: false

        signal pressed(var anchorItem)

        implicitHeight: settings.controlHeight
        radius: settings.effectivePillRadius
        color: active ? theme.primary : hover.containsMouse && available ? theme.surfaceHover : theme.alpha(theme.surfaceContainer, 0.50)
        border.color: active ? theme.alpha(theme.primary, 0.60) : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        opacity: available ? 1 : 0.42
        antialiasing: true
        clip: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Row {
            anchors.centerIn: parent
            width: parent.width - settings.effectiveContentSpacing * 2
            height: parent.height
            spacing: Math.max(1, settings.effectiveContentSpacing)

            Text {
                width: settings.effectiveIconSize
                height: parent.height
                text: root.toggleIcon(toggle.kind)
                color: toggle.active ? theme.surface : theme.text
                font.family: settings.fontFamilyIcon
                font.pixelSize: settings.effectiveIconSize
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                width: parent.width - settings.effectiveIconSize - parent.spacing
                height: parent.height
                text: root.toggleLabel(toggle.kind)
                color: toggle.active ? theme.surface : theme.text
                elide: Text.ElideRight
                font.family: settings.fontFamilySans
                font.pixelSize: settings.effectiveFontSize
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
            enabled: toggle.available
            cursorShape: Qt.PointingHandCursor
            onClicked: toggle.pressed()
        }
    }

    component MediaPanel: Rectangle {
        id: mediaPanel

        property var theme
        property var settings
        readonly property bool available: root.boolValue(root.mediaData, "available")
        readonly property bool playing: String(root.mediaData.status || "") === "Playing"

        implicitHeight: Math.max(settings.controlHeight * 3.25, mediaContent.implicitHeight + settings.effectivePillPadding * 2)
        radius: settings.effectivePillRadius
        color: theme.alpha(theme.surfaceContainer, 0.52)
        border.color: theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        clip: true

        Row {
            id: mediaContent

            x: settings.effectivePillPadding
            y: settings.effectivePillPadding
            width: parent.width - settings.effectivePillPadding * 2
            spacing: settings.effectivePillPadding

            Rectangle {
                width: settings.controlHeight * 2.35
                height: width
                radius: settings.effectivePillRadius
                color: theme.alpha(theme.primary, 0.14)
                border.color: theme.outlineSubtle
                border.width: settings.effectiveBorderWidth
                antialiasing: true
                clip: true

                Image {
                    anchors.fill: parent
                    visible: source.toString().length > 0
                    source: root.mediaArtSource()
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.mediaArtSource().length <= 0
                    text: mediaPanel.available ? "󰝚" : "󰎊"
                    color: mediaPanel.available ? theme.primary : theme.textMuted
                    font.family: settings.fontFamilyIcon
                    font.pixelSize: settings.effectiveIconSize * 1.35
                }
            }

            Column {
                width: parent.width - parent.spacing - settings.controlHeight * 2.35
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.7))

                Text {
                    width: parent.width
                    text: mediaPanel.available ? String(root.mediaData.title || root.mediaData.player || "Media") : "No active player"
                    color: theme.text
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: mediaPanel.available ? String(root.mediaData.artist || root.mediaData.album || root.mediaData.player || "") : ""
                    color: theme.textMuted
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                }

                Row {
                    width: parent.width
                    height: settings.controlHeight
                    spacing: settings.effectiveContentSpacing

                    IconButton { theme: root.theme; settings: root.settings; icon: ""; enabled: mediaPanel.available; onPressed: root.mediaAction("previous") }
                    IconButton { theme: root.theme; settings: root.settings; icon: mediaPanel.playing ? "" : ""; enabled: mediaPanel.available; selected: mediaPanel.playing; onPressed: root.mediaAction("play-pause") }
                    IconButton { theme: root.theme; settings: root.settings; icon: ""; enabled: mediaPanel.available; onPressed: root.mediaAction("next") }
                    Scrubber {
                        width: parent.width - settings.controlHeight * 3 - parent.spacing * 3
                        height: parent.height
                        theme: root.theme
                        settings: root.settings
                        value: root.mediaProgress()
                        enabled: mediaPanel.available && root.numberValue(root.mediaData, "length", 0) > 0
                        onSeekRequested: function(value) { root.seekMedia(value); }
                    }
                }
            }
        }
    }

    component PerformanceRow: Rectangle {
        id: row

        property var theme
        property var settings
        property string moduleName: ""
        property bool selected: false

        signal pressed()

        implicitHeight: settings.controlHeight * 1.85
        radius: settings.effectivePillRadius
        color: selected ? theme.surfaceActive : hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceContainer, 0.42)
        border.color: selected ? theme.outlineActive : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        antialiasing: true
        clip: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

        Row {
            anchors.fill: parent
            anchors.margins: settings.effectiveContentSpacing
            spacing: settings.effectiveContentSpacing

            MiniGauge {
                width: parent.height
                height: parent.height
                theme: row.theme
                settings: row.settings
                value: root.metricProgress(row.moduleName)
                accentColor: root.metricAccent(row.moduleName)
                icon: settings.moduleIcon(row.moduleName)
            }

            Column {
                width: parent.width - parent.height - valueColumn.width - parent.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                Text {
                    width: parent.width
                    text: root.metricTitle(row.moduleName)
                    color: theme.text
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: root.metricDetail(row.moduleName)
                    color: theme.textMuted
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                }
            }

            Column {
                id: valueColumn

                width: settings.effectiveSpacingXL * 3.2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

                Text {
                    width: parent.width
                    text: root.metricValue(row.moduleName)
                    color: root.metricAccent(row.moduleName)
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    font.family: settings.fontFamilyMono
                    font.pixelSize: Math.round(settings.effectiveFontSize * 1.05)
                    font.weight: Font.Bold
                }

                Sparkline {
                    width: parent.width
                    height: settings.effectiveGroupPadding * 2
                    theme: row.theme
                    settings: row.settings
                    values: root.metricHistory(row.moduleName)
                    accentColor: root.metricAccent(row.moduleName)
                }
            }
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.pressed(row)
        }
    }

    component MiniGauge: Item {
        id: gauge

        property var theme
        property var settings
        property real value: 0
        property color accentColor: theme.primary
        property string icon: ""
        readonly property real clampedValue: Math.max(0, Math.min(1, Number(value) || 0))

        Canvas {
            id: gaugeCanvas

            anchors.fill: parent
            antialiasing: true
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (!gauge.theme || !gauge.settings || width <= 0 || height <= 0) return;

                const line = Math.max(gauge.settings.effectiveBorderWidth, Math.round(Math.min(width, height) * 0.12));
                const radius = Math.max(0, Math.min(width, height) / 2 - line / 2 - gauge.settings.effectiveBorderWidth);
                const start = -Math.PI * 0.72;
                const span = Math.PI * 1.44;
                ctx.lineWidth = line;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, radius, start, start + span, false);
                ctx.strokeStyle = gauge.theme.alpha(gauge.theme.outlineVariant, 0.65);
                ctx.stroke();
                if (gauge.clampedValue > 0.001) {
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, radius, start, start + span * gauge.clampedValue, false);
                    ctx.strokeStyle = gauge.accentColor;
                    ctx.stroke();
                }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: gauge
                function onClampedValueChanged() { gaugeCanvas.requestPaint(); }
                function onAccentColorChanged() { gaugeCanvas.requestPaint(); }
            }
        }

        Text {
            anchors.centerIn: parent
            text: gauge.icon
            color: gauge.accentColor
            font.family: settings.fontFamilyIcon
            font.pixelSize: Math.max(8, Math.round(settings.effectiveIconSize * 0.68))
        }
    }

    component Sparkline: Canvas {
        id: spark

        property var theme
        property var settings
        property var values: []
        property color accentColor: theme.primary

        antialiasing: true
        opacity: values.length > 1 ? 1 : 0
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const samples = Array.from(values || []);
            if (!theme || !settings || width <= 0 || height <= 0 || samples.length <= 1) return;

            const pad = Math.max(1, settings.effectiveBorderWidth);
            ctx.lineWidth = Math.max(1, settings.effectiveBorderWidth);
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            for (let i = 0; i < samples.length; i++) {
                const x = pad + (samples.length <= 1 ? 0 : i / (samples.length - 1)) * Math.max(1, width - pad * 2);
                const y = pad + (1 - Math.max(0, Math.min(1, Number(samples[i]) || 0))) * Math.max(1, height - pad * 2);
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.strokeStyle = spark.accentColor;
            ctx.stroke();
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onValuesChanged: requestPaint()
        onAccentColorChanged: requestPaint()
    }

    component IconButton: Rectangle {
        id: button

        property var theme
        property var settings
        property string icon: ""
        property bool selected: false

        signal pressed()

        width: settings.controlHeight
        height: settings.controlHeight
        radius: settings.effectivePillRadius
        color: selected ? theme.primary : hover.containsMouse ? theme.surfaceHover : theme.alpha(theme.surfaceContainerHigh, 0.34)
        border.color: selected ? theme.alpha(theme.primary, 0.55) : theme.outlineSubtle
        border.width: settings.effectiveBorderWidth
        opacity: enabled ? 1 : 0.35
        antialiasing: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }

        Text {
            anchors.centerIn: parent
            text: button.icon
            color: selected ? theme.surface : theme.text
            font.family: settings.fontFamilyIcon
            font.pixelSize: settings.effectiveIconSize
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.pressed()
        }
    }

    component Scrubber: Rectangle {
        id: scrubber

        property var theme
        property var settings
        property real value: 0

        signal seekRequested(real value)

        radius: height / 2
        color: theme.alpha(theme.outlineVariant, 0.42)
        opacity: enabled ? 1 : 0.38
        antialiasing: true

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, scrubber.value))
            height: parent.height
            radius: parent.radius
            color: theme.primary
            antialiasing: true
            Behavior on width { NumberAnimation { duration: settings.motionFast; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: scrubber.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function commit(mouseX) {
                scrubber.seekRequested(Math.max(0, Math.min(1, mouseX / Math.max(1, width))));
            }

            onPressed: function(mouse) { commit(mouse.x); }
            onPositionChanged: function(mouse) { if (pressed) commit(mouse.x); }
        }
    }
}
