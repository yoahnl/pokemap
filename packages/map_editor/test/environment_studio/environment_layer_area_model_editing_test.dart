// ignore_for_file: prefer_const_constructors — fixtures MapData / MaterialApp non const

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

EnvironmentPreset _preset({
  String id = 'preset_forest',
  String name = 'Forêt test',
}) {
  return EnvironmentPreset(
    id: id,
    name: name,
    templateId: 'forest_dense',
    palette: [
      EnvironmentPaletteItem(elementId: 'elem_tree', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

void main() {
  group('Lot 21 — EnvironmentArea model (inspector)', () {
    group('AddEnvironmentAreaUseCase', () {
      test(
          'ajoute une area : mask taille map, vide, placements vides, cible préservée',
          () {
        final tile = TileLayer(
          id: 'tiles_main',
          name: 'Sol',
          tiles: List<int>.filled(12, 0, growable: false),
        );
        final env = MapLayer.environment(
          id: 'env1',
          name: 'Nature',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'tiles_main',
            areas: const [],
          ),
        );
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 4, height: 3),
          layers: [env, tile],
          placedElements: [
            MapPlacedElement(
              id: 'pe1',
              layerId: 'tiles_main',
              elementId: 'x',
              pos: const GridPos(x: 0, y: 0),
            ),
          ],
        );
        final manifest = buildShellChromeProject(
          environmentPresets: [_preset()],
        );
        final uc = AddEnvironmentAreaUseCase();
        final result = uc.execute(
          map,
          manifest: manifest,
          environmentLayerId: 'env1',
          presetId: 'preset_forest',
        );
        final layer = result.map.layers.first as EnvironmentLayer;
        expect(layer.content.areas.length, 1);
        expect(layer.content.areas.single.presetId, 'preset_forest');
        expect(layer.content.targetTileLayerId, 'tiles_main');
        expect(layer.content.areas.single.mask.width, 4);
        expect(layer.content.areas.single.mask.height, 3);
        expect(layer.content.areas.single.mask.activeCellCount, 0);
        expect(layer.content.areas.single.generatedPlacementIds, isEmpty);
        expect(result.map.placedElements, map.placedElements);
      });

      test('deux areas même preset → ids différents, ordre stable', () {
        final env = MapLayer.environment(id: 'env1', name: 'E');
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 2, height: 2),
          layers: [env],
        );
        final manifest = buildShellChromeProject(
          environmentPresets: [_preset()],
        );
        final uc = AddEnvironmentAreaUseCase();
        final r1 = uc.execute(
          map,
          manifest: manifest,
          environmentLayerId: 'env1',
          presetId: 'preset_forest',
        );
        final r2 = AddEnvironmentAreaUseCase().execute(
          r1.map,
          manifest: manifest,
          environmentLayerId: 'env1',
          presetId: 'preset_forest',
        );
        final areas = (r2.map.layers.first as EnvironmentLayer).content.areas;
        expect(areas.length, 2);
        expect(areas[0].id, isNot(areas[1].id));
        expect(areas.map((a) => a.id).toSet().length, 2);
      });

      test('rejette environmentLayerId inconnu', () {
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 1),
          layers: [MapLayer.environment(id: 'env1', name: 'E')],
        );
        final manifest = buildShellChromeProject(
          environmentPresets: [_preset()],
        );
        expect(
          () => AddEnvironmentAreaUseCase().execute(
            map,
            manifest: manifest,
            environmentLayerId: 'missing',
            presetId: 'preset_forest',
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
        final manifest = buildShellChromeProject(
          environmentPresets: [_preset()],
        );
        expect(
          () => AddEnvironmentAreaUseCase().execute(
            map,
            manifest: manifest,
            environmentLayerId: 't1',
            presetId: 'preset_forest',
          ),
          throwsA(isA<EditorValidationException>()),
        );
      });

      test('rejette presetId inconnu', () {
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 1),
          layers: [MapLayer.environment(id: 'env1', name: 'E')],
        );
        final manifest = buildShellChromeProject(
          environmentPresets: [_preset()],
        );
        expect(
          () => AddEnvironmentAreaUseCase().execute(
            map,
            manifest: manifest,
            environmentLayerId: 'env1',
            presetId: 'nope',
          ),
          throwsA(isA<EditorValidationException>()),
        );
      });

      test('rejette presetId vide', () {
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 1),
          layers: [MapLayer.environment(id: 'env1', name: 'E')],
        );
        final manifest = buildShellChromeProject(
          environmentPresets: [_preset()],
        );
        expect(
          () => AddEnvironmentAreaUseCase().execute(
            map,
            manifest: manifest,
            environmentLayerId: 'env1',
            presetId: '   ',
          ),
          throwsA(isA<EditorValidationException>()),
        );
      });
    });

    group('SetEnvironmentAreaPresetUseCase', () {
      test('change presetId, préserve mask et generatedPlacementIds et cible',
          () {
        final mask = EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: const [true, false, false, false],
        );
        final area = EnvironmentArea(
          id: 'a1',
          name: 'Z1',
          presetId: 'preset_a',
          mask: mask,
          seed: 7,
          generatedPlacementIds: const ['pl1', 'pl2'],
        );
        final env = MapLayer.environment(
          id: 'env1',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 't1',
            areas: [area],
          ),
        );
        final tile = TileLayer(
          id: 't1',
          name: 'T',
          tiles: const <int>[0, 0, 0, 0],
        );
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 2, height: 2),
          layers: [env, tile],
        );
        final manifest = buildShellChromeProject(
          environmentPresets: [
            _preset(id: 'preset_a', name: 'A'),
            _preset(id: 'preset_b', name: 'B'),
          ],
        );
        final uc = SetEnvironmentAreaPresetUseCase();
        final out = uc.execute(
          map,
          manifest: manifest,
          environmentLayerId: 'env1',
          areaId: 'a1',
          presetId: 'preset_b',
        );
        final layer = out.layers.first as EnvironmentLayer;
        final updated = layer.content.areas.single;
        expect(updated.presetId, 'preset_b');
        expect(updated.mask, mask);
        expect(updated.generatedPlacementIds, const ['pl1', 'pl2']);
        expect(updated.seed, 7);
        expect(layer.content.targetTileLayerId, 't1');
      });

      test('rejette areaId inconnu', () {
        final env = MapLayer.environment(
          id: 'env1',
          name: 'E',
          content: EnvironmentLayerContent(
            areas: [
              EnvironmentArea(
                id: 'a1',
                name: 'Z',
                presetId: 'preset_a',
                mask: EnvironmentAreaMask(
                  width: 1,
                  height: 1,
                  cells: const [false],
                ),
                seed: 0,
              ),
            ],
          ),
        );
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 1),
          layers: [env],
        );
        final manifest = buildShellChromeProject(
          environmentPresets: [
            _preset(id: 'preset_a'),
            _preset(id: 'preset_b'),
          ],
        );
        expect(
          () => SetEnvironmentAreaPresetUseCase().execute(
            map,
            manifest: manifest,
            environmentLayerId: 'env1',
            areaId: 'ghost',
            presetId: 'preset_b',
          ),
          throwsA(isA<EditorValidationException>()),
        );
      });
    });

    group('RemoveEnvironmentAreaUseCase', () {
      test('retire une area, préserve l’autre et targetTileLayerId', () {
        final m =
            EnvironmentAreaMask(width: 1, height: 1, cells: const [false]);
        final a1 = EnvironmentArea(
          id: 'a1',
          name: '1',
          presetId: 'p',
          mask: m,
          seed: 0,
        );
        final a2 = EnvironmentArea(
          id: 'a2',
          name: '2',
          presetId: 'p',
          mask: m,
          seed: 0,
        );
        final tile = TileLayer(
          id: 't1',
          name: 'T',
          tiles: const <int>[0],
        );
        final env = MapLayer.environment(
          id: 'env1',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 't1',
            areas: [a1, a2],
          ),
        );
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 1),
          layers: [env, tile],
          placedElements: const [],
        );
        final uc = RemoveEnvironmentAreaUseCase();
        final out = uc.execute(
          map,
          environmentLayerId: 'env1',
          areaId: 'a1',
        );
        final layer = out.layers.first as EnvironmentLayer;
        expect(layer.content.areas.length, 1);
        expect(layer.content.areas.single.id, 'a2');
        expect(layer.content.targetTileLayerId, 't1');
        expect(out.placedElements, map.placedElements);
      });

      test('rejette areaId inconnu', () {
        final env = MapLayer.environment(
          id: 'env1',
          name: 'E',
          content: EnvironmentLayerContent(
            areas: [
              EnvironmentArea(
                id: 'a1',
                name: 'Z',
                presetId: 'p',
                mask: EnvironmentAreaMask(
                  width: 1,
                  height: 1,
                  cells: const [false],
                ),
                seed: 0,
              ),
            ],
          ),
        );
        final map = MapData(
          id: 'm',
          name: 'M',
          size: const GridSize(width: 1, height: 1),
          layers: [env],
        );
        expect(
          () => RemoveEnvironmentAreaUseCase().execute(
            map,
            environmentLayerId: 'env1',
            areaId: 'nope',
          ),
          throwsA(isA<EditorValidationException>()),
        );
      });
    });

    group('EditorNotifier — areas', () {
      test(
          'add / set preset / remove : activeMap, activeLayerId, dirty, chemins',
          () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final env = MapLayer.environment(id: 'env1', name: 'E');
        final map = MapData(
          id: 'm1',
          name: 'M1',
          size: const GridSize(width: 2, height: 2),
          layers: [env],
        );
        const root = '/tmp/lot21';
        const mapPath = 'maps/y.json';
        final manifest = buildShellChromeProject(
          environmentPresets: [
            _preset(id: 'pa', name: 'A'),
            _preset(id: 'pb', name: 'B'),
          ],
        );
        container.read(editorNotifierProvider.notifier).state = EditorState(
          projectRootPath: root,
          project: manifest,
          activeMap: map,
          activeMapPath: mapPath,
          activeLayerId: 'env1',
          savedMapSnapshot: map,
        );
        final notifier = container.read(editorNotifierProvider.notifier);
        notifier.addEnvironmentAreaToLayer(
          environmentLayerId: 'env1',
          presetId: 'pa',
        );
        var state = container.read(editorNotifierProvider);
        final areaId = (state.activeMap!.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .id;
        expect(state.activeLayerId, 'env1');
        expect(state.isDirty, isTrue);
        expect(state.projectRootPath, root);
        expect(state.activeMapPath, mapPath);

        notifier.setEnvironmentAreaPreset(
          environmentLayerId: 'env1',
          areaId: areaId,
          presetId: 'pb',
        );
        state = container.read(editorNotifierProvider);
        expect(
          (state.activeMap!.layers.first as EnvironmentLayer)
              .content
              .areas
              .single
              .presetId,
          'pb',
        );
        expect(state.activeLayerId, 'env1');

        notifier.removeEnvironmentArea(
          environmentLayerId: 'env1',
          areaId: areaId,
        );
        state = container.read(editorNotifierProvider);
        expect(
          (state.activeMap!.layers.first as EnvironmentLayer).content.areas,
          isEmpty,
        );
        expect(state.activeLayerId, 'env1');
      });
    });

    testWidgets('inspecteur : aucun preset → message et pas d’ajout',
        (tester) async {
      final env = MapLayer.environment(id: 'env1', name: 'E');
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
        project: buildShellChromeProject(environmentPresets: const []),
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
      expect(find.byKey(const Key('env-layer-inspector-no-presets')),
          findsOneWidget);
      expect(
          find.byKey(const Key('env-layer-inspector-add-area')), findsNothing);
    });

    testWidgets('ajout zone via picker + affichage + dirty', (tester) async {
      final env = MapLayer.environment(id: 'env1', name: 'E');
      final map = MapData(
        id: 'mx',
        name: 'Mx',
        size: const GridSize(width: 2, height: 2),
        layers: [env],
      );
      final p1 = _preset(id: 'preset_one', name: 'Un');
      final p2 = _preset(id: 'preset_two', name: 'Deux');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp',
        project: buildShellChromeProject(environmentPresets: [p1, p2]),
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
      await tester.tap(find.byKey(const Key('env-layer-inspector-add-area')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Un — preset_one').last);
      await tester.pumpAndSettle();
      final state = container.read(editorNotifierProvider);
      final areas =
          (state.activeMap!.layers.first as EnvironmentLayer).content.areas;
      expect(areas.length, 1);
      expect(areas.single.presetId, 'preset_one');
      expect(state.isDirty, isTrue);
      expect(find.byKey(Key('env-area-card-id-${areas.single.id}')),
          findsOneWidget);
    });

    testWidgets('changer de preset sur une area', (tester) async {
      final mask = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: List<bool>.filled(4, false),
      );
      final area = EnvironmentArea(
        id: 'area_x',
        name: 'Z',
        presetId: 'preset_one',
        mask: mask,
        seed: 0,
      );
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(areas: [area]),
      );
      final map = MapData(
        id: 'mx',
        name: 'Mx',
        size: const GridSize(width: 2, height: 2),
        layers: [env],
      );
      final p1 = _preset(id: 'preset_one', name: 'Un');
      final p2 = _preset(id: 'preset_two', name: 'Deux');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp',
        project: buildShellChromeProject(environmentPresets: [p1, p2]),
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
      final changePresetBtn =
          find.byKey(const Key('env-area-change-preset-area_x'));
      await tester.ensureVisible(changePresetBtn);
      await tester.pumpAndSettle();
      await tester.tap(changePresetBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Deux — preset_two').last);
      await tester.pumpAndSettle();
      expect(
        (container.read(editorNotifierProvider).activeMap!.layers.first
                as EnvironmentLayer)
            .content
            .areas
            .single
            .presetId,
        'preset_two',
      );
      expect(
        find.byKey(const Key('env-area-card-preset-id-area_x')),
        findsOneWidget,
      );
    });

    testWidgets('retirer une area', (tester) async {
      final mask = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: List<bool>.filled(4, false),
      );
      final area = EnvironmentArea(
        id: 'area_rm',
        name: 'Z',
        presetId: 'preset_one',
        mask: mask,
        seed: 0,
      );
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(areas: [area]),
      );
      final map = MapData(
        id: 'mx',
        name: 'Mx',
        size: const GridSize(width: 2, height: 2),
        layers: [env],
      );
      final p1 = _preset(id: 'preset_one', name: 'Un');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp',
        project: buildShellChromeProject(environmentPresets: [p1]),
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
      final removeBtn = find.byKey(const Key('env-area-remove-area_rm'));
      await tester.ensureVisible(removeBtn);
      await tester.pumpAndSettle();
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();
      expect(
        (container.read(editorNotifierProvider).activeMap!.layers.first
                as EnvironmentLayer)
            .content
            .areas,
        isEmpty,
      );
      expect(find.byKey(const Key('env-layer-inspector-no-areas')),
          findsOneWidget);
    });

    testWidgets('avertissement placements si generatedPlacementIds non vides',
        (tester) async {
      final mask = EnvironmentAreaMask(
        width: 1,
        height: 1,
        cells: const [false],
      );
      final area = EnvironmentArea(
        id: 'area_pl',
        name: 'Z',
        presetId: 'preset_one',
        mask: mask,
        seed: 0,
        generatedPlacementIds: const ['x1'],
      );
      final env = MapLayer.environment(
        id: 'env1',
        name: 'E',
        content: EnvironmentLayerContent(areas: [area]),
      );
      final map = MapData(
        id: 'mx',
        name: 'Mx',
        size: const GridSize(width: 1, height: 1),
        layers: [env],
      );
      final envLayer = map.layers.first as EnvironmentLayer;
      final p1 = _preset(id: 'preset_one', name: 'Un');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp',
        project: buildShellChromeProject(environmentPresets: [p1]),
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
                  child: EnvironmentLayerInspectorPanel(
                    map: map,
                    layer: envLayer,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('env-area-card-placements-warn-area_pl')),
        findsOneWidget,
      );
    });
  });
}
