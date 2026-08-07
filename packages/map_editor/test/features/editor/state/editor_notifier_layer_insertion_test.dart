import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('EditorNotifier.addMapLayer stacking', () {
    test('inserts a new layer in front of the active one', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load();

      notifier.setActiveLayer('middle');
      notifier.addMapLayer(kind: MapLayerKind.tile, name: 'Fresh');

      // The map serializes front-first, so the slot in front of "middle" is
      // its own index.
      expect(
        notifier.state.activeMap!.layers.map((layer) => layer.id).toList(),
        <String>['front', 'l_tile_fresh', 'middle', 'back'],
      );
      expect(notifier.state.activeLayerId, 'l_tile_fresh');
    });

    test('stacks successive layers in creation order, newest in front',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load();

      notifier.setActiveLayer('back');
      notifier.addMapLayer(kind: MapLayerKind.tile, name: 'One');
      notifier.addMapLayer(kind: MapLayerKind.tile, name: 'Two');

      // Each new layer lands in front of the previous one, never behind the
      // whole stack.
      expect(
        notifier.state.activeMap!.layers.map((layer) => layer.id).toList(),
        <String>['front', 'middle', 'l_tile_two', 'l_tile_one', 'back'],
      );
    });

    test('puts a new layer at the very front of the frontmost layer', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load();

      notifier.setActiveLayer('front');
      notifier.addMapLayer(kind: MapLayerKind.tile, name: 'Fresh');

      expect(notifier.state.activeMap!.layers.first.id, 'l_tile_fresh');
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
        await Directory.systemTemp.createTemp('pokemap_layer_insertion_editor_');
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

  Future<void> load() async {
    expect(
      await notifier.activateMap('maps/alpha.json'),
      MapActivationOutcome.activated,
    );
  }

  Future<void> dispose() async {
    container.dispose();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

ProjectManifest _project() => const ProjectManifest(
      name: 'Layer insertion editor',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'base_tiles',
          name: 'Base tiles',
          relativePath: 'tilesets/base.png',
          scope: TilesetScope.global,
        ),
      ],
    );

MapData _map() => const MapData(
      id: 'alpha',
      name: 'Alpha',
      version: ProjectVersion.v6,
      size: GridSize(width: 2, height: 2),
      tilesetId: 'base_tiles',
      layers: <MapLayer>[
        TileLayer(
          id: 'front',
          name: 'Front',
          cells: <int>[0, 0, 0, 0],
        ),
        TileLayer(
          id: 'middle',
          name: 'Middle',
          cells: <int>[0, 0, 0, 0],
        ),
        TileLayer(
          id: 'back',
          name: 'Back',
          cells: <int>[0, 0, 0, 0],
        ),
      ],
    );
