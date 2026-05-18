# Shadow-64 — Building Contact Ledge Minimal Depth Retune V0

## 1. Résumé exécutif

Shadow-64 implémente le design Shadow-63 validé : une seule constante de géométrie contact ledge building a été retunée.

```text
buildingStaticShadowContactLedgeMaxDepth : 20.0 -> 14.0
```

Le runtime renderer, la policy auto-shadow, les profils, les modèles, les codecs, Selbrume et les assets n'ont pas été modifiés.

Résultat mesuré sur Selbrume après retune :

```text
static instructions total : 10
contactLedge total       : 10
genericProjection total  : 0
height average           : 17.035750399999916
height max               : 17.483647999999903
area average             : 6521.864520204254
area max                 : 11158.372818616263
```

Comparaison Shadow-62 -> Shadow-64 :

```text
Chaque contact ledge perd exactement 6 px de profondeur.
Les 4 cas retune-next passent en keep-provisional.
Les 6 keep restent présents, alignés, et non dégradés visuellement.
```

## 2. Rappel Shadow-63 Design validé

Shadow-63 concluait que le problème restant était la profondeur/épaisseur trop visible de certains contact ledges sur chemins clairs, pas la largeur, pas l'opacité, pas l'alignement.

Option validée :

```text
Modifier uniquement buildingStaticShadowContactLedgeMaxDepth : 20.0 -> 14.0.
```

## 3. État initial du worktree

Shadow-63 a été commit et push avant Shadow-64.

```text
commit e8ffb35c docs: add shadow 63 contact ledge retune design
push origin main : main -> main
```

Premier état Shadow-64 capturé après le cycle TDD RED/GREEN de la constante, avant création du rapport :

```text
 M packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
 M packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
```

Note : le commit/push Shadow-63 a été effectué juste avant ce lot. Le premier `git status` strictement avant édition Shadow-64 n'a pas été recapturé dans le rapport, mais la base de travail vérifiée ensuite est `HEAD=e8ffb35c` et le diff de Shadow-64 ne touche que les fichiers listés plus bas.

## 4. Décision AGENTS / design gate satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Résultat :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md

765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision :

```text
Le design gate est satisfait par Shadow-63, explicitement validé par l'utilisateur.
Shadow-64 est l'implémentation du design validé.
Aucune règle AGENTS ne bloque l'implémentation chirurgicale demandée.
```

## 5. Fichiers modifiés

Fichiers de production modifiés :

```text
packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
```

Tests modifiés :

```text
packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
```

Fichiers créés :

```text
reports/shadows/shadow_lot_64_building_contact_ledge_minimal_depth_retune.md
reports/shadows/shadow_lot_64_visual_delta.tsv
reports/shadows/screenshots/shadow64_selbrume_overview.png
reports/shadows/screenshots/shadow64_contact_ledge_1_selbrum_maison_3.png
reports/shadows/screenshots/shadow64_contact_ledge_2_selbrum_maison_4.png
reports/shadows/screenshots/shadow64_contact_ledge_3_selbrum_maison_1.png
reports/shadows/screenshots/shadow64_contact_ledge_4_selbrume_centre_pok_mon.png
reports/shadows/screenshots/shadow64_contact_ledge_5_selbrum_maison_7.png
reports/shadows/screenshots/shadow64_contact_ledge_6_le_puits.png
reports/shadows/screenshots/shadow64_contact_ledge_7_selbrum_maison_4.png
reports/shadows/screenshots/shadow64_contact_ledge_8_selbrum_maison_2.png
reports/shadows/screenshots/shadow64_contact_ledge_9_selbrum_maison_8.png
reports/shadows/screenshots/shadow64_contact_ledge_10_kiosque_l_gumes.png
```

Fichiers temporaires créés hors repo :

```text
/tmp/shadow64_runtime_inventory_test.dart
/tmp/shadow64_capture_contact_ledges_test.dart
/tmp/shadow64_runtime_inventory.json
/tmp/shadow64_runtime_inventory.tsv
```

Fichiers Selbrume modifiés :

```text
Aucun.
```

Fichiers runtime/editor/profils/policy/modèles/codecs/assets modifiés :

```text
Aucun.
```

## 6. Changement exact de production

Diff :

```diff
diff --git a/packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart b/packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
index 52b7f69d..891ef39d 100644
--- a/packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
+++ b/packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
@@ -6,7 +6,7 @@ const buildingStaticShadowContactLedgeFarHalfWidthMultiplier = 0.62;
 const buildingStaticShadowContactLedgeNearHeightOffsetMultiplier = 0.18;
 const buildingStaticShadowContactLedgeDepthRatio = 0.055;
 const buildingStaticShadowContactLedgeMinDepth = 6.0;
-const buildingStaticShadowContactLedgeMaxDepth = 20.0;
+const buildingStaticShadowContactLedgeMaxDepth = 14.0;
 const buildingStaticShadowContactLedgeSkewRatio = 0.020;
 const buildingStaticShadowContactLedgeMinSkew = 0.0;
 const buildingStaticShadowContactLedgeMaxSkew = 7.0;
```

## 7. Tests modifiés/ajoutés

Test modifié :

```text
packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
```

Diff :

```diff
diff --git a/packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart b/packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
index 499edfcf..693025cc 100644
--- a/packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
+++ b/packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
@@ -9,7 +9,7 @@ void main() {
       expect(buildingStaticShadowContactLedgeNearHeightOffsetMultiplier, 0.18);
       expect(buildingStaticShadowContactLedgeDepthRatio, 0.055);
       expect(buildingStaticShadowContactLedgeMinDepth, 6);
-      expect(buildingStaticShadowContactLedgeMaxDepth, 20);
+      expect(buildingStaticShadowContactLedgeMaxDepth, 14);
       expect(buildingStaticShadowContactLedgeSkewRatio, 0.020);
       expect(buildingStaticShadowContactLedgeMinSkew, 0);
       expect(buildingStaticShadowContactLedgeMaxSkew, 7);
@@ -74,7 +74,7 @@ void main() {
         metrics: metrics,
       );
 
-      final depth = _clamp(metrics.visualHeight * 0.055, 6, 20);
+      final depth = _clamp(metrics.visualHeight * 0.055, 6, 14);
       final skew = _clamp(metrics.visualWidth * 0.020, 0, 7);
       expect(geometry.nearLeft.x,
           closeTo(base.centerX - base.width * 0.72, 0.000001));
@@ -153,7 +153,7 @@ void main() {
       );
       expect(
         largeGeometry.farLeft.y - _base(large).centerY,
-        closeTo(20, 0.000001),
+        closeTo(14, 0.000001),
       );
     });
```

Cycle TDD :

```text
RED : le test ciblé a été modifié avant la production et a échoué avec expected 14 / actual 20.0.
GREEN : la constante est passée à 14.0 et le test ciblé passe.
```

## 8. Résultats des tests ciblés

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_contact_ledge_geometry_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow/static_shadow_contact_ledge_geometry_test.dart
00:00 +0: building static shadow contact ledge constants defaults match Shadow-54 visible contact tuning
00:00 +1: building static shadow contact ledge constants defaults match Shadow-54 visible contact tuning
00:00 +1: resolveBuildingStaticShadowContactLedgeGeometry creates a shallow four point contact ledge
00:00 +2: resolveBuildingStaticShadowContactLedgeGeometry creates a shallow four point contact ledge
00:00 +2: resolveBuildingStaticShadowContactLedgeGeometry matches the Shadow-54 runtime formula exactly
00:00 +3: resolveBuildingStaticShadowContactLedgeGeometry matches the Shadow-54 runtime formula exactly
00:00 +3: resolveBuildingStaticShadowContactLedgeGeometry uses base footprint width
00:00 +4: resolveBuildingStaticShadowContactLedgeGeometry uses base footprint width
00:00 +4: resolveBuildingStaticShadowContactLedgeGeometry applies offset and scale only through base geometry
00:00 +5: resolveBuildingStaticShadowContactLedgeGeometry applies offset and scale only through base geometry
00:00 +5: resolveBuildingStaticShadowContactLedgeGeometry clamps minimum and maximum depth
00:00 +6: resolveBuildingStaticShadowContactLedgeGeometry clamps minimum and maximum depth
00:00 +6: resolveBuildingStaticShadowContactLedgeGeometry clamps maximum skew
00:00 +7: resolveBuildingStaticShadowContactLedgeGeometry clamps maximum skew
00:00 +7: resolveBuildingStaticShadowContactLedgeGeometry geometry is immutable and all points are finite
00:00 +8: resolveBuildingStaticShadowContactLedgeGeometry geometry is immutable and all points are finite
00:00 +8: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/static_shadow_contact_ledge_geometry.dart
```

Sortie :

```text
Analyzing static_shadow_contact_ledge_geometry.dart...
No issues found!
```

## 9. Résultats des régressions

Les logs complets de certaines suites sont bavards ; le rapport inclut les lignes finales exactes.

```text
cd packages/map_core && dart test test/shadow
00:00 +284: All tests passed!

cd packages/map_editor && flutter test test/application/shadow
00:00 +96: All tests passed!

cd packages/map_runtime && flutter test test/shadow
00:03 +233: All tests passed!

cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
00:00 +3: All tests passed!
```

## 10. Confirmation invariants Shadow-56 / 58 / 59

### Shadow-56 : runtime auto-apply absent

Commande :

```bash
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

Résultat exact :

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

Conclusion :

```text
map_runtime : aucun appel.
map_core : définition/tests.
map_editor : backfill explicite.
```

### Shadow-58 : policy durcie active

Commande :

```bash
rg -n "_autoShadowKindIsArtisticallySafe|case ElementAutoShadowSuggestionKind.buildingLarge|case ElementAutoShadowSuggestionKind.tallThin|case ElementAutoShadowSuggestionKind.wideLow|case ElementAutoShadowSuggestionKind.smallSquare|case ElementAutoShadowSuggestionKind.defaultProp" packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
```

Résultat exact :

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

### Shadow-59 : patch Selbrume toujours appliqué

Commande :

```bash
jq -r '.elements[] | select(.id=="panneau" or .id=="lampadaire" or .id=="arbre_pixellab_1" or .id=="arbre_pixellab_2" or .id=="selbrume_maison_5") | [.id, .name, (.shadow == null)] | @tsv' /Users/karim/Desktop/selbrume/project.json
```

Résultat exact :

```text
selbrume_maison_5	selbrume maison 5	true
lampadaire	lampadaire	true
arbre_pixellab_1	arbre  pixelLab 1	true
arbre_pixellab_2	arbre  pixelLab 2	true
panneau	panneau	true
```

Compteurs Selbrume :

```text
jq -r '[.elements[] | select(.shadow != null)] | length' /Users/karim/Desktop/selbrume/project.json
20

jq -r '[.elements[] | select(.shadow == null)] | length' /Users/karim/Desktop/selbrume/project.json
43

jq -r '.elements | length' /Users/karim/Desktop/selbrume/project.json
63

jq -r '[.. | objects | select(has("shadowOverride"))] as $placed | [$placed|length, ($placed|map(select(.shadowOverride != null))|length), ($placed|map(select(.shadowOverride == null))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json
2105	0	2105
```

Hashes Selbrume :

```text
3c3669a8274e31087b617fd46337c28aef6593f376a7d0a54c2d9fb8e31b389d  /Users/karim/Desktop/selbrume/project.json
8fd1f7efdc02413106a21068e3af310b3149c07023cfad64ddaa101f2c2cac63  /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

## 11. Inventaire runtime before/after

Before Shadow-64, source Shadow-62 :

```text
static instructions total : 10
contactLedge total       : 10
genericProjection total  : 0
height average           : 23.035750399999915
area average             : 8814.700582204255
retune-next              : ranks 2, 5, 7, 10
```

After Shadow-64, commande :

```bash
cd packages/map_runtime && flutter test /tmp/shadow64_runtime_inventory_test.dart --plain-name 'shadow64 runtime inventory'
```

Sortie :

```text
00:00 +0: loading /tmp/shadow64_runtime_inventory_test.dart
00:00 +0: shadow64 runtime inventory
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
  "heightAverage": 17.035750399999916,
  "heightMax": 17.483647999999903,
  "areaAverage": 6521.864520204254,
  "areaMax": 11158.372818616263
}
00:00 +1: All tests passed!
```

Inventaire complet after :

```text
rank	placementId/index	elementId	elementName	worldX	worldY	instructionLeft	instructionTop	instructionWidth	instructionHeight	instructionArea	opacity	shapeKind	geometryType	renderPass	family	shadowProfileId
1	l_tile_maison_selbrume::24::12	selbrum_maison_3	selbrum maison 3	2304.0	1152.0	2449.12128	1807.076352	477.7574400000003	17.483647999999903	8352.942910341078	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse
2	l_tile_maison_selbrume::17::17	selbrum_maison_4	selbrum maison  4	1632.0	1632.0	1722.7008	2193.494016	298.59839999999986	16.985983999999917	5071.987644825573	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse
3	l_tile_maison_selbrume::10::18	selbrum_maison_1	selbrum maison 1	960.0	1728.0	1050.7008	2289.494016	298.59839999999986	16.985983999999917	5071.987644825573	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse
4	l_tile_maison_selbrume::29::22	selbrume_centre_pok_mon	selbrume centre pokémon	2784.0	2112.0	2929.12128	2673.494016	477.7574400000003	16.985983999999917	8115.180231720926	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse
5	l_tile_maison_selbrume::38::22	selbrum_maison_7	selbrum maison  7	3648.0	2112.0	3756.84096	2673.494016	358.31807999999955	16.985983999999917	6086.3851737906825	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse
6	l_tile_maison_selbrume::23::27	le_puits	le puits	2208.0	2592.0	2280.56064	3059.91168	238.8787199999997	16.48831999999993	3938.7087765503784	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse
7	l_tile_maison_selbrume::36::29	selbrum_maison_4	selbrum maison  4	3456.0	2784.0	3546.7008	3345.494016	298.59839999999986	16.985983999999917	5071.987644825573	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse
8	l_tile_maison_selbrume::10::30	selbrum_maison_2	selbrum maison  2	960.0	2880.0	1068.84096	3535.076352	358.31808	17.483647999999903	6264.707182755806	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse
9	l_tile_maison_selbrume::18::33	selbrum_maison_8	selbrum maison  8	1728.0	3168.0	1927.54176	3729.494016	656.9164799999999	16.985983999999917	11158.372818616263	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse
10	l_tile_maison_selbrume::36::35	kiosque_l_gumes	kiosque à légumes	3456.0	3360.0	3564.84096	3921.494016	358.31808	16.985983999999917	6086.385173790691	0.2	projectedPolygon	contactLedge	groundStatic	building	default-ground-wide-ellipse
```

## 12. Captures after produites

Commande :

```bash
cd packages/map_runtime && flutter test /tmp/shadow64_capture_contact_ledges_test.dart --plain-name 'shadow64 capture contact ledges'
```

Sortie :

```text
00:00 +0: loading /tmp/shadow64_capture_contact_ledges_test.dart
00:00 +0: shadow64 capture contact ledges
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_selbrume_overview.png
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_1_selbrum_maison_3.png
capture rank=1 element=selbrum_maison_3 cropLeft=2189.1 cropTop=1377.1
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_2_selbrum_maison_4.png
capture rank=2 element=selbrum_maison_4 cropLeft=1462.7 cropTop=1763.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_3_selbrum_maison_1.png
capture rank=3 element=selbrum_maison_1 cropLeft=790.7 cropTop=1859.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_4_selbrume_centre_pok_mon.png
capture rank=4 element=selbrume_centre_pok_mon cropLeft=2669.1 cropTop=2243.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_5_selbrum_maison_7.png
capture rank=5 element=selbrum_maison_7 cropLeft=3496.8 cropTop=2243.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_6_le_puits.png
capture rank=6 element=le_puits cropLeft=2020.6 cropTop=2629.9
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_7_selbrum_maison_4.png
capture rank=7 element=selbrum_maison_4 cropLeft=3286.7 cropTop=2915.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_8_selbrum_maison_2.png
capture rank=8 element=selbrum_maison_2 cropLeft=808.8 cropTop=3105.1
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_9_selbrum_maison_8.png
capture rank=9 element=selbrum_maison_8 cropLeft=1667.5 cropTop=3299.5
wrote /Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_10_kiosque_l_gumes.png
capture rank=10 element=kiosque_l_gumes cropLeft=3304.8 cropTop=3491.5
00:01 +1: All tests passed!
```

Captures, tailles et hashes :

```text
57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4  reports/shadows/screenshots/shadow64_contact_ledge_10_kiosque_l_gumes.png 158827 bytes
f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48  reports/shadows/screenshots/shadow64_contact_ledge_1_selbrum_maison_3.png 180911 bytes
c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472  reports/shadows/screenshots/shadow64_contact_ledge_2_selbrum_maison_4.png 168205 bytes
27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd  reports/shadows/screenshots/shadow64_contact_ledge_3_selbrum_maison_1.png 181666 bytes
4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a  reports/shadows/screenshots/shadow64_contact_ledge_4_selbrume_centre_pok_mon.png 162048 bytes
568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530  reports/shadows/screenshots/shadow64_contact_ledge_5_selbrum_maison_7.png 177970 bytes
eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a  reports/shadows/screenshots/shadow64_contact_ledge_6_le_puits.png 146654 bytes
4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796  reports/shadows/screenshots/shadow64_contact_ledge_7_selbrum_maison_4.png 151150 bytes
f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8  reports/shadows/screenshots/shadow64_contact_ledge_8_selbrum_maison_2.png 183159 bytes
e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3  reports/shadows/screenshots/shadow64_contact_ledge_9_selbrum_maison_8.png 159359 bytes
5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25  reports/shadows/screenshots/shadow64_selbrume_overview.png 2529901 bytes
```

## 13. Comparaison visuelle Shadow-62 vs Shadow-64

Table complète :

```text
rank	elementId	shadow62Decision	shadow64Decision	beforeHeight	afterHeight	heightDelta	beforeArea	afterArea	areaDelta	beforePath	afterPath	passFail	reason
1	selbrum_maison_3	keep	keep	23.483648	17.483648	-6.000000	11219.487550	8352.942910	-2866.544640	reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png	reports/shadows/screenshots/shadow64_contact_ledge_1_selbrum_maison_3.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
2	selbrum_maison_4	retune-next	keep-provisional	22.985984	16.985984	-6.000000	6863.578045	5071.987645	-1791.590400	reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png	reports/shadows/screenshots/shadow64_contact_ledge_2_selbrum_maison_4.png	pass	retune-next ledge is 6 px shallower and reads more subtle on the same crop
3	selbrum_maison_1	keep	keep	22.985984	16.985984	-6.000000	6863.578045	5071.987645	-1791.590400	reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png	reports/shadows/screenshots/shadow64_contact_ledge_3_selbrum_maison_1.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
4	selbrume_centre_pok_mon	keep	keep	22.985984	16.985984	-6.000000	10981.724872	8115.180232	-2866.544640	reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png	reports/shadows/screenshots/shadow64_contact_ledge_4_selbrume_centre_pok_mon.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
5	selbrum_maison_7	retune-next	keep-provisional	22.985984	16.985984	-6.000000	8236.293654	6086.385174	-2149.908480	reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png	reports/shadows/screenshots/shadow64_contact_ledge_5_selbrum_maison_7.png	pass	retune-next ledge is 6 px shallower and reads more subtle on the same crop
6	le_puits	keep	keep	22.488320	16.488320	-6.000000	5371.981097	3938.708777	-1433.272320	reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png	reports/shadows/screenshots/shadow64_contact_ledge_6_le_puits.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
7	selbrum_maison_4	retune-next	keep-provisional	22.985984	16.985984	-6.000000	6863.578045	5071.987645	-1791.590400	reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png	reports/shadows/screenshots/shadow64_contact_ledge_7_selbrum_maison_4.png	pass	retune-next ledge is 6 px shallower and reads more subtle on the same crop
8	selbrum_maison_2	keep	keep	23.483648	17.483648	-6.000000	8414.615663	6264.707183	-2149.908480	reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png	reports/shadows/screenshots/shadow64_contact_ledge_8_selbrum_maison_2.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
9	selbrum_maison_8	keep	keep	22.985984	16.985984	-6.000000	15099.871699	11158.372819	-3941.498880	reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png	reports/shadows/screenshots/shadow64_contact_ledge_9_selbrum_maison_8.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
10	kiosque_l_gumes	retune-next	keep-provisional	22.985984	16.985984	-6.000000	8236.293654	6086.385174	-2149.908480	reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png	reports/shadows/screenshots/shadow64_contact_ledge_10_kiosque_l_gumes.png	pass	retune-next ledge is 6 px shallower and reads more subtle on the same crop
```

Hashes before/after des 4 cas retune-next :

```text
792fe167919624a8f898300a63cd73a69afde7c01ef20dd6c84375bfa24b52df  reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png
c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472  reports/shadows/screenshots/shadow64_contact_ledge_2_selbrum_maison_4.png
588510a2ba09b6a34800d74a9d4b488c7d6a1c82675fbbe365c21b37b2b4a201  reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png
568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530  reports/shadows/screenshots/shadow64_contact_ledge_5_selbrum_maison_7.png
a07272dd09d00e37480a563e43839cd061e5c20830ad59749bf98f537ea19e23  reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png
4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796  reports/shadows/screenshots/shadow64_contact_ledge_7_selbrum_maison_4.png
3b6140f47ad0b67d0ae1f8fc4d23189407b459007732fb3eb388142a75e970c1  reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png
57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4  reports/shadows/screenshots/shadow64_contact_ledge_10_kiosque_l_gumes.png
```

## 14. Décision visuelle finale

Décision :

```text
retune-next improved : 4 / 4
keep unchanged       : 6 / 6
genericProjection    : 0
static instructions  : 10
contact ledges       : 10
```

Interprétation :

```text
Le retune est volontairement discret.
Les 4 cas sur chemins clairs sont moins épais et ne lisent plus comme une correction à faire immédiatement.
Les 6 cas déjà acceptables restent visibles/cohérents sans devenir trop fins.
```

Décisions Shadow-64 :

```text
keep             : ranks 1, 3, 4, 6, 8, 9
keep-provisional : ranks 2, 5, 7, 10
retune-next      : aucun
disable-next     : aucun
manual-review    : aucun
```

## 15. Ce qui n'a volontairement pas été modifié

```text
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
/Users/karim/Desktop/selbrume/project.shadow59.before.json
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
assets/**
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/lib/src/operations/shadow_config_resolver.dart
packages/map_core/lib/src/models/shadow.dart
packages/map_core/lib/src/models/shadow_catalog.dart
```

## 16. git diff --stat

Commande :

```bash
git diff --stat
```

Résultat :

```text
 .../lib/src/operations/static_shadow_contact_ledge_geometry.dart    | 2 +-
 .../test/shadow/static_shadow_contact_ledge_geometry_test.dart      | 6 +++---
 2 files changed, 4 insertions(+), 4 deletions(-)
```

## 17. git diff --name-status

Commande :

```bash
git diff --name-status
```

Résultat :

```text
M	packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
M	packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
```

## 18. git diff --check

Commande :

```bash
git diff --check
```

Résultat :

```text
No output. Exit code 0.
```

## 19. git status final

État attendu après écriture du rapport :

```text
 M packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
 M packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
?? reports/shadows/screenshots/shadow64_contact_ledge_10_kiosque_l_gumes.png
?? reports/shadows/screenshots/shadow64_contact_ledge_1_selbrum_maison_3.png
?? reports/shadows/screenshots/shadow64_contact_ledge_2_selbrum_maison_4.png
?? reports/shadows/screenshots/shadow64_contact_ledge_3_selbrum_maison_1.png
?? reports/shadows/screenshots/shadow64_contact_ledge_4_selbrume_centre_pok_mon.png
?? reports/shadows/screenshots/shadow64_contact_ledge_5_selbrum_maison_7.png
?? reports/shadows/screenshots/shadow64_contact_ledge_6_le_puits.png
?? reports/shadows/screenshots/shadow64_contact_ledge_7_selbrum_maison_4.png
?? reports/shadows/screenshots/shadow64_contact_ledge_8_selbrum_maison_2.png
?? reports/shadows/screenshots/shadow64_contact_ledge_9_selbrum_maison_8.png
?? reports/shadows/screenshots/shadow64_selbrume_overview.png
?? reports/shadows/shadow_lot_64_building_contact_ledge_minimal_depth_retune.md
?? reports/shadows/shadow_lot_64_visual_delta.tsv
```

## 20. Risques / réserves

```text
- Le retune est global à la géométrie contact ledge building, donc il affecte tous les futurs contact ledges building.
- Les captures montrent une amélioration discrète, pas une refonte visuelle.
- Les décisions keep-provisional restent prudentes : une validation utilisateur in-app peut encore être utile.
- Les captures sont générées par un probe temporaire, pas par un harness golden permanent.
```

## 21. Auto-critique

```text
- Le lot respecte bien l'intention unique : profondeur max seulement.
- La vérification runtime prouve que le nombre d'instructions et genericProjection restent stables.
- Les captures after existent pour les mêmes ranks que Shadow-62.
- Le rapport est lourd parce que les preuves demandées sont nombreuses, mais les changements de code restent minuscules.
- Une lacune : le tout premier git status avant édition Shadow-64 n'a pas été recapturé séparément après le commit/push Shadow-63 ; la base HEAD et le diff final compensent partiellement cette preuve.
```

## 22. Regard critique sur le prompt

Le prompt est très bon pour empêcher le glissement de scope : une constante, pas de tuning multiple, pas de données Selbrume, pas de renderer.

Point à améliorer :

```text
Le prompt demande des screenshots after et une comparaison visuelle, mais ne précise pas si une validation pixel-diff automatique est obligatoire. Ici, la comparaison s'appuie sur captures, hashes, inspection visuelle et métriques géométriques.
```

## 23. Prochain lot recommandé

```text
Shadow-65 — Selbrume Contact Ledge Golden Slice / Regression Harness V0
```

Objectif :

```text
Transformer les captures manuelles Shadow-62/64 en garde-fou reproductible,
sans retune supplémentaire tant qu'aucune nouvelle régression visuelle n'est prouvée.
```

## Code complet des fichiers créés/modifiés

### packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart

```dart
import 'static_shadow_geometry.dart';
import 'static_shadow_projection_geometry.dart';

const buildingStaticShadowContactLedgeNearHalfWidthMultiplier = 0.72;
const buildingStaticShadowContactLedgeFarHalfWidthMultiplier = 0.62;
const buildingStaticShadowContactLedgeNearHeightOffsetMultiplier = 0.18;
const buildingStaticShadowContactLedgeDepthRatio = 0.055;
const buildingStaticShadowContactLedgeMinDepth = 6.0;
const buildingStaticShadowContactLedgeMaxDepth = 14.0;
const buildingStaticShadowContactLedgeSkewRatio = 0.020;
const buildingStaticShadowContactLedgeMinSkew = 0.0;
const buildingStaticShadowContactLedgeMaxSkew = 7.0;

ProjectedStaticShadowGeometry resolveBuildingStaticShadowContactLedgeGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
}) {
  final centerX = baseGeometry.centerX;
  final nearY = baseGeometry.centerY -
      baseGeometry.height *
          buildingStaticShadowContactLedgeNearHeightOffsetMultiplier;
  final farY =
      baseGeometry.centerY + _buildingStaticShadowContactLedgeDepth(metrics);
  final nearHalfWidth = baseGeometry.width *
      buildingStaticShadowContactLedgeNearHalfWidthMultiplier;
  final farHalfWidth = baseGeometry.width *
      buildingStaticShadowContactLedgeFarHalfWidthMultiplier;
  final skewX = _buildingStaticShadowContactLedgeSkew(metrics);

  return ProjectedStaticShadowGeometry(
    nearLeft: ProjectedStaticShadowPoint(
      x: centerX - nearHalfWidth,
      y: nearY,
    ),
    nearRight: ProjectedStaticShadowPoint(
      x: centerX + nearHalfWidth,
      y: nearY,
    ),
    farRight: ProjectedStaticShadowPoint(
      x: centerX + skewX + farHalfWidth,
      y: farY,
    ),
    farLeft: ProjectedStaticShadowPoint(
      x: centerX + skewX - farHalfWidth,
      y: farY,
    ),
  );
}

double _buildingStaticShadowContactLedgeDepth(
  StaticShadowVisualMetrics metrics,
) {
  return _clampDouble(
    metrics.visualHeight * buildingStaticShadowContactLedgeDepthRatio,
    buildingStaticShadowContactLedgeMinDepth,
    buildingStaticShadowContactLedgeMaxDepth,
  );
}

double _buildingStaticShadowContactLedgeSkew(
  StaticShadowVisualMetrics metrics,
) {
  return _clampDouble(
    metrics.visualWidth * buildingStaticShadowContactLedgeSkewRatio,
    buildingStaticShadowContactLedgeMinSkew,
    buildingStaticShadowContactLedgeMaxSkew,
  );
}

double _clampDouble(double value, double min, double max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}
```

### packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('building static shadow contact ledge constants', () {
    test('defaults match Shadow-54 visible contact tuning', () {
      expect(buildingStaticShadowContactLedgeNearHalfWidthMultiplier, 0.72);
      expect(buildingStaticShadowContactLedgeFarHalfWidthMultiplier, 0.62);
      expect(buildingStaticShadowContactLedgeNearHeightOffsetMultiplier, 0.18);
      expect(buildingStaticShadowContactLedgeDepthRatio, 0.055);
      expect(buildingStaticShadowContactLedgeMinDepth, 6);
      expect(buildingStaticShadowContactLedgeMaxDepth, 14);
      expect(buildingStaticShadowContactLedgeSkewRatio, 0.020);
      expect(buildingStaticShadowContactLedgeMinSkew, 0);
      expect(buildingStaticShadowContactLedgeMaxSkew, 7);
    });
  });

  group('resolveBuildingStaticShadowContactLedgeGeometry', () {
    test('creates a shallow four point contact ledge', () {
      final metrics = StaticShadowVisualMetrics(
        left: 160,
        top: 96,
        visualWidth: 192,
        visualHeight: 224,
      );
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(scaleX: 0.72, scaleY: 0.44),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.6,
          footprintHeightRatio: 0.08,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      expect(geometry.points, hasLength(4));
      expect(geometry.nearLeft.y, closeTo(geometry.nearRight.y, 0.000001));
      expect(geometry.farLeft.y, closeTo(geometry.farRight.y, 0.000001));
      expect(geometry.farLeft.y, greaterThan(geometry.nearLeft.y));
      expect(geometry.farRight.y, greaterThan(geometry.nearRight.y));
      expect(_bounds(geometry).height, greaterThan(13));
      expect(_bounds(geometry).height, lessThan(15));
      expect(_bounds(geometry).width, greaterThan(118));
      expect(_bounds(geometry).width, lessThan(121));
    });

    test('matches the Shadow-54 runtime formula exactly', () {
      final metrics = StaticShadowVisualMetrics(
        left: 160,
        top: 96,
        visualWidth: 192,
        visualHeight: 224,
      );
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(scaleX: 0.72, scaleY: 0.44),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.6,
          footprintHeightRatio: 0.08,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      final depth = _clamp(metrics.visualHeight * 0.055, 6, 14);
      final skew = _clamp(metrics.visualWidth * 0.020, 0, 7);
      expect(geometry.nearLeft.x,
          closeTo(base.centerX - base.width * 0.72, 0.000001));
      expect(geometry.nearLeft.y,
          closeTo(base.centerY - base.height * 0.18, 0.000001));
      expect(geometry.nearRight.x,
          closeTo(base.centerX + base.width * 0.72, 0.000001));
      expect(geometry.nearRight.y,
          closeTo(base.centerY - base.height * 0.18, 0.000001));
      expect(geometry.farRight.x,
          closeTo(base.centerX + skew + base.width * 0.62, 0.000001));
      expect(geometry.farRight.y, closeTo(base.centerY + depth, 0.000001));
      expect(geometry.farLeft.x,
          closeTo(base.centerX + skew - base.width * 0.62, 0.000001));
      expect(geometry.farLeft.y, closeTo(base.centerY + depth, 0.000001));
    });

    test('uses base footprint width', () {
      final metrics = _metrics();
      final narrow = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics, footprintWidthRatio: 0.25),
        metrics: metrics,
      );
      final wide = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics, footprintWidthRatio: 0.75),
        metrics: metrics,
      );

      expect(_bounds(narrow).width, lessThan(_bounds(wide).width));
    });

    test('applies offset and scale only through base geometry', () {
      final metrics = _metrics();
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(
          offsetX: 5,
          offsetY: 7,
          scaleX: 2,
          scaleY: 0.5,
        ),
        elementFootprint: StaticShadowFootprintConfig(
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.2,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      final nearCenterX = (geometry.nearLeft.x + geometry.nearRight.x) / 2;
      expect(nearCenterX, closeTo(base.centerX, 0.000001));
      expect(_bounds(geometry).width, greaterThan(base.width));
      expect(_bounds(geometry).height, greaterThan(7));
      expect(_bounds(geometry).height, lessThan(9));
    });

    test('clamps minimum and maximum depth', () {
      final small = _metrics(visualHeight: 24);
      final large = _metrics(visualHeight: 800);

      final smallGeometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(small),
        metrics: small,
      );
      final largeGeometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(large),
        metrics: large,
      );

      expect(
        smallGeometry.farLeft.y - _base(small).centerY,
        closeTo(6, 0.000001),
      );
      expect(
        largeGeometry.farLeft.y - _base(large).centerY,
        closeTo(14, 0.000001),
      );
    });

    test('clamps maximum skew', () {
      final metrics = _metrics(visualWidth: 640);
      final base = _base(metrics);

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      final farCenterX = (geometry.farLeft.x + geometry.farRight.x) / 2;
      expect(farCenterX - base.centerX, closeTo(7, 0.000001));
    });

    test('geometry is immutable and all points are finite', () {
      final metrics = _metrics();
      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics),
        metrics: metrics,
      );

      for (final point in geometry.points) {
        expect(point.x.isFinite, isTrue);
        expect(point.y.isFinite, isTrue);
      }
      expect(() => geometry.points.add(ProjectedStaticShadowPoint(x: 0, y: 0)),
          throwsUnsupportedError);
    });
  });
}

StaticShadowVisualMetrics _metrics({
  double left = 80,
  double top = 120,
  double visualWidth = 40,
  double visualHeight = 60,
}) {
  return StaticShadowVisualMetrics(
    left: left,
    top: top,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
}

ResolvedStaticShadowGeometry _base(
  StaticShadowVisualMetrics metrics, {
  double footprintWidthRatio = 0.5,
}) {
  return resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: _shadowConfig(),
    elementFootprint: StaticShadowFootprintConfig(
      footprintWidthRatio: footprintWidthRatio,
      footprintHeightRatio: 0.2,
    ),
  );
}

ResolvedShadowConfig _shadowConfig({
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: 'test-shadow',
    mode: ShadowCasterMode.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: 1,
    colorHexRgb: '000000',
    softnessMode: ShadowSoftnessMode.hardEdge,
  );
}

_TestBounds _bounds(ProjectedStaticShadowGeometry geometry) {
  final points = geometry.points;
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }
  return _TestBounds(width: maxX - minX, height: maxY - minY);
}

double _clamp(double value, double min, double max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

final class _TestBounds {
  const _TestBounds({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;
}
```

### reports/shadows/shadow_lot_64_visual_delta.tsv

```tsv
rank	elementId	shadow62Decision	shadow64Decision	beforeHeight	afterHeight	heightDelta	beforeArea	afterArea	areaDelta	beforePath	afterPath	passFail	reason
1	selbrum_maison_3	keep	keep	23.483648	17.483648	-6.000000	11219.487550	8352.942910	-2866.544640	reports/shadows/screenshots/shadow62_contact_ledge_1_selbrum_maison_3.png	reports/shadows/screenshots/shadow64_contact_ledge_1_selbrum_maison_3.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
2	selbrum_maison_4	retune-next	keep-provisional	22.985984	16.985984	-6.000000	6863.578045	5071.987645	-1791.590400	reports/shadows/screenshots/shadow62_contact_ledge_2_selbrum_maison_4.png	reports/shadows/screenshots/shadow64_contact_ledge_2_selbrum_maison_4.png	pass	retune-next ledge is 6 px shallower and reads more subtle on the same crop
3	selbrum_maison_1	keep	keep	22.985984	16.985984	-6.000000	6863.578045	5071.987645	-1791.590400	reports/shadows/screenshots/shadow62_contact_ledge_3_selbrum_maison_1.png	reports/shadows/screenshots/shadow64_contact_ledge_3_selbrum_maison_1.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
4	selbrume_centre_pok_mon	keep	keep	22.985984	16.985984	-6.000000	10981.724872	8115.180232	-2866.544640	reports/shadows/screenshots/shadow62_contact_ledge_4_selbrume_centre_pok_mon.png	reports/shadows/screenshots/shadow64_contact_ledge_4_selbrume_centre_pok_mon.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
5	selbrum_maison_7	retune-next	keep-provisional	22.985984	16.985984	-6.000000	8236.293654	6086.385174	-2149.908480	reports/shadows/screenshots/shadow62_contact_ledge_5_selbrum_maison_7.png	reports/shadows/screenshots/shadow64_contact_ledge_5_selbrum_maison_7.png	pass	retune-next ledge is 6 px shallower and reads more subtle on the same crop
6	le_puits	keep	keep	22.488320	16.488320	-6.000000	5371.981097	3938.708777	-1433.272320	reports/shadows/screenshots/shadow62_contact_ledge_6_le_puits.png	reports/shadows/screenshots/shadow64_contact_ledge_6_le_puits.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
7	selbrum_maison_4	retune-next	keep-provisional	22.985984	16.985984	-6.000000	6863.578045	5071.987645	-1791.590400	reports/shadows/screenshots/shadow62_contact_ledge_7_selbrum_maison_4.png	reports/shadows/screenshots/shadow64_contact_ledge_7_selbrum_maison_4.png	pass	retune-next ledge is 6 px shallower and reads more subtle on the same crop
8	selbrum_maison_2	keep	keep	23.483648	17.483648	-6.000000	8414.615663	6264.707183	-2149.908480	reports/shadows/screenshots/shadow62_contact_ledge_8_selbrum_maison_2.png	reports/shadows/screenshots/shadow64_contact_ledge_8_selbrum_maison_2.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
9	selbrum_maison_8	keep	keep	22.985984	16.985984	-6.000000	15099.871699	11158.372819	-3941.498880	reports/shadows/screenshots/shadow62_contact_ledge_9_selbrum_maison_8.png	reports/shadows/screenshots/shadow64_contact_ledge_9_selbrum_maison_8.png	pass	previous keep remains present, aligned, and not visually worse after 6 px depth reduction
10	kiosque_l_gumes	retune-next	keep-provisional	22.985984	16.985984	-6.000000	8236.293654	6086.385174	-2149.908480	reports/shadows/screenshots/shadow62_contact_ledge_10_kiosque_l_gumes.png	reports/shadows/screenshots/shadow64_contact_ledge_10_kiosque_l_gumes.png	pass	retune-next ledge is 6 px shallower and reads more subtle on the same crop
```

## Contenu complet des probes temporaires

### /tmp/shadow64_runtime_inventory_test.dart

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
  test('shadow64 runtime inventory', () async {
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
        final geometryType =
            instruction.shape == ShadowRuntimeShapeKind.projectedPolygon &&
                    family == StaticShadowFamily.building
                ? 'contactLedge'
                : instruction.shape.name;
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
    final heights =
        rows.map((row) => row['instructionHeight']! as double).toList();
    final widths =
        rows.map((row) => row['instructionWidth']! as double).toList();
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
      'opacityAverage': _avg(opacities),
      'opacityMax': _max(opacities),
      'widthAverage': _avg(widths),
      'widthMax': _max(widths),
      'heightAverage': _avg(heights),
      'heightMax': _max(heights),
      'areaAverage': _avg(areas),
      'areaMax': _max(areas),
      'rows': rows,
    };

    await File('/tmp/shadow64_runtime_inventory.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(summary),
    );
    await File('/tmp/shadow64_runtime_inventory.tsv').writeAsString(
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
      'heightAverage': summary['heightAverage'],
      'heightMax': summary['heightMax'],
      'areaAverage': summary['areaAverage'],
      'areaMax': summary['areaMax'],
    }));

    expect(rows.length, 10);
    expect(byGeometryType['contactLedge'] ?? 0, 10);
    expect(byFamily['genericProjection'] ?? 0, 0);
  });
}

double _avg(List<double> values) =>
    values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

double _max(List<double> values) =>
    values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

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
  ];
  final lines = <String>[headers.join('\t')];
  for (final row in rows) {
    lines.add(headers.map((header) => '${row[header] ?? ''}').join('\t'));
  }
  return '${lines.join('\n')}\n';
}
```

### /tmp/shadow64_capture_contact_ledges_test.dart

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_sources.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shadow64 capture contact ledges', () async {
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
    const overviewScale = 0.25;
    await _renderCapture(
      layer,
      filePath:
          '/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_selbrume_overview.png',
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
      final cropLeft =
          (capture.instructionLeft - 260).clamp(0, worldWidth - 900);
      final cropTop =
          (capture.instructionTop - 430).clamp(0, worldHeight - 650);
      await _renderCapture(
        layer,
        filePath:
            '/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow64_contact_ledge_${capture.rank}_${capture.elementId}.png',
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
