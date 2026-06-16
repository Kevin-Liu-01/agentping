---
name: agent-notify
description: Reach the human out-of-band when you are blocked and they may be away from the chat. Sends a real OS notification (or phone push / Slack / custom channel) and can block for the reply: a free-text answer, an approve/deny decision, or a pick-one choice. Use when you need approval before a risky or irreversible action, when you hit an ambiguous decision only the user can settle, when a long task finishes and needs sign-off, or when the user says "ping me", "notify me", "ask me when", "let me know", or "get my approval". Works from any agent that can run a shell command (Cursor, Claude Code, Codex, OpenClaw, Hermes).
---

# agent-notify

A single-file CLI that pings the human through their own notification settings
and, when you ask, waits for their reply. Use it instead of stalling silently or
guessing when you are blocked and the user might not be watching the chat.

Invoke it by path so it resolves the same from every agent:

```bash
AN="$HOME/.local/bin/agent-notify"   # or wherever install.sh put it
```

If it is not on `PATH`, call the script directly (e.g. the cloned repo path) or
`python3 /path/to/agent-notify`.

## When to reach for it

- **Approval gate** before something risky or irreversible (deploy, delete, spend, force-push, schema change).
- **Blocking decision** you genuinely cannot infer from the task or the code.
- **Done, needs sign-off**: a long-running task finished and the next step needs a human.
- The user explicitly asked to be pinged, notified, or asked.

Do **not** use it for things you can decide yourself, or to narrate progress.
One ping should carry a real question or a real decision.

## The four verbs

```bash
# Fire-and-forget banner (no reply expected)
"$AN" notify "Deploy to prod finished, all checks green" --title "CI"

# Free-text answer (printed to stdout)
answer="$("$AN" ask 'Which staging DB should I target?' --default 'staging-1')"

# Approve/deny gate (exit code is the answer)
if "$AN" confirm 'Run the destructive migration 0042 on dev?' ; then
  run_migration
else
  echo "human declined; stopping"
fi

# Pick one of several
pick="$("$AN" choose 'Which fix do you want?' \
        --option 'Patch the call site' \
        --option 'Fix the root function' \
        --option 'Skip for now')"
```

## Read the result two ways

**Exit code** (the headline, good for `confirm`):

| code | meaning |
|---|---|
| `0`   | delivered / answered / approved / chosen |
| `20`  | denied, declined, or dismissed |
| `124` | timed out (no response before `--timeout`) |
| `2`   | usage error |
| `3`   | could not deliver (transport/provider error) |

**`--json`** (the detail, best for `ask`/`choose` so you also catch timeouts):

```bash
"$AN" ask 'Pick a region' --timeout 90 --json
# {"status":"answered","verb":"ask","channel":"system","response":"us-east-1","error":null}
```

`status` is authoritative: `delivered|answered|approved|denied|chosen|timeout|cancelled|error`.
Always handle `timeout`: if the human never answered, do not guess; stop and
report that you are waiting on them.

## Flags

- `--title TEXT`: notification title (default `Agent`).
- `--timeout SECONDS`: how long to wait for a reply; `0` = wait forever (default `120`). `notify` ignores it.
- `--channel NAME`: send through a specific configured channel instead of the default.
- `--urgency low|normal|high`: hint for sound or priority.
- `ask --default TEXT`: prefill the answer box.
- `confirm --yes LABEL --no LABEL`: relabel the buttons (the labels are also what counts as approve/deny).
- `choose --option A --option B ...`: the choices (need at least two).

## Channels (the "linkup" layer)

The agent always calls the same verbs; **the user** decides where the ping lands
via `~/.config/agent-notify/config.json`. Built-in channel types:

- `system` (default, zero-config): native desktop notification/dialog.
- `ntfy`: push to a phone via [ntfy](https://ntfy.sh); the user replies from the ntfy app and you read it back. Best for "user is away from the keyboard."
- `webhook`: one-way POST (Slack/Discord/custom).
- `command`: run any program the user wires up (terminal-notifier, a Telegram CLI, text-to-speech...).

Run `"$AN" doctor` to see the host platform, which backends exist, and which
channels are configured and what each can do. If the default channel cannot do
the verb you need (e.g. a headless box with no desktop), it fails loud with a
typed error rather than silently doing nothing; pick another `--channel` or
tell the user to configure one. See `README.md` for the config schema.

## Logo banners (optional, macOS)

**Default is osascript** (zero setup, no extra permission prompts). Do not run
logo setup unless the user explicitly wants the bell image in notify banners.

When they do, on macOS only:

```bash
"$AN" setup-logo
```

That installs `terminal-notifier` if needed, ensures `assets/logo.png` exists,
writes `~/.config/agent-notify/config.json` so `notify` uses the `banner`
channel while `ask`/`confirm`/`choose` stay on system dialogs, and sends one
test banner. The user may need to allow notifications for their terminal app
once (System Settings -> Notifications).

To skip the test ping: `"$AN" setup-logo --no-test`.

To revert to osascript-only defaults, set `"default_channel": "system"` in the
config (or delete `~/.config/agent-notify/config.json`).
