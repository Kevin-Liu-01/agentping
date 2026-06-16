<p align="center">
  <img src="assets/logo.svg" alt="agentping" width="150" height="150">
</p>

<h1 align="center">agentping</h1>

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
agentping confirm "Run the destructive migration on prod?" && ./migrate.sh
```

---

## Why

Agents stall silently or, worse, guess. Both are bad. `agentping` gives them
a reliable out-of-band channel to you:

- **Approval gates.** Pause before anything risky or irreversible.
- **Real questions.** Get the one answer the agent genuinely cannot infer.
- **Sign-off.** "The long job finished; what next?"
- **Away from the keyboard?** Route the ping to your **phone** and reply from there.

The agent always calls the same four verbs. **You** decide where the ping lands:
desktop, phone, Slack, or a command of your own. That indirection is the whole
idea: the *notification linkup* lives in your config, not in the agent.

## Install

**npm** (one command; gives you the `agentping` command):

```bash
npm install -g agentping
```

agentping is one Python file, and the npm package is a thin launcher around
it, so you need **Python 3.8+** on your `PATH` (point `AGENTPING_PYTHON` at a
specific interpreter if `python3`/`python` isn't it). No Python packages to install.

**From source:**

```bash
git clone https://github.com/Kevin-Liu-01/agentping.git
cd agentping
./install.sh            # symlinks `agentping` into ~/.local/bin
# or:
./install.sh --skills   # also expose it as a skill to installed agents
```

Or just drop the single `agentping` file anywhere on your `PATH` and
`chmod +x` it. Verify:

```bash
agentping doctor
```

## The four verbs

```bash
# 1. notify: fire-and-forget banner
agentping notify "Deploy finished, all checks green" --title "CI"

# 2. ask: free-text answer (printed to stdout)
region="$(agentping ask 'Which region should I deploy to?' --default 'us-east-1')"

# 3. confirm: approve/deny (the exit code IS the answer)
if agentping confirm 'Delete 1,204 orphaned rows?'; then ./cleanup.sh; fi

# 4. choose: pick one of several
plan="$(agentping choose 'How should I fix this?' \
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
agentping ask 'Pick a name' --json
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
| `--sound NAME` | all (macOS) | notification sound: a name (`Glass`, `Ping`, `Sosumi`...), `auto` (a tone per verb), or `none` |
| `--default TEXT` | ask | prefill the answer box |
| `--yes / --no LABEL` | confirm | relabel buttons (labels are the approve/deny words) |
| `--option VALUE` | choose | a choice; repeat for each (need >= 2) |

## Channels (the linkup layer)

By default everything goes to the **`system`** channel: a native desktop
notification/dialog (macOS `osascript`, Linux `notify-send`/`zenity`/`kdialog`,
Windows PowerShell). Zero config required.

To add more destinations, create `~/.config/agentping/config.json`
(see [`config.example.json`](./config.example.json)):

```json
{
  "default_channel": "system",
  "channels": {
    "system": { "type": "system" },
    "phone":  { "type": "ntfy", "topic": "my-unguessable-topic-x9f2" },
    "iphone": { "type": "imessage", "to": "+15551234567" },
    "sms":    { "type": "sms", "from": "+15550000000", "to": "+15551234567" },
    "slack":  { "type": "webhook", "url": "https://hooks.slack.com/services/..." },
    "discord":{ "type": "webhook", "url": "https://discord.com/api/webhooks/...", "body": "{{\"content\": \"{title}: {message}\"}}" },
    "say":    { "type": "command", "notify": ["say", "{title}. {message}"] }
  }
}
```

Then target one explicitly: `agentping ask "..." --channel phone`, or set it as
`default_channel` (handy on a headless box where the desktop channel can't run).

### Logo banners (optional, macOS)

Out of the box, `notify` uses **osascript** (no extra setup). If you want the
repo logo in the banner, opt in once:

```bash
agentping setup-logo
```

That installs `terminal-notifier` if needed, writes config so `notify` uses the
`banner` channel while `ask`/`confirm`/`choose` stay on system dialogs, and sends
a test ping. macOS may ask once to allow your terminal app to post notifications.

### Notification sounds (macOS)

Give agentping a distinct, recognizable sound so you know a ping is from your
agent. Set `sound` on the `system` (or `banner`) channel:

```json
"system": { "type": "system", "sound": "auto" }
```

- `"auto"` plays a **different tone per verb** so you can tell by ear what the
  agent needs: `notify` -> Glass, `ask` -> Ping, `choose` -> Pop, `confirm` -> Sosumi.
- Set one name for everything (`"sound": "Hero"`), a per-verb map
  (`"sound": { "confirm": "Sosumi", "default": "Glass" }`), or `"none"` to silence.
- Override per call with `--sound NAME` (or `--sound none`).
- Names are macOS sounds in `/System/Library/Sounds` (Glass, Hero, Ping, Pop,
  Sosumi, Submarine, Tink, ...). For a **custom** sound, drop a `.aiff` in
  `~/Library/Sounds` and use its filename. Sounds require notifications to be
  allowed for your terminal in System Settings -> Notifications.

This covers the desktop **`system`** and **`banner`** channels. `imessage`/`sms`
use the phone's text tone, and `ntfy` uses the ntfy app's sound (set there).

### Channel types

| type | notify | ask / confirm / choose | notes |
|------|:------:|:----------------------:|-------|
| `system`  | yes | yes | native desktop; the default |
| `banner`  | yes | no | macOS logo banners via `setup-logo` (terminal-notifier) |
| `ntfy`    | yes | yes (round-trip) | phone push; you reply from the [ntfy](https://ntfy.sh) app and the agent reads it back |
| `imessage`| yes | yes (round-trip) | macOS; texts your own number/Apple ID via Messages, reads your reply back from the Messages database. No API key, no fee |
| `sms`     | yes | no | outbound SMS via [Twilio](https://www.twilio.com) (external provider); reaches non-Apple phones and works from a non-Mac host |
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

### Text me: iMessage and SMS

Two ways to land the ping as a normal text message on a phone.

**`imessage`** (macOS, free, your own number). Sends through the Messages app
under your own account to any phone number or Apple ID, and it is **two-way**:
the agent texts you the question and reads your reply back from the local
Messages database, so you can answer from your phone like ntfy.

```json
"iphone": { "type": "imessage", "to": "+15551234567" }
```

```bash
agentping confirm "Deploy v2 to prod?" --channel iphone   # reply yes/no from your phone
```

One-time macOS setup (it fails loud and tells you which of these is missing):

- Sign in to **Messages** with your Apple ID, and text the recipient once by hand.
- Allow your terminal/agent to **control Messages** (System Settings -> Privacy &
  Security -> Automation) so it can *send*.
- Grant your terminal/agent **Full Disk Access** so it can *read your replies*
  (for the blocking verbs) and *confirm delivery* (it reports a Messages "Not
  Delivered" as an error instead of a false success). Without it, `notify` can
  only confirm the message was handed to Messages, not that Apple delivered it.

Set `"service": "SMS"` to relay green-bubble texts through a connected iPhone
(Text Message Forwarding). SSH sessions can't send.

**`sms`** (Twilio, any OS, reaches non-Apple phones). Outbound only -- a real SMS
through [Twilio](https://www.twilio.com)'s API, useful from a Linux/Windows or
headless host, or to text someone not on iMessage. Keep the token in the
environment, not the file:

```json
"sms": { "type": "sms", "from": "+15550000000", "to": "+15551234567" }
```

```bash
export TWILIO_ACCOUNT_SID=ACxxx TWILIO_AUTH_TOKEN=xxxx
agentping notify "Nightly backup finished" --channel sms
```

For a reply over SMS use `imessage` (macOS) or `ntfy` (any OS) instead; two-way
SMS would need a public inbound webhook, which this tool deliberately does not run.

> **No silent fallback.** If a channel can't do the verb you asked for (say, the
> `system` channel on a machine with no desktop), it fails loudly with a typed
> error naming the problem. It never quietly routes elsewhere. Choose the channel
> deliberately.

## Configuration: tune everything

Everything about a ping is configurable in `~/.config/agentping/config.json`
(override the path with `$AGENTPING_CONFIG`, or `$XDG_CONFIG_HOME`). The agent
always calls the same verbs; this file decides **where** it lands, **how** it looks
and sounds, **how often** it fires, and **for what** it fires.

```json
{
  "default_channel": { "notify": "banner", "default": "system" },

  "defaults": {
    "title": "Agent",
    "urgency": "normal",
    "sound": "auto",
    "timeout": 120
  },

  "policy": {
    "min_urgency": "low",
    "min_interval": 0
  },

  "channels": {
    "system": { "type": "system", "sound": "auto" },
    "quiet":  { "type": "system", "sound": "none", "title": "Background agent" }
  }
}
```

**Resolution order** for every field: a command-line flag wins, then the chosen
channel's config, then the `defaults` block, then the built-in fallback. So you
can set a global default and override it per channel or per call.

### What you can configure

| where | key | what it controls |
|-------|-----|------------------|
| routing | `default_channel` | a channel name, or a per-verb map `{ "notify": "banner", "default": "system" }` |
| appearance | `title` | the notification title (default `Agent`) |
| appearance | `urgency` | `low` / `normal` / `high` (sound + priority hint) |
| appearance | `sound` | macOS sound: a name, a per-verb map, `auto`, or `none` (see [Notification sounds](#notification-sounds-macos)) |
| appearance | `banner` channel `logo` / `sender` | the image and the app a logo banner appears to come from |
| timing | `timeout` | seconds a blocking verb waits (`0` = forever) |
| **how often** | `policy.min_interval` | drop a `notify` that lands within N seconds of the last delivered one (returns `throttled`, exit 0). `0` = never throttle |
| **for what** | `policy.min_urgency` | only deliver a `notify` at or above this urgency; lower ones return `suppressed` (exit 0) |

`title`, `urgency`, `sound`, and `timeout` may live in `defaults` (global) or on
any individual channel. `policy` applies to `notify` only -- a blocking
`ask`/`confirm`/`choose` is never suppressed or throttled, because the agent is
waiting on the answer. Run `agentping doctor` to print the resolved channels,
`defaults`, and `policy`.

## Using it from an agent

`agentping` ships a [`SKILL.md`](./SKILL.md), so agents that support skills
(Claude Code, Codex, Cursor, OpenClaw, ...) can load it and learn when to reach for
it. `./install.sh --skills` symlinks this repo into the skill directories it finds
(`~/.claude/skills`, `~/.codex/skills`, `~/.cursor/skills`, `~/.openclaw/skills`,
`~/.config/hermes/skills`). For any other agent, point it at the four verbs above
and the exit-code contract; that is the entire interface.

## How it works

```
agent --> shell --> agentping <verb> <message> [flags]
                       |
                       |  load ~/.config/agentping/config.json (or built-in default)
                       |  pick the channel (--channel, else default_channel)
                       |  deliver; for ask/confirm/choose, block for the reply
                       v
             system : osascript / notify-send / zenity / PowerShell  (this machine)
             ntfy   : POST to a topic, then poll it for your reply    (your phone)
             imessage: Messages send, then poll chat.db for reply     (your phone, macOS)
             sms    : POST to Twilio                                   (any phone)
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
- The `sms` (Twilio) channel needs an auth token. Prefer `$TWILIO_ACCOUNT_SID` /
  `$TWILIO_AUTH_TOKEN` in your environment over writing them into `config.json`.
- The `imessage` channel reads `~/Library/Messages/chat.db` to collect your reply,
  which is why the blocking verbs need Full Disk Access. It only ever reads, and
  only matches replies from the configured `to` handle.

## Limitations

- The `system` channel needs a desktop session; on headless/CI machines use
  `ntfy`/`webhook`/`command` instead.
- macOS `choose` has no native countdown, so `--timeout` is enforced by killing
  the dialog rather than letting it self-dismiss.
- Windows support (`notify`/`ask`/`confirm`) is best-effort via PowerShell; `choose`
  is not implemented there; use `ask` or an `ntfy`/`command` channel.

## License

MIT. See [LICENSE](./LICENSE).
