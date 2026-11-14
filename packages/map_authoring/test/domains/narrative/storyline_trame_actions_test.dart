import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('every trame action is a described storyline action', () {
    final ids = StorylineActions.descriptors.map((item) => item.id).toSet();
    expect(ids, containsAll(StorylineTrameActions.ids));
    expect(StorylineTrameActions.ids, hasLength(9));
  });

  for (final wire in [false, true]) {
    final transport = wire ? 'JSONL' : 'direct API';
    test('$transport builds a trame, reopens and undoes a milestone', () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final initial = await f.manifest.readAsBytes();
      await f.run('storyline.chapter.create', wire,
          {'storylineId': 'main', 'chapterId': 'act_2', 'title': 'Act 2'});
      final created = await f.run('storyline.milestone.create', wire, {
        'storylineId': 'main',
        'chapterId': 'act_2',
        'stepId': 'leave_town',
        'title': 'Leave town',
      });
      final createdReceipt = created['receipt'] as Map;
      expect([
        for (final entry in (createdReceipt['diff'] as Map)['entries'])
          (entry['operation'], entry['path'])
      ], [
        ('add', '/facts/fact_leave_town'),
        ('replace', '/storylines/main'),
      ]);
      await f.run('storyline.milestone.rename', wire, {
        'storylineId': 'main',
        'chapterId': 'act_2',
        'stepId': 'leave_town',
        'title': 'Leave the town',
      });
      final attached = await f.run('storyline.milestone.attach_scene', wire, {
        'storylineId': 'main',
        'chapterId': 'act_2',
        'stepId': 'leave_town',
        'sceneId': 'scene_gate',
      });
      final entries =
          ((attached['receipt'] as Map)['diff'] as Map)['entries'] as List;
      expect(entries.single['extensions'], {
        'detachedFrom': [
          {'storylineId': 'main', 'chapterId': 'act_1', 'stepId': 'wake_up'}
        ]
      });
      await f.run('storyline.milestone.move', wire, {
        'storylineId': 'main',
        'chapterId': 'act_2',
        'stepId': 'leave_town',
        'targetChapterId': 'act_1',
        'targetIndex': 0,
      });
      await f.run('storyline.chapter.set_archived', wire,
          {'storylineId': 'main', 'chapterId': 'act_2', 'archived': true});

      await f.reopen();
      final project = (await f.snapshots.load(f.project)).manifest;
      final chapters = project.storylines.single.chapters;
      expect(chapters.map((chapter) => (chapter.id, chapter.status)), [
        ('act_1', null),
        ('act_2', StorylineStatus.archived),
      ]);
      final moved = chapters.first.steps.first;
      expect((moved.id, moved.title), ('leave_town', 'Leave the town'));
      expect(moved.sceneLinkIds, ['scene_gate']);
      expect(chapters.first.steps.last.sceneLinkIds, isEmpty);
      final fact = project.facts.last;
      expect((
        fact.id,
        fact.label,
        fact.initialValue
      ), (
        'fact_leave_town',
        'Leave the town',
        const NarrativeValue.boolean(false)
      ));

      for (final receipt in (await f.mutations
          .history(f.project, limit: 20))['entries'] as List) {
        await f.mutations.undo(f.project,
            entryId: (receipt as Map)['entryId'] as String,
            idempotencyKey: 'undo-${receipt['entryId']}');
      }
      expect(await f.manifest.readAsBytes(), initial);
    });
  }

  test('rejections are typed and leave the project untouched', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final before = await f.manifest.readAsBytes();
    for (final (action, parameters, code) in [
      (
        'storyline.milestone.create',
        {
          'storylineId': 'main',
          'chapterId': 'missing',
          'stepId': 'new_step',
          'title': 'New'
        },
        'chapterNotFound'
      ),
      (
        'storyline.milestone.attach_scene',
        {
          'storylineId': 'main',
          'chapterId': 'act_1',
          'stepId': 'wake_up',
          'sceneId': 'scene_missing'
        },
        'sceneNotFound'
      ),
      (
        'storyline.chapter.create',
        {'storylineId': 'main', 'chapterId': 'act_1', 'title': 'Again'},
        'chapterIdAlreadyExists'
      ),
    ]) {
      final result = await f.command('plan', {
        'projectHandle': f.project.value,
        'request': (await f.request(action, parameters)).toJson(),
      });
      expect(result.status, AuthoringResultStatus.failure, reason: action);
      expect(jsonEncode(result.error!.toJson()), contains(code),
          reason: action);
    }
    final unknownKey = await f.command('plan', {
      'projectHandle': f.project.value,
      'request': (await f.request('storyline.chapter.rename',
              {'storylineId': 'main', 'chapterId': 'act_1', 'name': 'X'}))
          .toJson(),
    });
    expect(unknownKey.status, AuthoringResultStatus.failure);
    expect(await f.manifest.readAsBytes(), before);
  });
}

final class _Fixture {
  _Fixture(this.directory, this.snapshots, this.mutations, this.worker);

  final Directory directory;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  late WorkspaceHandle workspace;
  late ProjectHandle project;
  var sequence = 0;

  File get manifest => File('${directory.path}/project.json');

  static Future<_Fixture> create() async {
    final root = await Directory('/Users/karim/Library/Caches/AveluneQA/c2')
        .create(recursive: true);
    final directory = await root.createTemp('trame-');
    final scene = SceneAsset(
      id: 'scene_gate',
      name: 'Gate',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
        edges: const [],
      ),
    );
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(ProjectManifest(
      name: 'Trame transport',
      tilesets: const [],
      maps: const [],
      scenes: [scene],
      facts: [NarrativeFactDefinition(id: 'fact_wake_up', label: 'Wake')],
      storylines: [
        StorylineAsset(
          id: 'main',
          type: StorylineType.main,
          title: 'Main',
          chapters: [
            StorylineChapter(id: 'act_1', title: 'Act 1', order: 0, steps: [
              StorylineStep(
                id: 'wake_up',
                title: 'Wake up',
                order: 0,
                sceneLinkIds: const ['scene_gate'],
              ),
            ]),
          ],
        ),
      ],
    ).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final fixture = _Fixture(directory, snapshots, mutations,
        JsonlWorker(api: api, mutations: mutations));
    await fixture.open();
    return fixture;
  }

  Future<void> open() async {
    final result = await command('open', {'projectRoot': directory.path});
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    workspace = WorkspaceHandle(result.data['workspaceHandle'] as String);
    project = ProjectHandle(result.data['projectHandle'] as String);
  }

  Future<void> reopen() async {
    await command('close', {'workspaceHandle': workspace.value});
    await open();
  }

  Future<AuthoringResult> command(
          String command, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
        'id': 'trame-${++sequence}',
        'command': command,
        'args': args,
      }))) as Map<String, dynamic>);

  Future<AuthoringRequest> request(
      String action, Map<String, Object?> parameters) async {
    final id = 'trame-request-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: parameters);
  }

  Future<Map<String, Object?>> run(
      String action, bool wire, Map<String, Object?> parameters) async {
    final planned = await request(action, parameters);
    if (!wire) {
      final plan = await mutations.plan(project, planned);
      return mutations.apply(project,
          planId: plan['planId'] as String, operationId: 'apply-$sequence');
    }
    final plan = await command(
        'plan', {'projectHandle': project.value, 'request': planned.toJson()});
    expect(plan.status, AuthoringResultStatus.success,
        reason: jsonEncode(plan.toJson()));
    final applied = await command('apply', {
      'projectHandle': project.value,
      'planId': plan.data['planId'],
      'operationId': 'apply-$sequence',
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    return applied.data;
  }

  Future<void> dispose() async {
    await command('close', {'workspaceHandle': workspace.value});
    await directory.delete(recursive: true);
  }
}
