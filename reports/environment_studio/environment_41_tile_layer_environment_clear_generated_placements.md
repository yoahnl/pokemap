# Environment-41 — TileLayer Environment Clear Generated Placements V0

## 1. Résumé

Environment-41 active `Effacer les placements générés` depuis la section TileLayer-centric.

Ajouts :

- `ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase` ;
- `EditorNotifier.clearEnvironmentGeneratedPlacementsForActiveTileLayer()` ;
- wiring `MapInspectorPanel` → `TileLayerEnvironmentInspectorSection` ;
- bouton clear actif seulement quand l’area sélectionnée a des `generatedPlacementIds` et un callback ;
- tests ciblés use case, notifier, widget ;
- rapport Evidence Pack.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector devient le lieu de peinture/génération.
- Ce lot ajoute seulement l’effacement des placements générés.
- Pas de regenerate, shuffle, preview ou génération dans ce lot.

## 3. Audit de l’existant

Fichiers inspectés :

- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/environment_generated_placements_clear_test.dart`
- `packages/map_editor/test/environment_studio/environment_generator_apply_candidates_test.dart`
- `packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_generate_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_generate_notifier_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Flow clear legacy :

- `ClearEnvironmentGeneratedPlacementsUseCase` reçoit `environmentLayerId` + `areaId`.
- Il supprime uniquement les `MapPlacedElement` dont l’id est dans `area.generatedPlacementIds`.
- Il vide `area.generatedPlacementIds`.
- Il préserve masque, seed, `paramsOverride`, `presetId`, autres areas et placements non référencés.
- Il accepte les IDs manquants : warning `missingGeneratedPlacement`, nettoyage des références quand même.
- Si `generatedPlacementIds` est vide : résultat no-op, map inchangée, warning `noGeneratedPlacements`.

Read model :

- `canClearGeneratedPlacements` existe déjà.
- Il est vrai quand `generatedPlacementCount > 0`.
- `missingGeneratedPlacementCount` est calculé depuis les IDs absents de `map.placedElements`.

## 4. Use case TileLayer-centric

Nom :

```text
ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase
```

Entrées :

```text
MapData map
String tileLayerId
String areaId
```

Sortie :

```text
ClearTileLayerEnvironmentAreaGeneratedPlacementsResult
- map
- tileLayerId
- environmentLayerId
- areaId
- removedPlacementIds
- removedPlacementCount
- clearedReferenceCount
```

Validation :

- `tileLayerId` non vide ;
- layer existant ;
- layer de type `TileLayer` ;
- EnvironmentLayer attaché trouvé via `targetTileLayerId` ;
- `areaId` non vide ;
- area existante.

Comportement :

- `generatedPlacementIds` vide : no-op clair, map inchangée, compteurs à 0.
- Sinon, appelle `ClearEnvironmentGeneratedPlacementsUseCase`.
- `removedPlacementCount` = nombre de `MapPlacedElement` réellement supprimés.
- `clearedReferenceCount` = nombre de références présentes avant clear, y compris les références mortes.
- Le wrapper ne réécrit pas la logique legacy de suppression.

## 5. Notifier

Méthode ajoutée :

```text
clearEnvironmentGeneratedPlacementsForActiveTileLayer()
```

Conditions :

- carte active présente ;
- `activeLayerId` présent et TileLayer ;
- `selectedEnvironmentAreaId` présent ;
- wrapper TileLayer-centric valide l’EnvironmentLayer attaché et l’area.

Effets :

- applique la map via `_applyMapMutation` quand des références sont nettoyées ;
- garde `activeLayerId` sur le TileLayer ;
- garde `selectedEnvironmentAreaId` stable ;
- remet `environmentMaskEditMode` à `null` ;
- nettoie `selectedPlacedElementInstanceId` si la sélection pointait vers un placement supprimé ;
- renseigne `statusMessage` avec placements supprimés et références manquantes ;
- renseigne `errorMessage` en cas de refus ;
- ne sauvegarde pas disque.

## 6. Intégration UI

`TileLayerEnvironmentInspectorSection` accepte maintenant :

```dart
VoidCallback? onClearGeneratedPlacements
```

Le bouton `Effacer les placements générés` :

- est visible quand le masque est éditable ou quand un clear est possible ;
- est actif uniquement si `readModel.canClearGeneratedPlacements == true`, `hasErrors == false`, callback non nul ;
- reste grisé sans callback ou sans `generatedPlacementIds` ;
- ne déclenche pas regenerate / shuffle / preview.

`MapInspectorPanel` passe le callback seulement si :

- le layer actif est un `TileLayer` ;
- le read model existe ;
- `canClearGeneratedPlacements == true` ;
- `hasErrors == false` ;
- `selectedEnvironmentAreaId != null`.

## 7. Tests

RED initial :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_clear_use_case_test.dart test/environment_studio/tile_layer_environment_clear_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat attendu observé :

```text
Error when reading 'lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart': No such file or directory
Method not found: 'ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase'
The method 'clearEnvironmentGeneratedPlacementsForActiveTileLayer' isn't defined for the type 'EditorNotifier'
No named parameter with the name 'onClearGeneratedPlacements'
00:00 +0 -3: Some tests failed.
```

Commandes ciblées finales :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_clear_use_case_test.dart
```

```text
00:00 +0: ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase efface les placements générés de l’area ciblée seulement
00:00 +1: ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase generatedPlacementIds vide retourne un no-op clair
00:00 +2: ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase refuse les entrées invalides sans mutation
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_clear_notifier_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
00:00 +0: EditorNotifier TileLayer environment clear efface les placements générés et garde la sélection TileLayer stable
00:00 +1: EditorNotifier TileLayer environment clear refuse si aucun TileLayer actif
00:00 +2: EditorNotifier TileLayer environment clear refuse si aucune area est sélectionnée
00:00 +3: EditorNotifier TileLayer environment clear aucun generatedPlacementId ne mute pas la MapData
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

```text
00:01 +36: All tests passed!
```

Non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_generate_use_case_test.dart
```

```text
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_generate_notifier_test.dart
```

```text
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

```text
00:00 +27: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generated_placements_clear_test.dart
```

```text
00:00 +14: All tests passed!
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
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

```text
00:00 +6: All tests passed!
```

Cas couverts :

- clear supprime les placements référencés par l’area sélectionnée ;
- clear vide `generatedPlacementIds` ;
- clear préserve les placements manuels ;
- clear préserve les placements d’une autre area ;
- clear préserve mask, `paramsOverride`, seed, `presetId` ;
- clear nettoie les références mortes ;
- refus `tileLayerId` vide ;
- refus TileLayer introuvable ;
- refus layer non TileLayer ;
- refus absence d’EnvironmentLayer attaché ;
- refus `areaId` vide ;
- refus area introuvable ;
- no-op clair si aucun `generatedPlacementId` ;
- notifier garde TileLayer sélectionné ;
- notifier garde `selectedEnvironmentAreaId` stable ;
- notifier remet `environmentMaskEditMode` à `null` ;
- widget active/désactive correctement `Effacer les placements générés`.

## 8. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_clear_use_case_test.dart test/environment_studio/tile_layer_environment_clear_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat exact :

```text
Analyzing 7 items...
No issues found! (ran in 2.9s)
```

Dette préexistante hors lot : aucune détectée par cette analyse ciblée.

## 9. Fichiers créés/modifiés

Fichiers préexistants dans le worktree avant Environment-41 :

```text
Aucun. Le git status initial était vide.
```

Fichiers créés par Environment-41 :

```text
packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart
packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_clear_use_case_test.dart
reports/environment_studio/environment_41_tile_layer_environment_clear_generated_placements.md
```

Fichiers modifiés par Environment-41 :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

## 10. Non-objectifs respectés

- Pas de preview.
- Pas de regenerate.
- Pas de shuffle.
- Pas de génération.
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
 .../src/features/editor/state/editor_notifier.dart | 92 ++++++++++++++++++++++
 .../lib/src/ui/panels/map_inspector_panel.dart     | 11 +++
 .../tile_layer_environment_inspector_section.dart  | 15 +++-
 ...e_layer_environment_inspector_section_test.dart | 74 ++++++++++++++++-
 4 files changed, 189 insertions(+), 3 deletions(-)
```

Note : les fichiers non suivis sont listés par `git ls-files --others --exclude-standard`.

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
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Commande :

```bash
git ls-files --others --exclude-standard
```

Résultat :

```text
packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart
packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_clear_use_case_test.dart
reports/environment_studio/environment_41_tile_layer_environment_clear_generated_placements.md
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
find .. -name AGENTS.md -print
rg -n "ClearEnvironmentGeneratedPlacementsUseCase|clearEnvironmentGeneratedPlacements|generatedPlacementIds|canClearGeneratedPlacements|missingGeneratedPlacementCount|MapPlacedElement|placedElements|environmentMaskEditMode|selectedEnvironmentAreaId|targetTileLayerId" packages/map_core/lib/src packages/map_editor/lib/src packages/map_editor/test/environment_studio
dart format packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart packages/map_editor/test/environment_studio/tile_layer_environment_clear_use_case_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_clear_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_clear_notifier_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_generate_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_generate_notifier_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
flutter test test/environment_studio/environment_generated_placements_clear_test.dart
flutter test test/environment_studio/environment_generator_apply_candidates_test.dart
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
flutter analyze lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_clear_use_case_test.dart test/environment_studio/tile_layer_environment_clear_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
git diff --check
git diff --stat
git diff --name-only
git ls-files --others --exclude-standard
git status --short --untracked-files=all
```

## 12. Diff pertinent

### Nouveau use case complet

`packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart`

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'environment_generator_clear_use_cases.dart';

final class ClearTileLayerEnvironmentAreaGeneratedPlacementsResult {
  const ClearTileLayerEnvironmentAreaGeneratedPlacementsResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.removedPlacementIds,
    required this.clearedReferenceCount,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final List<String> removedPlacementIds;
  final int clearedReferenceCount;

  int get removedPlacementCount => removedPlacementIds.length;
}

class ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase {
  ClearTileLayerEnvironmentAreaGeneratedPlacementsResult execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    final referenceCount = target.area.generatedPlacementIds.length;
    if (referenceCount == 0) {
      return ClearTileLayerEnvironmentAreaGeneratedPlacementsResult(
        map: map,
        tileLayerId: target.tileLayer.id,
        environmentLayerId: target.environmentLayer.id,
        areaId: target.area.id,
        removedPlacementIds: const [],
        clearedReferenceCount: 0,
      );
    }

    final clear = ClearEnvironmentGeneratedPlacementsUseCase().execute(
      map,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
    );
    if (clear.hasErrors) {
      throw EditorValidationException(_firstClearError(clear));
    }

    return ClearTileLayerEnvironmentAreaGeneratedPlacementsResult(
      map: clear.map,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      removedPlacementIds: [
        for (final placement in clear.clearedPlacements)
          placement.placedElementId,
      ],
      clearedReferenceCount: referenceCount,
    );
  }
}

_TileLayerEnvironmentClearTarget _resolveTarget(
  MapData map, {
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

  return _TileLayerEnvironmentClearTarget(
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

String _firstClearError(EnvironmentClearResult result) {
  final issue = result.issues.firstWhere(
    (issue) => issue.severity == EnvironmentClearIssueSeverity.error,
    orElse: () => result.issues.first,
  );
  return issue.message;
}

final class _TileLayerEnvironmentClearTarget {
  const _TileLayerEnvironmentClearTarget({
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
+  void clearEnvironmentGeneratedPlacementsForActiveTileLayer() {
+    final map = state.activeMap;
+    if (map == null) {
+      state = state.copyWith(
+        errorMessage: 'Impossible d’effacer : aucune carte active.',
+      );
+      return;
+    }
+    final layerId = state.activeLayerId?.trim();
+    if (layerId == null || layerId.isEmpty) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez un TileLayer pour effacer les placements générés.',
+      );
+      return;
+    }
+    final activeLayer = _findLayerById(map, layerId);
+    if (activeLayer is! TileLayer) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez un TileLayer pour effacer les placements générés.',
+      );
+      return;
+    }
+    final areaId = state.selectedEnvironmentAreaId?.trim();
+    if (areaId == null || areaId.isEmpty) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez une zone d’environnement avant d’effacer les placements générés.',
+      );
+      return;
+    }
+
+    try {
+      final result =
+          ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase().execute(
+        map,
+        tileLayerId: layerId,
+        areaId: areaId,
+      );
+      if (result.clearedReferenceCount == 0) {
+        state = state.copyWith(
+          activeLayerId: result.tileLayerId,
+          selectedEnvironmentAreaId: result.areaId,
+          environmentMaskEditMode: null,
+          statusMessage: 'Aucun placement généré à effacer pour cette zone.',
+          errorMessage: null,
+        );
+        return;
+      }
+
+      final removedIds = result.removedPlacementIds.toSet();
+      final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
+      final clearSelection = selectionBefore != null &&
+          selectionBefore.isNotEmpty &&
+          removedIds.contains(selectionBefore);
+
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: result.map,
+        preferredActiveLayerId: result.tileLayerId,
+        statusMessage: _clearTileLayerGeneratedPlacementsStatusMessage(result),
+      );
+      state = state.copyWith(
+        activeLayerId: result.tileLayerId,
+        selectedEnvironmentAreaId: result.areaId,
+        selectedPlacedElementInstanceId:
+            clearSelection ? null : state.selectedPlacedElementInstanceId,
+        environmentMaskEditMode: null,
+        errorMessage: null,
+      );
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage:
+            'Impossible d’effacer les placements générés de cette zone : $e',
+      );
+    }
+  }
```

### MapInspectorPanel

```diff
+    final canClearTileLayerEnvironmentGeneratedPlacements =
+        activeLayer is TileLayer &&
+            tileLayerEnvironmentReadModel != null &&
+            tileLayerEnvironmentReadModel.canClearGeneratedPlacements &&
+            !tileLayerEnvironmentReadModel.hasErrors &&
+            state.selectedEnvironmentAreaId != null;
...
+                    onClearGeneratedPlacements:
+                        canClearTileLayerEnvironmentGeneratedPlacements
+                            ? notifier
+                                .clearEnvironmentGeneratedPlacementsForActiveTileLayer
+                            : null,
```

### TileLayerEnvironmentInspectorSection

```diff
+  final VoidCallback? onClearGeneratedPlacements;
...
-    if (readModel.canClearGeneratedPlacements) {
+    if (readModel.canClearGeneratedPlacements || readModel.canPaintMask) {
       actions.add(
-        const _ActionData(
+        _ActionData(
           icon: CupertinoIcons.trash,
           label: 'Effacer les placements générés',
+          enabled: readModel.canClearGeneratedPlacements &&
+              !readModel.hasErrors &&
+              onClearGeneratedPlacements != null,
+          onPressed: readModel.canClearGeneratedPlacements
+              ? onClearGeneratedPlacements
+              : null,
         ),
       );
     }
```

### Tests widget

```diff
+    testWidgets('Effacer les placements générés est actif avec callback',
+        (tester) async {
+      var cleared = 0;
+      await _pump(
+        tester,
+        const TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.generated,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaName: 'Bosquet nord',
+          selectedPresetName: 'Forêt',
+          maskActiveCellCount: 42,
+          hasMask: true,
+          generatedPlacementCount: 18,
+          hasGeneratedPlacements: true,
+          canClearGeneratedPlacements: true,
+          emptyStateTitle: 'Placements générés',
+          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
+        ),
+        onClearGeneratedPlacements: () {
+          cleared++;
+        },
+      );
+
+      expect(find.text('Effacer les placements générés'), findsOneWidget);
+      expect(
+        _buttonFor(tester, 'Effacer les placements générés').onPressed,
+        isNotNull,
+      );
+
+      await tester.tap(find.text('Effacer les placements générés'));
+      await tester.pump();
+
+      expect(cleared, 1);
+    });
```

Les nouveaux fichiers de test complets font respectivement 225 et 223 lignes. Les extraits ci-dessus couvrent les assertions centrales ; les fixtures complètes construisent une map 2x2 avec TileLayer `tiles`, EnvironmentLayer `env`, area `area`, placements générés, placement manuel, seed, mask et paramsOverride.

## 13. Auto-review

- Le bouton clear est-il actif seulement quand l’area a des `generatedPlacementIds` ? Oui.
- Le clear utilise-t-il l’area sélectionnée ? Oui.
- Le clear utilise-t-il le TileLayer actif comme contexte ? Oui.
- `generatedPlacementIds` est-il vidé ? Oui.
- Les `MapPlacedElement` référencés sont-ils supprimés ? Oui.
- Les `MapPlacedElement` manuels sont-ils préservés ? Oui.
- Les placements d’autres areas sont-ils préservés ? Oui.
- mask / `paramsOverride` / seed / `presetId` sont-ils préservés ? Oui.
- `activeLayerId` reste-t-il le TileLayer ? Oui.
- `selectedEnvironmentAreaId` reste-t-il stable ? Oui.
- `environmentMaskEditMode` devient-il `null` ? Oui.
- Aucune sauvegarde disque n’est-elle faite ? Oui.
- Le flow legacy reste-t-il intact ? Oui.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 14. Critique du prompt et du lot

Clair :

- la source de vérité TileLayer → EnvironmentLayer attaché → area sélectionnée était nette ;
- la conservation de mask / params / seed / preset était testable ;
- la gestion des références mortes était explicitement demandée.

Ambigu :

- le comportement si `generatedPlacementIds` est vide pouvait être refus ou no-op. Le choix retenu est no-op clair côté wrapper/notifier, bouton grisé côté UI.
- le bouton clear sans placements pouvait être absent ou grisé. Le choix retenu est visible et grisé quand le masque est éditable, cohérent avec `Générer dans ce layer`.

À trancher avant Environment-42 :

- décider si `Regenerate` doit composer clear + generate en une seule mutation undo ;
- décider si `Shuffle` doit seulement changer seed puis regenerate ;
- décider si les deux actions doivent être visibles en TileLayer inspector ou dans un sous-menu compact.

## 15. Verdict

```text
Environment-41 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-42 — TileLayer Environment Regenerate / Shuffle V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié le modèle persistant.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement l’effacement des placements générés.
- [x] Je n’ai pas ajouté regenerate/shuffle.
- [x] Je n’ai pas ajouté de preview.
- [x] Je n’ai pas lancé de génération.
- [x] Je n’ai pas modifié le mask.
- [x] Je n’ai pas modifié les params locaux.
- [x] Je n’ai pas modifié le preset global.
- [x] Le TileLayer reste sélectionné.
- [x] selectedEnvironmentAreaId reste stable.
- [x] environmentMaskEditMode devient null après clear.
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
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_clear_use_case_test.dart
?? reports/environment_studio/environment_41_tile_layer_environment_clear_generated_placements.md
```
