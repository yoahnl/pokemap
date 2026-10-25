import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/security/audit_log.dart';
import 'package:map_authoring/src/security/audit_record.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_authoring/src/transactions/local_transaction_file_gateway.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late LocalCharacterContactShadowAuthoring service;
  late WorkspacePolicy policy;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('contact-replay-audit-');
    root = Directory(await root.resolveSymbolicLinks());
    await File('${root.path}/project.json').writeAsString(jsonEncode(
        ProjectManifest(
            name: 'Replay',
            maps: const [],
            tilesets: const [],
            characters: const [
          ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'people')
        ]).toJson()));
    policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    service = LocalCharacterContactShadowAuthoring(policy: policy);
  });
  tearDown(() => root.delete(recursive: true));

  test(
      'replay repairs denied audit after durable commit without writing the document again',
      () async {
    final inspection =
        await service.inspect(projectRoot: root.path, characterId: 'hero');
    Future<CharacterContactShadowMutation> save() => service.set(
        projectRoot: root.path,
        expectedRevision: inspection['revision']! as String,
        characterId: 'hero',
        enabled: true,
        operationId: 'replay');
    final outside = Zone.current;
    await expectLater(
        IOOverrides.runZoned(save,
            createFile: (path) =>
                path.contains('/audit-entries/') && path.endsWith('.tmp')
                    ? _DeniedAuditFile(path)
                    : outside.run(() => File(path))),
        throwsA(anything));
    final saved = await File('${root.path}/project.json').readAsBytes();
    final replay = await save();
    expect(await File('${root.path}/project.json').readAsBytes(), saved);
    final log = await FileAuthoringAuditLog.open(projectRoot: root.path);
    final audit = (await log.readAll()).single;
    expect(audit.receiptId, replay.receipt.receiptId);
    expect(audit.details['idempotentReplay'], isTrue);
  });

  test('pending recovery is audited and cleans its committed transaction',
      () async {
    final inspection =
        await service.inspect(projectRoot: root.path, characterId: 'hero');
    final crashed = LocalCharacterContactShadowAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterJournalCommitted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        crashed.set(
            projectRoot: root.path,
            expectedRevision: inspection['revision']! as String,
            characterId: 'hero',
            enabled: true,
            operationId: 'recover'),
        throwsA(anything));
    final recovered = await service.set(
        projectRoot: root.path,
        expectedRevision: inspection['revision']! as String,
        characterId: 'hero',
        enabled: true,
        operationId: 'recover');
    final audit =
        await (await FileAuthoringAuditLog.open(projectRoot: root.path))
            .readAll();
    final recoveredAudit = audit.singleWhere((record) =>
        record.receiptId == recovered.receipt.receiptId &&
        record.decision == AuthoringAuditDecision.succeeded);
    expect(recoveredAudit.details['recovery'], isTrue);
    expect(
        await (await LocalTransactionFileGateway.open(projectRoot: root.path))
            .listJournals(),
        isEmpty);
  });

  for (final corrupted in ['action', 'operation', 'path', 'revision']) {
    test('replay rejects corrupted receipt $corrupted binding', () async {
      final inspection =
          await service.inspect(projectRoot: root.path, characterId: 'hero');
      Future<CharacterContactShadowMutation> save() => service.set(
          projectRoot: root.path,
          expectedRevision: inspection['revision']! as String,
          characterId: 'hero',
          enabled: true,
          operationId: 'replay');
      await save();
      final directory =
          Directory('${root.path}/.pokemap/authoring/idempotency-scopes');
      final file = (await directory
              .list()
              .where((entry) => entry.path.endsWith('.jsonl'))
              .toList())
          .single;
      final events = (await File(file.path).readAsLines())
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final receipt = (events.last['record'] as Map)['receipt'] as Map;
      final diff = ((receipt['diff'] as Map)['entries'] as List).single as Map;
      if (corrupted == 'action') receipt['actionId'] = 'map.save';
      if (corrupted == 'operation') {
        (receipt['extensions'] as Map)['operationId'] = 'other';
      }
      if (corrupted == 'path') diff['path'] = '/characters/other/contactShadow';
      if (corrupted == 'revision') {
        (diff['extensions'] as Map)['documentBeforeRevision'] =
            'sha256:${'0' * 64}';
      }
      await File(file.path)
          .writeAsString('${events.map(jsonEncode).join('\n')}\n');
      final before = await File('${root.path}/project.json').readAsBytes();
      await expectLater(save(), throwsA(isA<FormatException>()));
      expect(await File('${root.path}/project.json').readAsBytes(), before);
    });
  }
}

final class _DeniedAuditFile implements File {
  _DeniedAuditFile(this.path);
  @override
  final String path;
  @override
  Future<File> writeAsString(String contents,
          {FileMode mode = FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) =>
      Future.error(const FileSystemException('Injected audit denial'));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
