import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets
import "I18n.js" as I18n
import "Ui.js" as Ui

NIconButtonHot {
  id: root

  property ShellScreen screen
  property var pluginApi

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property bool obsRunning: Boolean(service && service.obsRunning)
  readonly property bool websocket: Boolean(service && service.websocket)
  readonly property bool recording: Boolean(service && service.recording)
  readonly property bool replayBuffer: Boolean(service && service.replayBuffer)
  readonly property bool streaming: Boolean(service && service.streaming)
  readonly property bool connected: obsRunning && websocket
  readonly property string primaryActionText: service ? service.primaryActionText : "opens controls"
  readonly property string obsLogoSource: pluginApi ? ("file://" + pluginApi.pluginDir + "/assets/obs-logo.svg") : ""
  readonly property var outputState: ({
    recording: recording,
    replayBuffer: replayBuffer,
    streaming: streaming,
    recordDurationMs: 0,
    streamDurationMs: 0,
  })

  function tr(key, fallback, interpolations) {
    return I18n.tr(pluginApi, key, fallback, interpolations)
  }

  readonly property var activeOutputs: Ui.activeOutputs(tr, outputState, Color)
  readonly property bool hasActiveOutput: Ui.hasActiveOutputs(outputState)
  readonly property string currentIconName: Ui.primaryIcon(outputState)

  icon: ""
  hot: hasActiveOutput
  colorBgHot: Ui.accentBackgroundColor(outputState, Color, Color.mSecondary)
  colorFgHot: Ui.accentForegroundColor(outputState, Color, Color.mOnSecondary)
  tooltipText: Ui.controlCenterTooltip(tr, outputState, Color, connected, obsRunning, primaryActionText)

  NIcon {
    anchors.centerIn: parent
    visible: root.currentIconName !== ""
    icon: root.currentIconName
    pointSize: Math.max(1, Math.round(root.width * 0.48))
    color: {
      if ((root.enabled && root.hovering) || root.pressed) {
        return Color.mOnHover;
      }
      return Ui.accentForegroundColor(root.outputState, Color, Color.mOnSecondary);
    }
  }

  Image {
    anchors.centerIn: parent
    visible: root.currentIconName === ""
    source: root.obsLogoSource
    sourceSize.width: Math.round(root.width * 0.56)
    sourceSize.height: Math.round(root.height * 0.56)
    width: Math.round(root.width * 0.56)
    height: Math.round(root.height * 0.56)
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    asynchronous: true
    opacity: ((root.enabled && root.hovering) || root.pressed) ? 0.96 : 0.9
  }

  onClicked: {
    if (!service || !pluginApi || !screen) {
      return;
    }

    service.runPrimaryAction(screen, root);
  }

  onRightClicked: {
    if (!service) {
      return;
    }

    service.runSecondaryAction();
  }

  onMiddleClicked: {
    if (service) {
      service.runMiddleAction();
    }
  }

  Rectangle {
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.marginXS
    visible: root.activeOutputs.length > 1
    width: Math.max(14, Math.round(root.width * 0.3))
    height: width
    radius: width / 2
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: 1

    NText {
      anchors.centerIn: parent
      text: String(root.activeOutputs.length)
      pointSize: Math.max(1, Math.round(Style.fontSizeXS))
      font.weight: Style.fontWeightBold
      color: Color.mOnSurface
    }
  }
}
