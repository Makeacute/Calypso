pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

PopupWindow {
    id: root

    property var theme
    property var settings
    property var panelWindow
    property var anchorItem: null
    property string moduleName: ""
    property int panelWidth: settings ? Math.round(Math.min(panelWindow ? panelWindow.width : settings.effectiveSpacingXL * 22, Math.max(settings.effectiveSpacingXL * 18, Math.min(settings.settingsPanelWidth, settings.effectiveSpacingXL * 22)))) : 528
    property bool panelOpen: false
    property bool panelClosing: false
    property string activeTab: settings ? settings.modulePopupDefaultTab : "Overview"
    property var sink: Pipewire.defaultAudioSink
    property var detailData: ({})
    property var topRows: []
    property var listRows: []
    property var ipRows: []
    property var cpuHistory: []
    property var memoryHistory: []
    property var networkHistory: []
    property var batteryHistory: []
    property real previousNetworkRx: 0
    property real previousNetworkTx: 0
    property real previousNetworkStamp: 0
    property real networkRxRate: 0
    property real networkTxRate: 0
    property bool pendingRefresh: false
    property string queuedActionCommand: ""
    readonly property bool hasAudio: sink && sink.audio

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\\''") + "'";
    }

    function moduleTitle() {
        return settings && moduleName.length > 0 ? settings.moduleLabel(moduleName) : "Module";
    }

    function moduleSubtitle() {
        if (!settings || moduleName.length <= 0) return "";
        return settings.moduleCategory(moduleName) + " / " + settings.moduleCost(moduleName);
    }

    function clearData() {
        detailData = {};
        topRows = [];
        listRows = [];
        ipRows = [];
    }

    function normalizedTab(tab) {
        const value = String(tab || "Overview").toLowerCase();
        if (value === "controls") return "Controls";
        if (value === "diagnostics") return "Diagnostics";
        return "Overview";
    }

    function textValue(key, fallback) {
        const value = detailData[key];
        if (value === undefined || value === null || String(value).length === 0) return fallback || "";
        return String(value);
    }

    function numberValue(key, fallback) {
        const value = Number(detailData[key]);
        return Number.isFinite(value) ? value : (fallback || 0);
    }

    function boolValue(key) {
        const value = String(detailData[key] || "").toLowerCase();
        return value === "1" || value === "yes" || value === "true" || value === "on";
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

    function moduleHistory(name) {
        if (name === "cpu") return cpuHistory;
        if (name === "memory") return memoryHistory;
        if (name === "network") return networkHistory;
        if (name === "battery") return batteryHistory;
        return [];
    }

    function networkScaleBytes() {
        return Math.max(1024, (Number(settings ? settings.modulePopupNetworkScaleKib : 0) || 10240) * 1024);
    }

    function networkTotalRate() {
        return Math.max(0, networkRxRate + networkTxRate);
    }

    function networkProgress() {
        return Math.max(0, Math.min(1, networkTotalRate() / networkScaleBytes()));
    }

    function networkRateText() {
        if (!boolValue("online")) return "offline";
        const total = networkTotalRate();
        if (total <= 0) return root.textValue("device", "online");
        return formatBytes(total) + "/s";
    }

    function rememberDetailSample(data) {
        const name = String((data && data.module) || moduleName);

        if (name === "cpu") {
            cpuHistory = rememberHistory(cpuHistory, (Number(data.usage) || 0) / 100);
        } else if (name === "memory") {
            memoryHistory = rememberHistory(memoryHistory, (Number(data.mem_percent) || 0) / 100);
        } else if (name === "battery") {
            batteryHistory = rememberHistory(batteryHistory, (Number(data.capacity) || 0) / 100);
        } else if (name === "network") {
            const rx = Number(data.rx) || 0;
            const tx = Number(data.tx) || 0;
            const now = Date.now();

            if (previousNetworkStamp > 0 && now > previousNetworkStamp && rx >= previousNetworkRx && tx >= previousNetworkTx) {
                const seconds = Math.max(0.001, (now - previousNetworkStamp) / 1000);
                networkRxRate = (rx - previousNetworkRx) / seconds;
                networkTxRate = (tx - previousNetworkTx) / seconds;
            } else if (String(data.online || "").toLowerCase() !== "1" && String(data.online || "").toLowerCase() !== "true") {
                networkRxRate = 0;
                networkTxRate = 0;
            }

            previousNetworkRx = rx;
            previousNetworkTx = tx;
            previousNetworkStamp = now;
            networkHistory = rememberHistory(networkHistory, networkProgress());
        }
    }

    function formatBytes(value) {
        const number = Math.max(0, Number(value) || 0);
        if (number < 1024) return Math.round(number) + " B";
        if (number < 1024 * 1024) return Math.round(number / 1024) + " KiB";
        if (number < 1024 * 1024 * 1024) return (Math.round(number / 1024 / 1024 * 10) / 10) + " MiB";
        return (Math.round(number / 1024 / 1024 / 1024 * 10) / 10) + " GiB";
    }

    function formatKib(value) {
        return formatBytes((Number(value) || 0) * 1024);
    }

    function formatMicro(value, suffix) {
        const number = Number(value) || 0;
        return (Math.round(number / 1000000 * 100) / 100) + " " + suffix;
    }

    function parseOutput(text) {
        const data = {};
        const top = [];
        const rows = [];
        const ips = [];
        const lines = String(text || "").split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const index = line.indexOf("=");
            if (index < 0) continue;

            const key = line.slice(0, index).trim();
            const value = line.slice(index + 1).trim();

            if (key === "top") {
                const parts = value.split("|");
                top.push({ "label": parts[0] || "process", "value": Number(parts[1]) || 0 });
            } else if (key === "row") {
                const parts = value.split("|");
                rows.push({ "label": parts[0] || "", "value": parts[1] || "" });
            } else if (key === "ip") {
                const validAddress = value.length > 0
                                  && value.indexOf("Quickshell") < 0
                                  && value.indexOf("QScreen") < 0
                                  && value.length < 64
                                  && /^[0-9a-fA-F:.]+\/[0-9]+$/.test(value);
                if (validAddress) ips.push(value);
            } else {
                data[key] = value;
            }
        }

        if (data.module !== undefined && data.module !== moduleName) return;

        detailData = data;
        topRows = top;
        listRows = rows;
        ipRows = ips;
        rememberDetailSample(data);
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

    function toggle(name, anchor) {
        if (panelOpen && moduleName === name) close();
        else open(name, anchor);
    }

    function open(name, anchor) {
        closeTimer.stop();
        if (detailsProc.running) detailsProc.running = false;
        moduleName = String(name || "");
        anchorItem = anchor || null;
        panelClosing = false;
        panelOpen = true;
        activeTab = settings ? normalizedTab(settings.modulePopupDefaultTab) : "Overview";
        clearData();
        requestRefresh();
    }

    function openTab(name, tab, anchor) {
        open(name, anchor);
        activeTab = normalizedTab(tab);
    }

    function close() {
        if (!panelOpen && !panelClosing) return;

        panelClosing = true;
        panelOpen = false;
        closeTimer.restart();
    }

    function contentFor(name) {
        if (name === "cpu") return cpuContent;
        if (name === "network") return networkContent;
        if (name === "memory") return memoryContent;
        if (name === "battery") return batteryContent;
        if (name === "audio") return audioContent;
        if (name === "brightness") return brightnessContent;
        if (name === "bluetooth") return bluetoothContent;
        if (name === "powerProfile") return powerProfileContent;
        if (name === "media") return mediaContent;
        return genericContent;
    }

    function tabContentFor(name, tab) {
        if (tab === "Controls") return controlsContent;
        if (tab === "Diagnostics") return diagnosticsContent;
        return contentFor(name);
    }

    function diagnosticRows() {
        const rows = [
            { "label": "Module", "value": moduleName },
            { "label": "Visible", "value": settings.enabled(moduleName) ? "yes" : "no" },
            { "label": "Category", "value": settings.moduleCategory(moduleName) },
            { "label": "Cost", "value": settings.moduleCost(moduleName) }
        ];
        const data = detailData || {};
        const keys = Object.keys(data).sort();
        for (let i = 0; i < keys.length; i++) {
            if (keys[i] === "module") continue;
            rows.push({ "label": keys[i], "value": String(data[keys[i]]) });
        }
        return rows;
    }

    function refreshable(name) {
        return ["cpu", "network", "memory", "battery", "brightness", "bluetooth", "powerProfile", "media"].indexOf(name) >= 0;
    }

    function requestRefresh() {
        if (!refreshable(moduleName)) return;
        pendingRefresh = true;
        pendingRefreshTimer.restart();
    }

    function refresh() {
        if (!panelOpen || detailsProc.running || !refreshable(moduleName)) return;

        if (moduleName === "cpu") {
            detailsProc.command = ["sh", "-c", "read _ u n s i io irq sirq st rest < /proc/stat; total=$((u+n+s+i+io+irq+sirq+st)); idle=$((i+io)); sleep 0.15; read _ u2 n2 s2 i2 io2 irq2 sirq2 st2 rest < /proc/stat; total2=$((u2+n2+s2+i2+io2+irq2+sirq2+st2)); idle2=$((i2+io2)); dt=$((total2-total)); di=$((idle2-idle)); usage=0; [ \"$dt\" -gt 0 ] && usage=$((100*(dt-di)/dt)); read l1 l2 l3 rest < /proc/loadavg; printf 'usage=%s\\ncores=%s\\nload=%s %s %s\\n' \"$usage\" \"$(nproc)\" \"$l1\" \"$l2\" \"$l3\"; ps -eo pcpu,comm --sort=-pcpu | awk 'NR>1 && NR<=6 { gsub(/\\|/, \"\", $2); printf \"top=%s|%s\\n\", $2, $1 }'"];
        } else if (moduleName === "network") {
            const requested = String(settings.networkInterfaceName || "").trim();
            const prefix = requested.length > 0 ? "dev=" + shellQuote(requested) : "dev=$(ip -o route get 1.1.1.1 2>/dev/null | sed -n 's/.* dev \\([^ ]*\\).*/\\1/p' | head -1)";
            detailsProc.command = ["sh", "-c", prefix + "; if [ -z \"$dev\" ] || [ ! -d \"/sys/class/net/$dev\" ]; then printf 'online=0\\nstate=offline\\n'; exit 0; fi; state=$(cat \"/sys/class/net/$dev/operstate\" 2>/dev/null || echo unknown); kind=other; case \"$dev\" in wl*|*wifi*|*wlan*) kind=wifi;; en*|eth*) kind=ethernet;; esac; rx=$(cat \"/sys/class/net/$dev/statistics/rx_bytes\" 2>/dev/null || echo 0); tx=$(cat \"/sys/class/net/$dev/statistics/tx_bytes\" 2>/dev/null || echo 0); printf 'online=1\\ndevice=%s\\nstate=%s\\nkind=%s\\nrx=%s\\ntx=%s\\n' \"$dev\" \"$state\" \"$kind\" \"$rx\" \"$tx\"; ip -brief addr show dev \"$dev\" 2>/dev/null | awk '{ for (i=3; i<=NF; i++) print \"ip=\" $i }'; if command -v iw >/dev/null 2>&1; then iw dev \"$dev\" link 2>/dev/null | awk -F': ' '/SSID/ { print \"ssid=\" $2 } /signal/ { print \"signal=\" $2 } /tx bitrate/ { print \"bitrate=\" $2 }'; fi"];
        } else if (moduleName === "memory") {
            detailsProc.command = ["sh", "-c", "mt=$(awk '/MemTotal:/ {print $2}' /proc/meminfo); ma=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo); st=$(awk '/SwapTotal:/ {print $2}' /proc/meminfo); sf=$(awk '/SwapFree:/ {print $2}' /proc/meminfo); mu=$((mt-ma)); su=$((st-sf)); mp=0; sp=0; [ \"$mt\" -gt 0 ] && mp=$((100*mu/mt)); [ \"$st\" -gt 0 ] && sp=$((100*su/st)); printf 'mem_total=%s\\nmem_available=%s\\nmem_used=%s\\nmem_percent=%s\\nswap_total=%s\\nswap_free=%s\\nswap_used=%s\\nswap_percent=%s\\n' \"$mt\" \"$ma\" \"$mu\" \"$mp\" \"$st\" \"$sf\" \"$su\" \"$sp\""];
        } else if (moduleName === "battery") {
            detailsProc.command = ["sh", "-c", "bat=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' | head -1); if [ -z \"$bat\" ]; then printf 'present=0\\n'; exit 0; fi; printf 'present=1\\ndevice=%s\\n' \"$(basename \"$bat\")\"; for f in manufacturer model_name status capacity energy_now energy_full energy_full_design power_now voltage_now cycle_count; do [ -r \"$bat/$f\" ] && printf '%s=%s\\n' \"$f\" \"$(cat \"$bat/$f\")\"; done"];
        } else if (moduleName === "brightness") {
            detailsProc.command = ["sh", "-c", "if command -v brightnessctl >/dev/null 2>&1; then data=$(brightnessctl -m -c backlight info 2>/dev/null || true); if [ -n \"$data\" ]; then dev=$(printf '%s' \"$data\" | cut -d, -f1); cur=$(printf '%s' \"$data\" | cut -d, -f3); pct=$(printf '%s' \"$data\" | grep -o '[0-9][0-9]*%' | head -1 | tr -d %); max=0; [ -n \"$pct\" ] && [ \"$pct\" -gt 0 ] 2>/dev/null && max=$((cur*100/pct)); printf 'available=1\\ncan_set=1\\ndevice=%s\\ncurrent=%s\\nmax=%s\\npercent=%s\\n' \"$dev\" \"$cur\" \"$max\" \"${pct:-0}\"; exit 0; fi; fi; for d in /sys/class/backlight/*; do [ -r \"$d/brightness\" ] || continue; cur=$(cat \"$d/brightness\"); max=$(cat \"$d/max_brightness\"); pct=0; [ \"$max\" -gt 0 ] 2>/dev/null && pct=$((100*cur/max)); printf 'available=1\\ncan_set=0\\ndevice=%s\\ncurrent=%s\\nmax=%s\\npercent=%s\\n' \"$(basename \"$d\")\" \"$cur\" \"$max\" \"$pct\"; exit 0; done; printf 'available=0\\n'"];
        } else if (moduleName === "bluetooth") {
            detailsProc.command = ["sh", "-c", "if ! command -v bluetoothctl >/dev/null 2>&1; then printf 'available=0\\n'; exit 0; fi; out=$(bluetoothctl show 2>/dev/null || true); ctrl=$(printf '%s\\n' \"$out\" | sed -n 's/^Controller //p' | head -1); alias=$(printf '%s\\n' \"$out\" | sed -n 's/^[[:space:]]*Alias: //p' | head -1); powered=$(printf '%s\\n' \"$out\" | sed -n 's/^[[:space:]]*Powered: //p' | head -1); discoverable=$(printf '%s\\n' \"$out\" | sed -n 's/^[[:space:]]*Discoverable: //p' | head -1); pairable=$(printf '%s\\n' \"$out\" | sed -n 's/^[[:space:]]*Pairable: //p' | head -1); blocked=$(printf '%s\\n' \"$out\" | sed -n 's/^[[:space:]]*Blocked: //p' | head -1); printf 'available=1\\ncontroller=%s\\nalias=%s\\npowered=%s\\ndiscoverable=%s\\npairable=%s\\nblocked=%s\\n' \"$ctrl\" \"$alias\" \"$powered\" \"$discoverable\" \"$pairable\" \"$blocked\"; bluetoothctl devices Connected 2>/dev/null | sed 's/^Device //; s/ /|/' | awk '{ print \"row=\" $0 }'"];
        } else if (moduleName === "powerProfile") {
            detailsProc.command = ["sh", "-c", "if command -v powerprofilesctl >/dev/null 2>&1; then printf 'available=1\\ncurrent=%s\\n' \"$(powerprofilesctl get 2>/dev/null)\"; powerprofilesctl list 2>/dev/null | sed 's/^..//; s/:$//' | awk 'NF { print \"row=\" $0 \"|available\" }'; else printf 'available=0\\n'; fi"];
        } else if (moduleName === "media") {
            detailsProc.command = ["sh", "-c", "if command -v playerctl >/dev/null 2>&1; then playerctl metadata --format 'available=1\\nplayer={{playerName}}\\ntitle={{title}}\\nartist={{artist}}\\nalbum={{album}}' 2>/dev/null || printf 'available=0\\n'; else printf 'available=0\\n'; fi"];
        } else {
            return;
        }

        const currentCommand = Array.from(detailsProc.command || []);
        if (currentCommand.length >= 3 && currentCommand[0] === "sh" && currentCommand[1] === "-c") {
            detailsProc.command = ["sh", "-c", "printf 'module=%s\\n' " + shellQuote(moduleName) + "; " + currentCommand[2]];
        }

        detailsProc.running = true;
    }

    function runAction(command) {
        if (actionProc.running) {
            queuedActionCommand = command;
            return;
        }

        actionProc.command = ["sh", "-c", command];
        actionProc.running = true;
    }

    function setBrightnessPercent(value) {
        const next = Math.max(1, Math.min(100, Math.round(Number(value) || 0)));
        runAction("command -v brightnessctl >/dev/null 2>&1 && brightnessctl -c backlight set " + next + "%");
        const data = Object.assign({}, detailData);
        data.percent = String(next);
        detailData = data;
    }

    anchor.window: panelWindow
    anchor.rect.x: 0
    anchor.rect.y: panelWindow ? (settings.barPosition === "bottom" ? -detailsFrame.implicitHeight - settings.settingsPanelGap : panelWindow.height + settings.settingsPanelGap) : 0
    implicitWidth: panelWindow ? panelWindow.width : panelWidth
    implicitHeight: detailsFrame.implicitHeight
    visible: panelOpen || panelClosing
    grabFocus: panelOpen
    color: "transparent"

    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: root.panelOpen
        context: Qt.WindowShortcut
        onActivated: root.close()
    }

    Timer {
        id: closeTimer

        interval: root.settings ? Math.max(1, root.settings.motionClose) : 1
        repeat: false
        onTriggered: root.panelClosing = false
    }

    Timer {
        id: pendingRefreshTimer

        interval: 40
        repeat: false
        onTriggered: {
            if (!root.pendingRefresh) return;
            if (detailsProc.running) {
                restart();
                return;
            }

            root.pendingRefresh = false;
            root.refresh();
        }
    }

    Timer {
        interval: root.moduleName === "cpu" || root.moduleName === "network" ? 2500 : 6000
        running: root.panelOpen && root.refreshable(root.moduleName)
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: detailsProc

        stdout: StdioCollector {
            onStreamFinished: root.parseOutput(text)
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.warn("Module details:", text.trim())
        }
    }

    Process {
        id: actionProc

        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.warn("Module action:", text.trim())
        }
        onExited: {
            if (root.queuedActionCommand.length > 0) {
                const command = root.queuedActionCommand;
                root.queuedActionCommand = "";
                root.runAction(command);
                return;
            }

            root.refresh();
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.panelOpen && !settings.modulePopupPinned
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
        id: detailsFrame

        x: root.anchoredX()
        width: root.panelWidth
        y: root.panelOpen ? 0 : -Math.max(settings.effectiveContentSpacing * 2, settings.effectiveGroupPadding * 2)
        implicitHeight: detailsColumn.implicitHeight + settings.panelPadding * 2
        height: implicitHeight
        theme: root.theme
        settings: root.settings
        surfaceColor: theme.alpha(theme.surfaceContainerHigh, settings.panelOpacity / 100)
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
            id: detailsColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: settings.panelPadding
            spacing: settings.panelPadding

            Row {
                width: parent.width
                height: Math.max(settings.controlHeight, titleColumn.implicitHeight)
                spacing: settings.effectiveContentSpacing

                Rectangle {
                    width: settings.controlHeight
                    height: width
                    radius: settings.effectivePillRadius
                    color: theme.alpha(theme.accent, 0.14)
                    border.color: theme.alpha(theme.accent, 0.26)
                    border.width: settings.effectiveBorderWidth
                    antialiasing: true

                    Text {
                        anchors.centerIn: parent
                        text: settings.moduleIcon(root.moduleName)
                        color: theme.accent
                        font.family: settings.fontFamily
                        font.pixelSize: settings.effectiveIconSize
                    }
                }

                Column {
                    id: titleColumn

                    width: parent.width - settings.controlHeight * 2 - parent.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.35))

                    Text {
                        width: parent.width
                        text: root.moduleTitle()
                        color: theme.text
                        elide: Text.ElideRight
                        font.family: settings.fontFamily
                        font.pixelSize: Math.round(settings.effectiveFontSize * 1.12)
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: root.moduleSubtitle()
                        color: theme.textMuted
                        elide: Text.ElideRight
                        font.family: settings.fontFamily
                        font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                    }
                }

                ActionButton {
                    theme: root.theme
                    settings: root.settings
                    icon: ""
                    label: ""
                    square: true
                    onPressed: root.close()
                }
            }

            Flow {
                width: parent.width
                spacing: settings.effectiveContentSpacing

                Repeater {
                    model: ["Overview", "Controls", "Diagnostics"]

                    ActionButton {
                        required property var modelData

                        theme: root.theme
                        settings: root.settings
                        label: String(modelData)
                        selected: root.activeTab === String(modelData)
                        onPressed: root.activeTab = String(modelData)
                    }
                }
            }

            Loader {
                id: detailsLoader

                active: root.panelOpen
                width: parent.width
                sourceComponent: root.tabContentFor(root.moduleName, root.activeTab)
            }
        }
    }

    component CpuContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        GaugeCard {
            width: parent.width
            theme: root.theme
            settings: root.settings
            title: "Processor load"
            icon: ""
            valueText: Math.round(root.numberValue("usage", 0)) + "%"
            subText: root.textValue("cores", "0") + " cores / load " + root.textValue("load", "0 0 0")
            progress: root.numberValue("usage", 0) / 100
            accentColor: root.numberValue("usage", 0) >= 90 ? theme.error : root.numberValue("usage", 0) >= 70 ? theme.warning : theme.primary
            sampleHistory: root.cpuHistory
        }

        Flow {
            width: parent.width
            spacing: settings.effectiveContentSpacing

            MetricCard { theme: root.theme; settings: root.settings; label: "Cores"; value: root.textValue("cores", "0"); icon: "󰘚"; width: (parent.width - parent.spacing) / 2 }
            MetricCard { theme: root.theme; settings: root.settings; label: "Polling"; value: settings.cpuPollMs + "ms"; icon: "󰥔"; width: (parent.width - parent.spacing) / 2 }
        }

        PanelCard {
            width: parent.width
            theme: root.theme
            settings: root.settings

            Column {
                x: settings.effectivePillPadding
                y: settings.effectivePillPadding
                width: parent.width - settings.effectivePillPadding * 2
                spacing: settings.effectiveContentSpacing

                SectionLabel { theme: root.theme; settings: root.settings; text: "Top processes" }

                Repeater {
                    model: root.topRows

                    UsageRow {
                        required property var modelData

                        width: parent.width
                        theme: root.theme
                        settings: root.settings
                        label: modelData && modelData.label !== undefined ? String(modelData.label) : ""
                        value: Math.min(100, Number(modelData && modelData.value) || 0)
                        valueText: Math.round((Number(modelData && modelData.value) || 0) * 10) / 10 + "%"
                    }
                }
            }
        }

        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show graph on bar"; checked: settings.cpuShowGraph; onToggled: function(checked) { settings.setValue("cpuShowGraph", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Polling"; value: settings.cpuPollMs; minimum: 5000; maximum: 60000; step: 1000; suffix: "ms"; onValueRequested: function(value) { settings.setPollingInterval("cpuMs", value, minimum, maximum); } }
    }

    component NetworkContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        GaugeCard {
            width: parent.width
            theme: root.theme
            settings: root.settings
            title: root.boolValue("online") ? "Network activity" : "Offline"
            icon: root.textValue("kind", "other") === "wifi" ? "󰤨" : "󰈀"
            valueText: root.networkRateText()
            subText: root.boolValue("online") ? root.textValue("device", "net") + " / down " + root.formatBytes(root.networkRxRate) + "/s up " + root.formatBytes(root.networkTxRate) + "/s" : root.textValue("state", "offline")
            progress: root.boolValue("online") ? root.networkProgress() : 0
            accentColor: !root.boolValue("online") ? theme.textMuted : root.networkProgress() >= 0.90 ? theme.error : root.networkProgress() >= 0.72 ? theme.warning : theme.primary
            sampleHistory: root.networkHistory
        }

        Flow {
            width: parent.width
            spacing: settings.effectiveContentSpacing

            MetricCard { theme: root.theme; settings: root.settings; label: "RX"; value: root.formatBytes(root.numberValue("rx", 0)); icon: "󰇚"; width: (parent.width - parent.spacing) / 2 }
            MetricCard { theme: root.theme; settings: root.settings; label: "TX"; value: root.formatBytes(root.numberValue("tx", 0)); icon: "󰕒"; width: (parent.width - parent.spacing) / 2 }
        }

        PanelCard {
            width: parent.width
            theme: root.theme
            settings: root.settings

            Column {
                x: settings.effectivePillPadding
                y: settings.effectivePillPadding
                width: parent.width - settings.effectivePillPadding * 2
                spacing: settings.effectiveContentSpacing

                SectionLabel { theme: root.theme; settings: root.settings; text: "Address" }

                Flow {
                    width: parent.width
                    spacing: settings.effectiveContentSpacing

                    Repeater {
                        model: root.ipRows.length > 0 ? root.ipRows : ["No address"]

                        Chip {
                            required property var modelData

                            theme: root.theme
                            settings: root.settings
                            label: String(modelData)
                        }
                    }
                }

                InfoRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Signal"; value: root.textValue("signal", "n/a") }
                InfoRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Bitrate"; value: root.textValue("bitrate", "n/a") }
            }
        }

        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show speed on bar"; checked: settings.networkShowSpeed; onToggled: function(checked) { settings.setValue("networkShowSpeed", checked); } }
        TextInputRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Interface override"; value: settings.networkInterfaceName; onTextRequested: function(text) { settings.setString("networkInterfaceName", text); root.refresh(); } }
    }

    component MemoryContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        GaugeCard {
            width: parent.width
            theme: root.theme
            settings: root.settings
            title: "Memory pressure"
            icon: ""
            valueText: Math.round(root.numberValue("mem_percent", 0)) + "%"
            subText: root.formatKib(root.numberValue("mem_used", 0)) + " used of " + root.formatKib(root.numberValue("mem_total", 0))
            progress: root.numberValue("mem_percent", 0) / 100
            accentColor: root.numberValue("mem_percent", 0) >= 90 ? theme.error : root.numberValue("mem_percent", 0) >= 75 ? theme.warning : theme.primary
            sampleHistory: root.memoryHistory
        }

        Flow {
            width: parent.width
            spacing: settings.effectiveContentSpacing

            MetricCard { theme: root.theme; settings: root.settings; label: "Available"; value: root.formatKib(root.numberValue("mem_available", 0)); icon: "󰘚"; width: (parent.width - parent.spacing) / 2 }
            MetricCard { theme: root.theme; settings: root.settings; label: "Swap"; value: Math.round(root.numberValue("swap_percent", 0)) + "%"; icon: "󰋊"; width: (parent.width - parent.spacing) / 2 }
        }

        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show graph on bar"; checked: settings.memoryShowGraph; onToggled: function(checked) { settings.setValue("memoryShowGraph", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Polling"; value: settings.memoryPollMs; minimum: 1000; maximum: 30000; step: 500; suffix: "ms"; onValueRequested: function(value) { settings.setPollingInterval("memoryMs", value, minimum, maximum); } }
    }

    component BatteryContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        GaugeCard {
            width: parent.width
            theme: root.theme
            settings: root.settings
            title: root.textValue("status", "Battery")
            icon: "󰁹"
            valueText: root.boolValue("present") ? Math.round(root.numberValue("capacity", 0)) + "%" : "none"
            subText: root.textValue("manufacturer", "") + " " + root.textValue("model_name", "")
            progress: root.numberValue("capacity", 0) / 100
            accentColor: root.numberValue("capacity", 0) <= settings.batteryCriticalThreshold ? theme.error : root.numberValue("capacity", 0) <= settings.batteryCriticalThreshold * 2 ? theme.warning : theme.primary
            sampleHistory: root.batteryHistory
        }

        Flow {
            width: parent.width
            spacing: settings.effectiveContentSpacing

            MetricCard { theme: root.theme; settings: root.settings; label: "Energy"; value: root.formatMicro(root.numberValue("energy_now", 0), "Wh"); icon: "󰚥"; width: (parent.width - parent.spacing) / 2 }
            MetricCard { theme: root.theme; settings: root.settings; label: "Power"; value: root.formatMicro(root.numberValue("power_now", 0), "W"); icon: ""; width: (parent.width - parent.spacing) / 2 }
            MetricCard { theme: root.theme; settings: root.settings; label: "Voltage"; value: root.formatMicro(root.numberValue("voltage_now", 0), "V"); icon: "󱐋"; width: (parent.width - parent.spacing) / 2 }
            MetricCard { theme: root.theme; settings: root.settings; label: "Cycles"; value: root.textValue("cycle_count", "n/a"); icon: "󰑓"; width: (parent.width - parent.spacing) / 2 }
        }

        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show percentage"; checked: settings.batteryShowPercentage; onToggled: function(checked) { settings.setValue("batteryShowPercentage", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Critical threshold"; value: settings.batteryCriticalThreshold; minimum: 5; maximum: 30; step: 1; suffix: "%"; onValueRequested: function(value) { settings.setNumber("batteryCriticalThreshold", value, minimum, maximum); } }
    }

    component AudioContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        GaugeCard {
            width: parent.width
            theme: root.theme
            settings: root.settings
            title: root.hasAudio && root.sink.audio.muted ? "Muted" : "Output volume"
            icon: root.hasAudio && root.sink.audio.muted ? "󰖁" : "󰕾"
            valueText: root.hasAudio ? Math.round(root.sink.audio.volume * 100) + "%" : "off"
            subText: root.hasAudio ? String(root.sink.description || root.sink.name || "Default sink") : "No default sink"
            progress: root.hasAudio ? root.sink.audio.volume : 0
            accentColor: root.hasAudio && root.sink.audio.muted ? theme.textMuted : theme.accent
        }

        SliderRow {
            width: parent.width
            theme: root.theme
            settings: root.settings
            label: "Volume"
            value: root.hasAudio ? Math.round(root.sink.audio.volume * 100) : 0
            minimum: 0
            maximum: 150
            step: 5
            suffix: "%"
            enabled: root.hasAudio
            onValueRequested: function(value) {
                if (!root.hasAudio) return;
                root.sink.audio.volume = Math.max(0, Math.min(1.5, value / 100));
                if (value > 0) root.sink.audio.muted = false;
            }
        }

        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Muted"; checked: root.hasAudio ? root.sink.audio.muted : true; enabled: root.hasAudio; onToggled: function(checked) { if (root.hasAudio) root.sink.audio.muted = checked; } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show percentage"; checked: settings.audioShowPercentage; onToggled: function(checked) { settings.setValue("audioShowPercentage", checked); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Device name"; checked: settings.audioShowDeviceName; onToggled: function(checked) { settings.setValue("audioShowDeviceName", checked); } }
    }

    component BrightnessContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        GaugeCard {
            width: parent.width
            theme: root.theme
            settings: root.settings
            title: root.boolValue("available") ? "Backlight" : "Unavailable"
            icon: "󰃠"
            valueText: Math.round(root.numberValue("percent", 0)) + "%"
            subText: root.textValue("device", "No backlight")
            progress: root.numberValue("percent", 0) / 100
            accentColor: theme.accent
        }

        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Brightness"; value: root.numberValue("percent", 0); minimum: 1; maximum: 100; step: settings.brightnessStep; suffix: "%"; enabled: root.boolValue("can_set"); onValueRequested: function(value) { root.setBrightnessPercent(value); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show percentage"; checked: settings.brightnessShowPercentage; onToggled: function(checked) { settings.setValue("brightnessShowPercentage", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Scroll step"; value: settings.brightnessStep; minimum: 1; maximum: 20; step: 1; suffix: "%"; onValueRequested: function(value) { settings.setNumber("brightnessStep", value, minimum, maximum); } }
    }

    component BluetoothContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        GaugeCard {
            width: parent.width
            theme: root.theme
            settings: root.settings
            title: root.boolValue("powered") ? "Bluetooth on" : "Bluetooth off"
            icon: "󰂯"
            valueText: root.textValue("alias", "Adapter")
            subText: root.textValue("controller", root.boolValue("available") ? "Controller present" : "bluetoothctl missing")
            progress: root.boolValue("powered") ? 1 : 0
            accentColor: root.boolValue("powered") ? theme.good : theme.textMuted
        }

        Flow {
            width: parent.width
            spacing: settings.effectiveContentSpacing

            Chip { theme: root.theme; settings: root.settings; label: "Discoverable " + root.textValue("discoverable", "no") }
            Chip { theme: root.theme; settings: root.settings; label: "Pairable " + root.textValue("pairable", "no") }
            Chip { theme: root.theme; settings: root.settings; label: root.textValue("blocked", "no") === "yes" ? "Blocked" : "Ready" }
        }

        PanelCard {
            width: parent.width
            theme: root.theme
            settings: root.settings

            Column {
                x: settings.effectivePillPadding
                y: settings.effectivePillPadding
                width: parent.width - settings.effectivePillPadding * 2
                spacing: settings.effectiveContentSpacing

                SectionLabel { theme: root.theme; settings: root.settings; text: "Connected devices" }

                Repeater {
                    model: root.listRows.length > 0 ? root.listRows : [{ "label": "No connected devices", "value": "" }]

                    InfoRow {
                        required property var modelData

                        width: parent.width
                        theme: root.theme
                        settings: root.settings
                        label: modelData.label
                        value: modelData.value
                    }
                }
            }
        }

        ActionButton {
            theme: root.theme
            settings: root.settings
            icon: root.boolValue("powered") ? "󰂲" : "󰂯"
            label: root.boolValue("powered") ? "Power off" : "Power on"
            onPressed: root.runAction("bluetoothctl power " + (root.boolValue("powered") ? "off" : "on"))
        }
    }

    component PowerProfileContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        GaugeCard { width: parent.width; theme: root.theme; settings: root.settings; title: "Power profile"; icon: "󰓅"; valueText: root.textValue("current", "unknown"); subText: root.boolValue("available") ? "powerprofilesctl" : "Unavailable"; progress: root.textValue("current", "") === "performance" ? 1 : root.textValue("current", "") === "balanced" ? 0.55 : 0.25; accentColor: root.textValue("current", "") === "performance" ? theme.warning : root.textValue("current", "") === "power-saver" ? theme.good : theme.accent }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Show label"; checked: settings.powerProfileShowLabel; onToggled: function(checked) { settings.setValue("powerProfileShowLabel", checked); } }
    }

    component MediaContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        GaugeCard { width: parent.width; theme: root.theme; settings: root.settings; title: root.textValue("title", "No active player"); icon: "󰝚"; valueText: root.textValue("artist", "Media"); subText: root.textValue("album", root.textValue("player", "")); progress: root.boolValue("available") ? 1 : 0; accentColor: root.boolValue("available") ? theme.accent : theme.textMuted }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Transport controls"; checked: settings.mediaShowControls; onToggled: function(checked) { settings.setValue("mediaShowControls", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Title width"; value: settings.mediaMaxWidth; minimum: 80; maximum: 320; step: 10; suffix: "px"; onValueRequested: function(value) { settings.setNumber("mediaMaxWidth", value, minimum, maximum); } }
    }

    component GenericContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        PanelCard {
            width: parent.width
            theme: root.theme
            settings: root.settings

            Column {
                x: settings.effectivePillPadding
                y: settings.effectivePillPadding
                width: parent.width - settings.effectivePillPadding * 2
                spacing: settings.effectiveContentSpacing

                SectionLabel { theme: root.theme; settings: root.settings; text: "Module" }
                InfoRow { width: parent.width; theme: root.theme; settings: root.settings; label: "State"; value: settings.enabled(root.moduleName) ? "Enabled" : "Disabled" }
            }
        }

        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled(root.moduleName); onToggled: function(checked) { settings.setModuleEnabled(root.moduleName, checked); } }
    }

    Component { id: cpuContent; CpuContent {} }
    Component { id: networkContent; NetworkContent {} }
    Component { id: memoryContent; MemoryContent {} }
    Component { id: batteryContent; BatteryContent {} }
    Component { id: audioContent; AudioContent {} }
    Component { id: brightnessContent; BrightnessContent {} }
    Component { id: bluetoothContent; BluetoothContent {} }
    Component { id: powerProfileContent; PowerProfileContent {} }
    Component { id: mediaContent; MediaContent {} }
    Component { id: genericContent; GenericContent {} }
    Component { id: controlsContent; ControlsContent {} }
    Component { id: diagnosticsContent; DiagnosticsContent {} }

    component ControlsContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; label: "Enabled"; checked: settings.enabled(root.moduleName); onToggled: function(checked) { settings.setModuleEnabled(root.moduleName, checked); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "audio"; label: "Show percentage"; checked: settings.audioShowPercentage; onToggled: function(checked) { settings.setValue("audioShowPercentage", checked); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "audio"; label: "Device name"; checked: settings.audioShowDeviceName; onToggled: function(checked) { settings.setValue("audioShowDeviceName", checked); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "network"; label: "Show speed"; checked: settings.networkShowSpeed; onToggled: function(checked) { settings.setValue("networkShowSpeed", checked); } }
        TextInputRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "network"; label: "Interface override"; value: settings.networkInterfaceName; onTextRequested: function(text) { settings.setString("networkInterfaceName", text); root.refresh(); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "battery"; label: "Show percentage"; checked: settings.batteryShowPercentage; onToggled: function(checked) { settings.setValue("batteryShowPercentage", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "battery"; label: "Critical threshold"; value: settings.batteryCriticalThreshold; minimum: 5; maximum: 30; step: 1; suffix: "%"; onValueRequested: function(value) { settings.setNumber("batteryCriticalThreshold", value, minimum, maximum); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "cpu"; label: "Show graph on bar"; checked: settings.cpuShowGraph; onToggled: function(checked) { settings.setValue("cpuShowGraph", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "cpu"; label: "Polling"; value: settings.cpuPollMs; minimum: 5000; maximum: 60000; step: 1000; suffix: "ms"; onValueRequested: function(value) { settings.setPollingInterval("cpuMs", value, minimum, maximum); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "memory"; label: "Show graph on bar"; checked: settings.memoryShowGraph; onToggled: function(checked) { settings.setValue("memoryShowGraph", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "memory"; label: "Polling"; value: settings.memoryPollMs; minimum: 1000; maximum: 30000; step: 500; suffix: "ms"; onValueRequested: function(value) { settings.setPollingInterval("memoryMs", value, minimum, maximum); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "media"; label: "Transport controls"; checked: settings.mediaShowControls; onToggled: function(checked) { settings.setValue("mediaShowControls", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "media"; label: "Title width"; value: settings.mediaMaxWidth; minimum: 80; maximum: 320; step: 10; suffix: "px"; onValueRequested: function(value) { settings.setNumber("mediaMaxWidth", value, minimum, maximum); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "brightness"; label: "Show percentage"; checked: settings.brightnessShowPercentage; onToggled: function(checked) { settings.setValue("brightnessShowPercentage", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "brightness"; label: "Scroll step"; value: settings.brightnessStep; minimum: 1; maximum: 20; step: 1; suffix: "%"; onValueRequested: function(value) { settings.setNumber("brightnessStep", value, minimum, maximum); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "powerProfile"; label: "Show label"; checked: settings.powerProfileShowLabel; onToggled: function(checked) { settings.setValue("powerProfileShowLabel", checked); } }
        ToggleRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "tray"; label: "Compact"; checked: settings.trayCompact; onToggled: function(checked) { settings.setValue("trayCompact", checked); } }
        SliderRow { width: parent.width; theme: root.theme; settings: root.settings; visible: root.moduleName === "tray"; label: "Visible icons"; value: settings.trayMaxVisible; minimum: 2; maximum: 12; step: 1; suffix: ""; onValueRequested: function(value) { settings.setNumber("trayMaxVisible", value, minimum, maximum); } }
    }

    component DiagnosticsContent: Column {
        width: detailsLoader.width
        spacing: settings.effectiveContentSpacing

        PanelCard {
            width: parent.width
            theme: root.theme
            settings: root.settings

            Column {
                x: settings.effectivePillPadding
                y: settings.effectivePillPadding
                width: parent.width - settings.effectivePillPadding * 2
                spacing: settings.effectiveContentSpacing

                Repeater {
                    model: root.diagnosticRows()

                    InfoRow {
                        required property var modelData

                        width: parent.width
                        theme: root.theme
                        settings: root.settings
                        label: modelData.label
                        value: modelData.value
                    }
                }
            }
        }
    }

    component GaugeCard: PanelCard {
        id: gauge

        property string title: ""
        property string icon: ""
        property string valueText: ""
        property string subText: ""
        property real progress: 0
        property color accentColor: theme.accent
        property var sampleHistory: []
        readonly property bool useGauge: settings.modulePopupShowGauge
        readonly property bool useSparkline: settings.modulePopupShowSparkline && sampleHistory.length > 1
        readonly property int gaugeSize: Math.round(settings.controlHeight * (useGauge ? 3.15 : 1.45))

        implicitHeight: Math.max(settings.controlHeight * 2.7, gaugeContent.implicitHeight + settings.effectivePillPadding * 2)

        Row {
            id: gaugeContent

            x: settings.effectivePillPadding
            y: settings.effectivePillPadding
            width: parent.width - settings.effectivePillPadding * 2
            spacing: settings.effectivePillPadding

            Item {
                id: gaugeVisual

                width: gauge.gaugeSize
                height: gauge.gaugeSize

                CircularGauge {
                    anchors.fill: parent
                    visible: gauge.useGauge
                    theme: gauge.theme
                    settings: gauge.settings
                    value: gauge.progress
                    accentColor: gauge.accentColor
                    icon: gauge.icon
                    valueText: gauge.valueText
                }

                Rectangle {
                    anchors.fill: parent
                    visible: !gauge.useGauge
                    radius: width / 2
                    color: theme.alpha(gauge.accentColor, 0.16)
                    border.color: theme.alpha(gauge.accentColor, 0.28)
                    border.width: settings.effectiveBorderWidth
                    antialiasing: true

                    Text {
                        anchors.centerIn: parent
                        text: gauge.icon
                        color: gauge.accentColor
                        font.family: settings.fontFamilyIcon
                        font.pixelSize: settings.effectiveIconSize
                    }
                }
            }

            Column {
                width: Math.max(0, parent.width - parent.spacing - gaugeVisual.width)
                spacing: Math.max(2, settings.effectiveContentSpacing / 2)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: gauge.title
                    color: theme.text
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: settings.effectiveFontSize
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    visible: !gauge.useGauge
                    text: gauge.valueText
                    color: gauge.accentColor
                    elide: Text.ElideRight
                    font.family: settings.fontFamilyMono
                    font.pixelSize: Math.round(settings.effectiveFontSize * 1.55)
                    font.weight: Font.Bold
                }

                ProgressLine {
                    visible: !gauge.useGauge
                    width: parent.width
                    theme: root.theme
                    settings: root.settings
                    value: gauge.progress
                    accentColor: gauge.accentColor
                }

                Sparkline {
                    width: parent.width
                    height: settings.controlHeight
                    visible: gauge.useSparkline
                    theme: gauge.theme
                    settings: gauge.settings
                    values: gauge.sampleHistory
                    accentColor: gauge.accentColor
                }

                Text {
                    width: parent.width
                    text: gauge.subText
                    color: theme.textMuted
                    elide: Text.ElideRight
                    font.family: settings.fontFamilySans
                    font.pixelSize: Math.max(9, settings.effectiveFontSize - 2)
                }
            }
        }
    }

    component CircularGauge: Item {
        id: gaugeRoot

        property var theme
        property var settings
        property real value: 0
        property color accentColor: theme && theme.primary ? theme.primary : Qt.rgba(1, 1, 1, 1)
        property string icon: ""
        property string valueText: ""
        readonly property real clampedValue: Math.max(0, Math.min(1, Number(value) || 0))

        Canvas {
            id: gaugeCanvas

            anchors.fill: parent
            antialiasing: true
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                if (!gaugeRoot.theme || !gaugeRoot.settings || width <= 0 || height <= 0) return;

                const lineWidth = Math.max(gaugeRoot.settings.effectiveGroupPadding, Math.round(Math.min(width, height) * 0.075));
                const inset = lineWidth / 2 + gaugeRoot.settings.effectiveBorderWidth;
                const radius = Math.max(0, Math.min(width, height) / 2 - inset);
                const centerX = width / 2;
                const centerY = height / 2;
                const start = -Math.PI * 0.72;
                const span = Math.PI * 1.44;

                ctx.lineWidth = lineWidth;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, start, start + span, false);
                ctx.strokeStyle = gaugeRoot.theme.alpha(gaugeRoot.theme.outlineVariant, 0.70);
                ctx.stroke();

                if (gaugeRoot.clampedValue > 0.001) {
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, start, start + span * gaugeRoot.clampedValue, false);
                    ctx.strokeStyle = gaugeRoot.accentColor;
                    ctx.stroke();
                }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: gaugeRoot
                function onClampedValueChanged() { gaugeCanvas.requestPaint(); }
                function onAccentColorChanged() { gaugeCanvas.requestPaint(); }
            }
        }

        Column {
            anchors.centerIn: parent
            width: Math.round(parent.width * 0.76)
            spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.25))

            Text {
                width: parent.width
                text: gaugeRoot.icon
                color: gaugeRoot.accentColor
                horizontalAlignment: Text.AlignHCenter
                font.family: settings.fontFamilyIcon
                font.pixelSize: Math.max(9, Math.round(settings.effectiveIconSize * 0.82))
            }

            Text {
                width: parent.width
                text: gaugeRoot.valueText
                color: theme.text
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.family: settings.fontFamilyMono
                font.pixelSize: gaugeRoot.valueText.length > 5 ? Math.round(settings.effectiveFontSize * 1.08) : Math.round(settings.effectiveFontSize * 1.42)
                font.weight: Font.Bold
            }
        }
    }

    component Sparkline: Canvas {
        id: sparklineRoot

        property var theme
        property var settings
        property var values: []
        property color accentColor: theme && theme.primary ? theme.primary : Qt.rgba(1, 1, 1, 1)

        antialiasing: true
        opacity: values.length > 1 ? 1 : 0
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            const samples = Array.from(values || []);
            if (!theme || !settings || width <= 0 || height <= 0 || samples.length <= 0) return;

            const padding = Math.max(1, settings.effectiveBorderWidth);
            const usableWidth = Math.max(1, width - padding * 2);
            const usableHeight = Math.max(1, height - padding * 2);
            const baseY = height - padding;

            ctx.lineWidth = Math.max(1, settings.effectiveBorderWidth);
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            ctx.moveTo(padding, baseY);
            ctx.lineTo(width - padding, baseY);
            ctx.strokeStyle = theme.alpha(theme.outlineVariant, 0.55);
            ctx.stroke();

            ctx.beginPath();
            for (let i = 0; i < samples.length; i++) {
                const ratio = samples.length <= 1 ? 0 : i / (samples.length - 1);
                const x = padding + ratio * usableWidth;
                const y = padding + (1 - Math.max(0, Math.min(1, Number(samples[i]) || 0))) * usableHeight;
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.strokeStyle = sparklineRoot.accentColor;
            ctx.stroke();
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onValuesChanged: requestPaint()
        onAccentColorChanged: requestPaint()
    }

    component MetricCard: PanelCard {
        id: metric

        property string label: ""
        property string value: ""
        property string icon: ""

        implicitHeight: settings.controlHeight * 1.65

        Row {
            x: settings.effectivePillPadding
            y: settings.effectivePillPadding
            width: parent.width - settings.effectivePillPadding * 2
            height: settings.controlHeight
            spacing: settings.effectiveContentSpacing

            Text {
                width: settings.effectiveIconSize
                height: parent.height
                text: metric.icon
                color: theme.accent
                font.family: settings.fontFamilyIcon
                font.pixelSize: settings.effectiveIconSize
                verticalAlignment: Text.AlignVCenter
            }

            Column {
                width: parent.width - settings.effectiveIconSize - parent.spacing
                spacing: Math.max(1, Math.round(settings.effectiveContentSpacing * 0.2))

                Text { width: parent.width; text: metric.label; color: theme.textMuted; elide: Text.ElideRight; font.family: settings.fontFamilySans; font.pixelSize: Math.max(9, settings.effectiveFontSize - 2) }
                Text { width: parent.width; text: metric.value; color: theme.text; elide: Text.ElideRight; font.family: settings.fontFamilyMono; font.pixelSize: settings.effectiveFontSize; font.weight: Font.DemiBold }
            }
        }
    }

    component PanelCard: Rectangle {
        property var theme
        property var settings

        implicitHeight: childrenRect.height + settings.effectivePillPadding * 2
        radius: settings.effectivePillRadius
        color: theme.alpha(theme.surfaceContainer, 0.46)
        border.color: theme.outlineSubtle
        border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
        antialiasing: true
    }

    component SectionLabel: Text {
        property var theme
        property var settings

        color: theme.text
        font.family: settings.fontFamilySans
        font.pixelSize: settings.effectiveFontSize
        font.weight: Font.DemiBold
    }

    component ProgressLine: Rectangle {
        id: progressRoot

        property var theme
        property var settings
        property real value: 0
        property color accentColor: theme.accent

        height: Math.max(3, Math.round(settings.effectiveGroupPadding * 0.9))
        radius: height / 2
        color: theme.alpha(theme.text, 0.12)
        antialiasing: true

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, progressRoot.value))
            height: parent.height
            radius: parent.radius
            color: progressRoot.accentColor
            opacity: 0.9
            antialiasing: true

            Behavior on width { NumberAnimation { duration: settings.motionFast; easing.type: Easing.OutCubic } }
        }
    }

    component UsageRow: Item {
        id: usageRow

        property var theme
        property var settings
        property string label: ""
        property real value: 0
        property string valueText: ""

        implicitHeight: Math.max(settings.controlHeight, nameText.implicitHeight)

        Text {
            id: nameText

            anchors.left: parent.left
            anchors.right: valueLabel.left
            anchors.rightMargin: settings.effectiveContentSpacing
            anchors.verticalCenter: parent.verticalCenter
            text: usageRow.label
            color: theme.text
            elide: Text.ElideRight
            font.family: settings.fontFamilySans
            font.pixelSize: settings.effectiveFontSize
        }

        Text {
            id: valueLabel

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(settings.effectiveFontSize * 5)
            text: usageRow.valueText
            color: theme.textMuted
            horizontalAlignment: Text.AlignRight
            font.family: settings.fontFamilyMono
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.DemiBold
        }

        ProgressLine {
            anchors.left: parent.left
            anchors.right: valueLabel.left
            anchors.rightMargin: settings.effectiveContentSpacing
            anchors.bottom: parent.bottom
            theme: usageRow.theme
            settings: usageRow.settings
            value: usageRow.value / 100
            accentColor: usageRow.value >= 75 ? theme.warning : theme.accent
            opacity: 0.55
        }
    }

    component InfoRow: Item {
        id: infoRoot

        property var theme
        property var settings
        property string label: ""
        property string value: ""

        implicitHeight: Math.max(settings.controlHeight * 0.82, labelText.implicitHeight)

        Text {
            id: labelText

            anchors.left: parent.left
            anchors.right: valueText.left
            anchors.rightMargin: settings.effectiveContentSpacing
            anchors.verticalCenter: parent.verticalCenter
            text: infoRoot.label
            color: theme.textMuted
            elide: Text.ElideRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
        }

        Text {
            id: valueText

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.56
            text: infoRoot.value
            color: theme.text
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.Medium
        }
    }

    component Chip: Rectangle {
        id: chipRoot

        property var theme
        property var settings
        property string label: ""
        property real maxWidth: parent && parent.width ? parent.width : implicitWidth

        implicitWidth: chipText.implicitWidth + settings.effectivePillPadding * 2
        width: Math.min(implicitWidth, maxWidth)
        implicitHeight: settings.controlHeight
        radius: settings.effectivePillRadius
        color: theme.alpha(theme.accent, 0.10)
        border.color: theme.alpha(theme.accent, 0.22)
        border.width: settings.effectiveBorderWidth
        antialiasing: true

        Text {
            id: chipText

            anchors.centerIn: parent
            width: parent.width - settings.effectivePillPadding * 2
            text: chipRoot.label
            color: theme.text
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.Medium
        }
    }

    component ToggleRow: Item {
        id: toggleRoot

        property var theme
        property var settings
        property string label: ""
        property bool checked: false

        signal toggled(bool checked)

        implicitHeight: Math.max(settings.controlHeight, labelText.implicitHeight)

        Text {
            id: labelText

            anchors.left: parent.left
            anchors.right: toggle.left
            anchors.rightMargin: settings.effectivePillPadding
            anchors.verticalCenter: parent.verticalCenter
            text: toggleRoot.label
            color: theme.text
            elide: Text.ElideRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.Medium
        }

        Rectangle {
            id: toggle

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(settings.controlHeight * 1.72)
            height: Math.round(settings.controlHeight * 0.72)
            radius: height / 2
            color: toggleRoot.checked ? theme.surfaceActive : theme.alpha(theme.textMuted, 0.16)
            border.color: toggleRoot.checked ? theme.outlineActive : theme.outlineSubtle
            border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
            opacity: toggleRoot.enabled ? 1 : 0.35
            antialiasing: true

            Behavior on color { ColorAnimation { duration: settings.motionNormal } }
            Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }

            Rectangle {
                readonly property real knobMargin: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.5))

                width: parent.height - knobMargin * 2
                height: width
                radius: width / 2
                x: toggleRoot.checked ? parent.width - width - knobMargin : knobMargin
                y: knobMargin
                color: toggleRoot.checked ? theme.accent : theme.textMuted
                antialiasing: true

                Behavior on x {
                    enabled: settings.motionNormal > 0
                    SpringAnimation { spring: 4.0; damping: 0.8; epsilon: 0.2 }
                }

                Behavior on color { ColorAnimation { duration: settings.motionNormal } }
            }

            MouseArea {
                anchors.fill: parent
                enabled: toggleRoot.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: toggleRoot.toggled(!toggleRoot.checked)
            }
        }
    }

    component SliderRow: Item {
        id: sliderRoot

        property var theme
        property var settings
        property string label: ""
        property real value: 0
        property real minimum: 0
        property real maximum: 100
        property real step: 1
        property string suffix: ""
        property bool dragging: false
        property real liveValue: value

        signal valueRequested(real value)

        function clamped(number) {
            return Math.max(minimum, Math.min(maximum, number));
        }

        function snapped(number) {
            const safeStep = step > 0 ? step : 1;
            return clamped(minimum + Math.round((number - minimum) / safeStep) * safeStep);
        }

        function ratio() {
            if (maximum <= minimum) return 0;
            return (clamped(liveValue) - minimum) / (maximum - minimum);
        }

        onValueChanged: {
            if (!dragging)
                liveValue = value;
        }

        implicitHeight: labelText.implicitHeight + settings.effectiveContentSpacing + settings.controlHeight
        opacity: enabled ? 1 : 0.45

        Text {
            id: labelText

            anchors.left: parent.left
            anchors.right: valueText.left
            anchors.rightMargin: settings.effectiveContentSpacing
            anchors.top: parent.top
            text: sliderRoot.label
            color: theme.text
            elide: Text.ElideRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.Medium
        }

        Text {
            id: valueText

            anchors.right: parent.right
            anchors.top: parent.top
            width: Math.round(settings.effectiveFontSize * 6)
            text: Math.round(sliderRoot.liveValue) + sliderRoot.suffix
            color: theme.textMuted
            horizontalAlignment: Text.AlignRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.DemiBold
        }

        Item {
            id: trackArea

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: labelText.bottom
            anchors.topMargin: settings.effectiveContentSpacing
            height: settings.controlHeight

            Rectangle {
                id: track

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: Math.max(2, Math.round(settings.effectiveGroupPadding * 0.75))
                radius: height / 2
                color: theme.alpha(theme.text, 0.12)
                antialiasing: true

                Rectangle {
                    width: Math.max(0, knob.x + knob.width / 2)
                    height: parent.height
                    radius: parent.radius
                    color: theme.accentSoft
                    antialiasing: true
                }
            }

            Rectangle {
                id: knob

                width: Math.round(settings.controlHeight * 0.54)
                height: width
                radius: width / 2
                x: sliderRoot.ratio() * Math.max(0, trackArea.width - width)
                anchors.verticalCenter: parent.verticalCenter
                color: theme.accent
                border.color: theme.alpha(theme.text, 0.28)
                border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
                antialiasing: true

                Behavior on x { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                enabled: sliderRoot.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function commit(mouseX) {
                    if (trackArea.width <= 0) return;

                    const bounded = Math.max(0, Math.min(trackArea.width, mouseX));
                    const raw = sliderRoot.minimum + (bounded / trackArea.width) * (sliderRoot.maximum - sliderRoot.minimum);
                    const next = sliderRoot.snapped(raw);
                    const previous = sliderRoot.liveValue;
                    sliderRoot.liveValue = next;
                    if (Math.abs(next - previous) > 0.0001)
                        sliderRoot.valueRequested(next);
                }

                onPressed: function(mouse) {
                    sliderRoot.dragging = true;
                    commit(mouse.x);
                }
                onPositionChanged: function(mouse) { if (pressed) commit(mouse.x); }
                onReleased: {
                    sliderRoot.dragging = false;
                    sliderRoot.liveValue = sliderRoot.value;
                }
                onCanceled: {
                    sliderRoot.dragging = false;
                    sliderRoot.liveValue = sliderRoot.value;
                }
            }
        }
    }

    component TextInputRow: Item {
        id: inputRoot

        property var theme
        property var settings
        property string label: ""
        property string value: ""

        signal textRequested(string text)

        implicitHeight: labelText.implicitHeight + settings.effectiveContentSpacing + settings.controlHeight

        Text {
            id: labelText

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            text: inputRoot.label
            color: theme.text
            elide: Text.ElideRight
            font.family: settings.fontFamily
            font.pixelSize: settings.effectiveFontSize
            font.weight: Font.Medium
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: labelText.bottom
            anchors.topMargin: settings.effectiveContentSpacing
            height: settings.controlHeight
            radius: settings.effectivePillRadius
            color: editor.activeFocus ? theme.surfaceHover : theme.alpha(theme.text, 0.045)
            border.color: editor.activeFocus ? theme.outlineActive : theme.outlineSubtle
            border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
            antialiasing: true
            clip: true

            TextInput {
                id: editor

                anchors.fill: parent
                anchors.leftMargin: settings.effectivePillPadding
                anchors.rightMargin: settings.effectivePillPadding
                text: inputRoot.value
                color: theme.text
                selectionColor: theme.accentSoft
                selectedTextColor: theme.text
                font.family: settings.fontFamily
                font.pixelSize: settings.effectiveFontSize
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                onTextEdited: inputRoot.textRequested(editor.text)
            }
        }
    }

    component ActionButton: Rectangle {
        id: buttonRoot

        property var theme
        property var settings
        property string icon: ""
        property string label: ""
        property bool square: false
        property bool selected: false

        signal pressed()

        implicitWidth: square ? settings.controlHeight : buttonContent.implicitWidth + settings.effectivePillPadding * 2
        implicitHeight: settings.controlHeight
        radius: settings.effectivePillRadius
        color: selected ? theme.surfaceActive : buttonHover.containsMouse ? theme.surfaceHover : theme.alpha(theme.text, 0.035)
        border.color: selected ? theme.outlineActive : buttonHover.containsMouse ? theme.outlineActive : theme.outlineSubtle
        border.width: Math.max(1, Math.round(settings.effectiveGroupPadding * 0.25))
        scale: buttonHover.containsMouse ? 1.015 : 1
        antialiasing: true

        Behavior on color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on border.color { ColorAnimation { duration: settings.motionNormal } }
        Behavior on scale { NumberAnimation { duration: settings.motionHover; easing.type: Easing.OutCubic } }

        Row {
            id: buttonContent

            anchors.centerIn: parent
            height: parent.height
            spacing: settings.effectiveContentSpacing

            Text {
                height: parent.height
                text: buttonRoot.icon
                color: buttonRoot.selected ? theme.accent : theme.text
                font.family: settings.fontFamily
                font.pixelSize: settings.effectiveIconSize
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: buttonRoot.label.length > 0
                height: parent.height
                text: buttonRoot.label
                color: buttonRoot.selected ? theme.text : theme.textMuted
                font.family: settings.fontFamily
                font.pixelSize: settings.effectiveFontSize
                font.weight: buttonRoot.selected ? Font.DemiBold : Font.Medium
                verticalAlignment: Text.AlignVCenter
            }
        }

        MouseArea {
            id: buttonHover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: buttonRoot.pressed()
        }
    }
}
