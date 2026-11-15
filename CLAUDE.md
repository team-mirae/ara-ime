# ara ime

- **ara ime** (아라 입력기, アラIME) is bada ime on Linux: a GitHub fork of `team-mirae/bada-ime` with
  the macOS shell (`mac/`) removed and a Fcitx5 / IBus input method in its place. Names: ara
  (lowercase), アラ (katakana), 아라. The layouts keep bada's names (bada, bada roman, bada plain); the
  engine and its C ABI stay `bada` (`bada_*`). Windows sibling: team-mirae/pado-ime.
- Source of truth: bada's `docs/spec.md` and `docs/layouts/` for behaviour, and
  [docs/linux.md](docs/linux.md) for what ara does on Linux (where it differs from the Mac). If code
  and docs disagree, the docs win or are updated in the same change. Don't implement **[decide]**
  items silently.
- **Stay a fork.** Everything outside `linux/`, `docs/linux.md`, `README.md`, `CLAUDE.md`, `.gitignore`
  and `.github/workflows/{linux,sync-upstream}.yml` is bada's: change it upstream in
  team-mirae/bada-ime, not here, so merges stay clean. Upstream comes down through
  `.github/workflows/sync-upstream.yml` (docs/linux.md, "Staying a fork").
- `linux/host/` is team-mirae/bada-linux as a git subtree (`git subtree pull --prefix=linux/host …
  --squash`); its own `CLAUDE.md` applies inside it. Keep changes there generic (any engine) and send
  them upstream; ara-specific code goes in `linux/ara`, `linux/*.sh`, `linux/tests`.
- `linux.id` in `linux/ara/ime.json` (`bada-ara`) is permanent.
- License: MIT © Mirae Research; `linux/host` is CC0.
- Ask before changing the user's desktop input settings (Fcitx5 profile, KDE's Virtual Keyboard,
  environment variables). `linux/test.sh` runs a private fcitx5 and touches nothing.

## Building

- Linux: `linux/build.sh` (engine as `libara_engine.so`, bada-linux's Fcitx5 addon and IBus engine
  for whichever headers are installed, the staged IME in `linux/build/stage/ara/`; `--engine-tests`),
  `linux/install.sh` (sudo; `--uninstall`), `linux/test.sh` (ara end to end through a private fcitx5;
  after a build). CI: `.github/workflows/linux.yml` (x86_64 and arm64, in
  `linux/host/tools/Dockerfile`).
- Engine: `cargo test` in `engine/` (bada's tests). The typing robot: `cargo test --release --test robot`
  (docs/robot.md; CI: `.github/workflows/robot.yml`).
- Engine data and the analysis tools: as bada's (docs/layouts/13-bada.md §H9 and the build scripts in
  `engine/tools/`); regenerate them upstream.
- Web simulator (`web/`): bada's, `node web/build.mjs`. ara doesn't deploy it.
