import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:test/test.dart';

void main() {
  late Directory supportRoot;
  late GameIdentity identity;
  late HubSaveStore store;

  setUp(() async {
    supportRoot = await Directory.systemTemp.createTemp('checkpoint-commit-');
    identity = GameIdentity(
      gameId: 'org.example.adventure',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: 1,
      compatibilityId: 'story-v1',
    );
    store = HubSaveStore(supportRoot: supportRoot, identity: identity);
  });

  tearDown(() async {
    if (await supportRoot.exists()) {
      await supportRoot.delete(recursive: true);
    }
  });

  test(
    'builds and atomically commits active and completed envelopes',
      () async {
    final committer = HubSessionCheckpointCommitter(store: store);
    final descriptor = _descriptor(identity);
    final active = _checkpoint(updatedAt: DateTime.utc(2026, 7, 25, 1));

    await committer.commit(
      GameSessionCheckpointCommit(
        descriptor: descriptor.publicContext,
        checkpoint: active,
        status: SaveStatus.active,
      ),
    );
    var read = await store.read(activeAddress(identity));
    expect(read.envelope?.status, SaveStatus.active);
    expect(read.envelope?.state['currentMapId'], 'route-1');

    final completedAt = DateTime.utc(2026, 7, 25, 2);
    final completed = _checkpoint(updatedAt: completedAt);
    await committer.commit(
      GameSessionCheckpointCommit(
        descriptor: descriptor.publicContext,
        checkpoint: completed,
        status: SaveStatus.completed,
        completedAt: completedAt,
      ),
    );
    read = await store.read(activeAddress(identity));
    expect(read.envelope?.status, SaveStatus.completed);
    expect(read.envelope?.completedAt, completedAt);
    },
  );

  test(
    'rejects mismatched identity and malformed completion metadata',
      () async {
    final committer = HubSessionCheckpointCommitter(store: store);
    final other = GameIdentity(
      gameId: 'org.example.other',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: 1,
      compatibilityId: 'story-v1',
    );

    await expectLater(
      committer.commit(
        GameSessionCheckpointCommit(
          descriptor: _descriptor(other).publicContext,
          checkpoint: _checkpoint(),
          status: SaveStatus.active,
        ),
      ),
      throwsA(isA<HubSessionCheckpointException>()),
    );
    await expectLater(
      committer.commit(
        GameSessionCheckpointCommit(
          descriptor: _descriptor(identity).publicContext,
          checkpoint: _checkpoint(),
          status: SaveStatus.completed,
        ),
      ),
      throwsA(isA<HubSessionCheckpointException>()),
    );
    },
  );

  test(
    'publishes success only after the exact disk generation is confirmed',
      () async {
    var confirmed = false;
    store = HubSaveStore(
      supportRoot: supportRoot,
      identity: identity,
      faultHook: (stage) async {
        if (stage == SaveWriteStage.afterCurrentConfirmed) {
          confirmed = true;
        }
      },
    );
    final committer = HubSessionCheckpointCommitter(store: store);

    await committer.commit(
      GameSessionCheckpointCommit(
        descriptor: _descriptor(identity).publicContext,
        checkpoint: _checkpoint(),
        status: SaveStatus.active,
      ),
    );

    expect(confirmed, isTrue);
    final read = await store.read(activeAddress(identity));
    expect(read.status, SaveSlotReadStatus.valid);
    expect(read.envelope?.checksum, isA<SaveChecksum>());
    },
  );

  test(
    'a corrupt promoted generation restores the previous valid save',
      () async {
    final stable = HubSessionCheckpointCommitter(store: store);
    final previousAt = DateTime.utc(2026, 7, 25, 1);
    await stable.commit(
      GameSessionCheckpointCommit(
        descriptor: _descriptor(identity).publicContext,
        checkpoint: _checkpoint(updatedAt: previousAt),
        status: SaveStatus.active,
      ),
    );
    final primary = File(
      '${supportRoot.path}/saves/${identity.gameId}/player-1/slot-1/save.json',
    );
    final hostileStore = HubSaveStore(
      supportRoot: supportRoot,
      identity: identity,
      faultHook: (stage) async {
        if (stage == SaveWriteStage.afterCurrentPromoted) {
          await primary.writeAsString('{corrupt', flush: true);
        }
      },
    );
    final hostile = HubSessionCheckpointCommitter(store: hostileStore);

    await expectLater(
      hostile.commit(
        GameSessionCheckpointCommit(
          descriptor: _descriptor(identity).publicContext,
          checkpoint: _checkpoint(updatedAt: DateTime.utc(2026, 7, 25, 2)),
          status: SaveStatus.active,
        ),
      ),
      throwsA(
        isA<HubSessionCheckpointException>().having(
          (error) => error.code,
          'code',
          HubSessionCheckpointErrorCode.writeFailed,
        ),
      ),
    );

    final recovered = await store.read(activeAddress(identity));
    expect(recovered.status, SaveSlotReadStatus.valid);
    expect(recovered.envelope?.updatedAt, previousAt);
    },
  );
}

SaveSlotAddress activeAddress(GameIdentity identity) => SaveSlotAddress(
      gameId: identity.gameId,
      profileId: 'player-1',
      slotId: 'slot-1',
    );

GameSessionDescriptor _descriptor(GameIdentity identity) =>
    GameSessionDescriptor(
      sessionId: 'session-1',
      sessionToken: 'secret',
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      launchMode: GameSessionLaunchMode.newGame,
      installedVersionHandle: 'install-1',
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: const <String>{},
      locale: 'fr-FR',
      accessibility: const GameSessionAccessibilityOptions(),
      initialGameState: const GameState(
        saveId: 'slot-1',
        currentMapId: 'route-1',
      ),
    );

GameSessionCheckpoint _checkpoint({DateTime? updatedAt}) {
  return GameSessionCheckpoint(
    saveId: '123e4567-e89b-42d3-a456-426614174000',
    createdAt: DateTime.utc(2026, 7, 24),
    updatedAt: updatedAt ?? DateTime.utc(2026, 7, 25),
    playTimeSeconds: 120,
    state: const <String, Object?>{
      'saveId': '123e4567-e89b-42d3-a456-426614174000',
      'currentMapId': 'route-1',
    },
  );
}
