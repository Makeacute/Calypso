import QtQuick
import Quickshell.Bluetooth

Pill {
    id: root

    property var adapter: Bluetooth.defaultAdapter
    property var devices: Bluetooth.devices.values
    readonly property bool hasAdapter: typeof adapter !== "undefined" && adapter !== null
    readonly property var connectedDevices: connectedFor(devices)
    readonly property int connectedCount: connectedDevices.length
    readonly property int adapterState: hasAdapter ? adapter.state : BluetoothAdapterState.Disabled

    icon: bluetoothIcon()
    text: bluetoothText()
    detailText: settings.widgetStyle === "expanded" && connectedCount > 0 ? connectedCount + " connected" : ""
    active: connectedCount > 0
    muted: !hasAdapter || adapterState === BluetoothAdapterState.Disabled || adapterState === BluetoothAdapterState.Blocked
    urgent: hasAdapter && adapterState === BluetoothAdapterState.Blocked
    iconFadeOnChange: true
    textPulseOnChange: true
    maximumTextWidth: 88
    detailsOnClick: true
    detailsModuleName: "bluetooth"

    function connectedFor(values) {
        const list = values || [];
        const connected = [];

        for (let i = 0; i < list.length; i++) {
            const device = list[i];
            if (device && device.connected) connected.push(device);
        }

        return connected;
    }

    function shortName(value, fallback) {
        const text = String(value || fallback || "").trim();
        if (text.length <= 0) return "device";
        return text.length > 10 ? text.slice(0, 10) : text;
    }

    function deviceName(device) {
        if (!device) return "device";
        return shortName(device.name || device.deviceName || device.address, "device");
    }

    function bluetoothIcon() {
        if (!hasAdapter || adapterState === BluetoothAdapterState.Disabled) return "󰂲";
        if (adapterState === BluetoothAdapterState.Blocked) return "󰂲";
        if (connectedCount > 0) return "󰂱";
        return "󰂯";
    }

    function bluetoothText() {
        if (!hasAdapter) return "none";
        if (adapterState === BluetoothAdapterState.Blocked) return "blocked";
        if (adapterState === BluetoothAdapterState.Disabled) return "off";
        if (adapterState === BluetoothAdapterState.Enabling) return "on...";
        if (adapterState === BluetoothAdapterState.Disabling) return "off...";
        if (connectedCount === 1) return deviceName(connectedDevices[0]);
        if (connectedCount > 1) return connectedCount + " dev";
        return "on";
    }
}
