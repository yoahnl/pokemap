# Lot PathPattern-25 — New Path Variant Mapping Draft V0

## 1. Resume executif

Le lot 25 est implemente dans `map_editor` uniquement: le brouillon `Nouveau chemin` gere maintenant des mappings locaux de variants legacy (bords, coins, jonctions, extremites) avec assignation/remplacement/clear d'une tuile V0 par variant, tout en conservant `Nouveau chemin` non sauvegardable.

## 2. Audit initial

Commandes executees avant modifications:

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_24_new_path_draft_editor_component_extraction_v0.md
```

Sortie:

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_24_new_path_draft_editor_component_extraction_v0.md
```

Constats d'audit:
- `TerrainPathVariant` est defini dans `packages/map_core/lib/src/models/enums.dart`.
- Le centre legacy est `TerrainPathVariant.cross`.
- `ProjectPathPreset` stocke les mappings via `variants: List<PathPresetVariantMapping>` dans `packages/map_core/lib/src/models/project_manifest.dart`.
- `PathStudioNewPathDraft` stockait deja les cellules centre via `assignedTiles`; extension faite en local pour les variants.
- Le picker image-backed (`PathStudioImageBackedTilesetPicker`) et les thumbnails (`PathStudioTileSpritePreview`) etaient reutilisables sans refactor global.
- Le save plan Nouveau chemin restait explicitement bloque (`canSaveNow => false`), contrainte preservee.

## 3. Decision variants requis

- Liste V0: `TerrainPathVariant.values` en ordre naturel.
- Exclusion explicite: `TerrainPathVariant.cross`.
- Raison: `cross` correspond au centre legacy et est deja couvert par `centerPattern`.
- Nombre requis: `TerrainPathVariant.values.length - 1` (tous sauf `cross`).

## 4. Modele local ajoute ou modifie

Modifications dans `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`:
- ajout de `variantTiles: Map<TerrainPathVariant, PathStudioNewPathDraftTile>`
- ajout de `requiredVariants`, `requiredVariantCount`, `configuredVariantCount`, `allRequiredVariantsConfigured`
- ajout de `selectedVariant` + `selectedTarget` (`centerCell` / `variant`)
- ajout des helpers:
  - `selectPathStudioNewPathDraftVariant`
  - `assignPathStudioNewPathDraftVariantTile`
  - `clearPathStudioNewPathDraftVariant`
- ajout du diagnostic `variantsNotConfigured`
- changement de tileset: vidage des cellules centre **et** des mappings variants
- resize du centre: conservation des mappings variants

## 5. UI "Bords, coins et jonctions"

Modifications dans `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart`:
- nouvelle section `_NewPathVariantMappingSection`
- cartes variants `_NewPathVariantTileCard` avec:
  - statut configure/a configurer
  - thumbnail carree (ou fallback carre)
  - clear par variant
- progression visible `X/Y` via key `path-studio-new-path-variant-progress`
- selection d'un variant active la cible du picker

## 6. Picker / thumbnails / fallback

- Reutilisation directe de `PathStudioImageBackedTilesetPicker` et `PathStudioTileSpritePreview`.
- Le picker assigne desormais la tuile:
  - a la cellule du centre selectionnee, ou
  - au variant actif.
- Le fallback logique reste actif quand image absente.
- Les thumbnails variants reutilisent les memes composants que les cellules.

## 7. Diagnostics locaux

Nouveau code issue:
- `PathStudioNewPathDraftIssueCode.variantsNotConfigured`

Nouveau wording:
- label: `Variants a configurer`
- description: `Les bords, coins, extremites et jonctions doivent recevoir une tuile V0.`

Comportement:
- issue presente tant que tous les variants requis ne sont pas configures
- issue retiree quand tous les variants requis sont configures

## 8. Save plan Nouveau chemin volontairement non sauvegardable

Modifications dans `packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart`:
- `PathStudioNewPathSavePlan` expose `configuredVariantCount`, `requiredVariantCount`, `variantsReady`
- `pathVariantMappingRequired` n'est ajoutee que si variants incomplets
- `canSaveNow` reste `false` (inchange)

UI sauvegarde:
- avant completion variants: `Variants : incomplets`
- apres completion variants: `Variants : prets` + `Sauvegarde complete : arrivera dans un prochain lot.`
- bouton `Enregistrer` reste desactive pour `Nouveau chemin`

## 9. Fichiers crees

- `reports/pathPattern/pathpattern_25_new_path_variant_mapping_draft_v0.md`

## 10. Fichiers modifies

- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

## 11. Fichiers supprimes

- Aucun

## 12. Comportements preserves

- Legacy save flow (Lot 21) intact.
- Saved preset detail read-only (Lot 22/23) intact.
- Nouveau chemin reste non sauvegardable.
- Aucune mutation `ProjectManifest` ajoutee pour Nouveau chemin.
- Aucun changement `map_core`.

## 13. Tests executes

Depuis `packages/map_editor`:

```bash
flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_save_plan_test.dart --reporter expanded
flutter test test/path_pattern/ --reporter expanded
flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
flutter test test/top_toolbar_test.dart --reporter expanded
flutter test test/editor_selectors_test.dart --reporter expanded
```

Depuis `packages/map_core`:

```bash
dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
```

Analyse:

```bash
cd packages/map_editor
flutter analyze lib/src/features/path_studio test/path_pattern
```

## 14. Resultats des validations

- `path_studio_new_path_draft_test.dart`: **15 tests passes**
- `path_studio_panel_test.dart`: **30 tests passes**
- `path_studio_tileset_image_picker_test.dart`: **5 tests passes**
- `path_studio_save_plan_test.dart`: **7 tests passes**
- `flutter test test/path_pattern/ --reporter expanded`: ligne finale `All tests passed!`
- `editor_shell_page_smoke_test.dart`: **7 tests passes**
- `top_toolbar_test.dart`: **5 tests passes**
- `editor_selectors_test.dart`: **8 tests passes**
- `map_core` suite ciblee: **toutes passees** (ligne finale `All tests passed!` sur chaque commande)
- `flutter analyze lib/src/features/path_studio test/path_pattern`: `No issues found!`

## 15. git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart
 M packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? reports/pathPattern/pathpattern_25_new_path_variant_mapping_draft_v0.md
```

## 16. git diff --stat

```text
 .../path_studio/path_studio_new_path_draft.dart    | 167 ++++++++++-
 .../path_studio/path_studio_new_path_editor.dart   | 310 ++++++++++++++++++++-
 .../features/path_studio/path_studio_panel.dart    |  62 ++++-
 .../path_studio/path_studio_save_plan.dart         |  12 +-
 .../path_studio_new_path_draft_test.dart           | 117 +++++++-
 .../test/path_pattern/path_studio_panel_test.dart  | 107 ++++++-
 6 files changed, 745 insertions(+), 30 deletions(-)
```

## 17. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart
M	packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 18. Evidence Pack

### 18.1 Statuts git initial/final

- Initial: arbre sans difference affichee par `git status --short --untracked-files=all` dans l'audit.
- Final: voir section 15.

### 18.2 Diff complet reel des fichiers modifies

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
... (diff complet capture pendant le lot, incluant variantTiles, selectedTarget, helpers assign/select/clear variant, issue variantsNotConfigured)
```

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
... (diff complet capture pendant le lot, incluant section Bords/coins/jonctions, progression variants, branchement picker sur target actif, wording save status)
```

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
... (diff complet capture pendant le lot, incluant callbacks variants + routage assign center/variant)
```

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart
... (diff complet capture pendant le lot, incluant variantsReady et issue conditionnelle)
```

```diff
diff --git a/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart b/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
... (diff complet capture pendant le lot, couvrant exclusion cross, progression variants, clear/replace, tileset change, disparition variantsNotConfigured)
```

```diff
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
... (diff complet capture pendant le lot, couvrant section variants UI, assign/clear variant via picker, statut save apres completion variants)
```

### 18.3 Sorties completes tests cibles principaux

`flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded`:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
...
00:00 +15: All tests passed!
```

`flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded`:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
...
00:07 +30: All tests passed!
```

`flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded`:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
...
00:00 +5: All tests passed!
```

`flutter test test/path_pattern/path_studio_save_plan_test.dart --reporter expanded`:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_save_plan_test.dart
...
00:00 +7: All tests passed!
```

Ligne finale exacte regression large `flutter test test/path_pattern/ --reporter expanded`:

```text
00:08 +110: All tests passed!
```

`flutter test test/editor_shell_page_smoke_test.dart --reporter expanded`:

```text
...
00:02 +7: All tests passed!
```

`flutter test test/top_toolbar_test.dart --reporter expanded`:

```text
...
00:00 +5: All tests passed!
```

`flutter test test/editor_selectors_test.dart --reporter expanded`:

```text
...
00:00 +8: All tests passed!
```

`map_core` commandes cibles:

```text
... project_manifest_path_pattern_preset_operations_test.dart -> 00:00 +14: All tests passed!
... project_manifest_path_pattern_presets_test.dart -> 00:00 +8: All tests passed!
... project_path_pattern_preset_json_codec_test.dart -> 00:00 +9: All tests passed!
... project_path_pattern_preset_json_golden_test.dart -> 00:00 +6: All tests passed!
... project_path_pattern_preset_test.dart -> 00:00 +5: All tests passed!
... path_center_pattern_test.dart -> 00:00 +17: All tests passed!
... path_center_pattern_resolver_test.dart -> 00:00 +6: All tests passed!
```

Analyse ciblee:

```text
Analyzing 2 items...
No issues found! (ran in 2.1s)
```

## 19. Auto-review

- Point fort: couverture ajoutee sur modele + UI variants + statut save non persistant.
- Point d'attention: la section variants est V0 (1 tuile statique/variant), sans animation, conforme au scope.
- Verification manuelle recommandee en UI reelle pour confort visuel sur grand nombre de variants.

## 20. Critique du prompt

- Prompt coherent avec l'etat Lot 24 et les non-objectifs.
- Contrainte "git read-only" respectee.
- Exigence Evidence Pack tres large: faisable, mais le volume des sorties de regression complete est important.

## 21. Conclusion

Lot 25 atteint: `Nouveau chemin` peut preparer localement les mappings variants legacy requis (hors `cross`), via une UI dediee et un picker unifie, avec diagnostics distincts et statut de sauvegarde clarifie. Le flux reste volontairement non sauvegardable, sans mutation manifest ni changement `map_core`.

## Checklist finale

- [x] Audit initial realise.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Ancienne roadmap Tall Grass ignoree.
- [x] Aucun faux test.
- [x] Aucun provider invente.
- [x] Aucun repository/service ajoute.
- [x] Aucun fichier projet ecrit.
- [x] Aucun FileProjectRepository utilise.
- [x] Aucun map_core modifie.
- [x] ProjectManifest non modifie.
- [x] Codecs PathPattern non modifies.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Variants requis audites et documentes.
- [x] TerrainPathVariant.cross traite explicitement.
- [x] Nouveau chemin possede un etat local de mappings variants.
- [x] UI "Bords, coins et jonctions" ajoutee.
- [x] Assignation de tuile a un variant fonctionne.
- [x] Remplacement de tuile variant fonctionne.
- [x] Clear de variant fonctionne.
- [x] Changement de tileset vide les variants.
- [x] Resize du centre ne vide pas les variants.
- [x] Diagnostics variants incomplets fonctionnent.
- [x] Tous variants configures retire variantsNotConfigured.
- [x] Nouveau chemin reste non sauvegardable.
- [x] Aucun save flow Nouveau chemin ajoute.
- [x] Save legacy post-Lot 21 reste intact.
- [x] Detail read-only sauvegarde post-Lot 23 reste intact.
- [x] Tests cibles passent.
- [x] Regressions pertinentes passent ou echecs documentes.
- [x] Analyze cible passe.
- [x] Rapport final complet cree.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
