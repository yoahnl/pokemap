import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    final transport = jsonl ? 'JSONL' : 'API';
    test(
      '$transport configures, reads, reopens and clears bag capacity',
      () async {
        final fixture = await _Fixture.create();
        addTearDown(fixture.dispose);
        final before = await fixture.document();
        expect((await fixture.query(jsonl)).items.single['pockets'], isEmpty);
        await fixture.set(_pockets, jsonl);
        final after = await fixture.document();
        expect(after, {
          ...before,
          'bagCapacity': {'pockets': _pockets},
        });
        expect((await fixture.query(jsonl)).items.single['pockets'], _pockets);
        await fixture.reopen();
        for (final operation in [
          AuthoringQueryOperation.get,
          AuthoringQueryOperation.batchGet,
          AuthoringQueryOperation.list,
          AuthoringQueryOperation.summary,
        ]) {
          final page = await fixture.query(jsonl, operation: operation);
          expect(page.items.single['id'], 'project');
          expect(page.items.single['pockets'], _pockets);
        }
        await fixture.set({}, jsonl);
        expect(await fixture.document(), before);
        expect((await fixture.query(jsonl)).items.single['pockets'], isEmpty);
      },
    );

    test('$transport invalid capacities never change project bytes', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.set(_pockets, jsonl);
      for (final invalid in [
        null,
        [],
        {'medicine': null},
        {
          'medicine': {'maxDistinctItems': 0},
        },
        {
          'medicine': {'maxDistinctItems': -1},
        },
        {
          'medicine': {'maxQuantityPerItem': 1.5},
        },
        {
          'medicine': {'maxQuantityPerItem': '99'},
        },
        {
          'medicine': {'maxQuantityPerItem': true},
        },
        {
          'medicine': {'unknown': 2},
        },
        {
          ' medicine ': {'maxDistinctItems': 2},
        },
      ]) {
        final before = await fixture.bytes();
        await expectLater(fixture.set(invalid, jsonl), _rejected(jsonl));
        expect(await fixture.bytes(), before);
      }
      final before = await fixture.bytes();
      await expectLater(
        fixture.set({}, jsonl, extra: {'globalCapacity': 5}),
        _rejected(jsonl),
      );
      expect(await fixture.bytes(), before);
    });

    test(
      '$transport refuses limits below the initial bag atomically',
      () async {
        final fixture = await _Fixture.create(initialQuantity: 5);
        addTearDown(fixture.dispose);
        final before = await fixture.bytes();
        await expectLater(
          fixture.set({
            'medicine': {'maxQuantityPerItem': 4},
          }, jsonl),
          _rejected(jsonl),
        );
        expect(await fixture.bytes(), before);
        await fixture.set({
          'medicine': {'maxQuantityPerItem': 5},
        }, jsonl);
        expect((await fixture.query(jsonl)).items.single['pockets'], {
          'medicine': {'maxQuantityPerItem': 5},
        });
      },
    );
  }

  test(
    'capacity is discoverable with an explicit complete replacement schema',
    () {
      final descriptor = MapMutationDispatcher.canonical().descriptors
          .singleWhere((action) => action.id == 'bag.capacity.set');
      expect(descriptor.resourceKinds, contains('bagCapacity'));
      expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
      final schema = descriptor.extensions['inputSchema'] as Map;
      expect(schema['required'], contains('pockets'));
      expect(schema['additionalProperties'], false);
      expect(canonicalQueryableResourceKindIds, contains('bagCapacity'));
      final parity = AuthoringFullParityCatalog.canonical()
          .requireMutationAction('bag.capacity.set');
      expect(
        parity.contractTestPath,
        'test/domains/gameplay/bag_capacity_authoring_test.dart',
      );
      expect(
        parity.adapterCapableTransports,
        AuthoringTransport.values.toSet(),
      );
    },
  );

  test(
    'stale revision cannot replace capacity and undo restores exact preimage',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final before = await fixture.bytes();
      final oldRevision = (await fixture.snapshots.load(
        fixture.opened.projectHandle,
      )).revision;
      await fixture.set(_pockets, false);
      final accepted = await fixture.bytes();
      await expectLater(
        fixture.set({}, false, revision: oldRevision),
        throwsA(anything),
      );
      expect(await fixture.bytes(), accepted);
      final history = (await fixture.mutations.listMutationHistory(
        fixture.opened.projectHandle,
        limit: 10,
      )).toJson();
      final entry = Map<String, dynamic>.from(
        (history['entries'] as List).last as Map,
      );
      await fixture.mutations.undo(
        fixture.opened.projectHandle,
        entryId: entry['entryId'] as String,
        idempotencyKey: 'undo-bag-capacity',
      );
      expect(await fixture.bytes(), before);
    },
  );

  for (final duplicate in [false, true]) {
    test(
      'deferred resolved catalog validates initial bag, duplicate=$duplicate',
      () async {
        const catalogPath = 'data/custom/bag-items.json';
        final fixture = await _Fixture.create(
          initialQuantity: 5,
          catalogPath: catalogPath,
        );
        addTearDown(fixture.dispose);
        if (duplicate) {
          final file = File('${fixture.root.path}/$catalogPath');
          final catalog =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          final entries = catalog['entries'] as List;
          entries.add({
            ...Map<String, dynamic>.from(entries.first as Map),
            'id': ' medicine_a ',
          });
          await file.writeAsString(jsonEncode(catalog));
        }
        final snapshot = await fixture.snapshots.load(
          fixture.opened.projectHandle,
          deferPokemonDocuments: true,
        );
        expect(snapshot.itemCatalog, isNull);
        expect(snapshot.hasResource(itemCatalogResourceIdentity), true);
        expect(
          snapshot.resourceStorageKeys[itemCatalogResourceIdentity],
          catalogPath,
        );
        final before = await fixture.bytes();
        AuthoringPlanningContext context(int maximum) =>
            AuthoringPlanningContext(
              snapshot: snapshot,
              request: AuthoringRequest(
                requestId: 'deferred-$maximum',
                actionId: 'bag.capacity.set',
                actionVersion: 1,
                workspaceHandle: fixture.opened.workspaceHandle.value,
                parameters: {
                  'pockets': {
                    'medicine': {'maxQuantityPerItem': maximum},
                  },
                },
                expectedRevision: snapshot.revision,
                idempotencyKey: 'deferred-$maximum',
              ),
              planId: 'deferred-$maximum',
              seed: 1,
            );
        await expectLater(
          const BagCapacityActions().build(context(4)),
          throwsA(
            isA<BagCapacityAuthoringException>().having(
              (error) => error.code,
              'code',
              duplicate
                  ? 'bag.capacity.invalidItemCatalog'
                  : 'bag.capacity.stackFull',
            ),
          ),
        );
        if (!duplicate) {
          final draft = await const BagCapacityActions().build(context(5));
          expect(draft.preview['pockets'], {
            'medicine': {'maxQuantityPerItem': 5},
          });
        }
        expect(await fixture.bytes(), before);
      },
    );
  }
}

const _pockets = {
  'medicine': {'maxDistinctItems': 2, 'maxQuantityPerItem': 99},
  'future_pocket': {'maxDistinctItems': 1},
};

Matcher _rejected(bool jsonl) => throwsA(
  jsonl
      ? isA<AuthoringError>().having(
          (error) => error.details['domainCode'],
          'domainCode',
          startsWith('bag.capacity.'),
        )
      : isA<BagCapacityAuthoringException>(),
);

final class _Fixture {
  _Fixture(this.root, this.reads, this.mutations, this.snapshots, this.opened)
    : worker = JsonlWorker(api: reads, mutations: mutations);

  final Directory root;
  final AuthoringReadApi reads;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  OpenedProject opened;
  final JsonlWorker worker;
  int sequence = 0;

  static Future<_Fixture> create({
    int initialQuantity = 0,
    String catalogPath = 'data/pokemon/catalogs/items.json',
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'bag-capacity-authoring-',
    );
    final manifest = ProjectManifest(
      name: 'Generic bag capacity',
      maps: const [],
      tilesets: const [],
      pokemon: ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        catalogFiles: {
          ...const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          ).catalogFiles,
          'items': catalogPath,
        },
      ),
      newGame: ProjectNewGameConfig(
        initialBag: [
          if (initialQuantity > 0)
            BagEntry(itemId: 'medicine_a', quantity: initialQuantity),
        ],
      ),
    );
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final catalog = File('${root.path}/$catalogPath');
    await catalog.parent.create(recursive: true);
    await catalog.writeAsString(
      jsonEncode(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: const [
            ProjectItemDefinition(
              id: 'medicine_a',
              displayName: 'Medicine A',
              pocketId: 'medicine',
            ),
            ProjectItemDefinition(
              id: 'medicine_b',
              displayName: 'Medicine B',
              pocketId: 'medicine',
            ),
          ],
        ).toJson(),
      ),
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final reads = AuthoringReadApi(
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
    final opened = await reads.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _Fixture(root, reads, mutations, snapshots, opened);
  }

  Future<List<int>> bytes() => File('${root.path}/project.json').readAsBytes();
  Future<Map<String, dynamic>> document() async =>
      jsonDecode(utf8.decode(await bytes())) as Map<String, dynamic>;

  Future<AuthoringQueryPage> query(
    bool jsonl, {
    AuthoringQueryOperation operation = AuthoringQueryOperation.list,
  }) async {
    final request = AuthoringQueryRequest(
      resourceKind: 'bagCapacity',
      operation: operation,
      ids:
          operation == AuthoringQueryOperation.get ||
              operation == AuthoringQueryOperation.batchGet
          ? ['project']
          : const [],
      view: AuthoringQueryView.detail,
    );
    if (!jsonl) return reads.queryProject(opened.projectHandle, request);
    final result = await wire('query', {
      'projectHandle': opened.projectHandle.value,
      'request': request.toJson(),
    });
    return AuthoringQueryPage.fromJson(Map<String, dynamic>.from(result.data));
  }

  Future<void> set(
    Object? pockets,
    bool jsonl, {
    Map<String, Object?> extra = const {},
    String? revision,
  }) async {
    final id = 'capacity-${sequence++}';
    final request = AuthoringRequest(
      requestId: id,
      actionId: 'bag.capacity.set',
      actionVersion: 1,
      workspaceHandle: opened.workspaceHandle.value,
      parameters: {'pockets': pockets, ...extra},
      expectedRevision:
          revision ?? (await snapshots.load(opened.projectHandle)).revision,
      idempotencyKey: id,
      dryRun: false,
    );
    final before = await bytes();
    if (jsonl) {
      final plan = await wire('plan', {
        'projectHandle': opened.projectHandle.value,
        'request': request.toJson(),
      });
      expect(await bytes(), before);
      await wire('apply', {
        'projectHandle': opened.projectHandle.value,
        'planId': plan.data['planId'],
        'operationId': '$id-apply',
      });
    } else {
      final plan = await mutations.plan(opened.projectHandle, request);
      expect(await bytes(), before);
      await mutations.apply(
        opened.projectHandle,
        planId: plan['planId'] as String,
        operationId: '$id-apply',
      );
    }
  }

  Future<AuthoringResult> wire(
    String command,
    Map<String, Object?> args,
  ) async {
    final response = await worker.processLine(
      jsonEncode({
        'id': 'wire-${sequence++}',
        'command': command,
        'args': args,
      }),
    );
    final result = AuthoringResult.fromJson(
      jsonDecode(response) as Map<String, dynamic>,
    );
    if (result.status != AuthoringResultStatus.success) throw result.error!;
    return result;
  }

  Future<void> reopen() async {
    await reads.closeWorkspace(opened.workspaceHandle);
    opened = await reads.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
  }

  Future<void> dispose() async {
    await reads.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}
