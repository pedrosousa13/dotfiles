#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
TEST_HOME="$TEST_ROOT/home"
STATE_DIR="$TEST_ROOT/gsettings"
MOCK_DIR="$TEST_ROOT/bin"
SETTINGS_FILE="$TEST_HOME/.local/share/com.pais.handy/settings_store.json"
TEST_JQ=$(command -v jq)
TEST_STOW=$(command -v stow)

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$TEST_HOME" "$(dirname "$SETTINGS_FILE")" "$STATE_DIR" "$MOCK_DIR"

cat >"$SETTINGS_FILE" <<'JSON'
{
  "settings": {
    "mute_while_recording": true,
    "post_process_api_keys": {
      "openai": "preserve-this-sentinel"
    }
  }
}
JSON

cat >"$MOCK_DIR/gsettings" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail

state_dir=${HANDY_BT_TEST_GSETTINGS_STATE:?}
operation=${1:?}
schema=${2:?}
key=${3:?}
value=${4:-}
slot=global
if [[ "$schema" == *:* ]]; then
  shortcut_path=${schema#*:}
  slot=${shortcut_path%/}
  slot=${slot##*/}
fi

case "$operation:$schema:$key" in
  get:org.gnome.settings-daemon.plugins.media-keys:custom-keybindings)
    if [[ -f "$state_dir/list" ]]; then
      cat "$state_dir/list"
    else
      printf '@as []\n'
    fi
    ;;
  get:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:*/:command)
    if [[ -f "$state_dir/$slot.command" ]]; then
      cat "$state_dir/$slot.command"
    else
      printf "''\n"
    fi
    ;;
  set:org.gnome.settings-daemon.plugins.media-keys:custom-keybindings)
    printf '%s\n' "$value" >"$state_dir/list"
    ;;
  set:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:*:name)
    printf '%s\n' "$value" >"$state_dir/$slot.name"
    ;;
  set:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:*:binding)
    printf '%s\n' "$value" >"$state_dir/$slot.binding"
    ;;
  set:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:*:command)
    printf '%s\n' "$value" >"$state_dir/$slot.command"
    ;;
  *)
    printf 'unexpected gsettings invocation: %q %q %q %q\n' \
      "$operation" "$schema" "$key" "$value" >&2
    exit 2
    ;;
esac
MOCK
chmod +x "$MOCK_DIR/gsettings"

cat >"$MOCK_DIR/pgrep-not-running" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
cat >"$MOCK_DIR/pgrep-running" <<'MOCK'
#!/usr/bin/env bash
printf '12345\n'
MOCK
chmod +x "$MOCK_DIR/pgrep-not-running" "$MOCK_DIR/pgrep-running"

mkdir -p "$TEST_HOME/.local/bin"
cp "$PROJECT_DIR/handy/.local/bin/handy-bt-toggle" \
  "$TEST_HOME/.local/bin/handy-bt-toggle"
[[ ! -L "$TEST_HOME/.local/bin/handy-bt-toggle" ]] || {
  printf 'FAIL: migration fixture must start as a regular file\n' >&2
  exit 1
}

run_setup() {
  HOME="$TEST_HOME" \
    HANDY_BT_GSETTINGS_CMD="$MOCK_DIR/gsettings" \
    HANDY_BT_JQ_CMD="$TEST_JQ" \
    HANDY_BT_PGREP_CMD="${HANDY_BT_TEST_PGREP_CMD:-$MOCK_DIR/pgrep-not-running}" \
    HANDY_BT_SETTINGS_FILE="$SETTINGS_FILE" \
    HANDY_BT_STOW_CMD="$TEST_STOW" \
    HANDY_BT_STOW_TARGET="$TEST_HOME" \
    HANDY_BT_TEST_GSETTINGS_STATE="$STATE_DIR" \
    "$PROJECT_DIR/linux/setup-handy-bt.sh"
}

setup_status=0
run_setup || setup_status=$?
if [[ "$setup_status" -ne 0 ]]; then
  printf 'FAIL: setup exited %s\n' "$setup_status" >&2
  exit 1
fi

wrapper_link="$TEST_HOME/.local/bin/handy-bt-toggle"
[[ -e "$wrapper_link" ]] || {
  printf 'FAIL: wrapper was not installed by Stow\n' >&2
  exit 1
}
[[ "$(readlink -f "$wrapper_link")" == \
  "$PROJECT_DIR/handy/.local/bin/handy-bt-toggle" ]] || {
  printf 'FAIL: wrapper symlink points outside the Handy package\n' >&2
  exit 1
}

"$TEST_JQ" -e '
  .settings.mute_while_recording == false and
  .settings.post_process_api_keys.openai == "preserve-this-sentinel"
' "$SETTINGS_FILE" >/dev/null || {
  printf 'FAIL: setup did not patch only the Handy mute setting\n' >&2
  exit 1
}

shortcut_path='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/handy/'
[[ "$(grep -Fo "$shortcut_path" "$STATE_DIR/list" | wc -l)" -eq 1 ]] || {
  printf 'FAIL: shortcut path was not installed exactly once\n' >&2
  exit 1
}
[[ "$(cat "$STATE_DIR/handy.name")" == 'Handy Toggle' ]] || {
  printf 'FAIL: shortcut name is wrong\n' >&2
  exit 1
}
[[ "$(cat "$STATE_DIR/handy.binding")" == '<Alt>space' ]] || {
  printf 'FAIL: shortcut binding is wrong\n' >&2
  exit 1
}
[[ "$(cat "$STATE_DIR/handy.command")" == "$wrapper_link" ]] || {
  printf 'FAIL: shortcut command is wrong\n' >&2
  exit 1
}

run_setup
[[ "$(grep -Fo "$shortcut_path" "$STATE_DIR/list" | wc -l)" -eq 1 ]] || {
  printf 'FAIL: rerunning setup duplicated the shortcut\n' >&2
  exit 1
}

legacy_path='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/'
printf "['%s']\n" "$legacy_path" >"$STATE_DIR/list"
printf 'handy --toggle-transcription\n' >"$STATE_DIR/custom2.command"
run_setup
[[ "$(grep -Fo "$legacy_path" "$STATE_DIR/list" | wc -l)" -eq 1 ]] || {
  printf 'FAIL: setup did not reuse the existing Handy shortcut slot\n' >&2
  exit 1
}
[[ "$(cat "$STATE_DIR/list")" != *"$shortcut_path"* ]] || {
  printf 'FAIL: setup duplicated the existing Handy shortcut\n' >&2
  exit 1
}
[[ "$(cat "$STATE_DIR/custom2.command")" == "$wrapper_link" ]] || {
  printf 'FAIL: setup did not migrate the existing Handy command\n' >&2
  exit 1
}

list_before=$(cat "$STATE_DIR/list")
running_status=0
HANDY_BT_TEST_PGREP_CMD="$MOCK_DIR/pgrep-running" run_setup ||
  running_status=$?
[[ "$running_status" -ne 0 ]] || {
  printf 'FAIL: setup ran while Handy was still active\n' >&2
  exit 1
}
[[ "$(cat "$STATE_DIR/list")" == "$list_before" ]] || {
  printf 'FAIL: active-Handy refusal mutated shortcuts\n' >&2
  exit 1
}

printf "['%s']\n" "$shortcut_path" >"$STATE_DIR/list"
printf '/usr/local/bin/not-handy\n' >"$STATE_DIR/handy.command"
occupied_status=0
run_setup || occupied_status=$?
[[ "$occupied_status" -ne 0 ]] || {
  printf 'FAIL: setup overwrote an occupied dedicated shortcut\n' >&2
  exit 1
}
[[ "$(cat "$STATE_DIR/handy.command")" == '/usr/local/bin/not-handy' ]] || {
  printf 'FAIL: occupied dedicated shortcut was modified\n' >&2
  exit 1
}

printf '@as []\n' >"$STATE_DIR/list"
printf '{broken json\n' >"$SETTINGS_FILE"
malformed_status=0
run_setup || malformed_status=$?
[[ "$malformed_status" -ne 0 ]] || {
  printf 'FAIL: malformed Handy settings were accepted\n' >&2
  exit 1
}
[[ "$(cat "$STATE_DIR/list")" == '@as []' ]] || {
  printf 'FAIL: malformed settings caused partial shortcut setup\n' >&2
  exit 1
}

printf '@as []\n' >"$STATE_DIR/list"
: >"$SETTINGS_FILE"
empty_status=0
run_setup || empty_status=$?
[[ "$empty_status" -ne 0 ]] || {
  printf 'FAIL: empty Handy settings were accepted\n' >&2
  exit 1
}
[[ "$(cat "$STATE_DIR/list")" == '@as []' ]] || {
  printf 'FAIL: empty settings caused partial shortcut setup\n' >&2
  exit 1
}

printf 'PASS: Handy setup is complete, secret-safe, and idempotent\n'
