import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/catalog_storage/working_project_catalog.dart';
import 'package:map_authoring/src/history/file_history_store.dart';
import 'package:map_authoring/src/history/content_blob_store.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_authoring/src/support/authoring_fingerprint.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late LocalCharacterContactShadowAuthoring service;
  late CatalogStorageStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('contact_catalog_');
    root = Directory(await root.resolveSymbolicLinks());
    store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store,
        projectId: 'contact_game',
        project: ProjectManifest(
            name: 'Catalog only',
            maps: const [],
            characters: const [
              ProjectCharacterEntry(
                  id: 'hero', name: 'Hero', tilesetId: 'sprites')
            ],
            tilesets: const [
              ProjectTilesetEntry(
                  id: 'sprites', name: 'Sprites', relativePath: 'bad.png')
            ]));
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    service = LocalCharacterContactShadowAuthoring(policy: policy);
  });
  tearDown(() async {
    await service.close();
    await root.delete(recursive: true);
  });

  for (final value in <bool?>[true, false, null]) {
    test('first save after preparation persists $value with compact history',
        () async {
      if (value == null) {
        final first =
            await service.inspect(projectRoot: root.path, characterId: 'hero');
        await service.set(
            projectRoot: root.path,
            expectedRevision: first['revision']! as String,
            characterId: 'hero',
            enabled: true,
            operationId: 'seed');
        await service.close();
        final policy = await WorkspacePolicy.create(
            allowedRootPaths: [root.path],
            fileReader: const LocalProjectFileReader());
        service = LocalCharacterContactShadowAuthoring(policy: policy);
      }
      final descriptor = await File('${root.path}/project.json').readAsBytes();
      final inspected =
          await service.inspect(projectRoot: root.path, characterId: 'hero');
      final result = await service.set(
          projectRoot: root.path,
          expectedRevision: inspected['revision']! as String,
          characterId: 'hero',
          enabled: value,
          operationId: 'first_${value ?? 'inherit'}');
      expect(result.afterValue, value);
      expect(await File('${root.path}/project.json').readAsBytes(), descriptor);
      expect(
          result.afterRevision, 'sha256:${(await store.readHead())!.sha256}');
      expect(result.receipt.diff.entries, hasLength(2));
      final history =
          await FileAuthoringHistoryStore.open(projectRoot: root.path);
      final entry = await history.get(
          projectId: 'contact_game', entryId: result.receipt.receiptId);
      expect(entry!.changes.single.storageKey, 'catalog/HEAD.json');
      final blobs =
          await FileAuthoringContentBlobStore.open(projectRoot: root.path);
      expect((await blobs.get(entry.changes.single.afterBlobId!))!.byteLength,
          lessThan(4096));
      await service.close();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path],
          fileReader: const LocalProjectFileReader());
      service = LocalCharacterContactShadowAuthoring(policy: policy);
      final reopened =
          await service.inspect(projectRoot: root.path, characterId: 'hero');
      expect(reopened['contactShadow'], value);
    });
  }

  test('set rejects an unprepared catalog instead of scanning its index',
      () async {
    final rootRevision = 'sha256:${(await store.readHead())!.sha256}';
    await expectLater(
        service.set(
            projectRoot: root.path,
            expectedRevision: rootRevision,
            characterId: 'hero',
            enabled: true,
            operationId: 'unprepared'),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', contains('catalog.preparation_required'))));
  });

  test('preparation can follow an explicit format change in the same service',
      () async {
    final source = await Directory('${root.path}/format_change').create();
    final project = ProjectManifest(
        name: 'Format change',
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
              id: 'sprites', name: 'Sprites', relativePath: 'bad.png')
        ],
        characters: const [
          ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'sprites')
        ]);
    final file = File('${source.path}/project.json');
    await file.writeAsString(jsonEncode(project.toJson()));
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [source.path],
        fileReader: const LocalProjectFileReader());
    final changing = LocalCharacterContactShadowAuthoring(policy: policy);
    addTearDown(changing.close);
    await changing.prepareCatalog(projectRoot: source.path);
    await changing.inspect(projectRoot: source.path, characterId: 'hero');
    final revision = computeAuthoringBytesFingerprint(await file.readAsBytes(),
        logicalName: 'project.json');
    await WorkingProjectCatalog.create(
        store: await CatalogStorageStore.open(projectRoot: source.path),
        projectId: 'format_change',
        project: project,
        expectedProjectRevision: revision);
    final inspected =
        await changing.inspect(projectRoot: source.path, characterId: 'hero');
    final result = await changing.set(
        projectRoot: source.path,
        expectedRevision: inspected['revision']! as String,
        characterId: 'hero',
        enabled: true,
        operationId: 'after_partition');
    expect(result.afterValue, isTrue);
  });

  test('the first mutation reads no unrelated units or legacy journals',
      () async {
    final large = await Directory('${root.path}/large').create();
    final largeStore = await CatalogStorageStore.open(projectRoot: large.path);
    await WorkingProjectCatalog.create(
        store: largeStore,
        projectId: 'large_game',
        project: ProjectManifest(
            name: 'Large unrelated catalog',
            maps: const [],
            tilesets: const [
              ProjectTilesetEntry(
                  id: 'sprites', name: 'Sprites', relativePath: 'bad.png')
            ],
            characters: [
              const ProjectCharacterEntry(
                  id: 'hero', name: 'Hero', tilesetId: 'sprites'),
              for (var index = 0; index < 160; index++)
                ProjectCharacterEntry(
                    id: 'extra_$index',
                    name: 'Extra $index',
                    tilesetId: 'sprites')
            ]));
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [large.path],
        fileReader: const LocalProjectFileReader());
    final prepared = LocalCharacterContactShadowAuthoring(policy: policy);
    addTearDown(prepared.close);
    final opened =
        await prepared.inspect(projectRoot: large.path, characterId: 'hero');
    final outside = Zone.current;
    final blocked = <String>{};
    var blockedLeaves = 0;
    await for (final entity
        in Directory('${large.path}/catalog/objects').list(recursive: true)) {
      if (entity is! File) continue;
      final raw = jsonDecode(await entity.readAsString());
      if (raw is Map &&
          raw['type'] == 'unit' &&
          (raw['key'] as Map)['id'] != 'hero') {
        blocked.add(entity.path);
      }
      if (raw is Map &&
          raw['type'] == 'leaf' &&
          !(raw['entries'] as List).any((entry) => const ['hero', 'sprites']
              .contains((entry['key'] as Map)['id']))) {
        blocked.add(entity.path);
        blockedLeaves++;
      }
    }
    await File('${large.path}/bad.png').writeAsString('unrelated image');
    blocked.add('${large.path}/bad.png');
    await Directory('${large.path}/.pokemap/authoring').create(recursive: true);
    for (final name in ['history.jsonl', 'idempotency.jsonl', 'audit.jsonl']) {
      final file = File('${large.path}/.pokemap/authoring/$name');
      await file.writeAsString('unrelated historical bytes' * 1000);
      blocked.add(file.path);
    }
    final attempts = <String>[];
    await IOOverrides.runZoned(() async {
      await prepared.set(
          projectRoot: large.path,
          expectedRevision: opened['revision']! as String,
          characterId: 'hero',
          enabled: true,
          operationId: 'forbidden_first');
    }, createFile: (path) {
      final file = outside.run(() => File(path));
      return blocked.contains(file.path)
          ? _UnreadableFile(file, attempts)
          : file;
    });
    expect(blocked.length, greaterThan(3));
    expect(blockedLeaves, greaterThan(0));
    expect(attempts, isEmpty);
  });

  test('concurrent catalog publication preserves the winner', () async {
    final opened =
        await service.inspect(projectRoot: root.path, characterId: 'hero');
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    final other = LocalCharacterContactShadowAuthoring(policy: policy);
    addTearDown(other.close);
    await other.prepareCatalog(projectRoot: root.path);
    await other.set(
        projectRoot: root.path,
        expectedRevision: opened['revision']! as String,
        characterId: 'hero',
        enabled: true,
        operationId: 'winner');
    final head = await store.readHead();
    await expectLater(
        service.set(
            projectRoot: root.path,
            expectedRevision: opened['revision']! as String,
            characterId: 'hero',
            enabled: false,
            operationId: 'loser'),
        throwsA(anything));
    expect(await store.readHead(), head);
  });

  test('a promoted mutation resumes after reopening and replays exactly',
      () async {
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    final crashing = LocalCharacterContactShadowAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    final opened =
        await crashing.inspect(projectRoot: root.path, characterId: 'hero');
    final revision = opened['revision']! as String;
    await expectLater(
        crashing.set(
            projectRoot: root.path,
            expectedRevision: revision,
            characterId: 'hero',
            enabled: true,
            operationId: 'resume_catalog'),
        throwsA(anything));
    await crashing.close();
    await service.prepareCatalog(projectRoot: root.path);
    final recovered = await service.set(
        projectRoot: root.path,
        expectedRevision: revision,
        characterId: 'hero',
        enabled: true,
        operationId: 'resume_catalog');
    final replay = await service.set(
        projectRoot: root.path,
        expectedRevision: revision,
        characterId: 'hero',
        enabled: true,
        operationId: 'resume_catalog');
    expect(recovered.toJson(), replay.toJson());
    expect(
        (await service.inspect(
            projectRoot: root.path, characterId: 'hero'))['contactShadow'],
        isTrue);
    expect(await store.gateway.listJournals(), isEmpty);
  });

  test('canonical undo restores the selected unit after reopening', () async {
    final inspected =
        await service.inspect(projectRoot: root.path, characterId: 'hero');
    final result = await service.set(
        projectRoot: root.path,
        expectedRevision: inspected['revision']! as String,
        characterId: 'hero',
        enabled: true,
        operationId: 'undoable');
    await service.close();
    final editing = await CatalogEditingSession.open(
        store: store, projectId: 'contact_game', actorId: 'local_cli');
    try {
      await editing.undo(
          entryId: result.receipt.receiptId, idempotencyKey: 'undo_contact');
      final unit = await editing.snapshot.lookup(
          CatalogDefinitionKey(CatalogDefinitionKind.character, 'hero'));
      expect((unit!.payload['value'] as Map).containsKey('contactShadow'),
          isFalse);
    } finally {
      await editing.close();
    }
  });

  for (final pending in [false, true]) {
    test(
        'a replaced descriptor blocks ${pending ? 'pending recovery' : 'completed replay'} before writing',
        () async {
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path],
          fileReader: const LocalProjectFileReader());
      final writer = LocalCharacterContactShadowAuthoring(
          policy: policy,
          faultInjector: pending
              ? (context) {
                  if (context.checkpoint ==
                      AuthoringTransactionCheckpoint.afterReservation) {
                    throw const AuthoringTransactionSimulatedCrash();
                  }
                }
              : null);
      addTearDown(writer.close);
      final opened =
          await writer.inspect(projectRoot: root.path, characterId: 'hero');
      final revision = opened['revision']! as String;
      Future<CharacterContactShadowMutation> save() => writer.set(
          projectRoot: root.path,
          expectedRevision: revision,
          characterId: 'hero',
          enabled: true,
          operationId: 'descriptor_guard');
      if (pending) {
        await expectLater(save(), throwsA(anything));
      } else {
        await save();
      }
      final descriptor = File('${root.path}/project.json');
      final raw =
          jsonDecode(await descriptor.readAsString()) as Map<String, dynamic>;
      raw['projectId'] = 'replacement_project';
      await descriptor.writeAsString(jsonEncode(raw));
      final before = await _inventory(root);
      await expectLater(
          save(),
          throwsA(isA<FormatException>().having((error) => error.message,
              'message', contains('document_revision_conflict'))));
      expect(await _inventory(root), before);
    });
  }

  test('recovery rechecks the descriptor under the project writer lock',
      () async {
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    final crashing = LocalCharacterContactShadowAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterReservation) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    final inspected =
        await crashing.inspect(projectRoot: root.path, characterId: 'hero');
    await expectLater(
        crashing.set(
            projectRoot: root.path,
            expectedRevision: inspected['revision']! as String,
            characterId: 'hero',
            enabled: true,
            operationId: 'guarded_resume'),
        throwsA(anything));
    await crashing.close();
    final editing = await CatalogEditingSession.open(
        store: store, projectId: 'contact_game', actorId: 'local_cli');
    addTearDown(editing.close);
    final descriptor = File('${root.path}/project.json');
    final expected = await descriptor.readAsString();
    final head = await store.readHead();
    final entered = Completer<void>();
    final release = Completer<void>();
    final writer = store.gateway.withExclusiveWriteLock(() async {
      entered.complete();
      await release.future;
      await descriptor
          .writeAsString(expected.replaceAll('contact_game', 'replaced_game'));
    });
    await entered.future;
    final recover = editing.reconcile('guarded_resume', precondition: () async {
      if (await descriptor.readAsString() != expected) {
        throw const FormatException('descriptor changed under the writer lock');
      }
    });
    release.complete();
    await writer;
    await expectLater(recover, throwsFormatException);
    expect(await store.readHead(), head);
  });
}

Future<Map<String, String>> _inventory(Directory root) async {
  final result = <String, String>{};
  await for (final entity in root.list(recursive: true)) {
    if (entity is File) {
      result[entity.path.substring(root.path.length)] =
          base64Encode(await entity.readAsBytes());
    }
  }
  return result;
}

final class _UnreadableFile implements File {
  _UnreadableFile(this.delegate, this.attempts);
  final File delegate;
  final List<String> attempts;
  Never deny() {
    attempts.add(path);
    throw StateError('Unrelated file read: $path');
  }

  @override
  String get path => delegate.path;
  @override
  Uri get uri => delegate.uri;
  @override
  bool get isAbsolute => delegate.isAbsolute;
  @override
  File get absolute => delegate.absolute;
  @override
  Directory get parent => delegate.parent;
  @override
  Future<Uint8List> readAsBytes() async => deny();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => deny();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => deny();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      deny();
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileStat> stat() => delegate.stat();
  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
