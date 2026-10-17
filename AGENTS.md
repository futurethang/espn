# Project rules

- Engine: Godot 4.7, GDScript only, statically typed (var x: int).
- Never use Godot 3 syntax: no yield (use await), no export keyword
  (use @export), no onready (use @onready), no TileMap (use TileMapLayer),
  no move_and_slide(velocity) (set velocity, then call move_and_slide()).
- Connect signals with signal_name.connect(callable).
- One scene per folder under scenes/, its script beside it.
- Game data lives in custom Resources (.tres) under data/, never hardcoded.
- Grid logic works in tile coordinates (Vector2i); convert to pixels only for display.
- All randomness goes through a seeded RandomNumberGenerator.
- Prefer small scripts with one job. Explain new Godot concepts in comments.

## Working agreement

This project is built one stage at a time, following `docs/course.md`. Every
stage ends playable. If a stage drags, cut scope, not the stage.

- **AI writes:** GDScript, Resource classes, generation algorithms, UI logic,
  shaders, and `.tscn` scaffolds when work happens away from the editor.
- **Kevin does:** scene layout, tile painting, art, palettes, tuning numbers,
  deciding what feels good.
- Scenes authored by AI are a starting point, not a finished layout. Rearranging
  them in the editor is expected.
- Commit with the stage number in the message (`Stage 3: ...`).

## Verification

Before claiming a change works, run `./check.sh`. It imports the project
headlessly (catching parse errors, broken resource paths and malformed scenes)
and runs the unit tests. A change that has not passed it is not done.

Tests live in `tests/unit/test_*.gd` and extend `TestBase`. Test the things
that are invisible by eye: grid math, seeded determinism, recipe matching,
generation validity. Do not write tests that assert on how something looks.

## Art pipeline

Final art comes from Adobe Firefly Graph, exported as PNG atlases plus a
palette (Stage 5). Until then, placeholder art is generated from the same
locked palette by a script under `tools/`, so swapping in real art is a file
replacement, not a code change. Two rules keep this smooth: the graph exports
data and images, never Godot scenes, and one command re-exports everything.
