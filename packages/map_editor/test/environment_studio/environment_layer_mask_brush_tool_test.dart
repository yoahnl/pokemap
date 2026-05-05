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
  final w = env.content.areas.isEmpty ? 4 : env.content.areas.first.mask.width;
  final h = env.content.areas.isEmpty ? 3 : env.content.areas.first.mask.height;
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

      notifier.startEnvironmentAreaGeneratedPlacementAdd(
        environmentLayerId: 'env1',
        areaId: 'area_1',
      );
      s = container.read(editorNotifierProvider);
      expect(s.environmentMaskEditMode, EnvironmentMaskEditMode.generatedAdd);

      notifier.startEnvironmentAreaGeneratedPlacementDelete(
        environmentLayerId: 'env1',
        areaId: 'area_1',
      );
      s = container.read(editorNotifierProvider);
      expect(
        s.environmentMaskEditMode,
        EnvironmentMaskEditMode.generatedDelete,
      );

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
      expect(
        find.byKey(Key('env-area-placement-add-${area.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('env-area-placement-delete-${area.id}')),
        findsOneWidget,
      );
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
      await tester.tap(find.byKey(Key('env-area-placement-add-${area.id}')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Édition active : ajout'), findsOneWidget);
      await tester.tap(find.byKey(Key('env-area-placement-delete-${area.id}')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Édition active : suppression'),
        findsOneWidget,
      );
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

    testWidgets('tap sans mode placement ne supprime pas un arbre généré', (
      tester,
    ) async {
      final area = _area(
        id: 'a_delete',
        w: 4,
        h: 4,
        generatedPlacementIds: const ['tree_a'],
      );
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      ) as EnvironmentLayer;
      final map = MapData(
        id: 'route_1',
        name: 'Route 1',
        size: const GridSize(width: 4, height: 4),
        layers: <MapLayer>[
          env,
          TileLayer(id: 'tiles', name: 'T', tiles: List<int>.filled(16, 0)),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'tree_a',
            layerId: 'tiles',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'p',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        surfaceCatalog: ProjectSurfaceCatalog(),
        elements: const [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'ts',
            categoryId: 'flora',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
              ),
            ],
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempDir.path,
        project: project,
        activeMap: map,
        activeLayerId: 'env1',
        selectedEnvironmentAreaId: area.id,
        environmentMaskEditMode: null,
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

      final s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements.map((p) => p.id), ['tree_a']);
    });

    testWidgets('mode suppression + tap retire un arbre généré',
        (tester) async {
      final area = _area(
        id: 'a_delete',
        w: 4,
        h: 4,
        generatedPlacementIds: const ['tree_a'],
      );
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      ) as EnvironmentLayer;
      final map = MapData(
        id: 'route_1',
        name: 'Route 1',
        size: const GridSize(width: 4, height: 4),
        layers: <MapLayer>[
          env,
          TileLayer(id: 'tiles', name: 'T', tiles: List<int>.filled(16, 0)),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'tree_a',
            layerId: 'tiles',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'p',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        surfaceCatalog: ProjectSurfaceCatalog(),
        elements: const [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'ts',
            categoryId: 'flora',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
              ),
            ],
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempDir.path,
        project: project,
        activeMap: map,
        activeLayerId: 'env1',
        selectedEnvironmentAreaId: area.id,
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
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

      final s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements, isEmpty);
      expect(s.statusMessage, contains('Placement généré supprimé'));
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
