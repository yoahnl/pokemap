import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  test('EditorNotifier publishes and adopts a reciprocal connection pair',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_editor_connection_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    const project = ProjectManifest(
      name: 'Editor connection flow',
      maps: [
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
        ProjectMapEntry(
          id: 'beta',
          name: 'Beta',
          relativePath: 'maps/beta.json',
        ),
      ],
      tilesets: [],
    );
    const alpha = MapData(
      id: 'alpha',
      name: 'Alpha',
      size: GridSize(width: 8, height: 8),
    );
    const beta = MapData(
      id: 'beta',
      name: 'Beta',
      size: GridSize(width: 8, height: 8),
    );
    final projectPath = p.join(root.path, 'project.json');
    final alphaPath = p.join(root.path, 'maps', 'alpha.json');
    final betaPath = p.join(root.path, 'maps', 'beta.json');
    final projectRepository = FileProjectRepository();
    final mapRepository = FileMapRepository();
    await projectRepository.saveProject(project, projectPath);
    await mapRepository.saveMap(
      alpha,
      alphaPath,
      projectDialogueContext: project,
    );
    await mapRepository.saveMap(
      beta,
      betaPath,
      projectDialogueContext: project,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(editorNotifierProvider, (_, _) {});
    addTearDown(keepAlive.close);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = EditorState(
        projectRootPath: root.path,
        project: project,
        activeMap: alpha,
        activeMapPath: alphaPath,
        savedMapSnapshot: alpha,
      );

    await notifier.saveMapConnection(
      direction: MapConnectionDirection.east,
      targetMapId: 'beta',
      offset: 2,
      reciprocal: true,
    );

    expect(notifier.state.errorMessage, isNull);
    expect(
      notifier.state.activeMap!.connections.single,
      const MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'beta',
        offset: 2,
      ),
    );
    expect(
      (await mapRepository.loadMap(betaPath)).connections.single,
      const MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'alpha',
        offset: -2,
      ),
    );

    await notifier.deleteMapConnection(MapConnectionDirection.east);

    expect(notifier.state.errorMessage, isNull);
    expect(notifier.state.activeMap!.connections, isEmpty);
    expect((await mapRepository.loadMap(betaPath)).connections, isEmpty);
  });
}
