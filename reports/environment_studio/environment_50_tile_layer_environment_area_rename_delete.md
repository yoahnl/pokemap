# Environment-50 — TileLayer Environment Area Rename / Delete V0

## 1. Résumé

Environment-50 ajoute la gestion minimale des zones d’environnement depuis le flow TileLayer-centric :

- renommage de l’EnvironmentArea sélectionnée via un use case dédié ;
- suppression de l’EnvironmentArea sélectionnée via un use case dédié ;
- suppression des placements générés référencés par la zone supprimée ;
- préservation des placements manuels, des autres areas et des placements générés des autres areas ;
- wiring notifier pour garder le TileLayer actif et nettoyer les états transitoires après delete ;
- UI dans la section “Zones d’environnement” de l’inspecteur avec champ de nom, bouton de renommage, bouton de suppression et aide destructive.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector reste le lieu de gestion des zones.
- Ce lot ajoute seulement rename/delete d’area.
- Pas de génération, preview ou mutation hors scope.

L’utilisateur voit “Renommer la zone”, “Nom de la zone” et “Supprimer la zone”. Il ne manipule pas `EnvironmentLayerContent.areas` ni `generatedPlacementIds`.

## 3. Orchestration sub-agents

Sub-agents utilisés :

- Copernicus, audit / architecture : a confirmé qu’aucun rename dédié n’existait, que `RemoveEnvironmentAreaUseCase` retirait seulement l’area, et que delete devait aussi nettoyer les placements générés référencés par l’area.
- Gauss, state / notifier : a audité `EditorState`, `EditorNotifier`, les modes `EnvironmentMaskEditMode`, `selectedPlacedElementInstanceId` et `environmentGeneratedPlacementAddElementProvider`.
- McClintock, UI / UX : a audité `TileLayerEnvironmentInspectorSection`, la liste des zones, les risques de densité et les tests widget existants.
- Confucius, QA / Evidence Pack : a relu le diff et le rapport sans modification de code, a confirmé l’absence de placeholder interdit, l’absence de violation map_core/runtime/canvas/generated, le `git diff --check` vide, et le statut final cohérent.

Stratégie retenue :

1. Rename name-only : reconstruire l’area avec le même `id`, `presetId`, `mask`, `seed`, `paramsOverride`, `generatedPlacementIds`, et remplacer seulement `name`.
2. Delete ciblé : supprimer l’area et retirer de `MapData.placedElements` uniquement les ids listés dans `area.generatedPlacementIds`.
3. Après delete notifier : conserver `activeLayerId` sur le TileLayer, mettre `selectedEnvironmentAreaId` à `null`, mettre `environmentMaskEditMode` à `null`, nettoyer la sélection de placement si elle pointe vers un placement supprimé, réinitialiser l’élément d’ajout généré sélectionné.
4. Fichiers modifiés : use case applicatif, notifier, `MapInspectorPanel`, `TileLayerEnvironmentInspectorSection`, tests ciblés.
5. Tests créés : use case et notifier. Tests widget étendus dans le fichier existant.

Disposition des remarques QA :

- Le rapport conserve la structure obligatoire du prompt Environment-50 en 16 sections, avec Evidence Pack intégré à la section 12 et verdict en section 16.
- Les actions rename/delete restent disponibles quand un mode environnement est actif ; c’est volontaire en V0 car le contrat demande surtout que delete stoppe les modes liés à la zone supprimée. Le notifier le fait explicitement.
- La suppression est immédiate ; le prompt autorisait l’absence de confirmation modale en V0. Le risque UX est documenté comme point à trancher plus tard.

## 4. Audit de l’existant

Fichiers inspectés :

- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/environment_generated_placement_add_element_provider.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- tests Environment existants listés dans le prompt.

Constats :

- `EnvironmentArea` porte `id`, `name`, `presetId`, `mask`, `seed`, `paramsOverride`, `generatedPlacementIds`.
- `EnvironmentLayerContent` porte `targetTileLayerId` et `areas`, avec `areaById`.
- Les use cases TileLayer-centric existants résolvent déjà TileLayer actif → EnvironmentLayer attaché → area.
- Le clear existant supprime bien les placements générés, mais garde l’area.
- Le remove legacy existant supprime l’area mais ne nettoie pas les placements générés. C’est une dette préexistante hors lot ; Environment-50 ajoute un use case TileLayer-centric plus strict sans modifier ce legacy.

## 5. Use cases

Nouveau fichier :

- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_management_use_cases.dart`

Use cases ajoutés :

- `RenameTileLayerEnvironmentAreaUseCase`
- `DeleteTileLayerEnvironmentAreaUseCase`

Rename :

- entrées : `MapData`, `tileLayerId`, `areaId`, `name` ;
- validation : TileLayer id non vide, TileLayer existant, layer bien TileLayer, EnvironmentLayer attaché existant, area existante, `name.trim()` non vide ;
- effet : modifie uniquement `EnvironmentArea.name` ;
- préserve : `id`, `presetId`, `mask`, `seed`, `paramsOverride`, `generatedPlacementIds`, `placedElements`, autres areas.

Delete :

- entrées : `MapData`, `tileLayerId`, `areaId` ;
- validation : TileLayer id non vide, TileLayer existant, layer bien TileLayer, EnvironmentLayer attaché existant, area existante ;
- effet : supprime l’area ciblée ;
- supprime uniquement les `MapPlacedElement` dont `id` est dans `area.generatedPlacementIds` ;
- accepte les références mortes : les ids absents de `placedElements` disparaissent avec l’area ;
- préserve : TileLayer, EnvironmentLayer attaché, autres areas, placements manuels, placements générés des autres areas.

## 6. Notifier

Méthodes ajoutées dans `EditorNotifier` :

- `renameEnvironmentAreaForActiveTileLayer(String name)`
- `deleteEnvironmentAreaForActiveTileLayer()`

Rename notifier :

- vérifie qu’une map est active ;
- exige un TileLayer actif ;
- résout l’area effective ;
- appelle `RenameTileLayerEnvironmentAreaUseCase` ;
- applique via `_applyMapMutation` ;
- garde `activeLayerId` sur le TileLayer ;
- garde `selectedEnvironmentAreaId` stable ;
- garde `environmentMaskEditMode` inchangé ;
- status : `Zone renommée : <nom>.`

Delete notifier :

- vérifie qu’une map est active ;
- exige un TileLayer actif ;
- résout l’area effective ;
- appelle `DeleteTileLayerEnvironmentAreaUseCase` ;
- applique via `_applyMapMutation` ;
- garde `activeLayerId` sur le TileLayer ;
- met `selectedEnvironmentAreaId` à `null` ;
- met `environmentMaskEditMode` à `null` ;
- nettoie `selectedPlacedElementInstanceId` si le placement sélectionné fait partie des placements supprimés ;
- réinitialise `environmentGeneratedPlacementAddElementProvider` à `null` ;
- status : `Zone supprimée.`

## 7. Intégration UI

Dans `TileLayerEnvironmentInspectorSection`, la liste des zones affiche maintenant, pour la zone active :

- `Gestion de la zone active` ;
- libellé `Nom de la zone` ;
- champ de texte prérempli avec le nom actuel ;
- bouton `Renommer la zone` ;
- bouton `Supprimer la zone` ;
- aide destructive : `Supprime la zone et ses placements générés. Le masque et les réglages de cette zone seront perdus.`

Dans `MapInspectorPanel`, les callbacks sont câblés vers :

- `notifier.renameEnvironmentAreaForActiveTileLayer`
- `notifier.deleteEnvironmentAreaForActiveTileLayer`

Les boutons sont désactivés si le callback est absent ou si le nom saisi est vide après trim.

## 8. Tests

Commandes ciblées lancées :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_management_use_case_test.dart
```

Résultat exact :

```text
00:00 +8: DeleteTileLayerEnvironmentAreaUseCase refuses a missing TileLayer
00:00 +9: DeleteTileLayerEnvironmentAreaUseCase refuses a missing area
00:00 +10: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_management_notifier_test.dart
```

Résultat exact :

```text
00:00 +3: EditorNotifier TileLayer environment area management refuse sans TileLayer actif
00:00 +4: EditorNotifier TileLayer environment area management refuse sans area sélectionnée
00:00 +5: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat exact :

```text
00:02 +56: TileLayerEnvironmentInspectorSection Supprimer un élément généré est actif avec callback
00:02 +57: TileLayerEnvironmentInspectorSection mode suppression actif affiche stop et aide
00:02 +58: All tests passed!
```

Non-régressions lancées :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
flutter test test/environment_studio/tile_layer_environment_area_selection_test.dart
flutter test test/environment_studio/tile_layer_environment_clear_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

Résultats exacts :

```text
## test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
00:00 +29: All tests passed!

## test/environment_studio/tile_layer_environment_area_selection_test.dart
00:00 +5: All tests passed!

## test/environment_studio/tile_layer_environment_clear_use_case_test.dart
00:00 +3: All tests passed!

## test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart
00:00 +3: All tests passed!

## test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart
00:00 +3: All tests passed!

## test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
00:00 +1: All tests passed!

## test/environment_studio/environment_golden_slice_workflow_test.dart
00:00 +6: All tests passed!
```

Cas couverts :

- rename modifie uniquement `area.name` ;
- rename trim le nom ;
- rename refuse nom vide ;
- rename refuse TileLayer introuvable ;
- rename refuse area introuvable ;
- delete supprime l’area ;
- delete supprime les placements générés de l’area ;
- delete préserve les placements manuels ;
- delete préserve les placements générés d’une autre area ;
- delete préserve les autres areas ;
- delete accepte les `generatedPlacementIds` morts ;
- delete dernière area laisse l’EnvironmentLayer attaché avec `areas` vide ;
- notifier conserve le TileLayer actif ;
- notifier nettoie `selectedEnvironmentAreaId`, `environmentMaskEditMode`, `selectedPlacedElementInstanceId` et le provider d’ajout ;
- widget affiche et déclenche rename/delete ;
- widget garde la liste des zones visible ;
- widget désactive rename sur nom vide.

## 9. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/use_cases/tile_layer_environment_area_management_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_area_management_use_case_test.dart test/environment_studio/tile_layer_environment_area_management_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat exact :

```text
Analyzing 7 items...
No issues found! (ran in 2.2s)
```

Dettes préexistantes hors lot :

- le remove legacy d’area retire l’area sans nettoyer les placements générés. Environment-50 ne le modifie pas pour ne pas changer le flow legacy ; le nouveau delete TileLayer-centric est strict.

Problèmes introduits par Environment-50 :

- aucun problème connu après tests ciblés, non-régressions et analyze ciblé.

## 10. Fichiers créés/modifiés

Fichiers créés par Environment-50 :

- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_management_use_cases.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_area_management_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_area_management_notifier_test.dart`
- `reports/environment_studio/environment_50_tile_layer_environment_area_rename_delete.md`

Fichiers modifiés par Environment-50 :

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fichiers préexistants dans le worktree non touchés :

- aucun. Le `git status --short --untracked-files=all` initial était vide.

## 11. Non-objectifs respectés

- Pas de génération.
- Pas de preview.
- Pas de création/duplication/reorder d’area.
- Pas de modification du mask.
- Pas de modification des params locaux.
- Pas de modification du seed.
- Pas de modification du preset global.
- Pas de suppression de l’EnvironmentLayer attaché.
- Pas de migration vers `TileLayer.environmentContent`.
- Pas de modification de `map_core`.
- Pas de modification runtime/gameplay/battle.
- Pas de build_runner.
- Pas de generated files.

## 12. Evidence pack

Git status initial :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text

```

Git status avant création du rapport :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_management_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_area_management_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_area_management_use_case_test.dart
```

Git status final :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_management_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_area_management_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_area_management_use_case_test.dart
?? reports/environment_studio/environment_50_tile_layer_environment_area_rename_delete.md
```

Diff stat demandé :

```bash
git diff --stat
```

Résultat exact :

```text
 .../src/features/editor/state/editor_notifier.dart | 115 ++++++++++
 .../lib/src/ui/panels/map_inspector_panel.dart     |  12 ++
 .../tile_layer_environment_inspector_section.dart  | 234 +++++++++++++++++++++
 ...e_layer_environment_inspector_section_test.dart | 200 +++++++++++++++++-
 4 files changed, 560 insertions(+), 1 deletion(-)
```

Note vérifiable : `git diff --stat` ne liste pas les fichiers non indexés. Les fichiers créés par Environment-50 apparaissent dans les sorties `git status`.

Diff name-only demandé :

```bash
git diff --name-only
```

Résultat exact :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Note vérifiable : `git diff --name-only` ne liste pas les fichiers non indexés. Les fichiers créés par Environment-50 apparaissent dans les sorties `git status`.

Git diff check :

```bash
git diff --check
```

Résultat exact :

```text

```

Format :

```bash
dart format packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_management_use_cases.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart packages/map_editor/test/environment_studio/tile_layer_environment_area_management_use_case_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_area_management_notifier_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat exact :

```text
Formatted packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
Formatted packages/map_editor/test/environment_studio/tile_layer_environment_area_management_use_case_test.dart
Formatted packages/map_editor/test/environment_studio/tile_layer_environment_area_management_notifier_test.dart
Formatted 7 files (3 changed) in 0.08 seconds.
```

## 13. Diff pertinent

### Nouveau use case complet

`packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_management_use_cases.dart`

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

final class RenameTileLayerEnvironmentAreaResult {
  const RenameTileLayerEnvironmentAreaResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.name,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final String name;
}

final class DeleteTileLayerEnvironmentAreaResult {
  const DeleteTileLayerEnvironmentAreaResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.deletedAreaId,
    required this.removedPlacementIds,
    required this.clearedReferenceCount,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String deletedAreaId;
  final List<String> removedPlacementIds;
  final int clearedReferenceCount;

  int get removedPlacementCount => removedPlacementIds.length;
}

class RenameTileLayerEnvironmentAreaUseCase {
  RenameTileLayerEnvironmentAreaResult execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
    required String name,
  }) {
    final nextName = name.trim();
    if (nextName.isEmpty) {
      throw const EditorValidationException(
        'Environment area name cannot be empty',
      );
    }
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    final updatedArea = EnvironmentArea(
      id: target.area.id,
      name: nextName,
      presetId: target.area.presetId,
      mask: target.area.mask,
      seed: target.area.seed,
      paramsOverride: target.area.paramsOverride,
      generatedPlacementIds: target.area.generatedPlacementIds,
    );
    final updated = _replaceEnvironmentLayerAreas(
      map,
      environmentLayer: target.environmentLayer,
      areas: [
        for (final area in target.environmentLayer.content.areas)
          if (area.id == target.area.id) updatedArea else area,
      ],
      placedElements: map.placedElements,
    );
    return RenameTileLayerEnvironmentAreaResult(
      map: updated,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      name: nextName,
    );
  }
}

class DeleteTileLayerEnvironmentAreaUseCase {
  DeleteTileLayerEnvironmentAreaResult execute(
    MapData map, {
    required String tileLayerId,
    required String areaId,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    final generatedPlacementIds = target.area.generatedPlacementIds.toSet();
    final removedPlacementIds = [
      for (final placed in map.placedElements)
        if (generatedPlacementIds.contains(placed.id)) placed.id,
    ];
    final updated = _replaceEnvironmentLayerAreas(
      map,
      environmentLayer: target.environmentLayer,
      areas: [
        for (final area in target.environmentLayer.content.areas)
          if (area.id != target.area.id) area,
      ],
      placedElements: [
        for (final placed in map.placedElements)
          if (!generatedPlacementIds.contains(placed.id)) placed,
      ],
    );
    return DeleteTileLayerEnvironmentAreaResult(
      map: updated,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      deletedAreaId: target.area.id,
      removedPlacementIds: removedPlacementIds,
      clearedReferenceCount: target.area.generatedPlacementIds.length,
    );
  }
}

_TileLayerEnvironmentAreaManagementTarget _resolveTarget(
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

  return _TileLayerEnvironmentAreaManagementTarget(
    tileLayer: layer,
    environmentLayer: environmentLayer,
    area: area,
  );
}

MapData _replaceEnvironmentLayerAreas(
  MapData map, {
  required EnvironmentLayer environmentLayer,
  required List<EnvironmentArea> areas,
  required List<MapPlacedElement> placedElements,
}) {
  final updated = map.copyWith(
    layers: [
      for (final layer in map.layers)
        if (layer is EnvironmentLayer && layer.id == environmentLayer.id)
          MapLayer.environment(
            id: layer.id,
            name: layer.name,
            isVisible: layer.isVisible,
            opacity: layer.opacity,
            content: EnvironmentLayerContent(
              targetTileLayerId: layer.content.targetTileLayerId,
              areas: areas,
            ),
            properties: layer.properties,
          )
        else
          layer,
    ],
    placedElements: placedElements,
  );
  try {
    MapValidator.validate(updated);
    return updated;
  } on ValidationException catch (e) {
    throw EditorValidationException(e.message);
  }
}

MapLayer? _findLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer;
    }
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

final class _TileLayerEnvironmentAreaManagementTarget {
  const _TileLayerEnvironmentAreaManagementTarget({
    required this.tileLayer,
    required this.environmentLayer,
    required this.area,
  });

  final TileLayer tileLayer;
  final EnvironmentLayer environmentLayer;
  final EnvironmentArea area;
}
```

### Notifier

`packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

```diff
+import '../../../application/use_cases/tile_layer_environment_area_management_use_cases.dart';
```

```diff
+  void renameEnvironmentAreaForActiveTileLayer(String name) {
+    final map = state.activeMap;
+    if (map == null) return;
+    final layerId = state.activeLayerId?.trim();
+    if (layerId == null || layerId.isEmpty) {
+      state = state.copyWith(
+        errorMessage: 'Sélectionnez un TileLayer pour renommer une zone.',
+      );
+      return;
+    }
+    final activeLayer = _findLayerById(map, layerId);
+    if (activeLayer is! TileLayer) {
+      state = state.copyWith(
+        errorMessage: 'Sélectionnez un TileLayer pour renommer une zone.',
+      );
+      return;
+    }
+    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
+    if (areaId == null || areaId.isEmpty) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez une zone d’environnement avant de la renommer.',
+      );
+      return;
+    }
+    final mode = state.environmentMaskEditMode;
+
+    try {
+      final result = RenameTileLayerEnvironmentAreaUseCase().execute(
+        map,
+        tileLayerId: layerId,
+        areaId: areaId,
+        name: name,
+      );
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: result.map,
+        preferredActiveLayerId: result.tileLayerId,
+        statusMessage: 'Zone renommée : ${result.name}.',
+      );
+      state = state.copyWith(
+        activeLayerId: result.tileLayerId,
+        selectedEnvironmentAreaId: result.areaId,
+        environmentMaskEditMode: mode,
+        errorMessage: null,
+      );
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Impossible de renommer la zone : $e',
+      );
+    }
+  }
```

```diff
+  void deleteEnvironmentAreaForActiveTileLayer() {
+    final map = state.activeMap;
+    if (map == null) return;
+    final layerId = state.activeLayerId?.trim();
+    if (layerId == null || layerId.isEmpty) {
+      state = state.copyWith(
+        errorMessage: 'Sélectionnez un TileLayer pour supprimer une zone.',
+      );
+      return;
+    }
+    final activeLayer = _findLayerById(map, layerId);
+    if (activeLayer is! TileLayer) {
+      state = state.copyWith(
+        errorMessage: 'Sélectionnez un TileLayer pour supprimer une zone.',
+      );
+      return;
+    }
+    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
+    if (areaId == null || areaId.isEmpty) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez une zone d’environnement avant de la supprimer.',
+      );
+      return;
+    }
+    final selectedPlacementId = state.selectedPlacedElementInstanceId?.trim();
+
+    try {
+      final result = DeleteTileLayerEnvironmentAreaUseCase().execute(
+        map,
+        tileLayerId: layerId,
+        areaId: areaId,
+      );
+      final removedPlacementIds = result.removedPlacementIds.toSet();
+      final shouldClearPlacedSelection = selectedPlacementId != null &&
+          selectedPlacementId.isNotEmpty &&
+          removedPlacementIds.contains(selectedPlacementId);
+      ref.read(environmentGeneratedPlacementAddElementProvider.notifier).state =
+          null;
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: result.map,
+        preferredActiveLayerId: result.tileLayerId,
+        statusMessage: 'Zone supprimée.',
+      );
+      state = state.copyWith(
+        activeLayerId: result.tileLayerId,
+        selectedEnvironmentAreaId: null,
+        selectedPlacedElementInstanceId: shouldClearPlacedSelection
+            ? null
+            : state.selectedPlacedElementInstanceId,
+        environmentMaskEditMode: null,
+        errorMessage: null,
+      );
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Impossible de supprimer la zone : $e',
+      );
+    }
+  }
```

### MapInspectorPanel wiring

`packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`

```diff
+                    onRenameEnvironmentArea: activeLayer is TileLayer &&
+                            tileLayerEnvironmentReadModel
+                                    .selectedEnvironmentAreaId !=
+                                null
+                        ? notifier.renameEnvironmentAreaForActiveTileLayer
+                        : null,
+                    onDeleteEnvironmentArea: activeLayer is TileLayer &&
+                            tileLayerEnvironmentReadModel
+                                    .selectedEnvironmentAreaId !=
+                                null
+                        ? notifier.deleteEnvironmentAreaForActiveTileLayer
+                        : null,
```

### Inspector UI

`packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`

```diff
+  final ValueChanged<String>? onRenameEnvironmentArea;
+  final VoidCallback? onDeleteEnvironmentArea;
```

```diff
+          if (selectedSummary != null) ...[
+            const SizedBox(height: 10),
+            _EnvironmentAreaManagementPanel(
+              summary: selectedSummary,
+              onRenameEnvironmentArea: onRenameEnvironmentArea,
+              onDeleteEnvironmentArea: onDeleteEnvironmentArea,
+            ),
+          ],
```

```diff
+class _EnvironmentAreaManagementPanel extends StatefulWidget {
+  const _EnvironmentAreaManagementPanel({
+    required this.summary,
+    required this.onRenameEnvironmentArea,
+    required this.onDeleteEnvironmentArea,
+  });
+  ...
+            'Gestion de la zone active',
+  ...
+            'Nom de la zone',
+  ...
+          CupertinoTextField(
+            key: const ValueKey('tile-layer-environment-area-name-field'),
+            controller: _controller,
+            placeholder: 'Nom de la zone',
+  ...
+                  label: 'Renommer la zone',
+  ...
+                  label: 'Supprimer la zone',
+  ...
+            'Supprime la zone et ses placements générés. Le masque et les réglages de cette zone seront perdus.',
```

### Tests ajoutés

`packages/map_editor/test/environment_studio/tile_layer_environment_area_management_use_case_test.dart`

```dart
group('RenameTileLayerEnvironmentAreaUseCase', () {
  test('renames only the selected area name and trims input', () {
    final map = _map();
    final beforeArea = _areaById(map, 'area_a');
    final beforeOtherArea = _areaById(map, 'area_b');
    final beforePlacedElements = map.placedElements;

    final result = RenameTileLayerEnvironmentAreaUseCase().execute(
      map,
      tileLayerId: 'tile_layer',
      areaId: 'area_a',
      name: '  Bosquet plage  ',
    );

    final renamedArea = _areaById(result.map, 'area_a');
    final otherArea = _areaById(result.map, 'area_b');

    expect(result.name, 'Bosquet plage');
    expect(renamedArea.name, 'Bosquet plage');
    expect(renamedArea.id, beforeArea.id);
    expect(renamedArea.presetId, beforeArea.presetId);
    expect(renamedArea.mask, beforeArea.mask);
    expect(renamedArea.seed, beforeArea.seed);
    expect(renamedArea.paramsOverride, beforeArea.paramsOverride);
    expect(renamedArea.generatedPlacementIds, beforeArea.generatedPlacementIds);
    expect(otherArea, beforeOtherArea);
    expect(result.map.placedElements, beforePlacedElements);
  });
});
```

```dart
group('DeleteTileLayerEnvironmentAreaUseCase', () {
  test('deletes the area and its generated placements only', () {
    final result = DeleteTileLayerEnvironmentAreaUseCase().execute(
      _map(),
      tileLayerId: 'tile_layer',
      areaId: 'area_a',
    );

    final environmentLayer = _environmentLayer(result.map);

    expect(result.removedPlacementIds, ['generated_a', 'generated_b']);
    expect(result.removedPlacementCount, 2);
    expect(result.clearedReferenceCount, 3);
    expect(environmentLayer.content.targetTileLayerId, 'tile_layer');
    expect(environmentLayer.content.areaById('area_a'), isNull);
    expect(environmentLayer.content.areaById('area_b'), isNotNull);
    expect(_placedElementIds(result.map), ['manual', 'other_generated']);
    expect(
      environmentLayer.content.areaById('area_b')!.generatedPlacementIds,
      ['other_generated'],
    );
  });
});
```

`packages/map_editor/test/environment_studio/tile_layer_environment_area_management_notifier_test.dart`

```dart
test('rename garde TileLayer, area sélectionnée et mode actifs', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(editorNotifierProvider.notifier);
  final map = _map();
  notifier.state = EditorState(
    project: _manifest(),
    activeMap: map,
    activeLayerId: 'tiles',
    selectedEnvironmentAreaId: 'area_a',
    environmentMaskEditMode: EnvironmentMaskEditMode.paint,
    savedMapSnapshot: map,
  );

  notifier.renameEnvironmentAreaForActiveTileLayer('  Bosquet plage  ');

  final state = notifier.state;
  final area = _areaById(state.activeMap!, 'area_a');

  expect(state.activeLayerId, 'tiles');
  expect(state.selectedEnvironmentAreaId, 'area_a');
  expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.paint);
  expect(area.name, 'Bosquet plage');
  expect(area.id, 'area_a');
  expect(area.generatedPlacementIds, ['generated_a']);
});
```

```dart
test('delete nettoie la sélection active et le mode sans changer le TileLayer',
    () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(editorNotifierProvider.notifier);
  final map = _map();
  notifier.state = EditorState(
    project: _manifest(),
    activeMap: map,
    activeLayerId: 'tiles',
    selectedEnvironmentAreaId: 'area_a',
    selectedPlacedElementInstanceId: 'generated_a',
    environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
    savedMapSnapshot: map,
  );
  container
      .read(environmentGeneratedPlacementAddElementProvider.notifier)
      .state = 'tree';

  notifier.deleteEnvironmentAreaForActiveTileLayer();

  final state = notifier.state;
  final environmentLayer = _environmentLayer(state.activeMap!);

  expect(state.activeLayerId, 'tiles');
  expect(state.selectedEnvironmentAreaId, isNull);
  expect(state.environmentMaskEditMode, isNull);
  expect(state.selectedPlacedElementInstanceId, isNull);
  expect(container.read(environmentGeneratedPlacementAddElementProvider), isNull);
  expect(environmentLayer.content.areaById('area_a'), isNull);
  expect(environmentLayer.content.areaById('area_b'), isNotNull);
  expect(state.activeMap!.placedElements.map((placement) => placement.id),
      ['manual', 'other_generated']);
});
```

`packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

```dart
testWidgets('affiche et renomme la zone active', (tester) async {
  String? renamed;
  await _pump(
    tester,
    const TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.ready,
      selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
      hasAttachment: true,
      hasValidTargetTileLayer: true,
      selectedEnvironmentAreaId: 'area_a',
      selectedEnvironmentAreaName: 'Bosquet nord',
      selectedPresetName: 'Forêt',
      maskActiveCellCount: 42,
      hasMask: true,
      canPaintMask: true,
      emptyStateTitle: 'Prêt à générer',
      emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
      areaSummaries: [
        TileLayerEnvironmentAreaSummary(
          id: 'area_a',
          name: 'Bosquet nord',
          presetId: 'forest',
          presetName: 'Forêt',
          isSelected: true,
          maskActiveCellCount: 42,
          generatedPlacementCount: 18,
          missingGeneratedPlacementCount: 0,
          hasMissingPreset: false,
        ),
      ],
    ),
    onRenameEnvironmentArea: (name) {
      renamed = name;
    },
  );

  expect(find.text('Zone active'), findsOneWidget);
  expect(find.text('Nom de la zone'), findsWidgets);
  expect(find.text('Renommer la zone'), findsOneWidget);

  final nameField =
      find.byKey(const ValueKey('tile-layer-environment-area-name-field'));
  await tester.ensureVisible(nameField);
  await tester.tap(nameField);
  await tester.enterText(nameField, '  Bosquet plage  ');
  await tester.pump();
  await tester.ensureVisible(find.text('Renommer la zone'));
  await tester.tap(find.text('Renommer la zone'));
  await tester.pump();

  expect(renamed, 'Bosquet plage');
});
```

```dart
testWidgets('Supprimer la zone déclenche le callback et affiche l’aide',
    (tester) async {
  var deleted = 0;
  await _pump(..., onDeleteEnvironmentArea: () {
    deleted++;
  });

  expect(find.text('Supprimer la zone'), findsOneWidget);
  expect(
    find.text(
      'Supprime la zone et ses placements générés. Le masque et les réglages de cette zone seront perdus.',
    ),
    findsOneWidget,
  );

  await tester.ensureVisible(find.text('Supprimer la zone'));
  await tester.tap(find.text('Supprimer la zone'));
  await tester.pump();

  expect(deleted, 1);
});
```

Les nouveaux fichiers de tests complets font plusieurs centaines de lignes avec fixtures locales. Les extraits ci-dessus couvrent les assertions métier centrales ; les résultats de commandes prouvent que chaque fichier complet a été compilé et exécuté.

## 14. Auto-review

- Rename modifie-t-il uniquement le nom ? Oui, test use case dédié.
- Delete supprime-t-il seulement l’area ciblée ? Oui, test use case dédié.
- Delete supprime-t-il seulement les placements générés de cette area ? Oui, filtrage sur `area.generatedPlacementIds` et tests.
- Les placements manuels sont-ils préservés ? Oui.
- Les autres areas sont-elles préservées ? Oui.
- `selectedEnvironmentAreaId` devient-il null après delete ? Oui, test notifier.
- `environmentMaskEditMode` devient-il null après delete ? Oui, test notifier.
- EnvironmentLayer reste-t-il attaché ? Oui, test use case dernière area.
- Le flow TileLayer-centric reste-t-il intact ? Oui, non-régressions ciblées pass.
- Le flow legacy reste-t-il intact ? Oui, non modifié.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 15. Critique du prompt et du lot

Clair :

- séparation nette entre “Effacer les placements générés” et “Supprimer la zone” ;
- préservations attendues pour rename et delete ;
- nettoyage d’état notifier après suppression ;
- interdiction de toucher à map_core / runtime / canvas.

Ambigu :

- faut-il autoriser delete/rename quand aucune zone n’est explicitement sélectionnée mais qu’une unique area existe ? Le notifier réutilise l’area effective comme les autres actions TileLayer-centric. Les tests couvrent l’erreur sans sélection sur une map à plusieurs zones.
- confirmation modale de suppression : le prompt l’excluait comme nécessité stricte ; V0 affiche une aide destructive mais ne crée pas de confirmation.

À trancher avant Environment-51 :

- politique de réparation des EnvironmentLayers orphelins ;
- comportement lors de suppression d’un TileLayer ayant un EnvironmentLayer attaché ;
- accès éventuel au legacy remove d’area qui ne nettoie pas les placements générés.
- confirmation modale ou undo léger pour `Supprimer la zone`.

## 16. Verdict

```text
Environment-50 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-51 — TileLayer / Environment Attachment Safety V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement rename/delete d’area.
- [x] Je n’ai pas ajouté duplication/reorder d’area.
- [x] Je n’ai pas lancé de génération.
- [x] Je n’ai pas ajouté de preview.
- [x] Je n’ai pas modifié le mask.
- [x] Je n’ai pas modifié les params locaux.
- [x] Je n’ai pas modifié le seed.
- [x] Je n’ai pas modifié le preset global.
- [x] Je n’ai pas supprimé l’EnvironmentLayer attaché.
- [x] Les placements manuels sont préservés.
- [x] Le TileLayer reste sélectionné.
- [x] selectedEnvironmentAreaId est géré correctement.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
