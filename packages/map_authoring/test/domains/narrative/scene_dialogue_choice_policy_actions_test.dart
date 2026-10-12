import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _actionId = 'scene.dialogue.choicePolicy.update';
const _source = '''
title: Start
---
-> Oui
    <<outcome yes>>
-> Non
    <<outcome no>>
===
''';
const _policy = SceneDialogueChoicePolicy(nodeName: 'Start', defaultOutcomeId: 'yes',
    cancellation: SceneDialogueChoiceCancellation.choice('no'));

void main() {
  test('disabling cancellation preserves its declared scene branch and graph', () {
    const branch = SceneDialogueChoicePolicy(nodeName: 'Start',
      cancellation: SceneDialogueChoiceCancellation.branch('cancel'));
    final original = _project(choicePolicies: const [branch], cancelBranch: true);
    final updated = const SceneActions().updateDialogueChoicePolicy(original,
      maps: const [], sceneId: 'scene', nodeId: 'dialogue',
      choicePolicy: const SceneDialogueChoicePolicy(nodeName: 'Start'),
      dialogue: const YarnDialogueCompiler().compile(_source));
    expect(_payload(updated).choicePolicies.single.cancellation.kind,
      SceneDialogueChoiceCancellationKind.disabled);
    expect(_payload(updated).expectedOutcomes, ['yes', 'no', 'cancel']);
    expect(updated.scenes.single.graph.edges, original.scenes.single.graph.edges);
    expect(SceneAsset.fromJson(jsonDecode(jsonEncode(updated.scenes.single.toJson()))
      as Map<String, dynamic>), updated.scenes.single);
  });
  test('JSONL reports a dangling choice policy as an exact validation error', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final worker = JsonlWorker(api: fixture.readApi, mutations: fixture.api);
    final request = await fixture.request(const SceneDialogueChoicePolicy(nodeName: 'Start', choiceIndex: 2));
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
      'id': 'invalid-policy', 'command': 'plan', 'args': {
        'projectHandle': fixture.opened.projectHandle.value, 'request': request.toJson(),
      },
    }))) as Map<String, dynamic>);
    expect(result.status, AuthoringResultStatus.failure);
    expect(result.error!.code, AuthoringErrorCode.validationFailed);
    expect(result.error!.details['domainCode'], 'scene.dialogue.choice_policy.invalid');
  });

  test('dialogue source update rejects a dangling cancellation choice before any disk write', () async {
    final fixture = await _Fixture.create(choicePolicies: const [_policy]);
    addTearDown(fixture.dispose);
    final request = AuthoringRequest(requestId: 'remove-choice', actionId: 'dialogue.source_update', actionVersion: 1,
      workspaceHandle: fixture.opened.workspaceHandle.value,
      expectedRevision: (await fixture.loader.load(fixture.opened.projectHandle)).revision,
      idempotencyKey: 'remove-choice',
      parameters: {'dialogueId': 'choice', 'source': 'title: Start\n---\n-> Oui\n    <<outcome yes>>\n===\n'},
    );
    await expectLater(fixture.api.planMutation(fixture.opened.projectHandle, request),
      throwsA(isA<NarrativeAuthoringException>().having((error) => error.code, 'code', 'dialogue.scene_choice_policy_references_blocking')));
    expect(await File('${fixture.directory.path}/dialogues/choice.yarn').readAsString(), _source);
  });

  test('direct typed action validates the exact compiled choice scope', () {
    final project = const SceneActions().updateDialogueChoicePolicy(_project(),
      maps: const [], sceneId: 'scene', nodeId: 'dialogue', choicePolicy: _policy,
      dialogue: const YarnDialogueCompiler().compile(_source));
    expect(_payload(project).choicePolicies, [_policy]);
    expect(SceneAsset.fromJson(jsonDecode(jsonEncode(project.scenes.single.toJson())) as Map<String, dynamic>), project.scenes.single);
    expect(() => const SceneActions().updateDialogueChoicePolicy(_project(),
      maps: const [], sceneId: 'scene', nodeId: 'dialogue',
      choicePolicy: const SceneDialogueChoicePolicy(nodeName: 'Missing'),
      dialogue: const YarnDialogueCompiler().compile(_source)), throwsA(isA<NarrativeAuthoringException>().having((error) => error.code, 'code', 'scene.dialogue.choice_policy.invalid')));
  });

  test('discoverable direct and JSONL plans preserve cancellation after disk reload', () async {
    for (final jsonl in [false, true]) {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final worker = JsonlWorker(api: fixture.readApi, mutations: fixture.api);
      Future<AuthoringResult> command(String command, Map<String, Object?> args) async =>
          AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
            'id': command, 'command': command, 'args': args,
          }))) as Map<String, dynamic>);
      final catalog = await command('describe', {});
      expect(jsonEncode(catalog.toJson()), contains(_actionId));
      final parity = AuthoringFullParityCatalog.canonical().requireMutationAction(_actionId);
      expect(parity.endToEndEvidence.keys.toSet(), AuthoringTransport.values.toSet());
      final request = await fixture.request(_policy);
      final before = await fixture.projectFile.readAsBytes();
      final plan = jsonl
          ? (await command('plan', {'projectHandle': fixture.opened.projectHandle.value, 'request': request.toJson()})).data
          : await fixture.api.plan(fixture.opened.projectHandle, request);
      expect(await fixture.projectFile.readAsBytes(), before);
      final applied = jsonl
          ? (await command('apply', {'projectHandle': fixture.opened.projectHandle.value, 'planId': plan['planId'], 'operationId': 'choice-policy'})).data
          : await fixture.api.apply(fixture.opened.projectHandle, planId: plan['planId']! as String, operationId: 'choice-policy');
      expect(applied['receipt'], isNotNull);
      final reloaded = await fixture.loader.load(fixture.opened.projectHandle);
      expect(_payload(reloaded.manifest).choicePolicies, [_policy]);
      expect(await File('${fixture.directory.path}/dialogues/choice.yarn').readAsString(), _source);
      final invalid = await fixture.request(const SceneDialogueChoicePolicy(nodeName: 'Start', choiceIndex: 2));
      if (jsonl) {
        final rejected = await command('plan', {'projectHandle': fixture.opened.projectHandle.value, 'request': invalid.toJson()});
        expect(rejected.status, isNot(AuthoringResultStatus.success));
        expect(rejected.error!.code, AuthoringErrorCode.validationFailed);
        expect(rejected.error!.details['domainCode'], 'scene.dialogue.choice_policy.invalid');
      } else {
        await expectLater(fixture.api.planMutation(fixture.opened.projectHandle, invalid), throwsA(anything));
      }
      expect(_payload((await fixture.loader.load(fixture.opened.projectHandle)).manifest).choicePolicies, [_policy]);
    }
  });
}

SceneYarnDialoguePayload _payload(ProjectManifest project) =>
    project.scenes.single.graph.nodes.singleWhere((node) => node.id == 'dialogue').payload as SceneYarnDialoguePayload;

ProjectManifest _project({List<SceneDialogueChoicePolicy> choicePolicies = const [], bool cancelBranch = false}) => ProjectManifest(name: 'Choice policy', maps: const [], tilesets: const [],
  dialogues: const [ProjectDialogueEntry(id: 'choice', name: 'Choice', relativePath: 'dialogues/choice.yarn',
    declaredOutcomes: [DialogueDeclaredOutcome(id: 'yes', label: 'Yes'), DialogueDeclaredOutcome(id: 'no', label: 'No')])],
  scenes: [SceneAsset(id: 'scene', name: 'Scene', graph: SceneGraph(startNodeId: 'start', nodes: [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    SceneNode(id: 'dialogue', kind: SceneNodeKind.yarnDialogue,
      payload: SceneYarnDialoguePayload(dialogueId: 'choice', expectedOutcomes: ['yes', 'no', if (cancelBranch) 'cancel'], choicePolicies: choicePolicies)),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ], edges: [
    SceneEdge(id: 'entry', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'dialogue', kind: SceneEdgeKind.defaultFlow),
    SceneEdge(id: 'completed', fromNodeId: 'dialogue', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.defaultFlow),
    for (final id in ['yes', 'no', if (cancelBranch) 'cancel']) SceneEdge(id: id, fromNodeId: 'dialogue', fromPortId: id, toNodeId: 'end', kind: SceneEdgeKind.dialogueOutcome),
  ]))]);

final class _Fixture {
  _Fixture(this.directory, this.handles, this.opened, this.loader, this.api, this.readApi);
  final Directory directory;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  final AuthoringReadApi readApi;
  File get projectFile => File('${directory.path}/project.json');

  static Future<_Fixture> create({List<SceneDialogueChoicePolicy> choicePolicies = const []}) async {
    final directory = await Directory.systemTemp.createTemp('scene_choice_policy_');
    await Directory('${directory.path}/dialogues').create();
    await File('${directory.path}/dialogues/choice.yarn').writeAsString(_source);
    await File('${directory.path}/project.json').writeAsString(jsonEncode(_project(choicePolicies: choicePolicies).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(directory.path);
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
    await api.attachProject(projectRootPath: directory.path, workspaceHandle: opened.workspaceHandle, projectHandle: opened.projectHandle);
    return _Fixture(directory, handles, opened, loader, api, AuthoringReadApi(openService: opener, snapshotLoader: loader));
  }

  Future<AuthoringRequest> request(SceneDialogueChoicePolicy policy) async => AuthoringRequest(
    requestId: 'policy', actionId: _actionId, actionVersion: 1,
    workspaceHandle: opened.workspaceHandle.value,
    expectedRevision: (await loader.load(opened.projectHandle)).revision,
    idempotencyKey: jsonEncode(policy.toJson()),
    parameters: {'sceneId': 'scene', 'nodeId': 'dialogue', 'choicePolicy': policy.toJson()},
  );

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}
