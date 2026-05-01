# Lot PathPattern-19 — Path Studio Save Flow Prep V0

## 1. Résumé exécutif

Le Lot 19 est implémenté côté `map_editor` uniquement.

Le Path Studio expose maintenant une préparation locale de sauvegarde :

- le flux `Nouveau chemin` produit un save plan local, propose des ids, peut construire un `PathCenterPattern` local quand le centre est complet, mais reste non sauvegardable car les bords / coins / jonctions du futur chemin complet ne sont pas encore définis ;
- le flux `Depuis un path existant` produit une requête locale contenant un vrai `ProjectPathPatternPreset` lorsque le brouillon est valide ;
- le bouton `Enregistrer` est activé uniquement pour un draft legacy valide avec callback injecté ;
- le clic `Enregistrer` appelle seulement le callback optionnel et ne mute pas le manifest ;
- aucune écriture projet, aucune persistance, aucun repository/service, aucun `map_core`, aucun `ProjectManifest`, aucun codec n'a été modifié.

## 2. Audit initial

Commande initiale :

```text
pwd
```

Sortie :

```text
/Users/karim/Project/pokemonProject
```

Commande initiale :

```text
git status --short --untracked-files=all
```

Sortie :

```text

```

Commande initiale :

```text
git diff --stat
```

Sortie :

```text

```

Commande initiale :

```text
git diff --name-status
```

Sortie :

```text

```

Le worktree était propre avant modification.

Fichiers inspectés :

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`
- `packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart`
- `packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart`
- `packages/map_editor/test/path_pattern/path_pattern_draft_test.dart`
- `packages/map_core/lib/src/models/project_path_pattern_preset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart`

Context Mode était disponible et a été utilisé pour l'audit large des fichiers Path Studio, tests et contrats `map_core`.

Constats :

- `PathStudioPanel` recevait déjà un `ProjectManifest` explicite et un `projectRootPath`, ce qui rendait le câblage testable sans ajouter d'infrastructure globale.
- `PathStudioNewPathDraft` porte déjà `tilesetId`, taille de centre, cellule active, cellules assignées et issues locales.
- Chaque `PathStudioNewPathDraftTile` sait déjà produire une `TilesetVisualFrame` via `toFrame()`.
- `PathPatternDraft` représente le flux legacy depuis un `ProjectPathPreset` existant et contient déjà `basePathPresetId`, `centerPattern`, `transparentColor`, `categoryId`, `sortOrder`.
- `ProjectPathPatternPreset` nécessite `id`, `name`, `basePathPresetId`, `centerPattern`, et accepte `transparentColor`, `categoryId`, `sortOrder`.
- Les opérations `project_manifest_path_pattern_preset_operations.dart` mutent par copie de manifest, mais ne sont pas appelées dans ce lot.
- Le type `ProjectPathPreset` n'est pas dans un fichier dédié `project_path_preset.dart`; il est déclaré dans `packages/map_core/lib/src/models/project_manifest.dart`.

## 3. État constaté avant travaux

Le bouton `Enregistrer` était un bouton shell désactivé avec `hint: lot futur`.

Le flux `Nouveau chemin` pouvait déjà :

- créer un draft local ;
- choisir un tileset ;
- configurer les cellules du centre ;
- afficher les diagnostics `Tileset à choisir` / `Cellules à configurer`.

Le flux `Depuis un path existant` pouvait déjà :

- créer un `PathPatternDraft` depuis le centre legacy `cross` ;
- changer de base legacy ;
- modifier nom et taille 1x1 / 2x2.

Manque avant le lot :

- aucun modèle local ne séparait readiness save / request save ;
- aucun `ProjectPathPatternPreset` n'était préparé pour le flux legacy ;
- le header ne dépendait pas de l'état réel de sauvegarde ;
- l'UI n'expliquait pas pourquoi `Nouveau chemin` restait non sauvegardable.

## 4. Décisions prises

- Créer un helper local `path_studio_save_plan.dart` côté `map_editor`.
- Ne pas déplacer de logique vers `map_core`.
- Ne pas appeler les opérations manifest.
- Garder `PathStudioPanel` comme orchestrateur avec un callback optionnel :
  `ValueChanged<ProjectPathPatternPreset>? onPathPatternPresetSaveRequested`.
- Rendre le callback disponible seulement pour le flux legacy valide.
- Garder `PathStudioNewPathSavePlan.canSaveNow == false` dans tous les cas.
- Ajouter `pathVariantMappingRequired` systématiquement au flux `Nouveau chemin`.
- Slugifier simplement en ASCII `[a-z0-9-]`; les accents sont remplacés comme séparateurs en V0.
- Détecter les collisions avec `manifest.pathPatternPresets.id` et `manifest.pathPresets.id`.
- Ne pas auto-incrémenter les ids en V0.

## 5. Modèle local de save plan

Fichier créé :

```text
packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart
```

Types ajoutés :

- `PathStudioSaveFlowKind`
- `PathStudioSaveIssueCode`
- `PathStudioSaveReadiness`
- `PathStudioNewPathSavePlan`
- `PathStudioLegacyPathPatternSaveRequest`
- `PathStudioLegacyPathPatternSavePlan`

Helpers ajoutés :

- `pathStudioSlugifyId`
- `createPathStudioNewPathSavePlan`
- `createPathStudioLegacyPathPatternSavePlan`
- `createPathCenterPatternFromNewPathDraft`
- `pathStudioSaveIssueLabel`
- `pathStudioSaveIssueDescription`

## 6. Conversion nouveau chemin vers centre PathPattern

Le helper `createPathCenterPatternFromNewPathDraft` retourne `null` si toutes les cellules requises ne sont pas configurées.

Quand le centre est complet :

- la taille du draft devient `PathCenterPatternSize`;
- les cellules sont émises en ordre row-major ;
- chaque cellule contient exactement une `TilesetVisualFrame`;
- `source.x` / `source.y` restent des coordonnées de tuiles ;
- aucune animation, aucun multi-frame, aucune sauvegarde n'est ajoutée.

Le flux `Nouveau chemin` reste bloqué par `pathVariantMappingRequired`, même si ce centre local est constructible.

## 7. Requête legacy ProjectPathPatternPreset

Le flux `Depuis un path existant` peut produire un `ProjectPathPatternPreset` local lorsque :

- le nom n'est pas vide ;
- `basePathPresetId` référence un `ProjectPathPreset` existant ;
- l'id proposé ne collisionne pas avec les ids existants.

La requête reprend :

- `id` depuis le slug du nom ;
- `name` trim ;
- `basePathPresetId` du draft ;
- `centerPattern` du draft ;
- `transparentColor` du draft ;
- `categoryId` du draft ;
- `sortOrder` du draft.

Elle ne modifie jamais `ProjectManifest`.

## 8. UI sauvegarde

Une section `Sauvegarde` a été ajoutée dans la zone centrale des deux modes draft.

Pour `Nouveau chemin`, l'UI affiche :

- `Brouillon de nouveau chemin`
- `Centre prêt` ou `Centre incomplet`
- `Sauvegarde non disponible dans ce lot`
- `Bords / coins / jonctions à définir`

Pour `Depuis un path existant`, l'UI affiche :

- `Motif PathPattern depuis path existant`
- id proposé ;
- base héritée ;
- readiness `Requête prête` ou `Bloquée` ;
- `Callback de sauvegarde absent` si la requête est prête mais non branchée.

Clés de test ajoutées :

- `path-studio-save-button`
- `path-studio-save-status-card`
- `path-studio-save-issue-<issue.name>`

## 9. Callback save prep

`PathStudioPanel` expose maintenant :

```dart
final ValueChanged<ProjectPathPatternPreset>? onPathPatternPresetSaveRequested;
```

Règles appliquées :

- aucun draft : `Enregistrer` disabled ;
- `Nouveau chemin` : `Enregistrer` disabled ;
- legacy invalid : `Enregistrer` disabled ;
- legacy valid sans callback : `Enregistrer` disabled ;
- legacy valid avec callback : `Enregistrer` enabled ;
- clic : callback appelé une fois avec le preset préparé ;
- le draft n'est pas vidé ;
- le manifest n'est pas muté ;
- un feedback local `Requête de sauvegarde préparée` est affiché.

## 10. Fichiers créés

- `packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart`
- `packages/map_editor/test/path_pattern/path_studio_save_plan_test.dart`
- `reports/pathPattern/pathpattern_19_save_flow_prep_v0.md`

## 11. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

## 12. Fichiers supprimés

Aucun fichier supprimé.

## 13. Tests ajoutés / modifiés

Ajout :

- `path_studio_save_plan_test.dart`

Couverture ajoutée :

- slug stable ;
- nouveau chemin sans tileset non sauvegardable ;
- nouveau chemin complet côté centre constructible en `PathCenterPattern` ;
- centre 2x2 row-major ;
- legacy valid produit un `ProjectPathPatternPreset` ;
- legacy nom vide bloqué ;
- id dupliqué bloqué.

Complément dans `path_studio_panel_test.dart` :

- section `Sauvegarde` pour nouveau chemin ;
- nouveau chemin complet côté centre encore bloqué ;
- legacy request prête sans callback mais bouton disabled ;
- legacy request avec callback appelle le callback sans mutation manifest ;
- id dupliqué bloque le bouton.

## 14. Commandes exécutées

```text
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git diff -- packages/map_core
flutter test test/path_pattern/path_studio_save_plan_test.dart
flutter test test/path_pattern/path_studio_panel_test.dart
flutter test test/path_pattern/path_studio_new_path_draft_test.dart
flutter test test/path_pattern/path_pattern_draft_test.dart
flutter test test/path_pattern/
flutter test test/editor_shell_page_smoke_test.dart
flutter test test/top_toolbar_test.dart
flutter test test/editor_selectors_test.dart
dart test test/project_manifest_path_pattern_preset_operations_test.dart
dart test test/project_manifest_path_pattern_presets_test.dart
dart test test/project_path_pattern_preset_json_codec_test.dart
dart test test/project_path_pattern_preset_json_golden_test.dart
dart test test/project_path_pattern_preset_test.dart
dart test test/path_center_pattern_test.dart
dart test test/path_center_pattern_resolver_test.dart
flutter analyze lib/src/features/path_studio test/path_pattern
dart format packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart packages/map_editor/test/path_pattern/path_studio_save_plan_test.dart packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 15. Résultats des validations

### Test ciblé save plan

Commande :

```text
cd packages/map_editor && flutter test test/path_pattern/path_studio_save_plan_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_save_plan_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_save_plan_test.dart
00:01 +0: PathStudioSavePlan slugifies proposed ids with a stable fallback
00:01 +1: PathStudioSavePlan slugifies proposed ids with a stable fallback
00:01 +1: PathStudioSavePlan keeps a new path without tileset non-saveable
00:01 +2: PathStudioSavePlan keeps a new path without tileset non-saveable
00:01 +2: PathStudioSavePlan builds a local center pattern for a complete new path center
00:01 +3: PathStudioSavePlan builds a local center pattern for a complete new path center
00:01 +3: PathStudioSavePlan builds a row-major 2x2 local center pattern for new path
00:01 +4: PathStudioSavePlan builds a row-major 2x2 local center pattern for new path
00:01 +4: PathStudioSavePlan prepares a ProjectPathPatternPreset for a valid legacy draft
00:01 +5: PathStudioSavePlan prepares a ProjectPathPatternPreset for a valid legacy draft
00:01 +5: PathStudioSavePlan blocks a legacy draft with an empty name
00:01 +6: PathStudioSavePlan blocks a legacy draft with an empty name
00:01 +6: PathStudioSavePlan blocks duplicate proposed PathPattern ids
00:01 +7: PathStudioSavePlan blocks duplicate proposed PathPattern ids
00:01 +7: All tests passed!
```

### Test ciblé panel

Commande :

```text
cd packages/map_editor && flutter test test/path_pattern/path_studio_panel_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:02 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +1: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +1: PathStudioPanel lists presets and updates summary and inspector selection
00:03 +2: PathStudioPanel lists presets and updates summary and inspector selection
00:03 +2: PathStudioPanel filters presets locally and clears selection on no result
00:03 +3: PathStudioPanel filters presets locally and clears selection on no result
00:03 +3: PathStudioPanel creates a new path draft without legacy base presets
00:03 +4: PathStudioPanel creates a new path draft without legacy base presets
00:03 +4: PathStudioPanel new path draft does not force existing legacy path choices
00:03 +5: PathStudioPanel new path draft does not force existing legacy path choices
00:03 +5: PathStudioPanel new path draft can select a project tileset
00:04 +5: PathStudioPanel new path draft can select a project tileset
00:04 +6: PathStudioPanel new path draft can select a project tileset
00:04 +6: PathStudioPanel new path draft stays usable when the project has no tileset
00:04 +7: PathStudioPanel new path draft stays usable when the project has no tileset
00:04 +7: PathStudioPanel assigns a tileset tile to the 1x1 active cell
00:04 +8: PathStudioPanel assigns a tileset tile to the 1x1 active cell
00:04 +8: PathStudioPanel missing tileset image keeps the logical picker fallback
00:04 +9: PathStudioPanel missing tileset image keeps the logical picker fallback
00:04 +9: PathStudioPanel image-backed tileset picker assigns the active cell
00:05 +9: PathStudioPanel image-backed tileset picker assigns the active cell
00:05 +10: PathStudioPanel image-backed tileset picker assigns the active cell
00:05 +10: PathStudioPanel image-backed picker fills all 2x2 cells and supports clear
00:05 +11: PathStudioPanel image-backed picker fills all 2x2 cells and supports clear
00:05 +11: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:06 +11: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:06 +12: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:06 +12: PathStudioPanel replaces and clears the active cell tile
00:06 +13: PathStudioPanel replaces and clears the active cell tile
00:06 +13: PathStudioPanel changing tileset clears configured center cells
00:06 +14: PathStudioPanel changing tileset clears configured center cells
00:06 +14: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:06 +15: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:06 +15: PathStudioPanel edits new path draft name and keeps save disabled
00:06 +16: PathStudioPanel edits new path draft name and keeps save disabled
00:06 +16: PathStudioPanel new path save status explains missing path variant mapping
00:07 +16: PathStudioPanel new path save status explains missing path variant mapping
00:07 +17: PathStudioPanel new path save status explains missing path variant mapping
00:07 +17: PathStudioPanel new path with complete center stays blocked for save
00:07 +18: PathStudioPanel new path with complete center stays blocked for save
00:07 +18: PathStudioPanel legacy save request is prepared but disabled without callback
00:07 +19: PathStudioPanel legacy save request is prepared but disabled without callback
00:07 +19: PathStudioPanel legacy save request calls callback without mutating manifest
00:07 +20: PathStudioPanel legacy save request calls callback without mutating manifest
00:07 +20: PathStudioPanel legacy duplicate proposed id blocks save
00:07 +21: PathStudioPanel legacy duplicate proposed id blocks save
00:07 +21: PathStudioPanel secondary legacy flow changes inherited structure locally
00:07 +22: PathStudioPanel secondary legacy flow changes inherited structure locally
00:07 +22: PathStudioPanel empty new path name shows a local diagnostic
00:07 +23: PathStudioPanel empty new path name shows a local diagnostic
00:07 +23: PathStudioPanel secondary legacy flow reports missing existing paths
00:07 +24: PathStudioPanel secondary legacy flow reports missing existing paths
00:07 +24: All tests passed!
```

### Régressions PathPattern

Commande :

```text
cd packages/map_editor && flutter test test/path_pattern/
```

Lignes représentatives :

```text
PathStudioSavePlan blocks duplicate proposed PathPattern ids
PathStudioPanel legacy save request calls callback without mutating manifest
PathStudioPanel secondary legacy flow reports missing existing paths
```

Ligne finale exacte :

```text
00:08 +97: All tests passed!
```

### Régressions shell

Commande :

```text
cd packages/map_editor && flutter test test/editor_shell_page_smoke_test.dart
```

Ligne finale exacte :

```text
00:06 +7: All tests passed!
```

Commande :

```text
cd packages/map_editor && flutter test test/top_toolbar_test.dart
```

Ligne finale exacte :

```text
00:04 +5: All tests passed!
```

Commande :

```text
cd packages/map_editor && flutter test test/editor_selectors_test.dart
```

Ligne finale exacte :

```text
00:02 +8: All tests passed!
```

### Régressions map_core PathPattern

Commande :

```text
cd packages/map_core && dart test test/project_manifest_path_pattern_preset_operations_test.dart
```

Ligne finale exacte :

```text
00:00 +14: All tests passed!
```

Commande :

```text
cd packages/map_core && dart test test/project_manifest_path_pattern_presets_test.dart
```

Ligne finale exacte :

```text
00:00 +8: All tests passed!
```

Commande :

```text
cd packages/map_core && dart test test/project_path_pattern_preset_json_codec_test.dart
```

Ligne finale exacte :

```text
00:00 +9: All tests passed!
```

Commande :

```text
cd packages/map_core && dart test test/project_path_pattern_preset_json_golden_test.dart
```

Ligne finale exacte :

```text
00:00 +6: All tests passed!
```

Commande :

```text
cd packages/map_core && dart test test/project_path_pattern_preset_test.dart
```

Ligne finale exacte :

```text
00:00 +5: All tests passed!
```

Commande :

```text
cd packages/map_core && dart test test/path_center_pattern_test.dart
```

Ligne finale exacte :

```text
00:00 +17: All tests passed!
```

Commande :

```text
cd packages/map_core && dart test test/path_center_pattern_resolver_test.dart
```

Ligne finale exacte :

```text
00:00 +6: All tests passed!
```

### Analyze ciblé

Commande :

```text
cd packages/map_editor && flutter analyze lib/src/features/path_studio test/path_pattern
```

Sortie :

```text
Analyzing 2 items...

No issues found! (ran in 9.2s)
```

## 16. git status final

Commande :

```text
git status --short --untracked-files=all
```

Sortie finale vérifiée après création du présent rapport :

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart
?? packages/map_editor/test/path_pattern/path_studio_save_plan_test.dart
?? reports/pathPattern/pathpattern_19_save_flow_prep_v0.md
```

## 17. git diff --stat

Commande :

```text
git diff --stat
```

Sortie :

```text
 .../features/path_studio/path_studio_panel.dart    | 305 ++++++++++++++++++++-
 .../test/path_pattern/path_studio_panel_test.dart  | 152 ++++++++++
 2 files changed, 452 insertions(+), 5 deletions(-)
```

Note factuelle : `git diff --stat` ne liste pas les fichiers non suivis.

## 18. git diff --name-status

Commande :

```text
git diff --name-status
```

Sortie :

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

Note factuelle : `git diff --name-status` ne liste pas les fichiers non suivis.

## 19. Evidence Pack

### 19.1 Absence de diff map_core

Commande :

```text
git diff -- packages/map_core
```

Sortie :

```text

```

### 19.2 Contenu complet — fichier créé `path_studio_save_plan.dart`

```dart
import 'package:map_core/map_core.dart';

import 'path_pattern_draft.dart';
import 'path_studio_new_path_draft.dart';

enum PathStudioSaveFlowKind {
  newPath,
  legacyPathPattern,
}

enum PathStudioSaveIssueCode {
  nameRequired,
  tilesetRequired,
  centerCellsRequired,
  basePathPresetRequired,
  pathVariantMappingRequired,
  duplicatePathPatternId,
}

final class PathStudioSaveReadiness {
  PathStudioSaveReadiness({
    required this.kind,
    required this.canSaveNow,
    required List<PathStudioSaveIssueCode> issues,
  }) : issues = List<PathStudioSaveIssueCode>.unmodifiable(issues);

  final PathStudioSaveFlowKind kind;
  final bool canSaveNow;
  final List<PathStudioSaveIssueCode> issues;
}

final class PathStudioNewPathSavePlan {
  PathStudioNewPathSavePlan({
    required this.name,
    required this.proposedBasePathPresetId,
    required this.proposedPathPatternPresetId,
    required this.centerWidth,
    required this.centerHeight,
    required this.configuredCellCount,
    required this.centerCellCount,
    required List<PathStudioSaveIssueCode> issues,
    required this.centerPattern,
  }) : issues = List<PathStudioSaveIssueCode>.unmodifiable(issues);

  final String name;
  final String proposedBasePathPresetId;
  final String proposedPathPatternPresetId;
  final int centerWidth;
  final int centerHeight;
  final int configuredCellCount;
  final int centerCellCount;
  final List<PathStudioSaveIssueCode> issues;
  final PathCenterPattern? centerPattern;

  PathStudioSaveFlowKind get kind => PathStudioSaveFlowKind.newPath;

  bool get canSaveNow => false;

  bool get isCenterReady => centerPattern != null;

  PathStudioSaveReadiness get readiness => PathStudioSaveReadiness(
        kind: kind,
        canSaveNow: canSaveNow,
        issues: issues,
      );
}

final class PathStudioLegacyPathPatternSaveRequest {
  const PathStudioLegacyPathPatternSaveRequest({required this.preset});

  final ProjectPathPatternPreset preset;
}

final class PathStudioLegacyPathPatternSavePlan {
  PathStudioLegacyPathPatternSavePlan({
    required this.name,
    required this.proposedPathPatternPresetId,
    required this.basePathPresetId,
    required List<PathStudioSaveIssueCode> issues,
    required this.request,
  }) : issues = List<PathStudioSaveIssueCode>.unmodifiable(issues);

  final String name;
  final String proposedPathPatternPresetId;
  final String basePathPresetId;
  final List<PathStudioSaveIssueCode> issues;
  final PathStudioLegacyPathPatternSaveRequest? request;

  PathStudioSaveFlowKind get kind => PathStudioSaveFlowKind.legacyPathPattern;

  bool get canSaveNow => request != null && issues.isEmpty;

  PathStudioSaveReadiness get readiness => PathStudioSaveReadiness(
        kind: kind,
        canSaveNow: canSaveNow,
        issues: issues,
      );
}

String pathStudioSlugifyId(String input) {
  final normalized = input.trim().toLowerCase();
  final replaced = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  final collapsed = replaced.replaceAll(RegExp(r'-+'), '-');
  final trimmed = collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
  return trimmed.isEmpty ? 'path-pattern' : trimmed;
}

PathStudioNewPathSavePlan createPathStudioNewPathSavePlan({
  required ProjectManifest manifest,
  required PathStudioNewPathDraft draft,
}) {
  final baseId = pathStudioSlugifyId(draft.name);
  final patternId = '$baseId-pattern';
  final issues = <PathStudioSaveIssueCode>[];
  if (draft.name.trim().isEmpty) {
    issues.add(PathStudioSaveIssueCode.nameRequired);
  }
  if (draft.tilesetId == null || draft.tilesetId!.isEmpty) {
    issues.add(PathStudioSaveIssueCode.tilesetRequired);
  }
  if (!draft.allCenterCellsConfigured) {
    issues.add(PathStudioSaveIssueCode.centerCellsRequired);
  }
  issues.add(PathStudioSaveIssueCode.pathVariantMappingRequired);
  if (_hasPathPatternId(manifest, patternId) ||
      _hasPathPresetId(manifest, baseId)) {
    issues.add(PathStudioSaveIssueCode.duplicatePathPatternId);
  }

  return PathStudioNewPathSavePlan(
    name: draft.name.trim(),
    proposedBasePathPresetId: baseId,
    proposedPathPatternPresetId: patternId,
    centerWidth: draft.centerWidth,
    centerHeight: draft.centerHeight,
    configuredCellCount: draft.configuredCellCount,
    centerCellCount: draft.centerCellCount,
    issues: issues,
    centerPattern: createPathCenterPatternFromNewPathDraft(draft),
  );
}

PathStudioLegacyPathPatternSavePlan createPathStudioLegacyPathPatternSavePlan({
  required ProjectManifest manifest,
  required PathPatternDraft draft,
}) {
  final patternId = pathStudioSlugifyId(draft.name);
  final issues = <PathStudioSaveIssueCode>[];
  if (draft.name.trim().isEmpty) {
    issues.add(PathStudioSaveIssueCode.nameRequired);
  }
  if (draft.basePathPresetId.trim().isEmpty ||
      !_hasPathPresetId(manifest, draft.basePathPresetId)) {
    issues.add(PathStudioSaveIssueCode.basePathPresetRequired);
  }
  if (_hasPathPatternId(manifest, patternId) ||
      _hasPathPresetId(manifest, patternId)) {
    issues.add(PathStudioSaveIssueCode.duplicatePathPatternId);
  }

  final request = issues.isEmpty
      ? PathStudioLegacyPathPatternSaveRequest(
          preset: ProjectPathPatternPreset(
            id: patternId,
            name: draft.name.trim(),
            basePathPresetId: draft.basePathPresetId,
            centerPattern: draft.centerPattern,
            transparentColor: draft.transparentColor,
            categoryId: draft.categoryId,
            sortOrder: draft.sortOrder,
          ),
        )
      : null;

  return PathStudioLegacyPathPatternSavePlan(
    name: draft.name.trim(),
    proposedPathPatternPresetId: patternId,
    basePathPresetId: draft.basePathPresetId,
    issues: issues,
    request: request,
  );
}

PathCenterPattern? createPathCenterPatternFromNewPathDraft(
  PathStudioNewPathDraft draft,
) {
  if (!draft.allCenterCellsConfigured) {
    return null;
  }
  return PathCenterPattern(
    size: PathCenterPatternSize(
      width: draft.centerWidth,
      height: draft.centerHeight,
    ),
    cells: [
      for (final cell in draft.cells)
        PathCenterPatternCell(
          localX: cell.localX,
          localY: cell.localY,
          frames: [cell.tile!.toFrame()],
        ),
    ],
  );
}

String pathStudioSaveIssueLabel(PathStudioSaveIssueCode issue) {
  return switch (issue) {
    PathStudioSaveIssueCode.nameRequired => 'Nom requis',
    PathStudioSaveIssueCode.tilesetRequired => 'Tileset requis',
    PathStudioSaveIssueCode.centerCellsRequired =>
      'Cellules du centre à configurer',
    PathStudioSaveIssueCode.basePathPresetRequired => 'Path de base requis',
    PathStudioSaveIssueCode.pathVariantMappingRequired =>
      'Bords / coins / jonctions à définir',
    PathStudioSaveIssueCode.duplicatePathPatternId =>
      'ID PathPattern déjà utilisé',
  };
}

String pathStudioSaveIssueDescription(PathStudioSaveIssueCode issue) {
  return switch (issue) {
    PathStudioSaveIssueCode.nameRequired =>
      'Le nom du brouillon doit être renseigné avant une préparation de sauvegarde.',
    PathStudioSaveIssueCode.tilesetRequired =>
      'Le nouveau chemin doit choisir un tileset avant de préparer ses données.',
    PathStudioSaveIssueCode.centerCellsRequired =>
      'Chaque cellule requise du centre doit recevoir une tuile.',
    PathStudioSaveIssueCode.basePathPresetRequired =>
      'Le motif legacy doit référencer un path existant du projet.',
    PathStudioSaveIssueCode.pathVariantMappingRequired =>
      'Le centre est préparé localement, mais les bords, coins et jonctions du chemin complet restent à définir.',
    PathStudioSaveIssueCode.duplicatePathPatternId =>
      'L’identifiant proposé entre en collision avec un id déjà présent dans le projet.',
  };
}

bool _hasPathPatternId(ProjectManifest manifest, String id) {
  return manifest.pathPatternPresets.any((preset) => preset.id == id);
}

bool _hasPathPresetId(ProjectManifest manifest, String id) {
  return manifest.pathPresets.any((preset) => preset.id == id);
}
```

### 19.3 Contenu complet — fichier créé `path_studio_save_plan_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_draft.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';
import 'package:map_editor/src/features/path_studio/path_studio_save_plan.dart';

void main() {
  group('PathStudioSavePlan', () {
    test('slugifies proposed ids with a stable fallback', () {
      expect(pathStudioSlugifyId('Nouveau chemin'), 'nouveau-chemin');
      expect(pathStudioSlugifyId('  Route   eau!! '), 'route-eau');
      expect(pathStudioSlugifyId('   '), 'path-pattern');
    });

    test('keeps a new path without tileset non-saveable', () {
      final plan = createPathStudioNewPathSavePlan(
        manifest: _manifest(),
        draft: createInitialPathStudioNewPathDraft(),
      );

      expect(plan.kind, PathStudioSaveFlowKind.newPath);
      expect(plan.proposedBasePathPresetId, 'nouveau-chemin');
      expect(plan.proposedPathPatternPresetId, 'nouveau-chemin-pattern');
      expect(plan.configuredCellCount, 0);
      expect(plan.centerCellCount, 1);
      expect(plan.centerPattern, isNull);
      expect(plan.canSaveNow, isFalse);
      expect(plan.issues, [
        PathStudioSaveIssueCode.tilesetRequired,
        PathStudioSaveIssueCode.centerCellsRequired,
        PathStudioSaveIssueCode.pathVariantMappingRequired,
      ]);
    });

    test('builds a local center pattern for a complete new path center', () {
      final draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final plan = createPathStudioNewPathSavePlan(
        manifest: _manifest(),
        draft: draft,
      );

      expect(plan.centerPattern, isNotNull);
      expect(
          plan.centerPattern!.size, PathCenterPatternSize(width: 1, height: 1));
      expect(plan.centerPattern!.cellAt(0, 0).frames, [
        const TilesetVisualFrame(
          tilesetId: 'tileset-main',
          source: TilesetSourceRect(x: 2, y: 3),
        ),
      ]);
      expect(
        plan.issues,
        isNot(contains(PathStudioSaveIssueCode.centerCellsRequired)),
      );
      expect(
        plan.issues,
        contains(PathStudioSaveIssueCode.pathVariantMappingRequired),
      );
      expect(plan.canSaveNow, isFalse);
    });

    test('builds a row-major 2x2 local center pattern for new path', () {
      var draft = resizePathStudioNewPathDraftCenter(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        width: 2,
        height: 2,
      );
      draft = _assign(draft, localX: 0, localY: 0, sourceX: 1, sourceY: 0);
      draft = _assign(draft, localX: 1, localY: 0, sourceX: 2, sourceY: 0);
      draft = _assign(draft, localX: 0, localY: 1, sourceX: 3, sourceY: 0);
      draft = _assign(draft, localX: 1, localY: 1, sourceX: 4, sourceY: 0);

      final plan = createPathStudioNewPathSavePlan(
        manifest: _manifest(),
        draft: draft,
      );
      final pattern = plan.centerPattern!;

      expect(pattern.size, PathCenterPatternSize(width: 2, height: 2));
      expect(
        pattern.cells.map((cell) => (cell.localX, cell.localY)),
        [
          (0, 0),
          (1, 0),
          (0, 1),
          (1, 1),
        ],
      );
      expect(pattern.cellAt(0, 0).frames.single.source,
          const TilesetSourceRect(x: 1, y: 0));
      expect(pattern.cellAt(1, 0).frames.single.source,
          const TilesetSourceRect(x: 2, y: 0));
      expect(pattern.cellAt(0, 1).frames.single.source,
          const TilesetSourceRect(x: 3, y: 0));
      expect(pattern.cellAt(1, 1).frames.single.source,
          const TilesetSourceRect(x: 4, y: 0));
    });

    test('prepares a ProjectPathPatternPreset for a valid legacy draft', () {
      final base = _legacyPathPreset(id: 'legacy-water');
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(basePathPreset: base, sortOrder: 7),
        'Motif eau',
      );

      final plan = createPathStudioLegacyPathPatternSavePlan(
        manifest: _manifest(pathPresets: [base]),
        draft: draft,
      );

      expect(plan.kind, PathStudioSaveFlowKind.legacyPathPattern);
      expect(plan.proposedPathPatternPresetId, 'motif-eau');
      expect(plan.canSaveNow, isTrue);
      expect(plan.issues, isEmpty);
      expect(plan.request, isNotNull);
      expect(plan.request!.preset.id, 'motif-eau');
      expect(plan.request!.preset.name, 'Motif eau');
      expect(plan.request!.preset.basePathPresetId, 'legacy-water');
      expect(plan.request!.preset.centerPattern, draft.centerPattern);
      expect(plan.request!.preset.sortOrder, 7);
    });

    test('blocks a legacy draft with an empty name', () {
      final base = _legacyPathPreset(id: 'legacy-water');
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(basePathPreset: base),
        '   ',
      );

      final plan = createPathStudioLegacyPathPatternSavePlan(
        manifest: _manifest(pathPresets: [base]),
        draft: draft,
      );

      expect(plan.canSaveNow, isFalse);
      expect(plan.request, isNull);
      expect(plan.issues, contains(PathStudioSaveIssueCode.nameRequired));
    });

    test('blocks duplicate proposed PathPattern ids', () {
      final base = _legacyPathPreset(id: 'legacy-water');
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(basePathPreset: base),
        'Motif eau',
      );

      final plan = createPathStudioLegacyPathPatternSavePlan(
        manifest: _manifest(
          pathPresets: [base],
          pathPatternPresets: [
            _pathPatternPreset(id: 'motif-eau', basePathPresetId: base.id),
          ],
        ),
        draft: draft,
      );

      expect(plan.canSaveNow, isFalse);
      expect(plan.request, isNull);
      expect(
        plan.issues,
        contains(PathStudioSaveIssueCode.duplicatePathPatternId),
      );
    });
  });
}

PathStudioNewPathDraft _assign(
  PathStudioNewPathDraft draft, {
  required int localX,
  required int localY,
  required int sourceX,
  required int sourceY,
}) {
  return assignPathStudioNewPathDraftCellTile(
    draft: draft,
    localX: localX,
    localY: localY,
    sourceX: sourceX,
    sourceY: sourceY,
  );
}

ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPreset _legacyPathPreset({
  required String id,
}) {
  return ProjectPathPreset(
    id: id,
    name: id,
    surfaceKind: PathSurfaceKind.water,
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.cross,
        frames: [_frame(0)],
      ),
    ],
  );
}

ProjectPathPatternPreset _pathPatternPreset({
  required String id,
  required String basePathPresetId,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: id,
    basePathPresetId: basePathPresetId,
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 1, height: 1),
      cells: [
        PathCenterPatternCell(localX: 0, localY: 0, frames: [_frame(0)]),
      ],
    ),
  );
}

TilesetVisualFrame _frame(int sourceX) {
  return TilesetVisualFrame(source: TilesetSourceRect(x: sourceX, y: 0));
}
```

### 19.4 Diff complet réel — fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index b783aa2d..ec92fc14 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -7,6 +7,7 @@ import '../editor/state/editor_selectors.dart';
 import 'path_pattern_draft.dart';
 import 'path_pattern_editor_read_model.dart';
 import 'path_studio_new_path_draft.dart';
+import 'path_studio_save_plan.dart';
 import 'path_studio_theme.dart';
 import 'path_studio_tileset_image_picker.dart';
 
@@ -43,10 +44,13 @@ class PathStudioPanel extends StatefulWidget {
     super.key,
     required this.manifest,
     this.projectRootPath,
+    this.onPathPatternPresetSaveRequested,
   });
 
   final ProjectManifest manifest;
   final String? projectRootPath;
+  final ValueChanged<ProjectPathPatternPreset>?
+      onPathPatternPresetSaveRequested;
 
   @override
   State<PathStudioPanel> createState() => _PathStudioPanelState();
@@ -59,6 +63,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
   PathPatternDraft? _draft;
   bool _draftSelected = false;
   String? _draftMessage;
+  String? _saveFeedbackMessage;
 
   /// Index dans `readModel.presets`, pas id métier.
   ///
@@ -77,6 +82,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
       _draft = null;
       _draftSelected = false;
       _draftMessage = null;
+      _saveFeedbackMessage = null;
     }
   }
 
@@ -92,6 +98,23 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         : _selectedCard(filtered);
     final selectedNewPathDraft = _newPathDraftSelected ? _newPathDraft : null;
     final selectedDraft = _draftSelected ? _draft : null;
+    final newPathSavePlan = selectedNewPathDraft == null
+        ? null
+        : createPathStudioNewPathSavePlan(
+            manifest: widget.manifest,
+            draft: selectedNewPathDraft,
+          );
+    final legacySavePlan = selectedDraft == null
+        ? null
+        : createPathStudioLegacyPathPatternSavePlan(
+            manifest: widget.manifest,
+            draft: selectedDraft,
+          );
+    final saveCallback = widget.onPathPatternPresetSaveRequested;
+    final onSavePressed =
+        legacySavePlan?.canSaveNow == true && saveCallback != null
+            ? _requestLegacyPathPatternSave
+            : null;
 
     return DecoratedBox(
       decoration: const BoxDecoration(
@@ -106,6 +129,12 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
               summary: readModel.summary,
               onCreateNewPathDraft: _createNewPathDraft,
               onCreateLegacyDraft: _createLegacyDraft,
+              onSavePressed: onSavePressed,
+              saveHint: _saveButtonHint(
+                newPathSavePlan: newPathSavePlan,
+                legacySavePlan: legacySavePlan,
+                hasSaveCallback: saveCallback != null,
+              ),
             ),
             const SizedBox(height: 16),
             Expanded(
@@ -160,7 +189,11 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                       settings: widget.manifest.settings,
                       projectRootPath: widget.projectRootPath,
                       newPathDraft: selectedNewPathDraft,
+                      newPathSavePlan: newPathSavePlan,
                       draft: selectedDraft,
+                      legacySavePlan: legacySavePlan,
+                      hasSaveCallback: saveCallback != null,
+                      saveFeedbackMessage: _saveFeedbackMessage,
                       selected: selected?.card,
                       hasAnyPreset: readModel.presets.isNotEmpty,
                       onNewPathSizeChanged: _resizeNewPathDraft,
@@ -265,6 +298,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
       _newPathDraftSelected = true;
       _draftSelected = false;
       _draftMessage = null;
+      _saveFeedbackMessage = null;
     });
   }
 
@@ -272,6 +306,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     if (widget.manifest.pathPresets.isEmpty) {
       setState(() {
         _draftMessage = 'Aucun path existant disponible';
+        _saveFeedbackMessage = null;
         _newPathDraftSelected = false;
         _draftSelected = false;
       });
@@ -288,11 +323,13 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         _draftMessage = draft == null
             ? 'Aucun path existant disponible'
             : 'Brouillon non sauvegardé';
+        _saveFeedbackMessage = null;
       });
     } on ArgumentError {
       setState(() {
         _draftMessage =
             'Le preset Path de base ne contient pas de centre cross';
+        _saveFeedbackMessage = null;
         _newPathDraftSelected = false;
         _draftSelected = false;
       });
@@ -306,6 +343,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     }
     setState(() {
       _newPathDraft = renamePathStudioNewPathDraft(draft, name);
+      _saveFeedbackMessage = null;
     });
   }
 
@@ -320,6 +358,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         width: width,
         height: height,
       );
+      _saveFeedbackMessage = null;
     });
   }
 
@@ -330,6 +369,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     }
     setState(() {
       _newPathDraft = selectPathStudioNewPathDraftTileset(draft, tilesetId);
+      _saveFeedbackMessage = null;
     });
   }
 
@@ -344,6 +384,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         localX: localX,
         localY: localY,
       );
+      _saveFeedbackMessage = null;
     });
   }
 
@@ -360,6 +401,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         sourceX: sourceX,
         sourceY: sourceY,
       );
+      _saveFeedbackMessage = null;
     });
   }
 
@@ -374,6 +416,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         localX: localX,
         localY: localY,
       );
+      _saveFeedbackMessage = null;
     });
   }
 
@@ -382,7 +425,10 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     if (draft == null) {
       return;
     }
-    setState(() => _draft = renamePathPatternDraft(draft, name));
+    setState(() {
+      _draft = renamePathPatternDraft(draft, name);
+      _saveFeedbackMessage = null;
+    });
   }
 
   void _resizeDraft(int width, int height) {
@@ -398,6 +444,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         width: width,
         height: height,
       );
+      _saveFeedbackMessage = null;
     });
   }
 
@@ -415,6 +462,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         draft: draft,
         basePathPreset: base,
       );
+      _saveFeedbackMessage = null;
     });
   }
 
@@ -429,9 +477,48 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         localX: localX,
         localY: localY,
       );
+      _saveFeedbackMessage = null;
     });
   }
 
+  void _requestLegacyPathPatternSave() {
+    final draft = _draft;
+    final callback = widget.onPathPatternPresetSaveRequested;
+    if (draft == null || !_draftSelected || callback == null) {
+      return;
+    }
+    final plan = createPathStudioLegacyPathPatternSavePlan(
+      manifest: widget.manifest,
+      draft: draft,
+    );
+    final request = plan.request;
+    if (request == null) {
+      return;
+    }
+    callback(request.preset);
+    setState(() {
+      _saveFeedbackMessage = 'Requête de sauvegarde préparée';
+      _draftMessage = _saveFeedbackMessage;
+    });
+  }
+
+  String _saveButtonHint({
+    required PathStudioNewPathSavePlan? newPathSavePlan,
+    required PathStudioLegacyPathPatternSavePlan? legacySavePlan,
+    required bool hasSaveCallback,
+  }) {
+    if (newPathSavePlan != null) {
+      return 'variants manquants';
+    }
+    if (legacySavePlan != null) {
+      if (!legacySavePlan.canSaveNow) {
+        return 'à corriger';
+      }
+      return hasSaveCallback ? 'préparer' : 'callback absent';
+    }
+    return 'aucun brouillon';
+  }
+
   ProjectPathPreset? _basePathPresetForDraft(PathPatternDraft? draft) {
     if (draft == null) {
       return null;
@@ -482,11 +569,15 @@ class _PathStudioHeader extends StatelessWidget {
     required this.summary,
     required this.onCreateNewPathDraft,
     required this.onCreateLegacyDraft,
+    required this.onSavePressed,
+    required this.saveHint,
   });
 
   final PathPatternEditorSummary summary;
   final VoidCallback onCreateNewPathDraft;
   final VoidCallback onCreateLegacyDraft;
+  final VoidCallback? onSavePressed;
+  final String saveHint;
 
   @override
   Widget build(BuildContext context) {
@@ -573,10 +664,12 @@ class _PathStudioHeader extends StatelessWidget {
                   label: 'Dupliquer',
                   hint: 'lot futur',
                 ),
-                const _ShellActionButton(
+                _ShellActionButton(
                   icon: CupertinoIcons.floppy_disk,
                   label: 'Enregistrer',
-                  hint: 'lot futur',
+                  hint: saveHint,
+                  buttonKey: const Key('path-studio-save-button'),
+                  onPressed: onSavePressed,
                 ),
               ],
             ),
@@ -636,17 +729,20 @@ class _ShellActionButton extends StatelessWidget {
     required this.icon,
     required this.label,
     this.hint = 'lot futur',
+    this.buttonKey,
     this.onPressed,
   });
 
   final IconData icon;
   final String label;
   final String hint;
+  final Key? buttonKey;
   final VoidCallback? onPressed;
 
   @override
   Widget build(BuildContext context) {
     return CupertinoButton(
+      key: buttonKey,
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
       minimumSize: Size.zero,
       onPressed: onPressed,
@@ -1267,7 +1363,11 @@ class _CenterWorkspace extends StatelessWidget {
     required this.settings,
     required this.projectRootPath,
     required this.newPathDraft,
+    required this.newPathSavePlan,
     required this.draft,
+    required this.legacySavePlan,
+    required this.hasSaveCallback,
+    required this.saveFeedbackMessage,
     required this.selected,
     required this.hasAnyPreset,
     required this.onNewPathSizeChanged,
@@ -1282,7 +1382,11 @@ class _CenterWorkspace extends StatelessWidget {
   final ProjectSettings settings;
   final String? projectRootPath;
   final PathStudioNewPathDraft? newPathDraft;
+  final PathStudioNewPathSavePlan? newPathSavePlan;
   final PathPatternDraft? draft;
+  final PathStudioLegacyPathPatternSavePlan? legacySavePlan;
+  final bool hasSaveCallback;
+  final String? saveFeedbackMessage;
   final PathPatternPresetCardModel? selected;
   final bool hasAnyPreset;
   final void Function(int width, int height) onNewPathSizeChanged;
@@ -1295,12 +1399,14 @@ class _CenterWorkspace extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     final newPathDraft = this.newPathDraft;
-    if (newPathDraft != null) {
+    final newPathSavePlan = this.newPathSavePlan;
+    if (newPathDraft != null && newPathSavePlan != null) {
       return _NewPathCenterWorkspace(
         tilesets: tilesets,
         settings: settings,
         projectRootPath: projectRootPath,
         draft: newPathDraft,
+        savePlan: newPathSavePlan,
         onSizeChanged: onNewPathSizeChanged,
         onCellSelected: onNewPathCellSelected,
         onTileSelected: onNewPathTileSelected,
@@ -1308,9 +1414,13 @@ class _CenterWorkspace extends StatelessWidget {
       );
     }
     final draft = this.draft;
-    if (draft != null) {
+    final legacySavePlan = this.legacySavePlan;
+    if (draft != null && legacySavePlan != null) {
       return _DraftCenterWorkspace(
         draft: draft,
+        savePlan: legacySavePlan,
+        hasSaveCallback: hasSaveCallback,
+        saveFeedbackMessage: saveFeedbackMessage,
         onSizeChanged: onDraftSizeChanged,
         onCellSelected: onDraftCellSelected,
       );
@@ -1343,6 +1453,7 @@ class _NewPathCenterWorkspace extends StatelessWidget {
     required this.settings,
     required this.projectRootPath,
     required this.draft,
+    required this.savePlan,
     required this.onSizeChanged,
     required this.onCellSelected,
     required this.onTileSelected,
@@ -1353,6 +1464,7 @@ class _NewPathCenterWorkspace extends StatelessWidget {
   final ProjectSettings settings;
   final String? projectRootPath;
   final PathStudioNewPathDraft draft;
+  final PathStudioNewPathSavePlan savePlan;
   final void Function(int width, int height) onSizeChanged;
   final void Function(int localX, int localY) onCellSelected;
   final void Function(int sourceX, int sourceY) onTileSelected;
@@ -1382,6 +1494,8 @@ class _NewPathCenterWorkspace extends StatelessWidget {
           ),
           const SizedBox(height: 14),
           _NewPathDiagnosticsCard(draft: draft),
+          const SizedBox(height: 14),
+          _NewPathSaveStatusCard(plan: savePlan),
         ],
       ),
     );
@@ -2130,11 +2244,17 @@ class _NewPathDiagnosticsCard extends StatelessWidget {
 class _DraftCenterWorkspace extends StatelessWidget {
   const _DraftCenterWorkspace({
     required this.draft,
+    required this.savePlan,
+    required this.hasSaveCallback,
+    required this.saveFeedbackMessage,
     required this.onSizeChanged,
     required this.onCellSelected,
   });
 
   final PathPatternDraft draft;
+  final PathStudioLegacyPathPatternSavePlan savePlan;
+  final bool hasSaveCallback;
+  final String? saveFeedbackMessage;
   final void Function(int width, int height) onSizeChanged;
   final void Function(int localX, int localY) onCellSelected;
 
@@ -2159,6 +2279,12 @@ class _DraftCenterWorkspace extends StatelessWidget {
           ),
           const SizedBox(height: 14),
           _DraftDiagnosticsCard(draft: draft),
+          const SizedBox(height: 14),
+          _LegacyPathSaveStatusCard(
+            plan: savePlan,
+            hasSaveCallback: hasSaveCallback,
+            feedbackMessage: saveFeedbackMessage,
+          ),
         ],
       ),
     );
@@ -2489,6 +2615,174 @@ class _DraftDiagnosticsCard extends StatelessWidget {
   }
 }
 
+class _NewPathSaveStatusCard extends StatelessWidget {
+  const _NewPathSaveStatusCard({required this.plan});
+
+  final PathStudioNewPathSavePlan plan;
+
+  @override
+  Widget build(BuildContext context) {
+    return _SectionCard(
+      key: const Key('path-studio-save-status-card'),
+      title: 'Sauvegarde',
+      icon: CupertinoIcons.floppy_disk,
+      trailing: const _StatusChip(
+        label: 'Non sauvegardable',
+        color: PathStudioTheme.warning,
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Wrap(
+            spacing: 10,
+            runSpacing: 10,
+            children: [
+              const _InfoTile(
+                label: 'État',
+                value: 'Brouillon de nouveau chemin',
+              ),
+              _InfoTile(
+                label: 'Centre',
+                value: plan.isCenterReady ? 'Centre prêt' : 'Centre incomplet',
+              ),
+              const _InfoTile(
+                label: 'Sauvegarde',
+                value: 'Sauvegarde non disponible dans ce lot',
+              ),
+              _InfoTile(
+                label: 'Pattern proposé',
+                value: plan.proposedPathPatternPresetId,
+              ),
+            ],
+          ),
+          const SizedBox(height: 14),
+          const Text(
+            'Le centre peut être préparé localement, mais un nouveau chemin complet doit encore définir ses bords, coins et jonctions.',
+            style: TextStyle(
+              color: PathStudioTheme.textSecondary,
+              fontSize: 12,
+              height: 1.35,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 12),
+          _SaveIssueList(issues: plan.issues),
+        ],
+      ),
+    );
+  }
+}
+
+class _LegacyPathSaveStatusCard extends StatelessWidget {
+  const _LegacyPathSaveStatusCard({
+    required this.plan,
+    required this.hasSaveCallback,
+    required this.feedbackMessage,
+  });
+
+  final PathStudioLegacyPathPatternSavePlan plan;
+  final bool hasSaveCallback;
+  final String? feedbackMessage;
+
+  @override
+  Widget build(BuildContext context) {
+    final ready = plan.canSaveNow;
+    return _SectionCard(
+      key: const Key('path-studio-save-status-card'),
+      title: 'Sauvegarde',
+      icon: CupertinoIcons.floppy_disk,
+      trailing: _StatusChip(
+        label: ready ? 'Requête prête' : 'Bloquée',
+        color: ready ? PathStudioTheme.success : PathStudioTheme.warning,
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Wrap(
+            spacing: 10,
+            runSpacing: 10,
+            children: [
+              const _InfoTile(
+                label: 'État',
+                value: 'Motif PathPattern depuis path existant',
+              ),
+              _InfoTile(
+                label: 'ID proposé',
+                value: plan.proposedPathPatternPresetId,
+              ),
+              _InfoTile(label: 'Base', value: plan.basePathPresetId),
+              _InfoTile(
+                label: 'Action',
+                value: ready ? 'Requête prête' : 'À corriger',
+              ),
+            ],
+          ),
+          if (feedbackMessage != null) ...[
+            const SizedBox(height: 12),
+            _DiagnosticRow(
+              icon: CupertinoIcons.check_mark_circled_solid,
+              color: PathStudioTheme.success,
+              title: feedbackMessage!,
+              message:
+                  'Le callback a reçu le ProjectPathPatternPreset préparé. Le manifest reste inchangé.',
+            ),
+          ],
+          if (ready && !hasSaveCallback) ...[
+            const SizedBox(height: 12),
+            const _DiagnosticRow(
+              icon: CupertinoIcons.info_circle_fill,
+              color: PathStudioTheme.warning,
+              title: 'Callback de sauvegarde absent',
+              message:
+                  'La requête locale est prête, mais aucun callback externe ne l’utilise encore.',
+            ),
+          ],
+          if (plan.issues.isNotEmpty) ...[
+            const SizedBox(height: 12),
+            _SaveIssueList(issues: plan.issues),
+          ],
+        ],
+      ),
+    );
+  }
+}
+
+class _SaveIssueList extends StatelessWidget {
+  const _SaveIssueList({required this.issues});
+
+  final List<PathStudioSaveIssueCode> issues;
+
+  @override
+  Widget build(BuildContext context) {
+    if (issues.isEmpty) {
+      return const _DiagnosticRow(
+        icon: CupertinoIcons.check_mark_circled_solid,
+        color: PathStudioTheme.success,
+        title: 'Aucune issue de sauvegarde locale',
+        message: 'La préparation locale ne signale aucun blocage.',
+      );
+    }
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        for (final issue in issues)
+          Padding(
+            key: Key('path-studio-save-issue-${issue.name}'),
+            padding: const EdgeInsets.only(bottom: 8),
+            child: _DiagnosticRow(
+              icon: CupertinoIcons.exclamationmark_triangle_fill,
+              color: issue == PathStudioSaveIssueCode.pathVariantMappingRequired
+                  ? PathStudioTheme.warning
+                  : PathStudioTheme.accentCyan,
+              title: pathStudioSaveIssueLabel(issue),
+              message: pathStudioSaveIssueDescription(issue),
+            ),
+          ),
+      ],
+    );
+  }
+}
+
 class _NoSelectionCenter extends StatelessWidget {
   const _NoSelectionCenter({required this.hasAnyPreset});
 
@@ -3354,6 +3648,7 @@ class _InspectorEmptyState extends StatelessWidget {
 
 class _SectionCard extends StatelessWidget {
   const _SectionCard({
+    super.key,
     required this.title,
     required this.icon,
     required this.child,
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
index 1395a5aa..9146ee97 100644
--- a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
@@ -636,6 +636,155 @@ void main() {
       expect(saveButton.onPressed, isNull);
     });
 
+    testWidgets('new path save status explains missing path variant mapping',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+
+      expect(find.byKey(const Key('path-studio-save-status-card')),
+          findsOneWidget);
+      expect(find.text('Sauvegarde'), findsWidgets);
+      expect(find.text('Brouillon de nouveau chemin'), findsWidgets);
+      expect(find.text('Sauvegarde non disponible dans ce lot'), findsWidgets);
+      expect(find.text('Bords / coins / jonctions à définir'), findsWidgets);
+
+      final saveButton = tester.widget<CupertinoButton>(
+        find.byKey(const Key('path-studio-save-button')),
+      );
+      expect(saveButton.onPressed, isNull);
+    });
+
+    testWidgets('new path with complete center stays blocked for save',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await tester.pumpAndSettle();
+      await _tapNewPathTile(tester, tileX: 2, tileY: 1);
+
+      expect(find.text('Centre prêt'), findsWidgets);
+      expect(find.text('Cellules du centre à configurer'), findsNothing);
+      expect(find.text('Bords / coins / jonctions à définir'), findsWidgets);
+
+      final saveButton = tester.widget<CupertinoButton>(
+        find.byKey(const Key('path-studio-save-button')),
+      );
+      expect(saveButton.onPressed, isNull);
+    });
+
+    testWidgets('legacy save request is prepared but disabled without callback',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+        ),
+      );
+
+      await tester.tap(
+        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('path-studio-draft-name-field')),
+        'Motif eau',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('Motif PathPattern depuis path existant'), findsWidgets);
+      expect(find.text('Requête prête'), findsWidgets);
+      expect(find.text('Callback de sauvegarde absent'), findsWidgets);
+
+      final saveButton = tester.widget<CupertinoButton>(
+        find.byKey(const Key('path-studio-save-button')),
+      );
+      expect(saveButton.onPressed, isNull);
+    });
+
+    testWidgets('legacy save request calls callback without mutating manifest',
+        (tester) async {
+      final manifest = _manifest(
+        pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+      );
+      final captured = <ProjectPathPatternPreset>[];
+      await _pumpPathStudio(
+        tester,
+        manifest: manifest,
+        onPathPatternPresetSaveRequested: captured.add,
+      );
+
+      await tester.tap(
+        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('path-studio-draft-name-field')),
+        'Motif eau',
+      );
+      await tester.pumpAndSettle();
+
+      final saveButton = tester.widget<CupertinoButton>(
+        find.byKey(const Key('path-studio-save-button')),
+      );
+      expect(saveButton.onPressed, isNotNull);
+
+      await tester.tap(find.byKey(const Key('path-studio-save-button')));
+      await tester.pumpAndSettle();
+
+      expect(captured, hasLength(1));
+      expect(captured.single.id, 'motif-eau');
+      expect(captured.single.name, 'Motif eau');
+      expect(captured.single.basePathPresetId, 'legacy-water');
+      expect(manifest.pathPatternPresets, isEmpty);
+      expect(find.text('Requête de sauvegarde préparée'), findsWidgets);
+    });
+
+    testWidgets('legacy duplicate proposed id blocks save', (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+          pathPatternPresets: [
+            _pathPatternPreset(
+                id: 'motif-eau', basePathPresetId: 'legacy-water')
+          ],
+        ),
+      );
+
+      await tester.tap(
+        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('path-studio-draft-name-field')),
+        'Motif eau',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('ID PathPattern déjà utilisé'), findsWidgets);
+      final saveButton = tester.widget<CupertinoButton>(
+        find.byKey(const Key('path-studio-save-button')),
+      );
+      expect(saveButton.onPressed, isNull);
+    });
+
     testWidgets('secondary legacy flow changes inherited structure locally',
         (tester) async {
       await _pumpPathStudio(
@@ -723,6 +872,7 @@ Future<void> _pumpPathStudio(
   WidgetTester tester, {
   required ProjectManifest manifest,
   String? projectRootPath,
+  ValueChanged<ProjectPathPatternPreset>? onPathPatternPresetSaveRequested,
 }) async {
   await tester.binding.setSurfaceSize(const Size(1440, 920));
   addTearDown(() => tester.binding.setSurfaceSize(null));
@@ -737,6 +887,8 @@ Future<void> _pumpPathStudio(
               return PathStudioPanel(
                 manifest: manifest,
                 projectRootPath: projectRootPath,
+                onPathPatternPresetSaveRequested:
+                    onPathPatternPresetSaveRequested,
               );
             },
           ),
```

Le présent rapport est aussi un fichier créé. Son contenu complet est le document courant.

## 20. Limites connues

- `Nouveau chemin` ne sauvegarde pas encore un chemin complet, même avec centre prêt.
- Le slug V0 remplace les accents par des séparateurs au lieu de translittérer.
- Les collisions d'id sont bloquantes ; aucun suffixe automatique n'est généré.
- Le callback prépare une requête en mémoire ; il ne marque pas le draft comme sauvegardé.
- Le flux legacy peut préparer `ProjectPathPatternPreset`, mais aucune UI ne persiste encore la requête.

## 21. Auto-review

- Ai-je modifié `map_core` ? Non.
- Ai-je modifié `ProjectManifest` ? Non.
- Ai-je modifié les codecs PathPattern ? Non.
- Ai-je ajouté une sauvegarde réelle ? Non.
- Ai-je appelé les opérations d'upsert/replace manifest ? Non.
- Ai-je écrit un fichier projet ? Non.
- Ai-je ajouté un repository/service/provider complexe ? Non.
- Ai-je gardé `Nouveau chemin` non sauvegardable ? Oui.
- Ai-je préparé un `ProjectPathPatternPreset` pour legacy seulement ? Oui.
- Ai-je testé le callback optionnel ? Oui.
- Ai-je testé l'absence de mutation manifest ? Oui.
- Ai-je lancé les tests ciblés, régressions et analyze ? Oui.

## 22. Review séparée

Reviewer séparé : sub-agent `Pasteur`, lecture seule.

Synthèse :

- aucun finding de dérive de périmètre ;
- aucun diff `packages/map_core` ;
- changements repérés uniquement côté `map_editor` ;
- `PathStudioNewPathSavePlan.canSaveNow` reste toujours false ;
- le flux legacy appelle seulement le callback injecté ;
- aucune mutation manifest repérée ;
- tests ciblés save plan + panel passés côté reviewer : 31 tests.

## 23. Critique du prompt

Ce qui était clair :

- la frontière entre préparation locale et persistance réelle ;
- le statut particulier de `Nouveau chemin`, bloqué par le mapping des variants ;
- le cas legacy, qui peut honnêtement produire un `ProjectPathPatternPreset` ;
- les non-objectifs.

Ce qui était ambigu :

- le prompt mentionnait `project_path_preset.dart`, mais le type réel `ProjectPathPreset` vit dans `project_manifest.dart`.
- `duplicatePathPatternId` devait couvrir des collisions avec `pathPatternPresets.id` et `pathPresets.id`, alors que le nom de l'issue ne décrit pas parfaitement une collision côté `ProjectPathPreset`.
- Le niveau exact de contenu à inclure pour le rapport lui-même est circulaire : le rapport est un fichier créé et demander son contenu complet dans lui-même n'est pas une exigence techniquement bien définie.

Ce qui aurait pu être mieux borné :

- définir explicitement si la translittération des accents était attendue ou si un slug ASCII simple suffisait ;
- définir si le callback devait recevoir `ProjectPathPatternPreset` directement ou un wrapper local.

Exigences discutables :

- demander un Evidence Pack très volumineux pour un lot local court alourdit la review plus qu'il n'améliore le code ;
- demander les grosses régressions `map_core` alors que `map_core` n'est pas modifié est prudent mais redondant.

Le prompt a-t-il forcé quelque chose de non optimal ?

- Oui, partiellement : l'Evidence Pack très large augmente fortement la taille du rapport. Le choix d'inclure les sorties complètes des tests ciblés et les lignes finales exactes des régressions garde toutefois une preuve exploitable.

## 24. Prochaine étape recommandée

Lot suivant recommandé : brancher la vraie sauvegarde legacy derrière un handler externe contrôlé, probablement en deux étapes :

1. sauvegarde du flux `Depuis un path existant` via opération manifest existante, avec tests de mutation explicite ;
2. préparation du futur `ProjectPathPreset` complet pour `Nouveau chemin` quand les bords / coins / jonctions seront éditables.

## 25. Checklist finale

- [x] Audit initial réalisé.
- [x] Git utilisé uniquement en lecture.
- [x] Aucun commit / push / reset / restore / stash / checkout.
- [x] map_core non modifié.
- [x] ProjectManifest non modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Aucun save flow réel.
- [x] Aucune mutation manifest.
- [x] Aucune écriture disque projet.
- [x] Aucun repository/service ajouté.
- [x] Aucun painter.
- [x] Aucun runtime.
- [x] Aucun gameplay / battle.
- [x] Aucun tall grass.
- [x] Aucun Surface Studio / TSX / TMX.
- [x] Save plan local créé.
- [x] Nouveau chemin explique pourquoi il n'est pas encore sauvegardable.
- [x] Nouveau chemin complet côté centre produit un PathCenterPattern local.
- [x] Legacy draft produit une requête ProjectPathPatternPreset.
- [x] Bouton Enregistrer reste honnête selon l'état.
- [x] Callback optionnel testé.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.

## 26. Conclusion

Le Lot PathPattern-19 est fermable.

La préparation de sauvegarde est locale, testée et visible dans l'UI. Le flux `Nouveau chemin` ne prétend pas être sauvegardable tant que les variants complets du chemin manquent. Le flux `Depuis un path existant` peut préparer un `ProjectPathPatternPreset` et l'envoyer à un callback optionnel, sans mutation manifest.
