import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import '../support/scene_catalog_pokemon_gift_fixture.dart';

void main() {
  const damagedState = GameState(
    saveId: 'heal-service',
    currentMapId: 'clinic',
    playerPosition: GridPos(x: 4, y: 6),
    playerFacing: EntityFacing.west,
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
    final root = await Directory.systemTemp.createTemp('heal-species-locale-');
    addTearDown(() => root.delete(recursive: true));
    final config = await writeSceneCatalogPokemonGiftFixture(root);
    final file = File('${root.path}/custom/species/not-a-builtin.json');
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    json['id'] = 'sproutle';
    json['names'] = {'en': 'Sprout Friend', 'fr': 'Pousse'};
    await file.writeAsString(jsonEncode(json));
    var state = damagedState;
    var uiLocale = 'en';
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
      projectRootDirectory: root.path,
      pokemonConfig: config,
      locale: 'fr',
      displayLocale: () => uiLocale,
    );
    addTearDown(controller.dispose);

    final firstSnapshot = controller.worldServiceSnapshots.firstWhere(
      (snapshot) => snapshot != null,
    );
    final open = controller.openHealCenter(
      request: const OpenHealService(
        interactionId: 'npc.nurse',
      ),
    );
    final confirmation = (await firstSnapshot)!;
    expect(confirmation.request.kind, RuntimeWorldServiceKind.heal);
    expect(confirmation.stage, RuntimeWorldServiceStage.active);
    final member =
        (confirmation.content! as RuntimeHealServiceContent).members.single;
    expect(member.currentHp, 3);
    expect(member.label, 'Sprout Friend');

    uiLocale = 'fr';
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
    expect(PlayerRecoveryPoint.tryRead(state)?.mapId, 'clinic');
    expect(
      PlayerRecoveryPoint.tryRead(state)?.position,
      const GridPos(x: 4, y: 6),
    );
    expect(PlayerRecoveryPoint.tryRead(state)?.facing, EntityFacing.west);

    final resultSnapshot = controller.worldServiceSnapshot!;
    final healed = resultSnapshot.content! as RuntimeHealServiceContent;
    expect(healed.members.single.label, 'Pousse');

    uiLocale = 'en';
    controller.refreshPokemonDisplayNames();
    final refreshed = controller.worldServiceSnapshot!;
    final refreshedMembers = (refreshed.content! as RuntimeHealServiceContent).members;
    expect(refreshedMembers.single.label, 'Sprout Friend');
    expect(refreshed.stage, RuntimeWorldServiceStage.completed);
    expect(refreshed.safeMessage, resultSnapshot.safeMessage);
    expect(commits, hasLength(1));
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: refreshed.revision,
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
