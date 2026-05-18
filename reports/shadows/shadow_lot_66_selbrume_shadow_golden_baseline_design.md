# Shadow-66 — Selbrume Shadow Golden Baseline Design V0

## 1. Résumé exécutif

Shadow-66 est un lot design-only. Aucun code, aucune donnée Selbrume et aucun screenshot Shadow-65 existant n'ont été modifiés.

Recommandation centrale :

```text
Créer une baseline complète de 11 images Shadow-65, versionnée sous reports/shadows/baselines/selbrume_shadow_v1/.
En V0, rendre bloquants les invariants structurels et la génération des captures.
Garder la comparaison pixel/hash informative, non bloquante, jusqu'à validation explicite d'une stratégie de seuil.
```

La baseline recommandée inclut :

```text
1 overview Selbrume
10 crops contact ledge
manifest baseline JSON
index TSV
hashes SHA-256 informatifs
```

Prochain lot recommandé :

```text
Shadow-67 — Selbrume Shadow Golden Baseline Implementation V0
```

## 2. Rappel Shadow-65

Shadow-65 a créé un harness manuel de capture :

```text
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
packages/map_runtime/tool/shadow/README.md
reports/shadows/screenshots/shadow65_*.png
reports/shadows/shadow_lot_65_capture_index.tsv
reports/shadows/shadow_lot_65_capture_manifest.json
```

Il ne change pas le rendu. Il charge Selbrume via le runtime existant, rend `MapLayersComponent` offscreen, produit une overview et 10 crops, puis vérifie :

```text
staticInstructions = 10
contactLedge = 10
genericProjection = 0
```

Les captures Shadow-65 sont les candidates naturelles de baseline V1.

## 3. Nature design-only du lot

Ce lot ne crée pas de baseline réelle et ne modifie pas le harness. Il audite l'état actuel et définit la stratégie du lot suivant.

Actions effectuées :

- lecture du harness Shadow-65 ;
- lecture du README ;
- audit des 11 screenshots ;
- audit du manifest JSON ;
- audit du TSV ;
- conception du mode baseline / compare / update pour Shadow-67 ;
- création de ce rapport.

Actions non effectuées :

- aucun rendu modifié ;
- aucune donnée Selbrume modifiée ;
- aucun PNG Shadow-65 modifié ;
- aucun golden test bloquant créé ;
- aucun commit.

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

Commit de base lu :

```text
eae392b8 test: add selbrume shadow screenshot harness
03d2edab fix: retune building contact ledge depth
e8ffb35c docs: add shadow 63 contact ledge retune design
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

Décision : le design gate est respecté. Le lot touche une stratégie de validation visuelle produit, donc il reste strictement design-only. Aucune implémentation Shadow-67 n'a été anticipée.

Skills utilisés : `using-superpowers`, `karpathy-guidelines`, `writing-plans`, `verification-before-completion`. La logique `writing-plans` est appliquée dans la section Shadow-67, mais le plan est enregistré dans ce rapport parce que le prompt impose ce livrable, pas `docs/superpowers/plans`.

## 6. Audit du harness Shadow-65

Fichiers audités :

```text
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
packages/map_runtime/tool/shadow/README.md
```

Commande de lancement documentée :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow65 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

Variables d'environnement :

```text
SELBRUME_PROJECT_PATH
SHADOW_SCREENSHOT_OUTPUT_DIR
SHADOW_SCREENSHOT_PREFIX
```

Points clés du harness :

```text
22:const _overviewScale = 0.25;
23:const _contactCropWidth = 900;
24:const _contactCropHeight = 650;
34:    final bundle = await loadRuntimeMapBundle(
49:    final layer = MapLayersComponent(
53:          buildRuntimeStaticPlacedElementShadowCollectionForBundle(
68:      outputWidth: (worldWidth * _overviewScale).round(),
69:      outputHeight: (worldHeight * _overviewScale).round(),
70:      scale: _overviewScale,
76:          (row.instructionLeft - 260).clamp(0, worldWidth - _contactCropWidth);
78:          .clamp(0, worldHeight - _contactCropHeight);
88:        outputWidth: _contactCropWidth,
89:        outputHeight: _contactCropHeight,
96:          cropWidth: _contactCropWidth,
97:          cropHeight: _contactCropHeight,
112:      'width': (worldWidth * _overviewScale).round(),
113:      'height': (worldHeight * _overviewScale).round(),
121:    await File(indexPath).writeAsString(_captureIndexTsv(captures));
122:    await File(manifestPath).writeAsString(
149:    expect(counts.staticInstructions, 10);
150:    expect(counts.contactLedge, 10);
151:    expect(counts.genericProjection, 0);
152:    expect(captures, hasLength(10));
153:    expect(File(overviewPath).existsSync(), isTrue);
154:    expect(File(indexPath).existsSync(), isTrue);
155:    expect(File(manifestPath).existsSync(), isTrue);
163:  final sources = buildRuntimeStaticPlacedElementShadowSources(bundle: bundle);
167:    final collection = buildRuntimeStaticPlacedElementShadowCollection(
235:  MapLayersComponent layer, {
243:  final recorder = ui.PictureRecorder();
262:String _captureIndexTsv(List<_CaptureArtifact> captures) {
335:        Platform.environment['SELBRUME_PROJECT_PATH'] ?? _defaultProjectPath;
337:      Platform.environment['SHADOW_SCREENSHOT_OUTPUT_DIR'] ?? _defaultOutputDir,
340:        _safeFilePart(Platform.environment['SHADOW_SCREENSHOT_PREFIX'] ??
```

Audit :

- lancement : manuel, depuis `packages/map_runtime`, hors suite normale ;
- chargement Selbrume : `loadRuntimeMapBundle(projectFilePath, mapId: 'Selbrume')` ;
- rendu : `MapLayersComponent.render(canvas)` dans `ui.PictureRecorder` ;
- identification contact ledge : instruction `projectedPolygon` + `StaticShadowFamily.building`, classée en `geometryType = contactLedge` ;
- crops : 900x650 px, dérivés de `instructionLeft - 260` et `instructionTop - 430`, clampés à la taille monde ;
- overview : map entière à `0.25` ;
- noms : `<prefix>_selbrume_overview.png` et `<prefix>_contact_ledge_<rank>_<elementId>.png` ;
- TSV : rang, élément, placement, coordonnées monde/crop, shape, geometry, family, profile, opacity, dimensions, area ;
- manifest : configuration de run, overview, counts, captures, tailles et SHA-256 ;
- limites : harness spécialisé Selbrume, pas un système multi-map ; pas de diff pixel ; chemins absolus par défaut ; dépend de `shasum`.

Conclusion : le harness est assez stable pour une baseline V0 informative, car les crops et l'ordre sont déterministes pour l'état Selbrume actuel. Il n'est pas encore suffisant pour un golden bloquant strict, car il ne gère ni seuil pixel, ni environnement CI, ni workflow d'update.

## 7. Audit des screenshots Shadow-65

Vérification existence :

```bash
test -f packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
test -f packages/map_runtime/tool/shadow/README.md
test -f reports/shadows/shadow_lot_65_capture_index.tsv
test -f reports/shadows/shadow_lot_65_capture_manifest.json
find reports/shadows/screenshots -maxdepth 1 -type f -name "shadow65_*.png" -print | sort
find reports/shadows/screenshots -maxdepth 1 -type f -name "shadow65_*.png" | wc -l
```

Sortie :

```text
reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png
reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png
reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png
reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png
reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png
reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png
reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png
reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png
reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png
reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png
reports/shadows/screenshots/shadow65_selbrume_overview.png
      11
```

Hashes :

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

Tailles et dimensions :

```text
-rw-r--r--@ 1 karim  staff   155K May 18 23:15 reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png
-rw-r--r--@ 1 karim  staff   177K May 18 23:15 reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png
-rw-r--r--@ 1 karim  staff   164K May 18 23:15 reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png
-rw-r--r--@ 1 karim  staff   177K May 18 23:15 reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png
-rw-r--r--@ 1 karim  staff   158K May 18 23:15 reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png
-rw-r--r--@ 1 karim  staff   174K May 18 23:15 reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png
-rw-r--r--@ 1 karim  staff   143K May 18 23:15 reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png
-rw-r--r--@ 1 karim  staff   148K May 18 23:15 reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png
-rw-r--r--@ 1 karim  staff   179K May 18 23:15 reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png
-rw-r--r--@ 1 karim  staff   156K May 18 23:15 reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png
-rw-r--r--@ 1 karim  staff   2.4M May 18 23:15 reports/shadows/screenshots/shadow65_selbrume_overview.png
reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png: PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png:                PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow65_selbrume_overview.png:                       PNG image data, 1320 x 1320, 8-bit/color RGBA, non-interlaced
```

Conclusion : 11 captures présentes, lisibles, avec dimensions stables. Les 10 crops contact ledge sont homogènes à 900x650. L'overview est 1320x1320.

## 8. Audit du manifest JSON Shadow-65

Commande :

```bash
jq '{projectPath,mapId,prefix,outputDir,overviewPath:.overview.path,overviewHash:.overview.sha256,captureCount:(.captures|length),counts:.counts,captures:[.captures[]|{rank,elementId,screenshotPath,sha256,fileSizeBytes,cropWidth,cropHeight,instructionWidth,instructionHeight,instructionArea}]}' reports/shadows/shadow_lot_65_capture_manifest.json
```

Sortie :

```json
{
  "projectPath": "/Users/karim/Desktop/selbrume/project.json",
  "mapId": "Selbrume",
  "prefix": "shadow65",
  "outputDir": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots",
  "overviewPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_selbrume_overview.png",
  "overviewHash": "5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25",
  "captureCount": 10,
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png",
      "sha256": "f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48",
      "fileSizeBytes": 180911,
      "cropWidth": 900,
      "cropHeight": 650,
      "instructionWidth": 477.7574400000003,
      "instructionHeight": 17.483647999999903,
      "instructionArea": 8352.942910341078
    },
    {
      "rank": 2,
      "elementId": "selbrum_maison_4",
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png",
      "sha256": "c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472",
      "fileSizeBytes": 168205,
      "cropWidth": 900,
      "cropHeight": 650,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 5071.987644825573
    },
    {
      "rank": 3,
      "elementId": "selbrum_maison_1",
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png",
      "sha256": "27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd",
      "fileSizeBytes": 181666,
      "cropWidth": 900,
      "cropHeight": 650,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 5071.987644825573
    },
    {
      "rank": 4,
      "elementId": "selbrume_centre_pok_mon",
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png",
      "sha256": "4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a",
      "fileSizeBytes": 162048,
      "cropWidth": 900,
      "cropHeight": 650,
      "instructionWidth": 477.7574400000003,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 8115.180231720926
    },
    {
      "rank": 5,
      "elementId": "selbrum_maison_7",
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png",
      "sha256": "568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530",
      "fileSizeBytes": 177970,
      "cropWidth": 900,
      "cropHeight": 650,
      "instructionWidth": 358.31807999999955,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 6086.3851737906825
    },
    {
      "rank": 6,
      "elementId": "le_puits",
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png",
      "sha256": "eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a",
      "fileSizeBytes": 146654,
      "cropWidth": 900,
      "cropHeight": 650,
      "instructionWidth": 238.8787199999997,
      "instructionHeight": 16.48831999999993,
      "instructionArea": 3938.7087765503784
    },
    {
      "rank": 7,
      "elementId": "selbrum_maison_4",
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png",
      "sha256": "4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796",
      "fileSizeBytes": 151150,
      "cropWidth": 900,
      "cropHeight": 650,
      "instructionWidth": 298.59839999999986,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 5071.987644825573
    },
    {
      "rank": 8,
      "elementId": "selbrum_maison_2",
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png",
      "sha256": "f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8",
      "fileSizeBytes": 183159,
      "cropWidth": 900,
      "cropHeight": 650,
      "instructionWidth": 358.31808,
      "instructionHeight": 17.483647999999903,
      "instructionArea": 6264.707182755806
    },
    {
      "rank": 9,
      "elementId": "selbrum_maison_8",
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png",
      "sha256": "e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3",
      "fileSizeBytes": 159359,
      "cropWidth": 900,
      "cropHeight": 650,
      "instructionWidth": 656.9164799999999,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 11158.372818616263
    },
    {
      "rank": 10,
      "elementId": "kiosque_l_gumes",
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png",
      "sha256": "57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4",
      "fileSizeBytes": 158827,
      "cropWidth": 900,
      "cropHeight": 650,
      "instructionWidth": 358.31808,
      "instructionHeight": 16.985983999999917,
      "instructionArea": 6086.385173790691
    }
  ]
}
```

Audit :

- `projectPath` pointe vers `/Users/karim/Desktop/selbrume/project.json` ;
- `mapId` est `Selbrume` ;
- `prefix` est `shadow65` ;
- `captures.length = 10` pour les contact ledges ;
- avec l'overview, les artefacts image font bien 11 ;
- counts cohérents : `staticInstructions = 10`, `contactLedge = 10`, `genericProjection = 0` ;
- hashes et tailles sont présents pour chaque image.

Conclusion : le manifest est suffisant comme base de manifest baseline V1.

## 9. Audit du TSV Shadow-65

Commande :

```bash
wc -l reports/shadows/shadow_lot_65_capture_index.tsv
head -n 1 reports/shadows/shadow_lot_65_capture_index.tsv
tail -n +2 reports/shadows/shadow_lot_65_capture_index.tsv | cut -f1,2,3,5,6,7,8,11,13,14,15,16,17,18,19
```

Sortie :

```text
      11 reports/shadows/shadow_lot_65_capture_index.tsv
rank	elementId	elementName	placementIdOrIndex	worldX	worldY	cropLeft	cropTop	cropWidth	cropHeight	screenshotPath	shapeKind	geometryType	family	profile	opacity	instructionWidth	instructionHeight	instructionArea
1	selbrum_maison_3	selbrum maison 3	2304.0	1152.0	2189.12128	1377.076352	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png	contactLedge	building	default-ground-wide-ellipse	0.2	477.7574400000003	17.483647999999903	8352.942910341078
2	selbrum_maison_4	selbrum maison  4	1632.0	1632.0	1462.7008	1763.494016	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png	contactLedge	building	default-ground-wide-ellipse	0.2	298.59839999999986	16.985983999999917	5071.987644825573
3	selbrum_maison_1	selbrum maison 1	960.0	1728.0	790.7008000000001	1859.494016	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png	contactLedge	building	default-ground-wide-ellipse	0.2	298.59839999999986	16.985983999999917	5071.987644825573
4	selbrume_centre_pok_mon	selbrume centre pokémon	2784.0	2112.0	2669.12128	2243.494016	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png	contactLedge	building	default-ground-wide-ellipse	0.2	477.7574400000003	16.985983999999917	8115.180231720926
5	selbrum_maison_7	selbrum maison  7	3648.0	2112.0	3496.84096	2243.494016	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png	contactLedge	building	default-ground-wide-ellipse	0.2	358.31807999999955	16.985983999999917	6086.3851737906825
6	le_puits	le puits	2208.0	2592.0	2020.5606400000001	2629.91168	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png	contactLedge	building	default-ground-wide-ellipse	0.2	238.8787199999997	16.48831999999993	3938.7087765503784
7	selbrum_maison_4	selbrum maison  4	3456.0	2784.0	3286.7008	2915.494016	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png	contactLedge	building	default-ground-wide-ellipse	0.2	298.59839999999986	16.985983999999917	5071.987644825573
8	selbrum_maison_2	selbrum maison  2	960.0	2880.0	808.84096	3105.076352	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png	contactLedge	building	default-ground-wide-ellipse	0.2	358.31808	17.483647999999903	6264.707182755806
9	selbrum_maison_8	selbrum maison  8	1728.0	3168.0	1667.54176	3299.494016	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png	contactLedge	building	default-ground-wide-ellipse	0.2	656.9164799999999	16.985983999999917	11158.372818616263
10	kiosque_l_gumes	kiosque à légumes	3456.0	3360.0	3304.84096	3491.494016	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png	contactLedge	building	default-ground-wide-ellipse	0.2	358.31808	16.985983999999917	6086.385173790691
```

Audit :

- 11 lignes : 1 header + 10 contact ledges ;
- colonnes utiles présentes : elementId, placement, world, crop, screenshot, shapeKind, geometryType, family, profile, opacity, dimensions, area ;
- les elementIds attendus sont tous présents ;
- `selbrum_maison_4` apparaît deux fois, ce qui correspond aux deux placements restants ;
- le TSV ne contient pas l'overview, donc le manifest doit rester la source d'inventaire complète 11 images.

Conclusion : le TSV est suffisant pour indexer les crops contact ledge, mais Shadow-67 doit garder le manifest comme source principale de comparaison globale.

## 10. Baselines candidates

Trois granularités possibles :

| Option | Contenu | Couverture | Maintenance | Recommandation |
|---|---|---:|---:|---|
| complète | overview + 10 crops | maximale | moyenne | recommandée |
| minimale | overview + 4 anciens retune-next | partielle | faible | insuffisante |
| progressive | baseline initiale 4 puis extension | moyenne | moyenne | inutile ici |

Recommandation : baseline complète de 11 images.

Justification :

- les 11 images existent déjà, avec dimensions et hashes ;
- les 10 crops couvrent tous les éléments restants avec ombre statique ;
- l'overview détecte les régressions grossières de map/rendu/cadrage ;
- le coût de maintenance reste acceptable : 11 images seulement ;
- une baseline minimale raterait une régression sur les 6 anciens `keep`.

Liste candidate :

```text
shadow65_selbrume_overview.png
shadow65_contact_ledge_1_selbrum_maison_3.png
shadow65_contact_ledge_2_selbrum_maison_4.png
shadow65_contact_ledge_3_selbrum_maison_1.png
shadow65_contact_ledge_4_selbrume_centre_pok_mon.png
shadow65_contact_ledge_5_selbrum_maison_7.png
shadow65_contact_ledge_6_le_puits.png
shadow65_contact_ledge_7_selbrum_maison_4.png
shadow65_contact_ledge_8_selbrum_maison_2.png
shadow65_contact_ledge_9_selbrum_maison_8.png
shadow65_contact_ledge_10_kiosque_l_gumes.png
```

## 11. Options de stockage des baselines

### Option A — `reports/shadows/baselines/selbrume_shadow_v1/`

Avantages :

- proche des rapports Shadow ;
- lisible par revue humaine ;
- naturel pour une baseline issue d'un lot d'audit visuel ;
- ne pollue pas le package runtime avec des PNG de référence ;
- cohérent avec le fait que le harness reste manuel en V0.

Risques :

- moins intégré au package `map_runtime` ;
- peut être confondu avec artefacts de rapport si la convention n'est pas documentée.

### Option B — `packages/map_runtime/tool/shadow/baselines/selbrume_shadow_v1/`

Avantages :

- proche du harness ;
- facile à découvrir depuis le README du tool ;
- chemin relatif simple depuis `packages/map_runtime`.

Risques :

- alourdit le package runtime avec des assets de référence Selbrume ;
- mélange outil et artefacts visuels de validation ;
- pourrait donner l'impression d'un test package standard alors que V0 reste manuel.

### Option C — `goldens/shadows/selbrume_shadow_v1/`

Avantages :

- convention claire de golden assets ;
- extensible au-delà de Selbrume ;
- bonne cible long terme si plusieurs visual gates apparaissent.

Risques :

- nouvelle convention repo à valider ;
- plus structurel que nécessaire pour V0 ;
- risque de lancer une architecture golden globale avant d'avoir stabilisé la stratégie.

Recommandation : Option A pour Shadow-67.

Structure proposée :

```text
reports/shadows/baselines/selbrume_shadow_v1/
  README.md
  baseline_manifest.json
  capture_index.tsv
  screenshots/
    shadow65_selbrume_overview.png
    shadow65_contact_ledge_1_selbrum_maison_3.png
    ...
    shadow65_contact_ledge_10_kiosque_l_gumes.png
```

Le README doit dire que cette baseline est V1, revue via Shadow-62/64/65, et qu'elle est non bloquante côté pixels en V0.

## 12. Stratégies de comparaison

| Approche | Description | Avantages | Risques | Décision |
|---|---|---|---|---|
| hash exact | SHA-256 identique | simple, strict | extrêmement fragile, un pixel casse | non pour blocage V0 |
| dimensions + hash informatif | vérifier dimensions/counts, reporter hashes | stable, utile en revue | pas de détection pixel automatique bloquante | oui V0 |
| pixel diff seuil | comparer pixels avec tolérance | meilleur équilibre à terme | seuils à calibrer, outil à écrire | V1 après stabilisation |
| perceptual diff | métrique proche perception | intéressant long terme | overkill, dépendances, seuils flous | non V0 |

Recommandation V0 :

```text
Comparer structurellement de façon bloquante.
Comparer les hashes de façon informative.
Ne pas échouer sur différence de pixels en Shadow-67.
```

Concrètement, Shadow-67 peut produire un bloc `baselineComparison` dans le manifest :

```json
{
  "mode": "informative",
  "baselineDir": "reports/shadows/baselines/selbrume_shadow_v1",
  "matchingHashes": 11,
  "changedHashes": 0,
  "missingBaselineFiles": [],
  "missingCurrentFiles": []
}
```

Si des hashes diffèrent, le test ne doit pas échouer en V0, mais le rapport / stdout doit lister les différences.

## 13. Décision bloquant / non-bloquant

Décision :

```text
Pixels non bloquants en V0.
Invariants structurels bloquants.
```

Bloquant dès Shadow-67 :

- manifest JSON valide ;
- baseline manifest lisible si `SHADOW_COMPARE_BASELINE=true` ;
- `staticInstructions == 10` ;
- `contactLedge == 10` ;
- `genericProjection == 0` ;
- 10 crops contact ledge générés ;
- overview générée ;
- 11 fichiers attendus présents ;
- dimensions identiques à la baseline ;
- elementIds attendus présents ;
- `Shadow-59` targets toujours `shadow == null` si le harness ajoute cette vérification ;
- aucune image manquante.

Non bloquant en V0 :

- SHA-256 différent ;
- taille fichier différente ;
- pixel diff non nul.

Justification : les différences de rendu Flutter/PNG peuvent varier selon environnement. Bloquer la CI sur hash exact transformerait le garde-fou en piège à faux positifs avant que le seuil soit validé.

## 14. Invariants structurels recommandés

Invariants à implémenter dans Shadow-67 :

```text
staticInstructions == 10
contactLedge == 10
genericProjection == 0
capture count == 11
contact crop count == 10
overview exists
all expected elementIds present
all screenshots dimensions stable
manifest JSON valid
TSV valid and has 11 lines
projectPath present
mapId == Selbrume
family == building for all contact ledges
profile == default-ground-wide-ellipse for all contact ledges
Shadow-59 targets still shadow null
```

Dimension baseline attendue :

```text
overview: 1320 x 1320
contact ledges: 900 x 650
```

## 15. Workflow update baseline

Workflow recommandé :

1. lancer le harness avec un préfixe de run, par exemple `shadow67`;
2. inspecter les nouvelles images ;
3. lancer la comparaison informative contre `selbrume_shadow_v1` ;
4. si le rendu est attendu, ouvrir un lot explicite d'update baseline ;
5. copier volontairement les nouvelles images dans le dossier baseline ;
6. régénérer `baseline_manifest.json` ;
7. documenter la raison dans un rapport ;
8. ne jamais auto-update silencieusement.

Variables proposées pour Shadow-67 :

```text
SHADOW_BASELINE_DIR
SHADOW_COMPARE_BASELINE
SHADOW_UPDATE_BASELINE
```

Valeurs proposées :

```text
SHADOW_BASELINE_DIR=/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1
SHADOW_COMPARE_BASELINE=false
SHADOW_UPDATE_BASELINE=false
```

Règle V0 :

```text
SHADOW_UPDATE_BASELINE=true ne doit pas être implémenté comme auto-écriture silencieuse dans Shadow-67.
Si la variable existe, elle doit soit être refusée explicitement, soit exiger un lot séparé.
```

Commande future de comparaison :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow67 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
SHADOW_BASELINE_DIR=/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1 \
SHADOW_COMPARE_BASELINE=true \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

## 16. Risques de faux positifs

| Risque | Impact | Mitigation V0 |
|---|---|---|
| macOS vs Linux | pixels/hashes peuvent changer | pixels non bloquants ; dimensions/counts bloquants |
| version Flutter | anti-aliasing et encodage PNG variables | enregistrer version dans manifest futur si simple |
| anti-aliasing | hash exact fragile | ne pas bloquer sur hash |
| fonts | faible ici, map pixel art surtout, mais possible via text overlays futurs | éviter UI host dans V0 ; map-layer only |
| devicePixelRatio | tailles/crops peuvent varier si widget/window | offscreen `PictureRecorder` à dimensions fixes |
| PNG metadata | hash peut changer | hash informatif seulement |
| ordre de rendu | changement réel important | counts + image review ; pixel diff V1 |
| chemin absolu Selbrume | non portable | garder env var, documenter défaut local |
| assets modifiés | image change légitime ou bug | comparaison informative + revue humaine |
| crop instability | faux diff si position change | rendre les crops déterminés par instruction, comme aujourd'hui |
| update silencieux | baseline perd sa valeur | interdire auto-update V0 |

## 17. Recommandation finale

Recommandation :

```text
Shadow-67 doit créer une baseline complète de 11 images sous reports/shadows/baselines/selbrume_shadow_v1/.
Il doit étendre le harness pour lire cette baseline et produire une comparaison informative.
Il ne doit pas rendre les pixels bloquants.
Il doit rendre bloquants les invariants structurels.
```

Pourquoi :

- la capacité de capture est maintenant reproductible ;
- les images Shadow-65 sont déjà le rendu validé après cleanup + retune ;
- 11 images restent un volume raisonnable ;
- une comparaison hash exacte bloquante serait trop fragile ;
- une comparaison informative donnera un vrai garde-fou sans transformer la CI en loterie ;
- les invariants structurels protègent contre les régressions graves sans dépendre du rendu pixel-perfect.

## 18. Plan Shadow-67 Implementation

### Objectif

Créer une baseline V1 versionnée et une comparaison informative du harness Shadow-65, sans golden test bloquant.

### Fichiers à créer

```text
reports/shadows/baselines/selbrume_shadow_v1/README.md
reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json
reports/shadows/baselines/selbrume_shadow_v1/capture_index.tsv
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_selbrume_overview.png
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_contact_ledge_6_le_puits.png
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png
reports/shadows/baselines/selbrume_shadow_v1/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png
reports/shadows/shadow_lot_67_selbrume_shadow_golden_baseline_implementation.md
```

### Fichiers à modifier

```text
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
packages/map_runtime/tool/shadow/README.md
```

### Fichiers interdits

```text
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
packages/map_runtime/lib/src/**
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
assets/**
```

### Étapes proposées

1. copier les 11 captures Shadow-65 vers `reports/shadows/baselines/selbrume_shadow_v1/screenshots/` ;
2. copier le TSV Shadow-65 vers `capture_index.tsv` ;
3. créer `baseline_manifest.json` à partir du manifest Shadow-65, avec chemins relatifs baseline et contexte Shadow-65/64 ;
4. créer un README baseline ;
5. ajouter au harness la lecture optionnelle de `SHADOW_BASELINE_DIR` ;
6. ajouter `SHADOW_COMPARE_BASELINE=true` comme mode informatif ;
7. comparer presence, dimensions et hashes ;
8. échouer uniquement si fichiers/dimensions/counts/invariants structurels manquent ;
9. écrire la comparaison dans le manifest de run ;
10. documenter le workflow dans le README du harness ;
11. générer un rapport Shadow-67 avec sorties de harness, hashes et status Git.

## 19. Tests à prévoir

Commandes :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow67 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow67 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
SHADOW_BASELINE_DIR=/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1 \
SHADOW_COMPARE_BASELINE=true \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

Régressions utiles :

```bash
cd packages/map_runtime && flutter test test/shadow
cd packages/map_core && dart test test/shadow
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_runtime && flutter analyze tool/shadow
```

## 20. Ce qui n'a volontairement pas été modifié

- Aucun code ;
- aucun harness ;
- aucun renderer ;
- aucune policy ;
- aucune géométrie Shadow ;
- aucun profil Shadow ;
- aucun fichier Selbrume ;
- aucun screenshot Shadow-65 ;
- aucune baseline réelle ;
- aucun test CI ;
- aucun golden bloquant.

## 21. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
(aucune sortie)
```

## 22. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text
(aucune sortie)
```

## 23. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale :

```text
(aucune sortie)
```

## 24. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? reports/shadows/shadow_lot_66_selbrume_shadow_golden_baseline_design.md
```

## 25. Risques / réserves

- Le choix `reports/shadows/baselines` est pragmatique pour V0 ; si plusieurs domaines visuels apparaissent, une convention top-level `goldens/` pourra être rediscutée.
- La comparaison non bloquante peut laisser passer une régression subtile si personne ne lit le rapport ; c'est le prix de la prudence avant seuil pixel.
- Le harness reste Selbrume-specific. Ce n'est pas un framework golden global.
- Le manifest baseline devra éviter les chemins absolus pour rester portable.

## 26. Auto-critique

La recommandation évite le piège du hash exact bloquant, mais elle demande une discipline humaine : lire les deltas informatifs. C'est adapté à V0 parce que l'équipe sort d'une phase de stabilisation visuelle. Le point à surveiller dans Shadow-67 sera la tentation d'ajouter trop de modes d'un coup. Il faut garder le lot à baseline + comparaison informative.

## 27. Regard critique sur le prompt

Le prompt est bien cadré : design-only, pas de CI fragile, pas de modification de rendu. La seule ambiguïté est le dossier de baseline : `reports/shadows/baselines` est le meilleur compromis V0, mais ce n'est pas forcément la convention finale si PokeMap généralise des goldens visuels.

## 28. Prompt proposé pour Shadow-67

~~~markdown
# Shadow-67 — Selbrume Shadow Golden Baseline Implementation V0

Tu travailles dans `/Users/karim/Project/pokemonProject`.

Le design Shadow-66 est validé.

Objectif : créer une baseline visuelle V1 à partir des 11 captures Shadow-65 et ajouter au harness Shadow-65 une comparaison baseline informative, non bloquante côté pixels.

Contraintes :

- ne pas modifier le rendu ;
- ne pas modifier Selbrume ;
- ne pas modifier le renderer ;
- ne pas modifier la policy Shadow ;
- ne pas modifier la géométrie Shadow ;
- ne pas ajouter de golden test CI bloquant ;
- ne pas faire de commit.

Créer :

```text
reports/shadows/baselines/selbrume_shadow_v1/README.md
reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json
reports/shadows/baselines/selbrume_shadow_v1/capture_index.tsv
reports/shadows/baselines/selbrume_shadow_v1/screenshots/*.png
reports/shadows/shadow_lot_67_selbrume_shadow_golden_baseline_implementation.md
```

Modifier seulement :

```text
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
packages/map_runtime/tool/shadow/README.md
```

Ajouter les variables :

```text
SHADOW_BASELINE_DIR
SHADOW_COMPARE_BASELINE
```

Comportement :

- `SHADOW_COMPARE_BASELINE=false` par défaut ;
- si `true`, lire la baseline, comparer présence, dimensions, tailles et SHA-256 ;
- échouer seulement sur invariants structurels : counts, fichiers manquants, dimensions inattendues, manifest invalide ;
- ne pas échouer sur hash différent en V0 ;
- écrire la comparaison dans le manifest de run.

Validations :

```bash
cd packages/map_runtime
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"

SHADOW_BASELINE_DIR=/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1 \
SHADOW_COMPARE_BASELINE=true \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"

flutter analyze tool/shadow
flutter test test/shadow
cd ../map_core && dart test test/shadow
cd ../map_editor && flutter test test/application/shadow
```

Rapport attendu : inclure les fichiers créés, diff complet du harness/README, hashes baseline, sortie harness normal, sortie harness compare, git diff/stat/status, risques et prochain lot.
~~~
