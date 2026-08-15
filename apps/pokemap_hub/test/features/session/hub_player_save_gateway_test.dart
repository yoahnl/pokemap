import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_save_gateway.dart';
import 'package:pokemap_hub/features/session/application/services/hub_session_checkpoint_committer.dart';
import 'package:pokemap_hub/features/saves/data/repositories/hub_save_repository_impl.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';

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

  test(
    'returns scoped summaries and opaque handles for the exact slot',
    () async {
      final envelope = _envelope(identity);
      await store.write(envelope);

      final latest = await gateway.readLatestSummary();
      final exact = await gateway.readSummary(envelope.address);
      final handle = await gateway.openReadHandle(envelope.address);
      final launchable = await gateway.readLaunchableEnvelope(envelope.address);

      expect(gateway.identity, identity);
      expect(latest?.address, envelope.address);
      expect(exact?.address, envelope.address);
      expect(exact?.canContinue, isTrue);
      expect(exact?.playTimeSeconds, 120);
      expect(handle, isNotNull);
      expect(handle, isNot(contains(identity.gameId)));
      expect(handle, isNot(contains(envelope.profileId)));
      expect(handle, isNot(contains(envelope.slotId)));
      expect(launchable?.saveId, envelope.saveId);
    },
  );

  test(
    'completed saves respect the authored post-game policy on reload',
    () async {
      for (final testCase in <({ScenePostGamePolicy policy, bool canContinue})>[
        (policy: ScenePostGamePolicy.continueGame, canContinue: true),
        (policy: ScenePostGamePolicy.returnToTitle, canContinue: false),
        (policy: ScenePostGamePolicy.returnToHub, canContinue: false),
      ]) {
        final envelope = _envelope(
          identity,
          status: SaveStatus.completed,
          completedAt: DateTime.utc(2026, 7, 25, 11),
          state: <String, Object?>{
            'currentMapId': 'port',
            'metadata': <String, String>{
              sceneGameCompletionEndingMetadataKey: 'ending.selbrume',
              sceneGameCompletionPostGamePolicyMetadataKey:
                  testCase.policy.name,
            },
          },
        );
        await store.write(envelope);

        final summary = await gateway.readSummary(envelope.address);
        final handle = await gateway.openReadHandle(envelope.address);
        final launchable = await gateway.readLaunchableEnvelope(
          envelope.address,
        );

        expect(
          summary?.canContinue,
          testCase.canContinue,
          reason: testCase.policy.name,
        );
        expect(
          handle != null,
          testCase.canContinue,
          reason: testCase.policy.name,
        );
        expect(
          launchable != null,
          testCase.canContinue,
          reason: testCase.policy.name,
        );
      }
    },
  );

  test(
    'refuses another game and does not leak another profile or slot',
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
    },
  );

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

  test(
    'coalesces an identical checkpoint while its write is in flight',
    () async {
      final gate = Completer<void>();
      var temporaryWrites = 0;
      store = HubSaveStore(
        supportRoot: root,
        identity: identity,
        faultHook: (stage) async {
          if (stage != SaveWriteStage.afterTemporaryFlushed) return;
          temporaryWrites++;
          await gate.future;
        },
      );
      gateway = HubPlayerSaveGateway(store: store);
      final request = GameSessionCheckpointCommit(
        descriptor: _descriptor(identity).publicContext,
        checkpoint: _checkpoint(revision: 1),
        status: SaveStatus.active,
      );

      final first = gateway.commit(request);
      final second = gateway.commit(request);
      await _waitUntil(() => temporaryWrites == 1);
      gate.complete();
      await Future.wait(<Future<void>>[first, second]);

      expect(temporaryWrites, 1);
      final stored = await store.read(activeAddress(identity));
      expect(stored.envelope?.state['revision'], 1);
    },
  );

  test(
    'keeps the previous generation around failures before promotion',
    () async {
      for (final failureStage in <SaveWriteStage>[
        SaveWriteStage.afterTemporaryVerified,
        SaveWriteStage.afterCurrentStagedAsBackup,
      ]) {
        final caseRoot = await Directory.systemTemp.createTemp(
          'hub-gateway-race-',
        );
        addTearDown(() async {
          if (await caseRoot.exists()) await caseRoot.delete(recursive: true);
        });
        final stableStore = HubSaveStore(
          supportRoot: caseRoot,
          identity: identity,
        );
        await stableStore.write(_envelope(identity));
        final failingStore = HubSaveStore(
          supportRoot: caseRoot,
          identity: identity,
          faultHook: (stage) async {
            if (stage == failureStage) {
              throw StateError('injected ${stage.name}');
            }
          },
        );
        final failingGateway = HubPlayerSaveGateway(store: failingStore);

        await expectLater(
          failingGateway.commit(
            GameSessionCheckpointCommit(
              descriptor: _descriptor(identity).publicContext,
              checkpoint: _checkpoint(revision: 2),
              status: SaveStatus.active,
            ),
          ),
          throwsA(isA<HubSessionCheckpointException>()),
          reason: failureStage.name,
        );

        final recovered = await stableStore.read(activeAddress(identity));
        expect(recovered.envelope?.saveId, _envelope(identity).saveId);
        expect(
          recovered.envelope?.state['currentMapId'],
          'port',
          reason: failureStage.name,
        );
      }
    },
  );

  test(
    'releases a failed coalesced checkpoint so the player can retry',
    () async {
      var failNextWrite = true;
      store = HubSaveStore(
        supportRoot: root,
        identity: identity,
        faultHook: (stage) async {
          if (failNextWrite && stage == SaveWriteStage.afterTemporaryVerified) {
            failNextWrite = false;
            throw StateError('injected first failure');
          }
        },
      );
      gateway = HubPlayerSaveGateway(store: store);
      final request = GameSessionCheckpointCommit(
        descriptor: _descriptor(identity).publicContext,
        checkpoint: _checkpoint(revision: 3),
        status: SaveStatus.active,
      );

      await expectLater(
        gateway.commit(request),
        throwsA(isA<HubSessionCheckpointException>()),
      );
      await gateway.commit(request);

      final stored = await store.read(activeAddress(identity));
      expect(stored.envelope?.state['revision'], 3);
    },
  );
}

SaveEnvelope _envelope(
  GameIdentity identity, {
  SaveStatus status = SaveStatus.active,
  DateTime? completedAt,
  Map<String, Object?> state = const <String, Object?>{'currentMapId': 'port'},
}) {
  return const SaveEnvelopeCodec().create(
    identity: identity,
    profileId: 'player-1',
    slotId: 'slot-1',
    saveId: '550e8400-e29b-41d4-a716-446655440000',
    createdAt: DateTime.utc(2026, 7, 25, 10),
    updatedAt: DateTime.utc(2026, 7, 25, 11),
    status: status,
    completedAt: completedAt,
    playTimeSeconds: 120,
    state: state,
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
      initialGameState: const GameState(
        saveId: 'slot-1',
        currentMapId: 'route-1',
      ),
    );

SaveSlotAddress activeAddress(GameIdentity identity) => SaveSlotAddress(
  gameId: identity.gameId,
  profileId: 'player-1',
  slotId: 'slot-1',
);

GameSessionCheckpoint _checkpoint({required int revision}) {
  return GameSessionCheckpoint(
    saveId: '550e8400-e29b-41d4-a716-44665544000$revision',
    createdAt: DateTime.utc(2026, 7, 25, 10),
    updatedAt: DateTime.utc(2026, 7, 25, 11, revision),
    playTimeSeconds: 180 + revision,
    state: <String, Object?>{
      'currentMapId': 'route-$revision',
      'revision': revision,
    },
  );
}

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not reached before the test timeout.');
}
