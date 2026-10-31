import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';

import '../../../../../packages/map_runtime/test/session/spatial_image_puzzle_durable_host_test.dart'
    show SpatialImagePuzzleDurableHostFixture;
import '../../../../../packages/map_runtime/test/scene_periodic_reward_durable_host_test.dart'
    show rewardScene, availabilityScene, calendarCeilingFaultFixture, periodicQa;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('unavailable after durable checkpoint preserves Hub bytes and leaves event retryable on cold Continue', () async {
    final fixture = await SpatialImagePuzzleDurableHostFixture.create(sceneOverride: availabilityScene(), configureInitialState: calendarCeilingFaultFixture, qaDirectory: periodicQa);
    addTearDown(fixture.dispose);
    final identity = fixture.descriptor(false).identity;
    final support = Directory('${fixture.root.path}/support');
    final store = HubSaveStore(supportRoot: support, identity: identity);
    final gateway = HubPlayerSaveGateway(store: store);
    final address = SaveSlotAddress(gameId: identity.gameId, profileId: 'profile', slotId: 'slot');
    await fixture.open(checkpointCommitter: (request) async {
      await gateway.commit(request);
      fixture.now = fixture.now.add(const Duration(days: 1));
    });
    await fixture.runtime.gameplayReady;
    final session = fixture.runtime.session!;
    expect(session.interactionError.value, isNotNull);
    expect(session.interactionError.value.toString(), contains('disponibilité'));
    final durable = const GameStateSaveEnvelopeMapper().restore((await store.read(address)).envelope!);
    expect(durable.periodicRewardState.claimFor('tree'), isNotNull);
    expect(durable.trainerProfile.money, 0);
    expect(fixture.runtime.gameStateSnapshot.periodicRewardState, durable.periodicRewardState);
    expect(fixture.runtime.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds, isEmpty);
    final file = File('${support.path}/saves/${identity.gameId}/profile/slot/save.json');
    final bytes = await file.readAsBytes();
    await expectLater(fixture.open(continueGame: true, checkpointCommitter: gateway.commit, saveLoader: () => gateway.readLaunchableEnvelope(address)), throwsFormatException);
    expect(await file.readAsBytes(), bytes);
    fixture.now = DateTime(2026, 10, 30, 23, 59);
    await fixture.open(continueGame: true, checkpointCommitter: gateway.commit, saveLoader: () => gateway.readLaunchableEnvelope(address));
    await fixture.runtime.gameplayReady;
    expect(fixture.runtime.session!.interactionError.value, isNull);
    expect(fixture.runtime.gameStateSnapshot.trainerProfile.money, 0);
    expect(fixture.runtime.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds, hasLength(1));
    expect(await file.readAsBytes(), bytes);
  });
  test('suspended Hub writer cannot publish claim or calendar and fault permits cold retry', () async {
    final fixture = await SpatialImagePuzzleDurableHostFixture.create(sceneOverride: availabilityScene(), qaDirectory: periodicQa);
    addTearDown(fixture.dispose);
    final identity = fixture.descriptor(false).identity;
    final support = Directory('${fixture.root.path}/support');
    final reached = Completer<void>();
    final release = Completer<void>();
    var fail = false;
    final store = HubSaveStore(supportRoot: support, identity: identity, faultHook: (stage) async {
      if (fail && stage == SaveWriteStage.afterTemporaryVerified) {
        reached.complete(); await release.future; throw const FileSystemException('disk full');
      }
    });
    final gateway = HubPlayerSaveGateway(store: store);
    final address = SaveSlotAddress(gameId: identity.gameId, profileId: 'profile', slotId: 'slot');
    await store.writeVerified(const GameStateSaveEnvelopeMapper().create(identity: identity, profileId: 'profile', slotId: 'slot', saveId: fixture.initial.saveId, createdAt: fixture.now.toUtc(), updatedAt: fixture.now.toUtc(), status: SaveStatus.active, playTimeSeconds: 0, gameState: fixture.initial));
    final file = File('${support.path}/saves/${identity.gameId}/profile/slot/save.json');
    final bytes = await file.readAsBytes();
    fail = true;
    await fixture.open(checkpointCommitter: gateway.commit);
    await reached.future;
    final before = fixture.runtime.gameStateSnapshot;
    fixture.now = fixture.now.add(const Duration(minutes: 2));
    await fixture.runtime.resume();
    fixture.runtime.session!.setLifecyclePaused(true);
    fixture.runtime.session!.setLifecyclePaused(false);
    expect(fixture.runtime.gameStateSnapshot, before);
    expect(before.periodicRewardState.claimsById, isEmpty);
    expect(await file.readAsBytes(), bytes);
    release.complete();
    await fixture.runtime.gameplayReady;
    expect(fixture.runtime.gameStateSnapshot.periodicRewardState.claimsById, isEmpty);
    expect(await file.readAsBytes(), bytes);
    fail = false;
    await fixture.open(continueGame: true, checkpointCommitter: gateway.commit, saveLoader: () => gateway.readLaunchableEnvelope(address));
    await fixture.runtime.gameplayReady;
    final saved = const GameStateSaveEnvelopeMapper().restore((await store.read(address)).envelope!);
    expect(saved.periodicRewardState.claimsById.keys, ['tree']);
    expect(saved.gameplayCalendarState.observedLocalDay, '2026-10-31');
    final committed = await file.readAsBytes();
    await fixture.open(continueGame: true, checkpointCommitter: gateway.commit, saveLoader: () => gateway.readLaunchableEnvelope(address));
    await fixture.runtime.gameplayReady;
    expect(await file.readAsBytes(), committed);
  });
  test('reward crosses real Hub store: atomic fault preserves bytes, cold Continue cannot duplicate', () async {
    final fixture = await SpatialImagePuzzleDurableHostFixture.create(
      sceneOverride: rewardScene(),
      qaDirectory: periodicQa,
    );
    addTearDown(fixture.dispose);
    final identity = fixture.descriptor(false).identity;
    final support = Directory('${fixture.root.path}/support');
    var fail = true;
    final store = HubSaveStore(
      supportRoot: support,
      identity: identity,
      faultHook: (stage) async {
        if (fail && stage == SaveWriteStage.afterTemporaryVerified) {
          throw const FileSystemException('disk full');
        }
      },
    );
    final gateway = HubPlayerSaveGateway(store: store);
    final address = SaveSlotAddress(
      gameId: identity.gameId,
      profileId: 'profile',
      slotId: 'slot',
    );
    fail = false;
    await store.writeVerified(
      const GameStateSaveEnvelopeMapper().create(
        identity: identity,
        profileId: 'profile',
        slotId: 'slot',
        saveId: fixture.initial.saveId,
        createdAt: DateTime.utc(2026, 10, 30),
        updatedAt: DateTime.utc(2026, 10, 30),
        status: SaveStatus.active,
        playTimeSeconds: 0,
        gameState: fixture.initial,
      ),
    );
    final file = File(
      '${support.path}/saves/${identity.gameId}/profile/slot/save.json',
    );
    final original = await file.readAsBytes();
    fail = true;
    await fixture.open(checkpointCommitter: gateway.commit);
    await fixture.runtime.gameplayReady;
    expect(await file.readAsBytes(), original);
    expect(
      fixture.runtime.gameStateSnapshot.periodicRewardState.claimsById,
      isEmpty,
    );
    fail = false;
    await fixture.open(
      continueGame: true,
      checkpointCommitter: gateway.commit,
      saveLoader: () => gateway.readLaunchableEnvelope(address),
    );
    await fixture.runtime.gameplayReady;
    final saved = const GameStateSaveEnvelopeMapper().restore(
      (await store.read(address)).envelope!,
    );
    expect(const BagOperations().quantityOf(saved.bag, 'fruit'), 8);
    expect(saved.periodicRewardState.claimsById.length, 2);
    expect(saved.trainerProfile.money, 0);
    final bytes = await file.readAsBytes();
    await fixture.open(
      continueGame: true,
      checkpointCommitter: gateway.commit,
      saveLoader: () => gateway.readLaunchableEnvelope(address),
    );
    await fixture.runtime.gameplayReady;
    expect(await file.readAsBytes(), bytes);
    expect(
      fixture.runtime.gameStateSnapshot.periodicRewardState,
      saved.periodicRewardState,
    );
  });
}
