import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('Studio canonical publication retains unrelated catalog scenes after reopening', () async {
    final root = await Directory.systemTemp.createTemp('puzzle-authoring-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final scene = SceneAsset(
      id: 'puzzle',
      name: 'Puzzle',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'open',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.openImagePuzzle(
                definition: ImagePuzzleDefinition(
                  puzzleId: 'mosaic',
                  imageResourceId: 'image',
                  rows: 2,
                  columns: 2,
                ),
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'enter',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'open',
            kind: SceneEdgeKind.defaultFlow,
          ),
          for (final port in ['solved', 'quit'])
            SceneEdge(
              id: port,
              fromNodeId: 'open',
              fromPortId: port,
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
        ],
      ),
    );
    final unrelated = [
      for (var i = 0; i < 128; i++)
        SceneAsset(
          id: 'other-$i',
          name: 'Other $i',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
          ),
        ),
    ];
    await WorkingProjectCatalog.create(
      store: store,
      projectId: 'puzzle',
      project: ProjectManifest(
        name: 'Puzzle',
        maps: [],
        tilesets: [],
        scenes: [scene, ...unrelated],
      ),
    );
    await Directory('${root.path}/assets').create();
    await File('${root.path}/assets/.pokemap-media.json').writeAsString(
      jsonEncode(
        ProjectMediaCatalog(
          entries: [
            ProjectMediaAsset(
              id: 'image',
              label: 'Mosaïque',
              kind: ProjectMediaKind.image,
              sourceAssetId: 'source',
            ),
          ],
        ).toJson(),
      ),
    );
    final session = ProjectSession(
      sessionId: root.path,
      name: 'Puzzle',
      directoryPath: root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    final adapter = LocalMapWorkspaceAdapter();
    await adapter.loadProject(session);
    final changed = SceneAsset.fromJson({
      ...scene.toJson(),
      'name': 'Puzzle guidé',
    });
    final receipt = await LocalSceneAdapter(
      session: session,
      mapAdapter: adapter,
    ).publishScene(base: scene, current: changed);
    expect(receipt.catalog.manifest.scenes, [changed, ...unrelated]);
    final reopened = await LocalMapWorkspaceAdapter().loadProject(session);
    expect(reopened.scenes, [changed, ...unrelated]);
  });
}
