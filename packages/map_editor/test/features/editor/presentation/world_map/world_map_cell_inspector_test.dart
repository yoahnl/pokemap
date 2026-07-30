import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_cell_inspector.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('reads exact cell values for every cell-backed layer kind',
      (tester) async {
    const cases = <({
      String layerId,
      String layerLabel,
      String typeLabel,
      String value,
    })>[
      (
        layerId: 'tile',
        layerLabel: 'Tuiles (tile)',
        typeLabel: 'Tuiles',
        value: 'Tuile 7 · Tileset Monde (world)',
      ),
      (
        layerId: 'collision',
        layerLabel: 'Collision (collision)',
        typeLabel: 'Collision',
        value: 'Bloquée',
      ),
      (
        layerId: 'terrain',
        layerLabel: 'Terrain (terrain)',
        typeLabel: 'Terrain',
        value: 'grass',
      ),
      (
        layerId: 'path',
        layerLabel: 'Chemin (path)',
        typeLabel: 'Path',
        value: 'Présent · Preset road',
      ),
      (
        layerId: 'surface',
        layerLabel: 'Surface (surface)',
        typeLabel: 'Surface',
        value: 'water',
      ),
    ];

    for (final testCase in cases) {
      final harness = _CellHarness(testCase.layerId);
      addTearDown(harness.dispose);
      final before = harness.notifier.state;
      await harness.pump(tester);

      _expectFact(
        tester,
        const ValueKey<String>('world-map-cell-coordinate'),
        '(1, 0)',
      );
      _expectFact(
        tester,
        const ValueKey<String>('world-map-cell-layer'),
        testCase.layerLabel,
      );
      _expectFact(
        tester,
        const ValueKey<String>('world-map-cell-type'),
        testCase.typeLabel,
      );
      _expectFact(
        tester,
        const ValueKey<String>('world-map-cell-value'),
        testCase.value,
      );
      expect(find.byType(PokeMapButton), findsNothing);
      expect(find.byType(PokeMapIconButton), findsNothing);
      expect(find.byType(EditableText), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(harness.notifier.state, same(before));

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('missing layer and truncated data are honest no-crash guidance',
      (tester) async {
    final missingHarness = _CellHarness('missing');
    addTearDown(missingHarness.dispose);
    await missingHarness.pump(tester);
    expect(find.text('Calque introuvable'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());

    final truncatedHarness = _CellHarness(
      'tile',
      map: _map.copyWith(
        layers: const <MapLayer>[
          TileLayer(
            id: 'tile',
            name: 'Tuiles',
            tilesetId: 'world',
            tiles: <int>[],
          ),
        ],
      ),
    );
    addTearDown(truncatedHarness.dispose);
    await truncatedHarness.pump(tester);
    _expectFact(
      tester,
      const ValueKey<String>('world-map-cell-value'),
      'Donnée indisponible',
    );
  });
}

void _expectFact(WidgetTester tester, Key key, String value) {
  expect(
    find.descendant(
      of: find.byKey(key),
      matching: find.text(value),
    ),
    findsOneWidget,
  );
}

class _CellHarness {
  _CellHarness(
    String layerId, {
    MapData map = _map,
  }) {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = EditorState(
      project: _project,
      activeMap: map,
      activeLayerId: layerId,
      savedMapSnapshot: map,
    );
    this.layerId = layerId;
  }

  final ProviderContainer container = ProviderContainer();
  late final ProviderSubscription<EditorState> keepAlive;
  late final String layerId;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        key: ValueKey<Object>(container),
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 600,
              child: WorldMapCellInspector(
                cell: const GridPos(x: 1, y: 0),
                layerId: layerId,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void dispose() {
    keepAlive.close();
    container.dispose();
  }
}

const _project = ProjectManifest(
  name: 'Cell inspector',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'Monde',
      relativePath: 'tilesets/world.png',
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Tuiles',
      tilesetId: 'world',
      tiles: <int>[0, 7, 0, 0],
    ),
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[false, true, false, false],
    ),
    TerrainLayer(
      id: 'terrain',
      name: 'Terrain',
      terrains: <TerrainType>[
        TerrainType.none,
        TerrainType.grass,
        TerrainType.none,
        TerrainType.none,
      ],
    ),
    PathLayer(
      id: 'path',
      name: 'Chemin',
      presetId: 'road',
      cells: <bool>[false, true, false, false],
    ),
    SurfaceLayer(
      id: 'surface',
      name: 'Surface',
      placements: <SurfaceCellPlacement>[
        SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'water'),
      ],
    ),
  ],
);
