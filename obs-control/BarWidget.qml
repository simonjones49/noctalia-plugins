import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "I18n.js" as I18n
import "Ui.js" as Ui

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property bool obsRunning: Boolean(service && service.obsRunning)
  readonly property bool websocket: Boolean(service && service.websocket)
  readonly property bool recording: Boolean(service && service.recording)
  readonly property bool replayBuffer: Boolean(service && service.replayBuffer)
  readonly property bool streaming: Boolean(service && service.streaming)
  readonly property int recordDurationMs: Number(service && service.displayRecordDurationMs ? service.displayRecordDurationMs : 0)
  readonly property int streamDurationMs: Number(service && service.displayStreamDurationMs ? service.displayStreamDurationMs : 0)
  readonly property string primaryActionText: service ? service.primaryActionText : "opens controls"
  readonly property string obsLogoSource: pluginApi ? ("file://" + pluginApi.pluginDir + "/assets/obs-logo.svg") : ""
  readonly property string barLabelMode: service ? String(service.barLabelMode) : "short-label"
  readonly property bool showElapsedInBar: Boolean(service && service.showElapsedInBar)
  readonly property var outputState: ({
    recording: recording,
    replayBuffer: replayBuffer,
    streaming: streaming,
    recordDurationMs: recordDurationMs,
    streamDurationMs: streamDurationMs,
  })

  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  function tr(key, fallback, interpolations) {
    return I18n.tr(pluginApi, key, fallback, interpolations)
  }

  readonly property var activeOutputs: Ui.activeOutputs(tr, outputState, Color)
  readonly property string statusTooltip: Ui.barTooltip(tr, outputState, Color, primaryActionText)
  readonly property bool showObsLogo: activeOutputs.length === 0
  readonly property string displayText: Ui.barDisplayText(tr, outputState, Color, barLabelMode, showElapsedInBar)
  readonly property color accentColor: Ui.accentBackgroundColor(outputState, Color, Color.mOnSurface)
  readonly property string primaryIconName: Ui.primaryIcon(outputState)

  readonly property bool showInBar: Boolean(service && service.showInBar)
  readonly property real contentWidth: showInBar
                                      ? (isBarVertical
                                          ? capsuleHeight
                                          : Math.round(content.implicitWidth + Style.marginM * 2))
                                      : 0
  readonly property real contentHeight: showInBar
                                       ? (isBarVertical
                                           ? Math.round(content.implicitHeight + Style.marginM * 2)
                                           : capsuleHeight)
                                       : 0

  visible: showInBar
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    id: visualCapsule

    visible: root.showInBar
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Item {
      id: content
      anchors.centerIn: parent
      implicitWidth: horizontalContent.visible ? horizontalContent.implicitWidth : verticalContent.implicitWidth
      implicitHeight: horizontalContent.visible ? horizontalContent.implicitHeight : verticalContent.implicitHeight

      RowLayout {
        id: horizontalContent
        anchors.centerIn: parent
        visible: !root.isBarVertical
        spacing: Style.marginS

        Image {
          visible: root.showObsLogo
          source: root.obsLogoSource
          sourceSize.width: Math.round(root.barFontSize * 1.3)
          sourceSize.height: Math.round(root.barFontSize * 1.3)
          width: Math.round(root.barFontSize * 1.3)
          height: Math.round(root.barFontSize * 1.3)
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
          asynchronous: true
          Layout.alignment: Qt.AlignVCenter
        }

        NIcon {
          visible: !root.showObsLogo && root.barLabelMode === "icon-only"
          icon: root.primaryIconName
          pointSize: Math.max(1, Math.round(root.barFontSize))
          applyUiScale: false
          color: root.accentColor
          Layout.alignment: Qt.AlignVCenter
        }

        NText {
          visible: root.displayText !== ""
          text: root.displayText
          pointSize: root.barFontSize
          applyUiScale: false
          font.weight: Style.fontWeightSemiBold
          color: root.accentColor
          Layout.alignment: Qt.AlignVCenter
        }
      }

      ColumnLayout {
        id: verticalContent
        anchors.centerIn: parent
        visible: root.isBarVertical
        spacing: Style.marginXS

        Image {
          visible: root.showObsLogo
          source: root.obsLogoSource
          sourceSize.width: Math.round(root.barFontSize * 1.15)
          sourceSize.height: Math.round(root.barFontSize * 1.15)
          width: Math.round(root.barFontSize * 1.15)
          height: Math.round(root.barFontSize * 1.15)
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
          asynchronous: true
          Layout.alignment: Qt.AlignHCenter
        }

        NIcon {
          visible: !root.showObsLogo && root.barLabelMode === "icon-only"
          icon: root.primaryIconName
          pointSize: Math.max(1, Math.round(root.barFontSize))
          applyUiScale: false
          color: root.accentColor
          Layout.alignment: Qt.AlignHCenter
        }

        NText {
          visible: root.displayText !== ""
          text: root.displayText
          pointSize: root.barFontSize * 0.88
          applyUiScale: false
          font.weight: Style.fontWeightSemiBold
          color: root.accentColor
          Layout.alignment: Qt.AlignHCenter
        }
      }
    }
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    enabled: root.showInBar
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      TooltipService.show(root, root.statusTooltip, "auto");
    }

    onExited: {
      TooltipService.hide(root);
    }

    onPressed: {
      TooltipService.hide(root);
    }

    onClicked: function(mouse) {
      if (!service) {
        return;
      }

      if (mouse.button === Qt.LeftButton) {
        service.runPrimaryAction(screen, root);
      } else if (mouse.button === Qt.RightButton) {
        service.runSecondaryAction();
      } else if (mouse.button === Qt.MiddleButton) {
        service.runMiddleAction();
      }
    }
  }
}
