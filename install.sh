#!/usr/bin/env bash
# install.sh: put agent-notify on PATH, and optionally expose it as a skill to
# any AI agents installed on this machine.
#
#   ./install.sh            # symlink `agent-notify` into ~/.local/bin
#   ./install.sh --skills   # also link this repo as a skill into agent skill dirs
#
# Override the bin dir with AGENT_NOTIFY_BIN=/somewhere ./install.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
TOOL="$REPO/agent-notify"
WITH_SKILLS=0
[ "${1:-}" = "--skills" ] && WITH_SKILLS=1

chmod +x "$TOOL"

BIN="${AGENT_NOTIFY_BIN:-$HOME/.local/bin}"
mkdir -p "$BIN"
ln -sf "$TOOL" "$BIN/agent-notify"
echo "linked $BIN/agent-notify -> $TOOL"
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "note: $BIN is not on your PATH; add it in your shell profile to call 'agent-notify' directly" ;;
esac

if [ "$WITH_SKILLS" = 1 ]; then
  link_skill() {
    [ -d "$1" ] || return 0
    ln -sfn "$REPO" "$1/agent-notify"
    echo "linked skill: $1/agent-notify -> $REPO"
  }
  for dir in \
    "$HOME/.claude/skills" \
    "$HOME/.codex/skills" \
    "$HOME/.cursor/skills" \
    "$HOME/.cursor/skills-cursor" \
    "$HOME/.openclaw/skills" \
    "$HOME/.config/hermes/skills"; do
    link_skill "$dir"
  done
fi

echo
echo "done. verify with:  agent-notify doctor"
[ -f "$HOME/.config/agent-notify/config.json" ] || \
  echo "optional: cp config.example.json ~/.config/agent-notify/config.json  (to add phone/Slack/custom channels)"
