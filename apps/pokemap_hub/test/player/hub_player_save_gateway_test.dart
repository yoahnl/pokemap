import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/src/player/hub_player_save_gateway.dart';
import 'package:pokemap_hub/src/saves/hub_save_store.dart';
import 'package:pokemap_hub/src/saves/save_storage_diagnostic.dart';

void main() {
  late Directory root;
  late GameIdentity identity;
  late HubSaveStore store;
  late HubPlayerSaveGateway gateway;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-save-gateway-');
    identity = GameIdentity(
      gameId: 'org.example.adventure',
      gameVersion: '1.2.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: 1,
      compatibilityId: 'story-v1',
    );
    store = HubSaveStore(supportRoot: root, identity: identity);
    gateway = HubPlayerSaveGateway(store: store);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('returns scoped summaries and opaque handles for the exact slot',
      () async {
    final envelope = _envelope(identity);
    await store.write(envelope);

    final latest = await gateway.readLatestSummary();
    final exact = await gateway.readSummary(envelope.address);
    final handle = await gateway.openReadHandle(envelope.address);

    expect(gateway.identity, identity);
    expect(latest?.address, envelope.address);
    expect(exact?.address, envelope.address);
    expect(exact?.canContinue, isTrue);
    expect(exact?.playTimeSeconds, 120);
    expect(handle, isNotNull);
    expect(handle, isNot(contains(identity.gameId)));
    expect(handle, isNot(contains(envelope.profileId)));
    expect(handle, isNot(contains(envelope.slotId)));
  });

  test('refuses another game and does not leak another profile or slot',
      () async {
    final envelope = _envelope(identity);
    await store.write(envelope);

    await expectLater(
      gateway.readSummary(
        SaveSlotAddress(
          gameId: 'org.example.other',
          profileId: 'player-1',
          slotId: 'slot-1',
        ),
      ),
      throwsA(
        isA<SaveStorageException>().having(
          (error) => error.code,
          'code',
          SaveStorageErrorCode.outOfScope,
        ),
      ),
    );
    expect(
      await gateway.openReadHandle(
        SaveSlotAddress(
          gameId: identity.gameId,
          profileId: 'player-2',
          slotId: 'slot-1',
        ),
      ),
      isNull,
    );
    expect(
      await gateway.openReadHandle(
        SaveSlotAddress(
          gameId: identity.gameId,
          profileId: 'player-1',
          slotId: 'slot-2',
        ),
      ),
      isNull,
    );
  });

  test('commits runtime checkpoints through the atomic Hub store', () async {
    final descriptor = _descriptor(identity);
    final checkpoint = GameSessionCheckpoint(
      saveId: '550e8400-e29b-41d4-a716-446655440001',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 25, 11),
      playTimeSeconds: 180,
      state: const <String, Object?>{'currentMapId': 'port'},
    );

    await gateway.commit(
      GameSessionCheckpointCommit(
        descriptor: descriptor.publicContext,
        checkpoint: checkpoint,
        status: SaveStatus.active,
      ),
    );

    final stored = await store.read(
      SaveSlotAddress(
        gameId: identity.gameId,
        profileId: descriptor.profileId,
        slotId: descriptor.slotId,
      ),
    );
    expect(stored.envelope?.saveId, checkpoint.saveId);
    expect(stored.envelope?.state['currentMapId'], 'port');
  });
}

SaveEnvelope _envelope(GameIdentity identity) {
  return const SaveEnvelopeCodec().create(
    identity: identity,
    profileId: 'player-1',
    slotId: 'slot-1',
    saveId: '550e8400-e29b-41d4-a716-446655440000',
    createdAt: DateTime.utc(2026, 7, 25, 10),
    updatedAt: DateTime.utc(2026, 7, 25, 11),
    status: SaveStatus.active,
    playTimeSeconds: 120,
    state: const <String, Object?>{'currentMapId': 'port'},
  );
}

GameSessionDescriptor _descriptor(GameIdentity identity) =>
    GameSessionDescriptor(
      sessionId: 'session-1',
      sessionToken: 'secret-1',
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      launchMode: GameSessionLaunchMode.newGame,
      installedVersionHandle: 'install-1',
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: const <String>{},
      locale: 'fr-FR',
      accessibility: const GameSessionAccessibilityOptions(),
    );
