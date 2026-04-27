# Element Collision Granularity Verdict

## What the runtime really does

In this checkout, the active placed-element collision pipeline is strictly grid-based.

### Data model

- [`ElementCollisionProfile.cells`](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.dart) is a `List<GridPos>`
- [`GridPos`](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/geometry.dart) is just:
  - `int x`
  - `int y`

There is no sub-tile coordinate in the runtime collision profile.

### Gameplay consumption

In [`GameplayWorldState.isBlocked(...)`](/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_world_state.dart#L269) and the collision-cache builder in the same file:

- each local `GridPos` is offset by the placed element world position
- that world cell is marked in a `List<bool>` cache
- blocking queries are `isBlocked(int x, int y)`

So the runtime collision representation is:

- whole-cell only
- integer grid only
- boolean blocked / not blocked

### What does **not** exist in this checkout

No sub-tile gameplay collision was found.

No continuous polygon collision was found.

No pixel-perfect runtime collision was found.

No placed-element runtime path consumes anything finer than `GridPos`.

---

## Real source size for the user case

For the real element `petite_maison_toit_bleu` in:

- [`/Users/karim/Desktop/my_new_project/project.json`](/Users/karim/Desktop/my_new_project/project.json)

the source frame is:

- `width = 6`
- `height = 7`

So the collision runtime resolution is not even `7x7`; it is `6x7`.

That means there are only **42 possible collision cells** for the whole building.

---

## Why the roof still looks blocky

Even if the author draws a visually nice roof polygon, the runtime cannot block “part of a cell”.

If a polygon converts to:

```text
GridPos(1,0) GridPos(2,0) GridPos(3,0) GridPos(4,0)
GridPos(1,1) GridPos(2,1) GridPos(3,1) GridPos(4,1)
GridPos(1,2) GridPos(2,2) GridPos(3,2) GridPos(4,2)
```

then gameplay blocks those **12 entire world cells**.

It cannot preserve the sloped roof edge inside those cells, because that information does not exist in the runtime contract.

---

## Rasterizer verdict

The remaining issue is **not primarily a broken runtime implementation**.

The rasterizer may still be tunable, but the current behavior is structurally constrained by the runtime lattice.

For a roof-like polygon on a `6x7` source, the rasterizer resolves to a coarse block of cells. That is coherent with the current backend contract:

- author polygon -> `GridPos`
- gameplay -> whole blocked cells

So the main remaining limitation is:

- **the runtime granularity is too coarse for fine roof silhouettes**

---

## Tests added

### Rasterizer

- [`element_collision_shape_rasterizer_service_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_shape_rasterizer_service_test.dart)

Added:

- `roof-like polygon on a 6x7 source resolves to a coarse top block`

This proves the shape is converted into a discrete set of whole cells.

### Gameplay

- [`placed_elements_collision_test.dart`](/Users/karim/Project/pokemonProject/packages/map_gameplay/test/placed_elements_collision_test.dart)

Added:

- `one GridPos blocks one full world cell and nothing sub-tile exists`
- `roof-like coarse cell set blocks the exact whole world cells it names`

These prove:

- one selected cell means one whole runtime cell blocked
- the runtime does not preserve polygon edges beyond the chosen `GridPos`

---

## Verdict

**The system current in this checkout cannot do what the user wants at this granularity.**

More precisely:

- the rasterizer can be coherent
- the preview can be nicer
- but once converted to `GridPos` on a `6x7` lattice, the runtime can only block whole cells

So the honest conclusion is:

**“Le système actuel ne peut pas faire ce que veut l’utilisateur à cette granularité ; il faut accepter des collisions grossières.”**

And if the product requirement is truly:

- fine sloped-roof collision
- without gross whole-cell blocking

then the stronger conclusion is:

**“Le système actuel ne peut pas faire ce que veut l’utilisateur ; il faut changer le contrat runtime pour supporter une granularité plus fine.”**

---

## Minimal realistic correction

Without changing the runtime contract, the only realistic correction is:

- accept the grid limitation explicitly
- use the rasterizer only to get the least-bad cell selection
- guide authors toward low-resolution plausible shapes
- avoid promising roof-precise collisions in the UI

If the product really wants fine silhouettes, then the runtime contract must evolve beyond `List<GridPos>`.
