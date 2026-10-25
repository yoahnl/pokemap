import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_editing_session.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart';
import 'package:map_authoring/src/history/file_history_store.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/transactions/local_transaction_file_gateway.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final unrelated in [0, 900]) {
    test('cold admission stays local with $unrelated unrelated units',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('local-admission-');
      addTearDown(() => directory.delete(recursive: true));
      final published =
          await CatalogStorageStore.open(projectRoot: directory.path);
      final build = CatalogStorageBuilder().build([
        _unit('selected', 'before'),
        for (var i = 0; i < unrelated; i++) _unit('unrelated-$i', 'untouched'),
      ]);
      await published.publish(build, expectedRootRevision: null);
      final unrelatedUnits = {
        for (final object in build.objects.entries)
          if ((jsonDecode(utf8.decode(object.value)) as Map)['type'] ==
                  'unit' &&
              (jsonDecode(utf8.decode(object.value)) as Map)['key']['id'] !=
                  'selected')
            'catalog/objects/${object.key}.json',
      };
      final reader = _CountingReader();
      Future<CatalogEditingSession> open() async => CatalogEditingSession.open(
          store: CatalogStorageStore(
              projectRoot: directory.path,
              reader: reader,
              gateway: await LocalTransactionFileGateway.open(
                  projectRoot: directory.path)),
          projectId: 'game',
          actorId: 'editor',
          incrementalHistory: true);
      var session = await open();
      try {
        expect(
            reader.paths.where((path) => path.startsWith('catalog/objects/')),
            hasLength(2));
        for (var edit = 0; edit < 2; edit++) {
          reader.paths.clear();
          final plan = await session.planPatch(
              upserts: [_unit('selected', 'after-$edit')],
              idempotencyKey: 'edit-$edit');
          await session.apply(plan);
          expect(reader.paths.where(unrelatedUnits.contains), isEmpty);
          expect(
              reader.paths
                  .where((path) => path.startsWith('catalog/objects/'))
                  .length,
              lessThanOrEqualTo(18));
          print(
              'local-catalog unrelated=$unrelated edit=$edit objectReads=${reader.paths.where((path) => path.startsWith('catalog/objects/')).length} unrelatedUnitReads=0');
        }
        await session.close();
        reader.paths.clear();
        session = await open();
        expect(
            reader.paths.where((path) => path.startsWith('catalog/objects/')),
            hasLength(1));
        expect(
            (await session.snapshot.lookup(_key('selected')))!.payload['name'],
            'after-1');
      } finally {
        await session.close();
      }
    });
  }
  test('explicit metadata preparation is an undoable canonical transaction',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('metadata-preparation-');
    addTearDown(() => directory.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: directory.path);
    await store.publish(
        CatalogStorageBuilder().build([_unit('selected', 'before')]),
        expectedRootRevision: null);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path,
        incrementalWrites: true,
        onFullRead: () => throw StateError('global history read'));
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'editor',
        incrementalHistory: true,
        history: history);
    try {
      final before = session.snapshot.root;
      await session.prepareMetadataDocuments();
      final prepared = session.snapshot.root;
      final receipt =
          (await history.latestLocalEntry(projectId: 'game'))!.receipt;
      expect(prepared, isNot(before));
      await session.prepareMetadataDocuments();
      expect(session.snapshot.root, prepared);
      await session.undo(
          entryId: receipt.receiptId, idempotencyKey: 'undo-preparation');
      expect(session.snapshot.root, before);
      expect(
          await session.snapshot
              .lookup(CatalogMetadataDocuments.fieldKey('facts')),
          isNull);
      await session.redo(
          entryId: receipt.receiptId, idempotencyKey: 'redo-preparation');
      expect(session.snapshot.root, prepared);
    } finally {
      await session.close();
    }
  });

  test(
      'a project cannot forge local admission and explicit preparation preserves its bytes',
      () async {
    final parent = await Directory.systemTemp.createTemp('trusted-admission-');
    addTearDown(() => parent.delete(recursive: true));
    final canonical = await parent.resolveSymbolicLinks();
    final project = await Directory('$canonical/project').create();
    final firstCache = Directory('$canonical/first-authority');
    final freshCache = Directory('$canonical/fresh-authority');
    final store = await CatalogStorageStore.open(
        projectRoot: project.path, trustedAdmissionDirectory: firstCache);
    final build = CatalogStorageBuilder().build([_unit('selected', 'before')]);
    await store.publish(build, expectedRootRevision: null);
    final head = File('${project.path}/catalog/HEAD.json');
    final before = await head.readAsBytes();
    final forged =
        File('${project.path}/catalog/admissions/${build.root.sha256}.json');
    await forged.parent.create();
    await forged.writeAsString(
        jsonEncode({'root': build.root.toJson(), 'storedBytes': 1}));
    final imported = await CatalogStorageStore.open(
        projectRoot: project.path, trustedAdmissionDirectory: freshCache);
    await expectLater(
        CatalogEditingSession.open(
            store: imported, projectId: 'game', actorId: 'editor'),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.preparation_required')));
    expect(await head.readAsBytes(), before);
    await imported.prepareLocalEditing();
    final session = await CatalogEditingSession.open(
        store: imported, projectId: 'game', actorId: 'editor');
    await session.close();
    expect(await head.readAsBytes(), before);
  });

  test(
      'explicit preparation admits retained generations after a machine change',
      () async {
    final parent =
        await Directory.systemTemp.createTemp('retained-admissions-');
    addTearDown(() => parent.delete(recursive: true));
    final canonical = await parent.resolveSymbolicLinks();
    final project = await Directory('$canonical/project').create();
    final originalStore = await CatalogStorageStore.open(
        projectRoot: project.path,
        trustedAdmissionDirectory: Directory('$canonical/first-authority'));
    await originalStore.publish(
        CatalogStorageBuilder().build([
          _unit('selected', 'before'),
          ...CatalogMetadataDocuments.initialize([_unit('selected', 'before')])
        ]),
        expectedRootRevision: null);
    var session = await CatalogEditingSession.open(
        store: originalStore,
        projectId: 'game',
        actorId: 'editor',
        incrementalHistory: true);
    await session.prepareMetadataDocuments();
    final receipt = await session.apply(await session.planPatch(
        upserts: [_unit('selected', 'after')], idempotencyKey: 'change'));
    await session.close();
    final newStore = await CatalogStorageStore.open(
        projectRoot: project.path,
        trustedAdmissionDirectory: Directory('$canonical/new-authority'));
    expect(await newStore.prepareLocalEditing(), isTrue);
    var fullReads = 0;
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
        incrementalWrites: true,
        onFullRead: () => fullReads++);
    session = await CatalogEditingSession.open(
        store: newStore,
        projectId: 'game',
        actorId: 'editor',
        incrementalHistory: true,
        history: history);
    try {
      await newStore.gateway.withExclusiveWriteLock(() =>
          history.prepareLocalHistory(
              force: true,
              prepareEntry: session.prepareRetainedGenerationAdmissions));
      expect(fullReads, 1);
      fullReads = 0;
      await session.undo(
          entryId: receipt.receiptId, idempotencyKey: 'undo-on-new-machine');
      expect((await session.snapshot.lookup(_key('selected')))!.payload['name'],
          'before');
      await session.redo(
          entryId: receipt.receiptId, idempotencyKey: 'redo-on-new-machine');
      expect((await session.snapshot.lookup(_key('selected')))!.payload['name'],
          'after');
      await newStore.requireMetadataIndexAdmission(session.snapshot);
      expect(fullReads, 0);
    } finally {
      await session.close();
    }
  });

  test('structural admission cannot bless forged document index markers',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('forged-metadata-index-');
    addTearDown(() => directory.delete(recursive: true));
    final key = CatalogMetadataDocuments.definitionKey('facts', 0);
    final definition = CatalogDefinitionUnit(key: key, payload: {
      'section': r'$projectDefinition',
      'id': key.id,
      'position': 0,
      'value': {
        'field': 'facts',
        'definition': {'id': 'fact-a', 'name': 'Fact A'}
      },
    });
    final initialized = CatalogMetadataDocuments.initialize([definition]);
    final forged = [
      definition,
      for (final unit in initialized)
        if (unit.key != CatalogMetadataDocuments.documentKey('facts', 'fact-a'))
          if (unit.key == CatalogMetadataDocuments.fieldKey('facts'))
            CatalogDefinitionUnit(
                key: unit.key, payload: {...unit.payload, 'count': 0})
          else
            unit,
    ];
    final store = await CatalogStorageStore.open(projectRoot: directory.path);
    await store.publish(CatalogStorageBuilder().build(forged),
        expectedRootRevision: null);
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'editor',
        incrementalHistory: true);
    try {
      await expectLater(
          store.requireMetadataIndexAdmission(session.snapshot),
          throwsA(isA<CatalogStorageException>().having(
              (error) => error.code, 'code', 'catalog.preparation_required')));
      await session.prepareMetadataDocuments();
      await store.requireMetadataIndexAdmission(session.snapshot);
      expect(
          (await session.snapshot
                  .lookup(CatalogMetadataDocuments.fieldKey('facts')))!
              .payload['count'],
          1);
      expect(
          await session.snapshot
              .lookup(CatalogMetadataDocuments.documentKey('facts', 'fact-a')),
          isNotNull);
    } finally {
      await session.close();
    }
  });

  test('trusted admission cannot live inside project data', () async {
    final parent = await Directory.systemTemp.createTemp('unsafe-admission-');
    addTearDown(() => parent.delete(recursive: true));
    final canonical = await parent.resolveSymbolicLinks();
    final store = await CatalogStorageStore.open(
        projectRoot: canonical,
        trustedAdmissionDirectory: Directory('$canonical/admissions'));
    await expectLater(
        store.publish(
            CatalogStorageBuilder().build([_unit('selected', 'before')]),
            expectedRootRevision: null),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.admission_path_unsafe')));
    expect(await store.readHead(), isNull);
  });

  test('cached admission still verifies every touched immutable index object',
      () async {
    final parent = await Directory.systemTemp.createTemp('corrupt-admission-');
    addTearDown(() => parent.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: parent.path);
    final build = CatalogStorageBuilder().build([_unit('selected', 'before')]);
    await store.publish(build, expectedRootRevision: null);
    final leaf = build.objects.entries.singleWhere((entry) =>
        (jsonDecode(utf8.decode(entry.value)) as Map)['type'] == 'leaf');
    final session = await CatalogEditingSession.open(
        store: store, projectId: 'game', actorId: 'editor');
    try {
      await File('${parent.path}/catalog/objects/${leaf.key}.json')
          .writeAsString('{}');
      await expectLater(
          session.planPatch(
              upserts: [_unit('selected', 'after')], idempotencyKey: 'corrupt'),
          throwsA(anything));
      expect(await store.readHead(), build.root);
    } finally {
      await session.close();
    }
  });
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
      throw StateError('Unbounded reads are forbidden');
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
