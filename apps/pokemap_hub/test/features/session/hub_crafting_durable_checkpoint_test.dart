import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';

import '../../../../../packages/map_runtime/test/session/spatial_crafting_durable_host_test.dart'
    show SpatialCraftingDurableHostFixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('3D crafting uses production Hub save gateway and atomic store across failure and cold Continue', () async {
    final fixture = await SpatialCraftingDurableHostFixture.create();
    addTearDown(fixture.dispose);
    final identity = fixture.descriptor(false).identity;
    final support = Directory('${fixture.root.path}/support');
    var fail = false;
    final store = HubSaveStore(
      supportRoot: support,
      identity: identity,
      faultHook: (stage) async {
        if (fail && stage == SaveWriteStage.afterTemporaryVerified)
          throw const FileSystemException('injected disk failure');
      },
    );
    final gateway = HubPlayerSaveGateway(store: store);
    final address = SaveSlotAddress(
      gameId: identity.gameId,
      profileId: 'profile',
      slotId: 'slot',
    );
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
    final before = await file.readAsBytes();
    await fixture.open(checkpointCommitter: gateway.commit);
    await fixture.active();
    final beforeScene = fixture.runtime.gameStateSnapshot;
    await fixture.send(RuntimeWorldServiceAction.select, target: 'ball');
    await fixture.send(RuntimeWorldServiceAction.confirm);
    fail = true;
    expect(
      (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
      RuntimeWorldServiceCommandStatus.failed,
    );
    expect(await file.readAsBytes(), before);
    expect(
      fixture.runtime.gameStateSnapshot.deferredCraftingState
          .serviceFor('artisan')
          .pendingOrder,
      isNull,
    );
    fail = false;
    await fixture.send(RuntimeWorldServiceAction.confirm);
    final submitted = (await store.read(address)).envelope!;
    final state = const GameStateSaveEnvelopeMapper().restore(submitted);
    expect(state.bag.entries.single.quantity, 2);
    expect(state.trainerProfile.money, 0);
    expect(
      state.copyWith(
        bag: beforeScene.bag,
        gameplayCalendarState: beforeScene.gameplayCalendarState,
        deferredCraftingState: beforeScene.deferredCraftingState,
      ),
      beforeScene,
    );
    expect(
      state.deferredCraftingState.serviceFor('artisan').pendingOrder,
      isNotNull,
    );
    await fixture.send(RuntimeWorldServiceAction.close);
    await fixture.runtime.gameplayReady;
    expect(fixture.runtime.gameStateSnapshot.trainerProfile.money, 25);
    final submittedBytes = await file.readAsBytes();
    fixture.now = DateTime(2026, 10, 31, 0, 1);
    await fixture.open(
      continueGame: true,
      checkpointCommitter: gateway.commit,
      saveLoader: () => gateway.readLaunchableEnvelope(address),
    );
    await fixture.active();
    expect(
      (fixture.runtime.worldServiceSnapshot!.content
              as RuntimeCraftingServiceContent)
          .status,
      RuntimeCraftingStatus.ready,
    );
    fail = true;
    expect(
      (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
      RuntimeWorldServiceCommandStatus.failed,
    );
    expect(await file.readAsBytes(), submittedBytes);
    fail = false;
    await fixture.send(RuntimeWorldServiceAction.confirm);
    final collected = const GameStateSaveEnvelopeMapper().restore(
      (await store.read(address)).envelope!,
    );
    expect(
      collected.deferredCraftingState.serviceFor('artisan').pendingOrder,
      isNull,
    );
    expect(const BagOperations().quantityOf(collected.bag, 'ball'), 1);
    await fixture.send(RuntimeWorldServiceAction.close);
    await fixture.runtime.gameplayReady;
    await fixture.open(
      continueGame: true,
      checkpointCommitter: gateway.commit,
      saveLoader: () => gateway.readLaunchableEnvelope(address),
    );
    await fixture.active();
    expect(
      (fixture.runtime.worldServiceSnapshot!.content
              as RuntimeCraftingServiceContent)
          .status,
      RuntimeCraftingStatus.idle,
    );
    await fixture.send(RuntimeWorldServiceAction.cancel);
    await fixture.runtime.gameplayReady;
    expect(
      const BagOperations().quantityOf(
        const GameStateSaveEnvelopeMapper()
            .restore((await store.read(address)).envelope!)
            .bag,
        'ball',
      ),
      1,
    );
  });
}
