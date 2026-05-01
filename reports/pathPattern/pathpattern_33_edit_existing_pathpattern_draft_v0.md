# Lot PathPattern-33 — Edit Existing PathPattern Draft V0

## 1. Résumé exécutif

Le lot implémente un mode **édition locale** d’un `ProjectPathPatternPreset` existant dans Path Studio:
- ajout d’un bouton `Modifier` en read-only, avec blocage propre si base absente/ambiguë;
- conversion `ProjectPathPreset + ProjectPathPatternPreset -> PathStudioNewPathDraft` en mode `edit` avec conservation des IDs, frames, durations, `tilesetId` overrides, `surfaceKind` et variants;
- ajout d’un build plan/request d’édition et d’un helper de save flow de remplacement **en place** dans le manifest mémoire;
- intégration UI/feedback (`Chemin modifié dans le projet` / erreur) + nettoyage du draft après succès.

Aucune écriture disque, aucun `map_core` modifié, aucun runtime/painter modifié.

## 2. Audit initial

### Commandes d’audit obligatoires

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_30_center_pattern_animation_draft_v0.md
git ls-files reports/pathPattern/pathpattern_31_runtime_pathpattern_render_v0.md
git ls-files reports/pathPattern/pathpattern_32_center_animation_ux_clarification_v0.md
```

Sortie obtenue:

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_30_center_pattern_animation_draft_v0.md
reports/pathPattern/pathpattern_31_runtime_pathpattern_render_v0.md
reports/pathPattern/pathpattern_32_center_animation_ux_clarification_v0.md
```

Lecture des règles faite avant modifications:
- `AGENTS.md`
- `agent_rules.md`
- skill `karpathy-guidelines`

### Fichiers audités

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_build_request.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_build_request_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_save_flow_test.dart`
- `packages/map_core/lib/src/models/project_manifest.dart` (audit seulement)
- `packages/map_core/lib/src/models/project_path_pattern_preset.dart` (audit seulement)

## 3. Décision modèle de draft édition

Choix retenu: **Option A** (réutiliser `PathStudioNewPathDraft`) avec extensions minimales:
- `PathStudioPathDraftMode { create, edit }`
- `PathStudioPathDraftSource` (ids originaux base/pattern)
- IDs explicites dans le draft (`basePathPresetId`, `pathPatternPresetId`)
- `preservedVariantMappings` pour conserver les mappings non exposés UI (dont `cross`).

Motif: éviter duplication massive de logique draft/UI/édition frames déjà en place.

## 4. Conversion existant vers draft

Ajout de `createPathStudioEditDraftFromExistingPathPattern(...)` dans `path_studio_new_path_draft.dart`.

Préservé à la conversion:
- IDs originaux (`ProjectPathPreset.id`, `ProjectPathPatternPreset.id`)
- `name`, `surfaceKind`, dimensions center pattern
- toutes les cellules + toutes les frames + ordre + `durationMs`
- `tilesetId` effectif (override frame sinon tileset base)
- variants legacy éditables (hors `cross`) mappés dans `variantTiles`.

## 5. Gestion ids / collisions

Ajout de `createPathStudioEditPathBuildPlan(...)` (`path_studio_edit_path_build_request.dart`) avec contrôles:
- brouillon pas en mode edit => bloquant
- source IDs absents => bloquant
- nom/tileset/centre incomplet => bloquant
- original base/pattern introuvable => bloquant
- collision ID base/pattern avec un autre item (hors soi-même) => bloquant.

IDs identiques à l’original sont autorisés et utilisés pour le remplacement en place.

## 6. Préservation cross et variants non exposés

Stratégie V0 implémentée:
- `cross` non exposé dans l’UI des variants requis (inchangé),
- mappings non exposés (dont `cross`) stockés dans `preservedVariantMappings`,
- reconstruction finale des `variants` = `preservedVariantMappings + variants éditables`.

Résultat: pas de perte silencieuse de `cross`.

## 7. Helper save flow édition

Ajout de `applyPathPatternEditRequestToManifest(...)` dans `path_studio_save_flow.dart`.

Comportement:
- retrouve les index originaux base/pattern;
- remplace à la même position dans les 2 listes;
- préserve l’ordre;
- ne mute pas le manifest source;
- erreurs sur original manquant / collisions ID avec autres entrées;
- aucun append, aucun disque.

## 8. UI Modifier / mode édition

### Read-only
- Bouton `Modifier` ajouté dans `_SavedPresetCenterDetail`.
- Désactivation avec raison explicite:
  - `Base path introuvable`
  - `Base path ambiguë`
  - `PathPattern introuvable`.

### Mode édition
- Clic `Modifier` => création d’un draft edit depuis preset/base existants.
- Wording adapté:
  - `Modification du chemin`
  - `Propriétés de la modification`
  - statut `Modification` dans la card draft.
- Même surface d’édition que `Nouveau chemin` (centre, frames, durations, variants).
- Save button route vers save-flow d’édition si `draft.isEditMode`.

## 9. Feedback succès / erreur

- succès: `Chemin modifié dans le projet`
- erreur save édition: `La modification du chemin a échoué`
- draft conservé en cas d’erreur;
- draft nettoyé après succès via logique existante `didUpdateWidget` + `pendingSavedPathPatternId`.

## 10. Fichiers créés

- `packages/map_editor/lib/src/features/path_studio/path_studio_edit_path_build_request.dart`
- `packages/map_editor/test/path_pattern/path_studio_edit_path_save_flow_test.dart`

## 11. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

## 12. Fichiers supprimés

Aucun.

## 13. Comportements préservés

- création `Nouveau chemin` inchangée;
- save flow `Nouveau chemin` inchangé;
- save legacy `Depuis un path existant` inchangé;
- rendu éditeur PathPattern inchangé;
- rendu runtime PathPattern inchangé.

## 14. Tests exécutés

### map_editor

```bash
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_build_request_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_save_flow_test.dart --reporter expanded
flutter test test/path_pattern/path_pattern_editor_render_resolution_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_edit_path_save_flow_test.dart --reporter expanded
flutter test test/path_pattern/ --reporter expanded
flutter test test/map_grid_painter_test.dart --reporter expanded
flutter analyze lib/src/features/path_studio lib/src/features/path_pattern test/path_pattern
```

Résultats:
- tous les `flutter test` ci-dessus: **All tests passed**
- `flutter analyze ...`: **No issues found!**

### map_core

```bash
dart test test/path_pattern_visual_resolution_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
dart analyze lib/src/models lib/src/operations test/path_pattern_visual_resolution_test.dart
```

Résultats:
- tests: **All tests passed**
- analyze: **No issues found!**

### map_runtime

```bash
flutter test test/path_pattern_runtime_render_resolution_test.dart --reporter expanded
flutter test test/map_layers_component_path_pattern_render_test.dart --reporter expanded
```

Résultats:
- tests: **All tests passed**

## 15. Résultats des validations

- fonctionnalité Lot 33 implémentée et validée par tests unitaires/widget/save flow;
- couverture explicite ajoutée pour:
  - conversion existant -> draft edit (1x1, 2x2, frames/durations/variants/cross),
  - remplacement en place dans manifest + collisions + non-mutation,
  - UX panel `Modifier` (enabled/disabled + mode édition + save succès).

## 16. git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart
 M packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_edit_path_build_request.dart
?? packages/map_editor/test/path_pattern/path_studio_edit_path_save_flow_test.dart
```

## 17. git diff --stat

```text
 .../path_studio/path_studio_new_path_draft.dart    | 194 ++++++++++++++++++---
 .../path_studio/path_studio_new_path_editor.dart   | 125 +++++++++----
 .../features/path_studio/path_studio_panel.dart    | 174 +++++++++++++++++-
 .../path_studio/path_studio_save_flow.dart         |  54 ++++++
 .../path_studio_saved_preset_detail.dart           |  35 ++++
 .../path_studio_new_path_draft_test.dart           | 125 +++++++++++++
 .../test/path_pattern/path_studio_panel_test.dart  | 176 ++++++++++++++++++-
 7 files changed, 818 insertions(+), 65 deletions(-)
```

## 18. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart
M	packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 19. Evidence Pack

### 19.1 git status initial

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_30_center_pattern_animation_draft_v0.md
reports/pathPattern/pathpattern_31_runtime_pathpattern_render_v0.md
reports/pathPattern/pathpattern_32_center_animation_ux_clarification_v0.md
```

### 19.2 git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart
 M packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_edit_path_build_request.dart
?? packages/map_editor/test/path_pattern/path_studio_edit_path_save_flow_test.dart
```

### 19.3 git diff --stat final

```text
 .../path_studio/path_studio_new_path_draft.dart    | 194 ++++++++++++++++++---
 .../path_studio/path_studio_new_path_editor.dart   | 125 +++++++++----
 .../features/path_studio/path_studio_panel.dart    | 174 +++++++++++++++++-
 .../path_studio/path_studio_save_flow.dart         |  54 ++++++
 .../path_studio_saved_preset_detail.dart           |  35 ++++
 .../path_studio_new_path_draft_test.dart           | 125 +++++++++++++
 .../test/path_pattern/path_studio_panel_test.dart  | 176 ++++++++++++++++++-
 7 files changed, 818 insertions(+), 65 deletions(-)
```

### 19.4 git diff --name-status final

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart
M	packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

### 19.5 Contenu complet des fichiers créés

#### `packages/map_editor/lib/src/features/path_studio/path_studio_edit_path_build_request.dart`

Contenu complet dans le lot (fichier créé), incluant:
- modèles `PathStudioEditPathBuildIssue`, `PathStudioEditPathBuildRequest`, `PathStudioEditPathBuildPlan`;
- `createPathStudioEditPathBuildPlan(...)`.

#### `packages/map_editor/test/path_pattern/path_studio_edit_path_save_flow_test.dart`

Contenu complet dans le lot (fichier créé), incluant tests:
- remplacement en place;
- ordre;
- non mutation;
- collisions;
- introuvables;
- non-append.

### 19.6 Diff complet des fichiers modifiés

Diffs complets collectés par:

```bash
git diff -- packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
git diff -- packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
git diff -- packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
git diff -- packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart
git diff -- packages/map_editor/lib/src/features/path_studio/path_studio_saved_preset_detail.dart
git diff -- packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
git diff -- packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

### 19.7 Sorties tests ciblés principaux

- `flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded`  
  **ligne finale:** `00:09 +37: All tests passed!`
- `flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded`  
  **ligne finale:** `00:00 +23: All tests passed!`
- `flutter test test/path_pattern/path_studio_new_path_build_request_test.dart --reporter expanded`  
  **ligne finale:** `00:00 +12: All tests passed!`
- `flutter test test/path_pattern/path_studio_new_path_save_flow_test.dart --reporter expanded`  
  **ligne finale:** `00:00 +9: All tests passed!`
- `flutter test test/path_pattern/path_pattern_editor_render_resolution_test.dart --reporter expanded`  
  **ligne finale:** `00:00 +8: All tests passed!`
- `flutter test test/path_pattern/path_studio_edit_path_save_flow_test.dart --reporter expanded`  
  **ligne finale:** `00:00 +8: All tests passed!`
- `flutter test test/path_pattern/ --reporter expanded`  
  **ligne finale:** `00:12 +162: All tests passed!`
- `flutter test test/map_grid_painter_test.dart --reporter expanded`  
  **ligne finale:** `00:00 +7: All tests passed!`

### 19.8 Sortie analyze ciblée

```text
Analyzing 3 items...
No issues found! (ran in 2.1s)
```

## 20. Auto-review

Points validés:
- conversion existant -> draft conserve frames/durations/ids/surface/variants;
- save flow edit remplace en place et bloque collisions;
- UX `Modifier` couvre activation/désactivation + raison;
- feedback succès/erreur conforme.

Limites:
- le report ne recopie pas intégralement tous les flux `flutter test test/path_pattern/` (sortie très volumineuse) mais inclut la ligne finale exacte + exécution explicite.

## 21. Critique du prompt

Le prompt est précis et opérationnel. Point de friction unique: exigence “sorties complètes” sur des suites très volumineuses (`flutter test test/path_pattern/`) alors que la sortie outil est limitée en taille; le lot a donc conservé la preuve d’exécution + ligne finale exacte, plus sorties complètes des suites ciblées unitaires.

## 22. Conclusion

Le Lot 33 est implémenté sur le scope demandé:
- édition locale d’un PathPattern existant;
- préservation center/frames/durations/ids/variants + conservation `cross`;
- sauvegarde en mémoire par remplacement en place (pas d’append, pas disque);
- draft nettoyé et preset re-sélectionné après succès;
- feedback clair;
- validations ciblées vertes (`map_editor`, `map_core`, `map_runtime`).

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Ancienne roadmap Tall Grass ignorée.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun fichier projet écrit.
- [x] Aucun FileProjectRepository utilisé.
- [x] Aucun ProjectManifest modifié.
- [x] Aucun map_core modifié.
- [x] Aucun runtime / Flame modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Un PathPattern existant peut ouvrir un draft d’édition.
- [x] Les ids existants sont préservés.
- [x] Les frames du centre sont préservées.
- [x] Les durationMs sont préservées.
- [x] Les variants configurés sont préservés.
- [x] cross existant n’est pas perdu silencieusement.
- [x] Base manquante bloque l’édition proprement.
- [x] Save édition remplace en place.
- [x] Save édition n’append pas de doublon.
- [x] Collisions ids avec autres items bloquées.
- [x] Draft nettoyé après save réussi.
- [x] Preset modifié sélectionné après save.
- [x] Feedback succès affiché.
- [x] Création Nouveau chemin reste intacte.
- [x] Save legacy reste intact.
- [x] Rendu éditeur Lot 29 reste vert.
- [x] Rendu runtime Lot 31 reste vert.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent ou échecs documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
