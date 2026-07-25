import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const damagedState = GameState(
    saveId: 'heal-service',
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'hardy',
          abilityId: 'overgrow',
          currentHp: 3,
          statusId: 'poison',
          knownMoveIds: <String>['tackle'],
          currentPpByMoveId: <String, int>{'tackle': 1},
        ),
      ],
    ),
  );
  const recoveryCaps = RuntimePlayerServiceRecoveryCaps(
    maxHpByPartyIndex: <int, int>{0: 24},
    maxPpByPartyIndex: <int, Map<String, int>>{
      0: <String, int>{'tackle': 35},
    },
  );

  test('confirmation heals HP, PP and status in one runtime transaction',
      () async {
    var state = damagedState;
    final commits = <GameState>[];
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => recoveryCaps,
    );
    addTearDown(controller.dispose);

    final open = controller.openHealCenter(
      request: const OpenHealService(
        interactionId: 'npc.nurse',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final confirmation = controller.worldServiceSnapshot!;
    expect(confirmation.request.kind, RuntimeWorldServiceKind.heal);
    expect(confirmation.stage, RuntimeWorldServiceStage.active);
    expect(
      (confirmation.content! as RuntimeHealServiceContent)
          .members
          .single
          .currentHp,
      3,
    );

    final confirmed = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: confirmation.revision,
      ),
    );
    expect(confirmed.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(controller.worldServiceSnapshot?.stage,
        RuntimeWorldServiceStage.completed);
    expect(commits, hasLength(1));
    expect(state.party.members.single.currentHp, 24);
    expect(state.party.members.single.currentPpByMoveId, <String, int>{
      'tackle': 35,
    });
    expect(state.party.members.single.statusId, isEmpty);

    final resultSnapshot = controller.worldServiceSnapshot!;
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: resultSnapshot.revision,
      ),
    );
    final result = await open;
    expect(result.status, PlayerServiceRuntimeStatus.completed);
    expect(locks, <bool>[true, false]);
    expect(controller.worldServiceSnapshot, isNull);
  });

  test('cancelling heal keeps the previous state and releases input', () async {
    final commits = <GameState>[];
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => damagedState,
      commitAndSave: (state) async => commits.add(state),
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => recoveryCaps,
    );
    addTearDown(controller.dispose);

    final open = controller.openHealCenter();
    await Future<void>.delayed(Duration.zero);
    final snapshot = controller.worldServiceSnapshot!;
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.cancel,
        snapshotRevision: snapshot.revision,
      ),
    );

    expect((await open).status, PlayerServiceRuntimeStatus.cancelled);
    expect(commits, isEmpty);
    expect(locks, <bool>[true, false]);
  });

  test(
      'failed heal commit preserves state, reports failure and unlocks on close',
      () async {
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => damagedState,
      commitAndSave: (_) async => throw StateError('disk full'),
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => recoveryCaps,
    );
    addTearDown(controller.dispose);

    final open = controller.openHealCenter();
    await Future<void>.delayed(Duration.zero);
    final confirmation = controller.worldServiceSnapshot!;
    final failed = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: confirmation.revision,
      ),
    );

    expect(failed.status, RuntimeWorldServiceCommandStatus.failed);
    expect(controller.worldServiceSnapshot?.stage,
        RuntimeWorldServiceStage.failed);
    expect(
      controller.worldServiceSnapshot?.safeMessage,
      'Le soin n’a pas pu être enregistré.',
    );
    final failedSnapshot = controller.worldServiceSnapshot!;
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: failedSnapshot.revision,
      ),
    );

    expect((await open).status, PlayerServiceRuntimeStatus.failed);
    expect(damagedState.party.members.single.currentHp, 3);
    expect(locks, <bool>[true, false]);
  });

  test('explicit immediate heal skips confirmation and commits once', () async {
    var state = damagedState;
    var commits = 0;
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits++;
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => recoveryCaps,
    );
    addTearDown(controller.dispose);

    final result = await controller.openHealCenter(
      request: const OpenHealService(
        interactionId: 'zone.auto-heal',
        requiresConfirmation: false,
      ),
    );

    expect(result.status, PlayerServiceRuntimeStatus.completed);
    expect(commits, 1);
    expect(state.party.members.single.currentHp, 24);
    expect(controller.worldServiceSnapshot, isNull);
  });
}
