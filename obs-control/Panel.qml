import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "I18n.js" as I18n
import "Ui.js" as Ui

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property string obsLogoSource: pluginApi ? ("file://" + pluginApi.pluginDir + "/assets/obs-logo.svg") : ""
  readonly property bool obsRunning: Boolean(service && service.obsRunning)
  readonly property bool websocket: Boolean(service && service.websocket)
  readonly property bool recording: Boolean(service && service.recording)
  readonly property bool replayBuffer: Boolean(service && service.replayBuffer)
  readonly property bool streaming: Boolean(service && service.streaming)
  readonly property int recordDurationMs: Number(service && service.displayRecordDurationMs ? service.displayRecordDurationMs : 0)
  readonly property int streamDurationMs: Number(service && service.displayStreamDurationMs ? service.displayStreamDurationMs : 0)
  readonly property bool connected: obsRunning && websocket
  readonly property bool autoCloseManagedObs: Boolean(service && service.autoCloseManagedObs)
  readonly property string primaryActionText: service ? service.primaryActionText : "opens controls"
  readonly property var outputState: ({
    recording: recording,
    replayBuffer: replayBuffer,
    streaming: streaming,
    recordDurationMs: recordDurationMs,
    streamDurationMs: streamDurationMs,
  })

  function tr(key, fallback, interpolations) {
    return I18n.tr(pluginApi, key, fallback, interpolations)
  }

  readonly property bool hasActiveOutputs: Ui.hasActiveOutputs(outputState)
  readonly property string activeOutputSummary: Ui.activeOutputSummary(tr, outputState, Color, " + ")
  readonly property color statusAccentColor: Ui.accentBackgroundColor(outputState, Color, Color.mOnSurface)

  property bool allowAttach: true
  property real contentPreferredWidth: Math.round(372 * Style.uiScaleRatio)
  property real contentPreferredHeight: content.implicitHeight + (Style.margin2L * 2)

  Item {
    id: panelContainer
    anchors.fill: parent

    ColumnLayout {
      id: content
      x: Style.marginL
      y: Style.marginL
      width: parent.width - (Style.margin2L)
      spacing: Style.marginL

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Image {
          source: root.obsLogoSource
          sourceSize.width: Math.round(Style.fontSizeXXL * 1.8)
          sourceSize.height: Math.round(Style.fontSizeXXL * 1.8)
          width: Math.round(Style.fontSizeXXL * 1.8)
          height: Math.round(Style.fontSizeXXL * 1.8)
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
          asynchronous: true
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXXS

          NText {
            text: root.tr("panel.header.title", "OBS Control")
            pointSize: Style.fontSizeXL
            font.weight: Style.fontWeightSemiBold
            color: Color.mPrimary
          }

          NText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Color.mOnSurfaceVariant
            text: Ui.panelHeaderText(root.tr, root.outputState, Color, connected, obsRunning)
          }
        }
      }

      NBox {
        Layout.fillWidth: true
        implicitHeight: statusColumn.implicitHeight + (Style.marginXL)

        ColumnLayout {
          id: statusColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginM
          spacing: Style.marginXS

          NText {
            Layout.fillWidth: true
            text: root.tr("panel.status.label", "Status") + ": " + Ui.panelStatusText(root.tr, root.outputState, Color, connected, obsRunning)
            font.weight: Style.fontWeightSemiBold
            color: statusAccentColor
          }

          NText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Color.mOnSurfaceVariant
            text: websocket
                  ? root.tr("panel.status.connected_hint", "Left click {primaryAction}. Right click toggles recording, middle click toggles replay, and the panel exposes streaming and save actions.", {
                      primaryAction: primaryActionText
                    })
                  : root.tr("panel.status.disconnected_hint", "WebSocket control is unavailable right now. Launch or restart OBS to restore quick actions.")
          }

          NText {
            Layout.fillWidth: true
            visible: recording && recordDurationMs > 0
            text: root.tr("panel.status.recording_elapsed", "Recording Time") + ": " + Ui.formatDuration(recordDurationMs)
            font.weight: Style.fontWeightMedium
            color: Color.mOnSurface
          }

          NText {
            Layout.fillWidth: true
            visible: streaming && streamDurationMs > 0
            text: root.tr("panel.status.streaming_elapsed", "Streaming Time") + ": " + Ui.formatDuration(streamDurationMs)
            font.weight: Style.fontWeightMedium
            color: Color.mOnSurface
          }

          NText {
            Layout.fillWidth: true
            visible: autoCloseManagedObs
            wrapMode: Text.WordWrap
            color: Color.mOnSurfaceVariant
            text: root.tr("panel.status.managed_hint", "Plugin-managed launches can close OBS after the last active recording, replay, or stream stops.")
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Style.marginM
        rowSpacing: Style.marginM

        NButton {
          Layout.fillWidth: true
          icon: obsRunning ? "refresh" : "player-play"
          text: !obsRunning
                ? root.tr("panel.actions.launch_obs", "Launch OBS")
                : root.tr("panel.actions.retry_connection", "Retry Connection")
          visible: !connected
          enabled: (!obsRunning || !websocket) && !actionBusy
          property bool actionBusy: Boolean(service && service.pendingAction !== "")
          onClicked: {
            if (!service) {
              return;
            }
            if (obsRunning) {
              service.refresh();
            } else {
              service.launchObs();
            }
          }
        }

        NButton {
          Layout.fillWidth: true
          icon: "player-record"
          text: recording
                ? root.tr("panel.actions.stop_recording", "Stop Recording")
                : root.tr("panel.actions.start_recording", "Start Recording")
          enabled: connected
          backgroundColor: recording ? Color.mError : Color.mPrimary
          textColor: recording ? Color.mOnError : Color.mOnPrimary
          onClicked: service && service.toggleRecord()
        }

        NButton {
          Layout.fillWidth: true
          icon: "antenna-bars-5"
          text: streaming
                ? root.tr("panel.actions.stop_streaming", "Stop Streaming")
                : root.tr("panel.actions.start_streaming", "Start Streaming")
          enabled: connected
          backgroundColor: streaming ? Color.mPrimary : Color.mSurfaceVariant
          textColor: streaming ? Color.mOnPrimary : Color.mOnSurface
          onClicked: service && service.toggleStream()
        }

        NButton {
          Layout.fillWidth: true
          icon: "history"
          text: replayBuffer
                ? root.tr("panel.actions.stop_replay", "Stop Replay")
                : root.tr("panel.actions.start_replay", "Start Replay")
          enabled: connected
          backgroundColor: replayBuffer ? Color.mSecondary : Color.mSurfaceVariant
          textColor: replayBuffer ? Color.mOnSecondary : Color.mOnSurface
          onClicked: service && service.toggleReplay()
        }

        NButton {
          Layout.fillWidth: true
          icon: "device-floppy"
          text: root.tr("panel.actions.save_replay", "Save Replay")
          enabled: replayBuffer
          outlined: !replayBuffer
          onClicked: service && service.saveReplay()
        }

        NButton {
          Layout.fillWidth: true
          icon: "folder"
          text: root.tr("panel.actions.open_videos", "Open Videos")
          outlined: true
          onClicked: service && service.openVideos()
        }

        NButton {
          Layout.fillWidth: true
          icon: "refresh"
          text: root.tr("panel.actions.refresh_status", "Refresh Status")
          outlined: true
          onClicked: service && service.refresh()
        }
      }
    }
  }
}
