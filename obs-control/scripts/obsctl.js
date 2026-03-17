#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { spawn, execFileSync } = require("child_process");
const WebSocket = globalThis.WebSocket;

const validCommands = new Set(["launch", "status", "toggle-record", "toggle-replay", "toggle-stream", "save-replay"]);
const STATUS_DISCONNECTED = {
  obsRunning: false,
  websocket: false,
  recording: false,
  replayBuffer: false,
  streaming: false,
  recordDurationMs: 0,
  streamDurationMs: 0,
};
const WS_TIMEOUT_MS = 1500;
const AUTO_LAUNCH_STATE_VERSION = 1;
const AUTO_LAUNCH_SHUTDOWN_DELAY_MS = 250;
const LAUNCH_BEHAVIORS = new Set(["normal", "minimized-to-tray"]);

let launchBehavior = "minimized-to-tray";
let autoCloseManaged = true;
let cmd = "";

function usage() {
  console.error("usage: obsctl [--launch-behavior normal|minimized-to-tray] [--auto-close-managed true|false] <launch|status|toggle-record|toggle-replay|toggle-stream|save-replay>");
  process.exit(2);
}

for (let index = 2; index < process.argv.length; index += 1) {
  const arg = process.argv[index];
  if (arg === "--launch-behavior") {
    const value = process.argv[index + 1];
    if (!LAUNCH_BEHAVIORS.has(value)) {
      usage();
    }
    launchBehavior = value;
    index += 1;
    continue;
  }

  if (arg === "--auto-close-managed") {
    const value = String(process.argv[index + 1] || "").toLowerCase();
    if (value !== "true" && value !== "false") {
      usage();
    }
    autoCloseManaged = value === "true";
    index += 1;
    continue;
  }

  if (cmd === "") {
    cmd = arg;
  } else {
    usage();
  }
}

if (!validCommands.has(cmd)) {
  usage();
}

if (typeof WebSocket !== "function") {
  console.error("obsctl: this Node.js runtime does not provide WebSocket support");
  process.exit(1);
}

function obsRunning() {
  try {
    execFileSync("pgrep", ["-x", "obs"], { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

function launchObs(args = []) {
  spawn("obs", args, {
    detached: true,
    stdio: "ignore",
  }).unref();
}

function launchObsWithBehavior(args = []) {
  const launchArgs = [...args];
  if (launchBehavior === "minimized-to-tray") {
    launchArgs.push("--minimize-to-tray");
  }
  launchObs(launchArgs);
}

function launchObsMinimized(args = []) {
  launchObs([...args, "--minimize-to-tray"]);
}

function stateDir() {
  const runtimeDir = process.env.XDG_RUNTIME_DIR || path.join("/tmp", `noctalia-obs-control-${process.getuid?.() ?? "unknown"}`);
  return path.join(runtimeDir, "noctalia-obs-control");
}

function statePath() {
  return path.join(stateDir(), "auto-launch.json");
}

function readAutoLaunchState() {
  try {
    const parsed = JSON.parse(fs.readFileSync(statePath(), "utf8"));
    if (parsed && parsed.version === AUTO_LAUNCH_STATE_VERSION && parsed.autoLaunched === true) {
      return parsed;
    }
  } catch {}

  return null;
}

function writeAutoLaunchState(trigger) {
  fs.mkdirSync(stateDir(), { recursive: true });
  fs.writeFileSync(
    statePath(),
    JSON.stringify({
      version: AUTO_LAUNCH_STATE_VERSION,
      autoLaunched: true,
      trigger,
      createdAt: new Date().toISOString(),
    }),
    "utf8",
  );
}

function clearAutoLaunchState() {
  try {
    fs.unlinkSync(statePath());
  } catch {}
}

function getObsPids() {
  try {
    const output = execFileSync("pgrep", ["-x", "obs"], { encoding: "utf8" }).trim();
    if (output === "") return [];
    return output
      .split(/\s+/)
      .map((value) => Number(value))
      .filter((value) => Number.isInteger(value) && value > 0);
  } catch {
    return [];
  }
}

function terminateObs() {
  const pids = getObsPids();
  for (const pid of pids) {
    try {
      process.kill(pid, "SIGTERM");
    } catch {}
  }
  return pids.length > 0;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function sha256b64(input) {
  return crypto.createHash("sha256").update(input).digest("base64");
}

function readWsConfig() {
  const configHome = process.env.XDG_CONFIG_HOME || path.join(process.env.HOME, ".config");
  const configPath = path.join(configHome, "obs-studio", "plugin_config", "obs-websocket", "config.json");
  const parsed = JSON.parse(fs.readFileSync(configPath, "utf8"));
  return {
    host: "127.0.0.1",
    port: Number(parsed.server_port || 4455),
    password: String(parsed.server_password || ""),
  };
}

function disconnectedStatus(obsRunning = false) {
  return {
    ...STATUS_DISCONNECTED,
    obsRunning,
  };
}

function printStatus(status) {
  console.log(JSON.stringify(status));
}

function printResult(payload) {
  console.log(JSON.stringify(payload));
}

async function connectWs(config) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`ws://${config.host}:${config.port}`);
    const pending = new Map();
    let nextId = 1;
    let settled = false;

    function finish(err) {
      if (!settled) {
        settled = true;
        if (err) reject(err);
        else resolve({
          request(type, requestData = {}) {
            return new Promise((res, rej) => {
              const requestId = String(nextId++);
              pending.set(requestId, { res, rej });
              ws.send(
                JSON.stringify({
                  op: 6,
                  d: {
                    requestType: type,
                    requestId,
                    requestData,
                  },
                }),
              );
            });
          },
          close() {
            ws.close();
          },
        });
      }
    }

    const timeout = setTimeout(() => {
      try {
        ws.close();
      } catch {}
      finish(new Error("timeout"));
    }, WS_TIMEOUT_MS);

    ws.addEventListener("message", (event) => {
      const msg = JSON.parse(event.data);

      if (msg.op === 0) {
        const identify = { rpcVersion: 1, eventSubscriptions: 0 };
        const auth = msg.d.authentication;
        if (auth) {
          const secret = sha256b64(config.password + auth.salt);
          identify.authentication = sha256b64(secret + auth.challenge);
        }
        ws.send(JSON.stringify({ op: 1, d: identify }));
        return;
      }

      if (msg.op === 2) {
        clearTimeout(timeout);
        finish();
        return;
      }

      if (msg.op === 7) {
        const entry = pending.get(msg.d.requestId);
        if (!entry) return;
        pending.delete(msg.d.requestId);
        if (msg.d.requestStatus?.result) entry.res(msg.d.responseData || {});
        else entry.rej(new Error(msg.d.requestStatus?.comment || "request failed"));
      }
    });

    ws.addEventListener("error", () => {
      clearTimeout(timeout);
      finish(new Error("connect failed"));
    });

    ws.addEventListener("close", () => {
      clearTimeout(timeout);
      if (!settled) finish(new Error("closed"));
    });
  });
}

async function safeRequest(ws, type, requestData = {}, fallback = {}) {
  try {
    return await ws.request(type, requestData);
  } catch {
    return fallback;
  }
}

async function maybeQuitAutoLaunchedObs(ws) {
  const state = readAutoLaunchState();
  if (!state) {
    return false;
  }

  const [recordStatus, replayStatus, streamStatus, virtualCamStatus] = await Promise.all([
    safeRequest(ws, "GetRecordStatus"),
    safeRequest(ws, "GetReplayBufferStatus"),
    safeRequest(ws, "GetStreamStatus"),
    safeRequest(ws, "GetVirtualCamStatus"),
  ]);

  const hasActiveOutputs = Boolean(
    recordStatus.outputActive
    || replayStatus.outputActive
    || streamStatus.outputActive
    || virtualCamStatus.outputActive,
  );

  if (hasActiveOutputs) {
    return false;
  }

  await sleep(AUTO_LAUNCH_SHUTDOWN_DELAY_MS);
  const terminated = terminateObs();
  if (terminated || !obsRunning()) {
    clearAutoLaunchState();
  }
  return terminated;
}

async function run() {
  if (cmd === "launch") {
    clearAutoLaunchState();
    if (!obsRunning()) launchObsWithBehavior();
    return;
  }

  const running = obsRunning();
  if (!running) {
    clearAutoLaunchState();
  }

  let config;
  try {
    config = readWsConfig();
  } catch {
    if (cmd === "status") {
      printStatus(disconnectedStatus(running));
      return;
    }

    console.error("OBS websocket config not found.");
    process.exit(1);
  }

  let ws;
  try {
    ws = await connectWs(config);
  } catch {
    if (cmd === "status") {
      printStatus(disconnectedStatus(running));
      return;
    }

    if (!obsRunning()) {
      if (cmd === "toggle-record") {
        if (autoCloseManaged) {
          writeAutoLaunchState("toggle-record");
        } else {
          clearAutoLaunchState();
        }
        launchObsMinimized(["--startrecording"]);
        printResult({
          ok: true,
          event: "record-started-launch",
        });
      } else if (cmd === "toggle-replay") {
        if (autoCloseManaged) {
          writeAutoLaunchState("toggle-replay");
        } else {
          clearAutoLaunchState();
        }
        launchObsMinimized(["--startreplaybuffer"]);
        printResult({
          ok: true,
          event: "replay-started-launch",
        });
      } else if (cmd === "toggle-stream") {
        if (autoCloseManaged) {
          writeAutoLaunchState("toggle-stream");
        } else {
          clearAutoLaunchState();
        }
        launchObsMinimized(["--startstreaming"]);
        printResult({
          ok: true,
          event: "stream-started-launch",
        });
      } else {
        printResult({
          ok: false,
          event: "offline",
        });
      }
      return;
    }

    console.error("OBS is running but websocket control is unavailable. Restart OBS once.");
    process.exit(1);
  }

  try {
    if (cmd === "status") {
      const [recordStatus, replayStatus, streamStatus] = await Promise.all([
        ws.request("GetRecordStatus"),
        ws.request("GetReplayBufferStatus"),
        ws.request("GetStreamStatus"),
      ]);
      printStatus({
        obsRunning: running,
        websocket: true,
        recording: Boolean(recordStatus.outputActive),
        replayBuffer: Boolean(replayStatus.outputActive),
        streaming: Boolean(streamStatus.outputActive),
        recordDurationMs: Number(recordStatus.outputDuration || 0),
        streamDurationMs: Number(streamStatus.outputDuration || 0),
      });
    } else if (cmd === "toggle-record") {
      const status = await ws.request("GetRecordStatus");
      const stopping = status.outputActive;
      await ws.request(stopping ? "StopRecord" : "StartRecord");
      const obsClosed = stopping ? await maybeQuitAutoLaunchedObs(ws) : false;
      printResult({
        ok: true,
        event: stopping ? (obsClosed ? "record-stopped-autoclose" : "record-stopped") : "record-started",
        openVideos: stopping,
      });
    } else if (cmd === "toggle-stream") {
      const status = await ws.request("GetStreamStatus");
      const stopping = status.outputActive;
      await ws.request(stopping ? "StopStream" : "StartStream");
      const obsClosed = stopping ? await maybeQuitAutoLaunchedObs(ws) : false;
      printResult({
        ok: true,
        event: stopping ? (obsClosed ? "stream-stopped-autoclose" : "stream-stopped") : "stream-started",
      });
    } else if (cmd === "toggle-replay") {
      const status = await ws.request("GetReplayBufferStatus");
      const stopping = status.outputActive;
      await ws.request(stopping ? "StopReplayBuffer" : "StartReplayBuffer");
      const obsClosed = stopping ? await maybeQuitAutoLaunchedObs(ws) : false;
      printResult({
        ok: true,
        event: stopping ? (obsClosed ? "replay-stopped-autoclose" : "replay-stopped") : "replay-started",
      });
    } else if (cmd === "save-replay") {
      await ws.request("SaveReplayBuffer");
      printResult({
        ok: true,
        event: "replay-saved",
        openVideos: true,
      });
    }
  } finally {
    ws.close();
  }
}

run().catch((err) => {
  console.error(err.message || String(err));
  process.exit(1);
});
