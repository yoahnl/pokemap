import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('World Rule batch advertises bounded atomic upsert semantics', () {
    final descriptors = AuthoringMutationDispatcher.canonical()
        .descriptors
        .where((descriptor) => descriptor.id == 'world_rule.upsert_batch');
    expect(descriptors, hasLength(1));
    final descriptor = descriptors.single;
    expect(descriptor.riskLevel, AuthoringRiskLevel.medium);
    expect(descriptor.resourceKinds, ['project', 'worldRule']);
    expect(descriptor.extensions['batch'], {
      'minRules': 1,
      'maxRules': 128,
      'uniqueBy': 'id',
      'semantics': 'createOrUpdate',
      'atomic': true,
    });
    expect(descriptor.guarantees, containsAll(AuthoringGuarantee.values));
  });

  test('World Rule batch produces one project change and one diagnostic delta',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final snapshot = await f.snapshots.load(f.project);
    final request = await f.request({
      'rules': List.generate(128, _indexedRule),
    });
    final draft = const FactRuleActions().build(AuthoringPlanningContext(
      snapshot: snapshot,
      request: request,
      planId: 'batch-projection',
      seed: 1,
    ));
    expect(draft.changeSet.changes, hasLength(1));
    expect(draft.changeSet.diff.entries, hasLength(1));
    expect(draft.changeSet.changes.single.storageKey, 'project.json');
    expect(draft.projectedProject!.worldRules, hasLength(130));
    expect(draft.preview['ruleIds'],
        List.generate(128, (index) => 'world_rule_batch_$index'));
    expect(draft.preview['diagnosticDelta'], isA<Map>());
    expect(draft.preview['canPublish'], isFalse);
    expect(await f.map.readAsBytes(), f.mapBefore);
  });

  for (final wire in [false, true]) {
    final transport = wire ? 'JSONL' : 'direct API';
    test('$transport matches canonical mixed upserts and reopens atomically',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final rules = [
        _rule('world_rule_same_label', ' Same label '),
        _rule('world_rule_existing', ' Renamed existing ', priority: 12),
        _rule('world_rule_same_label_2', 'Same label'),
      ];
      final request = await f.request({'rules': rules});
      final planned = await f.plan(request, wire);
      expect(await f.manifest.readAsBytes(), before);
      final preview = (planned['receipt'] as Map)['extensions'] as Map;
      expect((preview['preview'] as Map)['canPublish'], isFalse);
      final applied = await f.apply(planned['planId'] as String, wire);
      final savedBytes = await f.manifest.readAsBytes();
      final replay = await f.apply(planned['planId'] as String, wire);
      expect(replay['receipt'], applied['receipt']);
      expect(await f.manifest.readAsBytes(), savedBytes);
      await f.reopen();
      final snapshot = await f.snapshots.load(f.project);
      var canonical = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(before)) as Map<String, dynamic>);
      for (final json in rules) {
        final rule = WorldRuleDefinition.fromJson(json);
        canonical = canonical.worldRules.any((item) => item.id == rule.id)
            ? const FactRuleActions().updateWorldRuleDefinition(canonical,
                maps: snapshot.maps, rule: rule)
            : const FactRuleActions()
                .createWorldRule(canonical, maps: snapshot.maps, rule: rule);
      }
      expect(snapshot.manifest.toJson(), canonical.toJson());
      expect(snapshot.manifest.worldRules.map((rule) => rule.id), [
        'world_rule_existing',
        'world_rule_keep',
        'world_rule_same_label',
        'world_rule_same_label_2',
      ]);
      expect(await f.map.readAsBytes(), f.mapBefore);
    });

    test('$transport rejects malformed bounds duplicates and last invalid rule',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final valid = _rule('world_rule_first', 'First');
      final cases = <(Map<String, Object?>, String, int?)>[
        ({}, 'world_rule.batch_invalid', null),
        ({'rules': null}, 'world_rule.batch_invalid', null),
        ({'rules': {}}, 'world_rule.batch_invalid', null),
        ({'rules': []}, 'world_rule.batch_invalid', null),
        (
          {'rules': List.generate(129, _indexedRule)},
          'world_rule.batch_invalid',
          null
        ),
        (
          {
            'rules': [valid],
            'unknown': true
          },
          'world_rule.batch_invalid',
          null
        ),
        (
          {
            'rules': [valid, valid]
          },
          'world_rule.batch_duplicate_id',
          1
        ),
        (
          {
            'rules': [valid, 42]
          },
          'world_rule.batch_rule_invalid',
          1
        ),
        (
          {
            'rules': [valid, <String, dynamic>{}]
          },
          'world_rule.batch_rule_invalid',
          1
        ),
        (
          {
            'rules': [valid, _rule('world_rule_wrong', 'Different label')]
          },
          'world_rule.batch_rejected',
          1
        ),
        (
          {
            'rules': [valid, _rule('world_rule_bad', 'Bad', factId: 'missing')]
          },
          'world_rule.batch_rejected',
          1
        ),
        (
          {
            'rules': [valid, _rule('world_rule_bad', 'Bad', mapId: 'missing')]
          },
          'world_rule.batch_rejected',
          1
        ),
        (
          {
            'rules': [
              valid,
              _rule('world_rule_bad', 'Bad', entityId: 'missing')
            ]
          },
          'world_rule.batch_rejected',
          1
        ),
        (
          {
            'rules': [
              valid,
              _rule('world_rule_bad', 'Bad', dialogue: 'missing')
            ]
          },
          'world_rule.batch_rejected',
          1
        ),
        (
          {
            'rules': [valid, _rule('world_rule_bad', 'Bad', badEffect: true)]
          },
          'world_rule.batch_rejected',
          1
        ),
      ];
      for (final (parameters, code, index) in cases) {
        final request = await f.request(parameters);
        if (wire) {
          final failure = await f.command('plan', {
            'projectHandle': f.project.value,
            'request': request.toJson(),
          });
          expect(failure.status, AuthoringResultStatus.failure);
          expect(failure.error!.details['domainCode'], code);
          if (index != null) {
            expect(failure.error!.details['index'], index);
            expect(failure.error!.details['reason'], isA<String>());
          }
        } else {
          await expectLater(
            f.mutations.plan(f.project, request),
            throwsA(isA<NarrativeAuthoringException>()
                .having((error) => error.code, 'code', code)
                .having((error) => error.details['index'], 'index', index)
                .having(
                    (error) =>
                        index == null || error.details['reason'] is String,
                    'indexed reason',
                    isTrue)),
          );
        }
        expect(await f.manifest.readAsBytes(), before);
        expect(await f.map.readAsBytes(), f.mapBefore);
      }
    });

    test('$transport accepts 128 rules and rejects an earlier stale plan',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final planned = await f.plan(
          await f.request({'rules': List.generate(128, _indexedRule)}), wire);
      final stale = await f.plan(
          await f.request({
            'rules': [_rule('world_rule_stale', 'Stale')]
          }),
          wire);
      await f.apply(planned['planId'] as String, wire);
      final beforeStale = await f.manifest.readAsBytes();
      if (wire) {
        final failure = await f.command('apply', {
          'projectHandle': f.project.value,
          'planId': stale['planId'],
          'operationId': 'stale',
        });
        expect(failure.status, AuthoringResultStatus.failure);
        expect(failure.error!.details['domainCode'], 'plan.stale');
      } else {
        await expectLater(
            f.mutations.apply(f.project,
                planId: stale['planId'] as String, operationId: 'stale'),
            throwsA(isA<AuthoringPlanException>()
                .having((error) => error.code, 'code', 'plan.stale')));
      }
      expect((await f.snapshots.load(f.project)).manifest.worldRules,
          hasLength(130));
      expect(await f.manifest.readAsBytes(), beforeStale);
      expect(await f.map.readAsBytes(), f.mapBefore);
    });

    test('$transport dry run cannot publish the batch', () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final planned = await f.plan(
          await f.request({
            'rules': [_rule('world_rule_preview', 'Preview')]
          }, dryRun: true),
          wire);
      expect((planned['receipt'] as Map)['extensions'],
          containsPair('nonApplicableReason', 'dry_run'));
      if (wire) {
        final failure = await f.command('apply', {
          'projectHandle': f.project.value,
          'planId': planned['planId'],
          'operationId': 'dry-run',
        });
        expect(failure.status, AuthoringResultStatus.failure);
        expect(failure.error!.details['domainCode'],
            'plan.dry_run_not_applicable');
      } else {
        await expectLater(
            f.mutations.apply(f.project,
                planId: planned['planId'] as String, operationId: 'dry-run'),
            throwsA(isA<AuthoringPlanException>().having(
                (error) => error.code, 'code', 'plan.dry_run_not_applicable')));
      }
      expect(await f.manifest.readAsBytes(), before);
      expect(await f.map.readAsBytes(), f.mapBefore);
    });
  }
}

Map<String, dynamic> _indexedRule(int index) =>
    _rule('world_rule_batch_$index', 'Batch $index');

Map<String, dynamic> _rule(String id, String label,
        {int priority = 0,
        String factId = 'fact_gate',
        String mapId = 'map',
        String entityId = 'npc',
        String? dialogue,
        bool badEffect = false}) =>
    {
      'id': id,
      'label': label,
      'priority': priority,
      'source': {'kind': 'fact', 'sourceId': factId, 'predicate': 'isTrue'},
      'target': {
        'kind': dialogue == null ? 'mapEntity' : 'npcDialogue',
        'mapId': mapId,
        'entityId': entityId,
      },
      'effect': {
        'kind': dialogue != null
            ? 'npcDialogueOverride'
            : badEffect
                ? 'eventDisabled'
                : 'entityHidden',
        if (dialogue != null) 'dialogueId': dialogue,
      },
    };

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
    final directory =
        await Directory.systemTemp.createTemp('world-rule-batch-');
    await Directory('${directory.path}/maps').create();
    final project = ProjectManifest(
      name: 'World Rule batch transport',
      tilesets: const [],
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
      ],
      facts: [NarrativeFactDefinition(id: 'fact_gate', label: 'Gate')],
      worldRules: [
        WorldRuleDefinition.fromJson(_rule('world_rule_existing', 'Existing')),
        WorldRuleDefinition.fromJson(_rule('world_rule_keep', 'Keep')),
      ],
      scenes: [
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
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
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
        actionId: 'world_rule.upsert_batch',
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
