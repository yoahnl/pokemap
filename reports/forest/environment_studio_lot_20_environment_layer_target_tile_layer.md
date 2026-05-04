# Environment Studio Lot 20 — Environment Layer Target TileLayer V0

## 1. Résumé exécutif

L’inspecteur **Environment Layer** permet désormais de lire et de modifier **`EnvironmentLayerContent.targetTileLayerId`** : affichage de l’état (aucune tuile, pas de cible, cible valide, cible invalide conservée), choix exclusif parmi les **TileLayer** de la map via le picker existant (`showCupertinoListPicker`), retrait de la cible (`null`). La mutation passe par **`SetEnvironmentLayerTargetTileLayerUseCase`** qui s’appuie sur **`setEnvironmentLayerContent`** (map_core, inchangé) + **`MapValidator.validate`**, puis **`EditorNotifier.setEnvironmentLayerTargetTileLayer`** et **`_applyMapMutation`** (même pattern dirty / sélection que les autres éditions de map). Aucune `EnvironmentArea` créée, aucun `map_core` modifié, aucune persistance disque sur ce flux.

## 2. Périmètre du lot

Inclus : UI inspecteur + use case + méthode notifier + tests ciblés + régressions `environment_studio` et barre d’outils / workspace. Exclus : areas, masques, presets par area, génération, `MapPlacedElement`, patch tuiles, `ProjectManifest`, `map_runtime`, `build_runner`, commits git.

## 3. Audit initial EnvironmentLayer / inspector / mutations

Fichiers relus : `layer_use_cases.dart`, `editor_notifier.dart` (`_applyMapMutation`), `map_inspector_panel.dart`, `layers_panel.dart`, `environment.dart` / `map_layer.dart` / `map_layers.dart` (lecture seule), tests Lot 19.

Constats :

- **map_core** expose déjà **`setEnvironmentLayerContent(map, layerId, content)`** qui remplace le contenu d’un `EnvironmentLayer` en conservant id / nom / visibilité / opacité / properties.
- **`MapValidator`** valide qu’une cible non nulle référence un **TileLayer** existant et interdit l’auto-référence (`targetTileLayerId == layerId`).
- Les mutations carte passent par **`EditorNotifier`** → **`_applyMapMutation`** → `MapEditingController.applyMutation` (dirty via `savedMapSnapshot`).
- L’inspecteur lit **`activeMap`** + **`activeLayer`** via `editorNotifierProvider` ; la section Environment est affichée quand `activeLayer is EnvironmentLayer`.

Recherches grep (extraits pertinents) :

- `setEnvironmentLayerContent` : défini dans `packages/map_core/lib/src/operations/map_layers.dart` (non modifié ce lot).
- `targetTileLayerId` : modèle `EnvironmentLayerContent` + usages diagnostics / tests map_core (non modifiés).
- **`map_core` n’est pas modifié** : seuls les appels existants sont utilisés depuis `map_editor`.

## 4. Décisions UI target TileLayer

- Textes FR conformes au cahier (aucune cible, aucun TileLayer, cible actuelle nom + id, invalide avec id affiché, boutons « Choisir / Changer / Retirer / Choisir un autre »).
- Sous-titre de section **TileLayer cible** distinct du bloc d’introduction Lot 19 (titres + corps conservés avec les mêmes `Key` pour non-régression tests Lot 19).
- Picker : uniquement les instances **`TileLayer`** collectées sur `map.layers`.
- Cible invalide : **pas de suppression automatique** ; l’UI propose correction ou retrait.

## 5. Mutation targetTileLayerId

- **`SetEnvironmentLayerTargetTileLayerUseCase.execute`** : vérifie l’id du layer Environment, valide la cible si non null (existe, est `TileLayer`, ≠ id du layer Environment), construit **`EnvironmentLayerContent(targetTileLayerId: …, areas: contenu.areas existant)`** pour préserver les zones, appelle **`setEnvironmentLayerContent`**, puis **`MapValidator.validate`**. Les **`ValidationException`** map_core sont enveloppées en **`EditorValidationException`** pour homogénéité côté éditeur.
- **`EditorNotifier.setEnvironmentLayerTargetTileLayer`** : instancie le use case (sans nouveau provider Riverpod pour éviter **`build_runner`**), applique **`_applyMapMutation`** avec **`preferredActiveLayerId: environmentLayerId`**.

## 6. Inspector Environment Layer

- Nouveau fichier **`environment_layer_inspector_panel.dart`** : widget **`EnvironmentLayerInspectorPanel`** (`ConsumerWidget`).
- **`map_inspector_panel.dart`** : remplace le placeholder interne par ce panneau, **`expandedHeight`** porté à **360**.

## 7. Dirty state / sélection active

Comportement identique aux autres mutations : **`_applyMapMutation`** avec carte mise à jour ; **`activeLayerId`** forcé sur l’Environment layer ; **`isDirty`** si la carte diffère du **`savedMapSnapshot`** (test notifier avec snapshot initial explicite).

## 8. Validation des cibles TileLayer

- Picker UI : seuls des **`TileLayer`** peuvent être choisis.
- Use case : rejette **`ObjectLayer`**, **`TileLayer`** passé comme `environmentLayerId`, id inconnu, auto-cible.

## 9. Non-persistance disque garantie

Aucun appel **`FileProjectRepository`**, **`saveProject`**, **`saveProjectManifest`** dans les fichiers du flux (`environment_layer_inspector_panel`, `map_inspector_panel`, `layer_use_cases`). Le grep sur **`editor_notifier`** ne trouve que des méthodes hors chemin `setEnvironmentLayerTargetTileLayer` (sortie en section 14).

## 10. Pourquoi aucune area / mask / preset / génération dans ce lot

Périmètre V0 strict : seule la **référence** au TileLayer cible pour les lots futurs (zones, génération, patchs). Aucune édition de **`EnvironmentArea`** ni de masque.

## 11. Fichiers modifiés

| Fichier | Rôle |
|---------|------|
| `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart` | `SetEnvironmentLayerTargetTileLayerUseCase`. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | `setEnvironmentLayerTargetTileLayer` + import use case. |
| `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` | Intégration panneau + hauteur section. |
| `packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart` | **Nouveau** — UI cible tuile. |
| `packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart` | **Nouveau** — tests use case, notifier, widgets. |
| `reports/forest/environment_studio_lot_20_environment_layer_target_tile_layer.md` | Ce rapport. |

## 12. Tests ajoutés ou modifiés

- **Nouveau** : `environment_layer_target_tile_layer_test.dart` (use case, notifier, inspecteur MapInspector, picker, retrait, invalide, panneau isolé, exclusion Object dans `MacosSheet`).
- **Non modifié** : `environment_layer_creation_test.dart` (régression Lot 19 ; toujours vert).

## 13. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/application/use_cases/layer_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/environment_layer_inspector_panel.dart test/environment_studio/environment_layer_target_tile_layer_test.dart
flutter analyze lib/src/application/use_cases/layer_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/environment_layer_inspector_panel.dart test/environment_studio/environment_layer_target_tile_layer_test.dart test/environment_studio/environment_layer_creation_test.dart
grep -R "FileProjectRepository\|saveProject\|saveProjectManifest" -n lib/src/ui/panels/environment_layer_inspector_panel.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/features/editor/state/editor_notifier.dart lib/src/application/use_cases/layer_use_cases.dart || true
flutter test test/environment_studio/environment_layer_target_tile_layer_test.dart test/environment_studio/environment_layer_creation_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test
```

## 14. Résultats des commandes

### `dart format`

Exécuté sur les chemins du lot (voir §13) : exit code 0.

### `flutter analyze` (6 fichiers)

```
Analyzing 6 items...                                            
No issues found! (ran in 1.7s)
```

### Grep persistance (chemins lot)

Commande :

```bash
grep -R "FileProjectRepository\|saveProject\|saveProjectManifest" -n \
  lib/src/ui/panels/environment_layer_inspector_panel.dart \
  lib/src/ui/panels/map_inspector_panel.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/application/use_cases/layer_use_cases.dart || true
```

Sortie (répertoire `packages/map_editor`) :

```
lib/src/features/editor/state/editor_notifier.dart:438:  Future<bool> saveProjectManifest() async {
lib/src/features/editor/state/editor_notifier.dart:447:    debugPrint('EditorNotifier: saveProjectManifest()');
lib/src/features/editor/state/editor_notifier.dart:449:      await ref.read(projectRepositoryProvider).saveProject(
lib/src/features/editor/state/editor_notifier.dart:1489:  Future<void> saveProjectDialogueYarnBody({
lib/src/features/editor/state/editor_notifier.dart:1493:    state = await _projectContentController.saveProjectDialogueYarnBody(
```

### `flutter test` Lot 19 + Lot 20 (fichiers cibles)

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer SetEnvironmentLayerTargetTileLayerUseCase définit targetTileLayerId et préserve areas
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer SetEnvironmentLayerTargetTileLayerUseCase target null remet targetTileLayerId à null
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer SetEnvironmentLayerTargetTileLayerUseCase rejette cible ObjectLayer
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer SetEnvironmentLayerTargetTileLayerUseCase rejette environmentLayerId TileLayer
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer SetEnvironmentLayerTargetTileLayerUseCase rejette id inconnu pour environmentLayerId
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer SetEnvironmentLayerTargetTileLayerUseCase rejette auto-cible
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer EditorNotifier.setEnvironmentLayerTargetTileLayer met à jour activeMap, garde activeLayerId, isDirty, chemins stables
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer inspecteur : aucun TileLayer
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:01 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer choix TileLayer via picker met à jour la cible et dirty
00:01 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer retirer la cible remet null
00:01 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer retirer la cible remet null
00:01 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map MapInspector : section neutre quand EnvironmentLayer actif
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer cible invalide affiche avertissement et actions
00:01 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer cible invalide affiche avertissement et actions
00:01 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer EnvironmentLayerInspectorPanel seul : pas de crash
00:01 +19: All tests passed!
```

### `flutter test test/environment_studio` (régression dossier)

Dernières lignes du journal `/tmp/lot20_env_studio.log` :

```
00:05 +121: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) tags : tree, canopy OK ; tree, , canopy → Tag vide
00:05 +122: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) Retirer : palette vide, emptyPalette revient
00:06 +123: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) deux items même elementId : Élément dupliqué
00:06 +124: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) édition palette + retour browser : manifest.environmentPresets inchangé
00:06 +125: All tests passed!
     227 /tmp/lot20_env_studio.log
```

### `flutter test` workspace + top toolbar

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokedexWorkspace switches mode and clears stale errors
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectTrainerWorkspace switches mode and clears stale errors
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectDialogueWorkspace keeps project session and only changes mode
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectEnvironmentStudioWorkspace switches mode and clears stale errors
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokemonCatalogSection opens the parent workspace and stores the section
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the app brand and project workspace label
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar falls back to the workspace label when no project is loaded
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the toolbar status chip when a status is present
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the trainer studio label for the trainer workspace
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Path Studio
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows neutral Save Project when project is clean in Path Studio
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Environment Studio
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows Environment Studio in the workspace brand strip
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar keeps map save action in map workspace
00:01 +14: All tests passed!
```

### `flutter test` (suite complète `packages/map_editor`)

Exit code **1** (dette hors lot : nombreux échecs préexistants, ex. suite catalogue/sync Pokémon). Dernières lignes observées :

```
01:03 +958 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync
01:03 +958 -34: Some tests failed.
```

## 15. Git status initial et final

**État initial** : le dépôt présentait déjà des modifications non commit hors périmètre Lot 20 au début de la session utilisateur (voir `git status` initial dans le fil de discussion / worktree).

**État final** (`git status --short --untracked-files=all`, racine du repo) :

```
 M packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
?? packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
?? packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart
?? reports/forest/environment_studio_lot_20_environment_layer_target_tile_layer.md
```

## 16. Contenu complet des fichiers créés ou modifiés

### `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

class AddMapLayerResult {
  final MapData map;
  final MapLayer layer;

  AddMapLayerResult(this.map, this.layer);
}

class AddMapLayerUseCase {
  AddMapLayerResult execute(
    MapData map, {
    required MapLayerKind kind,
    required String name,
    String? tileTilesetId,
    int? insertIndex,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const EditorValidationException('Layer name cannot be empty');
    }

    final layerId = _generateUniqueLayerId(
      map,
      kind: kind,
      name: normalizedName,
    );

    final updated = addMapLayer(
      map,
      kind: kind,
      id: layerId,
      name: normalizedName,
      tileTilesetId: tileTilesetId,
      insertIndex: insertIndex,
    );
    MapValidator.validate(updated);

    final created = updated.layers.firstWhere((layer) => layer.id == layerId);
    return AddMapLayerResult(updated, created);
  }

  AddMapLayerResult executeSurface(
    MapData map, {
    String name = 'Surfaces',
    int? insertIndex,
  }) {
    final normalizedName = name.trim().isEmpty ? 'Surfaces' : name.trim();
    final layerId = _generateUniqueSurfaceLayerId(map);
    final layerName = _resolveSurfaceLayerName(map, normalizedName);
    final layer = MapLayer.surface(
      id: layerId,
      name: layerName,
    );

    var targetIndex = insertIndex ?? map.layers.length;
    if (targetIndex < 0) targetIndex = 0;
    if (targetIndex > map.layers.length) targetIndex = map.layers.length;

    final updatedLayers = List<MapLayer>.from(map.layers, growable: true)
      ..insert(targetIndex, layer);
    final updated = map.copyWith(layers: updatedLayers);
    MapValidator.validate(updated);
    return AddMapLayerResult(updated, layer);
  }

  String _generateUniqueLayerId(
    MapData map, {
    required MapLayerKind kind,
    required String name,
  }) {
    final existing = map.layers.map((layer) => layer.id).toSet();
    final kindPrefix = switch (kind) {
      MapLayerKind.tile => 'l_tile',
      MapLayerKind.collision => 'l_collision',
      MapLayerKind.terrain => 'l_terrain',
      MapLayerKind.path => 'l_path',
      MapLayerKind.object => 'l_object',
      MapLayerKind.environment => 'l_environment',
    };
    final slug = _slugifyLayerName(name);
    final base = slug.isEmpty ? kindPrefix : '${kindPrefix}_$slug';
    var candidate = base;
    var suffix = 1;
    while (existing.contains(candidate)) {
      candidate = '${base}_$suffix';
      suffix++;
    }
    return candidate;
  }

  String _generateUniqueSurfaceLayerId(MapData map) {
    final existing = map.layers.map((layer) => layer.id).toSet();
    const base = 'surface-main';
    if (!existing.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existing.contains('surface-$suffix')) {
      suffix++;
    }
    return 'surface-$suffix';
  }

  String _resolveSurfaceLayerName(MapData map, String requestedName) {
    if (requestedName != 'Surfaces') {
      return requestedName;
    }
    final existing = map.layers.map((layer) => layer.name).toSet();
    const base = 'Surfaces';
    if (!existing.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existing.contains('$base $suffix')) {
      suffix++;
    }
    return '$base $suffix';
  }

  String _slugifyLayerName(String value) {
    final lowered = value.toLowerCase().trim();
    final replaced = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final normalized = replaced.replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized;
  }
}

class RenameMapLayerUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required String name,
  }) {
    final updated = renameMapLayer(
      map,
      layerId: layerId,
      name: name,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteMapLayerUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
  }) {
    final updated = removeMapLayer(map, layerId: layerId);
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteAllMapLayersUseCase {
  MapData execute(MapData map) {
    final updated = removeAllMapLayers(map);
    MapValidator.validate(updated);
    return updated;
  }
}

class MoveMapLayerUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required int direction,
  }) {
    final updated = moveMapLayer(
      map,
      layerId: layerId,
      direction: direction,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class ReorderMapLayersUseCase {
  MapData execute(
    MapData map, {
    required int oldIndex,
    required int newIndex,
  }) {
    final updated = reorderMapLayers(
      map,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class SetMapLayerVisibilityUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required bool isVisible,
  }) {
    final updated = setMapLayerVisibility(
      map,
      layerId: layerId,
      isVisible: isVisible,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class SetMapLayerOpacityUseCase {
  MapData execute(
    MapData map, {
    required String layerId,
    required double opacity,
  }) {
    final updated = setMapLayerOpacity(
      map,
      layerId: layerId,
      opacity: opacity,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

/// Lot Environment-20 : cible tuile pour un [EnvironmentLayer] (mutation map pure).
class SetEnvironmentLayerTargetTileLayerUseCase {
  MapData execute(
    MapData map, {
    required String environmentLayerId,
    required String? targetTileLayerId,
  }) {
    final envId = environmentLayerId.trim();
    if (envId.isEmpty) {
      throw const EditorValidationException(
          'Environment layer id cannot be empty');
    }

    MapLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        envLayer = layer;
        break;
      }
    }
    if (envLayer == null) {
      throw EditorValidationException('Environment layer not found: $envId');
    }
    if (envLayer is! EnvironmentLayer) {
      throw EditorValidationException(
          'Layer is not an environment layer: $envId');
    }

    if (targetTileLayerId == null) {
      final nextContent = EnvironmentLayerContent(
        targetTileLayerId: null,
        areas: envLayer.content.areas,
      );
      try {
        final updated = setEnvironmentLayerContent(
          map,
          layerId: envId,
          content: nextContent,
        );
        MapValidator.validate(updated);
        return updated;
      } on ValidationException catch (e) {
        throw EditorValidationException(e.message);
      }
    }

    final tid = targetTileLayerId.trim();
    if (tid.isEmpty) {
      throw const EditorValidationException(
          'Target tile layer id cannot be empty');
    }
    if (tid == envId) {
      throw const EditorValidationException(
        'Environment layer cannot target itself as targetTileLayerId',
      );
    }

    MapLayer? targetLayer;
    for (final layer in map.layers) {
      if (layer.id == tid) {
        targetLayer = layer;
        break;
      }
    }
    if (targetLayer == null) {
      throw EditorValidationException('Target tile layer not found: $tid');
    }
    if (targetLayer is! TileLayer) {
      throw EditorValidationException(
        'targetTileLayerId must reference a TileLayer, got ${targetLayer.runtimeType}',
      );
    }

    final nextContent = EnvironmentLayerContent(
      targetTileLayerId: tid,
      areas: envLayer.content.areas,
    );
    try {
      final updated = setEnvironmentLayerContent(
        map,
        layerId: envId,
        content: nextContent,
      );
      MapValidator.validate(updated);
      return updated;
    } on ValidationException catch (e) {
      throw EditorValidationException(e.message);
    }
  }
}
```

### `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/content_studio_providers.dart';
import '../../../app/providers/core_providers.dart';
import '../../../app/providers/editor_workspace_providers.dart';
import '../../../app/providers/use_case_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/use_cases/layer_use_cases.dart';
import '../../../application/models/trainer_field_update.dart';
import '../../../application/models/map_tool_preview.dart';
import '../../../application/models/path_autotile_set.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/services/editor_map_session_coordinator.dart';
import '../../../application/services/editor_map_mutation_coordinator.dart';
import '../../../application/services/element_collision_profile_generator.dart';
import '../../../application/services/entity_editing_service.dart';
import '../../../application/services/gameplay_zone_editing_service.dart';
import '../../../application/services/map_connection_editing_service.dart';
import '../../../application/services/path_autotile_resolver.dart';
import '../../../application/services/path_layer_editing_coordinator.dart';
import '../../../application/services/placed_element_instance_indexer.dart';
import '../../../application/services/terrain_painting_coordinator.dart';
import '../../../application/services/terrain_preset_resolver.dart';
import '../../../application/services/terrain_preset_selection_coordinator.dart';
import '../../../application/services/trigger_editing_service.dart';
import '../../../application/services/warp_editing_service.dart';
import '../application/editor_workspace_controller.dart';
import '../application/map_editing_controller.dart';
import '../application/map_selection_controller.dart';
import '../application/project_content_controller.dart';
import '../application/project_session_controller.dart';
import '../application/project_session_models.dart';
import '../tools/editor_tool.dart';
import 'editor_state.dart';
import '../../surface_painter/surface_painting_controller.dart';

part 'editor_notifier.g.dart';

/// Valeur sentinelle pour les paramètres optionnels nullable dans [EditorNotifier].
const Object _trainerUnset = Object();
const String _lastOpenedProjectManifestKey = 'lastOpenedProjectManifestPath';
const String _editorSessionFileName = 'editor_session_state.json';
const MethodChannel _macOsFileAccessChannel =
    MethodChannel('map_editor/file_access');

@riverpod
class EditorNotifier extends _$EditorNotifier {
  EditorWorkspaceController get _editorWorkspaceController =>
      ref.read(editorWorkspaceControllerProvider);
  MapEditingController get _mapEditingController => MapEditingController(
        mutationCoordinator: _editorMapMutationCoordinator,
      );
  MapSelectionController get _mapSelectionController => MapSelectionController(
        terrainPresetSelectionCoordinator: _terrainPresetSelectionCoordinator,
      );
  ProjectContentController get _projectContentController =>
      ref.read(projectContentControllerProvider);
  ProjectSessionController get _projectSessionController =>
      const ProjectSessionController();
  TerrainPresetResolver get _terrainPresetResolver =>
      ref.read(terrainPresetResolverProvider);
  TerrainPresetSelectionCoordinator get _terrainPresetSelectionCoordinator =>
      ref.read(terrainPresetSelectionCoordinatorProvider);
  PathAutotileResolver get _pathAutotileResolver =>
      ref.read(pathAutotileResolverProvider);
  EditorMapSessionCoordinator get _editorMapSessionCoordinator =>
      ref.read(editorMapSessionCoordinatorProvider);
  EditorMapMutationCoordinator get _editorMapMutationCoordinator =>
      ref.read(editorMapMutationCoordinatorProvider);
  ProjectWorkspaceFactory get _projectWorkspaceFactory =>
      ref.read(projectWorkspaceFactoryProvider);
  ProjectWorkspace? get _projectWorkspace {
    final projectRootPath = state.projectSession.projectRootPath;
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return null;
    }
    return _projectWorkspaceFactory.create(projectRootPath);
  }

  WarpEditingService get _warpEditingService =>
      ref.read(warpEditingServiceProvider);
  EntityEditingService get _entityEditingService =>
      ref.read(entityEditingServiceProvider);
  TriggerEditingService get _triggerEditingService =>
      ref.read(triggerEditingServiceProvider);
  GameplayZoneEditingService get _gameplayZoneEditingService =>
      ref.read(gameplayZoneEditingServiceProvider);
  MapConnectionEditingService get _mapConnectionEditingService =>
      ref.read(mapConnectionEditingServiceProvider);
  TerrainPaintingCoordinator get _terrainPaintingCoordinator =>
      ref.read(terrainPaintingCoordinatorProvider);
  PathLayerEditingCoordinator get _pathLayerEditingCoordinator =>
      ref.read(pathLayerEditingCoordinatorProvider);
  SurfacePaintingController get _surfacePaintingController =>
      const SurfacePaintingController();
  ElementCollisionProfileGenerator get _elementCollisionProfileGenerator =>
      ref.read(elementCollisionProfileGeneratorProvider);
  PlacedElementInstanceIndexer get _placedElementInstanceIndexer =>
      ref.read(placedElementInstanceIndexerProvider);

  TerrainPresetSelection _currentTerrainPresetSelection() {
    final selection = state.selection;
    return TerrainPresetSelection(
      selectionMode: selection.terrainSelectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
    );
  }

  EditorState _copyStateWithTerrainPresetSelection(
    EditorState source,
    TerrainPresetSelection selection, {
    String? statusMessage,
    String? errorMessage,
    EditorToolType? activeTool,
  }) {
    return source.copyWith(
      terrainSelectionMode: selection.selectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
      activeTool: activeTool ?? source.activeTool,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  EditorState build() {
    return const EditorState();
  }

  /// Returns the persisted manifest path of the most recently opened project.
  ///
  /// This is intentionally tiny and file-based (single JSON file in app support)
  /// to keep startup deterministic and avoid introducing extra dependencies.
  Future<String?> getLastOpenedProjectManifestPath() async {
    try {
      final file = await _sessionStateFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final value = decoded[_lastOpenedProjectManifestKey];
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      // Startup memory should never crash the editor. Any corrupted or
      // unreadable state is treated as "no remembered project".
      return null;
    }
  }

  /// Attempts to load the last opened project (if any).
  ///
  /// Returns true only when a project was actually restored.
  Future<bool> restoreLastOpenedProjectIfAny() async {
    // Do not override an already loaded project.
    if (state.project != null) {
      return false;
    }
    // On macOS sandbox, a plain path is not enough after restart.
    // We first ask native code to resolve a security-scoped bookmark if any.
    final manifestPath = await _resolveLastProjectManifestFromMacOsBookmark() ??
        await getLastOpenedProjectManifestPath();
    if (manifestPath == null) {
      return false;
    }
    if (!await File(manifestPath).exists()) {
      // Clear stale memory so the app won't re-check a dead path forever.
      await _clearLastOpenedProjectMemory();
      return false;
    }
    if (!await _isManifestReadable(manifestPath)) {
      // macOS can report that the path exists but still deny read access
      // (Desktop/Documents permission not granted to the app process).
      //
      // In that case we do NOT call `loadProject`, otherwise we'd surface a
      // noisy PathAccessException on every launch.
      await _clearLastOpenedProjectMemory();
      state = state.copyWith(
        errorMessage: null,
        statusMessage:
            'Dernier projet détecté, mais accès refusé par macOS. Ouvrez-le manuellement pour réautoriser l’accès.',
      );
      return false;
    }
    // Auto-restore must be resilient:
    // - no noisy startup error toast if macOS denies access to remembered path
    //   (common when the path is on Desktop/Documents and the app lost grant).
    // - no endless retry loop on next launch if access is denied.
    await loadProject(
      manifestPath,
      silentOnError: true,
      rememberAsRecent: false,
    );
    final restored = state.project != null;
    if (!restored) {
      // Important anti-loop guard:
      // if we failed to restore (permissions / deleted file / parse error),
      // drop the remembered path so startup stays clean next launch.
      await _clearLastOpenedProjectMemory();
    }
    return restored;
  }

  Future<void> createProject(String name, String directory) async {
    debugPrint('EditorNotifier: createProject($name, $directory)');
    try {
      final useCase = ref.read(createProjectUseCaseProvider);
      final manifest = await useCase.execute(name, directory);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: directory,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Project "$name" created successfully',
      );
      await _rememberLastOpenedProjectManifest(
        p.join(directory, 'project.json'),
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating project: $e');
      state = state.copyWith(errorMessage: 'Failed to create project: $e');
    }
  }

  Future<void> loadProject(
    String manifestPath, {
    bool silentOnError = false,
    bool rememberAsRecent = true,
  }) async {
    // Keep this trace for explicit user actions, but avoid noisy startup logs
    // when running a silent auto-restore attempt.
    if (!silentOnError) {
      debugPrint('EditorNotifier: loadProject($manifestPath)');
    }
    try {
      final useCase = ref.read(loadProjectUseCaseProvider);
      final manifest = await useCase.execute(manifestPath);
      final projectDir = p.dirname(manifestPath);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: projectDir,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Project "${manifest.name}" loaded',
      );
      if (rememberAsRecent) {
        await _rememberLastOpenedProjectManifest(manifestPath);
      }
    } catch (e) {
      if (!silentOnError) {
        debugPrint('EditorNotifier: Error loading project: $e');
      }
      if (silentOnError) {
        // Silent mode is used by startup auto-restore.
        // We intentionally avoid surfacing an intrusive error toast at launch.
        state = state.copyWith(
          errorMessage: null,
          statusMessage:
              'Impossible de rouvrir automatiquement le dernier projet. Ouvrez-le manuellement une fois pour réautoriser l’accès.',
        );
      } else {
        state = state.copyWith(errorMessage: 'Failed to load project: $e');
      }
    }
  }

  Future<bool> _isManifestReadable(String manifestPath) async {
    final file = File(manifestPath);
    try {
      // A tiny read is enough to validate real OS-level authorization.
      // We do not rely only on `exists()` because TCC can still block reads.
      await file.openRead(0, 1).first;
      return true;
    } on FileSystemException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<File> _sessionStateFile() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final editorDir = Directory(
      p.join(appSupportDir.path, 'rpg_map_editor'),
    );
    if (!await editorDir.exists()) {
      await editorDir.create(recursive: true);
    }
    return File(p.join(editorDir.path, _editorSessionFileName));
  }

  Future<void> _rememberLastOpenedProjectManifest(String manifestPath) async {
    try {
      final file = await _sessionStateFile();
      final payload = <String, dynamic>{
        _lastOpenedProjectManifestKey: manifestPath,
      };
      await file.writeAsString(jsonEncode(payload));
      // Also remember a security-scoped bookmark when running on macOS.
      // This is the durable way to re-open a user-selected folder under sandbox.
      await _rememberMacOsProjectBookmark(manifestPath);
    } catch (_) {
      // Non-critical: failing to persist recent project must not block editing.
    }
  }

  Future<void> _clearLastOpenedProjectMemory() async {
    try {
      final file = await _sessionStateFile();
      if (await file.exists()) {
        await file.delete();
      }
      await _clearMacOsProjectBookmark();
    } catch (_) {
      // Best effort cleanup only.
    }
  }

  Future<void> _rememberMacOsProjectBookmark(String manifestPath) async {
    if (!Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel.invokeMethod<void>(
        'rememberProjectPath',
        <String, dynamic>{'manifestPath': manifestPath},
      );
    } catch (_) {
      // Best effort only: path JSON persistence remains as fallback.
    }
  }

  Future<String?> _resolveLastProjectManifestFromMacOsBookmark() async {
    if (!Platform.isMacOS) {
      return null;
    }
    try {
      final path = await _macOsFileAccessChannel
          .invokeMethod<String>('resolveLastProjectManifestPath');
      if (path == null) {
        return null;
      }
      final trimmed = path.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearMacOsProjectBookmark() async {
    if (!Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel
          .invokeMethod<void>('clearRememberedProjectPath');
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> updateProjectSettings({
    required String name,
    required ProjectSettings settings,
  }) async {
    debugPrint('EditorNotifier: updateProjectSettings()');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectSettingsUseCaseProvider);
      final updated =
          await useCase.execute(fs, project, name: name, settings: settings);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Project settings saved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating project settings: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update project settings: $e',
      );
    }
  }

  /// Remplace le manifest projet en mémoire (aucune écriture disque).
  ///
  /// Lot Environment-16 : [statusMessage] optionnel pour feedback shell ;
  /// [errorMessage] est effacé sur succès pour éviter un message obsolète.
  void applyInMemoryProjectManifest(
    ProjectManifest manifest, {
    String? statusMessage,
  }) {
    state = statusMessage == null
        ? state.copyWith(
            project: manifest,
            isProjectDirty: true,
            errorMessage: null,
          )
        : state.copyWith(
            project: manifest,
            isProjectDirty: true,
            errorMessage: null,
            statusMessage: statusMessage,
          );
  }

  Future<bool> saveProjectManifest() async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) {
      state = state.copyWith(
        errorMessage: 'No project open to save.',
      );
      return false;
    }
    debugPrint('EditorNotifier: saveProjectManifest()');
    try {
      await ref.read(projectRepositoryProvider).saveProject(
            project,
            fs.projectManifestPath,
          );
      state = state.copyWith(
        isProjectDirty: false,
        statusMessage: 'Projet sauvegardé via le flux projet existant.',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      debugPrint('EditorNotifier: Error saving project manifest: $e');
      state = state.copyWith(
        errorMessage: 'Failed to save project: $e',
      );
      return false;
    }
  }

  Future<void> saveActiveMap() async {
    endMapStroke();
    final map = state.activeMap;
    final path = state.activeMapPath;
    if (map == null || path == null) return;

    debugPrint('EditorNotifier: saveActiveMap()');
    state = _projectSessionController.markMapSaving(state);

    try {
      final useCase = ref.read(saveMapUseCaseProvider);
      await useCase.execute(
        map,
        path,
        projectDialogueContext: state.project,
      );

      state = _projectSessionController.markMapSaved(
        current: state,
        map: map,
        statusMessage: 'Map "${map.id}" saved',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error saving map: $e');
      state = _projectSessionController.markMapSaveFailed(
        current: state,
        errorMessage: 'Failed to save map: $e',
      );
    }
  }

  Future<void> createMap(String id, int width, int height,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    debugPrint(
        'EditorNotifier: createMap($id, $width, $height) in group $groupId');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createMapUseCaseProvider);
      final map = await useCase.execute(fs, project, id, width, height,
          groupId: groupId, role: role);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: project,
        current: _currentTerrainPresetSelection(),
      );
      final updatedProject = project.copyWith(maps: [
        ...project.maps,
        ProjectMapEntry(
          id: id,
          name: id,
          relativePath: fs.getMapRelativePath(id),
          groupId: groupId,
          role: role,
        )
      ]);
      state = _projectSessionController.openMapDocument(
        current: state.copyWith(project: updatedProject),
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.getMapPath(id),
          presetSelection: presetSelection,
          selectedTilesetEditorId:
              _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
            map,
          ),
        ),
        statusMessage: 'Map "$id" created successfully',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error creating map: $e');
      state = state.copyWith(errorMessage: 'Failed to create map: $e');
    }
  }

  Future<void> loadMap(String relativePath) async {
    debugPrint('EditorNotifier: loadMap($relativePath)');
    final fs = _projectWorkspace;
    if (fs == null) return;

    try {
      final useCase = ref.read(loadMapUseCaseProvider);
      final project = state.project;
      final loadedMap = await useCase.execute(fs, relativePath);
      final map = project == null
          ? loadedMap
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: loadedMap,
              project: project,
            );
      final presetSelection = project == null
          ? _currentTerrainPresetSelection()
          : _terrainPresetSelectionCoordinator.normalize(
              project: project,
              current: _currentTerrainPresetSelection(),
            );
      final preservedSelectedTilesetEditorId = state.selectedTilesetEditorId;
      final nextSelectedTilesetEditorId =
          preservedSelectedTilesetEditorId != null &&
                  preservedSelectedTilesetEditorId.isNotEmpty &&
                  project != null &&
                  project.tilesets.any(
                    (tileset) => tileset.id == preservedSelectedTilesetEditorId,
                  )
              ? preservedSelectedTilesetEditorId
              : _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
                  map,
                );
      state = _projectSessionController.openMapDocument(
        current: state,
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.resolveMapPath(relativePath),
          presetSelection: presetSelection,
          selectedTilesetEditorId: nextSelectedTilesetEditorId,
        ),
        statusMessage: 'Map "${map.id}" loaded',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error loading map: $e');
      state = state.copyWith(errorMessage: 'Failed to load map: $e');
    }
  }

  /// Charge une "snapshot" de map par id SANS changer la map active.
  ///
  /// Pourquoi cette API existe:
  /// - certains workspaces (ex: Cutscene Studio) doivent proposer des
  ///   dropdowns guidés (PNJ/triggers) pour n'importe quelle map du projet;
  /// - on ne veut pas forcer un changement de contexte utilisateur vers cette
  ///   map juste pour lire ses entités;
  /// - on garde donc une lecture non destructive (read-only) côté éditeur.
  ///
  /// Contrat:
  /// - retourne la `activeMap` si c'est déjà la bonne map (inclut les edits
  ///   non sauvegardés en cours, utile pour une UX cohérente);
  /// - sinon lit le fichier map depuis le disque;
  /// - retourne `null` si le contexte projet est incomplet ou en cas d'erreur.
  Future<MapData?> loadMapSnapshotById(String mapId) async {
    final normalizedMapId = mapId.trim();
    if (normalizedMapId.isEmpty) {
      return null;
    }
    final project = state.project;
    final workspace = _projectWorkspace;
    if (project == null || workspace == null) {
      return null;
    }

    final activeMap = state.activeMap;
    if (activeMap != null && activeMap.id == normalizedMapId) {
      return activeMap;
    }

    ProjectMapEntry? entry;
    for (final mapEntry in project.maps) {
      if (mapEntry.id == normalizedMapId) {
        entry = mapEntry;
        break;
      }
    }
    if (entry == null) {
      return null;
    }

    try {
      final mapPath = workspace.resolveMapPath(entry.relativePath);
      final repo = ref.read(mapRepositoryProvider);
      return await repo.loadMap(mapPath);
    } catch (error) {
      debugPrint(
        'EditorNotifier: loadMapSnapshotById($normalizedMapId) failed: $error',
      );
      return null;
    }
  }

  Future<void> resizeActiveMap(int width, int height) async {
    final map = state.activeMap;
    if (map == null) return;

    debugPrint('EditorNotifier: resizeActiveMap(${width}x$height)');
    try {
      final useCase = ref.read(resizeMapUseCaseProvider);
      final resized = useCase.execute(map, width, height);
      final project = state.project;
      final committed = project == null
          ? resized
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: resized,
              project: project,
            );

      if (committed == map) {
        state = state.copyWith(
          statusMessage: 'Map "${map.id}" is already ${width}x$height',
          errorMessage: null,
        );
        return;
      }

      final hovered = state.hoveredTile;
      final nextHovered = (hovered != null &&
              (hovered.x < 0 ||
                  hovered.y < 0 ||
                  hovered.x >= width ||
                  hovered.y >= height))
          ? null
          : hovered;
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        hoveredTile: nextHovered,
        updateHoveredTile: true,
        statusMessage: 'Map "${map.id}" resized to ${width}x$height',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error resizing map: $e');
      state = state.copyWith(errorMessage: 'Failed to resize map: $e');
    }
  }

  void updateMapMetadata(MapMetadata metadata) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(updateMapMetadataUseCaseProvider);
      final updated = useCase.execute(
        map,
        metadata,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Carte : propriétés enregistrées',
      );
    } catch (e) {
      debugPrint('EditorNotifier: updateMapMetadata failed: $e');
      state = state.copyWith(
        errorMessage: 'Échec des propriétés de carte : $e',
      );
    }
  }

  Future<void> renameMap(String oldId, String newId) async {
    debugPrint('EditorNotifier: renameMap($oldId -> $newId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, oldId, newId);
      state = _projectSessionController.afterMapRenamed(
        current: state,
        updatedProject: updatedProject,
        oldId: oldId,
        newId: newId,
        newPath: fs.getMapPath(newId),
        statusMessage: 'Map renamed to "$newId"',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming map: $e');
      state = state.copyWith(errorMessage: 'Failed to rename map: $e');
    }
  }

  Future<void> deleteMap(String mapId) async {
    debugPrint('EditorNotifier: deleteMap($mapId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId);
      state = _projectSessionController.afterMapDeleted(
        current: state,
        updatedProject: updatedProject,
        deletedMapId: mapId,
        statusMessage: 'Map "$mapId" deleted',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting map: $e');
      state = state.copyWith(errorMessage: 'Failed to delete map: $e');
    }
  }

  Future<void> duplicateMap(String sourceId) async {
    debugPrint('EditorNotifier: duplicateMap($sourceId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(duplicateMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, sourceId);

      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map "$sourceId" duplicated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error duplicating map: $e');
      state = state.copyWith(errorMessage: 'Failed to duplicate map: $e');
    }
  }

  Future<void> createGroup(String name, MapGroupType type,
      {String? parentId}) async {
    debugPrint('EditorNotifier: createGroup($name, $type, parent: $parentId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, name, type, parentId: parentId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group "$name" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating group: $e');
      state = state.copyWith(errorMessage: 'Failed to create group: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    debugPrint('EditorNotifier: deleteGroup($groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting group: $e');
      state = state.copyWith(errorMessage: 'Failed to delete group: $e');
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    debugPrint('EditorNotifier: renameGroup($groupId -> $newName)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, groupId, newName);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming group: $e');
      state = state.copyWith(errorMessage: 'Failed to rename group: $e');
    }
  }

  Future<void> moveMapToGroup(String mapId, String? groupId) async {
    debugPrint('EditorNotifier: moveMapToGroup($mapId -> $groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(moveMapToGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving map: $e');
      state = state.copyWith(errorMessage: 'Failed to move map: $e');
    }
  }

  List<ProjectTilesetEntry> getAssignableTilesetsForActiveMap() {
    final project = state.project;
    final activeMap = state.activeMap;
    if (project == null || activeMap == null) return const [];
    try {
      final useCase = ref.read(resolveAssignableTilesetsForMapUseCaseProvider);
      return useCase.execute(project, activeMap.id);
    } catch (_) {
      return const [];
    }
  }

  Future<void> importProjectTileset({
    required String sourcePath,
    required String name,
    required TilesetScope scope,
    String? groupId,
    bool isWorldTileset = false,
    String? libraryFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(importProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        sourcePath: sourcePath,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        folderId: libraryFolderId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId:
            updated.tilesets.isNotEmpty ? updated.tilesets.last.id : null,
        selectedTilesetElementGroupId: null,
        statusMessage: 'Tileset "$name" imported',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error importing tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to import tileset: $e');
    }
  }

  Future<void> updateProjectTileset({
    required String tilesetId,
    String? name,
    TilesetScope? scope,
    String? groupId,
    bool? isWorldTileset,
    int? sortOrder,
    String? libraryFolderId,
    bool clearLibraryFolder = false,
    TilesetTransparentColor? transparentColor,
    bool clearTransparentColor = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        sortOrder: sortOrder,
        folderId: libraryFolderId,
        clearLibraryFolder: clearLibraryFolder,
        transparentColor: transparentColor,
        clearTransparentColor: clearTransparentColor,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to update tileset: $e');
    }
  }

  Future<void> reorderProjectTileset(String tilesetId, int direction) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(reorderProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        direction: direction,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset reordered',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error reordering tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to reorder tileset: $e');
    }
  }

  Future<void> createTilesetLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentFolderId: parentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create tileset folder: $e',
      );
    }
  }

  Future<void> renameTilesetLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset folder: $e',
      );
    }
  }

  Future<void> moveTilesetLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        newParentFolderId: newParentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset folder: $e',
      );
    }
  }

  Future<void> deleteTilesetLibraryFolder(String folderId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to delete tileset folder: $e',
      );
    }
  }

  Future<void> assignTilesetToLibraryFolder({
    required String tilesetId,
    required String folderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(assignTilesetToLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to folder',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to folder: $e',
      );
    }
  }

  Future<void> moveTilesetToLibraryRoot(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetToLibraryRootUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to library root',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset to library root: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to library root: $e',
      );
    }
  }

  Future<void> deleteProjectTileset(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(fs, project, tilesetId);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      String? selectedTilesetEditorId = state.selectedTilesetEditorId;
      var workspaceMode = state.workspaceMode;
      var activeBrush =
          _clearBrushIfTilesetRemoved(state.activeBrush, tilesetId);
      if (selectedTilesetEditorId == tilesetId) {
        selectedTilesetEditorId =
            _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
          state.activeMap,
          preferredLayerId: state.activeLayerId,
        );
        if (selectedTilesetEditorId != null &&
            !updated.tilesets.any((t) => t.id == selectedTilesetEditorId)) {
          selectedTilesetEditorId =
              updated.tilesets.isNotEmpty ? updated.tilesets.first.id : null;
        }
        if (selectedTilesetEditorId == null) {
          workspaceMode = EditorWorkspaceMode.map;
        }
      }
      state = state.copyWith(
        project: updated,
        workspaceMode: workspaceMode,
        activeBrush: activeBrush,
        selectedTilesetEditorId: selectedTilesetEditorId,
        selectedTilesetElementGroupId: null,
        terrainSelectionMode: presetSelection.selectionMode,
        selectedTerrainType: presetSelection.selectedTerrainType,
        selectedTerrainPresetId: presetSelection.selectedTerrainPresetId,
        selectedPathPresetId: presetSelection.selectedPathPresetId,
        selectedTerrainPresetByType:
            presetSelection.selectedTerrainPresetByType,
        statusMessage: 'Tileset deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to delete tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveLayer(String tilesetId) async {
    final project = state.project;
    final map = state.activeMap;
    final mapPath = state.activeMapPath;
    final layerId = state.activeLayerId;
    if (project == null || map == null || mapPath == null || layerId == null) {
      return;
    }
    final layer = _findLayerById(map, layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Active layer must be a tile layer to assign a tileset',
      );
      return;
    }

    try {
      final useCase = ref.read(assignTilesetToMapUseCaseProvider);
      final updatedMap = await useCase.execute(
        project,
        map,
        mapPath,
        layerId,
        tilesetId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Tileset "$tilesetId" assigned to layer "${layer.name}"',
        updateSavedSnapshot: true,
      );
      state = state.copyWith(
        workspaceMode: EditorWorkspaceMode.map,
        activeBrush: const EditorBrush.none(),
        selectedTilesetEditorId: tilesetId,
        selectedTilesetElementGroupId: null,
        paletteCategoryFilter: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning layer tileset: $e');
      state =
          state.copyWith(errorMessage: 'Failed to assign layer tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveMap(String tilesetId) async {
    await assignTilesetToActiveLayer(tilesetId);
  }

  ProjectTilesetEntry? getActiveTilesetEntry() {
    return getSelectedTilesetEntry();
  }

  String? getActiveTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getActiveTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  PathAutotileSet? getSelectedPathAutotileSet() {
    return _pathAutotileResolver.resolve(
      selectedPreset: getSelectedPathPreset(),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  PathAutotileSet? getPathAutotileSetForPresetId(String? presetId) {
    return _pathAutotileResolver.resolve(
      selectedPreset: getPathPresetById(presetId),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  Map<String, PathAutotileSet> getPathAutotileSetsByPresetId() {
    final result = <String, PathAutotileSet>{};
    for (final preset in getPathPresets()) {
      final resolved = getPathAutotileSetForPresetId(preset.id);
      if (resolved != null) {
        result[preset.id] = resolved;
      }
    }
    return result;
  }

  List<ProjectTerrainPreset> getTerrainPresets({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listTerrainPresets(
      project,
      terrainType: terrainType,
    );
  }

  List<ProjectPathPreset> getPathPresets() {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPathPresets(project);
  }

  List<ProjectSurfacePreset> getSurfacePresets() {
    return state.project?.surfaceCatalog.presets ?? const [];
  }

  List<ProjectPresetCategory> getPresetCategories({
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPresetCategories(
      project,
      kind: kind,
      parentCategoryId: parentCategoryId,
    );
  }

  ProjectPresetCategory? getPresetCategoryById({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPresetCategoryById(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  String? resolvePresetCategoryPath({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolvePresetCategoryPath(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  ProjectTerrainPreset? getTerrainPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findTerrainPresetById(project, presetId);
  }

  ProjectPathPreset? getPathPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPathPresetById(project, presetId);
  }

  ProjectSurfacePreset? getSurfacePresetById(String? presetId) {
    final normalizedPresetId = presetId?.trim();
    if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
      return null;
    }
    final project = state.project;
    if (project == null) return null;
    return project.surfaceCatalog.presetById(normalizedPresetId);
  }

  ProjectTerrainPreset? getSelectedTerrainPreset({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return null;
    final type = terrainType ?? state.selectedTerrainType;
    return _terrainPresetResolver.resolveSelectedTerrainPreset(
      project,
      terrainType: type,
      selectedTerrainPresetId: state.selectedTerrainPresetId,
      selectedTerrainPresetByType: state.selectedTerrainPresetByType,
    );
  }

  ProjectPathPreset? getSelectedPathPreset() {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolveSelectedPathPreset(
      project,
      selectedPathPresetId: state.selectedPathPresetId,
    );
  }

  ProjectSurfacePreset? getSelectedSurfacePreset() {
    return getSurfacePresetById(state.selectedSurfacePresetId);
  }

  Map<TerrainType, ProjectTerrainPreset> getTerrainPresetByType() {
    final result = <TerrainType, ProjectTerrainPreset>{};
    for (final type in TerrainType.values) {
      if (!type.isBackgroundPaintable) continue;
      final preset = getSelectedTerrainPreset(terrainType: type);
      if (preset != null) {
        result[type] = preset;
      }
    }
    return result;
  }

  void selectMapWorkspace() {
    state = _editorWorkspaceController.selectMapWorkspace(state);
  }

  void selectTilesetWorkspace(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      workspaceMode: tilesetId == null
          ? EditorWorkspaceMode.map
          : EditorWorkspaceMode.tileset,
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
    );
  }

  /// Ouvre le workspace Pokédex des lots 12-13.
  ///
  /// Ce changement reste volontairement une simple navigation :
  /// - aucune donnee Pokemon n'est chargee ici ;
  /// - aucun service Pokemon n'est appele ici ;
  /// - l'ecran central gerera lui-meme la lecture simple necessaire au lot 13.
  ///
  /// Cela garde la responsabilite du notifier tres claire :
  /// il route vers un workspace, mais ne commence pas une logique Pokédex riche.
  void selectPokedexWorkspace() {
    state = _editorWorkspaceController.selectPokedexWorkspace(state);
  }

  void selectPokemonCatalogSection(PokemonCatalogSection section) {
    state = _editorWorkspaceController.selectPokemonCatalogSection(
      state,
      section,
    );
  }

  /// Ouvre le workspace central "Trainer Studio".
  ///
  /// Cette navigation reste volontairement minimale :
  /// - aucun pipeline trainer parallèle n'est créé ici ;
  /// - aucune donnée locale n'est préchargée depuis le notifier ;
  /// - la surface centrale réutilise le même flux trainer que la sidebar,
  ///   via les méthodes existantes du notifier.
  void selectTrainerWorkspace() {
    state = _editorWorkspaceController.selectTrainerWorkspace(state);
  }

  /// Ouvre le workspace central "Global Story".
  ///
  /// Ce changement est purement une navigation d'espace de travail:
  /// - aucune mutation map/tileset n'est exécutée,
  /// - aucune donnée narrative n'est modifiée ici.
  void selectGlobalStoryWorkspace() {
    state = _editorWorkspaceController.selectGlobalStoryWorkspace(state);
  }

  /// Ouvre le workspace central "Step".
  void selectStepWorkspace() {
    state = _editorWorkspaceController.selectStepWorkspace(state);
  }

  /// Ouvre le workspace central "Cutscene".
  void selectCutsceneWorkspace() {
    state = _editorWorkspaceController.selectCutsceneWorkspace(state);
  }

  /// Bascule vers Dialogue Studio (bibliothèque + canvas + inspecteur).
  void selectDialogueWorkspace() {
    state = _editorWorkspaceController.selectDialogueWorkspace(state);
  }

  /// Bascule vers Path Studio.
  ///
  /// Navigation pure de shell : aucune mutation de manifest, aucune génération
  /// de preview et aucun save flow ne sont déclenchés par ce point d'entrée.
  void selectPathStudioWorkspace() {
    state = _editorWorkspaceController.selectPathStudioWorkspace(state);
  }

  /// Bascule vers Environment Studio (shell read-only Lot Environment-9).
  void selectEnvironmentStudioWorkspace() {
    state = _editorWorkspaceController.selectEnvironmentStudioWorkspace(state);
  }

  /// Écrit uniquement le fichier `.yarn` (le manifest projet reste inchangé).
  Future<void> saveProjectDialogueYarnBody({
    required String dialogueId,
    required String yarnBody,
  }) async {
    state = await _projectContentController.saveProjectDialogueYarnBody(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      yarnBody: yarnBody,
    );
  }

  void selectTilesetEditorContext(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
      errorMessage: null,
    );
  }

  ProjectTilesetEntry? getSelectedTilesetEntry() {
    final project = state.project;
    if (project == null) return null;

    final selectedId = state.selectedTilesetEditorId;
    if (selectedId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == selectedId) {
          return tileset;
        }
      }
    }

    final map = state.activeMap;
    final activeLayerId = state.activeLayerId;
    if (map != null && activeLayerId != null) {
      final activeLayer = _findLayerById(map, activeLayerId);
      if (activeLayer is TileLayer) {
        final layerTilesetId = activeLayer.tilesetId?.trim();
        if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
          for (final tileset in project.tilesets) {
            if (tileset.id == layerTilesetId) {
              return tileset;
            }
          }
        }
      }
    }

    final brushTilesetId = getActiveBrushTilesetId();
    if (brushTilesetId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == brushTilesetId) {
          return tileset;
        }
      }
    }

    if (project.tilesets.isEmpty) return null;
    return project.tilesets.first;
  }

  String? getSelectedTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getSelectedTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getTilesetAbsolutePathById(String tilesetId) {
    final fs = _projectWorkspace;
    if (fs == null) return null;
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getActiveBrushTilesetId() {
    final brush = state.activeBrush;
    if (brush is TileEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is PaletteEntryEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      return element?.tilesetId;
    }
    return null;
  }

  List<TilesetElementGroup> getSelectedTilesetElementGroups() {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return const [];
    final groups = List<TilesetElementGroup>.from(
      tileset.elementGroups,
      growable: false,
    );
    groups.sort((a, b) {
      if (a.parentGroupId == b.parentGroupId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentGroupId ?? '';
      final parentB = b.parentGroupId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return groups;
  }

  void selectTilesetElementGroupFilter(String? groupId) {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return;
    if (groupId != null &&
        !tileset.elementGroups.any((group) => group.id == groupId)) {
      return;
    }
    state = state.copyWith(selectedTilesetElementGroupId: groupId);
  }

  Future<void> createTilesetElementGroup(
    String tilesetId,
    String name, {
    String? parentGroupId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        parentGroupId: parentGroupId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset group: $e',
      );
    }
  }

  Future<void> createTilesetElementSubgroup(
    String tilesetId,
    String parentGroupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementSubgroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        parentGroupId: parentGroupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset subgroup created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset subgroup: $e',
      );
    }
  }

  Future<void> renameTilesetElementGroup(
    String tilesetId,
    String groupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        groupId: groupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset group: $e',
      );
    }
  }

  List<ProjectElementEntry> getSelectedTilesetElements({
    String? tilesetGroupId,
    bool includeDescendants = true,
  }) {
    final project = state.project;
    final selectedTileset = getSelectedTilesetEntry();
    if (project == null || selectedTileset == null) return const [];
    try {
      final useCase = ref.read(resolveTilesetElementsUseCaseProvider);
      return useCase.execute(
        project,
        tilesetId: selectedTileset.id,
        tilesetGroupId: tilesetGroupId,
        includeDescendants: includeDescendants,
      );
    } catch (_) {
      return const [];
    }
  }

  List<ProjectElementCategory> getElementCategories() {
    final project = state.project;
    if (project == null) return const [];
    final categories = List<ProjectElementCategory>.from(
      project.elementCategories,
      growable: false,
    );
    categories.sort((a, b) {
      if (a.parentCategoryId == b.parentCategoryId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentCategoryId ?? '';
      final parentB = b.parentCategoryId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  ProjectElementCategory? getElementCategoryById(String categoryId) {
    final project = state.project;
    if (project == null) return null;
    for (final category in project.elementCategories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  ProjectElementEntry? getProjectElementById(String elementId) {
    final project = state.project;
    if (project == null) return null;
    for (final element in project.elements) {
      if (element.id == elementId) {
        return element;
      }
    }
    return null;
  }

  List<ProjectElementEntry> getVisibleProjectElementsForActiveMap({
    bool includeAll = false,
    bool globalOnly = false,
    bool acrossAllTilesets = false,
  }) {
    final project = state.project;
    final map = state.activeMap;
    if (project == null || map == null) return const [];

    List<ProjectElementEntry> resolved;
    final activeTilesetId = getSelectedTilesetEntry()?.id;
    if (includeAll) {
      resolved = project.elements.where((element) {
        if (!acrossAllTilesets && element.tilesetId != activeTilesetId) {
          return false;
        }
        return true;
      }).toList(growable: false);
    } else if (globalOnly) {
      resolved = project.elements
          .where(
            (element) =>
                (acrossAllTilesets || element.tilesetId == activeTilesetId) &&
                element.groupId == null,
          )
          .toList(growable: false);
    } else {
      if (!acrossAllTilesets && activeTilesetId == null) {
        return const [];
      }
      try {
        final useCase = ref.read(resolveVisibleProjectElementsUseCaseProvider);
        resolved = useCase.execute(
          project,
          tilesetId: acrossAllTilesets ? null : activeTilesetId,
          mapId: map.id,
        );
      } catch (_) {
        resolved = const [];
      }
    }

    resolved.sort((a, b) {
      final categoryCompare = a.categoryId.compareTo(b.categoryId);
      if (categoryCompare != 0) return categoryCompare;
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return resolved;
  }

  Future<void> createElementCategory(
    String name, {
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> createElementSubcategory(
    String parentCategoryId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementSubcategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        parentCategoryId: parentCategoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element subcategory created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create subcategory: $e');
    }
  }

  Future<void> renameElementCategory(String categoryId, String name) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> createProjectElement({
    required String name,
    required String categoryId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    ElementCollisionProfile? collisionProfile,
    String? tilesetId,
    String? tilesetGroupId,
    String? groupId,
    String? recommendedLayerId,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    final selectedTileset = getSelectedTilesetEntry();
    final effectiveTilesetId = tilesetId ?? selectedTileset?.id;
    if (effectiveTilesetId == null) {
      state = state.copyWith(errorMessage: 'No tileset selected');
      return;
    }
    try {
      final useCase = ref.read(createProjectElementUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: effectiveTilesetId,
        categoryId: categoryId,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        tilesetGroupId: tilesetGroupId,
        source: source,
        groupId: groupId,
        recommendedLayerId: recommendedLayerId,
        tags: tags,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.projectElement(elementId: result.element.id),
        selectedTilesetEditorId: result.element.tilesetId,
        selectedTilesetElementGroupId: result.element.tilesetGroupId,
        statusMessage: 'Element "${result.element.name}" created',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> updateProjectElement({
    required String elementId,
    String? name,
    ElementPresetKind? presetKind,
    ElementCollisionProfile? collisionProfile,
    bool clearCollisionProfile = false,
    String? categoryId,
    String? tilesetGroupId,
    bool clearTilesetGroupId = false,
    String? groupId,
    bool clearGroupId = false,
    String? recommendedLayerId,
    bool clearRecommendedLayerId = false,
    TilesetSourceRect? source,
    List<TilesetVisualFrame>? frames,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
        name: name,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        clearCollisionProfile: clearCollisionProfile,
        categoryId: categoryId,
        tilesetGroupId: tilesetGroupId,
        clearTilesetGroupId: clearTilesetGroupId,
        groupId: groupId,
        clearGroupId: clearGroupId,
        recommendedLayerId: recommendedLayerId,
        clearRecommendedLayerId: clearRecommendedLayerId,
        source: source,
        frames: frames,
        tags: tags,
      );
      String? selectedTilesetElementGroupId =
          state.selectedTilesetElementGroupId;
      final selectedElementId = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId,
        orElse: () => null,
      );
      if (selectedElementId == elementId) {
        if (clearTilesetGroupId) {
          selectedTilesetElementGroupId = null;
        } else if (tilesetGroupId != null) {
          selectedTilesetElementGroupId = tilesetGroupId;
        }
      }
      state = state.copyWith(
        project: updated,
        selectedTilesetElementGroupId: selectedTilesetElementGroupId,
        statusMessage: 'Element updated',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update element: $e');
    }
  }

  Future<void> deleteProjectElement(String elementId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
      );
      final activeBrush = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId == elementId
            ? const EditorBrush.none()
            : state.activeBrush,
        orElse: () => state.activeBrush,
      );
      state = state.copyWith(
        project: updated,
        activeBrush: activeBrush,
        statusMessage: 'Element deleted',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete element: $e');
    }
  }

  Future<ElementCollisionProfile?> generateElementCollisionProfile({
    required String tilesetId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
  }) async {
    final project = state.project;
    if (project == null) {
      state = state.copyWith(errorMessage: 'No project loaded');
      return null;
    }
    final tilesetPath = getTilesetAbsolutePathById(tilesetId);
    if (tilesetPath == null || tilesetPath.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Tileset path not found');
      return null;
    }
    try {
      final profile = await _elementCollisionProfileGenerator.generate(
        tilesetImagePath: tilesetPath,
        source: source,
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight,
        presetKind: presetKind,
        padding: padding,
      );
      state = state.copyWith(
        statusMessage:
            'Collision auto-générée (${profile.cells.length} cellule${profile.cells.length > 1 ? 's' : ''})',
        errorMessage: null,
      );
      return profile;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to generate collision profile: $e',
      );
      return null;
    }
  }

  void _resyncPlacedElementsForActiveMapFromProject() {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      return;
    }
    final synced = _placedElementInstanceIndexer.syncAllTileLayers(
      map: map,
      project: project,
    );
    if (identical(synced, map) || synced == map) {
      return;
    }
    _applyMapMutation(
      previousMap: map,
      updatedMap: synced,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: 'Instances d’éléments synchronisées',
    );
  }

  List<TilesetPaletteEntry> getActivePaletteEntries() {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return const [];
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  ProjectTilesetEntry? getTilesetById(String tilesetId) {
    final project = state.project;
    if (project == null) return null;
    for (final tileset in project.tilesets) {
      if (tileset.id == tilesetId) {
        return tileset;
      }
    }
    return null;
  }

  List<TilesetPaletteEntry> getPaletteEntriesForTileset(String tilesetId) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  TilesetPaletteEntry? getPaletteEntryById({
    required String tilesetId,
    required String entryId,
  }) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    for (final entry in tileset.paletteEntries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  TilesetPaletteEntry? getActivePaletteEntryById(String entryId) {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return null;
    return getPaletteEntryById(tilesetId: tilesetId, entryId: entryId);
  }

  void setPaletteCategoryFilter(PaletteCategory? category) {
    state = state.copyWith(paletteCategoryFilter: category);
  }

  void selectPaletteTile(int tileId) {
    if (tileId <= 0) return;
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.tile(
        tileId: tileId,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectPaletteEntry(String entryId) {
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    final entry =
        getPaletteEntryById(tilesetId: selectedTileset.id, entryId: entryId);
    if (entry == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.paletteEntry(
        entryId: entry.id,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectProjectElement(String elementId) {
    final element = getProjectElementById(elementId);
    if (element == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.projectElement(elementId: element.id),
      selectedTilesetEditorId: element.tilesetId,
      selectedTilesetElementGroupId: element.tilesetGroupId,
      selectedPlacedElementInstanceId: null,
    );
  }

  Future<void> createPaletteEntry({
    required String name,
    required PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;

    try {
      final useCase = ref.read(createTilesetPaletteEntryUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        name: name,
        category: category,
        source: source,
        recommendedLayerId: recommendedLayerId,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.paletteEntry(
          entryId: result.entry.id,
          tilesetId: tileset.id,
        ),
        statusMessage: 'Palette element "${result.entry.name}" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating palette entry: $e');
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> upsertPaletteEntryForTile({
    required int tileId,
    required int columns,
    required PaletteCategory category,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;
    if (tileId <= 0 || columns <= 0) return;

    final sourceIndex = tileId - 1;
    final sourceX = sourceIndex % columns;
    final sourceY = sourceIndex ~/ columns;

    TilesetPaletteEntry? existing;
    for (final entry in tileset.paletteEntries) {
      final ps = entry.frames.primarySource;
      if (ps.width == 1 &&
          ps.height == 1 &&
          ps.x == sourceX &&
          ps.y == sourceY) {
        existing = entry;
        break;
      }
    }

    final rect = TilesetSourceRect(x: sourceX, y: sourceY);
    final entry = TilesetPaletteEntry(
      id: existing?.id ?? 'tile_$tileId',
      name: existing?.name.isNotEmpty == true ? existing!.name : 'tile_$tileId',
      category: category,
      frames: existing == null
          ? [TilesetVisualFrame(source: rect)]
          : [
              TilesetVisualFrame(source: rect),
              ...existing.frames.skip(1),
            ],
      recommendedLayerId: recommendedLayerId,
    );

    try {
      final useCase = ref.read(upsertTilesetPaletteEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        entry: entry,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Palette entry updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating palette entry: $e');
      state =
          state.copyWith(errorMessage: 'Failed to update palette entry: $e');
    }
  }

  void paintSelectedBrushAt(
    GridPos pos, {
    required Map<String, int> tilesetColumnsById,
  }) {
    final layerContext = _resolveActiveTileLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final resolvedBrush = _resolveActiveBrushPattern(
      tilesetColumnsById: tilesetColumnsById,
      emitErrors: true,
    );
    if (resolvedBrush == null) return;
    final preparedMap = _prepareMapForBrushTileset(
      map: layerContext.map,
      layerId: layerContext.layerId,
      activeLayer: layerContext.layer,
      brushTilesetId: resolvedBrush.tilesetId,
    );
    if (preparedMap == null) return;
    _paintPattern(
      map: preparedMap,
      layerId: layerContext.layerId,
      pos: pos,
      pattern: resolvedBrush.pattern,
      failureLabel: resolvedBrush.failureLabel,
    );
  }

  void paintCollisionAt(GridPos pos) {
    final layerContext = _resolveActiveCollisionLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final footprint = _resolveCollisionFootprint(emitErrors: true);
    if (footprint == null) return;
    _paintCollisionPattern(
      map: layerContext.map,
      layerId: layerContext.layerId,
      pos: pos,
      patternSize: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  void paintTerrainAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active editable layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TerrainLayer) {
      final footprint = _resolveTerrainFootprint(emitErrors: true);
      if (footprint == null) return;
      _paintTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: state.selectedTerrainType,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final footprint = _resolvePathFootprint();
      final selectedPathPreset = getSelectedPathPreset();
      if (activeLayer.presetId.trim().isEmpty && selectedPathPreset != null) {
        try {
          final presetAssigned = _pathLayerEditingCoordinator.assignPreset(
            map: map,
            layerId: layerId,
            presetId: selectedPathPreset.id,
          );
          _paintPathPattern(
            map: presetAssigned,
            previousMap: map,
            layerId: layerId,
            pos: pos,
            patternSize: footprint.size,
            failureLabel: footprint.failureLabel,
          );
        } catch (e) {
          _setPaintError('Failed to assign path preset: $e');
        }
        return;
      }
      _paintPathPattern(
        map: map,
        previousMap: map,
        layerId: layerId,
        pos: pos,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  void paintSurfaceAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) {
      _setPaintError('No active map selected');
      return;
    }
    final selectedPreset = getSelectedSurfacePreset();
    if (selectedPreset == null) {
      _setPaintError('Select a surface before painting');
      return;
    }

    try {
      final result = _surfacePaintingController.paint(
        map: map,
        targetLayerId: state.activeLayerId,
        surfacePresetId: selectedPreset.id,
        pos: pos,
      );
      if (!result.changed) {
        state = state.copyWith(errorMessage: null);
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layerId,
        statusMessage: 'Surface painted: ${selectedPreset.name}',
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint surface: $e');
    }
  }

  void fillActiveTerrainLayer(TerrainType terrain) {
    final layerContext = _resolveActiveTerrainLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final map = layerContext.map;
    final layerId = layerContext.layerId;
    try {
      final committed = _terrainPaintingCoordinator.fill(
        map: map,
        layerId: layerId,
        terrain: terrain,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        statusMessage: 'Terrain layer filled with ${terrain.name}',
      );
    } catch (e) {
      _setPaintError('Failed to fill terrain layer: $e');
    }
  }

  void assignPathPresetToActivePathLayer(String presetId) {
    final layerContext = _resolveActivePathLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final normalizedPresetId = presetId.trim();
    if (layerContext.layer.presetId.trim() == normalizedPresetId) {
      final preset = getPathPresetById(normalizedPresetId);
      state = state.copyWith(
        statusMessage: preset == null
            ? 'Path layer preset unchanged'
            : 'Path layer preset: ${preset.name}',
        errorMessage: null,
      );
      return;
    }
    try {
      final updated = _pathLayerEditingCoordinator.assignPreset(
        map: layerContext.map,
        layerId: layerContext.layerId,
        presetId: normalizedPresetId,
      );
      final preset = getPathPresetById(normalizedPresetId);
      _applyMapMutation(
        previousMap: layerContext.map,
        updatedMap: updated,
        preferredActiveLayerId: layerContext.layerId,
        statusMessage: preset == null
            ? 'Path layer preset assigned'
            : 'Path layer preset: ${preset.name}',
      );
    } catch (e) {
      _setPaintError('Failed to assign path preset: $e');
    }
  }

  void eraseAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TileLayer) {
      final pattern = _resolveErasePattern(emitErrors: true);
      if (pattern == null) return;
      _erasePattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        failureLabel: pattern.failureLabel,
      );
      return;
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: true);
      if (collisionFootprint == null) return;
      _eraseCollisionPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: collisionFootprint.size,
        failureLabel: collisionFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: true);
      if (terrainFootprint == null) return;
      _eraseTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: terrainFootprint.size,
        failureLabel: terrainFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      _erasePathPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pathFootprint.size,
        failureLabel: pathFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is SurfaceLayer) {
      try {
        final erased = _surfacePaintingController.erase(
          map: map,
          targetLayerId: layerId,
          pos: pos,
        );
        if (!erased.changed) {
          state = state.copyWith(errorMessage: null);
          return;
        }
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased.map,
          preferredActiveLayerId: erased.layerId,
          statusMessage: 'Surface placement erased',
          partOfStroke: true,
        );
      } catch (e) {
        _setPaintError('Failed to erase surface: $e');
      }
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  MapWarp? getSelectedWarp() {
    return _warpEditingService.findSelectedWarp(
      state.activeMap,
      state.selectedWarpId,
    );
  }

  MapConnection? getMapConnection(MapConnectionDirection direction) {
    return _mapConnectionEditingService.findConnection(
      state.activeMap,
      direction,
    );
  }

  MapEntity? getSelectedEntity() {
    return _entityEditingService.findSelectedEntity(
      state.activeMap,
      state.selectedEntityId,
    );
  }

  MapTrigger? getSelectedTrigger() {
    return _triggerEditingService.findSelectedTrigger(
      state.activeMap,
      state.selectedTriggerId,
    );
  }

  MapEventDefinition? getSelectedMapEvent() {
    final map = state.activeMap;
    final selectedMapEventId = state.selectedMapEventId;
    if (map == null || selectedMapEventId == null) {
      return null;
    }
    return findMapEventById(map, selectedMapEventId);
  }

  void placeOrSelectMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = findMapEventAtPos(
      map,
      pos.x,
      pos.y,
      preferredLayerId: state.activeLayerId,
    );
    if (existing != null) {
      selectMapEvent(existing.id);
      return;
    }
    addMapEventAt(pos);
  }

  void addMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = _resolveEventPlacementLayerId(map);
    if (layerId == null) {
      state = state.copyWith(
        errorMessage: 'No layer available to place a map event',
      );
      return;
    }
    final eventId = _generateUniqueMapEventId(map);
    final created = MapEventDefinition(
      id: eventId,
      title: eventId,
      position: EventPosition(layerId: layerId, x: pos.x, y: pos.y),
      pages: const [
        MapEventPage(
          pageNumber: 0,
          message: '',
        ),
      ],
    );
    try {
      final updated = addMapEventToMap(map, event: created);
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: created.id,
        statusMessage: 'Event "${created.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create event: $e');
    }
  }

  void selectMapEvent(String? eventId) {
    final map = state.activeMap;
    if (map == null) return;
    if (eventId == null) {
      state = state.copyWith(
        selectedMapEventId: null,
        errorMessage: null,
      );
      return;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Event not found: $eventId');
      return;
    }
    state = state.copyWith(
      selectedMapEventId: event.id,
      errorMessage: null,
    );
  }

  void updateSelectedMapEvent({
    required String id,
    required String title,
    required MapEventType type,
    required String layerId,
    required int x,
    required int y,
    required List<MapEventPage> pages,
  }) {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    updateMapEvent(
      eventId: selectedMapEventId,
      id: id,
      title: title,
      type: type,
      position: EventPosition(layerId: layerId, x: x, y: y),
      pages: pages,
    );
  }

  void updateMapEvent({
    required String eventId,
    String? id,
    String? title,
    MapEventType? type,
    EventPosition? position,
    List<MapEventPage>? pages,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        id: id,
        title: title,
        type: type,
        position: position,
        pages: pages,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId:
            id?.trim().isNotEmpty == true ? id!.trim() : eventId,
        statusMessage: 'Event updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update event: $e');
    }
  }

  void deleteSelectedMapEvent() {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    deleteMapEvent(selectedMapEventId);
  }

  void deleteMapEvent(String eventId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = removeMapEventFromMap(
        map,
        eventId: eventId,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: state.selectedMapEventId == eventId
            ? null
            : state.selectedMapEventId,
        statusMessage: 'Event deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete event: $e');
    }
  }

  void placeOrSelectEntityAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _entityEditingService.findEntityAtPos(map, pos);
    if (existing != null) {
      selectEntity(existing.id);
      return;
    }
    addEntityAt(
      pos,
      kind: state.selectedEntityKind,
    );
  }

  void addEntityAt(
    GridPos pos, {
    required MapEntityKind kind,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.addEntityAt(
        map,
        pos,
        kind: kind,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.createdEntity.id,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity "${result.createdEntity.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create entity: $e');
    }
  }

  void selectEntity(String? entityId) {
    final map = state.activeMap;
    if (map == null) return;
    if (entityId == null) {
      state = state.copyWith(
        selectedEntityId: null,
        npcWaypointPlacementEntityId: null,
        errorMessage: null,
      );
      return;
    }
    final entity = _entityEditingService.findSelectedEntity(map, entityId);
    if (entity == null) {
      state = state.copyWith(errorMessage: 'Entity not found: $entityId');
      return;
    }
    state = state.copyWith(
      selectedEntityId: entity.id,
      selectedEntityKind: entity.kind,
      npcWaypointPlacementEntityId:
          state.npcWaypointPlacementEntityId == entity.id
              ? state.npcWaypointPlacementEntityId
              : null,
      errorMessage: null,
    );
  }

  /// Active le mode "placement waypoint" sur l'entité NPC sélectionnée.
  ///
  /// Ce mode est volontairement porté par l'état éditeur (et non local panel),
  /// afin que le canvas puisse router le clic map de manière explicite.
  bool startNpcWaypointPlacementForSelectedEntity() {
    final map = state.activeMap;
    final selectedEntityId = state.selectedEntityId;
    if (map == null || selectedEntityId == null || selectedEntityId.isEmpty) {
      return false;
    }
    final entity =
        _entityEditingService.findSelectedEntity(map, selectedEntityId);
    if (entity == null || entity.kind != MapEntityKind.npc) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires a selected NPC.',
      );
      return false;
    }
    final movement = entity.npc?.movement ?? const MapEntityNpcMovementConfig();
    if (movement.mode != MapEntityNpcMovementMode.patrol) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires NPC movement mode "patrol".',
      );
      return false;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage: 'Waypoint placement enabled for "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  /// Désactive explicitement le mode placement waypoint.
  void cancelNpcWaypointPlacement({String? statusMessage}) {
    if (state.npcWaypointPlacementEntityId == null) {
      return;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: null,
      statusMessage: statusMessage ?? 'Waypoint placement disabled',
      errorMessage: null,
    );
  }

  /// Traite un clic map en mode placement waypoint.
  ///
  /// Retourne `true` si le clic a été consommé par ce mode.
  /// Retourne `false` si aucun mode placement actif (ou session invalide).
  bool addNpcWaypointAt(GridPos position) {
    final placementEntityId = state.npcWaypointPlacementEntityId;
    if (placementEntityId == null || placementEntityId.trim().isEmpty) {
      return false;
    }
    final map = state.activeMap;
    if (map == null) {
      cancelNpcWaypointPlacement(statusMessage: 'Waypoint placement cancelled');
      return false;
    }
    final entity = _entityEditingService.findSelectedEntity(
      map,
      placementEntityId,
    );
    if (entity == null || entity.kind != MapEntityKind.npc) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC no longer valid)',
      );
      return false;
    }
    final npc = entity.npc ?? const MapEntityNpcData();
    if (npc.movement.mode != MapEntityNpcMovementMode.patrol) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC not in patrol mode)',
      );
      return false;
    }

    final nextWaypoints = <GridPos>[
      ...npc.movement.waypoints,
      position,
    ];
    final nextNpc = npc.copyWith(
      movement: npc.movement.copyWith(waypoints: nextWaypoints),
    );
    updateEntity(
      entityId: entity.id,
      npc: nextNpc,
    );
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage:
          'Waypoint (${position.x}, ${position.y}) added to "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  void selectEntityKind(MapEntityKind kind) {
    state = _mapSelectionController.selectEntityKind(
      current: state,
      kind: kind,
    );
  }

  void updateSelectedEntity({
    required String id,
    required String name,
    required MapEntityKind kind,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
    required bool blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    updateEntity(
      entityId: selectedEntityId,
      id: id,
      name: name,
      kind: kind,
      pos: GridPos(x: x, y: y),
      size: GridSize(width: width, height: height),
      properties: properties,
      blocksMovement: blocksMovement,
      npc: npc,
      sign: sign,
      item: item,
      spawn: spawn,
      editorVisual: editorVisual,
    );
  }

  void updateEntity({
    required String entityId,
    String? id,
    String? name,
    MapEntityKind? kind,
    GridPos? pos,
    GridSize? size,
    Map<String, String>? properties,
    bool? blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.updateEntity(
        map,
        entityId: entityId,
        id: id,
        name: name,
        kind: kind,
        pos: pos,
        size: size,
        properties: properties,
        blocksMovement: blocksMovement,
        npc: npc,
        sign: sign,
        item: item,
        spawn: spawn,
        editorVisual: editorVisual,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity updated',
      );
      if (kind != null && kind != state.selectedEntityKind) {
        state = state.copyWith(selectedEntityKind: kind);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update entity: $e');
    }
  }

  void deleteSelectedEntity() {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    deleteEntity(selectedEntityId);
  }

  void deleteEntity(String entityId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _entityEditingService.deleteEntity(
        map,
        entityId: entityId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId:
            state.selectedEntityId == entityId ? null : state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete entity: $e');
    }
  }

  void placeOrSelectTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _triggerEditingService.findTriggerAtPos(map, pos);
    if (existing != null) {
      selectTrigger(existing.id);
      return;
    }
    addTriggerAt(pos);
  }

  void addTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.addTriggerAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.createdTrigger.id,
        statusMessage: 'Trigger "${result.createdTrigger.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trigger: $e');
    }
  }

  void selectTrigger(String? triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    if (triggerId == null) {
      state = state.copyWith(
        selectedTriggerId: null,
        errorMessage: null,
      );
      return;
    }
    final trigger = _triggerEditingService.findSelectedTrigger(map, triggerId);
    if (trigger == null) {
      state = state.copyWith(errorMessage: 'Trigger not found: $triggerId');
      return;
    }
    state = state.copyWith(
      selectedTriggerId: trigger.id,
      errorMessage: null,
    );
  }

  void updateSelectedTrigger({
    required String id,
    required String name,
    required TriggerType type,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
  }) {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    updateTrigger(
      triggerId: selectedTriggerId,
      id: id,
      name: name,
      type: type,
      area: MapRect(
        pos: GridPos(x: x, y: y),
        size: GridSize(width: width, height: height),
      ),
      properties: properties,
    );
  }

  void updateTrigger({
    required String triggerId,
    String? id,
    String? name,
    TriggerType? type,
    MapRect? area,
    Map<String, String>? properties,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.updateTrigger(
        map,
        triggerId: triggerId,
        id: id,
        name: name,
        type: type,
        area: area,
        properties: properties,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.selectedTriggerId,
        statusMessage: 'Trigger updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trigger: $e');
    }
  }

  void deleteSelectedTrigger() {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    deleteTrigger(selectedTriggerId);
  }

  void deleteTrigger(String triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _triggerEditingService.deleteTrigger(
        map,
        triggerId: triggerId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId == triggerId
            ? null
            : state.selectedTriggerId,
        statusMessage: 'Trigger deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trigger: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Gameplay zones
  // ---------------------------------------------------------------------------

  MapGameplayZone? getSelectedGameplayZone() {
    return _gameplayZoneEditingService.findSelectedZone(
      state.activeMap,
      state.selectedGameplayZoneId,
    );
  }

  void placeOrSelectGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _gameplayZoneEditingService.findZoneAtPos(map, pos);
    if (existing != null) {
      selectGameplayZone(existing.id);
      return;
    }
    addGameplayZoneAt(pos);
  }

  void addGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.addZoneAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" created',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  void selectGameplayZone(String? zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    if (zoneId == null) {
      state = state.copyWith(selectedGameplayZoneId: null);
      return;
    }
    final zone = _gameplayZoneEditingService.findSelectedZone(map, zoneId);
    if (zone == null) {
      state = state.copyWith(errorMessage: 'Zone not found: $zoneId');
      return;
    }
    state = state.copyWith(selectedGameplayZoneId: zone.id);
  }

  void updateSelectedGameplayZone({
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    updateGameplayZone(
      zoneId: selectedZoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      priority: priority,
      encounter: encounter,
      movement: movement,
      movementEffect: movementEffect,
      hazard: hazard,
      special: special,
    );
  }

  void updateGameplayZone({
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.updateZone(
        map,
        zoneId: zoneId,
        id: id,
        name: name,
        kind: kind,
        area: area,
        priority: priority,
        encounter: encounter,
        movement: movement,
        movementEffect: movementEffect,
        hazard: hazard,
        special: special,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone updated',
      );
      state = state.copyWith(selectedGameplayZoneId: result.selectedZoneId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update zone: $e');
    }
  }

  bool applyGeneratedGameplayZones({
    required List<MapGameplayZone> zones,
    String? selectZoneId,
    String? statusMessage,
  }) {
    final map = state.activeMap;
    if (map == null || zones.isEmpty) return false;
    try {
      var updatedMap = map;
      for (final zone in zones) {
        updatedMap = addGameplayZoneToMap(updatedMap, zone: zone);
      }

      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: statusMessage ??
            'Generated ${zones.length} gameplay ${zones.length == 1 ? 'zone' : 'zones'}',
      );

      final requestedSelection = selectZoneId?.trim();
      final hasRequestedSelection = requestedSelection != null &&
          requestedSelection.isNotEmpty &&
          updatedMap.gameplayZones.any(
            (zone) => zone.id == requestedSelection,
          );
      state = state.copyWith(
        selectedGameplayZoneId:
            hasRequestedSelection ? requestedSelection : zones.first.id,
      );
      return true;
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to apply generated zones: $e');
      return false;
    }
  }

  void deleteSelectedGameplayZone() {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    deleteGameplayZone(selectedZoneId);
  }

  void deleteGameplayZone(String zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated =
          _gameplayZoneEditingService.deleteZone(map, zoneId: zoneId);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone deleted',
      );
      if (state.selectedGameplayZoneId == zoneId) {
        state = state.copyWith(selectedGameplayZoneId: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete zone: $e');
    }
  }

  // Drag-to-draw ─────────────────────────────────────────────────────────────

  /// Met à jour l'aire de tracé en cours (fantôme visible sur le canvas).
  void setGameplayZoneDraftArea(MapRect area) {
    state = state.copyWith(gameplayZoneDraftArea: area);
  }

  /// Valide le tracé et crée la zone persistée.
  void commitGameplayZoneDraft() {
    final draft = state.gameplayZoneDraftArea;
    if (draft == null) return;
    state = state.copyWith(gameplayZoneDraftArea: null);
    final map = state.activeMap;
    if (map == null) return;
    // Clamp la zone dans les limites de la map
    final clampedArea = _clampRectToMap(draft, map.size);
    if (clampedArea == null) return;
    try {
      final result =
          _gameplayZoneEditingService.addZoneInRect(map, clampedArea);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" créée',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  /// Annule le tracé en cours sans créer de zone.
  void cancelGameplayZoneDraft() {
    state = state.copyWith(gameplayZoneDraftArea: null);
  }

  static MapRect? _clampRectToMap(MapRect rect, GridSize mapSize) {
    final x = rect.pos.x.clamp(0, mapSize.width - 1);
    final y = rect.pos.y.clamp(0, mapSize.height - 1);
    final w = rect.size.width.clamp(1, mapSize.width - x);
    final h = rect.size.height.clamp(1, mapSize.height - y);
    if (w <= 0 || h <= 0) return null;
    return MapRect(
        pos: GridPos(x: x, y: y), size: GridSize(width: w, height: h));
  }

  void placeOrSelectWarpAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _warpEditingService.findWarpAtPos(map, pos);
    if (existing != null) {
      selectWarp(existing.id);
      return;
    }
    addWarpAt(pos);
  }

  void addWarpAt(GridPos pos) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.addWarpAt(map, project, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.createdWarp.id,
        statusMessage: 'Warp "${result.createdWarp.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create warp: $e');
    }
  }

  void selectWarp(String? warpId) {
    final map = state.activeMap;
    if (map == null) return;
    if (warpId == null) {
      state = state.copyWith(
        selectedWarpId: null,
        errorMessage: null,
      );
      return;
    }
    final warp = _warpEditingService.findSelectedWarp(map, warpId);
    if (warp == null) {
      state = state.copyWith(errorMessage: 'Warp not found: $warpId');
      return;
    }
    state = state.copyWith(
      selectedWarpId: warp.id,
      errorMessage: null,
    );
  }

  void updateSelectedWarp({
    required String id,
    required String targetMapId,
    required int targetPosX,
    required int targetPosY,
    required MapWarpTriggerMode triggerMode,
    required List<EntityFacing> allowedApproachFacings,
    required WarpTriggerPadding triggerPadding,
  }) {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    updateWarp(
      warpId: selectedWarpId,
      id: id,
      targetMapId: targetMapId,
      targetPos: GridPos(x: targetPosX, y: targetPosY),
      triggerMode: triggerMode,
      allowedApproachFacings: allowedApproachFacings,
      triggerPadding: triggerPadding,
    );
  }

  Future<void> createReciprocalWarpForSelectedWarp() async {
    final fs = _projectWorkspace;
    final project = state.project;
    final sourceMap = state.activeMap;
    final selectedWarpId = state.selectedWarpId;
    if (fs == null) {
      state = state.copyWith(errorMessage: 'No project filesystem available');
      return;
    }
    if (project == null) {
      state = state.copyWith(errorMessage: 'No project loaded');
      return;
    }
    if (sourceMap == null) {
      state = state.copyWith(errorMessage: 'No active map loaded');
      return;
    }
    if (selectedWarpId == null) {
      state = state.copyWith(errorMessage: 'No warp selected');
      return;
    }
    try {
      final selectedWarp =
          _warpEditingService.requireSelectedWarp(sourceMap, selectedWarpId);
      final result = await _warpEditingService.createReciprocalWarp(
        fs,
        project,
        sourceMap: sourceMap,
        sourceWarp: selectedWarp,
      );

      if (result.targetIsSourceMap) {
        _applyMapMutation(
          previousMap: sourceMap,
          updatedMap: result.updatedTargetMap,
          preferredActiveLayerId: state.activeLayerId,
          preferredSelectedWarpId: selectedWarpId,
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
        );
      } else {
        state = state.copyWith(
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create return warp: $e');
    }
  }

  void updateWarp({
    required String warpId,
    String? id,
    GridPos? pos,
    String? targetMapId,
    GridPos? targetPos,
    MapWarpTriggerMode? triggerMode,
    List<EntityFacing>? allowedApproachFacings,
    WarpTriggerPadding? triggerPadding,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.updateWarp(
        map,
        project,
        warpId: warpId,
        id: id,
        pos: pos,
        targetMapId: targetMapId,
        targetPos: targetPos,
        triggerMode: triggerMode,
        allowedApproachFacings: allowedApproachFacings,
        triggerPadding: triggerPadding,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.selectedWarpId,
        statusMessage: 'Warp updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update warp: $e');
    }
  }

  void deleteSelectedWarp() {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    deleteWarp(selectedWarpId);
  }

  void deleteWarp(String warpId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _warpEditingService.deleteWarp(
        map,
        warpId: warpId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId:
            state.selectedWarpId == warpId ? null : state.selectedWarpId,
        statusMessage: 'Warp deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete warp: $e');
    }
  }

  Future<void> saveMapConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final map = state.activeMap;
    if (fs == null || project == null || map == null) return;
    try {
      final updatedMap = await _mapConnectionEditingService.upsertConnection(
        fs,
        project,
        sourceMap: map,
        direction: direction,
        targetMapId: targetMapId,
        offset: offset,
      );
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        targetMapId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage:
            '${direction.name.toUpperCase()} connection saved to "${targetEntry.name}"',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save map connection: $e',
      );
    }
  }

  void deleteMapConnection(MapConnectionDirection direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = _mapConnectionEditingService.deleteConnection(
        map,
        direction: direction,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage: '${direction.name.toUpperCase()} connection deleted',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete map connection: $e',
      );
    }
  }

  Future<void> openConnectedMap(MapConnectionDirection direction) async {
    final project = state.project;
    final connection = getMapConnection(direction);
    if (project == null || connection == null) {
      state = state.copyWith(
        errorMessage: 'No ${direction.name} connection available',
      );
      return;
    }
    try {
      endMapStroke();
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        connection.targetMapId,
      );
      await loadMap(targetEntry.relativePath);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to open connected map: $e',
      );
    }
  }

  MapToolPreview? resolveMapToolPreview({
    GridPos? hoveredTile,
    required Map<String, int> tilesetColumnsById,
  }) {
    if (hoveredTile == null) return null;
    final tool = state.activeTool;
    if (tool != EditorToolType.tilePaint &&
        tool != EditorToolType.terrainPaint &&
        tool != EditorToolType.collisionPaint &&
        tool != EditorToolType.eraser) {
      return null;
    }
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) return null;
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) return null;

    if (tool == EditorToolType.tilePaint) {
      if (activeLayer is! TileLayer) return null;
      final resolvedBrush = _resolveActiveBrushPattern(
        tilesetColumnsById: tilesetColumnsById,
        emitErrors: false,
      );
      if (resolvedBrush == null) return null;
      final compatibility = _resolveLayerBrushCompatibility(
        activeLayer,
        resolvedBrush.tilesetId,
      );
      final validity = compatibility == _BrushLayerCompatibility.incompatible
          ? MapToolPreviewValidity.invalid
          : MapToolPreviewValidity.valid;
      return MapToolPreview.paint(
        origin: hoveredTile,
        size: resolvedBrush.pattern.size,
        tilesetId: resolvedBrush.tilesetId,
        tiles: resolvedBrush.pattern.tiles,
        validity: validity,
      );
    }

    if (tool == EditorToolType.terrainPaint) {
      if (activeLayer is TerrainLayer) {
        final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
        if (terrainFootprint == null) return null;
        return MapToolPreview.terrainPaint(
          origin: hoveredTile,
          size: terrainFootprint.size,
          terrain: state.selectedTerrainType,
          validity: MapToolPreviewValidity.valid,
        );
      }
      if (activeLayer is PathLayer) {
        final pathFootprint = _resolvePathFootprint();
        return MapToolPreview.pathPaint(
          origin: hoveredTile,
          size: pathFootprint.size,
          validity: MapToolPreviewValidity.valid,
        );
      }
      return null;
    }

    if (tool == EditorToolType.collisionPaint) {
      if (activeLayer is! CollisionLayer) return null;
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionPaint(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }

    if (activeLayer is TileLayer) {
      final erasePattern = _resolveErasePattern(emitErrors: false);
      if (erasePattern == null) return null;
      return MapToolPreview.erase(
        origin: hoveredTile,
        size: erasePattern.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionErase(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
      if (terrainFootprint == null) return null;
      return MapToolPreview.terrainErase(
        origin: hoveredTile,
        size: terrainFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      return MapToolPreview.pathErase(
        origin: hoveredTile,
        size: pathFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    return null;
  }

  void paintSelectedTileAt(GridPos pos) {
    beginMapStroke();
    paintSelectedBrushAt(pos, tilesetColumnsById: const {});
    endMapStroke();
  }

  void beginMapStroke() {
    state = _mapEditingController.beginStroke(state);
  }

  void endMapStroke() {
    state = _mapEditingController.endStroke(state);
  }

  void undoMap() {
    endMapStroke();
    final restored = _mapEditingController.undo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  void redoMap() {
    endMapStroke();
    final restored = _mapEditingController.redo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  EditorBrush _clearBrushIfTilesetRemoved(EditorBrush brush, String tilesetId) {
    if (brush is TileEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is PaletteEntryEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element != null && element.tilesetId == tilesetId) {
        return const EditorBrush.none();
      }
    }
    return brush;
  }

  _PaintPattern _buildPatternFromSource(
    TilesetSourceRect source, {
    required int tilesetColumns,
  }) {
    final tiles = List<int>.filled(
      source.width * source.height,
      0,
      growable: false,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final sourceX = source.x + x;
        final sourceY = source.y + y;
        tiles[y * source.width + x] = sourceY * tilesetColumns + sourceX + 1;
      }
    }
    return _PaintPattern(
      size: GridSize(width: source.width, height: source.height),
      tiles: tiles,
    );
  }

  _ResolvedBrushPattern? _resolveActiveBrushPattern({
    required Map<String, int> tilesetColumnsById,
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) return null;

    if (brush is TileEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected tile brush does not have a valid tileset');
        }
        return null;
      }
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'tile',
        pattern: _PaintPattern(
          size: const GridSize(width: 1, height: 1),
          tiles: <int>[brush.tileId],
        ),
      );
    }

    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
            'Selected palette brush does not have a valid tileset',
          );
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'palette entry',
        pattern: _buildPatternFromSource(
          entry.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      final tilesetId = element.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected project element does not have a tileset');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'element',
        pattern: _buildPatternFromSource(
          element.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    return null;
  }

  _ErasePattern? _resolveErasePattern({
    required bool emitErrors,
  }) {
    final footprint = _resolveBrushFootprint(emitErrors: emitErrors);
    if (footprint == null) return null;
    return _ErasePattern(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveCollisionFootprint({
    required bool emitErrors,
  }) {
    if (state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    return _resolveBrushFootprint(emitErrors: emitErrors);
  }

  _ResolvedBrushFootprint? _resolveTerrainFootprint({
    required bool emitErrors,
  }) {
    final footprint = _terrainPaintingCoordinator.resolveFootprint(
      terrain: state.selectedTerrainType,
    );
    return _ResolvedBrushFootprint(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveBrushFootprint({
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is TileEditorBrush) {
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
              'Selected palette brush does not have a valid tileset');
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: entry.frames.primarySource.width,
          height: entry.frames.primarySource.height,
        ),
        failureLabel: 'palette entry',
      );
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: element.frames.primarySource.width,
          height: element.frames.primarySource.height,
        ),
        failureLabel: 'element',
      );
    }
    return null;
  }

  void _paintPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required _PaintPattern pattern,
    required String failureLabel,
  }) {
    try {
      final useCase = ref.read(paintTilePatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        tiles: pattern.tiles,
        clipToMapBounds: true,
      );
      final project = state.project;
      final committed = project == null
          ? painted
          : _placedElementInstanceIndexer.syncLayer(
              map: painted,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint $failureLabel: $e');
    }
  }

  void _erasePattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final project = state.project;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        final committed = project == null
            ? erased
            : _placedElementInstanceIndexer.syncLayer(
                map: erased,
                project: project,
                layerId: layerId,
              );
        _applyMapMutation(
          previousMap: map,
          updatedMap: committed,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }

      final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase $failureLabel: $e');
    }
  }

  void _paintCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(paintCollisionOnMapUseCaseProvider);
        final painted = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: painted,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(paintCollisionPatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: painted,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint collision $failureLabel: $e');
    }
  }

  void _eraseCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseCollisionOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(eraseCollisionPatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase collision $failureLabel: $e');
    }
  }

  void _paintTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required TerrainType terrain,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _terrainPaintingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: terrain,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint terrain $failureLabel: $e');
    }
  }

  void _paintPathPattern({
    required MapData map,
    required MapData previousMap,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _pathLayerEditingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: previousMap,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint path $failureLabel: $e');
    }
  }

  void _eraseTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _terrainPaintingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase terrain $failureLabel: $e');
    }
  }

  void _erasePathPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _pathLayerEditingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase path $failureLabel: $e');
    }
  }

  void _setPaintError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  _ActiveTileLayerContext? _resolveActiveTileLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active tile layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TileLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a tile layer');
      }
      return null;
    }
    return _ActiveTileLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveCollisionLayerContext? _resolveActiveCollisionLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active collision layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! CollisionLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a collision layer');
      }
      return null;
    }
    return _ActiveCollisionLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveTerrainLayerContext? _resolveActiveTerrainLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active terrain layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TerrainLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a terrain layer');
      }
      return null;
    }
    return _ActiveTerrainLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  PathLayerBrushFootprint _resolvePathFootprint() {
    return _pathLayerEditingCoordinator.resolveFootprint();
  }

  _ActivePathLayerContext? _resolveActivePathLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active path layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! PathLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a path layer');
      }
      return null;
    }
    return _ActivePathLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _BrushLayerCompatibility _resolveLayerBrushCompatibility(
    TileLayer activeLayer,
    String brushTilesetId,
  ) {
    final currentTilesetId = activeLayer.tilesetId?.trim();
    if (currentTilesetId == brushTilesetId) {
      return _BrushLayerCompatibility.compatible;
    }
    if (currentTilesetId == null ||
        currentTilesetId.isEmpty ||
        _isTileLayerEmpty(activeLayer)) {
      return _BrushLayerCompatibility.rebindable;
    }
    return _BrushLayerCompatibility.incompatible;
  }

  MapData? _prepareMapForBrushTileset({
    required MapData map,
    required String layerId,
    required TileLayer activeLayer,
    required String brushTilesetId,
  }) {
    final compatibility = _resolveLayerBrushCompatibility(
      activeLayer,
      brushTilesetId,
    );
    if (compatibility == _BrushLayerCompatibility.compatible) {
      return map;
    }
    if (compatibility == _BrushLayerCompatibility.incompatible) {
      _setPaintError(
        'Layer "${activeLayer.name}" already contains tiles from another source',
      );
      return null;
    }

    final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
    final layerIndex = updatedLayers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) {
      _setPaintError('Active layer not found: $layerId');
      return null;
    }
    final layer = updatedLayers[layerIndex];
    if (layer is! TileLayer) {
      _setPaintError('Active layer is not a tile layer');
      return null;
    }
    updatedLayers[layerIndex] = layer.copyWith(tilesetId: brushTilesetId);
    final updatedMap = map.copyWith(
      layers: updatedLayers,
      tilesetId: map.tilesetId.trim().isEmpty ? brushTilesetId : map.tilesetId,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: layerId,
      statusMessage: 'Layer "${activeLayer.name}" updated for current brush',
      partOfStroke: true,
    );
    state = state.copyWith(
      selectedTilesetEditorId: brushTilesetId,
      selectedTilesetElementGroupId: null,
      paletteCategoryFilter: null,
    );
    return updatedMap;
  }

  bool _isTileLayerEmpty(TileLayer layer) {
    for (final tile in layer.tiles) {
      if (tile != 0) return false;
    }
    return true;
  }

  void addMapLayer({
    required MapLayerKind kind,
    required String name,
    String? tileTilesetId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      int? insertIndex;
      final activeId = state.activeLayerId;
      if (activeId != null) {
        final idx = map.layers.indexWhere((layer) => layer.id == activeId);
        if (idx >= 0) {
          insertIndex = idx;
        }
      }
      final result = useCase.execute(
        map,
        kind: kind,
        name: name,
        tileTilesetId: tileTilesetId,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add layer: $e');
    }
  }

  void addSurfaceLayer({
    String name = 'Surfaces',
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      int? insertIndex;
      final activeId = state.activeLayerId;
      if (activeId != null) {
        final idx = map.layers.indexWhere((layer) => layer.id == activeId);
        if (idx >= 0) {
          insertIndex = idx;
        }
      }
      final result = useCase.executeSurface(
        map,
        name: name,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Surface layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add surface layer: $e');
    }
  }

  /// Lot Environment-20 : [EnvironmentLayerContent.targetTileLayerId] uniquement.
  void setEnvironmentLayerTargetTileLayer({
    required String environmentLayerId,
    required String? targetTileLayerId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = SetEnvironmentLayerTargetTileLayerUseCase();
      final updated = useCase.execute(
        map,
        environmentLayerId: environmentLayerId,
        targetTileLayerId: targetTileLayerId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: environmentLayerId,
        statusMessage: targetTileLayerId == null
            ? 'Environment layer target tile layer cleared'
            : 'Environment layer target tile layer updated',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to set environment target tile layer: $e',
      );
    }
  }

  void renameMapLayer(String layerId, String name) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(renameMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        name: name,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Layer renamed',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename layer: $e');
    }
  }

  void deleteMapLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final removedIndex = _findLayerIndexById(map, layerId);
    if (removedIndex < 0) return;
    try {
      final useCase = ref.read(deleteMapLayerUseCaseProvider);
      final updated = useCase.execute(map, layerId: layerId);
      final nextActiveLayerId = state.activeLayerId == layerId
          ? _editorMapSessionCoordinator.resolveFallbackLayerIdAfterDeletion(
              updated,
              removedIndex: removedIndex,
            )
          : _editorMapSessionCoordinator.resolveActiveLayerId(
              updated,
              preferredLayerId: state.activeLayerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: nextActiveLayerId,
        statusMessage: 'Layer deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete layer: $e');
    }
  }

  void deleteAllMapLayers() {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(deleteAllMapLayersUseCaseProvider);
      final updated = useCase.execute(map);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId:
            _editorMapSessionCoordinator.resolveActiveLayerId(updated),
        statusMessage: 'All layers removed',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove all layers: $e');
    }
  }

  void moveMapLayerUp(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void moveMapLayerDown(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerForward(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerBackward(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void _moveMapLayer(String layerId, int direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(moveMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        direction: direction,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Layer reordered',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder layer: $e');
    }
  }

  void reorderMapLayers(int oldIndex, int newIndex) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(reorderMapLayersUseCaseProvider);
      final updated = useCase.execute(
        map,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Layer reordered',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder layer: $e');
    }
  }

  /// Places [layerId] before [beforeIndex] (0 = top of list, [layers.length] = bottom).
  void moveMapLayerBeforeIndex(String layerId, int beforeIndex) {
    final map = state.activeMap;
    if (map == null) return;
    final oldIndex = map.layers.indexWhere((layer) => layer.id == layerId);
    if (oldIndex < 0) return;
    reorderMapLayers(oldIndex, beforeIndex);
  }

  void setMapLayerVisibility(String layerId, bool isVisible) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerVisibilityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        isVisible: isVisible,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: isVisible ? 'Layer shown' : 'Layer hidden',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update layer: $e');
    }
  }

  void setMapLayerOpacity(String layerId, double opacity) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerOpacityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        opacity: opacity,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update layer opacity: $e');
    }
  }

  void selectTool(EditorToolType tool) {
    state = _mapSelectionController.selectTool(
      current: state,
      tool: tool,
    );
  }

  void selectTerrainType(TerrainType terrain) {
    state = _mapSelectionController.selectTerrainType(
      current: state,
      terrain: terrain,
    );
  }

  void selectTerrainPreset(String? presetId) {
    state = _mapSelectionController.selectTerrainPreset(
      current: state,
      preset: getTerrainPresetById(presetId),
    );
  }

  void selectPathPreset(String? presetId) {
    state = _mapSelectionController.selectPathPreset(
      current: state,
      preset: getPathPresetById(presetId),
    );
  }

  void selectSurfacePreset(String? presetId) {
    final preset = getSurfacePresetById(presetId);
    if (preset == null) {
      state = state.copyWith(errorMessage: 'Surface not found');
      return;
    }
    state = state.copyWith(
      selectedSurfacePresetId: preset.id,
      activeTool: EditorToolType.surfacePaint,
      statusMessage: 'Surface sélectionnée : ${preset.name}',
      errorMessage: null,
    );
  }

  void selectPathPresetForActivePathLayer(String? presetId) {
    final preset = getPathPresetById(presetId);
    if (preset == null) {
      state = state.copyWith(errorMessage: 'Path preset not found');
      return;
    }
    selectPathPreset(presetId);
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! PathLayer) {
      return;
    }
    assignPathPresetToActivePathLayer(preset.id);
  }

  void selectTerrainPaintMode({
    TerrainType? terrainType,
  }) {
    state = _mapSelectionController.selectTerrainPaintMode(
      current: state,
      terrainType: terrainType,
    );
  }

  void selectPathPaintMode() {
    state = _mapSelectionController.selectPathPaintMode(
      current: state,
      selectedPathPreset: getSelectedPathPreset(),
    );
  }

  void selectSurfacePaintMode() {
    if (getSelectedSurfacePreset() == null) {
      state = state.copyWith(errorMessage: 'Select a surface before painting');
      return;
    }
    state = state.copyWith(
      activeTool: EditorToolType.surfacePaint,
      statusMessage: 'Surface paint mode',
      errorMessage: null,
    );
  }

  Future<void> createTerrainPreset({
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    String tilesetId = '',
    List<TerrainPresetVariant> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create terrain preset: $e',
      );
    }
  }

  Future<void> updateTerrainPreset({
    required String presetId,
    String? name,
    TerrainType? terrainType,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<TerrainPresetVariant>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selectedPreset =
          _terrainPresetResolver.findTerrainPresetById(updated, presetId) ??
              (throw EditorNotFoundException(
                'Terrain preset not found: $presetId',
              ));
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selectedPreset,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update terrain preset: $e',
      );
    }
  }

  Future<void> deleteTerrainPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete terrain preset: $e',
      );
    }
  }

  Future<void> createPathPreset({
    required String name,
    PathSurfaceKind surfaceKind = PathSurfaceKind.path,
    String? categoryId,
    String tilesetId = '',
    List<PathPresetVariantMapping> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        activeTool: EditorToolType.terrainPaint,
        statusMessage: 'Path preset created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create path preset: $e');
    }
  }

  Future<void> updatePathPreset({
    required String presetId,
    String? name,
    PathSurfaceKind? surfaceKind,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<PathPresetVariantMapping>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updatePathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selected = updated.pathPresets.firstWhere(
        (preset) => preset.id == presetId,
        orElse: () => throw EditorNotFoundException(
          'Path preset not found: $presetId',
        ),
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selected,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Path preset updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update path preset: $e');
    }
  }

  List<PathLayer> getPathLayersForPreset(String presetId) {
    final map = state.activeMap;
    if (map == null) return const [];
    return map.layers
        .whereType<PathLayer>()
        .where((l) => l.presetId.trim() == presetId.trim())
        .toList(growable: false);
  }

  void applyPathLayerAnimationTriggers({
    required String layerId,
    required List<PathAnimationTriggerRule> triggers,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationTriggers(
        map,
        layerId: layerId,
        triggers: triggers,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Animation triggers updated',
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to update animation triggers: $e');
    }
  }

  void setPathLayerAnimationMode({
    required String layerId,
    required PathAnimationMode mode,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationModeInMap(
        map,
        layerId: layerId,
        mode: mode,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Animation mode updated',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update animation mode: $e');
    }
  }

  Future<void> deletePathPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePathPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Path preset deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete path preset: $e');
    }
  }

  Future<void> createPresetCategory({
    required String name,
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        kind: kind,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> renamePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renamePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> deletePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
      );
      final selection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Category deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete category: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Encounter tables
  // ---------------------------------------------------------------------------

  Future<void> createEncounterTable({
    required String name,
    required EncounterKind encounterKind,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table created',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create encounter table: $e');
    }
  }

  Future<void> updateEncounterTable({
    required String tableId,
    String? name,
    EncounterKind? encounterKind,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter table: $e');
    }
  }

  Future<void> deleteEncounterTable(String tableId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterTableUseCaseProvider);
      final updated = await useCase.execute(fs, project, tableId: tableId);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter table: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Project dialogues (bibliothèque)
  // ---------------------------------------------------------------------------

  void selectProjectDialogue(String? dialogueId) {
    state = _projectContentController.selectProjectDialogue(state, dialogueId);
  }

  Future<void> createProjectDialogue({
    required String name,
    String? folderId,
  }) async {
    state = await _projectContentController.createProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      folderId: folderId,
    );
  }

  Future<void> importProjectDialogue({
    required String absoluteSourcePath,
    required String displayName,
    String? folderId,
  }) async {
    state = await _projectContentController.importProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      absoluteSourcePath: absoluteSourcePath,
      displayName: displayName,
      folderId: folderId,
    );
  }

  Future<void> renameProjectDialogue({
    required String dialogueId,
    required String newName,
  }) async {
    state = await _projectContentController.renameProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      newName: newName,
    );
  }

  Future<void> deleteProjectDialogue(String dialogueId) async {
    state = await _projectContentController.deleteProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  Future<void> createDialogueLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    state = await _projectContentController.createDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      parentFolderId: parentFolderId,
    );
  }

  Future<void> renameDialogueLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    state = await _projectContentController.renameDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      name: name,
    );
  }

  Future<void> moveDialogueLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    state = await _projectContentController.moveDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      newParentFolderId: newParentFolderId,
    );
  }

  Future<void> deleteDialogueLibraryFolder(String folderId) async {
    state = await _projectContentController.deleteDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
    );
  }

  Future<void> assignDialogueToLibraryFolder({
    required String dialogueId,
    required String folderId,
  }) async {
    state = await _projectContentController.assignDialogueToLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      folderId: folderId,
    );
  }

  Future<void> moveDialogueToLibraryRoot(String dialogueId) async {
    state = await _projectContentController.moveDialogueToLibraryRoot(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  // ---------------------------------------------------------------------------
  // Narrative Studio - scénarios
  // ---------------------------------------------------------------------------
  //
  // Ce bloc réintroduit des mutations scénario ciblées, mais dans un cadre
  // beaucoup plus strict que l'ancien "Scenario Graph" générique:
  // - surface d'édition centrale (Cutscene Studio v1 guidé),
  // - opérations explicites create / update / delete,
  // - persistance via use-cases dédiés + validation `ProjectValidator`.
  //
  // Frontière volontaire:
  // - ce notifier orchestre la mutation et la UX (messages, sélection),
  // - la logique métier de validation/persistance reste dans les use-cases.
  // ---------------------------------------------------------------------------

  Future<void> createProjectScenario(ScenarioAsset scenario) async {
    state = await _projectContentController.createProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenario: scenario,
    );
  }

  Future<void> updateProjectScenario({
    required String scenarioId,
    required ScenarioAsset scenario,
  }) async {
    state = await _projectContentController.updateProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
      scenario: scenario,
    );
  }

  Future<void> deleteProjectScenario(String scenarioId) async {
    state = await _projectContentController.deleteProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
    );
  }

  Future<void> addEncounterEntry({
    required String tableId,
    required String speciesId,
    required int minLevel,
    required int maxLevel,
    int weight = 1,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(addEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry added',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add encounter entry: $e');
    }
  }

  Future<void> updateEncounterEntry({
    required String tableId,
    required int entryIndex,
    String? speciesId,
    int? minLevel,
    int? maxLevel,
    int? weight,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter entry: $e');
    }
  }

  Future<void> deleteEncounterEntry({
    required String tableId,
    required int entryIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter entry: $e');
    }
  }

  void activateFirstTerrainLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is TerrainLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.terrain,
        name: 'Terrain',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No terrain layer found in this map',
    );
  }

  void activateFirstPathLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is PathLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.path,
        name: 'Path',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No path layer found in this map',
    );
  }

  void activateFirstSurfaceLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is SurfaceLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (!createIfMissing) {
      state = state.copyWith(
        errorMessage: 'No surface layer found in this map',
      );
      return;
    }

    try {
      final result = _surfacePaintingController.ensureSurfaceLayer(
        map: map,
        preferredLayerId: state.activeLayerId,
      );
      if (!result.changed) {
        state = state.copyWith(activeLayerId: result.layerId);
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layerId,
        statusMessage: 'Surface layer created',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create surface layer: $e');
    }
  }

  void setCollisionBrushSizeMode(CollisionBrushSizeMode mode) {
    if (state.collisionBrushSizeMode == mode) return;
    state = state.copyWith(
      collisionBrushSizeMode: mode,
      statusMessage: mode == CollisionBrushSizeMode.singleTile
          ? 'Collision brush: 1x1'
          : 'Collision brush: brush footprint',
      errorMessage: null,
    );
  }

  void toggleCollisionBrushSizeMode() {
    setCollisionBrushSizeMode(
      state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile
          ? CollisionBrushSizeMode.brushFootprint
          : CollisionBrushSizeMode.singleTile,
    );
  }

  void setActiveLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final selectedLayer = _findLayerById(map, layerId);
    if (selectedLayer == null) {
      state = state.copyWith(errorMessage: 'Layer not found: $layerId');
      return;
    }
    state = state.copyWith(
      activeLayerId: layerId,
      selectedPlacedElementInstanceId: null,
      errorMessage: null,
    );
    _coerceActiveToolIfIncompatibleWithLayer();
  }

  void setTilesElementsPanelMode(TilesElementsPanelMode mode) {
    if (state.tilesElementsPanelMode == mode) {
      return;
    }
    state = state.copyWith(
      tilesElementsPanelMode: mode,
      errorMessage: null,
    );
  }

  void selectPlacedElementInstance({
    required String? instanceId,
    String? elementId,
    String? layerId,
  }) {
    if (state.selectedPlacedElementInstanceId == instanceId) {
      return;
    }
    state = state.copyWith(
      selectedPlacedElementInstanceId: instanceId,
      errorMessage: null,
    );
    if (instanceId == null) {
      debugPrint('[editor][elements] selected placed instance cleared');
      return;
    }
    final safeElementId = elementId?.trim() ?? '';
    final safeLayerId = layerId?.trim() ?? '';
    debugPrint(
      '[editor][elements] selected placed instance id=$instanceId elementId=$safeElementId layer=$safeLayerId',
    );
  }

  void setPlacedElementInstanceCollisionApplied({
    required String instanceId,
    required bool applyCollision,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.applyCollision == applyCollision) {
      return;
    }
    final updatedMap = setMapPlacedElementCollisionApplied(
      map,
      instanceId: trimmedId,
      applyCollision: applyCollision,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage:
          'Collision ${applyCollision ? 'activée' : 'désactivée'} pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceAnimationConfig({
    required String instanceId,
    required MapPlacedElementAnimation? animation,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.animation == animation) {
      return;
    }
    final updatedMap = setMapPlacedElementAnimation(
      map,
      instanceId: trimmedId,
      animation: animation,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: animation == null
          ? 'Animation réinitialisée pour ${previous.elementId}'
          : 'Animation mise à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceBehaviors({
    required String instanceId,
    required List<MapPlacedElementBehavior> behaviors,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (listEquals(previous.behaviors, behaviors)) {
      return;
    }
    final updatedMap = setMapPlacedElementBehaviors(
      map,
      instanceId: trimmedId,
      behaviors: behaviors,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: behaviors.isEmpty
          ? 'Comportements réinitialisés pour ${previous.elementId}'
          : 'Comportements mis à jour pour ${previous.elementId}',
    );
  }

  void deletePlacedElementInstance({
    required String instanceId,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final instance = map.placedElements[index];
    final layer = _findLayerById(map, instance.layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Placed element layer is not a tile layer: ${instance.layerId}',
      );
      return;
    }

    final project = state.project;
    var patternSize = const GridSize(width: 1, height: 1);
    if (project != null) {
      ProjectElementEntry? element;
      for (final entry in project.elements) {
        if (entry.id == instance.elementId) {
          element = entry;
          break;
        }
      }
      if (element != null) {
        final source = element.frames.primarySource;
        patternSize = GridSize(
          width: source.width > 0 ? source.width : 1,
          height: source.height > 0 ? source.height : 1,
        );
      }
    }

    try {
      late final MapData erased;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
        );
      } else {
        final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
          patternSize: patternSize,
          clipToMapBounds: true,
        );
      }

      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: instance.layerId,
            );

      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Instance supprimée (${instance.elementId})',
      );
      debugPrint(
        '[editor][elements] deleted placed instance id=$trimmedId elementId=${instance.elementId} layer=${instance.layerId} pos=(${instance.pos.x},${instance.pos.y})',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete placed element instance: $e',
      );
    }
  }

  /// Bascule vers la sélection si l’outil courant ne peut pas agir sur le calque actif.
  void _coerceActiveToolIfIncompatibleWithLayer() {
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      state,
    );
  }

  void updateHoveredTile(GridPos? pos) {
    if (state.hoveredTile != pos) {
      state = state.copyWith(hoveredTile: pos);
    }
  }

  void pan(Offset delta) {
    state = state.copyWith(panOffset: state.panOffset + delta);
  }

  void zoom(double delta) {
    final newZoom = (state.zoom + delta).clamp(0.1, 5.0);
    state = state.copyWith(zoom: newZoom);
  }

  void _applyMapMutation({
    required MapData previousMap,
    required MapData updatedMap,
    required String? preferredActiveLayerId,
    String? preferredSelectedEntityId,
    String? preferredSelectedMapEventId,
    String? preferredSelectedWarpId,
    String? preferredSelectedTriggerId,
    bool partOfStroke = false,
    bool updateSavedSnapshot = false,
    GridPos? hoveredTile,
    bool updateHoveredTile = false,
    String? statusMessage,
  }) {
    final next = _mapEditingController.applyMutation(
      current: state,
      previousMap: previousMap,
      updatedMap: updatedMap,
      preferredActiveLayerId: preferredActiveLayerId,
      preferredSelectedEntityId: preferredSelectedEntityId,
      preferredSelectedMapEventId: preferredSelectedMapEventId,
      preferredSelectedWarpId: preferredSelectedWarpId,
      preferredSelectedTriggerId: preferredSelectedTriggerId,
      partOfStroke: partOfStroke,
      updateSavedSnapshot: updateSavedSnapshot,
      hoveredTile: hoveredTile,
      updateHoveredTile: updateHoveredTile,
      statusMessage: statusMessage,
    );
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      next,
    );
  }

  int _findLayerIndexById(MapData map, String layerId) {
    return map.layers.indexWhere((layer) => layer.id == layerId);
  }

  MapLayer? _findLayerById(MapData map, String layerId) {
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  String? _resolveEventPlacementLayerId(MapData map) {
    final activeLayerId = state.activeLayerId?.trim();
    if (activeLayerId != null &&
        activeLayerId.isNotEmpty &&
        map.layers.any((layer) => layer.id == activeLayerId)) {
      return activeLayerId;
    }
    if (map.layers.isNotEmpty) {
      return map.layers.first.id;
    }
    return null;
  }

  String _generateUniqueMapEventId(MapData map) {
    final ids = map.events.map((event) => event.id).toSet();
    if (!ids.contains('event')) {
      return 'event';
    }
    var index = 1;
    while (ids.contains('event_$index')) {
      index++;
    }
    return 'event_$index';
  }

  // ---------------------------------------------------------------------------
  // Characters (bibliothèque personnages)
  // ---------------------------------------------------------------------------

  void selectCharacter(String? characterId) {
    state = state.copyWith(selectedCharacterId: characterId);
  }

  Future<void> createCharacter({
    required String name,
    required String tilesetId,
    int frameWidth = 1,
    int frameHeight = 2,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId:
            updated.characters.isNotEmpty ? updated.characters.last.id : null,
        statusMessage: 'Character created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create character: $e');
    }
  }

  Future<void> updateCharacter({
    required String characterId,
    String? name,
    String? tilesetId,
    int? frameWidth,
    int? frameHeight,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Character updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update character: $e');
    }
  }

  Future<void> deleteCharacter(String characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId: state.selectedCharacterId == characterId
            ? null
            : state.selectedCharacterId,
        statusMessage: 'Character deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete character: $e');
    }
  }

  Future<void> upsertCharacterAnimation({
    required String characterId,
    required CharacterAnimationState animState,
    required EntityFacing direction,
    required List<CharacterAnimationFrame> frames,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(upsertCharacterAnimationUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        animState: animState,
        direction: direction,
        frames: frames,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Animation updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update animation: $e');
    }
  }

  Future<void> setPlayerCharacter(String? characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(setPlayerCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: characterId == null
            ? 'Player character cleared'
            : 'Player character set',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to set player character: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Trainers (bibliothèque dresseurs)
  // ---------------------------------------------------------------------------

  void selectTrainer(String? trainerId) {
    state = state.copyWith(selectedTrainerId: trainerId);
  }

  Future<bool> createTrainer({
    required String name,
    required String trainerClass,
    int? battleDifficulty,
    String? battleBackgroundRelativePath,
    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    List<String> tags = const <String>[],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(createTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: battleDifficulty,
        battleBackgroundRelativePath: battleBackgroundRelativePath,
        characterId: characterId,
        portraitElementId: portraitElementId,
        battleThemeId: battleThemeId,
        victoryThemeId: victoryThemeId,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId:
            updated.trainers.isNotEmpty ? updated.trainers.last.id : null,
        statusMessage: 'Trainer created',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trainer: $e');
      return false;
    }
  }

  Future<bool> updateTrainer({
    required String trainerId,
    String? name,
    String? trainerClass,
    Object? battleDifficulty = _trainerUnset,
    Object? battleBackgroundRelativePath = _trainerUnset,
    Object? characterId = _trainerUnset,
    Object? portraitElementId = _trainerUnset,
    Object? battleThemeId = _trainerUnset,
    Object? victoryThemeId = _trainerUnset,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: _trainerFieldUpdate<int>(battleDifficulty),
        battleBackgroundRelativePath:
            _trainerFieldUpdate<String>(battleBackgroundRelativePath),
        characterId: _trainerFieldUpdate<String>(characterId),
        portraitElementId: _trainerFieldUpdate<String>(portraitElementId),
        battleThemeId: _trainerFieldUpdate<String>(battleThemeId),
        victoryThemeId: _trainerFieldUpdate<String>(victoryThemeId),
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Trainer updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trainer: $e');
      return false;
    }
  }

  Future<bool> deleteTrainer(String trainerId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId: state.selectedTrainerId == trainerId
            ? null
            : state.selectedTrainerId,
        statusMessage: 'Trainer deleted',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trainer: $e');
      return false;
    }
  }

  Future<bool> addTrainerPokemon({
    required String trainerId,
    required String speciesId,
    required int level,
    List<String> moves = const <String>[],
    String? heldItemId,
    String? formId,
    String? gender,
    bool shiny = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(addTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: heldItemId,
        formId: formId,
        gender: gender,
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon added',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add Pokémon: $e');
      return false;
    }
  }

  Future<bool> updateTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
    String? speciesId,
    int? level,
    List<String>? moves,
    Object? heldItemId = _trainerUnset,
    Object? formId = _trainerUnset,
    Object? gender = _trainerUnset,
    bool? shiny,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: _trainerFieldUpdate<String>(heldItemId),
        formId: _trainerFieldUpdate<String>(formId),
        gender: _trainerFieldUpdate<String>(gender),
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update Pokémon: $e');
      return false;
    }
  }

  Future<bool> deleteTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon removed',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove Pokémon: $e');
      return false;
    }
  }
}

TrainerFieldUpdate<T> _trainerFieldUpdate<T>(Object? rawValue) {
  if (identical(rawValue, _trainerUnset)) {
    return TrainerFieldUpdate<T>.keep();
  }
  return TrainerFieldUpdate<T>.set(rawValue as T?);
}

class _PaintPattern {
  const _PaintPattern({
    required this.size,
    required this.tiles,
  });

  final GridSize size;
  final List<int> tiles;
}

enum _BrushLayerCompatibility {
  compatible,
  rebindable,
  incompatible,
}

class _ResolvedBrushPattern {
  const _ResolvedBrushPattern({
    required this.tilesetId,
    required this.failureLabel,
    required this.pattern,
  });

  final String tilesetId;
  final String failureLabel;
  final _PaintPattern pattern;
}

class _ResolvedBrushFootprint {
  const _ResolvedBrushFootprint({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ErasePattern {
  const _ErasePattern({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ActiveTileLayerContext {
  const _ActiveTileLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TileLayer layer;
}

class _ActiveCollisionLayerContext {
  const _ActiveCollisionLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final CollisionLayer layer;
}

class _ActiveTerrainLayerContext {
  const _ActiveTerrainLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TerrainLayer layer;
}

class _ActivePathLayerContext {
  const _ActivePathLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final PathLayer layer;
}
```

### `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/terrain_selection_mode.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../../features/surface_painter/surface_palette_panel.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_section_card.dart';
import 'encounter_tables_panel.dart';
import 'entity_properties_panel.dart';
import 'event_properties_panel.dart';
import 'gameplay_zone_properties_panel.dart';
import 'environment_layer_inspector_panel.dart';
import 'layers_panel.dart';
import 'map_connections_panel.dart';
import 'map_properties_panel.dart';
import 'terrain_map_panel.dart';
import 'tileset_palette_panel.dart';
import 'trigger_properties_panel.dart';
import 'warp_properties_panel.dart';

enum _InspectorSectionId {
  mapProperties,
  layers,
  environmentLayer,
  tiles,
  ground,
  surfacePlacements,
  surfaces,
  entities,
  events,
  connections,
  triggers,
  warps,
  gameplayZones,
  encounterTables,
}

class MapInspectorPanel extends ConsumerStatefulWidget {
  const MapInspectorPanel({super.key});

  @override
  ConsumerState<MapInspectorPanel> createState() => _MapInspectorPanelState();
}

class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
  final Map<_InspectorSectionId, bool> _expandedSections =
      <_InspectorSectionId, bool>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final activeMap = state.activeMap;
    final activeLayer = _findActiveLayer(activeMap, state.activeLayerId);

    if (activeMap == null) {
      return Container(
        alignment: Alignment.center,
        child: Text(
          'Open a map to inspect layers and map systems',
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final hasTileLayers = activeMap.layers.any((layer) => layer is TileLayer);
    final hasTerrainLayers =
        activeMap.layers.any((layer) => layer is TerrainLayer);
    final hasPathLayers = activeMap.layers.any((layer) => layer is PathLayer);
    final hasSurfaceLayers =
        activeMap.layers.any((layer) => layer is SurfaceLayer);
    final hasSurfacePresets =
        state.project?.surfaceCatalog.presets.isNotEmpty ?? false;
    final showEnvironmentLayerSection = activeLayer is EnvironmentLayer;
    final showTilesSection = activeLayer is TileLayer ||
        state.activeTool == EditorToolType.tilePaint ||
        (state.activeLayerId == null && hasTileLayers);
    final showGroundSection = hasTerrainLayers &&
        (activeLayer is TerrainLayer ||
            (activeLayer is! PathLayer &&
                state.activeTool == EditorToolType.terrainPaint &&
                state.terrainSelectionMode == TerrainSelectionMode.terrain));
    final showSurfaceSection = hasPathLayers && activeLayer is PathLayer;
    final showSurfacePlacementSection = hasSurfaceLayers ||
        hasSurfacePresets ||
        activeLayer is SurfaceLayer ||
        state.activeTool == EditorToolType.surfacePaint;
    const showConnectionsSection = true;
    final showEntitySection =
        state.activeTool == EditorToolType.entityPlacement ||
            state.selectedEntityId != null ||
            activeMap.entities.isNotEmpty;
    final showEventSection =
        state.activeTool == EditorToolType.eventPlacement ||
            state.selectedMapEventId != null ||
            activeMap.events.isNotEmpty;
    final showTriggerSection =
        state.activeTool == EditorToolType.triggerPlacement ||
            state.selectedTriggerId != null ||
            activeMap.triggers.isNotEmpty;
    final showWarpSection = state.activeTool == EditorToolType.warpPlacement ||
        state.selectedWarpId != null ||
        activeMap.warps.isNotEmpty;
    final showGameplayZoneSection =
        state.activeTool == EditorToolType.gameplayZonePlacement ||
            state.selectedGameplayZoneId != null ||
            activeMap.gameplayZones.isNotEmpty;
    final showEncounterTablesSection =
        (state.project?.encounterTables.isNotEmpty ?? false) ||
            showGameplayZoneSection;

    return LayoutBuilder(
      builder: (context, constraints) {
        final paletteHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(420.0, 760.0).toDouble()
            : 560.0;

        return SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _InspectorOverviewCard(
                map: activeMap,
                activeLayer: activeLayer,
              ),
              InspectorSectionCard(
                title: 'Propriétés de carte',
                subtitle:
                    'Gameplay et présentation (météo, musique, spawn par défaut…)',
                icon: CupertinoIcons.slider_horizontal_3,
                accentColor: EditorChrome.inspectorJoyPlum,
                expanded: _isExpanded(
                  _InspectorSectionId.mapProperties,
                  false,
                ),
                onToggle: () => _toggleSection(
                  _InspectorSectionId.mapProperties,
                  defaultExpanded: false,
                ),
                expandedHeight: 460,
                child: const MapPropertiesPanel(embedded: true),
              ),
              InspectorSectionCard(
                title: 'Layers',
                subtitle: activeLayer == null
                    ? 'Select the active layer for this map'
                    : 'Active: ${_layerLabel(activeLayer)}',
                icon: CupertinoIcons.layers,
                badgeText: '${activeMap.layers.length}',
                accentColor: EditorChrome.inspectorJoyBlue,
                expanded: _isExpanded(_InspectorSectionId.layers, true),
                onToggle: () => _toggleSection(
                  _InspectorSectionId.layers,
                  defaultExpanded: true,
                ),
                expandedHeight: 260,
                child: const LayersPanel(embedded: true),
              ),
              if (showEnvironmentLayerSection)
                InspectorSectionCard(
                  title: 'Environment Layer',
                  subtitle: null,
                  icon: CupertinoIcons.cloud,
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.environmentLayer,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.environmentLayer,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 360,
                  child: EnvironmentLayerInspectorPanel(
                    map: activeMap,
                    layer: activeLayer,
                    embedded: true,
                  ),
                ),
              if (showTilesSection)
                InspectorSectionCard(
                  title: 'Tiles & Elements',
                  subtitle:
                      'Palette de placement et gestion des instances posées sur le layer actif.',
                  icon: CupertinoIcons.square_grid_2x2,
                  accentColor: EditorChrome.inspectorJoyLilac,
                  expanded: _isExpanded(
                    _InspectorSectionId.tiles,
                    activeLayer is TileLayer ||
                        state.activeTool == EditorToolType.tilePaint,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.tiles,
                    defaultExpanded: activeLayer is TileLayer ||
                        state.activeTool == EditorToolType.tilePaint,
                  ),
                  expandedHeight: paletteHeight,
                  child: const TilesetPalettePanel(embedded: true),
                ),
              if (showGroundSection)
                InspectorSectionCard(
                  title: 'Base Ground',
                  subtitle: 'Terrain-only editing for the map background.',
                  icon: CupertinoIcons.tree,
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.ground,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.ground,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 300,
                  child: const TerrainMapPanel(
                    embedded: true,
                    mode: TerrainMapPanelMode.groundOnly,
                  ),
                ),
              if (showSurfacePlacementSection)
                InspectorSectionCard(
                  title: 'Surfaces',
                  subtitle:
                      'Choisir une surface et poser des placements dans la map.',
                  icon: CupertinoIcons.drop,
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.surfacePlacements,
                    activeLayer is SurfaceLayer ||
                        state.activeTool == EditorToolType.surfacePaint,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.surfacePlacements,
                    defaultExpanded: activeLayer is SurfaceLayer ||
                        state.activeTool == EditorToolType.surfacePaint,
                  ),
                  expandedHeight: 380,
                  child: const SurfacePainterPanel(embedded: true),
                ),
              if (showSurfaceSection)
                InspectorSectionCard(
                  title: 'Paths',
                  subtitle:
                      'Edit the active path layer for roads and specialized surfaces.',
                  icon: CupertinoIcons.map,
                  accentColor: EditorChrome.inspectorJoyAmber,
                  expanded: _isExpanded(
                    _InspectorSectionId.surfaces,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.surfaces,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 340,
                  child: const TerrainMapPanel(
                    embedded: true,
                    mode: TerrainMapPanelMode.surfaceOnly,
                  ),
                ),
              if (showEntitySection)
                InspectorSectionCard(
                  title: 'Map Entities',
                  subtitle: state.selectedEntityId != null
                      ? 'Selected entity ready for editing.'
                      : 'Visible world content such as NPCs, signs, items and spawn points.',
                  icon: CupertinoIcons.sparkles,
                  badgeText: '${activeMap.entities.length}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.entities,
                    state.activeTool == EditorToolType.entityPlacement ||
                        state.selectedEntityId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.entities,
                    defaultExpanded:
                        state.activeTool == EditorToolType.entityPlacement ||
                            state.selectedEntityId != null,
                  ),
                  expandedHeight: 560,
                  child: const EntityPropertiesPanel(embedded: true),
                ),
              if (showEventSection)
                InspectorSectionCard(
                  title: 'Map Events',
                  subtitle: state.selectedMapEventId != null
                      ? 'Selected event ready for editing.'
                      : 'Conditional event pages and script/message authoring.',
                  icon: CupertinoIcons.flag,
                  badgeText: '${activeMap.events.length}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.events,
                    state.activeTool == EditorToolType.eventPlacement ||
                        state.selectedMapEventId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.events,
                    defaultExpanded:
                        state.activeTool == EditorToolType.eventPlacement ||
                            state.selectedMapEventId != null,
                  ),
                  expandedHeight: 620,
                  child: const EventPropertiesPanel(embedded: true),
                ),
              if (showConnectionsSection)
                InspectorSectionCard(
                  title: 'Connections',
                  subtitle: 'Link the current map to adjacent world maps.',
                  icon: CupertinoIcons.arrow_branch,
                  badgeText: '${activeMap.connections.length}',
                  accentColor: EditorChrome.inspectorJoyPlum,
                  expanded: _isExpanded(_InspectorSectionId.connections, false),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.connections,
                    defaultExpanded: false,
                  ),
                  expandedHeight: 520,
                  child: const MapConnectionsPanel(embedded: true),
                ),
              if (showTriggerSection)
                InspectorSectionCard(
                  title: 'Triggers',
                  subtitle: state.selectedTriggerId != null
                      ? 'Selected trigger ready for editing.'
                      : 'Gameplay zones and editable trigger areas.',
                  icon: CupertinoIcons.square,
                  badgeText: '${activeMap.triggers.length}',
                  accentColor: EditorChrome.inspectorJoyCoral,
                  expanded: _isExpanded(
                    _InspectorSectionId.triggers,
                    state.activeTool == EditorToolType.triggerPlacement ||
                        state.selectedTriggerId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.triggers,
                    defaultExpanded:
                        state.activeTool == EditorToolType.triggerPlacement ||
                            state.selectedTriggerId != null,
                  ),
                  expandedHeight: 520,
                  child: const TriggerPropertiesPanel(embedded: true),
                ),
              if (showWarpSection)
                InspectorSectionCard(
                  title: 'Warps',
                  subtitle: state.selectedWarpId != null
                      ? 'Selected warp ready for editing.'
                      : 'Map transitions such as doors, stairs and exits.',
                  icon: CupertinoIcons.arrow_down_circle,
                  badgeText: '${activeMap.warps.length}',
                  accentColor: EditorChrome.inspectorJoyOrchid,
                  expanded: _isExpanded(
                    _InspectorSectionId.warps,
                    state.activeTool == EditorToolType.warpPlacement ||
                        state.selectedWarpId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.warps,
                    defaultExpanded:
                        state.activeTool == EditorToolType.warpPlacement ||
                            state.selectedWarpId != null,
                  ),
                  expandedHeight: 320,
                  child: const WarpPropertiesPanel(embedded: true),
                ),
              if (showGameplayZoneSection)
                InspectorSectionCard(
                  title: 'Gameplay Zones',
                  subtitle: state.selectedGameplayZoneId != null
                      ? 'Selected zone ready for editing.'
                      : 'Encounter areas, movement constraints and special zones.',
                  icon: CupertinoIcons.leaf_arrow_circlepath,
                  badgeText: '${activeMap.gameplayZones.length}',
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.gameplayZones,
                    state.activeTool == EditorToolType.gameplayZonePlacement ||
                        state.selectedGameplayZoneId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.gameplayZones,
                    defaultExpanded: state.activeTool ==
                            EditorToolType.gameplayZonePlacement ||
                        state.selectedGameplayZoneId != null,
                  ),
                  expandedHeight: 520,
                  child: const GameplayZonePropertiesPanel(embedded: true),
                ),
              if (showEncounterTablesSection)
                InspectorSectionCard(
                  title: 'Encounter Tables',
                  subtitle: 'Project-level encounter tables for wild Pokémon.',
                  icon: CupertinoIcons.list_bullet,
                  badgeText: '${state.project?.encounterTables.length ?? 0}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.encounterTables,
                    false,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.encounterTables,
                    defaultExpanded: false,
                  ),
                  expandedHeight: 480,
                  child: const EncounterTablesPanel(embedded: true),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isExpanded(_InspectorSectionId section, bool defaultExpanded) {
    return _expandedSections[section] ?? defaultExpanded;
  }

  void _toggleSection(
    _InspectorSectionId section, {
    required bool defaultExpanded,
  }) {
    setState(() {
      _expandedSections[section] =
          !(_expandedSections[section] ?? defaultExpanded);
    });
  }

  MapLayer? _findActiveLayer(MapData? map, String? activeLayerId) {
    if (map == null || activeLayerId == null) {
      return null;
    }
    for (final layer in map.layers) {
      if (layer.id == activeLayerId) {
        return layer;
      }
    }
    return null;
  }

  String _layerLabel(MapLayer layer) {
    return switch (layer) {
      TileLayer _ => 'Tile Layer',
      CollisionLayer _ => 'Collision Layer',
      TerrainLayer _ => 'Terrain Layer',
      PathLayer _ => 'Path Layer',
      SurfaceLayer _ => 'Surface Layer',
      ObjectLayer _ => 'Object Layer',
      EnvironmentLayer _ => 'Environment Layer',
    };
  }
}

class _InspectorOverviewCard extends StatelessWidget {
  const _InspectorOverviewCard({
    required this.map,
    required this.activeLayer,
  });

  final MapData map;
  final MapLayer? activeLayer;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const accentA = EditorChrome.inspectorJoyHoney;
    const accentB = EditorChrome.inspectorJoyApricot;
    final activeLayerText = activeLayer == null
        ? 'No active layer'
        : switch (activeLayer!) {
            TileLayer _ => 'Tile layer active',
            TerrainLayer _ => 'Ground layer active',
            PathLayer _ => 'Surface layer active',
            SurfaceLayer _ => 'Surface placement layer active',
            CollisionLayer _ => 'Collision layer active',
            ObjectLayer _ => 'Object layer active',
            EnvironmentLayer _ => 'Environment layer active',
          };

    final hi = EditorChrome.islandFillElevated(context);
    final lo = EditorChrome.islandFill(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(hi, accentA, 0.44)!,
            Color.lerp(lo, accentB, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color.lerp(accentA, accentB, 0.5)!.withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: EditorChrome.inspectorTileHardShadows(context),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, accentA, 0.78)!,
                  Color.lerp(accentB, const Color(0xFF1A0804), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentA.withValues(alpha: 0.9),
                width: 1.25,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.slider_horizontal_3,
              color: CupertinoColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  map.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${map.size.width} x ${map.size.height} tiles  •  ${map.layers.length} layers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activeLayerText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Inspecteur Lot Environment-19/20 : meta layer + cible [TileLayer] pour génération future.
class EnvironmentLayerInspectorPanel extends ConsumerWidget {
  const EnvironmentLayerInspectorPanel({
    super.key,
    required this.map,
    required this.layer,
    this.embedded = false,
  });

  final MapData map;
  final EnvironmentLayer layer;
  final bool embedded;

  List<TileLayer> _tileLayers() {
    final out = <TileLayer>[];
    for (final l in map.layers) {
      if (l is TileLayer) {
        out.add(l);
      }
    }
    return out;
  }

  TileLayer? _resolveTarget() {
    final tid = layer.content.targetTileLayerId;
    if (tid == null) return null;
    for (final l in map.layers) {
      if (l.id == tid && l is TileLayer) {
        return l;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final tiles = _tileLayers();
    final target = _resolveTarget();
    final tid = layer.content.targetTileLayerId;
    final invalidTarget = tid != null && target == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(embedded ? 8 : 10, 4, embedded ? 8 : 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Environment Layer',
            key: const Key('map-inspector-environment-layer-title'),
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce layer servira à dessiner des zones organiques et à générer des '
            'éléments naturels.\n'
            'La configuration des zones arrive dans un prochain lot.',
            key: const Key('map-inspector-environment-layer-body'),
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'TileLayer cible',
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (tiles.isEmpty) ...[
            Text(
              'Aucun TileLayer disponible dans cette map.\n'
              'Ajoutez d’abord un TileLayer pour recevoir les résultats générés.',
              key: const Key('env-layer-inspector-no-tile-layers'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (invalidTarget) ...[
            Text(
              'La cible configurée est introuvable ou invalide : $tid',
              key: const Key('env-layer-inspector-invalid-target'),
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            PushButton(
              key: const Key('env-layer-inspector-change-invalid'),
              controlSize: ControlSize.regular,
              onPressed: () => _pickTileLayer(context, notifier, tiles),
              child: const Text('Choisir un autre TileLayer cible'),
            ),
            const SizedBox(height: 8),
            PushButton(
              key: const Key('env-layer-inspector-remove-invalid'),
              controlSize: ControlSize.regular,
              secondary: true,
              onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
                environmentLayerId: layer.id,
                targetTileLayerId: null,
              ),
              child: const Text('Retirer la cible'),
            ),
          ] else if (target == null) ...[
            Text(
              'Aucun TileLayer cible sélectionné.',
              key: const Key('env-layer-inspector-no-target'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            PushButton(
              key: const Key('env-layer-inspector-choose-target'),
              controlSize: ControlSize.regular,
              onPressed: () => _pickTileLayer(context, notifier, tiles),
              child: const Text('Choisir le TileLayer cible'),
            ),
          ] else ...[
            Text(
              'Cible actuelle : ${target.name}',
              key: const Key('env-layer-inspector-current-target-name'),
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Id : ${target.id}',
              key: const Key('env-layer-inspector-current-target-id'),
              style: TextStyle(
                color: subtle,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            PushButton(
              key: const Key('env-layer-inspector-change-target'),
              controlSize: ControlSize.regular,
              onPressed: () => _pickTileLayer(context, notifier, tiles),
              child: const Text('Changer de TileLayer cible'),
            ),
            const SizedBox(height: 8),
            PushButton(
              key: const Key('env-layer-inspector-remove-target'),
              controlSize: ControlSize.regular,
              secondary: true,
              onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
                environmentLayerId: layer.id,
                targetTileLayerId: null,
              ),
              child: const Text('Retirer la cible'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickTileLayer(
    BuildContext context,
    EditorNotifier notifier,
    List<TileLayer> tiles,
  ) async {
    final picked = await showCupertinoListPicker<TileLayer>(
      context: context,
      title: 'TileLayer cible',
      items: tiles,
      labelOf: (t) => t.name,
    );
    if (picked == null) return;
    notifier.setEnvironmentLayerTargetTileLayer(
      environmentLayerId: layer.id,
      targetTileLayerId: picked.id,
    );
  }
}
```

### `packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart`

```dart
// ignore_for_file: prefer_const_constructors — fixtures MapData / MaterialApp non const pour lisibilité Lot 20

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/layer_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/environment_layer_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('Lot 20 — EnvironmentLayer target TileLayer', () {
    group('SetEnvironmentLayerTargetTileLayerUseCase', () {
      test('définit targetTileLayerId et préserve areas', () {
        final mask = EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: <bool>[false, false, false, false],
        );
        final area = EnvironmentArea(
          id: 'z1',
          name: 'Z',
          presetId: 'p1',
          mask: mask,
          seed: 0,
        );
        final env = MapLayer.environment(
          id: 'env',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: null,
            areas: [area],
          ),
        );
        final tile = TileLayer(
          id: 'tiles_main',
          name: 'Sol',
          tiles: const <int>[0, 0, 0, 0],
        );
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 2, height: 2),
          layers: [env, tile],
        );
        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
        final out = uc.execute(
          map,
          environmentLayerId: 'env',
          targetTileLayerId: 'tiles_main',
        );
        final layer = out.layers.first as EnvironmentLayer;
        expect(layer.content.targetTileLayerId, 'tiles_main');
        expect(layer.content.areas.length, 1);
        expect(layer.content.areas.single.id, 'z1');
        expect(out.placedElements, map.placedElements);
      });

      test('target null remet targetTileLayerId à null', () {
        final env = MapLayer.environment(
          id: 'env',
          name: 'E',
          content: EnvironmentLayerContent(targetTileLayerId: 't1'),
        );
        final tile = TileLayer(
          id: 't1',
          name: 'T',
          tiles: const <int>[0, 0],
        );
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 2),
          layers: [env, tile],
        );
        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
        final out = uc.execute(
          map,
          environmentLayerId: 'env',
          targetTileLayerId: null,
        );
        final layer = out.layers.first as EnvironmentLayer;
        expect(layer.content.targetTileLayerId, isNull);
      });

      test('rejette cible ObjectLayer', () {
        final env = MapLayer.environment(id: 'env', name: 'E');
        final obj = MapLayer.object(id: 'obj', name: 'O');
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 1),
          layers: [env, obj],
        );
        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
        expect(
          () => uc.execute(
            map,
            environmentLayerId: 'env',
            targetTileLayerId: 'obj',
          ),
          throwsA(isA<EditorValidationException>()),
        );
      });

      test('rejette environmentLayerId TileLayer', () {
        final tile = TileLayer(
          id: 't1',
          name: 'T',
          tiles: const <int>[0],
        );
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 1),
          layers: [tile],
        );
        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
        expect(
          () => uc.execute(
            map,
            environmentLayerId: 't1',
            targetTileLayerId: 't1',
          ),
          throwsA(isA<EditorValidationException>()),
        );
      });

      test('rejette id inconnu pour environmentLayerId', () {
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 1),
          layers: [
            MapLayer.environment(id: 'env', name: 'E'),
            TileLayer(id: 't1', name: 'T', tiles: const <int>[0]),
          ],
        );
        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
        expect(
          () => uc.execute(
            map,
            environmentLayerId: 'missing',
            targetTileLayerId: 't1',
          ),
          throwsA(isA<EditorValidationException>()),
        );
      });

      test('rejette auto-cible', () {
        final env = MapLayer.environment(id: 'env', name: 'E');
        final tile = TileLayer(
          id: 't1',
          name: 'T',
          tiles: const <int>[0],
        );
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 1),
          layers: [env, tile],
        );
        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
        expect(
          () => uc.execute(
            map,
            environmentLayerId: 'env',
            targetTileLayerId: 'env',
          ),
          throwsA(isA<EditorValidationException>()),
        );
      });
    });

    group('EditorNotifier.setEnvironmentLayerTargetTileLayer', () {
      test(
          'met à jour activeMap, garde activeLayerId, isDirty, chemins stables',
          () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final env = MapLayer.environment(id: 'env', name: 'E');
        final tile = TileLayer(
          id: 't1',
          name: 'Sol',
          tiles: const <int>[0, 0, 0, 0],
        );
        const root = '/tmp/lot20';
        const mapPath = 'maps/x.json';
        final map = MapData(
          id: 'm1',
          name: 'M1',
          size: const GridSize(width: 2, height: 2),
          layers: [env, tile],
        );
        container.read(editorNotifierProvider.notifier).state = EditorState(
          projectRootPath: root,
          project: buildShellChromeProject(),
          activeMap: map,
          activeMapPath: mapPath,
          activeLayerId: 'env',
          savedMapSnapshot: map,
        );
        final notifier = container.read(editorNotifierProvider.notifier);
        notifier.setEnvironmentLayerTargetTileLayer(
          environmentLayerId: 'env',
          targetTileLayerId: 't1',
        );
        final state = container.read(editorNotifierProvider);
        expect(state.activeLayerId, 'env');
        expect(state.isDirty, isTrue);
        expect(state.projectRootPath, root);
        expect(state.activeMapPath, mapPath);
        final el = state.activeMap!.layers.first as EnvironmentLayer;
        expect(el.content.targetTileLayerId, 't1');
      });
    });

    testWidgets('inspecteur : aucun TileLayer', (tester) async {
      final env = MapLayer.environment(id: 'env', name: 'E');
      final map = MapData(
        id: 'mx',
        name: 'Mx',
        size: const GridSize(width: 2, height: 2),
        layers: [env],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: env.id,
      );
      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 400,
                  height: 900,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('env-layer-inspector-no-tile-layers')),
          findsOneWidget);
    });

    testWidgets('inspecteur : TileLayer présents, pas de cible',
        (tester) async {
      final env = MapLayer.environment(id: 'env', name: 'E');
      final tile = TileLayer(
        id: 'tdecor',
        name: 'Décor',
        tiles: const <int>[0, 0, 0, 0],
      );
      final map = MapData(
        id: 'mx',
        name: 'Mx',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: env.id,
      );
      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 400,
                  height: 900,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('env-layer-inspector-no-target')),
          findsOneWidget);
      expect(find.byKey(const Key('env-layer-inspector-choose-target')),
          findsOneWidget);
    });

    testWidgets('choix TileLayer via picker met à jour la cible et dirty',
        (tester) async {
      final env = MapLayer.environment(id: 'env', name: 'E');
      final tile = TileLayer(
        id: 'tuniq',
        name: 'Tuiles sol',
        tiles: const <int>[0, 0, 0, 0],
      );
      final map = MapData(
        id: 'mx',
        name: 'Mx',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: env.id,
        savedMapSnapshot: map,
      );
      await tester.binding.setSurfaceSize(const Size(520, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 420,
                  height: 1000,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('env-layer-inspector-choose-target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tuiles sol').last);
      await tester.pumpAndSettle();
      final state = container.read(editorNotifierProvider);
      expect(
        (state.activeMap!.layers.first as EnvironmentLayer)
            .content
            .targetTileLayerId,
        'tuniq',
      );
      expect(state.isDirty, isTrue);
      expect(find.byKey(const Key('env-layer-inspector-current-target-name')),
          findsOneWidget);
      expect(find.textContaining('Cible actuelle :'), findsWidgets);
    });

    testWidgets('picker ne liste que les TileLayer (ObjectLayer exclu)',
        (tester) async {
      final env = MapLayer.environment(id: 'env', name: 'E');
      final tile = TileLayer(
        id: 'only_tile',
        name: 'Couche tuiles',
        tiles: const <int>[0, 0, 0, 0],
      );
      final obj = MapLayer.object(id: 'obj', name: 'Objets');
      final map = MapData(
        id: 'mx',
        name: 'Mx',
        size: const GridSize(width: 2, height: 2),
        layers: [env, obj, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: env.id,
      );
      await tester.binding.setSurfaceSize(const Size(520, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 420,
                  height: 1000,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('env-layer-inspector-choose-target')));
      await tester.pumpAndSettle();
      final sheetFinder = find.byType(MacosSheet).last;
      expect(
        find.descendant(of: sheetFinder, matching: find.text('Objets')),
        findsNothing,
      );
      expect(
        find.descendant(of: sheetFinder, matching: find.text('Couche tuiles')),
        findsOneWidget,
      );
      await tester.tap(find.descendant(
        of: sheetFinder,
        matching: find.text('Couche tuiles'),
      ));
      await tester.pumpAndSettle();
      expect(
        (container.read(editorNotifierProvider).activeMap!.layers.first
                as EnvironmentLayer)
            .content
            .targetTileLayerId,
        'only_tile',
      );
    });

    testWidgets('retirer la cible remet null', (tester) async {
      final tile = TileLayer(
        id: 't1',
        name: 'T',
        tiles: const <int>[0, 0, 0, 0],
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(targetTileLayerId: 't1'),
      );
      final map = MapData(
        id: 'mx',
        name: 'Mx',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: env.id,
        savedMapSnapshot: map,
      );
      await tester.binding.setSurfaceSize(const Size(520, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 420,
                  height: 1000,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('env-layer-inspector-remove-target')));
      await tester.pumpAndSettle();
      final state = container.read(editorNotifierProvider);
      expect(
        (state.activeMap!.layers.first as EnvironmentLayer)
            .content
            .targetTileLayerId,
        isNull,
      );
      expect(find.byKey(const Key('env-layer-inspector-no-target')),
          findsOneWidget);
    });

    testWidgets('cible invalide affiche avertissement et actions',
        (tester) async {
      final tile = TileLayer(
        id: 't1',
        name: 'T',
        tiles: const <int>[0, 0, 0, 0],
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(targetTileLayerId: 'missing_layer'),
      );
      final map = MapData(
        id: 'mx',
        name: 'Mx',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: env.id,
      );
      await tester.binding.setSurfaceSize(const Size(520, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 420,
                  height: 1000,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('env-layer-inspector-invalid-target')),
          findsOneWidget);
      expect(find.textContaining('missing_layer'), findsOneWidget);
      expect(find.byKey(const Key('env-layer-inspector-remove-invalid')),
          findsOneWidget);
    });

    testWidgets('EnvironmentLayerInspectorPanel seul : pas de crash', (
      tester,
    ) async {
      final envLayer = MapLayer.environment(id: 'e', name: 'E') as EnvironmentLayer;
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 1, height: 1),
        layers: [envLayer],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: EnvironmentLayerInspectorPanel(
                  map: map,
                  layer: envLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('env-layer-inspector-no-tile-layers')),
          findsOneWidget);
    });
  });
}
```

## 17. Diff complet

### Fichiers trackés modifiés

```diff
diff --git a/packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart b/packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
index 043b364c..a935859e 100644
--- a/packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
+++ b/packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
@@ -226,3 +226,94 @@ class SetMapLayerOpacityUseCase {
     return updated;
   }
 }
+
+/// Lot Environment-20 : cible tuile pour un [EnvironmentLayer] (mutation map pure).
+class SetEnvironmentLayerTargetTileLayerUseCase {
+  MapData execute(
+    MapData map, {
+    required String environmentLayerId,
+    required String? targetTileLayerId,
+  }) {
+    final envId = environmentLayerId.trim();
+    if (envId.isEmpty) {
+      throw const EditorValidationException(
+          'Environment layer id cannot be empty');
+    }
+
+    MapLayer? envLayer;
+    for (final layer in map.layers) {
+      if (layer.id == envId) {
+        envLayer = layer;
+        break;
+      }
+    }
+    if (envLayer == null) {
+      throw EditorValidationException('Environment layer not found: $envId');
+    }
+    if (envLayer is! EnvironmentLayer) {
+      throw EditorValidationException(
+          'Layer is not an environment layer: $envId');
+    }
+
+    if (targetTileLayerId == null) {
+      final nextContent = EnvironmentLayerContent(
+        targetTileLayerId: null,
+        areas: envLayer.content.areas,
+      );
+      try {
+        final updated = setEnvironmentLayerContent(
+          map,
+          layerId: envId,
+          content: nextContent,
+        );
+        MapValidator.validate(updated);
+        return updated;
+      } on ValidationException catch (e) {
+        throw EditorValidationException(e.message);
+      }
+    }
+
+    final tid = targetTileLayerId.trim();
+    if (tid.isEmpty) {
+      throw const EditorValidationException(
+          'Target tile layer id cannot be empty');
+    }
+    if (tid == envId) {
+      throw const EditorValidationException(
+        'Environment layer cannot target itself as targetTileLayerId',
+      );
+    }
+
+    MapLayer? targetLayer;
+    for (final layer in map.layers) {
+      if (layer.id == tid) {
+        targetLayer = layer;
+        break;
+      }
+    }
+    if (targetLayer == null) {
+      throw EditorValidationException('Target tile layer not found: $tid');
+    }
+    if (targetLayer is! TileLayer) {
+      throw EditorValidationException(
+        'targetTileLayerId must reference a TileLayer, got ${targetLayer.runtimeType}',
+      );
+    }
+
+    final nextContent = EnvironmentLayerContent(
+      targetTileLayerId: tid,
+      areas: envLayer.content.areas,
+    );
+    try {
+      final updated = setEnvironmentLayerContent(
+        map,
+        layerId: envId,
+        content: nextContent,
+      );
+      MapValidator.validate(updated);
+      return updated;
+    } on ValidationException catch (e) {
+      throw EditorValidationException(e.message);
+    }
+  }
+}
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index 4eef4fce..91457a73 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -13,6 +13,7 @@ import '../../../app/providers/core_providers.dart';
 import '../../../app/providers/editor_workspace_providers.dart';
 import '../../../app/providers/use_case_providers.dart';
 import '../../../application/errors/application_errors.dart';
+import '../../../application/use_cases/layer_use_cases.dart';
 import '../../../application/models/trainer_field_update.dart';
 import '../../../application/models/map_tool_preview.dart';
 import '../../../application/models/path_autotile_set.dart';
@@ -4645,6 +4646,35 @@ class EditorNotifier extends _$EditorNotifier {
     }
   }
 
+  /// Lot Environment-20 : [EnvironmentLayerContent.targetTileLayerId] uniquement.
+  void setEnvironmentLayerTargetTileLayer({
+    required String environmentLayerId,
+    required String? targetTileLayerId,
+  }) {
+    final map = state.activeMap;
+    if (map == null) return;
+    try {
+      final useCase = SetEnvironmentLayerTargetTileLayerUseCase();
+      final updated = useCase.execute(
+        map,
+        environmentLayerId: environmentLayerId,
+        targetTileLayerId: targetTileLayerId,
+      );
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: updated,
+        preferredActiveLayerId: environmentLayerId,
+        statusMessage: targetTileLayerId == null
+            ? 'Environment layer target tile layer cleared'
+            : 'Environment layer target tile layer updated',
+      );
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Failed to set environment target tile layer: $e',
+      );
+    }
+  }
+
   void renameMapLayer(String layerId, String name) {
     final map = state.activeMap;
     if (map == null) return;
diff --git a/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart b/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
index b9d1bc5d..14e6a459 100644
--- a/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
@@ -13,6 +13,7 @@ import 'encounter_tables_panel.dart';
 import 'entity_properties_panel.dart';
 import 'event_properties_panel.dart';
 import 'gameplay_zone_properties_panel.dart';
+import 'environment_layer_inspector_panel.dart';
 import 'layers_panel.dart';
 import 'map_connections_panel.dart';
 import 'map_properties_panel.dart';
@@ -178,8 +179,12 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
                     _InspectorSectionId.environmentLayer,
                     defaultExpanded: true,
                   ),
-                  expandedHeight: 200,
-                  child: const _EnvironmentLayerInspectorPlaceholder(),
+                  expandedHeight: 360,
+                  child: EnvironmentLayerInspectorPanel(
+                    map: activeMap,
+                    layer: activeLayer,
+                    embedded: true,
+                  ),
                 ),
               if (showTilesSection)
                 InspectorSectionCard(
@@ -456,47 +461,6 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
   }
 }
 
-/// Lot Environment-19 : pas de contrôles métier tant que zones / cible tuiles absents.
-class _EnvironmentLayerInspectorPlaceholder extends StatelessWidget {
-  const _EnvironmentLayerInspectorPlaceholder();
-
-  @override
-  Widget build(BuildContext context) {
-    final subtle = EditorChrome.subtleLabel(context);
-    final label = EditorChrome.primaryLabel(context);
-    return Padding(
-      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.stretch,
-        children: [
-          Text(
-            'Environment Layer',
-            key: const Key('map-inspector-environment-layer-title'),
-            style: TextStyle(
-              color: label,
-              fontSize: 14,
-              fontWeight: FontWeight.w800,
-            ),
-          ),
-          const SizedBox(height: 8),
-          Text(
-            'Ce layer servira à dessiner des zones organiques et à générer des '
-            'éléments naturels.\n'
-            'La configuration des zones arrive dans un prochain lot.',
-            key: const Key('map-inspector-environment-layer-body'),
-            style: TextStyle(
-              color: subtle,
-              fontSize: 12,
-              height: 1.4,
-              fontWeight: FontWeight.w600,
-            ),
-          ),
-        ],
-      ),
-    );
-  }
-}
-
 class _InspectorOverviewCard extends StatelessWidget {
   const _InspectorOverviewCard({
     required this.map,
```

### Nouveaux fichiers (`git diff --no-index /dev/null …`)

```diff
diff --git a/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart b/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
new file mode 100644
index 00000000..ef566811
--- /dev/null
+++ b/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
@@ -0,0 +1,210 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../features/editor/state/editor_notifier.dart';
+import '../shared/cupertino_editor_widgets.dart';
+
+/// Inspecteur Lot Environment-19/20 : meta layer + cible [TileLayer] pour génération future.
+class EnvironmentLayerInspectorPanel extends ConsumerWidget {
+  const EnvironmentLayerInspectorPanel({
+    super.key,
+    required this.map,
+    required this.layer,
+    this.embedded = false,
+  });
+
+  final MapData map;
+  final EnvironmentLayer layer;
+  final bool embedded;
+
+  List<TileLayer> _tileLayers() {
+    final out = <TileLayer>[];
+    for (final l in map.layers) {
+      if (l is TileLayer) {
+        out.add(l);
+      }
+    }
+    return out;
+  }
+
+  TileLayer? _resolveTarget() {
+    final tid = layer.content.targetTileLayerId;
+    if (tid == null) return null;
+    for (final l in map.layers) {
+      if (l.id == tid && l is TileLayer) {
+        return l;
+      }
+    }
+    return null;
+  }
+
+  @override
+  Widget build(BuildContext context, WidgetRef ref) {
+    final subtle = EditorChrome.subtleLabel(context);
+    final label = EditorChrome.primaryLabel(context);
+    final notifier = ref.read(editorNotifierProvider.notifier);
+    final tiles = _tileLayers();
+    final target = _resolveTarget();
+    final tid = layer.content.targetTileLayerId;
+    final invalidTarget = tid != null && target == null;
+
+    return Padding(
+      padding: EdgeInsets.fromLTRB(embedded ? 8 : 10, 4, embedded ? 8 : 10, 10),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            'Environment Layer',
+            key: const Key('map-inspector-environment-layer-title'),
+            style: TextStyle(
+              color: label,
+              fontSize: 14,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 8),
+          Text(
+            'Ce layer servira à dessiner des zones organiques et à générer des '
+            'éléments naturels.\n'
+            'La configuration des zones arrive dans un prochain lot.',
+            key: const Key('map-inspector-environment-layer-body'),
+            style: TextStyle(
+              color: subtle,
+              fontSize: 12,
+              height: 1.4,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+          const SizedBox(height: 14),
+          Text(
+            'TileLayer cible',
+            style: TextStyle(
+              color: label,
+              fontSize: 13,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 8),
+          if (tiles.isEmpty) ...[
+            Text(
+              'Aucun TileLayer disponible dans cette map.\n'
+              'Ajoutez d’abord un TileLayer pour recevoir les résultats générés.',
+              key: const Key('env-layer-inspector-no-tile-layers'),
+              style: TextStyle(
+                color: subtle,
+                fontSize: 12,
+                height: 1.35,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ] else if (invalidTarget) ...[
+            Text(
+              'La cible configurée est introuvable ou invalide : $tid',
+              key: const Key('env-layer-inspector-invalid-target'),
+              style: TextStyle(
+                color: CupertinoColors.systemOrange.resolveFrom(context),
+                fontSize: 12,
+                height: 1.35,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+            const SizedBox(height: 10),
+            PushButton(
+              key: const Key('env-layer-inspector-change-invalid'),
+              controlSize: ControlSize.regular,
+              onPressed: () => _pickTileLayer(context, notifier, tiles),
+              child: const Text('Choisir un autre TileLayer cible'),
+            ),
+            const SizedBox(height: 8),
+            PushButton(
+              key: const Key('env-layer-inspector-remove-invalid'),
+              controlSize: ControlSize.regular,
+              secondary: true,
+              onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
+                environmentLayerId: layer.id,
+                targetTileLayerId: null,
+              ),
+              child: const Text('Retirer la cible'),
+            ),
+          ] else if (target == null) ...[
+            Text(
+              'Aucun TileLayer cible sélectionné.',
+              key: const Key('env-layer-inspector-no-target'),
+              style: TextStyle(
+                color: subtle,
+                fontSize: 12,
+                height: 1.35,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+            const SizedBox(height: 10),
+            PushButton(
+              key: const Key('env-layer-inspector-choose-target'),
+              controlSize: ControlSize.regular,
+              onPressed: () => _pickTileLayer(context, notifier, tiles),
+              child: const Text('Choisir le TileLayer cible'),
+            ),
+          ] else ...[
+            Text(
+              'Cible actuelle : ${target.name}',
+              key: const Key('env-layer-inspector-current-target-name'),
+              style: TextStyle(
+                color: label,
+                fontSize: 12,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            const SizedBox(height: 4),
+            Text(
+              'Id : ${target.id}',
+              key: const Key('env-layer-inspector-current-target-id'),
+              style: TextStyle(
+                color: subtle,
+                fontSize: 11.5,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+            const SizedBox(height: 10),
+            PushButton(
+              key: const Key('env-layer-inspector-change-target'),
+              controlSize: ControlSize.regular,
+              onPressed: () => _pickTileLayer(context, notifier, tiles),
+              child: const Text('Changer de TileLayer cible'),
+            ),
+            const SizedBox(height: 8),
+            PushButton(
+              key: const Key('env-layer-inspector-remove-target'),
+              controlSize: ControlSize.regular,
+              secondary: true,
+              onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
+                environmentLayerId: layer.id,
+                targetTileLayerId: null,
+              ),
+              child: const Text('Retirer la cible'),
+            ),
+          ],
+        ],
+      ),
+    );
+  }
+
+  Future<void> _pickTileLayer(
+    BuildContext context,
+    EditorNotifier notifier,
+    List<TileLayer> tiles,
+  ) async {
+    final picked = await showCupertinoListPicker<TileLayer>(
+      context: context,
+      title: 'TileLayer cible',
+      items: tiles,
+      labelOf: (t) => t.name,
+    );
+    if (picked == null) return;
+    notifier.setEnvironmentLayerTargetTileLayer(
+      environmentLayerId: layer.id,
+      targetTileLayerId: picked.id,
+    );
+  }
+}
diff --git a/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart b/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart
new file mode 100644
index 00000000..42dd2402
--- /dev/null
+++ b/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart
@@ -0,0 +1,595 @@
+// ignore_for_file: prefer_const_constructors — fixtures MapData / MaterialApp non const pour lisibilité Lot 20
+
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/application/errors/application_errors.dart';
+import 'package:map_editor/src/application/use_cases/layer_use_cases.dart';
+import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
+import 'package:map_editor/src/features/editor/state/editor_state.dart';
+import 'package:map_editor/src/ui/panels/environment_layer_inspector_panel.dart';
+import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';
+
+import '../shell_chrome_test_harness.dart';
+
+void main() {
+  group('Lot 20 — EnvironmentLayer target TileLayer', () {
+    group('SetEnvironmentLayerTargetTileLayerUseCase', () {
+      test('définit targetTileLayerId et préserve areas', () {
+        final mask = EnvironmentAreaMask(
+          width: 2,
+          height: 2,
+          cells: <bool>[false, false, false, false],
+        );
+        final area = EnvironmentArea(
+          id: 'z1',
+          name: 'Z',
+          presetId: 'p1',
+          mask: mask,
+          seed: 0,
+        );
+        final env = MapLayer.environment(
+          id: 'env',
+          name: 'E',
+          content: EnvironmentLayerContent(
+            targetTileLayerId: null,
+            areas: [area],
+          ),
+        );
+        final tile = TileLayer(
+          id: 'tiles_main',
+          name: 'Sol',
+          tiles: const <int>[0, 0, 0, 0],
+        );
+        final map = MapData(
+          id: 'm',
+          name: 'M',
+          size: const GridSize(width: 2, height: 2),
+          layers: [env, tile],
+        );
+        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
+        final out = uc.execute(
+          map,
+          environmentLayerId: 'env',
+          targetTileLayerId: 'tiles_main',
+        );
+        final layer = out.layers.first as EnvironmentLayer;
+        expect(layer.content.targetTileLayerId, 'tiles_main');
+        expect(layer.content.areas.length, 1);
+        expect(layer.content.areas.single.id, 'z1');
+        expect(out.placedElements, map.placedElements);
+      });
+
+      test('target null remet targetTileLayerId à null', () {
+        final env = MapLayer.environment(
+          id: 'env',
+          name: 'E',
+          content: EnvironmentLayerContent(targetTileLayerId: 't1'),
+        );
+        final tile = TileLayer(
+          id: 't1',
+          name: 'T',
+          tiles: const <int>[0, 0],
+        );
+        final map = MapData(
+          id: 'm',
+          name: 'M',
+          size: const GridSize(width: 1, height: 2),
+          layers: [env, tile],
+        );
+        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
+        final out = uc.execute(
+          map,
+          environmentLayerId: 'env',
+          targetTileLayerId: null,
+        );
+        final layer = out.layers.first as EnvironmentLayer;
+        expect(layer.content.targetTileLayerId, isNull);
+      });
+
+      test('rejette cible ObjectLayer', () {
+        final env = MapLayer.environment(id: 'env', name: 'E');
+        final obj = MapLayer.object(id: 'obj', name: 'O');
+        final map = MapData(
+          id: 'm',
+          name: 'M',
+          size: const GridSize(width: 1, height: 1),
+          layers: [env, obj],
+        );
+        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
+        expect(
+          () => uc.execute(
+            map,
+            environmentLayerId: 'env',
+            targetTileLayerId: 'obj',
+          ),
+          throwsA(isA<EditorValidationException>()),
+        );
+      });
+
+      test('rejette environmentLayerId TileLayer', () {
+        final tile = TileLayer(
+          id: 't1',
+          name: 'T',
+          tiles: const <int>[0],
+        );
+        final map = MapData(
+          id: 'm',
+          name: 'M',
+          size: const GridSize(width: 1, height: 1),
+          layers: [tile],
+        );
+        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
+        expect(
+          () => uc.execute(
+            map,
+            environmentLayerId: 't1',
+            targetTileLayerId: 't1',
+          ),
+          throwsA(isA<EditorValidationException>()),
+        );
+      });
+
+      test('rejette id inconnu pour environmentLayerId', () {
+        final map = MapData(
+          id: 'm',
+          name: 'M',
+          size: const GridSize(width: 1, height: 1),
+          layers: [
+            MapLayer.environment(id: 'env', name: 'E'),
+            TileLayer(id: 't1', name: 'T', tiles: const <int>[0]),
+          ],
+        );
+        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
+        expect(
+          () => uc.execute(
+            map,
+            environmentLayerId: 'missing',
+            targetTileLayerId: 't1',
+          ),
+          throwsA(isA<EditorValidationException>()),
+        );
+      });
+
+      test('rejette auto-cible', () {
+        final env = MapLayer.environment(id: 'env', name: 'E');
+        final tile = TileLayer(
+          id: 't1',
+          name: 'T',
+          tiles: const <int>[0],
+        );
+        final map = MapData(
+          id: 'm',
+          name: 'M',
+          size: const GridSize(width: 1, height: 1),
+          layers: [env, tile],
+        );
+        final uc = SetEnvironmentLayerTargetTileLayerUseCase();
+        expect(
+          () => uc.execute(
+            map,
+            environmentLayerId: 'env',
+            targetTileLayerId: 'env',
+          ),
+          throwsA(isA<EditorValidationException>()),
+        );
+      });
+    });
+
+    group('EditorNotifier.setEnvironmentLayerTargetTileLayer', () {
+      test(
+          'met à jour activeMap, garde activeLayerId, isDirty, chemins stables',
+          () {
+        final container = ProviderContainer();
+        addTearDown(container.dispose);
+        final env = MapLayer.environment(id: 'env', name: 'E');
+        final tile = TileLayer(
+          id: 't1',
+          name: 'Sol',
+          tiles: const <int>[0, 0, 0, 0],
+        );
+        const root = '/tmp/lot20';
+        const mapPath = 'maps/x.json';
+        final map = MapData(
+          id: 'm1',
+          name: 'M1',
+          size: const GridSize(width: 2, height: 2),
+          layers: [env, tile],
+        );
+        container.read(editorNotifierProvider.notifier).state = EditorState(
+          projectRootPath: root,
+          project: buildShellChromeProject(),
+          activeMap: map,
+          activeMapPath: mapPath,
+          activeLayerId: 'env',
+          savedMapSnapshot: map,
+        );
+        final notifier = container.read(editorNotifierProvider.notifier);
+        notifier.setEnvironmentLayerTargetTileLayer(
+          environmentLayerId: 'env',
+          targetTileLayerId: 't1',
+        );
+        final state = container.read(editorNotifierProvider);
+        expect(state.activeLayerId, 'env');
+        expect(state.isDirty, isTrue);
+        expect(state.projectRootPath, root);
+        expect(state.activeMapPath, mapPath);
+        final el = state.activeMap!.layers.first as EnvironmentLayer;
+        expect(el.content.targetTileLayerId, 't1');
+      });
+    });
+
+    testWidgets('inspecteur : aucun TileLayer', (tester) async {
+      final env = MapLayer.environment(id: 'env', name: 'E');
+      final map = MapData(
+        id: 'mx',
+        name: 'Mx',
+        size: const GridSize(width: 2, height: 2),
+        layers: [env],
+      );
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/tmp',
+        project: buildShellChromeProject(),
+        activeMap: map,
+        activeMapPath: 'maps/x.json',
+        activeLayerId: env.id,
+      );
+      await tester.binding.setSurfaceSize(const Size(480, 900));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: MaterialApp(
+              home: CupertinoPageScaffold(
+                child: SizedBox(
+                  width: 400,
+                  height: 900,
+                  child: MapInspectorPanel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+      expect(find.byKey(const Key('env-layer-inspector-no-tile-layers')),
+          findsOneWidget);
+    });
+
+    testWidgets('inspecteur : TileLayer présents, pas de cible',
+        (tester) async {
+      final env = MapLayer.environment(id: 'env', name: 'E');
+      final tile = TileLayer(
+        id: 'tdecor',
+        name: 'Décor',
+        tiles: const <int>[0, 0, 0, 0],
+      );
+      final map = MapData(
+        id: 'mx',
+        name: 'Mx',
+        size: const GridSize(width: 2, height: 2),
+        layers: [env, tile],
+      );
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/tmp',
+        project: buildShellChromeProject(),
+        activeMap: map,
+        activeMapPath: 'maps/x.json',
+        activeLayerId: env.id,
+      );
+      await tester.binding.setSurfaceSize(const Size(480, 900));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: MaterialApp(
+              home: CupertinoPageScaffold(
+                child: SizedBox(
+                  width: 400,
+                  height: 900,
+                  child: MapInspectorPanel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+      expect(find.byKey(const Key('env-layer-inspector-no-target')),
+          findsOneWidget);
+      expect(find.byKey(const Key('env-layer-inspector-choose-target')),
+          findsOneWidget);
+    });
+
+    testWidgets('choix TileLayer via picker met à jour la cible et dirty',
+        (tester) async {
+      final env = MapLayer.environment(id: 'env', name: 'E');
+      final tile = TileLayer(
+        id: 'tuniq',
+        name: 'Tuiles sol',
+        tiles: const <int>[0, 0, 0, 0],
+      );
+      final map = MapData(
+        id: 'mx',
+        name: 'Mx',
+        size: const GridSize(width: 2, height: 2),
+        layers: [env, tile],
+      );
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/tmp',
+        project: buildShellChromeProject(),
+        activeMap: map,
+        activeMapPath: 'maps/x.json',
+        activeLayerId: env.id,
+        savedMapSnapshot: map,
+      );
+      await tester.binding.setSurfaceSize(const Size(520, 1000));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: MaterialApp(
+              home: CupertinoPageScaffold(
+                child: SizedBox(
+                  width: 420,
+                  height: 1000,
+                  child: MapInspectorPanel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+      await tester
+          .tap(find.byKey(const Key('env-layer-inspector-choose-target')));
+      await tester.pumpAndSettle();
+      await tester.tap(find.text('Tuiles sol').last);
+      await tester.pumpAndSettle();
+      final state = container.read(editorNotifierProvider);
+      expect(
+        (state.activeMap!.layers.first as EnvironmentLayer)
+            .content
+            .targetTileLayerId,
+        'tuniq',
+      );
+      expect(state.isDirty, isTrue);
+      expect(find.byKey(const Key('env-layer-inspector-current-target-name')),
+          findsOneWidget);
+      expect(find.textContaining('Cible actuelle :'), findsWidgets);
+    });
+
+    testWidgets('picker ne liste que les TileLayer (ObjectLayer exclu)',
+        (tester) async {
+      final env = MapLayer.environment(id: 'env', name: 'E');
+      final tile = TileLayer(
+        id: 'only_tile',
+        name: 'Couche tuiles',
+        tiles: const <int>[0, 0, 0, 0],
+      );
+      final obj = MapLayer.object(id: 'obj', name: 'Objets');
+      final map = MapData(
+        id: 'mx',
+        name: 'Mx',
+        size: const GridSize(width: 2, height: 2),
+        layers: [env, obj, tile],
+      );
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/tmp',
+        project: buildShellChromeProject(),
+        activeMap: map,
+        activeMapPath: 'maps/x.json',
+        activeLayerId: env.id,
+      );
+      await tester.binding.setSurfaceSize(const Size(520, 1000));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: MaterialApp(
+              home: CupertinoPageScaffold(
+                child: SizedBox(
+                  width: 420,
+                  height: 1000,
+                  child: MapInspectorPanel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+      await tester
+          .tap(find.byKey(const Key('env-layer-inspector-choose-target')));
+      await tester.pumpAndSettle();
+      final sheetFinder = find.byType(MacosSheet).last;
+      expect(
+        find.descendant(of: sheetFinder, matching: find.text('Objets')),
+        findsNothing,
+      );
+      expect(
+        find.descendant(of: sheetFinder, matching: find.text('Couche tuiles')),
+        findsOneWidget,
+      );
+      await tester.tap(find.descendant(
+        of: sheetFinder,
+        matching: find.text('Couche tuiles'),
+      ));
+      await tester.pumpAndSettle();
+      expect(
+        (container.read(editorNotifierProvider).activeMap!.layers.first
+                as EnvironmentLayer)
+            .content
+            .targetTileLayerId,
+        'only_tile',
+      );
+    });
+
+    testWidgets('retirer la cible remet null', (tester) async {
+      final tile = TileLayer(
+        id: 't1',
+        name: 'T',
+        tiles: const <int>[0, 0, 0, 0],
+      );
+      final env = MapLayer.environment(
+        id: 'env',
+        name: 'E',
+        content: EnvironmentLayerContent(targetTileLayerId: 't1'),
+      );
+      final map = MapData(
+        id: 'mx',
+        name: 'Mx',
+        size: const GridSize(width: 2, height: 2),
+        layers: [env, tile],
+      );
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/tmp',
+        project: buildShellChromeProject(),
+        activeMap: map,
+        activeMapPath: 'maps/x.json',
+        activeLayerId: env.id,
+        savedMapSnapshot: map,
+      );
+      await tester.binding.setSurfaceSize(const Size(520, 1000));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: MaterialApp(
+              home: CupertinoPageScaffold(
+                child: SizedBox(
+                  width: 420,
+                  height: 1000,
+                  child: MapInspectorPanel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+      await tester
+          .tap(find.byKey(const Key('env-layer-inspector-remove-target')));
+      await tester.pumpAndSettle();
+      final state = container.read(editorNotifierProvider);
+      expect(
+        (state.activeMap!.layers.first as EnvironmentLayer)
+            .content
+            .targetTileLayerId,
+        isNull,
+      );
+      expect(find.byKey(const Key('env-layer-inspector-no-target')),
+          findsOneWidget);
+    });
+
+    testWidgets('cible invalide affiche avertissement et actions',
+        (tester) async {
+      final tile = TileLayer(
+        id: 't1',
+        name: 'T',
+        tiles: const <int>[0, 0, 0, 0],
+      );
+      final env = MapLayer.environment(
+        id: 'env',
+        name: 'E',
+        content: EnvironmentLayerContent(targetTileLayerId: 'missing_layer'),
+      );
+      final map = MapData(
+        id: 'mx',
+        name: 'Mx',
+        size: const GridSize(width: 2, height: 2),
+        layers: [env, tile],
+      );
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/tmp',
+        project: buildShellChromeProject(),
+        activeMap: map,
+        activeMapPath: 'maps/x.json',
+        activeLayerId: env.id,
+      );
+      await tester.binding.setSurfaceSize(const Size(520, 1000));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: MaterialApp(
+              home: CupertinoPageScaffold(
+                child: SizedBox(
+                  width: 420,
+                  height: 1000,
+                  child: MapInspectorPanel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+      expect(find.byKey(const Key('env-layer-inspector-invalid-target')),
+          findsOneWidget);
+      expect(find.textContaining('missing_layer'), findsOneWidget);
+      expect(find.byKey(const Key('env-layer-inspector-remove-invalid')),
+          findsOneWidget);
+    });
+
+    testWidgets('EnvironmentLayerInspectorPanel seul : pas de crash', (
+      tester,
+    ) async {
+      final envLayer = MapLayer.environment(id: 'e', name: 'E') as EnvironmentLayer;
+      final map = MapData(
+        id: 'm',
+        name: 'M',
+        size: const GridSize(width: 1, height: 1),
+        layers: [envLayer],
+      );
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: MaterialApp(
+              home: CupertinoPageScaffold(
+                child: EnvironmentLayerInspectorPanel(
+                  map: map,
+                  layer: envLayer,
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+      expect(find.byKey(const Key('env-layer-inspector-no-tile-layers')),
+          findsOneWidget);
+    });
+  });
+}
```

## 18. Auto-review

- **Points solides** : réutilisation de **`setEnvironmentLayerContent`** ; validation **`MapValidator`** alignée sur map_core ; UI couvrant cible invalide sans auto-clear ; tests picker bornés au **`MacosSheet`** pour l’exclusion des non-TileLayer.
- **Points discutables** : use case instancié **inline** dans le notifier (pas de nouveau `@riverpod`) pour respecter l’interdiction **`build_runner`** sur ce lot — cohérent avec la contrainte, moins homogène que les providers existants.
- **Corrections après auto-review** : `ignore_for_file: prefer_const_constructors` sur le fichier de test ; assertions picker ajustées (libellés dupliqués section / feuille) ; exclusion des entrées « Objets » par ancêtre **`MacosSheet`**.
- **Risques restants** : carte avec cible invalide issue de données externes reste invalide jusqu’à action utilisateur (comportement voulu).
- **Regard critique (prompt)** : configurer **`targetTileLayerId`** avant les areas est logique (cible de rendu avant masques). Restreindre aux TileLayer est adapté au pipeline « patch tuiles ». Cible invalide via API use case : refusée ; via données corrompues : affichage d’avertissement sans auto-suppression. L’inspecteur gagne une sous-section mais reste dans une carte repliée existante. Aucune area / mask / preset / génération ajoutée.

## 19. Verdict

Statut du lot :

- [x] Validé

Résumé :

```
Lot 20 livré : SetEnvironmentLayerTargetTileLayerUseCase + EditorNotifier.setEnvironmentLayerTargetTileLayer + EnvironmentLayerInspectorPanel ; tests ciblés et dossier test/environment_studio verts ; flutter analyze ciblé sans issue. flutter test complet map_editor : +958 -34 (dettes hors lot).
```

Prochain lot recommandé :

```
Environment-21 — Environment Area Model Editing in Inspector V0
```

### Evidence Pack (confirmations explicites)

- Aucun fichier modèle **`ProjectManifest`** sous `examples/` ou ailleurs modifié par ce lot.
- Aucun fichier sous **`packages/map_core`** modifié (y compris `map_layer.dart`, `environment.dart`, `map_layers.dart`).
- Aucune **`EnvironmentArea`** créée ni modifiée par ce lot (le use case ne fait que recopier la liste **`areas`** existante dans le nouveau **`EnvironmentLayerContent`**).
- Aucun **`EnvironmentAreaMask`** créé.
- Aucun preset **`environmentPresets`** du manifest modifié.
- Aucun **`MapPlacedElement`** créé ; **`placedElements`** inchangés dans les tests du use case.
- Aucune génération / bouton Generate ajouté.
- Aucune sauvegarde disque dans ce flux ; le grep §14 montre uniquement des définitions hors chemin `setEnvironmentLayerTargetTileLayer` dans **`editor_notifier`** ; aucun hit dans les panneaux ni **`layer_use_cases`**.
- Aucun **`SurfaceLayer`** legacy utilisé pour la cible.
- Aucun **`build_runner`** lancé ; aucun fichier généré modifié.
- Aucun **`git commit`**, **`git add`**, **`git push`**, **`git checkout`**, **`git restore`**, **`git stash`**, merge, rebase ou tag exécuté par l’agent.
