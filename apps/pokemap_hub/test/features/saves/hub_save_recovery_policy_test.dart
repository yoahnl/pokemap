import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late GameIdentity identity;
  late SaveSlotAddress address;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pokemap-save-recovery-');
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

  test('a tampered checksum offers backup restoration, never deletion',
      () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    await store.write(_envelope(identity, marker: 'old', revision: 1));
    await store.write(_envelope(identity, marker: 'new', revision: 2));
    await _tamperChecksum(File(p.join(_slotPath(root), 'save.json')));

    final read = await store.read(address);

    expect(read.status, SaveSlotReadStatus.recoveredFromBackup);
    expect(read.envelope!.state['marker'], 'old');
    expect(
      read.diagnostics.map((d) => d.code),
      containsAll(<SaveStorageDiagnosticCode>[
        SaveStorageDiagnosticCode.primaryCorrupt,
        SaveStorageDiagnosticCode.backupUsed,
      ]),
    );
    for (final diagnostic in read.diagnostics) {
      expect(
        diagnostic.recommendedActions,
        contains(SaveRecoveryAction.restoreBackup),
      );
      expect(
        diagnostic.recommendedActions,
        isNot(contains(SaveRecoveryAction.deleteSave)),
        reason: 'a recoverable save must never be presented as disposable',
      );
    }
  });

  test('a corrupt save without any backup offers retry then deletion',
      () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    await store.write(_envelope(identity, marker: 'only', revision: 1));
    await _tamperChecksum(File(p.join(_slotPath(root), 'save.json')));

    final read = await store.read(address);

    expect(read.status, SaveSlotReadStatus.corrupt);
    expect(read.envelope, isNull);
    expect(
      read.diagnostics.single.code,
      SaveStorageDiagnosticCode.primaryCorrupt,
    );
    expect(
      read.diagnostics.single.recommendedActions,
      <SaveRecoveryAction>[
        SaveRecoveryAction.retry,
        SaveRecoveryAction.deleteSave,
        SaveRecoveryAction.returnToTitle,
      ],
    );
  });

  test('a save owned by another game is refused and never deletable from here',
      () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    final foreign = _envelope(
      _identity(gameId: 'games.example.other'),
      marker: 'private-to-other',
      revision: 1,
    );
    final target = File(p.join(_slotPath(root), 'save.json'));
    await target.parent.create(recursive: true);
    await target.writeAsString(
      const SaveEnvelopeCodec().encode(foreign),
      flush: true,
    );

    final read = await store.read(address);

    expect(read.status, SaveSlotReadStatus.incompatible);
    expect(read.envelope, isNull);
    expect(
      read.diagnostics.single.code,
      SaveStorageDiagnosticCode.saveGameMismatch,
    );
    expect(
      read.diagnostics.single.recommendedActions,
      <SaveRecoveryAction>[SaveRecoveryAction.returnToTitle],
    );
    expect(await target.exists(), isTrue);
  });

  test('a corrupt primary with an unusable backup never offers restoration',
      () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    await store.write(_envelope(identity, marker: 'old', revision: 1));
    await store.write(_envelope(identity, marker: 'new', revision: 2));
    await _tamperChecksum(File(p.join(_slotPath(root), 'save.json')));
    final newerGame = HubSaveStore(
      supportRoot: root,
      identity: _identity(saveFormat: 2),
    );

    final read = await newerGame.read(address);

    expect(read.status, SaveSlotReadStatus.incompatible);
    final corrupt = read.diagnostics.firstWhere(
      (d) => d.code == SaveStorageDiagnosticCode.primaryCorrupt,
    );
    expect(
      corrupt.recommendedActions,
      isNot(contains(SaveRecoveryAction.restoreBackup)),
      reason: 'the surviving backup cannot be loaded by this build',
    );
  });

  test('a missing migration chain reports detected and expected formats',
      () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    await store.write(_envelope(identity, marker: 'legacy', revision: 1));
    final newerGame = HubSaveStore(
      supportRoot: root,
      identity: _identity(saveFormat: 2),
    );

    final read = await newerGame.read(address);

    final diagnostic = read.diagnostics.single;
    expect(read.status, SaveSlotReadStatus.incompatible);
    expect(diagnostic.code, SaveStorageDiagnosticCode.saveMigrationUnavailable);
    expect(diagnostic.detectedSaveFormat, 1);
    expect(diagnostic.expectedSaveFormat, 2);
    expect(
      diagnostic.recommendedActions,
      <SaveRecoveryAction>[SaveRecoveryAction.returnToTitle],
    );
  });

  test('an available migration chain offers migration before returning to title',
      () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    await store.write(_envelope(identity, marker: 'legacy', revision: 1));
    final newerGame = HubSaveStore(
      supportRoot: root,
      identity: _identity(saveFormat: 2),
    );

    final read = await newerGame.read(address, migrationChainAvailable: true);

    final diagnostic = read.diagnostics.single;
    expect(read.status, SaveSlotReadStatus.migrationRequired);
    expect(diagnostic.code, SaveStorageDiagnosticCode.saveMigrationRequired);
    expect(diagnostic.detectedSaveFormat, 1);
    expect(diagnostic.expectedSaveFormat, 2);
    expect(
      diagnostic.recommendedActions,
      <SaveRecoveryAction>[
        SaveRecoveryAction.migrate,
        SaveRecoveryAction.returnToTitle,
      ],
    );
  });

  test('every diagnostic stays player-safe and actionable', () async {
    final store = HubSaveStore(supportRoot: root, identity: identity);
    final reads = <SaveSlotRead>[await store.read(address)];
    await store.write(_envelope(identity, marker: 'only', revision: 1));
    await _tamperChecksum(File(p.join(_slotPath(root), 'save.json')));
    reads.add(await store.read(address));
    await store.write(_envelope(identity, marker: 'fresh', revision: 2));
    reads.add(
      await HubSaveStore(
        supportRoot: root,
        identity: _identity(saveFormat: 2),
      ).read(address),
    );

    final diagnostics = reads.expand((read) => read.diagnostics).toList();
    expect(diagnostics, isNotEmpty);
    for (final diagnostic in diagnostics) {
      expect(
        diagnostic.recommendedActions,
        isNotEmpty,
        reason: '${diagnostic.code} leaves the player with no way forward',
      );
      expect(
        diagnostic.expectedSaveFormat,
        isNotNull,
        reason: '${diagnostic.code} hides the format this build expects',
      );
      expect(diagnostic.message, isNot(contains(root.path)));
      expect(diagnostic.message, isNot(contains('Exception')));
      expect(diagnostic.message, isNot(contains('FormatException')));
      expect(diagnostic.message, isNot(contains('checksum')));
      expect(diagnostic.message, isNot(contains('.json')));
    }
  });
}

Future<void> _tamperChecksum(File file) async {
  final decoded = jsonDecode(await file.readAsString()) as Map<String, Object?>;
  final checksum = decoded['checksum']! as Map<String, Object?>;
  checksum['value'] =
      '0000000000000000000000000000000000000000000000000000000000000000';
  await file.writeAsString(jsonEncode(decoded), flush: true);
}

String _slotPath(Directory root) => p.join(
      root.path,
      'saves',
      'games.example.recovery',
      'player-1',
      'slot-1',
    );

GameIdentity _identity({
  String gameId = 'games.example.recovery',
  int saveFormat = 1,
}) =>
    GameIdentity(
      gameId: gameId,
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: saveFormat,
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
