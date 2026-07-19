import QtQuick

Pill {
    id: root

    icon: "󰀻"
    text: "Apps"
    detailText: "Launcher"
    tooltipText: "App launcher"
    detailsOnClick: true
    detailsModuleName: "launcher"
    minimumWidth: Math.max(settings.moduleHeight, settings.effectiveIconSize + settings.effectivePillPadding * 2)
}
