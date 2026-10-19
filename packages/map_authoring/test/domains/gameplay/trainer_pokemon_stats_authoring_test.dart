import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    final transport = jsonl ? 'JSONL' : 'API';

    test('$transport plans, applies, reopens and queries member stat overrides',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final unrelated =
          _trainerById(await fixture.query(jsonl), 'trainer_beta');
      await fixture.upsert(
          _trainer([_member(_custom), _member(_other)]), jsonl);
      await fixture.reopen();
      final project = await fixture.query(jsonl);
      final alpha = _trainerById(project, 'trainer_alpha');
      final members = _members(alpha);
      _expectOverrides(members[0], _custom);
      _expectOverrides(members[1], _other);
      expect(_trainerById(project, 'trainer_beta'), unrelated);
      expect(alpha['battleDifficulty'], 7);
      expect(alpha['moneyReward'], 123);
      expect(alpha['rewardItemGrants'], [
        {'itemId': 'test_reward', 'quantity': 2},
      ]);
      expect(alpha['rewardFlagIds'], ['test_victory']);
      expect(alpha['rewardBadgeId'], 'test_badge');
      expect(alpha['tags'], ['synthetic']);
      for (final member in members) {
        for (final entry in _member(const {}).entries) {
          expect(member[entry.key], entry.value, reason: entry.key);
        }
      }
      final stored = await fixture.stored();
      expect(_trainerById(stored, 'trainer_alpha'), alpha);
    });

    test(
        '$transport allows each override independently and leaves Standard absent',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final overrides = <Map<String, dynamic>>[
        {'natureId': 'timid'},
        {'ivs': _ivs},
        {'evs': _evs},
        const {},
      ];
      await fixture.upsert(
        _trainer([for (final value in overrides) _member(value)]),
        jsonl,
      );
      await fixture.reopen();
      final members = _members(
        _trainerById(await fixture.query(jsonl), 'trainer_alpha'),
      );
      for (var index = 0; index < overrides.length; index++) {
        _expectOverrides(members[index], overrides[index]);
      }
    });

    for (final explicitNull in [false, true]) {
      test(
        '$transport clears Standard with ${explicitNull ? 'explicit nulls' : 'absent overrides'} for one member',
        () async {
          final fixture = await _Fixture.create();
          addTearDown(fixture.dispose);
          await fixture.upsert(
              _trainer([_member(_custom), _member(_other)]), jsonl);
          final overrides = <String, dynamic>{
            if (explicitNull) 'natureId': null,
            if (explicitNull) 'ivs': null,
            if (explicitNull) 'evs': null,
          };
          await fixture.upsert(
            _trainer([_member(overrides), _member(_other)]),
            jsonl,
          );
          await fixture.reopen();
          final members = _members(
            _trainerById(await fixture.query(jsonl), 'trainer_alpha'),
          );
          _expectOverrides(members[0], const {});
          _expectOverrides(members[1], _other);
          final storedMembers = _members(
            _trainerById(await fixture.stored(), 'trainer_alpha'),
          );
          _expectOverrides(storedMembers[0], const {});
          _expectOverrides(storedMembers[1], _other);
        },
      );
    }

    test('$transport clears one override without clearing the other two',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.upsert(_trainer([_member(_custom)]), jsonl);
      final remaining = {'ivs': _ivs, 'evs': _evs};
      await fixture.upsert(
        _trainer([
          _member({...remaining, 'natureId': null})
        ]),
        jsonl,
      );
      await fixture.reopen();
      _expectOverrides(
        _members(_trainerById(await fixture.query(jsonl), 'trainer_alpha'))
            .single,
        remaining,
      );
    });

    test('$transport changing battleDifficulty preserves all member overrides',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      for (final difficulty in [1, 10]) {
        await fixture.upsert(
          {
            ..._trainer([_member(_custom), _member(const {})]),
            'battleDifficulty': difficulty
          },
          jsonl,
        );
        final alpha = _trainerById(await fixture.query(jsonl), 'trainer_alpha');
        expect(alpha['battleDifficulty'], difficulty);
        _expectOverrides(_members(alpha)[0], _custom);
        _expectOverrides(_members(alpha)[1], const {});
      }
    });

    test(
        '$transport dry run previews overrides without writing or changing revision',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final before = await fixture.capture();
      final plan =
          await fixture.plan(_trainer([_member(_custom)]), jsonl, dryRun: true);
      expect(jsonEncode(plan), contains('"natureId":"modest"'));
      expect(jsonEncode(plan), contains('"specialDefense":23'));
      await fixture.expectUnchanged(before);
      await fixture.reopen();
      expect(
        (await fixture.query(jsonl))['trainers'],
        (await fixture.stored())['trainers'],
      );
      expect(
        ((await fixture.query(jsonl))['trainers'] as List)
            .cast<Map>()
            .any((trainer) => trainer['id'] == 'trainer_alpha'),
        isFalse,
      );
    });

    for (final field in ['natureId', 'ivs', 'evs']) {
      test(
          '$transport rejects invalid $field atomically through the actual transport',
          () async {
        final fixture = await _Fixture.create();
        addTearDown(fixture.dispose);
        await fixture.upsert(
            _trainer([_member(_custom), _member(_other)]), jsonl);
        final accepted = await fixture.query(jsonl);
        for (final entry in _invalidOverrides(field).entries) {
          await fixture.expectRejected(
            {
              ..._trainer([
                _member({..._custom, field: entry.value}),
                _member(_other)
              ]),
              'name': 'Rejected ${fixture.sequence}',
            },
            jsonl,
            field: field,
            reason: entry.key,
          );
        }
        await fixture.reopen();
        expect(await fixture.query(jsonl), accepted);
      });
    }
  }

  test(
      'direct campaign semantic API persists trainer stats without altering peers',
      () {
    final original = ProjectManifest(
      name: 'Synthetic trainer stats',
      maps: const [],
      tilesets: const [],
      trainers: const [_unrelatedTrainer],
      badges: const [BadgeDefinition(id: 'test_badge', label: 'Test Badge')],
    );
    final result = const CampaignContentActions().upsert(
      original,
      CampaignContentKind.trainer,
      ProjectTrainerEntry.fromJson(_trainer([_member(_custom)])),
      itemCatalog: _catalog,
    );
    expect(result.trainers.first, _unrelatedTrainer);
    _expectOverrides(result.trainers.last.team.single.toJson(), _custom);
    expect(original.trainers, const [_unrelatedTrainer]);
  });
}

const _stats = [
  'hp',
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed',
];

const _ivs = {
  'hp': 31,
  'attack': 0,
  'defense': 1,
  'specialAttack': 7,
  'specialDefense': 23,
  'speed': 30,
};

const _evs = {
  'hp': 252,
  'attack': 0,
  'defense': 4,
  'specialAttack': 0,
  'specialDefense': 2,
  'speed': 252,
};

const _custom = {'natureId': 'modest', 'ivs': _ivs, 'evs': _evs};
const _other = {
  'natureId': 'timid',
  'ivs': {
    'hp': 0,
    'attack': 31,
    'defense': 4,
    'specialAttack': 10,
    'specialDefense': 8,
    'speed': 2,
  },
  'evs': {
    'hp': 0,
    'attack': 252,
    'defense': 0,
    'specialAttack': 0,
    'specialDefense': 0,
    'speed': 252,
  },
};

Map<String, dynamic> _member(Map<String, dynamic> overrides) => {
      'speciesId': 'test_species',
      'level': 50,
      'moves': ['test_move_one', 'test_move_two'],
      'heldItemId': 'test_held_item',
      'ballItemId': 'test_ball',
      'abilityId': 'test_ability',
      'formId': 'test_form',
      'gender': 'female',
      'shiny': true,
      ...overrides,
    };

Map<String, dynamic> _trainer(List<Map<String, dynamic>> members) => {
      'id': 'trainer_alpha',
      'name': 'Trainer Alpha',
      'trainerClass': 'Trainer',
      'battleDifficulty': 7,
      'moneyReward': 123,
      'rewardItemGrants': [
        {'itemId': 'test_reward', 'quantity': 2},
      ],
      'rewardFlagIds': ['test_victory'],
      'rewardBadgeId': 'test_badge',
      'team': members,
      'tags': ['synthetic'],
    };

Map<String, Object?> _trainerById(Map<String, Object?> project, String id) =>
    Map<String, Object?>.from(
      (project['trainers'] as List)
          .cast<Map>()
          .singleWhere((trainer) => trainer['id'] == id),
    );

List<Map<String, dynamic>> _members(Map<String, Object?> trainer) => [
      for (final member in trainer['team'] as List)
        Map<String, dynamic>.from(member as Map),
    ];

void _expectOverrides(
  Map<String, dynamic> member,
  Map<String, dynamic> overrides,
) {
  for (final field in ['natureId', 'ivs', 'evs']) {
    if (overrides.containsKey(field)) {
      expect(member[field], overrides[field], reason: field);
    } else {
      expect(member.containsKey(field), isFalse, reason: field);
    }
  }
}

Map<String, Object?> _invalidOverrides(String field) {
  final cases = <String, Object?>{};
  if (field == 'natureId') {
    for (final value in <Object>[
      '',
      ' ',
      ' modest ',
      'Modest',
      'unknown_nature',
      1,
      true,
      [],
      {},
    ]) {
      cases[jsonEncode(value)] = value;
    }
    return cases;
  }
  final standard = {for (final stat in _stats) stat: 0};
  for (final value in <Object>[true, 1, 1.0, '15', [], {}]) {
    cases['non-spread ${jsonEncode(value)}'] = value;
  }
  cases['unknown stat'] = {...standard, 'accuracy': 0};
  for (final stat in _stats) {
    cases['missing $stat'] = {...standard}..remove(stat);
    for (final value in <Object?>[
      null,
      true,
      '1',
      1.0,
      1.5,
      -1,
      field == 'ivs' ? 32 : 253,
    ]) {
      cases['$stat ${jsonEncode(value)}'] = {...standard, stat: value};
    }
  }
  if (field == 'evs') {
    cases['total 511'] = {..._evs, 'defense': 5};
  }
  return cases;
}

const _unrelatedTrainer = ProjectTrainerEntry(
  id: 'trainer_beta',
  name: 'Trainer Beta',
  trainerClass: 'Other Trainer',
  moneyReward: 17,
  tags: ['untouched'],
  team: [ProjectTrainerPokemonEntry(speciesId: 'test_species', level: 8)],
);

const _catalog = ProjectItemCatalog(
  schemaVersion: 1,
  entries: [
    ProjectItemDefinition(
      id: 'test_ball',
      displayName: 'Test Ball',
      pocketId: 'balls',
      capture: ProjectCaptureItemDefinition(
        rateNumerator: 1,
        rateDenominator: 1,
        allowedEncounterKinds: {EncounterKind.walk},
      ),
    ),
    ProjectItemDefinition(
      id: 'test_reward',
      displayName: 'Test Reward',
      pocketId: 'medicine',
    ),
    ProjectItemDefinition(
      id: 'test_held_item',
      displayName: 'Test Held Item',
      pocketId: 'medicine',
    ),
  ],
);

class _Fixture {
  _Fixture(this.root, this.file, this.catalog, this.api, this.mutations,
      this.snapshots, this.opened, this.worker);

  final Directory root;
  final File file;
  final File catalog;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  OpenedProject opened;
  final JsonlWorker worker;
  int sequence = 0;

  static Future<_Fixture> create() async {
    final root =
        await Directory.systemTemp.createTemp('trainer-stats-authoring-');
    final file = File('${root.path}/project.json');
    await file.writeAsString(jsonEncode(ProjectManifest(
      name: 'Synthetic trainer stats',
      maps: [],
      tilesets: [],
      trainers: const [_unrelatedTrainer],
      badges: const [BadgeDefinition(id: 'test_badge', label: 'Test Badge')],
      pokemon: const ProjectPokemonConfig(
        enabled: true,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        catalogFiles: {'items': 'data/pokemon/catalogs/items.json'},
      ),
    ).toJson()));
    final catalog = File('${root.path}/data/pokemon/catalogs/items.json');
    await catalog.parent.create(recursive: true);
    await catalog.writeAsString(jsonEncode(_catalog.toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _Fixture(root, file, catalog, api, mutations, snapshots, opened,
        JsonlWorker(api: api, mutations: mutations));
  }

  Future<String> revision() async =>
      (await snapshots.load(opened.projectHandle)).revision;

  Future<({List<int> project, List<int> catalog, String revision})>
      capture() async => (
            project: await file.readAsBytes(),
            catalog: await catalog.readAsBytes(),
            revision: await revision(),
          );

  Future<void> expectUnchanged(
    ({List<int> project, List<int> catalog, String revision}) before, {
    String? reason,
  }) async {
    expect(await file.readAsBytes(), before.project, reason: reason);
    expect(await catalog.readAsBytes(), before.catalog, reason: reason);
    expect(await revision(), before.revision, reason: reason);
  }

  Future<Map<String, Object?>> stored() async => Map<String, Object?>.from(
        jsonDecode(await file.readAsString()) as Map,
      );

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final result = AuthoringResult.fromJson(
      jsonDecode(await worker.processLine(jsonEncode({
        'id': '$command-${sequence++}',
        'command': command,
        'args': args,
      }))) as Map<String, dynamic>,
    );
    if (result.status != AuthoringResultStatus.success) {
      throw result.error!;
    }
    return result.data;
  }

  Future<Map<String, Object?>> query(bool jsonl) async {
    final request = AuthoringQueryRequest(
      resourceKind: 'project',
      operation: AuthoringQueryOperation.get,
      ids: ['project'],
      view: AuthoringQueryView.detail,
      fieldMask: ['trainers'],
    );
    final page = jsonl
        ? AuthoringQueryPage.fromJson(
            Map<String, dynamic>.from(await wire('query', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson(),
          })))
        : await api.queryProject(opened.projectHandle, request);
    return page.items.single;
  }

  Future<Map<String, Object?>> plan(
    Map<String, dynamic> trainer,
    bool jsonl, {
    bool dryRun = false,
  }) async {
    final id = 'trainer-stats-${sequence++}';
    final before = await capture();
    final rawRequest = <String, Object?>{
      'requestId': id,
      'actionId': 'campaign.trainer.upsert',
      'actionVersion': 1,
      'workspaceHandle': opened.workspaceHandle.value,
      'expectedRevision': before.revision,
      'idempotencyKey': id,
      'parameters': {'value': trainer},
      'dryRun': dryRun,
    };
    final plan = jsonl
        ? await wire('plan', {
            'projectHandle': opened.projectHandle.value,
            'request': rawRequest,
          })
        : await mutations.plan(
            opened.projectHandle,
            AuthoringRequest.fromJson(rawRequest),
          );
    await expectUnchanged(before);
    return plan;
  }

  Future<void> upsert(Map<String, dynamic> trainer, bool jsonl) async {
    final planned = await plan(trainer, jsonl);
    final operationId = 'trainer-stats-apply-${sequence++}';
    if (jsonl) {
      await wire('apply', {
        'projectHandle': opened.projectHandle.value,
        'planId': planned['planId'],
        'operationId': operationId,
      });
    } else {
      await mutations.apply(
        opened.projectHandle,
        planId: planned['planId']! as String,
        operationId: operationId,
      );
    }
  }

  Future<void> expectRejected(
    Map<String, dynamic> trainer,
    bool jsonl, {
    required String field,
    required String reason,
  }) async {
    final before = await capture();
    final Matcher rejection = jsonl
        ? anyOf(
            isA<AuthoringError>()
                .having((error) => error.code, 'code',
                    AuthoringErrorCode.invalidRequest)
                .having((error) => error.details['domainCode'], 'domainCode',
                    'worker.request_invalid'),
            isA<AuthoringError>()
                .having((error) => error.code, 'code',
                    AuthoringErrorCode.validationFailed)
                .having((error) => error.details['domainCode'], 'domainCode',
                    anyOf(['validation.failed', ..._validationCodes(field)])),
          )
        : anyOf(
            isA<ValidationException>().having(
              (error) => error.code,
              'code',
              anyOf(_validationCodes(field)),
            ),
            isA<FormatException>()
                .having((error) => error.message, 'message', contains(field)),
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              'parameters.value.team[0].$field',
            ),
          );
    try {
      await expectLater(upsert(trainer, jsonl), throwsA(rejection),
          reason: reason);
    } finally {
      await expectUnchanged(before, reason: reason);
    }
  }

  Future<void> reopen() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    opened = await api.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

List<String> _validationCodes(String field) => switch (field) {
      'natureId' => ['trainer.pokemon.nature.invalid'],
      'ivs' => ['trainer.pokemon.ivs.invalid'],
      'evs' => [
          'trainer.pokemon.evs.invalid',
          'trainer.pokemon.evs.total_exceeded'
        ],
      _ => throw ArgumentError.value(field, 'field'),
    };
