#!/bin/sh
# Bootstrap ~/.claude-personal (second Claude Code account).
# Shared config is symlinked from ~/.claude; account data (auth,
# history, projects, sessions) stays local to each account.
#
# Usage: ./claude/setup-personal.sh   (after `stow claude`)
set -eu

personal="$HOME/.claude-personal"
mkdir -p "$personal"

for item in settings.json skills agents commands plugins; do
  target="$personal/$item"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "skip $item: real file/dir exists (back it up first)"
    continue
  fi
  ln -sfn "$HOME/.claude/$item" "$target"
  echo "linked $item -> ~/.claude/$item"
done

echo "done. run 'claudly' and /login to authenticate the personal account."
