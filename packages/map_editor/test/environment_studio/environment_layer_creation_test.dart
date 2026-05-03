import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/application/use_cases/layer_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/panels/layers_panel.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('Lot 19 — Environment Layer dans l’éditeur de map', () {
    testWidgets('picker d’ajout de layer expose Environment Layer', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        activeMap: MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 3, height: 3),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 360,
                  height: 520,
                  child: LayersPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is MacosTooltip && widget.message == 'Add Layer',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Type: Tile Layer'));
      await tester.pumpAndSettle();
      expect(find.text('Environment Layer'), findsOneWidget);
    });

    testWidgets(
        'ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        activeMap: MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 3, height: 3),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 360,
                  height: 520,
                  child: LayersPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      final placedBefore = container
          .read(editorNotifierProvider)
          .activeMap!
          .placedElements
          .length;

      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is MacosTooltip && widget.message == 'Add Layer',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Type: Tile Layer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Environment Layer'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('layers-panel-add-environment-description')),
        findsOneWidget,
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final state = container.read(editorNotifierProvider);
      final layer = state.activeMap!.layers.single;
      expect(layer, isA<EnvironmentLayer>());
      final env = layer as EnvironmentLayer;
      expect(env.content.areas, isEmpty);
      expect(env.content.targetTileLayerId, isNull);
      expect(env.isVisible, isTrue);
      expect(env.opacity, 1.0);
      expect(env.properties, isEmpty);
      expect(state.activeLayerId, env.id);
      expect(state.isDirty, isTrue);
      expect(
        state.activeMap!.placedElements.length,
        placedBefore,
      );
    });

    test('AddMapLayerUseCase crée MapLayer.environment via map_core', () {
      const map = MapData(
        id: 'm',
        name: 'M',
        size: GridSize(width: 2, height: 2),
      );
      final uc = AddMapLayerUseCase();
      final r = uc.execute(
        map,
        kind: MapLayerKind.environment,
        name: 'Forêt auteur',
      );
      final layer = r.layer as EnvironmentLayer;
      expect(layer.id, startsWith('l_environment'));
      expect(layer.name, 'Forêt auteur');
      expect(layer.content, EnvironmentLayerContent.emptyContent);
    });

    testWidgets('MapInspector : section neutre quand EnvironmentLayer actif', (
      tester,
    ) async {
      const env = MapLayer.environment(
        id: 'l_environment_demo',
        name: 'Zones bio',
      );
      const map = MapData(
        id: 'map_x',
        name: 'Map X',
        size: GridSize(width: 4, height: 4),
        layers: [env],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/lot19_insp',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/map_x.json',
        activeLayerId: env.id,
      );

      await tester.binding.setSurfaceSize(const Size(520, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 400,
                  height: 1100,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('map-inspector-environment-layer-title')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('map-inspector-environment-layer-body')),
        findsOneWidget,
      );
      expect(
        find.textContaining('La configuration des zones arrive'),
        findsOneWidget,
      );
    });

    test('MapGridPainter : map avec TileLayer + EnvironmentLayer ne lève pas',
        () {
      const map = MapData(
        id: 'lab',
        name: 'lab',
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.environment(id: 'env1', name: 'E'),
          TileLayer(
            id: 't1',
            name: 'T',
            tiles: <int>[1, 0, 0, 1],
          ),
        ],
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
      ).paint(canvas, const ui.Size(64, 64));

      final picture = recorder.endRecording();
      picture.dispose();
    });
  });
}
