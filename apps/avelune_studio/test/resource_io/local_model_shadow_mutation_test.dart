import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../support/model_shadow_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('portable catalogs refuse changed and unchanged shadow defaults without writes', () async {
    final fixture = await ModelShadowFixture.create(
      storage: ProjectSessionStorage.portableCatalog,
    );
    addTearDown(fixture.dispose);
    final descriptor = await File('${fixture.root.path}/project.json')
        .readAsBytes();
    for (final enabled in [true, false]) {
      await expectLater(
        fixture.resources.mutate('model3d.configure', {
          'modelId': 'house',
          'castsShadowsByDefault': enabled,
        }),
        throwsA(
          isA<ResourceFailure>().having(
            (failure) => failure.message,
            'read only',
            contains('lecture seule'),
          ),
        ),
      );
      expect(
        await File('${fixture.root.path}/project.json').readAsBytes(),
        descriptor,
      );
    }
  });
  test('a completed indexed native transaction is verified and retired before the next shadow edit', () async {
    final fixture = await ModelShadowFixture.create(
      storage: ProjectSessionStorage.manifest,
    );
    addTearDown(fixture.dispose);
    final outside = Zone.current;
    await IOOverrides.runZoned(
      () => fixture.resources.mutate('model3d.configure', {
        'modelId': 'house',
        'castsShadowsByDefault': true,
      }),
      createDirectory: (path) {
        final directory = outside.run(() => Directory(path));
        final prefix = '${fixture.root.path}/.pokemap/authoring/transactions/';
        return path.startsWith(prefix) &&
                !path.substring(prefix.length).contains('/') &&
                !path.substring(prefix.length).startsWith('.')
            ? _RetirementFailure(directory)
            : directory;
      },
    );
    final pendingFile = File(
      '${fixture.root.path}/.pokemap/authoring/transactions/pending-journals.json',
    );
    final indexed =
        (jsonDecode(await pendingFile.readAsString()) as Map)['operationIds']
            as List;
    expect(indexed, hasLength(1));
    final journal = File(
      '${fixture.root.path}/.pokemap/authoring/transactions/${indexed.single}/journal.json',
    );
    expect(await journal.exists(), isTrue);
    final receipt = await fixture.resources.mutate('model3d.configure', {
      'modelId': 'house',
      'castsShadowsByDefault': false,
    });
    expect(receipt.manifest.models3d.single.castsShadowsByDefault, isFalse);
    expect(await journal.exists(), isFalse);
    expect(
      (jsonDecode(await pendingFile.readAsString()) as Map)['operationIds'],
      isEmpty,
    );
  });
  for (final storage in [
    ProjectSessionStorage.manifest,
    ProjectSessionStorage.workingCatalog,
  ]) {
    for (final unrelated in [0, 90]) {
      test(
        'shadow mutation stays local cold and repeated in $storage with $unrelated foreign definitions',
        () async {
          final phases = <String>[];
          final fixture = await ModelShadowFixture.create(
            storage: storage,
            unrelated: unrelated,
            phaseObserver: phases.add,
          );
          addTearDown(fixture.dispose);
          final original = (await fixture.maps.resourceBaseline(
            fixture.session,
          )).manifest;
          final protected = {
            for (final path in fixture.foreignPaths)
              path: await File(path).readAsBytes(),
          };
          for (final enabled in [true, false]) {
            final reads = <String>[];
            final receipt = await fixture.observe(
              () => fixture.resources.mutate('model3d.configure', {
                'modelId': 'house',
                'castsShadowsByDefault': enabled,
              }),
              reads,
              denyForeign: true,
            );
            expect(reads, isEmpty);
            expect(
              receipt.manifest.models3d.first,
              original.models3d.first.copyWith(castsShadowsByDefault: enabled),
            );
            expect(receipt.manifest.maps, same(original.maps));
            final reopened = LocalMapWorkspaceAdapter();
            await reopened.loadCatalog(fixture.session);
            final definitions = storage == ProjectSessionStorage.workingCatalog
                ? (await reopened.loadResourceKind(
                    fixture.session,
                    'model3d',
                  )).metadata
                : (await reopened.resourceBaseline(fixture.session)).manifest;
            expect(
              definitions.models3d
                  .firstWhere((model) => model.id == 'house')
                  .castsShadowsByDefault,
              enabled,
            );
          }
          phases.clear();
          final revision = (await fixture.maps.resourceBaseline(
            fixture.session,
          )).revision;
          final receipt = await fixture.resources.mutate('model3d.configure', {
            'modelId': 'house',
            'castsShadowsByDefault': false,
          });
          expect(receipt.changedPaths, isEmpty);
          expect(receipt.revision, revision);
          expect(phases, ['baseline.start', 'baseline.end']);
          for (final entry in protected.entries) {
            expect(
              await File(entry.key).readAsBytes(),
              entry.value,
              reason: entry.key,
            );
          }
          if (storage == ProjectSessionStorage.manifest) {
            final raw = jsonDecode(
              await File('${fixture.root.path}/project.json').readAsString(),
            ) as Map;
            expect(raw['futureProjectField'], {'preserve': true});
          }
        },
      );
    }
  }
  for (final storage in [
    ProjectSessionStorage.manifest,
    ProjectSessionStorage.workingCatalog,
  ]) {
    test(
      'shadow publication reconciles without replay or unrelated reads in $storage',
      () async {
        var reject = true;
        final fixture = await ModelShadowFixture.create(
          storage: storage,
          beforeReconciliation: () async {
            if (reject) throw StateError('Injected reconciliation failure');
          },
        );
        addTearDown(fixture.dispose);
        ResourceMutationReceipt? published;
        try {
          await fixture.resources.mutate('model3d.configure', {
            'modelId': 'house',
            'castsShadowsByDefault': true,
          });
          fail('The publication must expose the reconciliation failure.');
        } on ResourceFailure catch (failure) {
          published = failure.partialReceipt;
        }
        expect(published, isNotNull);
        reject = false;
        final reads = <String>[];
        await fixture.observe(
          () => fixture.resources.reconcileReceipt(published!),
          reads,
          denyForeign: true,
        );
        expect(reads, isEmpty);
        expect(
          (await fixture.maps.resourceBaseline(fixture.session))
              .manifest
              .models3d
              .single
              .castsShadowsByDefault,
          isTrue,
        );
      },
    );
  }
  for (final storage in [
    ProjectSessionStorage.manifest,
    ProjectSessionStorage.workingCatalog,
  ]) {
    test(
      'completed shadow journals are not reread on cold or repeated $storage saves',
      () async {
        final fixture = await ModelShadowFixture.create(storage: storage);
        addTearDown(fixture.dispose);
        final gateway = await LocalTransactionFileGateway.open(
          projectRoot: fixture.root.path,
        );
        await gateway.preparePendingJournalIndex();
        for (var i = 0; i < 6; i++) {
          final journal = File(
            '${fixture.root.path}/.pokemap/authoring/transactions/retained-$i/journal.json',
          );
          await journal.parent.create(recursive: true);
          await journal.writeAsString(
            jsonEncode(_retainedJournal('retained-$i').toJson()),
          );
        }
        final journals =
            await Directory(
                  '${fixture.root.path}/.pokemap/authoring/transactions',
                )
                .list(recursive: true)
                .where(
                  (entry) =>
                      entry is File && entry.path.endsWith('/journal.json'),
                )
                .toList();
        expect(journals, hasLength(6));
        fixture.foreignPaths.addAll(journals.map((entry) => entry.path));
        final cold = LocalResourceAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        );
        addTearDown(cold.dispose);
        final reads = <String>[];
        for (final enabled in [true, false]) {
          await fixture.observe(
            () => cold.mutate('model3d.configure', {
              'modelId': 'house',
              'castsShadowsByDefault': enabled,
            }),
            reads,
            denyForeign: true,
          );
        }
        expect(reads, isEmpty);
      },
    );
  }
  test(
    'failed shadow transaction preserves the original and permits retry',
    () async {
      var fail = true;
      final fixture = await ModelShadowFixture.create(
        beforeTransaction: () async {
          if (fail) throw StateError('Injected precondition failure');
        },
      );
      addTearDown(fixture.dispose);
      final head = File(
        '${fixture.root.path}/${CatalogStorageStore.headStorageKey}',
      );
      final before = await head.readAsBytes();
      await expectLater(
        fixture.resources.mutate('model3d.configure', {
          'modelId': 'house',
          'castsShadowsByDefault': true,
        }),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await head.readAsBytes(), before);
      fail = false;
      final saved = await fixture.resources.mutate('model3d.configure', {
        'modelId': 'house',
        'castsShadowsByDefault': true,
      });
      expect(saved.manifest.models3d.single.castsShadowsByDefault, isTrue);
    },
  );
  for (final storage in [
    ProjectSessionStorage.manifest,
    ProjectSessionStorage.workingCatalog,
  ]) {
    test(
      'pending recovery blocks a shadow edit without changing $storage data',
      () async {
        final fixture = await ModelShadowFixture.create(storage: storage);
        addTearDown(fixture.dispose);
        final gateway = await LocalTransactionFileGateway.open(
          projectRoot: fixture.root.path,
        );
        await gateway.preparePendingJournalIndex();
        final path = storage == ProjectSessionStorage.manifest
            ? 'project.json'
            : CatalogStorageStore.headStorageKey;
        final before = await File('${fixture.root.path}/$path').readAsBytes();
        await gateway.writeJournal(
          _retainedJournal('pending-shadow', pending: true),
        );
        await expectLater(
          fixture.resources.mutate('model3d.configure', {
            'modelId': 'house',
            'castsShadowsByDefault': true,
          }),
          throwsA(isA<ResourceFailure>()),
        );
        expect(await File('${fixture.root.path}/$path').readAsBytes(), before);
      },
    );
  }
}

final class _RetirementFailure implements Directory {
  _RetirementFailure(this.directory);
  final Directory directory;
  @override
  String get path => directory.path;
  @override
  Future<bool> exists() => directory.exists();
  @override
  Future<Directory> create({bool recursive = false}) =>
      directory.create(recursive: recursive);
  @override
  Future<String> resolveSymbolicLinks() => directory.resolveSymbolicLinks();
  @override
  Future<FileStat> stat() => directory.stat();
  @override
  Future<Directory> rename(String newPath) async =>
      throw const FileSystemException('Injected retirement failure');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthoringTransactionJournal _retainedJournal(
  String operation, {
  bool pending = false,
}) {
  final resource = AuthoringResourceRef(kind: 'project', id: 'project');
  final before = 'sha256:${'0' * 64}', after = 'sha256:${'1' * 64}';
  final receipt = AuthoringReceipt(
    receiptId: 'receipt-$operation',
    requestId: operation,
    actionId: 'fixture.write',
    actionVersion: 1,
    status: AuthoringReceiptStatus.applied,
    createdAtUtc: '2026-11-09T00:00:00.000Z',
    beforeRevision: AuthoringRevisionSet([
      AuthoringResourceRevision(resource: resource, revision: before),
    ]).fingerprint,
    afterRevision: AuthoringRevisionSet([
      AuthoringResourceRevision(resource: resource, revision: after),
    ]).fingerprint,
    diff: AuthoringDiff([
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: '/',
        before: false,
        after: true,
      ),
    ]),
  );
  return AuthoringTransactionJournal(
    operationId: operation,
    planId: 'plan-$operation',
    scope: AuthoringIdempotencyScope(
      actorId: 'actor',
      projectId: 'project',
      actionId: 'fixture.write',
      actionVersion: 1,
      key: operation,
    ),
    status: pending
        ? AuthoringTransactionStatus.prepared
        : AuthoringTransactionStatus.committed,
    createdAt: DateTime.utc(2026, 11, 9),
    updatedAt: DateTime.utc(2026, 11, 9),
    entries: [
      AuthoringTransactionJournalEntry(
        resource: resource,
        storageKey: 'project.json',
        beforeRevision: before,
        afterRevision: after,
      ),
    ],
    intendedReceipt: receipt,
    finalReceipt: pending ? null : receipt,
  );
}
