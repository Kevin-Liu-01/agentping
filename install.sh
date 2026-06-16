#!/usr/bin/env bash
# install.sh: put agentping on PATH, and optionally expose it as a skill to
# any AI agents installed on this machine.
#
#   ./install.sh            # symlink `agentping` into ~/.local/bin
#   ./install.sh --skills   # also link this repo as a skill into agent skill dirs
#
# Override the bin dir with AGENTPING_BIN=/somewhere ./install.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
TOOL="$REPO/agentping"
WITH_SKILLS=0
[ "${1:-}" = "--skills" ] && WITH_SKILLS=1

chmod +x "$TOOL"

BIN="${AGENTPING_BIN:-$HOME/.local/bin}"
mkdir -p "$BIN"
ln -sf "$TOOL" "$BIN/agentping"
echo "linked $BIN/agentping -> $TOOL"
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "note: $BIN is not on your PATH; add it in your shell profile to call 'agentping' directly" ;;
esac

if [ "$WITH_SKILLS" = 1 ]; then
  link_skill() {
    [ -d "$1" ] || return 0
    ln -sfn "$REPO" "$1/agentping"
    echo "linked skill: $1/agentping -> $REPO"
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

echo "done. verify with:  agentping doctor"
echo "optional (macOS logo banners):  agentping setup-logo"
[ -f "$HOME/.config/agentping/config.json" ] || \
  echo "optional: cp config.example.json ~/.config/agentping/config.json  (phone/Slack/custom channels)"
