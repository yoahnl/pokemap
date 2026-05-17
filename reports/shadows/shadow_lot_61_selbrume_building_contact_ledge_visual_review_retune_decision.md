# Shadow-61 — Selbrume Building Contact Ledge Visual Review / Retune Decision V0

## 1. Résumé exécutif

Shadow-61 est un audit uniquement. Aucun code, aucun renderer, aucune policy et aucun fichier Selbrume n'ont été modifiés.

Résultat principal : l'état post-cleanup est stable. Selbrume génère encore 10 instructions statiques, toutes issues de familles `building` et toutes interprétées comme `contactLedge`. `genericProjection` est à 0. Les deux arbres PixelLab, `panneau`, `lampadaire` et `selbrume_maison_5` ne génèrent plus d'instruction statique.

La revue visuelle n'a pas pu être une validation pixel-based fiable dans ce lot : aucune capture post-cleanup fiable n'a été produite sans introduire de harness permanent, et la recherche Flame MCP n'a pas fourni de chemin documentaire exploitable pour un screenshot ponctuel fiable. Les décisions sont donc instruction-based : maisons et centre Pokémon en `keep-provisional`, `le_puits` et `kiosque_l_gumes` en `manual-review`.

Prochain lot recommandé : `Shadow-62 — Selbrume Contact Ledge Screenshot Review / Visual Gate V0`, avant tout retune.

## 2. Rappel Shadow-56 / 57 / 58 / 59 / 60

- Shadow-56 : suppression de l'auto-apply runtime. Le runtime consomme le manifest authoré.
- Shadow-57 : audit initial post Shadow-56, 111 instructions statiques, toutes en `projectedPolygon`, dont 97 `genericProjection`.
- Shadow-58 : policy auto-shadow durcie, seul `buildingLarge` reste safe.
- Shadow-59 : patch explicite Selbrume, `shadow: null` pour `panneau`, `lampadaire`, `arbre_pixellab_1`, `arbre_pixellab_2`, `selbrume_maison_5`.
- Shadow-60 : audit post-cleanup, environ 10 ombres restantes, toutes attendues en contact ledges de buildings.

## 3. Nature audit-only du lot

Ce lot n'a modifié aucun fichier de production et aucun fichier Selbrume. Les seuls fichiers temporaires utilisés sont sous `/tmp` et servent à produire l'inventaire et les probes. Le seul livrable permanent est ce rapport.

## 4. État initial du worktree

Commande : `git status --short --untracked-files=all`

```text
(aucune sortie)
```

Commande : `find .. -name AGENTS.md -print`

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

AGENTS applicable : `/Users/karim/Project/pokemonProject/AGENTS.md`. Aucun `AGENTS.md` plus profond sous `packages/` n'a été trouvé par cette commande.

## 5. Hashes Selbrume initiaux

Commande : `shasum -a 256 /Users/karim/Desktop/selbrume/project.json /Users/karim/Desktop/selbrume/maps/Selbrume.json`

```text
3c3669a8274e31087b617fd46337c28aef6593f376a7d0a54c2d9fb8e31b389d  /Users/karim/Desktop/selbrume/project.json
8fd1f7efdc02413106a21068e3af310b3149c07023cfad64ddaa101f2c2cac63  /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

## 6. Confirmation runtime auto-apply absent

Commande : `rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core`

```text
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

Lecture : aucun appel depuis `packages/map_runtime`. La policy existe encore dans `map_core` et le backfill explicite reste exposé côté `map_editor`.

## 7. Confirmation policy Shadow-58 active

Commande : `rg -n "_autoShadowKindIsArtisticallySafe|case ElementAutoShadowSuggestionKind.buildingLarge|case ElementAutoShadowSuggestionKind.tallThin|case ElementAutoShadowSuggestionKind.wideLow|case ElementAutoShadowSuggestionKind.smallSquare|case ElementAutoShadowSuggestionKind.defaultProp" packages/map_core/lib/src/operations/element_auto_shadow_policy.dart`

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

Extrait de policy vérifié :

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

Conclusion : `buildingLarge` est le seul kind safe. `tallThin`, `wideLow`, `smallSquare` et `defaultProp` ne sont pas safe.

## 8. Confirmation Shadow-59 appliqué

Commande : `jq -r '.elements[] | select(.id=="panneau" or .id=="lampadaire" or .id=="arbre_pixellab_1" or .id=="arbre_pixellab_2" or .id=="selbrume_maison_5") | [.id, .name, (.shadow == null)] | @tsv' /Users/karim/Desktop/selbrume/project.json`

```text
selbrume_maison_5	selbrume maison 5	true
lampadaire	lampadaire	true
arbre_pixellab_1	arbre  pixelLab 1	true
arbre_pixellab_2	arbre  pixelLab 2	true
panneau	panneau	true
```

Les 5 cibles sont toujours `shadow == null`.

## 9. Inventaire des éléments restants avec Shadow

Counts Shadow Selbrume :

Commande :

```bash
jq -r '[.elements[] | select(.shadow != null)] | length' /Users/karim/Desktop/selbrume/project.json
jq -r '[.elements[] | select(.shadow == null)] | length' /Users/karim/Desktop/selbrume/project.json
jq -r '.elements | length' /Users/karim/Desktop/selbrume/project.json
```

```text
20
43
63
```

Sortie complète de l'inventaire brut demandé :

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

Table enrichie :

| elementId | name | frameWidth | frameHeight | family | profile | opacity | scaleX | scaleY | footprintSummary | placementCount | runtimeInstructionCount | geometryType | maxInstructionWidth | maxInstructionHeight | maxInstructionArea | visualRisk | recommendation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| test_maison_pkm | test maison pkm | 6 | 7 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 0 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |
| test | test | 45 | 33 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 1 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |
| custom_cliff_selbrume | custom cliff  selbrume | 3 | 13 | tallProp | default-ground-contact-blob | 0.2 | 0.8 | 0.55 | anchor=(0.5,1.0); size=(0.28,0.05) | 0 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |
| selbrum_maison_1 | selbrum maison 1 | 5 | 6 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 1 | 1 | contactLedge | 298.59839999999986 | 22.985983999999917 | 6863.578044825572 | unknown | keep-provisional |
| selbrum_maison_2 | selbrum maison  2 | 6 | 7 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 1 | 1 | contactLedge | 358.31808 | 23.483647999999903 | 8414.615662755805 | unknown | keep-provisional |
| selbrum_maison_3 | selbrum maison 3 | 8 | 7 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 1 | 1 | contactLedge | 477.7574400000003 | 23.483647999999903 | 11219.48755034108 | unknown | keep-provisional |
| selbrum_maison_4 | selbrum maison  4 | 5 | 6 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 2 | 2 | contactLedge | 298.59839999999986 | 22.985983999999917 | 6863.578044825572 | unknown | keep-provisional |
| selbrum_maison_7 | selbrum maison  7 | 6 | 6 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 1 | 1 | contactLedge | 358.31807999999955 | 22.985983999999917 | 8236.29365379068 | unknown | keep-provisional |
| selbrum_maison_8 | selbrum maison  8 | 11 | 6 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 1 | 1 | contactLedge | 656.9164799999999 | 22.985983999999917 | 15099.871698616262 | unknown | keep-provisional |
| objectif | objectif | 45 | 33 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 0 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |
| selbrume_centre_pok_mon | selbrume centre pokémon | 8 | 6 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 1 | 1 | contactLedge | 477.7574400000003 | 22.985983999999917 | 10981.724871720928 | unknown | keep-provisional |
| selbrume_maison_6 | selbrume maison 6 | 6 | 6 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 0 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |
| le_puits | le puits | 4 | 5 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 1 | 1 | contactLedge | 238.8787199999997 | 22.48831999999993 | 5371.981096550377 | unknown | manual-review |
| kiosque_l_gumes | kiosque à légumes | 6 | 6 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 1 | 1 | contactLedge | 358.31808 | 22.985983999999917 | 8236.29365379069 | unknown | manual-review |
| for_t_1 | forêt 1 | 25 | 11 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 0 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |
| barri_re_pierre | barrière pierre | 13 | 6 | compactProp | default-ground-wide-ellipse | 0.2 | 0.74 | 0.5 | anchor=(0.5,0.98); size=(0.58,0.06) | 0 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |
| parasol | parasol | 4 | 4 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 0 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |
| rock_cliff_1 | rock cliff 1 | 3 | 4 | building | default-ground-wide-ellipse | 0.2 | 0.72 | 0.48 | anchor=(0.5,0.98); size=(0.6,0.06) | 0 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |
| rock_cliff_2 | rock cliff  2 | 7 | 2 | compactProp | default-ground-wide-ellipse | 0.2 | 0.74 | 0.5 | anchor=(0.5,0.98); size=(0.58,0.06) | 0 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |
| rock_cliff_3 | rock cliff  3 | 9 | 3 | compactProp | default-ground-wide-ellipse | 0.2 | 0.74 | 0.5 | anchor=(0.5,0.98); size=(0.58,0.06) | 0 | 0 | none | 0 | 0 | 0 | none-in-current-visible-map | ignore-not-placed |

Placements ciblés :

Commande : `jq -r '[.. | objects | select(has("elementId"))] as $placed | [$placed|length, ($placed|map(select(.elementId=="panneau"))|length), ($placed|map(select(.elementId=="lampadaire"))|length), ($placed|map(select(.elementId=="arbre_pixellab_1"))|length), ($placed|map(select(.elementId=="arbre_pixellab_2"))|length), ($placed|map(select(.elementId=="selbrume_maison_5"))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json`

```text
2105	1	4	46	49	1
```

Shadow overrides :

Commande : `jq -r '[.. | objects | select(has("shadowOverride"))] as $placed | [$placed|length, ($placed|map(select(.shadowOverride != null))|length), ($placed|map(select(.shadowOverride == null))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json`

```text
2105	0	2105
```

## 10. Inventaire runtime des instructions restantes

Méthode : probe Flutter temporaire `/tmp/shadow61_runtime_inventory_test.dart`.

Le probe charge le bundle runtime réel avec :

```dart
loadRuntimeMapBundle(
  projectFilePath: '/Users/karim/Desktop/selbrume/project.json',
  mapId: 'Selbrume',
)
```

Puis il reconstruit les sources via `buildRuntimeStaticPlacedElementShadowSources(bundle: bundle)` et résout chaque source individuellement avec `buildRuntimeStaticPlacedElementShadowCollection(...)`, ce qui permet de relier chaque instruction à son `elementId`, son placement et sa config authorée.

Contenu du probe :

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
  test('shadow61 runtime inventory', () async {
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
        final recommendation = switch (source.elementId) {
          'le_puits' || 'kiosque_l_gumes' => 'manual-review',
          _ => 'keep-provisional',
        };
        final reason = switch (source.elementId) {
          'le_puits' =>
            'well uses building contact ledge; needs pixel review because it is not a house facade',
          'kiosque_l_gumes' =>
            'kiosk uses building contact ledge; needs pixel review because silhouette differs from house facade',
          _ =>
            'building contact ledge remains after cleanup; provisional until post-cleanup screenshot review',
        };
        rows.add({
          'rank': rank,
          'placementId': source.id,
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
          'visualRisk': 'unknown',
          'recommendation': recommendation,
          'reason': reason,
          'colorHexRgb': instruction.colorHexRgb,
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
      'actorContactTotalInThisInventory': byRenderPass['actorContact'] ?? 0,
      'projectedPolygonTotal': byShape['projectedPolygon'] ?? 0,
      'contactLedgeTotal': byGeometryType['contactLedge'] ?? 0,
      'genericProjectionTotal': byFamily['genericProjection'] ?? 0,
      'buildingTotal': byFamily['building'] ?? 0,
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

    await File('/tmp/shadow61_runtime_inventory.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(summary),
    );
    await File('/tmp/shadow61_runtime_inventory.tsv').writeAsString(
      _toTsv(rows),
    );
    print(const JsonEncoder.withIndent('  ').convert({
      'staticInstructionsTotal': summary['staticInstructionsTotal'],
      'groundStaticTotal': summary['groundStaticTotal'],
      'actorContactTotalInThisInventory':
          summary['actorContactTotalInThisInventory'],
      'projectedPolygonTotal': summary['projectedPolygonTotal'],
      'contactLedgeTotal': summary['contactLedgeTotal'],
      'genericProjectionTotal': summary['genericProjectionTotal'],
      'buildingTotal': summary['buildingTotal'],
      'byElement': summary['byElement'],
      'byFamily': summary['byFamily'],
      'byProfile': summary['byProfile'],
      'opacityAverage': summary['opacityAverage'],
      'opacityMax': summary['opacityMax'],
      'areaAverage': summary['areaAverage'],
      'areaMax': summary['areaMax'],
    }));

    expect(rows.length, 10);
    expect(byFamily['genericProjection'] ?? 0, 0);
    expect(byElement['arbre_pixellab_1'] ?? 0, 0);
    expect(byElement['arbre_pixellab_2'] ?? 0, 0);
    expect(byElement['panneau'] ?? 0, 0);
    expect(byElement['lampadaire'] ?? 0, 0);
    expect(byElement['selbrume_maison_5'] ?? 0, 0);
  });
}

String _toTsv(List<Map<String, Object?>> rows) {
  const headers = [
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
    'visualRisk',
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

Sortie du probe :

```text
00:00 +0: loading /tmp/shadow61_runtime_inventory_test.dart
00:00 +0: shadow61 runtime inventory
{
  "staticInstructionsTotal": 10,
  "groundStaticTotal": 10,
  "actorContactTotalInThisInventory": 0,
  "projectedPolygonTotal": 10,
  "contactLedgeTotal": 10,
  "genericProjectionTotal": 0,
  "buildingTotal": 10,
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

Synthèse runtime :

```text
static instructions total: 10
groundStatic total: 10
actorContact total dans cet inventaire: 0
projectedPolygon total: 10
contactLedge total: 10
genericProjection total: 0
building total: 10
byElement: {'selbrum_maison_3': 1, 'selbrum_maison_4': 2, 'selbrum_maison_1': 1, 'selbrume_centre_pok_mon': 1, 'selbrum_maison_7': 1, 'le_puits': 1, 'selbrum_maison_2': 1, 'selbrum_maison_8': 1, 'kiosque_l_gumes': 1}
byFamily: {'building': 10}
byProfile: {'default-ground-wide-ellipse': 10}
opacity average/max: 0.19999999999999998 / 0.2
area average/max: 8815.100232204255 / 15099.871698616262
```

## 11. Table complète des contact ledges restantes

| rank | placementId | elementId | elementName | worldX | worldY | instructionLeft | instructionTop | instructionWidth | instructionHeight | instructionArea | opacity | shapeKind | geometryType | renderPass | family | shadowProfileId | visualRisk | recommendation | reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | l_tile_maison_selbrume::24::12 | selbrum_maison_3 | selbrum maison 3 | 2304.0 | 1152.0 | 2449.12128 | 1807.076352 | 477.7574400000003 | 23.483647999999903 | 11219.48755034108 | 0.2 | projectedPolygon | contactLedge | groundStatic | building | default-ground-wide-ellipse | unknown | keep-provisional | building contact ledge remains after cleanup; provisional until post-cleanup screenshot review |
| 2 | l_tile_maison_selbrume::17::17 | selbrum_maison_4 | selbrum maison  4 | 1632.0 | 1632.0 | 1722.7008 | 2193.494016 | 298.59839999999986 | 22.985983999999917 | 6863.578044825572 | 0.2 | projectedPolygon | contactLedge | groundStatic | building | default-ground-wide-ellipse | unknown | keep-provisional | building contact ledge remains after cleanup; provisional until post-cleanup screenshot review |
| 3 | l_tile_maison_selbrume::10::18 | selbrum_maison_1 | selbrum maison 1 | 960.0 | 1728.0 | 1050.7008 | 2289.494016 | 298.59839999999986 | 22.985983999999917 | 6863.578044825572 | 0.2 | projectedPolygon | contactLedge | groundStatic | building | default-ground-wide-ellipse | unknown | keep-provisional | building contact ledge remains after cleanup; provisional until post-cleanup screenshot review |
| 4 | l_tile_maison_selbrume::29::22 | selbrume_centre_pok_mon | selbrume centre pokémon | 2784.0 | 2112.0 | 2929.12128 | 2673.494016 | 477.7574400000003 | 22.985983999999917 | 10981.724871720928 | 0.2 | projectedPolygon | contactLedge | groundStatic | building | default-ground-wide-ellipse | unknown | keep-provisional | building contact ledge remains after cleanup; provisional until post-cleanup screenshot review |
| 5 | l_tile_maison_selbrume::38::22 | selbrum_maison_7 | selbrum maison  7 | 3648.0 | 2112.0 | 3756.84096 | 2673.494016 | 358.31807999999955 | 22.985983999999917 | 8236.29365379068 | 0.2 | projectedPolygon | contactLedge | groundStatic | building | default-ground-wide-ellipse | unknown | keep-provisional | building contact ledge remains after cleanup; provisional until post-cleanup screenshot review |
| 6 | l_tile_maison_selbrume::23::27 | le_puits | le puits | 2208.0 | 2592.0 | 2280.56064 | 3059.91168 | 238.8787199999997 | 22.48831999999993 | 5371.981096550377 | 0.2 | projectedPolygon | contactLedge | groundStatic | building | default-ground-wide-ellipse | unknown | manual-review | well uses building contact ledge; needs pixel review because it is not a house facade |
| 7 | l_tile_maison_selbrume::36::29 | selbrum_maison_4 | selbrum maison  4 | 3456.0 | 2784.0 | 3546.7008 | 3345.494016 | 298.59839999999986 | 22.985983999999917 | 6863.578044825572 | 0.2 | projectedPolygon | contactLedge | groundStatic | building | default-ground-wide-ellipse | unknown | keep-provisional | building contact ledge remains after cleanup; provisional until post-cleanup screenshot review |
| 8 | l_tile_maison_selbrume::10::30 | selbrum_maison_2 | selbrum maison  2 | 960.0 | 2880.0 | 1068.84096 | 3535.076352 | 358.31808 | 23.483647999999903 | 8414.615662755805 | 0.2 | projectedPolygon | contactLedge | groundStatic | building | default-ground-wide-ellipse | unknown | keep-provisional | building contact ledge remains after cleanup; provisional until post-cleanup screenshot review |
| 9 | l_tile_maison_selbrume::18::33 | selbrum_maison_8 | selbrum maison  8 | 1728.0 | 3168.0 | 1927.54176 | 3729.494016 | 656.9164799999999 | 22.985983999999917 | 15099.871698616262 | 0.2 | projectedPolygon | contactLedge | groundStatic | building | default-ground-wide-ellipse | unknown | keep-provisional | building contact ledge remains after cleanup; provisional until post-cleanup screenshot review |
| 10 | l_tile_maison_selbrume::36::35 | kiosque_l_gumes | kiosque à légumes | 3456.0 | 3360.0 | 3564.84096 | 3921.494016 | 358.31808 | 22.985983999999917 | 8236.29365379069 | 0.2 | projectedPolygon | contactLedge | groundStatic | building | default-ground-wide-ellipse | unknown | manual-review | kiosk uses building contact ledge; needs pixel review because silhouette differs from house facade |

Note importante : `shapeKind` reste `projectedPolygon` au niveau instruction parce que le renderer dessine un polygone. La classification `geometryType = contactLedge` vient de la famille `building` et du chemin runtime `resolveBuildingStaticShadowContactLedgeGeometry(...)`.

## 12. Revue visuelle ou limite faute de capture

Capture disponible : non.

J'ai interrogé Flame MCP pendant le lot sur les sujets screenshot/render test (`Flame GameWidget screenshot render component canvas priority`, puis `Flame testing render game widget screenshot`). Les deux recherches ont retourné `No results found...`. Sans documentation exploitable et sans harness existant demandé dans ce lot, je n'ai pas inventé de nouveau mécanisme de capture.

Conclusion : cette revue est instruction-based, pas pixel-based. Les maisons et le centre Pokémon sont donc seulement `keep-provisional`; `le_puits` et `kiosque_l_gumes` restent `manual-review` parce que leur silhouette n'est pas une façade de bâtiment classique.

## 13. Décisions keep / retune / disable / manual-review

```text
keep: 0
keep-provisional: 8 instructions runtime / 7 elementIds runtime
retune-next: 0
disable-next: 0
manual-review: 2 instructions runtime / 2 elementIds runtime
ignore-not-placed: 11 éléments authorés avec shadow mais sans instruction runtime visible courante
```

Détail runtime :

- `keep-provisional` : `selbrum_maison_1`, `selbrum_maison_2`, `selbrum_maison_3`, `selbrum_maison_4` (2 placements), `selbrum_maison_7`, `selbrum_maison_8`, `selbrume_centre_pok_mon`.
- `manual-review` : `le_puits`, `kiosque_l_gumes`.

## 14. Réponses aux décisions obligatoires

1. Les grosses plaques diagonales d'arbres ont-elles disparu ? Oui, `arbre_pixellab_1 = 0` et `arbre_pixellab_2 = 0` dans l'inventaire runtime.
2. `genericProjection` est-il tombé à 0 ? Oui, `genericProjectionTotal = 0`.
3. `panneau` génère-t-il encore une instruction ? Non, 0.
4. `lampadaire` génère-t-il encore une instruction ? Non, 0.
5. `selbrume_maison_5` génère-t-elle encore une instruction ? Non, 0.
6. Combien d'instructions restent ? 10.
7. Quels `elementId` les génèrent ? `selbrum_maison_1`, `selbrum_maison_2`, `selbrum_maison_3`, `selbrum_maison_4`, `selbrum_maison_7`, `selbrum_maison_8`, `selbrume_centre_pok_mon`, `le_puits`, `kiosque_l_gumes`.
8. Les ombres restantes sont-elles uniquement des contact ledges building ? Oui, 10/10 sont `family = building` et `geometryType = contactLedge`.
9. Y a-t-il encore un élément debug/test à nettoyer ? `test` et `objectif` ont encore une config Shadow authorée mais ne produisent aucune instruction runtime visible dans Selbrume courante. Pas de cleanup urgent dans ce lot.
10. Les contact ledges building semblent-ils acceptables ? Impossible à conclure définitivement sans capture post-cleanup fiable. Instruction-based : maisons probablement low-risk mais seulement `keep-provisional`; puits/kiosque à revoir visuellement.
11. La conclusion est-elle basée sur capture ou inventaire runtime ? Inventaire runtime.
12. Quel est le prochain lot recommandé ? `Shadow-62 — Selbrume Contact Ledge Screenshot Review / Visual Gate V0`.

## 15. Recommandation du prochain lot

Recommandation : ne pas retune à l'aveugle. Le prochain lot doit produire une capture fiable ou une validation visuelle contrôlée des 10 contact ledges restantes.

Pourquoi : après Shadow-59, les grosses plaques dangereuses sont parties. Les 10 formes restantes sont minces (environ 22-23 px de hauteur runtime) et opacité 0.2. Elles peuvent être acceptables, mais le produit demandé est visuel. Sans pixels, retuner serait une nouvelle fuite en avant.

Prochain lot proposé :

```text
Shadow-62 — Selbrume Contact Ledge Screenshot Review / Visual Gate V0
Objectif : obtenir une capture post-cleanup fiable des zones contenant les 10 contact ledges, classer pixel-based chaque ledge, puis décider retune minimal, disable ciblé, ou golden slice.
```

## 16. Probe manifest load

Contenu du probe temporaire `/tmp/shadow61_validate_selbrume_manifest_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';

void main() {
  test('shadow61 validate selbrume manifest', () async {
    final manifest = await loadProjectManifestFromFile(
      '/Users/karim/Desktop/selbrume/project.json',
    );

    expect(manifest.elements.length, 63);
    expect(manifest.elements.where((element) => element.shadow != null).length, 20);

    final byId = {for (final element in manifest.elements) element.id: element};
    for (final id in [
      'panneau',
      'lampadaire',
      'arbre_pixellab_1',
      'arbre_pixellab_2',
      'selbrume_maison_5',
    ]) {
      expect(byId[id], isNotNull, reason: '$id must exist');
      expect(byId[id]!.shadow, isNull, reason: '$id shadow must be null');
    }
  });
}
```

Commande : `cd packages/map_runtime && flutter test /tmp/shadow61_validate_selbrume_manifest_test.dart --plain-name 'shadow61 validate selbrume manifest'`

```text
00:00 +0: loading /tmp/shadow61_validate_selbrume_manifest_test.dart
00:00 +0: shadow61 validate selbrume manifest
00:00 +1: All tests passed!
```

## 17. Tests de régression repo

Commande : `cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
00:00 +0: loadProjectManifestFromFile authored shadow manifest keeps missing shadow configs absent at runtime load
00:00 +1: loadProjectManifestFromFile authored shadow manifest preserves recognized old auto shadows as authored data
00:00 +2: loadProjectManifestFromFile authored shadow manifest preserves manual and disabled shadows
00:00 +3: All tests passed!
```

Commande : `cd packages/map_runtime && flutter test test/shadow`

Ligne finale exacte :

```text
00:04 +233: All tests passed!
```

Commande : `cd packages/map_core && dart test test/shadow`

Ligne finale exacte :

```text
00:00 +284: All tests passed!
```

Commande : `cd packages/map_editor && flutter test test/application/shadow`

Ligne finale exacte :

```text
00:00 +96: All tests passed!
```

## 18. Ce qui n'a volontairement pas été modifié

- Aucun fichier Selbrume.
- Aucun fichier `packages/map_core/**`.
- Aucun fichier `packages/map_editor/**`.
- Aucun fichier `packages/map_runtime/**`.
- Aucun renderer.
- Aucune policy.
- Aucun profil Shadow.
- Aucune géométrie contact ledge.
- Aucune migration.
- Aucun screenshot harness permanent.
- Aucun commit.

## 19. git diff --stat

Commande : `git diff --stat`

```text
(aucune sortie)
```

## 20. git diff --name-status

Commande : `git diff --name-status`

```text
(aucune sortie)
```

## 21. git diff --check

Commande : `git diff --check`

```text
(aucune sortie)
```

## 22. git status final

Commande : `git status --short --untracked-files=all`

```text
?? reports/shadows/shadow_lot_61_selbrume_building_contact_ledge_visual_review_retune_decision.md
```

## 23. Risques / réserves

- La conclusion visuelle est limitée : pas de capture post-cleanup fiable produite dans ce lot.
- Les 10 ledges restantes sont encore dessinées comme `projectedPolygon` côté renderer, même si leur géométrie est `contactLedge`; il faut éviter de confondre shape bas niveau et intention produit.
- `test`, `objectif` et plusieurs éléments non placés visibles conservent des configs Shadow authorées sans instruction runtime courante. Ce n'est pas une régression visuelle immédiate, mais cela mérite un cleanup de données plus tard si ces éléments redeviennent visibles/placés.
- `le_puits` et `kiosque_l_gumes` utilisent la famille `building`; c'est probablement acceptable seulement après validation pixel-based.

## 24. Auto-critique

Ce lot répond bien à la question technique : il prouve que les plaques génériques ont disparu et que les 10 ombres restantes sont des contact ledges. Il ne répond pas complètement à la question artistique parce qu'une vraie capture post-cleanup manque. J'ai préféré ne pas inventer de harness permanent dans un lot qui l'interdisait explicitement.

La décision est donc volontairement prudente : `keep-provisional`, pas `keep` définitif.

## 25. Regard critique sur le prompt

Le prompt demande une revue visuelle mais interdit un screenshot harness permanent. Cette tension est saine : elle force à distinguer l'inventaire runtime de la validation pixel-based. Pour le prochain lot, il faudra autoriser explicitement soit une capture manuelle encadrée, soit un mini harness temporaire documenté, soit un harness de régression assumé.

## 26. Proposition de prompt pour le prochain lot

```md
# Shadow-62 — Selbrume Contact Ledge Screenshot Review / Visual Gate V0

Objectif : produire une capture post-cleanup fiable des 10 contact ledges restantes de Selbrume, sans modifier le rendu ni les données, puis décider pixel-based si chaque ledge est keep, retune, disable ou manual-review.

Contraintes :
- aucun patch de code de rendu ;
- aucun patch Selbrume ;
- capture temporaire autorisée sous reports/shadows/screenshots ;
- si un harness est nécessaire, il doit être temporaire ou explicitement livré comme outil de regression, selon validation utilisateur ;
- table finale des 10 ledges avec crop/capture, verdict et prochain lot.

Critère de sortie :
- si les ledges sont acceptables : Shadow-63 Screenshot Golden Slice / Regression Harness ;
- si elles sont trop visibles : Shadow-63 Building Contact Ledge Minimal Retune ;
- si puits/kiosque sont incohérents : Shadow-63 targeted data cleanup for non-building ledges.
```
