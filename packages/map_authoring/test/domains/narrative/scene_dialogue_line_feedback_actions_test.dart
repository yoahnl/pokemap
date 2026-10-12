import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _actionId = 'scene.dialogue.lineFeedback.update';
const _source = '''
title: Start
---
Found!
-> Oui
    <<outcome yes>>
-> Non
    <<outcome no>>
Après.
===
''';

SceneDialogueLinePolicy _policy(
        {String nodeName = 'Start',
        int lineIndex = 0,
        String text = 'Found!',
        DialogueAudioCue? audioCue}) =>
    SceneDialogueLinePolicy(
        nodeName: nodeName,
        lineIndex: lineIndex,
        feedback: DialogueLineFeedback(
            segments: [
              DialogueTextSegment(text,
                  style: DialogueSegmentStyle(colorArgb: 0xff0070f8))
            ],
            revealIntervalMicros: 25000,
            advance: DialogueLineAdvancePolicy.autoAfterReveal(1000000),
            audioCue: audioCue));

void main() {
  test(
      'duplicate audio cue across two distinct lines is a precise domain refusal',
      () {
    final cue = DialogueAudioCue(mediaAssetId: 'cue', cueId: 'item_found');
    final project = _project(linePolicies: [
      _policy(lineIndex: 1, text: 'Après.', audioCue: cue)
    ]).copyWith(cinematicMediaAssets: [
      CinematicMediaAsset(
          id: 'cue',
          label: 'Found',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'media/found.ogg')
    ]);
    expect(
        () => const SceneActions().updateDialogueLineFeedback(project,
            maps: const [],
            sceneId: 'scene',
            nodeId: 'dialogue',
            linePolicy: _policy(audioCue: cue),
            dialogue: const YarnDialogueCompiler().compile(_source)),
        _invalid());
  });

  test(
      'typed update preserves choice policies, declared cancellation and other line feedback',
      () {
    final original = _project();
    final policy = _policy();
    final updated = const SceneActions().updateDialogueLineFeedback(original,
        maps: const [],
        sceneId: 'scene',
        nodeId: 'dialogue',
        linePolicy: policy,
        dialogue: const YarnDialogueCompiler().compile(_source));
    final before = _payload(original);
    final after = _payload(updated);
    expect(after.linePolicies, [policy, before.linePolicies.single]);
    expect(after.choicePolicies, before.choicePolicies);
    expect(after.declaredCancellationOutcomes, ['cancel']);
    expect(after.expectedOutcomes, before.expectedOutcomes);
    expect(
        updated.scenes.single.graph.edges, original.scenes.single.graph.edges);
    expect(
        SceneAsset.fromJson(
            jsonDecode(jsonEncode(updated.scenes.single.toJson()))
                as Map<String, dynamic>),
        updated.scenes.single);
  });

  test(
      'rejects unknown line scope, changed plain text and conflicting embedded feedback',
      () {
    final document = const YarnDialogueCompiler().compile(_source);
    for (final policy in [
      _policy(nodeName: 'Missing'),
      _policy(lineIndex: 9),
      _policy(text: 'Changed!')
    ]) {
      expect(
          () => const SceneActions().updateDialogueLineFeedback(_project(),
              maps: const [],
              sceneId: 'scene',
              nodeId: 'dialogue',
              linePolicy: policy,
              dialogue: document),
          _invalid());
    }
    final embedded = RuntimeDialogueDocument(nodes: [
      RuntimeDialogueNode(title: 'Start', steps: [
        RuntimeDialogueLine('Found!',
            feedback: DialogueLineFeedback(revealIntervalMicros: 1)),
        ...document.nodes.single.steps.skip(1),
      ])
    ]);
    expect(
        () => const SceneActions().updateDialogueLineFeedback(_project(),
            maps: const [],
            sceneId: 'scene',
            nodeId: 'dialogue',
            linePolicy: _policy(),
            dialogue: embedded),
        _invalid());
  });

  test(
      'validates exact icon identities and bounded nonlooping sound references',
      () {
    final actions = const SceneActions();
    final document = const YarnDialogueCompiler()
        .compile(_source.replaceFirst('Found!', 'Found!\uFFFC'));
    SceneDialogueLinePolicy icon(String id) => SceneDialogueLinePolicy(
        nodeName: 'Start',
        lineIndex: 0,
        feedback: DialogueLineFeedback(segments: [
          DialogueTextSegment('Found!'),
          DialogueIconSegment(assetId: id, widthPx: 24, heightPx: 24)
        ]));
    expect(
        () => actions.updateDialogueLineFeedback(_project(),
            maps: const [],
            sceneId: 'scene',
            nodeId: 'dialogue',
            linePolicy: icon('unknown'),
            dialogue: document),
        _invalid());
    final known = _project().copyWith(tilesets: const [
      ProjectTilesetEntry(
          id: 'item_icon', name: 'Item', relativePath: 'assets/item.png')
    ]);
    expect(
        _payload(actions.updateDialogueLineFeedback(known,
                maps: const [],
                sceneId: 'scene',
                nodeId: 'dialogue',
                linePolicy: icon('item_icon'),
                dialogue: document))
            .linePolicies
            .first,
        icon('item_icon'));
    for (final asset in [
      null,
      CinematicMediaAsset(
          id: 'cue',
          label: 'Music',
          kind: CinematicMediaAssetKind.music,
          relativePath: 'media/music.ogg'),
      CinematicMediaAsset(
          id: 'cue',
          label: 'Loop',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'media/loop.ogg',
          loopByDefault: true)
    ]) {
      final project =
          _project().copyWith(cinematicMediaAssets: [if (asset != null) asset]);
      expect(
          () => actions.updateDialogueLineFeedback(project,
              maps: const [],
              sceneId: 'scene',
              nodeId: 'dialogue',
              linePolicy: _policy(
                  audioCue: DialogueAudioCue(
                      mediaAssetId: 'cue', cueId: 'item_found')),
              dialogue: const YarnDialogueCompiler().compile(_source)),
          _invalid());
    }
    final sound = CinematicMediaAsset(
        id: 'cue',
        label: 'Found',
        kind: CinematicMediaAssetKind.sound,
        relativePath: 'media/found.ogg');
    expect(
        _payload(actions.updateDialogueLineFeedback(
                _project().copyWith(cinematicMediaAssets: [sound]),
                maps: const [],
                sceneId: 'scene',
                nodeId: 'dialogue',
                linePolicy: _policy(
                    audioCue: DialogueAudioCue(
                        mediaAssetId: 'cue', cueId: 'item_found')),
                dialogue: const YarnDialogueCompiler().compile(_source)))
            .linePolicies
            .first
            .feedback
            .audioCue!
            .cueId,
        'item_found');
  });

  test(
      'source update rejects feedback whose exact text or ordinal no longer matches before any write',
      () async {
    for (final source in [
      _source.replaceFirst('Found!', 'Changed!'),
      _source.replaceFirst('Found!\n', '')
    ]) {
      final fixture = await _Fixture.create(linePolicies: [_policy()]);
      addTearDown(fixture.dispose);
      final before = await fixture.projectFile.readAsBytes();
      final request = await fixture.request(
          'dialogue.source_update', {'dialogueId': 'choice', 'source': source});
      await expectLater(
          fixture.api.planMutation(fixture.opened.projectHandle, request),
          throwsA(isA<NarrativeAuthoringException>().having(
              (error) => error.code,
              'code',
              'dialogue.scene_line_policy_references_blocking')));
      expect(await fixture.projectFile.readAsBytes(), before);
      expect(await fixture.sourceFile.readAsString(), _source);
    }
  });

  test('whole scene upsert cannot bypass compiled line feedback validation',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final invalidScene =
        _project(linePolicies: [_policy(lineIndex: 9)]).scenes.single;
    final request =
        await fixture.request('scene.upsert', {'scene': invalidScene.toJson()});
    await expectLater(
        fixture.api.planMutation(fixture.opened.projectHandle, request),
        _invalid());
  });

  test(
      'direct API and JSONL discover, plan and apply typed feedback with reload and exact rejection',
      () async {
    for (final jsonl in [false, true]) {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final worker = JsonlWorker(api: fixture.readApi, mutations: fixture.api);
      Future<AuthoringResult> command(
              String name, Map<String, Object?> args) async =>
          AuthoringResult.fromJson(jsonDecode(await worker.processLine(
                  jsonEncode({'id': name, 'command': name, 'args': args})))
              as Map<String, dynamic>);
      final described = await command('describe', {});
      expect(jsonEncode(described.toJson()), contains(_actionId));
      final evidence = AuthoringFullParityCatalog.canonical()
          .requireMutationAction(_actionId)
          .endToEndEvidence
          .keys
          .toSet();
      expect(evidence, {
        AuthoringTransport.directApi,
        AuthoringTransport.cli,
        AuthoringTransport.mcp
      });
      final request = await fixture.request(_actionId, {
        'sceneId': 'scene',
        'nodeId': 'dialogue',
        'linePolicy': _policy().toJson()
      });
      final before = await fixture.projectFile.readAsBytes();
      final plan = jsonl
          ? (await command('plan', {
              'projectHandle': fixture.opened.projectHandle.value,
              'request': request.toJson()
            }))
              .data
          : await fixture.api.plan(fixture.opened.projectHandle, request);
      expect(await fixture.projectFile.readAsBytes(), before);
      final applied = jsonl
          ? (await command('apply', {
              'projectHandle': fixture.opened.projectHandle.value,
              'planId': plan['planId'],
              'operationId': 'line-feedback'
            }))
              .data
          : await fixture.api.apply(fixture.opened.projectHandle,
              planId: plan['planId']! as String, operationId: 'line-feedback');
      expect(applied['receipt'], isNotNull);
      final reloaded = await fixture.loader.load(fixture.opened.projectHandle);
      expect(_payload(reloaded.manifest).linePolicies.first, _policy());
      expect(_payload(reloaded.manifest).choicePolicies,
          _payload(_project()).choicePolicies);
      expect(
          _payload(reloaded.manifest).declaredCancellationOutcomes, ['cancel']);
      expect(await fixture.sourceFile.readAsString(), _source);
      for (final linePolicy in [
        _policy(text: 'Wrong').toJson(),
        {
          ..._policy().toJson(),
          'feedback': {
            ..._policy().feedback.toJson(),
            'revealIntervalMicros': -1
          }
        }
      ]) {
        final invalid = await fixture.request(_actionId, {
          'sceneId': 'scene',
          'nodeId': 'dialogue',
          'linePolicy': linePolicy
        });
        final rejected = await command('plan', {
          'projectHandle': fixture.opened.projectHandle.value,
          'request': invalid.toJson()
        });
        expect(rejected.status, AuthoringResultStatus.failure);
        expect(rejected.error!.code, AuthoringErrorCode.validationFailed);
        expect(rejected.error!.details['domainCode'],
            'scene.dialogue.line_feedback.invalid');
      }
    }
  });
}

Matcher _invalid() => throwsA(isA<NarrativeAuthoringException>().having(
    (error) => error.code, 'code', 'scene.dialogue.line_feedback.invalid'));

SceneYarnDialoguePayload _payload(ProjectManifest project) =>
    project.scenes.single.graph.nodes
        .singleWhere((node) => node.id == 'dialogue')
        .payload as SceneYarnDialoguePayload;

ProjectManifest _project({List<SceneDialogueLinePolicy>? linePolicies}) =>
    ProjectManifest(
        name: 'Line feedback',
        maps: const [],
        tilesets: const [],
        dialogues: const [
          ProjectDialogueEntry(
              id: 'choice',
              name: 'Choice',
              relativePath: 'dialogues/choice.yarn',
              declaredOutcomes: [
                DialogueDeclaredOutcome(id: 'yes', label: 'Yes'),
                DialogueDeclaredOutcome(id: 'no', label: 'No')
              ])
        ],
        scenes: [
          SceneAsset(
              id: 'scene',
              name: 'Scene',
              graph: SceneGraph(startNodeId: 'start', nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                    id: 'dialogue',
                    kind: SceneNodeKind.yarnDialogue,
                    payload: SceneYarnDialoguePayload(
                        dialogueId: 'choice',
                        expectedOutcomes: const ['yes', 'no', 'cancel'],
                        choicePolicies: const [
                          SceneDialogueChoicePolicy(
                              nodeName: 'Start',
                              cancellation:
                                  SceneDialogueChoiceCancellation.branch(
                                      'cancel'))
                        ],
                        linePolicies: linePolicies ??
                            [
                              SceneDialogueLinePolicy(
                                  nodeName: 'Start',
                                  lineIndex: 1,
                                  feedback: DialogueLineFeedback(
                                      segments: [DialogueTextSegment('Après.')],
                                      revealIntervalMicros: 1))
                            ])),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ], edges: [
                SceneEdge(
                    id: 'entry',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'dialogue',
                    kind: SceneEdgeKind.defaultFlow),
                SceneEdge(
                    id: 'completed',
                    fromNodeId: 'dialogue',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: SceneEdgeKind.defaultFlow),
                for (final id in ['yes', 'no', 'cancel'])
                  SceneEdge(
                      id: id,
                      fromNodeId: 'dialogue',
                      fromPortId: id,
                      toNodeId: 'end',
                      kind: SceneEdgeKind.dialogueOutcome)
              ]))
        ]);

final class _Fixture {
  _Fixture(this.directory, this.handles, this.opened, this.loader, this.api,
      this.readApi);
  final Directory directory;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  final AuthoringReadApi readApi;
  File get projectFile => File('${directory.path}/project.json');
  File get sourceFile => File('${directory.path}/dialogues/choice.yarn');

  static Future<_Fixture> create(
      {List<SceneDialogueLinePolicy>? linePolicies}) async {
    final directory =
        await Directory.systemTemp.createTemp('scene_line_feedback_');
    await Directory('${directory.path}/dialogues').create();
    await File('${directory.path}/dialogues/choice.yarn')
        .writeAsString(_source);
    await File('${directory.path}/project.json').writeAsString(
        jsonEncode(_project(linePolicies: linePolicies).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(directory.path);
    final loader = ProjectSnapshotLoader(handles: handles);
    final api =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
    await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(directory, handles, opened, loader, api,
        AuthoringReadApi(openService: opener, snapshotLoader: loader));
  }

  Future<AuthoringRequest> request(
          String actionId, Map<String, Object?> parameters) async =>
      AuthoringRequest(
          requestId: 'feedback',
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: (await loader.load(opened.projectHandle)).revision,
          idempotencyKey: jsonEncode(parameters),
          parameters: parameters);

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}
