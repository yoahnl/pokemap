import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, Object?> _value({int endMinute = 600}) => {
      'id': 'route',
      'name': 'Route',
      'encounterKind': 'walk',
      'chancePerStep': 0.11,
      'entries': [],
      'variants': [
        {
          'id': 'morning',
          'name': 'Morning',
          'priority': 1,
          'timeWindows': [
            {'startMinute': 240, 'endMinute': endMinute}
          ],
          'entries': [
            {'speciesId': 'sentret', 'minLevel': 2, 'maxLevel': 4, 'weight': 5}
          ],
        }
      ],
    };

void main() {
  test('bounded atomic encounter batch is discoverable', () {
    final action = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere(
            (entry) => entry.id == 'campaign.encounter_table.upsert_batch');
    expect(action.extensions['batch'], {
      'minValues': 1,
      'maxValues': 200,
      'uniqueBy': 'id',
      'semantics': 'createOrUpdate',
      'atomic': true
    });
    expect(action.guarantees, containsAll(AuthoringGuarantee.values));
  });

  test('canonical metadata publishes variant selection and time semantics', () {
    final action = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((entry) => entry.id == 'campaign.encounter_table.upsert');
    expect(action.extensions['encounterVariants'],
        encounterVariantAuthoringContract);
    expect(encounterVariantAuthoringContract['selection'],
        'highestEligiblePriorityBeforeRandom');
  });
  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'API'} 200-table batch is one atomic change and dry run is read only',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final values = [
        for (var i = 0; i < 200; i++) {..._value(), 'id': 'table_$i'}
      ];
      final before = await f.file.readAsBytes();
      final dry = await f.plan(
          await f.request({'values': values},
              dryRun: true, actionId: 'campaign.encounter_table.upsert_batch'),
          jsonl);
      await expectLater(
          f.apply(dry['planId'] as String, jsonl), throwsA(anything));
      expect(await f.file.readAsBytes(), before);
      final request = await f.request({'values': values},
          actionId: 'campaign.encounter_table.upsert_batch');
      final draft = await const CampaignContentActions()
          .buildEncounterTableBatch(AuthoringPlanningContext(
              snapshot: await f.snapshots.load(f.project),
              request: request,
              planId: 'batch-proof',
              seed: 1));
      expect(draft.changeSet.changes, hasLength(1));
      expect(draft.changeSet.changes.single.storageKey, 'project.json');
      expect(draft.changeSet.diff.entries, hasLength(1));
      final planned = await f.plan(request, jsonl);
      await f.apply(planned['planId'] as String, jsonl);
      expect((await f.snapshots.load(f.project)).manifest.encounterTables,
          hasLength(200));
      expect(await f.map.readAsBytes(), f.mapBefore);
    });

    test(
        '${jsonl ? 'JSONL' : 'API'} atomic encounter batch updates creates reopens replays and undoes once',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final first = await f.plan(await f.request({'value': _value()}), jsonl);
      await f.apply(first['planId'] as String, jsonl);
      final before = await f.file.readAsBytes();
      final values = [
        {..._value(), 'name': 'Changed'},
        {..._value(), 'id': 'second', 'name': 'Second'}
      ];
      final planned = await f.plan(
          await f.request({'values': values},
              actionId: 'campaign.encounter_table.upsert_batch'),
          jsonl);
      expect(await f.file.readAsBytes(), before);
      final applied = await f.apply(planned['planId'] as String, jsonl);
      final saved = await f.file.readAsBytes();
      final replay = await f.apply(planned['planId'] as String, jsonl);
      expect(replay['receipt'], applied['receipt']);
      expect(await f.file.readAsBytes(), saved);
      await f.reopen();
      final tables =
          (await f.snapshots.load(f.project)).manifest.encounterTables;
      expect(tables.map((table) => table.name), ['Changed', 'Second']);
      expect(
          tables.every((table) =>
              table.variants.single.entries.single.speciesId == 'sentret'),
          isTrue);
      expect(await f.map.readAsBytes(), f.mapBefore);
      await f.wire('undo', {
        'projectHandle': f.project.value,
        'entryId': (applied['receipt'] as Map)['receiptId'],
        'idempotencyKey': 'undo-encounter-batch'
      });
      expect(await f.file.readAsBytes(), before);
    });
    test(
        '${jsonl ? 'JSONL' : 'API'} encounter batch rejects bad final values and catalog references atomically',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.file.readAsBytes();
      final valid = _value();
      final unknownFact = {
        ..._value(),
        'id': 'other',
        'variants': [
          {
            ...(_value()['variants'] as List).single as Map,
            'conditions': [
              ScriptConditionFactory.factEquals(
                      'missing', const NarrativeValue.string('x'))
                  .toJson()
            ]
          },
        ]
      };
      final unknownSpecies = {
        ..._value(),
        'id': 'other',
        'entries': [
          {'speciesId': 'missing', 'minLevel': 2, 'maxLevel': 3}
        ]
      };
      final unknownMove = {
        ..._value(),
        'id': 'other',
        'entries': [
          {
            'speciesId': 'sentret',
            'minLevel': 2,
            'maxLevel': 3,
            'pokemonOverrides': {
              'knownMoveIds': ['missing']
            }
          }
        ]
      };
      for (final parameters in <Map<String, Object?>>[
        {},
        {'values': []},
        {
          'values': [valid],
          'unknown': true
        },
        {
          'values': [valid, valid]
        },
        {
          'values': [valid, {}]
        },
        {
          'values': [valid, unknownFact]
        },
        {
          'values': [valid, unknownSpecies]
        },
        {
          'values': [valid, unknownMove]
        },
        {
          'values': [
            valid,
            {..._value(endMinute: 240), 'id': 'other'}
          ]
        },
        {
          'values':
              List.generate(201, (index) => {..._value(), 'id': 'table_$index'})
        },
      ]) {
        await expectLater(
            f.plan(
                await f.request(parameters,
                    actionId: 'campaign.encounter_table.upsert_batch'),
                jsonl),
            throwsA(anything));
        expect(await f.file.readAsBytes(), before);
        expect(await f.map.readAsBytes(), f.mapBefore);
      }
    });

    test(
        '${jsonl ? 'JSONL' : 'API'} variants persist, reopen and undo atomically',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.file.readAsBytes();
      final planned = await f.plan(await f.request({'value': _value()}), jsonl);
      expect(await f.file.readAsBytes(), before);
      final applied = await f.apply(planned['planId'] as String, jsonl);
      final table =
          (await f.snapshots.load(f.project)).manifest.encounterTables.single;
      expect(table.variants.single.entries.single.speciesId, 'sentret');
      expect(table.chancePerStep, .11);
      expect(await f.map.readAsBytes(), f.mapBefore);
      await f.reopen();
      expect(
          (await f.snapshots.load(f.project)).manifest.encounterTables.single,
          table);
      if (jsonl) {
        await f.wire('undo', {
          'projectHandle': f.project.value,
          'entryId': (applied['receipt'] as Map)['receiptId'],
          'idempotencyKey': 'undo-variants'
        });
      } else {
        await f.mutations.undo(f.project,
            entryId: (applied['receipt'] as Map)['receiptId'] as String,
            idempotencyKey: 'undo-variants');
      }
      expect(await f.file.readAsBytes(), before);
    });
    test(
        '${jsonl ? 'JSONL' : 'API'} invalid variant leaves all project files untouched',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.file.readAsBytes();
      for (final end in [240, 1441, -1]) {
        await expectLater(
            f.plan(await f.request({'value': _value(endMinute: end)}), jsonl),
            throwsA(anything));
        expect(await f.file.readAsBytes(), before);
        expect(await f.map.readAsBytes(), f.mapBefore);
      }
    });
  }
}

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
    final species = File('${root.path}/data/pokemon/species/sentret.json');
    await species.parent.create(recursive: true);
    await Directory('${root.path}/data/pokemon/media').create(recursive: true);
    await species.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'id': 'sentret',
      'classification': {'isEnabledInProject': true}
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
      {bool dryRun = false,
      String actionId = 'campaign.encounter_table.upsert'}) async {
    final id = 'batch-${++sequence}';
    return AuthoringRequest(
        requestId: id,
        actionId: actionId,
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
