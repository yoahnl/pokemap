# Environment Studio Lot 29 — Golden Slice Final Validation / Roadmap Cutover

## 1. Résumé exécutif

Audit du Golden Slice Environment (Lots 19–28) sans changement produit : ajout d’un test de validation finale qui verrouille manifest, tuiles, masque, cible, preset, sélection éditeur et cohérence `generatedPlacementIds` sur tout le workflow generate → clear → generate → regenerate → shuffle. Rapport de cutover : Golden Slice **atteint** pour l’éditeur ; suite recommandée **UI-1** (refonte macOS globale) ; pas de lot Environment-30 technique requis d’après cet audit.

## 2. Périmètre du lot

- Inclus : audit fichiers listés §4 du cahier ; renforcement test `environment_golden_slice_workflow_test.dart` ; greps ; commandes §13 ; rapport.
- Exclus : map_core, MapCanvas, EditorState, nouveaux moteurs, refonte UI, build_runner, runtime, sauvegarde disque.
- Fichier `environment_golden_slice_final_validation_test.dart` **non créé** : le test existant a été complété (évite duplication).

## 3. Audit initial Golden Slice complet

Fichiers relus (contrat + flux) :

```text
packages/map_editor/lib/src/application/models/environment_area_generation_readiness.dart
packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart
packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart
packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart
packages/map_editor/lib/src/application/use_cases/environment_generator_regenerate_use_cases.dart
packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart
packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart (méthodes generate/clear/regenerate/shuffle)
packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
packages/map_editor/test/environment_studio/environment_area_generation_readiness_test.dart
packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
… + tests Lots 19–27 listés au cahier Lot 29 §12.3
```

Constat : la stack use cases + notifier + inspecteur est cohérente ; les disabled states sont déjà couverts par `environment_area_generation_readiness_test.dart` ; le seul manque mesurable pour la clôture Lot 29 était la **preuve testée** des invariants données (manifest, `TileLayer.tiles`, masque, ids).

### Greps d’audit (extraits)

```text
$ grep -R "Générer dans la map|Effacer les placements générés|Régénérer|Mélanger et régénérer" -n lib test | head -25
lib/src/ui/panels/environment_layer_inspector_panel.dart:569:                child: const Text('Générer dans la map'),
lib/src/ui/panels/environment_layer_inspector_panel.dart:595:                child: const Text('Effacer les placements générés'),
lib/src/ui/panels/environment_layer_inspector_panel.dart:619:                child: const Text('Régénérer'),
lib/src/ui/panels/environment_layer_inspector_panel.dart:643:                child: const Text('Mélanger et régénérer'),
lib/src/features/editor/state/editor_notifier.dart:4886:            '« Effacer les placements générés », « Régénérer » ou '
lib/src/application/models/environment_area_generation_readiness.dart:86:            '« Effacer les placements générés », « Régénérer » ou '

$ grep -R "generatedPlacementIds" -n ../map_core/lib lib test | wc -l
     108

$ grep -R "MapPlacedElement(" -n ../map_core/lib lib test | wc -l
      26
```

## 4. État fonctionnel validé

| Exigence produit | Statut |
|------------------|--------|
| Preset + Environment layer + TileLayer cible + area + masque + generate | OK (tests + code) |
| Clear / Regenerate / Shuffle | OK |
| Messages disabled / readiness | OK (Lot 28 + tests readiness) |
| Placements manuels protégés | OK (tests + invariant Lot 29) |
| Pas de patch `TileLayer.tiles` | OK (assert liste tuiles) |
| `ProjectManifest` non remplacé en session | OK (`identical` Lot 29) |
| Pas de save disque dans flux | OK (grep + absence dans méthodes) |

## 5. Tests Golden Slice ajoutés ou renforcés

Ajout dans `environment_golden_slice_workflow_test.dart` :

- groupe `Golden Slice — validation finale (Lot 29)` ;
- helpers `_tileLayer`, `_envArea`, `_tilesSnapshot` ;
- `_assertGoldenSliceFinalInvariants` appelé après chaque étape (generate, clear, generate, regenerate, shuffle).

## 6. Disabled states / readiness

Couverture existante (non dupliquée dans ce lot) dans `environment_area_generation_readiness_test.dart` :

- Generate : cible manquante, invalide, preset manquant, masque vide, déjà généré ;
- Clear : aucun placement ;
- Regenerate : sans placements ;
- Shuffle : sans placements générés mais prêt, masque vide, preset manquant, cible manquante.

Complément widget : `Generate désactivé sans cible TileLayer` dans le même fichier de test Golden Slice.

## 7. Non-régression Lots 19–28

Commande groupée sur les 11 fichiers §12.3 : **127 tests, All tests passed!**

## 8. Non-persistance disque garantie

Les flux `generateEnvironmentAreaPlacements` / `clear` / `regenerate` / `shuffle` ne contiennent pas d’appel à `saveProject` / `FileProjectRepository`. Grep sur chemins inspecteur + notifier + test Golden Slice :

```
lib/src/features/editor/state/editor_notifier.dart:443:  Future<bool> saveProjectManifest() async {
lib/src/features/editor/state/editor_notifier.dart:452:    debugPrint('EditorNotifier: saveProjectManifest()');
lib/src/features/editor/state/editor_notifier.dart:454:      await ref.read(projectRepositoryProvider).saveProject(
lib/src/features/editor/state/editor_notifier.dart:1494:  Future<void> saveProjectDialogueYarnBody({
lib/src/features/editor/state/editor_notifier.dart:1498:    state = await _projectContentController.saveProjectDialogueYarnBody(
```

## 9. Données protégées : ProjectManifest / TileLayer / placements manuels

Le test Lot 29 impose : `identical(s.project, manifestRef)` ; égalité des listes `TileLayer.tiles` à l’état initial ; `presetId` et `targetTileLayerId` stables ; `manual_keep` présent après shuffle ; chaque entrée de `generatedPlacementIds` résout un `MapPlacedElement` et n’est pas l’id manuel.

## 10. Limites connues restantes

- Hors Golden Slice : pas d’édition seed manuelle, pas de gestion avancée des orphelins hors liste, pas de persistance automatique.
- `flutter test` sur tout `packages/map_editor` échoue encore (compilation tests catalogues) — dette hors Environment Studio.
- Le test Lot 29 valide la **référence** manifest inchangée ; une mutation profonde du manifest sans remplacement d’objet serait un angle mort (non observé dans le code actuel).

## 11. Cutover roadmap recommandé

1. **Golden Slice Environment : atteint** pour l’éditeur (workflow + tests + invariants données).
2. **Product-ready** complet : exiger refonte UI, polish macOS, parcours utilisateur hors dev, éventuellement persistance / QA transverse.
3. **Prochaine étape** : **UI-1 — Global macOS Dark Redesign Audit / Design Direction V0**.
4. **Environment-30** (orphelins / safety) : **non recommandé** sauf bug terrain ; l’audit ne montre pas de manque bloquant dans le périmètre actuel.

## 12. Pourquoi aucune nouvelle feature / refonte UI dans ce lot

Lot de clôture : uniquement tests + documentation ; aucun changement `lib/` production.

## 13. Fichiers modifiés

```text
M packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
?? reports/forest/environment_studio_lot_29_golden_slice_final_validation.md
```

## 14. Tests ajoutés ou modifiés

- Modifié : `environment_golden_slice_workflow_test.dart` (groupe Lot 29 + helpers).

## 15. Commandes exécutées

```text
cd packages/map_editor
dart format test/environment_studio/environment_golden_slice_workflow_test.dart
flutter analyze test/environment_studio/environment_golden_slice_workflow_test.dart
grep (audits §4 lot + grep saveProject sur chemins §12.4)
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart --reporter expanded
flutter test (11 fichiers §12.3)
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test  # package map_editor entier
```

## 16. Résultats des commandes

### flutter analyze
```
Analyzing environment_golden_slice_workflow_test.dart...        
No issues found! (ran in 1.9s)
```

### flutter test — golden slice workflow (sortie complète)
```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
00:00 +0: Golden Slice — workflow notifier complet generate → clear → generate → regenerate → shuffle ; manuel conservé
00:00 +1: Golden Slice — workflow notifier complet shuffle sans placements générés préalables : seed change et placements
00:00 +2: Golden Slice — workflow notifier complet clear sans placements : message statut, carte inchangée
00:00 +3: Golden Slice — inspecteur minimal résumé + Generate activé quand prêt
00:00 +4: Golden Slice — inspecteur minimal Generate désactivé sans cible TileLayer
00:00 +5: Golden Slice — validation finale (Lot 29) generate → clear → generate → regenerate → shuffle : invariants manifest, tuiles, masque, sélection, ids
00:00 +6: All tests passed!
```

### flutter test — 11 fichiers Lots 19–28
Ligne finale : `00:05 +127: All tests passed!`

### flutter test — test/environment_studio
Ligne finale : `00:10 +233: All tests passed!`

### flutter test — workspace + top_toolbar
Ligne finale : `00:04 +14: All tests passed!`

### flutter test — package map_editor entier
**Ligne finale : `00:59 +1065 -35: Some tests failed.`** — échecs de compilation dans des tests hors périmètre Environment (ex. `pokemon_catalogs_workspace_ui_test.dart`, const factory).

## 17. Git status initial et final

**Initial (début Lot 29, avant modifications)** :
```
 M packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
```
(arbre par ailleurs propre côté fichiers suivis pour ce lot.)

**Final** :
```
 M packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
?? reports/forest/environment_studio_lot_29_golden_slice_final_validation.md
```

## 18. Contenu complet des fichiers créés ou modifiés

### `packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart`
```dart
// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/panels/environment_layer_inspector_panel.dart';

import '../shell_chrome_test_harness.dart';

ProjectManifest _manifest() {
  return buildShellChromeProject(
    environmentPresets: [
      EnvironmentPreset(
        id: 'p1',
        name: 'P',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'e1', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          edgeDensity: 1,
          variation: 0,
          minSpacingCells: 0,
        ),
        sortOrder: 0,
      ),
    ],
    elements: const [
      ProjectElementEntry(
        id: 'e1',
        name: 'E',
        tilesetId: 'tsA',
        categoryId: 'c',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
  );
}

EnvironmentArea _area({List<String>? generated}) {
  return EnvironmentArea(
    id: 'area1',
    name: 'Z',
    presetId: 'p1',
    mask: EnvironmentAreaMask(
      width: 2,
      height: 2,
      cells: List<bool>.filled(4, true),
    ),
    seed: 42,
    generatedPlacementIds: generated,
  );
}

MapData _map(EnvironmentArea area) {
  final env = MapLayer.environment(
    id: 'env',
    name: 'E',
    content: EnvironmentLayerContent(
      targetTileLayerId: 'tiles',
      areas: [area],
    ),
  );
  final tile = TileLayer(
    id: 'tiles',
    name: 'T',
    tiles: List<int>.filled(4, 0),
  );
  return MapData(
    id: 'm',
    name: 'M',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'tsA',
    layers: [env, tile],
    placedElements: const [
      MapPlacedElement(
        id: 'manual_keep',
        layerId: 'tiles',
        elementId: 'e1',
        pos: GridPos(x: 1, y: 1),
      ),
    ],
  );
}

TileLayer _tileLayer(MapData map) =>
    map.layers.whereType<TileLayer>().firstWhere((l) => l.id == 'tiles');

EnvironmentArea _envArea(MapData map) =>
    (map.layers.first as EnvironmentLayer).content.areas.single;

List<int> _tilesSnapshot(MapData map) => List<int>.from(_tileLayer(map).tiles);

/// Invariants Lot 29 : manifest et tuiles intacts, masque / preset / cible stables,
/// sélection cohérente, chaque id généré référence un placement existant (≠ manuel).
void _assertGoldenSliceFinalInvariants(
  EditorState s,
  ProjectManifest manifestRef,
  List<int> initialTiles,
  int initialMaskActive,
  String expectedPresetId,
  String expectedTargetId,
) {
  expect(s.project, isNotNull);
  expect(identical(s.project, manifestRef), isTrue,
      reason:
          'ProjectManifest ne doit pas être remplacé par les flux Golden Slice');
  final map = s.activeMap!;
  expect(_tilesSnapshot(map), initialTiles,
      reason: 'TileLayer.tiles ne doit pas être modifié');
  final area = _envArea(map);
  expect(area.mask.activeCellCount, initialMaskActive,
      reason:
          'Le masque ne doit pas changer (generate/clear/regenerate/shuffle)');
  expect(area.presetId, expectedPresetId);
  expect(
    (map.layers.first as EnvironmentLayer).content.targetTileLayerId,
    expectedTargetId,
  );
  expect(s.activeLayerId, 'env');
  expect(s.selectedEnvironmentAreaId, 'area1');
  expect(s.environmentMaskEditMode, isNull);
  for (final pid in area.generatedPlacementIds) {
    expect(pid, isNot('manual_keep'));
    expect(
      map.placedElements.any((e) => e.id == pid),
      isTrue,
      reason: 'generatedPlacementIds ne référence que des placements présents',
    );
  }
}

void main() {
  group('Golden Slice — workflow notifier complet', () {
    test('generate → clear → generate → regenerate → shuffle ; manuel conservé',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      var area = _area();
      var map = _map(area);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/golden',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area1',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
        savedMapSnapshot: map,
      );
      final notifier = container.read(editorNotifierProvider.notifier);

      notifier.generateEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      var s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements.length, greaterThan(1));
      expect(
        (s.activeMap!.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .generatedPlacementIds,
        isNotEmpty,
      );
      expect(
        s.activeMap!.placedElements.any((p) => p.id == 'manual_keep'),
        isTrue,
      );
      expect(s.environmentMaskEditMode, isNull);

      notifier.clearEnvironmentGeneratedPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      s = container.read(editorNotifierProvider);
      expect(
        (s.activeMap!.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .generatedPlacementIds,
        isEmpty,
      );
      expect(s.activeMap!.placedElements.map((e) => e.id).toList(),
          ['manual_keep']);

      notifier.generateEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements.length, greaterThan(1));
      final seedBeforeRegen = (s.activeMap!.layers.first as EnvironmentLayer)
          .content
          .areas
          .single
          .seed;

      notifier.regenerateEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements.length, greaterThan(1));
      expect(
        (s.activeMap!.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .seed,
        seedBeforeRegen,
      );
      expect(
        s.activeMap!.placedElements.any((p) => p.id == 'manual_keep'),
        isTrue,
      );

      final seedBeforeShuffle = (s.activeMap!.layers.first as EnvironmentLayer)
          .content
          .areas
          .single
          .seed;
      notifier.shuffleEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      s = container.read(editorNotifierProvider);
      final areaOut =
          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
      expect(areaOut.seed, isNot(seedBeforeShuffle));
      expect(areaOut.generatedPlacementIds, isNotEmpty);
      expect(
        s.activeMap!.placedElements.any((p) => p.id == 'manual_keep'),
        isTrue,
      );
    });

    test(
        'shuffle sans placements générés préalables : seed change et placements',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final area = _area();
      final map = _map(area);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/golden',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area1',
        savedMapSnapshot: map,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      final seed0 = (container
              .read(editorNotifierProvider)
              .activeMap!
              .layers
              .first as EnvironmentLayer)
          .content
          .areas
          .single
          .seed;

      notifier.shuffleEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      final s = container.read(editorNotifierProvider);
      final areaOut =
          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
      expect(areaOut.seed, isNot(seed0));
      expect(areaOut.generatedPlacementIds, isNotEmpty);
      expect(s.activeMap!.placedElements.length, greaterThan(1));
    });

    test('clear sans placements : message statut, carte inchangée', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final area = _area();
      final map = _map(area);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/golden',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.clearEnvironmentGeneratedPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      final s = container.read(editorNotifierProvider);
      expect(
          s.statusMessage, 'Aucun placement généré à effacer pour cette zone.');
      expect(identical(s.activeMap, map), isTrue);
    });
  });

  group('Golden Slice — inspecteur minimal', () {
    testWidgets('résumé + Generate activé quand prêt', (tester) async {
      final area = _area();
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/g',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: EnvironmentLayerInspectorPanel(
                  map: map,
                  layer: env as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('État : prêt à générer'), findsOneWidget);
      expect(
        tester
            .widget<PushButton>(
              find.byKey(const Key('env-area-generate-area1')),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('Generate désactivé sans cible TileLayer', (tester) async {
      final area = _area();
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: null,
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/g',
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'env',
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: EnvironmentLayerInspectorPanel(
                  map: map,
                  layer: env as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PushButton>(
              find.byKey(const Key('env-area-generate-area1')),
            )
            .onPressed,
        isNull,
      );
      expect(
          find.textContaining('Choisissez un TileLayer cible'), findsWidgets);
    });
  });

  group('Golden Slice — validation finale (Lot 29)', () {
    test(
      'generate → clear → generate → regenerate → shuffle : invariants manifest, '
      'tuiles, masque, sélection, ids',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final manifest = _manifest();
        final area = _area();
        final map = _map(area);
        final initialTiles = _tilesSnapshot(map);
        final initialMask = _envArea(map).mask.activeCellCount;
        expect(initialMask, 4);

        container.read(editorNotifierProvider.notifier).state = EditorState(
          projectRootPath: '/golden',
          project: manifest,
          activeMap: map,
          activeMapPath: 'maps/x.json',
          activeLayerId: 'env',
          selectedEnvironmentAreaId: 'area1',
          environmentMaskEditMode: EnvironmentMaskEditMode.paint,
          savedMapSnapshot: map,
        );
        final notifier = container.read(editorNotifierProvider.notifier);

        void check() {
          _assertGoldenSliceFinalInvariants(
            container.read(editorNotifierProvider),
            manifest,
            initialTiles,
            initialMask,
            'p1',
            'tiles',
          );
        }

        notifier.generateEnvironmentAreaPlacements(
          environmentLayerId: 'env',
          areaId: 'area1',
        );
        check();
        final s1 = container.read(editorNotifierProvider);
        expect(s1.activeMap!.placedElements.length, greaterThan(1));
        expect(_envArea(s1.activeMap!).generatedPlacementIds, isNotEmpty);

        notifier.clearEnvironmentGeneratedPlacements(
          environmentLayerId: 'env',
          areaId: 'area1',
        );
        check();
        final s2 = container.read(editorNotifierProvider);
        expect(_envArea(s2.activeMap!).generatedPlacementIds, isEmpty);
        expect(
          s2.activeMap!.placedElements.map((e) => e.id).toList(),
          ['manual_keep'],
        );

        notifier.generateEnvironmentAreaPlacements(
          environmentLayerId: 'env',
          areaId: 'area1',
        );
        check();
        final seedBeforeRegen =
            _envArea(container.read(editorNotifierProvider).activeMap!).seed;

        notifier.regenerateEnvironmentAreaPlacements(
          environmentLayerId: 'env',
          areaId: 'area1',
        );
        check();
        expect(
          _envArea(container.read(editorNotifierProvider).activeMap!).seed,
          seedBeforeRegen,
        );

        final seedBeforeShuffle =
            _envArea(container.read(editorNotifierProvider).activeMap!).seed;
        notifier.shuffleEnvironmentAreaPlacements(
          environmentLayerId: 'env',
          areaId: 'area1',
        );
        check();
        final areaOut = _envArea(
          container.read(editorNotifierProvider).activeMap!,
        );
        expect(areaOut.seed, isNot(seedBeforeShuffle));
        expect(areaOut.generatedPlacementIds, isNotEmpty);
        expect(
          container
              .read(editorNotifierProvider)
              .activeMap!
              .placedElements
              .any((p) => p.id == 'manual_keep'),
          isTrue,
        );
      },
    );
  });
}

```

### `reports/forest/environment_studio_lot_29_golden_slice_final_validation.md`
Ce fichier est le rapport lui-même (auto-référence : le contenu après génération correspond au fichier sur disque).

## 19. Diff complet

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart b/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
index f3f0ef04..9e799c81 100644
--- a/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
@@ -92,6 +92,53 @@ MapData _map(EnvironmentArea area) {
   );
 }
 
+TileLayer _tileLayer(MapData map) =>
+    map.layers.whereType<TileLayer>().firstWhere((l) => l.id == 'tiles');
+
+EnvironmentArea _envArea(MapData map) =>
+    (map.layers.first as EnvironmentLayer).content.areas.single;
+
+List<int> _tilesSnapshot(MapData map) => List<int>.from(_tileLayer(map).tiles);
+
+/// Invariants Lot 29 : manifest et tuiles intacts, masque / preset / cible stables,
+/// sélection cohérente, chaque id généré référence un placement existant (≠ manuel).
+void _assertGoldenSliceFinalInvariants(
+  EditorState s,
+  ProjectManifest manifestRef,
+  List<int> initialTiles,
+  int initialMaskActive,
+  String expectedPresetId,
+  String expectedTargetId,
+) {
+  expect(s.project, isNotNull);
+  expect(identical(s.project, manifestRef), isTrue,
+      reason:
+          'ProjectManifest ne doit pas être remplacé par les flux Golden Slice');
+  final map = s.activeMap!;
+  expect(_tilesSnapshot(map), initialTiles,
+      reason: 'TileLayer.tiles ne doit pas être modifié');
+  final area = _envArea(map);
+  expect(area.mask.activeCellCount, initialMaskActive,
+      reason:
+          'Le masque ne doit pas changer (generate/clear/regenerate/shuffle)');
+  expect(area.presetId, expectedPresetId);
+  expect(
+    (map.layers.first as EnvironmentLayer).content.targetTileLayerId,
+    expectedTargetId,
+  );
+  expect(s.activeLayerId, 'env');
+  expect(s.selectedEnvironmentAreaId, 'area1');
+  expect(s.environmentMaskEditMode, isNull);
+  for (final pid in area.generatedPlacementIds) {
+    expect(pid, isNot('manual_keep'));
+    expect(
+      map.placedElements.any((e) => e.id == pid),
+      isTrue,
+      reason: 'generatedPlacementIds ne référence que des placements présents',
+    );
+  }
+}
+
 void main() {
   group('Golden Slice — workflow notifier complet', () {
     test('generate → clear → generate → regenerate → shuffle ; manuel conservé',
@@ -381,4 +428,104 @@ void main() {
           find.textContaining('Choisissez un TileLayer cible'), findsWidgets);
     });
   });
+
+  group('Golden Slice — validation finale (Lot 29)', () {
+    test(
+      'generate → clear → generate → regenerate → shuffle : invariants manifest, '
+      'tuiles, masque, sélection, ids',
+      () {
+        final container = ProviderContainer();
+        addTearDown(container.dispose);
+        final manifest = _manifest();
+        final area = _area();
+        final map = _map(area);
+        final initialTiles = _tilesSnapshot(map);
+        final initialMask = _envArea(map).mask.activeCellCount;
+        expect(initialMask, 4);
+
+        container.read(editorNotifierProvider.notifier).state = EditorState(
+          projectRootPath: '/golden',
+          project: manifest,
+          activeMap: map,
+          activeMapPath: 'maps/x.json',
+          activeLayerId: 'env',
+          selectedEnvironmentAreaId: 'area1',
+          environmentMaskEditMode: EnvironmentMaskEditMode.paint,
+          savedMapSnapshot: map,
+        );
+        final notifier = container.read(editorNotifierProvider.notifier);
+
+        void check() {
+          _assertGoldenSliceFinalInvariants(
+            container.read(editorNotifierProvider),
+            manifest,
+            initialTiles,
+            initialMask,
+            'p1',
+            'tiles',
+          );
+        }
+
+        notifier.generateEnvironmentAreaPlacements(
+          environmentLayerId: 'env',
+          areaId: 'area1',
+        );
+        check();
+        final s1 = container.read(editorNotifierProvider);
+        expect(s1.activeMap!.placedElements.length, greaterThan(1));
+        expect(_envArea(s1.activeMap!).generatedPlacementIds, isNotEmpty);
+
+        notifier.clearEnvironmentGeneratedPlacements(
+          environmentLayerId: 'env',
+          areaId: 'area1',
+        );
+        check();
+        final s2 = container.read(editorNotifierProvider);
+        expect(_envArea(s2.activeMap!).generatedPlacementIds, isEmpty);
+        expect(
+          s2.activeMap!.placedElements.map((e) => e.id).toList(),
+          ['manual_keep'],
+        );
+
+        notifier.generateEnvironmentAreaPlacements(
+          environmentLayerId: 'env',
+          areaId: 'area1',
+        );
+        check();
+        final seedBeforeRegen =
+            _envArea(container.read(editorNotifierProvider).activeMap!).seed;
+
+        notifier.regenerateEnvironmentAreaPlacements(
+          environmentLayerId: 'env',
+          areaId: 'area1',
+        );
+        check();
+        expect(
+          _envArea(container.read(editorNotifierProvider).activeMap!).seed,
+          seedBeforeRegen,
+        );
+
+        final seedBeforeShuffle =
+            _envArea(container.read(editorNotifierProvider).activeMap!).seed;
+        notifier.shuffleEnvironmentAreaPlacements(
+          environmentLayerId: 'env',
+          areaId: 'area1',
+        );
+        check();
+        final areaOut = _envArea(
+          container.read(editorNotifierProvider).activeMap!,
+        );
+        expect(areaOut.seed, isNot(seedBeforeShuffle));
+        expect(areaOut.generatedPlacementIds, isNotEmpty);
+        expect(
+          container
+              .read(editorNotifierProvider)
+              .activeMap!
+              .placedElements
+              .any((p) => p.id == 'manual_keep'),
+          isTrue,
+        );
+      },
+    );
+  });
 }
```

## 20. Auto-review

- **Points solides** : invariants explicites ; pas de toucher au `lib/` ; régressions Environment Studio vertes.
- **Points discutables** : `identical(project)` est une garantie de non-remplacement d’instance, pas une preuve d’immutabilité profonde du manifest.
- **Corrections après auto-review** : aucune nécessaire.
- **Risques** : dette `flutter test` globale map_editor inchangée.
- **Regard critique sur le prompt** : Golden Slice atteint pour l’éditeur ; les tests couvrent le parcours notifier + smoke inspecteur, pas un E2E clic réel sur toute la chaîne Layers ; un mini-lot Environment-30 n’est pas justifié ici ; passage UI-1 raisonnable.

### Confirmations Evidence Pack

- Aucun `map_core` modifié.
- Aucun `MapCanvas` modifié.
- Aucun `EditorState` / `.freezed.dart` / generated modifié.
- Aucun patch de `TileLayer.tiles` dans le code produit ; test assert non-modification.
- Aucun nouveau moteur de génération.
- Aucune refonte UI.
- Aucune sauvegarde disque dans les flux Golden Slice ; grep montre `saveProject` uniquement hors ces méthodes dans `editor_notifier.dart`.
- Aucun `SurfaceLayer` legacy dans ce lot.
- Aucun `build_runner`.
- Aucun `git commit` / `git add` / `git push`.

## 21. Verdict

Statut du lot :

- [x] Validé

Résumé :

```text
Golden Slice validé par test d’invariants ; environment_studio vert ; aucune régression Lots 19–28 sur la batterie ciblée ; cutover documenté vers UI-1.
```

Golden Slice Environment :

* [x] Atteint

Prochaine étape recommandée :

```text
UI-1 — Global macOS Dark Redesign Audit / Design Direction V0
```

Alternative si réserve technique bloquante (non retenue ici) :

```text
Environment-30 — Generated Placements Safety / Orphan Cleanup V0
```