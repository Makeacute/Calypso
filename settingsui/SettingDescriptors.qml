import QtQuick

QtObject {
    id: root

    readonly property var entries: [
        {
            "page": "overview",
            "key": "overview",
            "title": "Overview",
            "description": "Identity, configuration summary, and service health",
            "tags": "calypso development schema repository config health services",
            "icon": "󰕮"
        },
        {
            "page": "bar",
            "key": "themeRecipe",
            "title": "Bar recipe",
            "description": "Apply a coordinated Calypso appearance recipe",
            "tags": "preset theme style",
            "icon": "󰓶"
        },
        {
            "page": "bar",
            "key": "barStyle",
            "title": "Bar style",
            "description": "Islands, solid, or pill composition",
            "tags": "layout shell surface",
            "icon": "󰓶"
        },
        {
            "page": "bar",
            "key": "barPosition",
            "title": "Bar position",
            "description": "Place the bar at the top or bottom",
            "tags": "edge screen",
            "icon": "󰓶"
        },
        {
            "page": "bar",
            "key": "widgetStyle",
            "title": "Widget style",
            "description": "Icon, text, and expanded module presentation",
            "tags": "modules labels icons expanded",
            "icon": "󰓶"
        },
        {
            "page": "bar",
            "key": "barHeight",
            "title": "Bar height",
            "description": "Adjust the bar's physical height",
            "tags": "size geometry",
            "icon": "󰓶"
        },
        {
            "page": "bar",
            "key": "screenMargin",
            "title": "Screen margin",
            "description": "Space between the bar and screen edge",
            "tags": "gap geometry",
            "icon": "󰓶"
        },
        {
            "page": "bar",
            "key": "barOpacity",
            "title": "Bar opacity",
            "description": "Tune surface transparency",
            "tags": "background translucent",
            "icon": "󰓶"
        },
        {
            "page": "bar",
            "key": "barBlur",
            "title": "Bar blur",
            "description": "Enable compositor blur behind the bar",
            "tags": "glass background",
            "icon": "󰓶"
        },
        {
            "page": "bar",
            "key": "barAutohide",
            "title": "Auto-hide",
            "description": "Reveal the bar on demand",
            "tags": "hide edge",
            "icon": "󰓶"
        },
        {
            "page": "bar",
            "key": "reserveSpace",
            "title": "Reserve space",
            "description": "Keep tiled windows clear of the bar",
            "tags": "exclusive zone niri",
            "icon": "󰓶"
        },
        {
            "page": "bar",
            "key": "groupSpacing",
            "title": "Group spacing",
            "description": "Space between bar groups",
            "tags": "layout gap",
            "icon": "󰓶"
        },
        {
            "page": "modules",
            "key": "modulePlacement",
            "title": "Module placement",
            "description": "Arrange modules in left, center, and right lanes",
            "tags": "reorder remove add lane section",
            "icon": "󱂬"
        },
        {
            "page": "modules",
            "key": "moduleCatalog",
            "title": "Module catalog",
            "description": "Browse registered Calypso modules",
            "tags": "registry enable configure cost capabilities",
            "icon": "󱂬"
        },
        {
            "page": "panels",
            "key": "osdEnabled",
            "title": "On-screen display",
            "description": "Configure volume, brightness, and system overlays",
            "tags": "osd overlay volume brightness battery",
            "icon": "󰕰"
        },
        {
            "page": "panels",
            "key": "dashboardPanelWidth",
            "title": "Dashboard panel",
            "description": "Configure dashboard behavior and width",
            "tags": "controls quick toggles media weather",
            "icon": "󰕰"
        },
        {
            "page": "panels",
            "key": "notificationsPanelWidth",
            "title": "Notifications panel",
            "description": "Configure notification grouping and content",
            "tags": "drawer cards body images actions",
            "icon": "󰕰"
        },
        {
            "page": "panels",
            "key": "launcherPanelWidth",
            "title": "Launcher panel",
            "description": "Configure app search and launcher results",
            "tags": "apps fuzzy descriptions icons",
            "icon": "󰕰"
        },
        {
            "page": "panels",
            "key": "clipboardPanelWidth",
            "title": "Clipboard panel",
            "description": "Configure history capacity and width",
            "tags": "cliphist history",
            "icon": "󰕰"
        },
        {
            "page": "panels",
            "key": "processPanelWidth",
            "title": "Process panel",
            "description": "Configure process rows and refresh",
            "tags": "tasks cpu memory temperature",
            "icon": "󰕰"
        },
        {
            "page": "personalization",
            "key": "paletteSource",
            "title": "Palette source",
            "description": "Choose wallpaper, Stylix, or manual colors",
            "tags": "matugen colors accent",
            "icon": "󰸌"
        },
        {
            "page": "personalization",
            "key": "matugenScheme",
            "title": "Matugen scheme",
            "description": "Select the generated Material color scheme",
            "tags": "tonal vibrant content expressive monochrome",
            "icon": "󰸌"
        },
        {
            "page": "personalization",
            "key": "surfaceStyle",
            "title": "Surface style",
            "description": "Control panel and module surface treatment",
            "tags": "frosted translucent solid",
            "icon": "󰸌"
        },
        {
            "page": "personalization",
            "key": "spacingScale",
            "title": "Spacing scale",
            "description": "Scale interface density",
            "tags": "compact roomy gap",
            "icon": "󰸌"
        },
        {
            "page": "personalization",
            "key": "radiusScale",
            "title": "Radius scale",
            "description": "Scale interface corner radii",
            "tags": "round sharp",
            "icon": "󰸌"
        },
        {
            "page": "personalization",
            "key": "fontFamilySans",
            "title": "Interface font",
            "description": "Set the UI typeface",
            "tags": "typography sans",
            "icon": "󰸌"
        },
        {
            "page": "personalization",
            "key": "animationProfile",
            "title": "Motion profile",
            "description": "Choose physical, snappy, calm, or instant motion",
            "tags": "animation duration reduce",
            "icon": "󰸌"
        },
        {
            "page": "system",
            "key": "performanceMode",
            "title": "Performance mode",
            "description": "Reduce rendering and background work",
            "tags": "cpu battery efficiency",
            "icon": "󰒓"
        },
        {
            "page": "system",
            "key": "reduceMotion",
            "title": "Reduce motion",
            "description": "Collapse token-derived animations to instant",
            "tags": "accessibility animation",
            "icon": "󰒓"
        },
        {
            "page": "system",
            "key": "compositorBackend",
            "title": "Compositor backend",
            "description": "Select automatic or Niri integration",
            "tags": "niri hyprland service",
            "icon": "󰒓"
        },
        {
            "page": "system",
            "key": "polling",
            "title": "Polling intervals",
            "description": "Tune fallback refresh intervals",
            "tags": "cpu memory network battery media",
            "icon": "󰒓"
        },
        {
            "page": "system",
            "key": "tooltipsEnabled",
            "title": "Tooltips",
            "description": "Control contextual labels and delay",
            "tags": "hover help",
            "icon": "󰒓"
        },
        {
            "page": "system",
            "key": "modulePopupPinned",
            "title": "Module details",
            "description": "Configure detail popups and history",
            "tags": "gauge sparkline pinned samples",
            "icon": "󰒓"
        }
    ]

    function moduleEntries(registry) {
        const source = registry && registry.entries ? Array.from(registry.entries) : [];
        return source.map(function (entry) {
            return {
                "page": "modules",
                "key": "module:" + String(entry.id || ""),
                "moduleName": String(entry.id || ""),
                "title": String(entry.label || entry.id || "Module"),
                "description": String(entry.category || "Module") + " module / " + String(entry.cost || "unknown"),
                "tags": [entry.id, entry.category, entry.cost].concat(Array.from(entry.aliases || [])).join(" ").toLowerCase(),
                "icon": String(entry.icon || "󰀻")
            };
        });
    }

    function search(query, registry) {
        const words = String(query || "").toLowerCase().trim().split(/\s+/).filter(Boolean);
        if (words.length === 0)
            return [];

        const candidates = Array.from(entries).concat(moduleEntries(registry));
        const matches = [];
        for (let i = 0; i < candidates.length; i++) {
            const entry = candidates[i];
            const haystack = String(entry.title + " " + entry.description + " " + entry.tags + " " + entry.key).toLowerCase();
            let score = 0;
            let matched = true;
            for (let wordIndex = 0; wordIndex < words.length; wordIndex++) {
                const word = words[wordIndex];
                const position = haystack.indexOf(word);
                if (position < 0) {
                    matched = false;
                    break;
                }
                score += position === 0 ? 3 : 1;
                if (String(entry.title).toLowerCase().indexOf(word) >= 0)
                    score += 2;
            }
            if (matched)
                matches.push({
                    "entry": entry,
                    "score": score
                });
        }

        matches.sort(function (left, right) {
            if (left.score !== right.score)
                return right.score - left.score;
            return String(left.entry.title).localeCompare(String(right.entry.title));
        });
        return matches.map(function (match) {
            return match.entry;
        });
    }
}
