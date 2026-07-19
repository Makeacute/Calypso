import QtQuick

Pill {
    id: root

    signal requested(var anchorItem)

    icon: "󰒓"
    clickable: true
    minimumWidth: Math.max(settings.moduleHeight, settings.effectiveIconSize + settings.effectivePillPadding * 2)
    onClicked: requested(root)
}
