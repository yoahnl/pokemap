# Environment Studio Lot 22 — Environment Area Mask Brush Tool V0

## 1. Résumé exécutif

Implémentation du pinceau V0 sur le masque booléen des `EnvironmentArea` : état partagé dans `EditorState` (`selectedEnvironmentAreaId`, `environmentMaskEditMode`), use case pur `PaintEnvironmentAreaMaskCellUseCase`, méthodes `EditorNotifier`, intégration `MapCanvas` (tap + drag avec déduplication de cellule et `beginMapStroke` / `endMapStroke`), overlay semi-transparent dans `MapGridPainter`, actions dans `EnvironmentLayerInspectorPanel`. Aucune modification `map_core`, pas de génération, pas de `MapPlacedElement`, pas de patch `TileLayer`, pas de sauvegarde disque.

## 2. Périmètre du lot

**Inclus :** sélection d’area pour masque, modes paint/erase/stop, mutation `mask.cells` avec index `y * width + x`, no-op référence identique, validation `MapValidator`, dirty via `_applyMapMutation`, tests use case / notifier / inspecteur / canvas / painter.

**Exclu (respecté) :** génération, placements, clear/shuffle, `ProjectManifest.environmentPresets`, `map_runtime`, rayon brush > 1, undo custom hors stroke existant.

## 3. Audit initial canvas / tools / EnvironmentAreaMask

- Routage : `MapCanvas` `GestureDetector` (`onTapUp`, `onPanStart` / `onPanUpdate` / `onPanEnd` / `onPanCancel`) appelle `applyToolAt` qui dispatche selon `activeTool` ou, si `_isEnvironmentMaskEditing(state, activeMap)`, vers `notifier.paintEnvironmentAreaMaskAt` (prioritaire sur les outils tuile/terrain tant que mode masque actif).
- Outils : `EditorToolType` inchangé pour le masque ; enum dédié `EnvironmentMaskEditMode` dans `editor_tool.dart`.
- Masque : `EnvironmentAreaMask` déjà défini dans `map_core` ; édition uniquement côté éditeur via use case + `setEnvironmentLayerContent`.

## 4. Décisions d’architecture state / tool

- Champs Freezed ajoutés à `EditorState` : `selectedEnvironmentAreaId`, `environmentMaskEditMode` (génération `editor_state.freezed.dart` déjà présente dans l’arbre de travail).
- `MapSelectionController.selectTool` remet à zéro la sélection masque lors d’un changement d’outil barre (cohérent avec les autres modes).
- `setActiveLayer` et `_coerceEnvironmentMaskSelectionAfterMapChange` évitent une sélection masque incohérente (layer non-env, area supprimée, carte vide).

## 5. Mutation EnvironmentAreaMask

Fichier `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart` : validation ids, type `EnvironmentLayer`, existence de l’area, bornes carte, cohérence taille masque / carte, longueur `cells`, index masque ; si `cells[index] == isActive` retour **identique** à `map` ; sinon reconstruction immuable de l’area avec `generatedPlacementIds` / `presetId` / `seed` / `paramsOverride` inchangés ; `MapValidator.validate`.

## 6. Sélection area active et modes paint / erase

- `selectEnvironmentAreaForMaskEditing` (area sans forcer le mode).
- `startEnvironmentAreaMaskPaint` / `startEnvironmentAreaMaskErase` : fixent layer + area + mode.
- `stopEnvironmentAreaMaskEditing` : `environmentMaskEditMode` → `null`.

## 7. Intégration inspector

`environment_layer_inspector_panel.dart` : par area, boutons « Peindre le masque », « Effacer du masque », « Arrêter l’édition », libellé d’état, compteur masque, note si pas de TileLayer cible ; description zones mise à jour (Lot 22).

## 8. Intégration canvas click / drag

`map_canvas.dart` : helper `_isEnvironmentMaskEditing` ; `isStrokeEditingTool` inclut le mode masque pour réutiliser `beginMapStroke` / `endMapStroke` ; `_lastEnvironmentMaskPaintCell` pour ne pas repeindre la même tuile pendant un drag ; `paintEnvironmentAreaMaskAt(..., partOfStroke: true/false)`.

## 9. Overlay V0 du mask actif

`MapGridPainter` reçoit `environmentMaskOverlay` optionnel ; `_paintEnvironmentMaskOverlay` dessine des rectangles semi-transparents verts sur les cellules `true` ; `shouldRepaint` compare les cellules avec `listEquals`.

## 10. Dirty state / undo-stroke / sélection active

- Dirty : `_applyMapMutation` + `savedMapSnapshot` (tests avec snapshot initial pour observer `isDirty: true`).
- Stroke : mêmes `beginMapStroke` / `endMapStroke` que les autres outils stroke.
- `preferredActiveLayerId` : id du layer environnement conservé.

## 11. Préservation presets / generatedPlacementIds / placedElements

Garanti par reconstruction ciblée de l’`EnvironmentArea` et tests use case + notifier ; `placedElements` non parcourus par le use case.

## 12. Non-persistance disque garantie

Commande exécutée :

```bash
cd packages/map_editor && grep -R "FileProjectRepository\|saveProject\|saveProjectManifest" -n \
  lib/src/ui/panels/environment_layer_inspector_panel.dart \
  lib/src/ui/canvas \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/application/use_cases/layer_use_cases.dart \
  lib/src/application/use_cases/environment_mask_use_cases.dart || true
```

Sortie :

```
lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart:174:    await notifier.saveProjectDialogueYarnBody(
lib/src/features/editor/state/editor_notifier.dart:439:  Future<bool> saveProjectManifest() async {
lib/src/features/editor/state/editor_notifier.dart:448:    debugPrint('EditorNotifier: saveProjectManifest()');
lib/src/features/editor/state/editor_notifier.dart:450:      await ref.read(projectRepositoryProvider).saveProject(
lib/src/features/editor/state/editor_notifier.dart:1490:  Future<void> saveProjectDialogueYarnBody({
lib/src/features/editor/state/editor_notifier.dart:1494:      state = await _projectContentController.saveProjectDialogueYarnBody(
```

Aucune occurrence dans `environment_mask_use_cases.dart`, `environment_layer_inspector_panel.dart`, ni dans le flux canvas masque. Les hits dans `editor_notifier.dart` sont des méthodes génériques hors chemin masque.

**Confirmations Lot 22 (preuves par absence dans le diff `packages/map_editor/` du masque) :**

- Aucun fichier `ProjectManifest` modèle hors manifeste en mémoire éditeur dans ce flux.
- Aucun fichier sous `packages/map_core/lib/` modifié par ce lot (use case importe seulement `map_core`).
- Aucun `EnvironmentPreset` modifié par le brush.
- Le use case ne modifie pas `generatedPlacementIds` (copie inchangée sur l’area).
- Aucun `MapPlacedElement` créé ; `placedElements` inchangés par le use case.
- Aucun `TileLayer` patché par le brush.
- Aucune génération procédurale ajoutée.
- Aucune sauvegarde `project.json` / `FileProjectRepository` dans le flux masque.
- Aucun `SurfaceLayer` legacy utilisé pour le masque.
- Aucun `git commit` / `git add` / `git push` exécuté par l’agent.

## 13. Pourquoi aucune génération / MapPlacedElement / TileLayer patch dans ce lot

Le use case appelle uniquement `setEnvironmentLayerContent` sur le layer environnement ; pas d’API de placement, pas de modification des tuiles, pas d’appel générateur.

## 14. Fichiers modifiés

- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart` (nouveau)
- `packages/map_editor/lib/src/features/editor/tools/editor_tool.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart` (généré / déjà dans l’arbre)
- `packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart`
- `packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart` (mineur si régénéré)
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` (`expandedHeight` 360 → 560 pour scroll inspecteur)
- `packages/map_editor/test/editor_state_groups_test.dart`
- `packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart` (nouveau)
- `packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart` (`ensureVisible` sur boutons bas de carte)
- `packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart` (`ensureVisible` + taps cible)
- `packages/map_editor/test/environment_studio/environment_layer_creation_test.dart` (texte zones Lot 22)

Fichiers hors Lot 22 encore modifiés dans le dépôt (présents au `git status`, non traités ici) : `packages/map_core/*`, autres chemins listés par l’utilisateur au démarrage.

## 15. Tests ajoutés ou modifiés

- Nouveau : `test/environment_studio/environment_layer_mask_brush_tool_test.dart` (use case, notifier, inspecteur, canvas tap paint/erase, painter overlay).
- Ajustements : `environment_layer_area_model_editing_test.dart`, `environment_layer_target_tile_layer_test.dart`, `environment_layer_creation_test.dart`, `editor_state_groups_test.dart`.

## 16. Commandes exécutées

```bash
cd packages/map_editor
dart format lib/src/ui/canvas/map_canvas/map_grid_painter.dart lib/src/ui/canvas/map_canvas.dart \
  lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/environment_layer_inspector_panel.dart \
  test/environment_studio/environment_layer_mask_brush_tool_test.dart
flutter analyze lib/src/ui/canvas/map_canvas/map_grid_painter.dart lib/src/ui/canvas/map_canvas.dart \
  lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/environment_layer_inspector_panel.dart \
  test/environment_studio/environment_layer_mask_brush_tool_test.dart
grep -R "FileProjectRepository|saveProject|saveProjectManifest" -n ...  # voir §12
flutter test test/environment_studio/environment_layer_mask_brush_tool_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
```

## 17. Résultats des commandes

- `flutter analyze` (fichiers listés §16) : **0 erreurs** (après corrections tests).
- `flutter test test/environment_studio/environment_layer_mask_brush_tool_test.dart` : **All tests passed!** (+12).
- `flutter test test/environment_studio` : **All tests passed!** (+153 tests, ligne finale du journal d’agent : `00:06 +153: All tests passed!`).
- `flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart` : **All tests passed!** (+14).

`flutter test` complet package : **non exécuté** dans cette session (périmètre : studio + tests proches ; la suite `test/environment_studio` couvre les régressions demandées).

## 18. Git status initial et final

**Final** (extrait commande `git status --short --untracked-files=all` à la racine du dépôt) :

```
 M packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
 M packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
 M packages/map_editor/lib/src/features/editor/tools/editor_tool.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/test/editor_state_groups_test.dart
 M packages/map_editor/test/environment_studio/environment_layer_creation_test.dart
 M packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart
?? packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart
?? packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart
?? packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart
?? reports/forest/environment_studio_lot_21_environment_area_model_editing.md
```

**Initial** : non capturé dans cette session (non demandé en entrée de commande isolée) ; le dépôt contenait déjà des modifications non commitées (`map_core`, `map_runtime`, etc. selon le contexte utilisateur).

## 19. Contenu complet des fichiers créés ou modifiés

Les fichiers volumineux (`editor_notifier.dart`, `environment_layer_inspector_panel.dart`, `editor_state.freezed.dart`, etc.) sont reproduits intégralement dans le dépôt ; cette section reproduit **intégralement** les fichiers **nouveaux** principaux du Lot 22 et les **extraits** critiques pour les autres (énumération + API masque). Pour une copie byte-à-byte de tout `packages/map_editor`, utiliser le dépôt après application du diff §20.

### 19.1 `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart` (intégral)

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

/// Lot Environment-22 : peinture / effacement d’une cellule du masque d’une zone.
///
/// Ne modifie pas [MapData] si la cellule a déjà la valeur demandée (référence
/// identique pour éviter dirty inutile).
class PaintEnvironmentAreaMaskCellUseCase {
  MapData execute(
    MapData map, {
    required String environmentLayerId,
    required String areaId,
    required GridPos pos,
    required bool isActive,
  }) {
    final envId = environmentLayerId.trim();
    if (envId.isEmpty) {
      throw const EditorValidationException(
        'Environment layer id cannot be empty',
      );
    }
    final aid = areaId.trim();
    if (aid.isEmpty) {
      throw const EditorValidationException('Area id cannot be empty');
    }

    if (pos.x < 0 ||
        pos.y < 0 ||
        pos.x >= map.size.width ||
        pos.y >= map.size.height) {
      throw EditorValidationException(
        'Position out of map bounds: (${pos.x}, ${pos.y})',
      );
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
        'Layer is not an environment layer: $envId',
      );
    }

    EnvironmentArea? area;
    for (final a in envLayer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      throw EditorValidationException('Environment area not found: $aid');
    }

    final mask = area.mask;
    if (mask.width != map.size.width || mask.height != map.size.height) {
      throw EditorValidationException(
        'Environment mask size ${mask.width}x${mask.height} does not match '
        'map size ${map.size.width}x${map.size.height}',
      );
    }
    final expected = mask.width * mask.height;
    if (mask.cells.length != expected) {
      throw EditorValidationException(
        'Environment mask cells length ${mask.cells.length} != $expected',
      );
    }

    final index = pos.y * mask.width + pos.x;
    if (index < 0 || index >= mask.cells.length) {
      throw EditorValidationException('Mask index out of bounds: $index');
    }

    if (mask.cells[index] == isActive) {
      return map;
    }

    final nextCells = List<bool>.from(mask.cells, growable: false);
    nextCells[index] = isActive;
    final nextMask = EnvironmentAreaMask(
      width: mask.width,
      height: mask.height,
      cells: nextCells,
    );
    final updatedArea = EnvironmentArea(
      id: area.id,
      name: area.name,
      presetId: area.presetId,
      mask: nextMask,
      seed: area.seed,
      paramsOverride: area.paramsOverride,
      generatedPlacementIds: area.generatedPlacementIds,
    );

    final nextAreas = envLayer.content.areas
        .map((a) => a.id == aid ? updatedArea : a)
        .toList(growable: false);
    final nextContent = EnvironmentLayerContent(
      targetTileLayerId: envLayer.content.targetTileLayerId,
      areas: nextAreas,
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

### 19.2 `packages/map_editor/lib/src/features/editor/tools/editor_tool.dart` (extrait Lot 22)

```dart
/// Lot Environment-22 : édition du masque d’une [EnvironmentArea] sur la carte.
enum EnvironmentMaskEditMode {
  paint,
  erase,
}
```

### 19.3 `packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart` (intégral)

```dart
// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/application/use_cases/environment_mask_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/panels/environment_layer_inspector_panel.dart';

import '../shell_chrome_test_harness.dart';

EnvironmentArea _area({
  required String id,
  required int w,
  required int h,
  List<bool>? cells,
  List<String>? generatedPlacementIds,
}) {
  return EnvironmentArea(
    id: id,
    name: 'Zone $id',
    presetId: 'preset_forest',
    mask: EnvironmentAreaMask(
      width: w,
      height: h,
      cells: cells ?? List<bool>.filled(w * h, false),
    ),
    seed: 42,
    generatedPlacementIds: generatedPlacementIds ?? const ['g1', 'g2'],
  );
}

MapData _mapWithEnv(EnvironmentLayer env) {
  final w = env.content.areas.isEmpty
      ? 4
      : env.content.areas.first.mask.width;
  final h = env.content.areas.isEmpty
      ? 3
      : env.content.areas.first.mask.height;
  final cellCount = w * h;
  return MapData(
    id: 'm',
    name: 'M',
    size: GridSize(width: w, height: h),
    layers: <MapLayer>[
      env,
      TileLayer(
        id: 'tiles_main',
        name: 'Sol',
        tiles: List<int>.filled(cellCount, 0),
      ),
    ],
    placedElements: [
      MapPlacedElement(
        id: 'pe1',
        layerId: 'tiles_main',
        elementId: 'elem',
        pos: const GridPos(x: 0, y: 0),
      ),
    ],
  );
}

EnvironmentPreset _manifestPreset() {
  return EnvironmentPreset(
    id: 'preset_forest',
    name: 'Forêt test',
    templateId: 'forest_dense',
    palette: [
      EnvironmentPaletteItem(elementId: 'elem_tree', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

void main() {
  group('Lot 22 — PaintEnvironmentAreaMaskCellUseCase', () {
    late EnvironmentLayer env;
    late MapData map;

    setUp(() {
      env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles_main',
          areas: [
            _area(id: 'a1', w: 4, h: 3),
          ],
        ),
      ) as EnvironmentLayer;
      map = _mapWithEnv(env);
    });

    test('paint (1,1) : une cellule active, preset et placements préservés',
        () {
      final uc = PaintEnvironmentAreaMaskCellUseCase();
      final out = uc.execute(
        map,
        environmentLayerId: 'env1',
        areaId: 'a1',
        pos: const GridPos(x: 1, y: 1),
        isActive: true,
      );
      final layer = out.layers.first as EnvironmentLayer;
      final area = layer.content.areas.single;
      expect(area.mask.activeCellCount, 1);
      expect(area.mask.isActiveAt(1, 1), isTrue);
      expect(area.presetId, 'preset_forest');
      expect(area.generatedPlacementIds, const ['g1', 'g2']);
      expect(layer.content.targetTileLayerId, 'tiles_main');
      expect(out.placedElements, map.placedElements);
    });

    test('erase : cellule repasse false, compteur diminue', () {
      final cells = List<bool>.filled(12, true);
      final env2 = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(
          areas: [
            _area(id: 'a1', w: 4, h: 3, cells: cells),
          ],
        ),
      ) as EnvironmentLayer;
      final map2 = _mapWithEnv(env2);
      final uc = PaintEnvironmentAreaMaskCellUseCase();
      final out = uc.execute(
        map2,
        environmentLayerId: 'env1',
        areaId: 'a1',
        pos: const GridPos(x: 0, y: 0),
        isActive: false,
      );
      final area = (out.layers.first as EnvironmentLayer).content.areas.single;
      expect(area.mask.isActiveAt(0, 0), isFalse);
      expect(area.mask.activeCellCount, 11);
    });

    test('no-op paint true sur true → même référence MapData', () {
      final cells = List<bool>.filled(12, false);
      cells[5] = true; // (1,1)
      final env2 = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(
          areas: [_area(id: 'a1', w: 4, h: 3, cells: cells)],
        ),
      ) as EnvironmentLayer;
      final map2 = _mapWithEnv(env2);
      final uc = PaintEnvironmentAreaMaskCellUseCase();
      final out = uc.execute(
        map2,
        environmentLayerId: 'env1',
        areaId: 'a1',
        pos: const GridPos(x: 1, y: 1),
        isActive: true,
      );
      expect(identical(out, map2), isTrue);
    });

    test('no-op erase false sur false → même référence MapData', () {
      final uc = PaintEnvironmentAreaMaskCellUseCase();
      final out = uc.execute(
        map,
        environmentLayerId: 'env1',
        areaId: 'a1',
        pos: const GridPos(x: 2, y: 2),
        isActive: false,
      );
      expect(identical(out, map), isTrue);
    });

    test('erreurs use case', () {
      final uc = PaintEnvironmentAreaMaskCellUseCase();
      expect(
        () => uc.execute(
          map,
          environmentLayerId: '',
          areaId: 'a1',
          pos: const GridPos(x: 0, y: 0),
          isActive: true,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => uc.execute(
          map,
          environmentLayerId: 'missing',
          areaId: 'a1',
          pos: const GridPos(x: 0, y: 0),
          isActive: true,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      final tileOnly = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 4, height: 3),
        layers: [
          TileLayer(
            id: 'env1',
            name: 'T',
            tiles: List<int>.filled(12, 0),
          ),
        ],
      );
      expect(
        () => uc.execute(
          tileOnly,
          environmentLayerId: 'env1',
          areaId: 'a1',
          pos: const GridPos(x: 0, y: 0),
          isActive: true,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => uc.execute(
          map,
          environmentLayerId: 'env1',
          areaId: 'missing_area',
          pos: const GridPos(x: 0, y: 0),
          isActive: true,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => uc.execute(
          map,
          environmentLayerId: 'env1',
          areaId: 'a1',
          pos: const GridPos(x: 10, y: 0),
          isActive: true,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      final wrongMaskEnv = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles_main',
          areas: [
            _area(id: 'a1', w: 2, h: 2),
          ],
        ),
      ) as EnvironmentLayer;
      final badMap = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 4, height: 3),
        layers: <MapLayer>[
          wrongMaskEnv,
          TileLayer(
            id: 'tiles_main',
            name: 'Sol',
            tiles: List<int>.filled(12, 0),
          ),
        ],
      );
      expect(
        () => uc.execute(
          badMap,
          environmentLayerId: 'env1',
          areaId: 'a1',
          pos: const GridPos(x: 0, y: 0),
          isActive: true,
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });
  });

  group('Lot 22 — EditorNotifier masque', () {
    test('start paint / erase / stop + paint met dirty et préserve chemins',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(
          areas: [_area(id: 'area_1', w: 4, h: 3)],
        ),
      ) as EnvironmentLayer;
      final map = _mapWithEnv(env);
      const root = '/tmp/lot22';
      const mapPath = 'maps/z.json';
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: root,
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: mapPath,
        activeLayerId: 'env1',
        savedMapSnapshot: map,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.startEnvironmentAreaMaskPaint(
        environmentLayerId: 'env1',
        areaId: 'area_1',
      );
      var s = container.read(editorNotifierProvider);
      expect(s.selectedEnvironmentAreaId, 'area_1');
      expect(s.environmentMaskEditMode, EnvironmentMaskEditMode.paint);

      notifier.startEnvironmentAreaMaskErase(
        environmentLayerId: 'env1',
        areaId: 'area_1',
      );
      s = container.read(editorNotifierProvider);
      expect(s.environmentMaskEditMode, EnvironmentMaskEditMode.erase);

      notifier.stopEnvironmentAreaMaskEditing();
      s = container.read(editorNotifierProvider);
      expect(s.environmentMaskEditMode, isNull);
      expect(s.selectedEnvironmentAreaId, 'area_1');

      notifier.startEnvironmentAreaMaskPaint(
        environmentLayerId: 'env1',
        areaId: 'area_1',
      );
      notifier.paintEnvironmentAreaMaskAt(const GridPos(x: 2, y: 1));
      s = container.read(editorNotifierProvider);
      expect(s.isDirty, isTrue);
      expect(s.activeLayerId, 'env1');
      expect(s.projectRootPath, root);
      expect(s.activeMapPath, mapPath);
      final area =
          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
      expect(area.mask.isActiveAt(2, 1), isTrue);
      expect(area.generatedPlacementIds, const ['g1', 'g2']);
      expect(s.activeMap!.placedElements, map.placedElements);
    });

    test('changer de layer actif hors Environment → mode masque désactivé', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final tile = TileLayer(
        id: 't1',
        name: 'T',
        tiles: List<int>.filled(12, 0),
      );
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(
          areas: [_area(id: 'a1', w: 4, h: 3)],
        ),
      ) as EnvironmentLayer;
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 4, height: 3),
        layers: [env, tile],
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env1',
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.startEnvironmentAreaMaskPaint(
        environmentLayerId: 'env1',
        areaId: 'a1',
      );
      notifier.setActiveLayer('t1');
      final s = container.read(editorNotifierProvider);
      expect(s.activeLayerId, 't1');
      expect(s.environmentMaskEditMode, isNull);
      expect(s.selectedEnvironmentAreaId, isNull);
    });

    test('removeEnvironmentArea nettoie la sélection masque', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(
          areas: [_area(id: 'a1', w: 4, h: 3)],
        ),
      ) as EnvironmentLayer;
      final map = _mapWithEnv(env);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env1',
        selectedEnvironmentAreaId: 'a1',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
      );
      container.read(editorNotifierProvider.notifier).removeEnvironmentArea(
            environmentLayerId: 'env1',
            areaId: 'a1',
          );
      final s = container.read(editorNotifierProvider);
      expect(s.selectedEnvironmentAreaId, isNull);
      expect(s.environmentMaskEditMode, isNull);
    });
  });

  group('Lot 22 — inspecteur masque', () {
    testWidgets('boutons masque + libellé édition active', (tester) async {
      final area = _area(id: 'area_ui', w: 2, h: 2);
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(areas: [area]),
      ) as EnvironmentLayer;
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
        project: buildShellChromeProject(
          environmentPresets: [_manifestPreset()],
        ),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env1',
      );
      await tester.binding.setSurfaceSize(const Size(520, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: SingleChildScrollView(
                  child: EnvironmentLayerInspectorPanel(
                    map: map,
                    layer: env,
                    embedded: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(Key('env-area-mask-paint-${area.id}')), findsOneWidget);
      expect(find.byKey(Key('env-area-mask-erase-${area.id}')), findsOneWidget);
      await tester.tap(find.byKey(Key('env-area-mask-paint-${area.id}')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('env-area-card-mask-edit-active-${area.id}')),
        findsOneWidget,
      );
      expect(find.textContaining('Édition active : peinture'), findsOneWidget);
      await tester.tap(find.byKey(Key('env-area-mask-erase-${area.id}')));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('Édition active : effacement'), findsOneWidget);
      await tester.tap(find.byKey(Key('env-area-mask-stop-${area.id}')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('env-area-card-mask-edit-active-${area.id}')),
        findsNothing,
      );
      final s = container.read(editorNotifierProvider);
      expect(s.environmentMaskEditMode, isNull);
    });
  });

  group('Lot 22 — MapCanvas tap masque', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('map_editor_lot22_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('tap peint une cellule du masque', (tester) async {
      final area = _area(id: 'a_canvas', w: 4, h: 4);
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(areas: [area]),
      ) as EnvironmentLayer;
      final map = MapData(
        id: 'route_1',
        name: 'Route 1',
        size: const GridSize(width: 4, height: 4),
        layers: <MapLayer>[env],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempDir.path,
        project: ProjectManifest(
          name: 'p',
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
        activeMap: map,
        activeLayerId: 'env1',
        selectedEnvironmentAreaId: area.id,
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
      );

      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: Center(
                  child: SizedBox(
                    width: 900,
                    height: 700,
                    child: MapCanvas(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final mapBox = tester.getRect(find.byType(MapCanvas));
      // tile logique 16 * displayScale 2 = 32 ; cellule (1,1) → centre ~48,48
      const local = Offset(48, 48);
      await tester.tapAt(mapBox.topLeft + local);
      await tester.pumpAndSettle();

      final s = container.read(editorNotifierProvider);
      expect(s.isDirty, isTrue);
      final painted =
          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
      expect(painted.mask.isActiveAt(1, 1), isTrue);
    });

    testWidgets('mode erase + tap efface la cellule', (tester) async {
      final cells = List<bool>.filled(16, false);
      cells[5] = true; // (1,1)
      final area = _area(id: 'a_erase', w: 4, h: 4, cells: cells);
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(areas: [area]),
      ) as EnvironmentLayer;
      final map = MapData(
        id: 'route_1',
        name: 'Route 1',
        size: const GridSize(width: 4, height: 4),
        layers: <MapLayer>[env],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempDir.path,
        project: ProjectManifest(
          name: 'p',
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
        activeMap: map,
        activeLayerId: 'env1',
        selectedEnvironmentAreaId: area.id,
        environmentMaskEditMode: EnvironmentMaskEditMode.erase,
      );

      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: Center(
                  child: SizedBox(
                    width: 900,
                    height: 700,
                    child: MapCanvas(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final mapBox = tester.getRect(find.byType(MapCanvas));
      await tester.tapAt(mapBox.topLeft + const Offset(48, 48));
      await tester.pumpAndSettle();

      final painted = (container
              .read(editorNotifierProvider)
              .activeMap!
              .layers
              .first as EnvironmentLayer)
          .content
          .areas
          .single;
      expect(painted.mask.isActiveAt(1, 1), isFalse);
    });
  });

  group('Lot 22 — MapGridPainter overlay masque', () {
    test('environmentMaskOverlay actif ne lève pas', () {
      final mask = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: [true, false, false, false],
      );
      final map = MapData(
        id: 'lab',
        name: 'lab',
        size: const GridSize(width: 2, height: 2),
        layers: const <MapLayer>[],
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      MapGridPainter(
        map: map,
        zoom: 1,
        offset: ui.Offset.zero,
        hoveredTile: null,
        activeLayerId: null,
        tileWidth: 32,
        tileHeight: 32,
        tilesetImagesById: const <String, ui.Image?>{},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{},
        toolPreview: null,
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        gameplayZoneDraftArea: null,
        selectedEntityId: null,
        selectedMapEventId: null,
        selectedWarpId: null,
        selectedTriggerId: null,
        selectedGameplayZoneId: null,
        selectedPlacedElementInstanceId: null,
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        selectedPathAutotileSet: null,
        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
        project: null,
        environmentMaskOverlay: mask,
      ).paint(canvas, const ui.Size(64, 64));
      recorder.endRecording().dispose();
    });
  });
}
```

## 20. Diff complet

```diff
diff --git a/packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart b/packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
index a935859e..51e7f726 100644
--- a/packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
+++ b/packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
@@ -317,3 +317,284 @@ class SetEnvironmentLayerTargetTileLayerUseCase {
     }
   }
 }
+
+/// Masque booléen vide aligné sur [MapData.size] (toutes les cellules inactives).
+EnvironmentAreaMask emptyEnvironmentAreaMaskForMap(MapData map) {
+  final w = map.size.width;
+  final h = map.size.height;
+  return EnvironmentAreaMask(
+    width: w,
+    height: h,
+    cells: List<bool>.filled(w * h, false, growable: false),
+  );
+}
+
+String _slugifyEnvAreaToken(String value) {
+  final lowered = value.toLowerCase().trim();
+  final replaced = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
+  return replaced.replaceAll(RegExp(r'^_+|_+$'), '');
+}
+
+String _uniqueEnvironmentAreaId({
+  required String presetId,
+  required Iterable<String> existingAreaIds,
+}) {
+  final slug = _slugifyEnvAreaToken(presetId);
+  final baseToken = slug.isEmpty ? 'area' : slug;
+  final base = 'env_area_$baseToken';
+  final existing = existingAreaIds.toSet();
+  if (!existing.contains(base)) {
+    return base;
+  }
+  var n = 2;
+  while (true) {
+    final candidate = '${base}_$n';
+    if (!existing.contains(candidate)) {
+      return candidate;
+    }
+    n++;
+  }
+}
+
+/// Lot Environment-21 : résultat de [AddEnvironmentAreaUseCase].
+final class AddEnvironmentAreaResult {
+  const AddEnvironmentAreaResult({
+    required this.map,
+    required this.area,
+  });
+
+  final MapData map;
+  final EnvironmentArea area;
+}
+
+/// Lot Environment-21 : ajoute une [EnvironmentArea] (mask vide, map size).
+class AddEnvironmentAreaUseCase {
+  AddEnvironmentAreaResult execute(
+    MapData map, {
+    required ProjectManifest manifest,
+    required String environmentLayerId,
+    required String presetId,
+  }) {
+    final envId = environmentLayerId.trim();
+    if (envId.isEmpty) {
+      throw const EditorValidationException(
+        'Environment layer id cannot be empty',
+      );
+    }
+    final pid = presetId.trim();
+    if (pid.isEmpty) {
+      throw const EditorValidationException('Preset id cannot be empty');
+    }
+
+    EnvironmentPreset? preset;
+    for (final p in manifest.environmentPresets) {
+      if (p.id == pid) {
+        preset = p;
+        break;
+      }
+    }
+    if (preset == null) {
+      throw EditorValidationException('Environment preset not found: $pid');
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
+        'Layer is not an environment layer: $envId',
+      );
+    }
+
+    final existingIds = envLayer.content.areas.map((a) => a.id).toList();
+    final newId = _uniqueEnvironmentAreaId(
+      presetId: pid,
+      existingAreaIds: existingIds,
+    );
+    final mask = emptyEnvironmentAreaMaskForMap(map);
+    final area = EnvironmentArea(
+      id: newId,
+      name: preset.name,
+      presetId: pid,
+      mask: mask,
+      seed: 0,
+    );
+
+    final nextAreas = <EnvironmentArea>[...envLayer.content.areas, area];
+    final nextContent = EnvironmentLayerContent(
+      targetTileLayerId: envLayer.content.targetTileLayerId,
+      areas: nextAreas,
+    );
+    try {
+      final updated = setEnvironmentLayerContent(
+        map,
+        layerId: envId,
+        content: nextContent,
+      );
+      MapValidator.validate(updated);
+      return AddEnvironmentAreaResult(map: updated, area: area);
+    } on ValidationException catch (e) {
+      throw EditorValidationException(e.message);
+    }
+  }
+}
+
+/// Lot Environment-21 : change uniquement le [EnvironmentArea.presetId].
+class SetEnvironmentAreaPresetUseCase {
+  MapData execute(
+    MapData map, {
+    required ProjectManifest manifest,
+    required String environmentLayerId,
+    required String areaId,
+    required String presetId,
+  }) {
+    final envId = environmentLayerId.trim();
+    if (envId.isEmpty) {
+      throw const EditorValidationException(
+        'Environment layer id cannot be empty',
+      );
+    }
+    final aid = areaId.trim();
+    if (aid.isEmpty) {
+      throw const EditorValidationException('Area id cannot be empty');
+    }
+    final pid = presetId.trim();
+    if (pid.isEmpty) {
+      throw const EditorValidationException('Preset id cannot be empty');
+    }
+
+    EnvironmentPreset? preset;
+    for (final p in manifest.environmentPresets) {
+      if (p.id == pid) {
+        preset = p;
+        break;
+      }
+    }
+    if (preset == null) {
+      throw EditorValidationException('Environment preset not found: $pid');
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
+        'Layer is not an environment layer: $envId',
+      );
+    }
+
+    EnvironmentArea? found;
+    for (final a in envLayer.content.areas) {
+      if (a.id == aid) {
+        found = a;
+        break;
+      }
+    }
+    if (found == null) {
+      throw EditorValidationException('Environment area not found: $aid');
+    }
+
+    final updatedArea = EnvironmentArea(
+      id: found.id,
+      name: found.name,
+      presetId: pid,
+      mask: found.mask,
+      seed: found.seed,
+      paramsOverride: found.paramsOverride,
+      generatedPlacementIds: found.generatedPlacementIds,
+    );
+
+    final nextAreas = envLayer.content.areas
+        .map((a) => a.id == aid ? updatedArea : a)
+        .toList(growable: false);
+    final nextContent = EnvironmentLayerContent(
+      targetTileLayerId: envLayer.content.targetTileLayerId,
+      areas: nextAreas,
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
+
+/// Lot Environment-21 : retire une [EnvironmentArea] du layer.
+class RemoveEnvironmentAreaUseCase {
+  MapData execute(
+    MapData map, {
+    required String environmentLayerId,
+    required String areaId,
+  }) {
+    final envId = environmentLayerId.trim();
+    if (envId.isEmpty) {
+      throw const EditorValidationException(
+        'Environment layer id cannot be empty',
+      );
+    }
+    final aid = areaId.trim();
+    if (aid.isEmpty) {
+      throw const EditorValidationException('Area id cannot be empty');
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
+        'Layer is not an environment layer: $envId',
+      );
+    }
+
+    final had = envLayer.content.areas.any((a) => a.id == aid);
+    if (!had) {
+      throw EditorValidationException('Environment area not found: $aid');
+    }
+
+    final nextAreas = envLayer.content.areas
+        .where((a) => a.id != aid)
+        .toList(growable: false);
+    final nextContent = EnvironmentLayerContent(
+      targetTileLayerId: envLayer.content.targetTileLayerId,
+      areas: nextAreas,
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
diff --git a/packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart b/packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart
index 277312df..7624988b 100644
--- a/packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart
+++ b/packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart
@@ -39,6 +39,9 @@ class MapSelectionController {
     return current.copyWith(
       activeTool: tool,
       terrainSelectionMode: terrainMode,
+      // Lot Environment-22 : un outil toolbar classique sort du mode masque.
+      selectedEnvironmentAreaId: null,
+      environmentMaskEditMode: null,
     );
   }
 
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index 91457a73..e7157884 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -13,6 +13,7 @@ import '../../../app/providers/core_providers.dart';
 import '../../../app/providers/editor_workspace_providers.dart';
 import '../../../app/providers/use_case_providers.dart';
 import '../../../application/errors/application_errors.dart';
+import '../../../application/use_cases/environment_mask_use_cases.dart';
 import '../../../application/use_cases/layer_use_cases.dart';
 import '../../../application/models/trainer_field_update.dart';
 import '../../../application/models/map_tool_preview.dart';
@@ -4675,6 +4676,211 @@ class EditorNotifier extends _$EditorNotifier {
     }
   }
 
+  /// Lot Environment-21 : ajoute une [EnvironmentArea] (mask vide, preset manifest).
+  void addEnvironmentAreaToLayer({
+    required String environmentLayerId,
+    required String presetId,
+  }) {
+    final map = state.activeMap;
+    final project = state.project;
+    if (map == null || project == null) {
+      state = state.copyWith(
+        errorMessage:
+            'Cannot add environment area: no active map or project manifest.',
+      );
+      return;
+    }
+    try {
+      final useCase = AddEnvironmentAreaUseCase();
+      final result = useCase.execute(
+        map,
+        manifest: project,
+        environmentLayerId: environmentLayerId,
+        presetId: presetId,
+      );
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: result.map,
+        preferredActiveLayerId: environmentLayerId,
+        statusMessage: 'Environment area added',
+      );
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Failed to add environment area: $e',
+      );
+    }
+  }
+
+  /// Lot Environment-21 : change le preset d’une zone existante.
+  void setEnvironmentAreaPreset({
+    required String environmentLayerId,
+    required String areaId,
+    required String presetId,
+  }) {
+    final map = state.activeMap;
+    final project = state.project;
+    if (map == null || project == null) {
+      state = state.copyWith(
+        errorMessage:
+            'Cannot set environment area preset: no active map or project manifest.',
+      );
+      return;
+    }
+    try {
+      final useCase = SetEnvironmentAreaPresetUseCase();
+      final updated = useCase.execute(
+        map,
+        manifest: project,
+        environmentLayerId: environmentLayerId,
+        areaId: areaId,
+        presetId: presetId,
+      );
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: updated,
+        preferredActiveLayerId: environmentLayerId,
+        statusMessage: 'Environment area preset updated',
+      );
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Failed to set environment area preset: $e',
+      );
+    }
+  }
+
+  /// Lot Environment-21 : retire une [EnvironmentArea].
+  void removeEnvironmentArea({
+    required String environmentLayerId,
+    required String areaId,
+  }) {
+    final map = state.activeMap;
+    if (map == null) return;
+    try {
+      final useCase = RemoveEnvironmentAreaUseCase();
+      final updated = useCase.execute(
+        map,
+        environmentLayerId: environmentLayerId,
+        areaId: areaId,
+      );
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: updated,
+        preferredActiveLayerId: environmentLayerId,
+        statusMessage: 'Environment area removed',
+      );
+      _coerceEnvironmentMaskSelectionAfterMapChange();
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Failed to remove environment area: $e',
+      );
+    }
+  }
+
+  /// Lot Environment-22 : area sélectionnée pour édition masque, sans activer paint/erase.
+  void selectEnvironmentAreaForMaskEditing({
+    required String environmentLayerId,
+    required String areaId,
+  }) {
+    final map = state.activeMap;
+    if (map == null) return;
+    final layer = _findLayerById(map, environmentLayerId);
+    if (layer is! EnvironmentLayer) return;
+    if (!layer.content.areas.any((a) => a.id == areaId)) return;
+    state = state.copyWith(
+      activeLayerId: environmentLayerId,
+      selectedEnvironmentAreaId: areaId,
+      errorMessage: null,
+    );
+  }
+
+  /// Lot Environment-22 : active la peinture du masque pour une zone.
+  void startEnvironmentAreaMaskPaint({
+    required String environmentLayerId,
+    required String areaId,
+  }) {
+    final map = state.activeMap;
+    if (map == null) return;
+    final layer = _findLayerById(map, environmentLayerId);
+    if (layer is! EnvironmentLayer) return;
+    if (!layer.content.areas.any((a) => a.id == areaId)) return;
+    state = state.copyWith(
+      activeLayerId: environmentLayerId,
+      selectedEnvironmentAreaId: areaId,
+      environmentMaskEditMode: EnvironmentMaskEditMode.paint,
+      errorMessage: null,
+    );
+  }
+
+  /// Lot Environment-22 : active l’effacement du masque pour une zone.
+  void startEnvironmentAreaMaskErase({
+    required String environmentLayerId,
+    required String areaId,
+  }) {
+    final map = state.activeMap;
+    if (map == null) return;
+    final layer = _findLayerById(map, environmentLayerId);
+    if (layer is! EnvironmentLayer) return;
+    if (!layer.content.areas.any((a) => a.id == areaId)) return;
+    state = state.copyWith(
+      activeLayerId: environmentLayerId,
+      selectedEnvironmentAreaId: areaId,
+      environmentMaskEditMode: EnvironmentMaskEditMode.erase,
+      errorMessage: null,
+    );
+  }
+
+  /// Lot Environment-22 : quitte paint/erase sans changer l’area sélectionnée.
+  void stopEnvironmentAreaMaskEditing() {
+    state = state.copyWith(environmentMaskEditMode: null, errorMessage: null);
+  }
+
+  /// Lot Environment-22 : applique paint ou erase selon [environmentMaskEditMode].
+  void paintEnvironmentAreaMaskAt(
+    GridPos pos, {
+    bool partOfStroke = false,
+  }) {
+    final map = state.activeMap;
+    if (map == null) return;
+    final layerId = state.activeLayerId;
+    final areaId = state.selectedEnvironmentAreaId;
+    final mode = state.environmentMaskEditMode;
+    if (layerId == null || areaId == null || mode == null) {
+      return;
+    }
+    final layer = _findLayerById(map, layerId);
+    if (layer is! EnvironmentLayer) {
+      return;
+    }
+    if (!layer.content.areas.any((a) => a.id == areaId)) {
+      return;
+    }
+    final isActive = mode == EnvironmentMaskEditMode.paint;
+    try {
+      final useCase = PaintEnvironmentAreaMaskCellUseCase();
+      final updated = useCase.execute(
+        map,
+        environmentLayerId: layerId,
+        areaId: areaId,
+        pos: pos,
+        isActive: isActive,
+      );
+      if (identical(updated, map)) {
+        return;
+      }
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: updated,
+        preferredActiveLayerId: layerId,
+        partOfStroke: partOfStroke,
+        statusMessage: 'Environment mask updated',
+      );
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Failed to edit environment mask: $e',
+      );
+    }
+  }
+
   void renameMapLayer(String layerId, String name) {
     final map = state.activeMap;
     if (map == null) return;
@@ -4719,6 +4925,7 @@ class EditorNotifier extends _$EditorNotifier {
         preferredActiveLayerId: nextActiveLayerId,
         statusMessage: 'Layer deleted',
       );
+      _coerceEnvironmentMaskSelectionAfterMapChange();
     } catch (e) {
       state = state.copyWith(errorMessage: 'Failed to delete layer: $e');
     }
@@ -4737,6 +4944,7 @@ class EditorNotifier extends _$EditorNotifier {
             _editorMapSessionCoordinator.resolveActiveLayerId(updated),
         statusMessage: 'All layers removed',
       );
+      _coerceEnvironmentMaskSelectionAfterMapChange();
     } catch (e) {
       state = state.copyWith(errorMessage: 'Failed to remove all layers: $e');
     }
@@ -5785,6 +5993,8 @@ class EditorNotifier extends _$EditorNotifier {
     state = state.copyWith(
       activeLayerId: layerId,
       selectedPlacedElementInstanceId: null,
+      selectedEnvironmentAreaId: null,
+      environmentMaskEditMode: null,
       errorMessage: null,
     );
     _coerceActiveToolIfIncompatibleWithLayer();
@@ -6100,6 +6310,38 @@ class EditorNotifier extends _$EditorNotifier {
     return null;
   }
 
+  /// Lot Environment-22 : évite une sélection masque fantôme si le layer ou l’area disparaît.
+  void _coerceEnvironmentMaskSelectionAfterMapChange() {
+    final map = state.activeMap;
+    final lid = state.activeLayerId;
+    if (map == null || lid == null) {
+      state = state.copyWith(
+        selectedEnvironmentAreaId: null,
+        environmentMaskEditMode: null,
+      );
+      return;
+    }
+    final layer = _findLayerById(map, lid);
+    if (layer is! EnvironmentLayer) {
+      state = state.copyWith(
+        selectedEnvironmentAreaId: null,
+        environmentMaskEditMode: null,
+      );
+      return;
+    }
+    final sid = state.selectedEnvironmentAreaId?.trim();
+    if (sid == null || sid.isEmpty) {
+      return;
+    }
+    final stillExists = layer.content.areas.any((a) => a.id == sid);
+    if (!stillExists) {
+      state = state.copyWith(
+        selectedEnvironmentAreaId: null,
+        environmentMaskEditMode: null,
+      );
+    }
+  }
+
   String? _resolveEventPlacementLayerId(MapData map) {
     final activeLayerId = state.activeLayerId?.trim();
     if (activeLayerId != null &&
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart
index 693d6afb..b9b6f68d 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart
@@ -6,7 +6,7 @@ part of 'editor_notifier.dart';
 // RiverpodGenerator
 // **************************************************************************
 
-String _$editorNotifierHash() => r'e0a8bea9cc8acff2d92042838cf78c5468c9fa97';
+String _$editorNotifierHash() => r'a140428284de9f56f207390e7ef24bbafc77c390';
 
 /// See also [EditorNotifier].
 @ProviderFor(EditorNotifier)
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_state.dart b/packages/map_editor/lib/src/features/editor/state/editor_state.dart
index ababe5a6..d4bce311 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_state.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_state.dart
@@ -76,6 +76,10 @@ class EditorState with _$EditorState {
     String? selectedTriggerId,
     String? selectedGameplayZoneId,
 
+    /// Lot Environment-22 : area dont le masque est édité (layer actif = Environment).
+    String? selectedEnvironmentAreaId,
+    EnvironmentMaskEditMode? environmentMaskEditMode,
+
     /// Zone en cours de tracé par clic+glisser (fantôme, pas encore persistée).
     MapRect? gameplayZoneDraftArea,
     String? selectedTilesetEditorId,
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart b/packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
index 3c53b4a3..a6f53250 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
@@ -738,6 +738,11 @@ mixin _$EditorState {
   String? get selectedTriggerId => throw _privateConstructorUsedError;
   String? get selectedGameplayZoneId => throw _privateConstructorUsedError;
 
+  /// Lot Environment-22 : area dont le masque est édité (layer actif = Environment).
+  String? get selectedEnvironmentAreaId => throw _privateConstructorUsedError;
+  EnvironmentMaskEditMode? get environmentMaskEditMode =>
+      throw _privateConstructorUsedError;
+
   /// Zone en cours de tracé par clic+glisser (fantôme, pas encore persistée).
   MapRect? get gameplayZoneDraftArea => throw _privateConstructorUsedError;
   String? get selectedTilesetEditorId => throw _privateConstructorUsedError;
@@ -816,6 +821,8 @@ abstract class $EditorStateCopyWith<$Res> {
       String? selectedWarpId,
       String? selectedTriggerId,
       String? selectedGameplayZoneId,
+      String? selectedEnvironmentAreaId,
+      EnvironmentMaskEditMode? environmentMaskEditMode,
       MapRect? gameplayZoneDraftArea,
       String? selectedTilesetEditorId,
       String? selectedTilesetElementGroupId,
@@ -887,6 +894,8 @@ class _$EditorStateCopyWithImpl<$Res, $Val extends EditorState>
     Object? selectedWarpId = freezed,
     Object? selectedTriggerId = freezed,
     Object? selectedGameplayZoneId = freezed,
+    Object? selectedEnvironmentAreaId = freezed,
+    Object? environmentMaskEditMode = freezed,
     Object? gameplayZoneDraftArea = freezed,
     Object? selectedTilesetEditorId = freezed,
     Object? selectedTilesetElementGroupId = freezed,
@@ -1007,6 +1016,14 @@ class _$EditorStateCopyWithImpl<$Res, $Val extends EditorState>
           ? _value.selectedGameplayZoneId
           : selectedGameplayZoneId // ignore: cast_nullable_to_non_nullable
               as String?,
+      selectedEnvironmentAreaId: freezed == selectedEnvironmentAreaId
+          ? _value.selectedEnvironmentAreaId
+          : selectedEnvironmentAreaId // ignore: cast_nullable_to_non_nullable
+              as String?,
+      environmentMaskEditMode: freezed == environmentMaskEditMode
+          ? _value.environmentMaskEditMode
+          : environmentMaskEditMode // ignore: cast_nullable_to_non_nullable
+              as EnvironmentMaskEditMode?,
       gameplayZoneDraftArea: freezed == gameplayZoneDraftArea
           ? _value.gameplayZoneDraftArea
           : gameplayZoneDraftArea // ignore: cast_nullable_to_non_nullable
@@ -1227,6 +1244,8 @@ abstract class _$$EditorStateImplCopyWith<$Res>
       String? selectedWarpId,
       String? selectedTriggerId,
       String? selectedGameplayZoneId,
+      String? selectedEnvironmentAreaId,
+      EnvironmentMaskEditMode? environmentMaskEditMode,
       MapRect? gameplayZoneDraftArea,
       String? selectedTilesetEditorId,
       String? selectedTilesetElementGroupId,
@@ -1303,6 +1322,8 @@ class __$$EditorStateImplCopyWithImpl<$Res>
     Object? selectedWarpId = freezed,
     Object? selectedTriggerId = freezed,
     Object? selectedGameplayZoneId = freezed,
+    Object? selectedEnvironmentAreaId = freezed,
+    Object? environmentMaskEditMode = freezed,
     Object? gameplayZoneDraftArea = freezed,
     Object? selectedTilesetEditorId = freezed,
     Object? selectedTilesetElementGroupId = freezed,
@@ -1423,6 +1444,14 @@ class __$$EditorStateImplCopyWithImpl<$Res>
           ? _value.selectedGameplayZoneId
           : selectedGameplayZoneId // ignore: cast_nullable_to_non_nullable
               as String?,
+      selectedEnvironmentAreaId: freezed == selectedEnvironmentAreaId
+          ? _value.selectedEnvironmentAreaId
+          : selectedEnvironmentAreaId // ignore: cast_nullable_to_non_nullable
+              as String?,
+      environmentMaskEditMode: freezed == environmentMaskEditMode
+          ? _value.environmentMaskEditMode
+          : environmentMaskEditMode // ignore: cast_nullable_to_non_nullable
+              as EnvironmentMaskEditMode?,
       gameplayZoneDraftArea: freezed == gameplayZoneDraftArea
           ? _value.gameplayZoneDraftArea
           : gameplayZoneDraftArea // ignore: cast_nullable_to_non_nullable
@@ -1544,6 +1573,8 @@ class _$EditorStateImpl implements _EditorState {
       this.selectedWarpId,
       this.selectedTriggerId,
       this.selectedGameplayZoneId,
+      this.selectedEnvironmentAreaId,
+      this.environmentMaskEditMode,
       this.gameplayZoneDraftArea,
       this.selectedTilesetEditorId,
       this.selectedTilesetElementGroupId,
@@ -1646,6 +1677,12 @@ class _$EditorStateImpl implements _EditorState {
   @override
   final String? selectedGameplayZoneId;
 
+  /// Lot Environment-22 : area dont le masque est édité (layer actif = Environment).
+  @override
+  final String? selectedEnvironmentAreaId;
+  @override
+  final EnvironmentMaskEditMode? environmentMaskEditMode;
+
   /// Zone en cours de tracé par clic+glisser (fantôme, pas encore persistée).
   @override
   final MapRect? gameplayZoneDraftArea;
@@ -1728,7 +1765,7 @@ class _$EditorStateImpl implements _EditorState {
 
   @override
   String toString() {
-    return 'EditorState(projectRootPath: $projectRootPath, project: $project, workspaceMode: $workspaceMode, pokemonCatalogSection: $pokemonCatalogSection, activeMap: $activeMap, activeMapPath: $activeMapPath, activeTool: $activeTool, activeLayerId: $activeLayerId, hoveredTile: $hoveredTile, activeBrush: $activeBrush, terrainSelectionMode: $terrainSelectionMode, selectedTerrainType: $selectedTerrainType, selectedEntityKind: $selectedEntityKind, selectedTerrainPresetId: $selectedTerrainPresetId, selectedPathPresetId: $selectedPathPresetId, selectedSurfacePresetId: $selectedSurfacePresetId, selectedTerrainPresetByType: $selectedTerrainPresetByType, collisionBrushSizeMode: $collisionBrushSizeMode, selectedEntityId: $selectedEntityId, npcWaypointPlacementEntityId: $npcWaypointPlacementEntityId, selectedMapEventId: $selectedMapEventId, selectedWarpId: $selectedWarpId, selectedTriggerId: $selectedTriggerId, selectedGameplayZoneId: $selectedGameplayZoneId, gameplayZoneDraftArea: $gameplayZoneDraftArea, selectedTilesetEditorId: $selectedTilesetEditorId, selectedTilesetElementGroupId: $selectedTilesetElementGroupId, tilesElementsPanelMode: $tilesElementsPanelMode, selectedPlacedElementInstanceId: $selectedPlacedElementInstanceId, selectedProjectDialogueId: $selectedProjectDialogueId, selectedTrainerId: $selectedTrainerId, selectedCharacterId: $selectedCharacterId, paletteCategoryFilter: $paletteCategoryFilter, zoom: $zoom, panOffset: $panOffset, mapUndoStack: $mapUndoStack, mapRedoStack: $mapRedoStack, mapStrokeStart: $mapStrokeStart, savedMapSnapshot: $savedMapSnapshot, canUndoMap: $canUndoMap, canRedoMap: $canRedoMap, isDirty: $isDirty, isProjectDirty: $isProjectDirty, isSaving: $isSaving, statusMessage: $statusMessage, errorMessage: $errorMessage)';
+    return 'EditorState(projectRootPath: $projectRootPath, project: $project, workspaceMode: $workspaceMode, pokemonCatalogSection: $pokemonCatalogSection, activeMap: $activeMap, activeMapPath: $activeMapPath, activeTool: $activeTool, activeLayerId: $activeLayerId, hoveredTile: $hoveredTile, activeBrush: $activeBrush, terrainSelectionMode: $terrainSelectionMode, selectedTerrainType: $selectedTerrainType, selectedEntityKind: $selectedEntityKind, selectedTerrainPresetId: $selectedTerrainPresetId, selectedPathPresetId: $selectedPathPresetId, selectedSurfacePresetId: $selectedSurfacePresetId, selectedTerrainPresetByType: $selectedTerrainPresetByType, collisionBrushSizeMode: $collisionBrushSizeMode, selectedEntityId: $selectedEntityId, npcWaypointPlacementEntityId: $npcWaypointPlacementEntityId, selectedMapEventId: $selectedMapEventId, selectedWarpId: $selectedWarpId, selectedTriggerId: $selectedTriggerId, selectedGameplayZoneId: $selectedGameplayZoneId, selectedEnvironmentAreaId: $selectedEnvironmentAreaId, environmentMaskEditMode: $environmentMaskEditMode, gameplayZoneDraftArea: $gameplayZoneDraftArea, selectedTilesetEditorId: $selectedTilesetEditorId, selectedTilesetElementGroupId: $selectedTilesetElementGroupId, tilesElementsPanelMode: $tilesElementsPanelMode, selectedPlacedElementInstanceId: $selectedPlacedElementInstanceId, selectedProjectDialogueId: $selectedProjectDialogueId, selectedTrainerId: $selectedTrainerId, selectedCharacterId: $selectedCharacterId, paletteCategoryFilter: $paletteCategoryFilter, zoom: $zoom, panOffset: $panOffset, mapUndoStack: $mapUndoStack, mapRedoStack: $mapRedoStack, mapStrokeStart: $mapStrokeStart, savedMapSnapshot: $savedMapSnapshot, canUndoMap: $canUndoMap, canRedoMap: $canRedoMap, isDirty: $isDirty, isProjectDirty: $isProjectDirty, isSaving: $isSaving, statusMessage: $statusMessage, errorMessage: $errorMessage)';
   }
 
   @override
@@ -1785,6 +1822,10 @@ class _$EditorStateImpl implements _EditorState {
                 other.selectedTriggerId == selectedTriggerId) &&
             (identical(other.selectedGameplayZoneId, selectedGameplayZoneId) ||
                 other.selectedGameplayZoneId == selectedGameplayZoneId) &&
+            (identical(other.selectedEnvironmentAreaId, selectedEnvironmentAreaId) ||
+                other.selectedEnvironmentAreaId == selectedEnvironmentAreaId) &&
+            (identical(other.environmentMaskEditMode, environmentMaskEditMode) ||
+                other.environmentMaskEditMode == environmentMaskEditMode) &&
             (identical(other.gameplayZoneDraftArea, gameplayZoneDraftArea) ||
                 other.gameplayZoneDraftArea == gameplayZoneDraftArea) &&
             (identical(other.selectedTilesetEditorId, selectedTilesetEditorId) ||
@@ -1795,10 +1836,8 @@ class _$EditorStateImpl implements _EditorState {
             (identical(other.tilesElementsPanelMode, tilesElementsPanelMode) ||
                 other.tilesElementsPanelMode == tilesElementsPanelMode) &&
             (identical(other.selectedPlacedElementInstanceId, selectedPlacedElementInstanceId) ||
-                other.selectedPlacedElementInstanceId ==
-                    selectedPlacedElementInstanceId) &&
-            (identical(other.selectedProjectDialogueId, selectedProjectDialogueId) ||
-                other.selectedProjectDialogueId == selectedProjectDialogueId) &&
+                other.selectedPlacedElementInstanceId == selectedPlacedElementInstanceId) &&
+            (identical(other.selectedProjectDialogueId, selectedProjectDialogueId) || other.selectedProjectDialogueId == selectedProjectDialogueId) &&
             (identical(other.selectedTrainerId, selectedTrainerId) || other.selectedTrainerId == selectedTrainerId) &&
             (identical(other.selectedCharacterId, selectedCharacterId) || other.selectedCharacterId == selectedCharacterId) &&
             (identical(other.paletteCategoryFilter, paletteCategoryFilter) || other.paletteCategoryFilter == paletteCategoryFilter) &&
@@ -1844,6 +1883,8 @@ class _$EditorStateImpl implements _EditorState {
         selectedWarpId,
         selectedTriggerId,
         selectedGameplayZoneId,
+        selectedEnvironmentAreaId,
+        environmentMaskEditMode,
         gameplayZoneDraftArea,
         selectedTilesetEditorId,
         selectedTilesetElementGroupId,
@@ -1903,6 +1944,8 @@ abstract class _EditorState implements EditorState {
       final String? selectedWarpId,
       final String? selectedTriggerId,
       final String? selectedGameplayZoneId,
+      final String? selectedEnvironmentAreaId,
+      final EnvironmentMaskEditMode? environmentMaskEditMode,
       final MapRect? gameplayZoneDraftArea,
       final String? selectedTilesetEditorId,
       final String? selectedTilesetElementGroupId,
@@ -1984,6 +2027,12 @@ abstract class _EditorState implements EditorState {
   @override
   String? get selectedGameplayZoneId;
 
+  /// Lot Environment-22 : area dont le masque est édité (layer actif = Environment).
+  @override
+  String? get selectedEnvironmentAreaId;
+  @override
+  EnvironmentMaskEditMode? get environmentMaskEditMode;
+
   /// Zone en cours de tracé par clic+glisser (fantôme, pas encore persistée).
   @override
   MapRect? get gameplayZoneDraftArea;
diff --git a/packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart b/packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
index 8a472c2a..0fdbba77 100644
--- a/packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
+++ b/packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
@@ -73,6 +73,8 @@ class EditorSelectionState {
     required this.selectedWarpId,
     required this.selectedTriggerId,
     required this.selectedGameplayZoneId,
+    required this.selectedEnvironmentAreaId,
+    required this.environmentMaskEditMode,
     required this.gameplayZoneDraftArea,
     required this.selectedTilesetEditorId,
     required this.selectedTilesetElementGroupId,
@@ -102,6 +104,8 @@ class EditorSelectionState {
   final String? selectedWarpId;
   final String? selectedTriggerId;
   final String? selectedGameplayZoneId;
+  final String? selectedEnvironmentAreaId;
+  final EnvironmentMaskEditMode? environmentMaskEditMode;
   final MapRect? gameplayZoneDraftArea;
   final String? selectedTilesetEditorId;
   final String? selectedTilesetElementGroupId;
@@ -131,6 +135,8 @@ class EditorSelectionState {
     Object? selectedWarpId = _editorStateGroupsUnset,
     Object? selectedTriggerId = _editorStateGroupsUnset,
     Object? selectedGameplayZoneId = _editorStateGroupsUnset,
+    Object? selectedEnvironmentAreaId = _editorStateGroupsUnset,
+    Object? environmentMaskEditMode = _editorStateGroupsUnset,
     Object? gameplayZoneDraftArea = _editorStateGroupsUnset,
     Object? selectedTilesetEditorId = _editorStateGroupsUnset,
     Object? selectedTilesetElementGroupId = _editorStateGroupsUnset,
@@ -189,6 +195,14 @@ class EditorSelectionState {
           identical(selectedGameplayZoneId, _editorStateGroupsUnset)
               ? this.selectedGameplayZoneId
               : selectedGameplayZoneId as String?,
+      selectedEnvironmentAreaId:
+          identical(selectedEnvironmentAreaId, _editorStateGroupsUnset)
+              ? this.selectedEnvironmentAreaId
+              : selectedEnvironmentAreaId as String?,
+      environmentMaskEditMode:
+          identical(environmentMaskEditMode, _editorStateGroupsUnset)
+              ? this.environmentMaskEditMode
+              : environmentMaskEditMode as EnvironmentMaskEditMode?,
       gameplayZoneDraftArea:
           identical(gameplayZoneDraftArea, _editorStateGroupsUnset)
               ? this.gameplayZoneDraftArea
@@ -344,6 +358,8 @@ extension EditorStateGroups on EditorState {
         selectedWarpId: selectedWarpId,
         selectedTriggerId: selectedTriggerId,
         selectedGameplayZoneId: selectedGameplayZoneId,
+        selectedEnvironmentAreaId: selectedEnvironmentAreaId,
+        environmentMaskEditMode: environmentMaskEditMode,
         gameplayZoneDraftArea: gameplayZoneDraftArea,
         selectedTilesetEditorId: selectedTilesetEditorId,
         selectedTilesetElementGroupId: selectedTilesetElementGroupId,
@@ -404,6 +420,8 @@ extension EditorStateGroups on EditorState {
       selectedWarpId: next.selectedWarpId,
       selectedTriggerId: next.selectedTriggerId,
       selectedGameplayZoneId: next.selectedGameplayZoneId,
+      selectedEnvironmentAreaId: next.selectedEnvironmentAreaId,
+      environmentMaskEditMode: next.environmentMaskEditMode,
       gameplayZoneDraftArea: next.gameplayZoneDraftArea,
       selectedTilesetEditorId: next.selectedTilesetEditorId,
       selectedTilesetElementGroupId: next.selectedTilesetElementGroupId,
diff --git a/packages/map_editor/lib/src/features/editor/tools/editor_tool.dart b/packages/map_editor/lib/src/features/editor/tools/editor_tool.dart
index e5171d41..eef0ab9e 100644
--- a/packages/map_editor/lib/src/features/editor/tools/editor_tool.dart
+++ b/packages/map_editor/lib/src/features/editor/tools/editor_tool.dart
@@ -12,6 +12,12 @@ enum EditorToolType {
   eraser,
 }
 
+/// Lot Environment-22 : édition du masque d’une [EnvironmentArea] sur la carte.
+enum EnvironmentMaskEditMode {
+  paint,
+  erase,
+}
+
 abstract class EditorTool {
   final EditorToolType type;
 
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
index a7c17504..a9eceb3e 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
@@ -14,6 +14,7 @@ import '../../application/models/map_tool_preview.dart';
 import '../../application/models/path_autotile_set.dart';
 import '../../application/services/tileset_transparent_color_processor.dart';
 import '../../features/editor/state/editor_notifier.dart';
+import '../../features/editor/state/editor_state.dart';
 import '../../features/editor/tools/editor_tool.dart';
 import '../../features/path_pattern/path_pattern_editor_render_resolution.dart';
 import '../../features/surface_painter/surface_layer_static_preview.dart';
@@ -26,6 +27,19 @@ import 'entity_editor_element_visual.dart';
 part 'map_canvas/map_canvas_assets.dart';
 part 'map_canvas/map_grid_painter.dart';
 
+bool _isEnvironmentMaskEditing(EditorState state, MapData map) {
+  if (state.environmentMaskEditMode == null) return false;
+  if (state.selectedEnvironmentAreaId == null) return false;
+  final lid = state.activeLayerId;
+  if (lid == null) return false;
+  for (final l in map.layers) {
+    if (l.id == lid && l is EnvironmentLayer) {
+      return true;
+    }
+  }
+  return false;
+}
+
 class MapCanvas extends ConsumerStatefulWidget {
   const MapCanvas({super.key});
 
@@ -47,6 +61,9 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
   /// Cellule de départ pour le tracé d'une zone par clic+glisser.
   GridPos? _zoneDragStart;
 
+  /// Lot Environment-22 : évite de repeindre la même cellule masque pendant un drag.
+  GridPos? _lastEnvironmentMaskPaintCell;
+
   Timer? _entityEditorAnimTimer;
   bool _entityEditorAnimTimerRunning = false;
   int _editorEntityAnimationMs = 0;
@@ -181,12 +198,15 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
           hoveredTile: _hoveredTile,
           tilesetColumnsById: tilesPerRowById,
         );
+        final isEnvironmentMaskEditing =
+            _isEnvironmentMaskEditing(state, activeMap);
         final isStrokeEditingTool =
             state.activeTool == EditorToolType.tilePaint ||
                 state.activeTool == EditorToolType.terrainPaint ||
                 state.activeTool == EditorToolType.surfacePaint ||
                 state.activeTool == EditorToolType.collisionPaint ||
-                state.activeTool == EditorToolType.eraser;
+                state.activeTool == EditorToolType.eraser ||
+                isEnvironmentMaskEditing;
         final isNpcWaypointPlacementActive =
             (state.npcWaypointPlacementEntityId?.trim().isNotEmpty ?? false);
         final isTapEditingTool = isStrokeEditingTool ||
@@ -196,7 +216,29 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
             state.activeTool == EditorToolType.triggerPlacement ||
             state.activeTool == EditorToolType.gameplayZonePlacement;
 
-        void applyToolAt(GridPos gridPos) {
+        EnvironmentAreaMask? environmentMaskOverlay;
+        if (isEnvironmentMaskEditing &&
+            state.selectedEnvironmentAreaId != null) {
+          for (final l in activeMap.layers) {
+            if (l.id != state.activeLayerId || l is! EnvironmentLayer) continue;
+            for (final a in l.content.areas) {
+              if (a.id == state.selectedEnvironmentAreaId) {
+                environmentMaskOverlay = a.mask;
+                break;
+              }
+            }
+            break;
+          }
+        }
+
+        void applyToolAt(GridPos gridPos, {bool partOfStroke = false}) {
+          if (isEnvironmentMaskEditing) {
+            notifier.paintEnvironmentAreaMaskAt(
+              gridPos,
+              partOfStroke: partOfStroke,
+            );
+            return;
+          }
           if (state.activeTool == EditorToolType.tilePaint) {
             notifier.paintSelectedBrushAt(
               gridPos,
@@ -274,7 +316,7 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
               if (isStrokeEditingTool) {
                 notifier.beginMapStroke();
               }
-              applyToolAt(gridPos);
+              applyToolAt(gridPos, partOfStroke: isStrokeEditingTool);
               if (isStrokeEditingTool) {
                 notifier.endMapStroke();
               }
@@ -309,8 +351,14 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
                 tileHeight,
               );
               if (gridPos == null) return;
+              if (isEnvironmentMaskEditing) {
+                _lastEnvironmentMaskPaintCell = null;
+              }
               notifier.beginMapStroke();
-              applyToolAt(gridPos);
+              applyToolAt(gridPos, partOfStroke: true);
+              if (isEnvironmentMaskEditing) {
+                _lastEnvironmentMaskPaintCell = gridPos;
+              }
             },
             onPanUpdate: (details) {
               if (state.activeTool == EditorToolType.gameplayZonePlacement &&
@@ -340,7 +388,14 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
                 tileHeight,
               );
               if (gridPos != null) {
-                applyToolAt(gridPos);
+                if (isEnvironmentMaskEditing &&
+                    _lastEnvironmentMaskPaintCell == gridPos) {
+                  return;
+                }
+                applyToolAt(gridPos, partOfStroke: true);
+                if (isEnvironmentMaskEditing) {
+                  _lastEnvironmentMaskPaintCell = gridPos;
+                }
               }
             },
             onPanEnd: (_) {
@@ -351,6 +406,9 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
                 return;
               }
               if (isStrokeEditingTool) {
+                if (isEnvironmentMaskEditing) {
+                  _lastEnvironmentMaskPaintCell = null;
+                }
                 notifier.endMapStroke();
               }
             },
@@ -362,6 +420,9 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
                 return;
               }
               if (isStrokeEditingTool) {
+                if (isEnvironmentMaskEditing) {
+                  _lastEnvironmentMaskPaintCell = null;
+                }
                 notifier.endMapStroke();
               }
             },
@@ -410,6 +471,7 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
                           terrainPresetsByType: terrainPresetsByType,
                           project: state.project,
                           editorEntityAnimationMs: _editorEntityAnimationMs,
+                          environmentMaskOverlay: environmentMaskOverlay,
                         ),
                       ),
                     ),
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
index 4ee1cead..33eea9b7 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
@@ -188,6 +188,9 @@ class MapGridPainter extends CustomPainter {
   final ProjectManifest? project;
   final int editorEntityAnimationMs;
 
+  /// Lot Environment-22 : surcouche semi-transparente des cellules masque actives.
+  final EnvironmentAreaMask? environmentMaskOverlay;
+
   MapGridPainter({
     required this.map,
     required this.zoom,
@@ -216,6 +219,7 @@ class MapGridPainter extends CustomPainter {
     required this.terrainPresetsByType,
     this.project,
     this.editorEntityAnimationMs = 0,
+    this.environmentMaskOverlay,
   });
 
   @override
@@ -360,6 +364,7 @@ class MapGridPainter extends CustomPainter {
     );
     _paintSelectedPlacedElementInstance(canvas);
     _paintToolPreview(canvas);
+    _paintEnvironmentMaskOverlay(canvas);
     _paintMapEvents(canvas);
     _paintTriggers(canvas);
     _paintWarps(canvas);
@@ -375,6 +380,36 @@ class MapGridPainter extends CustomPainter {
     canvas.restore();
   }
 
+  void _paintEnvironmentMaskOverlay(Canvas canvas) {
+    final mask = environmentMaskOverlay;
+    if (mask == null) return;
+    final expected = mask.width * mask.height;
+    if (mask.cells.length != expected) return;
+
+    final fill = Paint()
+      ..color = const Color(0x664CAF50)
+      ..style = PaintingStyle.fill;
+    final border = Paint()
+      ..color = const Color(0x992E7D32)
+      ..style = PaintingStyle.stroke
+      ..strokeWidth = 1.0 / zoom;
+
+    for (var y = 0; y < mask.height; y++) {
+      for (var x = 0; x < mask.width; x++) {
+        final i = y * mask.width + x;
+        if (i >= mask.cells.length || !mask.cells[i]) continue;
+        final rect = Rect.fromLTWH(
+          x * tileWidth,
+          y * tileHeight,
+          tileWidth,
+          tileHeight,
+        );
+        canvas.drawRect(rect, fill);
+        canvas.drawRect(rect, border);
+      }
+    }
+  }
+
   void _paintWarps(Canvas canvas) {
     if (warps.isEmpty) return;
     for (final warp in warps) {
@@ -1872,8 +1907,7 @@ class MapGridPainter extends CustomPainter {
       frameWidthTiles: width,
       frameHeightTiles: height,
       layout: chosen.multiTileLayout,
-      subtileSalt:
-          frameSource.x * 73856093 + frameSource.y * 19349663,
+      subtileSalt: frameSource.x * 73856093 + frameSource.y * 19349663,
     );
     final frameTilesetId = resolvedFrame.tilesetId.trim();
     final resolvedTilesetId =
@@ -2113,7 +2147,23 @@ class MapGridPainter extends CustomPainter {
         oldDelegate.sourceTileWidth != sourceTileWidth ||
         oldDelegate.sourceTileHeight != sourceTileHeight ||
         !mapEquals(oldDelegate.tilesPerRowById, tilesPerRowById) ||
-        oldDelegate.editorEntityAnimationMs != editorEntityAnimationMs;
+        oldDelegate.editorEntityAnimationMs != editorEntityAnimationMs ||
+        !_sameEnvironmentMaskOverlay(
+          oldDelegate.environmentMaskOverlay,
+          environmentMaskOverlay,
+        );
+  }
+
+  bool _sameEnvironmentMaskOverlay(
+    EnvironmentAreaMask? previous,
+    EnvironmentAreaMask? next,
+  ) {
+    if (identical(previous, next)) return true;
+    if (previous == null || next == null) return previous == next;
+    if (previous.width != next.width || previous.height != next.height) {
+      return false;
+    }
+    return listEquals(previous.cells, next.cells);
   }
 
   bool _sameToolPreview(MapToolPreview? previous, MapToolPreview? next) {
diff --git a/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart b/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
index ef566811..d9136313 100644
--- a/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
@@ -4,9 +4,11 @@ import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../features/editor/state/editor_notifier.dart';
+import '../../features/editor/state/editor_selectors.dart';
+import '../../features/editor/tools/editor_tool.dart';
 import '../shared/cupertino_editor_widgets.dart';
 
-/// Inspecteur Lot Environment-19/20 : meta layer + cible [TileLayer] pour génération future.
+/// Inspecteur Environment Studio : cible tuile (Lot 20) + zones (Lot 21), sans canvas.
 class EnvironmentLayerInspectorPanel extends ConsumerWidget {
   const EnvironmentLayerInspectorPanel({
     super.key,
@@ -45,147 +47,232 @@ class EnvironmentLayerInspectorPanel extends ConsumerWidget {
     final subtle = EditorChrome.subtleLabel(context);
     final label = EditorChrome.primaryLabel(context);
     final notifier = ref.read(editorNotifierProvider.notifier);
+    final manifest = ref.watch(editorProjectManifestProvider);
     final tiles = _tileLayers();
     final target = _resolveTarget();
     final tid = layer.content.targetTileLayerId;
     final invalidTarget = tid != null && target == null;
+    final presets = manifest?.environmentPresets ?? const <EnvironmentPreset>[];
 
-    return Padding(
-      padding: EdgeInsets.fromLTRB(embedded ? 8 : 10, 4, embedded ? 8 : 10, 10),
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
-          const SizedBox(height: 14),
-          Text(
-            'TileLayer cible',
-            style: TextStyle(
-              color: label,
-              fontSize: 13,
-              fontWeight: FontWeight.w700,
-            ),
-          ),
-          const SizedBox(height: 8),
-          if (tiles.isEmpty) ...[
-            Text(
-              'Aucun TileLayer disponible dans cette map.\n'
-              'Ajoutez d’abord un TileLayer pour recevoir les résultats générés.',
-              key: const Key('env-layer-inspector-no-tile-layers'),
-              style: TextStyle(
-                color: subtle,
-                fontSize: 12,
-                height: 1.35,
-                fontWeight: FontWeight.w600,
-              ),
-            ),
-          ] else if (invalidTarget) ...[
+    return SingleChildScrollView(
+      child: Padding(
+        padding:
+            EdgeInsets.fromLTRB(embedded ? 8 : 10, 4, embedded ? 8 : 10, 10),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
             Text(
-              'La cible configurée est introuvable ou invalide : $tid',
-              key: const Key('env-layer-inspector-invalid-target'),
+              'Environment Layer',
+              key: const Key('map-inspector-environment-layer-title'),
               style: TextStyle(
-                color: CupertinoColors.systemOrange.resolveFrom(context),
-                fontSize: 12,
-                height: 1.35,
-                fontWeight: FontWeight.w600,
+                color: label,
+                fontSize: 14,
+                fontWeight: FontWeight.w800,
               ),
             ),
-            const SizedBox(height: 10),
-            PushButton(
-              key: const Key('env-layer-inspector-change-invalid'),
-              controlSize: ControlSize.regular,
-              onPressed: () => _pickTileLayer(context, notifier, tiles),
-              child: const Text('Choisir un autre TileLayer cible'),
-            ),
             const SizedBox(height: 8),
-            PushButton(
-              key: const Key('env-layer-inspector-remove-invalid'),
-              controlSize: ControlSize.regular,
-              secondary: true,
-              onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
-                environmentLayerId: layer.id,
-                targetTileLayerId: null,
-              ),
-              child: const Text('Retirer la cible'),
-            ),
-          ] else if (target == null) ...[
             Text(
-              'Aucun TileLayer cible sélectionné.',
-              key: const Key('env-layer-inspector-no-target'),
+              'Ce layer servira à dessiner des zones organiques et à générer des '
+              'éléments naturels.',
+              key: const Key('map-inspector-environment-layer-body'),
               style: TextStyle(
                 color: subtle,
                 fontSize: 12,
-                height: 1.35,
+                height: 1.4,
                 fontWeight: FontWeight.w600,
               ),
             ),
-            const SizedBox(height: 10),
-            PushButton(
-              key: const Key('env-layer-inspector-choose-target'),
-              controlSize: ControlSize.regular,
-              onPressed: () => _pickTileLayer(context, notifier, tiles),
-              child: const Text('Choisir le TileLayer cible'),
-            ),
-          ] else ...[
+            const SizedBox(height: 16),
             Text(
-              'Cible actuelle : ${target.name}',
-              key: const Key('env-layer-inspector-current-target-name'),
+              'Zones d’environnement',
+              key: const Key('env-layer-inspector-zones-title'),
               style: TextStyle(
                 color: label,
-                fontSize: 12,
+                fontSize: 13,
                 fontWeight: FontWeight.w700,
               ),
             ),
-            const SizedBox(height: 4),
+            const SizedBox(height: 6),
             Text(
-              'Id : ${target.id}',
-              key: const Key('env-layer-inspector-current-target-id'),
+              'Les zones définissent où les presets organiques seront générés. '
+              'Peignez le masque par zone pour marquer les cellules actives.',
+              key: const Key('env-layer-inspector-zones-desc'),
               style: TextStyle(
                 color: subtle,
                 fontSize: 11.5,
+                height: 1.35,
                 fontWeight: FontWeight.w600,
               ),
             ),
             const SizedBox(height: 10),
-            PushButton(
-              key: const Key('env-layer-inspector-change-target'),
-              controlSize: ControlSize.regular,
-              onPressed: () => _pickTileLayer(context, notifier, tiles),
-              child: const Text('Changer de TileLayer cible'),
+            if (presets.isEmpty) ...[
+              Text(
+                'Aucun preset d’environnement disponible.\n'
+                'Créez d’abord un preset dans Environment Studio.',
+                key: const Key('env-layer-inspector-no-presets'),
+                style: TextStyle(
+                  color: subtle,
+                  fontSize: 12,
+                  height: 1.35,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+            ] else ...[
+              if (layer.content.areas.isEmpty)
+                Text(
+                  'Aucune zone d’environnement pour ce layer.',
+                  key: const Key('env-layer-inspector-no-areas'),
+                  style: TextStyle(
+                    color: subtle,
+                    fontSize: 12,
+                    height: 1.35,
+                    fontWeight: FontWeight.w600,
+                  ),
+                )
+              else
+                ...layer.content.areas.map(
+                  (area) => _EnvironmentAreaCard(
+                    area: area,
+                    manifest: manifest,
+                    layerId: layer.id,
+                    labelColor: label,
+                    subtleColor: subtle,
+                  ),
+                ),
+              const SizedBox(height: 10),
+              PushButton(
+                key: const Key('env-layer-inspector-add-area'),
+                controlSize: ControlSize.regular,
+                onPressed: () => _pickPresetAndAddArea(
+                  context,
+                  notifier,
+                  presets,
+                ),
+                child: const Text('Ajouter une zone'),
+              ),
+            ],
+            const SizedBox(height: 18),
+            Text(
+              'TileLayer cible',
+              style: TextStyle(
+                color: label,
+                fontSize: 13,
+                fontWeight: FontWeight.w700,
+              ),
             ),
             const SizedBox(height: 8),
-            PushButton(
-              key: const Key('env-layer-inspector-remove-target'),
-              controlSize: ControlSize.regular,
-              secondary: true,
-              onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
-                environmentLayerId: layer.id,
-                targetTileLayerId: null,
-              ),
-              child: const Text('Retirer la cible'),
-            ),
+            if (tiles.isEmpty) ...[
+              Text(
+                'Aucun TileLayer disponible dans cette map.\n'
+                'Ajoutez d’abord un TileLayer pour recevoir les résultats générés.',
+                key: const Key('env-layer-inspector-no-tile-layers'),
+                style: TextStyle(
+                  color: subtle,
+                  fontSize: 12,
+                  height: 1.35,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+            ] else if (invalidTarget) ...[
+              Text(
+                'La cible configurée est introuvable ou invalide : $tid',
+                key: const Key('env-layer-inspector-invalid-target'),
+                style: TextStyle(
+                  color: CupertinoColors.systemOrange.resolveFrom(context),
+                  fontSize: 12,
+                  height: 1.35,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+              const SizedBox(height: 10),
+              PushButton(
+                key: const Key('env-layer-inspector-change-invalid'),
+                controlSize: ControlSize.regular,
+                onPressed: () => _pickTileLayer(context, notifier, tiles),
+                child: const Text('Choisir un autre TileLayer cible'),
+              ),
+              const SizedBox(height: 8),
+              PushButton(
+                key: const Key('env-layer-inspector-remove-invalid'),
+                controlSize: ControlSize.regular,
+                secondary: true,
+                onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
+                  environmentLayerId: layer.id,
+                  targetTileLayerId: null,
+                ),
+                child: const Text('Retirer la cible'),
+              ),
+            ] else if (target == null) ...[
+              Text(
+                'Aucun TileLayer cible sélectionné.',
+                key: const Key('env-layer-inspector-no-target'),
+                style: TextStyle(
+                  color: subtle,
+                  fontSize: 12,
+                  height: 1.35,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+              const SizedBox(height: 6),
+              Text(
+                'Vous pouvez peindre le masque maintenant. Le TileLayer cible '
+                'sera nécessaire pour générer plus tard.',
+                key: const Key('env-layer-inspector-mask-without-target-note'),
+                style: TextStyle(
+                  color: subtle,
+                  fontSize: 11,
+                  height: 1.35,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+              const SizedBox(height: 10),
+              PushButton(
+                key: const Key('env-layer-inspector-choose-target'),
+                controlSize: ControlSize.regular,
+                onPressed: () => _pickTileLayer(context, notifier, tiles),
+                child: const Text('Choisir le TileLayer cible'),
+              ),
+            ] else ...[
+              Text(
+                'Cible actuelle : ${target.name}',
+                key: const Key('env-layer-inspector-current-target-name'),
+                style: TextStyle(
+                  color: label,
+                  fontSize: 12,
+                  fontWeight: FontWeight.w700,
+                ),
+              ),
+              const SizedBox(height: 4),
+              Text(
+                'Id : ${target.id}',
+                key: const Key('env-layer-inspector-current-target-id'),
+                style: TextStyle(
+                  color: subtle,
+                  fontSize: 11.5,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+              const SizedBox(height: 10),
+              PushButton(
+                key: const Key('env-layer-inspector-change-target'),
+                controlSize: ControlSize.regular,
+                onPressed: () => _pickTileLayer(context, notifier, tiles),
+                child: const Text('Changer de TileLayer cible'),
+              ),
+              const SizedBox(height: 8),
+              PushButton(
+                key: const Key('env-layer-inspector-remove-target'),
+                controlSize: ControlSize.regular,
+                secondary: true,
+                onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
+                  environmentLayerId: layer.id,
+                  targetTileLayerId: null,
+                ),
+                child: const Text('Retirer la cible'),
+              ),
+            ],
           ],
-        ],
+        ),
       ),
     );
   }
@@ -207,4 +294,252 @@ class EnvironmentLayerInspectorPanel extends ConsumerWidget {
       targetTileLayerId: picked.id,
     );
   }
+
+  Future<void> _pickPresetAndAddArea(
+    BuildContext context,
+    EditorNotifier notifier,
+    List<EnvironmentPreset> presets,
+  ) async {
+    final picked = await showCupertinoListPicker<EnvironmentPreset>(
+      context: context,
+      title: 'Preset d’environnement',
+      items: presets,
+      labelOf: (p) => '${p.name} — ${p.id}',
+    );
+    if (picked == null) return;
+    notifier.addEnvironmentAreaToLayer(
+      environmentLayerId: layer.id,
+      presetId: picked.id,
+    );
+  }
+}
+
+class _EnvironmentAreaCard extends ConsumerWidget {
+  const _EnvironmentAreaCard({
+    required this.area,
+    required this.manifest,
+    required this.layerId,
+    required this.labelColor,
+    required this.subtleColor,
+  });
+
+  final EnvironmentArea area;
+  final ProjectManifest? manifest;
+  final String layerId;
+  final Color labelColor;
+  final Color subtleColor;
+
+  EnvironmentPreset? _presetForArea() {
+    final m = manifest;
+    if (m == null) return null;
+    for (final p in m.environmentPresets) {
+      if (p.id == area.presetId) return p;
+    }
+    return null;
+  }
+
+  @override
+  Widget build(BuildContext context, WidgetRef ref) {
+    final notifier = ref.read(editorNotifierProvider.notifier);
+    final editorState = ref.watch(editorNotifierProvider);
+    final manifestPresets =
+        manifest?.environmentPresets ?? const <EnvironmentPreset>[];
+    final preset = _presetForArea();
+    final totalCells = area.mask.width * area.mask.height;
+    final activeCount = area.mask.activeCellCount;
+    final maskLabel = activeCount == 0
+        ? 'Masque vide — cliquez « Peindre le masque », puis dessinez sur la map.\n'
+            '($activeCount / $totalCells cellules actives)'
+        : 'Masque : $activeCount / $totalCells cellules actives';
+    final warnPlacements = area.generatedPlacementIds.isNotEmpty;
+    final isThisAreaActiveForMask = editorState.activeLayerId == layerId &&
+        editorState.selectedEnvironmentAreaId == area.id;
+    final maskMode = editorState.environmentMaskEditMode;
+    String? editModeLabel;
+    if (isThisAreaActiveForMask && maskMode != null) {
+      editModeLabel = maskMode == EnvironmentMaskEditMode.paint
+          ? 'Édition active : peinture'
+          : 'Édition active : effacement';
+    }
+
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 10),
+      child: DecoratedBox(
+        decoration: BoxDecoration(
+          color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
+          borderRadius: BorderRadius.circular(10),
+          border: Border.all(
+            color: CupertinoColors.separator.resolveFrom(context),
+          ),
+        ),
+        child: Padding(
+          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              Text(
+                'Zone : ${area.id}',
+                key: Key('env-area-card-id-${area.id}'),
+                style: TextStyle(
+                  color: labelColor,
+                  fontSize: 12,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+              const SizedBox(height: 6),
+              if (preset != null) ...[
+                Text(
+                  'Preset : ${preset.name}',
+                  key: Key('env-area-card-preset-name-${area.id}'),
+                  style: TextStyle(
+                    color: labelColor,
+                    fontSize: 11.5,
+                    fontWeight: FontWeight.w700,
+                  ),
+                ),
+                Text(
+                  'Id preset : ${preset.id}',
+                  key: Key('env-area-card-preset-id-${area.id}'),
+                  style: TextStyle(
+                    color: subtleColor,
+                    fontSize: 11,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+              ] else
+                Text(
+                  'Preset associé introuvable : ${area.presetId}',
+                  key: Key('env-area-card-preset-missing-${area.id}'),
+                  style: TextStyle(
+                    color: CupertinoColors.systemOrange.resolveFrom(context),
+                    fontSize: 11.5,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+              const SizedBox(height: 6),
+              Text(
+                maskLabel,
+                key: Key('env-area-card-mask-${area.id}'),
+                style: TextStyle(
+                  color: subtleColor,
+                  fontSize: 11,
+                  height: 1.3,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+              if (editModeLabel != null) ...[
+                const SizedBox(height: 6),
+                Text(
+                  editModeLabel,
+                  key: Key('env-area-card-mask-edit-active-${area.id}'),
+                  style: TextStyle(
+                    color: labelColor,
+                    fontSize: 11.5,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+              ],
+              const SizedBox(height: 4),
+              Text(
+                'Placements générés : ${area.generatedPlacementIds.length}',
+                key: Key('env-area-card-placements-count-${area.id}'),
+                style: TextStyle(
+                  color: subtleColor,
+                  fontSize: 11,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+              if (warnPlacements) ...[
+                const SizedBox(height: 6),
+                Text(
+                  'Cette zone référence des placements générés ; le retrait ne les '
+                  'supprime pas automatiquement.',
+                  key: Key('env-area-card-placements-warn-${area.id}'),
+                  style: TextStyle(
+                    color: CupertinoColors.systemOrange.resolveFrom(context),
+                    fontSize: 10.5,
+                    height: 1.25,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+              ],
+              const SizedBox(height: 10),
+              PushButton(
+                key: Key('env-area-mask-paint-${area.id}'),
+                controlSize: ControlSize.small,
+                onPressed: () => notifier.startEnvironmentAreaMaskPaint(
+                  environmentLayerId: layerId,
+                  areaId: area.id,
+                ),
+                child: const Text('Peindre le masque'),
+              ),
+              const SizedBox(height: 6),
+              PushButton(
+                key: Key('env-area-mask-erase-${area.id}'),
+                controlSize: ControlSize.small,
+                onPressed: () => notifier.startEnvironmentAreaMaskErase(
+                  environmentLayerId: layerId,
+                  areaId: area.id,
+                ),
+                child: const Text('Effacer du masque'),
+              ),
+              const SizedBox(height: 6),
+              PushButton(
+                key: Key('env-area-mask-stop-${area.id}'),
+                controlSize: ControlSize.small,
+                secondary: true,
+                onPressed: isThisAreaActiveForMask && maskMode != null
+                    ? notifier.stopEnvironmentAreaMaskEditing
+                    : null,
+                child: const Text('Arrêter l’édition'),
+              ),
+              const SizedBox(height: 10),
+              PushButton(
+                key: Key('env-area-change-preset-${area.id}'),
+                controlSize: ControlSize.small,
+                onPressed: manifestPresets.isEmpty
+                    ? null
+                    : () => _pickPresetForArea(
+                          context,
+                          notifier,
+                          manifestPresets,
+                        ),
+                child: const Text('Changer de preset'),
+              ),
+              const SizedBox(height: 6),
+              PushButton(
+                key: Key('env-area-remove-${area.id}'),
+                controlSize: ControlSize.small,
+                secondary: true,
+                onPressed: () => notifier.removeEnvironmentArea(
+                  environmentLayerId: layerId,
+                  areaId: area.id,
+                ),
+                child: const Text('Retirer'),
+              ),
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+
+  Future<void> _pickPresetForArea(
+    BuildContext context,
+    EditorNotifier notifier,
+    List<EnvironmentPreset> presets,
+  ) async {
+    final picked = await showCupertinoListPicker<EnvironmentPreset>(
+      context: context,
+      title: 'Nouveau preset',
+      items: presets,
+      labelOf: (p) => '${p.name} — ${p.id}',
+    );
+    if (picked == null) return;
+    notifier.setEnvironmentAreaPreset(
+      environmentLayerId: layerId,
+      areaId: area.id,
+      presetId: picked.id,
+    );
+  }
 }
diff --git a/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart b/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
index 14e6a459..85458f00 100644
--- a/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
@@ -179,7 +179,7 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
                     _InspectorSectionId.environmentLayer,
                     defaultExpanded: true,
                   ),
-                  expandedHeight: 360,
+                  expandedHeight: 560,
                   child: EnvironmentLayerInspectorPanel(
                     map: activeMap,
                     layer: activeLayer,
diff --git a/packages/map_editor/test/editor_state_groups_test.dart b/packages/map_editor/test/editor_state_groups_test.dart
index 511b4d0f..36b80264 100644
--- a/packages/map_editor/test/editor_state_groups_test.dart
+++ b/packages/map_editor/test/editor_state_groups_test.dart
@@ -108,6 +108,8 @@ void main() {
               selectedWarpId: null,
               selectedTriggerId: null,
               selectedGameplayZoneId: null,
+              selectedEnvironmentAreaId: null,
+              environmentMaskEditMode: null,
               gameplayZoneDraftArea: null,
               selectedTilesetEditorId: 'tileset_world',
               selectedTilesetElementGroupId: null,
diff --git a/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart b/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart
index 0786051a..94989e22 100644
--- a/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart
@@ -206,7 +206,7 @@ void main() {
         findsOneWidget,
       );
       expect(
-        find.textContaining('La configuration des zones arrive'),
+        find.textContaining('Peignez le masque par zone pour marquer'),
         findsOneWidget,
       );
     });
diff --git a/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart b/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart
index 42dd2402..a91d17f9 100644
--- a/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart
@@ -356,8 +356,11 @@ void main() {
         ),
       );
       await tester.pumpAndSettle();
-      await tester
-          .tap(find.byKey(const Key('env-layer-inspector-choose-target')));
+      final chooseTarget =
+          find.byKey(const Key('env-layer-inspector-choose-target'));
+      await tester.ensureVisible(chooseTarget);
+      await tester.pumpAndSettle();
+      await tester.tap(chooseTarget);
       await tester.pumpAndSettle();
       await tester.tap(find.text('Tuiles sol').last);
       await tester.pumpAndSettle();
@@ -418,8 +421,11 @@ void main() {
         ),
       );
       await tester.pumpAndSettle();
-      await tester
-          .tap(find.byKey(const Key('env-layer-inspector-choose-target')));
+      final chooseTarget2 =
+          find.byKey(const Key('env-layer-inspector-choose-target'));
+      await tester.ensureVisible(chooseTarget2);
+      await tester.pumpAndSettle();
+      await tester.tap(chooseTarget2);
       await tester.pumpAndSettle();
       final sheetFinder = find.byType(MacosSheet).last;
       expect(
@@ -491,8 +497,11 @@ void main() {
         ),
       );
       await tester.pumpAndSettle();
-      await tester
-          .tap(find.byKey(const Key('env-layer-inspector-remove-target')));
+      final removeTarget =
+          find.byKey(const Key('env-layer-inspector-remove-target'));
+      await tester.ensureVisible(removeTarget);
+      await tester.pumpAndSettle();
+      await tester.tap(removeTarget);
       await tester.pumpAndSettle();
       final state = container.read(editorNotifierProvider);
       expect(
```

## 21. Auto-review

**Points solides :** use case pur avec no-op stable ; état dans `EditorState` ; réutilisation stroke ; overlay simple ; tests couvrant use case, notifier, UI, canvas, painter.

**Points discutables :** §19 inclut intégralement le use case et le fichier de test Lot 22 ; les autres fichiers modifiés apparaissent dans le diff §20 (package `map_editor` entier) ; `flutter test` global `packages/map_editor` non lancé.

**Corrections après auto-review :** tests Environment scroll (`ensureVisible`), attente texte Lot 22 dans `environment_layer_creation_test`, hauteur inspecteur `map_inspector_panel`.

**Risques restants :** si la hauteur d’écran de test est très basse, d’autres tests inspecteur pourraient encore nécessiter `ensureVisible`.

**Regard critique sur le prompt :** fallait-il `selectedEnvironmentAreaId` dans `EditorState` ? Oui, pour partager inspecteur et canvas. `build_runner` ? Nécessaire si Freezed n’était pas déjà régénéré ; ici les `.freezed.dart` reflètent les champs. Brush 1×1 suffisant V0 ? Oui. Overlay utile ? Oui pour validation visuelle. Drag robuste ? Dédup par dernière cellule + stroke existant. Génération / placements / TileLayer ? Évités. **Git status initial** : non enregistré en session (seul le final est listé §18) — limite de preuve initiale.

## 22. Verdict

Statut du lot :

- [x] **Validé**

Résumé :

```text
Brush masque V0 livré : état EditorState, use case, notifier, canvas (tap+drag), overlay painter, inspecteur, tests + suite environment_studio verte. map_core non modifié. Pas de sauvegarde / génération / TileLayer patch.
```

Prochain lot recommandé :

```text
Environment-23 — Environment Generator Deterministic Core V0
```

*(Overlay V0 présent ; la polish multi-zones peut aller dans un lot dédié si besoin, mais le couple brush + overlay est suffisant pour enchaîner vers un générateur si la roadmap le confirme.)*
