import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'scene_graph_patch_test.dart' show fixture;

void main() {
  test('Scene contracts describe explicit defeat recovery', () {
    for (final id in ['scene.graph.patch', 'scene.upsert']) {
      final contract = SceneActions.descriptors
          .singleWhere((a) => a.id == id)
          .extensions['battleDefeatRecovery'] as Map;
      expect(contract['field'], 'defeatRecovery');
      expect(contract['default'], 'continueScene');
      expect(contract['values'], ['continueScene', 'returnToRecoveryPoint']);
      expect(
          contract['activation'], 'actualDefeatAfterSuccessfulSceneCompletion');
      expect(contract['projectDimension'], 'twoD');
    }
  });

  for (final jsonl in [false, true]) {
    for (final action in ['scene.graph.patch', 'scene.upsert']) {
      test(
          '${jsonl ? 'JSONL' : 'API'} $action retains recovery through cold reopen',
          () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        final original = f.initial.scenes.first;
        final other = f.initial.scenes.last;
        for (final mode in ['returnToRecoveryPoint', 'continueScene']) {
          final before = await f.file.readAsBytes();
          final request = await f.request(action, mode);
          final plan = jsonl
              ? await f.success('plan', {
                  'projectHandle': f.project.value,
                  'request': request.toJson()
                })
              : await f.mutations.plan(f.project, request);
          expect(await f.file.readAsBytes(), before);
          expect(plan['applicable'], isTrue);
          if (jsonl) {
            await f.success('apply', {
              'projectHandle': f.project.value,
              'planId': plan['planId'],
              'operationId': 'recover-${f.sequence}'
            });
          } else {
            await f.mutations.apply(f.project,
                planId: plan['planId']! as String,
                operationId: 'recover-${f.sequence}');
          }
          await f.api.closeWorkspace(f.workspace);
          await f.open();
          final current = (await f.snapshots.load(f.project)).manifest;
          final scene = current.scenes.first;
          final payload = scene.graph.nodes
              .singleWhere((n) => n.id == 'action')
              .payload as SceneBattlePayload;
          expect(payload.defeatRecovery.name, mode);
          expect(scene.graph.edges, original.graph.edges);
          expect(scene.layout, original.layout);
          expect(current.scenes.last, other);
          expect(current.trainers, f.initial.trainers);
        }
        final before = await f.file.readAsBytes();
        final invalid = await f.request(action, 'discardProgress');
        if (jsonl) {
          final result = await f.command('plan',
              {'projectHandle': f.project.value, 'request': invalid.toJson()});
          expect(result.status, isNot(AuthoringResultStatus.success));
          expect(
              jsonEncode(result.toJson()), isNot(contains('worker.internal')));
        } else {
          await expectLater(
              f.mutations.plan(f.project, invalid), throwsA(isA<Exception>()));
        }
        expect(await f.file.readAsBytes(), before);
      });
    }
  }
}

final class _Fixture {
  _Fixture(this.root, this.initial, this.api, this.snapshots, this.mutations,
      this.worker);
  final Directory root;
  final ProjectManifest initial;
  final AuthoringReadApi api;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  late ProjectHandle project;
  late WorkspaceHandle workspace;
  var sequence = 0;
  File get file => File('${root.path}/project.json');

  static Future<_Fixture> create() async {
    final root =
        await Directory.systemTemp.createTemp('scene-recovery-authoring-');
    final project = fixture().copyWith(trainers: const [
      ProjectTrainerEntry(
          id: 'rival',
          name: 'Rival',
          trainerClass: 'Rival',
          team: [ProjectTrainerPokemonEntry(speciesId: 'sproutle', level: 5)]),
    ]);
    final initial = const SceneActions().patchGraph(project,
        maps: [],
        sceneId: 'test',
        upsertNodes: [
          SceneNode(
              id: 'action',
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                  battleKind: 'trainer',
                  trainerId: 'rival',
                  declaredOutcomes: ['victory', 'defeat']))
        ],
        removeEdgeIds: ['leave'],
        upsertEdges: [
          SceneEdge(
              id: 'win',
              fromNodeId: 'action',
              fromPortId: 'victory',
              toNodeId: 'end',
              kind: SceneEdgeKind.battleVictory),
          SceneEdge(
              id: 'lose',
              fromNodeId: 'action',
              fromPortId: 'defeat',
              toNodeId: 'end',
              kind: SceneEdgeKind.battleDefeat),
        ]);
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(initial.toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final f = _Fixture(root, initial, api, snapshots, mutations,
        JsonlWorker(api: api, mutations: mutations));
    await f.open();
    return f;
  }

  Future<AuthoringResult> command(
          String name, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode(
              {'id': 'recovery-${++sequence}', 'command': name, 'args': args})))
          as Map<String, dynamic>);

  Future<Map<String, Object?>> success(
      String name, Map<String, Object?> args) async {
    final result = await command(name, args);
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    return result.data;
  }

  Future<void> open() async {
    final opened = await success('open', {'projectRoot': root.path});
    project = ProjectHandle(opened['projectHandle']! as String);
    workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
  }

  Future<AuthoringRequest> request(String action, String mode) async {
    final scene = initial.scenes.first.toJson();
    final graph = Map<String, dynamic>.from(scene['graph'] as Map);
    final node = initial.scenes.first.graph.nodes
        .singleWhere((n) => n.id == 'action')
        .toJson();
    node['payload'] = {
      ...node['payload'] as Map<String, dynamic>,
      'defeatRecovery': mode
    };
    graph['nodes'] = [
      for (final entry in graph['nodes'] as List)
        if ((entry as Map)['id'] == 'action') node else entry
    ];
    scene['graph'] = graph;
    final id = 'recovery-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: action == 'scene.upsert'
            ? {'scene': scene}
            : {
                'sceneId': 'test',
                'upsertNodes': [node]
              });
  }

  Future<void> dispose() async {
    await api.closeWorkspace(workspace);
    await root.delete(recursive: true);
  }
}
