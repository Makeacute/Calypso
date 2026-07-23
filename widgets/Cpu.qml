import QtQuick

Pill {
    id: root

    property var systemStatsService
    property var _consumerService: null
    readonly property bool graphEnabled: moduleSettings.showGraph === undefined
                                                  ? settings.cpuShowGraph
                                                  : Boolean(moduleSettings.showGraph)
    readonly property real usage: systemStatsService
                                          ? Number(systemStatsService.cpuUsage) || 0
                                          : 0
    readonly property var usageHistory: systemStatsService
                                            ? Array.from(systemStatsService.cpuHistory || []).slice(-12)
                                            : []

    icon: ""
    text: graphEnabled ? "" : Math.round(usage) + "%"
    detailText: settings.widgetStyle === "expanded" ? Math.round(usage) + "% load" : ""
    active: usage >= 75
    urgent: usage >= 92
    progress: graphEnabled ? -1 : usage / 100
    progressColor: theme.alpha(graphColor, 0.16)
    textPulseOnChange: !graphEnabled
    maximumTextWidth: graphEnabled ? theme.moduleGraphWidth : theme.moduleValueWidth
    showGraph: graphEnabled
    graphValues: usageHistory
    graphColor: urgent ? theme.urgent : active ? theme.warning : theme.accent
    detailsOnClick: true
    detailsModuleName: moduleInstanceId || "cpu"

    function registerConsumer() {
        if (_consumerService || !systemStatsService)
            return;
        _consumerService = systemStatsService;
        _consumerService.addConsumer();
    }

    function unregisterConsumer() {
        if (!_consumerService)
            return;
        _consumerService.removeConsumer();
        _consumerService = null;
    }

    onSystemStatsServiceChanged: {
        if (_consumerService !== systemStatsService) {
            unregisterConsumer();
            registerConsumer();
        }
    }
    Component.onCompleted: registerConsumer()
    Component.onDestruction: unregisterConsumer()
}
