pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var settings
    property var osd: null
    property var wallpapers: []
    property string pendingPalette: ""
    property string pendingWallpaper: ""
    readonly property bool scanning: scanProc.running
    readonly property bool applying: wallpaperProc.running || paletteProc.running || paletteWriteProc.running
    readonly property string lastError: settings ? settings.wallpaperLastError : ""

    function cleanHex(value, fallback) {
        const safeFallback = String(fallback || "000000").replace("#", "");
        const text = String(value || safeFallback).replace("#", "");
        return /^[0-9a-fA-F]{6}$/.test(text) ? text.toLowerCase() : safeFallback.toLowerCase();
    }

    function basename(path) {
        const parts = String(path || "").split("/");
        return parts.length > 0 ? parts[parts.length - 1] : "";
    }

    function dirname(path) {
        const text = String(path || "");
        const index = text.lastIndexOf("/");
        return index > 0 ? text.slice(0, index) : "";
    }

    function setError(message) {
        if (settings) settings.setString("wallpaperLastError", String(message || ""));
    }

    function markApplied(path) {
        if (!settings) return;
        settings.setString("currentWallpaper", path);
        settings.setString("wallpaperSelectedPreview", path);
        settings.setString("wallpaperLastApplied", new Date().toISOString());
    }

    function favoriteList() {
        return Array.from(settings ? settings.wallpaperFavorites || [] : []);
    }

    function isFavorite(path) {
        return favoriteList().indexOf(String(path || "")) >= 0;
    }

    function toggleFavorite(path) {
        if (!settings || String(path || "").length <= 0) return;
        settings.toggleStringInList("wallpaperFavorites", path);
        decorateWallpapers();
    }

    function transitionType() {
        const choices = ["none", "simple", "fade", "left", "right", "top", "bottom", "wipe", "wave", "grow", "center", "any", "outer", "random"];
        const value = settings && !settings.reduceMotion ? String(settings.wallpaperTransition || "grow") : "none";
        return choices.indexOf(value) >= 0 ? value : "grow";
    }

    function resizeMode() {
        const choices = ["no", "crop", "fit", "stretch"];
        const value = settings ? String(settings.wallpaperResizeMode || "crop") : "crop";
        return choices.indexOf(value) >= 0 ? value : "crop";
    }

    function cropGravity() {
        const choices = ["top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"];
        const value = settings ? String(settings.wallpaperCropGravity || "center") : "center";
        return choices.indexOf(value) >= 0 ? value : "center";
    }

    function transitionPosition() {
        const value = settings ? String(settings.wallpaperTransitionPosition || "center") : "center";
        return value.length > 0 ? value : "center";
    }

    function transitionDuration() {
        const value = settings ? Number(settings.wallpaperTransitionDuration) : 1;
        if (settings && settings.reduceMotion) return "0";
        return String(Math.max(0.1, Math.min(10, Number.isFinite(value) ? value : 1)));
    }

    function transitionFps() {
        const value = settings ? Number(settings.wallpaperTransitionFps) : 60;
        return String(Math.max(15, Math.min(120, Math.round(Number.isFinite(value) ? value : 60))));
    }

    function transitionAngle() {
        const value = settings ? Number(settings.wallpaperTransitionAngle) : 45;
        return String(Math.max(0, Math.min(360, Math.round(Number.isFinite(value) ? value : 45))));
    }

    function transitionBezier() {
        const value = settings ? String(settings.wallpaperTransitionBezier || ".54,0,.34,.99") : ".54,0,.34,.99";
        return value.length > 0 ? value : ".54,0,.34,.99";
    }

    function decorateWallpapers() {
        const favs = favoriteList();
        const current = settings ? String(settings.currentWallpaper || "") : "";
        const next = [];
        for (let i = 0; i < wallpapers.length; i++) {
            const entry = wallpapers[i];
            const path = typeof entry === "string" ? entry : String(entry.path || "");
            if (path.length <= 0) continue;
            next.push({
                "path": path,
                "name": basename(path),
                "folder": dirname(path),
                "favorite": favs.indexOf(path) >= 0,
                "current": current === path
            });
        }
        wallpapers = next;
    }

    function filtered(query, favoritesOnly) {
        const q = String(query || "").toLowerCase();
        const list = Array.from(wallpapers || []);
        const out = [];
        for (let i = 0; i < list.length; i++) {
            const item = list[i];
            if (favoritesOnly && !item.favorite) continue;
            if (q.length > 0 && String(item.name + " " + item.folder).toLowerCase().indexOf(q) < 0) continue;
            out.push(item);
        }
        return out;
    }

    function randomCandidates() {
        const mode = settings ? String(settings.wallpaperRandomMode || "any") : "any";
        const base = filtered("", mode === "favorites");
        if (base.length <= 0) return filtered("", false);

        if (mode === "light" || mode === "dark") {
            const tagged = [];
            for (let i = 0; i < base.length; i++) {
                const text = String(base[i].name + " " + base[i].folder).toLowerCase();
                if (text.indexOf(mode) >= 0) tagged.push(base[i]);
            }
            return tagged.length > 0 ? tagged : base;
        }

        if (mode === "dominantColor") {
            const colorful = [];
            const hints = ["color", "vibrant", "neon", "pastel", "gradient", "flower", "city", "sky"];
            for (let i = 0; i < base.length; i++) {
                const text = String(base[i].name + " " + base[i].folder).toLowerCase();
                for (let h = 0; h < hints.length; h++) {
                    if (text.indexOf(hints[h]) >= 0) {
                        colorful.push(base[i]);
                        break;
                    }
                }
            }
            return colorful.length > 0 ? colorful : base;
        }

        return base;
    }

    function scan() {
        if (!settings || scanProc.running) return;

        setError("");
        const depth = settings.wallpaperRecursive ? "" : "-maxdepth 1";
        scanProc.command = [
            "sh",
            "-c",
            "dir=$1; depth=$2; [ -d \"$dir\" ] || exit 0; find \"$dir\" $depth -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort -u | head -300",
            "sh",
            settings.wallpaperDirectory,
            depth
        ];
        scanProc.running = true;
    }

    function apply(path, withColors) {
        const image = String(path || "");
        if (!settings || image.length <= 0 || wallpaperProc.running) return;

        setError("");
        pendingWallpaper = image;
        markApplied(image);

        if (settings.wallpaperBackend === "awww") {
            wallpaperProc.command = [
                "sh",
                "-c",
                "img=$1; resize=$2; gravity=$3; transition=$4; duration=$5; fps=$6; pos=$7; angle=$8; bezier=$9; if ! command -v awww >/dev/null 2>&1; then printf 'awww is not installed\\n' >&2; exit 127; fi; if command -v awww-daemon >/dev/null 2>&1 && ! pgrep -x awww-daemon >/dev/null 2>&1; then awww-daemon >/tmp/calypso-awww.log 2>&1 & sleep 0.2; fi; set -- awww img \"$img\" --resize \"$resize\" --crop-gravity \"$gravity\" --transition-type \"$transition\" --transition-duration \"$duration\" --transition-fps \"$fps\" --transition-bezier \"$bezier\"; case \"$transition\" in wipe|wave) set -- \"$@\" --transition-angle \"$angle\" ;; grow|center|any|outer) set -- \"$@\" --transition-pos \"$pos\" ;; esac; exec \"$@\"",
                "sh",
                image,
                resizeMode(),
                cropGravity(),
                transitionType(),
                transitionDuration(),
                transitionFps(),
                transitionPosition(),
                transitionAngle(),
                transitionBezier()
            ];
        } else {
            wallpaperProc.command = ["sh", "-c", "printf 'Unsupported wallpaper backend: %s\\n' \"$1\" >&2; exit 2", "sh", settings.wallpaperBackend];
        }

        wallpaperProc.running = true;

        if (withColors && settings.wallpaperApplyColors && settings.matugenEnabled)
            generatePalette(image);
    }

    function applyRandom(favoritesOnly) {
        const list = favoritesOnly ? filtered("", true) : randomCandidates();
        if (list.length <= 0) return;
        const index = Math.floor(Math.random() * list.length);
        apply(list[index].path, true);
    }

    function colorFromBucket(bucket, fallback) {
        if (!bucket) return fallback;
        if (typeof bucket === "string") return bucket;

        const mode = settings ? String(settings.matugenMode || "dark") : "dark";
        const selected = bucket[mode] || bucket.default || bucket.dark || bucket.light || bucket;
        if (typeof selected === "string") return selected;
        if (selected && selected.color) return selected.color;
        return fallback;
    }

    function materialColor(colors, name, fallback) {
        return colorFromBucket(colors ? colors[name] : null, fallback);
    }

    function base16Color(base16, name, fallback) {
        const lower = name.toLowerCase();
        const upper = name.toUpperCase();
        return colorFromBucket(base16 ? (base16[name] || base16[lower] || base16[upper]) : null, fallback);
    }

    function paletteFromMatugen(text) {
        const raw = JSON.parse(String(text || "{}"));
        const colors = raw.colors || {};
        const base16 = raw.base16 || {};

        return {
            "base00": cleanHex(materialColor(colors, "background", base16Color(base16, "base00", "111318")), "111318"),
            "base01": cleanHex(materialColor(colors, "surface_container_lowest", base16Color(base16, "base01", "1a1a1a")), "1a1a1a"),
            "base02": cleanHex(materialColor(colors, "surface_container_low", base16Color(base16, "base02", "222222")), "222222"),
            "base03": cleanHex(materialColor(colors, "outline", base16Color(base16, "base03", "8d9199")), "8d9199"),
            "base04": cleanHex(materialColor(colors, "on_surface_variant", base16Color(base16, "base04", "c4c6cf")), "c4c6cf"),
            "base05": cleanHex(materialColor(colors, "on_surface", base16Color(base16, "base05", "e2e2e9")), "e2e2e9"),
            "base06": cleanHex(materialColor(colors, "inverse_on_surface", base16Color(base16, "base06", "f0f0f7")), "f0f0f7"),
            "base07": cleanHex(materialColor(colors, "surface_bright", base16Color(base16, "base07", "ffffff")), "ffffff"),
            "base08": cleanHex(materialColor(colors, "error", base16Color(base16, "base08", "ffb4ab")), "ffb4ab"),
            "base09": cleanHex(materialColor(colors, "tertiary", base16Color(base16, "base09", "d6bee4")), "d6bee4"),
            "base0A": cleanHex(materialColor(colors, "secondary", base16Color(base16, "base0A", "bec6dc")), "bec6dc"),
            "base0B": cleanHex(materialColor(colors, "primary", base16Color(base16, "base0B", "bec2ff")), "bec2ff"),
            "base0C": cleanHex(materialColor(colors, "tertiary_container", base16Color(base16, "base0C", "5d4670")), "5d4670"),
            "base0D": cleanHex(materialColor(colors, "primary", base16Color(base16, "base0D", "bec2ff")), "bec2ff"),
            "base0E": cleanHex(materialColor(colors, "secondary", base16Color(base16, "base0E", "bec6dc")), "bec6dc"),
            "base0F": cleanHex(materialColor(colors, "primary_container", base16Color(base16, "base0F", "464a77")), "464a77"),
            "author": "matugen",
            "scheme": "calypso-wallpaper",
            "slug": "calypso"
        };
    }

    function generatePalette(path) {
        if (!settings || paletteProc.running) return;

        const mode = ["dark", "light"].indexOf(settings.matugenMode) >= 0 ? settings.matugenMode : "dark";
        const schemeChoices = ["scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-tonal-spot", "scheme-vibrant"];
        const scheme = schemeChoices.indexOf(settings.matugenScheme) >= 0 ? settings.matugenScheme : "scheme-tonal-spot";
        paletteProc.command = ["matugen", "image", path, "--json", "hex", "--mode", mode, "--type", scheme, "--prefer", "saturation", "--dry-run"];
        paletteProc.running = true;
    }

    Process {
        id: scanProc

        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                const lines = String(text || "").split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const path = lines[i].trim();
                    if (path.length > 0)
                        list.push({ "path": path, "name": root.basename(path), "folder": root.dirname(path), "favorite": root.isFavorite(path), "current": root.settings && root.settings.currentWallpaper === path });
                }
                root.wallpapers = list;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) root.setError(text.trim())
        }
    }

    Process {
        id: wallpaperProc

        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) root.setError(text.trim())
        }
        onExited: code => {
            if (code === 0) {
                root.decorateWallpapers();
            }
        }
    }

    Process {
        id: paletteProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const palette = root.paletteFromMatugen(text);
                    root.pendingPalette = JSON.stringify(palette, null, 2) + "\n";
                    paletteWriteProc.command = [
                        "sh",
                        "-c",
                        "data=$1; target=$2; dir=$(dirname \"$target\"); mkdir -p \"$dir\"; tmp=\"$target.tmp\"; printf '%s' \"$data\" > \"$tmp\" && mv \"$tmp\" \"$target\"",
                        "sh",
                        root.pendingPalette,
                        root.settings ? root.settings.palettePath : Quickshell.env("HOME") + "/.config/quickshell/palette.json"
                    ];
                    paletteWriteProc.running = true;
                } catch (error) {
                    root.setError("Could not parse matugen colors: " + error);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) root.setError(text.trim())
        }
    }

    Process {
        id: paletteWriteProc

        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) root.setError(text.trim())
        }
        onExited: code => {
            if (code === 0 && root.settings)
                root.settings.setString("wallpaperLastPalette", new Date().toISOString());
        }
    }

    Component.onCompleted: scan()

    Connections {
        target: settings
        function onWallpaperDirectoryChanged() { root.scan(); }
        function onWallpaperRecursiveChanged() { root.scan(); }
        function onWallpaperFavoritesChanged() { root.decorateWallpapers(); }
        function onCurrentWallpaperChanged() { root.decorateWallpapers(); }
    }
}
