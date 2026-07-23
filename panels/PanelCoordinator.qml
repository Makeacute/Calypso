import QtQml

QtObject {
    id: root

    property var registeredPanels: ({})
    property string activePanelId: ""
    readonly property var activePanel: activePanelId.length > 0
                                       ? registeredPanels[activePanelId] || null
                                       : null
    readonly property bool hasActivePanel: activePanel !== null
                                           && (activePanel.panelOpen === undefined
                                               || activePanel.panelOpen)

    signal panelRegistered(string panelId, var panel)
    signal panelUnregistered(string panelId, var panel)
    signal panelOpened(string panelId, var panel)
    signal panelClosed(string panelId, var panel)

    function normalizedId(panelId) {
        return String(panelId || "").trim();
    }

    function panel(panelId) {
        const id = normalizedId(panelId);
        return id.length > 0 ? registeredPanels[id] || null : null;
    }

    function isRegistered(panelId) {
        return panel(panelId) !== null;
    }

    function isActive(panelId) {
        const id = normalizedId(panelId);
        return id.length > 0 && activePanelId === id && activePanel !== null;
    }

    function register(panelId, panelObject) {
        const id = normalizedId(panelId);
        if (id.length <= 0 || !panelObject)
            return false;

        const current = registeredPanels[id] || null;
        if (current === panelObject)
            return true;

        if (current && activePanelId === id) {
            if (!invokeClose(current))
                return false;
            activePanelId = "";
            panelClosed(id, current);
        }

        const next = Object.assign({}, registeredPanels);
        next[id] = panelObject;
        registeredPanels = next;
        panelRegistered(id, panelObject);
        return true;
    }

    function unregister(panelId, panelObject) {
        const id = normalizedId(panelId);
        const current = panel(id);
        if (!current || (panelObject && current !== panelObject))
            return false;

        if (activePanelId === id) {
            activePanelId = "";
            panelClosed(id, current);
        }

        const next = Object.assign({}, registeredPanels);
        delete next[id];
        registeredPanels = next;
        panelUnregistered(id, current);
        return true;
    }

    function invokeOpen(panelObject, anchorItem, payload) {
        if (panelObject && typeof panelObject.openFromCoordinator === "function") {
            const result = panelObject.openFromCoordinator(anchorItem, payload);
            return result === undefined ? true : result !== false;
        }
        if (panelObject && typeof panelObject.open === "function") {
            const result = panelObject.open(anchorItem, payload);
            return result === undefined ? true : result !== false;
        }
        return false;
    }

    function invokeClose(panelObject) {
        if (panelObject && typeof panelObject.closeFromCoordinator === "function") {
            const result = panelObject.closeFromCoordinator();
            return result === undefined ? true : result !== false;
        }
        if (panelObject && typeof panelObject.close === "function") {
            const result = panelObject.close();
            return result === undefined ? true : result !== false;
        }
        return false;
    }

    function open(panelId, anchorItem, payload) {
        const id = normalizedId(panelId);
        const target = panel(id);
        if (!target)
            return false;

        if (activePanelId.length > 0 && activePanelId !== id) {
            const previousId = activePanelId;
            const previous = activePanel;
            if (!invokeClose(previous))
                return false;
            activePanelId = "";
            panelClosed(previousId, previous);
        }

        activePanelId = id;
        if (!invokeOpen(target, anchorItem, payload)) {
            activePanelId = "";
            return false;
        }

        panelOpened(id, target);
        return true;
    }

    function toggle(panelId, anchorItem, payload) {
        if (isActive(panelId)) {
            const target = panel(panelId);
            if (target && target.panelOpen === false) {
                activePanelId = "";
                panelClosed(normalizedId(panelId), target);
            } else {
                return close(panelId);
            }
        }
        return open(panelId, anchorItem, payload);
    }

    function close(panelId) {
        const requestedId = normalizedId(panelId);
        const id = requestedId.length > 0 ? requestedId : activePanelId;
        const target = panel(id);
        if (!target)
            return false;

        const closed = invokeClose(target);
        if (!closed)
            return false;

        if (activePanelId === id)
            activePanelId = "";
        panelClosed(id, target);
        return true;
    }

    function closeAll() {
        const panels = registeredPanels;
        const ids = Object.keys(panels);
        const previouslyActive = activePanelId;
        activePanelId = "";

        let closedAny = false;
        for (let index = 0; index < ids.length; index++) {
            const id = ids[index];
            const target = panels[id];
            if (!target)
                continue;
            const wasOpen = id === previouslyActive
                            || target.panelOpen
                            || target.panelClosing;
            if (invokeClose(target) && wasOpen) {
                closedAny = true;
                panelClosed(id, target);
            }
        }
        return closedAny;
    }
}
