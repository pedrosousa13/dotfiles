#!/usr/bin/env bash
# Shows the file the agent is currently editing on the herdr agents sidebar.
# Claude Code PostToolUse hook (Edit|Write|MultiEdit) -> herdr pane report-metadata.
#
# Turn off:  export HERDR_TITLE=0
# No-op unless running inside a herdr-managed pane.

[ "${HERDR_TITLE:-1}" = 0 ] && exit 0
[ "${HERDR_ENV:-}" = 1 ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0

json=$(cat)
tool=$(printf '%s' "$json" | jq -r '.tool_name // empty')
fp=$(printf '%s' "$json" | jq -r '.tool_input.file_path // empty')
[ -n "$fp" ] || exit 0

case "$tool" in
  Write) verb="writing" ;;
  *)     verb="editing" ;;
esac

herdr pane report-metadata "$HERDR_PANE_ID" \
  --source claude-title-hook \
  --display-agent "$verb $(basename "$fp")" \
  --ttl-ms 120000 >/dev/null 2>&1

exit 0
