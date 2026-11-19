import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('startup failures use known codes and preserve an unknown fallback', () {
    const failure = RuntimeStartupFailure(
      code: 'saveDiscoveryFailed',
      safeMessage: 'Legacy fallback.',
    );
    final english = PokeMapPlayerLocalizations.lookup(const Locale('en'));
    final french = PokeMapPlayerLocalizations.lookup(const Locale('fr'));
    expect(
      localizeRuntimeStartupFailure(failure, english),
      'Saved games could not be checked safely.',
    );
    expect(
      localizeRuntimeStartupFailure(failure, french),
      'Les sauvegardes n’ont pas pu être vérifiées en sécurité.',
    );
    expect(
      localizeRuntimeStartupFailure(
        const RuntimeStartupFailure(
          code: 'futureHostCode',
          safeMessage: 'Host fallback text.',
        ),
        english,
      ),
      'Host fallback text.',
    );
  });

  test(
    'the healing receipt follows the UI locale and survives transport',
    () async {
      var uiLocale = 'en-GB';
      var commits = 0;
      var state = const GameState(
        saveId: 'heal-localization',
        currentMapId: 'clinic',
        playerPosition: GridPos(x: 0, y: 0),
        playerFacing: EntityFacing.south,
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'creature',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 5,
              currentHp: 3,
            ),
          ],
        ),
      );
      final services = PlayerServiceRuntimeController.contextual(
        currentGameState: () => state,
        commitAndSave: (next) async {
          commits++;
          state = next;
        },
        setInputLocked: (_) {},
        loadRecoveryCaps: (_) async =>
            const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 24}),
        locale: 'fr',
        displayLocale: () => uiLocale,
        feedbackLocalizer: localizeRuntimePlayerFeedback,
      );
      addTearDown(services.dispose);

      final opening = services.worldServiceSnapshots.firstWhere(
        (snapshot) => snapshot?.stage == RuntimeWorldServiceStage.active,
      );
      final service = services.openHealCenter(
        request: const OpenHealService(interactionId: 'clinic'),
      );
      final open = (await opening)!;
      expect(
        (open.content as RuntimeHealServiceContent).title,
        'Pokémon Center',
      );

      final unavailable = await services.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.showPurchases,
          snapshotRevision: open.revision,
        ),
      );
      expect(unavailable.status, RuntimeWorldServiceCommandStatus.unavailable);
      expect(unavailable.safeMessage, 'Action unavailable');
      expect(commits, 0);

      final confirm = await services.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.confirm,
          snapshotRevision: open.revision,
        ),
      );
      expect(confirm.status, RuntimeWorldServiceCommandStatus.accepted);
      final receipt = services.worldServiceSnapshot!;
      expect(receipt.stage, RuntimeWorldServiceStage.completed);
      expect(receipt.safeMessage, 'Your party is fully healed.');
      final transported = RuntimeCompanionPresentationCodec.decodeWorldService(
        RuntimeCompanionPresentationCodec.encodeWorldService(receipt),
      );
      expect(transported.safeMessage, receipt.safeMessage);

      uiLocale = 'fr-CA';
      services.refreshPokemonDisplayNames();
      final french = services.worldServiceSnapshot!;
      final content = french.content as RuntimeHealServiceContent;
      expect(content.title, 'Centre Pokémon');
      expect(content.message, 'Le soin est terminé.');
      expect(french.safeMessage, 'Votre équipe est entièrement soignée.');
      expect(state.party.members.single.currentHp, 24);
      expect(commits, 1);

      await services.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.close,
          snapshotRevision: french.revision,
        ),
      );
      expect((await service).status, PlayerServiceRuntimeStatus.completed);
    },
  );

  test(
    'purchase feedback inserts the same quantity and authored item name',
    () {
      const arguments = {'quantity': 3, 'item': 'Miel des Dunes'};
      expect(
        localizeRuntimePlayerFeedback(
          'en',
          RuntimeServiceFeedback.shopPurchaseBonus,
          arguments,
        ),
        'Purchase complete. Bonus: 3 × Miel des Dunes.',
      );
      expect(
        localizeRuntimePlayerFeedback(
          'fr',
          RuntimeServiceFeedback.shopPurchaseBonus,
          arguments,
        ),
        'Achat effectué. Cadeau : 3 × Miel des Dunes.',
      );
    },
  );

  test('a traversal prompt and its move name use the same locale', () {
    for (final (locale, expected) in [
      ('en', 'Would you like to use Whirlpool to cross here?'),
      ('fr', 'Voulez-vous utiliser Tourbillon pour traverser ce passage ?'),
    ]) {
      final move = localizeRuntimePlayerFeedback(
        locale,
        RuntimeOverworldFeedback.fieldMoveWhirlpool,
        const {},
      )!;
      expect(
        localizeRuntimePlayerFeedback(
          locale,
          RuntimeOverworldFeedback.fieldTraversalConfirm,
          {'move': move},
        ),
        expected,
      );
    }
  });
}
