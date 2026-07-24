#!/usr/bin/env bash
# Claude Code Notification hook -> herdr pane blocked reason.
# Pushes the Notification message into the pane's "blocked" state label so the
# herdr-ntfysh plugin surfaces WHY the agent is blocked instead of a generic line.
#
# Turn off:  export HERDR_WHY=0
# No-op unless running inside a herdr-managed pane.

[ "${HERDR_WHY:-1}" = 0 ] && exit 0
[ "${HERDR_ENV:-}" = 1 ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

msg=$(jq -r '.message // empty')
[ -n "$msg" ] || exit 0

herdr pane report-metadata "$HERDR_PANE_ID" \
  --source claude-why \
  --state-label "blocked=$msg" \
  --ttl-ms 120000 >/dev/null 2>&1

exit 0
