#!/bin/sh
# Builds ara ime for Linux: bada's engine as libara_engine.so and bada-linux's Fcitx5 addon and IBus
# engine (linux/host); then lays the IME out as installed, in linux/build/stage/ara/: ime.json, the
# engine under <arch>/, the data ime.json lists and the licenses.
#
#   linux/build.sh                 everything (each frontend whose headers are installed)
#   linux/build.sh --engine-tests  also cargo test in engine/ (bada's own tests)
#   PREFIX=/usr/local linux/build.sh   where linux/install.sh will put the host (default /usr)
#
# Then linux/install.sh. Needs Rust (1.85+), CMake, pkg-config, libdbus and Fcitx5's or IBus'
# headers: docs/linux.md.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
build=$root/linux/build
stage=$build/stage/ara
arch=$(uname -m)
prefix=${PREFIX:-/usr}

if [ "${1:-}" = --engine-tests ]; then
  echo "== engine tests"
  cargo test --release --manifest-path "$root/engine/Cargo.toml"
fi

echo "== engine"
cargo build --release --manifest-path "$root/linux/ara/engine/Cargo.toml" --target-dir "$build/cargo"

echo "== host"
fcitx5=OFF; pkg-config --exists Fcitx5Core && fcitx5=ON
ibus=OFF; pkg-config --exists ibus-1.0 && ibus=ON
if [ $fcitx5 = OFF ] && [ $ibus = OFF ]; then
  echo "Neither Fcitx5 nor IBus headers found (docs/linux.md, Build)." >&2
  exit 1
fi
echo "fcitx5: $fcitx5, ibus: $ibus"
cmake -S "$root/linux/host" -B "$build/host" -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$prefix" -DBADA_FCITX5=$fcitx5 -DBADA_IBUS=$ibus -DBADA_TESTS=OFF > /dev/null
cmake --build "$build/host" -j"$(nproc)"

echo "== stage"
rm -rf "$stage"
mkdir -p "$stage/$arch" "$stage/licenses"
cp "$root/linux/ara/ime.json" "$stage/"
cp "$build/cargo/release/libara_engine.so" "$stage/$arch/"
# The data ime.json lists (data/…), as the Mac app shipped it: en-ko's sensitive words left out.
python3 - "$root/linux/ara/ime.json" "$root/engine" "$stage" <<'EOF'
import json, os, shutil, sys
manifest, engine, stage = sys.argv[1:]
def copy(rel):
    os.makedirs(os.path.dirname(os.path.join(stage, rel)), exist_ok=True)
    shutil.copy2(os.path.join(engine, rel), os.path.join(stage, rel))
for item in json.load(open(manifest, encoding="utf-8"))["data"]:
    for part in [item] if isinstance(item, str) else item["concat"]:
        if isinstance(part, str):
            copy(part)
        elif "dir" in part:
            for name in sorted(os.listdir(os.path.join(engine, part["dir"]))):
                if name.endswith(part.get("suffix", "")):
                    copy(os.path.join(part["dir"], name))
EOF
# Licenses: ara's (MIT), bada-linux's (CC0) and the data's.
cp "$root/LICENSE" "$stage/licenses/LICENSE-ara.txt"
cp "$root/linux/host/LICENSE" "$stage/licenses/LICENSE-bada-linux.txt"
cp "$root"/engine/data/LICENSE-*.txt "$stage/licenses/"
echo "Built $stage"
