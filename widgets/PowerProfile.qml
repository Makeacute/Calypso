import QtQuick

Pill {
    id: root

    property var powerProfileService
    readonly property bool showLabel: moduleSettings.showLabel === undefined
                                          ? settings.powerProfileShowLabel
                                          : Boolean(moduleSettings.showLabel)
    readonly property bool available: powerProfileService
                                          ? Boolean(powerProfileService.available)
                                          : false
    readonly property string profile: available ? String(powerProfileService.profile || "") : ""

    icon: profileIcon(profile)
    text: available && showLabel ? profile : ""
    detailText: settings.widgetStyle === "expanded" && available ? "power profile" : ""
    active: available && profile !== "balanced"
    muted: !available
    clickable: available
    accentColor: profile === "power-saver" ? theme.good
                 : profile === "performance" ? theme.warning
                                               : theme.accent
    iconFadeOnChange: true
    textPulseOnChange: available
    maximumTextWidth: theme.modulePowerProfileWidth
    onClicked: function(mouse) {
        cycleProfile();
    }

    function profileIcon(value) {
        if (value === "power-saver") return "";
        if (value === "performance") return "";
        if (value === "balanced") return "";
        return "󰚥";
    }

    function cycleProfile() {
        if (powerProfileService && available)
            powerProfileService.cycleProfile();
    }
}
