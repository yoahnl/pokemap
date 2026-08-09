import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorNotifier active map stroke interlock', () {
    test('save performs no I/O and preserves the cancellable stroke', () async {
      final fixture = _createFixture();
      final before = fixture.notifier.state;

      final outcome = await fixture.notifier.saveActiveMap();

      expect(outcome, ActiveMapSaveOutcome.unavailable);
      expect(fixture.repository.savedMaps, isEmpty);
      expect(fixture.notifier.state, before);

      // A blocked global command must leave ownership with the canvas so its
      // normal rollback terminal can still restore the exact checkpoint.
      fixture.notifier.cancelMapStroke();
      expect(fixture.notifier.state.activeMap, _cleanMap);
      expect(fixture.notifier.state.mapStrokeStart, isNull);
      expect(fixture.notifier.state.mapUndoStack, before.mapUndoStack);
      expect(fixture.notifier.state.mapRedoStack, before.mapRedoStack);
    });

    test('undo leaves the live stroke and both history stacks untouched', () {
      final fixture = _createFixture();
      final before = fixture.notifier.state;

      fixture.notifier.undoMap();

      expect(fixture.notifier.state, before);
      fixture.notifier.cancelMapStroke();
      expect(fixture.notifier.state.activeMap, _cleanMap);
      expect(fixture.notifier.state.mapUndoStack, before.mapUndoStack);
      expect(fixture.notifier.state.mapRedoStack, before.mapRedoStack);
    });

    test('redo preserves a pre-existing redo stack during the live stroke', () {
      final fixture = _createFixture();
      final before = fixture.notifier.state;

      fixture.notifier.redoMap();

      expect(fixture.notifier.state, before);
      fixture.notifier.cancelMapStroke();
      expect(fixture.notifier.state.activeMap, _cleanMap);
      expect(fixture.notifier.state.mapUndoStack, before.mapUndoStack);
      expect(fixture.notifier.state.mapRedoStack, before.mapRedoStack);
    });
  });
}

({
  ProviderContainer container,
  EditorNotifier notifier,
  _RecordingMapRepository repository,
})
_createFixture() {
  final repository = _RecordingMapRepository();
  final container = ProviderContainer(
    overrides: <Override>[
      mapRepositoryProvider.overrideWith((ref) => repository),
    ],
  );
  addTearDown(container.dispose);
  final notifier = container.read(editorNotifierProvider.notifier)
    ..state = const EditorState(
      workspaceMode: EditorWorkspaceMode.map,
      project: _project,
      activeMap: _partialMap,
      activeMapPath: '/project/maps/town.json',
      activeLayerId: 'ground',
      savedMapSnapshot: _cleanMap,
      mapStrokeStart: MapHistorySnapshot(
        map: _cleanMap,
        activeLayerId: 'ground',
      ),
      mapUndoStack: <MapHistorySnapshot>[
        MapHistorySnapshot(map: _undoCandidate),
      ],
      mapRedoStack: <MapHistorySnapshot>[
        MapHistorySnapshot(map: _redoCandidate),
      ],
      canUndoMap: true,
      canRedoMap: true,
      isDirty: true,
    );
  return (container: container, notifier: notifier, repository: repository);
}

class _RecordingMapRepository implements MapRepository {
  final List<MapData> savedMaps = <MapData>[];

  @override
  Future<void> deleteMap(String path) async {}

  @override
  Future<MapData> loadMap(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    savedMaps.add(map);
  }
}

const _project = ProjectManifest(
  name: 'Demo',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(id: 'town', name: 'Town', relativePath: 'maps/town.json'),
  ],
  tilesets: <ProjectTilesetEntry>[],
);

const _cleanMap = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 2, height: 1),
  layers: <MapLayer>[
    TileLayer(id: 'ground', name: 'Ground', cells: <int>[1, 1]),
  ],
);

const _partialMap = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 2, height: 1),
  layers: <MapLayer>[
    TileLayer(id: 'ground', name: 'Ground', cells: <int>[0, 1]),
  ],
);

const _undoCandidate = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 2, height: 1),
  layers: <MapLayer>[
    TileLayer(id: 'ground', name: 'Ground', cells: <int>[2, 2]),
  ],
);

const _redoCandidate = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 2, height: 1),
  layers: <MapLayer>[
    TileLayer(id: 'ground', name: 'Ground', cells: <int>[3, 3]),
  ],
);
