pragma ComponentBehavior: Bound

import Quickshell

Scope {
    id: root

    readonly property var context: appContext

    AppContext {
        id: appContext

        bars: barVariants.instances
    }

    Variants {
        id: barVariants

        model: Quickshell.screens
        delegate: Bar {
            appContext: root.context
        }
    }
}
