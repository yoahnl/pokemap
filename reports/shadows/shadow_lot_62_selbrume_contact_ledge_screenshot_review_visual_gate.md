# Shadow-62 — Selbrume Contact Ledge Screenshot Review / Visual Gate V0

## 1. Resume executif

Shadow-62 est termine en mode visual gate read-only.

Resultat principal: les grosses plaques diagonales dangereuses ont disparu, `genericProjection` est a 0, et il reste exactement 10 instructions statiques de type contact ledge building. Cette fois, la decision est basee sur des captures pixel-based produites automatiquement avec le rendu runtime offscreen de `MapLayersComponent` et les assets reels de Selbrume.

Decision visuelle:

- `keep`: 6 contact ledges.
- `retune-next`: 4 contact ledges encore visibles sur sols clairs ou chemins.
- `disable-next`: 0.
- `manual-review`: 0.
- `screenshot-needed`: 0.

Prochain lot recommande: **Shadow-63 — Building Contact Ledge Minimal Retune V0**. Objectif: retune minimal global des contact ledges, base sur les captures Shadow-62, puis nouvelle verification visuelle. Pas de patch de donnees cible avant ce retune.

## 2. Rappel Shadow-56 / 57 / 58 / 59 / 60 / 61

- Shadow-56: suppression du runtime auto-apply; le runtime consomme le manifest authore.
- Shadow-57: audit apres suppression auto-apply; 111 instructions statiques, toutes en projectedPolygon, dont 97 genericProjection et 95 arbres PixelLab.
- Shadow-58: durcissement de la policy; seul `buildingLarge` reste safe automatiquement.
- Shadow-59: cleanup explicite Selbrume sur `panneau`, `lampadaire`, `arbre_pixellab_1`, `arbre_pixellab_2`, `selbrume_maison_5`.
- Shadow-60: verification post-cleanup; genericProjection tombe a 0 et il reste environ 10 contact ledges.
- Shadow-61: decision prudente instruction-based; captures requises avant validation definitive.

## 3. Nature visual-gate read-only du lot

Ce lot n'a modifie ni code, ni donnees Selbrume, ni renderer, ni policy, ni profils, ni geometrie. Les seuls livrables permanents crees sont le rapport, l'index visuel TSV et les captures PNG Shadow-62.

## 4. Etat initial du worktree

Commande:

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
```

`git status` initial:

```
(aucune sortie)
```

`find .. -name AGENTS.md -print`:

```
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

AGENTS applicable lu: `/Users/karim/Project/pokemonProject/AGENTS.md`.

## 5. Hashes Selbrume initiaux

Commande:

```bash
shasum -a 256 /Users/karim/Desktop/selbrume/project.json
shasum -a 256 /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

```
3c3669a8274e31087b617fd46337c28aef6593f376a7d0a54c2d9fb8e31b389d  /Users/karim/Desktop/selbrume/project.json
8fd1f7efdc02413106a21068e3af310b3149c07023cfad64ddaa101f2c2cac63  /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Hashes finaux, pour preuve de non-modification:

```
3c3669a8274e31087b617fd46337c28aef6593f376a7d0a54c2d9fb8e31b389d  /Users/karim/Desktop/selbrume/project.json
8fd1f7efdc02413106a21068e3af310b3149c07023cfad64ddaa101f2c2cac63  /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Les hashes initiaux et finaux sont identiques.

## 6. Confirmation runtime auto-apply absent

Commande:

```bash
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

```
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:127:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:129:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:154:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:179:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:207:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:232:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:270:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:431:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
```

Conclusion: aucun appel dans `packages/map_runtime`. Les occurrences restantes sont la definition/tests core et le backfill editor explicite.

## 7. Confirmation policy Shadow-58 active

Commande:

```bash
rg -n "_autoShadowKindIsArtisticallySafe|case ElementAutoShadowSuggestionKind.buildingLarge|case ElementAutoShadowSuggestionKind.tallThin|case ElementAutoShadowSuggestionKind.wideLow|case ElementAutoShadowSuggestionKind.smallSquare|case ElementAutoShadowSuggestionKind.defaultProp" packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
```

```
124:  if (!_autoShadowKindIsArtisticallySafe(
261:bool _autoShadowKindIsArtisticallySafe(
267:    case ElementAutoShadowSuggestionKind.buildingLarge:
269:    case ElementAutoShadowSuggestionKind.tallThin:
270:    case ElementAutoShadowSuggestionKind.wideLow:
271:    case ElementAutoShadowSuggestionKind.smallSquare:
272:    case ElementAutoShadowSuggestionKind.defaultProp:
282:    case ElementAutoShadowSuggestionKind.tallThin:
283:    case ElementAutoShadowSuggestionKind.smallSquare:
285:    case ElementAutoShadowSuggestionKind.buildingLarge:
286:    case ElementAutoShadowSuggestionKind.wideLow:
288:    case ElementAutoShadowSuggestionKind.defaultProp:
348:    case ElementAutoShadowSuggestionKind.tallThin:
365:    case ElementAutoShadowSuggestionKind.buildingLarge:
382:    case ElementAutoShadowSuggestionKind.wideLow:
399:    case ElementAutoShadowSuggestionKind.smallSquare:
416:    case ElementAutoShadowSuggestionKind.defaultProp:
438:    case ElementAutoShadowSuggestionKind.tallThin:
440:    case ElementAutoShadowSuggestionKind.buildingLarge:
442:    case ElementAutoShadowSuggestionKind.wideLow:
444:    case ElementAutoShadowSuggestionKind.smallSquare:
446:    case ElementAutoShadowSuggestionKind.defaultProp:
```

Snippet verifie:

```dart
  if (area <= 4) {
    return ElementAutoShadowSuggestionKind.smallSquare;
  }
  return ElementAutoShadowSuggestionKind.defaultProp;
}

bool _autoShadowKindIsArtisticallySafe(
  ElementAutoShadowSuggestionKind kind, {
  required double width,
  required double height,
}) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return true;
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.wideLow:
    case ElementAutoShadowSuggestionKind.smallSquare:
    case ElementAutoShadowSuggestionKind.defaultProp:
      return false;
  }
}

```

Conclusion: `buildingLarge` est le seul kind safe; `tallThin`, `wideLow`, `smallSquare`, `defaultProp` restent non-safe.

## 8. Confirmation Shadow-59 applique

Commande:

```bash
jq -r '.elements[] | select(.id=="panneau" or .id=="lampadaire" or .id=="arbre_pixellab_1" or .id=="arbre_pixellab_2" or .id=="selbrume_maison_5") | [.id, .name, (.shadow == null)] | @tsv' /Users/karim/Desktop/selbrume/project.json
```

```tsv
selbrume_maison_5	selbrume maison 5	true
lampadaire	lampadaire	true
arbre_pixellab_1	arbre  pixelLab 1	true
arbre_pixellab_2	arbre  pixelLab 2	true
panneau	panneau	true
```

Counts `shadow != null`, `shadow == null`, total elements:

```
20
43
63
```

Shadow overrides dans `Selbrume.json`:

```tsv
2105	0	2105
```

Placements des 5 cibles, format `total panneau lampadaire arbre_pixellab_1 arbre_pixellab_2 selbrume_maison_5`:

```tsv
2105	1	4	46	49	1
```

## 9. Inventaire runtime actuel

Methode:

- Probe Flutter temporaire sous `/tmp/shadow62_runtime_inventory_test.dart`.
- Chargement reel de `/Users/karim/Desktop/selbrume/project.json` avec `loadRuntimeMapBundle`.
- Reconstruction des sources via `buildRuntimeStaticPlacedElementShadowSources`.
- Generation des instructions via `buildRuntimeStaticPlacedElementShadowCollection`.
- Enrichissement par `elementId`, `family`, `profile`, geometryType.
- Aucun fichier de production modifie.

Sortie:

```
00:00 +0: loading /tmp/shadow62_runtime_inventory_test.dart
00:00 +0: shadow62 runtime inventory
{
  "staticInstructionsTotal": 10,
  "groundStaticTotal": 10,
  "projectedPolygonTotal": 10,
  "contactLedgeTotal": 10,
  "genericProjectionTotal": 0,
  "byElement": {
    "selbrum_maison_3": 1,
    "selbrum_maison_4": 2,
    "selbrum_maison_1": 1,
    "selbrume_centre_pok_mon": 1,
    "selbrum_maison_7": 1,
    "le_puits": 1,
    "selbrum_maison_2": 1,
    "selbrum_maison_8": 1,
    "kiosque_l_gumes": 1
  },
  "byFamily": {
    "building": 10
  },
  "byProfile": {
    "default-ground-wide-ellipse": 10
  },
  "opacityAverage": 0.19999999999999998,
  "opacityMax": 0.2,
  "areaAverage": 8815.100232204255,
  "areaMax": 15099.871698616262
}
00:00 +1: All tests passed!
```

Synthese:

- static instructions total: 10.
- groundStatic total: 10.
- projectedPolygon total: 10, car le renderer encode encore les contact ledges comme polygon runtime.
- contactLedge total: 10, reconstruit par `family == building`.
- genericProjection total: 0.
- by family: `building: 10`.
- by profile: `default-ground-wide-ellipse: 10`.
- opacity average/max: 0.2 / 0.2.
- area average/max: 8815.100232204255 / 15099.871698616262.

## 10. Table complete des contact ledges

Table complete aussi disponible dans `reports/shadows/shadow_lot_62_contact_ledge_visual_index.tsv`.


| Rank | Element | Capture | Visual risk | Decision | Reason |
|---:|---|---|---|---|---|
| 1 | `selbrum_maison_3` | `reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png` | low | keep | Discret sous cloture/facade, ne lit plus comme une plaque. |
| 2 | `selbrum_maison_4` | `reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png` | medium | retune-next | Bande trapezoidale visible sur chemin clair. |
| 3 | `selbrum_maison_1` | `reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png` | low | keep | Ombre courte et peu intrusive. |
| 4 | `selbrume_centre_pok_mon` | `reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png` | low | keep | Contact discret sous facade, pas de grande dalle. |
| 5 | `selbrum_maison_7` | `reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png` | medium | retune-next | Ombre visible au pied droit sur zone claire. |
| 6 | `le_puits` | `reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png` | low | keep | Ombre locale et coherente pour le puits. |
| 7 | `selbrum_maison_4` | `reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png` | medium | retune-next | Barre trapezoidale visible sur chemin clair. |
| 8 | `selbrum_maison_2` | `reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png` | low | keep | Majoritairement cachee par pied du batiment/vegetation. |
| 9 | `selbrum_maison_8` | `reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png` | low | keep | Discrete sous facade large. |
| 10 | `kiosque_l_gumes` | `reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png` | medium | retune-next | Kiosque sur chemin clair; ledge encore visible comme bande. |


TSV complet:

```tsv
rank	placementId/index	elementId	elementName	worldX	worldY	instructionLeft	instructionTop	instructionWidth	instructionHeight	instructionArea	opacity	shapeKind	geometryType	renderPass	family	shadowProfileId	viewportSuggestion	visualRiskBeforeScreenshot	screenshotPath	visualRiskAfterScreenshot	recommendation	reason
1	l_tile_maison_selbrume::24::12	selbrum_maison_3	selbrum maison 3	2304.0	1152.0	2449.12128	1807.076352	477.7574400000003	23.483647999999903	11219.48755034108	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (2304, 1152); crop approx left=1704 top=732 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png	low	keep	discret sous la cloture et le pied de facade; ne lit plus comme une plaque
2	l_tile_maison_selbrume::17::17	selbrum_maison_4	selbrum maison  4	1632.0	1632.0	1722.7008	2193.494016	298.59839999999986	22.985983999999917	6863.578044825572	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (1632, 1632); crop approx left=1032 top=1212 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png	medium	retune-next	bande trapezoidale visible sur chemin clair au pied de la maison
3	l_tile_maison_selbrume::10::18	selbrum_maison_1	selbrum maison 1	960.0	1728.0	1050.7008	2289.494016	298.59839999999986	22.985983999999917	6863.578044825572	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (960, 1728); crop approx left=360 top=1308 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png	low	keep	ombre courte et peu intrusive sous la facade
4	l_tile_maison_selbrume::29::22	selbrume_centre_pok_mon	selbrume centre pokémon	2784.0	2112.0	2929.12128	2673.494016	477.7574400000003	22.985983999999917	10981.724871720928	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (2784, 2112); crop approx left=2184 top=1692 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png	low	keep	ombre discrete sous le centre Pokemon, sans grande plaque diagonale
5	l_tile_maison_selbrume::38::22	selbrum_maison_7	selbrum maison  7	3648.0	2112.0	3756.84096	2673.494016	358.31807999999955	22.985983999999917	8236.29365379068	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (3648, 2112); crop approx left=3048 top=1692 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png	medium	retune-next	ombre visible au pied droit du batiment sur herbe claire
6	l_tile_maison_selbrume::23::27	le_puits	le puits	2208.0	2592.0	2280.56064	3059.91168	238.8787199999997	22.48831999999993	5371.981096550377	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (2208, 2592); crop approx left=1608 top=2172 width=1200 height=840	unknown-watch	reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png	low	keep	contact shadow du puits coherente et locale, pas de dalle projetee
7	l_tile_maison_selbrume::36::29	selbrum_maison_4	selbrum maison  4	3456.0	2784.0	3546.7008	3345.494016	298.59839999999986	22.985983999999917	6863.578044825572	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (3456, 2784); crop approx left=2856 top=2364 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png	medium	retune-next	barre trapezoidale visible sur chemin clair
8	l_tile_maison_selbrume::10::30	selbrum_maison_2	selbrum maison  2	960.0	2880.0	1068.84096	3535.076352	358.31808	23.483647999999903	8414.615662755805	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (960, 2880); crop approx left=360 top=2460 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png	low	keep	ombre majoritairement cachee par le pied du batiment et la vegetation
9	l_tile_maison_selbrume::18::33	selbrum_maison_8	selbrum maison  8	1728.0	3168.0	1927.54176	3729.494016	656.9164799999999	22.985983999999917	15099.871698616262	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (1728, 3168); crop approx left=1128 top=2748 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png	low	keep	ombre discrete sous une facade large, peu lisible comme plaque
10	l_tile_maison_selbrume::36::35	kiosque_l_gumes	kiosque à légumes	3456.0	3360.0	3564.84096	3921.494016	358.31808	22.985983999999917	8236.29365379069	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (3456, 3360); crop approx left=2856 top=2940 width=1200 height=840	unknown-watch	reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png	medium	retune-next	kiosque sur chemin clair; contact ledge visible et a retuner avant validation
```

## 11. Tentative de capture automatique


Commandes executees:
- `find examples packages -maxdepth 4 -type f | rg "playable_runtime_host|screenshot|integration|golden|runtime_host|selbrume|macos|flutter_driver"`
- `rg -n "Selbrume|projectFilePath|playable_runtime_host|RuntimeMapBundle|loadRuntimeMapBundle|screenshot|takeScreenshot|golden" examples packages`

Resultat utile:
- `examples/playable_runtime_host/README.md` documente un lancement manuel du host, pas une capture automatique Selbrume.
- `examples/playable_runtime_host/test/runtime_project_picker_test.dart` teste le picker, pas les pixels runtime.
- `packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart` et `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart` montrent un pattern local de rendu offscreen avec `ui.PictureRecorder`.
- Aucun harness permanent dedie a une capture Selbrume Shadow n'a ete trouve.
- Une capture automatique temporaire et read-only etait possible en reutilisant le pattern de rendu offscreen de `MapLayersComponent`, sans modifier le repo.

Documentation Flame:
- `flame_docs.search_documentation("Flame screenshot testing GameWidget render capture canvas image")` -> `No results found.`
- `flame_docs.search_documentation("Flame test game widget golden screenshot")` -> `No results found.`
- Decision: ne pas inventer d'API Flame. Utiliser le pattern deja present dans les tests runtime PokeMap: `ui.PictureRecorder`, `MapLayersComponent.render(canvas)`, images de tilesets chargees via `loadTilesetImagesById`.


## 12. Captures produites ou plan manuel

Capture automatique possible: oui.

Plan manuel: non cree, car les captures pixel-based ont ete produites automatiquement.

Commande:

```bash
cd packages/map_runtime && flutter test /tmp/shadow62_capture_contact_ledges_test.dart --plain-name 'shadow62 capture contact ledges'
```

Sortie:

```
00:00 +0: loading /tmp/shadow62_capture_contact_ledges_test.dart
00:00 +0: shadow62 capture contact ledges
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_selbrume_overview.png
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png
capture rank=1 element=selbrum_maison_3 cropLeft=2189.1 cropTop=1377.1
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png
capture rank=2 element=selbrum_maison_4 cropLeft=1462.7 cropTop=1763.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png
capture rank=3 element=selbrum_maison_1 cropLeft=790.7 cropTop=1859.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png
capture rank=4 element=selbrume_centre_pok_mon cropLeft=2669.1 cropTop=2243.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png
capture rank=5 element=selbrum_maison_7 cropLeft=3496.8 cropTop=2243.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png
capture rank=6 element=le_puits cropLeft=2020.6 cropTop=2629.9
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png
capture rank=7 element=selbrum_maison_4 cropLeft=3286.7 cropTop=2915.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png
capture rank=8 element=selbrum_maison_2 cropLeft=808.8 cropTop=3105.1
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png
capture rank=9 element=selbrum_maison_8 cropLeft=1667.5 cropTop=3299.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png
capture rank=10 element=kiosque_l_gumes cropLeft=3304.8 cropTop=3491.5
00:01 +1: All tests passed!
```

Captures PNG produites:

```tsv
reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png	159151	3b6140f47ad0b67d0ae1f8fc4d23189407b459007732fb3eb388142a75e970c1
reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png	181017	8531533d287e416b9f3f3f34f09a934f4481dee40fdf9650ea1b7d06f184b53e
reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png	168372	792fe167919624a8f898300a63cd73a69afde7c01ef20dd6c84375bfa24b52df
reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png	181985	05ee73027af0edf06f409546892891dc574e1231c7783838c13a185630aaa10f
reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png	162447	485b26626399663875e136a724e2390e573b6711b4a80f808cfb13827565f810
reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png	178307	588510a2ba09b6a34800d74a9d4b488c7d6a1c82675fbbe365c21b37b2b4a201
reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png	146614	855e395885f8d929854f0f343efd269f3403ea6e02f16adc1ae234a31e733ff2
reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png	151455	a07272dd09d00e37480a563e43839cd061e5c20830ad59749bf98f537ea19e23
reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png	183186	8aaa6e5a285167bd62f913e2fe3a671f908aecefda8309d16158796d629c460d
reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png	159755	23a3ca24de210e03fa501f23a5fb5b8fa3bf8ff9d2c6fcf8c4f05e2221bb3f0b
reports/shadows/screenshots/shadow62_selbrume_overview.png	2531143	db3b0b226a79591a352805c307b723bde40e9c5e1322f6a65bc3cb7eb318942e
```

Le rendu capture la couche map runtime, les tilesets reels et les static shadows. Limite connue: ce n'est pas une capture de fenetre macOS du host avec UI Flutter/player/camera; c'est une capture offscreen des pixels de map via le composant runtime qui dessine les ombres.

## 13. Analyse visuelle par contact ledge

### Overview

`reports/shadows/screenshots/shadow62_selbrume_overview.png` montre que les grandes plaques diagonales des arbres/panneau/lampadaire ne sont plus visibles dans la slice capturee. Les seules ombres statiques restantes sont courtes et rattachees au pied des batiments/structures.

### Rank 1 — `selbrum_maison_3`

Capture: `reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png`.

Decision: `keep`. La ledge est discrete sous la cloture et le pied de facade. Elle ne lit plus comme une dalle.

### Rank 2 — `selbrum_maison_4`

Capture: `reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png`.

Decision: `retune-next`. La forme trapezoidale reste visible sur le chemin clair. Ce n'est plus catastrophique comme les grandes projections, mais ce n'est pas encore Pokemon-like.

### Rank 3 — `selbrum_maison_1`

Capture: `reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png`.

Decision: `keep`. Ombre courte, peu intrusive, coherente avec le pied de facade.

### Rank 4 — `selbrume_centre_pok_mon`

Capture: `reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png`.

Decision: `keep`. Contact discret, pas de grande plaque diagonale.

### Rank 5 — `selbrum_maison_7`

Capture: `reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png`.

Decision: `retune-next`. L'ombre au pied droit reste visible sur herbe/zone claire.

### Rank 6 — `le_puits`

Capture: `reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png`.

Decision: `keep`. L'ombre est locale, coherente et lisible comme contact shadow. Le puits etait a surveiller, mais il ne justifie pas une suppression data dans ce lot.

### Rank 7 — `selbrum_maison_4`

Capture: `reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png`.

Decision: `retune-next`. Une barre trapezoidale reste visible sur chemin clair.

### Rank 8 — `selbrum_maison_2`

Capture: `reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png`.

Decision: `keep`. Elle est majoritairement cachee par le pied du batiment et la vegetation.

### Rank 9 — `selbrum_maison_8`

Capture: `reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png`.

Decision: `keep`. Ombre discrete sous facade large, acceptable en V0.

### Rank 10 — `kiosque_l_gumes`

Capture: `reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png`.

Decision: `retune-next`. Le kiosque reste a surveiller: la ledge est une bande visible sur chemin clair. Je ne recommande pas de le desactiver tout de suite; un retune global minimal devrait d'abord etre tente.

## 14. Decisions obligatoires

1. Les grosses plaques diagonales d'arbres ont-elles disparu ? Oui. Les cibles arbres Shadow-59 ont `shadow == null` et l'inventaire runtime donne 0 instruction pour `arbre_pixellab_1` / `arbre_pixellab_2`.
2. `genericProjection` est-il bien a 0 ? Oui, `genericProjectionTotal: 0`.
3. Combien de contact ledges restent ? 10.
4. Quels elementId les generent ? `selbrum_maison_3`, `selbrum_maison_4` x2, `selbrum_maison_1`, `selbrume_centre_pok_mon`, `selbrum_maison_7`, `le_puits`, `selbrum_maison_2`, `selbrum_maison_8`, `kiosque_l_gumes`.
5. Les contact ledges sont-ils visuellement valides par capture ? Oui, le lot a produit une capture overview et une capture par ledge.
6. `le_puits` est-il acceptable ? Oui en V0, `keep`.
7. `kiosque_l_gumes` est-il acceptable ? Pas definitivement. Classification `medium`, `retune-next`.
8. Les maisons classiques sont-elles acceptables ? Mixte: 6 keep, 4 retune-next. Les cas problematiques sont surtout les ledges visibles sur sols clairs.
9. Faut-il retune l'opacite / hauteur / largeur des contact ledges ? Oui. Retune minimal recommande pour reduire les bandes visibles sans revenir aux plaques diagonales.
10. Faut-il desactiver certains contact ledges au niveau donnees ? Pas maintenant. Les captures soutiennent un retune global avant un patch de donnees cible.
11. Faut-il passer au screenshot golden slice ? Pas encore. D'abord Shadow-63 retune minimal, ensuite une nouvelle validation screenshot/golden peut devenir pertinente.
12. Quel est le prochain lot recommande ? Shadow-63 — Building Contact Ledge Minimal Retune V0.

## 15. Recommandation du prochain lot

**Shadow-63 — Building Contact Ledge Minimal Retune V0**.

Objectif propose:

- Modifier uniquement la geometrie/calibration contact ledge building, pas les projections generic ni les donnees Selbrume.
- Reduire la visibilite des bandes sur chemins clairs.
- Garder les 10 ledges locales et courtes.
- Verifier avec les memes 11 captures Shadow-62 apres retune.
- Ne pas toucher aux arbres/panneau/lampadaire; ils sont deja neutralises.

Critere produit:

- Les ledges medium de Shadow-62 doivent devenir low ou etre candidates a disable data dans le lot suivant.
- Aucune nouvelle instruction genericProjection.
- Pas de retour des grandes plaques diagonales.

## 16. Probe manifest load

Script temporaire:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';

void main() {
  test('shadow62 validate selbrume manifest', () async {
    final manifest = await loadProjectManifestFromFile(
      '/Users/karim/Desktop/selbrume/project.json',
    );
    expect(manifest.elements, hasLength(63));
    expect(manifest.elements.where((element) => element.shadow != null), hasLength(20));

    const cleanedIds = {
      'panneau',
      'lampadaire',
      'arbre_pixellab_1',
      'arbre_pixellab_2',
      'selbrume_maison_5',
    };
    for (final id in cleanedIds) {
      final element = manifest.elements.singleWhere((element) => element.id == id);
      expect(element.shadow, isNull, reason: '$id must remain cleaned by Shadow-59');
    }
  });
}
```

Commande:

```bash
cd packages/map_runtime && flutter test /tmp/shadow62_validate_selbrume_manifest_test.dart --plain-name 'shadow62 validate selbrume manifest'
```

Sortie:

```
00:00 +0: loading /tmp/shadow62_validate_selbrume_manifest_test.dart
00:00 +0: shadow62 validate selbrume manifest
00:00 +1: All tests passed!
```

## 17. Tests de regression repo

Commandes et lignes finales exactes:

```text
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
00:00 +3: All tests passed!

cd packages/map_runtime && flutter test test/shadow
00:05 +233: All tests passed!

cd packages/map_core && dart test test/shadow
00:01 +284: All tests passed!

cd packages/map_editor && flutter test test/application/shadow
00:00 +96: All tests passed!
```

## 18. Ce qui n'a volontairement pas ete modifie

- Aucun code `packages/**`.
- Aucun fichier Selbrume.
- Aucun renderer.
- Aucune policy Shadow.
- Aucun profil Shadow.
- Aucune geometrie contact ledge.
- Aucun `shadowOverride`.
- Aucun harness screenshot permanent.
- Aucun commit.

## 19. git diff --stat

Commande:

```bash
git diff --stat
```

```
(aucune sortie)
```

## 20. git diff --name-status

Commande:

```bash
git diff --name-status
```

```
(aucune sortie)
```

## 21. git diff --check

Commande:

```bash
git diff --check
```

```
(aucune sortie)
```

## 22. git status final

Commande:

```bash
git status --short --untracked-files=all
```

```
?? reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png
?? reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png
?? reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png
?? reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png
?? reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png
?? reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png
?? reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png
?? reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png
?? reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png
?? reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png
?? reports/shadows/screenshots/shadow62_selbrume_overview.png
?? reports/shadows/shadow_lot_62_contact_ledge_visual_index.tsv
?? reports/shadows/shadow_lot_62_selbrume_contact_ledge_screenshot_review_visual_gate.md
```

## 23. Risques / reserves

- Les captures sont offscreen map-layer, pas des screenshots de la fenetre host complete. Pour juger les contact ledges elles sont fiables, car elles utilisent `MapLayersComponent.render(canvas)` avec les tilesets et shadows runtime reels.
- Les contact ledges sont encore techniquement `projectedPolygon` dans l'instruction runtime. Ici, elles sont classees `contactLedge` par `family == building`. Un futur refactor pourrait separer le shape kind, mais ce n'est pas necessaire pour Shadow-62.
- Un retune global peut ameliorer les 4 cas medium, mais il faut verifier qu'il ne rend pas invisibles les 6 cas keep.

## 24. Auto-critique

Le lot a enfin juge des pixels, ce qui manquait aux lots precedents. La limite principale est que la capture n'inclut pas l'habillage Flutter du host ni la camera joueur; toutefois les ombres statiques sont dessinees par le meme composant de map runtime et les captures ciblent exactement les zones d'instruction. Je ne recommande pas de modifier les donnees Selbrume sur cette base: les problemes restants sont maintenant assez coherents pour un retune minimal de contact ledge.

## 25. Regard critique sur le prompt

Le prompt a bien verrouille le risque principal: ne pas calibrer dans le noir. La contrainte la plus utile est l'interdiction de conclure sans capture; elle force la decision pixel-based. Le prompt demande aussi un plan manuel si capture impossible; ici il n'est pas necessaire, puisque la capture automatique a reussi sans modifier le repo.

## 26. Proposition de prompt pour le prochain lot

```md
# Shadow-63 — Building Contact Ledge Minimal Retune V0

Objectif: retune minimal des contact ledges building apres validation pixel-based Shadow-62.

Contraintes:
- ne pas modifier Selbrume;
- ne pas modifier runtime renderer;
- ne pas modifier policy auto-shadow;
- ne pas reactiver genericProjection;
- modifier uniquement la calibration/geometrie contact ledge si necessaire;
- verifier avec les memes captures Shadow-62 regenerees;
- garder `genericProjectionTotal == 0`;
- objectif visuel: les 4 cas `retune-next` de Shadow-62 deviennent discrets sur sols clairs sans effacer completement les 6 cas `keep`.

Fichiers probablement touches:
- `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`
- tests associes sous `packages/map_core/test/shadow`
- eventuellement tests runtime/editor si la geometrie attendue change.

Tests:
- `cd packages/map_core && dart test test/shadow/static_shadow_contact_ledge_geometry_test.dart`
- `cd packages/map_runtime && flutter test test/shadow`
- `cd packages/map_editor && flutter test test/application/shadow`
- probe screenshot Shadow-63 regenere a partir du probe Shadow-62.
```

## File inventory

### Created text files

- `reports/shadows/shadow_lot_62_selbrume_contact_ledge_screenshot_review_visual_gate.md`
- `reports/shadows/shadow_lot_62_contact_ledge_visual_index.tsv`

### Created binary files

```tsv
reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png	159151	3b6140f47ad0b67d0ae1f8fc4d23189407b459007732fb3eb388142a75e970c1
reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png	181017	8531533d287e416b9f3f3f34f09a934f4481dee40fdf9650ea1b7d06f184b53e
reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png	168372	792fe167919624a8f898300a63cd73a69afde7c01ef20dd6c84375bfa24b52df
reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png	181985	05ee73027af0edf06f409546892891dc574e1231c7783838c13a185630aaa10f
reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png	162447	485b26626399663875e136a724e2390e573b6711b4a80f808cfb13827565f810
reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png	178307	588510a2ba09b6a34800d74a9d4b488c7d6a1c82675fbbe365c21b37b2b4a201
reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png	146614	855e395885f8d929854f0f343efd269f3403ea6e02f16adc1ae234a31e733ff2
reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png	151455	a07272dd09d00e37480a563e43839cd061e5c20830ad59749bf98f537ea19e23
reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png	183186	8aaa6e5a285167bd62f913e2fe3a671f908aecefda8309d16158796d629c460d
reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png	159755	23a3ca24de210e03fa501f23a5fb5b8fa3bf8ff9d2c6fcf8c4f05e2221bb3f0b
reports/shadows/screenshots/shadow62_selbrume_overview.png	2531143	db3b0b226a79591a352805c307b723bde40e9c5e1322f6a65bc3cb7eb318942e
```

### Modified tracked files

Aucun.

### Deleted files

Aucun.

### Still-untracked files touched by this task

```
?? reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png
?? reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png
?? reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png
?? reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png
?? reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png
?? reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png
?? reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png
?? reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png
?? reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png
?? reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png
?? reports/shadows/screenshots/shadow62_selbrume_overview.png
?? reports/shadows/shadow_lot_62_contact_ledge_visual_index.tsv
?? reports/shadows/shadow_lot_62_selbrume_contact_ledge_screenshot_review_visual_gate.md
```

## Code complet des fichiers crees/modifies

### `reports/shadows/shadow_lot_62_contact_ledge_visual_index.tsv`

```tsv
rank	placementId/index	elementId	elementName	worldX	worldY	instructionLeft	instructionTop	instructionWidth	instructionHeight	instructionArea	opacity	shapeKind	geometryType	renderPass	family	shadowProfileId	viewportSuggestion	visualRiskBeforeScreenshot	screenshotPath	visualRiskAfterScreenshot	recommendation	reason
1	l_tile_maison_selbrume::24::12	selbrum_maison_3	selbrum maison 3	2304.0	1152.0	2449.12128	1807.076352	477.7574400000003	23.483647999999903	11219.48755034108	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (2304, 1152); crop approx left=1704 top=732 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png	low	keep	discret sous la cloture et le pied de facade; ne lit plus comme une plaque
2	l_tile_maison_selbrume::17::17	selbrum_maison_4	selbrum maison  4	1632.0	1632.0	1722.7008	2193.494016	298.59839999999986	22.985983999999917	6863.578044825572	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (1632, 1632); crop approx left=1032 top=1212 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png	medium	retune-next	bande trapezoidale visible sur chemin clair au pied de la maison
3	l_tile_maison_selbrume::10::18	selbrum_maison_1	selbrum maison 1	960.0	1728.0	1050.7008	2289.494016	298.59839999999986	22.985983999999917	6863.578044825572	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (960, 1728); crop approx left=360 top=1308 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png	low	keep	ombre courte et peu intrusive sous la facade
4	l_tile_maison_selbrume::29::22	selbrume_centre_pok_mon	selbrume centre pokémon	2784.0	2112.0	2929.12128	2673.494016	477.7574400000003	22.985983999999917	10981.724871720928	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (2784, 2112); crop approx left=2184 top=1692 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png	low	keep	ombre discrete sous le centre Pokemon, sans grande plaque diagonale
5	l_tile_maison_selbrume::38::22	selbrum_maison_7	selbrum maison  7	3648.0	2112.0	3756.84096	2673.494016	358.31807999999955	22.985983999999917	8236.29365379068	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (3648, 2112); crop approx left=3048 top=1692 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png	medium	retune-next	ombre visible au pied droit du batiment sur herbe claire
6	l_tile_maison_selbrume::23::27	le_puits	le puits	2208.0	2592.0	2280.56064	3059.91168	238.8787199999997	22.48831999999993	5371.981096550377	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (2208, 2592); crop approx left=1608 top=2172 width=1200 height=840	unknown-watch	reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png	low	keep	contact shadow du puits coherente et locale, pas de dalle projetee
7	l_tile_maison_selbrume::36::29	selbrum_maison_4	selbrum maison  4	3456.0	2784.0	3546.7008	3345.494016	298.59839999999986	22.985983999999917	6863.578044825572	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (3456, 2784); crop approx left=2856 top=2364 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png	medium	retune-next	barre trapezoidale visible sur chemin clair
8	l_tile_maison_selbrume::10::30	selbrum_maison_2	selbrum maison  2	960.0	2880.0	1068.84096	3535.076352	358.31808	23.483647999999903	8414.615662755805	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (960, 2880); crop approx left=360 top=2460 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png	low	keep	ombre majoritairement cachee par le pied du batiment et la vegetation
9	l_tile_maison_selbrume::18::33	selbrum_maison_8	selbrum maison  8	1728.0	3168.0	1927.54176	3729.494016	656.9164799999999	22.985983999999917	15099.871698616262	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (1728, 3168); crop approx left=1128 top=2748 width=1200 height=840	unknown-provisional	reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png	low	keep	ombre discrete sous une facade large, peu lisible comme plaque
10	l_tile_maison_selbrume::36::35	kiosque_l_gumes	kiosque à légumes	3456.0	3360.0	3564.84096	3921.494016	358.31808	22.985983999999917	8236.29365379069	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	center near world (3456, 3360); crop approx left=2856 top=2940 width=1200 height=840	unknown-watch	reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png	medium	retune-next	kiosque sur chemin clair; contact ledge visible et a retuner avant validation
```

Le rapport lui-meme n'est pas recopie recursivement dans cette section.

## Probes temporaires

### `/tmp/shadow62_runtime_inventory_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_collection.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_sources.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  test('shadow62 runtime inventory', () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: '/Users/karim/Desktop/selbrume/project.json',
      mapId: 'Selbrume',
    );
    final elementsById = <String, ProjectElementEntry>{
      for (final element in bundle.manifest.elements) element.id: element,
    };
    final sources = buildRuntimeStaticPlacedElementShadowSources(
      bundle: bundle,
    );

    final rows = <Map<String, Object?>>[];
    var rank = 0;
    for (final source in sources) {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: bundle.manifest.shadowCatalog,
        sources: [source],
      );
      for (final instruction in collection.instructions) {
        rank += 1;
        final element = elementsById[source.elementId];
        final shadow = element?.shadow;
        final family = shadow?.family;
        final geometryType = instruction.shape ==
                    ShadowRuntimeShapeKind.projectedPolygon &&
                family == StaticShadowFamily.building
            ? 'contactLedge'
            : instruction.shape.name;
        final viewportSuggestion = _viewportSuggestion(
          source.metrics.worldLeft,
          source.metrics.worldTop,
        );
        final visualRiskBeforeScreenshot = switch (source.elementId) {
          'le_puits' || 'kiosque_l_gumes' => 'unknown-watch',
          _ => 'unknown-provisional',
        };
        final recommendation = switch (source.elementId) {
          'le_puits' || 'kiosque_l_gumes' => 'screenshot-needed',
          _ => 'keep-provisional',
        };
        final reason = switch (source.elementId) {
          'le_puits' =>
            'well uses building contact ledge; needs pixel review because it is not a house facade',
          'kiosque_l_gumes' =>
            'kiosk uses building contact ledge; needs pixel review because silhouette differs from house facade',
          _ =>
            'building contact ledge remains after cleanup; cannot be final keep without screenshot',
        };
        rows.add({
          'rank': rank,
          'placementId/index': source.id,
          'elementId': source.elementId,
          'elementName': element?.name ?? source.elementId,
          'worldX': source.metrics.worldLeft,
          'worldY': source.metrics.worldTop,
          'instructionLeft': instruction.worldLeft,
          'instructionTop': instruction.worldTop,
          'instructionWidth': instruction.width,
          'instructionHeight': instruction.height,
          'instructionArea': instruction.width * instruction.height,
          'opacity': instruction.opacity,
          'shapeKind': instruction.shape.name,
          'geometryType': geometryType,
          'renderPass': instruction.renderPass.name,
          'family': family?.name ?? 'null',
          'shadowProfileId': shadow?.shadowProfileId ?? 'null',
          'viewportSuggestion': viewportSuggestion,
          'visualRiskBeforeScreenshot': visualRiskBeforeScreenshot,
          'screenshotPath': 'not-produced',
          'visualRiskAfterScreenshot': 'unknown',
          'recommendation': recommendation,
          'reason': reason,
        });
      }
    }

    final byElement = <String, int>{};
    final byFamily = <String, int>{};
    final byProfile = <String, int>{};
    final byGeometryType = <String, int>{};
    final byShape = <String, int>{};
    final byRenderPass = <String, int>{};
    for (final row in rows) {
      void inc(Map<String, int> map, String key) {
        map[key] = (map[key] ?? 0) + 1;
      }

      inc(byElement, row['elementId']! as String);
      inc(byFamily, row['family']! as String);
      inc(byProfile, row['shadowProfileId']! as String);
      inc(byGeometryType, row['geometryType']! as String);
      inc(byShape, row['shapeKind']! as String);
      inc(byRenderPass, row['renderPass']! as String);
    }
    final areas = rows.map((row) => row['instructionArea']! as double).toList();
    final opacities = rows.map((row) => row['opacity']! as double).toList();
    final summary = {
      'staticInstructionsTotal': rows.length,
      'groundStaticTotal': byRenderPass['groundStatic'] ?? 0,
      'projectedPolygonTotal': byShape['projectedPolygon'] ?? 0,
      'contactLedgeTotal': byGeometryType['contactLedge'] ?? 0,
      'genericProjectionTotal': byFamily['genericProjection'] ?? 0,
      'byElement': byElement,
      'byFamily': byFamily,
      'byProfile': byProfile,
      'byGeometryType': byGeometryType,
      'opacityAverage': opacities.isEmpty
          ? 0
          : opacities.reduce((a, b) => a + b) / opacities.length,
      'opacityMax': opacities.isEmpty
          ? 0
          : opacities.reduce((a, b) => a > b ? a : b),
      'areaAverage': areas.isEmpty
          ? 0
          : areas.reduce((a, b) => a + b) / areas.length,
      'areaMax': areas.isEmpty
          ? 0
          : areas.reduce((a, b) => a > b ? a : b),
      'rows': rows,
    };

    await File('/tmp/shadow62_runtime_inventory.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(summary),
    );
    await File('/tmp/shadow62_runtime_inventory.tsv').writeAsString(
      _toTsv(rows),
    );
    print(const JsonEncoder.withIndent('  ').convert({
      'staticInstructionsTotal': summary['staticInstructionsTotal'],
      'groundStaticTotal': summary['groundStaticTotal'],
      'projectedPolygonTotal': summary['projectedPolygonTotal'],
      'contactLedgeTotal': summary['contactLedgeTotal'],
      'genericProjectionTotal': summary['genericProjectionTotal'],
      'byElement': summary['byElement'],
      'byFamily': summary['byFamily'],
      'byProfile': summary['byProfile'],
      'opacityAverage': summary['opacityAverage'],
      'opacityMax': summary['opacityMax'],
      'areaAverage': summary['areaAverage'],
      'areaMax': summary['areaMax'],
    }));

    expect(rows.length, 10);
    expect(byGeometryType['contactLedge'] ?? 0, 10);
    expect(byFamily['genericProjection'] ?? 0, 0);
  });
}

String _viewportSuggestion(double worldX, double worldY) {
  final left = (worldX - 600).clamp(0, double.infinity).toStringAsFixed(0);
  final top = (worldY - 420).clamp(0, double.infinity).toStringAsFixed(0);
  return 'center near world (${worldX.toStringAsFixed(0)}, ${worldY.toStringAsFixed(0)}); crop approx left=$left top=$top width=1200 height=840';
}

String _toTsv(List<Map<String, Object?>> rows) {
  const headers = [
    'rank',
    'placementId/index',
    'elementId',
    'elementName',
    'worldX',
    'worldY',
    'instructionLeft',
    'instructionTop',
    'instructionWidth',
    'instructionHeight',
    'instructionArea',
    'opacity',
    'shapeKind',
    'geometryType',
    'renderPass',
    'family',
    'shadowProfileId',
    'viewportSuggestion',
    'visualRiskBeforeScreenshot',
    'screenshotPath',
    'visualRiskAfterScreenshot',
    'recommendation',
    'reason',
  ];
  final lines = <String>[headers.join('\t')];
  for (final row in rows) {
    lines.add(headers.map((header) => '${row[header] ?? ''}').join('\t'));
  }
  return '${lines.join('\n')}\n';
}
```

### `/tmp/shadow62_capture_contact_ledges_test.dart`

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_sources.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shadow62 capture contact ledges', () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: '/Users/karim/Desktop/selbrume/project.json',
      mapId: 'Selbrume',
    );
    final tileImages = await loadTilesetImagesById(
      bundle.tilesetAbsolutePathsById,
      transparentColorByTilesetId: {
        for (final tileset in bundle.manifest.tilesets)
          if (tileset.transparentColor != null)
            tileset.id: tileset.transparentColor!,
      },
    );
    final shadows = buildRuntimeStaticPlacedElementShadowCollectionForBundle(
      bundle: bundle,
    );
    final layer = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImages,
      shadowCollectionProvider: () => shadows,
    );
    layer.update(0);

    final worldWidth = bundle.map.size.width * bundle.cellWidth;
    final worldHeight = bundle.map.size.height * bundle.cellHeight;
    final overviewScale = 0.25;
    await _renderCapture(
      layer,
      filePath:
          '/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_selbrume_overview.png',
      cropLeft: 0,
      cropTop: 0,
      outputWidth: (worldWidth * overviewScale).round(),
      outputHeight: (worldHeight * overviewScale).round(),
      scale: overviewScale,
    );

    final captures = [
      _CaptureSpec(1, 'selbrum_maison_3', 2449.12128, 1807.076352),
      _CaptureSpec(2, 'selbrum_maison_4', 1722.7008, 2193.494016),
      _CaptureSpec(3, 'selbrum_maison_1', 1050.7008, 2289.494016),
      _CaptureSpec(4, 'selbrume_centre_pok_mon', 2929.12128, 2673.494016),
      _CaptureSpec(5, 'selbrum_maison_7', 3756.84096, 2673.494016),
      _CaptureSpec(6, 'le_puits', 2280.56064, 3059.91168),
      _CaptureSpec(7, 'selbrum_maison_4', 3546.7008, 3345.494016),
      _CaptureSpec(8, 'selbrum_maison_2', 1068.84096, 3535.076352),
      _CaptureSpec(9, 'selbrum_maison_8', 1927.54176, 3729.494016),
      _CaptureSpec(10, 'kiosque_l_gumes', 3564.84096, 3921.494016),
    ];
    for (final capture in captures) {
      final cropLeft = (capture.instructionLeft - 260).clamp(0, worldWidth - 900);
      final cropTop = (capture.instructionTop - 430).clamp(0, worldHeight - 650);
      await _renderCapture(
        layer,
        filePath:
            '/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow62_contact_ledge_${capture.rank}_${capture.elementId}.png',
        cropLeft: cropLeft.toDouble(),
        cropTop: cropTop.toDouble(),
        outputWidth: 900,
        outputHeight: 650,
      );
      print(
        'capture rank=${capture.rank} element=${capture.elementId} cropLeft=${cropLeft.toStringAsFixed(1)} cropTop=${cropTop.toStringAsFixed(1)}',
      );
    }

    expect(shadows.groundStatic, hasLength(10));
  });
}

Future<void> _renderCapture(
  MapLayersComponent layer, {
  required String filePath,
  required double cropLeft,
  required double cropTop,
  required int outputWidth,
  required int outputHeight,
  double scale = 1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
    Paint()..color = const Color(0xFF000000),
  );
  canvas.save();
  canvas.scale(scale, scale);
  canvas.translate(-cropLeft, -cropTop);
  layer.render(canvas);
  canvas.restore();
  final image = await recorder.endRecording().toImage(outputWidth, outputHeight);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) {
    throw StateError('Could not encode PNG for $filePath');
  }
  await File(filePath).writeAsBytes(Uint8List.view(data.buffer));
  print('wrote $filePath');
}

final class _CaptureSpec {
  const _CaptureSpec(
    this.rank,
    this.elementId,
    this.instructionLeft,
    this.instructionTop,
  );

  final int rank;
  final String elementId;
  final double instructionLeft;
  final double instructionTop;
}
```

### `/tmp/shadow62_validate_selbrume_manifest_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';

void main() {
  test('shadow62 validate selbrume manifest', () async {
    final manifest = await loadProjectManifestFromFile(
      '/Users/karim/Desktop/selbrume/project.json',
    );
    expect(manifest.elements, hasLength(63));
    expect(manifest.elements.where((element) => element.shadow != null), hasLength(20));

    const cleanedIds = {
      'panneau',
      'lampadaire',
      'arbre_pixellab_1',
      'arbre_pixellab_2',
      'selbrume_maison_5',
    };
    for (final id in cleanedIds) {
      final element = manifest.elements.singleWhere((element) => element.id == id);
      expect(element.shadow, isNull, reason: '$id must remain cleaned by Shadow-59');
    }
  });
}
```
