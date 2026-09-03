---
name: pokemap-reference-builder
description: Use when reconstructing an editable exterior PokeMap/Avelune map from a reference, creating correctly sized missing props or buildings, or measuring PSDK object assets as reusable dimensional templates. Map reconstruction supports exteriors; asset measurement also covers interior furniture.
---

# PokeMap Reference Builder

Convert a visual reference into an editable PokeMap composition. The reference guides geometry and visual hierarchy; it is never imported as a runtime background.

## Object measurements and asset templates

For an asset-only inventory or dimensional-template request, use this section without requiring a map ID, a blueprint approval, or a live MCP session. Source PNG/TSX/TMX inspection and catalog creation do not mutate the game project. Exclude floors and terrain when the user asks for props, buildings, furniture, or vegetation.

Look for `assets/meta/patrons_psdk/patrons.json` under the user's asset-library root. Its companion `index.html` is the visual table; `patrons.csv` is the spreadsheet export. If absent or stale, build it from the designated PSDK `Data/Tiled` directory:

```bash
python3 scripts/build_psdk_patron_catalog.py \
  --tiled-root '<sdk>/Data/Tiled' \
  --output '<asset-library>/assets/meta/patrons_psdk'
python3 scripts/build_psdk_patron_catalog.py \
  --output '<asset-library>/assets/meta/patrons_psdk' --check-only
python3 scripts/build_psdk_patron_catalog.py \
  --output '<asset-library>/assets/meta/patrons_psdk' --query 'lampe' --limit 8
python3 scripts/build_psdk_patron_catalog.py \
  --output '<asset-library>/assets/meta/patrons_psdk' --query '' --family architecture --limit 8
```

The measurement scripts require Pillow. Source layouts are declared in `references/psdk-outdoor-patrons.json`, `references/psdk-interior-patrons.json`, and `references/psdk-nature-patrons.json`. Treat them as source-version-specific coordinates, not universal PSDK geometry. Inspect changed source images and update their regions before trusting a rebuilt catalog. `--check-only` checks the hashes of source sheets, rules, definitions, and generators as well as each preview and measurement; rebuild when any input changes. Houses assembled from rules use the generic label `Bâtiment`; the `architecture` filter includes them.

Use a catalog entry's ID and provenance when choosing a template. `canvasPx` and `canvasCells` describe its source or assembled canvas; `artBoundsPx` is the visible art with alpha at least 128; `visibleBoundsPx` also includes translucent shadows. None is a collision footprint. `minimumCanvasCells` is only a bounding-box lower bound, not permission to crop or move a sprite. A `module` entry is a collection or construction piece, not necessarily a complete placeable object.

For buildings and trees, use the composed Tiled-rule entries before raw atlas fragments. The entire `TECH-Buildings.png` sheet is not one building. Roofs, façades, bases, doors, and shadows can live at unrelated atlas coordinates. Reconstruct their relative positions from `regions_input` plus `regions_output` and the rule layers. Building input markers are not artwork; tree and furniture input layers can contain real trunks or bases. Missing source tiles must remain explicit diagnostics, never invented geometry or usable templates.

Keep rule input anchors distinct from ground-contact anchors. Preserve raw passage information without assuming its collision meaning. When using a template for new artwork, choose and review the new asset's ground anchor, collision cells, entrance, and shadow policy separately; the defaults produced by `asset_contract.py init` are proposals, not measurements from the patron.

The catalog preserves source pixel scale and converts only the exact pink/yellow sheet guides to transparency in previews. It does not restyle assets, certify their artistic fit, or export an animation just because one pose and TSX cadence were measured. Before new art, show the chosen source template and its pixel/cell dimensions; then use the missing-asset workshop below. Use the canonical MCP workflow only when importing or modifying the game project.

## Asset creation rules — proportions, alpha, and shadows

Apply these rules to every new or adapted asset, including asset-only work. The selected patron supplies proportions and construction geometry; the user's approved visual reference supplies the palette, texture, architecture, lighting, and detail density. Do not impose the original PSDK colors or building style on new artwork.

- Record the patron ID, exact canvas in pixels and 32 px cells, and the selected visual reference before creating the asset. Preserve pixel scale and silhouette readability. Export a PNG with real RGBA transparency; no opaque background, baked checkerboard, guide colors, or smoothing of the artwork.
- **Trees require a small round ground shadow in alpha at their base.** In top-down perspective it may read as a slightly flattened oval. Center it on the trunk's ground-contact point, place it behind the trunk, and keep it compact beneath the canopy. It must ground the tree without hiding the trunk base or becoming a large dark disk. A different shadow requires an explicit user direction.
- **Props and buildings use a shadow fitted to their ground contact and the approved reference's light direction.** Do not apply the tree's round shadow to every object. For the station platform, preserve the requested south-facing lip and very small shadow on its east side when creating or adapting that family.
- Use a dark tint consistent with the approved palette and genuinely translucent shadow pixels: alpha strictly between 0 and 255, with alpha 0 outside the silhouette/shadow. Match opacity and edge softness to the approved reference; record the chosen opacity instead of inventing a universal value. Keep the artwork itself crisp.
- Inspect an existing PNG before adding a shadow. Keep an existing shadow only if it already satisfies the requested shape, position, and alpha; otherwise replace it. Deliver **one ground shadow per asset**. Do not stack the source shadow, a new painted shadow, and an editor/runtime auto-shadow. Keep the shadow editable separately in the working source; combine it once for a standalone PNG when that is the chosen delivery mode. Do not assume a separate runtime shadow layer exists without checking the product capability.
- Fit the complete asset and shadow inside the declared canvas. Reserve transparent padding before painting; never clip a shadow, stretch the drawing, or silently enlarge its footprint to make it fit. Any needed canvas revision must be made explicit before import. Ground anchor, entrance, and collision are defined from the object, not from its shadow or canopy bounds.
- Review at native size and integer zoom, on transparency and on representative grass and path backgrounds. Confirm one compact shadow, no opaque halo/background, no clipped edge, coherent light, and preserved ground contact. Record shadow shape, position, opacity, and delivery mode in the existing asset metadata or delivery notes; do not invent unsupported contract fields. The current `asset_contract.py validate` checks actual transparency but **does not certify shadow shape, placement, translucency, or double-shadow absence**; inspect these explicitly.

## Required inputs

Obtain or infer:

- the attached reference image;
- the absolute PokeMap project root;
- the target map ID or approval to create one;
- map width and height in 32 px cells.

If map dimensions are not explicit, propose them from the reference and viewport goal, then obtain approval before mutation. This workflow supports exterior maps only.

## Start with capability discovery

Call `pokemap_describe` before opening the project. Require the live catalog to expose the action families needed by the approved blueprint. At minimum, ordinary exterior reconstruction needs Environment, Smart Tiles, placed elements, collisions, rendering, and validation.

Do not translate a missing action into direct JSON edits. Report the MCP parity gap and stop that family. A transport failure is not evidence that the server contract is absent; retry with a fresh configured PokeMap MCP transport before concluding that the capability is missing.

## Decode before authoring

Inspect the reference visually and create a semantic blueprint before any PokeMap mutation. Read [the layer model](references/exterior-layer-model.md). Use the assisted V2 pipeline when the reference and candidate render align to an integer cell grid. Fall back to `scripts/blueprint_tool.py init` only when they do not.

### Assisted V2 pipeline

Create a small analysis profile from reviewed seed cells. Keep `cellSizePx` at 32 and set `sourceCellSizePx` to the capture scale, such as 16 for a half-size render. Each semantic class may declare a family, confidence threshold, minimum connected-component size, constraints, and unresolved asset requirements.

```bash
python3 scripts/reference_analyzer.py analyze \
  --reference <reference.png> --profile <reference-profile.json> \
  --map-id <map-id> --name <name> \
  --output-blueprint <reference-blueprint.json> \
  --output-report <reference-analysis.json> \
  --output-overlay <reference-overlay.png>
```

Run the same command on the current PokeMap render with a profile using the same semantics. Review both overlays. A high numeric confidence proves only that cells resemble their seeds; it does not prove the semantic labels are correct.

Index only roots with reviewed provenance, then resolve exact-footprint candidates:

```bash
python3 scripts/asset_resolver.py index \
  --root '<path>=hgss_ds' --root '<path>=custom_hgss_compatible' \
  --output <asset-catalog.json>
python3 scripts/asset_resolver.py resolve \
  --blueprint <reference-blueprint.json> --catalog <asset-catalog.json> \
  --output <asset-resolution.json>
python3 scripts/asset_resolver.py workshop \
  --blueprint <reference-blueprint.json> --resolution <asset-resolution.json> \
  --output-dir <assets-workshop> --manifest <asset-workshop.json>
```

`reuse` means an eligible exact-footprint candidate scored at least 80. `gap` creates a transparent canvas and contract at exactly `widthCells * 32` by `heightCells * 32`; it is not finished artwork and cannot be imported without native-scale review.

Lint the proposed masks and compare the current candidate:

```bash
python3 scripts/blueprint_quality.py lint \
  --blueprint <candidate-blueprint.json> --output <lint.json>
python3 scripts/blueprint_quality.py compare \
  --reference <reference-blueprint.json> --candidate <candidate-blueprint.json> \
  --asset-report <asset-resolution.json> \
  --reference-image <reference.png> --candidate-image <candidate-render.png> \
  --threshold 80 \
  --output <comparison.json>
```

The two images must show the same crop and aspect ratio. The comparison command exits non-zero below the threshold, when image evidence is missing, when any visual axis is below 80, or on a hard spatial gate. Its published score gives 50 percent of the weight to rendered fidelity and 50 percent to semantic composition, network topology, structure scale, and asset resolution. Rendered fidelity covers palette and material style, visual hierarchy, and detail density. The report keeps a separate `technicalScore`, identifies weak image regions, and emits an ordered `repairPlan`. Trees in water, structures, or rails, required disconnected networks, and large repeated placed assets that flatten terrain or network families are blocking errors. A score of 80 only makes the candidate eligible for human review; it never marks the map verified.

Classify geometry into these families:

1. `surface` for ground masses and forest coverage;
2. `network` for paths, rivers, stairs, and other connected lines;
3. `border` only for an explicitly approved border system;
4. `structure` for buildings, gates, bridges, and monuments;
5. `decoration` for trees, rocks, flowers, signs, and props;
6. `navigation` for collision, entrances, exits, warps, and traversal zones.

Every layer begins as `proposed`. Show the blueprint summary and unresolved bindings. Do not advance it to `approved` without human review.

## Visual and provenance invariants

Read [the HGSS/DS quality gates](references/hgss-ds-quality-gates.md) before binding assets or creating a missing asset.

- Native cell size is exactly 32 px.
- Accepted provenance is `hgss_ds` or `custom_hgss_compatible`.
- Reject GBA assets and ambiguous mixed-generation sheets.
- Forests use the canonical Environment capability as the natural-surface implementation. If the live product semantics do not satisfy the requested Surface Studio behavior, stop instead of substituting a repeated tree grid.
- Rivers use river water and river banks, never ocean water.
- Do not create or apply Smart Borders unless the blueprint contains a separately approved `border` layer.
- Use nearest-neighbor scaling only when an approved custom asset requires an integer scale. Never use fractional scaling or smoothing.
- Keep terrain and networks editable. Never replace a large share of grass, water, forest, paths, rails, or paddies with one opaque multi-family sprite, even when it improves the image score.

## Missing asset workshop

When no existing HGSS/DS resource satisfies an approved structure or prop:

1. Declare the footprint in cells with `scripts/asset_contract.py init`.
2. Keep the candidate under `<project>/.pokemap/authoring/reference-builder/<operation-id>/assets/`.
3. Produce or import a PNG whose dimensions are exactly `widthCells * 32` by `heightCells * 32`.
4. Apply the asset creation and shadow rules above; record anchor, local collision cells, selected style references, and alpha policy.
5. Run `scripts/asset_contract.py validate`.
6. Show the candidate at native scale and an integer zoom for approval.
7. Import it only after approval through the canonical `asset.import` or `asset.replace` action.

If image generation is available, it may produce a candidate inside that exact canvas. Generation does not grant approval and must not invent a different footprint.

## Apply one family at a time

Read [the MCP recipes](references/pokemap-mcp-recipes.md) before mutation.

For every family:

1. reopen the absolute project and query the current revision;
2. resolve resource IDs from live catalogs rather than guessing names;
3. plan against the current revision;
4. inspect the plan and required confirmation;
5. apply with a unique operation ID;
6. requery and validate;
7. render the map;
8. compare the same-crop render with the reference image and the approved blueprint;
9. mark the family `verified` only after human visual acceptance.

Recommended checkpoints are surfaces, networks plus any explicit borders, structures, decorations, then navigation. Do not stack later families on a visibly rejected checkpoint.

## Safety boundaries

- Stage generated files inside the target project authoring folder, never `/tmp` or a broad allowed root.
- Do not broaden MCP access to the home directory or filesystem root.
- Back up the mutable project before the first mutation.
- Preserve unrelated project content and existing map behavior.
- Requery after any revision mismatch and rebuild the plan.
- Use the editor or Player for final visual and interaction review; structural validation alone is insufficient.

Read [the review checkpoints](references/visual-review-checkpoints.md) before claiming completion.
