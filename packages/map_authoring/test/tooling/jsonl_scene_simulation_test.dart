import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late AuthoringReadApi api;
  late ProjectHandle handle;
  late File manifestFile;
  late String original;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('scene_simulation_');
    manifestFile = File('${directory.path}/project.json');
    original = jsonEncode(ProjectManifest(
      name: 'Simulation',
      maps: const [],
      tilesets: const [],
      scenes: [_scene()],
    ).toJson());
    await manifestFile.writeAsString(original);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [directory.path], fileReader: reader),
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    handle = (await api.openProject(directory.path)).projectHandle;
  });
  tearDown(() async {
    expect(await manifestFile.readAsString(), original);
    await directory.delete(recursive: true);
  });

  Future<Map<String, Object?>> simulate(Map<String, Object?> inputs) async =>
      (await api.queryProject(handle, _request(inputs))).items.single;

  test('routes explicit badge and gift outcomes without applying consequences',
      () async {
    final received = await simulate({
      'portsByNodeId': {'badge': 'true', 'gift': 'received'}
    });
    expect(received['status'], 'completed');
    expect(received['proofKind'], 'simulation');
    expect(received['mountedPlayer'], isFalse);
    expect(received['effects'], 'proposedOnly');
    expect(received['proposedConsequences'], hasLength(1));
    expect(received['branchProvenance'], [
      {
        'branchNodeId': 'branch',
        'sourceNodeId': 'badge',
        'sourceOutcome': 'true',
        'routedPortId': 'true',
        'usedFallback': false
      },
    ]);
    expect((received['trace'] as List).map((entry) => (entry as Map)['nodeId']),
        ['start', 'badge', 'branch', 'gift', 'reward', 'end']);
    final bagFull = await simulate({
      'portsByNodeId': {'badge': 'true', 'gift': 'bagFull'}
    });
    expect(bagFull['status'], 'completed');
    expect(bagFull['proposedConsequences'], isEmpty);
    final refused = await simulate({
      'portsByNodeId': {'badge': 'false'}
    });
    expect(refused['status'], 'completed');
    expect(refused['proposedConsequences'], isEmpty);
  });

  test('missing input fails with a partial trace rather than choosing a port',
      () async {
    final result = await simulate({
      'portsByNodeId': {'badge': 'true'}
    });
    expect(result['status'], 'failed');
    expect(result['errorCode'], 'missingInput');
    expect(result['missingInputNodeId'], 'gift');
    expect((result['trace'] as List).map((entry) => (entry as Map)['nodeId']),
        ['start', 'badge', 'branch', 'gift']);
    expect(result['proposedConsequences'], isEmpty);
  });

  test(
      'invalid overrides and bounds are rejected and unused inputs are visible',
      () async {
    for (final inputs in [
      {
        'portsByNodeId': {'unknown': 'true'}
      },
      {
        'portsByNodeId': {'badge': 'victory'}
      },
      {
        'portsByNodeId': {'start': 'completed'}
      },
      {'maxSteps': 1001},
      {'maxSteps': 0},
      {'unexpected': true},
    ]) {
      await expectLater(
          simulate(inputs), throwsA(isA<NarrativeAuthoringException>()));
    }
    final unused = await simulate({
      'portsByNodeId': {'badge': 'false', 'gift': 'received'}
    });
    expect(unused['status'], 'failed');
    expect(unused['errorCode'], 'unusedInput');
    expect(unused['unusedInputNodeIds'], ['gift']);
    expect(unused['message'], contains('gift'));
    final limited = await simulate({
      'maxSteps': 1,
      'portsByNodeId': {'badge': 'true'}
    });
    expect(limited['errorCode'], 'stepLimitExceeded');
    expect(limited['trace'], hasLength(1));
  });

  test(
      'JSONL exposes discoverable simulation and preserves its read-only result',
      () async {
    final worker = JsonlWorker(api: api);
    final described = api.describeRead().toJson();
    expect(jsonEncode(described), contains('scene.simulate'));
    final response = jsonDecode((await worker.processLine(jsonEncode({
      'id': 'simulation',
      'command': 'query',
      'args': {
        'projectHandle': handle.value,
        'request': _request({
          'portsByNodeId': {'badge': 'false'}
        }).toJson()
      },
    }))));
    expect(response['status'], 'success');
    expect(response['data']['items'][0]['status'], 'completed');
  });
}

AuthoringQueryRequest _request(Map<String, Object?> parameters) =>
    AuthoringQueryRequest(
      resourceKind: 'scene',
      operation: AuthoringQueryOperation.get,
      ids: ['scene'],
      extensions: {'actionId': 'scene.simulate', 'parameters': parameters},
    );

SceneAsset _scene() => SceneAsset(
    id: 'scene',
    name: 'Simulation',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'badge',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                    sourceKind: SceneConditionSourceKind.badge,
                    sourceId: 'zephyr',
                    operator: SceneConditionOperator.isTrue))),
        SceneNode(
            id: 'gift',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.giveItem(itemId: 'tm23', quantity: 1))),
        SceneNode(
            id: 'branch',
            kind: SceneNodeKind.branchByOutcome,
            payload: SceneBranchByOutcomePayload(sourceNodeId: 'badge')),
        SceneNode(
            id: 'reward',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: 'received', value: true))),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        _edge('s', 'start', 'completed', 'badge', SceneEdgeKind.defaultFlow),
        _edge('yes', 'badge', 'true', 'branch', SceneEdgeKind.conditionTrue),
        _edge('no', 'badge', 'false', 'branch', SceneEdgeKind.conditionFalse),
        _edge(
            'ok', 'gift', 'received', 'reward', SceneEdgeKind.actionCompleted),
        _edge('full', 'gift', 'bagFull', 'end', SceneEdgeKind.actionCompleted),
        _edge('conditionTrue', 'branch', 'true', 'gift',
            SceneEdgeKind.branchOutcome),
        _edge('bagFull', 'branch', 'false', 'end', SceneEdgeKind.branchOutcome),
        _edge('done', 'reward', 'completed', 'end',
            SceneEdgeKind.actionCompleted),
      ],
    ));

SceneEdge _edge(
        String id, String from, String port, String to, SceneEdgeKind kind) =>
    SceneEdge(
        id: id, fromNodeId: from, fromPortId: port, toNodeId: to, kind: kind);
