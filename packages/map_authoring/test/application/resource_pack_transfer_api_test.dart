import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_pack_import_fixture.dart';
import '../domains/assets/resource_pack_export_test.dart' as source;

void main() {
  test('families and all authors page within the escaped MCP envelope and bind cursors to their section', () async {
    final mixed = source.mixedFixture();
    final largeName = '🌲' * 62000;
    final authorNames = [for (var i = 0; i < 3000; i++) 'Auteur $i «"\\ ${'é' * 70}'];
    final original = source.metadata();
    final fixture = await NativeResourcePackImportFixture.create(
      sourceManifest: mixed.$1.copyWith(resourceLibraryCatalog: ResourceLibraryCatalog(families: [ResourceFamily(id: 'long-name', name: largeName)], entries: [ResourceLibraryEntry(resourceKind: 'element', resourceId: 'decor', familyId: 'long-name')])),
      metadata: ResourcePackMetadata(id: original.id, version: original.version, name: original.name, description: original.description, universeId: original.universeId, authors: authorNames, provenance: original.provenance),
    );
    final api = LocalResourcePackTransferApi(mutations: fixture.mutations, snapshotLoader: fixture.loader);
    try {
      final file = File('${fixture.source.directory.path}/attributions.aveluneassets');
      final sink = file.openWrite();
      await fixture.source.archive.withSource((source) => sink.addStream(sourceChunks(source)));
      await sink.close();
      await fixture.mutations.resourcePackPayloadStore(fixture.opened.projectHandle).authorizeSourceFile(file.path);
      Future<Map<String, Object?>> transfer(String verb, Map<String, Object?> input) => api.transfer(fixture.opened.projectHandle, verb: verb, input: input);
      final staged = (await waitForJob(api, fixture.opened.projectHandle, await transfer('stage', {'sourcePath': file.path})))['result']! as Map;
      final inspection = (await waitForJob(api, fixture.opened.projectHandle, await transfer('inspect', {'archiveHandle': staged['archiveHandle']})))['result']! as Map;
      expect(inspection['authorCount'], authorNames.length);
      expect((inspection['pack'] as Map).containsKey('authors'), isFalse);
      final owner = inspection['inspectionHandle'];
      final families = await transfer('entries', {'inspectionHandle': owner, 'section': 'families', 'limit': 50});
      final family = (families['items'] as List).cast<Map>().singleWhere((row) => row['labelComplete'] == false);
      expect(family['labelComplete'], isFalse);
      expect(family['labelLength'], 62000);
      expect((family['label'] as String).runes.length, 160);
      final chosen = await transfer('selection.create', {'mode': 'archive', 'inspectionHandle': owner});
      final familySelection = await transfer('selection.select_filtered', {'selectionHandle': chosen['selectionHandle'], 'revision': chosen['revision'], 'filter': {'familyId': family['id']}});
      expect(familySelection['selectedCount'], 1);
      var page = await transfer('entries', {'inspectionHandle': owner, 'section': 'authors', 'limit': 200});
      final firstCursor = page['nextCursor'];
      final authors = <String>[];
      while (true) {
        final envelope = {'content': [{'type': 'text', 'text': jsonEncode({'data': page})}], 'structuredContent': {'data': page}};
        expect(utf8.encode(jsonEncode(envelope)).length, lessThanOrEqualTo(256 * 1024));
        expect((page['items'] as List).length, lessThanOrEqualTo(200));
        authors.addAll((page['items'] as List).map((row) => (row as Map)['label'] as String));
        if (page['nextCursor'] == null) break;
        page = await transfer('entries', {'inspectionHandle': owner, 'section': 'authors', 'limit': 200, 'cursor': page['nextCursor']});
      }
      expect(authors, authorNames);
      await expectLater(transfer('entries', {'inspectionHandle': owner, 'section': 'families', 'cursor': firstCursor}), throwsA(isA<ResourcePackTransferException>()));
    } finally { await api.closeTransferWorkspace(fixture.opened.workspaceHandle); await fixture.dispose(); }
  });
  test('release preview invalidates its cursor and preserves other previews and selection', () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final api = LocalResourcePackTransferApi(
      mutations: fixture.mutations,
      snapshotLoader: fixture.loader,
    );
    try {
      final file = File(
        '${fixture.source.directory.path}/preview.aveluneassets',
      );
      final sink = file.openWrite();
      await fixture.source.archive.withSource(
        (source) => sink.addStream(sourceChunks(source)),
      );
      await sink.close();
      await fixture.mutations
          .resourcePackPayloadStore(fixture.opened.projectHandle)
          .authorizeSourceFile(file.path);
      Future<Map> job(String verb, Map<String, Object?> input) async =>
          (await waitForJob(
                api,
                fixture.opened.projectHandle,
                await api.transfer(
                  fixture.opened.projectHandle,
                  verb: verb,
                  input: input,
                ),
              ))['result']!
              as Map;
      final archive = await job('stage', {'sourcePath': file.path});
      final inspected = await job('inspect', {
        'archiveHandle': archive['archiveHandle'],
      });
      expect((inspected['pack'] as Map)['name'], isA<String>());
      expect(inspected['archiveBytes'], await file.length());
      expect(inspected['authorCount'], greaterThan(0));
      final authors = await api.transfer(fixture.opened.projectHandle, verb: 'entries', input: {'inspectionHandle': inspected['inspectionHandle'], 'section': 'authors', 'limit': 1});
      expect((authors['items'] as List).single, containsPair('kind', 'author'));
      final families = await api.transfer(fixture.opened.projectHandle, verb: 'entries', input: {'inspectionHandle': inspected['inspectionHandle'], 'section': 'families', 'limit': 1});
      expect((families['items'] as List).length, lessThanOrEqualTo(1));
      var selection = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'selection.create',
        input: {
          'mode': 'archive',
          'inspectionHandle': inspected['inspectionHandle'],
        },
      );
      selection = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'selection.select_filtered',
        input: {
          'selectionHandle': selection['selectionHandle'],
          'revision': selection['revision'],
          'filter': <String, Object?>{},
        },
      );
      final input = {
        'selectionHandle': selection['selectionHandle'],
        'revision': selection['revision'],
        'expectedRevision': (await fixture.loader.load(
          fixture.opened.projectHandle,
        )).revision,
      };
      final first = await job('prepare', input);
      final summary = first['summary'] as Map;
      expect(summary['selectedResourceCount'], selection['selectedCount']);
      expect(summary['sourceBytes'], greaterThan(0));
      expect(summary['writeBytes'], greaterThan(0));
      expect(summary['createdDefinitionCount'], summary['definitionCount']);
      expect(summary['copiedDefinitionCount'], 0);
      final second = await job('prepare', input);
      final page = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'preview',
        input: {'previewHandle': first['previewHandle'], 'limit': 1},
      );
      expect(page['nextCursor'], isNotNull);
      expect(((page['items'] as List).first as Map)['label'], isA<String>());
      expect(((page['items'] as List).first as Map)['requiredByLabel'], isA<String>());
      expect(
        await api.transfer(
          fixture.opened.projectHandle,
          verb: 'release',
          input: {'handle': first['previewHandle']},
        ),
        {'released': true},
      );
      await expectLater(
        api.transfer(
          fixture.opened.projectHandle,
          verb: 'preview',
          input: {
            'previewHandle': first['previewHandle'],
            'cursor': page['nextCursor'],
          },
        ),
        throwsA(isA<ResourcePackTransferException>()),
      );
      await expectLater(
        api.queryTransfer(
          fixture.opened.projectHandle,
          AuthoringQueryRequest(
            operation: AuthoringQueryOperation.get,
            resourceKind: 'resourcePackPreview',
            ids: [first['previewHandle']! as String],
          ),
        ),
        throwsA(isA<ResourcePackTransferException>()),
      );
      final retainedPreview = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'preview',
        input: {'previewHandle': second['previewHandle']},
      );
      final sourceCatalog = fixture.source.archive.inspection.catalog.toJson();
      final sourceBorder = ((sourceCatalog['borderCatalog'] as Map)['records']
              as List)
          .single as Map;
      expect(sourceBorder['draft'], isNull);
      final publishedName =
          ((sourceBorder['latestPublished'] as Map)['definition'] as Map)['name'];
      expect(publishedName, 'Original border');
      final borderRow = (retainedPreview['items'] as List).cast<Map>().singleWhere(
          (row) => row['kind'] == 'borderBlueprint');
      expect(borderRow['selected'], isTrue);
      expect(borderRow['label'], publishedName);
      expect(borderRow['requiredByLabel'], publishedName);
      expect(
        (await api.transfer(
          fixture.opened.projectHandle,
          verb: 'entries',
          input: {'selectionHandle': selection['selectionHandle']},
        ))['items'],
        isNotEmpty,
      );
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });
  test('pack start_apply rejects an ordinary plan before writing while canonical ordinary apply remains available', () async {
    final fixture = await NativeResourcePackImportFixture.create(target: ProjectManifest(
        name: 'Ordinary budget', maps: [], tilesets: [], settings: ProjectSettings(tileWidth: 2, tileHeight: 2),
        resourceLibraryCatalog: ResourceLibraryCatalog(families: [ResourceFamily(id: 'existing', name: 'x' * 124000)])));
    final api = LocalResourcePackTransferApi(mutations: fixture.mutations, snapshotLoader: fixture.loader);
    try {
      final before = await File('${fixture.root.path}/project.json').readAsBytes();
      final snapshot = await fixture.loader.load(fixture.opened.projectHandle);
      final plan = await fixture.mutations.planMutation(fixture.opened.projectHandle,
          AuthoringRequest(requestId: 'ordinary-budget', actionId: 'resource.family.create', actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value, expectedRevision: snapshot.revision,
              idempotencyKey: 'ordinary-budget', parameters: {'familyId': 'new-family', 'name': 'Ordinary'}));
      final start = await api.transfer(fixture.opened.projectHandle, verb: 'start_apply',
          input: {'planId': plan.planId, 'operationId': 'ordinary-budget'});
      expect((start['snapshot'] as Map)['state'], 'queued');
      final refused = await waitForJob(api, fixture.opened.projectHandle, start);
      expect((refused['snapshot'] as Map)['state'], 'failed');
      expect((refused['snapshot'] as Map)['errorCode'], 'resource_pack.plan_kind_invalid');
      expect(refused['phase'], 'failed');
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), before);
      expect((await fixture.loader.load(fixture.opened.projectHandle)).manifest.resourceLibraryCatalog.families
          .any((family) => family.id == 'new-family'), false);
      final ordinary = await fixture.mutations.applyMutation(fixture.opened.projectHandle,
          planId: plan.planId, operationId: 'ordinary-budget');
      expect(ordinary.receipt.status, AuthoringReceiptStatus.applied);
      expect((await fixture.loader.load(fixture.opened.projectHandle)).manifest.resourceLibraryCatalog.families
          .any((family) => family.id == 'new-family'), true);
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  test(
    'stages on disk then inspects in the P04 worker while returning job IDs',
    () async {
      final fixture = await NativeResourcePackImportFixture.create();
      final port = ReceivePort();
      final observed = port.first;
      final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations,
        snapshotLoader: fixture.loader,
        inspectSource: _observer(port.sendPort),
      );
      try {
        final path = '${fixture.source.directory.path}/source.aveluneassets';
        final sink = File(path).openWrite();
        await fixture.source.archive.withSource((source) async {
          await sink.addStream(sourceChunks(source));
        });
        await sink.close();
        final store = fixture.mutations.resourcePackPayloadStore(
          fixture.opened.projectHandle,
        );
        final rejected = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'stage',
          input: {'sourcePath': path},
        );
        final denied = await waitForJob(
          api,
          fixture.opened.projectHandle,
          rejected,
        );
        expect(
          (denied['snapshot'] as Map)['errorCode'],
          'resource_pack.source_outside_allowed_roots',
        );
        await store.authorizeSourceFile(path);
        final start = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'stage',
          input: {'sourcePath': path},
        );
        expect((start['snapshot'] as Map)['state'], 'queued');
        expect(
          ((start['snapshot'] as Map)['request'] as Map)['input'],
          isEmpty,
        );
        final staged = await waitForJob(
          api,
          fixture.opened.projectHandle,
          start,
        );
        expect((staged['snapshot'] as Map)['state'], 'succeeded');
        final inspect = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'inspect',
          input: {'archiveHandle': (staged['result'] as Map)['archiveHandle']},
        );
        expect((inspect['snapshot'] as Map)['state'], 'queued');
        expect(await observed, isNot(Isolate.current.hashCode));
        final inspected = await waitForJob(
          api,
          fixture.opened.projectHandle,
          inspect,
        );
        expect((inspected['snapshot'] as Map)['state'], 'succeeded');
        expect((inspected['result'] as Map)['fileCount'], greaterThan(0));
        final result = inspected['result'] as Map;
        final selected = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'selection.create',
          input: {
            'mode': 'archive',
            'inspectionHandle': result['inspectionHandle'],
          },
        );
        final chosen = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'selection.select_filtered',
          input: {
            'selectionHandle': selected['selectionHandle'],
            'revision': selected['revision'],
            'filter': {'kind': 'element'},
          },
        );
        expect(chosen['selectedCount'], greaterThan(0));
        final hidden = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'entries',
          input: {
            'selectionHandle': selected['selectionHandle'],
            'filter': {'kind': 'model3d'},
          },
        );
        expect(
          (hidden['items'] as List).every(
            (row) => (row as Map)['selected'] == false,
          ),
          isTrue,
        );
        final prepare = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'prepare',
          input: {
            'selectionHandle': chosen['selectionHandle'],
            'revision': chosen['revision'],
            'expectedRevision': (await fixture.loader.load(
              fixture.opened.projectHandle,
            )).revision,
          },
        );
        final prepared = await waitForJob(
          api,
          fixture.opened.projectHandle,
          prepare,
        );
        expect(
          (prepared['snapshot'] as Map)['state'],
          'succeeded',
          reason: prepared.toString(),
        );
        final details = prepared['result'] as Map;
        final plan = await fixture.mutations.planMutation(
          fixture.opened.projectHandle,
          AuthoringRequest(
            requestId: 'p09-plan',
            actionId: 'resource_pack.import',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: (await fixture.loader.load(
              fixture.opened.projectHandle,
            )).revision,
            idempotencyKey: 'p09-import',
            parameters: {
              'preparedImportHandle': details['preparedImportHandle'],
            },
          ),
        );
        final apply = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'start_apply',
          input: {'planId': plan.planId, 'operationId': 'p09-operation'},
        );
        final applied = await waitForJob(
          api,
          fixture.opened.projectHandle,
          apply,
        );
        expect(
          (applied['snapshot'] as Map)['state'],
          'succeeded',
          reason: applied.toString(),
        );
        final receipt =
            ((applied['result'] as Map)['receipt'] as Map)['receiptId'];
        final undoStart = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'start_history',
          input: {
            'operation': 'undo',
            'entryId': receipt,
            'operationId': 'p09-undo',
            'expectedRevision': (await fixture.loader.load(
              fixture.opened.projectHandle,
            )).revision,
          },
        );
        final undone = await waitForJob(
          api,
          fixture.opened.projectHandle,
          undoStart,
        );
        expect(
          (undone['snapshot'] as Map)['state'],
          'succeeded',
          reason: undone.toString(),
        );
        final redo = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'start_history',
          input: {
            'operation': 'redo',
            'entryId': receipt,
            'operationId': 'p09-redo',
            'expectedRevision': (await fixture.loader.load(
              fixture.opened.projectHandle,
            )).revision,
          },
        );
        final redone = await waitForJob(
          api,
          fixture.opened.projectHandle,
          redo,
        );
        expect(
          (redone['snapshot'] as Map)['state'],
          'succeeded',
          reason: redone.toString(),
        );
        final native = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'selection.create',
          input: {'mode': 'native'},
        );
        final nativeChosen = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'selection.select_filtered',
          input: {
            'selectionHandle': native['selectionHandle'],
            'revision': native['revision'],
            'filter': {'kind': 'element'},
          },
        );
        final export = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'export',
          input: {
            'selectionHandle': nativeChosen['selectionHandle'],
            'revision': nativeChosen['revision'],
            'expectedRevision': native['sourceRevision'],
            'metadata': fixture.source.archive.inspection.manifest.pack
                .toJson(),
            'author': 'Fixture',
            'acknowledgeOrganizationRemoval': true,
          },
        );
        final exported = await waitForJob(
          api,
          fixture.opened.projectHandle,
          export,
        );
        expect(
          (exported['snapshot'] as Map)['state'],
          'succeeded',
          reason: exported.toString(),
        );
        final payload = (exported['result'] as Map)['payloadRef'];
        final chunk = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'read_payload',
          input: {'payloadRef': payload, 'offset': 0, 'length': 128 * 1024},
        );
        expect(chunk['totalBytes'], greaterThan(0));
        final queried = await api.queryTransfer(
          fixture.opened.projectHandle,
          AuthoringQueryRequest(
            resourceKind: 'resourcePackInspection',
            operation: AuthoringQueryOperation.get,
            ids: [result['inspectionHandle'] as String],
          ),
        );
        expect((queried['items'] as List).length, 1);
        final reverted = await waitForJob(
          api,
          fixture.opened.projectHandle,
          await api.transfer(
            fixture.opened.projectHandle,
            verb: 'start_history',
            input: {
              'operation': 'revert',
              'entryId':
                  ((undone['result'] as Map)['receipt'] as Map)['receiptId'],
              'expectedHeadEntryId':
                  ((redone['result'] as Map)['receipt'] as Map)['receiptId'],
              'operationId': 'p09-revert',
              'expectedRevision': (await fixture.loader.load(
                fixture.opened.projectHandle,
              )).revision,
            },
          ),
        );
        expect(
          (reverted['snapshot'] as Map)['state'],
          'succeeded',
          reason: reverted.toString(),
        );
      } finally {
        port.close();
        await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
        await fixture.dispose();
      }
    },
  );
}

Future<Map<String, Object?>> waitForJob(
  LocalResourcePackTransferApi api,
  ProjectHandle project,
  Map<String, Object?> start,
) async {
  final deadline = DateTime.now().add(Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    final state = await api.transfer(
      project,
      verb: 'get',
      input: {'jobId': start['jobId']},
    );
    if (const [
      'succeeded',
      'failed',
      'cancelled',
    ].contains((state['snapshot'] as Map)['state'])) {
      return state;
    }
    await Future<void>.delayed(Duration(milliseconds: 1));
  }
  throw StateError('Job did not finish.');
}

ResourcePackInspection Function(RandomAccessPackageSource) _observer(
  SendPort port,
) => (source) {
  port.send(Isolate.current.hashCode);
  return const ResourcePackInspector().inspectSourceSync(source);
};
