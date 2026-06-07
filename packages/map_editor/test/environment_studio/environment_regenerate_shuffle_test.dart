// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_regenerate_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/panels/environment_layer_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';

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

EnvironmentArea _area({
  required String id,
  List<String>? generatedPlacementIds,
  List<bool>? cells,
  int seed = 1,
  int w = 2,
  int h = 2,
  String presetId = 'p1',
}) {
  final c = cells ?? List<bool>.filled(w * h, true);
  return EnvironmentArea(
    id: id,
    name: 'Z',
    presetId: presetId,
    mask: EnvironmentAreaMask(width: w, height: h, cells: c),
    seed: seed,
    generatedPlacementIds: generatedPlacementIds,
  );
}

void main() {
  group('nextEnvironmentAreaSeed', () {
    test('déterministe, >= 0, change pour des seeds simples', () {
      expect(nextEnvironmentAreaSeed(0), nextEnvironmentAreaSeed(0));
      expect(nextEnvironmentAreaSeed(0), greaterThanOrEqualTo(0));
      expect(nextEnvironmentAreaSeed(1), greaterThanOrEqualTo(0));
      expect(nextEnvironmentAreaSeed(42), greaterThanOrEqualTo(0));
      expect(nextEnvironmentAreaSeed(0), isNot(0));
      expect(nextEnvironmentAreaSeed(1), isNot(1));
      expect(nextEnvironmentAreaSeed(42), isNot(42));
    });
  });

  group('SetEnvironmentAreaSeedUseCase', () {
    test('change seed et préserve le reste', () {
      final area = _area(id: 'a1', generatedPlacementIds: const ['x']);
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
        placedElements: const [
          MapPlacedElement(
            id: 'manual',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final r = SetEnvironmentAreaSeedUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'a1',
        seed: 999,
      );
      expect(r.isSuccess, isTrue);
      expect(r.previousSeed, 1);
      expect(r.seed, 999);
      final out =
          (r.map!.layers.first as EnvironmentLayer).content.areas.single;
      expect(out.seed, 999);
      expect(out.mask, area.mask);
      expect(out.presetId, 'p1');
      expect(out.paramsOverride, area.paramsOverride);
      expect(out.generatedPlacementIds, const ['x']);
      expect(
        (r.map!.layers.first as EnvironmentLayer).content.targetTileLayerId,
        'tiles',
      );
      expect(r.map!.placedElements.length, 1);
      expect(r.map!.placedElements.single.id, 'manual');
    });

    test('rejets : layer inconnu, non-env, area inconnue, seed négative', () {
      final area = _area(id: 'a1');
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
        layers: [env, tile],
      );
      expect(
        SetEnvironmentAreaSeedUseCase()
            .execute(map, environmentLayerId: 'ghost', areaId: 'a1', seed: 2)
            .isSuccess,
        isFalse,
      );
      final bad = MapData(
        id: 'm2',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [
          TileLayer(id: 'env', name: 'T', tiles: List<int>.filled(4, 0)),
        ],
      );
      expect(
        SetEnvironmentAreaSeedUseCase()
            .execute(bad, environmentLayerId: 'env', areaId: 'a1', seed: 2)
            .isSuccess,
        isFalse,
      );
      expect(
        SetEnvironmentAreaSeedUseCase()
            .execute(map, environmentLayerId: 'env', areaId: 'ghost', seed: 2)
            .isSuccess,
        isFalse,
      );
      expect(
        SetEnvironmentAreaSeedUseCase()
            .execute(map, environmentLayerId: 'env', areaId: 'a1', seed: -1)
            .isSuccess,
        isFalse,
      );
    });
  });

  group('EditorNotifier regenerate / shuffle', () {
    test('regenerate : placements remplacés, mask edit null, status régénér',
        () {
      final area = _area(
        id: 'a1',
        generatedPlacementIds: const ['g1'],
        seed: 7,
      );
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
        placedElements: const [
          MapPlacedElement(
            id: 'g1',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'a1',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
        savedMapSnapshot: map,
      );
      container
          .read(editorNotifierProvider.notifier)
          .regenerateEnvironmentAreaPlacements(
            environmentLayerId: 'env',
            areaId: 'a1',
          );
      final s = container.read(editorNotifierProvider);
      expect(s.activeLayerId, 'env');
      expect(s.selectedEnvironmentAreaId, 'a1');
      expect(s.environmentMaskEditMode, isNull);
      expect(s.isDirty, isTrue);
      expect(s.statusMessage, contains('régénér'));
      final outArea =
          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
      expect(outArea.generatedPlacementIds, isNotEmpty);
      expect(outArea.generatedPlacementIds, isNot(contains('g1')));
      expect(outArea.seed, 7);
      expect(s.activeMap!.placedElements, isNotEmpty);
    });

    test('shuffle : seed change, placements présents, status seed/mélang', () {
      final area = _area(
        id: 'a1',
        generatedPlacementIds: const ['g1'],
        seed: 100,
      );
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
        placedElements: const [
          MapPlacedElement(
            id: 'g1',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'a1',
        savedMapSnapshot: map,
      );
      final nextSeed = nextEnvironmentAreaSeed(100);
      container
          .read(editorNotifierProvider.notifier)
          .shuffleEnvironmentAreaPlacements(
            environmentLayerId: 'env',
            areaId: 'a1',
          );
      final s = container.read(editorNotifierProvider);
      final outArea =
          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
      expect(outArea.seed, nextSeed);
      expect(outArea.generatedPlacementIds, isNotEmpty);
      expect(
        s.statusMessage!.toLowerCase().contains('seed') ||
            s.statusMessage!.toLowerCase().contains('mélang'),
        isTrue,
      );
    });

    test('shuffle sans génération préalable : crée placements', () {
      final area = _area(id: 'a1');
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
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'a1',
        savedMapSnapshot: map,
      );
      container
          .read(editorNotifierProvider.notifier)
          .shuffleEnvironmentAreaPlacements(
            environmentLayerId: 'env',
            areaId: 'a1',
          );
      final s = container.read(editorNotifierProvider);
      final outArea =
          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
      expect(outArea.generatedPlacementIds, isNotEmpty);
      expect(outArea.seed, isNot(1));
      expect(s.activeMap!.placedElements, isNotEmpty);
    });

    test('regenerate sans placements : pas de mutation', () {
      final area = _area(id: 'a1');
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
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        isDirty: false,
        savedMapSnapshot: map,
      );
      final before = container.read(editorNotifierProvider).activeMap!;
      container
          .read(editorNotifierProvider.notifier)
          .regenerateEnvironmentAreaPlacements(
            environmentLayerId: 'env',
            areaId: 'a1',
          );
      final s = container.read(editorNotifierProvider);
      expect(identical(s.activeMap, before), isTrue);
      expect(s.isDirty, isFalse);
      expect(s.statusMessage, contains('Aucun placement généré à régénérer'));
    });

    test('transactionnalité : clear OK puis generate KO → carte inchangée', () {
      final area = _area(
        id: 'a1',
        generatedPlacementIds: const ['g1'],
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
        placedElements: const [
          MapPlacedElement(
            id: 'g1',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      container
          .read(editorNotifierProvider.notifier)
          .regenerateEnvironmentAreaPlacements(
            environmentLayerId: 'env',
            areaId: 'a1',
          );
      final s = container.read(editorNotifierProvider);
      expect(s.errorMessage, isNotNull);
      expect(s.activeMap!.placedElements.length, 1);
      expect(s.activeMap!.placedElements.single.id, 'g1');
      final outArea =
          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
      expect(outArea.generatedPlacementIds, const ['g1']);
    });
  });

  group('EnvironmentLayerInspectorPanel — Regenerate / Shuffle', () {
    testWidgets('régénérer activé + compteur stable', (tester) async {
      final area = _area(
        id: 'a1',
        generatedPlacementIds: const ['g1'],
      );
      final envLayer = MapLayer.environment(
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
        layers: [envLayer, tile],
        placedElements: const [
          MapPlacedElement(
            id: 'g1',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      await tester.binding.setSurfaceSize(const Size(520, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 440,
                  height: 2000,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final regen = find.byKey(const Key('env-area-regenerate-a1'));
      expect(tester.widget<PushButton>(regen).onPressed, isNotNull);
      await tester.ensureVisible(regen);
      await tester.pumpAndSettle();
      await tester.tap(regen);
      await tester.pumpAndSettle();
      final s = container.read(editorNotifierProvider);
      expect(
        (s.activeMap!.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .generatedPlacementIds,
        isNotEmpty,
      );
      expect(
        find.byKey(const Key('env-area-card-placements-count-a1')),
        findsOneWidget,
      );
    });

    testWidgets('shuffle : seed affichée change', (tester) async {
      final area = _area(id: 'a1', seed: 555);
      final envLayer = MapLayer.environment(
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
        layers: [envLayer, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      await tester.binding.setSurfaceSize(const Size(520, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 440,
                  height: 2000,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Seed : 555'), findsOneWidget);
      final sh = find.byKey(const Key('env-area-shuffle-a1'));
      await tester.ensureVisible(sh);
      await tester.pumpAndSettle();
      await tester.tap(sh);
      await tester.pumpAndSettle();
      expect(find.textContaining('Seed : 555'), findsNothing);
      expect(
        (container.read(editorNotifierProvider).activeMap!.layers.first
                as EnvironmentLayer)
            .content
            .areas
            .single
            .generatedPlacementIds,
        isNotEmpty,
      );
    });

    testWidgets('états désactivés : regenerate sans ids, shuffle masque vide',
        (tester) async {
      final areaEmptyMask = _area(
        id: 'a1',
        cells: List<bool>.filled(4, false),
      );
      final env1 = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [areaEmptyMask],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map1 = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env1, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map1,
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
                  map: map1,
                  layer: env1 as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PushButton>(find.byKey(const Key('env-area-regenerate-a1')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<PushButton>(find.byKey(const Key('env-area-shuffle-a1')))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('Peignez le masque'), findsWidgets);

      final areaNoTarget = _area(id: 'a2');
      final env2 = MapLayer.environment(
        id: 'env2',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: null,
          areas: [areaNoTarget],
        ),
      );
      final map2 = MapData(
        id: 'm2',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env2, tile],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: EnvironmentLayerInspectorPanel(
                  map: map2,
                  layer: env2 as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PushButton>(find.byKey(const Key('env-area-shuffle-a2')))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('TileLayer cible'), findsWidgets);

      final areaBadPreset = _area(id: 'a3', presetId: 'missing');
      final env3 = MapLayer.environment(
        id: 'env3',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [areaBadPreset],
        ),
      );
      final map3 = MapData(
        id: 'm3',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env3, tile],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: EnvironmentLayerInspectorPanel(
                  map: map3,
                  layer: env3 as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PushButton>(find.byKey(const Key('env-area-shuffle-a3')))
            .onPressed,
        isNull,
      );
    });
  });
}
