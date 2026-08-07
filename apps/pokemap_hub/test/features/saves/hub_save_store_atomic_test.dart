import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

import '../../support/dart_subprocess.dart';

void main() {
  late Directory root;
  late GameIdentity identity;
  late SaveSlotAddress address;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pokemap-save-atomic-');
    identity = _identity();
    address = SaveSlotAddress(
      gameId: identity.gameId,
      profileId: 'player-1',
      slotId: 'slot-1',
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('rotates the previous valid current into backup', () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    await store.write(_envelope(identity, marker: 'old', revision: 1));
    await store.write(_envelope(identity, marker: 'new', revision: 2));

    final current = await store.read(address);
    final backup = const SaveEnvelopeCodec().decode(
      await File(p.join(_slotPath(root), 'save.backup.json')).readAsString(),
      expectedAddress: address,
    );

    expect(current.status, SaveSlotReadStatus.valid);
    expect(current.envelope!.state['marker'], 'new');
    expect(backup.state['marker'], 'old');
  });

  test('quarantines corrupt primary and exposes valid backup', () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    await store.write(_envelope(identity, marker: 'old', revision: 1));
    await store.write(_envelope(identity, marker: 'new', revision: 2));
    await File(p.join(_slotPath(root), 'save.json')).writeAsString('{broken');

    final recovered = await store.read(address);

    expect(recovered.status, SaveSlotReadStatus.recoveredFromBackup);
    expect(recovered.envelope!.state['marker'], 'old');
    expect(
      Directory(p.join(_slotPath(root), 'quarantine')).listSync(),
      hasLength(1),
    );
    expect(
      File(p.join(_slotPath(root), 'save.backup.json')).existsSync(),
      isTrue,
      reason: 'backup is not silently promoted without player acknowledgement',
    );
  });

  test('a new write never rotates a corrupt primary over a valid backup',
      () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    await store.write(_envelope(identity, marker: 'old', revision: 1));
    await store.write(_envelope(identity, marker: 'current', revision: 2));
    await File(p.join(_slotPath(root), 'save.json')).writeAsString('{broken');

    await store.write(_envelope(identity, marker: 'new', revision: 3));

    final current = await store.read(address);
    final backup = const SaveEnvelopeCodec().decode(
      await File(p.join(_slotPath(root), 'save.backup.json')).readAsString(),
      expectedAddress: address,
    );
    expect(current.envelope!.state['marker'], 'new');
    expect(backup.state['marker'], 'old');
  });

  test('restores the previous save after every injected write failure',
      () async {
    for (final stage in SaveWriteStage.values) {
      final caseRoot =
          await Directory.systemTemp.createTemp('pokemap-save-fault-');
      addTearDown(() async {
        if (await caseRoot.exists()) await caseRoot.delete(recursive: true);
      });
      final initial = HubSaveStore(supportRoot: caseRoot, identity: identity);
      await initial.write(_envelope(identity, marker: 'old', revision: 1));
      final failing = HubSaveStore(
        supportRoot: caseRoot,
        identity: identity,
        faultHook: (seen) async {
          if (seen == stage) throw StateError('injected $seen');
        },
      );

      await expectLater(
        () => failing.write(_envelope(identity, marker: 'new', revision: 2)),
        throwsA(isA<SaveStorageException>()),
        reason: stage.name,
      );
      final recovered = await initial.read(address);
      expect(recovered.envelope, isNotNull, reason: stage.name);
      expect(
        recovered.envelope!.state['marker'],
        anyOf('old', 'new'),
        reason: 'a complete old or new save must survive ${stage.name}',
      );
    }
  });

  test('serializes concurrent writes for the same slot', () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    await store.write(_envelope(identity, marker: 'initial', revision: 0));

    await Future.wait(<Future<void>>[
      store.write(_envelope(identity, marker: 'one', revision: 1)),
      store.write(_envelope(identity, marker: 'two', revision: 2)),
    ]);

    final current = await store.read(address);
    final backup = const SaveEnvelopeCodec().decode(
      await File(p.join(_slotPath(root), 'save.backup.json')).readAsString(),
      expectedAddress: address,
    );
    expect(current.envelope!.state['marker'], anyOf('one', 'two'));
    expect(backup.state['marker'], anyOf('initial', 'one', 'two'));
    expect(
      current.envelope!.state['marker'],
      isNot(backup.state['marker']),
    );
  });

  for (final stage in SaveWriteStage.values) {
    test('recovers after a process dies at ${stage.name}', () async {
      final store = HubSaveStore(supportRoot: root, identity: identity);
      await store.write(_envelope(identity, marker: 'old', revision: 1));

      final process = await Process.run(
        dartSubprocessExecutable(),
        <String>[
          '--packages=.dart_tool/package_config.json',
          'test/fixtures/atomic_save_crash_writer.dart',
          root.path,
          stage.name,
        ],
        workingDirectory: Directory.current.path,
      );
      expect(
        process.exitCode,
        86,
        reason: '${stage.name}\n${process.stdout}\n${process.stderr}',
      );

      final recovered = await store.read(address);
      expect(recovered.envelope, isNotNull, reason: stage.name);
      expect(
        recovered.envelope!.state['marker'],
        anyOf('old', 'new'),
        reason: stage.name,
      );
    });
  }

  test('keeps a future incompatible save listed in place', () async {
    final futureIdentity = GameIdentity(
      gameId: identity.gameId,
      gameVersion: '2.0.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: 2,
      compatibilityId: identity.compatibilityId,
    );
    final futureEnvelope =
        _envelope(futureIdentity, marker: 'future', revision: 3);
    final slot = Directory(_slotPath(root));
    await slot.create(recursive: true);
    await File(p.join(slot.path, 'save.json')).writeAsString(
      const SaveEnvelopeCodec().encode(futureEnvelope),
      flush: true,
    );
    final store = HubSaveStore(supportRoot: root, identity: identity);

    final result = await store.read(address);

    expect(result.status, SaveSlotReadStatus.incompatible);
    expect(
      result.diagnostics.single.code,
      SaveStorageDiagnosticCode.saveFormatFuture,
    );
    expect(File(p.join(slot.path, 'save.json')).existsSync(), isTrue);
  });
}

String _slotPath(Directory root) => p.join(
      root.path,
      'saves',
      'games.example.atomic',
      'player-1',
      'slot-1',
    );

GameIdentity _identity() => GameIdentity(
      gameId: 'games.example.atomic',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: 1,
      compatibilityId: 'campaign-v1',
    );

SaveEnvelope _envelope(
  GameIdentity identity, {
  required String marker,
  required int revision,
}) =>
    const SaveEnvelopeCodec().create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c$revision',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 25, 10, revision),
      status: SaveStatus.active,
      playTimeSeconds: revision,
      state: <String, Object?>{'marker': marker},
    );
