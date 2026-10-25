import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late LocalCharacterContactShadowAuthoring service;
  late File manifest;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('contact_document_');
    root = Directory(await root.resolveSymbolicLinks());
    manifest = File('${root.path}/project.json');
    final raw = ProjectManifest(name: 'Document only', tilesets: const [
      ProjectTilesetEntry(
          id: 'sprites', name: 'Sprites', relativePath: 'sprites.png')
    ], characters: [
      const ProjectCharacterEntry(
          id: 'hero', name: 'Hero', tilesetId: 'sprites'),
    ], maps: [
      const ProjectMapEntry(
          id: 'unrelated',
          name: 'Unrelated',
          relativePath: 'unreadable-map.json'),
    ]).toJson();
    raw['unknownRoot'] = {
      'retain': [1, 2, 3]
    };
    (raw['characters'] as List).single['unknownCharacter'] = 'retain';
    await manifest.writeAsString(jsonEncode(raw));
    await File('${root.path}/unreadable-map.json')
        .writeAsString('invalid unrelated map');
    await File('${root.path}/sprites.png')
        .writeAsString('unrelated corrupt image');
    final metadata = Directory('${root.path}/.pokemap/authoring');
    await metadata.create(recursive: true);
    await File('${metadata.path}/audit.jsonl')
        .writeAsString('unrelated audit must not be read');
    await File('${metadata.path}/history.jsonl')
        .writeAsString('unrelated historical bytes must not be read');
    await File('${metadata.path}/idempotency.jsonl')
        .writeAsString('unrelated ledger must not be read');
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    service = LocalCharacterContactShadowAuthoring(policy: policy);
  });
  tearDown(() => root.delete(recursive: true));

  test('first and repeated states ignore unrelated maps and legacy journals',
      () async {
    final untouched =
        await File('${root.path}/unreadable-map.json').readAsBytes();
    for (final value in <bool?>[true, false, null]) {
      final inspected =
          await service.inspect(projectRoot: root.path, characterId: 'hero');
      final mutation = await service.set(
          projectRoot: root.path,
          expectedRevision: inspected['revision']! as String,
          characterId: 'hero',
          enabled: value,
          operationId: 'document_${value ?? 'inherit'}');
      expect(mutation.afterValue, value);
      final raw = jsonDecode(await manifest.readAsString()) as Map;
      expect((raw['characters'] as List).single['contactShadow'], value);
      expect((raw['characters'] as List).single.containsKey('contactShadow'),
          value != null);
      expect((raw['characters'] as List).single['unknownCharacter'], 'retain');
      expect(raw['unknownRoot'], {
        'retain': [1, 2, 3]
      });
      expect(mutation.afterRevision,
          narrativeEventBytesFingerprint(await manifest.readAsBytes()));
    }
    expect(await File('${root.path}/unreadable-map.json').readAsBytes(),
        untouched);
    expect(
        await File('${root.path}/.pokemap/authoring/history.jsonl')
            .readAsString(),
        'unrelated historical bytes must not be read');
  });

  test('all three states perform zero reads of unrelated files', () async {
    final outside = Zone.current;
    final blocked = <String>[];
    final attempts = <String>[];
    for (final path in [
      'unreadable-map.json',
      'sprites.png',
      '.pokemap/authoring/history.jsonl',
      '.pokemap/authoring/idempotency.jsonl',
      '.pokemap/authoring/audit.jsonl'
    ]) {
      blocked.add('${root.path}/$path');
    }
    await IOOverrides.runZoned(() async {
      for (final value in <bool?>[true, false, null]) {
        final inspected =
            await service.inspect(projectRoot: root.path, characterId: 'hero');
        await service.set(
            projectRoot: root.path,
            expectedRevision: inspected['revision']! as String,
            characterId: 'hero',
            enabled: value,
            operationId: 'count_${value ?? 'inherit'}');
      }
    }, createFile: (path) {
      final file = outside.run(() => File(path));
      return blocked.contains(file.path)
          ? _UnreadableFile(file, attempts)
          : file;
    });
    expect(attempts, isEmpty);
  });

  test('pending promoted mutation resumes with the same operation identity',
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
    final inspected =
        await service.inspect(projectRoot: root.path, characterId: 'hero');
    final revision = inspected['revision']! as String;
    await expectLater(
        crashing.set(
            projectRoot: root.path,
            expectedRevision: revision,
            characterId: 'hero',
            enabled: true,
            operationId: 'document_resume'),
        throwsA(anything));
    final recovered = await service.set(
        projectRoot: root.path,
        expectedRevision: revision,
        characterId: 'hero',
        enabled: true,
        operationId: 'document_resume');
    expect(recovered.afterValue, isTrue);
    expect(
        (await service.inspect(
            projectRoot: root.path, characterId: 'hero'))['contactShadow'],
        isTrue);
  });

  test('a swapped project root cannot write through a symlink', () async {
    final outside = await Directory.systemTemp.createTemp('contact_outside_');
    addTearDown(() => outside.delete(recursive: true));
    final outsideManifest = File('${outside.path}/project.json');
    final original = await manifest.readAsBytes();
    await outsideManifest.writeAsBytes(original);
    final moved = '${root.path}-moved';
    try {
      await expectLater(
          service.set(
              projectRoot: root.path,
              expectedRevision: narrativeEventBytesFingerprint(original),
              characterId: 'hero',
              enabled: true,
              operationId: 'swap_root',
              precondition: () async {
                await root.rename(moved);
                await Link(root.path).create(outside.path);
              }),
          throwsA(anything));
      expect(await outsideManifest.readAsBytes(), original);
      expect(
          await outside
              .list()
              .map((entity) => entity.uri.pathSegments.last)
              .toList(),
          ['project.json']);
    } finally {
      if (await FileSystemEntity.type(root.path, followLinks: false) ==
          FileSystemEntityType.link) {
        await Link(root.path).delete();
      }
      if (await Directory(moved).exists()) {
        await Directory(moved).rename(root.path);
      }
    }
  });

  test('future document version is rejected without writing it', () async {
    final raw =
        jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
    raw['version'] = 'v999';
    await manifest.writeAsString(jsonEncode(raw));
    final before = await manifest.readAsBytes();
    await expectLater(
        service.set(
            projectRoot: root.path,
            expectedRevision: narrativeEventBytesFingerprint(before),
            characterId: 'hero',
            enabled: true,
            operationId: 'future'),
        throwsA(isA<FormatException>()));
    expect(await manifest.readAsBytes(), before);
  });

  test('concurrent write is preserved inside the transaction precondition',
      () async {
    final inspected =
        await service.inspect(projectRoot: root.path, characterId: 'hero');
    late List<int> external;
    await expectLater(
        service.set(
            projectRoot: root.path,
            expectedRevision: inspected['revision']! as String,
            characterId: 'hero',
            enabled: true,
            operationId: 'document_concurrent',
            precondition: () async {
              final raw = jsonDecode(await manifest.readAsString())
                  as Map<String, dynamic>;
              raw['name'] = 'Concurrent';
              external = utf8.encode(jsonEncode(raw));
              await manifest.writeAsBytes(external, flush: true);
            }),
        throwsA(anything));
    expect(await manifest.readAsBytes(), external);
  });

  test('same operation is replayed without changing the document again',
      () async {
    final inspected =
        await service.inspect(projectRoot: root.path, characterId: 'hero');
    final first = await service.set(
        projectRoot: root.path,
        expectedRevision: inspected['revision']! as String,
        characterId: 'hero',
        enabled: true,
        operationId: 'document_replay');
    final replay = await service.set(
        projectRoot: root.path,
        expectedRevision: inspected['revision']! as String,
        characterId: 'hero',
        enabled: true,
        operationId: 'document_replay');
    expect(replay.receipt.receiptId, first.receipt.receiptId);
    expect(replay.afterRevision, first.afterRevision);
    await expectLater(
        service.set(
            projectRoot: root.path,
            expectedRevision: inspected['revision']! as String,
            characterId: 'hero',
            enabled: false,
            operationId: 'document_replay'),
        throwsA(anything));
  });
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
