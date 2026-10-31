import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_save_gateway.dart';
import 'package:pokemap_hub/features/session/application/services/hub_session_checkpoint_committer.dart';
import 'package:pokemap_hub/features/saves/data/repositories/hub_save_repository_impl.dart';

import '../../../../../packages/map_runtime/test/spatial_battle_runtime_test.dart'
    as spatial;
import '../../../../../packages/map_runtime/test/source_converted_gym_reward_journey_test.dart'
    show installConvertedQaHeadlessAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final partySize in [1, 6]) {
    testWidgets(
      'manual Save failure retry and cold Continue retain Friend capture partySize=$partySize',
      (tester) async {
        installConvertedQaHeadlessAudio(completePlayback: true);
        final fixture = (await tester.runAsync(
          spatial.contextualCaptureSpatialFixture,
        ))!;
        final qa = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('capture-hub-store-'),
        ))!;
        addTearDown(() => qa.delete(recursive: true));
        final initial = fixture.state.copyWith(
          saveId: '550e8400-e29b-41d4-a716-446655440000',
          party: PlayerParty(
            members: [
              for (var index = 0; index < partySize; index++)
                fixture.state.party.members.first.copyWith(
                  individualId: 'owned-$index',
                ),
            ],
          ),
        );
        final identity = GameIdentity(
          gameId: 'org.example.contextual-capture',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v9,
          saveFormat: 2,
          compatibilityId: 'contextual-capture',
        );
        var fail = false;
        var writes = 0;
        final store = HubSaveStore(
          supportRoot: qa,
          identity: identity,
          faultHook: (stage) async {
            if (stage == SaveWriteStage.afterTemporaryVerified) {
              writes++;
              if (fail) throw StateError('injected disk failure');
            }
          },
        );
        final gateway = HubPlayerSaveGateway(store: store);
        final address = SaveSlotAddress(
          gameId: identity.gameId,
          profileId: 'player',
          slotId: 'slot',
        );
        GameSessionDescriptor descriptor(bool continuation) =>
            GameSessionDescriptor(
              sessionId: 'capture',
              sessionToken: 'token',
              identity: identity,
              profileId: address.profileId,
              slotId: address.slotId,
              launchMode: continuation
                  ? GameSessionLaunchMode.continueGame
                  : GameSessionLaunchMode.newGame,
              saveReadHandle: continuation ? 'save' : null,
              initialGameState: continuation ? null : initial,
              installedVersionHandle: 'installed',
              runtimeApiVersion: '1.4.0',
              grantedCapabilities: {
                'map3d@1',
                'map3d.story@1',
                'map3d.gameplay@1',
              },
              locale: 'fr',
              accessibility: const GameSessionAccessibilityOptions(),
            );
        SpatialExplorationGameSessionRuntime open(bool continuation) =>
            SpatialExplorationGameSessionRuntime(
              descriptor: descriptor(continuation),
              projectFilePath: () async =>
                  '${fixture.bundle.projectRootDirectory}/project.json',
              initialSave: continuation
                  ? () => gateway.readLaunchableEnvelope(address)
                  : null,
              preloadedInitialMap:
                  ({
                    required projectFilePath,
                    required descriptor,
                    required initialSave,
                  }) async =>
                      RuntimeInitialMapPreloadResult(bundle: fixture.bundle),
              commitCheckpoint: gateway.commit,
              mountSession: (_) async {},
              unmountSession: (_) async {},
            );
        var host = open(false);
        addTearDown(() => host.dispose());
        await tester.runAsync(() => host.load((_) {}));
        await tester.runAsync(() => host.gameplayReady);
        Future<void> save() async {
          final checkpoint = (await host.captureCheckpoint())!;
          await gateway.commit(
            GameSessionCheckpointCommit(
              descriptor: host.descriptor.publicContext,
              checkpoint: checkpoint,
              status: SaveStatus.active,
              trigger: GameSessionCheckpointTrigger.manual,
            ),
          );
        }

        await tester.runAsync(save);
        final previous = (await tester.runAsync(
          () => gateway.readLaunchableEnvelope(address),
        ))!;
        final currentFile = qa
            .listSync(recursive: true)
            .whereType<File>()
            .singleWhere((file) => file.path.endsWith('/save.json'));
        final originalBytes = currentFile.readAsBytesSync();
        final battle = host.battle!;
        final completion = battle.start(
          bundle: fixture.bundle,
          request: spatial.contextualCaptureWildRequest('friend-capture'),
        );
        await spatial.readyContextualCaptureBattle(tester, battle);
        expect(
          await spatial.submitFriendContextualCapture(tester, battle),
          isTrue,
        );
        expect(battle.displaySession!.state.outcome!.isCaptured, isTrue);
        final runtimeContext = battle.context!;
        final outcome = battle.displaySession!.state.outcome!;
        await spatial.acknowledgeContextualCaptureBattle(tester, battle);
        expect(await completion, isTrue);
        final finalState = host.gameStateSnapshot;
        final captured = partySize == 1
            ? finalState.party.members.last
            : finalState.pokemonStorage.storedPokemon.single;
        expect(captured.friendship, 200);
        expect(
          finalState.completedBattleRequestIds,
          contains('friend-capture'),
        );
        expect(finalState.bag.entries.single.quantity, 49);
        expect(currentFile.readAsBytesSync(), originalBytes);
        fail = true;
        await tester.runAsync(
          () => expectLater(
            save(),
            throwsA(isA<HubSessionCheckpointException>()),
          ),
        );
        expect(currentFile.readAsBytesSync(), originalBytes);
        expect(
          (await tester.runAsync(
            () => gateway.readLaunchableEnvelope(address),
          ))!.checksum,
          previous.checksum,
        );
        expect(host.gameStateSnapshot, finalState);
        fail = false;
        await tester.runAsync(save);
        expect(writes, 3);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(host.dispose);
        host = open(true);
        await tester.runAsync(() => host.load((_) {}));
        await tester.runAsync(() => host.gameplayReady);
        final restored = host.gameStateSnapshot;
        final restoredCaptured = partySize == 1
            ? restored.party.members.last
            : restored.pokemonStorage.storedPokemon.single;
        expect(restoredCaptured.individualId, captured.individualId);
        expect(restoredCaptured.friendship, 200);
        expect(restored.bag.entries.single.quantity, 49);
        expect(restored.completedBattleRequestIds, contains('friend-capture'));
        final bytes = currentFile.readAsBytesSync();
        final duplicate = await tester.runAsync(
          () => RuntimePostBattleDecisionCoordinator().begin(
            transactionBaseState: restored,
            bundle: fixture.bundle,
            runtimeContext: runtimeContext,
            outcome: outcome,
            itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
          ),
        );
        expect(
          duplicate!.failure!.code,
          RuntimePostBattleCoordinatorFailureCode.alreadyApplied,
        );
        expect(host.gameStateSnapshot, restored);
        expect(currentFile.readAsBytesSync(), bytes);
        expect(writes, 3);
      },
      timeout: const Timeout(Duration(seconds: 120)),
      skip:
          Platform.environment['AVELUNE_CONTEXTUAL_CAPTURE_DURABLE_QA'] != '1',
    );
  }
}
