import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('trainer batch advertises one bounded atomic canonical operation', () {
    final descriptor = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((value) => value.id == 'campaign.trainer.upsert_batch');
    expect(descriptor.guarantees, containsAll(AuthoringGuarantee.values));
    expect(descriptor.extensions['batch'], {
      'minValues': 1,
      'maxValues': 512,
      'uniqueBy': 'id',
      'semantics': 'createOrUpdate',
      'atomic': true,
    });
    expect(descriptor.extensions['trainerPokemonBall'], isNotNull);
    expect(descriptor.extensions['trainerBattleItems'], isNotNull);
  });

  for (final jsonl in [false, true]) {
    test('${jsonl ? 'JSONL' : 'API'} dry run cannot write a trainer batch',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.file.readAsBytes();
      final planned = await f.plan(
          await f.request({
            'values': [_trainer('preview', reward: 600)],
          }, dryRun: true),
          jsonl);
      expect(planned['applicable'], isFalse);
      await expectLater(
          f.apply(planned['planId'] as String, jsonl), throwsA(anything));
      expect(await f.file.readAsBytes(), before);
      expect(await f.map.readAsBytes(), f.mapBefore);
    });

    test(
        '${jsonl ? 'JSONL' : 'API'} trainer batch preserves order, reopens, replays and undoes once',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final original = await f.file.readAsBytes();
      final values = [
        {
          ..._trainer('update', reward: 760),
          'battleItems': {'potion': 2}
        },
        _trainer('new', reward: 1200)
      ];
      final request = await f.request({'values': values});
      final planned = await f.plan(request, jsonl);
      expect(await f.file.readAsBytes(), original);
      final applied = await f.apply(planned['planId'] as String, jsonl);
      final saved = await f.file.readAsBytes();
      final replay = await f.apply(planned['planId'] as String, jsonl);
      expect(replay['receipt'], applied['receipt']);
      expect(await f.file.readAsBytes(), saved);
      final current = await f.snapshots.load(f.project);
      expect(current.manifest.trainers.map((x) => x.id),
          ['keep', 'update', 'new']);
      expect(
          current.manifest.trainers.map((x) => x.moneyReward), [0, 760, 1200]);
      expect(await f.map.readAsBytes(), f.mapBefore);
      await f.reopen();
      expect(
          (await f.snapshots.load(f.project))
              .manifest
              .trainers
              .map((x) => x.moneyReward),
          [0, 760, 1200]);
      if (jsonl) {
        await f.wire('undo', {
          'projectHandle': f.project.value,
          'entryId': (applied['receipt'] as Map)['receiptId'],
          'idempotencyKey': 'undo-batch'
        });
      } else {
        await f.mutations.undo(f.project,
            entryId: (applied['receipt'] as Map)['receiptId'] as String,
            idempotencyKey: 'undo-batch');
      }
      expect(await f.file.readAsBytes(), original);
      expect(await f.map.readAsBytes(), f.mapBefore);
    });

    test(
        '${jsonl ? 'JSONL' : 'API'} maximum trainer batch has one atomic manifest change',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final request = await f.request({
        'values': [
          for (var i = 0; i < 512; i++) _trainer('batch_$i', reward: i)
        ]
      });
      final snapshot = await f.snapshots.load(f.project);
      final draft = const CampaignContentActions().build(
          AuthoringPlanningContext(
              snapshot: snapshot,
              request: request,
              planId: 'bounded-batch',
              seed: 1));
      expect(draft.changeSet.changes, hasLength(1));
      expect(draft.changeSet.diff.entries, hasLength(1));
      expect(draft.changeSet.changes.single.storageKey, 'project.json');
      final planned = await f.plan(request, jsonl);
      await f.apply(planned['planId'] as String, jsonl);
      expect((await f.snapshots.load(f.project)).manifest.trainers,
          hasLength(514));
      expect(await f.map.readAsBytes(), f.mapBefore);
    });

    test(
        '${jsonl ? 'JSONL' : 'API'} malformed, duplicate and invalid last trainer are rejected without writes',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.file.readAsBytes();
      final beforeItems = await f.items.readAsBytes();
      final revision = (await f.snapshots.load(f.project)).revision;
      final valid = _trainer('first', reward: 500);
      for (final parameters in <Map<String, Object?>>[
        {},
        {'values': null},
        {'values': {}},
        {'values': []},
        {
          'values': [valid],
          'unknown': true
        },
        {'values': List.generate(513, (i) => _trainer('x$i'))},
        {
          'values': [valid, valid]
        },
        {
          'values': [valid, 42]
        },
        {
          'values': [valid, {}]
        },
        {
          'values': [
            valid,
            {..._trainer('last'), 'moneyReward': -1}
          ]
        },
        {
          'values': [
            valid,
            {..._trainer('last'), 'battleFormat': 'unknown'}
          ]
        },
        {
          'values': [
            valid,
            {
              ..._trainer('last'),
              'team': [
                {'speciesId': 'pikachu', 'level': 10, 'ballItemId': 'missing'}
              ]
            }
          ]
        },
        {
          'values': [
            valid,
            {
              ..._trainer('last'),
              'team': [
                {'speciesId': 'pikachu', 'level': 10, 'ballItemId': 'potion'}
              ]
            }
          ]
        },
        {
          'values': [
            valid,
            {
              ..._trainer('last'),
              'battleItems': {'missing': 1}
            }
          ]
        },
        {
          'values': [
            valid,
            {
              ..._trainer('last'),
              'battleItems': {'ball': 1}
            }
          ]
        },
      ]) {
        final request = await f.request(parameters);
        await expectLater(
            f.plan(request, jsonl),
            throwsA(jsonl
                ? isA<AuthoringError>()
                    .having((error) => error.code, 'code',
                        isNot(AuthoringErrorCode.internal))
                    .having((error) => error.details['domainCode'],
                        'domainCode', isNot('worker.internal'))
                : isA<ValidationException>()));
        expect(await f.file.readAsBytes(), before);
        expect(await f.items.readAsBytes(), beforeItems);
        expect((await f.snapshots.load(f.project)).revision, revision);
        expect(await f.map.readAsBytes(), f.mapBefore);
      }
    });

    test(
        '${jsonl ? 'JSONL' : 'API'} planned trainer batch refuses a stale revision',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final first = await f.request({
        'values': [_trainer('update', reward: 100)]
      });
      final stale = await f.plan(first, jsonl);
      final second = await f.plan(
          await f.request({
            'values': [_trainer('other', reward: 200)]
          }),
          jsonl);
      await f.apply(second['planId'] as String, jsonl);
      final before = await f.file.readAsBytes();
      await expectLater(
          f.apply(stale['planId'] as String, jsonl), throwsA(anything));
      expect(await f.file.readAsBytes(), before);
      expect(await f.map.readAsBytes(), f.mapBefore);
    });
  }
}

Map<String, Object?> _trainer(String id, {int reward = 0}) => {
      'id': id,
      'name': 'Trainer $id',
      'trainerClass': 'Trainer',
      'moneyReward': reward,
      'team': [
        {'speciesId': 'pikachu', 'level': 10, 'ballItemId': 'ball'}
      ],
    };

final class _Fixture {
  _Fixture(this.root, this.api, this.mutations, this.snapshots, this.worker,
      this.mapBefore);
  final Directory root;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;
  final List<int> mapBefore;
  late ProjectHandle project;
  late WorkspaceHandle workspace;
  var sequence = 0;
  File get file => File('${root.path}/project.json');
  File get map => File('${root.path}/maps/map.json');
  File get items => File('${root.path}/data/pokemon/catalogs/items.json');

  static Future<_Fixture> create() async {
    final root =
        await Directory.systemTemp.createTemp('trainer-batch-authoring-');
    final project = ProjectManifest(
        name: 'Trainer batch',
        maps: const [
          ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
        ],
        tilesets: const [],
        trainers: [
          ProjectTrainerEntry.fromJson(_trainer('keep')),
          ProjectTrainerEntry.fromJson(_trainer('update'))
        ],
        pokemon: const ProjectPokemonConfig(
            enabled: true,
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            catalogFiles: {'items': 'data/pokemon/catalogs/items.json'}));
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    final map = File('${root.path}/maps/map.json');
    await map.parent.create();
    await map.writeAsString(jsonEncode(const MapData(
            id: 'map', name: 'Map', size: GridSize(width: 4, height: 4))
        .toJson()));
    final items = File('${root.path}/data/pokemon/catalogs/items.json');
    await items.parent.create(recursive: true);
    await items.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'entries': [
        {
          'id': 'ball',
          'displayName': 'Ball',
          'pocketId': 'balls',
          'capture': {
            'rateNumerator': 1,
            'rateDenominator': 1,
            'allowedEncounterKinds': ['walk']
          }
        },
        {
          'id': 'potion',
          'displayName': 'Potion',
          'pocketId': 'medicine',
          'uses': [
            {
              'contexts': ['battle'],
              'target': 'party_member',
              'consumption': 'on_applied',
              'effect': {'kind': 'heal_hp', 'mode': 'flat', 'amount': 20}
            },
          ]
        },
      ]
    }));
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
    final f = _Fixture(root, api, mutations, snapshots,
        JsonlWorker(api: api, mutations: mutations), await map.readAsBytes());
    await f.open();
    return f;
  }

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
        jsonEncode({
      'id': 'batch-wire-${++sequence}',
      'command': command,
      'args': args
    }))) as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) throw result.error!;
    return result.data;
  }

  Future<void> open() async {
    final result = await wire('open', {'projectRoot': root.path});
    workspace = WorkspaceHandle(result['workspaceHandle'] as String);
    project = ProjectHandle(result['projectHandle'] as String);
  }

  Future<void> reopen() async {
    await wire('close', {'workspaceHandle': workspace.value});
    await open();
  }

  Future<AuthoringRequest> request(Map<String, Object?> parameters,
      {bool dryRun = false}) async {
    final id = 'batch-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: 'campaign.trainer.upsert_batch',
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: parameters,
        dryRun: dryRun);
  }

  Future<Map<String, Object?>> plan(AuthoringRequest request, bool jsonl) =>
      jsonl
          ? wire('plan',
              {'projectHandle': project.value, 'request': request.toJson()})
          : mutations.plan(project, request);
  Future<Map<String, Object?>> apply(String planId, bool jsonl) => jsonl
      ? wire('apply', {
          'projectHandle': project.value,
          'planId': planId,
          'operationId': 'apply-$planId'
        })
      : mutations.apply(project, planId: planId, operationId: 'apply-$planId');
  Future<void> dispose() async {
    await wire('close', {'workspaceHandle': workspace.value});
    await root.delete(recursive: true);
  }
}
