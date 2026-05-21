# Shadow-63 — Building Contact Ledge Minimal Retune Design / Visual Delta Plan V0

## 1. Resume executif

Shadow-63 Design est termine en mode design-only. Le design gate d'`AGENTS.md` s'applique clairement aux changements visuels/product-facing, donc aucun code de production et aucun fichier Selbrume n'ont ete modifies.

Diagnostic pixel-based depuis Shadow-62: les 4 cas `retune-next` ne souffrent pas d'une largeur absurde ni d'un mauvais alignement; ils souffrent surtout d'une ledge trop epaisse/lisible sur sol clair, en particulier sur les chemins. Les 6 cas `keep` sont deja discrets ou partiellement masques.

Option recommandee pour le prochain lot: **retune height/depth minimal**, en changeant uniquement `buildingStaticShadowContactLedgeMaxDepth` de `20.0` a `14.0`. Cette option reduit la hauteur visible des ledges actuelles d'environ 6 px dans Selbrume sans toucher a la largeur, aux donnees, aux profils, au renderer, ni a `genericProjection`.

Prochain lot propose: **Shadow-64 Implementation — Building Contact Ledge Minimal Depth Retune V0**.

## 2. Rappel Shadow-62

Shadow-62 a produit 11 captures exploitables: une overview et 10 captures ciblees. Etat confirme par Shadow-62:

- `genericProjection = 0`.
- `static instructions = 10`.
- `contactLedge = 10`.
- `keep = 6`.
- `retune-next = 4`.
- `disable-next = 0`.
- `manual-review = 0`.
- `screenshot-needed = 0`.

Les grandes projections diagonales des arbres/panneau/lampadaire ont disparu. Les problemes restants sont localises et beaucoup plus fins: des bandes de contact encore visibles sur fonds clairs.

## 3. Decision AGENTS / design gate

Commandes:

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

`find`:

```
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

`rg`:

```
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Decision: le design gate bloque l'implementation dans ce lot. Le changement vise un comportement visuel product-facing; le rapport design doit etre valide avant tout patch. Donc Shadow-63 s'arrete au design et au prompt d'implementation suivant.

## 4. Etat initial du worktree

Commande:

```bash
git status --short --untracked-files=all
```

```
(aucune sortie)
```

## 5. Confirmation invariants Shadow-56 / 58 / 59

### Shadow-56 — runtime auto-apply absent

Commande:

```bash
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

```
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:431:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:127:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:129:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:154:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:179:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:207:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:232:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:270:      final result = applyElementAutoShadowPolicyToProject(
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
```

Conclusion: aucun appel dans `map_runtime`; les occurrences restantes sont la definition/tests core et le backfill editor explicite.

### Shadow-58 — policy durcie

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

Conclusion: `buildingLarge` reste le seul kind safe; `tallThin`, `wideLow`, `smallSquare`, `defaultProp` restent non-safe.

### Shadow-59 — cibles nettoyees

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

## 6. Inventaire des screenshots Shadow-62

Commandes:

```bash
ls -la reports/shadows/screenshots/ | rg "shadow62"
test -f reports/shadows/shadow_lot_62_contact_ledge_visual_index.tsv
find reports/shadows/screenshots -maxdepth 1 -type f -name "shadow62_*.png" -print
```

`ls`:

```
-rw-r--r--@  1 karim  staff   159151 May 17 23:41 shadow62_contact_ledge_10_kiosque_l_gumes.png
-rw-r--r--@  1 karim  staff   181017 May 17 23:41 shadow62_contact_ledge_1_selbrum_maison_3.png
-rw-r--r--@  1 karim  staff   168372 May 17 23:41 shadow62_contact_ledge_2_selbrum_maison_4.png
-rw-r--r--@  1 karim  staff   181985 May 17 23:41 shadow62_contact_ledge_3_selbrum_maison_1.png
-rw-r--r--@  1 karim  staff   162447 May 17 23:41 shadow62_contact_ledge_4_selbrume_centre_pok_mon.png
-rw-r--r--@  1 karim  staff   178307 May 17 23:41 shadow62_contact_ledge_5_selbrum_maison_7.png
-rw-r--r--@  1 karim  staff   146614 May 17 23:41 shadow62_contact_ledge_6_le_puits.png
-rw-r--r--@  1 karim  staff   151455 May 17 23:41 shadow62_contact_ledge_7_selbrum_maison_4.png
-rw-r--r--@  1 karim  staff   183186 May 17 23:41 shadow62_contact_ledge_8_selbrum_maison_2.png
-rw-r--r--@  1 karim  staff   159755 May 17 23:41 shadow62_contact_ledge_9_selbrum_maison_8.png
-rw-r--r--@  1 karim  staff  2531143 May 17 23:41 shadow62_selbrume_overview.png
```

Presence de l'index:

```
visual index present
```

`find`:

```
reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png
reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png
reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png
reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png
reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png
reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png
reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png
reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png
reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png
reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png
reports/shadows/screenshots/shadow62_selbrume_overview.png
```

Nombre de screenshots trouves: 11.

Mapping:

- overview: `shadow62_selbrume_overview.png`.
- keep: ranks 1, 3, 4, 6, 8, 9.
- retune-next: ranks 2, 5, 7, 10.

Index Shadow-62 complet:

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

## 7. Analyse visuelle par screenshot


| Rank | elementId | Shadow-62 | Background | Visibility | Width | Height | Position | Problem | Action |
|---:|---|---|---|---|---|---|---|---|---|
| 1 | `selbrum_maison_3` | keep | mixed | subtle | acceptable | acceptable | aligned | none; mostly hidden by fence/facade | keep |
| 2 | `selbrum_maison_4` | retune-next | path | visible | acceptable | too-thick | aligned | trapezoid band readable on light path | reduce-height |
| 3 | `selbrum_maison_1` | keep | mixed | subtle | acceptable | acceptable | aligned | short contact under facade | keep |
| 4 | `selbrume_centre_pok_mon` | keep | mixed | subtle | acceptable | acceptable | aligned | soft footing only | keep |
| 5 | `selbrum_maison_7` | retune-next | mixed | visible | acceptable | too-thick | aligned | visible band on light/grass edge | reduce-height |
| 6 | `le_puits` | keep | mixed | subtle | acceptable | acceptable | aligned | local under well body | keep |
| 7 | `selbrum_maison_4` | retune-next | path | too-visible | acceptable | too-thick | aligned | strip obvious on path | reduce-height |
| 8 | `selbrum_maison_2` | keep | mixed | subtle | acceptable | acceptable | aligned | mostly hidden by base/vegetation | keep |
| 9 | `selbrum_maison_8` | keep | mixed | subtle | acceptable | acceptable | aligned | footing under wide facade | keep |
| 10 | `kiosque_l_gumes` | retune-next | path | visible | acceptable | too-thick | aligned | band visible across pale path | reduce-height |


Table TSV produite pour ce lot:

```tsv
rank	elementId	elementName	screenshotPath	decisionShadow62	backgroundType	ledgeVisibility	ledgeWidthCategory	ledgeHeightCategory	ledgePositionQuality	visualProblem	recommendedAction
1	selbrum_maison_3	selbrum maison 3	reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; contact mostly hidden by fence/facade	keep
2	selbrum_maison_4	selbrum maison 4	reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png	retune-next	path	visible	acceptable	too-thick	aligned	trapezoid band remains readable on light path	reduce-height
3	selbrum_maison_1	selbrum maison 1	reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; short contact under facade	keep
4	selbrume_centre_pok_mon	selbrume centre pokemon	reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; visible only as soft footing	keep
5	selbrum_maison_7	selbrum maison 7	reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png	retune-next	mixed	visible	acceptable	too-thick	aligned	right-side contact reads as a band on light/grass edge	reduce-height
6	le_puits	le puits	reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; local under well body	keep
7	selbrum_maison_4	selbrum maison 4	reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png	retune-next	path	too-visible	acceptable	too-thick	aligned	horizontal/trapezoid strip is obvious on path	reduce-height
8	selbrum_maison_2	selbrum maison 2	reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; mostly hidden by building base and vegetation	keep
9	selbrum_maison_8	selbrum maison 8	reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; reads as footing under wide facade	keep
10	kiosque_l_gumes	kiosque a legumes	reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png	retune-next	path	visible	acceptable	too-thick	aligned	contact band remains visible across pale path	reduce-height
```

## 8. Synthese des 4 retune-next

Les 4 cas `retune-next` partagent un motif:

- ils sont sur fond clair ou mixte incluant un chemin;
- la ledge est alignee mais se lit comme une bande/trapeze;
- la largeur correspond au pied de facade, donc la largeur n'est pas le premier coupable;
- l'epaisseur verticale est le probleme dominant;
- l'opacite est a `0.2` partout, mais elle vient des configs authorees et non d'une constante contact ledge dediee.

Cas concernes:

- rank 2 `selbrum_maison_4`: bande trapezoidale sur chemin clair.
- rank 5 `selbrum_maison_7`: ledge visible sur herbe/chemin clair.
- rank 7 `selbrum_maison_4`: bande horizontale/trapezoidale evidente sur chemin.
- rank 10 `kiosque_l_gumes`: bande visible sur chemin clair.

Conclusion: le micro-retune le plus logique est une reduction de la profondeur/hauteur de la contact ledge, pas une modification globale de largeur ou de data.

## 9. Synthese des 6 keep

Les 6 `keep` sont acceptables parce qu'ils sont:

- discrets ou partiellement caches par la facade, la cloture, la vegetation, ou le pied de l'objet;
- courts;
- alignes avec le pied de l'asset;
- non lisibles comme grandes plaques diagonales.

Cas:

- `selbrum_maison_3`
- `selbrum_maison_1`
- `selbrume_centre_pok_mon`
- `le_puits`
- `selbrum_maison_2`
- `selbrum_maison_8`

Le futur retune ne doit pas les effacer. C'est pourquoi une reduction tres limitee de profondeur max est preferable a une baisse d'opacite forte ou une reduction de largeur globale.

## 10. Audit du code contact ledge

### Geometrie contact ledge

Fichier: `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`.

Extrait avec lignes:

```text
     1	import 'static_shadow_geometry.dart';
     2	import 'static_shadow_projection_geometry.dart';
     3	
     4	const buildingStaticShadowContactLedgeNearHalfWidthMultiplier = 0.72;
     5	const buildingStaticShadowContactLedgeFarHalfWidthMultiplier = 0.62;
     6	const buildingStaticShadowContactLedgeNearHeightOffsetMultiplier = 0.18;
     7	const buildingStaticShadowContactLedgeDepthRatio = 0.055;
     8	const buildingStaticShadowContactLedgeMinDepth = 6.0;
     9	const buildingStaticShadowContactLedgeMaxDepth = 20.0;
    10	const buildingStaticShadowContactLedgeSkewRatio = 0.020;
    11	const buildingStaticShadowContactLedgeMinSkew = 0.0;
    12	const buildingStaticShadowContactLedgeMaxSkew = 7.0;
    13	
    14	ProjectedStaticShadowGeometry resolveBuildingStaticShadowContactLedgeGeometry({
    15	  required ResolvedStaticShadowGeometry baseGeometry,
    16	  required StaticShadowVisualMetrics metrics,
    17	}) {
    18	  final centerX = baseGeometry.centerX;
    19	  final nearY = baseGeometry.centerY -
    20	      baseGeometry.height *
    21	          buildingStaticShadowContactLedgeNearHeightOffsetMultiplier;
    22	  final farY =
    23	      baseGeometry.centerY + _buildingStaticShadowContactLedgeDepth(metrics);
    24	  final nearHalfWidth = baseGeometry.width *
    25	      buildingStaticShadowContactLedgeNearHalfWidthMultiplier;
    26	  final farHalfWidth = baseGeometry.width *
    27	      buildingStaticShadowContactLedgeFarHalfWidthMultiplier;
    28	  final skewX = _buildingStaticShadowContactLedgeSkew(metrics);
    29	
    30	  return ProjectedStaticShadowGeometry(
    31	    nearLeft: ProjectedStaticShadowPoint(
    32	      x: centerX - nearHalfWidth,
    33	      y: nearY,
    34	    ),
    35	    nearRight: ProjectedStaticShadowPoint(
    36	      x: centerX + nearHalfWidth,
    37	      y: nearY,
    38	    ),
    39	    farRight: ProjectedStaticShadowPoint(
    40	      x: centerX + skewX + farHalfWidth,
    41	      y: farY,
    42	    ),
    43	    farLeft: ProjectedStaticShadowPoint(
    44	      x: centerX + skewX - farHalfWidth,
    45	      y: farY,
    46	    ),
    47	  );
    48	}
    49	
    50	double _buildingStaticShadowContactLedgeDepth(
    51	  StaticShadowVisualMetrics metrics,
    52	) {
    53	  return _clampDouble(
    54	    metrics.visualHeight * buildingStaticShadowContactLedgeDepthRatio,
    55	    buildingStaticShadowContactLedgeMinDepth,
    56	    buildingStaticShadowContactLedgeMaxDepth,
    57	  );
    58	}
    59	
    60	double _buildingStaticShadowContactLedgeSkew(
    61	  StaticShadowVisualMetrics metrics,
    62	) {
    63	  return _clampDouble(
    64	    metrics.visualWidth * buildingStaticShadowContactLedgeSkewRatio,
    65	    buildingStaticShadowContactLedgeMinSkew,
    66	    buildingStaticShadowContactLedgeMaxSkew,
    67	  );
    68	}
    69	
    70	double _clampDouble(double value, double min, double max) {
    71	  if (value < min) {
    72	    return min;
    73	  }
    74	  if (value > max) {
    75	    return max;
    76	  }
    77	  return value;
    78	}
```

Constantes importantes:

- Largeur: `buildingStaticShadowContactLedgeNearHalfWidthMultiplier = 0.72`, `buildingStaticShadowContactLedgeFarHalfWidthMultiplier = 0.62`.
- Position verticale proche: `buildingStaticShadowContactLedgeNearHeightOffsetMultiplier = 0.18`.
- Profondeur/hauteur: `buildingStaticShadowContactLedgeDepthRatio = 0.055`, `buildingStaticShadowContactLedgeMinDepth = 6.0`, `buildingStaticShadowContactLedgeMaxDepth = 20.0`.
- Skew: `buildingStaticShadowContactLedgeSkewRatio = 0.020`, min `0.0`, max `7.0`.

Analyse des 10 cas Selbrume: leurs hauteurs visuelles sont assez grandes pour que `metrics.visualHeight * 0.055` depasse le max de `20.0`. Donc `buildingStaticShadowContactLedgeMaxDepth` est le levier principal pour reduire les bandes visibles dans Selbrume.

### Source des configs authorees

Commande jq sur les 9 elementIds generateurs:

```tsv
selbrum_maison_1	selbrum maison 1	5	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_2	selbrum maison  2	6	7	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_3	selbrum maison 3	8	7	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_4	selbrum maison  4	5	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_7	selbrum maison  7	6	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_8	selbrum maison  8	11	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrume_centre_pok_mon	selbrume centre pokémon	8	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
le_puits	le puits	4	5	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
kiosque_l_gumes	kiosque à légumes	6	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
```

Tous les cas restants utilisent:

- `shadowProfileId = default-ground-wide-ellipse`
- `family = building`
- `opacity = 0.2`
- `scaleX = 0.72`
- `scaleY = 0.48`
- footprint width `0.6`
- footprint height `0.06`

### Passage en projectedPolygon runtime

Fichier: `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`.

Extrait:

```text
   120	    elementFootprint: legacyAndElementFootprint,
   121	    overrideFootprint: overrideFootprint,
   122	  );
   123	
   124	  return ShadowRuntimeAnchor(
   125	    worldX: geometry.anchorX,
   126	    worldY: geometry.anchorY,
   127	    baseWidth: geometry.baseWidth,
   128	    baseHeight: geometry.baseHeight,
   129	  );
   130	}
   131	
   132	ShadowRuntimeRenderInstruction?
   133	    resolveStaticPlacedElementShadowRuntimeInstruction(
   134	  StaticPlacedElementShadowRuntimeInput input,
   135	) {
   136	  final resolved = input.resolvedConfig;
   137	  if (resolved.mode == ShadowCasterMode.none) {
   138	    return null;
   139	  }
   140	  if (resolved.renderPass != ShadowRenderPass.groundStatic) {
   141	    throw const ValidationException(
   142	      'Static placed element shadow resolver requires groundStatic render pass',
   143	    );
   144	  }
   145	  if (resolved.mode != ShadowCasterMode.ellipse &&
   146	      resolved.mode != ShadowCasterMode.contactBlob) {
   147	    throw const ValidationException(
   148	      'Static placed element shadow resolver requires ellipse or contactBlob mode',
   149	    );
   150	  }
   151	
   152	  final baseGeometry = _resolveStaticPlacedElementBaseGeometry(input);
   153	  final family = resolveStaticShadowFamily(
   154	    elementFamily: input.elementFamily,
   155	    overrideFamily: input.overrideFamily,
   156	  );
   157	  if (family == StaticShadowFamily.building) {
   158	    return _resolveBuildingContactLedgeRuntimeInstruction(
   159	      input,
   160	      baseGeometry,
   161	    );
   162	  }
   163	
   164	  final projectedGeometry = resolveProjectedStaticShadowGeometry(
   165	    baseGeometry: baseGeometry,
   166	    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
   167	    projectionSpec: resolveStaticShadowFamilyProjectionSpec(
   168	      family: family,
   169	    ),
   170	  );
   171	  final points = _runtimePointsFromProjection(projectedGeometry);
   172	  final bounds = _boundsFromRuntimePoints(points);
   173	
   174	  return ShadowRuntimeRenderInstruction(
   175	    shape: ShadowRuntimeShapeKind.projectedPolygon,
   176	    renderPass: resolved.renderPass,
   177	    worldLeft: bounds.left,
   178	    worldTop: bounds.top,
   179	    width: bounds.width,
   180	    height: bounds.height,
   181	    opacity: resolved.opacity,
   182	    colorHexRgb: resolved.colorHexRgb,
   183	    softnessMode: resolved.softnessMode,
   184	    polygonPoints: points,
   185	  );
   186	}
   187	
   188	List<ShadowRuntimeRenderInstruction>
   189	    resolveStaticPlacedElementShadowRuntimeInstructions(
   190	  Iterable<StaticPlacedElementShadowRuntimeInput> inputs,
   191	) {
   192	  final instructions = <ShadowRuntimeRenderInstruction>[];
   193	  for (final input in inputs) {
   194	    final instruction =
   195	        resolveStaticPlacedElementShadowRuntimeInstruction(input);
   196	    if (instruction != null) {
   197	      instructions.add(instruction);
   198	    }
   199	  }
   200	  return List<ShadowRuntimeRenderInstruction>.unmodifiable(instructions);
   201	}
   202	
   203	ShadowRuntimeRenderInstruction _resolveBuildingContactLedgeRuntimeInstruction(
   204	  StaticPlacedElementShadowRuntimeInput input,
   205	  ResolvedStaticShadowGeometry baseGeometry,
   206	) {
   207	  final ledgeGeometry = resolveBuildingStaticShadowContactLedgeGeometry(
   208	    baseGeometry: baseGeometry,
   209	    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
   210	  );
   203	ShadowRuntimeRenderInstruction _resolveBuildingContactLedgeRuntimeInstruction(
   204	  StaticPlacedElementShadowRuntimeInput input,
   205	  ResolvedStaticShadowGeometry baseGeometry,
   206	) {
   207	  final ledgeGeometry = resolveBuildingStaticShadowContactLedgeGeometry(
   208	    baseGeometry: baseGeometry,
   209	    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
   210	  );
   211	  final points = _runtimePointsFromProjection(ledgeGeometry);
   212	  final bounds = _boundsFromRuntimePoints(points);
   213	  return ShadowRuntimeRenderInstruction(
   214	    shape: ShadowRuntimeShapeKind.projectedPolygon,
   215	    renderPass: input.resolvedConfig.renderPass,
   216	    worldLeft: bounds.left,
   217	    worldTop: bounds.top,
   218	    width: bounds.width,
   219	    height: bounds.height,
   220	    opacity: input.resolvedConfig.opacity,
   221	    colorHexRgb: input.resolvedConfig.colorHexRgb,
   222	    softnessMode: input.resolvedConfig.softnessMode,
   223	    polygonPoints: points,
   224	  );
   225	}
   226	
   227	void _validateFinite(double value, String name) {
   228	  if (!value.isFinite) {
   229	    throw ValidationException(
   230	      'StaticPlacedElementShadowRuntimeMetrics.$name must be finite',
```

Le runtime choisit la branche contact ledge si `family == StaticShadowFamily.building`, puis renvoie tout de meme une instruction `ShadowRuntimeShapeKind.projectedPolygon`. C'est normal dans l'architecture actuelle: `projectedPolygon` est le shape runtime, `contactLedge` est le type logique reconstruit par family/geometry.

L'opacite runtime vient de `input.resolvedConfig.opacity`, donc des configs/profils resolves, pas du fichier contact ledge.

### Preview editor

Fichier: `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`.

Extrait:

```text
   130	  final visibleTileLayerById = <String, TileLayer>{
   131	    for (final layer in map.layers.whereType<TileLayer>())
   132	      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
   133	  };
   134	  if (elementById.isEmpty || visibleTileLayerById.isEmpty) {
   135	    return const <EditorStaticShadowPreviewInstruction>[];
   136	  }
   137	
   138	  final instructions = <EditorStaticShadowPreviewInstruction>[];
   139	  final resolvedLightPreviewPreset =
   140	      lightPreviewPreset ?? neutralEditorShadowLightPreviewPreset;
   141	  for (final placed in map.placedElements) {
   142	    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
   143	      continue;
   144	    }
   145	    final element = elementById[placed.elementId.trim()];
   146	    if (element == null || element.frames.isEmpty) {
   147	      continue;
   148	    }
   149	    final source = element.frames.first.source;
   150	    if (source.width <= 0 || source.height <= 0) {
   151	      continue;
   152	    }
   153	
   154	    final resolution = resolveShadowConfig(
   155	      catalog: manifest.shadowCatalog,
   156	      elementShadow: element.shadow,
   157	      placedOverride: placed.shadowOverride,
   158	    );
   159	    final resolved = resolution.resolved;
   160	    if (resolved == null ||
   161	        resolved.renderPass != ShadowRenderPass.groundStatic ||
   162	        resolved.mode == ShadowCasterMode.none) {
   163	      continue;
   164	    }
   165	
   166	    final visualWidth = source.width * tileWidth;
   167	    final visualHeight = source.height * tileHeight;
   168	    final baseLeft = placed.pos.x * tileWidth;
   169	    final baseTop = placed.pos.y * tileHeight;
   170	    final metrics = StaticShadowVisualMetrics(
   171	      left: baseLeft,
   172	      top: baseTop,
   173	      visualWidth: visualWidth,
   174	      visualHeight: visualHeight,
   175	    );
   176	    final geometry = resolveStaticShadowGeometry(
   177	      metrics: metrics,
   178	      shadowConfig: resolved,
   179	      elementFootprint: element.shadow?.footprint,
   180	      overrideFootprint: placed.shadowOverride?.footprint,
   181	    );
   182	    final family = resolveStaticShadowFamily(
   183	      elementFamily: element.shadow?.family,
   184	      overrideFamily: placed.shadowOverride?.family,
   185	    );
   186	    final projectedGeometry = family == StaticShadowFamily.building
   187	        ? resolveBuildingStaticShadowContactLedgeGeometry(
   188	            baseGeometry: geometry,
   189	            metrics: metrics,
   190	          )
   191	        : resolveProjectedStaticShadowGeometry(
   192	            baseGeometry: geometry,
   193	            metrics: metrics,
   194	            projectionSpec: resolveStaticShadowFamilyProjectionSpec(
   195	              family: family,
   196	              baseProjectionSpec: _projectionSpecForEditorLightPreview(
   197	                resolvedLightPreviewPreset,
   198	              ),
   199	            ),
   200	          );
   201	    final points = _editorPreviewPointsFromProjection(projectedGeometry);
   202	    final bounds = _boundsFromEditorPreviewPoints(points);
   203	
   204	    instructions.add(
   205	      EditorStaticShadowPreviewInstruction(
```

La preview editor utilise la meme fonction `resolveBuildingStaticShadowContactLedgeGeometry` pour `StaticShadowFamily.building`, ce qui est sain: un retune core de la geometrie sera visible aussi en preview editor.

### Tests existants

Fichier: `packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart`.

Extrait:

```text
     1	import 'package:map_core/map_core.dart';
     2	import 'package:test/test.dart';
     3	
     4	void main() {
     5	  group('building static shadow contact ledge constants', () {
     6	    test('defaults match Shadow-54 visible contact tuning', () {
     7	      expect(buildingStaticShadowContactLedgeNearHalfWidthMultiplier, 0.72);
     8	      expect(buildingStaticShadowContactLedgeFarHalfWidthMultiplier, 0.62);
     9	      expect(buildingStaticShadowContactLedgeNearHeightOffsetMultiplier, 0.18);
    10	      expect(buildingStaticShadowContactLedgeDepthRatio, 0.055);
    11	      expect(buildingStaticShadowContactLedgeMinDepth, 6);
    12	      expect(buildingStaticShadowContactLedgeMaxDepth, 20);
    13	      expect(buildingStaticShadowContactLedgeSkewRatio, 0.020);
    14	      expect(buildingStaticShadowContactLedgeMinSkew, 0);
    15	      expect(buildingStaticShadowContactLedgeMaxSkew, 7);
    16	    });
    17	  });
    18	
    19	  group('resolveBuildingStaticShadowContactLedgeGeometry', () {
    20	    test('creates a shallow four point contact ledge', () {
    21	      final metrics = StaticShadowVisualMetrics(
    22	        left: 160,
    23	        top: 96,
    24	        visualWidth: 192,
    25	        visualHeight: 224,
    26	      );
    27	      final base = resolveStaticShadowGeometry(
    28	        metrics: metrics,
    29	        shadowConfig: _shadowConfig(scaleX: 0.72, scaleY: 0.44),
    30	        elementFootprint: StaticShadowFootprintConfig(
    31	          anchorXRatio: 0.5,
    32	          anchorYRatio: 0.92,
    33	          footprintWidthRatio: 0.6,
    34	          footprintHeightRatio: 0.08,
    35	        ),
    36	      );
    37	
    38	      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
    39	        baseGeometry: base,
    40	        metrics: metrics,
    41	      );
    42	
    43	      expect(geometry.points, hasLength(4));
    44	      expect(geometry.nearLeft.y, closeTo(geometry.nearRight.y, 0.000001));
    45	      expect(geometry.farLeft.y, closeTo(geometry.farRight.y, 0.000001));
    46	      expect(geometry.farLeft.y, greaterThan(geometry.nearLeft.y));
    47	      expect(geometry.farRight.y, greaterThan(geometry.nearRight.y));
    48	      expect(_bounds(geometry).height, greaterThan(13));
    49	      expect(_bounds(geometry).height, lessThan(15));
    50	      expect(_bounds(geometry).width, greaterThan(118));
    51	      expect(_bounds(geometry).width, lessThan(121));
    52	    });
    53	
    54	    test('matches the Shadow-54 runtime formula exactly', () {
    55	      final metrics = StaticShadowVisualMetrics(
    56	        left: 160,
    57	        top: 96,
    58	        visualWidth: 192,
    59	        visualHeight: 224,
    60	      );
    61	      final base = resolveStaticShadowGeometry(
    62	        metrics: metrics,
    63	        shadowConfig: _shadowConfig(scaleX: 0.72, scaleY: 0.44),
    64	        elementFootprint: StaticShadowFootprintConfig(
    65	          anchorXRatio: 0.5,
    66	          anchorYRatio: 0.92,
    67	          footprintWidthRatio: 0.6,
    68	          footprintHeightRatio: 0.08,
    69	        ),
    70	      );
    71	
    72	      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
    73	        baseGeometry: base,
    74	        metrics: metrics,
    75	      );
    76	
    77	      final depth = _clamp(metrics.visualHeight * 0.055, 6, 20);
    78	      final skew = _clamp(metrics.visualWidth * 0.020, 0, 7);
    79	      expect(geometry.nearLeft.x,
    80	          closeTo(base.centerX - base.width * 0.72, 0.000001));
    81	      expect(geometry.nearLeft.y,
    82	          closeTo(base.centerY - base.height * 0.18, 0.000001));
    83	      expect(geometry.nearRight.x,
    84	          closeTo(base.centerX + base.width * 0.72, 0.000001));
    85	      expect(geometry.nearRight.y,
    86	          closeTo(base.centerY - base.height * 0.18, 0.000001));
    87	      expect(geometry.farRight.x,
    88	          closeTo(base.centerX + skew + base.width * 0.62, 0.000001));
    89	      expect(geometry.farRight.y, closeTo(base.centerY + depth, 0.000001));
    90	      expect(geometry.farLeft.x,
    91	          closeTo(base.centerX + skew - base.width * 0.62, 0.000001));
    92	      expect(geometry.farLeft.y, closeTo(base.centerY + depth, 0.000001));
    93	    });
    94	
    95	    test('uses base footprint width', () {
    96	      final metrics = _metrics();
    97	      final narrow = resolveBuildingStaticShadowContactLedgeGeometry(
    98	        baseGeometry: _base(metrics, footprintWidthRatio: 0.25),
    99	        metrics: metrics,
   100	      );
   101	      final wide = resolveBuildingStaticShadowContactLedgeGeometry(
   102	        baseGeometry: _base(metrics, footprintWidthRatio: 0.75),
   103	        metrics: metrics,
   104	      );
   105	
   106	      expect(_bounds(narrow).width, lessThan(_bounds(wide).width));
   107	    });
   108	
   109	    test('applies offset and scale only through base geometry', () {
   110	      final metrics = _metrics();
   111	      final base = resolveStaticShadowGeometry(
   112	        metrics: metrics,
   113	        shadowConfig: _shadowConfig(
   114	          offsetX: 5,
   115	          offsetY: 7,
   116	          scaleX: 2,
   117	          scaleY: 0.5,
   118	        ),
   119	        elementFootprint: StaticShadowFootprintConfig(
   120	          footprintWidthRatio: 0.5,
   121	          footprintHeightRatio: 0.2,
   122	        ),
   123	      );
   124	
   125	      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
   126	        baseGeometry: base,
   127	        metrics: metrics,
   128	      );
   129	
   130	      final nearCenterX = (geometry.nearLeft.x + geometry.nearRight.x) / 2;
   131	      expect(nearCenterX, closeTo(base.centerX, 0.000001));
   132	      expect(_bounds(geometry).width, greaterThan(base.width));
   133	      expect(_bounds(geometry).height, greaterThan(7));
   134	      expect(_bounds(geometry).height, lessThan(9));
   135	    });
   136	
   137	    test('clamps minimum and maximum depth', () {
   138	      final small = _metrics(visualHeight: 24);
   139	      final large = _metrics(visualHeight: 800);
   140	
```

Les tests couvrent les constantes, la formule exacte, la hauteur/largeur, le clamp min/max depth, le skew et l'immutabilite. Le futur lot devra adapter les assertions liees a `MaxDepth` et aux bounds de hauteur.

## 11. Options de retune comparees


| Option | Retune | Fit with evidence | Pros | Risks | Decision |
|---|---|---|---|---|---|
| A | Opacity-only, e.g. `0.20 -> 0.14/0.16` | Weak: opacity comes from authored data/current resolved config, not contact ledge geometry. | Could soften path bands. | Requires data/profile/runtime multiplier; may erase acceptable grass ledges; not the smallest core geometry change. | Reject for Shadow-64. |
| B | Height/depth minimal: reduce only contact ledge maximum depth, proposed `20.0 -> 14.0` | Strong: all 4 problem cases are too thick on light paths, width/alignment are acceptable. | One constant, no data changes, no profile changes, no genericProjection changes. | If too low, some keep cases may become too subtle; must regenerate screenshots. | Recommended. |
| C | Width + height conservative, e.g. near/far half-width and max depth | Medium: path bands would shrink more. | More visible improvement if B is insufficient. | Larger blast radius; may hurt wide facades and already-keep cases. | Defer unless B fails. |
| D | Data-specific disable for outliers | Weak for V0: no contact ledge is clearly absurd after Shadow-62. | Zero impact on accepted houses. | Avoids fixing common path visibility; data churn; kiosk/house special casing. | Reject for now. |


## 12. Option recommandee

Option recommandee: **Option B — Height/depth minimal**, version ultra ciblee:

```dart
const buildingStaticShadowContactLedgeMaxDepth = 14.0;
```

Conserver dans un premier temps:

```dart
buildingStaticShadowContactLedgeNearHalfWidthMultiplier = 0.72
buildingStaticShadowContactLedgeFarHalfWidthMultiplier = 0.62
buildingStaticShadowContactLedgeNearHeightOffsetMultiplier = 0.18
buildingStaticShadowContactLedgeDepthRatio = 0.055
buildingStaticShadowContactLedgeMinDepth = 6.0
buildingStaticShadowContactLedgeSkewRatio = 0.020
buildingStaticShadowContactLedgeMaxSkew = 7.0
```

Pourquoi `14.0`:

- Les 10 ledges Shadow-62 ont une hauteur autour de `22.49` a `23.48` px.
- La profondeur est actuellement clamped a `20.0`, donc changer `MaxDepth` est le plus petit levier qui agit sur tous les cas visibles.
- `14.0` reduit la profondeur max d'environ 30%, et la hauteur finale visible d'environ 25-26% selon les cas.
- La largeur et l'alignement restent identiques, ce qui protege les 6 cas `keep`.
- Aucun changement de donnees Selbrume, profil, runtime renderer ou policy.

Pourquoi pas opacity-only:

- `opacity = 0.2` vient des configs authorees visibles dans `project.json`.
- Une baisse d'opacite globale demanderait un patch de donnees/profil ou un nouveau multiplicateur runtime/core, ce qui serait plus invasif que la reduction de profondeur.

Pourquoi pas width+height tout de suite:

- La largeur est acceptable sur les 10 captures; c'est l'epaisseur sur path qui attire l'oeil.
- Toucher la largeur pourrait degrader les grands batiments deja acceptables.

## 13. Risques / reserves

- Un maxDepth a `14.0` peut rendre certains contacts trop subtils sur herbe. C'est acceptable comme risque si le lot Shadow-64 regenere exactement les captures before/after.
- Les captures Shadow-62 sont offscreen map-layer, pas des captures du host macOS complet. Elles sont cependant adaptees au sujet: elles montrent les pixels de map et les shadows rendues par `MapLayersComponent`.
- Le renderer continue d'appeler la shape `projectedPolygon` pour les contact ledges. Ce design ne change pas cette architecture.
- Si Shadow-64 montre encore des bandes visibles, le lot suivant pourra envisager une baisse legere de largeur ou un patch data cible, mais pas avant preuve.

## 14. Captures before/after requises pour implementation

Before existantes a reutiliser:

- `reports/shadows/screenshots/shadow62_selbrume_overview.png`
- `reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png`
- `reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png`
- `reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png`
- `reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png`
- `reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png`
- `reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png`
- `reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png`
- `reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png`
- `reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png`
- `reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png`

After a produire dans Shadow-64:

- `reports/shadows/screenshots/shadow64_selbrume_overview.png`
- `reports/shadows/screenshots/shadow64_contact_ledge_1_selbrum_maison_3.png`
- `reports/shadows/screenshots/shadow64_contact_ledge_2_selbrum_maison_4.png`
- `reports/shadows/screenshots/shadow64_contact_ledge_3_selbrum_maison_1.png`
- `reports/shadows/screenshots/shadow64_contact_ledge_4_selbrume_centre_pok_mon.png`
- `reports/shadows/screenshots/shadow64_contact_ledge_5_selbrum_maison_7.png`
- `reports/shadows/screenshots/shadow64_contact_ledge_6_le_puits.png`
- `reports/shadows/screenshots/shadow64_contact_ledge_7_selbrum_maison_4.png`
- `reports/shadows/screenshots/shadow64_contact_ledge_8_selbrum_maison_2.png`
- `reports/shadows/screenshots/shadow64_contact_ledge_9_selbrum_maison_8.png`
- `reports/shadows/screenshots/shadow64_contact_ledge_10_kiosque_l_gumes.png`

Criteres de comparaison:

- Les 4 `retune-next` Shadow-62 doivent devenir `low` ou `keep-provisional`.
- Les 6 `keep` restent acceptables.
- `genericProjection` reste a 0.
- Nombre d'instructions statiques reste 10.
- Aucun nouvel element ne recoit d'ombre.
- Aucune grande projection diagonale ne revient.

## 15. Tests a prevoir

Commandes exactes pour Shadow-64:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_contact_ledge_geometry_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

Tests a adapter/creer:

- Adapter `building static shadow contact ledge constants defaults match ...` pour `MaxDepth = 14.0`.
- Adapter le test `creates a shallow four point contact ledge` pour les nouvelles bornes de hauteur.
- Adapter `matches the ... runtime formula exactly` pour le nouveau max depth.
- Adapter `clamps minimum and maximum depth` pour attendre `14.0` sur les grands visuels.
- Verifier editor preview: les tests qui attendent une ledge building peuvent changer si les bounds exacts sont assertes.

## 16. Fichiers probablement touches au lot suivant

- `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`
- `packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart`
- Potentiellement tests runtime/editor si des attentes de bounds exactes dependent de la geometrie.
- Rapport Shadow-64.
- Captures after Shadow-64 sous `reports/shadows/screenshots/`.

## 17. Fichiers interdits au lot suivant

- `/Users/karim/Desktop/selbrume/project.json`
- `/Users/karim/Desktop/selbrume/maps/Selbrume.json`
- `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`
- `packages/map_core/lib/src/operations/element_auto_shadow_policy.dart`
- `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`
- profils Shadow globaux, codecs, models, assets, renderer, UI.

## 18. git diff --stat

Commande:

```bash
git diff --stat
```

```
(aucune sortie)
```

## 19. git diff --name-status

Commande:

```bash
git diff --name-status
```

```
(aucune sortie)
```

## 20. git diff --check

Commande:

```bash
git diff --check
```

```
(aucune sortie)
```

## 21. git status final

Commande:

```bash
git status --short --untracked-files=all
```

```
?? reports/shadows/shadow_lot_63_building_contact_ledge_minimal_retune_design.md
?? reports/shadows/shadow_lot_63_contact_ledge_measurements.tsv
```

## 22. Auto-critique

La recommandation est volontairement stricte: une seule constante, pas de retune combine. C'est probablement moins spectaculaire qu'une baisse d'opacite + width + height, mais c'est mieux pour isoler l'effet. La faiblesse du plan est que `14.0` reste une valeur de design empirique; elle devra etre validee par captures after, pas par conviction. Si elle ne suffit pas, le prochain ajustement devra etre documente comme un deuxieme palier, pas empile dans Shadow-64.

## 23. Regard critique sur le prompt

Le prompt est bien calibre: il force la relecture des captures et bloque les modifications visuelles avant design. Le point le plus important est l'ordre des priorites: micro-retune global seulement si les 4 medium partagent un probleme commun. C'est le cas ici: epaisseur visible sur fonds clairs.

## 24. Prompt propose pour Shadow-64 Implementation

```md

# Shadow-64 Implementation — Building Contact Ledge Minimal Depth Retune V0

Tu travailles dans `/Users/karim/Project/pokemonProject`.

Design validé attendu: Shadow-63 recommande un retune minimal height/depth-only des contact ledges building.

Objectif:
- Réduire la visibilité des 4 contact ledges `retune-next` de Shadow-62 sur chemins clairs.
- Préserver les 6 contact ledges `keep`.
- Ne pas modifier Selbrume.
- Ne pas modifier la policy auto-shadow.
- Ne pas modifier genericProjection.
- Ne pas modifier le renderer.

Changement attendu:
- Dans `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`, modifier uniquement `buildingStaticShadowContactLedgeMaxDepth` de `20.0` à `14.0`.
- Ne pas changer width, skew, minDepth, opacity, profiles, data, policy.
- Adapter les tests de `static_shadow_contact_ledge_geometry_test.dart` pour la nouvelle constante et les nouvelles bornes de hauteur.

Verification attendue:
- `cd packages/map_core && dart test test/shadow/static_shadow_contact_ledge_geometry_test.dart`
- `cd packages/map_core && dart test test/shadow`
- `cd packages/map_runtime && flutter test test/shadow`
- `cd packages/map_editor && flutter test test/application/shadow`
- `cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart`
- Regenerer les captures after en reprenant le probe Shadow-62, sans créer de harness permanent.

Critères visuels:
- `genericProjection` reste à 0.
- `static instructions` reste à 10.
- Les 4 `retune-next` deviennent `low` ou `keep-provisional`.
- Les 6 `keep` restent acceptables.
- Aucune grande projection diagonale ne revient.
```

## File inventory

### Created text files

- `reports/shadows/shadow_lot_63_building_contact_ledge_minimal_retune_design.md`
- `reports/shadows/shadow_lot_63_contact_ledge_measurements.tsv`

### Modified tracked files

Aucun.

### Deleted files

Aucun.

### Selbrume files modified

Aucun.

### Complete contents of created text files

#### `reports/shadows/shadow_lot_63_contact_ledge_measurements.tsv`

```tsv
rank	elementId	elementName	screenshotPath	decisionShadow62	backgroundType	ledgeVisibility	ledgeWidthCategory	ledgeHeightCategory	ledgePositionQuality	visualProblem	recommendedAction
1	selbrum_maison_3	selbrum maison 3	reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; contact mostly hidden by fence/facade	keep
2	selbrum_maison_4	selbrum maison 4	reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png	retune-next	path	visible	acceptable	too-thick	aligned	trapezoid band remains readable on light path	reduce-height
3	selbrum_maison_1	selbrum maison 1	reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; short contact under facade	keep
4	selbrume_centre_pok_mon	selbrume centre pokemon	reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; visible only as soft footing	keep
5	selbrum_maison_7	selbrum maison 7	reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png	retune-next	mixed	visible	acceptable	too-thick	aligned	right-side contact reads as a band on light/grass edge	reduce-height
6	le_puits	le puits	reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; local under well body	keep
7	selbrum_maison_4	selbrum maison 4	reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png	retune-next	path	too-visible	acceptable	too-thick	aligned	horizontal/trapezoid strip is obvious on path	reduce-height
8	selbrum_maison_2	selbrum maison 2	reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; mostly hidden by building base and vegetation	keep
9	selbrum_maison_8	selbrum maison 8	reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png	keep	mixed	subtle	acceptable	acceptable	aligned	none; reads as footing under wide facade	keep
10	kiosque_l_gumes	kiosque a legumes	reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png	retune-next	path	visible	acceptable	too-thick	aligned	contact band remains visible across pale path	reduce-height
```

Le rapport lui-meme n'est pas recopie recursivement dans cette section.
