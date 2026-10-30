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

## Where the ground comes from

A cell shows ground only if a visible Smart Tile layer paints it (and no Border masks it), or
a Border with `replacesGround` draws it, or a Smart Tile model replaces it. Imported maps often
leave the cells under a shore or a cliff **unpainted** because the Border draws them. Deleting
or retracing that Border then leaves a hole you can see through. A placed object (an islet
rock, a pier, stairs) over an unpainted cell hides the hole only where its mesh happens to be:
its bounding box proves nothing.

## Iron laws

- Never set or keep `spatialOffsetWorld.y` to raise or lower a face. An offset only matches
  where the low side happens to be flat; it drifts everywhere else.
- Never judge a 3D map from `pokemap_render`: it draws no GLB, terrain surface or Border face.
  Use `pokemap_render_3d`.
- Never edit map JSON or save a whole map to move a contour. Use the canonical actions.
- Never republish a shared profile to fix one map. Check who uses it first.
- Never report done while a touched feature is `stale`, has errors, or has an unexplained
  warning.
- Never delete or retrace a Border, or erase paint, without first giving its cells their own
  ground. Paint the sea or the floor first, then remove the Border.

## Workflow

### 1. Inspect before touching

`pokemap_query` `resourceKind: borderFeature`, `operation: list`, `filters: {mapId}`. For each
item, read `status`, `materialization` (`fresh` / `stale` / `missing`), `errorCount` and
`warningCount`. Then use `get`, `view: detail` on the suspicious ids for the diagnostics.

Then `pokemap_query` `resourceKind: spatialMapIntegrity`, `operation: get`, `ids: [mapId]`,
`view: detail`. `groundGaps` are enclosed cells whose ground nothing proves: `exposed` cells are
holes for certain, `unproven` cells are hidden only by an object's bounds or a partial Border
cover. `borderObjectOverlaps` lists placed objects whose bounds cross Border modules. Keep the
counts as the baseline.

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
  one-cell jog is profile-dependent: inspect the real resolver diagnostics before changing
  the terrain. It is not a universal reason to reject a contour.
- Ask the owner when either could be the intent. Say which cells disagree.

### 4. Check the profile's side before tracing with it

Trace a short test stroke in an empty area, materialize it, render it in 3D. The face must
hang on the lower side. Publication now refuses `border.spatial.face_on_land_side` when the
declared ground footprints are on the land side, and warns
`border.spatial.face_mass_on_land_side` from model bounds alone.

On a **catalog** project, a published spatial profile cannot get a new revision. Publish a
separate corrected profile, then use targeted `border_layer.relink_apply` or
`border_layer.feature_set_blueprint`. A handedness conversion requires explicit
`reverseStrokes: true` and `clearVerticalOffset: true` in the same plan. Supply
`replacementPrimitiveIdsBySlot` for every replacement override; suppression and variation
stay attached to their stable slots. Locked or transformed corrections that cannot be
preserved are refused. Never delete and recreate a feature to bypass a refused conversion.
Open two-phase strokes retain their visual alternation after reversal. Simulate the change
and compare models, positions and rotations beyond the repaired area before applying it.

### 5. Plan with the right revision

For admitted edits of one existing map, discover `map3d.edit_batch` then use
`pokemap_map_edit` with a retained logical `operationId`. Its intentions include
`intent.ground.fill`, `intent.border.remove_keeping_ground`,
`intent.border.trace_step` and `intent.border.clear_over_object`. Read their exact schemas;
the step intent needs explicit lower/upper heights, profile and optional region. It uses
effective heights and the real profile resolver, and refuses unsupported ramps/ambiguity.
It does not decide whether an absent step should be created in the terrain.

Use `dryRun` to inspect concrete expanded operations when the provenance is uncertain.
Choose explicit material/layer IDs on ambiguity. Removing a Border must preserve its real
ground contribution even along a map edge; the interior-hole detector alone cannot prove
that. Clearing object overlaps can remove ground too: inspect the final guards and render.
The default batch reports new warnings; an applied edit is not a healthy-map certificate.
Run `pokemap_map_check` and examine any `fail` or `incomplete`, then review the affected views.

After a lost response, reuse the same operation identity and semantic content. Follow the
recovery rules in `using-pokemap-mcp`; never obtain a second application by changing its ID.
New intentions after undo require new IDs. The advanced workflow below remains applicable
to creation and actions outside the batch.

On a catalog project, call `pokemap_workshop` with `operation: read`, the **same** `actionId`
and `parameters` you are about to plan. Pass its `snapshotRevision` as `expectedRevision` and
its `planExtensions` as `extensions` to `pokemap_plan`. A revision taken from another action
or from a query is rejected as `plan.stale`. Re-read it after every apply.

### 6. Read every preview before applying

Every map action on a 3D map adds `groundGapsIntroduced` (with `groundGapsIntroducedCount`)
when it opens or worsens a ground gap, and `borderObjectOverlapsIntroduced` when it makes a
Border module cross an object. Either key means the plan breaks the map: do not apply it.
Plan the deletion first if you need to know which cells a Border provides, then paint them.

### 7. Materialize and read the warnings before applying

Stroke, offset, move and override edits change the geometry only: the feature becomes
`stale`. Rematerialize every touched feature with `border_layer.materialize_batch_apply`. Its
plan preview lists `warningCount` and `warnings`, with the slot, cell and heights. Read them
**before** applying; a warning on the edited segment means the fix is wrong.

### 8. Prove it on the whole map

- `borderFeature` list again: every touched feature `fresh`, `errorCount: 0`, and each
  remaining warning explained in the report (code, cell, why it is acceptable).
- `spatialMapIntegrity` again: no `exposed` cell, and no more `unproven` cells or overlaps
  than the baseline.
- `pokemap_render_3d_scan` on the map, `grid` left on: it frames every gap cluster and
  overlap, then tiles the whole map including unpainted areas, and measures `holeRatio`, the share of
  background the scene encloses. Every view must read `0`; a `backgroundRatio` alone is the
  map's outer void. The grid expands coverage beyond the integrity report, including
  unbridged height steps. Openings connected to an image edge escape `holeRatio`; inspect
  the views before concluding that a hole joined to the map margin is absent.
  Look at each overlap image yourself: a shore drawn across a pier deck is not a hole but is
  still a defect.
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
- "This shore looks spurious, deleting it is harmless."
- "The diagnostics are green, so the map is fine."
- "The rock sits on these cells, so they are covered."
