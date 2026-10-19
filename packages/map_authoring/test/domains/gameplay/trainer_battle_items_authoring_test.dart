import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    final transport = jsonl ? 'JSONL' : 'API';

    test(
        '$transport authors, reopens and explicitly clears trainer battle stock',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final other = _trainerById(await fixture.query(jsonl), 'trainer_beta');
      final catalogBefore = await fixture.catalog.readAsBytes();

      await fixture.upsert(_trainer({'potion': 3, 'antidote': 1}), jsonl);
      expect(_stock(await fixture.query(jsonl)), {'potion': 3, 'antidote': 1});
      expect(
          (await fixture.stored())
              .trainers
              .singleWhere((t) => t.id == 'trainer_alpha')
              .toJson()['battleItems'],
          {'potion': 3, 'antidote': 1});
      expect(_trainerById(await fixture.query(jsonl), 'trainer_beta'), other);
      expect(await fixture.catalog.readAsBytes(), catalogBefore);

      await fixture.reopen();
      expect(_stock(await fixture.query(jsonl)), {'potion': 3, 'antidote': 1});
      await fixture.upsert(_trainer(<String, int>{}), jsonl);
      expect(_stock(await fixture.query(jsonl)), <String, int>{});
      await fixture.reopen();
      expect(_stock(await fixture.query(jsonl)), <String, int>{});
      expect(_trainerById(await fixture.query(jsonl), 'trainer_beta'), other);
      expect(await fixture.catalog.readAsBytes(), catalogBefore);
    });

    test('$transport creates an empty stock when the field is absent',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.upsert(_trainer(null, includeStock: false), jsonl);
      expect(_stock(await fixture.query(jsonl)), <String, int>{});
    });

    test('$transport rejects malformed stock and quantities atomically',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.upsert(_trainer({'potion': 2}), jsonl);
      for (final invalid in <String, Object?>{
        'explicit null': null,
        'list': <Object?>[],
        'boolean': true,
        'string': 'potion',
        'number': 2,
        'decimal': {'potion': 1.0},
        'fraction': {'potion': 1.5},
        'boolean quantity': {'potion': true},
        'string quantity': {'potion': '1'},
        'null quantity': {'potion': null},
        'negative': {'potion': -1},
        'zero': {'potion': 0},
        'over maximum': {'potion': 100},
        'too many types': {for (var i = 0; i < 17; i++) 'tonic_$i': 1},
      }.entries) {
        await fixture.expectRejected(
          'campaign.trainer.upsert',
          {'value': _trainer(invalid.value)},
          jsonl,
          reason: invalid.key,
        );
      }
      expect(_stock(await fixture.query(jsonl)), {'potion': 2});
    });

    test(
        '$transport rejects unsupported and inexact item references atomically',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.upsert(_trainer({'potion': 2}), jsonl);
      for (final itemId in [
        '',
        ' ',
        ' potion ',
        'POTION',
        'legacy-potion',
        'missing',
        'revive',
        'ether',
        'reusable_tonic',
        'passive',
        'lunar_orb',
        'field_tonic',
      ]) {
        await fixture.expectRejected(
          'campaign.trainer.upsert',
          {
            'value': _trainer({itemId: 1})
          },
          jsonl,
          reason: 'item $itemId',
        );
      }
      expect(_stock(await fixture.query(jsonl)), {'potion': 2});
    });

    test('$transport accepts the stock type and quantity boundaries', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final stock = {
        for (var i = 0; i < 16; i++) 'tonic_$i': i == 0 ? 99 : 1,
      };
      await fixture.upsert(_trainer(stock), jsonl);
      expect(_stock(await fixture.query(jsonl)), stock);
    });

    test('$transport rejects a duplicated catalogue identity atomically',
        () async {
      final fixture = await _Fixture.create(duplicate: true);
      addTearDown(fixture.dispose);
      await fixture.expectRejected(
        'campaign.trainer.upsert',
        {
          'value': _trainer({'potion': 1})
        },
        jsonl,
      );
    });

    test(
        '$transport exposes battle stock in deletion plans and blocks deletion',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.upsert(_trainer({'potion': 2}), jsonl);
      final before = await fixture.file.readAsBytes();
      final catalogBefore = await fixture.catalog.readAsBytes();
      final revision = await fixture.revision();
      final deletion = await fixture.queryPage(
        AuthoringQueryRequest(
          resourceKind: 'itemUsage',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          extensions: const {
            'actionId': 'item.delete_plan',
            'parameters': {'itemId': 'potion'},
          },
        ),
        jsonl,
      );
      expect(deletion.items, hasLength(1));
      expect(deletion.items.single['kind'], 'trainerBattleItem');
      expect(deletion.items.single['editablePath'],
          'trainers[trainer_alpha].battleItems[potion]');
      expect(deletion.items.single['blocksDeletion'], isTrue);
      expect(await fixture.file.readAsBytes(), before);
      expect(await fixture.catalog.readAsBytes(), catalogBefore);
      expect(await fixture.revision(), revision);
      await fixture.expectRejected(
        'item.delete_apply',
        {'itemId': 'potion'},
        jsonl,
      );
    });

    test('$transport blocks catalog edits that invalidate an authored stock',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.upsert(_trainer({'potion': 2}), jsonl);
      final invalidDefinitions = [
        _potion.copyWith(uses: []),
        _potion.copyWith(uses: [
          _battleUse(
            const ProjectItemEffectDefinition.revive(
              rateNumerator: 1,
              rateDenominator: 2,
            ),
          )
        ]),
        _potion.copyWith(uses: [
          _battleUse(
            const ProjectItemEffectDefinition.healHp(
              mode: ProjectItemAmountMode.flat,
              amount: 20,
            ),
            consumption: ProjectItemConsumptionPolicy.never,
          )
        ]),
      ];
      for (final definition in invalidDefinitions) {
        await fixture.expectRejected(
          'item.update',
          {'itemId': 'potion', 'definition': definition.toJson()},
          jsonl,
        );
      }
      await fixture.expectRejected(
        'item.set_battle_effect',
        {
          'itemId': 'potion',
          'use': _battleUse(
            const ProjectItemEffectDefinition.restorePp(
              mode: ProjectItemAmountMode.flat,
              amount: 10,
            ),
            target: ProjectItemTargetKind.partyMove,
          ).toJson(),
        },
        jsonl,
      );
      expect(_stock(await fixture.query(jsonl)), {'potion': 2});
    });

    test(
        '$transport permits a supported battle effect update without rewriting stock',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.upsert(_trainer({'potion': 2}), jsonl);
      final before = await fixture.file.readAsBytes();
      await fixture.mutate(
        'item.set_battle_effect',
        {
          'itemId': 'potion',
          'use': _battleUse(
            const ProjectItemEffectDefinition.healHp(
              mode: ProjectItemAmountMode.flat,
              amount: 30,
            ),
          ).toJson(),
        },
        jsonl,
      );
      expect(await fixture.file.readAsBytes(), before);
      expect(_stock(await fixture.query(jsonl)), {'potion': 2});
    });
  }

  test('direct semantic upsert requires catalogue context for nonempty stock',
      () {
    expect(
      () => const CampaignContentActions().upsert(
        ProjectManifest(name: 'No catalogue', maps: [], tilesets: []),
        CampaignContentKind.trainer,
        ProjectTrainerEntry.fromJson(_trainer({'potion': 1})),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test(
      'direct semantic upsert accepts an empty stock without catalogue context',
      () {
    expect(
      () => const CampaignContentActions().upsert(
        ProjectManifest(name: 'No catalogue', maps: [], tilesets: []),
        CampaignContentKind.trainer,
        ProjectTrainerEntry.fromJson(_trainer(<String, int>{})),
      ),
      returnsNormally,
    );
  });
}

Map<String, dynamic> _trainer(Object? stock, {bool includeStock = true}) => {
      'id': 'trainer_alpha',
      'name': 'Trainer Alpha',
      'trainerClass': 'Trainer',
      if (includeStock) 'battleItems': stock,
      'team': [
        {'speciesId': 'test_species', 'level': 10},
      ],
    };

Map<String, Object?> _trainerById(Map<String, Object?> project, String id) =>
    Map<String, Object?>.from(
      (project['trainers'] as List)
          .cast<Map>()
          .singleWhere((t) => t['id'] == id),
    );

Object? _stock(Map<String, Object?> project) =>
    _trainerById(project, 'trainer_alpha')['battleItems'];

ProjectItemUseDefinition _battleUse(
  ProjectItemEffectDefinition effect, {
  ProjectItemTargetKind target = ProjectItemTargetKind.partyMember,
  ProjectItemConsumptionPolicy consumption =
      ProjectItemConsumptionPolicy.onApplied,
}) =>
    ProjectItemUseDefinition(
      contexts: {ProjectItemUseContext.battle},
      target: target,
      consumption: consumption,
      effect: effect,
    );

const _potion = ProjectItemDefinition(
  id: 'potion',
  displayName: 'Potion',
  aliases: ['legacy-potion'],
  pocketId: 'medicine',
  uses: [
    ProjectItemUseDefinition(
      contexts: {ProjectItemUseContext.battle},
      target: ProjectItemTargetKind.partyMember,
      consumption: ProjectItemConsumptionPolicy.onApplied,
      effect: ProjectItemEffectDefinition.healHp(
        mode: ProjectItemAmountMode.flat,
        amount: 20,
      ),
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

  static Future<_Fixture> create({bool duplicate = false}) async {
    final root = await Directory.systemTemp
        .createTemp('trainer-battle-items-authoring-');
    final file = File('${root.path}/project.json');
    await file.writeAsString(jsonEncode(ProjectManifest(
      name: 'Trainer battle stock',
      maps: [],
      tilesets: [],
      trainers: const [
        ProjectTrainerEntry(
          id: 'trainer_beta',
          name: 'Trainer Beta',
          trainerClass: 'Other trainer',
          moneyReward: 17,
          tags: ['untouched'],
          team: [
            ProjectTrainerPokemonEntry(speciesId: 'test_species', level: 8)
          ],
        ),
      ],
      pokemon: const ProjectPokemonConfig(
        enabled: true,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        catalogFiles: {'items': 'data/pokemon/catalogs/items.json'},
      ),
    ).toJson()));
    final catalog = File('${root.path}/data/pokemon/catalogs/items.json');
    await catalog.parent.create(recursive: true);
    final entries = [
      _potion,
      if (duplicate) _potion,
      _potion.copyWith(
        id: 'antidote',
        uses: [
          _battleUse(const ProjectItemEffectDefinition.cureStatus(
            mode: ProjectItemStatusCureMode.listed,
            statusIds: {'poison'},
          )),
        ],
      ),
      _potion.copyWith(
        id: 'revive',
        uses: [
          _battleUse(const ProjectItemEffectDefinition.revive(
            rateNumerator: 1,
            rateDenominator: 2,
          )),
        ],
      ),
      _potion.copyWith(
        id: 'ether',
        uses: [
          _battleUse(
            const ProjectItemEffectDefinition.restorePp(
              mode: ProjectItemAmountMode.flat,
              amount: 10,
            ),
            target: ProjectItemTargetKind.partyMove,
          ),
        ],
      ),
      _potion.copyWith(
        id: 'reusable_tonic',
        uses: [
          _battleUse(
            const ProjectItemEffectDefinition.healHp(
              mode: ProjectItemAmountMode.flat,
              amount: 20,
            ),
            consumption: ProjectItemConsumptionPolicy.never,
          ),
        ],
      ),
      _potion.copyWith(id: 'passive', uses: []),
      _potion.copyWith(
        id: 'field_tonic',
        uses: const [
          ProjectItemUseDefinition(
            contexts: {ProjectItemUseContext.overworld},
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.healHp(
              mode: ProjectItemAmountMode.flat,
              amount: 20,
            ),
          ),
        ],
      ),
      const ProjectItemDefinition(
        id: 'lunar_orb',
        displayName: 'Lunar Orb',
        pocketId: 'balls',
        capture: ProjectCaptureItemDefinition(
          rateNumerator: 1,
          rateDenominator: 1,
          allowedEncounterKinds: {EncounterKind.walk},
        ),
      ),
      for (var i = 0; i < 17; i++) _potion.copyWith(id: 'tonic_$i'),
    ];
    await catalog.writeAsString(jsonEncode(
        ProjectItemCatalog(schemaVersion: 1, entries: entries).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: snapshots,
    );
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(root, file, catalog, api, mutations, snapshots, opened,
        JsonlWorker(api: api, mutations: mutations));
  }

  Future<String> revision() async =>
      (await snapshots.load(opened.projectHandle)).revision;

  Future<ProjectManifest> stored() async => ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>);

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
      jsonEncode(
          {'id': '$command-${sequence++}', 'command': command, 'args': args}),
    )) as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) {
      throw result.error!;
    }
    return result.data;
  }

  Future<AuthoringQueryPage> queryPage(
          AuthoringQueryRequest request, bool jsonl) async =>
      jsonl
          ? AuthoringQueryPage.fromJson(
              Map<String, dynamic>.from(await wire('query', {
              'projectHandle': opened.projectHandle.value,
              'request': request.toJson(),
            })))
          : await api.queryProject(opened.projectHandle, request);

  Future<Map<String, Object?>> query(bool jsonl) async => (await queryPage(
        AuthoringQueryRequest(
          resourceKind: 'project',
          operation: AuthoringQueryOperation.get,
          ids: ['project'],
          view: AuthoringQueryView.detail,
          fieldMask: ['trainers'],
        ),
        jsonl,
      ))
          .items
          .single;

  Future<void> upsert(Map<String, dynamic> trainer, bool jsonl) async =>
      mutate('campaign.trainer.upsert', {'value': trainer}, jsonl);

  Future<void> mutate(
      String actionId, Map<String, Object?> parameters, bool jsonl) async {
    final id = 'trainer-stock-${sequence++}';
    final before = await file.readAsBytes();
    final catalogBefore = await catalog.readAsBytes();
    final revisionBefore = await revision();
    final plan = jsonl
        ? await wire('plan', {
            'projectHandle': opened.projectHandle.value,
            'request': {
              'requestId': id,
              'actionId': actionId,
              'actionVersion': 1,
              'workspaceHandle': opened.workspaceHandle.value,
              'expectedRevision': revisionBefore,
              'idempotencyKey': id,
              'parameters': parameters,
              'dryRun': false,
            },
          })
        : await mutations.plan(
            opened.projectHandle,
            AuthoringRequest(
              requestId: id,
              actionId: actionId,
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              expectedRevision: revisionBefore,
              idempotencyKey: id,
              parameters: parameters,
            ),
          );
    expect(await file.readAsBytes(), before);
    expect(await catalog.readAsBytes(), catalogBefore);
    expect(await revision(), revisionBefore);
    if (jsonl) {
      await wire('apply', {
        'projectHandle': opened.projectHandle.value,
        'planId': plan['planId'],
        'operationId': id,
      });
    } else {
      await mutations.apply(opened.projectHandle,
          planId: plan['planId']! as String, operationId: id);
    }
  }

  Future<void> expectRejected(
      String actionId, Map<String, Object?> parameters, bool jsonl,
      {String? reason}) async {
    final before = await file.readAsBytes();
    final catalogBefore = await catalog.readAsBytes();
    final revisionBefore = await revision();
    final matcher = jsonl
        ? isA<AuthoringError>()
            .having(
                (error) => error.code,
                'code',
                anyOf(AuthoringErrorCode.validationFailed,
                    AuthoringErrorCode.invalidRequest))
            .having(
                (error) => error.details['domainCode'],
                'domainCode',
                anyOf('worker.request_invalid',
                    startsWith('trainer.battle_item'), startsWith('item.')))
        : anyOf(
            isA<ValidationException>(),
            isA<FormatException>(),
            isA<ItemCatalogAuthoringException>(),
            isA<ArgumentError>()
                .having((error) => error.name, 'name',
                    'parameters.value.battleItems')
                .having((error) => error.message, 'message',
                    contains('JSON keys must not be blank')));
    await expectLater(mutate(actionId, parameters, jsonl), throwsA(matcher),
        reason: reason);
    expect(await file.readAsBytes(), before, reason: reason);
    expect(await catalog.readAsBytes(), catalogBefore, reason: reason);
    expect(await revision(), revisionBefore, reason: reason);
  }

  Future<void> reopen() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}
