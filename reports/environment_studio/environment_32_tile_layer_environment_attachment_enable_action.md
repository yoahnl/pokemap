# Environment-32 — TileLayer Environment Attachment Enable Action V0

## 1. Résumé

Environment-32 active uniquement l’action `Activer l’environnement` depuis la section `Environnement du layer`.

Ajouts principaux :

- un use case pur `EnableTileLayerEnvironmentAttachmentUseCase` ;
- une méthode notifier `enableEnvironmentForActiveTileLayer()` ;
- un callback optionnel `onEnableEnvironment` dans `TileLayerEnvironmentInspectorSection` ;
- le wiring minimal depuis `MapInspectorPanel` ;
- des tests use case, widget, notifier, plus non-régression Environment-30.

Le clic crée un `EnvironmentLayer` technique attaché au `TileLayer` actif, garde le `TileLayer` sélectionné, ne crée aucune area, aucun preset, aucun masque, aucun placement et ne lance aucune génération.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets / recettes d’environnement.
- Map Editor / TileLayer inspector devient le lieu de peinture/génération.
- Ce lot active seulement l’action `Activer l’environnement`.

L’UI parle créateur : `Activer l’environnement`, pas `Créer EnvironmentLayer`.

## 3. Audit de l’existant

Fichiers inspectés :

- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/application/map_editing_controller.dart`
- `packages/map_editor/lib/src/features/editor/application/project_session_controller.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/operations/map_layers.dart`

Mécanisme de mutation retenu :

- `EditorNotifier` applique les mutations de map via `_applyMapMutation`.
- `_applyMapMutation` délègue à `EditorMapEditingController.applyMutation`, ce qui conserve le flux working copy / dirty / undo existant.
- Pour garder le `TileLayer` actif, le notifier appelle `_applyMapMutation(... preferredActiveLayerId: layerId)`.

Conventions identifiées :

- `AddMapLayerUseCase` génère déjà des ids uniques et appelle `MapValidator.validate`.
- Les mutations Environment existantes utilisent des use cases purs ou des classes directes, puis `_applyMapMutation`.
- `MapLayer.environment` a un `EnvironmentLayerContent.emptyContent` par défaut, mais ce lot doit fournir explicitement `targetTileLayerId`.
- `addMapLayer` actuel insère près du layer actif, mais sélectionne le nouveau layer. Pour ce lot, un use case dédié est préférable afin d’insérer juste après le TileLayer et de garder le TileLayer actif.

## 4. Use case ajouté

Nom :

`EnableTileLayerEnvironmentAttachmentUseCase`

Chemin :

`packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart`

Entrées :

- `MapData map`
- `String tileLayerId`

Sortie :

`EnableTileLayerEnvironmentAttachmentResult`

Champs :

- `map`
- `environmentLayerId`
- `tileLayerId`
- `created`
- `alreadyAttached`

Règles :

- refuse un id vide ;
- refuse un layer introuvable ;
- refuse un layer qui n’est pas un `TileLayer` ;
- si un `EnvironmentLayer` cible déjà le TileLayer, retourne la map inchangée avec `created = false` et `alreadyAttached = true` ;
- sinon crée un `EnvironmentLayer` attaché ;
- `content.targetTileLayerId = tileLayerId` ;
- `content.areas = []` ;
- insertion juste après le TileLayer ciblé ;
- validation via `MapValidator.validate`.

Stratégie d’id :

- base : `l_environment_<slug TileLayer name>` ;
- fallback si nom vide : `l_environment` ;
- suffixe `_2`, `_3`, etc. si l’id existe déjà.

Stratégie de nom :

- `Environnement - <nom du TileLayer>` ;
- fallback : `Environnement`.

## 5. Intégration notifier

Méthode ajoutée :

`EditorNotifier.enableEnvironmentForActiveTileLayer()`

Comportement :

- lit `state.activeMap` ;
- lit `state.activeLayerId` ;
- vérifie que le layer actif est un `TileLayer` ;
- appelle `EnableTileLayerEnvironmentAttachmentUseCase` ;
- applique la map via `_applyMapMutation` ;
- garde `preferredActiveLayerId` sur le TileLayer ;
- vide `selectedEnvironmentAreaId` et `environmentMaskEditMode` ;
- ne crée aucune `EnvironmentArea`.

Cas déjà attaché :

- aucune map mutée ;
- `activeLayerId` reste le TileLayer ;
- message : `L’environnement est déjà activé sur ce layer.`

## 6. Intégration UI

`TileLayerEnvironmentInspectorSection` accepte maintenant :

```dart
VoidCallback? onEnableEnvironment
```

Règle du bouton :

- `Activer l’environnement` est actif uniquement si `readModel.canEnableEnvironment == true` et `onEnableEnvironment != null`.
- Sans callback, le bouton reste désactivé.

Dans `MapInspectorPanel`, le callback est passé seulement si :

- le layer actif est un `TileLayer` ;
- le read model expose `canEnableEnvironment == true`.

Actions qui restent désactivées :

- `Peindre le masque`
- `Générer dans ce layer`
- `Effacer les placements générés`

Après activation, le read model voit l’attachment et bascule naturellement vers l’état sans area (`Aucune zone d’environnement`).

## 7. Tests

Commandes lancées :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
```

Résultat :

```text
00:00 +7: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat :

```text
00:00 +10: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
```

Résultat :

```text
00:00 +1: All tests passed!
```

Non-régression Environment-30 :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

```text
00:00 +21: All tests passed!
```

Cas couverts :

- création d’un `EnvironmentLayer` attaché ;
- `targetTileLayerId` correct ;
- liste `areas` vide ;
- insertion juste après le TileLayer ciblé ;
- `created = true` ;
- réutilisation si déjà attaché ;
- `created = false`, `alreadyAttached = true` ;
- refus layer introuvable ;
- refus layer non TileLayer ;
- préservation des autres layers ;
- préservation des `placedElements` ;
- aucun `EnvironmentArea` créé ;
- aucun `MapPlacedElement` créé ;
- bouton actif avec callback ;
- bouton désactivé sans callback ;
- autres actions toujours désactivées ;
- notifier garde le TileLayer sélectionné.

## 8. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart lib/src/ui/panels/map_inspector_panel.dart test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart test/environment_studio/tile_layer_environment_attachment_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

```text
Analyzing 10 items...
No issues found! (ran in 2.1s)
```

## 9. Fichiers créés/modifiés

Fichiers créés par Environment-32 :

- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_notifier_test.dart`
- `reports/environment_studio/environment_32_tile_layer_environment_attachment_enable_action.md`

Fichiers modifiés par Environment-32 :

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fichiers préexistants dans le worktree, non touchés par Environment-32 :

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart`
- `packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart`
- `packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart`
- `packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart`
- `packages/map_editor/test/tileset_grid_metrics_test.dart`
- `reports/environment_studio/environment_studio_map_centric_workflow_review.md`

## 10. Non-objectifs respectés

- pas de brush ;
- pas de generate ;
- pas de preview ;
- pas de clear/regenerate/shuffle ;
- pas d’area ;
- pas de preset selection ;
- pas de migration ;
- pas de modification de `map_core` ;
- pas de modification runtime ;
- pas de build_runner ;
- pas de generated files.

## 11. Evidence pack

Git status initial :

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
?? packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
?? packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart
?? packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/tileset_grid_metrics_test.dart
?? reports/environment_studio/environment_studio_map_centric_workflow_review.md
```

`git diff --stat` avant rapport :

```text
 .../src/features/editor/state/editor_notifier.dart |  52 ++++
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  34 ++
 .../src/ui/canvas/map_canvas/map_grid_painter.dart | 138 ++++++++-
 .../lib/src/ui/canvas/tileset_editor_canvas.dart   | 344 +++++++++++----------
 .../lib/src/ui/panels/map_inspector_panel.dart     |   5 +
 .../tile_layer_environment_inspector_section.dart  |  23 +-
 ...e_layer_environment_inspector_section_test.dart |  69 ++++-
 7 files changed, 485 insertions(+), 180 deletions(-)
```

`git diff --name-only` avant rapport :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Commandes principales :

```bash
git status --short --untracked-files=all
rg -n "create.*Layer|add.*Layer|EnvironmentLayer|targetTileLayerId|MapLayer.environment|EnvironmentLayerContent|_applyMapMutation|activeLayerId|selectedEnvironmentAreaId|copyWith\\(layers" packages/map_editor/lib/src packages/map_core/lib/src
dart format lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart lib/src/ui/panels/map_inspector_panel.dart test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart test/environment_studio/tile_layer_environment_attachment_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
flutter analyze lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart lib/src/ui/panels/map_inspector_panel.dart test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart test/environment_studio/tile_layer_environment_attachment_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Résultats de tests :

```text
Use case : 00:00 +7: All tests passed!
Widget : 00:00 +10: All tests passed!
Notifier : 00:00 +1: All tests passed!
Read model Environment-30 : 00:00 +21: All tests passed!
```

Résultat d’analyse :

```text
No issues found! (ran in 2.1s)
```

Git status final :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart
?? packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart
?? packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
?? packages/map_editor/test/tileset_grid_metrics_test.dart
?? reports/environment_studio/environment_32_tile_layer_environment_attachment_enable_action.md
?? reports/environment_studio/environment_studio_map_centric_workflow_review.md
```

## 12. Diff pertinent

### Nouveau use case

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

final class EnableTileLayerEnvironmentAttachmentResult {
  const EnableTileLayerEnvironmentAttachmentResult({
    required this.map,
    required this.environmentLayerId,
    required this.tileLayerId,
    required this.created,
    required this.alreadyAttached,
  });

  final MapData map;
  final String environmentLayerId;
  final String tileLayerId;
  final bool created;
  final bool alreadyAttached;
}

class EnableTileLayerEnvironmentAttachmentUseCase {
  EnableTileLayerEnvironmentAttachmentResult execute(
    MapData map, {
    required String tileLayerId,
  }) {
    final tid = tileLayerId.trim();
    if (tid.isEmpty) {
      throw const EditorValidationException('Tile layer id cannot be empty');
    }

    final tileLayerIndex = map.layers.indexWhere((layer) => layer.id == tid);
    if (tileLayerIndex < 0) {
      throw EditorValidationException('Tile layer not found: $tid');
    }

    final tileLayer = map.layers[tileLayerIndex];
    if (tileLayer is! TileLayer) {
      throw EditorValidationException('Layer is not a TileLayer: $tid');
    }

    for (final layer in map.layers) {
      if (layer is EnvironmentLayer &&
          layer.content.targetTileLayerId?.trim() == tid) {
        return EnableTileLayerEnvironmentAttachmentResult(
          map: map,
          environmentLayerId: layer.id,
          tileLayerId: tid,
          created: false,
          alreadyAttached: true,
        );
      }
    }

    final environmentLayerId = _uniqueEnvironmentLayerId(
      map,
      tileLayerName: tileLayer.name,
    );
    final environmentLayer = MapLayer.environment(
      id: environmentLayerId,
      name: _environmentLayerName(tileLayer.name),
      content: EnvironmentLayerContent(
        targetTileLayerId: tid,
        areas: const [],
      ),
    );

    final updatedLayers = List<MapLayer>.from(map.layers, growable: true)
      ..insert(tileLayerIndex + 1, environmentLayer);
    final updatedMap = map.copyWith(layers: updatedLayers);

    try {
      MapValidator.validate(updatedMap);
    } on ValidationException catch (e) {
      throw EditorValidationException(e.message);
    }

    return EnableTileLayerEnvironmentAttachmentResult(
      map: updatedMap,
      environmentLayerId: environmentLayerId,
      tileLayerId: tid,
      created: true,
      alreadyAttached: false,
    );
  }
}
```

### Notifier

```diff
+  void enableEnvironmentForActiveTileLayer() {
+    final map = state.activeMap;
+    if (map == null) return;
+    final layerId = state.activeLayerId?.trim();
+    if (layerId == null || layerId.isEmpty) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez un TileLayer pour activer l’environnement.',
+      );
+      return;
+    }
+    final activeLayer = _findLayerById(map, layerId);
+    if (activeLayer is! TileLayer) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez un TileLayer pour activer l’environnement.',
+      );
+      return;
+    }
+
+    try {
+      final result = EnableTileLayerEnvironmentAttachmentUseCase().execute(
+        map,
+        tileLayerId: layerId,
+      );
+      if (!result.created) {
+        state = state.copyWith(
+          activeLayerId: layerId,
+          selectedEnvironmentAreaId: null,
+          environmentMaskEditMode: null,
+          statusMessage: 'L’environnement est déjà activé sur ce layer.',
+          errorMessage: null,
+        );
+        return;
+      }
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: result.map,
+        preferredActiveLayerId: layerId,
+        statusMessage: 'Environnement activé sur "${activeLayer.name}"',
+      );
+      state = state.copyWith(
+        activeLayerId: layerId,
+        selectedEnvironmentAreaId: null,
+        environmentMaskEditMode: null,
+      );
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Impossible d’activer l’environnement : $e',
+      );
+    }
+  }
```

### UI wiring

```diff
+    final notifier = ref.read(editorNotifierProvider.notifier);
...
                   child: TileLayerEnvironmentInspectorSection(
                     readModel: tileLayerEnvironmentReadModel,
+                    onEnableEnvironment: activeLayer is TileLayer &&
+                            tileLayerEnvironmentReadModel.canEnableEnvironment
+                        ? notifier.enableEnvironmentForActiveTileLayer
+                        : null,
                   ),
```

### Section callback

```diff
   const TileLayerEnvironmentInspectorSection({
     super.key,
     required this.readModel,
+    this.onEnableEnvironment,
   });

   final TileLayerEnvironmentAttachmentReadModel readModel;
+  final VoidCallback? onEnableEnvironment;
...
-          _FutureActions(readModel: readModel),
+          _FutureActions(
+            readModel: readModel,
+            onEnableEnvironment: onEnableEnvironment,
+          ),
```

### Tests ajoutés

Nouveaux tests :

- `tile_layer_environment_attachment_enable_use_case_test.dart`
- `tile_layer_environment_attachment_notifier_test.dart`

Tests modifiés :

- `tile_layer_environment_inspector_section_test.dart` ajoute le cas callback actif et vérifie que `Peindre`, `Générer`, `Effacer les placements générés` restent désactivés.

## 13. Auto-review

- Le bouton “Activer l’environnement” est-il le seul bouton mutant activé ? Oui.
- Le use case crée-t-il bien un EnvironmentLayer attaché ? Oui.
- Le TileLayer reste-t-il sélectionné ? Oui, couvert par test notifier.
- Aucune area n’est-elle créée ? Oui.
- Aucun MapPlacedElement n’est-il créé ? Oui.
- Le flow legacy reste-t-il intact ? Oui, aucun changement à `EnvironmentLayerInspectorPanel`.
- Le read model Environment-30 continue-t-il à fonctionner ? Oui, test +21 passé.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 14. Critique du prompt et du lot

Clair :

- mutation très bornée ;
- UX attendue claire ;
- règles de création/réutilisation explicites ;
- non-objectifs précis.

Ambigu :

- la stratégie d’id n’était pas imposée. Choix retenu : slug du nom TileLayer, suffixe numérique.
- le test notifier était indiqué “si raisonnable”. Il était raisonnable et ajouté.
- le message post-activation exact dépend du read model existant ; aucune refonte de message n’a été faite.

À trancher avant Environment-33 :

- bouton `Ajouter une zone` : auto-créer une area sans preset ou demander d’abord le preset ?
- nom par défaut de l’area ;
- sélection automatique de l’area créée ;
- garder ou masquer visuellement l’EnvironmentLayer technique dans la liste des layers lors d’un futur lot.

## 15. Verdict

```text
Environment-32 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-33 — TileLayer Environment Area Create Action V0
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
- [x] J’ai activé uniquement l’action “Activer l’environnement”.
- [x] Je n’ai pas créé d’EnvironmentArea.
- [x] Je n’ai pas créé de MapPlacedElement.
- [x] Je n’ai pas ajouté de brush.
- [x] Je n’ai pas lancé de génération.
- [x] Le TileLayer reste sélectionné après activation.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
