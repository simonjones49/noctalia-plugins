import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI
import "I18n.js" as I18n
import "Ui.js" as Ui

Item {
  id: root

  required property var pluginApi

  visible: false
  width: 0
  height: 0

  readonly property var defaults: pluginApi && pluginApi.manifest && pluginApi.manifest.metadata
                                   ? (pluginApi.manifest.metadata.defaultSettings || {})
                                   : ({})
  readonly property var pluginSettings: pluginApi ? (pluginApi.pluginSettings || {}) : ({})
  readonly property string obsctlPath: pluginApi ? (pluginApi.pluginDir + "/scripts/obsctl") : ""
  readonly property string configuredVideosPath: pluginSettings.videosPath !== undefined
                                                 ? String(pluginSettings.videosPath).trim()
                                                 : String(defaults.videosPath !== undefined ? defaults.videosPath : "")
  readonly property string videosOpener: pluginSettings.videosOpener !== undefined
                                         ? String(pluginSettings.videosOpener).trim()
                                         : String(defaults.videosOpener !== undefined ? defaults.videosOpener : "xdg-open")
  readonly property string videosPath: configuredVideosPath !== ""
                                       ? configuredVideosPath
                                       : (Quickshell.env("XDG_VIDEOS_DIR") || ((Quickshell.env("HOME") || "") + "/Videos"))
  readonly property int pollIntervalMs: Math.max(
                                          750,
                                          Number(pluginSettings.pollIntervalMs !== undefined
                                                   ? pluginSettings.pollIntervalMs
                                                   : (defaults.pollIntervalMs !== undefined ? defaults.pollIntervalMs : 2500))
                                        )
  readonly property string leftClickAction: pluginSettings.leftClickAction !== undefined
                                            ? String(pluginSettings.leftClickAction)
                                            : String(defaults.leftClickAction !== undefined ? defaults.leftClickAction : "panel")
  readonly property string launchBehavior: pluginSettings.launchBehavior !== undefined
                                           ? String(pluginSettings.launchBehavior)
                                           : String(defaults.launchBehavior !== undefined ? defaults.launchBehavior : "minimized-to-tray")
  readonly property string barLabelMode: pluginSettings.barLabelMode !== undefined
                                         ? String(pluginSettings.barLabelMode)
                                         : String(defaults.barLabelMode !== undefined ? defaults.barLabelMode : "short-label")
  readonly property bool showBarWhenRecording: pluginSettings.showBarWhenRecording !== undefined
                                               ? Boolean(pluginSettings.showBarWhenRecording)
                                               : Boolean(defaults.showBarWhenRecording)
  readonly property bool showBarWhenReplay: pluginSettings.showBarWhenReplay !== undefined
                                            ? Boolean(pluginSettings.showBarWhenReplay)
                                            : Boolean(defaults.showBarWhenReplay)
  readonly property bool showBarWhenStreaming: pluginSettings.showBarWhenStreaming !== undefined
                                               ? Boolean(pluginSettings.showBarWhenStreaming)
                                               : Boolean(defaults.showBarWhenStreaming)
  readonly property bool showControlCenterWhenRecording: pluginSettings.showControlCenterWhenRecording !== undefined
                                                         ? Boolean(pluginSettings.showControlCenterWhenRecording)
                                                         : Boolean(defaults.showControlCenterWhenRecording)
  readonly property bool showControlCenterWhenReplay: pluginSettings.showControlCenterWhenReplay !== undefined
                                                      ? Boolean(pluginSettings.showControlCenterWhenReplay)
                                                      : Boolean(defaults.showControlCenterWhenReplay)
  readonly property bool showControlCenterWhenStreaming: pluginSettings.showControlCenterWhenStreaming !== undefined
                                                         ? Boolean(pluginSettings.showControlCenterWhenStreaming)
                                                         : Boolean(defaults.showControlCenterWhenStreaming)
  readonly property bool showControlCenterWhenReady: pluginSettings.showControlCenterWhenReady !== undefined
                                                     ? Boolean(pluginSettings.showControlCenterWhenReady)
                                                     : Boolean(defaults.showControlCenterWhenReady)
  readonly property bool autoCloseManagedObs: pluginSettings.autoCloseManagedObs !== undefined
                                              ? Boolean(pluginSettings.autoCloseManagedObs)
                                              : Boolean(defaults.autoCloseManagedObs !== undefined ? defaults.autoCloseManagedObs : true)
  readonly property bool openVideosAfterStop: pluginSettings.openVideosAfterStop !== undefined
                                              ? Boolean(pluginSettings.openVideosAfterStop)
                                              : Boolean(defaults.openVideosAfterStop !== undefined ? defaults.openVideosAfterStop : true)
  readonly property bool showElapsedInBar: pluginSettings.showElapsedInBar !== undefined
                                           ? Boolean(pluginSettings.showElapsedInBar)
                                           : Boolean(defaults.showElapsedInBar)

  property bool obsRunning: false
  property bool websocket: false
  property bool recording: false
  property bool replayBuffer: false
  property bool streaming: false
  property int recordDurationMs: 0
  property int streamDurationMs: 0
  property int displayRecordDurationMs: 0
  property int displayStreamDurationMs: 0
  readonly property bool connected: obsRunning && websocket
  readonly property var outputState: ({
    recording: recording,
    replayBuffer: replayBuffer,
    streaming: streaming,
    recordDurationMs: recordDurationMs,
    streamDurationMs: streamDurationMs,
  })
  readonly property var visibilitySettings: ({
    showBarWhenRecording: showBarWhenRecording,
    showBarWhenReplay: showBarWhenReplay,
    showBarWhenStreaming: showBarWhenStreaming,
    showControlCenterWhenRecording: showControlCenterWhenRecording,
    showControlCenterWhenReplay: showControlCenterWhenReplay,
    showControlCenterWhenStreaming: showControlCenterWhenStreaming,
    showControlCenterWhenReady: showControlCenterWhenReady,
  })
  readonly property bool showInBar: Ui.shouldShowInBar(outputState, visibilitySettings)
  readonly property bool showInControlCenter: Ui.shouldShowInControlCenter(outputState, visibilitySettings, connected)
  readonly property string primaryActionText: Ui.primaryActionText(tr, leftClickAction)

  function tr(key, fallback, interpolations) {
    return I18n.tr(pluginApi, key, fallback, interpolations);
  }

  function applyStatus(payload) {
    obsRunning = Boolean(payload && payload.obsRunning);
    websocket = Boolean(payload && payload.websocket);
    recording = Boolean(payload && payload.recording);
    replayBuffer = Boolean(payload && payload.replayBuffer);
    streaming = Boolean(payload && payload.streaming);
    recordDurationMs = Math.max(0, Number(payload && payload.recordDurationMs ? payload.recordDurationMs : 0));
    streamDurationMs = Math.max(0, Number(payload && payload.streamDurationMs ? payload.streamDurationMs : 0));
    displayRecordDurationMs = recording ? recordDurationMs : 0;
    displayStreamDurationMs = streaming ? streamDurationMs : 0;
    displayTimer.running = recording || streaming;
  }

  function resetStatus() {
    applyStatus({
      "obsRunning": false,
      "websocket": false,
      "recording": false,
      "replayBuffer": false,
      "streaming": false,
      "recordDurationMs": 0,
      "streamDurationMs": 0
    });
  }

  function refresh() {
    if (!statusProcess.running) {
      statusProcess.running = true;
    }
  }

  function runAction(action) {
    if (!actionProcess.running) {
      pendingAction = action;
      actionProcess.running = true;
    }
  }

  function launchObs() {
    runAction("launch");
  }

  function toggleRecord() {
    runAction("toggle-record");
  }

  function toggleReplay() {
    runAction("toggle-replay");
  }

  function toggleStream() {
    runAction("toggle-stream");
  }

  function saveReplay() {
    runAction("save-replay");
  }

  function openVideos() {
    if (videosPath !== "" && videosOpener !== "") {
      Quickshell.execDetached([videosOpener, videosPath]);
    }
  }

  function showActionToast(payload) {
    if (!payload) {
      return;
    }

    const translated = translatedActionPayload(payload);
    if (!translated.title) {
      return;
    }

    const actionLabel = payload.openVideos && openVideosAfterStop ? tr("toast.actions.open_videos", "Open Videos") : "";
    const actionCallback = payload.openVideos && openVideosAfterStop ? function () { root.openVideos(); } : null;
    ToastService.showNotice(translated.title, translated.body, "", 3200, actionLabel, actionCallback);
  }

  function translatedActionPayload(payload) {
    return Ui.toastPayload(tr, payload);
  }

  function showProcessErrorToast(detail) {
    const body = detail && detail !== ""
                 ? detail
                 : tr("toast.error.body", "Check the OBS helper output.");
    ToastService.showNotice(
      tr("toast.error.title", "OBS control failed"),
      body,
      "",
      4200
    );
  }

  function openControls(screen, anchorItem) {
    if (pluginApi && screen) {
      pluginApi.togglePanel(screen, anchorItem);
    }
  }

  function togglePanelFromIpc() {
    pluginApi?.withCurrentScreen(function(screen) {
      root.openControls(screen, null);
    });
  }

  function runPrimaryAction(screen, anchorItem) {
    if (leftClickAction === "toggle-record") {
      toggleRecord();
      return;
    }

    if (leftClickAction === "toggle-stream") {
      toggleStream();
      return;
    }

    openControls(screen, anchorItem);
  }

  function runSecondaryAction() {
    if (!obsRunning) {
      launchObs();
    } else if (connected) {
      toggleRecord();
    } else {
      refresh();
    }
  }

  function runMiddleAction() {
    if (connected) {
      toggleReplay();
    }
  }

  Component.onCompleted: refresh()

  property string pendingAction: ""

  Timer {
    id: actionRefreshTimer
    interval: 900
    running: false
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    id: pollTimer
    interval: root.pollIntervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: displayTimer
    interval: 1000
    running: false
    repeat: true
    onTriggered: {
      if (!root.recording) {
        root.displayRecordDurationMs = 0;
      }

      if (!root.streaming) {
        root.displayStreamDurationMs = 0;
      }

      if (!root.recording && !root.streaming) {
        running = false;
        return;
      }

      if (root.recording) {
        root.displayRecordDurationMs += 1000;
      }
      if (root.streaming) {
        root.displayStreamDurationMs += 1000;
      }
    }
  }

  IpcHandler {
    target: "plugin:obs-control"

    function togglePanel() {
      root.togglePanelFromIpc();
    }

    function refreshStatus() {
      root.refresh();
    }

    function launchObs() {
      root.launchObs();
    }

    function toggleRecord() {
      root.toggleRecord();
    }

    function toggleReplay() {
      root.toggleReplay();
    }

    function toggleStream() {
      root.toggleStream();
    }

    function saveReplay() {
      root.saveReplay();
    }

    function openVideos() {
      root.openVideos();
    }

    function primaryAction() {
      if (root.leftClickAction === "toggle-record") {
        root.toggleRecord();
        return;
      }
      if (root.leftClickAction === "toggle-stream") {
        root.toggleStream();
        return;
      }
      root.togglePanelFromIpc();
    }

    function secondaryAction() {
      root.runSecondaryAction();
    }

    function middleAction() {
      root.runMiddleAction();
    }
  }

  Process {
    id: actionProcess
    running: false
    command: pendingAction === ""
             ? []
             : [
                 root.obsctlPath,
                 "--launch-behavior", root.launchBehavior,
                 "--auto-close-managed", root.autoCloseManagedObs ? "true" : "false",
                 pendingAction
               ]
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode) {
      const output = String(stdout.text || "").trim();
      const errorOutput = String(stderr.text || "").trim();

      if (exitCode === 0 && output !== "") {
        try {
          root.showActionToast(JSON.parse(output));
        } catch (e) {}
      } else if (exitCode !== 0) {
        root.showProcessErrorToast(errorOutput);
      }

      pendingAction = "";
      actionRefreshTimer.restart();
    }
  }

  Process {
    id: statusProcess
    running: false
    command: [root.obsctlPath, "status"]
    stdout: StdioCollector {}

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.resetStatus();
        return;
      }

      try {
        root.applyStatus(JSON.parse(String(stdout.text || "").trim() || "{}"));
      } catch (e) {
        root.resetStatus();
      }
    }
  }
}
