import QtQuick

Pill {
    id: root

    property var networkService
    property var _consumerService: null
    readonly property bool showSpeed: moduleSettings.showSpeed === undefined
                                          ? settings.networkShowSpeed
                                          : Boolean(moduleSettings.showSpeed)
    readonly property string device: networkService ? String(networkService.device || "") : ""
    readonly property string connectionName: networkService
                                                  ? String(networkService.connectionName || "")
                                                  : ""
    readonly property bool online: networkService ? Boolean(networkService.online) : false
    readonly property real rxRate: networkService ? Number(networkService.rxRate) || 0 : 0
    readonly property real txRate: networkService ? Number(networkService.txRate) || 0 : 0

    icon: online ? networkIcon(device) : "󰤮"
    text: networkText()
    detailText: settings.widgetStyle === "expanded" && online ? (showSpeed ? networkLabel() : speedText()) : ""
    muted: !online
    iconMorphOnChange: settings.iconMorphTransitions
    textPulseOnChange: true
    maximumTextWidth: showSpeed ? theme.moduleNetworkSpeedWidth : theme.moduleNetworkLabelWidth
    detailsOnClick: true
    detailsModuleName: moduleInstanceId || "network"

    function networkIcon(name) {
        const value = String(name || "").toLowerCase();
        if (value.startsWith("wl") || value.includes("wifi") || value.includes("wlan")) return "󰤨";
        if (value.startsWith("en") || value.includes("eth")) return "󰈀";
        return "󰌘";
    }

    function networkLabel() {
        const value = connectionName.trim();
        return value.length > 0 ? value : device;
    }

    function rateText(value) {
        const amount = Math.max(0, Number(value) || 0);
        if (amount < 1024) return Math.round(amount) + "B/s";
        if (amount < 1024 * 1024) return Math.round(amount / 1024) + "K/s";
        return (Math.round(amount / 1024 / 1024 * 10) / 10) + "M/s";
    }

    function speedText() {
        return "↓" + rateText(rxRate) + " ↑" + rateText(txRate);
    }

    function networkText() {
        if (!online) return "down";
        return showSpeed ? speedText() : networkLabel();
    }

    function registerConsumer() {
        if (_consumerService || !networkService)
            return;
        _consumerService = networkService;
        _consumerService.addConsumer();
    }

    function unregisterConsumer() {
        if (!_consumerService)
            return;
        _consumerService.removeConsumer();
        _consumerService = null;
    }

    onNetworkServiceChanged: {
        if (_consumerService !== networkService) {
            unregisterConsumer();
            registerConsumer();
        }
    }
    Component.onCompleted: registerConsumer()
    Component.onDestruction: unregisterConsumer()
}
