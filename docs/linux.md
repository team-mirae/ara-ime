# ara ime on Linux

ara ime (아라 입력기 · アラIME) is bada ime on Linux: bada's engine (`engine/`, unchanged) built as
`libara_engine.so`, hosted by [bada-linux](https://github.com/team-mirae/bada-linux) (`linux/host`), a
Fcitx5 addon and an IBus engine for any bada-compatible engine. Behaviour is bada's (`docs/spec.md`,
`docs/layouts/`); how keys reach the engine and text the app is bada-linux's (`linux/host/docs/spec.md`).
This page says what ara does on Linux, and where that differs from the Mac.

| Path | What |
|---|---|
| `linux/ara/ime.json` | ara's manifest: the engine, its data, `linux.id` **`bada-ara`** (permanent: it's in users' Fcitx5 profiles and GNOME's input sources), the indicator's labels |
| `linux/ara/engine/` | A cdylib crate that exports bada's C ABI (`bada::ffi`) as `libara_engine.so` |
| `linux/build.sh` | Builds the engine and the host, and stages the IME folder in `linux/build/stage/ara/` |
| `linux/install.sh` | Installs the host and ara system-wide (`--uninstall` removes them) |
| `linux/test.sh` | ara through a fresh fcitx5 on its own session bus (`linux/tests/ara_e2e.py`) |
| `linux/host/` | bada-linux, a git subtree |

## Install

From source. Arch Linux:

```sh
sudo pacman -S --needed rust cmake fcitx5 fcitx5-qt fcitx5-gtk fcitx5-configtool python-dbus
git clone https://github.com/team-mirae/ara-ime && cd ara-ime
linux/build.sh
linux/install.sh          # sudo: the addon goes where Fcitx5 loads addons from
fcitx5 -r
```

Debian / Ubuntu: `build-essential cmake pkg-config cargo rustc libdbus-1-dev` and
`fcitx5 libfcitx5core-dev libfcitx5utils-dev libfcitx5config-dev` (or `ibus libibus-1.0-dev`). The
engine needs Rust 1.85 or newer (edition 2024). `linux/build.sh` builds each frontend whose headers
are installed.

To update, pull and run `linux/build.sh` and `linux/install.sh` again, then `fcitx5 -r`.
`linux/install.sh --uninstall` removes it.

## Set up

### Fcitx5 on KDE Plasma (Wayland)

1. System Settings → Keyboard → Virtual Keyboard: **Fcitx 5**. KWin then starts Fcitx5 and hands it
   the keys (Wayland's input method protocol), so don't set `GTK_IM_MODULE` / `QT_IM_MODULE`
   globally. XWayland apps use XIM; Chromium and Electron apps need `--enable-wayland-ime`.
2. `fcitx5-configtool` (System Settings → Input Method): add **ara ime** to the group, after the
   **Keyboard - Japanese** layout. The group's layout should be `jp` for a JIS keyboard.
3. Global Options → Hotkey: take **`Zenkaku_Hankaku`** out of Trigger Input Method, and **`Hangul`** /
   **`Hangul_Hanja`** out of Activate / Deactivate Input Method. They're Fcitx5's defaults, and Fcitx5
   takes them before ara sees them: 半角/全角 is bada's full-width / half-width key, and an Apple
   keyboard's 英数 / かな arrive as `Hangul_Hanja` / `Hangul`.

Fcitx5's trigger key (⌃Space by default) switches between ara and the plain keyboard layout; ara's
own modes are switched with the language keys below.

### IBus (GNOME)

`linux/install.sh` writes `/usr/share/ibus/component/bada-linux-ara.xml`. Run `ibus restart`, then
Settings → Keyboard → Input Sources → Japanese → **ara ime**.

## Keys

bada-linux reads the JIS language keys by their evdev codes, whatever layout is loaded
(`linux/host/docs/spec.md` §4).

| Key | |
|---|---|
| **変換** | Henkan mode. The best candidate shows as you type; **Space** commits it |
| **Tab**, **↓**, **変換** | The next candidate. **⇧Tab**, **↑**, **⇧変換**: back |
| **⇧Enter** | Commits what shows, and nothing else |
| **Esc** | Commits too. It doesn't cancel, unlike most IMEs |
| **無変換** | Muhenkan mode: plain QWERTY |
| **カタカナ/ひらがな** | Henkan in its own profile (`katakana`) |
| An Apple keyboard's **英数** / **かな** | Muhenkan / henkan in profile `mac-kana` |

The indicator shows **아** in henkan and **A** in muhenkan. ara starts in muhenkan.

## Settings

`~/.config/bada-linux/bada-ara.json`, re-read when a field gets focus. The host's fields are
bada-linux's (`linux/host/docs/spec.md` §9: `caps_lock`, `pass_on`, `kana_key`, `right_alt_tap`,
`publish_state`, `off_in`, `dictionary`); the engine's go under **`engine_settings`**, as the Mac's
settings JSON has them (`enabled`, `profiles`, `weights`, `script_forms`, `ja_shortcuts`, …;
`docs/spec.md`). Henkan is bada plain (16) alone until you set it. For example, QWERTY + bada roman
on 変換, and QWERTY + kana on カタカナ:

```json
{
  "caps_lock": "respect",
  "engine_settings": {
    "enabled": [0, 16],
    "profiles": {
      "henkan": { "enabled": [0, 15] },
      "katakana": { "enabled": [0, 20] }
    }
  }
}
```

There's no settings window yet (bada-linux keeps settings a JSON file for now).

## The dictionary

Your words, and the words you never mean: `~/.local/share/bada-linux/bada-ara/dictionary.json`
(or the setting `dictionary`), in [docs/dictionary-contract.md](dictionary-contract.md)'s format. It's
read when the engine loads: restart Fcitx5 (`fcitx5 -r`) after changing it.

## State for other programs

bada-linux publishes ara's state as a file, `$XDG_RUNTIME_DIR/bada-linux/bada-ara/state.json`, and a
D-Bus signal (`me.sjun.BadaLinux.State.Changed`): `linux/host/docs/api.md`.

```sh
jq -r .mode "$XDG_RUNTIME_DIR/bada-linux/bada-ara/state.json"
```

## What isn't the Mac's

- **One input method**, not two input sources: ara switches muhenkan and henkan itself
  (`linux/host/docs/spec.md` §3).
- **⌃変換** (bada's ⌃かな, which fixes what shows) doesn't reach the engine yet: bada-linux follows
  bada-compatible v1.1, where a profile key with ⌃ is eaten. bada-windows has it (v1.3); it belongs
  upstream in bada-linux.
- **Caps Lock** is the system's by default (bada-linux's `caps_lock: "respect"`); `toggle` and
  `transient` are bada-linux's. An input method can't set the lock on Linux, and under the jp layout
  the unshifted Caps Lock key is 英数.
- **The menu** is the framework's candidate window: no separating line, no Japanese font for
  Japanese rows.
- **No Keyboard Viewer legends, no settings window.** Settings are the JSON file above.
- The data is the Mac's, with layout 15's sensitive words left out.

## Testing

- `cargo test` in `engine/`: bada's tests (`linux/build.sh --engine-tests` runs them too). The typing
  robot: `cargo test --release --test robot` (docs/robot.md).
- `linux/test.sh`: after `linux/build.sh`, ara through a fresh fcitx5 on a private session bus, as an
  app's input module drives it. It doesn't touch the desktop's Fcitx5.
- `linux/host/tools/test.sh`: bada-linux's own tests (in Docker, against shout).
- CI (`.github/workflows/linux.yml`) runs `linux/build.sh` and `linux/test.sh` on x86_64 and arm64 in
  bada-linux's Debian trixie build machine, and uploads the staged IME.

## Staying a fork

ara is a GitHub fork of [team-mirae/bada-ime](https://github.com/team-mirae/bada-ime), and `linux/host`
is a subtree of [team-mirae/bada-linux](https://github.com/team-mirae/bada-linux).
`.github/workflows/sync-upstream.yml` runs daily (and by hand). For each upstream it merges new work into
a branch (`sync/bada-ime`, `sync/bada-linux`) and opens a pull request:

- bada-ime: upstream's changes to what ara removed (`mac/`, the Mac and web-deploy workflows) are
  dropped, and ara keeps its own `README.md` and `CLAUDE.md`. Any other conflict stops the sync and
  opens an issue: merge `upstream/main` by hand.
- bada-linux: `git subtree pull --prefix=linux/host … --squash`.

By hand:

```sh
git remote add upstream https://github.com/team-mirae/bada-ime.git
git fetch upstream && git merge upstream/main
git subtree pull --prefix=linux/host https://github.com/team-mirae/bada-linux.git main --squash
```
