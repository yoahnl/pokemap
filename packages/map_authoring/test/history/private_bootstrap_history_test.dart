import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('default sessions retain history and undo blobs', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.attach();
    final receipt = await fixture.addFact(0);
    final history = await fixture.api.history(fixture.opened.projectHandle, limit: 100);
    expect(history['entries'], hasLength(1));
    expect(await fixture.blobs(), isNotEmpty);
    expect(receipt.status, AuthoringReceiptStatus.applied);
  });

  test('private bootstrap keeps receipts audit and journals without undo blobs', () async {
    final fixture = await _Fixture.create(retainUndoHistory: false);
    addTearDown(fixture.dispose);
    await fixture.attach();
    for (var index = 0; index < 24; index++) {
      final receipt = await fixture.addFact(index);
      expect(receipt.status, AuthoringReceiptStatus.applied);
      expect(receipt.beforeRevision, isNot(receipt.afterRevision));
    }
    final snapshot = await fixture.loader.load(fixture.opened.projectHandle);
    expect(snapshot.manifest.facts, hasLength(24));
    expect((await fixture.api.history(fixture.opened.projectHandle, limit: 100))['entries'], isEmpty);
    expect(await fixture.blobs(), isEmpty);
    expect(await File('${fixture.path}/.pokemap/authoring/idempotency.jsonl').length(), greaterThan(0));
    expect(await Directory('${fixture.path}/.pokemap/authoring/transactions')
        .list().where((entry) => entry is Directory).toList(), isEmpty);
    final metadata = await Directory('${fixture.path}/.pokemap/authoring')
        .list(recursive: true).toList();
    expect(metadata.where((entry) => entry.path.contains('audit')), isNotEmpty);
    await fixture.api.detachWorkspace(fixture.opened.workspaceHandle);
    fixture.replaceApi();
    await fixture.attach();
    await fixture.addFact(24);
    expect((await fixture.api.history(fixture.opened.projectHandle, limit: 100))['entries'], hasLength(1));
    expect(await fixture.blobs(), isNotEmpty);
  });

  for (final checkpoint in [
    AuthoringTransactionCheckpoint.beforeResourcePromotion,
    AuthoringTransactionCheckpoint.afterResourcePromoted,
  ]) {
    test('private bootstrap preserves recovery at ${checkpoint.name}', () async {
      var crashed = false;
      final fixture = await _Fixture.create(retainUndoHistory: false,
          faultInjector: (context) {
            if (!crashed && context.checkpoint == checkpoint) {
              crashed = true;
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
      addTearDown(fixture.dispose);
      await fixture.attach();
      final before = await File('${fixture.path}/project.json').readAsBytes();
      await expectLater(fixture.addFact(0), throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      if (checkpoint == AuthoringTransactionCheckpoint.beforeResourcePromotion) {
        expect(await File('${fixture.path}/project.json').readAsBytes(), before);
      }
      final gateway = await LocalTransactionFileGateway.open(projectRoot: fixture.path);
      expect(await gateway.listJournals(), hasLength(1));
      final recovered = await fixture.api.recoverMutation(fixture.opened.projectHandle,
          operationId: 'fact-0');
      expect(recovered.receipt.status, AuthoringReceiptStatus.recovered);
      expect((await fixture.loader.load(fixture.opened.projectHandle)).manifest.facts, hasLength(1));
      expect((await fixture.api.history(fixture.opened.projectHandle, limit: 100))['entries'], isEmpty);
      expect(await fixture.blobs(), isEmpty);
      expect((await gateway.listJournals()).single.status, AuthoringTransactionStatus.committed);
    });
  }

  test('private bootstrap compensates an ordinary failure after promotion', () async {
    var failed = false;
    final fixture = await _Fixture.create(retainUndoHistory: false,
        faultInjector: (context) {
          if (!failed && context.checkpoint == AuthoringTransactionCheckpoint.afterResourcePromoted) {
            failed = true;
            throw StateError('ordinary bootstrap write failure');
          }
        });
    addTearDown(fixture.dispose);
    await fixture.attach();
    final before = await File('${fixture.path}/project.json').readAsBytes();
    await expectLater(fixture.addFact(0), throwsA(isA<JournaledAuthoringTransactionException>()));
    final gateway = await LocalTransactionFileGateway.open(projectRoot: fixture.path);
    final recovery = AuthoringRecoveryService(gateway: gateway,
        idempotency: AuthoringIdempotencyLedger(store: FileIdempotencyStore(
            filePath: '${fixture.path}/.pokemap/authoring/idempotency.jsonl')),
        clock: DateTime.now);
    await recovery.compensate('fact-0');
    expect(await File('${fixture.path}/project.json').readAsBytes(), before);
    expect((await gateway.listJournals()).single.status, AuthoringTransactionStatus.compensated);
    expect(await fixture.blobs(), isEmpty);
    expect((await fixture.api.history(fixture.opened.projectHandle, limit: 100))['entries'], isEmpty);
  });

  for (final corruption in ['content', 'pokemon', 'settings', 'catalog', 'pending', 'foreign', 'history', 'blob', 'symlink']) {
    test('private bootstrap refuses $corruption before creating a session', () async {
      final fixture = await _Fixture.create(retainUndoHistory: false);
      addTearDown(fixture.dispose);
      final projectFile = File('${fixture.path}/project.json');
      final manifest = ProjectManifest.fromJson(jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>);
      if (corruption == 'content') {
        await projectFile.writeAsString(jsonEncode(manifest.copyWith(facts: [
          NarrativeFactDefinition(id: 'existing', label: 'Existing', initialValue: NarrativeValue.boolean(false)),
        ]).toJson()));
      } else if (corruption == 'pokemon') {
        await projectFile.writeAsString(jsonEncode(manifest.copyWith(pokemon: manifest.pokemon.copyWith(enabled: true)).toJson()));
      } else if (corruption == 'settings') {
        await projectFile.writeAsString(jsonEncode(manifest.copyWith(settings:
            manifest.settings.copyWith(defaultMapWidth: manifest.settings.defaultMapWidth + 1)).toJson()));
      } else if (corruption == 'catalog') {
        await projectFile.writeAsString(jsonEncode({'format': 'avelune.working-catalog'}));
      } else if (corruption == 'pending' || corruption == 'foreign') {
        final ledger = File('${fixture.path}/.pokemap/authoring/idempotency.jsonl');
        final lines = await ledger.readAsLines();
        if (corruption == 'pending') {
          await ledger.writeAsString('${lines.first}\n');
        } else {
          final rows = lines.map((line) => jsonDecode(line) as Map).toList();
          for (final row in rows) {
            ((row['record'] as Map)['scope'] as Map)['actionId'] = 'fact.create';
          }
          await ledger.writeAsString('${rows.map(jsonEncode).join('\n')}\n');
        }
      } else if (corruption == 'symlink') {
        final lock = '${fixture.path}/.pokemap/authoring/idempotency.jsonl.lock';
        await File(lock).delete();
        await Link(lock).create('${fixture.directory.path}/missing-lock');
      } else {
        await Directory('${fixture.path}/.pokemap/authoring/${corruption == 'blob' ? 'blobs' : 'history'}').create();
      }
      final before = await projectFile.readAsBytes();
      await expectLater(fixture.attach(), throwsA(isA<WorkspaceHandleException>()
          .having((error) => error.code, 'code', 'workspace.undo_history_requires_fresh_bootstrap')));
      expect(await projectFile.readAsBytes(), before);
    });
  }
}

final class _Fixture {
  _Fixture(this.directory, this.path, this.policy, this.handles, this.opened,
      this.loader, this.api);

  final Directory directory;
  final String path;
  final WorkspacePolicy policy;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  LocalMapAuthoringMutationApi api;

  static Future<_Fixture> create({bool retainUndoHistory = true,
      AuthoringTransactionFaultInjector? faultInjector}) async {
    final directory = await Directory.systemTemp.createTemp('private-bootstrap-history-');
    final created = await const LocalProjectCreationService().create(
        ProjectCreationRequest(name: 'Bootstrap', folderName: 'project',
            parentPath: directory.path, template: ProjectCreationTemplate.empty));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(created.projectPath);
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader,
        retainUndoHistory: retainUndoHistory, faultInjector: faultInjector);
    return _Fixture(directory, created.projectPath, policy, handles, opened, loader, api);
  }

  void replaceApi() {
    api = LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
  }

  Future<void> attach() => api.attachProject(projectRootPath: path,
      workspaceHandle: opened.workspaceHandle, projectHandle: opened.projectHandle);

  Future<AuthoringReceipt> addFact(int index) async {
    final snapshot = await loader.load(opened.projectHandle);
    final fact = addNarrativeFact(snapshot.manifest, label: 'Fact $index',
        initialValue: NarrativeValue.boolean(false)).createdFact;
    final request = AuthoringRequest(requestId: 'fact-$index', actionId: 'fact.create',
        actionVersion: 1, workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'fact-$index', parameters: {'fact': fact.toJson()});
    final plan = await api.planMutation(opened.projectHandle, request);
    final result = await api.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: 'fact-$index');
    return result.receipt;
  }

  Future<List<FileSystemEntity>> blobs() async {
    final root = Directory('$path/.pokemap/authoring/blobs');
    return await root.exists() ? root.list().toList() : [];
  }

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}
