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
      final chooseTarget =
          find.byKey(const Key('env-layer-inspector-choose-target'));
      await tester.ensureVisible(chooseTarget);
      await tester.pumpAndSettle();
      await tester.tap(chooseTarget);
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
      final chooseTarget2 =
          find.byKey(const Key('env-layer-inspector-choose-target'));
      await tester.ensureVisible(chooseTarget2);
      await tester.pumpAndSettle();
      await tester.tap(chooseTarget2);
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
      final removeTarget =
          find.byKey(const Key('env-layer-inspector-remove-target'));
      await tester.ensureVisible(removeTarget);
      await tester.pumpAndSettle();
      await tester.tap(removeTarget);
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
