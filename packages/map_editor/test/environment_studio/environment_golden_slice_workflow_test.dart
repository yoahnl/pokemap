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
