import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

/// Painting a cell that already holds the same value leaves the editor dirty
/// while the serialized map stays byte-identical. `map.save` refuses a no-op
/// write, so the editor must report that as saved rather than as a failure —
/// otherwise an author who fills a layer completely can never clear the error.
void main() {
  group('EditorNotifier save with nothing to write', () {
    test('reports saved when the map is already byte-identical on disk',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);

      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Painted',
        ),
      );
      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);

      // Re-apply the exact same metadata: the editor goes dirty again but the
      // document it would write is unchanged.
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Painted',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.isDirty, isFalse);
    });
  });
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.project,
    required this.mapPath,
    required this.container,
  });

  static Future<_Fixture> create() async {
    final root =
        await Directory.systemTemp.createTemp('pokemap_no_change_save_');
    final mapPath = p.join(root.path, 'maps', 'alpha.json');
    final project = _project();
    await FileProjectRepository().saveProject(
      project,
      p.join(root.path, 'project.json'),
    );
    await FileMapRepository().saveMap(
      _map(),
      mapPath,
      projectDialogueContext: project,
    );
    final container = ProviderContainer();
    final fixture = _Fixture(
      root: root,
      project: project,
      mapPath: mapPath,
      container: container,
    );
    fixture.notifier.state = EditorState(
      projectRootPath: root.path,
      project: project,
    );
    return fixture;
  }

  final Directory root;
  final ProjectManifest project;
  final String mapPath;
  final ProviderContainer container;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  Future<void> load(EditorNotifier notifier) async {
    expect(
      await notifier.activateMap('maps/alpha.json'),
      MapActivationOutcome.activated,
    );
  }

  void dispose() {
    container.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}

ProjectManifest _project() => const ProjectManifest(
      name: 'No change save',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
    );

MapData _map() => const MapData(
      id: 'alpha',
      name: 'Alpha',
      version: ProjectVersion.v6,
      size: GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        TileLayer(
          id: 'ground',
          name: 'Ground',
          palette: <TileLayerPaletteEntry>[],
          cells: <int>[0, 0, 0, 0],
        ),
      ],
    );
