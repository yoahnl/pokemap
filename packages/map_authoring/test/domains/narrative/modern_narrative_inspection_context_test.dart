import 'dart:collection';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('batch scene inspection indexes project resources once', () {
    int readsFor(int count) {
      final models = _CountedEmptyList<ProjectModel3dEntry>();
      final project = ProjectManifest(
        name: 'Narrative inspection',
        maps: const [],
        tilesets: const [],
        models3d: models,
        scenes: [for (var index = 0; index < count; index++) _scene('$index')],
      );
      models.lengthReads = 0;
      const ModernNarrativeInspector()
          .inspect(project: project, maps: const []);
      return models.lengthReads;
    }

    final one = readsFor(1);
    final many = readsFor(20);
    expect(one, greaterThan(0));
    expect(many, lessThanOrEqualTo(one + 1));
  });

  test('batch diagnostics match individual scenes and changed snapshots', () {
    final scenes = [
      _scene('known', dialogueId: 'known'),
      _scene('unknown', dialogueId: 'missing')
    ];
    final project = ProjectManifest(
      name: 'Narrative inspection',
      maps: const [],
      tilesets: const [],
      scenes: scenes,
      dialogues: const [
        ProjectDialogueEntry(
            id: 'known', name: 'Known', relativePath: 'dialogues/known.yarn')
      ],
    );
    final report = const ModernNarrativeInspector()
        .inspect(project: project, maps: const []);
    final expected = [
      for (final scene in scenes)
        for (final item
            in diagnoseSceneAgainstProject(scene, project).diagnostics)
          '${scene.id}:scene.${item.code.name}:${item.message}'
    ]..sort();
    final actual = [
      for (final item in report.diagnostics)
        if (item.resourceKind == 'scene')
          '${item.resourceId}:${item.code}:${item.message}'
    ]..sort();
    expect(actual, expected);
    expect(
        report.diagnostics
            .where((item) => item.code == 'scene.dialogueRefUnknown')
            .map((item) => item.resourceId),
        ['unknown']);
    final changed = const ModernNarrativeInspector()
        .inspect(project: project.copyWith(dialogues: []), maps: const []);
    expect(
        changed.diagnostics
            .where((item) => item.code == 'scene.dialogueRefUnknown')
            .map((item) => item.resourceId),
        unorderedEquals(['known', 'unknown']));
  });
}

final class _CountedEmptyList<T> extends ListBase<T> {
  int lengthReads = 0;
  @override
  int get length {
    lengthReads++;
    return 0;
  }

  @override
  set length(int value) => throw UnsupportedError('Read-only fixture');
  @override
  T operator [](int index) => throw RangeError.index(index, this);
  @override
  void operator []=(int index, T value) =>
      throw UnsupportedError('Read-only fixture');
}

SceneAsset _scene(String id, {String? dialogueId}) => SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        if (dialogueId != null)
          SceneNode(
              id: 'dialogue',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: dialogueId)),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(
            id: 'first',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: dialogueId == null ? 'end' : 'dialogue',
            kind: SceneEdgeKind.defaultFlow),
        if (dialogueId != null)
          SceneEdge(
              id: 'last',
              fromNodeId: 'dialogue',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow),
      ]),
    );
