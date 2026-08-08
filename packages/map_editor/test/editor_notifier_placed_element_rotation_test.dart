import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorNotifier placed-element rotation', () {
    test('commits once, keeps selection, and restores exact undo and redo', () {
      final fixture = _fixture();
      addTearDown(fixture.container.dispose);
      final sourceSnapshot = fixture.sourceMap.toJson();

      final committed = fixture.notifier.setPlacedElementInstanceQuarterTurns(
        instanceId: 'placed',
        quarterTurns: 1,
      );

      expect(committed, isTrue);
      expect(
        fixture.notifier.state.activeMap!.placedElements.single.quarterTurns,
        1,
      );
      expect(
        fixture.notifier.state.selectedPlacedElementInstanceId,
        'placed',
      );
      expect(fixture.notifier.state.mapUndoStack, hasLength(1));
      expect(fixture.notifier.state.mapRedoStack, isEmpty);
      expect(fixture.notifier.state.mapStrokeStart, isNull);
      expect(fixture.notifier.state.errorMessage, isNull);
      expect(fixture.sourceMap.toJson(), sourceSnapshot);

      fixture.notifier.undoMap();

      expect(fixture.notifier.state.activeMap, fixture.sourceMap);
      expect(
        fixture.notifier.state.activeMap!.placedElements.single.quarterTurns,
        0,
      );
      expect(
        fixture.notifier.state.selectedPlacedElementInstanceId,
        'placed',
      );
      expect(fixture.notifier.state.mapUndoStack, isEmpty);
      expect(fixture.notifier.state.mapRedoStack, hasLength(1));

      fixture.notifier.redoMap();

      expect(
        fixture.notifier.state.activeMap!.placedElements.single.quarterTurns,
        1,
      );
      expect(
        fixture.notifier.state.selectedPlacedElementInstanceId,
        'placed',
      );
      expect(fixture.notifier.state.mapUndoStack, hasLength(1));
      expect(fixture.notifier.state.mapRedoStack, isEmpty);
    });

    test('rejects an invalid absolute target without normalization or history',
        () {
      final fixture = _fixture(quarterTurns: 2);
      addTearDown(fixture.container.dispose);
      final sourceSnapshot = fixture.sourceMap.toJson();

      final committed = fixture.notifier.setPlacedElementInstanceQuarterTurns(
        instanceId: 'placed',
        quarterTurns: 4,
      );

      expect(committed, isFalse);
      expect(fixture.notifier.state.activeMap, same(fixture.sourceMap));
      expect(
        fixture.notifier.state.activeMap!.placedElements.single.quarterTurns,
        2,
      );
      expect(fixture.notifier.state.mapUndoStack, isEmpty);
      expect(
        fixture.notifier.state.selectedPlacedElementInstanceId,
        'placed',
      );
      expect(fixture.notifier.state.errorMessage, contains('0 et 3'));
      expect(fixture.sourceMap.toJson(), sourceSnapshot);
    });

    test('does not record history for an absolute no-op', () {
      final fixture = _fixture(quarterTurns: 2);
      addTearDown(fixture.container.dispose);

      final committed = fixture.notifier.setPlacedElementInstanceQuarterTurns(
        instanceId: 'placed',
        quarterTurns: 2,
      );

      expect(committed, isFalse);
      expect(fixture.notifier.state.activeMap, same(fixture.sourceMap));
      expect(fixture.notifier.state.mapUndoStack, isEmpty);
      expect(fixture.notifier.state.mapRedoStack, isEmpty);
      expect(
        fixture.notifier.state.selectedPlacedElementInstanceId,
        'placed',
      );
    });

    test('normalizes a large relative delta before adding it', () {
      final fixture = _fixture(quarterTurns: 2);
      addTearDown(fixture.container.dispose);

      final committed = fixture.notifier.rotateSelectedPlacedElement(
        deltaQuarterTurns: int.parse('9007199254740991'),
      );

      expect(committed, isTrue);
      expect(
        fixture.notifier.state.activeMap!.placedElements.single.quarterTurns,
        1,
      );
      expect(fixture.notifier.state.mapUndoStack, hasLength(1));
    });

    test('wraps a negative relative delta counter-clockwise', () {
      final fixture = _fixture();
      addTearDown(fixture.container.dispose);

      final committed = fixture.notifier.rotateSelectedPlacedElement(
        deltaQuarterTurns: -1,
      );

      expect(committed, isTrue);
      expect(
        fixture.notifier.state.activeMap!.placedElements.single.quarterTurns,
        3,
      );
      expect(fixture.notifier.state.mapUndoStack, hasLength(1));
    });

    test('surfaces missing-selection feedback without changing the map', () {
      final fixture = _fixture(selectedInstanceId: null);
      addTearDown(fixture.container.dispose);

      final committed = fixture.notifier.rotateSelectedPlacedElement(
        deltaQuarterTurns: 1,
      );

      expect(committed, isFalse);
      expect(fixture.notifier.state.activeMap, same(fixture.sourceMap));
      expect(fixture.notifier.state.mapUndoStack, isEmpty);
      expect(fixture.notifier.state.errorMessage, contains('introuvable'));
    });

    test('surfaces capability rejection and preserves Environment ownership',
        () {
      final fixture = _fixture(
        properties: const <String, String>{
          pokemapPlacementOriginProperty: pokemapPlacementOriginEnvironment,
          'seed': '42',
        },
      );
      addTearDown(fixture.container.dispose);
      final sourceSnapshot = fixture.sourceMap.toJson();

      final committed = fixture.notifier.setPlacedElementInstanceQuarterTurns(
        instanceId: 'placed',
        quarterTurns: 1,
      );

      expect(committed, isFalse);
      expect(fixture.notifier.state.activeMap, same(fixture.sourceMap));
      expect(fixture.notifier.state.mapUndoStack, isEmpty);
      expect(fixture.notifier.state.errorMessage, contains('Environment'));
      expect(fixture.sourceMap.toJson(), sourceSnapshot);
    });
  });
}

({
  ProviderContainer container,
  EditorNotifier notifier,
  MapData sourceMap,
}) _fixture({
  int quarterTurns = 0,
  String? selectedInstanceId = 'placed',
  Map<String, String> properties = const <String, String>{},
}) {
  final container = ProviderContainer();
  final notifier = container.read(editorNotifierProvider.notifier);
  final map = _map(
    quarterTurns: quarterTurns,
    properties: properties,
  );
  notifier.state = EditorState(
    project: _project,
    activeMap: map,
    activeLayerId: 'decor',
    selectedPlacedElementInstanceId: selectedInstanceId,
    savedMapSnapshot: map,
  );
  return (
    container: container,
    notifier: notifier,
    sourceMap: map,
  );
}

MapData _map({
  required int quarterTurns,
  required Map<String, String> properties,
}) {
  const size = GridSize(width: 5, height: 5);
  return MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: size,
    layers: <MapLayer>[
      MapLayer.tile(
        id: 'decor',
        name: 'Decor',
        cells: List<int>.filled(
          size.width * size.height,
          0,
          growable: false,
        ),
      ),
    ],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'placed',
        layerId: 'decor',
        elementId: 'element-3x2',
        pos: const GridPos(x: 1, y: 1),
        quarterTurns: quarterTurns,
        properties: properties,
      ),
    ],
  );
}

const _project = ProjectManifest(
  name: 'Rotation notifier',
  version: ProjectVersion.v6,
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'assets/tiles.png',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'element-3x2',
      name: 'Element 3x2',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(
            x: 0,
            y: 0,
            width: 3,
            height: 2,
          ),
        ),
      ],
    ),
  ],
);
