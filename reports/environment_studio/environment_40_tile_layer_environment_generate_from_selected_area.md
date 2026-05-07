# Environment-40 — TileLayer Environment Generate From Selected Area V0

## 1. Résumé

Environment-40 branche le bouton `Générer dans ce layer` dans le flow TileLayer-centric.

Ajouts principaux :

- un wrapper applicatif `GenerateTileLayerEnvironmentAreaPlacementsUseCase` ;
- une méthode notifier `generateEnvironmentAreaPlacementsForActiveTileLayer()` ;
- le wiring depuis `MapInspectorPanel` vers `TileLayerEnvironmentInspectorSection` ;
- l’activation contrôlée du bouton `Générer dans ce layer` ;
- des tests use case, notifier et widget ;
- une correction test-only d’un test legacy devenu fragile car le bouton testé était hors viewport.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector devient le lieu de peinture/génération.
- Ce lot ajoute seulement la génération depuis l’area sélectionnée du TileLayer actif.
- Pas de preview, pas de clear, pas de regenerate, pas de shuffle dans ce lot.

## 3. Audit de l’existant

Fichiers inspectés :

- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_regenerate_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/environment_generator_deterministic_core_test.dart`
- `packages/map_editor/test/environment_studio/environment_generator_apply_candidates_test.dart`
- `packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart`
- `packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fonctionnement legacy generate :

- `GenerateEnvironmentAreaPlacementsUseCase` génère des candidats depuis un `EnvironmentLayer` + `areaId`.
- Il utilise déjà `area.paramsOverride ?? preset.defaultParams`.
- Il utilise déjà `area.seed`.
- Il retourne des warnings pour masque vide / zéro candidat, sans mutation.
- `ApplyEnvironmentGeneratedPlacementsUseCase` transforme les candidats en `MapPlacedElement`.
- `ApplyEnvironmentGeneratedPlacementsUseCase` écrit `generatedPlacementIds` dans l’area.
- Le target `TileLayer` vient de `EnvironmentLayerContent.targetTileLayerId`.

Sémantique des placements existants :

- Le flow apply existant refuse `areaAlreadyHasGeneratedPlacements`.
- Environment-40 garde cette sémantique : il ne remplace pas et n’accumule pas les placements existants.
- Les placements manuels qui ne sont pas dans `generatedPlacementIds` sont préservés.

## 4. Use case TileLayer-centric

Nom :

```text
GenerateTileLayerEnvironmentAreaPlacementsUseCase
```

Entrées :

```text
MapData map
ProjectManifest manifest
String tileLayerId
String areaId
```

Sortie :

```text
GenerateTileLayerEnvironmentAreaPlacementsResult
- map
- tileLayerId
- environmentLayerId
- areaId
- generatedPlacementIds
- generatedPlacementCount
```

Validations :

- `tileLayerId` non vide ;
- layer actif existant ;
- layer actif de type `TileLayer` ;
- `EnvironmentLayer` attaché via `targetTileLayerId` ;
- `areaId` non vide ;
- area existante dans l’EnvironmentLayer attaché ;
- preset existant ;
- masque non vide ;
- pas de `generatedPlacementIds` existants.

Résolution :

```text
TileLayer actif
→ EnvironmentLayer attaché
→ EnvironmentArea sélectionnée
→ EnvironmentPreset
→ GenerateEnvironmentAreaPlacementsUseCase
→ ApplyEnvironmentGeneratedPlacementsUseCase
```

Le wrapper ne réécrit pas le générateur. Les paramètres effectifs et le seed sont ceux du générateur legacy : `area.paramsOverride ?? preset.defaultParams` et `area.seed`.

## 5. Notifier

Méthode ajoutée :

```text
generateEnvironmentAreaPlacementsForActiveTileLayer()
```

Conditions :

- carte active présente ;
- manifeste projet présent ;
- `activeLayerId` présent et TileLayer ;
- `selectedEnvironmentAreaId` présent ;
- wrapper TileLayer-centric valide la cible, l’area, le preset, le masque.

Effets :

- applique la map générée via `_applyMapMutation` quand des placements sont produits ;
- garde `activeLayerId` sur le TileLayer ;
- garde `selectedEnvironmentAreaId` stable ;
- remet `environmentMaskEditMode` à `null` ;
- renseigne `statusMessage` avec le nombre généré ;
- renseigne `errorMessage` en cas de refus ;
- ne sauvegarde pas disque.

Cas zéro candidat :

- la map n’est pas mutée ;
- `environmentMaskEditMode` passe à `null` ;
- status : `Aucun placement généré pour cette zone.`

## 6. Intégration UI

`TileLayerEnvironmentInspectorSection` accepte maintenant :

```dart
VoidCallback? onGenerateEnvironment
```

Le bouton `Générer dans ce layer` :

- est visible quand le masque est éditable ou générable ;
- est actif uniquement si `readModel.canGenerate == true`, `readModel.hasErrors == false` et callback non nul ;
- reste grisé si `canGenerate == false`, par exemple masque vide ;
- déclenche uniquement le callback, sans logique métier dans le widget.

`MapInspectorPanel` fournit le callback seulement si :

- le layer actif est un `TileLayer` ;
- le read model existe ;
- `canGenerate == true` ;
- `hasErrors == false` ;
- `selectedEnvironmentAreaId != null`.

Actions non branchées dans ce lot :

- `Effacer les placements générés` ;
- regenerate ;
- shuffle ;
- preview.

## 7. Tests

Commandes lancées et résultats exacts :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_generate_use_case_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_generate_use_case_test.dart
00:00 +0: GenerateTileLayerEnvironmentAreaPlacementsUseCase génère des placements depuis le TileLayer ciblé
00:00 +1: GenerateTileLayerEnvironmentAreaPlacementsUseCase refuse les entrées invalides sans créer de placement
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_generate_notifier_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart
00:00 +0: EditorNotifier TileLayer environment generation génère les placements et garde la sélection TileLayer stable
00:00 +1: EditorNotifier TileLayer environment generation refuse si aucun TileLayer actif
00:00 +2: EditorNotifier TileLayer environment generation refuse si aucune area est sélectionnée
00:00 +3: EditorNotifier TileLayer environment generation refuse masque vide et preset manquant sans mutation
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

```text
00:01 +34: All tests passed!
```

Non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

```text
00:00 +27: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_selection_test.dart
```

```text
00:00 +5: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_settings_use_case_test.dart
```

```text
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_settings_notifier_test.dart
```

```text
00:00 +6: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generator_deterministic_core_test.dart
```

```text
00:00 +22: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generator_apply_candidates_test.dart
```

```text
00:00 +14: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generate_button_wiring_test.dart
```

Première exécution :

```text
00:02 +8 -1: Lot 25 — EnvironmentLayerInspectorPanel Generate clic Générer : placements + bouton désactivé ensuite [E]
Expected: non-empty
  Actual: []
Warning: A call to tap() ... Offset(220.0, 1647.0) is outside the bounds of the root of the render tree, Size(520.0, 1100.0).
00:02 +9 -1: Some tests failed.
```

Cause racine :

- le bouton legacy existait et `onPressed` était non nul ;
- le tap tombait hors écran à cause d’une position `y=1647` dans un viewport de hauteur `1100` ;
- le test ne scrollait pas vers le bouton.

Correctif test-only :

```dart
await tester.ensureVisible(genFinder);
await tester.pumpAndSettle();
```

Nouvelle exécution :

```text
00:01 +10: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

```text
00:00 +6: All tests passed!
```

Cas couverts :

- génération depuis TileLayer actif ;
- placements générés avec `layerId = TileLayer.id` ;
- `generatedPlacementIds` mis à jour ;
- mask préservé ;
- `paramsOverride` préservé ;
- seed préservé ;
- preset global préservé ;
- placements manuels préservés ;
- refus `tileLayerId` vide ;
- refus TileLayer introuvable ;
- refus layer non TileLayer ;
- refus absence d’EnvironmentLayer attaché ;
- refus `areaId` vide ;
- refus area introuvable ;
- refus preset manquant ;
- refus masque vide ;
- refus area déjà générée ;
- notifier garde TileLayer sélectionné ;
- notifier garde `selectedEnvironmentAreaId` stable ;
- notifier remet `environmentMaskEditMode` à `null` ;
- widget active/désactive correctement `Générer dans ce layer`.

## 8. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_generate_use_case_test.dart test/environment_studio/tile_layer_environment_generate_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_generate_button_wiring_test.dart
```

Résultat exact :

```text
Analyzing 8 items...
No issues found! (ran in 3.0s)
```

Dette préexistante hors lot : aucune détectée par cette analyse ciblée.

## 9. Fichiers créés/modifiés

Fichiers préexistants dans le worktree avant Environment-40 :

```text
Aucun. Le git status initial était vide.
```

Fichiers créés par Environment-40 :

```text
packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart
packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_generate_use_case_test.dart
reports/environment_studio/environment_40_tile_layer_environment_generate_from_selected_area.md
```

Fichiers modifiés par Environment-40 :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

## 10. Non-objectifs respectés

- Pas de preview.
- Pas de clear.
- Pas de regenerate.
- Pas de shuffle.
- Pas de modification du mask.
- Pas de modification des params locaux.
- Pas de modification du preset global.
- Pas de création d’area.
- Pas de suppression/renommage d’area.
- Pas de migration.
- Pas de modification de `map_core`.
- Pas de modification runtime.
- Pas de modification gameplay.
- Pas de modification battle.
- Pas de build_runner.
- Pas de generated files.
- Pas de sauvegarde disque.

## 11. Evidence pack

### Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat :

```text

```

### Diff stat

Commande :

```bash
git diff --stat
```

Résultat :

```text
 .../src/features/editor/state/editor_notifier.dart | 73 ++++++++++++++++++++++
 .../lib/src/ui/panels/map_inspector_panel.dart     |  9 +++
 .../tile_layer_environment_inspector_section.dart  | 19 +++---
 .../environment_generate_button_wiring_test.dart   |  2 +
 ...e_layer_environment_inspector_section_test.dart | 62 +++++++++++++++++-
 5 files changed, 156 insertions(+), 9 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Ils sont listés par `git status` et `git ls-files --others --exclude-standard`.

### Diff name-only

Commande :

```bash
git diff --name-only
```

Résultat :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Commande :

```bash
git ls-files --others --exclude-standard
```

Résultat :

```text
packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart
packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_generate_use_case_test.dart
reports/environment_studio/environment_40_tile_layer_environment_generate_from_selected_area.md
```

### Git diff check

Commande :

```bash
git diff --check
```

Résultat :

```text

```

### Commandes principales

```bash
git status --short --untracked-files=all
rg -n "generateEnvironmentAreaPlacements|GenerateEnvironmentAreaPlacementsUseCase|ApplyEnvironmentGeneratedPlacementsUseCase|EnvironmentGeneratedPlacement|generatedPlacementIds|canGenerate|EnvironmentAreaGenerationReadiness|paramsOverride|defaultParams|seed|targetTileLayerId|MapPlacedElement" packages/map_core/lib/src packages/map_editor/lib/src packages/map_editor/test/environment_studio
dart format packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart packages/map_editor/test/environment_studio/tile_layer_environment_generate_use_case_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_generate_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_generate_notifier_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
flutter test test/environment_studio/tile_layer_environment_area_selection_test.dart
flutter test test/environment_studio/tile_layer_environment_area_settings_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_area_settings_notifier_test.dart
flutter test test/environment_studio/environment_generator_deterministic_core_test.dart
flutter test test/environment_studio/environment_generator_apply_candidates_test.dart
flutter test test/environment_studio/environment_generate_button_wiring_test.dart
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
flutter analyze lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_generate_use_case_test.dart test/environment_studio/tile_layer_environment_generate_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_generate_button_wiring_test.dart
git diff --check
git diff --stat
git diff --name-only
git ls-files --others --exclude-standard
git status --short --untracked-files=all
```

## 12. Diff pertinent

### Nouveau use case

`packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart`

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'environment_generator_apply_use_cases.dart';
import 'environment_generator_use_cases.dart';

final class GenerateTileLayerEnvironmentAreaPlacementsResult {
  const GenerateTileLayerEnvironmentAreaPlacementsResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.generatedPlacementIds,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final List<String> generatedPlacementIds;

  int get generatedPlacementCount => generatedPlacementIds.length;
}

class GenerateTileLayerEnvironmentAreaPlacementsUseCase {
  GenerateTileLayerEnvironmentAreaPlacementsResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String tileLayerId,
    required String areaId,
  }) {
    final target = _resolveTarget(
      map,
      manifest: manifest,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );

    final generation = GenerateEnvironmentAreaPlacementsUseCase().execute(
      map,
      manifest: manifest,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
    );
    if (generation.hasErrors) {
      throw EditorValidationException(_firstGenerationError(generation));
    }
    if (generation.placements.isEmpty) {
      return GenerateTileLayerEnvironmentAreaPlacementsResult(
        map: map,
        tileLayerId: target.tileLayer.id,
        environmentLayerId: target.environmentLayer.id,
        areaId: target.area.id,
        generatedPlacementIds: const [],
      );
    }

    final apply = ApplyEnvironmentGeneratedPlacementsUseCase().execute(
      map,
      manifest: manifest,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      candidates: generation.placements,
    );
    if (apply.hasErrors) {
      throw EditorValidationException(_firstApplyError(apply));
    }

    return GenerateTileLayerEnvironmentAreaPlacementsResult(
      map: apply.map,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      generatedPlacementIds: [
        for (final placement in apply.appliedPlacements)
          placement.placedElementId,
      ],
    );
  }
}

_TileLayerEnvironmentGenerationTarget _resolveTarget(
  MapData map, {
  required ProjectManifest manifest,
  required String tileLayerId,
  required String areaId,
}) {
  final tid = tileLayerId.trim();
  if (tid.isEmpty) {
    throw const EditorValidationException('Tile layer id cannot be empty');
  }
  final aid = areaId.trim();
  if (aid.isEmpty) {
    throw const EditorValidationException(
      'Environment area id cannot be empty',
    );
  }

  final layer = _findLayerById(map, tid);
  if (layer == null) {
    throw EditorValidationException('Tile layer not found: $tid');
  }
  if (layer is! TileLayer) {
    throw EditorValidationException('Layer is not a TileLayer: $tid');
  }

  final environmentLayer = _firstEnvironmentLayerTargeting(map, tid);
  if (environmentLayer == null) {
    throw const EditorValidationException(
      'Activez d’abord l’environnement sur ce layer.',
    );
  }

  final area = environmentLayer.content.areaById(aid);
  if (area == null) {
    throw EditorValidationException('Environment area not found: $aid');
  }

  final preset = _presetById(manifest, area.presetId);
  if (preset == null) {
    throw EditorValidationException(
      'Environment preset not found: ${area.presetId.trim()}',
    );
  }
  if (area.mask.activeCellCount == 0) {
    throw const EditorValidationException(
      'Masque vide : peignez une zone sur la carte avant de générer.',
    );
  }
  if (area.generatedPlacementIds.isNotEmpty) {
    throw const EditorValidationException(
      'Cette zone possède déjà des placements générés.',
    );
  }

  return _TileLayerEnvironmentGenerationTarget(
    tileLayer: layer,
    environmentLayer: environmentLayer,
    area: area,
  );
}
MapLayer? _findLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) return layer;
  }
  return null;
}

EnvironmentLayer? _firstEnvironmentLayerTargeting(
  MapData map,
  String tileLayerId,
) {
  for (final layer in map.layers) {
    if (layer is EnvironmentLayer &&
        layer.content.targetTileLayerId?.trim() == tileLayerId) {
      return layer;
    }
  }
  return null;
}

EnvironmentPreset? _presetById(ProjectManifest manifest, String presetId) {
  final pid = presetId.trim();
  for (final preset in manifest.environmentPresets) {
    if (preset.id == pid) return preset;
  }
  return null;
}

String _firstGenerationError(EnvironmentGenerationResult result) {
  final issue = result.issues.firstWhere(
    (issue) => issue.severity == EnvironmentGenerationIssueSeverity.error,
    orElse: () => result.issues.first,
  );
  return issue.message;
}

String _firstApplyError(EnvironmentApplyResult result) {
  final issue = result.issues.firstWhere(
    (issue) => issue.severity == EnvironmentApplyIssueSeverity.error,
    orElse: () => result.issues.first,
  );
  return issue.message;
}

final class _TileLayerEnvironmentGenerationTarget {
  const _TileLayerEnvironmentGenerationTarget({
    required this.tileLayer,
    required this.environmentLayer,
    required this.area,
  });

  final TileLayer tileLayer;
  final EnvironmentLayer environmentLayer;
  final EnvironmentArea area;
}
```

### EditorNotifier

```diff
+  void generateEnvironmentAreaPlacementsForActiveTileLayer() {
+    final map = state.activeMap;
+    final manifest = state.project;
+    if (map == null || manifest == null) {
+      state = state.copyWith(
+        errorMessage:
+            'Impossible de générer : aucune carte active ou manifeste projet.',
+      );
+      return;
+    }
+    final layerId = state.activeLayerId?.trim();
+    if (layerId == null || layerId.isEmpty) {
+      state = state.copyWith(
+        errorMessage: 'Sélectionnez un TileLayer pour générer cette zone.',
+      );
+      return;
+    }
+    final activeLayer = _findLayerById(map, layerId);
+    if (activeLayer is! TileLayer) {
+      state = state.copyWith(
+        errorMessage: 'Sélectionnez un TileLayer pour générer cette zone.',
+      );
+      return;
+    }
+    final areaId = state.selectedEnvironmentAreaId?.trim();
+    if (areaId == null || areaId.isEmpty) {
+      state = state.copyWith(
+        errorMessage: 'Sélectionnez une zone d’environnement avant de générer.',
+      );
+      return;
+    }
+
+    try {
+      final result =
+          GenerateTileLayerEnvironmentAreaPlacementsUseCase().execute(
+        map,
+        manifest: manifest,
+        tileLayerId: layerId,
+        areaId: areaId,
+      );
+      if (result.generatedPlacementCount == 0) {
+        state = state.copyWith(
+          activeLayerId: result.tileLayerId,
+          selectedEnvironmentAreaId: result.areaId,
+          environmentMaskEditMode: null,
+          statusMessage: 'Aucun placement généré pour cette zone.',
+          errorMessage: null,
+        );
+        return;
+      }
+
+      final count = result.generatedPlacementCount;
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: result.map,
+        preferredActiveLayerId: result.tileLayerId,
+        statusMessage:
+            '$count placement(s) généré(s) dans ce layer pour la zone « ${result.areaId} ».',
+      );
+      state = state.copyWith(
+        activeLayerId: result.tileLayerId,
+        selectedEnvironmentAreaId: result.areaId,
+        environmentMaskEditMode: null,
+        errorMessage: null,
+      );
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Impossible de générer cette zone : $e',
+      );
+    }
+  }
```

### MapInspectorPanel

```diff
+    final canGenerateTileLayerEnvironment = activeLayer is TileLayer &&
+        tileLayerEnvironmentReadModel != null &&
+        tileLayerEnvironmentReadModel.canGenerate &&
+        !tileLayerEnvironmentReadModel.hasErrors &&
+        state.selectedEnvironmentAreaId != null;
...
+                    onGenerateEnvironment: canGenerateTileLayerEnvironment
+                        ? notifier
+                            .generateEnvironmentAreaPlacementsForActiveTileLayer
+                        : null,
```

### TileLayerEnvironmentInspectorSection

```diff
+  final VoidCallback? onGenerateEnvironment;
...
-    if (readModel.canGenerate) {
+    if (readModel.canGenerate || readModel.canPaintMask) {
       actions.add(
-        const _ActionData(
+        _ActionData(
           icon: CupertinoIcons.play,
           label: 'Générer dans ce layer',
+          enabled: readModel.canGenerate &&
+              !readModel.hasErrors &&
+              onGenerateEnvironment != null,
+          onPressed: readModel.canGenerate ? onGenerateEnvironment : null,
         ),
       );
     }
```

### Tests use case

Sections comportementales ajoutées dans `tile_layer_environment_generate_use_case_test.dart` :

```dart
test('génère des placements depuis le TileLayer ciblé', () {
  final map = _map();
  final manifest = _manifest();
  final result = GenerateTileLayerEnvironmentAreaPlacementsUseCase()
      .execute(map, manifest: manifest, tileLayerId: 'tiles', areaId: 'area');

  expect(result.tileLayerId, 'tiles');
  expect(result.environmentLayerId, 'env');
  expect(result.areaId, 'area');
  expect(result.generatedPlacementCount, greaterThan(0));
  expect(result.generatedPlacementIds, isNotEmpty);

  final outArea = _areaById(result.map, 'area');
  expect(outArea.generatedPlacementIds, result.generatedPlacementIds);
  expect(outArea.mask, _areaById(map, 'area').mask);
  expect(outArea.paramsOverride, _overrideParams);
  expect(outArea.seed, 7);
  expect(manifest.environmentPresets.single.defaultParams, _defaultParams);
});
```

```dart
test('refuse les entrées invalides sans créer de placement', () {
  final useCase = GenerateTileLayerEnvironmentAreaPlacementsUseCase();
  final manifest = _manifest();
  final map = _map();

  expect(() => useCase.execute(map, manifest: manifest, tileLayerId: '', areaId: 'area'), throwsA(isA<EditorValidationException>()));
  expect(() => useCase.execute(map, manifest: manifest, tileLayerId: 'missing', areaId: 'area'), throwsA(isA<EditorValidationException>()));
  expect(() => useCase.execute(_mapWithNonTileActiveLayer(), manifest: manifest, tileLayerId: 'tiles', areaId: 'area'), throwsA(isA<EditorValidationException>()));
  expect(() => useCase.execute(_mapWithoutEnvironmentAttachment(), manifest: manifest, tileLayerId: 'tiles', areaId: 'area'), throwsA(isA<EditorValidationException>()));
  expect(() => useCase.execute(map, manifest: manifest, tileLayerId: 'tiles', areaId: ''), throwsA(isA<EditorValidationException>()));
  expect(() => useCase.execute(map, manifest: manifest, tileLayerId: 'tiles', areaId: 'missing'), throwsA(isA<EditorValidationException>()));
  expect(() => useCase.execute(_map(areaPresetId: 'missing'), manifest: manifest, tileLayerId: 'tiles', areaId: 'area'), throwsA(isA<EditorValidationException>()));
  expect(() => useCase.execute(_map(cells: List<bool>.filled(4, false)), manifest: manifest, tileLayerId: 'tiles', areaId: 'area'), throwsA(isA<EditorValidationException>()));
  expect(() => useCase.execute(_map(generatedPlacementIds: const ['old']), manifest: manifest, tileLayerId: 'tiles', areaId: 'area'), throwsA(isA<EditorValidationException>()));
  expect(map.placedElements.length, 1);
});
```

Les fixtures de ce fichier construisent une map 2x2 avec un `TileLayer` `tiles`, un `EnvironmentLayer` `env` attaché, deux areas, un preset `forest`, un élément `tree`, un placement manuel `manual`, un mask actif et des variantes invalides.

### Tests notifier

Sections comportementales ajoutées dans `tile_layer_environment_generate_notifier_test.dart` :

```dart
test('génère les placements et garde la sélection TileLayer stable', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(editorNotifierProvider.notifier);
  final map = _map();
  notifier.state = EditorState(
    project: _manifest(),
    activeMap: map,
    activeLayerId: 'tiles',
    selectedEnvironmentAreaId: 'area',
    environmentMaskEditMode: EnvironmentMaskEditMode.paint,
    savedMapSnapshot: map,
  );

  notifier.generateEnvironmentAreaPlacementsForActiveTileLayer();

  final state = notifier.state;
  expect(state.activeMap, isNot(same(map)));
  expect(state.activeLayerId, 'tiles');
  expect(state.selectedEnvironmentAreaId, 'area');
  expect(state.environmentMaskEditMode, isNull);
  expect(state.errorMessage, isNull);
  expect(state.statusMessage, contains('placement'));
  expect(state.isDirty, isTrue);
});
```

```dart
test('refuse si aucun TileLayer actif', () { ... });
test('refuse si aucune area est sélectionnée', () { ... });
test('refuse masque vide et preset manquant sans mutation', () { ... });
```

Les assertions de refus vérifient que `activeMap` reste identique, que la sélection reste stable, et qu’un message d’erreur clair est présent.

### Tests widget

```diff
+    testWidgets('Générer dans ce layer est actif avec callback',
+        (tester) async {
+      var generated = 0;
+      await _pump(
+        tester,
+        const TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.ready,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaName: 'Bosquet nord',
+          selectedPresetName: 'Forêt',
+          maskActiveCellCount: 42,
+          hasMask: true,
+          canPaintMask: true,
+          canGenerate: true,
+          emptyStateTitle: 'Prêt à générer',
+          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
+        ),
+        onGenerateEnvironment: () {
+          generated++;
+        },
+      );
+
+      expect(find.text('Générer dans ce layer'), findsOneWidget);
+      expect(_buttonFor(tester, 'Générer dans ce layer').onPressed, isNotNull);
+
+      await tester.tap(find.text('Générer dans ce layer'));
+      await tester.pump();
+
+      expect(generated, 1);
+    });
```

```diff
+    testWidgets('Générer dans ce layer reste désactivé si canGenerate false',
+        (tester) async {
+      await _pump(
+        tester,
+        const TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.emptyMask,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaName: 'Bosquet nord',
+          selectedPresetName: 'Forêt',
+          maskActiveCellCount: 0,
+          hasMask: false,
+          canPaintMask: true,
+          canGenerate: false,
+          emptyStateTitle: 'Masque vide',
+          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
+        ),
+        onGenerateEnvironment: () {},
+      );
+
+      expect(find.text('Générer dans ce layer'), findsOneWidget);
+      expect(_buttonFor(tester, 'Générer dans ce layer').onPressed, isNull);
+    });
```

### Test legacy stabilisé

```diff
       final genFinder = find.byKey(const Key('env-area-generate-area1'));
       expect(tester.widget<PushButton>(genFinder).onPressed, isNotNull);
+      await tester.ensureVisible(genFinder);
+      await tester.pumpAndSettle();
       await tester.tap(genFinder);
```

## 13. Auto-review

- Le bouton generate est-il actif seulement quand l’area est prête ? Oui.
- La génération utilise-t-elle l’area sélectionnée ? Oui, via `selectedEnvironmentAreaId`.
- La génération utilise-t-elle le TileLayer actif comme cible ? Oui, via `tileLayerId` actif et l’EnvironmentLayer attaché.
- La génération respecte-t-elle `paramsOverride ?? preset.defaultParams` ? Oui, via le générateur existant.
- La génération utilise-t-elle `area.seed` ? Oui, via le générateur existant.
- `generatedPlacementIds` est-il mis à jour ? Oui.
- Les `MapPlacedElement` générés existent-ils dans `map.placedElements` ? Oui, testé.
- `activeLayerId` reste-t-il le TileLayer ? Oui.
- `selectedEnvironmentAreaId` reste-t-il stable ? Oui.
- `environmentMaskEditMode` devient-il `null` ? Oui.
- Les placements manuels sont-ils préservés ? Oui.
- Aucune sauvegarde disque n’est-elle faite ? Oui.
- Le flow legacy reste-t-il intact ? Oui, non-régressions relancées.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 14. Critique du prompt et du lot

Clair :

- les sources de vérité étaient bien définies ;
- le non-scope était net : pas de preview, pas de clear, pas de regenerate, pas de shuffle ;
- la règle `paramsOverride ?? preset.defaultParams` et `area.seed` était explicite ;
- la stabilité TileLayer / selected area / arrêt mask edit était testable.

Ambigu :

- la sémantique de remplacement des placements existants demandait un audit. Le legacy refuse déjà une area avec `generatedPlacementIds`, donc ce lot s’aligne dessus.
- le wording “le bouton reste désactivé si canGenerate=false” peut vouloir dire visible ou absent. Le choix retenu est visible et grisé dès que le masque est éditable, car c’est plus explicite pour l’utilisateur.

À trancher avant Environment-41 :

- confirmer que `Effacer les placements générés` doit supprimer uniquement les IDs de l’area sélectionnée ;
- confirmer si Environment-41 doit ensuite permettre generate après clear dans le même flow TileLayer-centric ;
- décider si le message “Cette zone possède déjà des placements générés” doit être exposé dans l’inspector avant clic ou seulement via erreur notifier.

## 15. Verdict

```text
Environment-40 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-41 — TileLayer Environment Clear Generated Placements V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/switch/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié le modèle persistant.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement la génération depuis l’area sélectionnée.
- [x] Je n’ai pas ajouté de preview.
- [x] Je n’ai pas ajouté clear/regenerate/shuffle.
- [x] Je n’ai pas modifié le mask.
- [x] Je n’ai pas modifié les params locaux.
- [x] Je n’ai pas modifié le preset global.
- [x] Le TileLayer reste sélectionné.
- [x] selectedEnvironmentAreaId reste stable.
- [x] environmentMaskEditMode devient null après génération.
- [x] Les placements manuels sont préservés.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.

## Commande finale obligatoire

Commande :

```bash
git status --short --untracked-files=all
```

Résultat final exact :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_generate_use_case_test.dart
?? reports/environment_studio/environment_40_tile_layer_environment_generate_from_selected_area.md
```
