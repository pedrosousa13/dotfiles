#!/usr/bin/env bash
# Install the Handy Bluetooth wrapper and configure its GNOME shortcut.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_TARGET=${HANDY_BT_STOW_TARGET:-"$HOME"}
SETTINGS_FILE=${HANDY_BT_SETTINGS_FILE:-"$HOME/.local/share/com.pais.handy/settings_store.json"}
DEFAULT_SHORTCUT_PATH='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/handy/'
MEDIA_KEYS_SCHEMA='org.gnome.settings-daemon.plugins.media-keys'

resolve_command() {
  local configured=$1 fallback=$2 description=$3 resolved
  if [[ -n "$configured" ]]; then
    resolved=$(command -v -- "$configured" 2>/dev/null) || {
      printf '%s command not found: %s\n' "$description" "$configured" >&2
      return 1
    }
  else
    resolved=$(command -v -- "$fallback" 2>/dev/null) || {
      printf '%s is required; install %s and rerun.\n' \
        "$description" "$fallback" >&2
      return 1
    }
  fi
  printf '%s\n' "$resolved"
}

STOW_CMD=$(resolve_command "${HANDY_BT_STOW_CMD:-}" stow 'GNU Stow')
JQ_CMD=$(resolve_command "${HANDY_BT_JQ_CMD:-}" jq jq)
PGREP_CMD=$(resolve_command "${HANDY_BT_PGREP_CMD:-}" pgrep pgrep)
if [[ -n "${HANDY_BT_GSETTINGS_CMD:-}" ]]; then
  GSETTINGS_CMD=$(
    resolve_command "$HANDY_BT_GSETTINGS_CMD" gsettings GSettings
  )
elif [[ -x /usr/bin/gsettings ]]; then
  GSETTINGS_CMD=/usr/bin/gsettings
else
  GSETTINGS_CMD=$(resolve_command '' gsettings GSettings)
fi

[[ -f "$SETTINGS_FILE" ]] || {
  printf 'Handy settings not found at %s; start Handy once, then rerun.\n' \
    "$SETTINGS_FILE" >&2
  exit 1
}

if "$PGREP_CMD" -x handy >/dev/null 2>&1; then
  printf 'Handy is running; quit it fully, then rerun this setup.\n' >&2
  exit 1
else
  pgrep_status=$?
  if [[ "$pgrep_status" -ne 1 ]]; then
    printf 'Could not determine whether Handy is running.\n' >&2
    exit 1
  fi
fi

settings_tmp=$(mktemp "${SETTINGS_FILE}.tmp.XXXXXX")
trap 'rm -f -- "$settings_tmp"' EXIT
if ! "$JQ_CMD" -e '.settings.mute_while_recording = false' \
  "$SETTINGS_FILE" >"$settings_tmp"; then
  printf 'Handy settings are not valid JSON; no setup changes were made.\n' >&2
  exit 1
fi
chmod --reference="$SETTINGS_FILE" "$settings_tmp"

wrapper_source="$REPO_ROOT/handy/.local/bin/handy-bt-toggle"
wrapper_target="$STOW_TARGET/.local/bin/handy-bt-toggle"
if [[ -e "$wrapper_target" && ! "$wrapper_target" -ef "$wrapper_source" ]]; then
  if [[ -f "$wrapper_target" ]] &&
    cmp -s -- "$wrapper_source" "$wrapper_target"; then
    rm -- "$wrapper_target"
  else
    printf 'Refusing to replace differing file at %s\n' "$wrapper_target" >&2
    exit 1
  fi
fi

printf '==> stowing Handy wrapper\n'
"$STOW_CMD" -d "$REPO_ROOT" -t "$STOW_TARGET" -R handy

current_shortcuts=$(
  "$GSETTINGS_CMD" get "$MEDIA_KEYS_SCHEMA" custom-keybindings
)

mapfile -t shortcut_paths < <(
  grep -oE "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/[^']+/" \
    <<<"$current_shortcuts" || true
)

SHORTCUT_PATH=
default_path_command=
for candidate_path in "${shortcut_paths[@]}"; do
  candidate_schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$candidate_path"
  candidate_command=$(
    "$GSETTINGS_CMD" get "$candidate_schema" command
  )
  candidate_command=${candidate_command#\'}
  candidate_command=${candidate_command%\'}
  if [[ "$candidate_command" == 'handy --toggle-transcription' ||
    "$candidate_command" == "$wrapper_target" ]]; then
    SHORTCUT_PATH=$candidate_path
    break
  fi
  if [[ "$candidate_path" == "$DEFAULT_SHORTCUT_PATH" ]]; then
    default_path_command=$candidate_command
  fi
done

if [[ -z "$SHORTCUT_PATH" ]]; then
  if [[ -n "$default_path_command" ]]; then
    printf 'Refusing to overwrite occupied GNOME shortcut at %s\n' \
      "$DEFAULT_SHORTCUT_PATH" >&2
    exit 1
  fi
  SHORTCUT_PATH=$DEFAULT_SHORTCUT_PATH
fi

if [[ "$current_shortcuts" != *"$SHORTCUT_PATH"* ]]; then
  case "$current_shortcuts" in
    '@as []'|'[]')
      updated_shortcuts="['$SHORTCUT_PATH']"
      ;;
    '['*']')
      updated_shortcuts="${current_shortcuts%]}, '$SHORTCUT_PATH']"
      ;;
    *)
      printf 'Unexpected GNOME custom-keybinding list: %s\n' \
        "$current_shortcuts" >&2
      exit 1
      ;;
  esac
  "$GSETTINGS_CMD" set "$MEDIA_KEYS_SCHEMA" custom-keybindings \
    "$updated_shortcuts"
fi

SHORTCUT_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$SHORTCUT_PATH"
printf '==> configuring Alt+Space shortcut\n'
"$GSETTINGS_CMD" set "$SHORTCUT_SCHEMA" name 'Handy Toggle'
"$GSETTINGS_CMD" set "$SHORTCUT_SCHEMA" binding '<Alt>space'
"$GSETTINGS_CMD" set "$SHORTCUT_SCHEMA" command \
  "$STOW_TARGET/.local/bin/handy-bt-toggle"

printf '==> disabling Handy output muting\n'
mv -- "$settings_tmp" "$SETTINGS_FILE"
trap - EXIT

printf 'done. Alt+Space now toggles Handy with the Bluetooth microphone.\n'
