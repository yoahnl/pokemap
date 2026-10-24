import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'scene_graph_patch_test.dart' show fixture;

Map<String, dynamic> configuration() => {
      'playerTrainerId': 'rival',
      'bagItems': [
        {'itemId': 'poke-ball', 'quantity': 20}
      ],
      'choices': [
        {'kind': 'capture', 'itemId': 'poke-ball'}
      ],
      'captureAlwaysSucceeds': true,
      'stepDelayMs': 500,
    };

void main() {
  test('Scene contracts discover the temporary battle demonstration', () {
    for (final id in ['scene.graph.patch', 'scene.upsert']) {
      final contract = SceneActions.descriptors
          .singleWhere((entry) => entry.id == id)
          .extensions['battleDemonstration'] as Map;
      expect(contract['field'], 'demonstration');
      expect(contract['writeBack'], false);
      expect(contract['capability'], SceneBattleDemonstration.capabilityId);
    }
  });
  for (final jsonl in [false, true]) {
    for (final action in ['scene.graph.patch', 'scene.upsert']) {
      test(
          '${jsonl ? 'JSONL' : 'API'} $action preserves demonstration through reopen',
          () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        for (final value in [configuration(), null]) {
          final before = await f.file.readAsBytes();
          final request = await f.request(action, value);
          final plan = jsonl
              ? await f.success('plan', {
                  'projectHandle': f.project.value,
                  'request': request.toJson()
                })
              : await f.mutations.plan(f.project, request);
          expect(await f.file.readAsBytes(), before);
          expect(plan['applicable'], true);
          if (jsonl) {
            await f.success('apply', {
              'projectHandle': f.project.value,
              'planId': plan['planId'],
              'operationId': 'demo-${f.sequence}'
            });
          } else {
            await f.mutations.apply(f.project,
                planId: plan['planId']! as String,
                operationId: 'demo-${f.sequence}');
          }
          await f.api.closeWorkspace(f.workspace);
          await f.open();
          final current = (await f.snapshots.load(f.project)).manifest;
          final payload = current.scenes.first.graph.nodes
              .singleWhere((node) => node.id == 'action')
              .payload as SceneBattlePayload;
          expect(payload.demonstration?.toJson(), value);
          expect(current.scenes.first.graph.edges,
              f.initial.scenes.first.graph.edges);
          expect(current.scenes.first.layout, f.initial.scenes.first.layout);
          expect(current.scenes.last, f.initial.scenes.last);
        }
        final before = await f.file.readAsBytes();
        final invalid =
            await f.request(action, {...configuration(), 'stepDelayMs': 0});
        if (jsonl) {
          final result = await f.command('plan',
              {'projectHandle': f.project.value, 'request': invalid.toJson()});
          expect(result.status, isNot(AuthoringResultStatus.success));
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
    final project = fixture().copyWith(
        version: ProjectVersion.v9,
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        encounterTables: const [
          ProjectEncounterTable(
              id: 'target',
              name: 'Target',
              encounterKind: EncounterKind.walk,
              entries: [
                ProjectEncounterEntry(
                    speciesId: 'target', minLevel: 2, maxLevel: 2)
              ])
        ],
        trainers: const [
          ProjectTrainerEntry(
              id: 'rival',
              name: 'Rival',
              trainerClass: 'Rival',
              team: [
                ProjectTrainerPokemonEntry(speciesId: 'sproutle', level: 5)
              ]),
        ]);
    final initial = const SceneActions().patchGraph(project,
        maps: [],
        sceneId: 'test',
        upsertNodes: [
          SceneNode(
              id: 'action',
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                  battleKind: 'wild',
                  battleTemplateId: 'target',
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

  Future<AuthoringRequest> request(
      String action, Map<String, dynamic>? configuration) async {
    final scene = initial.scenes.first.toJson();
    final graph = Map<String, dynamic>.from(scene['graph'] as Map);
    final node = initial.scenes.first.graph.nodes
        .singleWhere((n) => n.id == 'action')
        .toJson();
    node['payload'] = {
      ...node['payload'] as Map<String, dynamic>,
      'demonstration': configuration
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
