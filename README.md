# Potion Forager

A cozy, turn-based roguelite. Leave a handmade home, forage freshly generated
realms for potion ingredients, outwit their critters, and return home to brew.

Built one stage at a time, following [`docs/course.md`](docs/course.md). Every
stage ends playable.

## Requirements

- **Godot 4.7 stable**, standard build (not .NET). The version is pinned — the
  Compatibility renderer and the `.tscn` format version both depend on it.

## Running

Open `project.godot` in Godot 4.7 and press Play.

## Verifying without the editor

```sh
./check.sh                              # import the project + run unit tests
./shoot.sh                              # main scene -> shots/main.png
./shoot.sh scenes/x/x.tscn shots/x.png  # any scene
INPUT=right,right,down ./shoot.sh       # walk the hero first, then shoot
INPUT=down SHOT_DELAY=0.05 ./shoot.sh   # catch a short animation mid-flight
```

`check.sh` imports headlessly, which surfaces GDScript parse errors, broken
resource paths and malformed scenes, then runs `tests/unit/`. `shoot.sh`
runs the real game and captures from inside it, through the Compatibility
renderer on a software rasteriser inside a virtual X server — no desktop or
GPU needed, and the frame goes through the project's own stretch settings and
camera. `INPUT=` plays movement actions through the real input pipeline before
the shot, so behaviour that only exists in response to a keypress can still be
checked. Both work in a container, which is what makes remote sessions on this
project trustworthy.

Set `GODOT=/path/to/godot` if the binary is not on your `PATH`.

## Regenerating placeholders

```sh
python3 tools/make_placeholder_art.py   # atlas + hero from data/palette.json
python3 tools/make_home_tileset.py      # data/tilesets/home.tres
python3 tools/seed_home_layout.py       # a first pass at scenes/main/main.tscn
```

The first two are the pipeline Stage 5 replaces with Firefly Graph exports.
`seed_home_layout.py` is a bootstrap only — once home is painted in the
editor, delete it rather than running it over hand-painted work.

## Playing it in a browser

```sh
tools/export_web.sh    # build/web/
tools/deploy_web.sh    # force-push it to the gh-pages branch
```

Pushing to `master` does this automatically (`.github/workflows/deploy-web.yml`),
after `check.sh` passes — a red build never reaches the page. The scripts above
are for deploying without waiting for CI.

The export has thread support off on purpose: a threaded Godot web build
needs SharedArrayBuffer, which needs cross-origin isolation headers, which
GitHub Pages cannot send. Export templates are a separate download — see the
comment at the top of `tools/export_web.sh`.

On touch devices an on-screen pad appears (`scenes/touch_controls/`). It is
an input layer only: it synthesises the same actions a keyboard sends, so
nothing downstream knows touch exists. Hold the phone landscape — the web
build scales fractionally to fill the screen, where desktop keeps crisp
integer scaling.

## Layout

```
scenes/    one folder per scene, script beside it
data/      .tres Resources: items, recipes, biomes
art/       sprites, tilesets, palettes
systems/   autoloads and shared logic (turns, RNG, save)
tools/     editor scripts, import helpers, the test runner
tests/     unit tests, run by check.sh
docs/      the course this project follows
```

[`AGENTS.md`](AGENTS.md) holds the rules every AI session on this project
follows. Point each new session at it.
[`docs/composability.md`](docs/composability.md) describes the seams that keep
placeholder assets swappable — read it before adding a system.

## Progress

- [x] **Stage 0** — Workshop setup
- [x] **Stage 1** — A character on the grid
- [~] **Stage 2** — Paint the home — tileset, layers, walkable data and
  y-sorting are in; terrain autotiling and the actual composition of home
  (cottage, garden) are editor work
- [~] **Stage 3** — Things that do things — props, interaction and bump
  feedback are in; items, inventory and brewing are not
- [ ] **Stage 4** — Turns, inventory and brewing
