# Potion Forager: A Godot Course

Oct 15, 2026 · @Kevin Hyde

## Vision

A cozy, turn-based roguelite: you leave a handmade home, forage freshly generated realms for potion ingredients, outwit their critters, and return home to brew. One home, 3 to 5 realms, built over 15 stages that each end playable.

**The core loop**

1. Pick a potion recipe at home and step through a portal.
2. Explore a realm generated fresh for this run.
3. Forage ingredients, avoid or fight critters.
4. Return home with your haul before you run out of turns (or health).
5. Brew. New potions unlock new realms or make the next trip easier.

**Design pillars**

- **Home is the source.** The home realm is hand-built, and it defines the tile vocabulary, object types and palette rules that every generated realm reuses.
- **Fresh but authored.** Every run's map is new, but every piece of it traces back to rules and art you made. Variation lives inside tight constraints.
- **Small and always finished.** Every stage ends with something you can play. If a stage drags, cut scope, not the stage.

**Scope guardrails**

- No dialogue trees, quests or story beyond flavor text.
- Turn-based on a grid. No real-time physics.
- One playable character, a single save slot.
- 3 realms is done. 5 is a stretch goal.

**Tech choices**

- [Godot](https://godotengine.org/blog/release) 4.7, the current stable line. Pin the exact version for the whole project.
- GDScript, top-down 2D, a fixed pixel grid, git from day one.

&#91;embedded content: course map · 4 acts, 16 stages, 4 playable milestones\]

Each diamond is a playable milestone. Stage 6 is the hinge: it turns the hand-built home into the kit every generated realm draws from.

## How to use this course

Every stage has the same shape, so you always know what "done" means before you start: a goal, what you build, the one key lesson, the Godot concepts it introduces, deep-dive seeds, and a done-when check.

**Working rhythm for a stage**

1. Read the stage primer, then ask the AI to explain the key concepts *before* it writes code. This is where the learning happens.
2. Have the AI write scripts; you assemble scenes in the editor. Scripts are where AI is strong; the editor is where you build intuition.
3. Play it. Note what feels wrong in plain words ("movement feels floaty") and let the AI translate that into fixes.
4. Commit to git with the stage number in the message. Each stage is a safe point to roll back to.
5. Write two or three lines in a stage log: what you learned, what surprised you.

**Split of labor**

- **AI writes:** GDScript, Resource classes, generation algorithms, UI logic, shaders.
- **You do:** scene layout, tile painting, art, palettes, tuning numbers, deciding what feels good.
- **Together:** debugging. Paste the error from Godot's Output panel along with the script.

**The AI rules file**

Put this in `AGENTS.md` (or `CLAUDE.md`) at the project root and point every AI session at it. The biggest risk with AI-written Godot is Godot 3 syntax sneaking in, so the rules call it out directly.

```markdown
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
```

Update the file whenever the AI makes the same mistake twice.

## Stage 0: Workshop setup

**Goal:** a blank project that opens, runs, and is wired for AI-assisted work. About one evening.

**You build**

- Godot 4.7, standard build (not .NET), new project on the **Compatibility** renderer. It's the lightest renderer for 2D and the one web export uses.
- Pixel-art settings: default texture filter set to Nearest; stretch mode `canvas_items` with integer scaling; a base resolution like 480×270 that scales cleanly to 1080p.
- VS Code with the Godot extension as the external script editor, so the AI and you edit the same files.
- A git repo, a Godot-specific `.gitignore` (ignore `.godot/`), and the rules file from above.
- This folder layout:

```
scenes/      one folder per scene, script beside it
data/        .tres Resources: items, recipes, biomes
art/         sprites, tilesets, palettes (exports from your graph tools)
systems/     autoloads and shared logic (turns, RNG, save)
tools/       editor scripts and import helpers
```

**Key lesson:** Godot projects are mostly text. Scripts (`.gd`), scenes (`.tscn`) and resources (`.tres`) are all readable files. That's why AI can work here, and why git diffs stay meaningful.

**Godot concepts:** project settings, the FileSystem dock, the editor/runtime split, renderers.

**Deep-dive seeds**

- Open a `.tscn` file in a text editor and compare it to what the editor shows.
- Running Godot from the command line, so an AI agent can launch the project and read the errors itself.
- Community MCP servers that let an AI agent inspect a running Godot editor. Evaluate before adopting; the plain-files workflow is enough to start.

**Done when:** pressing Play opens a window with a solid background color at the right scale, and the first commit is pushed.

## Act I: The home realm

Act I builds home by hand, then turns it into the kit every generated realm is made from. By the end you have a cozy, playable home where you can brew one potion, plus a biome definition that describes it.

### Stage 1: A character on the grid

**Goal:** a placeholder hero who steps tile by tile across an empty field, with a camera that follows.

**You build:** a Player scene (a node with a sprite), one-tile-per-press movement on the arrow keys or WASD, a short tween so each step glides instead of teleports, and a Camera2D with light smoothing.

**Key lesson:** in Godot everything is a tree of nodes, and a scene is a reusable component. If you know web components, this will feel familiar: a scene is a custom element, its child nodes are its shadow tree, and instancing is like dropping the tag on a page.

**Godot concepts:** Node, Scene, instancing, `_ready` and `_unhandled_input`, the Input Map, Tween, Camera2D.

**Deep-dive seeds**

- Tile coordinates vs pixel coordinates, and why the game logic should only know tiles.
- Input buffering: queue a key pressed mid-step so movement never feels sticky.
- Why grid games often skip physics bodies (CharacterBody2D) entirely.

**Done when:** you can walk around, the camera follows, and movement feels crisp.

### Stage 2: Paint the home

**Goal:** a small hand-painted clearing with a cottage, a garden, a path and trees, where walls and trees block movement.

**You build:** a TileSet from placeholder art (Kenney's packs are fine), three TileMapLayers (ground, obstacles, decor), a custom data layer called `walkable` that the player checks before moving, terrain sets so grass and path edges autotile, and y-sorting so the hero walks behind tree canopies.

**Key lesson:** tiles are data, not just pictures. Custom data layers turn art into rules, and the generators in Act II will read exactly these rules.

**Godot concepts:** TileSet, atlas sources, TileMapLayer, terrains, custom data layers, `y_sort_enabled`, `local_to_map` and `map_to_local`.

**Deep-dive seeds**

- Autotiling: how terrain sets pick edge tiles (the "47-tile blob" idea).
- Why ground, obstacles and decor live on separate layers.
- Small-space composition: framing, paths that lead the eye, a focal point.

**Done when:** home feels like a place, collisions are right, and the hero tucks behind the trees.

### Stage 3: Things that do things

**Goal:** home objects you bump into to use: a storage chest, a garden plot, a cauldron, a portal stone.

**You build:** an `ItemData` Resource (name, icon, tags like `herb` or `glowing`), a `RecipeData` Resource, an interactable component you can add to any object scene, and signals like `interacted` and `item_added`.

**Key lesson:** keep data (Resources) separate from behavior (scenes), and let things talk through signals instead of reaching into each other. That keeps every object swappable, which Act II relies on when a generator places them.

**Godot concepts:** custom Resources with `class_name` and `@export`, `.tres` files, signals, groups, composition through child nodes.

**Deep-dive seeds**

- The shared-Resource gotcha: edit one instance and every instance changes, unless you `duplicate()` it.
- Signals vs direct calls vs an event-bus autoload.
- Item tags vs item types, and why tags make recipes more flexible.

**Done when:** you can harvest a plot, stash herbs in the chest, and the cauldron reacts to what you carry.

### Stage 4: Turns, inventory and brewing

**Goal:** the home loop works end to end. Time passes in turns, you carry items, and you brew your first potion.

**You build:** a TurnManager autoload (the player acts, then the world gets a turn), an inventory model plus a UI that only displays it, a HUD with the turn count, and a brewing panel that matches ingredients against recipes by tags.

**Key lesson:** game state lives in one place, and UI renders it. It's the same model/view split as a reactive store in a web app, which you already know.

**Godot concepts:** autoloads, Control nodes and containers, CanvasLayer for HUDs, Theme resources, `await` for sequencing turns.

**Deep-dive seeds**

- Godot Themes compared to CSS: what maps over and what doesn't.
- Turn scheduling: energy or speed systems for later, when critters move at different rates.
- Recipe matching: exact lists vs tag rules vs a little randomness.

**Done when:** you brew a potion from home-grown ingredients and the HUD stays in sync.

### Stage 5: Art direction and the pipeline

**Goal:** replace placeholders with your own look, produced by a pipeline rather than one-off drawings.

**You build:** a locked tile size (16 px is the forgiving choice), a home palette of 6 to 8 colors, base tiles and sprite parts, exports from your node-graph tools (tile variants, sprite sheets) with consistent names, Godot import presets, and a palette-swap shader you will reuse for every realm.

**Key lesson:** constraints create cohesion. A strict palette and a fixed grid are what keep generated variety from looking like slop. Aim for a pipeline where one export command updates the game, with no manual dragging.

**Godot concepts:** import settings and presets, AtlasTexture, SpriteFrames and AnimatedSprite2D, a simple CanvasItem shader.

**Deep-dive seeds**

- Color ramps and hue shifting; palettes on Lospec for reference.
- Readability: silhouettes, value contrast, and making the hero pop from the ground.
- Two-frame idle animations: the cheapest way to make a world feel alive.

**Done when:** home looks intentional, and re-exporting from your graph tools updates the game in one step.

### Stage 6: Extract the kit

**Goal:** turn everything you hand-built into a vocabulary a generator can use.

**You build**

- **Tile roles:** ground, path, blocker, decor, water, edge. Each tile gets a role, not just a picture.
- **Object archetypes:** forage node, container, hazard, portal.
- **Placement notes:** the rules you followed by instinct, written down. Herbs grow near water; mushrooms sit under trees; paths avoid blockers.
- **A `BiomeData` Resource** holding the palette, tileset, role-to-tile map, spawn tables and generation settings. Home becomes the first biome.

**Key lesson:** design the schema before the generator. A generator is only as good as the vocabulary it draws from, and home is where you earned that vocabulary.

**Godot concepts:** nested Resources, typed arrays and dictionaries, `@tool` scripts that preview in the editor.

**Deep-dive seeds**

- Data-driven design, and how far to push it before it becomes a chore.
- Adjacency rules learned from a sample map, the starting point for Wave Function Collapse.
- Making home itself partly generated: a garden that regrows differently each visit.

**Done when:** `home.tres` exists, and swapping its palette re-skins home without touching code.

## Act II: The first generated realm

Act II feeds the kit from Act I into a generator and closes the core loop. By the end, every trip through the portal lands in a new map, and you bring ingredients home to brew.

### Stage 7: Grow the terrain

**Goal:** a generator that builds a fresh realm layout from a seed, always walkable from entrance to exit.

**You build:** a seeded random number generator that everything shares, noise for broad regions (meadow, water, thicket), cellular automata to carve natural-looking clearings, a flood-fill check that the exit is reachable, and an automatic retry when it isn't. Add an editor button that regenerates the map so you can tune it without pressing Play.

**Key lesson:** generate, then validate. Every generator needs a checker, because random output fails in ways you won't predict. The same seed must always give the same map, or you can't debug anything.

**Godot concepts:** RandomNumberGenerator with a seed, FastNoiseLite, `set_cells_terrain_connect` for autotiled output, grids as arrays of Vector2i, `@tool` previews.

**Deep-dive seeds**

- Noise settings in plain terms: frequency is zoom, octaves are detail.
- Cellular automata: the "4-5 rule" for cave-like shapes.
- Drunkard's walk for organic paths; Wave Function Collapse as the advanced option.
- Your node-graph tools as the parameter UI: tune generation visually, export the settings as data.

**Done when:** pressing a key makes a new map every time, each one passes the walkability check, and a fixed seed reproduces the same map exactly.

### Stage 8: Fill it with life

**Goal:** forage spots, decor and landmarks placed by your rules, so the realm looks composed instead of sprinkled.

**You build:** placement driven by the Stage 6 rules (herbs near water, mushrooms under trees), even spacing with Poisson-disk sampling, weighted picks from the biome's spawn table, a guaranteed minimum of each recipe ingredient, and a distance map from the entrance so rare finds sit deeper in.

**Key lesson:** placement rules beat randomness. Pure random scatter reads as noise. Rules plus a little jitter read as design.

**Godot concepts:** weighted random choice, breadth-first search over the grid, spatial queries on TileMapLayers.

**Deep-dive seeds**

- Dijkstra maps, a roguelike staple that also powers critter AI in Act III.
- Landmarks: small hand-made vignettes (a ring of stones, a fallen log with mushrooms) stamped into generated maps. This is one of the best anti-slop techniques there is.
- Clustering: why things in nature appear in groups.

**Done when:** realms feel composed at a glance, and rare ingredients reliably sit farther from the entrance.

### Stage 9: The run

**Goal:** the full loop works: home, portal, realm, forage, return, brew.

**You build:** a GameState autoload holding run state (seed, turns left, carried items) and meta state (stored items, unlocked recipes), portal transitions with a fade, a return portal in each realm, and a penalty for failing a run, such as dropping half your haul.

**Key lesson:** persistence is a decision. Know what survives a scene change, what survives a run, and what survives quitting the game.

**Godot concepts:** scene switching (`change_scene_to_packed`, or swapping children under a root node), autoload lifetimes, AnimationPlayer for transitions.

**Deep-dive seeds**

- Run state vs meta progression: the core design question of roguelites.
- Daily seeds that everyone shares, and what determinism requires to support them.
- Turn budgets as tension: how many turns makes a trip feel tight but fair?

**Done when:** you can play several loops in a row, each trip lands in a fresh realm, and brewing at home feels like a payoff.

## Act III: Life and danger

Act III adds critters, gives them generated variety, and tunes the loop until a run feels worth repeating.

### Stage 10: Critters and combat

**Goal:** critters that wander, notice you, chase, and flee when hurt, with simple bump combat.

**You build:** a Critter scene plus a `CritterData` Resource, a small state machine (wander, chase, flee), pathfinding on the grid, line of sight, health, and bump-to-attack. Critters show what they'll do next turn with a small intent icon.

**Key lesson:** simple AI feels smart when it's readable. Players forgive dumb enemies; they don't forgive surprising ones.

**Godot concepts:** AStarGrid2D, enum-based state machines, critters taking turns through the TurnManager.

**Deep-dive seeds**

- Dijkstra maps from Stage 8, reused for fleeing and herding.
- Telegraphing: showing intent so every fight becomes a small puzzle.
- Non-combat options: sneaking past, throwing a potion, luring critters into each other.

**Done when:** critters behave believably, you can predict them, and a fight takes a few turns of real decisions.

### Stage 11: Parametric critters

**Goal:** each realm has a family of critters that share a look but vary visibly.

**You build:** critters assembled from parts (body, eyes, ears or antennae, pattern) exported from your node-graph tools, palette swaps per biome, stats derived from parts (a spiky body means more defense), and critter generation driven by the run seed.

**Key lesson:** parametric content is a few parts times a few rules. Constrained parts plus a shared palette give a family; unconstrained parts give a mess.

**Godot concepts:** layered sprites, the palette-swap shader from Stage 5, creating Resources at runtime.

**Deep-dive seeds**

- A critter "genome": a compact description that rebuilds the same creature from a seed.
- Readability limits: which part combinations to forbid.
- Biome traits that carry into critters, like moss on forest creatures or glow in caves.

**Done when:** you can tell which realm a critter comes from at a glance, and no two feel identical.

### Stage 12: Tune the loop

**Goal:** a run takes 5 to 10 minutes, failure feels fair, and you want one more.

**You build:** all items, recipes and critter stats as editable data, debug keys (reveal map, spawn critter, add items), a simple run log written to a file, and potion effects that feed back into runs, such as a lantern potion that reveals more map.

**Key lesson:** tuning is design. When numbers live in data and you can test quickly, you make better decisions by playing than by planning.

**Godot concepts:** debug drawing, custom inspector tools, writing to `user://`.

**Deep-dive seeds**

- Difficulty curves across realms.
- Risk and reward: push deeper for rare ingredients, or head home safe.
- Watching someone else play without helping. It's the fastest way to find problems.

**Done when:** a friend can play a run without instructions and asks to go again.

## Act IV: More worlds and polish

Act IV proves the system scales, makes it feel good, and gets it into other people's hands.

### Stage 13: The second realm

**Goal:** a new realm with its own look, ingredients and critters, added mostly through data.

**You build:** a second `BiomeData` with a new palette, tiles, placement rules and spawn tables, plus at most one new generation trick (water channels, ruins, elevation bands). New recipes that need ingredients from both realms connect them.

**Key lesson:** this is the test of your architecture. If adding a realm is mostly config and art, Acts I to III were built well. If it means rewriting generators, find what was hardcoded and pull it into data before going further.

**Godot concepts:** nothing new, deliberately. This stage is about reuse.

**Deep-dive seeds**

- Realm identity: what makes a place memorable besides its colors (sound, critter behavior, one signature mechanic).
- Unlocks: gating realms behind potions.
- When to stop adding realms. Three good ones beat five thin ones.

**Done when:** the second realm took a fraction of the effort of the first and feels distinct.

### Stage 14: Juice

**Goal:** everything feels good to do, not just correct.

**You build:** squash-and-stretch on steps, hit flashes and small screen shake, particles for foraging and brewing, ambient motion (swaying grass, drifting spores), sound effects for every action, and a music loop per realm.

**Key lesson:** feel comes from feedback. Every action deserves an immediate, proportionate response in motion, light or sound.

**Godot concepts:** Tweens in depth, GPUParticles2D and CPUParticles2D, shaders for wind and glow, AudioStreamPlayer and audio buses, Light2D.

**Deep-dive seeds**

- "Juice it or lose it," the classic talk on game feel.
- Easing curves: why everything should ease.
- Generative ambient audio, an easy win if you make music.

**Done when:** watching a silent recording of a run still looks satisfying, and with sound it's better.

### Stage 15: Save and ship

**Goal:** a build other people can play, with progress that survives quitting.

**You build:** save and load for meta progress, a title screen and settings (volume, key remapping), web and macOS exports, and an itch.io page.

**Key lesson:** shipping is its own skill. Exporting, testing on other machines and writing a store page teach things building never will.

**Godot concepts:** `ConfigFile` and `FileAccess`, export presets, web export limits, versioned save data.

**Deep-dive seeds**

- Save format versioning, so updates don't break old saves.
- Web export gotchas: audio autoplay, file size, threads.
- What to cut to ship. Keep a "later" list so ideas aren't lost.

**Done when:** a friend plays it in a browser from an itch.io link, and their progress is still there tomorrow.

## Appendix

### Where your node-graph tools plug in

| Stage | What the graph produces | Lands in Godot as |
| --- | --- | --- |
| 5 | Tile variants, sprite sheets, palette ramps | PNG atlases with import presets |
| 6 | Placement and adjacency rules | `BiomeData` fields (.tres or JSON) |
| 7 | Noise and generation settings tuned visually | Exported parameters read by the generator |
| 8 | Landmark vignettes, decor scatter sets | Small prefab scenes plus spawn tables |
| 11 | Critter parts and their allowed combinations | Layered sprite parts plus a part list |
| 13 | A whole new biome kit | A second `BiomeData` and its art |

Two rules keep this smooth: the graph exports data and images, never Godot scenes, and one command re-exports everything.

### Anti-slop rules

- One strict palette per realm, 6 to 8 colors. Generated pieces may only use it.
- Every generated piece is assembled from parts you made or chose.
- Rules over randomness: placement follows written rules, with jitter on top.
- Hand-made landmarks in every generated map.
- Readability first: the hero, critters and forage spots must pop from the ground at a glance.
- If something looks off, change the rule that made it, not the single output.

### Glossary

- **Node / Scene:** the building block / a saved, reusable tree of nodes.
- **Resource:** a data object saved as a file (`.tres`), like an item or a biome.
- **Autoload:** a scene or script that's always loaded, used for global state.
- **Signal:** an event a node emits; other nodes connect to it.
- **Seed:** the number that makes random generation repeatable.
- **Juice:** feedback that makes actions feel good.

### Starting points for deep dives

- [Godot docs](https://docs.godotengine.org/en/stable/): the step-by-step 2D tutorials, then the TileMap and Resources pages.
- [Red Blob Games](https://www.redblobgames.com/): the best visual explanations of grids, pathfinding and noise.
- [RogueBasin](https://www.roguebasin.com/): decades of roguelike generation and AI techniques.
- [GDQuest](https://www.gdquest.com/): Godot-specific tutorials and patterns.
- [Lospec](https://lospec.com/palette-list): palettes and pixel-art tutorials.
- [Kenney](https://kenney.nl/assets): free placeholder art for Stages 1 to 4.
