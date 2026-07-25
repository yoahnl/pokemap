import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late GameIdentity sourceIdentity;
  late GameIdentity targetIdentity;
  late SaveSlotAddress address;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pokemap-save-migration-');
    sourceIdentity = _identity(saveFormat: 0, gameVersion: '1.0.0');
    targetIdentity = _identity(saveFormat: 1, gameVersion: '1.1.0');
    address = SaveSlotAddress(
      gameId: sourceIdentity.gameId,
      profileId: 'player-1',
      slotId: 'slot-1',
    );
    await _seedSource(root, sourceIdentity);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('migrates through a pre-migration snapshot then promotes atomically',
      () async {
    final store = HubSaveStore(
      supportRoot: root,
      identity: targetIdentity,
    );

    final result = await store.migrate(
      address: address,
      engine: _engine(),
      newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
      updatedAt: DateTime.utc(2026, 7, 25, 11),
    );

    expect(result.envelope.saveFormat, 1);
    expect(result.envelope.gameVersion, '1.1.0');
    expect(result.envelope.state['difficulty'], 'normal');
    expect(await result.snapshot.primaryFile.exists(), isTrue);
    final sourceSnapshot = const SaveEnvelopeCodec().decode(
      await result.snapshot.primaryFile.readAsString(),
      expectedAddress: address,
      acceptedSaveFormats: const <int>{0},
    );
    expect(sourceSnapshot.saveId, '018f255f-2d50-4f4f-8aa2-c893ae06b8c1');
    expect((await store.read(address)).status, SaveSlotReadStatus.valid);
  });

  test('failed migration leaves current bytes and backup untouched', () async {
    final current = File(p.join(_slotPath(root), 'save.json'));
    final before = await current.readAsBytes();
    final store = HubSaveStore(
      supportRoot: root,
      identity: targetIdentity,
    );
    final failing = SaveMigrationEngine(
      migrations: <SaveStateMigration>[
        SaveStateMigration(
          fromFormat: 0,
          toFormat: 1,
          migrate: (_) => throw StateError('bad migration'),
        ),
      ],
    );

    await expectLater(
      () => store.migrate(
        address: address,
        engine: failing,
        newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
        updatedAt: DateTime.utc(2026, 7, 25, 11),
      ),
      throwsA(isA<SaveMigrationException>()),
    );

    expect(await current.readAsBytes(), before);
    expect(
      File(p.join(_slotPath(root), 'save.backup.json')).existsSync(),
      isFalse,
    );
  });

  test('rollback restores the snapshot using the previous game identity',
      () async {
    final targetStore = HubSaveStore(
      supportRoot: root,
      identity: targetIdentity,
    );
    final migrated = await targetStore.migrate(
      address: address,
      engine: _engine(),
      newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
      updatedAt: DateTime.utc(2026, 7, 25, 11),
    );
    final rollbackStore = HubSaveStore(
      supportRoot: root,
      identity: sourceIdentity,
    );

    await rollbackStore.restoreMigrationSnapshot(migrated.snapshot);
    final restored = await rollbackStore.read(address);

    expect(restored.status, SaveSlotReadStatus.valid);
    expect(restored.envelope!.gameVersion, '1.0.0');
    expect(restored.envelope!.saveFormat, 0);
    expect(restored.envelope!.state, <String, Object?>{'mapId': 'start'});
  });

  test('future source format is refused without migration execution', () async {
    final olderStore = HubSaveStore(
      supportRoot: root,
      identity: sourceIdentity,
    );
    final future = const SaveEnvelopeCodec().create(
      identity: targetIdentity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 25, 11),
      status: SaveStatus.active,
      playTimeSeconds: 2,
      state: <String, Object?>{'mapId': 'future'},
    );
    await File(p.join(_slotPath(root), 'save.json')).writeAsString(
      const SaveEnvelopeCodec().encode(future),
      flush: true,
    );

    final read = await olderStore.read(address);

    expect(read.status, SaveSlotReadStatus.incompatible);
    expect(
      read.diagnostics.single.code,
      SaveStorageDiagnosticCode.saveFormatFuture,
    );
  });
}

SaveMigrationEngine _engine() => SaveMigrationEngine(
      migrations: <SaveStateMigration>[
        SaveStateMigration(
          fromFormat: 0,
          toFormat: 1,
          migrate: (state) => <String, Object?>{
            ...state,
            'difficulty': 'normal',
          },
        ),
      ],
    );

GameIdentity _identity({
  required int saveFormat,
  required String gameVersion,
}) =>
    GameIdentity(
      gameId: 'games.example.migration',
      gameVersion: gameVersion,
      projectFormat: ProjectFormat.v2,
      saveFormat: saveFormat,
      compatibilityId: 'campaign-v1',
    );

Future<void> _seedSource(
  Directory root,
  GameIdentity sourceIdentity,
) async {
  final slot = Directory(_slotPath(root));
  await slot.create(recursive: true);
  final source = const SaveEnvelopeCodec().create(
    identity: sourceIdentity,
    profileId: 'player-1',
    slotId: 'slot-1',
    saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
    createdAt: DateTime.utc(2026, 7, 25, 10),
    updatedAt: DateTime.utc(2026, 7, 25, 10),
    status: SaveStatus.active,
    playTimeSeconds: 1,
    state: <String, Object?>{'mapId': 'start'},
  );
  await File(p.join(slot.path, 'save.json')).writeAsString(
    const SaveEnvelopeCodec().encode(source),
    flush: true,
  );
}

String _slotPath(Directory root) => p.join(
      root.path,
      'saves',
      'games.example.migration',
      'player-1',
      'slot-1',
    );
