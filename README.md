<p align="center">
  <img src="assets/logo.svg" alt="Agent-Notify" width="150" height="150">
</p>

<h1 align="center">agent-notify</h1>

<p align="center"><em>Let any AI agent tap you on the shoulder.</em></p>

<p align="center">
  <a href="#install">Install</a> &middot;
  <a href="#the-four-verbs">Verbs</a> &middot;
  <a href="#channels-the-linkup-layer">Channels</a> &middot;
  <a href="LICENSE">MIT</a>
</p>

When an agent is blocked and needs your approval, an answer, or a decision, it
pings you through your normal notification settings and waits for your reply. No
more coming back to a chat that has been idle for an hour because the agent was
too polite to interrupt.

One file, no dependencies (Python 3.8+ standard library only), works from any
agent that can run a shell command: **Cursor, Claude Code, Codex, OpenClaw,
Hermes**, or your own scripts.

```bash
# the agent runs this and blocks until you tap a button on your Mac/Linux/Windows:
agent-notify confirm "Run the destructive migration on prod?" && ./migrate.sh
```

---

## Why

Agents stall silently or, worse, guess. Both are bad. `agent-notify` gives them
a reliable out-of-band channel to you:

- **Approval gates.** Pause before anything risky or irreversible.
- **Real questions.** Get the one answer the agent genuinely cannot infer.
- **Sign-off.** "The long job finished; what next?"
- **Away from the keyboard?** Route the ping to your **phone** and reply from there.

The agent always calls the same four verbs. **You** decide where the ping lands:
desktop, phone, Slack, or a command of your own. That indirection is the whole
idea: the *notification linkup* lives in your config, not in the agent.

## Install

```bash
git clone https://github.com/Kevin-Liu-01/Agent-Notify.git
cd Agent-Notify
./install.sh            # symlinks `agent-notify` into ~/.local/bin
# or:
./install.sh --skills   # also expose it as a skill to installed agents
```

Or just drop the single `agent-notify` file anywhere on your `PATH` and
`chmod +x` it. Verify:

```bash
agent-notify doctor
```

## The four verbs

```bash
# 1. notify: fire-and-forget banner
agent-notify notify "Deploy finished, all checks green" --title "CI"

# 2. ask: free-text answer (printed to stdout)
region="$(agent-notify ask 'Which region should I deploy to?' --default 'us-east-1')"

# 3. confirm: approve/deny (the exit code IS the answer)
if agent-notify confirm 'Delete 1,204 orphaned rows?'; then ./cleanup.sh; fi

# 4. choose: pick one of several
plan="$(agent-notify choose 'How should I fix this?' \
        --option 'Patch the call site' \
        --option 'Fix the root cause' \
        --option 'Leave it for now')"
```

### Reading the result

The **exit code** is the headline:

| code | meaning |
|------|---------|
| `0`   | delivered / answered / approved / chosen |
| `20`  | denied, declined, or dismissed |
| `124` | timed out (no answer before `--timeout`) |
| `2`   | usage error |
| `3`   | could not deliver |

Add `--json` for the full picture (recommended for `ask`/`choose` so you can
also detect timeouts):

```bash
agent-notify ask 'Pick a name' --json
# {"status":"answered","verb":"ask","channel":"system","response":"orion","error":null}
```

`status` is one of `delivered | answered | approved | denied | chosen | timeout | cancelled | error`.

### Common flags

| flag | applies to | meaning |
|------|------------|---------|
| `--title` | all | notification title (default `Agent`) |
| `--timeout SECONDS` | ask/confirm/choose | wait time; `0` = forever (default `120`) |
| `--channel NAME` | all | send through a specific configured channel |
| `--urgency low\|normal\|high` | all | sound / priority hint |
| `--default TEXT` | ask | prefill the answer box |
| `--yes / --no LABEL` | confirm | relabel buttons (labels are the approve/deny words) |
| `--option VALUE` | choose | a choice; repeat for each (need >= 2) |

## Channels (the linkup layer)

By default everything goes to the **`system`** channel: a native desktop
notification/dialog (macOS `osascript`, Linux `notify-send`/`zenity`/`kdialog`,
Windows PowerShell). Zero config required.

To add more destinations, create `~/.config/agent-notify/config.json`
(see [`config.example.json`](./config.example.json)):

```json
{
  "default_channel": "system",
  "channels": {
    "system": { "type": "system" },
    "phone":  { "type": "ntfy", "topic": "my-unguessable-topic-x9f2" },
    "slack":  { "type": "webhook", "url": "https://hooks.slack.com/services/..." },
    "discord":{ "type": "webhook", "url": "https://discord.com/api/webhooks/...", "body": "{{\"content\": \"{title}: {message}\"}}" },
    "say":    { "type": "command", "notify": ["say", "{title}. {message}"] }
  }
}
```

Then target one explicitly: `agent-notify ask "..." --channel phone`, or set it as
`default_channel` (handy on a headless box where the desktop channel can't run).

### Logo banners (optional, macOS)

Out of the box, `notify` uses **osascript** (no extra setup). If you want the
repo logo in the banner, opt in once:

```bash
agent-notify setup-logo
```

That installs `terminal-notifier` if needed, writes config so `notify` uses the
`banner` channel while `ask`/`confirm`/`choose` stay on system dialogs, and sends
a test ping. macOS may ask once to allow your terminal app to post notifications.

### Channel types

| type | notify | ask / confirm / choose | notes |
|------|:------:|:----------------------:|-------|
| `system`  | yes | yes | native desktop; the default |
| `banner`  | yes | no | macOS logo banners via `setup-logo` (terminal-notifier) |
| `ntfy`    | yes | yes (round-trip) | phone push; you reply from the [ntfy](https://ntfy.sh) app and the agent reads it back |
| `webhook` | yes | no | one-way POST; default body `{"text": ...}` suits Slack. Discord needs a `content` body template (see [`config.example.json`](./config.example.json)) |
| `command` | yes | yes | run any program; placeholders `{message} {title} {default} {options}` |

The **`ntfy`** channel is what makes "the user is away" work: the agent publishes
your question to a topic, you get a push notification, you reply to the topic from
the ntfy app, and the agent reads your reply back off the same topic. Self-host
ntfy or use the public `ntfy.sh`; pick an unguessable topic name.

The **`command`** channel is the escape hatch for anything else: a Telegram CLI,
text-to-speech, a webhook with a custom shape. For `ask`/`choose`
the agent reads your program's **stdout**; for `confirm`, **exit 0 = approve**,
nonzero = deny.

> **No silent fallback.** If a channel can't do the verb you asked for (say, the
> `system` channel on a machine with no desktop), it fails loudly with a typed
> error naming the problem. It never quietly routes elsewhere. Choose the channel
> deliberately.

## Using it from an agent

`agent-notify` ships a [`SKILL.md`](./SKILL.md), so agents that support skills
(Claude Code, Codex, Cursor, OpenClaw, ...) can load it and learn when to reach for
it. `./install.sh --skills` symlinks this repo into the skill directories it finds
(`~/.claude/skills`, `~/.codex/skills`, `~/.cursor/skills`, `~/.openclaw/skills`,
`~/.config/hermes/skills`). For any other agent, point it at the four verbs above
and the exit-code contract; that is the entire interface.

## How it works

```
agent --> shell --> agent-notify <verb> <message> [flags]
                       |
                       |  load ~/.config/agent-notify/config.json (or built-in default)
                       |  pick the channel (--channel, else default_channel)
                       |  deliver; for ask/confirm/choose, block for the reply
                       v
             system : osascript / notify-send / zenity / PowerShell  (this machine)
             ntfy   : POST to a topic, then poll it for your reply    (your phone)
             webhook: POST once                                       (Slack/Discord)
             command: run your program                                (anything)
                       |
                       v
                    result: stdout (answer) + exit code  (+ optional --json)
```

## Security notes

- `config.json` can hold an ntfy token or a webhook URL, so it is git-ignored
  here; keep it `chmod 600` and out of version control.
- The `command` channel runs whatever **you** put in your config. Only put trusted
  commands there; the message/title text an agent passes is substituted as argv,
  not run through a shell.
- ntfy topics are effectively passwords. Use a long, random topic name (or a
  self-hosted server with auth) so others can't read your prompts or inject replies.

## Limitations

- The `system` channel needs a desktop session; on headless/CI machines use
  `ntfy`/`webhook`/`command` instead.
- macOS `choose` has no native countdown, so `--timeout` is enforced by killing
  the dialog rather than letting it self-dismiss.
- Windows support (`notify`/`ask`/`confirm`) is best-effort via PowerShell; `choose`
  is not implemented there; use `ask` or an `ntfy`/`command` channel.

## License

MIT. See [LICENSE](./LICENSE).
