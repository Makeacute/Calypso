import QtQuick

Pill {
    id: root

    icon: "󰒋"
    text: "Proc"
    detailText: "Tasks"
    tooltipText: "Processes"
    detailsOnClick: true
    detailsModuleName: "processes"
    minimumWidth: Math.max(settings.moduleHeight, settings.effectiveIconSize + settings.effectivePillPadding * 2)
}
