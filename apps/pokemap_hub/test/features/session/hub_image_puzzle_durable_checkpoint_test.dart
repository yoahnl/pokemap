import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';

import '../../../../../packages/map_runtime/test/session/spatial_image_puzzle_durable_host_test.dart'
    show SpatialImagePuzzleDurableHostFixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('image puzzle crosses production Hub gateway and atomic store then cold Continue', () async {
    final fixture = await SpatialImagePuzzleDurableHostFixture.create();
    addTearDown(fixture.dispose);
    final identity = fixture.descriptor(false).identity;
    final support = Directory('${fixture.root.path}/support');
    var fail = false;
    final store = HubSaveStore(
      supportRoot: support,
      identity: identity,
      faultHook: (stage) async {
        if (fail && stage == SaveWriteStage.afterTemporaryVerified)
          throw const FileSystemException('disk full');
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
    await fixture.open(checkpointCommitter: gateway.commit);
    await fixture.active();
    final initialized = const GameStateSaveEnvelopeMapper().restore(
      (await store.read(address)).envelope!,
    );
    expect(initialized.imagePuzzleState.puzzlesById['mosaic'], isNotNull);
    expect(initialized.trainerProfile.money, 0);
    final before = await file.readAsBytes();
    fail = true;
    expect(
      (await fixture.send(
        RuntimeWorldServiceAction.move,
        target: '0',
        slot: '0',
      )).status,
      RuntimeWorldServiceCommandStatus.failed,
    );
    expect(await file.readAsBytes(), before);
    fail = false;
    await fixture.send(RuntimeWorldServiceAction.rotate, target: '0');
    final saved = const GameStateSaveEnvelopeMapper().restore(
      (await store.read(address)).envelope!,
    );
    expect(
      saved.copyWith(imagePuzzleState: initialized.imagePuzzleState),
      initialized,
    );
    await fixture.send(RuntimeWorldServiceAction.cancel);
    await fixture.runtime.gameplayReady;
    expect(fixture.runtime.gameStateSnapshot.trainerProfile.money, 25);
    await fixture.open(
      continueGame: true,
      checkpointCommitter: gateway.commit,
      saveLoader: () => gateway.readLaunchableEnvelope(address),
    );
    await fixture.active();
    expect(
      (fixture.runtime.worldServiceSnapshot!.content
              as RuntimeImagePuzzleServiceContent)
          .progress,
      saved.imagePuzzleState.puzzlesById['mosaic'],
    );
    await fixture.send(RuntimeWorldServiceAction.cancel);
    await fixture.runtime.gameplayReady;
  });
}
