#!/bin/bash
# Shows which Claude account this session runs under (work vs personal).
# Account emails live in a local, non-committed env file:
#   ~/.claude/statusline-accounts.env
#     PERSONAL_EMAIL=you@personal.example
#     WORK_EMAIL=you@work.example
cfg="${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json"
email=$(jq -r '.oauthAccount.emailAddress // ""' "$cfg" 2>/dev/null)
[ -f "$HOME/.claude/statusline-accounts.env" ] && . "$HOME/.claude/statusline-accounts.env"
if [ -z "$email" ]; then
  printf '\033[1;33m● ?\033[0m'
elif [ "$email" = "${PERSONAL_EMAIL:-}" ]; then
  printf '\033[1;35m● personal\033[0m'
elif [ "$email" = "${WORK_EMAIL:-}" ]; then
  printf '\033[1;36m● work\033[0m'
else
  printf '\033[1;33m● %s\033[0m' "$email"
fi
