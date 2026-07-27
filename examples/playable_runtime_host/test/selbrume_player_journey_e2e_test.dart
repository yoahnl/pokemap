import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/driver/evaluation_game_fixtures.dart';
import 'package:pokemap_loader/src/evaluation/driver/selbrume_evaluation_driver.dart';

import 'support/selbrume_player_service_test_host.dart';

const Set<String> _oneShotsThroughPortAlert = <String>{
  'evt_019abcde-5000-7000-8000-000000000011',
  'evt_019abcde-4000-7000-8000-000000000002',
};
const Set<String> _oneShotsThroughLysaVictory = <String>{
  ..._oneShotsThroughPortAlert,
  'evt_019abcde-4000-7000-8000-000000000001',
  'evt_019abcde-5000-7000-8000-000000000033',
};
const Set<String> _oneShotsThroughLysaDefeat = <String>{
  ..._oneShotsThroughPortAlert,
  'evt_019abcde-4000-7000-8000-000000000001',
  'evt_019abcde-5000-7000-8000-000000000034',
};
const Set<String> _oneShotsThroughLysaDefeatThenVictory = <String>{
  ..._oneShotsThroughLysaDefeat,
  'evt_019abcde-5000-7000-8000-000000000033',
};
const Set<String> _oneShotsThroughGoeliseKeep = <String>{
  ..._oneShotsThroughLysaVictory,
  'evt_019abcde-5000-7000-8000-000000000020',
  'evt_019abcde-5000-7000-8000-000000000022',
  'evt_019abcde-5000-7000-8000-000000000035',
};
const Set<String> _oneShotsThroughMarsh = <String>{
  ..._oneShotsThroughLysaVictory,
  'evt_019abcde-5000-7000-8000-000000000012',
  'evt_019abcde-4000-7000-8000-000000000003',
  'evt_019abcde-5000-7000-8000-000000000014',
  'evt_019abcde-5000-7000-8000-000000000015',
  'evt_019abcde-5000-7000-8000-000000000017',
  'evt_019abcde-5000-7000-8000-000000000018',
  'evt_019abcde-5000-7000-8000-000000000019',
  'evt_019abcde-5000-7000-8000-000000000032',
};
const Set<String> _oneShotsThroughLighthouseGuardians = <String>{
  ..._oneShotsThroughMarsh,
  'evt_019abcde-5000-7000-8000-000000000016',
  'evt_019abcde-5000-7000-8000-000000000020',
  'evt_019abcde-5000-7000-8000-000000000022',
  'evt_019abcde-5000-7000-8000-000000000021',
  'evt_019abcde-5000-7000-8000-000000000023',
  'evt_019abcde-5000-7000-8000-000000000029',
  'evt_019abcde-5000-7000-8000-000000000030',
  'evt_019abcde-5000-7000-8000-000000000025',
};
const Set<String> _oneShotsThroughBoss = <String>{
  ..._oneShotsThroughLighthouseGuardians,
  // The two guardians and the boss are reusable until their victory Facts
  // become true. Their IDs intentionally never enter the one-shot ledger.
  'evt_019abcde-5000-7000-8000-000000000036',
};
const Set<String> _oneShotsThroughEpilogue = <String>{
  ..._oneShotsThroughBoss,
  'evt_019abcde-5000-7000-8000-000000000031',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FG-182 product journey source excludes forged gameplay shortcuts', () {
    final source = <String>[
      p.join(
        Directory.current.path,
        'test',
        'selbrume_player_journey_e2e_test.dart',
      ),
      p.join(
        Directory.current.path,
        'lib',
        'src',
        'evaluation',
        'driver',
        'selbrume_evaluation_driver.dart',
      ),
    ].map((path) => File(path).readAsStringSync()).join('\n');
    final forbiddenFragments = <String>[
      <String>['_finished', 'Outcome('].join(),
      <String>['GameState', 'Mutations'].join(),
      <String>['.', 'set', 'Flag('].join(),
      <String>['debug', 'Set'].join(),
      <String>['debug', 'Apply'].join(),
      <String>['debug', 'Finish'].join(),
      <String>['setPlayer', 'MovementMode('].join(),
      <String>['setSurfing', 'Enabled('].join(),
    ];

    for (final fragment in forbiddenFragments) {
      expect(
        source,
        isNot(contains(fragment)),
        reason: 'The canonical product journey must not use $fragment.',
      );
    }
  });

  test(
    'checkpoint reload preserves 32px movement through the opened port gate',
    () async {
      final journey = await _SelbrumeJourney.start();

      await journey.interactWith(
        entityId: 'npc_mael',
        dialogue: const _DialogueChoice(linesBeforeChoice: 1),
      );
      await journey.waitForFact('fact_mael_mission_given');
      expect(journey.bagQuantity('poke-ball'), 5);
      await journey.navigateTo(const GridPos(x: 17, y: 24));
      await journey.checkpoint(
        'before_port_regression',
        expectedConsumedEventIds: const <String>{
          'evt_019abcde-5000-7000-8000-000000000011',
        },
      );
      final starterBeforeReentry = journey.state.party.members.single.toJson();
      final oneShotsBeforeReentry = Set<String>.from(
        journey.state.narrativeEventProgress.consumedNarrativeEventIds,
      );
      await journey.interactWith(entityId: 'npc_mael');
      expect(journey.state.party.members, hasLength(1));
      expect(
        journey.state.party.members.single.toJson(),
        starterBeforeReentry,
        reason: 'Re-entering Mael after reload must not replay starter grant.',
      );
      expect(
        journey.state.narrativeEventProgress.consumedNarrativeEventIds,
        oneShotsBeforeReentry,
        reason: 'Re-entry must not consume or replay a new Event Registry ID.',
      );
      expect(
        journey.bagQuantity('poke-ball'),
        5,
        reason: 'Maël must grant the authored capture kit only once.',
      );

      final diagnostic = journey.pathDiagnostic(
        const GridPos(x: 26, y: 54),
        gateEntityId: 'gate_bourg_to_port',
      );
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 26,
      );

      expect(
        journey.state.currentMapId,
        'map_port_brisants',
        reason: diagnostic,
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test('Lysa victory uses a real damaging move and victory branch', () async {
    final journey = await _SelbrumeJourney.start();
    await journey.prepareLysaBattle();
    final moveStart = journey.selectedBattleMoveIds.length;

    await journey.interactWith(
      entityId: 'npc_lysa',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
      battleFactId: 'fact_rival_port_defeated',
      battleStrategy: _BattleStrategy.win,
      expectedTrainerId: 'trainer_lysa_port',
      expectedEnemySpeciesId: 'bulbasaur',
    );

    final victoryMoves = journey.battleMoveChoices.skip(moveStart);
    expect(
      victoryMoves,
      contains(
        isA<_BattleMoveChoiceEvidence>()
            .having((move) => move.power, 'power', greaterThan(0))
            .having(
              (move) => move.effectiveness,
              'effectiveness',
              greaterThan(0),
            ),
      ),
    );
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_rival_port_defeated'],
      isTrue,
    );
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_rival_port_lost_once'],
      isNot(isTrue),
    );
    await journey.checkpoint(
      'lysa_victory',
      expectedConsumedEventIds: _oneShotsThroughLysaVictory,
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('Lysa defeat can be healed, retried, and converted into victory',
      () async {
    final journey = await _SelbrumeJourney.start();
    await journey.prepareLysaBattle();
    final moveStart = journey.selectedBattleMoveIds.length;

    await journey.interactWith(
      entityId: 'npc_lysa',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
      battleFactId: 'fact_rival_port_defeated',
      acceptedDefeatFactId: 'fact_rival_port_lost_once',
      battleStrategy: _BattleStrategy.lose,
      expectedTrainerId: 'trainer_lysa_port',
      expectedEnemySpeciesId: 'bulbasaur',
    );

    final deliberateLossMoves =
        journey.battleMoveChoices.skip(moveStart).toList();
    expect(deliberateLossMoves, isNotEmpty);
    expect(
      deliberateLossMoves.map((move) => move.moveId),
      everyElement('growl'),
    );
    expect(
      deliberateLossMoves.map((move) => move.power),
      everyElement(0),
    );
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_rival_port_lost_once'],
      isTrue,
    );
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_rival_port_defeated'],
      isNot(isTrue),
    );
    await journey.checkpoint(
      'lysa_defeat',
      expectedConsumedEventIds: _oneShotsThroughLysaDefeat,
    );

    await journey.useAuthoredHealingService();
    await journey.interactWith(
      entityId: 'npc_lysa',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
      battleFactId: 'fact_rival_port_defeated',
      battleStrategy: _BattleStrategy.win,
      expectedTrainerId: 'trainer_lysa_port',
      expectedEnemySpeciesId: 'bulbasaur',
    );
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_rival_port_lost_once'],
      isTrue,
    );
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_rival_port_defeated'],
      isTrue,
    );
    expect(
      journey.state.trainerProfile.badgeIds,
      contains('badge_brisants'),
    );
    expect(
      journey.state.progression.unlockedFieldAbilities,
      contains(FieldAbility.surf),
    );
    await journey.checkpoint(
      'lysa_retry_victory',
      expectedConsumedEventIds: _oneShotsThroughLysaDefeatThenVictory,
    );
    await journey.crossConnection(MapConnectionDirection.north);
    await journey.crossConnection(
      MapConnectionDirection.east,
      preferredAxis: 22,
    );
    await journey.crossConnection(
      MapConnectionDirection.east,
      preferredAxis: 22,
    );
    await journey.enterTrigger('zone_marais_entry');
    await journey.waitForFact('fact_marais_unlocked');
    expect(journey.state.currentMapId, 'map_marais_salants');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'player completes Selbrume through PlayableMapGame production hooks',
    () async {
      final journey = await _SelbrumeJourney.start();
      journey.completeWalkthroughStep('new_game');

      await journey.interactWith(
        entityId: 'npc_mael',
        dialogue: const _DialogueChoice(
          linesBeforeChoice: 1,
          choiceIndex: 2,
        ),
      );
      await journey.waitForFact('fact_mael_mission_given');
      journey.expectStarterMatchesAuthoredOption('starter_squirtle');
      expect(journey.bagQuantity('poke-ball'), 5);
      journey.completeWalkthroughStep('starter_and_capture_kit');
      await journey.navigateTo(const GridPos(x: 17, y: 24));
      await journey.checkpoint(
        'before_port',
        expectedConsumedEventIds: const <String>{
          'evt_019abcde-5000-7000-8000-000000000011',
        },
      );

      final bourgPortPathDiagnostic = journey.pathDiagnostic(
        const GridPos(x: 26, y: 54),
        gateEntityId: 'gate_bourg_to_port',
      );
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 26,
      );
      expect(journey.state.currentMapId, 'map_port_brisants',
          reason: bourgPortPathDiagnostic);
      await journey.enterTrigger(
        'zone_port_entry',
        dialogue: const _DialogueChoice(
          linesBeforeChoice: 2,
          choiceIndex: 1,
        ),
      );
      await journey.waitForFact('fact_port_alert_seen');
      expect(journey.state.currentMapId, 'map_port_brisants');
      journey.completeWalkthroughStep('port_alert');

      await journey.attemptPortSurfGate(expectTraversal: false);
      journey.completeWalkthroughStep('surf_refused_before_unlock');

      await journey.purchaseAtPort(
        'poke-ball',
        expectedStateId: ShopStateResolver.defaultStateId,
        expectedCatalogue: const <String, int>{
          'potion': 300,
          'poke-ball': 200,
        },
      );

      final starterBeforeLysa = journey.state.party.members.first;
      expect(starterBeforeLysa.speciesId, 'squirtle');
      final starterExperienceBeforeLysa = starterBeforeLysa.experience;
      expect(starterExperienceBeforeLysa, isNotNull);
      final movesBeforeLysa = journey.selectedBattleMoveIds.length;
      await journey.interactWith(
        entityId: 'npc_lysa',
        dialogue: const _DialogueChoice(linesBeforeChoice: 2),
        battleFactId: 'fact_rival_port_defeated',
        expectedTrainerId: 'trainer_lysa_port',
        expectedEnemySpeciesId: 'bulbasaur',
      );
      expect(
        journey.state.progression.completedStepIds,
        contains('step_rival_battle'),
      );
      final starterAfterLysa = journey.state.party.members.first;
      expect(starterAfterLysa.experience,
          greaterThan(starterExperienceBeforeLysa!));
      expect(starterAfterLysa.level, greaterThan(starterBeforeLysa.level));
      expect(
        starterAfterLysa.speciesId,
        'wartortle',
        reason: 'The real post-battle queue must apply the level 16 evolution.',
      );
      expect(
        starterAfterLysa.knownMoveIds,
        contains('bite'),
        reason: 'The product journey must learn a move through the real '
            'post-battle level-up queue.',
      );
      expect(
        journey.battleMoveChoices.skip(movesBeforeLysa),
        contains(
          isA<_BattleMoveChoiceEvidence>()
              .having((move) => move.power, 'power', greaterThan(0))
              .having(
                (move) => move.effectiveness,
                'effectiveness',
                greaterThan(0),
              ),
        ),
        reason: 'Lysa must be beaten with a damaging, non-immune move '
            'selected in the UI.',
      );
      journey.completeWalkthroughStep('lysa_victory');
      expect(
        journey.state.trainerProfile.badgeIds,
        contains('badge_brisants'),
      );
      expect(
        journey.state.progression.unlockedFieldAbilities,
        contains(FieldAbility.surf),
      );
      journey.completeWalkthroughStep('badge_and_surf_unlocked');

      const afterLysaCatalogue = <String, int>{
        'potion': 250,
        'poke-ball': 200,
        'antidote': 100,
      };
      await journey.purchaseAtPort(
        'potion',
        expectedStateId: 'after-lysa',
        expectedCatalogue: afterLysaCatalogue,
      );
      expect(
        journey.playerServices.openedServices
            .where((service) => service == 'shop:shop_port_supplies'),
        hasLength(2),
      );
      journey.completeWalkthroughStep('shop_used');

      await journey.useAuthoredHealingService();
      journey.completeWalkthroughStep('healing_service_used');

      await journey.checkpoint(
        'after_lysa',
        expectedConsumedEventIds: _oneShotsThroughLysaVictory,
      );
      await journey.inspectPortShop(
        expectedStateId: 'after-lysa',
        expectedCatalogue: afterLysaCatalogue,
      );
      expect(
        journey.state.progression
            .shopPurchaseCounts['shop_port_supplies::after-lysa::potion'],
        1,
        reason: 'The after-Lysa stock ledger must survive save/load.',
      );
      await journey.expectInactiveTriggerDoesNotReplay('zone_port_entry');

      await journey.crossConnection(MapConnectionDirection.north);
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 22,
      );
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 22,
      );
      await journey.enterTrigger('zone_marais_entry');
      await journey.waitForFact('fact_marais_unlocked');

      expect(
        await journey.captureWildPokemon(),
        CaptureDestinationKind.party,
      );
      expect(
        journey.state.progression.caughtSpeciesIds,
        contains('pidgeotto'),
      );
      journey.completeWalkthroughStep('first_wild_capture');
      for (var capture = 0; capture < 4; capture++) {
        expect(
          await journey.captureWildPokemon(),
          CaptureDestinationKind.party,
        );
      }
      expect(journey.state.party.members, hasLength(maxPlayerPartySize));
      journey.completeWalkthroughStep('party_filled_by_captures');
      expect(
        await journey.captureWildPokemon(),
        CaptureDestinationKind.storage,
      );
      expect(
        journey.state.pokemonStorage.boxes.expand((box) => box.pokemon),
        isNotEmpty,
      );
      journey.completeWalkthroughStep('capture_sent_to_storage');

      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 39,
      );
      await journey.withdrawCapturedPokemonFromPc();
      journey.completeWalkthroughStep('pc_withdrawal');
      await journey.crossConnection(MapConnectionDirection.north);
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 22,
      );
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 22,
      );

      await journey.interactWith(
        entityId: 'npc_mado',
        dialogue: const _DialogueChoice(linesBeforeChoice: 2),
      );
      await journey.waitForFact('fact_crystals_quest_started');

      await journey.interactWith(entityId: 'clue_glass_object');
      await journey.waitForFact('fact_clue_glass_found');
      await journey.enterTrigger('tr_marais_indice_traces_electriques');
      await journey.waitForFact('fact_clue_electric_tracks_found');
      await journey.enterTrigger('tr_marais_indice_repere_lentille');
      await journey.waitForFact('fact_clue_lighthouse_mark_found');

      await journey.enterTrigger('tr_marais_cristal_1');
      await journey.waitForFact('fact_crystal_1_found');
      await journey.enterTrigger('tr_marais_cristal_2');
      await journey.waitForFact('fact_crystal_2_found');
      await journey.enterTrigger('tr_marais_cristal_3');
      await journey.waitForFact('fact_crystal_3_found');
      await journey.interactWith(entityId: 'npc_mado');
      await journey.waitForFact('fact_crystals_quest_completed');
      expect(
        journey.state.bag.entries,
        contains(
          const BagEntry(
            itemId: 'super-potion',
            categoryId: 'medicine',
            quantity: 1,
          ),
        ),
      );
      await journey.checkpoint(
        'after_marsh',
        expectedConsumedEventIds: _oneShotsThroughMarsh,
      );
      journey.completeWalkthroughStep('marsh_investigation');

      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 39,
      );
      await journey.interactWith(entityId: 'npc_soline');
      await journey.waitForFact('fact_passage_dames_unlocked');

      await journey.interactWith(entityId: 'npc_pecheur');
      await journey.waitForFact('fact_goelise_quest_started');
      await journey.enterTrigger(
        'tr_port_nest',
        dialogue: const _DialogueChoice(linesBeforeChoice: 1),
      );
      await journey.waitForFact('fact_goelise_object_returned');
      final moneyBeforeReward = journey.state.trainerProfile.money;
      await journey.interactWith(entityId: 'npc_pecheur');
      await journey.waitForFact('fact_goelise_quest_completed');
      expect(journey.state.trainerProfile.money, moneyBeforeReward + 300);
      expect(
        journey.state.narrativeFactRuntimeState
            .overridesByFactId['fact_goelise_object_kept'],
        isNot(isTrue),
      );
      expect(
        journey.state.bag.entries.map((entry) => entry.itemId),
        isNot(contains('pearl')),
      );

      await journey.attemptPortSurfGate(expectTraversal: true);
      journey.completeWalkthroughStep('surf_gate_crossed');

      await journey.crossConnection(MapConnectionDirection.north);
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 28,
      );
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 28,
      );
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 28,
      );
      journey.expectSurfMode('while crossing the Passage des Dames channel');
      await journey.crossConnection(
        MapConnectionDirection.east,
        preferredAxis: 10,
      );
      await journey.enterTrigger('zone_lighthouse_entry');
      await journey.waitForFact('fact_lighthouse_reached');

      await journey.interactWith(entityId: 'npc_yvon');
      await journey.waitForFact('fact_cabin_quest_started');
      await journey.enterTrigger('tr_cabin_key_outside');
      await journey.waitForFact('fact_cabin_key_found');
      await journey.enterWarp('warp_phare_ext_to_cabane');
      expect(journey.state.currentMapId, 'map_cabane_gardien');
      await journey.enterTrigger('tr_cabane_journal');
      await journey.waitForFact('fact_cabin_quest_completed');
      expect(
        journey.state.bag.entries.map((entry) => entry.itemId),
        containsAll(<String>['basement-key', 'rare-candy']),
      );
      await journey.enterWarp('warp_cabane_to_phare_exterieur');

      await journey.enterWarp('warp_phare_ext_to_interieur');
      await journey.enterTrigger('tr_phare_note');
      await journey.waitForFact('fact_lighthouse_old_note_read');
      await journey.enterTrigger(
        'tr_phare_guardian_1',
        battleFactId: 'fact_lighthouse_guardian_1_defeated',
        expectedTrainerId: 'trainer_phare_gardien_1',
        expectedEnemySpeciesId: 'magnemite',
      );
      await journey.enterTrigger(
        'tr_phare_guardian_2',
        battleFactId: 'fact_lighthouse_guardian_2_defeated',
        expectedTrainerId: 'trainer_phare_gardien_2',
        expectedEnemySpeciesId: 'gastly',
      );
      expect(
        journey.state.progression.completedStepIds,
        contains('step_climb_lighthouse'),
      );
      await journey.enterWarp('warp_phare_interieur_to_sommet');
      await journey.checkpoint(
        'before_boss',
        expectedConsumedEventIds: _oneShotsThroughLighthouseGuardians,
      );

      await journey.enterTrigger(
        'tr_sommet_confrontation',
        battleFactId: 'fact_mist_source_resolved',
        expectStaticBattle: true,
      );
      await journey.waitForFact('fact_mist_source_resolved');
      await journey.checkpoint(
        'after_boss',
        expectedConsumedEventIds: _oneShotsThroughBoss,
      );
      journey.completeWalkthroughStep('lighthouse_completed');
      journey.completeWalkthroughStep('save_reload_mid_journey');
      expect(
        journey.isEntityVisible('map_sommet_phare', 'fog_sommet'),
        isFalse,
      );
      expect(
        journey.isEntityVisible(
          'map_sommet_phare',
          'boss_phare_pokemon',
        ),
        isFalse,
      );
      await journey.expectInactiveTriggerDoesNotReplay(
        'tr_sommet_confrontation',
      );

      await journey.enterWarp('warp_sommet_to_phare_interieur');
      await journey.enterWarp('warp_phare_interieur_to_exterieur');
      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(MapConnectionDirection.north);
      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(MapConnectionDirection.west);
      await journey.crossConnection(
        MapConnectionDirection.south,
        preferredAxis: 24,
      );
      journey.expectResolvedPortShop(
        expectedStateId: 'lighthouse-alert',
        expectedCatalogue: const <String, int>{},
        expectedOpen: false,
        expectedMessage: 'Le comptoir reste fermé pendant l’alerte du phare.',
      );
      await journey.enterTrigger('zone_port_center');
      await journey.waitForFact('fact_main_story_completed');
      await journey.waitForGameCompletion();
      expect(journey.gameCompletionRequests, hasLength(1));
      final completion = journey.gameCompletionRequests.single;
      expect(completion.endingId, 'ending.selbrume-sauvee');
      expect(completion.outcome, GameCompletionOutcome.victory);
      expect(completion.result.title, 'Selbrume est sauvée');
      expect(
        completion.result.summary,
        'La lumière du phare traverse de nouveau la brume et les habitants '
        'reprennent la mer.',
      );
      expect(completion.credits.title, 'Crédits — Selbrume');
      expect(completion.credits.author, 'Selbrume');
      expect(
        completion.credits.endingLabel,
        'Fin principale — Selbrume sauvée',
      );
      expect(completion.credits.skippable, isTrue);
      expect(completion.destination, GameCompletionDestination.hub);
      expect(completion.allowPostGameContinue, isFalse);
      await journey.purchaseAtPort(
        'poke-ball',
        expectedStateId: 'story-finished',
        expectedCatalogue: const <String, int>{
          'potion': 200,
          'super-potion': 700,
          'poke-ball': 150,
        },
      );
      await journey.checkpoint(
        'after_epilogue',
        expectedConsumedEventIds: _oneShotsThroughEpilogue,
      );
      journey.completeWalkthroughStep('epilogue_reached');
      for (final fog in const <(String, String)>[
        ('map_port_brisants', 'fog_port'),
        ('map_marais_salants', 'fog_marais'),
        ('map_passage_dames', 'fog_passage'),
        ('map_phare_exterieur', 'fog_phare'),
      ]) {
        expect(
          journey.isEntityVisible(fog.$1, fog.$2),
          isFalse,
          reason: '${fog.$2} must remain hidden after serialized reload.',
        );
      }
      expect(
        journey.isEntityVisible(
          'map_port_brisants',
          'goelise_nest_proxy',
        ),
        isFalse,
      );

      expect(
        journey.state.progression.completedStepIds,
        containsAll(<String>[
          'step_intro_selbrume',
          'step_rival_battle',
          'step_find_three_clues',
          'step_climb_lighthouse',
          'step_final_confrontation',
          'step_main_story_completed',
          'step_crystals_completed',
          'step_goelise_completed',
          'step_cabin_completed',
        ]),
      );
      expect(journey.savedCheckpointNames, <String>[
        'before_port',
        'after_lysa',
        'after_marsh',
        'before_boss',
        'after_boss',
        'after_epilogue',
      ]);
      journey.expectWalkthroughComplete();
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test('Goelise keep choice reaches its authored alternative reward', () async {
    final journey = await _SelbrumeJourney.start();
    await journey.interactWith(
      entityId: 'npc_mael',
      dialogue: const _DialogueChoice(linesBeforeChoice: 1, choiceIndex: 1),
    );
    await journey.waitForFact('fact_mael_mission_given');
    await journey.crossConnection(
      MapConnectionDirection.south,
      preferredAxis: 26,
    );
    await journey.enterTrigger(
      'zone_port_entry',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
    );
    await journey.waitForFact('fact_port_alert_seen');
    await journey.interactWith(
      entityId: 'npc_lysa',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
      battleFactId: 'fact_rival_port_defeated',
      expectedTrainerId: 'trainer_lysa_port',
      expectedEnemySpeciesId: 'bulbasaur',
    );
    await journey.interactWith(entityId: 'npc_pecheur');
    await journey.waitForFact('fact_goelise_quest_started');
    await journey.enterTrigger(
      'tr_port_nest',
      dialogue: const _DialogueChoice(linesBeforeChoice: 1, choiceIndex: 1),
    );
    await journey.waitForFact('fact_goelise_object_kept');
    final moneyBeforeKeepReward = journey.state.trainerProfile.money;
    await journey.interactWith(entityId: 'npc_pecheur');
    await journey.waitForFact('fact_goelise_quest_completed');

    expect(
      journey.state.bag.entries.map((entry) => entry.itemId),
      contains('pearl'),
    );
    expect(journey.state.trainerProfile.money, moneyBeforeKeepReward);
    expect(
      journey.state.narrativeFactRuntimeState
          .overridesByFactId['fact_goelise_object_returned'],
      isNot(isTrue),
    );
    await journey.checkpoint(
      'goelise_keep',
      expectedConsumedEventIds: _oneShotsThroughGoeliseKeep,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}

final class _SelbrumeJourney {
  _SelbrumeJourney._({
    required this.game,
    required this.project,
    required this.projectRoot,
    required this.playerServices,
    required this.gameCompletionRequests,
    required this.expectedWalkthroughStepIds,
  });

  final EvaluationPlayableMapGame game;
  final ProjectManifest project;
  final Directory projectRoot;
  final SelbrumePlayerServiceTestHost playerServices;
  final List<GameCompletionRequest> gameCompletionRequests;
  final List<String> expectedWalkthroughStepIds;
  final List<String> completedWalkthroughStepIds = <String>[];
  final Map<String, MapData> _mapsById = <String, MapData>{};
  final Map<String, Set<String>> _runtimeRejectedEdgesByMapId =
      <String, Set<String>>{};
  final List<String> savedCheckpointNames = <String>[];
  final List<_BattleMoveChoiceEvidence> battleMoveChoices =
      <_BattleMoveChoiceEvidence>[];

  GameState get state => game.gameStateSnapshot;

  int bagQuantity(String itemId) => state.bag.entries
      .where((entry) => entry.itemId == itemId)
      .fold(0, (total, entry) => total + entry.quantity);
  List<String> get selectedBattleMoveIds =>
      battleMoveChoices.map((choice) => choice.moveId).toList(growable: false);

  void expectStarterMatchesAuthoredOption(String optionId) {
    final authoredStarter = project.newGame.starterOptions
        .singleWhere((option) => option.id == optionId)
        .pokemon;
    final hydratedStarter = state.party.members.single;
    final expectedProvenance = PlayerPokemonProvenance(
      kind: PlayerPokemonOriginKind.starter,
      mapId: state.currentMapId,
      sourceId: optionId,
      metLevel: authoredStarter.level,
    );
    expect(hydratedStarter.provenance, expectedProvenance);
    expect(
      hydratedStarter.copyWith(
        experience: authoredStarter.experience,
        currentPpByMoveId: authoredStarter.currentPpByMoveId,
      ),
      authoredStarter.copyWith(provenance: expectedProvenance),
      reason: 'The Scene starter grant must consume the complete project-owned '
          'New Game option (HP, moves, nature, ability and level), not rebuild '
          'a partial Pokemon from the Scene consequence.',
    );
    expect(hydratedStarter.experience, isNotNull);
    expect(hydratedStarter.currentPpByMoveId, isNotNull);
  }

  String pathDiagnostic(GridPos target, {required String gateEntityId}) {
    final map = _currentMap;
    final projection = const RuntimeWorldRuleProjectionHook().resolve(
      project: project,
      gameState: state,
      map: map,
    );
    final world = _pathfindingWorld(map);
    final reason = world.movementBlockReasonAt(
      x: target.x,
      y: target.y,
      movementMode: state.playerMovementMode,
    );
    return 'map=${map.id}, from=${game.debugPlayerGridPosition}, '
        'mission=${state.narrativeFactRuntimeState.overridesByFactId['fact_mael_mission_given']}, '
        'gateHidden=${projection.hiddenEntityIds.contains(gateEntityId)}, '
        'targetBlock=${reason?.name}, '
        'gridReachable=${_hasGridPath(world, target)}, '
        'physicalPathLength=${_findPath(target, avoidEncounters: false)?.length}';
  }

  static Future<_SelbrumeJourney> start() async {
    final repositoryRoot = _findRepositoryRoot();
    final projectRoot = Directory(p.join(repositoryRoot.path, 'selbrume'));
    final driver = await SelbrumeEvaluationDriver.start(
      projectRoot: projectRoot,
      runId: 'fg-182-canonical-journey',
    );
    final game = driver.headlessGame;
    final playerServices = driver.headlessPlayerServices;
    final walkthrough = jsonDecode(
      File(p.join(projectRoot.path, 'walkthrough.json')).readAsStringSync(),
    ) as Map<String, dynamic>;
    final expectedWalkthroughStepIds = (walkthrough['steps'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((step) => step['id'] as String)
        .toList(growable: false);
    final journey = _SelbrumeJourney._(
      game: game,
      project: driver.project,
      projectRoot: projectRoot,
      playerServices: playerServices,
      gameCompletionRequests: driver.gameCompletionRequests,
      expectedWalkthroughStepIds: expectedWalkthroughStepIds,
    );
    expect(journey.state.currentMapId, 'map_bourg_selbrume');
    expect(journey.state.party.members, isEmpty);
    return journey;
  }

  void completeWalkthroughStep(String stepId) {
    final index = completedWalkthroughStepIds.length;
    expect(index, lessThan(expectedWalkthroughStepIds.length));
    expect(
      stepId,
      expectedWalkthroughStepIds[index],
      reason: 'Le walkthrough produit doit être exécuté strictement dans '
          'l’ordre authoré.',
    );
    completedWalkthroughStepIds.add(stepId);
  }

  void expectWalkthroughComplete() {
    expect(completedWalkthroughStepIds, expectedWalkthroughStepIds);
  }

  void expectSurfMode(String stage) {
    expect(
      state.playerMovementMode,
      MovementMode.surf,
      reason: 'The unlocked Surf traversal mode must survive $stage.',
    );
  }

  Future<void> checkpoint(
    String name, {
    required Set<String> expectedConsumedEventIds,
  }) async {
    expect(await game.saveGame(), isTrue, reason: 'save checkpoint $name');
    final before = SaveData.fromJson(
      saveDataFromGameState(state).toJson(),
    );
    final consumedBefore = Set<String>.from(
      state.narrativeEventProgress.consumedNarrativeEventIds,
    );
    final resetTokensBefore = List<String>.from(
      state.narrativeEventProgress.appliedNarrativeResetTokens,
    );
    expect(
      consumedBefore,
      unorderedEquals(expectedConsumedEventIds),
      reason: 'The exact Event Registry one-shot set must match before '
          'checkpoint $name.',
    );
    expect(await game.loadGame(), isTrue, reason: 'load checkpoint $name');
    await _pumpUntil(
      () =>
          !game.debugIsLoadActivationWorkInFlight &&
          !game.debugIsMapActivationDispatchInFlight,
      label: 'reload checkpoint $name',
    );
    final after = saveDataFromGameState(state);
    expect(
      _withoutInternalResetTokens(after.toJson()),
      _withoutInternalResetTokens(before.toJson()),
      reason: 'Reload must preserve gameplay state at checkpoint $name. '
          'The per-activation idempotency token is compared separately.',
    );
    final resetTokensAfter =
        state.narrativeEventProgress.appliedNarrativeResetTokens;
    expect(
      resetTokensAfter.take(resetTokensBefore.length),
      resetTokensBefore,
      reason: 'Reload must preserve the existing reset ledger.',
    );
    expect(
      resetTokensAfter.length,
      inInclusiveRange(resetTokensBefore.length, resetTokensBefore.length + 1),
      reason:
          'A save restore may append at most its single map activation token.',
    );
    if (resetTokensAfter.length > resetTokensBefore.length) {
      expect(resetTokensAfter.last, startsWith('map:mapact_'));
    }
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      consumedBefore,
      reason: 'One-shot consumption must survive checkpoint $name.',
    );
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      unorderedEquals(expectedConsumedEventIds),
      reason: 'The exact Event Registry one-shot set must match after '
          'checkpoint $name.',
    );
    savedCheckpointNames.add(name);
  }

  Future<void> waitForFact(String factId) async {
    await _settleUntil(
      () => state.narrativeFactRuntimeState.overridesByFactId[factId] == true,
      label: 'Fact $factId',
    );
  }

  Future<void> waitForGameCompletion() async {
    await _settleUntil(
      () => gameCompletionRequests.isNotEmpty,
      label: 'Game completion request',
    );
  }

  bool isEntityVisible(String mapId, String entityId) {
    final map = _mapById(mapId);
    final entity = map.entities.singleWhere((entry) => entry.id == entityId);
    final projection = const RuntimeWorldRuleProjectionHook().resolve(
      project: project,
      gameState: state,
      map: map,
    );
    return projection.isMapEntityVisible(entity);
  }

  Future<void> expectInactiveTriggerDoesNotReplay(String triggerId) async {
    final trigger = _currentMap.triggers.singleWhere(
      (entry) => entry.id == triggerId,
    );
    final consumedBefore = Set<String>.from(
      state.narrativeEventProgress.consumedNarrativeEventIds,
    );
    if (_contains(trigger.area, game.debugPlayerGridPosition)) {
      await navigateTo(_reachableCellOutsideArea(trigger.area));
    }
    await navigateTo(_reachableCellInArea(trigger.area));
    await _pumpUntil(
      () =>
          !game.debugIsNarrativeSpatialDispatchInFlight &&
          !game.debugIsNarrativeOutcomeWorkInFlight,
      label: 'inactive trigger $triggerId skip',
      maxTicks: 1000,
    );
    expect(
      game.debugFlowPhaseName,
      'overworld',
      reason: 'Inactive trigger $triggerId must not replay authored flow.',
    );
    expect(game.debugPendingBattleRequest, isNull);
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      consumedBefore,
    );
  }

  Future<void> prepareLysaBattle() async {
    await interactWith(
      entityId: 'npc_mael',
      dialogue: const _DialogueChoice(linesBeforeChoice: 1, choiceIndex: 1),
    );
    await waitForFact('fact_mael_mission_given');
    await crossConnection(
      MapConnectionDirection.south,
      preferredAxis: 26,
    );
    await enterTrigger(
      'zone_port_entry',
      dialogue: const _DialogueChoice(linesBeforeChoice: 2),
    );
    await waitForFact('fact_port_alert_seen');
  }

  Future<void> purchaseAtPort(
    String itemId, {
    required String expectedStateId,
    required Map<String, int> expectedCatalogue,
  }) async {
    final before = bagQuantity(itemId);
    final moneyBefore = state.trainerProfile.money;
    final requestCountBefore = playerServices.shopRequests.length;
    final stockKey = expectedStateId == ShopStateResolver.defaultStateId
        ? 'shop_port_supplies::$itemId'
        : 'shop_port_supplies::$expectedStateId::$itemId';
    final stockBefore = state.progression.shopPurchaseCounts[stockKey] ?? 0;
    playerServices.queueShopPurchase(itemId);
    await interactWith(entityId: 'service_port_shop');
    expect(playerServices.shopRequests, hasLength(requestCountBefore + 1));
    final request = playerServices.shopRequests.last;
    _expectResolvedPortShop(
      request,
      expectedStateId: expectedStateId,
      expectedCatalogue: expectedCatalogue,
      expectedOpen: true,
    );
    expect(bagQuantity(itemId), before + 1);
    expect(
      state.trainerProfile.money,
      moneyBefore - expectedCatalogue[itemId]!,
    );
    expect(
      state.progression.shopPurchaseCounts[stockKey],
      stockBefore + 1,
    );
    expect(playerServices.purchasedItemIds.last, itemId);
  }

  Future<void> inspectPortShop({
    required String expectedStateId,
    required Map<String, int> expectedCatalogue,
    bool expectedOpen = true,
    String? expectedMessage,
  }) async {
    final moneyBefore = state.trainerProfile.money;
    final bagBefore = state.bag.toJson();
    final stockBefore =
        Map<String, int>.from(state.progression.shopPurchaseCounts);
    final factsBefore = state.narrativeFactRuntimeState.toJson();
    final requestCountBefore = playerServices.shopRequests.length;
    await interactWith(entityId: 'service_port_shop');
    expect(playerServices.shopRequests, hasLength(requestCountBefore + 1));
    _expectResolvedPortShop(
      playerServices.shopRequests.last,
      expectedStateId: expectedStateId,
      expectedCatalogue: expectedCatalogue,
      expectedOpen: expectedOpen,
      expectedMessage: expectedMessage,
    );
    expect(state.trainerProfile.money, moneyBefore);
    expect(state.bag.toJson(), bagBefore);
    expect(state.progression.shopPurchaseCounts, stockBefore);
    expect(state.narrativeFactRuntimeState.toJson(), factsBefore);
  }

  void expectResolvedPortShop({
    required String expectedStateId,
    required Map<String, int> expectedCatalogue,
    required bool expectedOpen,
    String? expectedMessage,
  }) {
    final shop = project.shops.singleWhere(
      (candidate) => candidate.id == 'shop_port_supplies',
    );
    final resolved = const ShopStateResolver().resolve(
      shop: shop,
      gameState: state,
      conditionContext: ScriptEvaluationContext(
        narrativeFactResolver:
            NarrativeFactRuntimeResolver.fromFacts(project.facts),
      ),
    );
    expect(resolved.stateId, expectedStateId);
    expect(resolved.isOpen, expectedOpen);
    if (expectedMessage != null) expect(resolved.message, expectedMessage);
    expect(
      <String, int>{
        for (final entry in resolved.entries) entry.itemId: entry.price,
      },
      expectedCatalogue,
    );
  }

  void _expectResolvedPortShop(
    PlayerServiceShopRequest request, {
    required String expectedStateId,
    required Map<String, int> expectedCatalogue,
    required bool expectedOpen,
    String? expectedMessage,
  }) {
    expect(request.shop.id, 'shop_port_supplies');
    expect(request.resolvedState.stateId, expectedStateId);
    expect(request.resolvedState.isOpen, expectedOpen);
    if (expectedMessage != null) {
      expect(request.resolvedState.message, expectedMessage);
    }
    expect(
      <String, int>{
        for (final entry in request.resolvedState.entries)
          entry.itemId: entry.price,
      },
      expectedCatalogue,
    );
  }

  Future<void> useAuthoredHealingService() async {
    final before = state.party.members
        .map((pokemon) => pokemon.currentHp)
        .toList(growable: false);
    await interactWith(entityId: 'service_port_healing');
    final after = state.party.members
        .map((pokemon) => pokemon.currentHp)
        .toList(growable: false);
    expect(after.length, before.length);
    for (var index = 0; index < after.length; index++) {
      expect(after[index], greaterThanOrEqualTo(before[index]));
    }
    expect(
      Iterable<int>.generate(after.length).any(
        (index) => after[index] > before[index],
      ),
      isTrue,
      reason: 'Le poste de soins doit réparer les dégâts du combat contre '
          'Lysa, pas seulement ouvrir une Scene sans effet.',
    );
  }

  Future<void> attemptPortSurfGate({required bool expectTraversal}) async {
    final zone = _currentMap.gameplayZones.singleWhere(
      (candidate) => candidate.id == 'zone_port_surf_training',
    );
    await _attemptSurfGateAt(
      target: zone.area.pos,
      expectTraversal: expectTraversal,
    );
  }

  Future<void> _attemptSurfGateAt({
    required GridPos target,
    required bool expectTraversal,
  }) async {
    final approach = _reachableGateApproach(target);
    await navigateTo(approach.position);
    final before = game.debugPlayerGridPosition;
    await _tapMovement(_controlForDirection(approach.facing));
    await _pumpUntil(
      () => game.debugFlowPhaseName == 'dialogue',
      label: 'Surf gate dialogue',
    );
    await completeOpenDialogue(
      expectTraversal
          ? const _DialogueChoice(linesBeforeChoice: 0)
          : const _DialogueChoice(),
    );
    await _settleUntil(
      () => game.debugFlowPhaseName == 'overworld',
      label: 'Surf gate dialogue completion',
    );
    if (!expectTraversal) {
      expect(game.debugPlayerGridPosition, before);
      expect(state.playerMovementMode, MovementMode.walk);
      return;
    }
    expect(state.playerMovementMode, MovementMode.surf);
    await _tapMovement(_controlForDirection(approach.facing));
    expect(game.debugPlayerGridPosition, target);
  }

  Future<CaptureDestinationKind> captureWildPokemon() async {
    final zone = _currentMap.gameplayZones.firstWhere(
      (candidate) => candidate.kind == GameplayZoneKind.encounter,
    );
    if (_contains(zone.area, game.debugPlayerGridPosition)) {
      await navigateTo(_reachableCellOutsideArea(zone.area));
    }
    final partyBefore = state.party.members.length;
    final storageBefore =
        state.pokemonStorage.boxes.expand((box) => box.pokemon).length;
    final ballsBefore = bagQuantity('poke-ball');
    await navigateTo(
      _reachableCellInArea(zone.area),
      deferBattleInArea: zone.area,
    );
    await _driveRealBattle(
      expectStaticBattle: false,
      strategy: _BattleStrategy.capture,
      expectedEnemySpeciesId: 'pidgeotto',
    );
    await _settleUntil(
      () => game.debugFlowPhaseName == 'overworld',
      label: 'wild capture completion',
    );
    expect(bagQuantity('poke-ball'), ballsBefore - 1);
    final partyAfter = state.party.members.length;
    final storageAfter =
        state.pokemonStorage.boxes.expand((box) => box.pokemon).length;
    if (partyAfter == partyBefore + 1) {
      expect(storageAfter, storageBefore);
      return CaptureDestinationKind.party;
    }
    expect(partyAfter, partyBefore);
    expect(storageAfter, storageBefore + 1);
    return CaptureDestinationKind.storage;
  }

  Future<void> withdrawCapturedPokemonFromPc() async {
    final storedBefore = state.pokemonStorage.boxes
        .expand((box) => box.pokemon)
        .map((pokemon) => pokemon.speciesId)
        .toList(growable: false);
    expect(storedBefore, isNotEmpty);
    playerServices.queueCapturedPokemonWithdrawal();
    await interactWith(entityId: 'service_port_pc');
    expect(state.party.members, hasLength(maxPlayerPartySize));
    expect(
      state.party.members.map((pokemon) => pokemon.speciesId),
      contains(playerServices.withdrawnSpeciesId),
    );
  }

  Future<void> interactWith({
    required String entityId,
    _DialogueChoice? dialogue,
    String? battleFactId,
    String? acceptedDefeatFactId,
    _BattleStrategy battleStrategy = _BattleStrategy.win,
    String? expectedTrainerId,
    String? expectedEnemySpeciesId,
  }) async {
    final map = _currentMap;
    final entity = map.entities.singleWhere((entry) => entry.id == entityId);
    final approach = _shortestReachableApproach(entity);
    await navigateTo(approach.stagingPosition);
    await _tapMovement(_controlForDirection(approach.facing));
    // The final one-cell approach is intentionally outside navigateTo(). It
    // can still cross encounter terrain, so drain that production battle
    // before asserting that the interaction input belongs to the NPC.
    await _resolveIncidentalEncounterIfNeeded();
    expect(game.debugPlayerGridPosition, approach.position);
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await _handleAuthoredFlow(
      sourceLabel: 'entity $entityId',
      dialogue: dialogue,
      battleFactId: battleFactId,
      acceptedDefeatFactId: acceptedDefeatFactId,
      battleStrategy: battleStrategy,
      expectedTrainerId: expectedTrainerId,
      expectedEnemySpeciesId: expectedEnemySpeciesId,
    );
  }

  Future<void> enterTrigger(
    String triggerId, {
    _DialogueChoice? dialogue,
    String? battleFactId,
    bool expectStaticBattle = false,
    _BattleStrategy battleStrategy = _BattleStrategy.win,
    String? expectedTrainerId,
    String? expectedEnemySpeciesId,
  }) async {
    final trigger = _currentMap.triggers.singleWhere(
      (entry) => entry.id == triggerId,
    );
    if (_contains(trigger.area, game.debugPlayerGridPosition)) {
      await navigateTo(_reachableCellOutsideArea(trigger.area));
    }
    final target = _reachableCellInArea(trigger.area);
    await navigateTo(
      target,
      deferBattleInArea:
          battleFactId != null || expectStaticBattle ? trigger.area : null,
    );
    await _handleAuthoredFlow(
      sourceLabel: 'trigger $triggerId',
      dialogue: dialogue,
      battleFactId: battleFactId,
      expectStaticBattle: expectStaticBattle,
      battleStrategy: battleStrategy,
      expectedTrainerId: expectedTrainerId,
      expectedEnemySpeciesId: expectedEnemySpeciesId,
    );
  }

  Future<void> enterWarp(String warpId) async {
    final sourceMapId = state.currentMapId;
    final warp = _currentMap.warps.singleWhere((entry) => entry.id == warpId);
    if (game.debugPlayerGridPosition == warp.pos) {
      await navigateTo(_adjacentReachableCell(warp.pos));
    }
    await navigateTo(warp.pos);
    await _pumpUntil(
      () =>
          state.currentMapId == warp.targetMapId &&
          !game.debugHasPendingMapTransition,
      label: 'warp $warpId to ${warp.targetMapId} from $sourceMapId',
      allowTransitionClock: true,
    );
    await _settleUntil(
      () =>
          game.debugFlowPhaseName == 'overworld' &&
          !game.debugIsMapActivationDispatchInFlight &&
          !game.debugIsNarrativeSpatialDispatchInFlight,
      label: 'post-warp flow $warpId',
    );
  }

  Future<void> crossConnection(
    MapConnectionDirection direction, {
    int? preferredAxis,
  }) async {
    final sourceMap = _currentMap;
    final connection = sourceMap.connections.singleWhere(
      (entry) => entry.direction == direction,
    );
    final candidates = _connectionBoundaryCandidates(
      sourceMap,
      direction,
      preferredAxis,
    );
    Object? lastFailure;
    for (final boundary in candidates) {
      final path = _pathTo(boundary);
      if (path == null) continue;
      final before = state.currentMapId;
      try {
        await navigateTo(boundary);
        await _tapMovement(_controlForConnection(direction));
        await _pumpUntil(
          () => state.currentMapId == connection.targetMapId,
          label: 'connection ${direction.name} to ${connection.targetMapId}',
          maxTicks: 600,
          allowTransitionClock: true,
        );
        await _pumpUntil(
          () => !game.debugHasPendingMapTransition,
          label: 'connection transition ${direction.name}',
          allowTransitionClock: true,
        );
        await _pumpUntil(
          () => game.debugFlowPhaseName == 'overworld',
          label: 'connection overworld resume ${direction.name}',
          allowTransitionClock: true,
        );
        return;
      } catch (error) {
        lastFailure = error;
        if (state.currentMapId != before) rethrow;
      }
    }
    final rejected =
        _runtimeRejectedEdgesByMapId[sourceMap.id]?.toList() ?? <String>[];
    rejected.sort();
    fail(
      'No production-input route crossed ${sourceMap.id} '
      '${direction.name} to ${connection.targetMapId}; '
      'current=${game.debugPlayerGridPosition}, '
      'movementMode=${state.playerMovementMode.name}, '
      'lastFailure=$lastFailure, rejectedEdges=$rejected.',
    );
  }

  Future<void> navigateTo(
    GridPos target, {
    MapRect? deferBattleInArea,
  }) async {
    for (var attempt = 0; attempt < 600; attempt++) {
      if (game.debugPlayerGridPosition == target) return;
      if (game.debugFlowPhaseName != 'overworld') {
        fail(
          'Unexpected ${game.debugFlowPhaseName} flow while physically '
          'navigating ${state.currentMapId}.',
        );
      }
      final path = _pathTo(target);
      if (path == null || path.isEmpty) {
        fail(
          'No physical path on ${state.currentMapId} from '
          '${game.debugPlayerGridPosition} to $target.',
        );
      }
      final direction = path.first;
      final before = game.debugPlayerGridPosition;
      await _tapMovement(_controlForDirection(direction));
      final deferred = await _resolveIncidentalEncounterIfNeeded(
        deferBattleInArea: deferBattleInArea,
      );
      if (deferred) {
        return;
      }
      final after = game.debugPlayerGridPosition;
      if (after == before) {
        _runtimeRejectedEdgesByMapId
            .putIfAbsent(state.currentMapId, () => <String>{})
            .add(_edgeKey(before, direction));
      }
    }
    fail(
      'Physical navigation exceeded 600 steps on ${state.currentMapId} '
      'towards $target.',
    );
  }

  Future<bool> _resolveIncidentalEncounterIfNeeded({
    MapRect? deferBattleInArea,
  }) async {
    final hasEncounter = game.debugPendingBattleRequest != null ||
        game.debugFlowPhaseName == 'battleTransition' ||
        game.debugFlowPhaseName == 'battle';
    if (!hasEncounter) return false;
    if (deferBattleInArea != null &&
        _contains(deferBattleInArea, game.debugPlayerGridPosition)) {
      return true;
    }
    await _pumpUntil(
      () =>
          game.debugFlowPhaseName == 'battleTransition' ||
          game.debugFlowPhaseName == 'battle',
      label: 'incidental encounter handoff',
    );
    await _driveRealBattle(
      expectStaticBattle: false,
      strategy: _BattleStrategy.flee,
    );
    await _settleUntil(
      () => game.debugFlowPhaseName == 'overworld',
      label: 'incidental encounter return to overworld',
    );
    return false;
  }

  Future<void> _handleAuthoredFlow({
    required String sourceLabel,
    _DialogueChoice? dialogue,
    String? battleFactId,
    String? acceptedDefeatFactId,
    bool expectStaticBattle = false,
    _BattleStrategy battleStrategy = _BattleStrategy.win,
    String? expectedTrainerId,
    String? expectedEnemySpeciesId,
  }) async {
    await _pumpUntil(
      () =>
          game.debugFlowPhaseName != 'overworld' ||
          game.debugIsNarrativeSpatialDispatchInFlight,
      label: 'authored spatial dispatch start for $sourceLabel',
    );
    if (dialogue != null) {
      await _pumpUntil(
        () => game.debugFlowPhaseName == 'dialogue',
        label: 'authored Yarn open',
        driveCinematic: true,
      );
      await completeOpenDialogue(dialogue);
    } else if (battleFactId != null) {
      await _pumpUntil(
        () =>
            game.debugFlowPhaseName == 'dialogue' ||
            game.debugFlowPhaseName == 'battleTransition' ||
            game.debugFlowPhaseName == 'battle',
        label: 'authored dialogue or battle handoff',
        driveCinematic: true,
      );
      if (game.debugFlowPhaseName == 'dialogue') {
        await completeOpenDialogue(const _DialogueChoice());
      }
    } else if (game.debugFlowPhaseName == 'dialogue') {
      await completeOpenDialogue(const _DialogueChoice());
    }

    if (battleFactId != null) {
      await _pumpUntil(
        () =>
            game.debugFlowPhaseName == 'battleTransition' ||
            game.debugFlowPhaseName == 'battle',
        label: 'authored battle handoff',
        driveCinematic: true,
      );
      await _driveRealBattle(
        expectStaticBattle: expectStaticBattle,
        strategy: battleStrategy,
        expectedTrainerId: expectedTrainerId,
        expectedEnemySpeciesId: expectedEnemySpeciesId,
      );
      await _settleUntil(
        () =>
            state.narrativeFactRuntimeState.overridesByFactId[battleFactId] ==
                true ||
            (acceptedDefeatFactId != null &&
                state.narrativeFactRuntimeState
                        .overridesByFactId[acceptedDefeatFactId] ==
                    true),
        label: 'battle consequence $battleFactId',
      );
      if (battleStrategy == _BattleStrategy.lose) {
        expect(
          acceptedDefeatFactId,
          isNotNull,
          reason: 'A deliberate loss must declare its authored defeat Fact.',
        );
        expect(
          state.narrativeFactRuntimeState
              .overridesByFactId[acceptedDefeatFactId],
          isTrue,
        );
        expect(
          state.narrativeFactRuntimeState.overridesByFactId[battleFactId],
          isNot(isTrue),
        );
      } else {
        expect(
          state.narrativeFactRuntimeState.overridesByFactId[battleFactId],
          isTrue,
          reason: 'This canonical battle must be won to continue.',
        );
      }
      await _settleUntil(
        () =>
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsNarrativeSpatialDispatchInFlight &&
            !game.debugIsNarrativeOutcomeWorkInFlight &&
            !game.debugIsCinematicPlaying,
        label: 'authored battle completion for $sourceLabel',
      );
      return;
    }

    await _settleUntil(
      () =>
          game.debugFlowPhaseName == 'overworld' &&
          !game.debugIsNarrativeSpatialDispatchInFlight &&
          !game.debugIsNarrativeOutcomeWorkInFlight &&
          !game.debugIsCinematicPlaying,
      label: 'authored non-battle completion',
    );
  }

  Future<void> completeOpenDialogue(_DialogueChoice choice) async {
    await _pumpUntil(
      () => game.debugFlowPhaseName == 'dialogue',
      label: 'dialogue open',
      driveCinematic: true,
    );
    if (choice.linesBeforeChoice case final lineCount?) {
      for (var line = 0; line < lineCount; line++) {
        _pressPrimary();
        await _microPump();
      }
      for (var move = 0; move < choice.choiceIndex; move++) {
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          ),
          isTrue,
        );
        await _microPump();
      }
      _pressPrimary();
      await _microPump();
    }
    for (var input = 0; input < 40; input++) {
      if (game.debugFlowPhaseName != 'dialogue') return;
      _pressPrimary();
      await _microPump();
    }
    fail('Yarn did not close after 40 explicit player inputs.');
  }

  Future<void> _driveRealBattle({
    required bool expectStaticBattle,
    _BattleStrategy strategy = _BattleStrategy.win,
    String? expectedTrainerId,
    String? expectedEnemySpeciesId,
  }) async {
    await _pumpUntil(
      () => game.debugFlowPhaseName == 'battle',
      label: 'Battle transition completion',
      allowTransitionClock: true,
    );
    await _waitForBattleInputReady();
    final initialBattle = game.debugBattleSessionSnapshot;
    expect(initialBattle, isNotNull);
    final canUseWildFleeStrategy =
        !initialBattle!.setup.isTrainerBattle && initialBattle.setup.allowFlee;
    final effectiveStrategy =
        strategy == _BattleStrategy.flee && !canUseWildFleeStrategy
            ? _BattleStrategy.win
            : strategy;
    if (expectedTrainerId != null) {
      expect(initialBattle.setup.isTrainerBattle, isTrue);
      expect(initialBattle.setup.trainerId, expectedTrainerId);
    }
    if (expectedEnemySpeciesId != null) {
      expect(initialBattle.state.enemy.speciesId, expectedEnemySpeciesId);
    }
    if (expectStaticBattle) {
      expect(initialBattle.setup.isTrainerBattle, isFalse);
      expect(initialBattle.setup.allowCapture, isFalse);
      expect(initialBattle.setup.allowFlee, isFalse);
      expect(initialBattle.setup.trainerId, isNull);
      expect(initialBattle.state.enemy.speciesId, 'lanturn');
    }

    var medicineAttempted = false;
    for (var turn = 0; turn < 80; turn++) {
      if (game.debugFlowPhaseName != 'battle') return;
      await _waitForBattleInputReady();
      if (await _completePostBattleIfNeeded()) return;
      if (game.debugFlowPhaseName != 'battle') return;
      if (effectiveStrategy == _BattleStrategy.flee) {
        await _tryRunFromBattle();
        continue;
      }
      if (effectiveStrategy == _BattleStrategy.capture) {
        await _tryCaptureWithPokeBall();
        continue;
      }
      final battle = game.debugBattleSessionSnapshot;
      expect(battle, isNotNull);
      final player = battle!.state.player;
      if (effectiveStrategy == _BattleStrategy.win &&
          !medicineAttempted &&
          player.currentHp < player.maxHp) {
        medicineAttempted = true;
        if (!await _tryUseFirstMedicine()) {
          await _useBestDamagingMove();
        }
      } else if (effectiveStrategy == _BattleStrategy.lose) {
        await _useStatusMove();
      } else {
        await _useBestDamagingMove();
      }
    }
    fail('A real Selbrume battle exceeded 80 turns.');
  }

  Future<bool> _completePostBattleIfNeeded() async {
    final battleFinished =
        game.debugBattleSessionSnapshot?.state.isFinished ?? false;
    if (!game.debugPostBattleOverlayMounted && !battleFinished) return false;

    await _pumpUntil(
      () =>
          game.debugFlowPhaseName != 'battle' ||
          game.debugPostBattleOverlayMounted,
      label: 'post-battle overlay mount',
      allowTransitionClock: true,
    );
    for (var acknowledgement = 0;
        acknowledgement < 240 && game.debugPostBattleOverlayMounted;
        acknowledgement++) {
      expect(game.debugValidatePostBattleChoice(), isTrue);
      await _microPump();
    }
    if (game.debugPostBattleOverlayMounted) {
      fail('The Selbrume post-battle queue exceeded 240 acknowledgements.');
    }
    await game.debugWaitForPostBattleCompletion();
    return true;
  }

  Future<void> _tryCaptureWithPokeBall() async {
    final overlay = game.debugBattleOverlayComponent;
    expect(overlay, isNotNull);
    final activeOverlay = overlay!;
    for (var back = 0;
        back < 3 && activeOverlay.currentMenuMode.name != 'root';
        back++) {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump();
    }
    expect(activeOverlay.currentMenuMode.name, 'root');
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    await _pressBattleDirection(RuntimeInputControl.right);
    _pressPrimary();
    await _microPump();
    expect(activeOverlay.currentMenuMode.name, 'bag');
    _pressPrimary();
    await _waitForBattleInputReady();
  }

  Future<void> _tryRunFromBattle() async {
    final overlay = game.debugBattleOverlayComponent;
    expect(overlay, isNotNull);
    final activeOverlay = overlay!;
    if (activeOverlay.currentMenuMode.name == 'continueOnly') {
      _pressPrimary();
      await _waitForBattleInputReady();
      return;
    }
    for (var back = 0;
        back < 3 && activeOverlay.currentMenuMode.name != 'root';
        back++) {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump();
    }
    expect(activeOverlay.currentMenuMode.name, 'root');
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    await _pressBattleDirection(RuntimeInputControl.down);
    await _pressBattleDirection(RuntimeInputControl.right);
    _pressPrimary();
    await _waitForBattleInputReady();
  }

  Future<void> _useBestDamagingMove() async {
    final battle = game.debugBattleSessionSnapshot;
    expect(battle, isNotNull);
    final player = battle!.state.player;
    final enemy = battle.state.enemy;
    final enemyTypes = enemy.typing?.types ?? const <String>[];
    var bestIndex = -1;
    var bestScore = 0.0;
    for (var index = 0; index < player.moves.length; index++) {
      final move = player.moves[index];
      if (move.power <= 0 || move.currentPp <= 0) continue;
      final effectiveness = _moveEffectiveness(move.type, enemyTypes);
      final stab = (player.typing?.hasType(move.type) ?? false) ? 1.5 : 1.0;
      final score = move.power * effectiveness * stab;
      if (score > bestScore) {
        bestScore = score;
        bestIndex = index;
      }
    }
    expect(
      bestIndex,
      greaterThanOrEqualTo(0),
      reason: 'The active battler needs a non-immune damaging move.',
    );
    await _useMoveAtIndex(bestIndex);
  }

  Future<void> _useStatusMove() async {
    final battle = game.debugBattleSessionSnapshot;
    expect(battle, isNotNull);
    final moves = battle!.state.player.moves;
    final statusIndex = moves.indexWhere(
      (move) => move.power == 0 && move.currentPp > 0,
    );
    expect(
      statusIndex,
      greaterThanOrEqualTo(0),
      reason: 'The deliberate-loss proof requires a real status move.',
    );
    await _useMoveAtIndex(statusIndex);
  }

  Future<void> _useMoveAtIndex(int moveIndex) async {
    final overlay = game.debugBattleOverlayComponent;
    expect(overlay, isNotNull);
    final activeOverlay = overlay!;
    if (activeOverlay.currentMenuMode.name == 'continueOnly') {
      _pressPrimary();
      await _waitForBattleInputReady();
      return;
    }
    for (var back = 0;
        back < 3 && activeOverlay.currentMenuMode.name != 'root';
        back++) {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump();
    }
    expect(activeOverlay.currentMenuMode.name, 'root');
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    _pressPrimary();
    await _microPump();
    expect(activeOverlay.currentMenuMode.name, 'fight');
    if (moveIndex >= 2) {
      await _pressBattleDirection(RuntimeInputControl.down);
    }
    if (moveIndex.isOdd) {
      await _pressBattleDirection(RuntimeInputControl.right);
    }
    final battle = game.debugBattleSessionSnapshot;
    expect(battle, isNotNull);
    final selectedMove = battle!.state.player.moves[moveIndex];
    battleMoveChoices.add(
      _BattleMoveChoiceEvidence(
        moveId: selectedMove.id,
        power: selectedMove.power,
        effectiveness: _moveEffectiveness(
          selectedMove.type,
          battle.state.enemy.typing?.types ?? const <String>[],
        ),
      ),
    );
    _pressPrimary();
    await _waitForBattleInputReady();
  }

  Future<bool> _tryUseFirstMedicine() async {
    final overlay = game.debugBattleOverlayComponent;
    expect(overlay, isNotNull);
    final activeOverlay = overlay!;
    for (var back = 0;
        back < 3 && activeOverlay.currentMenuMode.name != 'root';
        back++) {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump();
    }
    expect(activeOverlay.currentMenuMode.name, 'root');
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    await _pressBattleDirection(RuntimeInputControl.right);
    _pressPrimary();
    await _microPump();
    expect(activeOverlay.currentMenuMode.name, 'bag');
    _pressPrimary();
    await _microPump();
    if (activeOverlay.currentMenuMode.name != 'bagMedicineTarget') {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump();
      expect(activeOverlay.currentMenuMode.name, 'root');
      return false;
    }
    _pressPrimary();
    await _waitForBattleInputReady();
    return true;
  }

  Future<void> _waitForBattleInputReady() async {
    await game.debugWaitForBattleOverlaySync();
    await _pumpUntil(
      () =>
          game.debugFlowPhaseName != 'battle' ||
          !(game.debugBattleOverlayComponent?.isTurnPresentationActive ??
              false),
      label: 'battle presentation completion',
      allowTransitionClock: true,
    );
  }

  Future<void> _pressBattleDirection(RuntimeInputControl control) async {
    expect(
      game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
      isTrue,
    );
    await _microPump();
  }

  Future<void> _settleUntil(
    bool Function() done, {
    required String label,
  }) {
    return _pumpUntil(
      done,
      label: label,
      driveCinematic: true,
      drivePlainDialogue: true,
      allowTransitionClock: true,
      maxTicks: 6000,
    );
  }

  Future<void> _pumpUntil(
    bool Function() done, {
    required String label,
    int maxTicks = 3000,
    bool driveCinematic = false,
    bool drivePlainDialogue = false,
    bool allowTransitionClock = false,
  }) async {
    for (var tick = 0; tick < maxTicks; tick++) {
      if (done()) return;
      if (driveCinematic &&
          game.debugIsCinematicPlaying &&
          game.debugCinematicDialogueLine != null) {
        _pressPrimary();
      } else if (drivePlainDialogue && game.debugFlowPhaseName == 'dialogue') {
        _pressPrimary();
      }
      game.update(0.016);
      await Future<void>.delayed(
        allowTransitionClock ? const Duration(milliseconds: 1) : Duration.zero,
      );
    }
    fail(
      'Timed out waiting for $label: map=${state.currentMapId}, '
      'pos=${game.debugPlayerGridPosition}, '
      'phase=${game.debugFlowPhaseName}, '
      'notification=${game.debugNotificationText}.',
    );
  }

  Future<void> _microPump() async {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }

  void _pressPrimary() {
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
  }

  Future<void> _tapMovement(RuntimeInputControl control) async {
    expect(
      game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
      isTrue,
    );
    game.update(0.016);
    expect(
      game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
      isTrue,
    );
    await _pumpUntil(
      () => !game.debugIsPlayerStepping,
      label: 'movement ${control.name}',
      maxTicks: 500,
    );
  }

  MapData get _currentMap => _mapById(state.currentMapId);

  MapData _mapById(String mapId) {
    return _mapsById.putIfAbsent(mapId, () {
      final entry = project.maps.singleWhere((map) => map.id == mapId);
      final json = jsonDecode(
        File(p.join(projectRoot.path, entry.relativePath)).readAsStringSync(),
      ) as Map<String, dynamic>;
      return MapData.fromJson(json);
    });
  }

  GameplayWorldState _pathfindingWorld(MapData map) {
    final projection = const RuntimeWorldRuleProjectionHook().resolve(
      project: project,
      gameState: state,
      map: map,
    );
    bool entityPresence(String _, MapEntity entity) =>
        projection.isMapEntityVisible(entity);
    return GameplayWorldState.initial(
      map: map,
      playerPos: game.debugPlayerGridPosition,
      playerFacing: _directionFromFacing(state.playerFacing),
      project: project,
      tileWidth: project.settings.tileWidth,
      tileHeight: project.settings.tileHeight,
      playerMovementMode: state.playerMovementMode,
      npcMapPresencePredicate: entityPresence,
      mapEntityPresencePredicate: entityPresence,
    );
  }

  List<Direction>? _pathTo(GridPos target) {
    return _findPath(target, avoidEncounters: true) ??
        _findPath(target, avoidEncounters: false);
  }

  List<Direction>? _findPath(
    GridPos target, {
    required bool avoidEncounters,
  }) {
    final map = _currentMap;
    final world = _pathfindingWorld(map);
    final start = game.debugPlayerGridPosition;
    if (start == target) return <Direction>[];
    if (!_inside(map, target) || world.isBlocked(target.x, target.y)) {
      return null;
    }
    final queue = Queue<GridPos>()..add(start);
    final previous = <GridPos, ({GridPos pos, Direction direction})>{};
    final visited = <GridPos>{start};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final direction in const <Direction>[
        Direction.north,
        Direction.east,
        Direction.south,
        Direction.west,
      ]) {
        final next = _translated(current, direction);
        if (!_inside(map, next) ||
            visited.contains(next) ||
            (_runtimeRejectedEdgesByMapId[map.id]
                    ?.contains(_edgeKey(current, direction)) ??
                false) ||
            !_canTakePhysicalStep(world, current, direction, next) ||
            (_isUnintendedWarpCell(map, next, target)) ||
            (avoidEncounters && _isEncounterCell(map, next))) {
          continue;
        }
        visited.add(next);
        previous[next] = (pos: current, direction: direction);
        if (next == target) {
          final reversed = <Direction>[];
          var cursor = next;
          while (cursor != start) {
            final edge = previous[cursor]!;
            reversed.add(edge.direction);
            cursor = edge.pos;
          }
          return reversed.reversed.toList(growable: false);
        }
        queue.add(next);
      }
    }
    return null;
  }

  bool _hasGridPath(GameplayWorldState world, GridPos target) {
    final map = _currentMap;
    final start = game.debugPlayerGridPosition;
    final queue = Queue<GridPos>()..add(start);
    final visited = <GridPos>{start};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final direction in Direction.values) {
        final next = _translated(current, direction);
        if (!_inside(map, next) ||
            visited.contains(next) ||
            world.isBlocked(next.x, next.y)) {
          continue;
        }
        if (next == target) return true;
        visited.add(next);
        queue.add(next);
      }
    }
    return start == target;
  }

  bool _canTakePhysicalStep(
    GameplayWorldState baseWorld,
    GridPos from,
    Direction direction,
    GridPos expectedTarget,
  ) {
    final positioned = baseWorld.withPlayer(
      GameplayPlayerState.fromGridSpawn(
        cell: from,
        facing: direction,
        movementMode: state.playerMovementMode,
        tileWidthPx: project.settings.tileWidth,
        tileHeightPx: project.settings.tileHeight,
        mapWidthCells: baseWorld.map.size.width,
        mapHeightCells: baseWorld.map.size.height,
      ),
    );
    var cursor = positioned;
    for (var pixelStep = 0; pixelStep < 32; pixelStep++) {
      final result = stepGameplayWorld(cursor, MoveIntent(direction));
      if (result is Blocked) return false;
      cursor = result.world;
      if (cursor.player.pos == expectedTarget) return true;
      if (cursor.player.pos != from) return false;
    }
    return false;
  }

  _EntityApproach _shortestReachableApproach(MapEntity entity) {
    final candidates = <_EntityApproach>[];
    for (final entry in <({Direction facing, GridPos position})>[
      (
        facing: Direction.south,
        position: GridPos(x: entity.pos.x, y: entity.pos.y - 1),
      ),
      (
        facing: Direction.west,
        position: GridPos(x: entity.pos.x + entity.size.width, y: entity.pos.y),
      ),
      (
        facing: Direction.north,
        position:
            GridPos(x: entity.pos.x, y: entity.pos.y + entity.size.height),
      ),
      (
        facing: Direction.east,
        position: GridPos(x: entity.pos.x - 1, y: entity.pos.y),
      ),
    ]) {
      final stagingPosition = GridPos(
        x: entry.position.x - entry.facing.dx,
        y: entry.position.y - entry.facing.dy,
      );
      final stagingPath = _pathTo(stagingPosition);
      final approachPath = _pathTo(entry.position);
      if (stagingPath != null && approachPath != null) {
        candidates.add(
          _EntityApproach(
            position: entry.position,
            stagingPosition: stagingPosition,
            facing: entry.facing,
            pathLength: stagingPath.length + 1,
          ),
        );
      }
    }
    if (candidates.isEmpty) {
      fail('Entity ${entity.id} has no reachable interaction front.');
    }
    candidates.sort((a, b) => a.pathLength.compareTo(b.pathLength));
    return candidates.first;
  }

  ({GridPos position, Direction facing}) _reachableGateApproach(
    GridPos target,
  ) {
    final candidates = <({GridPos position, Direction facing, int length})>[];
    for (final facing in Direction.values) {
      final position = GridPos(
        x: target.x - facing.dx,
        y: target.y - facing.dy,
      );
      final path = _pathTo(position);
      if (path != null) {
        candidates.add(
          (position: position, facing: facing, length: path.length),
        );
      }
    }
    if (candidates.isEmpty) {
      fail('Surf gate $target has no reachable approach.');
    }
    candidates.sort((left, right) => left.length.compareTo(right.length));
    final selected = candidates.first;
    return (position: selected.position, facing: selected.facing);
  }

  GridPos _reachableCellInArea(MapRect area) {
    final candidates = <({GridPos pos, int length})>[];
    for (var y = area.pos.y; y < area.pos.y + area.size.height; y++) {
      for (var x = area.pos.x; x < area.pos.x + area.size.width; x++) {
        final pos = GridPos(x: x, y: y);
        final path = _pathTo(pos);
        if (path != null) candidates.add((pos: pos, length: path.length));
      }
    }
    if (candidates.isEmpty) fail('Trigger area $area has no reachable cell.');
    candidates.sort((a, b) => a.length.compareTo(b.length));
    return candidates.first.pos;
  }

  GridPos _adjacentReachableCell(GridPos origin) {
    for (final direction in Direction.values) {
      final candidate = _translated(origin, direction);
      if (_pathTo(candidate) != null) return candidate;
    }
    fail('No reachable exit adjacent to $origin on ${state.currentMapId}.');
  }

  GridPos _reachableCellOutsideArea(MapRect area) {
    final candidates = <({GridPos pos, int length})>[];
    for (var y = area.pos.y - 1; y <= area.pos.y + area.size.height; y++) {
      for (final x in <int>[area.pos.x - 1, area.pos.x + area.size.width]) {
        final pos = GridPos(x: x, y: y);
        final path = _pathTo(pos);
        if (path != null) candidates.add((pos: pos, length: path.length));
      }
    }
    for (var x = area.pos.x; x < area.pos.x + area.size.width; x++) {
      for (final y in <int>[area.pos.y - 1, area.pos.y + area.size.height]) {
        final pos = GridPos(x: x, y: y);
        final path = _pathTo(pos);
        if (path != null) candidates.add((pos: pos, length: path.length));
      }
    }
    if (candidates.isEmpty) {
      fail('Trigger area $area has no reachable outside cell.');
    }
    candidates.sort((a, b) => a.length.compareTo(b.length));
    return candidates.first.pos;
  }

  Iterable<GridPos> _connectionBoundaryCandidates(
    MapData map,
    MapConnectionDirection direction,
    int? preferredAxis,
  ) {
    final result = <GridPos>[];
    final axisLength = switch (direction) {
      MapConnectionDirection.north ||
      MapConnectionDirection.south =>
        map.size.width,
      MapConnectionDirection.east ||
      MapConnectionDirection.west =>
        map.size.height,
    };
    final preferred =
        (preferredAxis ?? axisLength ~/ 2).clamp(0, axisLength - 1);
    final axes = List<int>.generate(axisLength, (index) => index)
      ..sort((a, b) => (a - preferred).abs().compareTo((b - preferred).abs()));
    for (final axis in axes) {
      result.add(
        switch (direction) {
          MapConnectionDirection.north => GridPos(x: axis, y: 0),
          MapConnectionDirection.south =>
            GridPos(x: axis, y: map.size.height - 1),
          MapConnectionDirection.east =>
            GridPos(x: map.size.width - 1, y: axis),
          MapConnectionDirection.west => GridPos(x: 0, y: axis),
        },
      );
    }
    return result;
  }

  bool _isEncounterCell(MapData map, GridPos pos) {
    return map.gameplayZones.any(
      (zone) =>
          zone.kind == GameplayZoneKind.encounter &&
          pos.x >= zone.area.pos.x &&
          pos.y >= zone.area.pos.y &&
          pos.x < zone.area.pos.x + zone.area.size.width &&
          pos.y < zone.area.pos.y + zone.area.size.height,
    );
  }

  bool _isUnintendedWarpCell(MapData map, GridPos pos, GridPos target) {
    if (pos == target) return false;
    return map.warps.any(
      (warp) =>
          warp.triggerMode == MapWarpTriggerMode.onEnter && warp.pos == pos,
    );
  }
}

enum _BattleStrategy { win, lose, flee, capture }

final class _DialogueChoice {
  const _DialogueChoice({this.linesBeforeChoice, this.choiceIndex = 0});

  final int? linesBeforeChoice;
  final int choiceIndex;
}

final class _BattleMoveChoiceEvidence {
  const _BattleMoveChoiceEvidence({
    required this.moveId,
    required this.power,
    required this.effectiveness,
  });

  final String moveId;
  final int power;
  final double effectiveness;
}

final class _EntityApproach {
  const _EntityApproach({
    required this.position,
    required this.stagingPosition,
    required this.facing,
    required this.pathLength,
  });

  final GridPos position;
  final GridPos stagingPosition;
  final Direction facing;
  final int pathLength;
}

GridPos _translated(GridPos pos, Direction direction) {
  return switch (direction) {
    Direction.north => GridPos(x: pos.x, y: pos.y - 1),
    Direction.east => GridPos(x: pos.x + 1, y: pos.y),
    Direction.south => GridPos(x: pos.x, y: pos.y + 1),
    Direction.west => GridPos(x: pos.x - 1, y: pos.y),
  };
}

bool _inside(MapData map, GridPos pos) {
  return pos.x >= 0 &&
      pos.y >= 0 &&
      pos.x < map.size.width &&
      pos.y < map.size.height;
}

bool _contains(MapRect area, GridPos pos) {
  return pos.x >= area.pos.x &&
      pos.y >= area.pos.y &&
      pos.x < area.pos.x + area.size.width &&
      pos.y < area.pos.y + area.size.height;
}

double _moveEffectiveness(String attackType, List<String> defenderTypes) {
  const immunityByAttackType = <String, Set<String>>{
    'normal': <String>{'ghost'},
    'fighting': <String>{'ghost'},
    'ghost': <String>{'normal'},
    'electric': <String>{'ground'},
    'ground': <String>{'flying'},
    'psychic': <String>{'dark'},
    'poison': <String>{'steel'},
    'dragon': <String>{'fairy'},
  };
  const canonicalStarterMatchups = <String, Map<String, double>>{
    'normal': <String, double>{'rock': 0.5, 'steel': 0.5},
    'fire': <String, double>{
      'fire': 0.5,
      'water': 0.5,
      'grass': 2,
      'ice': 2,
      'bug': 2,
      'rock': 0.5,
      'dragon': 0.5,
      'steel': 2,
    },
  };
  final normalizedAttack = attackType.trim().toLowerCase();
  var multiplier = 1.0;
  for (final rawDefenderType in defenderTypes) {
    final defenderType = rawDefenderType.trim().toLowerCase();
    if (immunityByAttackType[normalizedAttack]?.contains(defenderType) ??
        false) {
      return 0;
    }
    multiplier *=
        canonicalStarterMatchups[normalizedAttack]?[defenderType] ?? 1;
  }
  return multiplier;
}

Direction _directionFromFacing(EntityFacing facing) {
  return switch (facing) {
    EntityFacing.north => Direction.north,
    EntityFacing.east => Direction.east,
    EntityFacing.south => Direction.south,
    EntityFacing.west => Direction.west,
  };
}

RuntimeInputControl _controlForDirection(Direction direction) {
  return switch (direction) {
    Direction.north => RuntimeInputControl.up,
    Direction.east => RuntimeInputControl.right,
    Direction.south => RuntimeInputControl.down,
    Direction.west => RuntimeInputControl.left,
  };
}

RuntimeInputControl _controlForConnection(MapConnectionDirection direction) {
  return switch (direction) {
    MapConnectionDirection.north => RuntimeInputControl.up,
    MapConnectionDirection.east => RuntimeInputControl.right,
    MapConnectionDirection.south => RuntimeInputControl.down,
    MapConnectionDirection.west => RuntimeInputControl.left,
  };
}

String _edgeKey(GridPos from, Direction direction) =>
    '${from.x}:${from.y}:${direction.name}';

Map<String, dynamic> _withoutInternalResetTokens(
  Map<String, dynamic> value,
) {
  final copy = Map<String, dynamic>.from(
    jsonDecode(jsonEncode(value)) as Map,
  );
  final progress = copy['narrativeEventProgress'];
  if (progress is Map) {
    progress.remove('appliedNarrativeResetTokens');
  }
  return copy;
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}
