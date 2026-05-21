# Shadow-67 — Selbrume Shadow Golden Baseline Implementation V0

## 1. Résumé exécutif
Shadow-67 transforme les captures Shadow-65 en baseline versionnée `selbrume_shadow_v1` et étend le harness manuel pour produire une comparaison baseline vs current. Les invariants structurels restent bloquants (`staticInstructions=10`, `contactLedge=10`, `genericProjection=0`, 11 captures et dimensions stables). Les différences de hash / contenu image sont informatives en V0 et ne cassent pas le run. Aucun rendu, aucune donnée Selbrume, aucun renderer, aucune policy et aucune géométrie Shadow n’ont été modifiés.

## 2. Rappel Shadow-66 Design validé
Shadow-66 a validé une baseline complète de 11 images stockée sous `reports/shadows/baselines/selbrume_shadow_v1/`, avec comparaison hash/dimensions informative et invariants structurels bloquants. Shadow-67 est l’implémentation de ce design validé, pas une nouvelle calibration visuelle.

## 3. État initial du worktree
Commande: `git status --short --untracked-files=all`
```text
(no output)
```

## 4. Décision AGENTS / design gate
Commande: `find .. -name AGENTS.md -print`
```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```
Commande: `rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md`
```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```
Décision: le design gate product-facing a été satisfait par Shadow-66. Ce lot modifie uniquement un outil manuel sous `packages/map_runtime/tool/shadow/` et ne modifie aucun rendu produit.

## 5. Fichiers modifiés / créés
Modifiés:
- `packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart`
- `packages/map_runtime/tool/shadow/README.md`

Créés:
- `reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json`
- 11 PNG baseline sous `reports/shadows/baselines/selbrume_shadow_v1/`
- 11 PNG current sous `reports/shadows/screenshots/shadow67_*.png`
- `reports/shadows/shadow_lot_67_capture_index.tsv`
- `reports/shadows/shadow_lot_67_capture_manifest.json`
- `reports/shadows/shadow_lot_67_baseline_compare.json`
- `reports/shadows/shadow_lot_67_baseline_compare.tsv`
- `reports/shadows/shadow_lot_67_selbrume_shadow_golden_baseline_implementation.md`

Supprimés: Aucun.

Fichiers Selbrume modifiés: Aucun.

## 6. Baseline créée
Dossier: `reports/shadows/baselines/selbrume_shadow_v1/`
PNG count: 11
Manifest: `reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json`

Liste baseline PNG:
```text
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png
reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png
```

## 7. Mapping Shadow-65 -> baseline
| Shadow-65 original | Baseline V1 | SHA-256 equal |
|---|---|---|
| `reports/shadows/screenshots/shadow65_selbrume_overview.png` | `reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png` | oui (`5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25`) |
| `reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png` | `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png` | oui (`f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48`) |
| `reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png` | `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png` | oui (`c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472`) |
| `reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png` | `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png` | oui (`27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd`) |
| `reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png` | `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png` | oui (`4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a`) |
| `reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png` | `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png` | oui (`568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530`) |
| `reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png` | `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png` | oui (`eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a`) |
| `reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png` | `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png` | oui (`4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796`) |
| `reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png` | `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png` | oui (`f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8`) |
| `reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png` | `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png` | oui (`e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3`) |
| `reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png` | `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png` | oui (`57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4`) |

## 8. Baseline manifest
```json
{
  "baselineId": "selbrume_shadow_v1",
  "sourceLot": "Shadow-65",
  "designLot": "Shadow-66",
  "mapId": "Selbrume",
  "projectPath": "/Users/karim/Desktop/selbrume/project.json",
  "createdFromPrefix": "shadow65",
  "comparisonMode": "informative-hash-v0",
  "pixelDiffBlocking": false,
  "structureBlocking": true,
  "counts": {
    "staticInstructions": 10,
    "contactLedge": 10,
    "genericProjection": 0,
    "captures": 11
  },
  "expected": {
    "contactElementIds": [
      "selbrum_maison_3",
      "selbrum_maison_4",
      "selbrum_maison_1",
      "selbrume_centre_pok_mon",
      "selbrum_maison_7",
      "le_puits",
      "selbrum_maison_4",
      "selbrum_maison_2",
      "selbrum_maison_8",
      "kiosque_l_gumes"
    ],
    "families": {
      "building": 10
    },
    "profiles": {
      "default-ground-wide-ellipse": 10
    },
    "overviewDimensions": {
      "width": 1320,
      "height": 1320
    },
    "contactCaptureDimensions": {
      "width": 900,
      "height": 650
    }
  },
  "captures": [
    {
      "kind": "overview",
      "rank": null,
      "elementId": null,
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_selbrume_overview.png",
      "sha256": "5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25",
      "fileSizeBytes": 2529901,
      "width": 1320,
      "height": 1320
    },
    {
      "kind": "contactLedge",
      "rank": 1,
      "elementId": "selbrum_maison_3",
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_contact_ledge_1_selbrum_maison_3.png",
      "sha256": "f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48",
      "fileSizeBytes": 180911,
      "width": 900,
      "height": 650,
      "elementName": "selbrum maison 3",
      "placementIdOrIndex": "l_tile_maison_selbrume::24::12",
      "worldX": 2304.0,
      "worldY": 1152.0,
      "cropLeft": 2189.12128,
      "cropTop": 1377.076352,
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
      "kind": "contactLedge",
      "rank": 2,
      "elementId": "selbrum_maison_4",
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_contact_ledge_2_selbrum_maison_4.png",
      "sha256": "c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472",
      "fileSizeBytes": 168205,
      "width": 900,
      "height": 650,
      "elementName": "selbrum maison  4",
      "placementIdOrIndex": "l_tile_maison_selbrume::17::17",
      "worldX": 1632.0,
      "worldY": 1632.0,
      "cropLeft": 1462.7008,
      "cropTop": 1763.494016,
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
      "kind": "contactLedge",
      "rank": 3,
      "elementId": "selbrum_maison_1",
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_contact_ledge_3_selbrum_maison_1.png",
      "sha256": "27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd",
      "fileSizeBytes": 181666,
      "width": 900,
      "height": 650,
      "elementName": "selbrum maison 1",
      "placementIdOrIndex": "l_tile_maison_selbrume::10::18",
      "worldX": 960.0,
      "worldY": 1728.0,
      "cropLeft": 790.7008000000001,
      "cropTop": 1859.494016,
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
      "kind": "contactLedge",
      "rank": 4,
      "elementId": "selbrume_centre_pok_mon",
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_contact_ledge_4_selbrume_centre_pok_mon.png",
      "sha256": "4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a",
      "fileSizeBytes": 162048,
      "width": 900,
      "height": 650,
      "elementName": "selbrume centre pokémon",
      "placementIdOrIndex": "l_tile_maison_selbrume::29::22",
      "worldX": 2784.0,
      "worldY": 2112.0,
      "cropLeft": 2669.12128,
      "cropTop": 2243.494016,
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
      "kind": "contactLedge",
      "rank": 5,
      "elementId": "selbrum_maison_7",
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_contact_ledge_5_selbrum_maison_7.png",
      "sha256": "568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530",
      "fileSizeBytes": 177970,
      "width": 900,
      "height": 650,
      "elementName": "selbrum maison  7",
      "placementIdOrIndex": "l_tile_maison_selbrume::38::22",
      "worldX": 3648.0,
      "worldY": 2112.0,
      "cropLeft": 3496.84096,
      "cropTop": 2243.494016,
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
      "kind": "contactLedge",
      "rank": 6,
      "elementId": "le_puits",
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_contact_ledge_6_le_puits.png",
      "sha256": "eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a",
      "fileSizeBytes": 146654,
      "width": 900,
      "height": 650,
      "elementName": "le puits",
      "placementIdOrIndex": "l_tile_maison_selbrume::23::27",
      "worldX": 2208.0,
      "worldY": 2592.0,
      "cropLeft": 2020.5606400000001,
      "cropTop": 2629.91168,
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
      "kind": "contactLedge",
      "rank": 7,
      "elementId": "selbrum_maison_4",
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_contact_ledge_7_selbrum_maison_4.png",
      "sha256": "4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796",
      "fileSizeBytes": 151150,
      "width": 900,
      "height": 650,
      "elementName": "selbrum maison  4",
      "placementIdOrIndex": "l_tile_maison_selbrume::36::29",
      "worldX": 3456.0,
      "worldY": 2784.0,
      "cropLeft": 3286.7008,
      "cropTop": 2915.494016,
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
      "kind": "contactLedge",
      "rank": 8,
      "elementId": "selbrum_maison_2",
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_contact_ledge_8_selbrum_maison_2.png",
      "sha256": "f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8",
      "fileSizeBytes": 183159,
      "width": 900,
      "height": 650,
      "elementName": "selbrum maison  2",
      "placementIdOrIndex": "l_tile_maison_selbrume::10::30",
      "worldX": 960.0,
      "worldY": 2880.0,
      "cropLeft": 808.84096,
      "cropTop": 3105.076352,
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
      "kind": "contactLedge",
      "rank": 9,
      "elementId": "selbrum_maison_8",
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_contact_ledge_9_selbrum_maison_8.png",
      "sha256": "e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3",
      "fileSizeBytes": 159359,
      "width": 900,
      "height": 650,
      "elementName": "selbrum maison  8",
      "placementIdOrIndex": "l_tile_maison_selbrume::18::33",
      "worldX": 1728.0,
      "worldY": 3168.0,
      "cropLeft": 1667.54176,
      "cropTop": 3299.494016,
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
      "kind": "contactLedge",
      "rank": 10,
      "elementId": "kiosque_l_gumes",
      "baselinePath": "reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png",
      "sourcePath": "reports/shadows/screenshots/shadow65_contact_ledge_10_kiosque_l_gumes.png",
      "sha256": "57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4",
      "fileSizeBytes": 158827,
      "width": 900,
      "height": 650,
      "elementName": "kiosque à légumes",
      "placementIdOrIndex": "l_tile_maison_selbrume::36::35",
      "worldX": 3456.0,
      "worldY": 3360.0,
      "cropLeft": 3304.84096,
      "cropTop": 3491.494016,
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
}

```

## 9. Changement du harness
Le harness accepte maintenant `SHADOW_COMPARE_BASELINE`, `SHADOW_BASELINE_DIR`, `SHADOW_BASELINE_COMPARE_OUTPUT_JSON` et `SHADOW_BASELINE_COMPARE_OUTPUT_TSV`. Sans baseline, il conserve le comportement Shadow-65. Avec baseline, il charge le manifest, vérifie les invariants structurels, compare dimensions/taille/hash, écrit JSON+TSV et ne bloque pas sur un hash différent.

## 10. Variables d’environnement ajoutées
- `SHADOW_COMPARE_BASELINE`: active la comparaison baseline quand `true`.
- `SHADOW_BASELINE_DIR`: dossier contenant `baseline_manifest.json` et les PNG baseline.
- `SHADOW_BASELINE_COMPARE_OUTPUT_JSON`: sortie JSON de comparaison.
- `SHADOW_BASELINE_COMPARE_OUTPUT_TSV`: sortie TSV de comparaison.

Variables existantes conservées: `SELBRUME_PROJECT_PATH`, `SHADOW_SCREENSHOT_OUTPUT_DIR`, `SHADOW_SCREENSHOT_PREFIX`.

## 11. Invariants bloquants V0
Le harness échoue en mode baseline si un invariant structurel est cassé:
- `staticInstructions != 10`
- `contactLedge != 10`
- `genericProjection != 0`
- capture count != 11
- overview manquante
- contact ledge manquante
- elementIds attendus absents ou désordonnés
- manifest baseline manquant
- capture baseline/current manquante
- dimensions mismatch

## 12. Comparaison informative V0
Différences non bloquantes en V0:
- SHA-256 différent
- taille fichier différente
- contenu pixel différent implicite

Statut utilisé: `pixel-diff-informative`. Preuve de non-blocage hash diff:
```text
Command: run harness against a temporary baseline manifest where only contact_ledge_01 expected SHA-256 was changed to 0000000000000000000000000000000000000000000000000000000000000000.
Result summary:
{
  "baselineComparison": {
    "baselineId": "selbrume_shadow_v1",
    "baselineDir": "/tmp/shadow67_hashdiff/baseline",
    "mode": "informative-hash-v0",
    "total": 11,
    "exactMatches": 10,
    "informativeDiffs": 1,
    "blockingFailures": 0,
    "hasBlockingFailure": false
  }
}
Final line: 00:01 +1: All tests passed!
TSV evidence:
3:1	contactLedge	selbrum_maison_3	/tmp/shadow67_hashdiff/baseline/contact_ledge_01_selbrum_maison_3.png	/tmp/shadow67_hashdiff/screenshots/shadow67hashdiff_contact_ledge_1_selbrum_maison_3.png	0000000000000000000000000000000000000000000000000000000000000000	f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48	false	180911	180911	900	650	900	650	pixel-diff-informative
```

## 13. Commandes lancées
Commande RED TDD avant implémentation:
```text
Command: run the Shadow-65 harness before implementation with SHADOW_COMPARE_BASELINE=true and then require /tmp/shadow67_red/baseline_compare.json.
Relevant output:
00:00 +0: selbrume shadow screenshot harness
capture rank=1 element=selbrum_maison_3 cropLeft=2189.1 cropTop=1377.1
...
{
  "projectPath": "/Users/karim/Desktop/selbrume/project.json",
  "outputDir": "/tmp/shadow67_red/screenshots",
  "prefix": "shadow67red",
  "indexTsv": "/tmp/shadow67_red/shadow_lot_65_capture_index.tsv",
  "manifest": "/tmp/shadow67_red/shadow_lot_65_capture_manifest.json",
  "counts": {
    "staticInstructions": 10,
    "contactLedge": 10,
    "genericProjection": 0
  }
}
00:01 +1: All tests passed!
Then: test -f /tmp/shadow67_red/baseline_compare.json failed.
Expected RED reason: baseline compare outputs did not exist before Shadow-67 implementation.
```
Commande harness compare principale:
```text
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow67 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
SHADOW_COMPARE_BASELINE=true \
SHADOW_BASELINE_DIR=/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1 \
SHADOW_BASELINE_COMPARE_OUTPUT_JSON=/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_baseline_compare.json \
SHADOW_BASELINE_COMPARE_OUTPUT_TSV=/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_baseline_compare.tsv \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

## 14. Résultats du harness compare
```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
00:00 +0: selbrume shadow screenshot harness
capture rank=1 element=selbrum_maison_3 cropLeft=2189.1 cropTop=1377.1
capture rank=2 element=selbrum_maison_4 cropLeft=3264.6 cropTop=1457.1
capture rank=3 element=selbrum_maison_1 cropLeft=3774.1 cropTop=2074.8
capture rank=4 element=selbrume_centre_pok_mon cropLeft=2300.4 cropTop=2248.5
capture rank=5 element=selbrum_maison_7 cropLeft=2626.0 cropTop=2715.6
capture rank=6 element=le_puits cropLeft=2157.5 cropTop=3077.8
capture rank=7 element=selbrum_maison_4 cropLeft=3272.2 cropTop=3094.7
capture rank=8 element=selbrum_maison_2 cropLeft=4027.1 cropTop=3178.1
capture rank=9 element=selbrum_maison_8 cropLeft=2497.4 cropTop=3448.1
capture rank=10 element=kiosque_l_gumes cropLeft=3304.8 cropTop=3491.5
baseline comparison wrote /Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_baseline_compare.json and /Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_baseline_compare.tsv
{
  "projectPath": "/Users/karim/Desktop/selbrume/project.json",
  "outputDir": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots",
  "prefix": "shadow67",
  "overview": {
    "kind": "overview",
    "rank": null,
    "elementId": null,
    "path": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_selbrume_overview.png",
    "sha256": "5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25",
    "fileSizeBytes": 2529901,
    "width": 1320,
    "height": 1320
  },
  "indexTsv": "/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_capture_index.tsv",
  "manifest": "/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_capture_manifest.json",
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
  "baselineComparison": {
    "baselineId": "selbrume_shadow_v1",
    "baselineDir": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1",
    "mode": "informative-hash-v0",
    "total": 11,
    "exactMatches": 11,
    "informativeDiffs": 0,
    "blockingFailures": 0,
    "hasBlockingFailure": false
  }
}
00:01 +1: All tests passed!
```

## 15. Artefacts générés
Shadow67 PNG:
```text
reports/shadows/screenshots/shadow67_contact_ledge_10_kiosque_l_gumes.png
reports/shadows/screenshots/shadow67_contact_ledge_1_selbrum_maison_3.png
reports/shadows/screenshots/shadow67_contact_ledge_2_selbrum_maison_4.png
reports/shadows/screenshots/shadow67_contact_ledge_3_selbrum_maison_1.png
reports/shadows/screenshots/shadow67_contact_ledge_4_selbrume_centre_pok_mon.png
reports/shadows/screenshots/shadow67_contact_ledge_5_selbrum_maison_7.png
reports/shadows/screenshots/shadow67_contact_ledge_6_le_puits.png
reports/shadows/screenshots/shadow67_contact_ledge_7_selbrum_maison_4.png
reports/shadows/screenshots/shadow67_contact_ledge_8_selbrum_maison_2.png
reports/shadows/screenshots/shadow67_contact_ledge_9_selbrum_maison_8.png
reports/shadows/screenshots/shadow67_selbrume_overview.png
```
Hashes baseline PNG:
```text
f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48  reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png
c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472  reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png
27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd  reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png
4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a  reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png
568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530  reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png
eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a  reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png
4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796  reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png
f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8  reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png
e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3  reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png
57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4  reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png
5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25  reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png
```
Hashes shadow67 PNG:
```text
57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4  reports/shadows/screenshots/shadow67_contact_ledge_10_kiosque_l_gumes.png
f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48  reports/shadows/screenshots/shadow67_contact_ledge_1_selbrum_maison_3.png
c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472  reports/shadows/screenshots/shadow67_contact_ledge_2_selbrum_maison_4.png
27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd  reports/shadows/screenshots/shadow67_contact_ledge_3_selbrum_maison_1.png
4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a  reports/shadows/screenshots/shadow67_contact_ledge_4_selbrume_centre_pok_mon.png
568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530  reports/shadows/screenshots/shadow67_contact_ledge_5_selbrum_maison_7.png
eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a  reports/shadows/screenshots/shadow67_contact_ledge_6_le_puits.png
4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796  reports/shadows/screenshots/shadow67_contact_ledge_7_selbrum_maison_4.png
f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8  reports/shadows/screenshots/shadow67_contact_ledge_8_selbrum_maison_2.png
e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3  reports/shadows/screenshots/shadow67_contact_ledge_9_selbrum_maison_8.png
5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25  reports/shadows/screenshots/shadow67_selbrume_overview.png
```
Dimensions PNG (`file`):
```text
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png: PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png:                PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png:        PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png:         PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png:                        PNG image data, 1320 x 1320, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_contact_ledge_10_kiosque_l_gumes.png:                 PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_contact_ledge_1_selbrum_maison_3.png:                 PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_contact_ledge_2_selbrum_maison_4.png:                 PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_contact_ledge_3_selbrum_maison_1.png:                 PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_contact_ledge_4_selbrume_centre_pok_mon.png:          PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_contact_ledge_5_selbrum_maison_7.png:                 PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_contact_ledge_6_le_puits.png:                         PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_contact_ledge_7_selbrum_maison_4.png:                 PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_contact_ledge_8_selbrum_maison_2.png:                 PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_contact_ledge_9_selbrum_maison_8.png:                 PNG image data, 900 x 650, 8-bit/color RGBA, non-interlaced
reports/shadows/screenshots/shadow67_selbrume_overview.png:                                PNG image data, 1320 x 1320, 8-bit/color RGBA, non-interlaced
```
Tailles fichiers (`ls -l`):
```text
-rw-r--r--@ 1 karim  staff   180911 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png
-rw-r--r--@ 1 karim  staff   168205 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png
-rw-r--r--@ 1 karim  staff   181666 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png
-rw-r--r--@ 1 karim  staff   162048 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png
-rw-r--r--@ 1 karim  staff   177970 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png
-rw-r--r--@ 1 karim  staff   146654 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png
-rw-r--r--@ 1 karim  staff   151150 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png
-rw-r--r--@ 1 karim  staff   183159 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png
-rw-r--r--@ 1 karim  staff   159359 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png
-rw-r--r--@ 1 karim  staff   158827 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png
-rw-r--r--@ 1 karim  staff  2529901 May 18 23:15 reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png
-rw-r--r--@ 1 karim  staff   158827 May 18 23:52 reports/shadows/screenshots/shadow67_contact_ledge_10_kiosque_l_gumes.png
-rw-r--r--@ 1 karim  staff   180911 May 18 23:52 reports/shadows/screenshots/shadow67_contact_ledge_1_selbrum_maison_3.png
-rw-r--r--@ 1 karim  staff   168205 May 18 23:52 reports/shadows/screenshots/shadow67_contact_ledge_2_selbrum_maison_4.png
-rw-r--r--@ 1 karim  staff   181666 May 18 23:52 reports/shadows/screenshots/shadow67_contact_ledge_3_selbrum_maison_1.png
-rw-r--r--@ 1 karim  staff   162048 May 18 23:52 reports/shadows/screenshots/shadow67_contact_ledge_4_selbrume_centre_pok_mon.png
-rw-r--r--@ 1 karim  staff   177970 May 18 23:52 reports/shadows/screenshots/shadow67_contact_ledge_5_selbrum_maison_7.png
-rw-r--r--@ 1 karim  staff   146654 May 18 23:52 reports/shadows/screenshots/shadow67_contact_ledge_6_le_puits.png
-rw-r--r--@ 1 karim  staff   151150 May 18 23:52 reports/shadows/screenshots/shadow67_contact_ledge_7_selbrum_maison_4.png
-rw-r--r--@ 1 karim  staff   183159 May 18 23:52 reports/shadows/screenshots/shadow67_contact_ledge_8_selbrum_maison_2.png
-rw-r--r--@ 1 karim  staff   159359 May 18 23:52 reports/shadows/screenshots/shadow67_contact_ledge_9_selbrum_maison_8.png
-rw-r--r--@ 1 karim  staff  2529901 May 18 23:52 reports/shadows/screenshots/shadow67_selbrume_overview.png
```
Table synthétique PNG:
| Path | Size bytes | Dimensions | SHA-256 |
|---|---:|---|---|
| `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png` | 180911 | 900x650 | `f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48` |
| `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png` | 168205 | 900x650 | `c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472` |
| `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png` | 181666 | 900x650 | `27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd` |
| `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png` | 162048 | 900x650 | `4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a` |
| `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png` | 177970 | 900x650 | `568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530` |
| `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png` | 146654 | 900x650 | `eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a` |
| `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png` | 151150 | 900x650 | `4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796` |
| `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png` | 183159 | 900x650 | `f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8` |
| `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png` | 159359 | 900x650 | `e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3` |
| `reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png` | 158827 | 900x650 | `57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4` |
| `reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png` | 2529901 | 1320x1320 | `5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25` |
| `reports/shadows/screenshots/shadow67_contact_ledge_10_kiosque_l_gumes.png` | 158827 | 900x650 | `57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4` |
| `reports/shadows/screenshots/shadow67_contact_ledge_1_selbrum_maison_3.png` | 180911 | 900x650 | `f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48` |
| `reports/shadows/screenshots/shadow67_contact_ledge_2_selbrum_maison_4.png` | 168205 | 900x650 | `c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472` |
| `reports/shadows/screenshots/shadow67_contact_ledge_3_selbrum_maison_1.png` | 181666 | 900x650 | `27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd` |
| `reports/shadows/screenshots/shadow67_contact_ledge_4_selbrume_centre_pok_mon.png` | 162048 | 900x650 | `4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a` |
| `reports/shadows/screenshots/shadow67_contact_ledge_5_selbrum_maison_7.png` | 177970 | 900x650 | `568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530` |
| `reports/shadows/screenshots/shadow67_contact_ledge_6_le_puits.png` | 146654 | 900x650 | `eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a` |
| `reports/shadows/screenshots/shadow67_contact_ledge_7_selbrum_maison_4.png` | 151150 | 900x650 | `4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796` |
| `reports/shadows/screenshots/shadow67_contact_ledge_8_selbrum_maison_2.png` | 183159 | 900x650 | `f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8` |
| `reports/shadows/screenshots/shadow67_contact_ledge_9_selbrum_maison_8.png` | 159359 | 900x650 | `e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3` |
| `reports/shadows/screenshots/shadow67_selbrume_overview.png` | 2529901 | 1320x1320 | `5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25` |

## 16. Comparison JSON
```json
{
  "baselineId": "selbrume_shadow_v1",
  "baselineDir": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1",
  "mode": "informative-hash-v0",
  "total": 11,
  "exactMatches": 11,
  "informativeDiffs": 0,
  "blockingFailures": 0,
  "hasBlockingFailure": false,
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
  "rows": [
    {
      "rank": null,
      "kind": "overview",
      "elementId": null,
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_selbrume_overview.png",
      "baselineSha256": "5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25",
      "currentSha256": "5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 2529901,
      "currentFileSizeBytes": 2529901,
      "baselineWidth": 1320,
      "baselineHeight": 1320,
      "currentWidth": 1320,
      "currentHeight": 1320,
      "status": "match"
    },
    {
      "rank": 1,
      "kind": "contactLedge",
      "elementId": "selbrum_maison_3",
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_1_selbrum_maison_3.png",
      "baselineSha256": "f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48",
      "currentSha256": "f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 180911,
      "currentFileSizeBytes": 180911,
      "baselineWidth": 900,
      "baselineHeight": 650,
      "currentWidth": 900,
      "currentHeight": 650,
      "status": "match"
    },
    {
      "rank": 2,
      "kind": "contactLedge",
      "elementId": "selbrum_maison_4",
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_2_selbrum_maison_4.png",
      "baselineSha256": "c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472",
      "currentSha256": "c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 168205,
      "currentFileSizeBytes": 168205,
      "baselineWidth": 900,
      "baselineHeight": 650,
      "currentWidth": 900,
      "currentHeight": 650,
      "status": "match"
    },
    {
      "rank": 3,
      "kind": "contactLedge",
      "elementId": "selbrum_maison_1",
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_3_selbrum_maison_1.png",
      "baselineSha256": "27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd",
      "currentSha256": "27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 181666,
      "currentFileSizeBytes": 181666,
      "baselineWidth": 900,
      "baselineHeight": 650,
      "currentWidth": 900,
      "currentHeight": 650,
      "status": "match"
    },
    {
      "rank": 4,
      "kind": "contactLedge",
      "elementId": "selbrume_centre_pok_mon",
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_4_selbrume_centre_pok_mon.png",
      "baselineSha256": "4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a",
      "currentSha256": "4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 162048,
      "currentFileSizeBytes": 162048,
      "baselineWidth": 900,
      "baselineHeight": 650,
      "currentWidth": 900,
      "currentHeight": 650,
      "status": "match"
    },
    {
      "rank": 5,
      "kind": "contactLedge",
      "elementId": "selbrum_maison_7",
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_5_selbrum_maison_7.png",
      "baselineSha256": "568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530",
      "currentSha256": "568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 177970,
      "currentFileSizeBytes": 177970,
      "baselineWidth": 900,
      "baselineHeight": 650,
      "currentWidth": 900,
      "currentHeight": 650,
      "status": "match"
    },
    {
      "rank": 6,
      "kind": "contactLedge",
      "elementId": "le_puits",
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_6_le_puits.png",
      "baselineSha256": "eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a",
      "currentSha256": "eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 146654,
      "currentFileSizeBytes": 146654,
      "baselineWidth": 900,
      "baselineHeight": 650,
      "currentWidth": 900,
      "currentHeight": 650,
      "status": "match"
    },
    {
      "rank": 7,
      "kind": "contactLedge",
      "elementId": "selbrum_maison_4",
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_7_selbrum_maison_4.png",
      "baselineSha256": "4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796",
      "currentSha256": "4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 151150,
      "currentFileSizeBytes": 151150,
      "baselineWidth": 900,
      "baselineHeight": 650,
      "currentWidth": 900,
      "currentHeight": 650,
      "status": "match"
    },
    {
      "rank": 8,
      "kind": "contactLedge",
      "elementId": "selbrum_maison_2",
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_8_selbrum_maison_2.png",
      "baselineSha256": "f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8",
      "currentSha256": "f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 183159,
      "currentFileSizeBytes": 183159,
      "baselineWidth": 900,
      "baselineHeight": 650,
      "currentWidth": 900,
      "currentHeight": 650,
      "status": "match"
    },
    {
      "rank": 9,
      "kind": "contactLedge",
      "elementId": "selbrum_maison_8",
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_9_selbrum_maison_8.png",
      "baselineSha256": "e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3",
      "currentSha256": "e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 159359,
      "currentFileSizeBytes": 159359,
      "baselineWidth": 900,
      "baselineHeight": 650,
      "currentWidth": 900,
      "currentHeight": 650,
      "status": "match"
    },
    {
      "rank": 10,
      "kind": "contactLedge",
      "elementId": "kiosque_l_gumes",
      "baselinePath": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png",
      "currentPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_10_kiosque_l_gumes.png",
      "baselineSha256": "57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4",
      "currentSha256": "57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4",
      "exactHashMatch": true,
      "baselineFileSizeBytes": 158827,
      "currentFileSizeBytes": 158827,
      "baselineWidth": 900,
      "baselineHeight": 650,
      "currentWidth": 900,
      "currentHeight": 650,
      "status": "match"
    }
  ]
}
```

## 17. Comparison TSV
```tsv
rank	kind	elementId	baselinePath	currentPath	baselineSha256	currentSha256	exactHashMatch	baselineFileSizeBytes	currentFileSizeBytes	baselineWidth	baselineHeight	currentWidth	currentHeight	status
	overview		/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_selbrume_overview.png	5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25	5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25	true	2529901	2529901	1320	1320	1320	1320	match
1	contactLedge	selbrum_maison_3	/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_1_selbrum_maison_3.png	f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48	f941d9bead4676ae5c35709cae16cf28566eb4f127626af5becd4de317adbe48	true	180911	180911	900	650	900	650	match
2	contactLedge	selbrum_maison_4	/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_2_selbrum_maison_4.png	c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472	c5d9d4fe203baeedafe71275be0460f06d7929aa21aaf794ef736a0b0b710472	true	168205	168205	900	650	900	650	match
3	contactLedge	selbrum_maison_1	/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_3_selbrum_maison_1.png	27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd	27d4bb763c7bab07d5355828041ab357c456d27b1fb207431b35abded08ae4dd	true	181666	181666	900	650	900	650	match
4	contactLedge	selbrume_centre_pok_mon	/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_4_selbrume_centre_pok_mon.png	4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a	4ef8b44a2548b855ac7414ba6cee55fd124e6e0c2dddd3786a4add2b0db94a3a	true	162048	162048	900	650	900	650	match
5	contactLedge	selbrum_maison_7	/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_5_selbrum_maison_7.png	568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530	568955c97486474a1f5a735f2a39c9435d4e2b3efd4a26c4fefe80d7caa23530	true	177970	177970	900	650	900	650	match
6	contactLedge	le_puits	/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_6_le_puits.png	eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a	eb2216c6f3cf917e228075950d2dc60308a798a31fd29a4dab021b6902bf384a	true	146654	146654	900	650	900	650	match
7	contactLedge	selbrum_maison_4	/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_7_selbrum_maison_4.png	4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796	4a11b7d013b6a8295f11efe31742b6b0a41d7a5a9b61c233920e6d6d69823796	true	151150	151150	900	650	900	650	match
8	contactLedge	selbrum_maison_2	/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_8_selbrum_maison_2.png	f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8	f87857012a218e37651bb937845acb94fdc94417e89e4c687885702dc3e5b7b8	true	183159	183159	900	650	900	650	match
9	contactLedge	selbrum_maison_8	/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_9_selbrum_maison_8.png	e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3	e153e08a9695f7d009456d02407776c402eecec5c99734406561bbded872e5f3	true	159359	159359	900	650	900	650	match
10	contactLedge	kiosque_l_gumes	/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_10_kiosque_l_gumes.png	57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4	57013cf3c072149f843d943f55e35dddf91fa2b460b9709e141899c128f0b2a4	true	158827	158827	900	650	900	650	match

```

## 18. Capture manifest Shadow-67
```json
{
  "lot": "Shadow-67",
  "projectPath": "/Users/karim/Desktop/selbrume/project.json",
  "mapId": "Selbrume",
  "prefix": "shadow67",
  "outputDir": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots",
  "overview": {
    "kind": "overview",
    "rank": null,
    "elementId": null,
    "path": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_selbrume_overview.png",
    "sha256": "5f9d2c779c8fdd17dbe888f79874ba8823ce62801c560d577b4f8cfb1bce8a25",
    "fileSizeBytes": 2529901,
    "width": 1320,
    "height": 1320
  },
  "indexTsv": "/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_capture_index.tsv",
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
  "baselineComparison": {
    "baselineId": "selbrume_shadow_v1",
    "baselineDir": "/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1",
    "mode": "informative-hash-v0",
    "total": 11,
    "exactMatches": 11,
    "informativeDiffs": 0,
    "blockingFailures": 0,
    "hasBlockingFailure": false
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_1_selbrum_maison_3.png",
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_2_selbrum_maison_4.png",
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_3_selbrum_maison_1.png",
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_4_selbrume_centre_pok_mon.png",
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_5_selbrum_maison_7.png",
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_6_le_puits.png",
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_7_selbrum_maison_4.png",
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_8_selbrum_maison_2.png",
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_9_selbrum_maison_8.png",
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
      "screenshotPath": "/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_10_kiosque_l_gumes.png",
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
}
```

## 19. Capture index Shadow-67
```tsv
rank	elementId	elementName	placementIdOrIndex	worldX	worldY	cropLeft	cropTop	cropWidth	cropHeight	screenshotPath	shapeKind	geometryType	family	profile	opacity	instructionWidth	instructionHeight	instructionArea
1	selbrum_maison_3	selbrum maison 3	l_tile_maison_selbrume::24::12	2304.0	1152.0	2189.12128	1377.076352	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_1_selbrum_maison_3.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	477.7574400000003	17.483647999999903	8352.942910341078
2	selbrum_maison_4	selbrum maison  4	l_tile_maison_selbrume::17::17	1632.0	1632.0	1462.7008	1763.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_2_selbrum_maison_4.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	298.59839999999986	16.985983999999917	5071.987644825573
3	selbrum_maison_1	selbrum maison 1	l_tile_maison_selbrume::10::18	960.0	1728.0	790.7008000000001	1859.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_3_selbrum_maison_1.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	298.59839999999986	16.985983999999917	5071.987644825573
4	selbrume_centre_pok_mon	selbrume centre pokémon	l_tile_maison_selbrume::29::22	2784.0	2112.0	2669.12128	2243.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_4_selbrume_centre_pok_mon.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	477.7574400000003	16.985983999999917	8115.180231720926
5	selbrum_maison_7	selbrum maison  7	l_tile_maison_selbrume::38::22	3648.0	2112.0	3496.84096	2243.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_5_selbrum_maison_7.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	358.31807999999955	16.985983999999917	6086.3851737906825
6	le_puits	le puits	l_tile_maison_selbrume::23::27	2208.0	2592.0	2020.5606400000001	2629.91168	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_6_le_puits.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	238.8787199999997	16.48831999999993	3938.7087765503784
7	selbrum_maison_4	selbrum maison  4	l_tile_maison_selbrume::36::29	3456.0	2784.0	3286.7008	2915.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_7_selbrum_maison_4.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	298.59839999999986	16.985983999999917	5071.987644825573
8	selbrum_maison_2	selbrum maison  2	l_tile_maison_selbrume::10::30	960.0	2880.0	808.84096	3105.076352	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_8_selbrum_maison_2.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	358.31808	17.483647999999903	6264.707182755806
9	selbrum_maison_8	selbrum maison  8	l_tile_maison_selbrume::18::33	1728.0	3168.0	1667.54176	3299.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_9_selbrum_maison_8.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	656.9164799999999	16.985983999999917	11158.372818616263
10	kiosque_l_gumes	kiosque à légumes	l_tile_maison_selbrume::36::35	3456.0	3360.0	3304.84096	3491.494016	900	650	/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow67_contact_ledge_10_kiosque_l_gumes.png	projectedPolygon	contactLedge	building	default-ground-wide-ellipse	0.2	358.31808	16.985983999999917	6086.385173790691

```

## 20. Résultats des tests de régression
```text
cd packages/map_runtime && flutter test test/shadow
Final line: 00:03 +233: All tests passed!

cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
Final line: 00:00 +3: All tests passed!

cd packages/map_core && dart test test/shadow
Final line: 00:00 +284: All tests passed!

cd packages/map_editor && flutter test test/application/shadow
Final line: 00:01 +96: All tests passed!
```

## 21. Résultat analyze
```text
cd packages/map_runtime && flutter analyze tool/shadow
Analyzing shadow...
No issues found! (ran in 1.8s)
```

## 22. Selbrume inchangé
Hashes après lot:
```text
3c3669a8274e31087b617fd46337c28aef6593f376a7d0a54c2d9fb8e31b389d  /Users/karim/Desktop/selbrume/project.json
8fd1f7efdc02413106a21068e3af310b3149c07023cfad64ddaa101f2c2cac63  /Users/karim/Desktop/selbrume/maps/Selbrume.json
```
Aucun fichier sous `/Users/karim/Desktop/selbrume/` n’a été écrit par ce lot.

## 23. Ce qui n’a volontairement pas été fait
- Pas de modification du renderer.
- Pas de modification de `map_runtime/lib`.
- Pas de modification de `map_runtime/test`.
- Pas de modification `map_core`, `map_editor`, `map_gameplay`, `map_battle`, `examples` ou `assets`.
- Pas de modification Selbrume.
- Pas de pixel diff complexe.
- Pas de golden CI bloquant.
- Pas d’auto-update de baseline.
- Pas de commit.

## 24. git diff --stat
```text
 packages/map_runtime/tool/shadow/README.md         |  96 +++-
 .../tool/shadow/selbrume_shadow_capture_test.dart  | 495 ++++++++++++++++++++-
 2 files changed, 561 insertions(+), 30 deletions(-)
```

## 25. git diff --name-status
```text
M	packages/map_runtime/tool/shadow/README.md
M	packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
```

## 26. git diff --check
```text
(no output)
```

## 27. git status final
```text
 M packages/map_runtime/tool/shadow/README.md
 M packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
?? reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json
?? reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png
?? reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png
?? reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png
?? reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png
?? reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png
?? reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png
?? reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png
?? reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png
?? reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png
?? reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png
?? reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png
?? reports/shadows/screenshots/shadow67_contact_ledge_10_kiosque_l_gumes.png
?? reports/shadows/screenshots/shadow67_contact_ledge_1_selbrum_maison_3.png
?? reports/shadows/screenshots/shadow67_contact_ledge_2_selbrum_maison_4.png
?? reports/shadows/screenshots/shadow67_contact_ledge_3_selbrum_maison_1.png
?? reports/shadows/screenshots/shadow67_contact_ledge_4_selbrume_centre_pok_mon.png
?? reports/shadows/screenshots/shadow67_contact_ledge_5_selbrum_maison_7.png
?? reports/shadows/screenshots/shadow67_contact_ledge_6_le_puits.png
?? reports/shadows/screenshots/shadow67_contact_ledge_7_selbrum_maison_4.png
?? reports/shadows/screenshots/shadow67_contact_ledge_8_selbrum_maison_2.png
?? reports/shadows/screenshots/shadow67_contact_ledge_9_selbrum_maison_8.png
?? reports/shadows/screenshots/shadow67_selbrume_overview.png
?? reports/shadows/shadow_lot_67_baseline_compare.json
?? reports/shadows/shadow_lot_67_baseline_compare.tsv
?? reports/shadows/shadow_lot_67_capture_index.tsv
?? reports/shadows/shadow_lot_67_capture_manifest.json
?? reports/shadows/shadow_lot_67_selbrume_shadow_golden_baseline_implementation.md
```

## 28. Risques / réserves
- La comparaison V0 ne détecte pas automatiquement la qualité visuelle; elle signale seulement les hashes différents.
- Les PNG restent dépendants du moteur de rendu Flutter local, même si les dimensions et counts sont verrouillés.
- Les chemins baseline contiennent le chemin absolu projet/Selbrume pour traçabilité locale.
- Le mode baseline n’est pas branché à la CI et doit rester manuel tant que la stratégie pixel diff n’est pas validée.

## 29. Auto-critique
Le lot est volontairement prudent: la protection structurelle est solide, mais le jugement pixel reste humain en V0. J’ai ajouté une preuve explicite que le hash diff est informatif et non bloquant pour éviter que le harness devienne un golden fragile par accident.

## 30. Regard critique sur le prompt
Le prompt était précis et utile: il séparait bien baseline informative et invariants bloquants. La seule tension vient du volume de preuves demandé: inclure les contenus complets des artefacts texte rend le rapport long, mais c’est cohérent avec une baseline visuelle versionnée.

## 31. Prochain lot recommandé
Shadow-68 — Selbrume Shadow Baseline Review Workflow / Optional Pixel Diff Design V0. Objectif: concevoir une comparaison pixel avec seuil, sans l’activer en CI, et définir quand un changement visuel doit mettre à jour la baseline.

## 32. Code complet — packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
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
const _defaultRepoRoot = '/Users/karim/Project/pokemonProject';
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
    for (final row
        in shadowRows.where((row) => row.geometryType == 'contactLedge')) {
      final cropLeft =
          (row.instructionLeft - 260).clamp(0, worldWidth - _contactCropWidth);
      final cropTop =
          (row.instructionTop - 430).clamp(0, worldHeight - _contactCropHeight);
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

    final overviewArtifact = _CurrentImageArtifact(
      kind: 'overview',
      rank: null,
      elementId: null,
      path: overviewPath,
      sha256: await _sha256ForFile(overviewPath),
      fileSizeBytes: await File(overviewPath).length(),
      width: (worldWidth * _overviewScale).round(),
      height: (worldHeight * _overviewScale).round(),
    );
    final currentArtifacts = <_CurrentImageArtifact>[
      overviewArtifact,
      for (final capture in captures)
        _CurrentImageArtifact(
          kind: 'contactLedge',
          rank: capture.row.rank,
          elementId: capture.row.elementId,
          path: capture.screenshotPath,
          sha256: capture.sha256,
          fileSizeBytes: capture.fileSizeBytes,
          width: capture.cropWidth,
          height: capture.cropHeight,
        ),
    ];
    final baselineComparison = config.compareBaseline
        ? await _compareAgainstBaseline(
            config: config,
            currentArtifacts: currentArtifacts,
            counts: counts,
          )
        : null;
    final indexPath =
        p.join(config.artifactDir, '${config.artifactStem}_capture_index.tsv');
    final manifestPath = p.join(
      config.artifactDir,
      '${config.artifactStem}_capture_manifest.json',
    );
    await File(indexPath).writeAsString(_captureIndexTsv(captures));
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'lot': config.lotLabel,
        'projectPath': config.projectPath,
        'mapId': _mapId,
        'prefix': config.prefix,
        'outputDir': config.outputDir,
        'overview': overviewArtifact.toJson(),
        'indexTsv': indexPath,
        'counts': counts.toJson(),
        if (baselineComparison != null)
          'baselineComparison': baselineComparison.summaryJson(),
        'captures': [
          for (final capture in captures) capture.toJson(),
        ],
      }),
    );

    final summary = {
      'projectPath': config.projectPath,
      'outputDir': config.outputDir,
      'prefix': config.prefix,
      'overview': overviewArtifact.toJson(),
      'indexTsv': indexPath,
      'manifest': manifestPath,
      'counts': counts.toJson(),
      if (baselineComparison != null)
        'baselineComparison': baselineComparison.summaryJson(),
    };
    debugPrint(const JsonEncoder.withIndent('  ').convert(summary));

    expect(counts.staticInstructions, 10);
    expect(counts.contactLedge, 10);
    expect(counts.genericProjection, 0);
    expect(captures, hasLength(10));
    expect(currentArtifacts, hasLength(11));
    expect(File(overviewPath).existsSync(), isTrue);
    expect(File(indexPath).existsSync(), isTrue);
    expect(File(manifestPath).existsSync(), isTrue);
    if (config.compareBaseline) {
      expect(File(config.compareOutputJson).existsSync(), isTrue);
      expect(File(config.compareOutputTsv).existsSync(), isTrue);
      expect(baselineComparison?.hasBlockingFailure, isFalse);
    }
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
  final image =
      await recorder.endRecording().toImage(outputWidth, outputHeight);
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

Future<_BaselineComparisonResult> _compareAgainstBaseline({
  required _HarnessConfig config,
  required List<_CurrentImageArtifact> currentArtifacts,
  required _RuntimeCounts counts,
}) async {
  final baselineDir = config.baselineDir;
  if (baselineDir == null) {
    throw StateError(
      'SHADOW_BASELINE_DIR is required when SHADOW_COMPARE_BASELINE=true',
    );
  }
  final manifestFile = File(p.join(baselineDir, 'baseline_manifest.json'));
  if (!manifestFile.existsSync()) {
    throw StateError('Baseline manifest is missing: ${manifestFile.path}');
  }

  final manifest =
      jsonDecode(await manifestFile.readAsString()) as Map<String, Object?>;
  final expectedCounts = manifest['counts'] as Map<String, Object?>;
  final baselineCaptures =
      (manifest['captures'] as List<Object?>).cast<Map<String, Object?>>();
  final expected = manifest['expected'] as Map<String, Object?>?;
  final expectedElementIds =
      (expected?['contactElementIds'] as List<Object?>?)?.cast<String>();
  final currentElementIds = [
    for (final artifact in currentArtifacts)
      if (artifact.kind == 'contactLedge') artifact.elementId,
  ];

  final structureFailures = <String>[];
  void expectStructure(bool condition, String message) {
    if (!condition) {
      structureFailures.add(message);
    }
  }

  expectStructure(
      counts.staticInstructions == expectedCounts['staticInstructions'],
      'staticInstructions mismatch');
  expectStructure(counts.contactLedge == expectedCounts['contactLedge'],
      'contactLedge mismatch');
  expectStructure(
      counts.genericProjection == expectedCounts['genericProjection'],
      'genericProjection mismatch');
  expectStructure(currentArtifacts.length == expectedCounts['captures'],
      'capture count mismatch');
  if (expectedElementIds != null) {
    expectStructure(
      _listEquals(currentElementIds, expectedElementIds),
      'contact element ids mismatch',
    );
  }

  final currentByKey = {
    for (final artifact in currentArtifacts) artifact.key: artifact,
  };
  final rows = <_BaselineComparisonRow>[];
  if (structureFailures.isNotEmpty) {
    rows.add(
      _BaselineComparisonRow.structureFailure(
        structureFailures.join('; '),
      ),
    );
  }

  for (final baseline in baselineCaptures) {
    final kind = baseline['kind'] as String;
    final rank = baseline['rank'] as int?;
    final elementId = baseline['elementId'] as String?;
    final baselinePath = _resolveRepoPath(baseline['baselinePath'] as String);
    final current = currentByKey[_artifactKey(kind, rank)];
    final baselineFile = File(baselinePath);
    final baselineExists = baselineFile.existsSync();
    final currentExists = current != null && File(current.path).existsSync();
    final baselineWidth = baseline['width'] as int;
    final baselineHeight = baseline['height'] as int;
    final currentWidth = current?.width;
    final currentHeight = current?.height;
    final baselineSha256 = baseline['sha256'] as String;
    final baselineFileSizeBytes = baseline['fileSizeBytes'] as int;

    var status = 'match';
    if (!baselineExists) {
      status = 'missing-baseline-fail';
    } else if (!currentExists) {
      status = 'missing-current-fail';
    } else if (baselineWidth != currentWidth ||
        baselineHeight != currentHeight) {
      status = 'dimension-mismatch-fail';
    } else if (baselineSha256 != current.sha256) {
      status = 'pixel-diff-informative';
    }

    rows.add(
      _BaselineComparisonRow(
        rank: rank,
        kind: kind,
        elementId: elementId,
        baselinePath: baselinePath,
        currentPath: current?.path,
        baselineSha256: baselineSha256,
        currentSha256: current?.sha256,
        exactHashMatch: baselineSha256 == current?.sha256,
        baselineFileSizeBytes: baselineFileSizeBytes,
        currentFileSizeBytes: current?.fileSizeBytes,
        baselineWidth: baselineWidth,
        baselineHeight: baselineHeight,
        currentWidth: currentWidth,
        currentHeight: currentHeight,
        status: status,
      ),
    );
  }

  final result = _BaselineComparisonResult(
    baselineId: manifest['baselineId'] as String? ?? 'unknown',
    baselineDir: baselineDir,
    counts: counts,
    rows: rows,
  );
  await Directory(p.dirname(config.compareOutputJson)).create(recursive: true);
  await Directory(p.dirname(config.compareOutputTsv)).create(recursive: true);
  await File(config.compareOutputJson).writeAsString(
    const JsonEncoder.withIndent('  ').convert(result.toJson()),
  );
  await File(config.compareOutputTsv).writeAsString(result.toTsv());
  debugPrint(
    'baseline comparison wrote ${config.compareOutputJson} and '
    '${config.compareOutputTsv}',
  );
  if (result.hasBlockingFailure) {
    throw StateError('Blocking baseline comparison failure');
  }
  return result;
}

String _artifactKey(String kind, int? rank) => '$kind:${rank ?? 0}';

bool _listEquals(List<Object?> left, List<Object?> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i += 1) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

String _resolveRepoPath(String value) {
  if (p.isAbsolute(value)) {
    return value;
  }
  return p.normalize(p.join(_defaultRepoRoot, value));
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
    required this.artifactStem,
    required this.lotLabel,
    required this.compareBaseline,
    required this.baselineDir,
    required this.compareOutputJson,
    required this.compareOutputTsv,
  });

  factory _HarnessConfig.fromEnvironment() {
    final projectPath =
        Platform.environment['SELBRUME_PROJECT_PATH'] ?? _defaultProjectPath;
    final outputDir = Directory(
      Platform.environment['SHADOW_SCREENSHOT_OUTPUT_DIR'] ?? _defaultOutputDir,
    ).absolute.path;
    final prefix = _safeFilePart(
        Platform.environment['SHADOW_SCREENSHOT_PREFIX'] ?? _defaultPrefix);
    final artifactDir = p.basename(outputDir) == 'screenshots'
        ? Directory(outputDir).parent.path
        : outputDir;
    final artifactStem = _artifactStemForPrefix(prefix);
    final lotLabel = _lotLabelForArtifactStem(artifactStem);
    final compareBaseline = _envFlag('SHADOW_COMPARE_BASELINE');
    final baselineDirValue = Platform.environment['SHADOW_BASELINE_DIR'];
    final baselineDir = baselineDirValue == null || baselineDirValue.isEmpty
        ? null
        : _resolveRepoPath(baselineDirValue);
    final compareOutputJson = _resolveRepoPath(
      Platform.environment['SHADOW_BASELINE_COMPARE_OUTPUT_JSON'] ??
          p.join(artifactDir, '${artifactStem}_baseline_compare.json'),
    );
    final compareOutputTsv = _resolveRepoPath(
      Platform.environment['SHADOW_BASELINE_COMPARE_OUTPUT_TSV'] ??
          p.join(artifactDir, '${artifactStem}_baseline_compare.tsv'),
    );
    return _HarnessConfig(
      projectPath: projectPath,
      outputDir: outputDir,
      prefix: prefix,
      artifactDir: artifactDir,
      artifactStem: artifactStem,
      lotLabel: lotLabel,
      compareBaseline: compareBaseline,
      baselineDir: baselineDir,
      compareOutputJson: compareOutputJson,
      compareOutputTsv: compareOutputTsv,
    );
  }

  final String projectPath;
  final String outputDir;
  final String prefix;
  final String artifactDir;
  final String artifactStem;
  final String lotLabel;
  final bool compareBaseline;
  final String? baselineDir;
  final String compareOutputJson;
  final String compareOutputTsv;
}

String _artifactStemForPrefix(String prefix) {
  final match = RegExp(r'^shadow(\d+)$').firstMatch(prefix);
  if (match != null) {
    return 'shadow_lot_${match.group(1)}';
  }
  return prefix;
}

String _lotLabelForArtifactStem(String artifactStem) {
  final match = RegExp(r'^shadow_lot_(\d+)$').firstMatch(artifactStem);
  if (match != null) {
    return 'Shadow-${match.group(1)}';
  }
  return artifactStem;
}

bool _envFlag(String name) {
  final value = Platform.environment[name]?.toLowerCase();
  return value == '1' || value == 'true' || value == 'yes';
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

final class _CurrentImageArtifact {
  const _CurrentImageArtifact({
    required this.kind,
    required this.rank,
    required this.elementId,
    required this.path,
    required this.sha256,
    required this.fileSizeBytes,
    required this.width,
    required this.height,
  });

  final String kind;
  final int? rank;
  final String? elementId;
  final String path;
  final String sha256;
  final int fileSizeBytes;
  final int width;
  final int height;

  String get key => _artifactKey(kind, rank);

  Map<String, Object?> toJson() {
    return {
      'kind': kind,
      'rank': rank,
      'elementId': elementId,
      'path': path,
      'sha256': sha256,
      'fileSizeBytes': fileSizeBytes,
      'width': width,
      'height': height,
    };
  }
}

final class _BaselineComparisonRow {
  const _BaselineComparisonRow({
    required this.rank,
    required this.kind,
    required this.elementId,
    required this.baselinePath,
    required this.currentPath,
    required this.baselineSha256,
    required this.currentSha256,
    required this.exactHashMatch,
    required this.baselineFileSizeBytes,
    required this.currentFileSizeBytes,
    required this.baselineWidth,
    required this.baselineHeight,
    required this.currentWidth,
    required this.currentHeight,
    required this.status,
  });

  factory _BaselineComparisonRow.structureFailure(String message) {
    return _BaselineComparisonRow(
      rank: null,
      kind: 'structure',
      elementId: null,
      baselinePath: null,
      currentPath: null,
      baselineSha256: null,
      currentSha256: null,
      exactHashMatch: false,
      baselineFileSizeBytes: null,
      currentFileSizeBytes: null,
      baselineWidth: null,
      baselineHeight: null,
      currentWidth: null,
      currentHeight: null,
      status: 'structure-fail:$message',
    );
  }

  final int? rank;
  final String kind;
  final String? elementId;
  final String? baselinePath;
  final String? currentPath;
  final String? baselineSha256;
  final String? currentSha256;
  final bool exactHashMatch;
  final int? baselineFileSizeBytes;
  final int? currentFileSizeBytes;
  final int? baselineWidth;
  final int? baselineHeight;
  final int? currentWidth;
  final int? currentHeight;
  final String status;

  bool get isBlockingFailure =>
      status.endsWith('-fail') || status.startsWith('structure-fail');

  Map<String, Object?> toJson() {
    return {
      'rank': rank,
      'kind': kind,
      'elementId': elementId,
      'baselinePath': baselinePath,
      'currentPath': currentPath,
      'baselineSha256': baselineSha256,
      'currentSha256': currentSha256,
      'exactHashMatch': exactHashMatch,
      'baselineFileSizeBytes': baselineFileSizeBytes,
      'currentFileSizeBytes': currentFileSizeBytes,
      'baselineWidth': baselineWidth,
      'baselineHeight': baselineHeight,
      'currentWidth': currentWidth,
      'currentHeight': currentHeight,
      'status': status,
    };
  }

  String toTsvLine() {
    return [
      rank ?? '',
      kind,
      elementId ?? '',
      baselinePath ?? '',
      currentPath ?? '',
      baselineSha256 ?? '',
      currentSha256 ?? '',
      exactHashMatch,
      baselineFileSizeBytes ?? '',
      currentFileSizeBytes ?? '',
      baselineWidth ?? '',
      baselineHeight ?? '',
      currentWidth ?? '',
      currentHeight ?? '',
      status,
    ].map((value) => '$value').join('\t');
  }
}

final class _BaselineComparisonResult {
  const _BaselineComparisonResult({
    required this.baselineId,
    required this.baselineDir,
    required this.counts,
    required this.rows,
  });

  final String baselineId;
  final String baselineDir;
  final _RuntimeCounts counts;
  final List<_BaselineComparisonRow> rows;

  bool get hasBlockingFailure => rows.any((row) => row.isBlockingFailure);

  int get exactMatches => rows.where((row) => row.status == 'match').length;

  int get informativeDiffs =>
      rows.where((row) => row.status == 'pixel-diff-informative').length;

  int get blockingFailures => rows.where((row) => row.isBlockingFailure).length;

  Map<String, Object?> summaryJson() {
    return {
      'baselineId': baselineId,
      'baselineDir': baselineDir,
      'mode': 'informative-hash-v0',
      'total': rows.length,
      'exactMatches': exactMatches,
      'informativeDiffs': informativeDiffs,
      'blockingFailures': blockingFailures,
      'hasBlockingFailure': hasBlockingFailure,
    };
  }

  Map<String, Object?> toJson() {
    return {
      ...summaryJson(),
      'counts': counts.toJson(),
      'rows': [
        for (final row in rows) row.toJson(),
      ],
    };
  }

  String toTsv() {
    const headers = [
      'rank',
      'kind',
      'elementId',
      'baselinePath',
      'currentPath',
      'baselineSha256',
      'currentSha256',
      'exactHashMatch',
      'baselineFileSizeBytes',
      'currentFileSizeBytes',
      'baselineWidth',
      'baselineHeight',
      'currentWidth',
      'currentHeight',
      'status',
    ];
    return '${[
      headers.join('\t'),
      for (final row in rows) row.toTsvLine(),
    ].join('\n')}\n';
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

## 33. Code complet — packages/map_runtime/tool/shadow/README.md
```markdown
# Selbrume Shadow Screenshot Harness

This directory contains manual visual-gate tools for PokeMap shadow work.

The harness is intentionally outside `test/` so it does not run in normal
package test suites or CI by accident. It is a reproducible screenshot capture
tool, not a golden comparison test.

## Run capture only

From the `map_runtime` package:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow67 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

## Run capture + baseline comparison

Shadow baseline comparison is optional and manually invoked. In V0 it is
informative for image hashes: structural invariants can fail the test, but
pixel/hash differences are reported without failing.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow67 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
SHADOW_COMPARE_BASELINE=true \
SHADOW_BASELINE_DIR=/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1 \
SHADOW_BASELINE_COMPARE_OUTPUT_JSON=/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_baseline_compare.json \
SHADOW_BASELINE_COMPARE_OUTPUT_TSV=/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_baseline_compare.tsv \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

## Environment

The harness supports these environment variables:

```text
SELBRUME_PROJECT_PATH
SHADOW_SCREENSHOT_OUTPUT_DIR
SHADOW_SCREENSHOT_PREFIX
SHADOW_COMPARE_BASELINE
SHADOW_BASELINE_DIR
SHADOW_BASELINE_COMPARE_OUTPUT_JSON
SHADOW_BASELINE_COMPARE_OUTPUT_TSV
```

Defaults:

```text
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots
SHADOW_SCREENSHOT_PREFIX=shadow65
SHADOW_COMPARE_BASELINE=false
```

## Outputs

With a `shadow67` prefix, the harness writes:

```text
reports/shadows/screenshots/shadow67_selbrume_overview.png
reports/shadows/screenshots/shadow67_contact_ledge_1_<elementId>.png
...
reports/shadows/screenshots/shadow67_contact_ledge_10_<elementId>.png
reports/shadows/shadow_lot_67_capture_index.tsv
reports/shadows/shadow_lot_67_capture_manifest.json
```

The TSV records capture coordinates, element ids, runtime instruction geometry,
family/profile metadata, opacity, and screenshot paths. The manifest records
the run configuration, counts, screenshot paths, file sizes, and SHA-256 hashes.

When `SHADOW_COMPARE_BASELINE=true`, the harness also writes:

```text
reports/shadows/shadow_lot_67_baseline_compare.json
reports/shadows/shadow_lot_67_baseline_compare.tsv
```

The baseline V1 lives under:

```text
reports/shadows/baselines/selbrume_shadow_v1/
```

## Baseline comparison V0

Blocking invariants:

```text
staticInstructions = 10
contactLedge = 10
genericProjection = 0
capture count = 11
baseline manifest exists
baseline/current screenshots exist
all expected contact element ids are present
baseline/current dimensions match
```

Informative only:

```text
SHA-256 mismatch
file size mismatch
pixel content changes
```

Statuses in the comparison TSV/JSON:

```text
match
pixel-diff-informative
dimension-mismatch-fail
missing-baseline-fail
missing-current-fail
structure-fail
```

V0 deliberately does not implement automatic baseline updates. To update a
baseline, regenerate current screenshots, review them visually, then copy them
over the baseline in an explicit follow-up lot with a report explaining why the
visual change is intended.

## Limits

This V0 harness captures the current runtime output and asserts the expected
Selbrume shadow inventory:

```text
staticInstructions = 10
contactLedge = 10
genericProjection = 0
```

It does not compare pixels against a golden baseline, and it should not block
normal test suites. Baseline comparison is manually invoked and remains
non-blocking for pixel/hash differences until a stricter visual regression gate
is explicitly designed and approved.

```
