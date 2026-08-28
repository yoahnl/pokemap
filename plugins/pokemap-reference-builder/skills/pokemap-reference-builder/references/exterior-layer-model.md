# Exterior layer model

## Coordinate contract

- Origin is the top-left map cell.
- `x` increases to the right and `y` increases downward.
- Every map and asset cell is 32 px.
- Geometry must remain inside `[0, widthCells)` and `[0, heightCells)`.
- A placement origin is the top-left cell of its footprint.
- An asset anchor is expressed in local cells inside its footprint.

## Families

### Surface

Large natural masses: base ground, meadow, forest coverage, sand, snow, or other area semantics. Forest is a surface-level intent even when Environment Studio produces individual tree placements.

### Network

Connected topology: roads, paths, rivers, stairs, rails, bridges, and junctions. Preserve centerlines, widths, endpoints, crossings, and connections before choosing tiles.

For a river, set `constraints.waterBodyType` to `river`. Bind only a river preset or material whose live catalog and source provenance confirm river water and banks.

### Border

An explicit edge system such as a fence, wall, cliff line, or approved decorative border. A layer cannot advance beyond `proposed` without `constraints.explicitApproval: true`.

Do not use this family merely because a surface or network needs a visual edge. Prefer the canonical surface or Smart Tile transition when it owns that edge.

### Structure

Buildings, gates, shrines, torii, bridges, monuments, platforms, and other authored multi-cell objects. Record footprint, entrance cell, occlusion expectations, and anchor.

### Decoration

Trees, bushes, rocks, flowers, lamps, signs, mailboxes, stumps, and small props. Decorations must not repair incorrect surface or network geometry.

### Navigation

Collision, traversal zones, entrances, exits, connections, and behaviors. Navigation follows the accepted visual layout and must not be used to disguise a wrong footprint.

## Statuses

- `proposed`: decoded from the reference but not approved.
- `approved`: geometry and binding choice accepted for mutation.
- `applied`: canonical PokeMap receipt confirms the mutation.
- `verified`: validation, render, and required human review passed.

Approved and later layers require at least one concrete binding. Resource IDs must come from the current PokeMap catalog.

## Geometry forms

- `cells`: explicit cell set for masks and painted regions.
- `polygon`: closed area outline, later rasterized or masked.
- `polyline`: ordered network centerline.
- `placement`: origin and footprint for one structure or prop.
- `connection`: endpoint pair and traversal metadata.

Prefer the smallest semantic geometry that preserves intent. Do not expand every polygon into thousands of cells during visual decoding if the target action accepts a mask or area.
