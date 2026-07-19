import QtQuick
import Quickshell

QtObject {
    property var desktopEntryCache: ({})
    property var iconNameCache: ({})
    property var iconSourceCache: ({})
    property var displayNameCache: ({})

    function normalizedAppId(id) {
        return String(id || "").replace(/\.desktop$/i, "").trim();
    }

    function desktopEntry(id) {
        const key = normalizedAppId(id);
        if (key.length === 0) return null;
        if (desktopEntryCache[key] !== undefined)
            return desktopEntryCache[key];

        const candidates = [key, key + ".desktop"];
        for (let i = 0; i < candidates.length; i++) {
            const entry = DesktopEntries.byId(candidates[i]);
            if (entry) {
                desktopEntryCache[key] = entry;
                return entry;
            }
        }

        desktopEntryCache[key] = null;
        return null;
    }

    function mappedIconName(id) {
        const key = normalizedAppId(id).toLowerCase();
        if (key.length === 0) return "application-x-executable";
        if (key.includes("firefox")) return "firefox";
        if (key.includes("librewolf")) return "librewolf";
        if (key.includes("zen")) return "zen-browser";
        if (key.includes("chromium")) return "chromium";
        if (key.includes("chrome")) return "google-chrome";
        if (key.includes("brave")) return "brave-browser";
        if (key.includes("vivaldi")) return "vivaldi";
        if (key.includes("codium")) return "vscodium";
        if (key === "code" || key.includes("visual-studio-code")) return "com.visualstudio.code";
        if (key.includes("foot")) return "foot";
        if (key.includes("kitty")) return "kitty";
        if (key.includes("alacritty")) return "Alacritty";
        if (key.includes("wezterm")) return "org.wezfurlong.wezterm";
        if (key.includes("terminal")) return "utilities-terminal";
        if (key.includes("thunar")) return "Thunar";
        if (key.includes("nautilus")) return "org.gnome.Nautilus";
        if (key.includes("dolphin") || key.includes("files")) return "system-file-manager";
        if (key.includes("obsidian")) return "obsidian";
        if (key.includes("spotify")) return "spotify";
        if (key.includes("discord")) return "discord";
        if (key.includes("telegram")) return "telegram";
        if (key.includes("steam")) return "steam";
        if (key.includes("mpv")) return "mpv";
        if (key.includes("vlc")) return "vlc";
        if (key.includes("gimp")) return "gimp";
        if (key.includes("krita")) return "krita";
        return key;
    }

    function fallbackIconName(id) {
        const key = normalizedAppId(id).toLowerCase();
        if (key.includes("foot") || key.includes("kitty") || key.includes("alacritty") || key.includes("wezterm") || key.includes("terminal"))
            return "utilities-terminal";
        if (key.includes("thunar") || key.includes("nautilus") || key.includes("dolphin") || key.includes("files"))
            return "system-file-manager";
        return "application-x-executable";
    }

    function iconName(id) {
        const key = normalizedAppId(id).toLowerCase();
        if (iconNameCache[key] !== undefined)
            return iconNameCache[key];

        const mapped = mappedIconName(id);
        if (mapped !== key && mapped !== "application-x-executable") {
            iconNameCache[key] = mapped;
            return mapped;
        }

        const entry = desktopEntry(id);
        if (entry && String(entry.icon || "").length > 0) {
            iconNameCache[key] = entry.icon;
            return entry.icon;
        }

        iconNameCache[key] = mapped;
        return mapped;
    }

    function source(id) {
        const key = normalizedAppId(id).toLowerCase();
        if (iconSourceCache[key] !== undefined)
            return iconSourceCache[key];

        const primaryName = iconName(id);
        if (Quickshell.hasThemeIcon(primaryName)) {
            const primarySource = Quickshell.iconPath(primaryName, true);
            iconSourceCache[key] = primarySource;
            return primarySource;
        }

        const fallbackName = fallbackIconName(id);
        if (Quickshell.hasThemeIcon(fallbackName)) {
            const fallbackSource = Quickshell.iconPath(fallbackName, true);
            iconSourceCache[key] = fallbackSource;
            return fallbackSource;
        }

        iconSourceCache[key] = "";
        return "";
    }

    function displayName(id) {
        const key = normalizedAppId(id).toLowerCase();
        if (displayNameCache[key] !== undefined)
            return displayNameCache[key];

        const entry = desktopEntry(id);
        if (entry && String(entry.name || "").length > 0) {
            displayNameCache[key] = entry.name;
            return entry.name;
        }

        const text = normalizedAppId(id).replace(/-/g, " ");
        const fallbackName = text.length === 0 ? "Desktop" : text.charAt(0).toUpperCase() + text.slice(1);
        displayNameCache[key] = fallbackName;
        return fallbackName;
    }

    function initial(id) {
        const name = displayName(id).replace(/[^A-Za-z0-9]/g, "");
        return name.length > 0 ? name.charAt(0).toUpperCase() : "";
    }
}
