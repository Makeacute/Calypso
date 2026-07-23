import QtQuick

Pill {
    id: root

    property var systemStatsService
    property var _consumerService: null
    readonly property bool graphEnabled: moduleSettings.showGraph === undefined
                                                  ? settings.memoryShowGraph
                                                  : Boolean(moduleSettings.showGraph)
    readonly property real usedPercent: systemStatsService
                                                ? Number(systemStatsService.memoryUsedPercent) || 0
                                                : 0
    readonly property var usageHistory: systemStatsService
                                            ? Array.from(systemStatsService.memoryHistory || []).slice(-12)
                                            : []

    icon: ""
    text: graphEnabled ? "" : Math.round(usedPercent) + "%"
    detailText: settings.widgetStyle === "expanded" ? Math.round(usedPercent) + "% used" : ""
    active: usedPercent >= 75
    urgent: usedPercent >= 90
    progress: graphEnabled ? -1 : usedPercent / 100
    progressColor: theme.alpha(graphColor, 0.16)
    textPulseOnChange: !graphEnabled
    maximumTextWidth: graphEnabled ? theme.moduleGraphWidth : theme.moduleValueWidth
    showGraph: graphEnabled
    graphValues: usageHistory
    graphColor: urgent ? theme.urgent : active ? theme.warning : theme.accent
    detailsOnClick: true
    detailsModuleName: moduleInstanceId || "memory"

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
