#!/bin/sh
# Installs what linux/build.sh built: bada-linux's Fcitx5 addon and IBus engine (system-wide, as
# Fcitx5 and IBus only load them from there) and ara's IME folder into
# <prefix>/share/bada-linux/imes/ara/. Asks for sudo. Then restart Fcitx5 (fcitx5 -r) or IBus.
#
#   linux/install.sh               install (or update)
#   linux/install.sh --uninstall   remove what it installed
#   PREFIX=/usr/local …            must match the build's (default /usr)
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
build=$root/linux/build
prefix=${PREFIX:-/usr}
sudo=sudo; [ "$(id -u)" = 0 ] && sudo=

if [ "${1:-}" = --uninstall ]; then
  [ -f "$build/host/install_manifest.txt" ] && xargs -d '\n' $sudo rm -f < "$build/host/install_manifest.txt"
  $sudo rm -rf "$prefix/share/bada-linux/imes/ara"
  $sudo rm -f "$prefix/share/ibus/component/bada-linux-ara.xml"
  echo "Uninstalled ara ime. Restart Fcitx5 (fcitx5 -r) or IBus (ibus restart)."
  exit 0
fi

[ -d "$build/stage/ara" ] || { echo "Run linux/build.sh first." >&2; exit 1; }
$sudo cmake --install "$build/host"
$sudo rm -rf "$prefix/share/bada-linux/imes/ara"
$sudo env BADA_IBUS="$prefix/libexec/bada-ibus" sh "$root/linux/host/tools/install-ime.sh" "$build/stage/ara" "$prefix"
echo "Installed. Restart Fcitx5 (fcitx5 -r) or IBus (ibus restart), then add \"ara ime\" (docs/linux.md, Set up)."
