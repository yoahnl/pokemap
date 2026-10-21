import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('Scene batch advertises bounded atomic upsert semantics', () {
    final descriptor = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((entry) => entry.id == 'scene.upsert_batch');
    expect(descriptor.resourceKinds, ['project', 'scene']);
    expect(descriptor.extensions['batch'], {
      'minScenes': 1,
      'maxScenes': 128,
      'uniqueBy': 'id',
      'semantics': 'createOrUpdate',
      'atomic': true,
    });
    expect(descriptor.guarantees, containsAll(AuthoringGuarantee.values));
  });

  test('Scene batch retains unit diagnostics and emits one diff for 128 scenes',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final snapshot = await f.snapshots.load(f.project);
    final invalid = _scene('bad', dialogue: 'missing');
    NarrativeAuthoringException failure(void Function() action) {
      try {
        action();
      } on NarrativeAuthoringException catch (error) {
        return error;
      }
      throw StateError('Expected refusal');
    }

    final unit = failure(() => const SceneActions()
        .upsert(snapshot.manifest, maps: snapshot.maps, scene: invalid));
    final batch = failure(() => const SceneActions().upsertBatch(
        snapshot.manifest,
        maps: snapshot.maps,
        scenes: [_scene('first'), invalid]));
    expect(batch.code, unit.code);
    expect(batch.message, unit.message);
    expect(batch.details, unit.details);
    final draft = await const SceneActions().prepare(AuthoringPlanningContext(
      snapshot: snapshot,
      request: await f.request(
          {'scenes': List.generate(128, (i) => _scene('s_$i').toJson())}),
      planId: 'batch-projection',
      seed: 1,
    ));
    expect(draft.changeSet.changes, hasLength(1));
    expect(draft.changeSet.diff.entries, hasLength(1));
    expect(draft.changeSet.changes.single.storageKey, 'project.json');
    expect(draft.preview['diagnosticDelta'], isA<Map>());
    expect(draft.preview['canPublish'], isFalse);
  });

  for (final wire in [false, true]) {
    final transport = wire ? 'JSONL' : 'direct API';
    test(
        '$transport publishes one change, replays, reopens and undoes atomically',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final scenes = [
        _scene('existing', name: 'Updated'),
        _scene('new_a'),
        _scene('new_b')
      ];
      final planned = await f.plan(
          await f.request({'scenes': scenes.map((s) => s.toJson()).toList()}),
          wire);
      expect(await f.manifest.readAsBytes(), before);
      final preview =
          ((planned['receipt'] as Map)['extensions'] as Map)['preview'] as Map;
      expect(preview['canPublish'], isFalse);
      expect(preview['sceneIds'], scenes.map((s) => s.id).toList());
      final applied = await f.apply(planned['planId'] as String, wire);
      final saved = await f.manifest.readAsBytes();
      expect((await f.apply(planned['planId'] as String, wire))['receipt'],
          applied['receipt']);
      expect(await f.manifest.readAsBytes(), saved);
      await f.reopen();
      final snapshot = await f.snapshots.load(f.project);
      expect(snapshot.manifest.scenes.map((s) => s.id),
          ['existing', 'keep', 'unrelated_broken', 'new_a', 'new_b']);
      expect(
          snapshot.manifest.scenes
              .where((s) => scenes.any((v) => s.id == v.id)),
          scenes);
      final receipt = applied['receipt'] as Map;
      final entryId = receipt['receiptId'] as String;
      if (wire) {
        final undone = await f.command('undo', {
          'projectHandle': f.project.value,
          'entryId': entryId,
          'idempotencyKey': 'undo-batch'
        });
        expect(undone.status, AuthoringResultStatus.success,
            reason: jsonEncode(undone.toJson()));
      } else {
        await f.mutations
            .undo(f.project, entryId: entryId, idempotencyKey: 'undo-batch');
      }
      expect(await f.manifest.readAsBytes(), before);
      expect(await f.map.readAsBytes(), f.mapBefore);
    });

    test(
        '$transport rejects every malformed batch and an invalid final scene without a write',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final valid = _scene('first').toJson();
      final cases = <(Map<String, Object?>, String)>[
        ({}, 'scene.batch_invalid'),
        ({'scenes': null}, 'scene.batch_invalid'),
        ({'scenes': {}}, 'scene.batch_invalid'),
        ({'scenes': []}, 'scene.batch_invalid'),
        (
          {'scenes': List.generate(129, (i) => _scene('s_$i').toJson())},
          'scene.batch_invalid'
        ),
        (
          {
            'scenes': [valid],
            'unknown': true
          },
          'scene.batch_invalid'
        ),
        (
          {
            'scenes': [valid, valid]
          },
          'scene.batch_duplicate_id'
        ),
        (
          {
            'scenes': [valid, 42]
          },
          'scene.invalid'
        ),
        (
          {
            'scenes': [valid, <String, Object?>{}]
          },
          'scene.invalid'
        ),
        (
          {
            'scenes': [valid, _scene('bad', dialogue: 'missing').toJson()]
          },
          'scene.publication_blocked'
        ),
      ];
      for (final (parameters, code) in cases) {
        final request = await f.request(parameters);
        if (wire) {
          final result = await f.command('plan',
              {'projectHandle': f.project.value, 'request': request.toJson()});
          expect(result.status, AuthoringResultStatus.failure,
              reason: jsonEncode(result.toJson()));
          expect(result.error!.details['domainCode'], code);
        } else {
          await expectLater(
              f.mutations.plan(f.project, request),
              throwsA(isA<NarrativeAuthoringException>()
                  .having((e) => e.code, 'code', code)));
        }
        expect(await f.manifest.readAsBytes(), before);
        expect(await f.map.readAsBytes(), f.mapBefore);
      }
    });

    test(
        '$transport retains compiled dialogue policies and move catalogue checks on every submitted scene',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final party = _partyScene('party', 'tackle');
      final dialogue = _policyScene('policy');
      await f.plan(
          await f.request({
            'scenes': [party.toJson(), dialogue.toJson()]
          }),
          wire);
      Future<void> refuses(SceneAsset last, String code) async {
        final request = await f.request({
          'scenes': [_scene('first').toJson(), last.toJson()]
        });
        if (wire) {
          final result = await f.command('plan',
              {'projectHandle': f.project.value, 'request': request.toJson()});
          expect(result.status, AuthoringResultStatus.failure);
          expect(result.error!.details['domainCode'], code);
        } else {
          await expectLater(
              f.mutations.plan(f.project, request),
              throwsA(isA<NarrativeAuthoringException>()
                  .having((e) => e.code, 'code', code)));
        }
        expect(await f.manifest.readAsBytes(), before);
      }

      await refuses(
          _partyScene('party', 'missing'), 'scene.party_move_ref_unknown');
      await refuses(_policyScene('policy', choiceIndex: 9),
          'scene.dialogue.choice_policy.invalid');
      await refuses(_policyScene('policy', lineNode: 'Missing'),
          'scene.dialogue.line_feedback.invalid');
      await f.plan(
          await f.request({
            'scenes': [_giftScene('gift', 'tackle').toJson()]
          }),
          wire);
      await refuses(
          _giftScene('gift', 'missing'), 'scene.pokemon_move_ref_unknown');
      await File('${f.directory.path}/data/moves.json').writeAsString('{');
      await refuses(party, 'scene.party_move_catalog_unavailable');
      expect(await f.map.readAsBytes(), f.mapBefore);
    });

    test('$transport accepts 128 and refuses stale and dry-run application',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final all = {
        'scenes': List.generate(128, (i) => _scene('s_$i').toJson())
      };
      final stale = await f.plan(await f.request(all), wire);
      final dry = await f.plan(await f.request(all, dryRun: true), wire);
      Future<void> refuses(String plan, String code) async {
        if (wire) {
          final r = await f.command('apply', {
            'projectHandle': f.project.value,
            'planId': plan,
            'operationId': code
          });
          expect(r.status, AuthoringResultStatus.failure);
          expect(r.error!.details['domainCode'], code);
        } else {
          await expectLater(
              f.mutations.apply(f.project, planId: plan, operationId: code),
              throwsA(isA<AuthoringPlanException>()
                  .having((e) => e.code, 'code', code)));
        }
      }

      await refuses(dry['planId'] as String, 'plan.dry_run_not_applicable');
      expect(await f.manifest.readAsBytes(), before);
      final publish = await f.plan(await f.request(all), wire);
      await f.apply(publish['planId'] as String, wire);
      expect(
          (await f.snapshots.load(f.project)).manifest.scenes, hasLength(131));
      final saved = await f.manifest.readAsBytes();
      await refuses(stale['planId'] as String, 'plan.stale');
      expect(await f.manifest.readAsBytes(), saved);
      expect(await f.map.readAsBytes(), f.mapBefore);
    });
  }
}

SceneAsset _scene(String id, {String? name, String? dialogue}) => SceneAsset(
      id: id,
      name: name ?? id,
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        if (dialogue != null)
          SceneNode(
              id: 'dialogue',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: dialogue)),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(
            id: 'first',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: dialogue == null ? 'end' : 'dialogue',
            kind: SceneEdgeKind.defaultFlow),
        if (dialogue != null)
          SceneEdge(
              id: 'last',
              fromNodeId: 'dialogue',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow),
      ]),
    );

SceneAsset _partyScene(String id, String move) => SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'condition',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
                conditionSource:
                    SceneConditionSource.partyKnowsMove(moveId: move))),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(
            id: 'entry',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'condition',
            kind: SceneEdgeKind.defaultFlow),
        SceneEdge(
            id: 'yes',
            fromNodeId: 'condition',
            fromPortId: 'true',
            toNodeId: 'end',
            kind: SceneEdgeKind.conditionTrue),
        SceneEdge(
            id: 'no',
            fromNodeId: 'condition',
            fromPortId: 'false',
            toNodeId: 'end',
            kind: SceneEdgeKind.conditionFalse),
      ]),
    );

SceneAsset _policyScene(String id,
        {int choiceIndex = 0, String lineNode = 'Start'}) =>
    SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
                dialogueId: 'choice',
                expectedOutcomes: [
                  'yes',
                  'no'
                ],
                linePolicies: [
                  SceneDialogueLinePolicy(
                      nodeName: lineNode,
                      lineIndex: 0,
                      feedback: DialogueLineFeedback(
                          segments: [DialogueTextSegment('Hello')]))
                ],
                choicePolicies: [
                  SceneDialogueChoicePolicy(
                      nodeName: 'Start',
                      choiceIndex: choiceIndex,
                      defaultOutcomeId: 'yes',
                      cancellation:
                          SceneDialogueChoiceCancellation.choice('no')),
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
        for (final port in ['yes', 'no'])
          SceneEdge(
              id: port,
              fromNodeId: 'dialogue',
              fromPortId: port,
              toNodeId: 'end',
              kind: SceneEdgeKind.dialogueOutcome),
      ]),
    );

SceneAsset _giftScene(String id, String move) => SceneAsset.fromJson({
      'id': id,
      'name': id,
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          {
            'id': 'gift',
            'kind': 'action',
            'payload': {
              'consequence': {
                'kind': 'givePokemonFromCatalog',
                'speciesId': 'sproutle',
                'formId': 'sunny',
                'level': 8,
                'moveIds': [move]
              }
            }
          },
          {'id': 'end', 'kind': 'end'},
        ],
        'edges': [
          {
            'id': 'entry',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'gift',
            'kind': 'default'
          },
          {
            'id': 'exit',
            'fromNodeId': 'gift',
            'fromPortId': 'completed',
            'toNodeId': 'end',
            'kind': 'actionCompleted'
          },
        ],
      },
    });

final class _Fixture {
  _Fixture(this.directory, this.snapshots, this.mutations, this.worker,
      this.mapBefore);

  final Directory directory;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  final List<int> mapBefore;
  late WorkspaceHandle workspace;
  late ProjectHandle project;
  var sequence = 0;

  File get manifest => File('${directory.path}/project.json');
  File get map => File('${directory.path}/maps/map.json');

  static Future<_Fixture> create() async {
    final directory = await Directory.systemTemp.createTemp('scene-batch-');
    await Directory('${directory.path}/maps').create();
    final project = ProjectManifest(
      name: 'Scene batch transport',
      tilesets: const [],
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
      ],
      facts: [NarrativeFactDefinition(id: 'fact_gate', label: 'Gate')],
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
        _scene('existing'),
        _scene('keep'),
        SceneAsset(
            id: 'unrelated_broken',
            name: 'Broken before batch',
            graph: SceneGraph(startNodeId: 'start', nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
            ], edges: const []))
      ],
    );
    final map = const MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 6, height: 6),
        entities: [
          MapEntity(
              id: 'npc',
              name: 'NPC',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 1, y: 1),
              npc: MapEntityNpcData(displayName: 'NPC')),
        ]);
    await Directory('${directory.path}/dialogues').create();
    await File('${directory.path}/dialogues/choice.yarn').writeAsString(
        'title: Start\n---\nHello\n-> Yes\n    <<outcome yes>>\n-> No\n    <<outcome no>>\n===\n');
    await Directory('${directory.path}/data').create();
    await File('${directory.path}/data/moves.json').writeAsString(jsonEncode({
      'schemaVersion': 1,
      'kind': 'catalog',
      'catalog': 'moves',
      'entries': [
        {'id': 'tackle', 'name': 'Tackle'}
      ]
    }));
    await File('${directory.path}/project.json').writeAsString(jsonEncode(
        project
            .copyWith(
                pokemon: project.pokemon.copyWith(
                    enabled: true, catalogFiles: {'moves': 'data/moves.json'}))
            .toJson()));
    final mapFile = File('${directory.path}/maps/map.json');
    await mapFile.writeAsString(jsonEncode(map.toJson()));
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
    final fixture = _Fixture(
        directory,
        snapshots,
        mutations,
        JsonlWorker(api: api, mutations: mutations),
        await mapFile.readAsBytes());
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
        'id': 'world-rule-${++sequence}',
        'command': command,
        'args': args,
      }))) as Map<String, dynamic>);

  Future<AuthoringRequest> request(Map<String, Object?> parameters,
      {bool dryRun = false}) async {
    final id = 'batch-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: 'scene.upsert_batch',
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: parameters,
        dryRun: dryRun);
  }

  Future<Map<String, Object?>> plan(AuthoringRequest request, bool wire) async {
    if (!wire) return mutations.plan(project, request);
    final result = await command('plan', {
      'projectHandle': project.value,
      'request': request.toJson(),
    });
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    return result.data;
  }

  Future<Map<String, Object?>> apply(String planId, bool wire) async {
    if (!wire) {
      return mutations.apply(project,
          planId: planId, operationId: 'apply-$planId');
    }
    final result = await command('apply', {
      'projectHandle': project.value,
      'planId': planId,
      'operationId': 'apply-$planId',
    });
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    return result.data;
  }

  Future<void> dispose() async {
    await command('close', {'workspaceHandle': workspace.value});
    await directory.delete(recursive: true);
  }
}
