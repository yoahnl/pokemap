# Shadow-60 — Selbrume Post-Cleanup Verification / Remaining Static Shadows Decision

## 1. Résumé exécutif

Shadow-60 est un audit post-cleanup strictement read-only. Aucun fichier Selbrume, aucun code, aucun renderer, aucune policy, aucun profil et aucune géométrie Shadow n'ont été modifiés.

Résultat principal : Shadow-59 est confirmé. Les 5 cibles ont `shadow == null`, `genericProjection` tombe à `0`, les arbres/panneau/lampadaire/maison ciblée ne génèrent plus d'instruction runtime, et il reste `10` instructions statiques runtime, toutes de type `building/contactLedge`.

Décision recommandée : ne pas relancer une calibration générale. Le prochain lot devrait être un lot visuel contrôlé sur les contact ledges restants : `Shadow-61 — Selbrume Building Contact Ledge Visual Review / Minimal Retune Decision`. Le lot doit partir d'une capture après Shadow-59/60 et décider si les 10 contact ledges sont acceptables, trop visibles, ou à désactiver/retuner élément par élément.

## 2. Rappel Shadow-56 / 57 / 58 / 59

- Shadow-56 : suppression du runtime auto-apply. Le runtime consomme le manifest authoré.
- Shadow-57 : audit montrant 111 instructions statiques avant cleanup, dont 97 `genericProjection` et 95 issues des deux arbres.
- Shadow-58 : durcissement de la policy auto-shadow ; seul `buildingLarge` reste safe.
- Shadow-59 : patch data Selbrume sur 5 éléments : `panneau`, `lampadaire`, `arbre_pixellab_1`, `arbre_pixellab_2`, `selbrume_maison_5`.

## 3. Nature audit-only du lot

Ce lot a seulement lu :

```text
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/project.shadow59.before.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Livrable permanent créé :

```text
reports/shadows/shadow_lot_60_selbrume_post_cleanup_verification_remaining_static_shadows.md
```

Aucun script temporaire n'a été conservé dans le repo.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Commande :

```bash
find .. -name AGENTS.md -print
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

## 5. Hashes Selbrume initiaux

Commande :

```bash
shasum -a 256 /Users/karim/Desktop/selbrume/project.json /Users/karim/Desktop/selbrume/maps/Selbrume.json /Users/karim/Desktop/selbrume/project.shadow59.before.json
```

Sortie :

```text
3c3669a8274e31087b617fd46337c28aef6593f376a7d0a54c2d9fb8e31b389d  /Users/karim/Desktop/selbrume/project.json
8fd1f7efdc02413106a21068e3af310b3149c07023cfad64ddaa101f2c2cac63  /Users/karim/Desktop/selbrume/maps/Selbrume.json
d3784bcb94ff1267bacd7bd46e902038389a601f023a981e840a92a8fba7efb5  /Users/karim/Desktop/selbrume/project.shadow59.before.json
```

Les hashes ont été relus après les tests et restent identiques.

## 6. Confirmation runtime auto-apply absent

Commande :

```bash
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

Sortie :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:127:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:129:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:154:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:179:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:207:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:232:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:270:      final result = applyElementAutoShadowPolicyToProject(
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:431:      final coreResult = applyElementAutoShadowPolicyToProject(project);
```

Conclusion : aucun appel dans `packages/map_runtime`. La policy existe dans `map_core` et reste appelée explicitement par l'editor backfill.

## 7. Confirmation policy Shadow-58 active

Commande :

```bash
rg -n "_autoShadowKindIsArtisticallySafe|case ElementAutoShadowSuggestionKind.buildingLarge|case ElementAutoShadowSuggestionKind.tallThin|case ElementAutoShadowSuggestionKind.wideLow|case ElementAutoShadowSuggestionKind.smallSquare|case ElementAutoShadowSuggestionKind.defaultProp" packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
```

Sortie :

```text
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

Extrait vérifié :

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

Conclusion : `buildingLarge` est le seul kind safe ; `tallThin`, `wideLow`, `smallSquare` et `defaultProp` retournent `false`.

## 8. Confirmation Shadow-59 appliqué

Commande :

```bash
jq -r '([.elements[] | select(.shadow != null)] | length), ([.elements[] | select(.shadow == null)] | length), (.elements | length)' /Users/karim/Desktop/selbrume/project.json
```

Sortie :

```text
20
43
63
```

Commande :

```bash
jq -r '.elements[] | select(.id=="panneau" or .id=="lampadaire" or .id=="arbre_pixellab_1" or .id=="arbre_pixellab_2" or .id=="selbrume_maison_5") | [.id, .name, (.shadow == null)] | @tsv' /Users/karim/Desktop/selbrume/project.json
```

Sortie :

```text
selbrume_maison_5	selbrume maison 5	true
lampadaire	lampadaire	true
arbre_pixellab_1	arbre  pixelLab 1	true
arbre_pixellab_2	arbre  pixelLab 2	true
panneau	panneau	true
```

Conclusion : les 5 cibles Shadow-59 sont bien neutralisées.

## 9. Inventaire des éléments restants avec Shadow

Commande :

```bash
jq -r '.elements[] | select(.shadow != null) | [.id, .name, (.frames[0].source.width // "?"), (.frames[0].source.height // "?"), (.shadow.castsShadow // "null"), (.shadow.shadowProfileId // "null"), (.shadow.family // "null"), (.shadow.opacity // "null"), (.shadow.scaleX // "null"), (.shadow.scaleY // "null"), (.shadow.footprint.anchorXRatio // "null"), (.shadow.footprint.anchorYRatio // "null"), (.shadow.footprint.footprintWidthRatio // "null"), (.shadow.footprint.footprintHeightRatio // "null")] | @tsv' /Users/karim/Desktop/selbrume/project.json
```

Sortie complète :

```text
test_maison_pkm	test maison pkm	6	7	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
test	test	45	33	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
custom_cliff_selbrume	custom cliff  selbrume	3	13	true	default-ground-contact-blob	tallProp	0.2	0.8	0.55	0.5	1.0	0.28	0.05
selbrum_maison_1	selbrum maison 1	5	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_2	selbrum maison  2	6	7	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_3	selbrum maison 3	8	7	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_4	selbrum maison  4	5	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_7	selbrum maison  7	6	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_8	selbrum maison  8	11	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
objectif	objectif	45	33	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrume_centre_pok_mon	selbrume centre pokémon	8	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrume_maison_6	selbrume maison 6	6	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
le_puits	le puits	4	5	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
kiosque_l_gumes	kiosque à légumes	6	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
for_t_1	forêt 1	25	11	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
barri_re_pierre	barrière pierre	13	6	true	default-ground-wide-ellipse	compactProp	0.2	0.74	0.5	0.5	0.98	0.58	0.06
parasol	parasol	4	4	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
rock_cliff_1	rock cliff 1	3	4	true	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
rock_cliff_2	rock cliff  2	7	2	true	default-ground-wide-ellipse	compactProp	0.2	0.74	0.5	0.5	0.98	0.58	0.06
rock_cliff_3	rock cliff  3	9	3	true	default-ground-wide-ellipse	compactProp	0.2	0.74	0.5	0.5	0.98	0.58	0.06
```

Table enrichie avec placements runtime visibles :

```text
elementId	name	frameWidth	frameHeight	family	profile	opacity	scale	footprint	recursivePlacementCount	runtimeVisiblePlacementCount	risk	recommendation
test_maison_pkm	test maison pkm	6	7	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	0	0	none-in-runtime	ignore-not-placed
test	test	45	33	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	1	0	none-in-runtime	ignore-not-placed
custom_cliff_selbrume	custom cliff  selbrume	3	13	tallProp	default-ground-contact-blob	0.2	0.8/0.55	anchor=(0.5,1.0) size=(0.28,0.05)	0	0	none-in-runtime	ignore-not-placed
selbrum_maison_1	selbrum maison 1	5	6	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	1	1	contact-ledge-visible-check	keep
selbrum_maison_2	selbrum maison  2	6	7	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	1	1	contact-ledge-visible-check	keep
selbrum_maison_3	selbrum maison 3	8	7	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	1	1	contact-ledge-visible-check	keep
selbrum_maison_4	selbrum maison  4	5	6	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	2	2	contact-ledge-visible-check	keep
selbrum_maison_7	selbrum maison  7	6	6	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	1	1	contact-ledge-visible-check	keep
selbrum_maison_8	selbrum maison  8	11	6	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	1	1	contact-ledge-visible-check	keep
objectif	objectif	45	33	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	0	0	none-in-runtime	ignore-not-placed
selbrume_centre_pok_mon	selbrume centre pokémon	8	6	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	1	1	contact-ledge-visible-check	keep
selbrume_maison_6	selbrume maison 6	6	6	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	0	0	none-in-runtime	ignore-not-placed
le_puits	le puits	4	5	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	1	1	contact-ledge-visible-check	manual-review
kiosque_l_gumes	kiosque à légumes	6	6	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	1	1	contact-ledge-visible-check	manual-review
for_t_1	forêt 1	25	11	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	0	0	none-in-runtime	ignore-not-placed
barri_re_pierre	barrière pierre	13	6	compactProp	default-ground-wide-ellipse	0.2	0.74/0.5	anchor=(0.5,0.98) size=(0.58,0.06)	0	0	none-in-runtime	ignore-not-placed
parasol	parasol	4	4	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	0	0	none-in-runtime	ignore-not-placed
rock_cliff_1	rock cliff 1	3	4	building	default-ground-wide-ellipse	0.2	0.72/0.48	anchor=(0.5,0.98) size=(0.6,0.06)	0	0	none-in-runtime	ignore-not-placed
rock_cliff_2	rock cliff  2	7	2	compactProp	default-ground-wide-ellipse	0.2	0.74/0.5	anchor=(0.5,0.98) size=(0.58,0.06)	0	0	none-in-runtime	ignore-not-placed
rock_cliff_3	rock cliff  3	9	3	compactProp	default-ground-wide-ellipse	0.2	0.74/0.5	anchor=(0.5,0.98) size=(0.58,0.06)	0	0	none-in-runtime	ignore-not-placed
```

Diagnostic : 20 éléments gardent une config Shadow authorée, mais seulement 9 elementIds génèrent effectivement les 10 instructions runtime restantes. Plusieurs éléments sont non placés ou placés sur une couche non visible au sens runtime.

## 10. Inventaire des placements et shadowOverrides

Commande :

```bash
jq -r '[.. | objects | select(has("elementId"))] as $placed | [$placed|length, ($placed|map(select(.elementId=="panneau"))|length), ($placed|map(select(.elementId=="lampadaire"))|length), ($placed|map(select(.elementId=="arbre_pixellab_1"))|length), ($placed|map(select(.elementId=="arbre_pixellab_2"))|length), ($placed|map(select(.elementId=="selbrume_maison_5"))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Sortie :

```text
2105	1	4	46	49	1
```

Commande :

```bash
jq -r '[.. | objects | select(has("shadowOverride"))] as $placed | [$placed|length, ($placed|map(select(.shadowOverride != null))|length), ($placed|map(select(.shadowOverride == null))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Sortie :

```text
2105	0	2105
```

Conclusion : aucun `shadowOverride` n'est présent dans Selbrume.

## 11. Méthode d’inventaire runtime

Méthode utilisée : probe Flutter temporaire `/tmp/shadow60_runtime_inventory_test.dart`.

Le probe charge le vrai `RuntimeMapBundle` via :

```dart
loadRuntimeMapBundle(
  projectFilePath: '/Users/karim/Desktop/selbrume/project.json',
  mapId: 'Selbrume',
)
```

Puis il utilise la chaîne runtime réelle :

```text
buildRuntimeStaticPlacedElementShadowSources(bundle)
buildRuntimeStaticPlacedElementShadowCollection(catalog, single source)
ShadowRuntimeRenderInstruction
```

Limite : le probe n'est pas un screenshot. Il vérifie les instructions runtime produites par la chaîne de résolution, pas le rendu pixel final.

Le MCP Flame a été interrogé sur le rendu/priority/components, mais les recherches rapides ont retourné `No results found`; aucun changement Flame n'a été proposé ni appliqué.

## 12. Inventaire runtime des instructions restantes

Commande :

```bash
cd packages/map_runtime && flutter test /tmp/shadow60_runtime_inventory_test.dart --plain-name 'shadow60 runtime inventory'
```

Sortie utile complète :

```text
00:00 +0: shadow60 runtime inventory
{
  "summary": {
    "staticInstructionsTotal": 10,
    "groundStaticTotal": 10,
    "actorContactTotal": 0,
    "projectedPolygonTotal": 10,
    "contactLedgeTotal": 10,
    "genericProjectionTotal": 0,
    "buildingTotal": 10,
    "tallPropTotal": 0,
    "compactPropTotal": 0,
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
    "byGeometry": {
      "contactLedge": 10
    },
    "opacityAverage": 0.19999999999999998,
    "opacityMax": 0.2,
    "areaAverage": 8815.100232204255,
    "areaMax": 15099.871698616262
  },
  "rows": [
    {
      "rank": 1,
      "placementId": "l_tile_maison_selbrume::24::12",
      "elementId": "selbrum_maison_3",
      "elementName": "selbrum maison 3",
      "worldX": 2304.0,
      "worldY": 1152.0,
      "instructionLeft": 2449.12128,
      "instructionTop": 1807.076352,
      "instructionWidth": 477.7574400000003,
      "instructionHeight": 23.483647999999903,
      "instructionArea": 11219.48755034108,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 2,
      "placementId": "l_tile_maison_selbrume::17::17",
      "elementId": "selbrum_maison_4",
      "elementName": "selbrum maison  4",
      "worldX": 1632.0,
      "worldY": 1632.0,
      "instructionLeft": 1722.7008,
      "instructionTop": 2193.494016,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 6863.578044825572,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 3,
      "placementId": "l_tile_maison_selbrume::10::18",
      "elementId": "selbrum_maison_1",
      "elementName": "selbrum maison 1",
      "worldX": 960.0,
      "worldY": 1728.0,
      "instructionLeft": 1050.7008,
      "instructionTop": 2289.494016,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 6863.578044825572,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 4,
      "placementId": "l_tile_maison_selbrume::29::22",
      "elementId": "selbrume_centre_pok_mon",
      "elementName": "selbrume centre pokémon",
      "worldX": 2784.0,
      "worldY": 2112.0,
      "instructionLeft": 2929.12128,
      "instructionTop": 2673.494016,
      "instructionWidth": 477.7574400000003,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 10981.724871720928,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 5,
      "placementId": "l_tile_maison_selbrume::38::22",
      "elementId": "selbrum_maison_7",
      "elementName": "selbrum maison  7",
      "worldX": 3648.0,
      "worldY": 2112.0,
      "instructionLeft": 3756.84096,
      "instructionTop": 2673.494016,
      "instructionWidth": 358.31807999999955,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 8236.29365379068,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 6,
      "placementId": "l_tile_maison_selbrume::23::27",
      "elementId": "le_puits",
      "elementName": "le puits",
      "worldX": 2208.0,
      "worldY": 2592.0,
      "instructionLeft": 2280.56064,
      "instructionTop": 3059.91168,
      "instructionWidth": 238.8787199999997,
      "instructionHeight": 22.48831999999993,
      "instructionArea": 5371.981096550377,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 7,
      "placementId": "l_tile_maison_selbrume::36::29",
      "elementId": "selbrum_maison_4",
      "elementName": "selbrum maison  4",
      "worldX": 3456.0,
      "worldY": 2784.0,
      "instructionLeft": 3546.7008,
      "instructionTop": 3345.494016,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 6863.578044825572,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 8,
      "placementId": "l_tile_maison_selbrume::10::30",
      "elementId": "selbrum_maison_2",
      "elementName": "selbrum maison  2",
      "worldX": 960.0,
      "worldY": 2880.0,
      "instructionLeft": 1068.84096,
      "instructionTop": 3535.076352,
      "instructionWidth": 358.31808,
      "instructionHeight": 23.483647999999903,
      "instructionArea": 8414.615662755805,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 9,
      "placementId": "l_tile_maison_selbrume::18::33",
      "elementId": "selbrum_maison_8",
      "elementName": "selbrum maison  8",
      "worldX": 1728.0,
      "worldY": 3168.0,
      "instructionLeft": 1927.54176,
      "instructionTop": 3729.494016,
      "instructionWidth": 656.9164799999999,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 15099.871698616262,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 10,
      "placementId": "l_tile_maison_selbrume::36::35",
      "elementId": "kiosque_l_gumes",
      "elementName": "kiosque à légumes",
      "worldX": 3456.0,
      "worldY": 3360.0,
      "instructionLeft": 3564.84096,
      "instructionTop": 3921.494016,
      "instructionWidth": 358.31808,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 8236.29365379069,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "manual-review"
    }
  ]
}
00:00 +1: All tests passed!
```

Synthèse runtime après cleanup :

```text
static instructions total: 10
groundStatic total: 10
actorContact total: 0
projectedPolygon total: 10
contactLedge total: 10
genericProjection total: 0
building total: 10
tallProp total: 0
compactProp total: 0
opacity average: 0.2
opacity max: 0.2
area average: 8815.100232204255
area max: 15099.871698616262
```

Inventaire runtime avant Shadow-59, depuis le backup, pour comparaison :

```text
{
  "summary": {
    "staticInstructionsTotal": 111,
    "groundStaticTotal": 111,
    "actorContactTotal": 0,
    "projectedPolygonTotal": 111,
    "contactLedgeTotal": 10,
    "genericProjectionTotal": 97,
    "buildingTotal": 10,
    "tallPropTotal": 4,
    "compactPropTotal": 0,
    "byElement": {
      "arbre_pixellab_1": 46,
      "arbre_pixellab_2": 49,
      "lampadaire": 4,
      "selbrum_maison_3": 1,
      "selbrume_maison_5": 1,
      "selbrum_maison_4": 2,
      "selbrum_maison_1": 1,
      "selbrume_centre_pok_mon": 1,
      "selbrum_maison_7": 1,
      "panneau": 1,
      "le_puits": 1,
      "selbrum_maison_2": 1,
      "selbrum_maison_8": 1,
      "kiosque_l_gumes": 1
    },
    "byFamily": {
      "null": 97,
      "tallProp": 4,
      "building": 10
    },
    "byProfile": {
      "default-ground-soft-ellipse": 96,
      "default-ground-contact-blob": 4,
      "default-ground-wide-ellipse": 11
    },
    "byGeometry": {
      "genericProjection": 97,
      "familyProjection": 4,
      "contactLedge": 10
    },
    "opacityAverage": 0.2436036036036035,
    "opacityMax": 0.27,
    "areaAverage": 120365.07643988424,
    "areaMax": 187303.33377729764
  },
  "rows": [
    {
      "rank": 1,
      "placementId": "env_gen_env_area_foret_4_0_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 384.0,
      "worldY": 0.0,
      "instructionLeft": 646.4258811475908,
      "instructionTop": 444.74195810575725,
      "instructionWidth": 364.04052394031066,
      "instructionHeight": 461.4468723626866,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 2,
      "placementId": "env_gen_env_area_foret_7_0_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 672.0,
      "worldY": 0.0,
      "instructionLeft": 866.6957396229008,
      "instructionTop": 595.8838658286684,
      "instructionWidth": 327.52572779869104,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411633,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 3,
      "placementId": "env_gen_env_area_foret_9_0_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 864.0,
      "worldY": 0.0,
      "instructionLeft": 1126.4258811475909,
      "instructionTop": 444.74195810575725,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626866,
      "instructionArea": 167985.36118553014,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 4,
      "placementId": "env_gen_env_area_foret_11_0_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 1056.0,
      "worldY": 0.0,
      "instructionLeft": 1250.6957396229006,
      "instructionTop": 595.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 5,
      "placementId": "env_gen_env_area_foret_14_0_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 1344.0,
      "worldY": 0.0,
      "instructionLeft": 1538.6957396229006,
      "instructionTop": 595.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 6,
      "placementId": "env_gen_env_area_foret_17_0_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 1632.0,
      "worldY": 0.0,
      "instructionLeft": 1826.6957396229006,
      "instructionTop": 595.8838658286684,
      "instructionWidth": 327.5257277986914,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411645,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 7,
      "placementId": "env_gen_env_area_foret_20_0_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 1920.0,
      "worldY": 0.0,
      "instructionLeft": 2114.695739622901,
      "instructionTop": 595.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 8,
      "placementId": "env_gen_env_area_foret_22_0_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 2112.0,
      "worldY": 0.0,
      "instructionLeft": 2374.4258811475906,
      "instructionTop": 444.74195810575725,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626866,
      "instructionArea": 167985.36118553014,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 9,
      "placementId": "env_gen_env_area_foret_24_0_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 2304.0,
      "worldY": 0.0,
      "instructionLeft": 2498.695739622901,
      "instructionTop": 595.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 10,
      "placementId": "env_gen_env_area_foret_30_0_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 2880.0,
      "worldY": 0.0,
      "instructionLeft": 3142.4258811475906,
      "instructionTop": 444.74195810575725,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626866,
      "instructionArea": 167985.36118553014,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 11,
      "placementId": "env_gen_env_area_foret_32_0_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 3072.0,
      "worldY": 0.0,
      "instructionLeft": 3266.695739622901,
      "instructionTop": 595.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 12,
      "placementId": "env_gen_env_area_foret_35_0_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 3360.0,
      "worldY": 0.0,
      "instructionLeft": 3622.4258811475906,
      "instructionTop": 444.74195810575725,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626866,
      "instructionArea": 167985.36118553014,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 13,
      "placementId": "env_gen_env_area_foret_42_0_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4032.0,
      "worldY": 0.0,
      "instructionLeft": 4294.425881147591,
      "instructionTop": 444.74195810575725,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626866,
      "instructionArea": 167985.36118553014,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 14,
      "placementId": "env_gen_env_area_foret_45_0_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4320.0,
      "worldY": 0.0,
      "instructionLeft": 4514.695739622901,
      "instructionTop": 595.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 15,
      "placementId": "env_gen_env_area_foret_26_1_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 2496.0,
      "worldY": 96.0,
      "instructionLeft": 2690.695739622901,
      "instructionTop": 691.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 16,
      "placementId": "env_gen_env_area_foret_7_2_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 672.0,
      "worldY": 192.0,
      "instructionLeft": 934.4258811475908,
      "instructionTop": 636.7419581057572,
      "instructionWidth": 364.0405239403109,
      "instructionHeight": 461.4468723626867,
      "instructionArea": 167985.36118553023,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 17,
      "placementId": "env_gen_env_area_foret_12_2_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 1152.0,
      "worldY": 192.0,
      "instructionLeft": 1346.6957396229006,
      "instructionTop": 787.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 18,
      "placementId": "env_gen_env_area_foret_19_2_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 1824.0,
      "worldY": 192.0,
      "instructionLeft": 2086.4258811475906,
      "instructionTop": 636.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626867,
      "instructionArea": 167985.36118553017,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 19,
      "placementId": "env_gen_env_area_foret_23_2_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 2208.0,
      "worldY": 192.0,
      "instructionLeft": 2402.695739622901,
      "instructionTop": 787.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 20,
      "placementId": "env_gen_env_area_foret_28_2_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 2688.0,
      "worldY": 192.0,
      "instructionLeft": 2882.695739622901,
      "instructionTop": 787.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 21,
      "placementId": "env_gen_env_area_foret_32_2_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 3072.0,
      "worldY": 192.0,
      "instructionLeft": 3334.4258811475906,
      "instructionTop": 636.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626867,
      "instructionArea": 167985.36118553017,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 22,
      "placementId": "env_gen_env_area_foret_39_2_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 3744.0,
      "worldY": 192.0,
      "instructionLeft": 3938.695739622901,
      "instructionTop": 787.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 23,
      "placementId": "env_gen_env_area_foret_46_2_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4416.0,
      "worldY": 192.0,
      "instructionLeft": 4610.695739622901,
      "instructionTop": 787.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 24,
      "placementId": "env_gen_env_area_foret_5_3_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 480.0,
      "worldY": 288.0,
      "instructionLeft": 674.6957396229008,
      "instructionTop": 883.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044523,
      "instructionArea": 108298.16442411643,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 25,
      "placementId": "env_gen_env_area_foret_9_3_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 864.0,
      "worldY": 288.0,
      "instructionLeft": 1058.6957396229006,
      "instructionTop": 883.8838658286684,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044523,
      "instructionArea": 108298.16442411643,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 26,
      "placementId": "env_gen_env_area_foret_14_3_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 1344.0,
      "worldY": 288.0,
      "instructionLeft": 1606.4258811475909,
      "instructionTop": 732.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626867,
      "instructionArea": 167985.36118553017,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 27,
      "placementId": "env_gen_env_area_foret_25_3_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 2400.0,
      "worldY": 288.0,
      "instructionLeft": 2662.4258811475906,
      "instructionTop": 732.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626867,
      "instructionArea": 167985.36118553017,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 28,
      "placementId": "env_gen_env_area_foret_20_4_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 1920.0,
      "worldY": 384.0,
      "instructionLeft": 2182.4258811475906,
      "instructionTop": 828.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 29,
      "placementId": "env_gen_env_area_foret_27_4_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 2592.0,
      "worldY": 384.0,
      "instructionLeft": 2786.695739622901,
      "instructionTop": 979.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 30,
      "placementId": "env_gen_env_area_foret_31_4_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 2976.0,
      "worldY": 384.0,
      "instructionLeft": 3170.695739622901,
      "instructionTop": 979.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 31,
      "placementId": "env_gen_env_area_foret_38_4_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 3648.0,
      "worldY": 384.0,
      "instructionLeft": 3842.695739622901,
      "instructionTop": 979.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 32,
      "placementId": "env_gen_env_area_foret_40_4_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 3840.0,
      "worldY": 384.0,
      "instructionLeft": 4034.695739622901,
      "instructionTop": 979.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 33,
      "placementId": "env_gen_env_area_foret_42_4_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4032.0,
      "worldY": 384.0,
      "instructionLeft": 4226.695739622901,
      "instructionTop": 979.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 34,
      "placementId": "env_gen_env_area_foret_46_4_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4416.0,
      "worldY": 384.0,
      "instructionLeft": 4610.695739622901,
      "instructionTop": 979.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 35,
      "placementId": "env_gen_env_area_foret_4_5_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 384.0,
      "worldY": 480.0,
      "instructionLeft": 646.4258811475908,
      "instructionTop": 924.7419581057572,
      "instructionWidth": 364.04052394031066,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553003,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 36,
      "placementId": "env_gen_env_area_foret_8_5_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 768.0,
      "worldY": 480.0,
      "instructionLeft": 1030.4258811475909,
      "instructionTop": 924.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 37,
      "placementId": "env_gen_env_area_foret_11_5_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 1056.0,
      "worldY": 480.0,
      "instructionLeft": 1250.6957396229006,
      "instructionTop": 1075.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 38,
      "placementId": "env_gen_env_area_foret_14_5_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 1344.0,
      "worldY": 480.0,
      "instructionLeft": 1606.4258811475909,
      "instructionTop": 924.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 39,
      "placementId": "env_gen_env_area_foret_17_5_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 1632.0,
      "worldY": 480.0,
      "instructionLeft": 1894.4258811475909,
      "instructionTop": 924.7419581057572,
      "instructionWidth": 364.04052394031055,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 40,
      "placementId": "env_gen_env_area_foret_22_5_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 2112.0,
      "worldY": 480.0,
      "instructionLeft": 2374.4258811475906,
      "instructionTop": 924.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 41,
      "placementId": "env_gen_env_area_foret_44_5_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4224.0,
      "worldY": 480.0,
      "instructionLeft": 4486.425881147591,
      "instructionTop": 924.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 42,
      "placementId": "env_gen_env_area_foret_6_6_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 576.0,
      "worldY": 576.0,
      "instructionLeft": 770.6957396229008,
      "instructionTop": 1171.8838658286681,
      "instructionWidth": 327.52572779869104,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411633,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 43,
      "placementId": "env_gen_env_area_foret_19_6_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 1824.0,
      "worldY": 576.0,
      "instructionLeft": 2086.4258811475906,
      "instructionTop": 1020.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 44,
      "placementId": "env_gen_env_area_foret_25_6_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 2400.0,
      "worldY": 576.0,
      "instructionLeft": 2662.4258811475906,
      "instructionTop": 1020.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 45,
      "placementId": "env_gen_env_area_foret_32_6_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 3072.0,
      "worldY": 576.0,
      "instructionLeft": 3334.4258811475906,
      "instructionTop": 1020.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 46,
      "placementId": "env_gen_env_area_foret_8_7_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 768.0,
      "worldY": 672.0,
      "instructionLeft": 962.6957396229008,
      "instructionTop": 1267.8838658286681,
      "instructionWidth": 327.52572779869104,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411633,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 47,
      "placementId": "env_gen_env_area_foret_11_7_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 1056.0,
      "worldY": 672.0,
      "instructionLeft": 1318.4258811475909,
      "instructionTop": 1116.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 48,
      "placementId": "env_gen_env_area_foret_22_7_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 2112.0,
      "worldY": 672.0,
      "instructionLeft": 2374.4258811475906,
      "instructionTop": 1116.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 49,
      "placementId": "env_gen_env_area_foret_36_7_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 3456.0,
      "worldY": 672.0,
      "instructionLeft": 3650.695739622901,
      "instructionTop": 1267.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 50,
      "placementId": "env_gen_env_area_foret_40_7_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 3840.0,
      "worldY": 672.0,
      "instructionLeft": 4034.695739622901,
      "instructionTop": 1267.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 51,
      "placementId": "env_gen_env_area_foret_13_8_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 1248.0,
      "worldY": 768.0,
      "instructionLeft": 1442.6957396229006,
      "instructionTop": 1363.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 52,
      "placementId": "env_gen_env_area_foret_15_8_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 1440.0,
      "worldY": 768.0,
      "instructionLeft": 1634.6957396229006,
      "instructionTop": 1363.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 53,
      "placementId": "env_gen_env_area_foret_24_8_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 2304.0,
      "worldY": 768.0,
      "instructionLeft": 2566.4258811475906,
      "instructionTop": 1212.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 54,
      "placementId": "env_gen_env_area_foret_31_8_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 2976.0,
      "worldY": 768.0,
      "instructionLeft": 3238.4258811475906,
      "instructionTop": 1212.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 55,
      "placementId": "env_gen_env_area_foret_33_8_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 3168.0,
      "worldY": 768.0,
      "instructionLeft": 3430.4258811475906,
      "instructionTop": 1212.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 56,
      "placementId": "env_gen_env_area_foret_38_8_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 3648.0,
      "worldY": 768.0,
      "instructionLeft": 3910.4258811475906,
      "instructionTop": 1212.7419581057572,
      "instructionWidth": 364.04052394031123,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553032,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 57,
      "placementId": "env_gen_env_area_foret_47_8_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4512.0,
      "worldY": 768.0,
      "instructionLeft": 4774.425881147591,
      "instructionTop": 1212.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 58,
      "placementId": "env_gen_env_area_foret_50_8_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4800.0,
      "worldY": 768.0,
      "instructionLeft": 4994.695739622901,
      "instructionTop": 1363.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 59,
      "placementId": "env_gen_env_area_foret_8_9_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 768.0,
      "worldY": 864.0,
      "instructionLeft": 1030.4258811475909,
      "instructionTop": 1308.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 60,
      "placementId": "env_gen_env_area_foret_10_9_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 960.0,
      "worldY": 864.0,
      "instructionLeft": 1154.6957396229006,
      "instructionTop": 1459.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 61,
      "placementId": "env_gen_env_area_foret_41_9_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 3936.0,
      "worldY": 864.0,
      "instructionLeft": 4198.425881147591,
      "instructionTop": 1308.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 62,
      "placementId": "env_gen_env_area_foret_43_9_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4128.0,
      "worldY": 864.0,
      "instructionLeft": 4390.425881147591,
      "instructionTop": 1308.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 63,
      "placementId": "env_gen_env_area_foret_13_10_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 1248.0,
      "worldY": 960.0,
      "instructionLeft": 1442.6957396229006,
      "instructionTop": 1555.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 64,
      "placementId": "env_gen_env_area_foret_17_10_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 1632.0,
      "worldY": 960.0,
      "instructionLeft": 1894.4258811475909,
      "instructionTop": 1404.7419581057572,
      "instructionWidth": 364.04052394031055,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 65,
      "placementId": "env_gen_env_area_foret_33_10_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 3168.0,
      "worldY": 960.0,
      "instructionLeft": 3362.695739622901,
      "instructionTop": 1555.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 66,
      "placementId": "env_gen_env_area_foret_36_10_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 3456.0,
      "worldY": 960.0,
      "instructionLeft": 3718.4258811475906,
      "instructionTop": 1404.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 67,
      "placementId": "env_gen_env_area_foret_9_11_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 864.0,
      "worldY": 1056.0,
      "instructionLeft": 1058.6957396229006,
      "instructionTop": 1651.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 68,
      "placementId": "env_gen_env_area_foret_42_11_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4032.0,
      "worldY": 1056.0,
      "instructionLeft": 4226.695739622901,
      "instructionTop": 1651.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 69,
      "placementId": "env_gen_env_area_foret_46_11_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4416.0,
      "worldY": 1056.0,
      "instructionLeft": 4678.425881147591,
      "instructionTop": 1500.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 70,
      "placementId": "env_gen_env_area_foret_48_11_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4608.0,
      "worldY": 1056.0,
      "instructionLeft": 4870.425881147591,
      "instructionTop": 1500.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 71,
      "placementId": "env_gen_env_area_foret_12_12_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 1152.0,
      "worldY": 1152.0,
      "instructionLeft": 1346.6957396229006,
      "instructionTop": 1747.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 72,
      "placementId": "env_gen_env_area_foret_43_13_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4128.0,
      "worldY": 1248.0,
      "instructionLeft": 4390.425881147591,
      "instructionTop": 1692.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626867,
      "instructionArea": 167985.36118553017,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 73,
      "placementId": "env_gen_env_area_foret_47_13_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4512.0,
      "worldY": 1248.0,
      "instructionLeft": 4706.695739622901,
      "instructionTop": 1843.8838658286681,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 74,
      "placementId": "env_gen_env_area_foret_12_14_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 1152.0,
      "worldY": 1344.0,
      "instructionLeft": 1414.4258811475909,
      "instructionTop": 1788.7419581057572,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626867,
      "instructionArea": 167985.36118553017,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 75,
      "placementId": "env_gen_env_area_foret_43_15_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4128.0,
      "worldY": 1440.0,
      "instructionLeft": 4390.425881147591,
      "instructionTop": 1884.741958105757,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626869,
      "instructionArea": 167985.36118553026,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 76,
      "placementId": "env_gen_env_area_foret_47_16_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4512.0,
      "worldY": 1536.0,
      "instructionLeft": 4706.695739622901,
      "instructionTop": 2131.883865828668,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044525,
      "instructionArea": 108298.16442411652,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 77,
      "placementId": "env_gen_env_area_foret_50_16_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4800.0,
      "worldY": 1536.0,
      "instructionLeft": 4994.695739622901,
      "instructionTop": 2131.883865828668,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044525,
      "instructionArea": 108298.16442411652,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 78,
      "placementId": "env_gen_env_area_foret_50_18_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4800.0,
      "worldY": 1728.0,
      "instructionLeft": 4994.695739622901,
      "instructionTop": 2323.883865828668,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044525,
      "instructionArea": 108298.16442411652,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 79,
      "placementId": "env_gen_env_area_foret_45_19_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4320.0,
      "worldY": 1824.0,
      "instructionLeft": 4514.695739622901,
      "instructionTop": 2419.883865828668,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044525,
      "instructionArea": 108298.16442411652,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 80,
      "placementId": "env_gen_env_area_foret_47_19_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4512.0,
      "worldY": 1824.0,
      "instructionLeft": 4774.425881147591,
      "instructionTop": 2268.741958105757,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626869,
      "instructionArea": 167985.36118553026,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 81,
      "placementId": "env_gen_env_area_foret_45_22_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4320.0,
      "worldY": 2112.0,
      "instructionLeft": 4582.425881147591,
      "instructionTop": 2556.741958105757,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626869,
      "instructionArea": 167985.36118553026,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 82,
      "placementId": "env_gen_env_area_foret_47_22_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4512.0,
      "worldY": 2112.0,
      "instructionLeft": 4774.425881147591,
      "instructionTop": 2556.741958105757,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626869,
      "instructionArea": 167985.36118553026,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 83,
      "placementId": "env_gen_env_area_foret_45_24_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4320.0,
      "worldY": 2304.0,
      "instructionLeft": 4582.425881147591,
      "instructionTop": 2748.741958105757,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626869,
      "instructionArea": 167985.36118553026,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 84,
      "placementId": "env_gen_env_area_foret_48_24_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4608.0,
      "worldY": 2304.0,
      "instructionLeft": 4802.695739622901,
      "instructionTop": 2899.883865828668,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044525,
      "instructionArea": 108298.16442411652,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 85,
      "placementId": "env_gen_env_area_foret_50_24_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4800.0,
      "worldY": 2304.0,
      "instructionLeft": 4994.695739622901,
      "instructionTop": 2899.883865828668,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044525,
      "instructionArea": 108298.16442411652,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 86,
      "placementId": "env_gen_env_area_foret_48_33_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4608.0,
      "worldY": 3168.0,
      "instructionLeft": 4870.425881147591,
      "instructionTop": 3612.741958105757,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.4468723626869,
      "instructionArea": 167985.36118553026,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 87,
      "placementId": "env_gen_env_area_foret_49_35_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4704.0,
      "worldY": 3360.0,
      "instructionLeft": 4898.695739622901,
      "instructionTop": 3955.883865828668,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.65544240445206,
      "instructionArea": 108298.16442411636,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 88,
      "placementId": "env_gen_env_area_foret_49_37_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4704.0,
      "worldY": 3552.0,
      "instructionLeft": 4898.695739622901,
      "instructionTop": 4147.883865828669,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044516,
      "instructionArea": 108298.16442411621,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 89,
      "placementId": "env_gen_env_area_foret_49_39_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4704.0,
      "worldY": 3744.0,
      "instructionLeft": 4898.695739622901,
      "instructionTop": 4339.883865828669,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044516,
      "instructionArea": 108298.16442411621,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 90,
      "placementId": "env_gen_env_area_foret_49_41_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4704.0,
      "worldY": 3936.0,
      "instructionLeft": 4898.695739622901,
      "instructionTop": 4531.883865828669,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044516,
      "instructionArea": 108298.16442411621,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 91,
      "placementId": "env_gen_env_area_foret_48_43_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4608.0,
      "worldY": 4128.0,
      "instructionLeft": 4870.425881147591,
      "instructionTop": 4572.7419581057575,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.446872362686,
      "instructionArea": 167985.36118552994,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 92,
      "placementId": "env_gen_env_area_foret_50_44_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4800.0,
      "worldY": 4224.0,
      "instructionLeft": 4994.695739622901,
      "instructionTop": 4819.883865828669,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044516,
      "instructionArea": 108298.16442411621,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 93,
      "placementId": "env_gen_env_area_foret_46_45_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4416.0,
      "worldY": 4320.0,
      "instructionLeft": 4678.425881147591,
      "instructionTop": 4764.7419581057575,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.446872362686,
      "instructionArea": 167985.36118552994,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 94,
      "placementId": "env_gen_env_area_foret_45_35_arbre_pixellab_1",
      "elementId": "arbre_pixellab_1",
      "elementName": "arbre  pixelLab 1",
      "worldX": 4320.0,
      "worldY": 3360.0,
      "instructionLeft": 4582.425881147591,
      "instructionTop": 3804.741958105757,
      "instructionWidth": 364.0405239403108,
      "instructionHeight": 461.44687236268646,
      "instructionArea": 167985.36118553008,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 95,
      "placementId": "env_gen_env_area_foret_46_37_arbre_pixellab_2",
      "elementId": "arbre_pixellab_2",
      "elementName": "arbre  pixelLab 2",
      "worldX": 4416.0,
      "worldY": 3552.0,
      "instructionLeft": 4610.695739622901,
      "instructionTop": 4147.883865828669,
      "instructionWidth": 327.52572779869115,
      "instructionHeight": 330.6554424044516,
      "instructionArea": 108298.16442411621,
      "opacity": 0.25,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 96,
      "placementId": "l_tile_parasol_lampadaire::23::17",
      "elementId": "lampadaire",
      "elementName": "lampadaire",
      "worldX": 2208.0,
      "worldY": 1632.0,
      "instructionLeft": 2344.8521695627646,
      "instructionTop": 2096.115932361699,
      "instructionWidth": 68.47097692796115,
      "instructionHeight": 52.86284944175395,
      "instructionArea": 3619.5709444726185,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "familyProjection",
      "renderPass": "groundStatic",
      "family": "tallProp",
      "shadowProfileId": "default-ground-contact-blob",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 97,
      "placementId": "l_tile_parasol_lampadaire::30::17",
      "elementId": "lampadaire",
      "elementName": "lampadaire",
      "worldX": 2880.0,
      "worldY": 1632.0,
      "instructionLeft": 3016.8521695627646,
      "instructionTop": 2096.115932361699,
      "instructionWidth": 68.47097692796115,
      "instructionHeight": 52.86284944175395,
      "instructionArea": 3619.5709444726185,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "familyProjection",
      "renderPass": "groundStatic",
      "family": "tallProp",
      "shadowProfileId": "default-ground-contact-blob",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 98,
      "placementId": "l_tile_maison_selbrume::24::12",
      "elementId": "selbrum_maison_3",
      "elementName": "selbrum maison 3",
      "worldX": 2304.0,
      "worldY": 1152.0,
      "instructionLeft": 2449.12128,
      "instructionTop": 1807.076352,
      "instructionWidth": 477.7574400000003,
      "instructionHeight": 23.483647999999903,
      "instructionArea": 11219.48755034108,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 99,
      "placementId": "l_tile_maison_selbrume::36::16",
      "elementId": "selbrume_maison_5",
      "elementName": "selbrume maison 5",
      "worldX": 3456.0,
      "worldY": 1536.0,
      "instructionLeft": 3705.7406882420028,
      "instructionTop": 1891.2726405377844,
      "instructionWidth": 364.981626933652,
      "instructionHeight": 513.1856508803016,
      "instructionArea": 187303.33377729764,
      "opacity": 0.22,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-soft-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 100,
      "placementId": "l_tile_maison_selbrume::17::17",
      "elementId": "selbrum_maison_4",
      "elementName": "selbrum maison  4",
      "worldX": 1632.0,
      "worldY": 1632.0,
      "instructionLeft": 1722.7008,
      "instructionTop": 2193.494016,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 6863.578044825572,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 101,
      "placementId": "l_tile_maison_selbrume::10::18",
      "elementId": "selbrum_maison_1",
      "elementName": "selbrum maison 1",
      "worldX": 960.0,
      "worldY": 1728.0,
      "instructionLeft": 1050.7008,
      "instructionTop": 2289.494016,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 6863.578044825572,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 102,
      "placementId": "l_tile_maison_selbrume::29::22",
      "elementId": "selbrume_centre_pok_mon",
      "elementName": "selbrume centre pokémon",
      "worldX": 2784.0,
      "worldY": 2112.0,
      "instructionLeft": 2929.12128,
      "instructionTop": 2673.494016,
      "instructionWidth": 477.7574400000003,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 10981.724871720928,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 103,
      "placementId": "l_tile_maison_selbrume::38::22",
      "elementId": "selbrum_maison_7",
      "elementName": "selbrum maison  7",
      "worldX": 3648.0,
      "worldY": 2112.0,
      "instructionLeft": 3756.84096,
      "instructionTop": 2673.494016,
      "instructionWidth": 358.31807999999955,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 8236.29365379068,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 104,
      "placementId": "l_tile_maison_selbrume::22::24",
      "elementId": "panneau",
      "elementName": "panneau",
      "worldX": 2112.0,
      "worldY": 2304.0,
      "instructionLeft": 2219.9885495114513,
      "instructionTop": 2497.5745544698916,
      "instructionWidth": 166.2427359451467,
      "instructionHeight": 220.48598650308622,
      "instructionArea": 36654.19363383774,
      "opacity": 0.27,
      "shapeKind": "projectedPolygon",
      "geometryType": "genericProjection",
      "renderPass": "groundStatic",
      "family": null,
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 105,
      "placementId": "l_tile_maison_selbrume::23::27",
      "elementId": "le_puits",
      "elementName": "le puits",
      "worldX": 2208.0,
      "worldY": 2592.0,
      "instructionLeft": 2280.56064,
      "instructionTop": 3059.91168,
      "instructionWidth": 238.8787199999997,
      "instructionHeight": 22.48831999999993,
      "instructionArea": 5371.981096550377,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 106,
      "placementId": "l_tile_maison_selbrume::18::28",
      "elementId": "lampadaire",
      "elementName": "lampadaire",
      "worldX": 1728.0,
      "worldY": 2688.0,
      "instructionLeft": 1864.8521695627644,
      "instructionTop": 3152.115932361699,
      "instructionWidth": 68.47097692796115,
      "instructionHeight": 52.86284944175395,
      "instructionArea": 3619.5709444726185,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "familyProjection",
      "renderPass": "groundStatic",
      "family": "tallProp",
      "shadowProfileId": "default-ground-contact-blob",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 107,
      "placementId": "l_tile_maison_selbrume::29::29",
      "elementId": "lampadaire",
      "elementName": "lampadaire",
      "worldX": 2784.0,
      "worldY": 2784.0,
      "instructionLeft": 2920.8521695627646,
      "instructionTop": 3248.115932361699,
      "instructionWidth": 68.47097692796115,
      "instructionHeight": 52.86284944175395,
      "instructionArea": 3619.5709444726185,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "familyProjection",
      "renderPass": "groundStatic",
      "family": "tallProp",
      "shadowProfileId": "default-ground-contact-blob",
      "colorHexRgb": "000000",
      "reason": "remaining non-building authored shadow",
      "recommendation": "manual-review"
    },
    {
      "rank": 108,
      "placementId": "l_tile_maison_selbrume::36::29",
      "elementId": "selbrum_maison_4",
      "elementName": "selbrum maison  4",
      "worldX": 3456.0,
      "worldY": 2784.0,
      "instructionLeft": 3546.7008,
      "instructionTop": 3345.494016,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 6863.578044825572,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 109,
      "placementId": "l_tile_maison_selbrume::10::30",
      "elementId": "selbrum_maison_2",
      "elementName": "selbrum maison  2",
      "worldX": 960.0,
      "worldY": 2880.0,
      "instructionLeft": 1068.84096,
      "instructionTop": 3535.076352,
      "instructionWidth": 358.31808,
      "instructionHeight": 23.483647999999903,
      "instructionArea": 8414.615662755805,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 110,
      "placementId": "l_tile_maison_selbrume::18::33",
      "elementId": "selbrum_maison_8",
      "elementName": "selbrum maison  8",
      "worldX": 1728.0,
      "worldY": 3168.0,
      "instructionLeft": 1927.54176,
      "instructionTop": 3729.494016,
      "instructionWidth": 656.9164799999999,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 15099.871698616262,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "keep"
    },
    {
      "rank": 111,
      "placementId": "l_tile_maison_selbrume::36::35",
      "elementId": "kiosque_l_gumes",
      "elementName": "kiosque à légumes",
      "worldX": 3456.0,
      "worldY": 3360.0,
      "instructionLeft": 3564.84096,
      "instructionTop": 3921.494016,
      "instructionWidth": 358.31808,
      "instructionHeight": 22.985983999999917,
      "instructionArea": 8236.29365379069,
      "opacity": 0.2,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "shadowProfileId": "default-ground-wide-ellipse",
      "colorHexRgb": "000000",
      "reason": "remaining authored building/contact ledge shadow",
      "recommendation": "manual-review"
    }
  ]
}```

## 13. Table complète des instructions restantes

```text
rank	placementId	elementId	elementName	worldX	worldY	instructionLeft	instructionTop	instructionWidth	instructionHeight	instructionArea	opacity	shapeKind	geometryType	renderPass	family	shadowProfileId	reason	recommendation
1	l_tile_maison_selbrume::24::12	selbrum_maison_3	selbrum maison 3	2304.0	1152.0	2449.12128	1807.076352	477.7574400000003	23.483647999999903	11219.48755034108	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	remaining authored building/contact ledge shadow	keep
2	l_tile_maison_selbrume::17::17	selbrum_maison_4	selbrum maison  4	1632.0	1632.0	1722.7008	2193.494016	298.59839999999986	22.985983999999917	6863.578044825572	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	remaining authored building/contact ledge shadow	keep
3	l_tile_maison_selbrume::10::18	selbrum_maison_1	selbrum maison 1	960.0	1728.0	1050.7008	2289.494016	298.59839999999986	22.985983999999917	6863.578044825572	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	remaining authored building/contact ledge shadow	keep
4	l_tile_maison_selbrume::29::22	selbrume_centre_pok_mon	selbrume centre pokémon	2784.0	2112.0	2929.12128	2673.494016	477.7574400000003	22.985983999999917	10981.724871720928	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	remaining authored building/contact ledge shadow	keep
5	l_tile_maison_selbrume::38::22	selbrum_maison_7	selbrum maison  7	3648.0	2112.0	3756.84096	2673.494016	358.31807999999955	22.985983999999917	8236.29365379068	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	remaining authored building/contact ledge shadow	keep
6	l_tile_maison_selbrume::23::27	le_puits	le puits	2208.0	2592.0	2280.56064	3059.91168	238.8787199999997	22.48831999999993	5371.981096550377	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	remaining authored building/contact ledge shadow	manual-review
7	l_tile_maison_selbrume::36::29	selbrum_maison_4	selbrum maison  4	3456.0	2784.0	3546.7008	3345.494016	298.59839999999986	22.985983999999917	6863.578044825572	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	remaining authored building/contact ledge shadow	keep
8	l_tile_maison_selbrume::10::30	selbrum_maison_2	selbrum maison  2	960.0	2880.0	1068.84096	3535.076352	358.31808	23.483647999999903	8414.615662755805	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	remaining authored building/contact ledge shadow	keep
9	l_tile_maison_selbrume::18::33	selbrum_maison_8	selbrum maison  8	1728.0	3168.0	1927.54176	3729.494016	656.9164799999999	22.985983999999917	15099.871698616262	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	remaining authored building/contact ledge shadow	keep
10	l_tile_maison_selbrume::36::35	kiosque_l_gumes	kiosque à légumes	3456.0	3360.0	3564.84096	3921.494016	358.31808	22.985983999999917	8236.29365379069	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse	remaining authored building/contact ledge shadow	manual-review
```

## 14. Diagnostic visuel probable

Ce qui est maintenant prouvé :

- Les grosses plaques diagonales d'arbres ont disparu du flux runtime.
- `genericProjection` est tombé à `0`.
- `panneau`, `lampadaire`, `arbre_pixellab_1`, `arbre_pixellab_2`, `selbrume_maison_5` ne génèrent plus d'instruction runtime.
- Les 10 instructions restantes sont toutes des `contactLedge` issues de family `building`.

Ce qui reste à juger visuellement :

- Les contact ledges des maisons peuvent être acceptables ou encore trop visibles selon la capture runtime.
- `le_puits` et `kiosque_l_gumes` sont classés `manual-review` parce qu'ils ne sont pas forcément des bâtiments au sens visuel Pokémon-like.
- L'élément `test` garde une config shadow authorée mais ne génère aucune instruction car son placement est sur `l_tile_objectif`, couche non visible au sens runtime.

Preuve `test` :

```text
l_tile_objectif::4::12	test	l_tile_objectif	4	12
l_tile_objectif	objectif	null	1.0
```

## 15. Décision sur les ombres restantes

Réponses explicites :

1. Les grosses plaques diagonales d'arbres ont-elles disparu ? oui, `arbre_pixellab_1 = 0`, `arbre_pixellab_2 = 0`.
2. `genericProjection` est-il tombé à 0 ? oui.
3. `panneau` génère-t-il encore une instruction ? non.
4. `lampadaire` génère-t-il encore une instruction ? non.
5. `selbrume_maison_5` génère-t-elle encore une instruction ? non.
6. Combien d'instructions restent ? 10.
7. Quels elementIds les génèrent ? `selbrum_maison_1`, `selbrum_maison_2`, `selbrum_maison_3`, `selbrum_maison_4` x2, `selbrum_maison_7`, `selbrum_maison_8`, `selbrume_centre_pok_mon`, `le_puits`, `kiosque_l_gumes`.
8. Les ombres restantes sont-elles uniquement des contact ledges building ? oui.
9. Y a-t-il encore un élément debug/test à nettoyer ? pas dans le runtime visible ; `test` reste authoré mais ne génère pas d'instruction car sa couche n'est pas visible.
10. Les contact ledges building sont-ils acceptables ou trop visibles ? impossible à conclure sans capture post-cleanup ; ils sont nettement moins dangereux que les generic projections, mais doivent être review visuellement.
11. Faut-il faire Shadow-61 comme cleanup test/debug ? pas en premier, sauf si l'utilisateur veut nettoyer les données authorées non visibles.
12. Faut-il faire Shadow-61 comme retune building contact ledge ? oui, si la prochaine capture montre encore des ombres trop visibles.
13. Faut-il faire Shadow-61 comme screenshot/visual golden slice ? recommandé après décision sur les contact ledges, ou intégré au lot de visual review.

## 16. Recommandation du prochain lot

Prochain lot recommandé :

```text
Shadow-61 — Selbrume Building Contact Ledge Visual Review / Minimal Retune Decision
```

Objectif : prendre une capture post-cleanup, vérifier seulement les 10 contact ledges restantes, puis décider une action minimale : keep / disable ciblé / retune très léger pour buildings. Ne pas réactiver les projections génériques.

## 17. Probe manifest load

Script temporaire : `/tmp/shadow60_validate_selbrume_manifest_test.dart`.

Commande :

```bash
cd packages/map_runtime && flutter test /tmp/shadow60_validate_selbrume_manifest_test.dart --plain-name 'shadow60 validate selbrume manifest'
```

Sortie complète :

```text
00:00 +0: loading /tmp/shadow60_validate_selbrume_manifest_test.dart
00:00 +0: shadow60 validate selbrume manifest
00:00 +1: All tests passed!
```

## 18. Tests de régression repo

Commande :

```bash
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
00:00 +0: loadProjectManifestFromFile authored shadow manifest keeps missing shadow configs absent at runtime load
00:00 +1: loadProjectManifestFromFile authored shadow manifest preserves recognized old auto shadows as authored data
00:00 +2: loadProjectManifestFromFile authored shadow manifest preserves manual and disabled shadows
00:00 +3: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Ligne finale exacte :

```text
00:05 +233: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Ligne finale exacte :

```text
00:00 +284: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Ligne finale exacte :

```text
00:00 +96: All tests passed!
```

## 19. Ce qui n’a volontairement pas été modifié

Aucun fichier Selbrume n'a été modifié :

```text
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
/Users/karim/Desktop/selbrume/project.shadow59.before.json
```

Aucun code repo n'a été modifié :

```text
packages/map_core/**
packages/map_editor/**
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
```

Aucun renderer, profil, modèle, codec, migration, UI ou screenshot harness n'a été ajouté.

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
```

## 21. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
```

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

## 23. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? reports/shadows/shadow_lot_60_selbrume_post_cleanup_verification_remaining_static_shadows.md
```

## 24. Risques / réserves

- Ce lot ne juge pas le rendu pixel final ; il juge les instructions runtime générées.
- Les 10 contact ledges restantes peuvent être encore trop visibles en capture ; il faut un lot visuel ciblé pour trancher.
- `test` et d'autres éléments non placés gardent des configs Shadow authorées, mais ne produisent pas d'instructions runtime visibles actuellement.
- Le MCP Flame n'a pas retourné de documentation exploitable sur les requêtes de rendu/priority ; l'audit s'appuie donc sur les tests et le code local.

## 25. Auto-critique

- Ai-je évité de modifier Selbrume ? oui, hashes inchangés.
- Ai-je évité de modifier le code ? oui, aucun fichier code dans `git diff`.
- Ai-je confirmé Shadow-56 ? oui, aucun appel runtime à `applyElementAutoShadowPolicyToProject`.
- Ai-je confirmé Shadow-58 ? oui, `buildingLarge` seul safe.
- Ai-je confirmé Shadow-59 ? oui, les 5 cibles sont `shadow == null`.
- Ai-je listé toutes les instructions restantes ? oui, 10 lignes complètes.
- Ai-je expliqué l'écart `test` ? oui, il est sur une couche non visible runtime.
- Ai-je évité tout commit ? oui.

## 26. Regard critique sur le prompt

Le prompt est bien calibré pour stopper la fuite en avant : audit-only, aucune donnée modifiée, décision basée sur les instructions réelles. Le point le plus important est la nuance entre `element has shadow` et `runtime generates instruction` : Shadow-60 montre que les données authorées restantes ne sont pas toutes visibles runtime.

## 27. Proposition de prompt pour le prochain lot

```md
# Shadow-61 — Selbrume Building Contact Ledge Visual Review / Minimal Retune Decision

Objectif : vérifier visuellement les 10 contact ledges restantes après Shadow-59/60 et décider une action minimale.

Contraintes :
- ne pas réactiver genericProjection ;
- ne pas modifier la policy auto-shadow ;
- ne pas toucher aux arbres/panneau/lampadaire déjà neutralisés ;
- prendre une capture runtime Selbrume post-cleanup ;
- comparer la capture aux 10 instructions listées par Shadow-60 ;
- classer chaque contact ledge : keep / disable / retune ;
- si retune, proposer uniquement un changement minimal de constantes building contact ledge ou un patch data ciblé ;
- produire un rapport avant tout changement de code/données.

Critère produit : les ombres restantes doivent être discrètes, proches du pied des bâtiments, et ne plus former de plaques diagonales visibles sur les chemins.
```

## 28. Contenu des probes temporaires utilisés

### `/tmp/shadow60_runtime_inventory_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_collection.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_sources.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  test('shadow60 runtime inventory', () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: '/Users/karim/Desktop/selbrume/project.json',
      mapId: 'Selbrume',
    );
    final elementsById = {
      for (final element in bundle.manifest.elements) element.id: element,
    };
    final sources = buildRuntimeStaticPlacedElementShadowSources(bundle: bundle);
    final rows = <Map<String, Object?>>[];
    var rank = 1;
    for (final source in sources) {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: bundle.manifest.shadowCatalog,
        sources: [source],
      );
      if (collection.instructions.isEmpty) {
        continue;
      }
      final instruction = collection.instructions.single;
      final element = elementsById[source.elementId]!;
      final family = source.placedOverride?.family ?? source.elementShadow?.family;
      final geometryType = family?.name == 'building'
          ? 'contactLedge'
          : family == null
              ? 'genericProjection'
              : 'familyProjection';
      rows.add({
        'rank': rank,
        'placementId': source.id,
        'elementId': source.elementId,
        'elementName': element.name,
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
        'family': family?.name,
        'shadowProfileId': source.elementShadow?.shadowProfileId,
        'colorHexRgb': instruction.colorHexRgb,
        'reason': _reason(source.elementId, family?.name),
        'recommendation': _recommendation(source.elementId, family?.name),
      });
      rank += 1;
    }

    final byElement = <String, int>{};
    final byFamily = <String, int>{};
    final byProfile = <String, int>{};
    final byGeometry = <String, int>{};
    var opacitySum = 0.0;
    var opacityMax = 0.0;
    var areaSum = 0.0;
    var areaMax = 0.0;
    for (final row in rows) {
      void inc(Map<String, int> map, String? key) {
        map[key ?? 'null'] = (map[key ?? 'null'] ?? 0) + 1;
      }
      inc(byElement, row['elementId'] as String?);
      inc(byFamily, row['family'] as String?);
      inc(byProfile, row['shadowProfileId'] as String?);
      inc(byGeometry, row['geometryType'] as String?);
      final opacity = row['opacity'] as double;
      final area = row['instructionArea'] as double;
      opacitySum += opacity;
      areaSum += area;
      if (opacity > opacityMax) opacityMax = opacity;
      if (area > areaMax) areaMax = area;
    }
    final summary = {
      'staticInstructionsTotal': rows.length,
      'groundStaticTotal': rows.where((row) => row['renderPass'] == 'groundStatic').length,
      'actorContactTotal': rows.where((row) => row['renderPass'] == 'actorContact').length,
      'projectedPolygonTotal': rows.where((row) => row['shapeKind'] == 'projectedPolygon').length,
      'contactLedgeTotal': rows.where((row) => row['geometryType'] == 'contactLedge').length,
      'genericProjectionTotal': rows.where((row) => row['geometryType'] == 'genericProjection').length,
      'buildingTotal': rows.where((row) => row['family'] == 'building').length,
      'tallPropTotal': rows.where((row) => row['family'] == 'tallProp').length,
      'compactPropTotal': rows.where((row) => row['family'] == 'compactProp').length,
      'byElement': byElement,
      'byFamily': byFamily,
      'byProfile': byProfile,
      'byGeometry': byGeometry,
      'opacityAverage': rows.isEmpty ? 0 : opacitySum / rows.length,
      'opacityMax': opacityMax,
      'areaAverage': rows.isEmpty ? 0 : areaSum / rows.length,
      'areaMax': areaMax,
    };
    final payload = {'summary': summary, 'rows': rows};
    await File('/tmp/shadow60_runtime_inventory.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    final tsv = StringBuffer()
      ..writeln([
        'rank',
        'placementId',
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
        'reason',
        'recommendation',
      ].join('\t'));
    for (final row in rows) {
      tsv.writeln([
        row['rank'],
        row['placementId'],
        row['elementId'],
        row['elementName'],
        row['worldX'],
        row['worldY'],
        row['instructionLeft'],
        row['instructionTop'],
        row['instructionWidth'],
        row['instructionHeight'],
        row['instructionArea'],
        row['opacity'],
        row['shapeKind'],
        row['geometryType'],
        row['renderPass'],
        row['family'] ?? 'null',
        row['shadowProfileId'],
        row['reason'],
        row['recommendation'],
      ].join('\t'));
    }
    await File('/tmp/shadow60_runtime_inventory.tsv').writeAsString(tsv.toString());

    print(const JsonEncoder.withIndent('  ').convert(summary));
    expect(rows.length, 10);
    expect(summary['genericProjectionTotal'], 0);
  });
}

String _reason(String elementId, String? family) {
  if (elementId == 'test') {
    return 'debug-like element still placed with building contact ledge';
  }
  if (family == 'building') {
    return 'remaining authored building/contact ledge shadow';
  }
  return 'remaining non-building authored shadow';
}

String _recommendation(String elementId, String? family) {
  if (elementId == 'test') {
    return 'disable-next';
  }
  if (elementId == 'le_puits' || elementId == 'kiosque_l_gumes') {
    return 'manual-review';
  }
  if (family == 'building') {
    return 'keep';
  }
  return 'manual-review';
}
```

### `/tmp/shadow60_runtime_inventory_before_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_collection.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_sources.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  test('shadow60 runtime inventory', () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: '/Users/karim/Desktop/selbrume/project.shadow59.before.json',
      mapId: 'Selbrume',
    );
    final elementsById = {
      for (final element in bundle.manifest.elements) element.id: element,
    };
    final sources = buildRuntimeStaticPlacedElementShadowSources(bundle: bundle);
    final rows = <Map<String, Object?>>[];
    var rank = 1;
    for (final source in sources) {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: bundle.manifest.shadowCatalog,
        sources: [source],
      );
      if (collection.instructions.isEmpty) {
        continue;
      }
      final instruction = collection.instructions.single;
      final element = elementsById[source.elementId]!;
      final family = source.placedOverride?.family ?? source.elementShadow?.family;
      final geometryType = family?.name == 'building'
          ? 'contactLedge'
          : family == null
              ? 'genericProjection'
              : 'familyProjection';
      rows.add({
        'rank': rank,
        'placementId': source.id,
        'elementId': source.elementId,
        'elementName': element.name,
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
        'family': family?.name,
        'shadowProfileId': source.elementShadow?.shadowProfileId,
        'colorHexRgb': instruction.colorHexRgb,
        'reason': _reason(source.elementId, family?.name),
        'recommendation': _recommendation(source.elementId, family?.name),
      });
      rank += 1;
    }

    final byElement = <String, int>{};
    final byFamily = <String, int>{};
    final byProfile = <String, int>{};
    final byGeometry = <String, int>{};
    var opacitySum = 0.0;
    var opacityMax = 0.0;
    var areaSum = 0.0;
    var areaMax = 0.0;
    for (final row in rows) {
      void inc(Map<String, int> map, String? key) {
        map[key ?? 'null'] = (map[key ?? 'null'] ?? 0) + 1;
      }
      inc(byElement, row['elementId'] as String?);
      inc(byFamily, row['family'] as String?);
      inc(byProfile, row['shadowProfileId'] as String?);
      inc(byGeometry, row['geometryType'] as String?);
      final opacity = row['opacity'] as double;
      final area = row['instructionArea'] as double;
      opacitySum += opacity;
      areaSum += area;
      if (opacity > opacityMax) opacityMax = opacity;
      if (area > areaMax) areaMax = area;
    }
    final summary = {
      'staticInstructionsTotal': rows.length,
      'groundStaticTotal': rows.where((row) => row['renderPass'] == 'groundStatic').length,
      'actorContactTotal': rows.where((row) => row['renderPass'] == 'actorContact').length,
      'projectedPolygonTotal': rows.where((row) => row['shapeKind'] == 'projectedPolygon').length,
      'contactLedgeTotal': rows.where((row) => row['geometryType'] == 'contactLedge').length,
      'genericProjectionTotal': rows.where((row) => row['geometryType'] == 'genericProjection').length,
      'buildingTotal': rows.where((row) => row['family'] == 'building').length,
      'tallPropTotal': rows.where((row) => row['family'] == 'tallProp').length,
      'compactPropTotal': rows.where((row) => row['family'] == 'compactProp').length,
      'byElement': byElement,
      'byFamily': byFamily,
      'byProfile': byProfile,
      'byGeometry': byGeometry,
      'opacityAverage': rows.isEmpty ? 0 : opacitySum / rows.length,
      'opacityMax': opacityMax,
      'areaAverage': rows.isEmpty ? 0 : areaSum / rows.length,
      'areaMax': areaMax,
    };
    final payload = {'summary': summary, 'rows': rows};
    await File('/tmp/shadow60_runtime_inventory_before.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    final tsv = StringBuffer()
      ..writeln([
        'rank',
        'placementId',
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
        'reason',
        'recommendation',
      ].join('\t'));
    for (final row in rows) {
      tsv.writeln([
        row['rank'],
        row['placementId'],
        row['elementId'],
        row['elementName'],
        row['worldX'],
        row['worldY'],
        row['instructionLeft'],
        row['instructionTop'],
        row['instructionWidth'],
        row['instructionHeight'],
        row['instructionArea'],
        row['opacity'],
        row['shapeKind'],
        row['geometryType'],
        row['renderPass'],
        row['family'] ?? 'null',
        row['shadowProfileId'],
        row['reason'],
        row['recommendation'],
      ].join('\t'));
    }
    await File('/tmp/shadow60_runtime_inventory_before.tsv').writeAsString(tsv.toString());

    print(const JsonEncoder.withIndent('  ').convert(summary));
  });
}

String _reason(String elementId, String? family) {
  if (elementId == 'test') {
    return 'debug-like element still placed with building contact ledge';
  }
  if (family == 'building') {
    return 'remaining authored building/contact ledge shadow';
  }
  return 'remaining non-building authored shadow';
}

String _recommendation(String elementId, String? family) {
  if (elementId == 'test') {
    return 'disable-next';
  }
  if (elementId == 'le_puits' || elementId == 'kiosque_l_gumes') {
    return 'manual-review';
  }
  if (family == 'building') {
    return 'keep';
  }
  return 'manual-review';
}
```

### `/tmp/shadow60_validate_selbrume_manifest_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';

void main() {
  test('shadow60 validate selbrume manifest', () async {
    final manifest = await loadProjectManifestFromFile(
      '/Users/karim/Desktop/selbrume/project.json',
    );
    final elementsById = {
      for (final element in manifest.elements) element.id: element,
    };
    const targets = <String>[
      'panneau',
      'lampadaire',
      'arbre_pixellab_1',
      'arbre_pixellab_2',
      'selbrume_maison_5',
    ];
    expect(manifest.elements.length, 63);
    expect(manifest.elements.where((element) => element.shadow != null), hasLength(20));
    for (final id in targets) {
      expect(elementsById[id], isNotNull, reason: id);
      expect(elementsById[id]!.shadow, isNull, reason: id);
    }
  });
}
```

### `/tmp/shadow60_remaining_shadow_elements.py`

```python
#!/usr/bin/env python3
import json
from pathlib import Path

project = json.loads(Path('/Users/karim/Desktop/selbrume/project.json').read_text())
map_data = json.loads(Path('/Users/karim/Desktop/selbrume/maps/Selbrume.json').read_text())
visible_layers = {layer['id'] for layer in map_data['layers'] if layer.get('isVisible') is True and layer.get('opacity', 1) > 0}
placed = map_data.get('placedElements', [])
recursive_counts = {}
placed_counts = {}
visible_counts = {}

def walk(node):
    if isinstance(node, dict):
        if 'elementId' in node:
            eid = node.get('elementId')
            recursive_counts[eid] = recursive_counts.get(eid, 0) + 1
        for value in node.values():
            walk(value)
    elif isinstance(node, list):
        for value in node:
            walk(value)

walk(map_data)
for item in placed:
    eid = item.get('elementId')
    placed_counts[eid] = placed_counts.get(eid, 0) + 1
    if item.get('layerId') in visible_layers:
        visible_counts[eid] = visible_counts.get(eid, 0) + 1

print('\t'.join(['elementId','name','frameWidth','frameHeight','family','profile','opacity','scale','footprint','recursivePlacementCount','runtimeVisiblePlacementCount','risk','recommendation']))
for element in project['elements']:
    shadow = element.get('shadow')
    if shadow is None:
        continue
    source = element['frames'][0]['source']
    eid = element['id']
    family = shadow.get('family') or 'null'
    footprint = shadow.get('footprint') or {}
    footprint_summary = 'anchor=({},{}) size=({},{})'.format(
        footprint.get('anchorXRatio', 'null'),
        footprint.get('anchorYRatio', 'null'),
        footprint.get('footprintWidthRatio', 'null'),
        footprint.get('footprintHeightRatio', 'null'),
    )
    runtime_count = visible_counts.get(eid, 0)
    recursive_count = recursive_counts.get(eid, 0)
    if runtime_count == 0:
        risk = 'none-in-runtime'
        recommendation = 'ignore-not-placed'
    elif eid == 'test':
        risk = 'debug-authoring-shadow-but-hidden-layer'
        recommendation = 'manual-review'
    elif family == 'building':
        risk = 'contact-ledge-visible-check'
        recommendation = 'keep' if eid.startswith('selbrum_maison') or eid == 'selbrume_centre_pok_mon' else 'manual-review'
    else:
        risk = 'non-building-authored-shadow'
        recommendation = 'manual-review'
    scale = '{}/{}'.format(shadow.get('scaleX', 'null'), shadow.get('scaleY', 'null'))
    print('\t'.join(map(str, [
        eid,
        element.get('name'),
        source.get('width'),
        source.get('height'),
        family,
        shadow.get('shadowProfileId'),
        shadow.get('opacity', 'null'),
        scale,
        footprint_summary,
        recursive_count,
        runtime_count,
        risk,
        recommendation,
    ])))
```

## 29. Inventaire complet des fichiers créés/modifiés

Fichiers repo créés :

```text
reports/shadows/shadow_lot_60_selbrume_post_cleanup_verification_remaining_static_shadows.md
```

Fichiers repo modifiés :

```text
Aucun
```

Fichiers Selbrume modifiés :

```text
Aucun
```

Fichiers temporaires hors repo créés pendant l'audit :

```text
/tmp/shadow60_runtime_inventory_test.dart
/tmp/shadow60_runtime_inventory_before_test.dart
/tmp/shadow60_runtime_inventory.json
/tmp/shadow60_runtime_inventory.tsv
/tmp/shadow60_runtime_inventory_after.json
/tmp/shadow60_runtime_inventory_after.tsv
/tmp/shadow60_runtime_inventory_before.json
/tmp/shadow60_runtime_inventory_before.tsv
/tmp/shadow60_validate_selbrume_manifest_test.dart
/tmp/shadow60_remaining_shadow_elements.py
```
