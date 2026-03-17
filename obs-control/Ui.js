.pragma library

function formatDuration(durationMs) {
  const totalSeconds = Math.max(0, Math.floor(Number(durationMs || 0) / 1000));
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  if (hours > 0) {
    return `${hours}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
  }

  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

function hasActiveOutputs(state) {
  return Boolean(state && (state.recording || state.replayBuffer || state.streaming));
}

function activeOutputs(tr, state, Color) {
  const outputs = [];

  if (state && state.recording) {
    outputs.push({
      key: "recording",
      label: tr("bar.recording_label", "REC"),
      longLabel: tr("panel.status.recording", "Recording"),
      icon: "player-record",
      color: Color.mError,
      textColor: Color.mOnError,
      durationMs: Number(state.recordDurationMs || 0),
    });
  }

  if (state && state.replayBuffer) {
    outputs.push({
      key: "replay",
      label: tr("bar.replay_label", "RPL"),
      longLabel: tr("panel.status.replay", "Replay Buffer"),
      icon: "history",
      color: Color.mSecondary,
      textColor: Color.mOnSecondary,
      durationMs: 0,
    });
  }

  if (state && state.streaming) {
    outputs.push({
      key: "streaming",
      label: tr("bar.streaming_label", "LIVE"),
      longLabel: tr("panel.status.streaming", "Streaming"),
      icon: "antenna-bars-5",
      color: Color.mPrimary,
      textColor: Color.mOnPrimary,
      durationMs: Number(state.streamDurationMs || 0),
    });
  }

  return outputs;
}

function activeOutputSummary(tr, state, Color, separator) {
  return activeOutputs(tr, state, Color).map(output => output.longLabel).join(separator || ", ");
}

function primaryIcon(state) {
  if (state && state.recording) {
    return "player-record";
  }
  if (state && state.streaming) {
    return "antenna-bars-5";
  }
  if (state && state.replayBuffer) {
    return "history";
  }
  return "";
}

function accentBackgroundColor(state, Color, fallback) {
  if (state && state.recording) {
    return Color.mError;
  }
  if (state && state.streaming) {
    return Color.mPrimary;
  }
  if (state && state.replayBuffer) {
    return Color.mSecondary;
  }
  return fallback;
}

function accentForegroundColor(state, Color, fallback) {
  if (state && state.recording) {
    return Color.mOnError;
  }
  if (state && state.streaming) {
    return Color.mOnPrimary;
  }
  if (state && state.replayBuffer) {
    return Color.mOnSecondary;
  }
  return fallback;
}

function barChipText(outputItem, barLabelMode, showElapsedInBar) {
  if (barLabelMode === "icon-only") {
    return "";
  }

  if (barLabelMode === "duration" && showElapsedInBar && outputItem && outputItem.durationMs > 0) {
    return `${outputItem.label} ${formatDuration(outputItem.durationMs)}`;
  }

  return outputItem ? outputItem.label : "";
}

function barDisplayText(tr, state, Color, barLabelMode, showElapsedInBar) {
  const outputs = activeOutputs(tr, state, Color);

  if (outputs.length === 0) {
    return "";
  }

  if (barLabelMode === "icon-only") {
    return "";
  }

  if (barLabelMode === "duration" && showElapsedInBar) {
    const timedOutputs = outputs.filter(output => output.durationMs > 0);
    if (timedOutputs.length === 1 && outputs.length === 1) {
      return `${timedOutputs[0].label} ${formatDuration(timedOutputs[0].durationMs)}`;
    }
  }

  return outputs.map(output => output.label).join(" + ");
}

function shouldShowInBar(state, settings) {
  if (!state || !settings) {
    return false;
  }

  return Boolean(
    (state.recording && settings.showBarWhenRecording)
    || (state.replayBuffer && settings.showBarWhenReplay)
    || (state.streaming && settings.showBarWhenStreaming)
  );
}

function shouldShowInControlCenter(state, settings, connected) {
  if (!state || !settings) {
    return false;
  }

  return Boolean(
    (state.recording && settings.showControlCenterWhenRecording)
    || (state.replayBuffer && settings.showControlCenterWhenReplay)
    || (state.streaming && settings.showControlCenterWhenStreaming)
    || (connected && settings.showControlCenterWhenReady)
  );
}

function primaryActionText(tr, leftClickAction) {
  if (leftClickAction === "toggle-record") {
    return tr("actions.primary.toggle_record", "toggles recording");
  }
  if (leftClickAction === "toggle-stream") {
    return tr("actions.primary.toggle_stream", "toggles streaming");
  }
  return tr("actions.primary.open_controls", "opens controls");
}

function barTooltip(tr, state, Color, primaryActionLabel) {
  return tr(
    "bar.tooltip.active",
    "OBS active: {outputs}\nLeft click {primaryAction}\nRight click toggles recording\nMiddle click toggles the replay buffer",
    {
      outputs: activeOutputSummary(tr, state, Color, ", "),
      primaryAction: primaryActionLabel,
    }
  );
}

function controlCenterTooltip(tr, state, Color, connected, obsRunning, primaryActionLabel) {
  if (hasActiveOutputs(state)) {
    return tr(
      "control_center.tooltip.active",
      "OBS active: {outputs}\nLeft click {primaryAction}\nRight click toggles recording\nMiddle click toggles the replay buffer",
      {
        outputs: activeOutputSummary(tr, state, Color, ", "),
        primaryAction: primaryActionLabel,
      }
    );
  }

  if (connected) {
    return tr(
      "control_center.tooltip.ready",
      "OBS is ready\nLeft click {primaryAction}\nRight click toggles recording\nMiddle click toggles the replay buffer",
      { primaryAction: primaryActionLabel }
    );
  }

  if (obsRunning) {
    return tr(
      "control_center.tooltip.needs_restart",
      "OBS is running, but WebSocket control is unavailable\nRestart OBS once to restore controls"
    );
  }

  return tr(
    "control_center.tooltip.offline",
    "OBS is offline\nLeft click {primaryAction}\nRight click launches OBS",
    { primaryAction: primaryActionLabel }
  );
}

function panelHeaderText(tr, state, Color, connected, obsRunning) {
  if (hasActiveOutputs(state)) {
    return tr(
      "panel.header.active",
      "Active outputs: {outputs}. Manage capture, replay, or streaming from here.",
      { outputs: activeOutputSummary(tr, state, Color, " + ") }
    );
  }

  if (connected) {
    return tr("panel.header.ready", "OBS is connected and ready for recording, replay, or streaming.");
  }

  if (obsRunning) {
    return tr(
      "panel.header.needs_restart",
      "OBS is open, but WebSocket control is unavailable until it is restarted once."
    );
  }

  return tr("panel.header.offline", "OBS is offline. Launch it here and the widget will track its state.");
}

function panelStatusText(tr, state, Color, connected, obsRunning) {
  if (hasActiveOutputs(state)) {
    return activeOutputSummary(tr, state, Color, " + ");
  }

  if (connected) {
    return tr("panel.status.ready", "Ready");
  }

  if (obsRunning) {
    return tr("panel.status.needs_restart", "Needs OBS Restart");
  }

  return tr("panel.status.offline", "Offline");
}

const TOAST_MESSAGES = {
  "record-started": {
    titleKey: "toast.record_started.title",
    titleFallback: "OBS recording started",
    bodyKey: "toast.record_started.body",
    bodyFallback: "Local recording is running.",
  },
  "record-started-launch": {
    titleKey: "toast.record_started_launch.title",
    titleFallback: "OBS recording started",
    bodyKey: "toast.record_started_launch.body",
    bodyFallback: "OBS launched automatically for recording.",
  },
  "record-stopped": {
    titleKey: "toast.record_stopped.title",
    titleFallback: "OBS recording stopped",
    bodyKey: "toast.record_stopped.body",
    bodyFallback: "Recording saved to Videos.",
  },
  "record-stopped-autoclose": {
    titleKey: "toast.record_stopped_autoclose.title",
    titleFallback: "OBS recording stopped",
    bodyKey: "toast.record_stopped_autoclose.body",
    bodyFallback: "Recording saved to Videos. OBS closed.",
  },
  "stream-started": {
    titleKey: "toast.stream_started.title",
    titleFallback: "OBS stream started",
    bodyKey: "toast.stream_started.body",
    bodyFallback: "Live streaming is active.",
  },
  "stream-started-launch": {
    titleKey: "toast.stream_started_launch.title",
    titleFallback: "OBS stream started",
    bodyKey: "toast.stream_started_launch.body",
    bodyFallback: "OBS launched automatically for streaming.",
  },
  "stream-stopped": {
    titleKey: "toast.stream_stopped.title",
    titleFallback: "OBS stream stopped",
    bodyKey: "toast.stream_stopped.body",
    bodyFallback: "Live streaming ended.",
  },
  "stream-stopped-autoclose": {
    titleKey: "toast.stream_stopped_autoclose.title",
    titleFallback: "OBS stream stopped",
    bodyKey: "toast.stream_stopped_autoclose.body",
    bodyFallback: "Live streaming ended. OBS closed.",
  },
  "replay-started": {
    titleKey: "toast.replay_started.title",
    titleFallback: "OBS replay buffer started",
    bodyKey: "toast.replay_started.body",
    bodyFallback: "Replay buffer is active.",
  },
  "replay-started-launch": {
    titleKey: "toast.replay_started_launch.title",
    titleFallback: "OBS replay buffer started",
    bodyKey: "toast.replay_started_launch.body",
    bodyFallback: "OBS launched automatically for replay.",
  },
  "replay-stopped": {
    titleKey: "toast.replay_stopped.title",
    titleFallback: "OBS replay buffer stopped",
    bodyKey: "toast.replay_stopped.body",
    bodyFallback: "Instant replay is off.",
  },
  "replay-stopped-autoclose": {
    titleKey: "toast.replay_stopped_autoclose.title",
    titleFallback: "OBS replay buffer stopped",
    bodyKey: "toast.replay_stopped_autoclose.body",
    bodyFallback: "Instant replay is off. OBS closed.",
  },
  "replay-saved": {
    titleKey: "toast.replay_saved.title",
    titleFallback: "OBS replay saved",
    bodyKey: "toast.replay_saved.body",
    bodyFallback: "Saved the last replay buffer to Videos.",
  },
  offline: {
    titleKey: "toast.offline.title",
    titleFallback: "OBS is offline",
    bodyKey: "toast.offline.body",
    bodyFallback: "Launch OBS to use recording controls.",
  },
};

function toastPayload(tr, payload) {
  if (!payload) {
    return { title: "", body: "" };
  }

  const message = TOAST_MESSAGES[payload.event];
  if (!message) {
    return {
      title: payload.title || "",
      body: payload.body || "",
    };
  }

  return {
    title: tr(message.titleKey, message.titleFallback),
    body: tr(message.bodyKey, message.bodyFallback),
  };
}
