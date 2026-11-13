import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../tool/create_example_project.dart';

void main() {
  test(
    'Studio scene adapter publishes one canonical batch and cold reopens it',
    () async {
      final h = await _Project.create();
      addTearDown(h.dispose);
      final adapter = LocalSceneAdapter(
        session: h.session,
        mapAdapter: h.adapter,
      );
      final first = _scene('batch_first');
      final second = _scene('batch_second');
      final receipt = await adapter.publishSceneBatch(
        scenes: [(base: null, current: first), (base: null, current: second)],
      );
      expect(receipt.manifest.scenes, containsAll([first, second]));
      final history = [
        for (final entry in Directory(
          '${h.directory.path}/.pokemap/authoring/history-entries',
        ).listSync().whereType<File>())
          await entry.readAsString(),
      ];
      expect(
        history.where((entry) => entry.contains('scene.upsert_batch')),
        hasLength(1),
      );
      final reopened = await LocalMapWorkspaceAdapter().loadProject(h.session);
      expect(reopened.scenes, containsAll([first, second]));
    },
  );

  test(
    'Studio refuses a stale last base and an invalid last scene atomically',
    () async {
      final h = await _Project.create();
      addTearDown(h.dispose);
      final adapter = LocalSceneAdapter(
        session: h.session,
        mapAdapter: h.adapter,
      );
      final first = _scene('batch_first');
      final second = _scene('batch_second');
      await adapter.publishSceneBatch(
        scenes: [(base: null, current: first), (base: null, current: second)],
      );
      final file = File('${h.directory.path}/project.json');
      final before = await file.readAsBytes();
      await expectLater(
        adapter.publishSceneBatch(
          scenes: [
            (base: first, current: _scene('batch_first', name: 'Changed')),
            (base: null, current: second),
          ],
        ),
        throwsA(isA<SceneFailure>()),
      );
      expect(await file.readAsBytes(), before);
      await expectLater(
        adapter.publishSceneBatch(
          scenes: [
            (base: first, current: _scene('batch_first', name: 'Changed')),
            (base: null, current: _scene('bad', dialogue: 'missing')),
          ],
        ),
        throwsA(isA<SceneFailure>()),
      );
      expect(await file.readAsBytes(), before);
      expect(
        ProjectManifest.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        ).scenes,
        contains(first),
      );
    },
  );

  test('Studio refuses empty and 129-scene batches before writing', () async {
    final h = await _Project.create();
    addTearDown(h.dispose);
    final adapter = LocalSceneAdapter(
      session: h.session,
      mapAdapter: h.adapter,
    );
    final file = File('${h.directory.path}/project.json');
    final before = await file.readAsBytes();
    await expectLater(
      adapter.publishSceneBatch(scenes: []),
      throwsA(isA<SceneFailure>()),
    );
    await expectLater(
      adapter.publishSceneBatch(
        scenes: List.generate(
          129,
          (i) => (base: null, current: _scene('s_$i')),
        ),
      ),
      throwsA(isA<SceneFailure>()),
    );
    expect(await file.readAsBytes(), before);
  });
}

SceneAsset _scene(String id, {String? name, String? dialogue}) => SceneAsset(
  id: id,
  name: name ?? id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      if (dialogue != null)
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: dialogue),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'first',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: dialogue == null ? 'end' : 'dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      if (dialogue != null)
        SceneEdge(
          id: 'last',
          fromNodeId: 'dialogue',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
    ],
  ),
);

class _Project {
  _Project(this.directory, this.session);

  final Directory directory;
  final ProjectSession session;
  final adapter = LocalMapWorkspaceAdapter();

  static Future<_Project> create() async {
    final temporary = await Directory.systemTemp.createTemp('avelune_scene_');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    final project = _Project(
      directory,
      ProjectSession(
        sessionId: directory.path,
        name: 'Scènes',
        directoryPath: directory.path,
      ),
    );
    await project.adapter.loadProject(project.session);
    return project;
  }

  Future<void> dispose() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
