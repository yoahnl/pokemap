# Shadow-65 — Selbrume Shadow Screenshot Harness V0

## 1. Résumé exécutif

Shadow-65 transforme la capture temporaire Shadow-62/64 en harness reproductible, placé hors des suites normales.

Livré :

- harness manuel : `packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart` ;
- documentation : `packages/map_runtime/tool/shadow/README.md` ;
- 11 captures `shadow65_*` sous `reports/shadows/screenshots/` ;
- index TSV : `reports/shadows/shadow_lot_65_capture_index.tsv` ;
- manifest JSON : `reports/shadows/shadow_lot_65_capture_manifest.json` ;
- rapport : `reports/shadows/shadow_lot_65_selbrume_shadow_screenshot_harness.md`.

Le harness charge Selbrume via le runtime, rend `MapLayersComponent` offscreen dans un `PictureRecorder`, écrit les PNG, indexe les 10 contact ledges restantes, puis vérifie :

```text
staticInstructions = 10
contactLedge = 10
genericProjection = 0
```

Aucun fichier Selbrume n'a été modifié. Aucun code de rendu, renderer, policy, profil, modèle, codec ou géométrie Shadow n'a été modifié.

## 2. Rappel Shadow-64

Shadow-64 a appliqué le retune validé par Shadow-63 : `buildingStaticShadowContactLedgeMaxDepth` est passé de `20.0` à `14.0`. Les captures Shadow-64 ont montré que les 10 ombres restantes étaient toujours des contact ledges building, avec `genericProjection = 0`.

Shadow-65 ne retune rien. Il rend la capture relançable.

## 3. Nature du harness V0

Le harness V0 est un outil manuel de visual gate. Il n'est pas un golden test bloquant :

- il ne compare pas les pixels à une baseline ;
- il n'est pas sous `packages/map_runtime/test/` ;
- il est lancé explicitement avec `flutter test tool/shadow/selbrume_shadow_capture_test.dart` depuis `packages/map_runtime` ;
- il produit des artefacts reproductibles avec chemins, tailles, hashes et métadonnées runtime.

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
(aucune sortie)
```

## 5. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision : le design gate ne bloque pas Shadow-65. Le lot ajoute un outil manuel non-production et ne modifie ni le rendu produit, ni la géométrie, ni les données Selbrume, ni l'architecture métier. Le design des visual gates a déjà été cadré par Shadow-62/63/64.

Skill / docs : `superpowers:using-superpowers`, `karpathy-guidelines`, `test-driven-development`, `verification-before-completion` ont guidé le flux. `flame_docs` a été interrogé pour le rendu Flame/Canvas, mais les recherches n'ont pas retourné de résultat exploitable ; j'ai donc suivi les patterns locaux existants (`MapLayersComponent.render(canvas)`, `PictureRecorder`) déjà utilisés par les probes Shadow-62/64.

## 6. Fichiers créés

Textes / code :

```text
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
packages/map_runtime/tool/shadow/README.md
reports/shadows/shadow_lot_65_capture_index.tsv
reports/shadows/shadow_lot_65_capture_manifest.json
reports/shadows/shadow_lot_65_selbrume_shadow_screenshot_harness.md
```

Binaires :

```text
reports/shadows/screenshots/shadow65_selbrume_overview.png
reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png
reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png
reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png
reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png
reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png
reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png
reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png
reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png
reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png
reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png
```

## 7. Fichiers modifiés

Aucun fichier existant suivi par Git n'a été modifié. Les changements Shadow-65 sont des fichiers nouveaux non suivis.

Fichiers Selbrume lus mais non modifiés :

```text
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Hashes Selbrume après le lot :

```text
3c3669a8274e31087b617fd46337c28aef6593f376a7d0a54c2d9fb8e31b389d  /Users/karim/Desktop/selbrume/project.json
8fd1f7efdc02413106a21068e3af310b3149c07023cfad64ddaa101f2c2cac63  /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

## 8. Commande de lancement du harness

La commande racine proposée dans le prompt a été testée conceptuellement mais le repo n'a pas de `pubspec.yaml` racine :

```text
Error: No pubspec.yaml file found.
This command should be run from the root of your Flutter project.
```

Commande reproductible documentée et vérifiée :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow65 SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

## 9. Variables d'environnement

Le harness accepte :

```text
SELBRUME_PROJECT_PATH
SHADOW_SCREENSHOT_OUTPUT_DIR
SHADOW_SCREENSHOT_PREFIX
```

Valeurs par défaut :

```text
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots
SHADOW_SCREENSHOT_PREFIX=shadow65
```

## 10. Méthode de capture

Méthode formalisée :

1. charger le `RuntimeMapBundle` Selbrume avec `loadRuntimeMapBundle(projectFilePath, mapId: 'Selbrume')` ;
2. charger les tilesets avec `loadTilesetImagesById` ;
3. reconstruire les sources statiques avec `buildRuntimeStaticPlacedElementShadowSources` ;
4. résoudre chaque instruction via `buildRuntimeStaticPlacedElementShadowCollection` pour rattacher instruction, placement, élément, family et profile ;
5. rendre la map runtime avec `MapLayersComponent.render(canvas)` dans un `ui.PictureRecorder` ;
6. écrire une overview et 10 crops centrés autour des contact ledges ;
7. écrire TSV, manifest JSON, tailles et hashes ;
8. asserter les compteurs runtime attendus.

Limite assumée : la capture est offscreen map-layer, pas une capture de fenêtre host complète. Pour les ombres statiques, elle passe toutefois par le même composant de couches runtime et les mêmes instructions Shadow.

## 11. Inventaire runtime produit

Sortie du manifest :

```json
{
  "staticInstructions": 10,
  "contactLedge": 10,
  "genericProjection": 0,
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
  }
}
```

Synthèse :

```text
static instructions total: 10
contactLedge total: 10
genericProjection total: 0
by family: building = 10
by profile: default-ground-wide-ellipse = 10
```

Vérification Shadow-56 :

```bash
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:127:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:129:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:154:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:179:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:207:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:232:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:270:      final result = applyElementAutoShadowPolicyToProject(
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:431:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
```

Conclusion : aucun appel dans `packages/map_runtime`.

Vérification Shadow-58 :

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

Vérification Shadow-59 / counts Selbrume :

```text
20
43
63
selbrume_maison_5	selbrume maison 5	true
lampadaire	lampadaire	true
arbre_pixellab_1	arbre  pixelLab 1	true
arbre_pixellab_2	arbre  pixelLab 2	true
panneau	panneau	true
```

Shadow overrides :

```text
2105	0	2105
```

## 12. Captures générées

| Path | Taille bytes | SHA-256 |
|---|---:|---|
| `reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png` | 158827 | `57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4` |
| `reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png` | 180911 | `f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48` |
| `reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png` | 168205 | `c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472` |
| `reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png` | 181666 | `27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd` |
| `reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png` | 162048 | `4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a` |
| `reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png` | 177970 | `568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530` |
| `reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png` | 146654 | `eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a` |
| `reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png` | 151150 | `4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796` |
| `reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png` | 183159 | `f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8` |
| `reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png` | 159359 | `e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3` |
| `reports/shadows/screenshots/shadow65_selbrume_overview.png` | 2529901 | `5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25` |

## 13. Index TSV / manifest JSON

Index TSV complet :

```tsv
rank	elementId	elementName	placementIdOrIndex	worldX	worldY	cropLeft	cropTop	cropWidth	cropHeight	screenshotPath	shapeKind	geometryType	family	profile	opacity	instructionWidth	instructionHeight	instructionArea
1	selbrum_maison_3	selbrum maison 3	l_tile_maison_selbrume::24::12	2304.0	1152.0	2189.12128	1377.076352	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	477.7574400000003	17.483647999999903	8352.942910341078
2	selbrum_maison_4	selbrum maison  4	l_tile_maison_selbrume::17::17	1632.0	1632.0	1462.7008	1763.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	298.59839999999986	16.985983999999917	5071.987644825573
3	selbrum_maison_1	selbrum maison 1	l_tile_maison_selbrume::10::18	960.0	1728.0	790.7008000000001	1859.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	298.59839999999986	16.985983999999917	5071.987644825573
4	selbrume_centre_pok_mon	selbrume centre pokémon	l_tile_maison_selbrume::29::22	2784.0	2112.0	2669.12128	2243.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	477.7574400000003	16.985983999999917	8115.180231720926
5	selbrum_maison_7	selbrum maison  7	l_tile_maison_selbrume::38::22	3648.0	2112.0	3496.84096	2243.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	358.31807999999955	16.985983999999917	6086.3851737906825
6	le_puits	le puits	l_tile_maison_selbrume::23::27	2208.0	2592.0	2020.5606400000001	2629.91168	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	238.8787199999997	16.48831999999993	3938.7087765503784
7	selbrum_maison_4	selbrum maison  4	l_tile_maison_selbrume::36::29	3456.0	2784.0	3286.7008	2915.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	298.59839999999986	16.985983999999917	5071.987644825573
8	selbrum_maison_2	selbrum maison  2	l_tile_maison_selbrume::10::30	960.0	2880.0	808.84096	3105.076352	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	358.31808	17.483647999999903	6264.707182755806
9	selbrum_maison_8	selbrum maison  8	l_tile_maison_selbrume::18::33	1728.0	3168.0	1667.54176	3299.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	656.9164799999999	16.985983999999917	11158.372818616263
10	kiosque_l_gumes	kiosque à légumes	l_tile_maison_selbrume::36::35	3456.0	3360.0	3304.84096	3491.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	358.31808	16.985983999999917	6086.385173790691
```

Manifest JSON complet :

```json
{
  "lot": "Shadow-65",
  "projectPath": "/Users/karim/Desktop/selbrume/project.json",
  "mapId": "Selbrume",
  "prefix": "shadow65",
  "outputDir": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots",
  "overview": {
    "path": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_selbrume_overview.png",
    "width": 1320,
    "height": 1320,
    "fileSizeBytes": 2529901,
    "sha256": "5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25"
  },
  "indexTsv": "/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_65_capture_index.tsv",
  "counts": {
    "staticInstructions": 10,
    "contactLedge": 10,
    "genericProjection": 0,
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
    }
  },
  "captures": [
    {
      "rank": 1,
      "elementId": "selbrum_maison_3",
      "elementName": "selbrum maison 3",
      "placementIdOrIndex": "l_tile_maison_selbrume::24::12",
      "worldX": 2304.0,
      "worldY": 1152.0,
      "cropLeft": 2189.12128,
      "cropTop": 1377.076352,
      "cropWidth": 900,
      "cropHeight": 650,
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png",
      "sha256": "f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48",
      "fileSizeBytes": 180911,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "profile": "default-ground-wide-ellipse",
      "opacity": 0.2,
      "instructionWidth": 477.7574400000003,
      "instructionHeight": 17.483647999999903,
      "instructionArea": 8352.942910341078
    },
    {
      "rank": 2,
      "elementId": "selbrum_maison_4",
      "elementName": "selbrum maison  4",
      "placementIdOrIndex": "l_tile_maison_selbrume::17::17",
      "worldX": 1632.0,
      "worldY": 1632.0,
      "cropLeft": 1462.7008,
      "cropTop": 1763.494016,
      "cropWidth": 900,
      "cropHeight": 650,
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png",
      "sha256": "c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472",
      "fileSizeBytes": 168205,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "profile": "default-ground-wide-ellipse",
      "opacity": 0.2,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 5071.987644825573
    },
    {
      "rank": 3,
      "elementId": "selbrum_maison_1",
      "elementName": "selbrum maison 1",
      "placementIdOrIndex": "l_tile_maison_selbrume::10::18",
      "worldX": 960.0,
      "worldY": 1728.0,
      "cropLeft": 790.7008000000001,
      "cropTop": 1859.494016,
      "cropWidth": 900,
      "cropHeight": 650,
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png",
      "sha256": "27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd",
      "fileSizeBytes": 181666,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "profile": "default-ground-wide-ellipse",
      "opacity": 0.2,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 5071.987644825573
    },
    {
      "rank": 4,
      "elementId": "selbrume_centre_pok_mon",
      "elementName": "selbrume centre pokémon",
      "placementIdOrIndex": "l_tile_maison_selbrume::29::22",
      "worldX": 2784.0,
      "worldY": 2112.0,
      "cropLeft": 2669.12128,
      "cropTop": 2243.494016,
      "cropWidth": 900,
      "cropHeight": 650,
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png",
      "sha256": "4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a",
      "fileSizeBytes": 162048,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "profile": "default-ground-wide-ellipse",
      "opacity": 0.2,
      "instructionWidth": 477.7574400000003,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 8115.180231720926
    },
    {
      "rank": 5,
      "elementId": "selbrum_maison_7",
      "elementName": "selbrum maison  7",
      "placementIdOrIndex": "l_tile_maison_selbrume::38::22",
      "worldX": 3648.0,
      "worldY": 2112.0,
      "cropLeft": 3496.84096,
      "cropTop": 2243.494016,
      "cropWidth": 900,
      "cropHeight": 650,
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png",
      "sha256": "568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530",
      "fileSizeBytes": 177970,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "profile": "default-ground-wide-ellipse",
      "opacity": 0.2,
      "instructionWidth": 358.31807999999955,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 6086.3851737906825
    },
    {
      "rank": 6,
      "elementId": "le_puits",
      "elementName": "le puits",
      "placementIdOrIndex": "l_tile_maison_selbrume::23::27",
      "worldX": 2208.0,
      "worldY": 2592.0,
      "cropLeft": 2020.5606400000001,
      "cropTop": 2629.91168,
      "cropWidth": 900,
      "cropHeight": 650,
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png",
      "sha256": "eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a",
      "fileSizeBytes": 146654,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "profile": "default-ground-wide-ellipse",
      "opacity": 0.2,
      "instructionWidth": 238.8787199999997,
      "instructionHeight": 16.48831999999993,
      "instructionArea": 3938.7087765503784
    },
    {
      "rank": 7,
      "elementId": "selbrum_maison_4",
      "elementName": "selbrum maison  4",
      "placementIdOrIndex": "l_tile_maison_selbrume::36::29",
      "worldX": 3456.0,
      "worldY": 2784.0,
      "cropLeft": 3286.7008,
      "cropTop": 2915.494016,
      "cropWidth": 900,
      "cropHeight": 650,
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png",
      "sha256": "4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796",
      "fileSizeBytes": 151150,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "profile": "default-ground-wide-ellipse",
      "opacity": 0.2,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 5071.987644825573
    },
    {
      "rank": 8,
      "elementId": "selbrum_maison_2",
      "elementName": "selbrum maison  2",
      "placementIdOrIndex": "l_tile_maison_selbrume::10::30",
      "worldX": 960.0,
      "worldY": 2880.0,
      "cropLeft": 808.84096,
      "cropTop": 3105.076352,
      "cropWidth": 900,
      "cropHeight": 650,
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png",
      "sha256": "f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8",
      "fileSizeBytes": 183159,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "profile": "default-ground-wide-ellipse",
      "opacity": 0.2,
      "instructionWidth": 358.31808,
      "instructionHeight": 17.483647999999903,
      "instructionArea": 6264.707182755806
    },
    {
      "rank": 9,
      "elementId": "selbrum_maison_8",
      "elementName": "selbrum maison  8",
      "placementIdOrIndex": "l_tile_maison_selbrume::18::33",
      "worldX": 1728.0,
      "worldY": 3168.0,
      "cropLeft": 1667.54176,
      "cropTop": 3299.494016,
      "cropWidth": 900,
      "cropHeight": 650,
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png",
      "sha256": "e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3",
      "fileSizeBytes": 159359,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "profile": "default-ground-wide-ellipse",
      "opacity": 0.2,
      "instructionWidth": 656.9164799999999,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 11158.372818616263
    },
    {
      "rank": 10,
      "elementId": "kiosque_l_gumes",
      "elementName": "kiosque à légumes",
      "placementIdOrIndex": "l_tile_maison_selbrume::36::35",
      "worldX": 3456.0,
      "worldY": 3360.0,
      "cropLeft": 3304.84096,
      "cropTop": 3491.494016,
      "cropWidth": 900,
      "cropHeight": 650,
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png",
      "sha256": "57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4",
      "fileSizeBytes": 158827,
      "shapeKind": "projectedPolygon",
      "geometryType": "contactLedge",
      "renderPass": "groundStatic",
      "family": "building",
      "profile": "default-ground-wide-ellipse",
      "opacity": 0.2,
      "instructionWidth": 358.31808,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 6086.385173790691
    }
  ]
}```

## 14. Hashes des screenshots

Commande :

```bash
shasum -a 256 reports/shadows/screenshots/shadow65_*.png
```

Sortie :

```text
57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4  reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png
f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48  reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png
c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472  reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png
27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd  reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png
4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a  reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png
568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530  reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png
eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a  reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png
4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796  reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png
f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8  reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png
e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3  reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png
5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25  reports/shadows/screenshots/shadow65_selbrume_overview.png
```

## 15. Résultats du harness

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow65 SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
00:00 +0: selbrume shadow screenshot harness
capture rank=1 element=selbrum_maison_3 cropLeft=2189.1 cropTop=1377.1
capture rank=2 element=selbrum_maison_4 cropLeft=1462.7 cropTop=1763.5
capture rank=3 element=selbrum_maison_1 cropLeft=790.7 cropTop=1859.5
capture rank=4 element=selbrume_centre_pok_mon cropLeft=2669.1 cropTop=2243.5
capture rank=5 element=selbrum_maison_7 cropLeft=3496.8 cropTop=2243.5
capture rank=6 element=le_puits cropLeft=2020.6 cropTop=2629.9
capture rank=7 element=selbrum_maison_4 cropLeft=3286.7 cropTop=2915.5
capture rank=8 element=selbrum_maison_2 cropLeft=808.8 cropTop=3105.1
capture rank=9 element=selbrum_maison_8 cropLeft=1667.5 cropTop=3299.5
capture rank=10 element=kiosque_l_gumes cropLeft=3304.8 cropTop=3491.5
{
  "projectPath": "/Users/karim/Desktop/selbrume/project.json",
  "outputDir": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots",
  "prefix": "shadow65",
  "overview": {
    "path": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_selbrume_overview.png",
    "width": 1320,
    "height": 1320,
    "fileSizeBytes": 2529901,
    "sha256": "5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25"
  },
  "indexTsv": "/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_65_capture_index.tsv",
  "manifest": "/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_65_capture_manifest.json",
  "counts": {
    "staticInstructions": 10,
    "contactLedge": 10,
    "genericProjection": 0,
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
    }
  }
}
00:01 +1: All tests passed!
```

## 16. Résultats des tests de régression

`cd packages/map_runtime && flutter test test/shadow`

```text
00:03 +233: All tests passed!
```

`cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart`

```text
00:00 +0: loadProjectManifestFromFile authored shadow manifest keeps missing shadow configs absent at runtime load
00:00 +1: loadProjectManifestFromFile authored shadow manifest preserves recognized old auto shadows as authored data
00:00 +2: loadProjectManifestFromFile authored shadow manifest preserves manual and disabled shadows
00:00 +3: All tests passed!
```

`cd packages/map_core && dart test test/shadow`

```text
00:00 +284: All tests passed!
```

`cd packages/map_editor && flutter test test/application/shadow`

```text
00:00 +96: All tests passed!
```

Les suites `map_runtime test/shadow` et `map_core test/shadow` sont bavardes ; le rapport conserve les lignes finales exactes, qui sont les preuves de succès demandées.

## 17. Résultat analyze

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter analyze tool/shadow
```

Sortie :

```text
Analyzing shadow...

No issues found! (ran in 2.2s)
```

## 18. Ce qui n'a volontairement pas été fait

- Aucun golden test bloquant.
- Aucune comparaison pixel automatique.
- Aucun changement renderer.
- Aucun changement `map_runtime/lib/src/**`.
- Aucun changement Selbrume.
- Aucun changement policy Shadow.
- Aucun changement profil / famille / modèle / codec.
- Aucun retune supplémentaire.

## 19. Limites du harness V0

- Capture offscreen des layers runtime, pas screenshot de l'application desktop complète.
- Pas de comparaison golden ni seuil de tolérance.
- Le harness suppose l'état Shadow-59/64 attendu : 10 contact ledges, 0 genericProjection.
- Les crops sont calculés autour de l'instruction Shadow ; ils sont stables pour Selbrume, mais pas conçus comme API générale multi-map.
- Le hash SHA-256 est calculé via `shasum`, donc l'environnement doit fournir cette commande.

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
(aucune sortie)
```

## 21. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text
(aucune sortie)
```

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale :

```text
(aucune sortie)
```

## 23. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? packages/map_runtime/tool/shadow/README.md
?? packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
?? reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png
?? reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png
?? reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png
?? reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png
?? reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png
?? reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png
?? reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png
?? reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png
?? reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png
?? reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png
?? reports/shadows/screenshots/shadow65_selbrume_overview.png
?? reports/shadows/shadow_lot_65_capture_index.tsv
?? reports/shadows/shadow_lot_65_capture_manifest.json
?? reports/shadows/shadow_lot_65_selbrume_shadow_screenshot_harness.md
```

## 24. Risques / réserves

- Le harness est volontairement manuel. C'est une étape saine avant un golden test CI.
- Les PNG `shadow65_*` ont les mêmes hashes que Shadow-64 avec le même état de rendu, ce qui est attendu après formalisation sans changement visuel.
- Si Selbrume change de dimensions, de placements ou de chemins d'assets, le harness échouera ou les crops devront être réévalués.

## 25. Auto-critique

Le lot formalise bien la capture, mais il reste très attaché à Selbrume. C'est assumé : Shadow-65 ne cherche pas encore à créer une infrastructure golden générique pour toutes les maps. Le point le plus fragile est le calcul du crop, fondé sur les instructions restantes et des marges fixes ; c'est suffisant pour V0, pas pour un système multi-fixtures.

## 26. Regard critique sur le prompt

Le prompt demandait une commande depuis la racine du repo, mais le repo n'a pas de `pubspec.yaml` racine. La commande relançable correcte doit partir de `packages/map_runtime`. Le prompt était par ailleurs très clair sur la frontière : outil reproductible oui, golden bloquant non.

## 27. Prochain lot recommandé

Shadow-66 — Selbrume Shadow Golden Baseline Design V0.

Objectif proposé : décider si les captures `shadow65_*` deviennent une baseline visuelle revue, définir le seuil de comparaison, choisir un mode non bloquant ou bloquant, et cadrer précisément comment éviter les faux positifs CI avant d'ajouter un golden test automatisé.

## Code complet des fichiers créés/modifiés

### `packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_collection.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_sources.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:path/path.dart' as p;

const _defaultProjectPath = '/Users/karim/Desktop/selbrume/project.json';
const _defaultOutputDir =
    '/Users/karim/Project/pokemonProject/reports/shadows/screenshots';
const _defaultPrefix = 'shadow65';
const _mapId = 'Selbrume';
const _overviewScale = 0.25;
const _contactCropWidth = 900;
const _contactCropHeight = 650;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selbrume shadow screenshot harness', () async {
    final config = _HarnessConfig.fromEnvironment();
    await Directory(config.outputDir).create(recursive: true);
    await Directory(config.artifactDir).create(recursive: true);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: config.projectPath,
      mapId: _mapId,
    );
    final tileImages = await loadTilesetImagesById(
      bundle.tilesetAbsolutePathsById,
      transparentColorByTilesetId: {
        for (final tileset in bundle.manifest.tilesets)
          if (tileset.transparentColor != null)
            tileset.id: tileset.transparentColor!,
      },
    );
    final shadowRows = _buildShadowRows(bundle: bundle);
    final counts = _buildCounts(shadowRows);

    final layer = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImages,
      shadowCollectionProvider: () =>
          buildRuntimeStaticPlacedElementShadowCollectionForBundle(
        bundle: bundle,
      ),
    );
    layer.update(0);

    final worldWidth = bundle.map.size.width * bundle.cellWidth;
    final worldHeight = bundle.map.size.height * bundle.cellHeight;
    final overviewPath =
        p.join(config.outputDir, '${config.prefix}_selbrume_overview.png');
    await _renderCapture(
      layer,
      filePath: overviewPath,
      cropLeft: 0,
      cropTop: 0,
      outputWidth: (worldWidth * _overviewScale).round(),
      outputHeight: (worldHeight * _overviewScale).round(),
      scale: _overviewScale,
    );

    final captures = <_CaptureArtifact>[];
    for (final row in shadowRows.where((row) => row.geometryType == 'contactLedge')) {
      final cropLeft =
          (row.instructionLeft - 260).clamp(0, worldWidth - _contactCropWidth);
      final cropTop = (row.instructionTop - 430)
          .clamp(0, worldHeight - _contactCropHeight);
      final screenshotPath = p.join(
        config.outputDir,
        '${config.prefix}_contact_ledge_${row.rank}_${_safeFilePart(row.elementId)}.png',
      );
      await _renderCapture(
        layer,
        filePath: screenshotPath,
        cropLeft: cropLeft.toDouble(),
        cropTop: cropTop.toDouble(),
        outputWidth: _contactCropWidth,
        outputHeight: _contactCropHeight,
      );
      captures.add(
        _CaptureArtifact(
          row: row,
          cropLeft: cropLeft.toDouble(),
          cropTop: cropTop.toDouble(),
          cropWidth: _contactCropWidth,
          cropHeight: _contactCropHeight,
          screenshotPath: screenshotPath,
          fileSizeBytes: await File(screenshotPath).length(),
          sha256: await _sha256ForFile(screenshotPath),
        ),
      );
      debugPrint(
        'capture rank=${row.rank} element=${row.elementId} '
        'cropLeft=${cropLeft.toStringAsFixed(1)} '
        'cropTop=${cropTop.toStringAsFixed(1)}',
      );
    }

    final overviewArtifact = {
      'path': overviewPath,
      'width': (worldWidth * _overviewScale).round(),
      'height': (worldHeight * _overviewScale).round(),
      'fileSizeBytes': await File(overviewPath).length(),
      'sha256': await _sha256ForFile(overviewPath),
    };
    final indexPath =
        p.join(config.artifactDir, 'shadow_lot_65_capture_index.tsv');
    final manifestPath =
        p.join(config.artifactDir, 'shadow_lot_65_capture_manifest.json');
    await File(indexPath).writeAsString(_captureIndexTsv(captures));
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'lot': 'Shadow-65',
        'projectPath': config.projectPath,
        'mapId': _mapId,
        'prefix': config.prefix,
        'outputDir': config.outputDir,
        'overview': overviewArtifact,
        'indexTsv': indexPath,
        'counts': counts.toJson(),
        'captures': [
          for (final capture in captures) capture.toJson(),
        ],
      }),
    );

    final summary = {
      'projectPath': config.projectPath,
      'outputDir': config.outputDir,
      'prefix': config.prefix,
      'overview': overviewArtifact,
      'indexTsv': indexPath,
      'manifest': manifestPath,
      'counts': counts.toJson(),
    };
    debugPrint(const JsonEncoder.withIndent('  ').convert(summary));

    expect(counts.staticInstructions, 10);
    expect(counts.contactLedge, 10);
    expect(counts.genericProjection, 0);
    expect(captures, hasLength(10));
    expect(File(overviewPath).existsSync(), isTrue);
    expect(File(indexPath).existsSync(), isTrue);
    expect(File(manifestPath).existsSync(), isTrue);
  });
}

List<_ShadowCaptureRow> _buildShadowRows({required RuntimeMapBundle bundle}) {
  final elementsById = <String, ProjectElementEntry>{
    for (final element in bundle.manifest.elements) element.id: element,
  };
  final sources = buildRuntimeStaticPlacedElementShadowSources(bundle: bundle);
  final rows = <_ShadowCaptureRow>[];
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
      rows.add(
        _ShadowCaptureRow(
          rank: rank,
          placementIdOrIndex: source.id,
          elementId: source.elementId,
          elementName: element?.name ?? source.elementId,
          worldX: source.metrics.worldLeft,
          worldY: source.metrics.worldTop,
          instructionLeft: instruction.worldLeft,
          instructionTop: instruction.worldTop,
          instructionWidth: instruction.width,
          instructionHeight: instruction.height,
          instructionArea: instruction.width * instruction.height,
          opacity: instruction.opacity,
          shapeKind: instruction.shape.name,
          geometryType: geometryType,
          renderPass: instruction.renderPass.name,
          family: family?.name ?? 'null',
          profile: shadow?.shadowProfileId ?? 'null',
        ),
      );
    }
  }
  return rows;
}

_RuntimeCounts _buildCounts(List<_ShadowCaptureRow> rows) {
  final byElement = <String, int>{};
  final byFamily = <String, int>{};
  final byProfile = <String, int>{};
  var contactLedge = 0;
  var genericProjection = 0;
  for (final row in rows) {
    byElement[row.elementId] = (byElement[row.elementId] ?? 0) + 1;
    byFamily[row.family] = (byFamily[row.family] ?? 0) + 1;
    byProfile[row.profile] = (byProfile[row.profile] ?? 0) + 1;
    if (row.geometryType == 'contactLedge') {
      contactLedge += 1;
    }
    if (row.family == 'genericProjection') {
      genericProjection += 1;
    }
  }
  return _RuntimeCounts(
    staticInstructions: rows.length,
    contactLedge: contactLedge,
    genericProjection: genericProjection,
    byElement: byElement,
    byFamily: byFamily,
    byProfile: byProfile,
  );
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
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF000000),
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
}

String _captureIndexTsv(List<_CaptureArtifact> captures) {
  const headers = [
    'rank',
    'elementId',
    'elementName',
    'placementIdOrIndex',
    'worldX',
    'worldY',
    'cropLeft',
    'cropTop',
    'cropWidth',
    'cropHeight',
    'screenshotPath',
    'shapeKind',
    'geometryType',
    'family',
    'profile',
    'opacity',
    'instructionWidth',
    'instructionHeight',
    'instructionArea',
  ];
  final lines = <String>[headers.join('\t')];
  for (final capture in captures) {
    lines.add([
      capture.row.rank,
      capture.row.elementId,
      capture.row.elementName,
      capture.row.placementIdOrIndex,
      capture.row.worldX,
      capture.row.worldY,
      capture.cropLeft,
      capture.cropTop,
      capture.cropWidth,
      capture.cropHeight,
      capture.screenshotPath,
      capture.row.shapeKind,
      capture.row.geometryType,
      capture.row.family,
      capture.row.profile,
      capture.row.opacity,
      capture.row.instructionWidth,
      capture.row.instructionHeight,
      capture.row.instructionArea,
    ].map((value) => '$value').join('\t'));
  }
  return '${lines.join('\n')}\n';
}

Future<String> _sha256ForFile(String filePath) async {
  final result = await Process.run('shasum', ['-a', '256', filePath]);
  if (result.exitCode != 0) {
    throw StateError('Could not calculate sha256 for $filePath: '
        '${result.stderr}');
  }
  final output = (result.stdout as String).trim();
  return output.split(RegExp(r'\s+')).first;
}

String _safeFilePart(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
}

final class _HarnessConfig {
  const _HarnessConfig({
    required this.projectPath,
    required this.outputDir,
    required this.prefix,
    required this.artifactDir,
  });

  factory _HarnessConfig.fromEnvironment() {
    final projectPath =
        Platform.environment['SELBRUME_PROJECT_PATH'] ?? _defaultProjectPath;
    final outputDir = Directory(
      Platform.environment['SHADOW_SCREENSHOT_OUTPUT_DIR'] ?? _defaultOutputDir,
    ).absolute.path;
    final prefix =
        _safeFilePart(Platform.environment['SHADOW_SCREENSHOT_PREFIX'] ??
            _defaultPrefix);
    final artifactDir = p.basename(outputDir) == 'screenshots'
        ? Directory(outputDir).parent.path
        : outputDir;
    return _HarnessConfig(
      projectPath: projectPath,
      outputDir: outputDir,
      prefix: prefix,
      artifactDir: artifactDir,
    );
  }

  final String projectPath;
  final String outputDir;
  final String prefix;
  final String artifactDir;
}

final class _ShadowCaptureRow {
  const _ShadowCaptureRow({
    required this.rank,
    required this.placementIdOrIndex,
    required this.elementId,
    required this.elementName,
    required this.worldX,
    required this.worldY,
    required this.instructionLeft,
    required this.instructionTop,
    required this.instructionWidth,
    required this.instructionHeight,
    required this.instructionArea,
    required this.opacity,
    required this.shapeKind,
    required this.geometryType,
    required this.renderPass,
    required this.family,
    required this.profile,
  });

  final int rank;
  final String placementIdOrIndex;
  final String elementId;
  final String elementName;
  final double worldX;
  final double worldY;
  final double instructionLeft;
  final double instructionTop;
  final double instructionWidth;
  final double instructionHeight;
  final double instructionArea;
  final double opacity;
  final String shapeKind;
  final String geometryType;
  final String renderPass;
  final String family;
  final String profile;
}

final class _CaptureArtifact {
  const _CaptureArtifact({
    required this.row,
    required this.cropLeft,
    required this.cropTop,
    required this.cropWidth,
    required this.cropHeight,
    required this.screenshotPath,
    required this.fileSizeBytes,
    required this.sha256,
  });

  final _ShadowCaptureRow row;
  final double cropLeft;
  final double cropTop;
  final int cropWidth;
  final int cropHeight;
  final String screenshotPath;
  final int fileSizeBytes;
  final String sha256;

  Map<String, Object?> toJson() {
    return {
      'rank': row.rank,
      'elementId': row.elementId,
      'elementName': row.elementName,
      'placementIdOrIndex': row.placementIdOrIndex,
      'worldX': row.worldX,
      'worldY': row.worldY,
      'cropLeft': cropLeft,
      'cropTop': cropTop,
      'cropWidth': cropWidth,
      'cropHeight': cropHeight,
      'screenshotPath': screenshotPath,
      'sha256': sha256,
      'fileSizeBytes': fileSizeBytes,
      'shapeKind': row.shapeKind,
      'geometryType': row.geometryType,
      'renderPass': row.renderPass,
      'family': row.family,
      'profile': row.profile,
      'opacity': row.opacity,
      'instructionWidth': row.instructionWidth,
      'instructionHeight': row.instructionHeight,
      'instructionArea': row.instructionArea,
    };
  }
}

final class _RuntimeCounts {
  const _RuntimeCounts({
    required this.staticInstructions,
    required this.contactLedge,
    required this.genericProjection,
    required this.byElement,
    required this.byFamily,
    required this.byProfile,
  });

  final int staticInstructions;
  final int contactLedge;
  final int genericProjection;
  final Map<String, int> byElement;
  final Map<String, int> byFamily;
  final Map<String, int> byProfile;

  Map<String, Object?> toJson() {
    return {
      'staticInstructions': staticInstructions,
      'contactLedge': contactLedge,
      'genericProjection': genericProjection,
      'byElement': byElement,
      'byFamily': byFamily,
      'byProfile': byProfile,
    };
  }
}
```

### `packages/map_runtime/tool/shadow/README.md`

~~~markdown
# Selbrume Shadow Screenshot Harness

This directory contains manual visual-gate tools for PokeMap shadow work.

The harness is intentionally outside `test/` so it does not run in normal
package test suites or CI by accident. It is a reproducible screenshot capture
tool, not a golden comparison test.

## Run

From the `map_runtime` package:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow65 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

## Environment

The harness supports these environment variables:

```text
SELBRUME_PROJECT_PATH
SHADOW_SCREENSHOT_OUTPUT_DIR
SHADOW_SCREENSHOT_PREFIX
```

Defaults:

```text
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots
SHADOW_SCREENSHOT_PREFIX=shadow65
```

## Outputs

With the default prefix, the harness writes:

```text
reports/shadows/screenshots/shadow65_selbrume_overview.png
reports/shadows/screenshots/shadow65_contact_ledge_1_<elementId>.png
...
reports/shadows/screenshots/shadow65_contact_ledge_10_<elementId>.png
reports/shadows/shadow_lot_65_capture_index.tsv
reports/shadows/shadow_lot_65_capture_manifest.json
```

The TSV records capture coordinates, element ids, runtime instruction geometry,
family/profile metadata, opacity, and screenshot paths. The manifest records
the run configuration, counts, screenshot paths, file sizes, and SHA-256 hashes.

## Limits

This V0 harness captures the current runtime output and asserts the expected
Selbrume shadow inventory:

```text
staticInstructions = 10
contactLedge = 10
genericProjection = 0
```

It does not compare pixels against a golden baseline, and it should not block
normal test suites. A future lot can turn these captures into a reviewed golden
slice once the team wants a stricter visual regression gate.
~~~
