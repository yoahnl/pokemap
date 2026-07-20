# Selbrume organic two-tier cliff V3 — generation record

## Status

Project-owned generated raster sources. The full-map render and `cliff.png`
are reference-only and are not shipped as map underlays.

## References

- `/Users/karim/Desktop/cliff.png`: stone anatomy and overlap reference.
- `/Users/karim/Desktop/assets/Selbrume/chatGPT/map/2_map_bourg_selbrume/map_bourg_selbrume.png`:
  in-map palette, scale and finish reference.

## Selected raw sheets

### Top lip stones

File: `raw/top_lip_stones_6x4.png`

SHA-256: `d5e870335af311b8e068e5dd8c687bd92b25d1a4b8669872814ddf725e2f7073`

Prompt intent: preserve a regular 6×4 contact-sheet layout on a perfectly
uniform `#FF00FF` background; create exactly one low-profile, asymmetrical
top-lip stone per cell; keep each stone 1.6–2.2 times wider than its visible
height; remove attached pebbles, cubes, thick slabs, wall segments, vegetation,
water, shadows, text and borders; match the reference’s upper-left light and
muted grey-taupe limestone palette.

### Cliff face stones

File: `raw/face_stones_6x4.png`

SHA-256: `7008d965c842c2a6254e6970b4b6a9fdc0a8b4987e5148597f15e814cec02ebc`

Prompt intent: preserve a regular 6×4 contact-sheet layout on uniform
`#FF00FF`; create exactly one indivisible vertical face stone per cell with
an uneven shoulder, faceted darker front, asymmetrical sides and tapered
bottom; explicitly reject multi-rock clusters, masonry strips, uniform posts,
vegetation, water, shadows, text and borders.

### Corner exploration

File: `raw/corner_assemblies_4x4.png`

SHA-256: `0371807bafd1dec4527b5601ef8e0187891af13efa3bc507a9255e694982efb0`

Prompt intent: 4×4 sheet of convex/concave top and face corner assemblies,
ordered by NW/NE/SE/SW quadrant, using 2–3 interlocked stones rather than
L-shaped slabs. This sheet remains exploratory until the straight-stone
prototype proves whether dedicated corner roles are necessary.

## Rejected generations

- The first top sheet was rejected because the rocks remained cube-like and
  too thick.
- The first face sheet was rejected because each cell contained a preassembled
  cluster instead of one atomic stone.

## Collision intent

Visual only. These assets do not author or modify collision data.
