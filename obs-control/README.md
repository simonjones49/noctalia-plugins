# OBS Control

OBS Studio controls for Noctalia Shell. The plugin adds a bar indicator, an optional Control Center shortcut, and a panel for recording, replay, and streaming actions.

## Requirements

- `obs-studio`
- OBS WebSocket enabled in OBS
- `node` available in `PATH`
- a Node.js runtime with built-in `WebSocket` support, such as current Node.js releases

## Installation

Open Noctalia Settings, go to `Plugins`, search for `OBS Control` in `Available`, and install it.

After enabling it, add `plugin:obs-control` to your bar or Control Center layout if you want the widget visible there.

## Features

- bar indicator for recording, replay, and streaming states, including combined active outputs
- optional Control Center shortcut when OBS is active
- panel with launch, refresh, recording, replay, streaming, save, and open-videos actions
- auto-close for OBS when the helper had to cold-launch it for recording, replay, or streaming and later stops the last active output
- elapsed recording and streaming timers in the panel
- configurable manual launch behavior, left-click behavior, bar label mode, toast behavior, and visibility rules
- native Noctalia toast actions after recording, replay, or stream transitions

## Keyboard Shortcuts

This plugin uses Noctalia IPC for compositor keybinds and external triggers.

Use Noctalia IPC directly from your compositor:

```bash
qs -c noctalia-shell ipc call plugin:obs-control togglePanel
qs -c noctalia-shell ipc call plugin:obs-control toggleRecord
qs -c noctalia-shell ipc call plugin:obs-control toggleReplay
qs -c noctalia-shell ipc call plugin:obs-control toggleStream
qs -c noctalia-shell ipc call plugin:obs-control saveReplay
```

Example `niri` binds:

```kdl
binds {
    Mod+F9 { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "plugin:obs-control" "toggleRecord"; }
    Mod+F10 { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "plugin:obs-control" "toggleReplay"; }
    Mod+Shift+F10 { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "plugin:obs-control" "saveReplay"; }
    Mod+F11 { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "plugin:obs-control" "toggleStream"; }
    Mod+F12 { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "plugin:obs-control" "togglePanel"; }
}
```

## Troubleshooting

- If OBS is running but the plugin says WebSocket control is unavailable, restart OBS once after enabling obs-websocket.
- Automatic recording, replay, and stream starts intentionally launch OBS minimized to the tray; the Launch OBS action is the only path that uses the configurable launch behavior.
- If Open Videos opens a terminal directory handler instead of a GUI file manager, set the Videos Opener setting to your file manager command, for example `nautilus`.
- If recording, replay, or streaming launched OBS automatically through this plugin, stopping the last active output through the same helper path will close OBS again for that session-managed launch.
- If actions do nothing, test `qs -c noctalia-shell ipc call plugin:obs-control refreshStatus` from a terminal in your session.
- If the plugin fails to talk to OBS, confirm `node` is in `PATH` for the graphical session as well as your shell.

## Screenshots

![OBS Control preview](preview.png)

![OBS Control settings](settings.png)
