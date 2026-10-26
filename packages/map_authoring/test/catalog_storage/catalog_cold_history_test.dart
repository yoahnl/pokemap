import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_editing_session.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/history/file_history_store.dart';
import 'package:map_authoring/src/history/authoring_history.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart';
import 'package:map_authoring/src/transactions/local_transaction_file_gateway.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('undo context optionally guards the durable history head', () {
    final guarded = AuthoringHistoryContext(
        kind: AuthoringHistoryKind.undo,
        targetEntryId: 'origin',
        expectedHeadEntryId: 'head');
    expect(
        AuthoringHistoryContext.fromExtensions({'history': guarded.toJson()})
            .expectedHeadEntryId,
        'head');
    expect(
        AuthoringHistoryContext(
                kind: AuthoringHistoryKind.undo, targetEntryId: 'origin')
            .expectedHeadEntryId,
        isNull);
    expect(() => AuthoringHistoryContext(expectedHeadEntryId: 'head'),
        throwsArgumentError);
    expect(
        () => AuthoringHistoryContext(
            kind: AuthoringHistoryKind.redo, targetEntryId: 'origin'),
        throwsArgumentError);
    expect(
        () => AuthoringHistoryContext(
            kind: AuthoringHistoryKind.revert, targetEntryId: 'origin'),
        throwsArgumentError);
  });

  test('oversized operation is rejected before publishing catalog objects',
      () async {
    final task = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-project-lifecycle/history-admission-tests');
    await task.create(recursive: true);
    final parent = await task.createTemp('budget-');
    addTearDown(() => parent.delete(recursive: true));
    final project = await Directory('${parent.path}/project').create();
    final store = await CatalogStorageStore.open(
        projectRoot: project.path,
        trustedAdmissionDirectory: Directory('${parent.path}/admissions'));
    await store.publish(
        CatalogStorageBuilder().build([_unit('selected', 'initial')]),
        expectedRootRevision: null);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    await history.expireEntries(
        projectId: 'game', entryFingerprints: {}, maxBytes: 4000);
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'editor',
        history: history,
        incrementalHistory: true);
    try {
      final head = await store.readHead();
      final objectNames = await Directory('${project.path}/catalog/objects')
          .list()
          .map((item) => item.path)
          .toList();
      await expectLater(
          session.planPatch(upserts: [
            CatalogDefinitionUnit(
                key: _key('selected'),
                payload: {'name': 'large', 'data': 'x' * 6000})
          ], idempotencyKey: 'oversized'),
          throwsA(isA<AuthoringHistoryException>().having((error) => error.code,
              'code', 'history.operation_exceeds_budget')));
      expect(await store.readHead(), head);
      expect(
          await Directory('${project.path}/catalog/objects')
              .list()
              .map((item) => item.path)
              .toList(),
          unorderedEquals(objectNames));
      expect(await store.gateway.listJournals(), isEmpty);
      expect((await history.localWindow('game'))!.entryIds, isEmpty);
    } finally {
      await session.close();
    }
  });

  test('bounded logical history restores two redos across reopening', () async {
    final task = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-project-lifecycle/history-admission-tests');
    await task.create(recursive: true);
    final parent = await task.createTemp('cursor-');
    addTearDown(() => parent.delete(recursive: true));
    final project = await Directory('${parent.path}/project').create();
    final store = await CatalogStorageStore.open(
        projectRoot: project.path,
        trustedAdmissionDirectory: Directory('${parent.path}/admissions'));
    await store.publish(
        CatalogStorageBuilder().build([_unit('selected', 'initial')]),
        expectedRootRevision: null);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    Future<CatalogEditingSession> open() => CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'editor',
        history: history,
        incrementalHistory: true);
    var session = await open();
    try {
      final first = (await session.apply(await session.planPatch(
              upserts: [_unit('selected', 'one')], idempotencyKey: 'one')))
          .receiptId;
      final second = (await session.apply(await session.planPatch(
              upserts: [_unit('selected', 'two')], idempotencyKey: 'two')))
          .receiptId;
      await history.expireEntries(projectId: 'game', entryFingerprints: {});
      await session.undo(entryId: second, idempotencyKey: 'undo-second');
      await session.close();
      session = await open();
      await session.undo(entryId: first, idempotencyKey: 'undo-first');
      expect((await session.snapshot.lookup(_key('selected')))!.payload['name'],
          'initial');
      await session.close();
      session = await open();
      await session.redo(entryId: first, idempotencyKey: 'redo-first');
      await session.close();
      session = await open();
      await session.redo(entryId: second, idempotencyKey: 'redo-second');
      expect((await session.snapshot.lookup(_key('selected')))!.payload['name'],
          'two');
      expect((await history.localWindow('game'))!.entryIds, [first, second]);
      expect((await history.localWindow('game'))!.cursor, 2);
    } finally {
      await session.close();
    }
  });

  for (final unrelated in [0, 900]) {
    test('cold property undo is incremental with $unrelated unrelated units',
        () async {
      final task = Directory(
          '/Users/karim/Library/Caches/AveluneQA/studio-project-lifecycle/history-admission-tests');
      await task.create(recursive: true);
      final parent = await task.createTemp('fixture-');
      addTearDown(() => parent.delete(recursive: true));
      final project = await Directory('${parent.path}/project').create();
      final original = await CatalogStorageStore.open(
          projectRoot: project.path,
          trustedAdmissionDirectory:
              Directory('${parent.path}/original-admissions'));
      final units = [
        _unit('selected', 'before'),
        for (var index = 0; index < unrelated; index++)
          _unit('unrelated-$index', 'untouched')
      ];
      final built = CatalogStorageBuilder()
          .build([...units, ...CatalogMetadataDocuments.initialize(units)]);
      await original.publish(built, expectedRootRevision: null);
      var session = await CatalogEditingSession.open(
          store: original,
          projectId: 'game',
          actorId: 'editor',
          incrementalHistory: true);
      String entryId;
      try {
        await session.prepareMetadataDocuments();
        entryId = (await session.apply(await session.planPatch(
                upserts: [_unit('selected', 'after')],
                idempotencyKey: 'change')))
            .receiptId;
      } finally {
        await session.close();
      }
      final counter = _CountingReader();
      final fresh = CatalogStorageStore(
          projectRoot: project.path,
          reader: counter,
          gateway:
              await LocalTransactionFileGateway.open(projectRoot: project.path),
          trustedAdmissionDirectory:
              Directory('${parent.path}/fresh-admissions'));
      await fresh.prepareLocalEditing();
      final history = await FileAuthoringHistoryStore.open(
          projectRoot: project.path,
          incrementalWrites: true,
          onFullRead: () => throw StateError('history replay'));
      session = await CatalogEditingSession.open(
          store: fresh,
          projectId: 'game',
          actorId: 'editor',
          history: history,
          incrementalHistory: true);
      try {
        await session.prepareMetadataDocuments();
        counter.paths.clear();
        final untouched = {
          for (final item in built.objects.entries)
            if ((jsonDecode(utf8.decode(item.value)) as Map)['type'] ==
                    'unit' &&
                ((jsonDecode(utf8.decode(item.value)) as Map)['key']['id']
                        as String)
                    .startsWith('unrelated-'))
              'catalog/objects/${item.key}.json'
        };
        await session.undo(entryId: entryId, idempotencyKey: 'cold-undo');
        expect(counter.paths.where(untouched.contains), isEmpty);
        expect(
            counter.paths
                .where((path) => path.startsWith('catalog/objects/'))
                .length,
            lessThanOrEqualTo(24));
        expect(
            (await session.snapshot.lookup(_key('selected')))!.payload['name'],
            'before');
        await fresh.requireMetadataIndexAdmission(session.snapshot);
        await session.close();
        session = await CatalogEditingSession.open(
            store: fresh,
            projectId: 'game',
            actorId: 'editor',
            history: history,
            incrementalHistory: true);
        await session.redo(entryId: entryId, idempotencyKey: 'cold-redo');
        expect(
            (await session.snapshot.lookup(_key('selected')))!.payload['name'],
            'after');
        await fresh.requireMetadataIndexAdmission(session.snapshot);
      } finally {
        await session.close();
      }
    });
  }
}

CatalogDefinitionKey _key(String id) =>
    CatalogDefinitionKey(CatalogDefinitionKind.tileset, id);
CatalogDefinitionUnit _unit(String id, String name) =>
    CatalogDefinitionUnit(key: _key(id), payload: {'name': name});

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
  @override
  Future<List<int>> readBytes(
          {required String projectRoot, required String relativePath}) =>
      throw StateError('unbounded reads');
  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}
