import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('Fact batch advertises bounded atomic creation semantics', () {
    final descriptor = FactRuleActions.descriptors
        .singleWhere((descriptor) => descriptor.id == 'fact.create_batch');
    expect(descriptor.resourceKinds, unorderedEquals(['project', 'fact']));
    expect(descriptor.extensions['batch'], {
      'minFacts': 1,
      'maxFacts': 128,
      'uniqueBy': 'id',
      'semantics': 'createOnly',
      'atomic': true,
    });
  });

  test('128 facts form one candidate validated once and one project change',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final snapshot = await f.snapshots.load(f.project);
    final request =
        await f.request({'facts': List.generate(128, _indexedFact)});
    var validations = 0;
    final plan = await AuthoringActionPlanner(store: AuthoringPlanStore()).plan(
      request: request,
      snapshot: snapshot,
      build: const FactRuleActions().build,
      validateProjectedState: (before, draft) {
        validations++;
        expect(draft.projectedProject!.facts, hasLength(129));
        expect(draft.changeSet.changes, hasLength(1));
        expect(draft.changeSet.diff.entries, hasLength(1));
        expect(draft.changeSet.changes.single.storageKey, 'project.json');
        expect(draft.preview['factIds'],
            List.generate(128, (i) => 'fact_batch_$i'));
      },
    );
    expect(validations, 1);
    expect(plan.changeSet.changes, hasLength(1));
    expect(await f.map.readAsBytes(), f.mapBefore);
  });

  for (final wire in [false, true]) {
    final transport = wire ? 'JSONL' : 'direct API';
    test(
        '$transport creates typed facts atomically, reopens, replays and undoes',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final facts = [
        NarrativeFactDefinition(
                id: 'fact_gate_2',
                label: 'Gate',
                defaultValue: true,
                legacyFlagName: 'gate_ready')
            .toJson(),
        NarrativeFactDefinition(
                id: 'fact_score',
                label: 'Score',
                initialValue: NarrativeValue.integer(12))
            .toJson(),
        NarrativeFactDefinition(
                id: 'fact_name',
                label: 'Name',
                initialValue: NarrativeValue.string('Johto'))
            .toJson(),
      ];
      final planned = await f.plan(await f.request({'facts': facts}), wire);
      expect(await f.manifest.readAsBytes(), before);
      final applied = await f.apply(planned['planId'] as String, wire);
      final saved = await f.manifest.readAsBytes();
      final replay = await f.apply(planned['planId'] as String, wire);
      expect(replay['receipt'], applied['receipt']);
      final receipt = applied['receipt'] as Map;
      expect(receipt['affectedResources'], hasLength(1));
      expect((receipt['diff'] as Map)['entries'], hasLength(1));
      expect((await f.mutations.history(f.project, limit: 10))['entries'],
          hasLength(1));
      expect(await f.manifest.readAsBytes(), saved);
      await f.reopen();
      final snapshot = await f.snapshots.load(f.project);
      var canonical = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(before)) as Map<String, dynamic>);
      for (final json in facts) {
        canonical = const FactRuleActions().createFact(canonical,
            fact: NarrativeFactDefinition.fromJson(json));
      }
      expect(snapshot.manifest.toJson(), canonical.toJson());
      expect(snapshot.manifest.facts.map((f) => f.id),
          ['fact_gate', 'fact_gate_2', 'fact_score', 'fact_name']);
      final receiptId = (applied['receipt'] as Map)['receiptId'] as String;
      if (wire) {
        final undone = await f.command('undo', {
          'projectHandle': f.project.value,
          'entryId': receiptId,
          'idempotencyKey': 'undo-batch'
        });
        expect(undone.status, AuthoringResultStatus.success,
            reason: jsonEncode(undone.toJson()));
      } else {
        await f.mutations
            .undo(f.project, entryId: receiptId, idempotencyKey: 'undo-batch');
      }
      expect(await f.manifest.readAsBytes(), before);
      expect(await f.map.readAsBytes(), f.mapBefore);
    });

    test(
        '$transport rejects bounds duplicates collisions and malformed final fact without writes',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.manifest.readAsBytes();
      final valid = _indexedFact(0);
      final cases = <(Map<String, Object?>, String, int?)>[
        (
          {
            'facts': [
              valid,
              {
                'id': 'fact_alias',
                'label': 'Alias',
                'legacyFlagName': 'fact_gate'
              }
            ]
          },
          'fact.batch_rejected',
          1
        ),
        (
          {
            'facts': [
              valid,
              {
                'id': 'fact_alias',
                'label': 'Alias',
                'legacyFlagName': 'fact_batch_0'
              }
            ]
          },
          'fact.batch_rejected',
          1
        ),
        (
          {
            'facts': [
              {
                'id': 'fact_alias',
                'label': 'Alias',
                'legacyFlagName': 'shared'
              },
              {
                'id': 'fact_alias_two',
                'label': 'Alias two',
                'legacyFlagName': 'shared'
              }
            ]
          },
          'fact.batch_rejected',
          1
        ),
        ({}, 'fact.batch_invalid', null),
        ({'facts': null}, 'fact.batch_invalid', null),
        ({'facts': {}}, 'fact.batch_invalid', null),
        ({'facts': []}, 'fact.batch_invalid', null),
        (
          {'facts': List.generate(129, _indexedFact)},
          'fact.batch_invalid',
          null
        ),
        (
          {
            'facts': [valid],
            'unknown': true
          },
          'fact.batch_invalid',
          null
        ),
        (
          {
            'facts': [valid, valid]
          },
          'fact.batch_rejected',
          1
        ),
        (
          {
            'facts': [
              valid,
              {'id': 'fact_gate', 'label': 'Gate'}
            ]
          },
          'fact.batch_rejected',
          1
        ),
        (
          {
            'facts': [
              valid,
              {'id': 'fact_wrong', 'label': 'Other'}
            ]
          },
          'fact.batch_rejected',
          1
        ),
        (
          {
            'facts': [valid, 42]
          },
          'fact.batch_fact_invalid',
          1
        ),
        (
          {
            'facts': [valid, {}]
          },
          'fact.batch_fact_invalid',
          1
        ),
        (
          {
            'facts': [
              valid,
              {
                'id': 'fact_bad',
                'label': 'Bad',
                'valueType': 'int',
                'defaultValue': 'bad'
              }
            ]
          },
          'fact.batch_fact_invalid',
          1
        ),
        (
          {
            'facts': [
              valid,
              {
                'id': 'fact_bad',
                'label': 'Bad',
                'tags': [42]
              }
            ]
          },
          'fact.batch_fact_invalid',
          1
        ),
      ];
      for (final (parameters, code, index) in cases) {
        final request = await f.request(parameters);
        if (wire) {
          final failure = await f.command('plan',
              {'projectHandle': f.project.value, 'request': request.toJson()});
          expect(failure.status, AuthoringResultStatus.failure);
          expect(failure.error!.details['domainCode'], code);
          expect(failure.error!.details['index'], index);
        } else {
          await expectLater(
              f.mutations.plan(f.project, request),
              throwsA(isA<NarrativeAuthoringException>()
                  .having((e) => e.code, 'code', code)
                  .having((e) => e.details['index'], 'index', index)));
        }
        expect(await f.manifest.readAsBytes(), before);
        expect(await f.map.readAsBytes(), f.mapBefore);
        expect((await f.mutations.history(f.project, limit: 10))['entries'],
            isEmpty);
      }
    });

    test('$transport accepts maximum size and rejects stale plans and dry runs',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final planned = await f.plan(
          await f.request({'facts': List.generate(128, _indexedFact)}), wire);
      final stale = await f.plan(
          await f.request({
            'facts': [
              {'id': 'fact_later', 'label': 'Later'}
            ]
          }),
          wire);
      await f.apply(planned['planId'] as String, wire);
      final before = await f.manifest.readAsBytes();
      if (wire) {
        final failure = await f.command('apply', {
          'projectHandle': f.project.value,
          'planId': stale['planId'],
          'operationId': 'stale'
        });
        expect(failure.status, AuthoringResultStatus.failure);
        expect(failure.error!.details['domainCode'], 'plan.stale');
      } else {
        await expectLater(
            f.mutations.apply(f.project,
                planId: stale['planId'] as String, operationId: 'stale'),
            throwsA(isA<AuthoringPlanException>()
                .having((e) => e.code, 'code', 'plan.stale')));
      }
      final dry = await f.plan(
          await f.request({
            'facts': [
              {'id': 'fact_preview', 'label': 'Preview'}
            ]
          }, dryRun: true),
          wire);
      if (wire) {
        final failure = await f.command('apply', {
          'projectHandle': f.project.value,
          'planId': dry['planId'],
          'operationId': 'dry'
        });
        expect(failure.status, AuthoringResultStatus.failure);
        expect(failure.error!.details['domainCode'],
            'plan.dry_run_not_applicable');
      } else {
        await expectLater(
            f.mutations.apply(f.project,
                planId: dry['planId'] as String, operationId: 'dry'),
            throwsA(isA<AuthoringPlanException>()
                .having((e) => e.code, 'code', 'plan.dry_run_not_applicable')));
      }
      expect(
          (await f.snapshots.load(f.project)).manifest.facts, hasLength(129));
      expect(await f.manifest.readAsBytes(), before);
      expect(await f.map.readAsBytes(), f.mapBefore);
    });
  }
}

Map<String, dynamic> _indexedFact(int index) =>
    {'id': 'fact_batch_$index', 'label': 'Batch $index'};

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
    final directory = await Directory.systemTemp.createTemp('fact-batch-');
    await Directory('${directory.path}/maps').create();
    final project = ProjectManifest(
      name: 'Fact batch transport',
      tilesets: const [],
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
      ],
      facts: [NarrativeFactDefinition(id: 'fact_gate', label: 'Gate')],
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
        actionId: 'fact.create_batch',
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
