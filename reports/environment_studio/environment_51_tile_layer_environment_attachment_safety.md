# Environment-51 — TileLayer / Environment Attachment Safety V0

## 1. Résumé

Environment-51 ajoute un garde-fou autour de la suppression de layer : un `TileLayer` qui possède un `EnvironmentLayer` attaché valide ne peut plus être supprimé silencieusement.

Le lot ajoute :

- un resolver pur pour identifier les `EnvironmentLayer` attachés valides à un `TileLayer` ;
- un blocage applicatif dans `DeleteMapLayerUseCase` ;
- un message d’erreur clair via `EditorNotifier` ;
- une protection visuelle dans `LayersPanel` sur le bouton delete du `TileLayer` protégé ;
- des tests ciblés pour helper, use case, notifier et panneau des layers.

Aucune cascade delete n’a été ajoutée. Aucun `EnvironmentLayer` attaché n’est supprimé automatiquement.

## 2. Rappel de la décision UX

- `EnvironmentLayer` reste un détail technique.
- Le `TileLayer` inspector pilote l’environnement.
- Ce lot ajoute des garde-fous, pas une migration.
- V0 bloque une suppression dangereuse au lieu de supprimer automatiquement l’environnement attaché, ses zones, ses masques, ses paramètres et ses placements.

## 3. Orchestration sub-agents

Sub-agents / passes utilisés :

- Sub-agent A — Audit / Architecture : `Linnaeus`
- Sub-agent B — Domain / Attachment Safety : `Ohm`
- Sub-agent C — UI / LayersPanel Safety : `Raman`
- Sub-agent D — Selection / Legacy Compatibility : `Maxwell`
- Sub-agent E — QA / Evidence Pack : `Feynman`

Conclusions principales :

- Le chemin réel de suppression d’un layer est `LayersPanel` → `EditorNotifier.deleteMapLayer` → `DeleteMapLayerUseCase` → `removeMapLayer`.
- Le bon point de blocage est `DeleteMapLayerUseCase`, afin que la sécurité soit applicative et pas seulement visuelle.
- Le panneau `LayersPanel` peut désactiver le bouton delete sur un `TileLayer` protégé sans changer les actions des autres layers.
- Les `EnvironmentLayer` invalides restent visibles via la logique du Lot 47 et doivent rester supprimables.
- Le cas d’ouverture d’une map dont le premier layer serait un `EnvironmentLayer` attaché caché est une dette préexistante de sélection initiale, non corrigée dans ce lot.

Mini-plan documenté avant code :

1. Détecter les attachments valides avec un helper pur basé sur `EnvironmentLayer.content.targetTileLayerId`.
2. Bloquer `DeleteMapLayerUseCase` si le layer demandé est un `TileLayer` ciblé par au moins un attachment valide.
3. Laisser les `EnvironmentLayer` invalides / orphelins visibles et supprimables.
4. Désactiver le bouton delete dans `LayersPanel` pour les rows TileLayer qui portent `attachedEnvironmentLayerIds`.
5. Tester helper, use case, notifier, UI panel et non-régressions Environment.

## 4. Audit de l’existant

Fichiers inspectés :

- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart`
- `packages/map_editor/test/environment_studio/environment_layer_creation_test.dart`
- `packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/environment.dart`

Commandes d’audit principales :

```bash
git status --short --untracked-files=all
rg -n "deleteLayer|removeLayer|DeleteLayer|RemoveLayer|delete.*layer|remove.*layer|onDelete|trash|LayersPanel|LayerRow|targetTileLayerId|EnvironmentLayer|TileLayer|activeLayerId|setActiveLayer" packages/map_editor/lib/src packages/map_editor/test packages/map_core/lib/src
```

Chemin réel de suppression :

- `LayersPanel` affiche un bouton trash par row.
- Le bouton appelle `_showDeleteLayerDialog`.
- La confirmation appelle `EditorNotifier.deleteMapLayer(layer.id)`.
- Le notifier appelle `DeleteMapLayerUseCase().execute(map, layerId: layerId)`.
- Le use case appelle `removeMapLayer` puis `MapValidator.validate(updated)`.

Comportement existant avant Environment-51 :

- La suppression d’un `TileLayer` supprimait le layer et les `MapPlacedElement` portés par ce layer.
- Si un `EnvironmentLayer` attaché ciblait ce `TileLayer`, le modèle pouvait devenir invalide ou orphelin.
- Le Lot 47 groupait déjà l’`EnvironmentLayer` attaché derrière le `TileLayer`, donc l’utilisateur ne voyait pas forcément le layer technique qui allait être cassé.

Risques identifiés :

- Une protection seulement UI aurait laissé un appel direct au notifier supprimer le `TileLayer`.
- Une cascade delete automatique aurait été trop destructive pour V0.
- Les `EnvironmentLayer` invalides ne doivent pas être cachés ni bloqués, car ils servent au diagnostic.

## 5. Guard / helper

Helper ajouté :

```text
packages/map_editor/lib/src/application/services/environment_layer_tile_layer_attachment_resolver.dart
```

API ajoutée :

```dart
List<EnvironmentLayer> validEnvironmentLayerAttachmentsForTileLayer(
  MapData map,
  String tileLayerId,
)

bool layerHasValidEnvironmentAttachments(
  MapData map,
  String layerId,
)
```

Définition d’un attachment valide :

- le layer cible demandé existe ;
- le layer cible demandé est un `TileLayer` ;
- un `EnvironmentLayer` possède un `targetTileLayerId` non vide après `trim()` ;
- ce `targetTileLayerId` existe dans la map ;
- ce target est un `TileLayer` ;
- ce target correspond au `TileLayer` demandé.

Cas ignorés :

- id demandé vide ;
- layer demandé absent ;
- layer demandé non `TileLayer` ;
- `EnvironmentLayer` avec target `null` ;
- target vide ;
- target manquant ;
- target non `TileLayer` ;
- target différent.

Message d’erreur applicatif :

```text
Impossible de supprimer ce layer : un environnement lui est attaché.
```

## 6. Suppression TileLayer protégée

Comportement quand attachment valide :

- `DeleteMapLayerUseCase` lève `EditorValidationException`.
- `removeMapLayer` n’est pas appelé.
- `MapData` reste inchangée.
- `EditorNotifier.deleteMapLayer` expose le message métier dans `errorMessage`.

Comportement quand pas d’attachment :

- suppression inchangée ;
- les placements du layer supprimé continuent d’être retirés par le comportement existant ;
- `MapValidator.validate` reste appelé sur la map résultante.

Comportement `EnvironmentLayer` invalide :

- suppression autorisée ;
- aucun blocage par le guard ;
- le diagnostic reste possible tant que le layer invalide n’est pas supprimé volontairement.

## 7. Intégration UI LayersPanel

Ajouts UI :

- `LayerPanelPresentationRow` expose `hasAttachedEnvironmentLayers`.
- `LayerPanelPresentationRow` expose `isDeleteProtectedByEnvironmentAttachment`.
- `_LayerList` calcule `canDeleteLayer`.
- Le bouton trash du `TileLayer` protégé reçoit `onPressed: null`.
- Le tooltip devient :

```text
Suppression protégée : environnement attaché
```

Impact sur invalid layers :

- `EnvironmentLayer` invalide reste visible avec warning `Cible invalide`.
- Son bouton delete reste actif.
- Les autres layers gardent leurs actions existantes : sélection, visibilité, move up/down, rename, delete.

## 8. Tests

### Commande ciblée helper / use case / notifier

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_safety_test.dart
```

Résultat exact :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_attachment_safety_test.dart
00:00 +0: validEnvironmentLayerAttachmentsForTileLayer détecte les EnvironmentLayers attachés valides en ordre de layer
00:00 +1: validEnvironmentLayerAttachmentsForTileLayer ignore les targets nulles, manquantes, non TileLayer et différentes
00:00 +2: validEnvironmentLayerAttachmentsForTileLayer retourne vide pour un id vide, manquant ou non TileLayer
00:00 +3: DeleteMapLayerUseCase attachment safety refuse la suppression d’un TileLayer avec EnvironmentLayer attaché
00:00 +4: DeleteMapLayerUseCase attachment safety autorise la suppression d’un TileLayer sans EnvironmentLayer attaché
00:00 +5: DeleteMapLayerUseCase attachment safety autorise la suppression d’un EnvironmentLayer invalide
00:00 +6: EditorNotifier attachment safety bloque la suppression d’un TileLayer avec environnement attaché
00:00 +7: EditorNotifier attachment safety la suppression d’un TileLayer sans environnement reste inchangée
00:00 +8: EditorNotifier attachment safety la suppression d’un EnvironmentLayer invalide reste possible
00:00 +9: All tests passed!
```

Cas couverts :

- détection d’un attachment valide ;
- ignore target null / vide ;
- ignore target manquant ;
- ignore target non `TileLayer` ;
- ignore target différent ;
- refuse suppression `TileLayer` protégé ;
- autorise suppression `TileLayer` non protégé ;
- autorise suppression `EnvironmentLayer` invalide ;
- map inchangée quand le notifier refuse la suppression.

### Commande ciblée LayersPanel

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
```

Résultat exact :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
00:00 +0: TileLayer environment grouping LayersPanel affiche le TileLayer avec badge et masque la row technique
00:00 +1: TileLayer environment grouping LayersPanel EnvironmentLayer invalide reste visible avec warning
00:00 +2: TileLayer environment grouping LayersPanel sélection du TileLayer fonctionne toujours
00:00 +3: TileLayer environment grouping LayersPanel EnvironmentLayer attaché actif reste visible via le TileLayer
00:00 +4: TileLayer environment grouping LayersPanel layers non-environment restent affichés
00:00 +5: TileLayer environment grouping LayersPanel TileLayer avec EnvironmentLayer attaché protège delete
00:00 +6: TileLayer environment grouping LayersPanel EnvironmentLayer invalide reste supprimable
00:01 +7: All tests passed!
```

Cas ajoutés :

- le bouton delete du `TileLayer` avec environnement attaché est désactivé ;
- aucun dialogue `Delete Layer` ne s’ouvre quand le bouton protégé est tapé ;
- la map garde `decor`, `env_decor`, `objects` ;
- l’`EnvironmentLayer` invalide reste supprimable.

### Non-régressions

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart
flutter test test/environment_studio/environment_layer_creation_test.dart
flutter test test/surface_painter/surface_layer_creation_entry_test.dart
flutter test test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

Résultats exacts :

```text
## test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart
00:00 +7: All tests passed!

## test/environment_studio/environment_layer_creation_test.dart
00:01 +5: All tests passed!

## test/surface_painter/surface_layer_creation_entry_test.dart
00:00 +2: All tests passed!

## test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
EditorNotifier: loadProject(/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_DbRbw6/project.json)
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_DbRbw6/project.json
FileProjectRepository: Project loaded successfully
EditorNotifier: Project loaded, activeMapId=map-golden
EditorNotifier: loadMap(maps/golden.json)
EditorNotifier: Attempting to load map from: maps/golden.json
FileMapRepository: Loading map maps/golden.json from project /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_DbRbw6
FileMapRepository: Loading map from path: /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_DbRbw6/maps/golden.json
00:00 +1: All tests passed!

## test/environment_studio/environment_golden_slice_workflow_test.dart
00:00 +6: All tests passed!
```

## 9. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/services/environment_layer_tile_layer_attachment_resolver.dart lib/src/application/use_cases/layer_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/layers_panel.dart lib/src/ui/panels/layers_panel_presentation.dart test/environment_studio/tile_layer_environment_attachment_safety_test.dart test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
```

Résultat exact :

```text
Analyzing 7 items...
No issues found! (ran in 1.7s)
```

Dette préexistante hors lot :

- Le cas où `ProjectSessionController.openMapDocument` choisirait comme premier layer actif un `EnvironmentLayer` attaché ensuite caché par le grouping reste à traiter dans un lot ultérieur de sélection initiale / legacy safety.
- Ce lot ne modifie pas `deleteAllMapLayers`. Cette action existante supprime tous les layers ensemble et ne crée pas un `EnvironmentLayer` orphelin ciblant un `TileLayer` supprimé seul.

## 10. Fichiers créés/modifiés

Fichiers déjà présents avant Environment-51 et modifiés par ce lot :

- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart`

Fichiers créés par Environment-51 :

- `packages/map_editor/lib/src/application/services/environment_layer_tile_layer_attachment_resolver.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_safety_test.dart`
- `reports/environment_studio/environment_51_tile_layer_environment_attachment_safety.md`

Fichiers préexistants dans l’état Git non touchés :

- Aucun au début du lot : le `git status --short --untracked-files=all` initial ne contenait aucune ligne.

Problèmes réellement introduits par Environment-51 :

- Aucun identifié par les tests ciblés, les non-régressions lancées, l’analyse ciblée et `git diff --check`.

## 11. Non-objectifs respectés

- Pas de cascade delete.
- Pas de suppression automatique d’un `EnvironmentLayer` attaché.
- Pas de migration modèle.
- Pas de modification `map_core`.
- Pas de modification runtime.
- Pas de modification des use cases environment generate / clear / regenerate / shuffle.
- Pas de modification des use cases area rename/delete.
- Pas de modification add/delete individuel.
- Pas de modification canvas.
- Pas de build_runner.
- Pas de generated files.

## 12. Evidence pack

### Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact : aucune ligne.

### Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/layers_panel.dart
 M packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
?? packages/map_editor/lib/src/application/services/environment_layer_tile_layer_attachment_resolver.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_attachment_safety_test.dart
?? reports/environment_studio/environment_51_tile_layer_environment_attachment_safety.md
```

### Diff stat

Commande :

```bash
git diff --stat
```

Résultat exact :

```text
 .../src/application/use_cases/layer_use_cases.dart |  6 +++
 .../src/features/editor/state/editor_notifier.dart |  2 +
 .../map_editor/lib/src/ui/panels/layers_panel.dart | 21 +++++---
 .../src/ui/panels/layers_panel_presentation.dart   |  6 +++
 ...ayer_environment_layer_grouping_panel_test.dart | 61 ++++++++++++++++++++++
 5 files changed, 90 insertions(+), 6 deletions(-)
```

Note : `git diff --stat` liste les modifications des fichiers déjà suivis. Les fichiers créés non indexés sont listés dans les sorties `git status` ci-dessus.

### Diff name-only

Commande :

```bash
git diff --name-only
```

Résultat exact :

```text
packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/layers_panel.dart
packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart
packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
```

Note : `git diff --name-only` liste les fichiers déjà suivis modifiés. Les fichiers créés non indexés sont listés dans les sorties `git status`.

### Git diff check

Commande :

```bash
git diff --check
```

Résultat exact : aucune ligne.

### Format

Commande :

```bash
dart format packages/map_editor/lib/src/application/services/environment_layer_tile_layer_attachment_resolver.dart packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/panels/layers_panel.dart packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart packages/map_editor/test/environment_studio/tile_layer_environment_attachment_safety_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
```

Résultat exact :

```text
Formatted packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart
Formatted packages/map_editor/test/environment_studio/tile_layer_environment_attachment_safety_test.dart
Formatted 7 files (2 changed) in 0.06 seconds.
```

### Commandes principales

Commandes lancées :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_safety_test.dart
flutter test test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
flutter test test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart
flutter test test/environment_studio/environment_layer_creation_test.dart
flutter test test/surface_painter/surface_layer_creation_entry_test.dart
flutter test test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
flutter analyze lib/src/application/services/environment_layer_tile_layer_attachment_resolver.dart lib/src/application/use_cases/layer_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/layers_panel.dart lib/src/ui/panels/layers_panel_presentation.dart test/environment_studio/tile_layer_environment_attachment_safety_test.dart test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
git diff --check
```

Résultats :

- `tile_layer_environment_attachment_safety_test.dart` : `00:00 +9: All tests passed!`
- `tile_layer_environment_layer_grouping_panel_test.dart` : `00:01 +7: All tests passed!`
- `tile_layer_environment_layer_grouping_presentation_test.dart` : `00:00 +7: All tests passed!`
- `environment_layer_creation_test.dart` : `00:01 +5: All tests passed!`
- `surface_layer_creation_entry_test.dart` : `00:00 +2: All tests passed!`
- `tile_layer_environment_golden_slice_save_reload_test.dart` : `00:00 +1: All tests passed!`
- `environment_golden_slice_workflow_test.dart` : `00:00 +6: All tests passed!`
- Analyse ciblée : `No issues found! (ran in 1.7s)`
- `git diff --check` : aucune ligne.

## 13. Diff pertinent

Les fichiers UI et tests existants sont volumineux : `layers_panel.dart` contient 866 lignes, `tile_layer_environment_layer_grouping_panel_test.dart` contient 247 lignes. Les hunks ci-dessous reproduisent les changements apportés par Environment-51 et les assertions centrales. Le nouveau helper est reproduit en entier.

### Nouveau helper complet

```dart
import 'package:map_core/map_core.dart';

List<EnvironmentLayer> validEnvironmentLayerAttachmentsForTileLayer(
  MapData map,
  String tileLayerId,
) {
  final targetId = tileLayerId.trim();
  if (targetId.isEmpty) {
    return const [];
  }

  final layersById = {
    for (final layer in map.layers) layer.id: layer,
  };
  final targetLayer = layersById[targetId];
  if (targetLayer is! TileLayer) {
    return const [];
  }

  final attachments = <EnvironmentLayer>[];
  for (final layer in map.layers) {
    if (layer is! EnvironmentLayer) {
      continue;
    }
    final attachedTargetId = layer.content.targetTileLayerId?.trim();
    if (attachedTargetId == null || attachedTargetId.isEmpty) {
      continue;
    }
    final attachedTarget = layersById[attachedTargetId];
    if (attachedTarget is! TileLayer) {
      continue;
    }
    if (attachedTarget.id == targetLayer.id) {
      attachments.add(layer);
    }
  }
  return List<EnvironmentLayer>.unmodifiable(attachments);
}

bool layerHasValidEnvironmentAttachments(
  MapData map,
  String layerId,
) {
  return validEnvironmentLayerAttachmentsForTileLayer(map, layerId).isNotEmpty;
}
```

### `layer_use_cases.dart`

```diff
@@
 import 'package:map_core/map_core.dart';
 
 import '../errors/application_errors.dart';
+import '../services/environment_layer_tile_layer_attachment_resolver.dart';
@@
 class DeleteMapLayerUseCase {
   MapData execute(
     MapData map, {
     required String layerId,
   }) {
+    if (layerHasValidEnvironmentAttachments(map, layerId)) {
+      throw const EditorValidationException(
+        'Impossible de supprimer ce layer : un environnement lui est attaché.',
+      );
+    }
     final updated = removeMapLayer(map, layerId: layerId);
     MapValidator.validate(updated);
     return updated;
   }
 }
```

### `editor_notifier.dart`

```diff
@@
       _applyMapMutation(
         previousMap: map,
         updatedMap: updated,
         preferredActiveLayerId: nextActiveLayerId,
         statusMessage: 'Layer deleted',
       );
       _coerceEnvironmentMaskSelectionAfterMapChange();
+    } on EditorValidationException catch (e) {
+      state = state.copyWith(errorMessage: e.message);
     } catch (e) {
       state = state.copyWith(errorMessage: 'Failed to delete layer: $e');
     }
   }
```

### `layers_panel_presentation.dart`

```diff
@@
   bool get isTechnicalEnvironmentSelection =>
       technicalEnvironmentSelectionLabel != null;
+
+  bool get hasAttachedEnvironmentLayers =>
+      attachedEnvironmentLayerIds.isNotEmpty;
+
+  bool get isDeleteProtectedByEnvironmentAttachment =>
+      layer is TileLayer && hasAttachedEnvironmentLayers;
 }
```

### `layers_panel.dart`

```diff
@@
         final row = rows[index];
         final layer = row.layer;
         final isActive = row.isActive;
         final canMoveUp = row.layerIndex > 0;
         final canMoveDown = row.layerIndex < map.layers.length - 1;
+        final canDeleteLayer = !row.isDeleteProtectedByEnvironmentAttachment;
@@
                                       _LayersAccentIconButton(
+                                        key: ValueKey(
+                                          'delete-layer-${layer.id}',
+                                        ),
                                         accent: layerAccent,
-                                        onPressed: () => _showDeleteLayerDialog(
-                                          context,
-                                          notifier,
-                                          layer,
-                                        ),
+                                        onPressed: canDeleteLayer
+                                            ? () => _showDeleteLayerDialog(
+                                                  context,
+                                                  notifier,
+                                                  layer,
+                                                )
+                                            : null,
                                         icon: CupertinoIcons.trash,
-                                        tooltip: 'Delete layer',
+                                        tooltip: canDeleteLayer
+                                            ? 'Delete layer'
+                                            : 'Suppression protégée : environnement attaché',
                                         iconSize: 15,
                                       ),
@@
 class _LayersAccentIconButton extends StatefulWidget {
   const _LayersAccentIconButton({
+    super.key,
     required this.accent,
     required this.onPressed,
     required this.icon,
```

### Nouveau test de sécurité, assertions centrales

Le fichier complet contient 243 lignes avec fixtures explicites. Les blocs suivants couvrent les comportements nouveaux et les helpers de fixture utilisés par ces comportements.

```dart
group('validEnvironmentLayerAttachmentsForTileLayer', () {
  test('détecte les EnvironmentLayers attachés valides en ordre de layer', () {
    final map = _mapWithAttachedEnvironment(extraAttached: true);

    final attachments = validEnvironmentLayerAttachmentsForTileLayer(
      map,
      ' decor ',
    );

    expect(
      attachments.map((layer) => layer.id),
      ['env_decor', 'env_decor_alt'],
    );
  });

  test('ignore les targets nulles, manquantes, non TileLayer et différentes',
      () {
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 3, height: 3),
      layers: [
        _tileLayer('decor'),
        const ObjectLayer(id: 'objects', name: 'Objects'),
        _environmentLayer(id: 'env_null', targetLayerId: null),
        _environmentLayer(id: 'env_missing', targetLayerId: 'missing'),
        _environmentLayer(id: 'env_object', targetLayerId: 'objects'),
        _tileLayer('other_tile'),
        _environmentLayer(id: 'env_other', targetLayerId: 'other_tile'),
      ],
    );

    final attachments = validEnvironmentLayerAttachmentsForTileLayer(
      map,
      'decor',
    );

    expect(attachments, isEmpty);
  });
});

group('DeleteMapLayerUseCase attachment safety', () {
  test('refuse la suppression d’un TileLayer avec EnvironmentLayer attaché',
      () {
    final map = _mapWithAttachedEnvironment();

    expect(
      () => DeleteMapLayerUseCase().execute(map, layerId: 'decor'),
      throwsA(
        isA<EditorValidationException>().having(
          (error) => error.message,
          'message',
          contains('environnement lui est attaché'),
        ),
      ),
    );
    expect(map.layers.map((layer) => layer.id),
        ['decor', 'env_decor', 'objects']);
  });

  test('autorise la suppression d’un TileLayer sans EnvironmentLayer attaché',
      () {
    final map = _mapWithoutAttachedEnvironment();

    final updated = DeleteMapLayerUseCase().execute(
      map,
      layerId: 'decor',
    );

    expect(updated.layers.map((layer) => layer.id), ['objects']);
    expect(updated.placedElements, isEmpty);
  });

  test('autorise la suppression d’un EnvironmentLayer invalide', () {
    final map = _mapWithInvalidEnvironment();

    final updated = DeleteMapLayerUseCase().execute(
      map,
      layerId: 'env_missing',
    );

    expect(updated.layers.map((layer) => layer.id), ['decor']);
  });
});

group('EditorNotifier attachment safety', () {
  test('bloque la suppression d’un TileLayer avec environnement attaché', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final map = _mapWithAttachedEnvironment();
    notifier.state = EditorState(
      activeMap: map,
      activeLayerId: 'decor',
    );

    notifier.deleteMapLayer('decor');

    final state = notifier.state;
    expect(state.activeMap, same(map));
    expect(state.activeLayerId, 'decor');
    expect(state.errorMessage, contains('environnement lui est attaché'));
  });
});
```

### Test LayersPanel ajouté

```dart
testWidgets('TileLayer avec EnvironmentLayer attaché protège delete',
    (tester) async {
  final container = await _pumpLayersPanel(
    tester,
    activeLayerId: 'decor',
    map: _mapWithAttachedEnvironment(),
  );

  final deleteButton = _deleteLayerButton(tester, 'decor');

  expect(deleteButton.onPressed, isNull);

  await tester.tap(find.byKey(const ValueKey('delete-layer-decor')));
  await tester.pumpAndSettle();

  expect(find.text('Delete Layer'), findsNothing);
  expect(
    container
        .read(editorNotifierProvider)
        .activeMap!
        .layers
        .map((layer) => layer.id),
    ['decor', 'env_decor', 'objects'],
  );
});

testWidgets('EnvironmentLayer invalide reste supprimable', (tester) async {
  final container = await _pumpLayersPanel(
    tester,
    activeLayerId: 'env_missing',
    map: _mapWithInvalidEnvironment(),
  );

  final deleteButton = _deleteLayerButton(tester, 'env_missing');

  expect(deleteButton.onPressed, isNotNull);

  await tester.tap(find.byKey(const ValueKey('delete-layer-env_missing')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  expect(
    container
        .read(editorNotifierProvider)
        .activeMap!
        .layers
        .map((layer) => layer.id),
    ['decor'],
  );
});

CupertinoButton _deleteLayerButton(WidgetTester tester, String layerId) {
  return tester.widget<CupertinoButton>(
    find.descendant(
      of: find.byKey(ValueKey('delete-layer-$layerId')),
      matching: find.byType(CupertinoButton),
    ),
  );
}
```

## 14. Auto-review

- La suppression d’un `TileLayer` avec environnement attaché est-elle bloquée ? Oui, dans `DeleteMapLayerUseCase`.
- La map reste-t-elle inchangée si suppression refusée ? Oui, le test notifier vérifie `same(map)`.
- La suppression d’un `TileLayer` sans environnement reste-t-elle possible ? Oui.
- Les `EnvironmentLayer` invalides restent-ils visibles ? Oui, la présentation du Lot 47 reste en place et le test panel le vérifie.
- Les `EnvironmentLayer` invalides restent-ils supprimables si le système le permet ? Oui, test panel et test use case.
- La sécurité est-elle applicative et pas seulement UI ? Oui, le use case bloque l’appel direct.
- Le grouping `LayersPanel` reste-t-il intact ? Oui, non-régression `tile_layer_environment_layer_grouping_presentation_test.dart` et `tile_layer_environment_layer_grouping_panel_test.dart`.
- Le flow TileLayer-centric reste-t-il intact ? Oui, non-régressions golden slice et save/reload passées.
- Le flow legacy reste-t-il intact ? Oui, les invalid layers restent visibles/supprimables ; aucune suppression automatique n’est ajoutée.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 15. Critique du prompt et du lot

Clair :

- La règle V0 `Block > silent destructive cascade`.
- La définition d’un attachment valide.
- L’obligation de sécurité applicative.
- Le maintien des `EnvironmentLayer` invalides visibles / supprimables.

Ambigu :

- Le comportement de `deleteAllMapLayers` n’était pas explicitement demandé. Il ne crée pas le cas dangereux ciblé, car tout est supprimé ensemble, donc il n’a pas été changé.
- Le tooltip exact du bouton delete protégé dépend de la structure Macos/Cupertino existante ; le test vérifie plutôt l’état désactivé et l’absence de dialogue.

À trancher avant Environment-52 :

- Ajouter ou non une action explicite “Désactiver / supprimer l’environnement attaché”.
- Ajouter une confirmation destructive pour les suppressions de zone et d’environnement.
- Sécuriser la sélection initiale si une map legacy active un `EnvironmentLayer` attaché masqué.

## 16. Verdict

```text
Environment-51 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-52 — Final Environment Closure / Destructive Actions Polish V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement des garde-fous d’attachement.
- [x] Je n’ai pas ajouté de cascade delete.
- [x] Je n’ai pas supprimé d’EnvironmentLayer attaché automatiquement.
- [x] Je n’ai pas migré le modèle.
- [x] La suppression protégée est applicative, pas seulement UI.
- [x] Les EnvironmentLayers invalides restent visibles.
- [x] Le grouping LayersPanel reste intact.
- [x] Le flow TileLayer-centric reste intact.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
