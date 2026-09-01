const fs = require("fs");
const net = require("net");
const path = require("path");
const assert = require("assert");
const { pathToFileURL } = require("url");
const { spawn } = require("child_process");

const cacheDir = path.join(process.env.LOCALAPPDATA, "yasb");
const cacheFile = path.join(cacheDir, "leopardwm-workspace.txt");
const pipeName = "\\\\.\\pipe\\yasb-leopardwm-workspace";
const populated = new Set();
let activeWorkspace;
let frame = 0;
let lastSvg = "";
let previousImageFile;

function render() {
  const visible = new Set(populated);
  if (activeWorkspace !== undefined) visible.add(activeWorkspace);
  const elements = [];
  let x = 0;

  for (const index of [...visible].sort((a, b) => a - b)) {
    if (index === activeWorkspace) {
      elements.push(`<rect x="${x}" y="1" width="32" height="10" rx="5" fill="#f4f4f5"/>`);
      x += 32;
    } else {
      elements.push(`<circle cx="${x + 4}" cy="6" r="4" fill="#77777b"/>`);
      x += 8;
    }
    x += 8;
  }

  const width = Math.max(0, x - 8);
  return {
    width,
    svg: `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="12" viewBox="0 0 ${width} 12">${elements.join("")}</svg>`,
  };
}

function renderDisconnected() {
  const width = 134;
  const height = 20;
  return {
    width,
    height,
    svg: `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}"><rect x="0.5" y="0.5" width="133" height="19" rx="9.5" fill="#18181f" stroke="#45475a"/><circle cx="11" cy="10" r="3" fill="#f38ba8"/><text x="20" y="13.5" fill="#bac2de" font-family="Segoe UI" font-size="10">Not connected</text><line x1="91.5" y1="5" x2="91.5" y2="15" stroke="#45475a"/><text x="100" y="13.5" fill="#f4f4f5" font-family="Segoe UI" font-size="10" font-weight="600">Start</text></svg>`,
  };
}

function updateImage({ width, height = 12, svg }) {
  if (svg === lastSvg) return;
  lastSvg = svg;

  const imageFile = path.join(cacheDir, `leopardwm-workspace-${process.pid}-${frame++}.svg`);
  fs.writeFileSync(imageFile, svg);
  fs.writeFileSync(cacheFile, `<img src="${pathToFileURL(imageFile).href}" width="${width}" height="${height}">`);

  if (previousImageFile) {
    const staleImageFile = previousImageFile;
    setTimeout(() => fs.rm(staleImageFile, { force: true }, () => {}), 5000);
  }
  previousImageFile = imageFile;
}

function updateWorkspaces() {
  updateImage(render());
}

function loadSavedWorkspaces() {
  try {
    const stateFile = path.join(process.env.APPDATA, "leopardwm", "data", "workspace-state.json");
    const state = JSON.parse(fs.readFileSync(stateFile, "utf8"));
    for (const item of state.workspaces ?? []) {
      const workspace = item.workspace;
      const hasWindows =
        workspace.columns?.some((column) => column.windows?.length) ||
        workspace.floating_windows?.length ||
        workspace.fullscreen_window !== null ||
        workspace.minimized_windows?.length;
      if (hasWindows) populated.add(item.workspace_index);
    }
  } catch {}
}

if (process.argv.includes("--self-test")) {
  populated.add(0);
  populated.add(1);
  populated.add(3);
  activeWorkspace = 1;
  const result = render();
  assert.strictEqual(result.width, 64);
  assert.match(result.svg, /<circle.*<rect.*<circle/);
  const disconnected = renderDisconnected();
  assert.strictEqual(disconnected.width, 134);
  assert.match(disconnected.svg, /Not connected.*Start/);
  process.exit(0);
}

fs.mkdirSync(cacheDir, { recursive: true });
loadSavedWorkspaces();

const server = net.createServer((socket) => socket.end());
server.on("error", (error) => {
  if (error.code === "EADDRINUSE") process.exit(0);
  throw error;
});

server.listen(pipeName, () => {
  let subscriber;

  for (const file of fs.readdirSync(cacheDir)) {
    if (/^leopardwm-workspace-.*\.svg$/.test(file)) fs.rmSync(path.join(cacheDir, file), { force: true });
  }

  const subscribe = () => {
    subscriber = spawn("lwm.exe", ["subscribe"], {
      stdio: ["ignore", "pipe", "ignore"],
      windowsHide: true,
    });

    let buffer = "";
    subscriber.stdout.on("data", (chunk) => {
      buffer += chunk;
      const lines = buffer.split(/\r?\n/);
      buffer = lines.pop();

      for (const line of lines) {
        try {
          const event = JSON.parse(line);
          if (event.type === "workspace_changed") {
            activeWorkspace = event.new_index;
            updateWorkspaces();
          }
          if (event.type === "layout_changed") {
            const hasWindows = event.columns?.some((column) => column.window_ids?.length);
            if (hasWindows) populated.add(event.workspace_index);
            else populated.delete(event.workspace_index);
            updateWorkspaces();
          }
        } catch {}
      }
    });

    subscriber.on("error", () => {});
    subscriber.on("close", () => {
      updateImage(renderDisconnected());
      setTimeout(subscribe, 2000);
    });
  };

  subscribe();
});
