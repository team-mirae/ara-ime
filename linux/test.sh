#!/bin/sh
# ara's end-to-end test (linux/tests/ara_e2e.py): what linux/build.sh built, installed into
# linux/build/root (nothing system-wide), in a fresh fcitx5 on its own session bus, home and runtime
# dir, driven over D-Bus as an app's input module drives it. Doesn't touch the desktop's Fcitx5.
#
#   linux/test.sh        after linux/build.sh. Needs fcitx5, dbus-run-session, python-dbus, python-gobject
#
# bada-linux's own tests (any engine, in Docker): linux/host/tools/test.sh.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
build=$root/linux/build
[ -d "$build/stage/ara" ] || { echo "Run linux/build.sh first." >&2; exit 1; }

dest=$build/root
rm -rf "$dest"
DESTDIR=$dest cmake --install "$build/host" > /dev/null
prefix=$(sed -n 's/^CMAKE_INSTALL_PREFIX:PATH=//p' "$build/host/CMakeCache.txt")
libdir=$(sed -n 's/^CMAKE_INSTALL_LIBDIR:PATH=//p' "$build/host/CMakeCache.txt")
mkdir -p "$dest$prefix/share/bada-linux/imes"
cp -R "$build/stage/ara" "$dest$prefix/share/bada-linux/imes/"

t=$build/e2e
rm -rf "$t" && mkdir -p "$t/home/.config/fcitx5" "$t/run" && chmod 700 "$t/run"
export HOME=$t/home XDG_CONFIG_HOME=$t/home/.config XDG_RUNTIME_DIR=$t/run
unset XDG_DATA_HOME DISPLAY WAYLAND_DISPLAY
export XDG_DATA_DIRS=$dest$prefix/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
export FCITX_ADDON_DIRS=$dest$prefix/$libdir/fcitx5:$prefix/$libdir/fcitx5
export PYTHONPATH=$root/linux/host/tests/e2e
cat > "$XDG_CONFIG_HOME/fcitx5/profile" <<'EOF'
[Groups/0]
Name=Default
Default Layout=jp
DefaultIM=bada-ara

[Groups/0/Items/0]
Name=keyboard-jp
Layout=

[Groups/0/Items/1]
Name=bada-ara
Layout=

[GroupOrder]
0=Default
EOF
# docs/linux.md, Set up: 半角/全角 and the Apple keys are the IME's, not Fcitx5's hotkeys.
cat > "$XDG_CONFIG_HOME/fcitx5/config" <<'EOF'
[Hotkey/TriggerKeys]
0=Control+space

[Hotkey/ActivateKeys]

[Hotkey/DeactivateKeys]
EOF

echo "== ara through fcitx5"
dbus-run-session -- sh -c '
  fcitx5 --disable=all --enable=dbus,dbusfrontend,keyboard,bada-linux > "$HOME/fcitx5.log" 2>&1 &
  pid=$!
  python3 "'"$root"'/linux/tests/ara_e2e.py"; status=$?
  kill $pid 2>/dev/null; wait $pid 2>/dev/null
  if [ $status -ne 0 ]; then echo "--- fcitx5 log"; tail -40 "$HOME/fcitx5.log"; fi
  exit $status'
