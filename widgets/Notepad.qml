import QtQuick

Pill {
    id: root

    icon: "󰎞"
    text: "Note"
    detailText: "Scratchpad"
    tooltipText: "Notepad"
    detailsOnClick: true
    detailsModuleName: "notepad"
    minimumWidth: Math.max(settings.moduleHeight, settings.effectiveIconSize + settings.effectivePillPadding * 2)
}
