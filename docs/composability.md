# Composability

Everything here is placeholder. The point of the structure is that replacing
the placeholders is a file change, not a rewrite. These are the seams, why
each one exists, and what you can swap across it.

## The rule

**Decisions and appearances never touch each other.** Nothing that decides
something holds a `Sprite2D`, and nothing that draws decides anything. Every
seam below is a consequence of that one rule.

## The layers

```
input ─▶ Player ─▶ GridWalker ─▶ MovementRules ─▶ [ walkability ]
                       │                          [ registry    ]
                       │                          [ …later rules]
                       ▼
                  ActorVisual                     InteractableRegistry ─▶ Prop ─▶ InteractableData
```

### `MovementRules` — why a tile is closed

A list of `Callable(Vector2i) -> bool`. A tile is open only when every rule
agrees. Today there are two: painted tile data, and placed props.

**Swap:** add a reason to be blocked by appending a rule. A closed gate, a
critter standing there, deep water you can cross only after a potion — none
of them edit `GridWalker`, `Player`, or each other.

### `GridWalker` — the stepping rules

Holds a tile, a facing, an input buffer and a blocked-direction latch. Owns
no nodes, so it is testable without running the game, and the same class will
drive critters in Act III.

It decides nothing about what blocking *means*: a refused step emits `bumped`
and the listener chooses whether that is a nudge, a conversation, or a locked
door.

**Swap:** a different actor (a critter) with different rules and a different
visual, same walker.

### `ActorVisual` — how an actor looks and reacts

Four methods and nothing else: `face`, `play_step`, `play_bump`, `play_react`.

**Swap:** point the scene at a different texture for new art; replace the
whole scene for directional sprites, an `AnimatedSprite2D`, or a shader-driven
palette swap. Movement code is unaffected because it only ever calls those
four methods.

### `Prop` + `InteractableData` — things in the world

One scene for every bumpable object. A sign, a berry bush and a boulder
differ only in their `.tres`: name, message, whether it blocks, whether it is
one-shot, and which atlas cell to draw.

**Swap:** new objects are data files. When real art lands, props point at
different cells — no script changes.

### `InteractableRegistry` — what stands where

Tile → object. Feeds both bump-to-interact and the blocking movement rule, so
a prop's solidity and its usability come from the same place and cannot drift
apart.

### `Main` — the only place that knows the parts exist

Composition lives in one `_ready`. The player does not know props exist; a
prop does not know the player exists. Both talk through `Main`.

**Swap:** a generated realm in Act II builds the same wiring from different
sources. That is the test of whether this held up.

## Asset swap checklist

When Firefly Graph art arrives:

1. Replace `art/placeholder/tileset.png` keeping the atlas layout, or change
   the layout and re-run `tools/make_home_tileset.py`.
2. Update `data/palette.json` to the exported palette.
3. Point `InteractableData.atlas_coords` at the new cells.
4. For animated or directional actors, replace `scenes/actor_visual/` with a
   scene exposing the same four methods.

No step in that list touches movement, rules or interaction.

## What is deliberately not abstracted

- **Turn order.** Stage 4 adds a `TurnManager`; the walker takes no view yet.
- **Inventory.** Props return a message, not an item. Stage 3 proper adds
  `ItemData`, and `Prop.interact()` grows a yield.
- **Terrain autotiling.** Editor work, and no amount of indirection helps.
- **Sound.** Nothing yet. `ActorVisual` is where it will hang.
