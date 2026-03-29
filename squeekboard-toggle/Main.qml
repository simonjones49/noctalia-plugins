import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool keyboardActive: false

    // --- State checker ---
    Process {
        id: stateChecker
        command: ["gsettings", "get", "org.gnome.desktop.a11y.applications", "screen-keyboard-enabled"]
        stdout: SplitParser {
            onRead: data => {
                root.keyboardActive = data.trim() === "true"
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stateChecker.running = false
            stateChecker.running = true
        }
    }

    // --- Toggle process ---
    Process {
        id: toggleProcess
        onExited: recheckTimer.start()
    }

    Timer {
        id: recheckTimer
        interval: 500
        repeat: false
        onTriggered: {
            stateChecker.running = false
            stateChecker.running = true
        }
    }

    function toggleKeyboard() {
        toggleProcess.command = ["gsettings", "set", "org.gnome.desktop.a11y.applications", "screen-keyboard-enabled", root.keyboardActive ? "false" : "true"]
        toggleProcess.running = true
    }
}