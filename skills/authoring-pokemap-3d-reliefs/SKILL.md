---
name: authoring-pokemap-3d-reliefs
description: Use when building, repairing or reviewing a 3D PokeMap map whose cliffs, ledges, shores or terraces use spatial Border features and terrain surfaces, especially when faces float above or sink into the ground, corners leave holes, joints look incoherent, or a 2D render looks fine while the 3D map is broken.
---

# Authoring PokeMap 3D Reliefs

## Overview

A 3D relief is two independent truths that must agree: the **terrain support** says how
high the ground is, and the **Border contour** says where the face stands. Every floating
wall, buried face and corner hole seen so far came from these two disagreeing, then being
hidden with an offset. Make them agree; never paper over the gap.

**REQUIRED SUB-SKILL:** `using-pokemap-mcp` for describe/open/plan/apply discipline.

## How the engine places a directed face

- A stroke has a direction. The **land cell is on the right** of travel; the face hangs on
  the left, toward the lower ground. Regions keep their interior on the right.
- The crest is anchored to the land cell's terrain height, plus `spatialOffsetWorld.y`.
- So the contour must sit **exactly on the height step**: land cell high, outside cell low.
  If both sides of the contour have the same height, the contour is on the wrong edge or the
  terrain support is wrong. No profile or offset fixes that.

## Iron laws

- Never set or keep `spatialOffsetWorld.y` to raise or lower a face. An offset only matches
  where the low side happens to be flat; it drifts everywhere else.
- Never judge a 3D map from `pokemap_render`: it draws no GLB, terrain surface or Border face.
  Use `pokemap_render_3d`.
- Never edit map JSON or save a whole map to move a contour. Use the canonical actions.
- Never republish a shared profile to fix one map. Check who uses it first.
- Never report done while a touched feature is `stale`, has errors, or has an unexplained
  warning.

## Workflow

### 1. Inspect before touching

`pokemap_query` `resourceKind: borderFeature`, `operation: list`, `filters: {mapId}`. For each
item, read `status`, `materialization` (`fresh` / `stale` / `missing`), `errorCount` and
`warningCount`. Then use `get`, `view: detail` on the suspicious ids for the diagnostics.

Render the problem area before changing anything: `pokemap_render_3d` with `view: orbit` for
the overview, and `view: game`, `magnification` 3 to 4, `center` on the exact spot. Keep these
images as the "before".

### 2. Diagnose from the diagnostic, not from the picture

| Code | Parameters to read | Usual meaning | Fix |
|---|---|---|---|
| `border.spatial.face_crown_mismatch` | `upperGroundHeight == lowerGroundHeight` | The contour runs on flat ground, one row off the real step | Move the contour onto the step, or correct the terrain support (step 3) |
| `border.spatial.face_crown_mismatch` | `crownHeight` > upper ground | An offset or a wrong-handed profile lifts the crest | Remove the offset; check the profile's side (step 4) |
| `border.spatial.face_base_mismatch` | base above `lowerGroundHeight` | The face floats: there is a hole under it | Fix the step height or pick a taller profile |
| `border.spatial.face_base_mismatch` | base below lower ground on a ramp | A buried skirt | Acceptable when written down; check the render |
| `border.spatial.orientation_missing`, `override_slot_missing` | `slotKey`, `cell` | A replacement or override no longer fits its slot | Re-set or clear that slot override |

Sample both sides before deciding: `landCell` and `outsideCell` are in every face
diagnostic. A one-cell sliver or a simplified polygon in a terrain surface can put the step
one row away from the contour.

### 3. Decide which truth is wrong: terrain or contour

- **The terrain is wrong** when a surface footprint overflows the intended shape (a
  simplified polygon, a thin sliver at a cell centre). Fix it with
  `map3d.terrain.surface.upsert_batch`: at most 32 convex footprints per surface, 3 to 16
  vertices each. This action rematerializes the dependent Borders in the same change; read
  `refreshedBorderFeatures` and `staleBorderFeatures` in the plan preview.
- **The contour is wrong** when the terrain matches the intended relief. Use
  `border_layer.stroke_update` (or `stroke_add`, `stroke_erase`, `region_fill`). A
  one-cell jog in a contour raises `corner_join_conflict`; prefer fixing the terrain then.
- Ask the owner when either could be the intent. Say which cells disagree.

### 4. Check the profile's side before tracing with it

Trace a short test stroke in an empty area, materialize it, render it in 3D. The face must
hang on the lower side. Publication now refuses `border.spatial.face_on_land_side` when the
declared ground footprints are on the land side, and warns
`border.spatial.face_mass_on_land_side` from model bounds alone.

On a **catalog** project, a published spatial profile cannot get a new revision, and
`feature_set_blueprint` / `relink_apply` are refused in 3D. A wrong-handed profile there is a
product gap to report, not something to work around with offsets or by deleting and
recreating features.

### 5. Plan with the right revision

On a catalog project, call `pokemap_workshop` with `operation: read`, the **same** `actionId`
and `parameters` you are about to plan. Pass its `snapshotRevision` as `expectedRevision` and
its `planExtensions` as `extensions` to `pokemap_plan`. A revision taken from another action
or from a query is rejected as `plan.stale`. Re-read it after every apply.

### 6. Materialize and read the warnings before applying

Stroke, offset, move and override edits change the geometry only: the feature becomes
`stale`. Rematerialize every touched feature with `border_layer.materialize_batch_apply`. Its
plan preview lists `warningCount` and `warnings`, with the slot, cell and heights. Read them
**before** applying; a warning on the edited segment means the fix is wrong.

### 7. Prove it

- `borderFeature` list again: every touched feature `fresh`, `errorCount: 0`, and each
  remaining warning explained in the report (code, cell, why it is acceptable).
- `pokemap_render_3d` at the same `center`, `view` and `magnification` as the "before"
  images, plus one `orbit` overview. Compare them yourself: crest flush with the upper
  ground, foot on the lower ground, corners closed, no slit of grass or void.
- Report the changed features and surfaces, warning counts before and after, and the
  render pairs.

## Red flags: stop and re-diagnose

- "Add `y: 1` to the offset, it lines up."
- "The 2D render looks fine, so the cliff is fine."
- "Both sides are at 3.0 but the profile will sort it out."
- "I'll republish the profile, it's faster."
- "The feature says stale but the picture looks right."
- "One more override on that slot will hide the gap."
- "I'll fix the JSON directly, the action is too strict."
