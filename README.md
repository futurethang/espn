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

## Progress

- [x] **Stage 0** — Workshop setup
- [x] **Stage 1** — A character on the grid
- [ ] **Stage 2** — Paint the home
