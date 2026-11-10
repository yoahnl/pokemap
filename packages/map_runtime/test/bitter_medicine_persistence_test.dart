import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final powder in ['energy-powder', 'heal-powder']) {
    for (final failFirstSave in [false, true]) {
      test('$powder saves friendship and consumption atomically failure=$failFirstSave', () async {
        final root = await Directory.systemTemp.createTemp('bitter-medicine-');
        addTearDown(() => root.delete(recursive: true));
        final save = File('${root.path}/current.json');
        var state = GameState(saveId: '123e4567-e89b-42d3-a456-426614174004', currentMapId: 'map',
          party: const PlayerParty(members: [PlayerPokemon(individualId: 'lead', speciesId: 'eevee',
            natureId: 'hardy', abilityId: 'run_away', currentHp: 20, statusId: 'poison', friendship: 200)]),
          bag: Bag(entries: [BagEntry(itemId: powder, quantity: 1)]));
        const mapper = GameStateSaveEnvelopeMapper();
        const codec = SaveEnvelopeCodec();
        SaveEnvelope envelope(GameState next) => mapper.create(identity: GameIdentity(gameId: 'org.example.bitter', gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v8, saveFormat: SaveEnvelopeCodec.currentSaveFormat, compatibilityId: 'bitter-v1'),
          profileId: 'player', slotId: 'slot', saveId: next.saveId, createdAt: DateTime.utc(2026, 11, 10),
          updatedAt: DateTime.utc(2026, 11, 10), status: SaveStatus.active, playTimeSeconds: 0, gameState: next);
        await save.writeAsString(codec.encode(envelope(state)), flush: true);
        final before = await save.readAsBytes();
        var writes = 0;
        final controller = PlayerServiceRuntimeController.contextual(currentGameState: () => state, commitAndSave: (next) async {
          writes++;
          if (failFirstSave && writes == 1) throw StateError('disk full');
          final pending = File('${save.path}.pending');
          await pending.writeAsString(codec.encode(envelope(next)), flush: true);
          await pending.rename(save.path);
          state = next;
        }, setInputLocked: (_) {}, loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 100}),
          itemCatalog: ItemCatalogSnapshot.fromCatalog(ProjectItemCatalog(schemaVersion: 1, entries: [ProjectItemDefinition(
            id: powder, displayName: powder, pocketId: 'medicine', uses: [ProjectItemUseDefinition(contexts: {ProjectItemUseContext.overworld},
              target: ProjectItemTargetKind.partyMember, consumption: ProjectItemConsumptionPolicy.onApplied,
              friendshipLoss: const ProjectItemFriendshipLoss(low: 5, medium: 5, high: 10),
              effect: powder == 'energy-powder' ? const ProjectItemEffectDefinition.healHp(mode: ProjectItemAmountMode.flat, amount: 50)
                : const ProjectItemEffectDefinition.cureStatus(mode: ProjectItemStatusCureMode.all, curesConfusion: true))],
          )])));
        addTearDown(controller.dispose);
        Future<RuntimePlayerPauseCommandResult> invoke() => controller.useBagItemOutsideBattle(RuntimePlayerPauseCommand.useBagItem(itemTargetId: powder, partyTargetId: 'party.0'));
        final first = await invoke();
        if (failFirstSave) {
          expect(first.status, RuntimePlayerPauseCommandStatus.failed);
          expect(await save.readAsBytes(), before);
          expect(state.party.members.single.friendship, 200);
          expect(state.bag.entries.single.quantity, 1);
          expect((await invoke()).status, RuntimePlayerPauseCommandStatus.accepted);
        } else {
          expect(first.status, RuntimePlayerPauseCommandStatus.accepted);
        }
        await controller.dispose();
        final resumed = mapper.restore(codec.decode(await save.readAsString()));
        expect(resumed.party.members.single.friendship, 190);
        expect(resumed.party.members.single.currentHp, powder == 'energy-powder' ? 70 : 20);
        expect(resumed.party.members.single.statusId, powder == 'heal-powder' ? '' : 'poison');
        expect(resumed.bag.entries, isEmpty);
        expect(resumed.party, state.party);
        expect(resumed.bag, state.bag);
      });
    }
  }
}
