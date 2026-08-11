import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/features/gameplay/items/item_studio_gateway.dart';

void main() {
  test('editor gateway creates queries simulates and undoes an item', () async {
    final root = await Directory.systemTemp.createTemp(
      'item-editor-transport-',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    await _writeFixture(root);

    const reader = LocalProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: _FixedProjectRootLocator(root.path),
    );
    addTearDown(mutations.closeAll);
    addTearDown(queries.closeAll);
    final gateway = CanonicalItemStudioGateway(
      queries: queries,
      mutations: mutations,
    );

    final initial = await gateway.load(root.path);
    expect(initial.definitions.map((definition) => definition.id), <String>[
      'potion',
    ]);

    final receipt = await gateway.save(
      root.path,
      definition: const ProjectItemDefinition(
        id: 'field-tonic',
        displayName: 'Field Tonic',
        pocketId: 'medicine',
        buyPrice: 300,
      ),
      snapshotRevision: initial.snapshotRevision,
    );
    final created = await gateway.load(root.path);
    final simulation = await gateway.simulate(
      root.path,
      itemId: 'field-tonic',
      context: ProjectItemUseContext.overworld,
    );

    expect(created.definitions.map((definition) => definition.id), <String>[
      'field-tonic',
      'potion',
    ]);
    expect(simulation, containsPair('context', 'overworld'));

    await gateway.undo(root.path, receiptId: receipt.receiptId);
    final undone = await gateway.load(root.path);
    expect(undone.definitions.map((definition) => definition.id), <String>[
      'potion',
    ]);
  });

  test('editor adapter executes and undoes every item mutation', () async {
    final executedActions = <String>{};
    final receiptIds = <String>{};

    for (final scenario in _itemMutationScenarios) {
      final harness = await _EditorItemHarness.create(scenario.slug);
      addTearDown(harness.dispose);

      final execution = await harness.execute(scenario);

      expect(execution.receipt.actionId, scenario.actionId);
      expect(execution.receipt.status, AuthoringReceiptStatus.applied);
      expect(execution.afterRevision, isNot(execution.beforeRevision));
      expect(execution.queriedRevision, execution.afterRevision);
      expect(execution.afterCatalog, isNot(execution.beforeCatalog));
      expect(execution.restoredCatalog, execution.beforeCatalog);
      expect(execution.undoReceipt.actionId, 'history.undo');
      expect(execution.historyEntryCount, 2);

      executedActions.add(execution.receipt.actionId);
      receiptIds.add(execution.receipt.receiptId);
    }

    expect(executedActions, _durableItemActionIds);
    expect(receiptIds, hasLength(_durableItemActionIds.length));
  });

  test('editor refusals preserve catalog and create no history', () async {
    final cases = <(_ItemMutationScenario, String, String?)>[
      (
        _itemMutationScenarios.first,
        'plan.stale',
        'sha256:${List<String>.filled(64, '0').join()}',
      ),
      (
        const _ItemMutationScenario('item.set_held_effect', <String, Object?>{
          'itemId': ' potion ',
          'heldEffectId': 'battle.leftovers',
        }),
        'item.parameter_invalid',
        null,
      ),
      (
        const _ItemMutationScenario('item.delete_apply', <String, Object?>{
          'itemId': 'potion',
        }),
        'item.delete_references_blocking',
        null,
      ),
    ];

    for (final entry in cases) {
      final scenario = entry.$1;
      final harness = await _EditorItemHarness.create(
        'refusal-${scenario.slug}-${entry.$2}',
      );
      addTearDown(harness.dispose);

      final refusal = await harness.refuse(
        scenario,
        revisionOverride: entry.$3,
      );

      expect(refusal.failure.code, entry.$2);
      expect(refusal.afterCatalog, refusal.beforeCatalog);
      expect(refusal.historyEntryCount, 0);
      expect(harness.mutations.lastAppliedReceipt, isNull);
    }
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
      _ItemMutationScenario('item.create', <String, Object?>{
        'definition': const ProjectItemDefinition(
          id: 'field-tonic',
          displayName: 'Field Tonic',
          pocketId: 'medicine',
          buyPrice: 300,
        ).toJson(),
      }),
      _ItemMutationScenario('item.update', <String, Object?>{
        'itemId': 'potion',
        'definition': const ProjectItemDefinition(
          id: 'potion',
          displayName: 'Super Potion',
          pocketId: 'medicine',
          buyPrice: 700,
        ).toJson(),
      }),
      const _ItemMutationScenario('item.clone', <String, Object?>{
        'sourceItemId': 'potion',
        'newItemId': 'potion-copy',
        'displayName': 'Potion Copy',
      }),
      const _ItemMutationScenario('item.delete_apply', <String, Object?>{
        'itemId': 'discardable',
      }),
      _ItemMutationScenario('item.set_overworld_effect', <String, Object?>{
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
      }),
      _ItemMutationScenario('item.set_battle_effect', <String, Object?>{
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
      }),
      const _ItemMutationScenario('item.set_held_effect', <String, Object?>{
        'itemId': 'potion',
        'heldEffectId': 'leftovers',
      }),
      _ItemMutationScenario('item.set_capture_effect', <String, Object?>{
        'itemId': 'potion',
        'capture': const ProjectCaptureItemDefinition(
          rateNumerator: 3,
          rateDenominator: 2,
          allowedEncounterKinds: <EncounterKind>{EncounterKind.walk},
        ).toJson(),
      }),
      _ItemMutationScenario('item.set_tm_hm_move', <String, Object?>{
        'itemId': 'potion',
        'machine': const ProjectMoveMachineItemDefinition(
          moveId: 'cut',
          kind: ProjectMoveMachineKind.tm,
          consumable: true,
        ).toJson(),
      }),
    ];

final class _ItemMutationScenario {
  const _ItemMutationScenario(this.actionId, this.parameters);

  final String actionId;
  final Map<String, Object?> parameters;

  String get slug => actionId.replaceAll('.', '-').replaceAll('_', '-');
}

final class _EditorItemExecution {
  const _EditorItemExecution({
    required this.receipt,
    required this.undoReceipt,
    required this.beforeRevision,
    required this.afterRevision,
    required this.queriedRevision,
    required this.beforeCatalog,
    required this.afterCatalog,
    required this.restoredCatalog,
    required this.historyEntryCount,
  });

  final AuthoringReceipt receipt;
  final AuthoringReceipt undoReceipt;
  final String beforeRevision;
  final String afterRevision;
  final String queriedRevision;
  final Map<String, dynamic> beforeCatalog;
  final Map<String, dynamic> afterCatalog;
  final Map<String, dynamic> restoredCatalog;
  final int historyEntryCount;
}

final class _EditorItemRefusal {
  const _EditorItemRefusal({
    required this.failure,
    required this.beforeCatalog,
    required this.afterCatalog,
    required this.historyEntryCount,
  });

  final EditorAuthoringMutationFailure failure;
  final Map<String, dynamic> beforeCatalog;
  final Map<String, dynamic> afterCatalog;
  final int historyEntryCount;
}

final class _EditorItemHarness {
  _EditorItemHarness({
    required this.root,
    required this.queries,
    required this.mutations,
  });

  final Directory root;
  final AuthoringQueryAdapter queries;
  final AuthoringMutationAdapter mutations;

  static Future<_EditorItemHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp('item-editor-$suffix-');
    await _writeFixture(root, includeDiscardable: true);
    const reader = LocalProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: _FixedProjectRootLocator(root.path),
    );
    return _EditorItemHarness(
      root: root,
      queries: queries,
      mutations: mutations,
    );
  }

  Future<_EditorItemExecution> execute(_ItemMutationScenario scenario) async {
    final beforeCatalog = await catalogJson();
    final before = await queries.open(root.path);
    final beforeRevision = before.snapshotRevision;
    final plan = await mutations.plan(
      root.path,
      actionId: scenario.actionId,
      parameters: scenario.parameters,
      idempotencyKey: 'editor-${scenario.slug}',
      requestId: 'editor-${scenario.slug}',
      expectedRevision: beforeRevision,
    );
    final confirmationToken = scenario.actionId == 'item.delete_apply'
        ? await mutations.confirm(plan)
        : null;
    final applied = await mutations.apply(
      plan,
      operationId: 'editor-${scenario.slug}',
      confirmationToken: confirmationToken,
    );
    final queried = await queries.open(root.path);
    final queriedCatalog = queried.query(
      AuthoringQueryRequest(
        resourceKind: 'itemDefinition',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ),
    );
    final afterCatalog = await catalogJson();
    final undone = await mutations.undo(
      root.path,
      entryId: applied.receipt.receiptId,
      idempotencyKey: 'editor-undo-${scenario.slug}',
    );
    return _EditorItemExecution(
      receipt: applied.receipt,
      undoReceipt: undone.receipt,
      beforeRevision: beforeRevision,
      afterRevision: applied.snapshotRevision,
      queriedRevision: queriedCatalog['snapshotRevision']! as String,
      beforeCatalog: beforeCatalog,
      afterCatalog: afterCatalog,
      restoredCatalog: await catalogJson(),
      historyEntryCount: await historyEntryCount(),
    );
  }

  Future<_EditorItemRefusal> refuse(
    _ItemMutationScenario scenario, {
    String? revisionOverride,
  }) async {
    final beforeCatalog = await catalogJson();
    final before = await queries.open(root.path);
    late final EditorAuthoringMutationFailure failure;
    try {
      await mutations.plan(
        root.path,
        actionId: scenario.actionId,
        parameters: scenario.parameters,
        idempotencyKey: 'editor-refusal-${scenario.slug}',
        requestId: 'editor-refusal-${scenario.slug}',
        expectedRevision: revisionOverride ?? before.snapshotRevision,
      );
      throw StateError('Expected the editor mutation plan to be refused.');
    } on EditorAuthoringMutationFailure catch (caught) {
      failure = caught;
    }
    return _EditorItemRefusal(
      failure: failure,
      beforeCatalog: beforeCatalog,
      afterCatalog: await catalogJson(),
      historyEntryCount: await historyEntryCount(),
    );
  }

  Future<Map<String, dynamic>> catalogJson() async =>
      jsonDecode(
            await File(
              '${root.path}/data/pokemon/catalogs/items.json',
            ).readAsString(),
          )
          as Map<String, dynamic>;

  Future<int> historyEntryCount() async {
    final file = File('${root.path}/.pokemap/authoring/history.jsonl');
    if (!await file.exists()) return 0;
    return (await file.readAsLines()).where((line) => line.isNotEmpty).length;
  }

  Future<void> dispose() async {
    await mutations.closeAll();
    await queries.closeAll();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _FixedProjectRootLocator implements EditorProjectRootLocator {
  const _FixedProjectRootLocator(this.root);

  final String root;

  @override
  Future<String> locateForResource(String resourcePath) async => root;
}

Future<void> _writeFixture(
  Directory root, {
  bool includeDiscardable = false,
}) async {
  await File('${root.path}/project.json').writeAsString(
    jsonEncode(
      const ProjectManifest(
        name: 'Item editor transport fixture',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        newGame: ProjectNewGameConfig(
          initialBag: <BagEntry>[BagEntry(itemId: 'potion', quantity: 1)],
        ),
      ).toJson(),
    ),
  );
  final catalogFile = File('${root.path}/data/pokemon/catalogs/items.json');
  await catalogFile.parent.create(recursive: true);
  await catalogFile.writeAsString(
    jsonEncode(
      encodeProjectItemCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: <ProjectItemDefinition>[
            const ProjectItemDefinition(
              id: 'potion',
              displayName: 'Potion',
              pocketId: 'medicine',
            ),
            if (includeDiscardable)
              const ProjectItemDefinition(
                id: 'discardable',
                displayName: 'Discardable',
                pocketId: 'custom',
              ),
          ],
        ),
      ),
    ),
  );
}
