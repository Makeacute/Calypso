import QtQuick

Pill {
    id: root

    icon: "󰅌"
    text: "Clip"
    detailText: "History"
    tooltipText: "Clipboard history"
    detailsOnClick: true
    detailsModuleName: "clipboard"
    minimumWidth: Math.max(settings.moduleHeight, settings.effectiveIconSize + settings.effectivePillPadding * 2)
}
