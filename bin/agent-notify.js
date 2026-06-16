#!/usr/bin/env node
"use strict";

// agent-notify is a single-file Python 3.8+ program. This launcher runs it with
// the user's Python and passes stdio and the exit code straight through -- the
// exit code is the tool's contract (0 ok, 20 declined, 124 timeout, 2 usage,
// 3 provider), so the calling agent sees exactly what the script returns.

const { spawnSync } = require("child_process");
const path = require("path");

const script = path.join(__dirname, "..", "agent-notify");
const args = process.argv.slice(2);
const candidates = process.env.AGENT_NOTIFY_PYTHON
  ? [process.env.AGENT_NOTIFY_PYTHON]
  : ["python3", "python"];

let result;
for (const python of candidates) {
  result = spawnSync(python, [script, ...args], { stdio: "inherit" });
  // Stop at the first interpreter that actually launched.
  if (!(result.error && result.error.code === "ENOENT")) break;
}

if (result.error && result.error.code === "ENOENT") {
  process.stderr.write(
    "agent-notify needs Python 3.8+ on PATH (tried: " + candidates.join(", ") + "). " +
    "Install Python 3, or set AGENT_NOTIFY_PYTHON to its full path.\n");
  process.exit(3);
}
if (result.error) {
  process.stderr.write("agent-notify: " + String(result.error) + "\n");
  process.exit(3);
}
process.exit(result.status === null ? 1 : result.status);
