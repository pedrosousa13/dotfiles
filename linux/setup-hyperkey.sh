#!/usr/bin/env bash
# Install keyd and map Caps Lock to Hyper (ctrl+alt+shift+super) on Linux,
# so herdr's hyperkey bindings behave the same as on macOS.
#
# Run on any Linux machine with a physical keyboard:
#   ~/dotfiles/linux/setup-hyperkey.sh
#
# Headless boxes reached over ssh do not need this — the chord is produced by
# the client machine's keyboard and travels over the connection.
set -euo pipefail

CONF_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/keyd/default.conf"

if ! command -v keyd >/dev/null; then
  echo "==> installing keyd"
  if command -v apt-get >/dev/null; then
    sudo apt-get update && sudo apt-get install -y keyd
  elif command -v pacman >/dev/null; then
    sudo pacman -S --needed --noconfirm keyd
  elif command -v dnf >/dev/null; then
    sudo dnf install -y keyd
  else
    echo "no supported package manager found — build keyd from" >&2
    echo "https://github.com/rvaiya/keyd and rerun this script" >&2
    exit 1
  fi
fi

echo "==> installing $CONF_SRC to /etc/keyd/default.conf"
sudo install -Dm644 "$CONF_SRC" /etc/keyd/default.conf

echo "==> enabling keyd"
sudo systemctl enable --now keyd
sudo keyd reload

echo
echo "done. verify with:  sudo keyd monitor"
echo "hold caps lock and press a key — it should report ctrl+alt+shift+meta."
