import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "I18n.js" as I18n

ColumnLayout {
  id: root
  spacing: Style.marginM
  width: 560

  required property var pluginApi

  readonly property var defaults: pluginApi && pluginApi.manifest && pluginApi.manifest.metadata
                                   ? (pluginApi.manifest.metadata.defaultSettings || {})
                                   : ({})

  property int valuePollIntervalMs: pluginApi.pluginSettings.pollIntervalMs !== undefined
                                    ? pluginApi.pluginSettings.pollIntervalMs
                                    : (defaults.pollIntervalMs !== undefined ? defaults.pollIntervalMs : 2500)
  property string valueLeftClickAction: pluginApi.pluginSettings.leftClickAction !== undefined
                                        ? pluginApi.pluginSettings.leftClickAction
                                        : (defaults.leftClickAction !== undefined ? defaults.leftClickAction : "panel")
  property string valueLaunchBehavior: pluginApi.pluginSettings.launchBehavior !== undefined
                                       ? pluginApi.pluginSettings.launchBehavior
                                       : (defaults.launchBehavior !== undefined ? defaults.launchBehavior : "minimized-to-tray")
  property string valueBarLabelMode: pluginApi.pluginSettings.barLabelMode !== undefined
                                     ? pluginApi.pluginSettings.barLabelMode
                                     : (defaults.barLabelMode !== undefined ? defaults.barLabelMode : "short-label")
  property string valueVideosPath: pluginApi.pluginSettings.videosPath !== undefined
                                   ? pluginApi.pluginSettings.videosPath
                                   : (defaults.videosPath !== undefined ? defaults.videosPath : "")
  property string valueVideosOpener: pluginApi.pluginSettings.videosOpener !== undefined
                                     ? pluginApi.pluginSettings.videosOpener
                                     : (defaults.videosOpener !== undefined ? defaults.videosOpener : "xdg-open")
  property bool valueAutoCloseManagedObs: pluginApi.pluginSettings.autoCloseManagedObs !== undefined
                                          ? pluginApi.pluginSettings.autoCloseManagedObs
                                          : (defaults.autoCloseManagedObs !== undefined ? defaults.autoCloseManagedObs : true)
  property bool valueOpenVideosAfterStop: pluginApi.pluginSettings.openVideosAfterStop !== undefined
                                          ? pluginApi.pluginSettings.openVideosAfterStop
                                          : (defaults.openVideosAfterStop !== undefined ? defaults.openVideosAfterStop : true)
  property bool valueShowBarWhenRecording: pluginApi.pluginSettings.showBarWhenRecording !== undefined
                                           ? pluginApi.pluginSettings.showBarWhenRecording
                                           : (defaults.showBarWhenRecording !== undefined ? defaults.showBarWhenRecording : true)
  property bool valueShowBarWhenReplay: pluginApi.pluginSettings.showBarWhenReplay !== undefined
                                        ? pluginApi.pluginSettings.showBarWhenReplay
                                        : (defaults.showBarWhenReplay !== undefined ? defaults.showBarWhenReplay : false)
  property bool valueShowBarWhenStreaming: pluginApi.pluginSettings.showBarWhenStreaming !== undefined
                                           ? pluginApi.pluginSettings.showBarWhenStreaming
                                           : (defaults.showBarWhenStreaming !== undefined ? defaults.showBarWhenStreaming : true)
  property bool valueShowControlCenterWhenRecording: pluginApi.pluginSettings.showControlCenterWhenRecording !== undefined
                                                     ? pluginApi.pluginSettings.showControlCenterWhenRecording
                                                     : (defaults.showControlCenterWhenRecording !== undefined ? defaults.showControlCenterWhenRecording : true)
  property bool valueShowControlCenterWhenReplay: pluginApi.pluginSettings.showControlCenterWhenReplay !== undefined
                                                  ? pluginApi.pluginSettings.showControlCenterWhenReplay
                                                  : (defaults.showControlCenterWhenReplay !== undefined ? defaults.showControlCenterWhenReplay : true)
  property bool valueShowControlCenterWhenStreaming: pluginApi.pluginSettings.showControlCenterWhenStreaming !== undefined
                                                     ? pluginApi.pluginSettings.showControlCenterWhenStreaming
                                                     : (defaults.showControlCenterWhenStreaming !== undefined ? defaults.showControlCenterWhenStreaming : true)
  property bool valueShowControlCenterWhenReady: pluginApi.pluginSettings.showControlCenterWhenReady !== undefined
                                                 ? pluginApi.pluginSettings.showControlCenterWhenReady
                                                 : (defaults.showControlCenterWhenReady !== undefined ? defaults.showControlCenterWhenReady : false)
  property bool valueShowElapsedInBar: pluginApi.pluginSettings.showElapsedInBar !== undefined
                                       ? pluginApi.pluginSettings.showElapsedInBar
                                       : (defaults.showElapsedInBar !== undefined ? defaults.showElapsedInBar : false)

  function tr(key, fallback, interpolations) {
    return I18n.tr(pluginApi, key, fallback, interpolations)
  }

  function saveSettings() {
    if (!pluginApi) {
      return;
    }

    pluginApi.pluginSettings.pollIntervalMs = valuePollIntervalMs;
    pluginApi.pluginSettings.leftClickAction = valueLeftClickAction;
    pluginApi.pluginSettings.launchBehavior = valueLaunchBehavior;
    pluginApi.pluginSettings.barLabelMode = valueBarLabelMode;
    pluginApi.pluginSettings.videosPath = valueVideosPath.trim();
    pluginApi.pluginSettings.videosOpener = valueVideosOpener.trim();
    pluginApi.pluginSettings.autoCloseManagedObs = valueAutoCloseManagedObs;
    pluginApi.pluginSettings.openVideosAfterStop = valueOpenVideosAfterStop;
    pluginApi.pluginSettings.showBarWhenRecording = valueShowBarWhenRecording;
    pluginApi.pluginSettings.showBarWhenReplay = valueShowBarWhenReplay;
    pluginApi.pluginSettings.showBarWhenStreaming = valueShowBarWhenStreaming;
    pluginApi.pluginSettings.showControlCenterWhenRecording = valueShowControlCenterWhenRecording;
    pluginApi.pluginSettings.showControlCenterWhenReplay = valueShowControlCenterWhenReplay;
    pluginApi.pluginSettings.showControlCenterWhenStreaming = valueShowControlCenterWhenStreaming;
    pluginApi.pluginSettings.showControlCenterWhenReady = valueShowControlCenterWhenReady;
    pluginApi.pluginSettings.showElapsedInBar = valueShowElapsedInBar;
    pluginApi.saveSettings();
  }

  NHeader {
    label: tr("settings.header.label", "OBS Control")
    description: tr("settings.header.description", "Control how often the plugin polls OBS and when it becomes visible in the shell.")
  }

  NSpinBox {
    label: tr("settings.poll_interval.label", "Poll Interval")
    description: tr("settings.poll_interval.description", "How often the plugin refreshes OBS state, in milliseconds.")
    from: 750
    to: 10000
    stepSize: 250
    value: valuePollIntervalMs
    onValueChanged: valuePollIntervalMs = value
  }

  NComboBox {
    label: tr("settings.left_click_action.label", "Left Click Action")
    description: tr("settings.left_click_action.description", "Choose whether left click opens the panel or toggles recording directly.")
    model: [
      { "key": "panel", "name": tr("settings.left_click_action.options.open_controls", "Open Controls") },
      { "key": "toggle-record", "name": tr("settings.left_click_action.options.toggle_recording", "Toggle Recording") },
      { "key": "toggle-stream", "name": tr("settings.left_click_action.options.toggle_streaming", "Toggle Streaming") }
    ]
    currentKey: valueLeftClickAction
    minimumWidth: 220
    onSelected: key => valueLeftClickAction = key
  }

  NComboBox {
    label: tr("settings.launch_behavior.label", "Launch Behavior")
    description: tr("settings.launch_behavior.description", "Choose how the explicit Launch OBS action opens OBS. Automatic recording, replay, or streaming starts still launch minimized to the tray.")
    model: [
      { "key": "normal", "name": tr("settings.launch_behavior.options.normal", "Normal Window") },
      { "key": "minimized-to-tray", "name": tr("settings.launch_behavior.options.minimized_to_tray", "Minimize To Tray") }
    ]
    currentKey: valueLaunchBehavior
    minimumWidth: 220
    onSelected: key => valueLaunchBehavior = key
  }

  NComboBox {
    label: tr("settings.bar_label_mode.label", "Bar Label Mode")
    description: tr("settings.bar_label_mode.description", "Choose how the bar indicator renders active OBS outputs.")
    model: [
      { "key": "icon-only", "name": tr("settings.bar_label_mode.options.icon_only", "Icon Only") },
      { "key": "short-label", "name": tr("settings.bar_label_mode.options.short_label", "Short Labels") },
      { "key": "duration", "name": tr("settings.bar_label_mode.options.duration", "Duration Labels") }
    ]
    currentKey: valueBarLabelMode
    minimumWidth: 220
    onSelected: key => valueBarLabelMode = key
  }

  NTextInput {
    Layout.fillWidth: true
    label: tr("settings.videos_path.label", "Videos Path")
    description: tr("settings.videos_path.description", "Optional custom folder used by the panel and the toast action. Leave empty to use your default Videos directory.")
    placeholderText: "~/Videos"
    text: valueVideosPath
    onTextChanged: valueVideosPath = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: tr("settings.videos_opener.label", "Videos Opener")
    description: tr("settings.videos_opener.description", "Command used to open the Videos folder. Set this to your GUI file manager if xdg-open resolves to a terminal opener.")
    placeholderText: "xdg-open"
    text: valueVideosOpener
    onTextChanged: valueVideosOpener = text
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.auto_close_managed.label", "Auto-Close Managed OBS")
    description: tr("settings.auto_close_managed.description", "If the plugin had to cold-launch OBS for recording, replay, or streaming, close OBS again after the last active output stops.")
    checked: valueAutoCloseManagedObs
    onToggled: checked => valueAutoCloseManagedObs = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.open_videos_after_stop.label", "Show Open Videos After Stop")
    description: tr("settings.open_videos_after_stop.description", "Offer an Open Videos toast action after recording stops or a replay is saved.")
    checked: valueOpenVideosAfterStop
    onToggled: checked => valueOpenVideosAfterStop = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_elapsed_in_bar.label", "Show Elapsed In Bar")
    description: tr("settings.show_elapsed_in_bar.description", "Allow duration labels in the bar when Bar Label Mode is set to Duration Labels.")
    checked: valueShowElapsedInBar
    onToggled: checked => valueShowElapsedInBar = checked
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_bar_recording.label", "Show Bar While Recording")
    description: tr("settings.show_bar_recording.description", "Display the bar indicator while OBS is actively recording.")
    checked: valueShowBarWhenRecording
    onToggled: checked => valueShowBarWhenRecording = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_bar_replay.label", "Show Bar While Replay Is Active")
    description: tr("settings.show_bar_replay.description", "Keep the bar indicator visible when only the replay buffer is running.")
    checked: valueShowBarWhenReplay
    onToggled: checked => valueShowBarWhenReplay = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_bar_streaming.label", "Show Bar While Streaming")
    description: tr("settings.show_bar_streaming.description", "Keep the bar indicator visible when OBS is actively streaming.")
    checked: valueShowBarWhenStreaming
    onToggled: checked => valueShowBarWhenStreaming = checked
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_control_center_recording.label", "Show Control Center While Recording")
    description: tr("settings.show_control_center_recording.description", "Show the Control Center shortcut while OBS is recording.")
    checked: valueShowControlCenterWhenRecording
    onToggled: checked => valueShowControlCenterWhenRecording = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_control_center_replay.label", "Show Control Center While Replay Is Active")
    description: tr("settings.show_control_center_replay.description", "Show the Control Center shortcut while the replay buffer is active.")
    checked: valueShowControlCenterWhenReplay
    onToggled: checked => valueShowControlCenterWhenReplay = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_control_center_streaming.label", "Show Control Center While Streaming")
    description: tr("settings.show_control_center_streaming.description", "Show the Control Center shortcut while OBS is streaming.")
    checked: valueShowControlCenterWhenStreaming
    onToggled: checked => valueShowControlCenterWhenStreaming = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_control_center_ready.label", "Show Control Center When OBS Is Ready")
    description: tr("settings.show_control_center_ready.description", "Keep the shortcut visible when OBS is connected but idle.")
    checked: valueShowControlCenterWhenReady
    onToggled: checked => valueShowControlCenterWhenReady = checked
  }
}
