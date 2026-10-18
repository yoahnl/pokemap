import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'scene_interactive_pokemon_gift_test.dart' show giftCatalog;

void main() {
  test(
    'gift modal validates replies without saving or writing variables',
    () async {
      const state = GameState(saveId: 'modal');
      final pokemon = giftCatalog().generate(
        consequence: SceneGivePokemonFromCatalogConsequence(
          speciesId: 'clockbird',
          formId: 'bronze',
          level: 7,
        ),
        state: state,
        operationId: 'op',
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      );
      final locks = <bool>[];
      var writes = 0;
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => state,
        commitAndSave: (_) async {
          writes++;
        },
        setInputLocked: locks.add,
        loadRecoveryCaps: (_) async =>
            const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
      );
      addTearDown(controller.dispose);
      final interaction = SceneTextInteractionRequest(
        requestId: 'gift:nickname',
        revision: 8,
        prompt: SceneInteractionPrompt(localizationKey: 'gift'),
        constraints: SceneTextInputConstraints(maxGraphemes: 10),
      );
      final pending = controller.openPokemonGiftInteraction(
        request: OpenPokemonGiftInteractionService(
          interactionId: 'gift:nickname',
          interaction: interaction,
          stage: PokemonGiftInteractionStage.nickname,
          pokemon: pokemon,
          projectedState: state,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final snapshot = controller.worldServiceSnapshot!;
      final stale = await controller.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.confirm,
          snapshotRevision: snapshot.revision,
          interactionResult: SceneInteractionResult.textSubmitted(
            requestId: 'old',
            revision: 8,
            value: 'wrong',
          ),
        ),
      );
      expect(stale.status, RuntimeWorldServiceCommandStatus.stale);
      final reply = SceneInteractionResult.textSubmitted(
        requestId: interaction.requestId,
        revision: interaction.revision,
        value: 'Horloge',
      );
      final accepted = await controller.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.confirm,
          snapshotRevision: snapshot.revision,
          interactionResult: reply,
        ),
      );
      expect(accepted.status, RuntimeWorldServiceCommandStatus.accepted);
      expect(await pending, reply);
      expect(writes, 0);
      expect(state.scriptVariables.values, isEmpty);
      expect(locks, [true, false]);
      expect(controller.worldServiceSnapshot, isNull);
      expect(
        (await controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.confirm,
            snapshotRevision: snapshot.revision,
            interactionResult: reply,
          ),
        )).status,
        RuntimeWorldServiceCommandStatus.unavailable,
      );
    },
  );
}
