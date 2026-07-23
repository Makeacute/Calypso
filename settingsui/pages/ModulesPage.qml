import QtQuick
import ".." as SettingsUi
import "../controls" as Controls

Item {
    id: root

    property var appContext
    property var settings
    property var theme
    property var registry
    property var targetScreen
    property var controller
    property string moduleName: controller ? controller.selectedModule : ""
    property string catalogSearch: ""
    readonly property var catalogEntries: filteredEntries()

    function filteredEntries() {
        const entries = registry && registry.entries ? Array.from(registry.entries) : settings && settings.moduleRegistry ? Array.from(settings.moduleRegistry) : [];
        const query = catalogSearch.toLowerCase().trim();
        if (query.length === 0)
            return entries;
        return entries.filter(function (entry) {
            const text = [entry.id, entry.label, entry.category, entry.cost].concat(Array.from(entry.aliases || [])).join(" ").toLowerCase();
            return text.indexOf(query) >= 0;
        });
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: page.implicitHeight + theme.settingsPagePadding * theme.settingsPagePaddingFactor
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: page

            width: Math.min(parent.width - theme.settingsPagePadding * theme.settingsPagePaddingFactor, theme.settingsPageMaxWidth)
            x: (parent.width - width) / 2
            y: theme.settingsPagePadding
            spacing: theme.spacingXL

            Controls.PageHeading {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Modules"
                subtitle: "Arrange each placement lane, control visibility, and configure registered modules."
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Placement"
                detail: "Order is applied immediately through the settings facade."
            }

            Grid {
                id: laneGrid

                width: parent.width
                columns: root.width < theme.settingsModuleLanesBreakpoint ? 1 : 3
                columnSpacing: theme.spacingM
                rowSpacing: theme.spacingM

                SettingsUi.PlacementLane {
                    width: (laneGrid.width - laneGrid.columnSpacing * (laneGrid.columns - 1)) / laneGrid.columns
                    theme: root.theme
                    settings: root.settings
                    controller: root.controller
                    sectionName: "left"
                    title: "Left lane"
                    icon: ""
                }

                SettingsUi.PlacementLane {
                    width: (laneGrid.width - laneGrid.columnSpacing * (laneGrid.columns - 1)) / laneGrid.columns
                    theme: root.theme
                    settings: root.settings
                    controller: root.controller
                    sectionName: "center"
                    title: "Center lane"
                    icon: ""
                }

                SettingsUi.PlacementLane {
                    width: (laneGrid.width - laneGrid.columnSpacing * (laneGrid.columns - 1)) / laneGrid.columns
                    theme: root.theme
                    settings: root.settings
                    controller: root.controller
                    sectionName: "right"
                    title: "Right lane"
                    icon: ""
                }
            }

            SettingsUi.ModuleConfig {
                width: parent.width
                visible: root.moduleName.length > 0
                theme: root.theme
                settings: root.settings
                controller: root.controller
                moduleName: root.moduleName
            }

            Controls.SectionHeader {
                width: parent.width
                theme: root.theme
                settings: root.settings
                title: "Registry catalog"
                detail: "Add a module to any lane or open its module-specific options."
            }

            Controls.SearchField {
                width: parent.width
                theme: root.theme
                settings: root.settings
                text: root.catalogSearch
                placeholderText: "Filter modules"
                onTextRequested: function (text) {
                    root.catalogSearch = text;
                }
            }

            Column {
                width: parent.width
                spacing: theme.spacingXS

                Repeater {
                    model: root.catalogEntries

                    SettingsUi.ModuleCatalogRow {
                        required property var modelData

                        width: parent.width
                        theme: root.theme
                        settings: root.settings
                        controller: root.controller
                        entry: modelData
                    }
                }
            }
        }
    }
}
