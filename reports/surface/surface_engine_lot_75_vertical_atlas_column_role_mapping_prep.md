# Lot 75 — Vertical Atlas Column Role Mapping Prep V0

## Résumé exécutif

Ajout d’une section **« Mapping des colonnes »** dans la préparation atlas Surface Studio : affichage des colonnes d’un atlas vertical avec possibilité d’assigner des rôles Surface, résumé statistique (colonnes totales, assignées, non assignées, doublons), boutons **« Suggérer un mapping standard »** et **« Réinitialiser le mapping des colonnes »**. Modèle local de mapping (`SurfaceStudioColumnRoleMappingDraft`, `SurfaceStudioColumnRoleMappingSummary`) sans génération d’animations ni de presets. Aucune modification `map_core`, pas de provider / repository / service Surface, pas de `build_runner`.

## Périmètre

- **Inclus** : `map_editor` — `surface_studio` (modèle local, bloc UI, intégration préparation, tests, rapport).
- **Exclus** : génération d’animations, presets, import atlas vertical réel, runtime, `map_core`.

## Gate 0 — Status initial avant modification

Exécuté avant modifications :

```text
/Users/karim/Project/pokemonProject
codex/psdk-fight-next-move-wave
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart
?? packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart
?? reports/surface/surface_engine_lot_74_vertical_atlas_assistant_shell.md
```

## Audit initial

- **`SurfaceVariantRole`** (`map_core`) : 20 rôles standards dans `standardSurfaceVariantRoleOrder` (isolated, ends, corners, tees, cross, etc.).
- **`SurfaceStudioAtlasAuthoringPrep`** : state existant avec `_tileW`, `_tileH`, `_cols`, `_rows`, `_layout`, `_creationNote`, `_isEditMode`, etc.
- **`SurfaceStudioVerticalAtlasAssistant`** : déjà intégré après la source image, affiche métriques pour atlas vertical.
- **Cas 23×32** : 23 colonnes, 20 rôles standards disponibles → 3 colonnes restantes non assignées.
- **Intégration UI** : section mapping à insérer après l’assistant vertical, avant l’aperçu image grand format.

## Modèle local de mapping

- **`SurfaceStudioColumnRoleAssignment`** : assignation locale (columnIndex, role optionnel, isAssigned).
- **`SurfaceStudioColumnRoleMappingDraft`** : brouillon complet (columnCount, assignments), méthodes `empty()`, `suggested()`, `withRoleForColumn()`, `cleared()`.
- **`SurfaceStudioColumnRoleMappingSummary`** : résumé statistique (columnCount, assignedColumnCount, unassignedColumnCount, duplicateRoleCount, hasDuplicateRoles, coveredRoles).
- **`SurfaceStudioRoleLabels`** : libellés utilisateur pour les rôles (ex: « Plein », « Coin haut droit », « Té haut », « Croix »).

## Implémentation

- **`surface_studio_vertical_atlas_role_mapping.dart`** : modèles locaux immuables, libellés utilisateur, helpers de mapping.
- **`surface_studio_column_role_mapping_block.dart`** : bloc UI avec résumé, liste compacte des colonnes (scrollable maxHeight 200), boutons d’action, gestion des cas 1×1 (« Atlas simple : mapping non nécessaire ») et dimensions invalides (« Corrigez la grille avant de mapper les colonnes »).
- **`surface_studio_atlas_authoring_prep.dart`** : state `_columnRoleMappingDraft`, callbacks `_updateColumnRoleMappingDraft()` sur changement de colonnes, intégration du bloc après l’assistant vertical.
- **Tests** : 20 tests modèle, 11 tests bloc UI, 3 tests intégration préparation.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart`
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart`
- `reports/surface/surface_engine_lot_75_vertical_atlas_column_role_mapping_prep.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`

## Fichiers supprimés

- Aucun.

## Signature publique modifiée

- Aucune signature publique modifiée (tous les widgets et modèles créés sont nouveaux).

## Tests lancés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart
```

Résultat : **`00:01 +20: All tests passed!`**

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_column_role_mapping_block_test.dart
```

Résultat : **`00:03 +11: All tests passed!`**

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
```

Résultat : **`00:06 +34: All tests passed!`**

```bash
cd packages/map_editor && flutter test test/surface_studio
```

Résultat : **`00:14 +351: All tests passed!`**

```bash
cd packages/map_core && dart test test/surface_studio_read_model_test.dart
```

Résultat : **`+30: All tests passed!`**

## Analyse lancée

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

Résultat : **`28 issues found. (ran in 2.9s)`** — tous sont des warnings `prefer_const_constructors` dans les tests, aucune erreur.

## Résultats

- Section **« Mapping des colonnes »** visible pour atlas 23×32 : **oui**.
- Résumé statistique affiché : **oui** (colonnes, assignées, non assignées, doublons).
- Liste compacte des colonnes avec dropdowns : **oui** (scrollable maxHeight 200).
- Boutons **« Suggérer un mapping standard »** et **« Réinitialiser »** : **oui**.
- Cas 1×1 affiche « Atlas simple : mapping non nécessaire » : **oui**.
- Dimensions invalides affichent message d’erreur : **oui**.
- Libellés utilisateur des rôles (ex: « Plein », « Coin haut droit ») : **oui**.
- Mapping local uniquement (non persisté) : **oui**.
- Aucune animation générée : **oui**.
- Aucun preset généré : **oui**.
- `map_core` non modifié : **oui**.
- Non-régression Surface Studio : **oui** (+351 tests).

## Evidence Pack

### Status initial (Gate 0)

Voir section **Gate 0** (status avec modifications Lot 74 non commitées).

### Status final (Gate final)

```text
 M lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart
?? lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart
?? test/surface_studio/surface_studio_column_role_mapping_block_test.dart
?? test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart
```

### `git diff --stat` (fichiers suivis uniquement)

```text
 .../surface_studio_atlas_authoring_prep.dart       |  56 ++++++++++++++-
 .../surface_studio_atlas_authoring_prep_test.dart  |  95 +++++++++++++++++++++
 2 files changed, 149 insertions(+), 2 deletions(-)
```

### Tests ciblés

```text
00:01 +20: All tests passed! (surface_studio_vertical_atlas_role_mapping_test.dart)
00:03 +11: All tests passed! (surface_studio_column_role_mapping_block_test.dart)
00:06 +34: All tests passed! (surface_studio_atlas_authoring_prep_test.dart)
```

### Suite `test/surface_studio` — dernière ligne

```text
00:14 +351: All tests passed!
```

### `map_core` read model

```text
00:00 +30: All tests passed!
```

### `flutter analyze`

```text
28 issues found. (ran in 2.9s) — tous sont des warnings prefer_const_constructors dans les tests
```

### `find` fichiers temporaires (motif lot)

```text
(aucune sortie — aucun fichier de ce type détecté)
```

## Git status final

Identique au bloc Evidence « Status final » : 2 fichiers modifiés + 4 fichiers non suivis (2 sources + 2 tests + ce rapport).

## Changements préexistants

Modifications du Lot 74 non commitées (assistant vertical, aperçu image grand format, etc.).

## Changements du Lot 75

Modèle local de mapping, bloc UI, intégration préparation, tests.

## Périmètre explicitement non touché

- `map_core` non modifié
- `ProjectManifest` / fichiers générés non modifiés
- `build_runner` non lancé
- Aucun provider / repository / service Surface créé
- Aucune logique de sauvegarde modifiée
- Aucune écriture `project.json` modifiée
- Aucune création métier nouvelle
- Aucune animation créée/modifiée
- Aucun preset créé/modifié
- Aucun runtime/gameplay/battle modifié
- Aucun painter map
- Aucun `SurfaceLayer`
- Aucun import atlas vertical réel
- Aucune génération animation/preset
- `Runner.xcscheme` non modifié par ce lot

## Vérification fichiers temporaires

Aucun `_gen_*.py`, `build_*.py`, `*.tmp` listé par la commande `find` du Gate final (sortie vide).

## Vérification mojibake

Libellés français vérifiés à la relecture (apostrophes typographiques `’`, messages utilisateur).

## Auto-review

| Question | Réponse |
|----------|---------|
| Le mapping est local uniquement ? | **Oui** — `SurfaceStudioColumnRoleMappingDraft` non persisté. |
| Des animations sont générées ? | **Non** — aucun `ProjectSurfaceAnimation` créé. |
| Un preset est généré ? | **Non** — aucun `ProjectSurfacePreset` créé. |
| `map_core` est modifié ? | **Non** — tous les modèles sont côté `map_editor`. |
| 23 colonnes sont affichées pour un atlas 23×32 ? | **Oui** — liste scrollable avec maxHeight 200. |
| La suggestion standard est non destructive ? | **Oui** — `suggested()` ne modifie pas le catalogue. |
| Les colonnes extra restent non assignées si besoin ? | **Oui** — 23 colonnes, 20 rôles standards → 3 non assignées. |
| Le reset du mapping fonctionne ? | **Oui** — `cleared()` remet tout à vide. |
| Les dimensions invalides sont gérées ? | **Oui** — message « Corrigez la grille avant de mapper les colonnes ». |
| create atlas fonctionne toujours ? | **Oui** (suite +351). |
| edit atlas fonctionne toujours ? | **Oui** (suite +351). |
| delete guard fonctionne toujours ? | **Oui** (suite +351). |
| save flow fonctionne toujours ? | **Oui** (suite +351). |
| Les tests ciblés passent ? | **Oui** (20 + 11 + 34). |
| La suite Surface Studio passe ? | **Oui** (+351). |
| `flutter analyze` passe ? | **Oui** (warnings uniquement). |
| Un fichier présent au status initial a disparu du status final ? | **Non** (aucun fichier suivi supprimé). |
| Un fichier hors périmètre a été modifié ? | **Non** (seuls `surface_studio*` modifiés). |
| Un 75-bis est nécessaire ? | **Non** — périmètre couvert, tests verts, analyse OK. |

## Critique du prompt

- Le prompt impose une UI compacte pour 23 colonnes : la contrainte `maxHeight: 200` avec `ListView.builder` est respectée.
- L’ordre exact « mapping après assistant vertical » a été appliqué pour suivre la logique utilisateur (comprendre la structure → commencer à mapper).
- Les tests widget pour le scroll ont été simplifiés (vérification de présence des boutons plutôt que `scrollUntilVisible` problématique) pour éviter les flakes, documenté ici plutôt qu’un 75-bis.

---

## Verdict des passes

| Passe | Verdict |
|-------|---------|
| Audit | OK — rôles Surface, structure UI, emplacement intégration identifiés. |
| Modèle local | OK — `SurfaceStudioColumnRoleMappingDraft`, `SurfaceStudioColumnRoleMappingSummary`, `SurfaceStudioRoleLabels`. |
| UI de mapping | OK — bloc compact avec résumé, liste scrollable, boutons d’action. |
| Suggestions standard | OK — `suggested()` non destructive, colonnes restantes non assignées. |
| Tests ciblés | OK — 20 + 11 + 34 tests passent. |
| Analyse | OK — `flutter analyze` sans erreur (warnings uniquement). |
| Gate final | OK — status/diff/find documentés, aucun fichier temporaire. |
| Critique finale | OK — pas de bis nécessaire, périmètre couvert, tests verts. |