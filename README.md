### <br>

<p align="center">
  <img src="docs/images/icon/ara-icon.svg" width="96" height="96" alt="ara ime icon">

  <h3 align="center">
	아라 입력기 · アラIME
  </h3>

  <p align="center">
	An input method for multilinguals, on Linux.
  </p>
</p>

### <br>

**ara ime** is [bada ime](https://github.com/team-mirae/bada-ime) on Linux. It's a fork of bada ime
with the macOS shell taken out and a Linux input method (Fcitx5 and IBus) in its place, hosted by
[bada-linux](https://github.com/team-mirae/bada-linux). The engine, the layouts and every feature are
bada's, and bada's updates come downstream (see [Staying a fork](docs/linux.md#staying-a-fork)). Its
Windows sibling is [pado ime](https://github.com/team-mirae/pado-ime).

The name is the same idea: bada (바다) is the sea, and ara (아라) is an old Korean word for it. The layouts keep their
names: **bada plain** (16, the default), **bada roman** (15) and **bada** (13).

### Why this was built

Multilingual typing is an afterthought in most IMEs. Even JIS, which has keys dedicated to language
actions, does not take into account that the user may want to type a language other than English or
Japanese.

In bada, and so in ara, multilingual typing is why the IME exists at all.

There are two modes: **muhenkan** and **henkan**, as on Japanese keyboards. Henkan mode, entered with
**変換**, types every candidate layout you've set up at the same time, ranks the readings and shows you
the candidates.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/layouts/qwerty-bada-plain-kana-dark.png">
  <img src="docs/images/layouts/qwerty-bada-plain-kana-light.png" alt="QWERTY, bada plain and kana on one HHKB JIS keyboard">
</picture>

QWERTY (0), bada plain (16) and Japanese Kana (20) all typed in henkan mode: `3`, `u`, `q` give
`3uq` (QWERTY), `｢졔` (bada plain) and `あなた` (kana) at the same time, ranked. Only the Japanese is a
legible phrase, so it ranks first.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/layouts/qwerty-bada-roman-kana-dark.png">
  <img src="docs/images/layouts/qwerty-bada-roman-kana-light.png" alt="QWERTY, bada roman and kana on one HHKB JIS keyboard">
</picture>

QWERTY (0), bada roman (15) and Japanese Kana (20): `g`, `w`, `i`, `h`, `a` give `gwiha` (QWERTY),
`귀하` (bada roman) and `きてにくた` (kana). Korean makes the most sense, so it ranks first.

[**Try bada in a browser**](https://bada.sjun.me/): the same engine.

### bada plain

bada plain (16) was designed so that your wrists never have to move: all movement is your fingers, up
and down or left and right. That means less strain and, once you're fluent, less fatigue. It's the
default henkan layout.

### bada roman

bada roman (15) types Korean with roman letters. It started as a joke and turned out surprisingly good.
If you type mostly in English and only sometimes in Korean, it's a very good setup. It leaves your
2-set (KTS) muscle memory alone: you learn which letters map to which jamo, not new key positions.

### bada

Initial layout which started this project. It had the same goal as bada plain, but it proved
to be less than ideal during extended sessions. Thus, it was redesigned completely into
bada plain. The old layout is kept in this repository, but is no longer the default.

### How to install

From source, with Rust (1.85+), CMake and Fcitx5 (or IBus). On Arch Linux:

```sh
sudo pacman -S --needed rust cmake fcitx5 fcitx5-qt fcitx5-gtk fcitx5-configtool python-dbus
git clone https://github.com/team-mirae/ara-ime && cd ara-ime
linux/build.sh
linux/install.sh
fcitx5 -r
```

Then add **ara ime** in Fcitx5's configuration, after the Japanese keyboard layout, and take
`Zenkaku_Hankaku`, `Hangul` and `Hangul_Hanja` out of Fcitx5's hotkeys. On KDE Plasma (Wayland), pick
Fcitx 5 in System Settings → Keyboard → Virtual Keyboard first. Other distributions, IBus and the
details: [docs/linux.md](docs/linux.md#install).

### How to type

| Key | |
|---|---|
| **変換** | Henkan mode. The best candidate shows as you type; **Space** commits it |
| **Tab**, **↓**, **変換** | The next candidate. **⇧Tab**, **↑**, **⇧変換**: back |
| **⇧Enter** | Commits what shows, and nothing else |
| **Esc** | Commits too. It doesn't cancel, unlike most IMEs |
| **無変換** | Muhenkan mode: plain QWERTY |
| **カタカナ/ひらがな** | Henkan in its own profile |

The input method indicator shows **아** in henkan and **A** in muhenkan.

### Henkan profiles

One henkan is not always enough. **変換**, **カタカナ** and an Apple keyboard's **かな** can each have
their own set of layouts, in `~/.config/bada-linux/bada-ara.json` ([docs/linux.md](docs/linux.md#settings)):

| Key | Layouts |
|---|---|
| 変換 | QWERTY + bada roman |
| カタカナ | QWERTY + Japanese Kana |
| かな (Apple) | Symbols + Unicode |

### Your dictionary

ara ranks candidates by how common the words are, and your own words may not be. Put them in
`~/.local/share/bada-linux/bada-ara/dictionary.json`, with the words you never mean, and restart Fcitx5.
The format: [docs/dictionary-contract.md](docs/dictionary-contract.md).

### Learn Korean

[learn.sjun.me](https://learn.sjun.me) teaches you to type Korean by typing: bada roman, 2-set or bada,
from the first lesson. Same engine.

### Layouts

| Id | Layout | |
|---|---|---|
| 0 | QWERTY | muhenkan, and English in henkan |
| 10 | Korean (2-set) | KTS, the standard Korean keyboard |
| 13 | Korean (bada) | [docs/layouts/13-bada.md](docs/layouts/13-bada.md) |
| 15 | Korean (bada roman) | [docs/layouts/15-bada-roman.md](docs/layouts/15-bada-roman.md) |
| 16 | Korean (bada plain) | [docs/layouts/16-bada-plain.md](docs/layouts/16-bada-plain.md), the default |
| 20 | Japanese (Kana) | JIS kana, with kanji conversion |
| 21 | Japanese (Romaji) | romaji, with kanji conversion |

### Layouts (other)

| Id | Layout | |
|---|---|---|
| 11 | Korean (legacy-korean) | from JIS Korean |
| 12 | Korean (legacy-moonshot) | from JIS Moonshot |
| 14 | Korean (3-set JIS) | 세벌식 for JIS, 모아쓰기 |
| 18 | Korean (Roman) | Korean in romanization |
| 19 | Korean (Kana) | Korean in kana |
| 150 | Symbols | symbols and emoji by name |
| 151 | Unicode | any character by its Unicode name |

Every layout and its rules: [docs/layouts](docs/layouts/README.md). bada's spec: [docs/spec.md](docs/spec.md);
what differs on Linux: [docs/linux.md](docs/linux.md).

### For developers

| Path | What |
|---|---|
| `engine/` | bada's core, in Rust. All behaviour lives here. `cargo test` |
| `linux/host/` | [bada-linux](https://github.com/team-mirae/bada-linux), the Fcitx5 and IBus host (a subtree) |
| `linux/ara/` | ara's manifest and the engine as `libara_engine.so` |
| `linux/*.sh` | Build, install, and the end-to-end test through Fcitx5 |
| `web/` | [bada.sjun.me](https://bada.sjun.me): the engine in WebAssembly |
| `docs/` | bada's spec, the layouts and their history; [linux.md](docs/linux.md) |
| `tools/`, `utils/` | Analysis, the layout renderer, the learner app |

### License

MIT © Mirae Research. `linux/host` (bada-linux) is CC0. The data's licenses: `engine/data/LICENSE-*`.
