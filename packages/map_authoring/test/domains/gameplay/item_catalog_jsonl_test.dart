import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('item mutation transport parity', () {
    test('describes the four resources and nine durable actions', () async {
      final harness = await _ItemTransportHarness.create('describe');
      addTearDown(harness.dispose);

      final described = await _request(harness.worker, 'describe');
      final resourceKinds = (described.data['resourceKinds']! as List)
          .cast<Map<String, Object?>>()
          .map((descriptor) => descriptor['id'])
          .toSet();
      final actionIds = (described.data['mutationActions']! as List)
          .cast<Map<String, Object?>>()
          .map((descriptor) => descriptor['id'])
          .whereType<String>()
          .where((id) => id.startsWith('item.'))
          .toSet();

      expect(
        resourceKinds,
        containsAll(<String>{
          'itemCatalog',
          'itemDefinition',
          'itemUsage',
          'itemReadiness',
        }),
      );
      expect(actionIds, _durableItemActionIds);
    });

    test('executes every mutation through direct API and JSONL', () async {
      final executedByTransport = <String, Set<String>>{
        'direct': <String>{},
        'jsonl': <String>{},
      };
      final receiptIds = <String>{};

      for (final scenario in _itemMutationScenarios) {
        final direct = await _ItemTransportHarness.create(
          'direct-${scenario.slug}',
        );
        final jsonl = await _ItemTransportHarness.create(
          'jsonl-${scenario.slug}',
        );
        addTearDown(direct.dispose);
        addTearDown(jsonl.dispose);

        final directResult = await direct.executeDirect(scenario);
        final jsonlResult = await jsonl.executeJsonl(scenario);

        expect(directResult.receipt['actionId'], scenario.actionId);
        expect(jsonlResult.receipt['actionId'], scenario.actionId);
        expect(directResult.receipt['status'], 'applied');
        expect(jsonlResult.receipt['status'], 'applied');
        expect(directResult.receipt['beforeRevision'], isNotNull);
        expect(directResult.receipt['afterRevision'], isNotNull);
        expect(jsonlResult.receipt['beforeRevision'], isNotNull);
        expect(jsonlResult.receipt['afterRevision'], isNotNull);
        expect(directResult.catalog, jsonlResult.catalog);

        executedByTransport['direct']!.add(
          directResult.receipt['actionId']! as String,
        );
        executedByTransport['jsonl']!.add(
          jsonlResult.receipt['actionId']! as String,
        );
        receiptIds
          ..add('direct:${directResult.receipt['receiptId']}')
          ..add('jsonl:${jsonlResult.receipt['receiptId']}');
      }

      expect(executedByTransport['direct'], _durableItemActionIds);
      expect(executedByTransport['jsonl'], _durableItemActionIds);
      expect(receiptIds, hasLength(_durableItemActionIds.length * 2));
    });

    test('rejects stale revisions without mutating either transport', () async {
      final direct = await _ItemTransportHarness.create('stale-direct');
      final jsonl = await _ItemTransportHarness.create('stale-jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);
      final scenario = _itemMutationScenarios.first;

      final directRefusal = await direct.refuseDirect(
        scenario,
        revisionOverride: 'sha256:${List<String>.filled(64, '0').join()}',
      );
      final jsonlRefusal = await jsonl.refuseJsonl(
        scenario,
        revisionOverride: 'sha256:${List<String>.filled(64, '0').join()}',
      );

      expect(
        directRefusal.error,
        isA<AuthoringPlanException>().having(
          (error) => error.code,
          'code',
          'plan.stale',
        ),
      );
      expect(jsonlRefusal.result!.status, AuthoringResultStatus.failure);
      expect(
        jsonlRefusal.result!.error!.details['domainCode'],
        'plan.stale',
      );
      expect(directRefusal.beforeCatalog, directRefusal.afterCatalog);
      expect(jsonlRefusal.beforeCatalog, jsonlRefusal.afterCatalog);
    });

    test('rejects invalid ids and referenced deletion without mutation',
        () async {
      final scenarios = <_ItemMutationScenario>[
        const _ItemMutationScenario(
          'item.set_held_effect',
          <String, Object?>{
            'itemId': ' potion ',
            'heldEffectId': 'leftovers',
          },
        ),
        const _ItemMutationScenario(
          'item.delete_apply',
          <String, Object?>{'itemId': 'potion'},
        ),
      ];
      scenarios.addAll(<_ItemMutationScenario>[
        _ItemMutationScenario(
          'item.set_battle_effect',
          <String, Object?>{
            'itemId': 'potion',
            'use': const ProjectItemUseDefinition(
              contexts: <ProjectItemUseContext>{
                ProjectItemUseContext.battle,
              },
              target: ProjectItemTargetKind.partyMove,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.restorePp(
                mode: ProjectItemAmountMode.flat,
                amount: 10,
              ),
            ).toJson(),
          },
        ),
        const _ItemMutationScenario(
          'item.set_held_effect',
          <String, Object?>{
            'itemId': 'potion',
            'heldEffectId': 'never_registered_effect',
          },
        ),
      ]);
      final expectedCodes = <String>[
        'item.parameter_invalid',
        'item.delete_references_blocking',
        'item.catalog_invalid',
        'item.catalog_invalid',
      ];

      for (var index = 0; index < scenarios.length; index += 1) {
        final scenario = scenarios[index];
        final direct = await _ItemTransportHarness.create(
          'refusal-direct-${scenario.slug}',
        );
        final jsonl = await _ItemTransportHarness.create(
          'refusal-jsonl-${scenario.slug}',
        );
        addTearDown(direct.dispose);
        addTearDown(jsonl.dispose);

        final directRefusal = await direct.refuseDirect(scenario);
        final jsonlRefusal = await jsonl.refuseJsonl(scenario);

        expect(
          directRefusal.error,
          isA<ItemCatalogAuthoringException>().having(
            (error) => error.code,
            'code',
            expectedCodes[index],
          ),
        );
        expect(jsonlRefusal.result!.status, AuthoringResultStatus.failure);
        expect(directRefusal.beforeCatalog, directRefusal.afterCatalog);
        expect(jsonlRefusal.beforeCatalog, jsonlRefusal.afterCatalog);
      }
    });
  });
}

const _durableItemActionIds = <String>{
  'item.create',
  'item.update',
  'item.clone',
  'item.delete_apply',
  'item.set_overworld_effect',
  'item.set_battle_effect',
  'item.set_held_effect',
  'item.set_capture_effect',
  'item.set_tm_hm_move',
};

final List<_ItemMutationScenario> _itemMutationScenarios =
    <_ItemMutationScenario>[
  _ItemMutationScenario(
    'item.create',
    <String, Object?>{
      'definition': const ProjectItemDefinition(
        id: 'field-tonic',
        displayName: 'Field Tonic',
        pocketId: 'medicine',
        buyPrice: 300,
      ).toJson(),
    },
  ),
  _ItemMutationScenario(
    'item.update',
    <String, Object?>{
      'itemId': 'potion',
      'definition': const ProjectItemDefinition(
        id: 'potion',
        displayName: 'Super Potion',
        pocketId: 'medicine',
        buyPrice: 700,
      ).toJson(),
    },
  ),
  const _ItemMutationScenario(
    'item.clone',
    <String, Object?>{
      'sourceItemId': 'potion',
      'newItemId': 'potion-copy',
      'displayName': 'Potion Copy',
    },
  ),
  const _ItemMutationScenario(
    'item.delete_apply',
    <String, Object?>{'itemId': 'discardable'},
  ),
  _ItemMutationScenario(
    'item.set_overworld_effect',
    <String, Object?>{
      'itemId': 'potion',
      'use': const ProjectItemUseDefinition(
        contexts: <ProjectItemUseContext>{ProjectItemUseContext.overworld},
        target: ProjectItemTargetKind.partyMember,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
      ).toJson(),
    },
  ),
  _ItemMutationScenario(
    'item.set_battle_effect',
    <String, Object?>{
      'itemId': 'potion',
      'use': const ProjectItemUseDefinition(
        contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
        target: ProjectItemTargetKind.partyMember,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 15,
        ),
      ).toJson(),
    },
  ),
  const _ItemMutationScenario(
    'item.set_held_effect',
    <String, Object?>{
      'itemId': 'potion',
      'heldEffectId': 'leftovers',
    },
  ),
  _ItemMutationScenario(
    'item.set_capture_effect',
    <String, Object?>{
      'itemId': 'potion',
      'capture': const ProjectCaptureItemDefinition(
        rateNumerator: 3,
        rateDenominator: 2,
        allowedEncounterKinds: <EncounterKind>{EncounterKind.walk},
      ).toJson(),
    },
  ),
  _ItemMutationScenario(
    'item.set_tm_hm_move',
    <String, Object?>{
      'itemId': 'potion',
      'machine': const ProjectMoveMachineItemDefinition(
        moveId: 'cut',
        kind: ProjectMoveMachineKind.tm,
        consumable: true,
      ).toJson(),
    },
  ),
];

final class _ItemMutationScenario {
  const _ItemMutationScenario(this.actionId, this.parameters);

  final String actionId;
  final Map<String, Object?> parameters;

  String get slug => actionId.replaceAll('.', '-').replaceAll('_', '-');

  AuthoringRequest request({
    required String workspaceHandle,
    required String revision,
    required String transport,
  }) =>
      AuthoringRequest(
        requestId: 'request-$slug-$transport',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: parameters,
        expectedRevision: revision,
        idempotencyKey: 'idempotency-$slug-$transport',
      );
}

final class _ItemExecution {
  const _ItemExecution({required this.receipt, required this.catalog});

  final Map<String, Object?> receipt;
  final Map<String, dynamic> catalog;
}

final class _ItemRefusal {
  const _ItemRefusal({
    required this.beforeCatalog,
    required this.afterCatalog,
    this.error,
    this.result,
  });

  final Map<String, dynamic> beforeCatalog;
  final Map<String, dynamic> afterCatalog;
  final Object? error;
  final AuthoringResult? result;
}

Future<AuthoringResult> _query(
  JsonlWorker worker, {
  required String projectHandle,
  required AuthoringQueryRequest request,
}) {
  return _request(
    worker,
    'query',
    args: <String, Object?>{
      'projectHandle': projectHandle,
      'request': request.toJson(),
    },
  );
}

Future<AuthoringResult> _request(
  JsonlWorker worker,
  String command, {
  Map<String, Object?> args = const <String, Object?>{},
}) async {
  final response = await worker.processLine(
    jsonEncode(<String, Object?>{
      'id': 'item-$command',
      'command': command,
      'args': args,
    }),
  );
  return AuthoringResult.fromJson(
    jsonDecode(response) as Map<String, dynamic>,
  );
}

final class _ItemTransportHarness {
  _ItemTransportHarness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_ItemTransportHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'item-authoring-$suffix-',
    );
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(
        const ProjectManifest(
          name: 'Item transport fixture',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          newGame: ProjectNewGameConfig(
            initialBag: <BagEntry>[
              BagEntry(itemId: 'potion', quantity: 1),
            ],
          ),
        ).toJson(),
      ),
    );
    final catalogFile = File(
      '${root.path}/data/pokemon/catalogs/items.json',
    );
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsString(
      jsonEncode(
        encodeProjectItemCatalog(
          const ProjectItemCatalog(
            schemaVersion: 1,
            entries: <ProjectItemDefinition>[
              ProjectItemDefinition(
                id: 'potion',
                displayName: 'Potion',
                pocketId: 'medicine',
              ),
              ProjectItemDefinition(
                id: 'discardable',
                displayName: 'Discardable',
                pocketId: 'custom',
              ),
            ],
          ),
        ),
      ),
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
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
    return _ItemTransportHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<_ItemExecution> executeDirect(_ItemMutationScenario scenario) async {
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final snapshot = await snapshots.load(opened.projectHandle);
    final plan = await mutations.plan(
      opened.projectHandle,
      scenario.request(
        workspaceHandle: opened.workspaceHandle.value,
        revision: snapshot.revision,
        transport: 'direct',
      ),
    );
    String? confirmationToken;
    if (scenario.actionId == 'item.delete_apply') {
      final confirmation = await mutations.confirm(
        opened.projectHandle,
        planId: plan['planId']! as String,
      );
      confirmationToken = confirmation['confirmationToken']! as String;
    }
    final applied = await mutations.apply(
      opened.projectHandle,
      planId: plan['planId']! as String,
      operationId: 'operation-${scenario.slug}-direct',
      confirmationToken: confirmationToken,
    );
    return _ItemExecution(
      receipt: Map<String, Object?>.from(applied['receipt']! as Map),
      catalog: await catalogJson(),
    );
  }

  Future<_ItemExecution> executeJsonl(_ItemMutationScenario scenario) async {
    final opened = await _request(
      worker,
      'open',
      args: <String, Object?>{'projectRoot': root.path},
    );
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    final definitions = await _query(
      worker,
      projectHandle: projectHandle,
      request: AuthoringQueryRequest(
        resourceKind: 'itemDefinition',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ),
    );
    final plan = await _request(
      worker,
      'plan',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'request': scenario
            .request(
              workspaceHandle: workspaceHandle,
              revision: definitions.data['snapshotRevision']! as String,
              transport: 'jsonl',
            )
            .toJson(),
      },
    );
    String? confirmationToken;
    if (scenario.actionId == 'item.delete_apply') {
      final confirmation = await _request(
        worker,
        'confirm',
        args: <String, Object?>{
          'projectHandle': projectHandle,
          'planId': plan.data['planId'],
        },
      );
      confirmationToken = confirmation.data['confirmationToken']! as String;
    }
    final applied = await _request(
      worker,
      'apply',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'planId': plan.data['planId'],
        'operationId': 'operation-${scenario.slug}-jsonl',
        if (confirmationToken != null) 'confirmationToken': confirmationToken,
      },
    );
    return _ItemExecution(
      receipt: Map<String, Object?>.from(
        applied.data['receipt']! as Map,
      ),
      catalog: await catalogJson(),
    );
  }

  Future<_ItemRefusal> refuseDirect(
    _ItemMutationScenario scenario, {
    String? revisionOverride,
  }) async {
    final beforeCatalog = await catalogJson();
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final snapshot = await snapshots.load(opened.projectHandle);
    Object? error;
    try {
      await mutations.plan(
        opened.projectHandle,
        scenario.request(
          workspaceHandle: opened.workspaceHandle.value,
          revision: revisionOverride ?? snapshot.revision,
          transport: 'direct-refusal',
        ),
      );
    } on Object catch (caught) {
      error = caught;
    }
    return _ItemRefusal(
      beforeCatalog: beforeCatalog,
      afterCatalog: await catalogJson(),
      error: error,
    );
  }

  Future<_ItemRefusal> refuseJsonl(
    _ItemMutationScenario scenario, {
    String? revisionOverride,
  }) async {
    final beforeCatalog = await catalogJson();
    final opened = await _request(
      worker,
      'open',
      args: <String, Object?>{'projectRoot': root.path},
    );
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    final definitions = await _query(
      worker,
      projectHandle: projectHandle,
      request: AuthoringQueryRequest(
        resourceKind: 'itemDefinition',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ),
    );
    final result = await _request(
      worker,
      'plan',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'request': scenario
            .request(
              workspaceHandle: workspaceHandle,
              revision: revisionOverride ??
                  definitions.data['snapshotRevision']! as String,
              transport: 'jsonl-refusal',
            )
            .toJson(),
      },
    );
    return _ItemRefusal(
      beforeCatalog: beforeCatalog,
      afterCatalog: await catalogJson(),
      result: result,
    );
  }

  Future<Map<String, dynamic>> catalogJson() async {
    return jsonDecode(
      await File(
        '${root.path}/data/pokemon/catalogs/items.json',
      ).readAsString(),
    ) as Map<String, dynamic>;
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}
