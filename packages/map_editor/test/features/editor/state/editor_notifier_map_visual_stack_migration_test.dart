import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/map_visual_stack_migration_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('preview is read-only and acceptance creates one undoable mutation',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    const source = MapData(
      id: 'legacy_map',
      name: 'Legacy map',
      size: GridSize(width: 1, height: 1),
      version: ProjectVersion.v2,
      layers: <MapLayer>[
        SurfaceLayer(id: 'surface', name: 'Surface'),
        TileLayer(id: 'tile', name: 'Tile', tiles: <int>[1]),
      ],
    );
    notifier.state = const EditorState(
      activeMap: source,
      activeLayerId: 'surface',
    );

    final preview = await notifier.previewActiveMapVisualStackMigration(
      compareRenderedPixels: _comparison,
    );

    expect(notifier.state.activeMap, same(source));
    expect(notifier.state.mapUndoStack, isEmpty);

    notifier.migrateActiveMapVisualStack(preview!);

    final migrated = notifier.state.activeMap!;
    expect(migrated.version, ProjectVersion.v3);
    expect(migrated.visualStack, MapVisualStackConfig.canonicalV1);
    expect(
      migrated.copyWith(
        version: source.version,
        visualStack: null,
      ),
      source,
    );
    expect(notifier.state.mapUndoStack, hasLength(1));
    expect(notifier.state.mapUndoStack.single.map, same(source));
    expect(notifier.state.statusMessage, contains('sauvegardez'));
  });

  test('stale preview is refused without mutation or history', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    const source = MapData(
      id: 'legacy_map',
      name: 'Legacy map',
      size: GridSize(width: 1, height: 1),
      version: ProjectVersion.v2,
    );
    notifier.state = const EditorState(activeMap: source);
    final preview = await notifier.previewActiveMapVisualStackMigration(
      compareRenderedPixels: _comparison,
    );
    final changed = source.copyWith(name: 'Changed after preview');
    notifier.state = EditorState(activeMap: changed);

    notifier.migrateActiveMapVisualStack(preview!);

    expect(notifier.state.activeMap, same(changed));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.errorMessage, contains('refusée'));
  });

  test('future semantics block ordinary authoring as read-only', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = MapData(
      id: 'future_map',
      name: 'Future map',
      size: const GridSize(width: 1, height: 1),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig(semanticsVersion: 99),
    );
    notifier.state = EditorState(activeMap: source);

    notifier.updateMapMetadata(const MapMetadata(displayName: 'Changed'));

    expect(notifier.state.activeMap, same(source));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.errorMessage, contains('lecture seule'));
  });
}

Future<MapVisualStackPixelComparison> _comparison({
  required MapData before,
  required MapData after,
}) async =>
    MapVisualStackPixelComparison(
      width: 16,
      height: 16,
      changedPixelCount: 0,
      changedBounds: null,
      beforeFingerprint: 'fnv1a32:same',
      afterFingerprint: 'fnv1a32:same',
      limitations: const <String>[
        'Comparaison RGBA du rendu statique de l’éditeur à t=0.',
      ],
    );
