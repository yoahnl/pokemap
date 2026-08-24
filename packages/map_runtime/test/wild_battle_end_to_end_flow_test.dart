import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_panel_component.dart';
// applyRuntimeDefeatRecoveryToGameState n'est volontairement pas exporte : c'est
// un helper interne que PlayableMapGame appelle. Import cible plutot que
// elargissement de la surface publique pour les besoins d'un test.
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart'
    show applyRuntimeDefeatRecoveryToGameState;
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('wild battle runtime flow lot 11', () {
    late Directory tempProjectRoot;
    final mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('wild_battle_flow_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('real wild encounter chain resolves to victory and writes back hp',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();

      // On part bien du vrai chemin overworld minimal :
      // 1. world gameplay avec spawn réel
      // 2. déplacement d'une case vers une zone de rencontre
      // 3. check de rencontre sur la case atteinte
      final initialWorld = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final stepResult = stepGameplayWorld(
        initialWorld,
        const MoveIntent(Direction.east),
      );
      expect(stepResult, isA<Moved>());
      final movedWorld = stepResult.world;
      expect(movedWorld.player.pos, const GridPos(x: 1, y: 0));

      final encounterCheck = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      );

      expect(encounterCheck.triggered, isTrue);
      final encounter = encounterCheck.encounter!;
      expect(encounter.speciesId, equals('sparkitten'));
      expect(encounter.level, equals(6));

      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );
      expect(request.kind, equals(RuntimeBattleKind.wild));
      expect(request.source, equals(RuntimeBattleSourceKind.wildEncounter));

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      final stateWithSeen = markSpeciesSeenInGameState(
          _playerState(), setup.enemyPokemon.speciesId);
      expect(stateWithSeen.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        stateWithSeen.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );

      var session = createBattleSession(setup);
      var turnCount = 0;
      while (!session.state.isFinished && turnCount < 10) {
        session = session.applyChoice(const PlayerBattleChoiceFight(0));
        turnCount++;
      }
      expect(session.state.outcome, isNotNull);
      // ignore: avoid_print
      print(
          'XOUT type=${session.state.outcome!.type} turns=$turnCount hp=${session.state.outcome!.finalState.player.currentHp}');
      expect(session.state.outcome!.isVictory, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: stateWithSeen,
        context: const RuntimeActiveBattleContext(
          request: WildBattleStartRequest(
            requestId: 'wild-request',
            createdAtEpochMs: 1,
            returnContext: OverworldReturnContext(
              mapId: 'field_map',
              playerPos: GridPos(x: 1, y: 0),
              playerFacing: Direction.east,
            ),
            mapId: 'field_map',
            encounterSourceId: 'encounter_grass',
            encounterSourceKind: EncounterSourceKind.gameplayZone,
            tableId: 'field_grass',
            encounterKind: EncounterKind.walk,
            speciesId: 'sparkitten',
            level: 6,
            minLevel: 6,
            maxLevel: 6,
            weight: 1,
            playerPos: GridPos(x: 1, y: 0),
          ),
          playerPartyIndex: 0,
        ),
        outcome: session.state.outcome!,
      );

      expect(
        updatedState.party.members.first.currentHp,
        equals(session.state.outcome!.finalState.player.currentHp),
      );
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        updatedState.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });

    test('victory writes back hp and pp, not only hp', () async {
      // Critère d'acceptation de BETA-BAT-008 : « write-back PV/PP/statut ».
      // Le write-back porte bien les trois depuis toujours, mais seul le PV
      // était vérifié : un round-trip qui perdrait les PP passait inaperçu.
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      // Pas de poison ici : mesuré, un sproutle empoisonné perd ce combat même
      // à PV pleins (6 tours, 29 PV). Le statut est donc couvert par le scénario
      // de défaite juste en dessous, qui est son terrain naturel.
      final incoming = _playerState(vineWhipPp: 35, currentHp: 29);

      final request = buildBattleStartRequestFromEncounter(
        encounter: const GameplayEncounter(
          mapId: 'field_map',
          sourceId: 'encounter_grass',
          sourceKind: EncounterSourceKind.gameplayZone,
          tableId: 'field_grass',
          encounterKind: EncounterKind.walk,
          speciesId: 'sparkitten',
          level: 6,
          minLevel: 6,
          maxLevel: 6,
          weight: 1,
          playerPos: GridPos(x: 1, y: 0),
        ),
        world: GameplayWorldState.fromMap(
          map,
          project: manifest,
          tileWidth: 16,
          tileHeight: 16,
        ),
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: incoming,
        request: request,
      );

      var session = createBattleSession(setup);
      var turnCount = 0;
      while (!session.state.isFinished && turnCount < 10) {
        session = session.applyChoice(const PlayerBattleChoiceFight(0));
        turnCount++;
      }
      expect(session.state.outcome, isNotNull);
      expect(session.state.outcome!.isVictory, isTrue);

      final kernelPlayer = session.state.outcome!.finalState.player;
      final updated = applyRuntimeBattleOutcomeToGameState(
        gameState: incoming,
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: 0,
        ),
        outcome: session.state.outcome!,
      );
      final written = updated.party.members.first;

      expect(written.currentHp, kernelPlayer.currentHp, reason: 'hp');
      expect(
        written.currentPpByMoveId?['vine_whip'],
        lessThan(35),
        reason: 'the moves used during the battle must cost PP',
      );
      expect(
        written.currentPpByMoveId?['vine_whip'],
        kernelPlayer.moves
            .firstWhere((move) => move.id == 'vine_whip')
            .currentPp,
        reason: 'pp must equal what the kernel ended with',
      );
      expect(
        written.statusId,
        '',
        reason: 'a healthy winner must not come back with an invented status',
      );
    });

    test('a move with no PP left is refused instead of being spent', () async {
      // Scénario « move sans PP ou action indisponible » du ticket. Trouvé en
      // écrivant le test précédent : avec 8 PP le combat s'arrêtait sur un
      // StateError plutôt que sur une issue, ce qui est le comportement voulu
      // mais que rien ne vérifiait.
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(vineWhipPp: 1, currentHp: 29),
        request: _wildRequest(manifest, map),
      );

      var session = createBattleSession(setup);
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse,
          reason: 'the vector needs a battle still running');

      // Le dernier PP est consommé : le moteur doit refuser, pas dépenser un PP
      // négatif ni laisser passer un tour fantôme.
      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(isA<StateError>()),
      );
      expect(
        session.decisionRequest.allowedChoices,
        isNot(contains(const PlayerBattleChoiceFight(0))),
        reason: 'an unusable move must not be offered either',
      );
    });

    test('a total party defeat writes back the run and its status', () async {
      // Scénario « défaite de toute la Party » du ticket, et terrain naturel du
      // write-back de statut : un sproutle empoisonné à 20 PV sur 29 perd ce
      // combat en quatre tours, mesuré.
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final incoming = _playerState(statusId: 'psn', vineWhipPp: 6);
      final request = _wildRequest(manifest, map);
      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: incoming,
        request: request,
      );

      // Le statut doit d'abord ENTRER, sinon l'aller-retour serait vide et le
      // test se féliciterait de rien.
      expect(setup.playerPokemon.majorStatus?.id, BattleMajorStatusId.psn);

      var session = createBattleSession(setup);
      var turnCount = 0;
      while (!session.state.isFinished && turnCount < 10) {
        session = session.applyChoice(const PlayerBattleChoiceFight(0));
        turnCount++;
      }

      expect(session.state.outcome!.isDefeat, isTrue);
      expect(session.state.outcome!.finalState.player.currentHp, 0);

      final updated = applyRuntimeBattleOutcomeToGameState(
        gameState: incoming,
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: 0,
        ),
        outcome: session.state.outcome!,
      );
      final written = updated.party.members.first;

      // PREMIÈRE ÉTAPE : le write-back enregistre la défaite FIDÈLEMENT, zéro PV
      // compris. J'avais d'abord supposé qu'il relevait lui-même le Pokémon ;
      // il ne le fait pas, et c'est le bon comportement — inventer un soin ici
      // effacerait la mémoire du combat.
      expect(written.currentHp, 0);
      expect(
        written.currentPpByMoveId?['vine_whip'],
        lessThan(6),
        reason: 'the moves spent before falling still cost PP',
      );
      expect(written.statusId, 'psn', reason: 'the poison is written back too');

      // SECONDE ÉTAPE, helper distinct et contrat explicite : puisque TOUTE la
      // party est K.O., le slot qui a servi au combat est relevé à 1 PV. Sans
      // cela le joueur reviendrait en overworld sans aucun combattant utilisable
      // et le prochain handoff runtime vers battle serait impossible.
      final recovered = applyRuntimeDefeatRecoveryToGameState(
        gameState: updated,
        playerPartyIndex: 0,
      );

      expect(recovered.party.members.first.currentHp, 1);
      expect(
        recovered.party.members.first.currentPpByMoveId?['vine_whip'],
        written.currentPpByMoveId?['vine_whip'],
        reason: 'reviving must not refill anything else',
      );
    });

    test('run choice produces a real runaway outcome without trainer flags',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      final stateWithSeen = markSpeciesSeenInGameState(
          _playerState(), setup.enemyPokemon.speciesId);

      final outcome = createBattleSession(setup)
          .applyChoice(const PlayerBattleChoiceRun())
          .state
          .outcome!;
      expect(outcome.isRunaway, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: stateWithSeen,
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: 0,
        ),
        outcome: outcome,
      );

      expect(updatedState.party.members.first.currentHp, equals(20));
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        updatedState.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });

    test('PlayableMapGame opens PSDK battle as the primary runtime bridge',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );
      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(_playerState()),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugBattleOverlayMounted, isTrue);
      expect(game.debugPsdkBattleSessionActive, isTrue);
      expect(game.debugBattleSessionSnapshot, isNotNull);
      expect(
        game.debugBattleSessionSnapshot!.state.player.moves.map(
          (move) => move.id,
        ),
        equals(<String>['vine_whip']),
      );
    });

    test(
        'recette 2026-08-24 : le noir TIENT tant que la scène de combat '
        'n’a pas fini de charger', () async {
      // Le rideau tombait dès le noir tenu, sur un overlay encore en plein
      // onLoad : la scène apparaissait complète (menu ouvert, combattants en
      // place), puis l'intro démarrait en retard par-dessus. Ce test ouvre
      // exactement cette fenêtre : le noir forcé PENDANT le chargement.
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(_playerState()),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      Future<void> pumpTicks({
        required bool Function() until,
        required int maxTicks,
      }) async {
        for (var i = 0; i < maxTicks; i++) {
          if (until()) return;
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);
        }
        fail('Timed out after $maxTicks ticks.');
      }

      await pumpTicks(
        until: () => !game.debugIsMapActivationDispatchInFlight,
        maxTicks: 240,
      );
      game.debugStartBattleHandoffForTest(_wildRequest(manifest, map));
      await pumpTicks(
        until: () => game.debugBattleOverlayMounted,
        maxTicks: 240,
      );
      final overlay = game.debugBattleOverlayComponent!;
      expect(
        overlay.isLoaded,
        isFalse,
        reason: 'la fenêtre de course doit être ouverte : le montage '
            'asynchrone court encore',
      );

      game.debugBattleTransitionOverlay!.debugHoldBlackNowForTest();
      await Future<void>.delayed(Duration.zero);
      game.update(0.016);
      expect(
        game.debugBattleTransitionOverlayMounted,
        isTrue,
        reason: 'le rideau ne tombe PAS sur une scène pas prête — c\'était '
            'le « les Pokémon sont là, puis ils arrivent » de la recette',
      );

      // Le chargement finit : le rappel de fin de montage révèle la scène et
      // démarre l'intro — qui existe, au lieu de partir dans le vide.
      await pumpTicks(until: () => overlay.isLoaded, maxTicks: 600);
      await pumpTicks(
        until: () => !game.debugBattleTransitionOverlayMounted,
        maxTicks: 600,
      );
      expect(
        overlay.isTurnPresentationActive,
        isTrue,
        reason: 'l’intro joue après le reveal — le plan n’a pas été consommé '
            'à vide pendant le chargement',
      );
    });

    test('BETA-BAT-016 : le vrai handoff traverse la pré-transition', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(_playerState()),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      Future<void> pumpTicks({
        required bool Function() until,
        required int maxTicks,
      }) async {
        for (var i = 0; i < maxTicks; i++) {
          if (until()) return;
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);
        }
        fail('Timed out after $maxTicks ticks.');
      }

      await pumpTicks(
        until: () => !game.debugIsMapActivationDispatchInFlight,
        maxTicks: 240,
      );
      game.debugStartBattleHandoffForTest(_wildRequest(manifest, map));
      expect(
        game.debugBattleTransitionOverlayMounted,
        isTrue,
        reason: 'la pré-transition se joue par-dessus la carte',
      );

      // Le chargement court en PARALLÈLE : la scène se monte sous le noir.
      // Attendre le onLoad COMPLET : le plan d'intro (et la planche de Ball
      // de BAT-022) se posent en fin de montage asynchrone.
      await pumpTicks(
        until: () =>
            game.debugBattleOverlayMounted &&
            game.debugBattleOverlayComponent!.isLoaded,
        maxTicks: 400,
      );
      expect(
        game.debugBattleOverlayComponent!.isTurnPresentationActive,
        isTrue,
        reason: 'critère 5 : verrouillé du montage au déverrouillage final',
      );
      expect(game.debugBattleOverlayComponent!.selectRootEntry(0), isFalse);

      // RBY 2,25 s + fondu 0,25 s + glissement 0,8 s + 2 messages ≈ 4,2 s.
      await pumpTicks(
        until: () =>
            !game.debugBattleOverlayComponent!.isTurnPresentationActive,
        maxTicks: 800,
      );
      expect(
        game.debugBattleTransitionOverlayMounted,
        isFalse,
        reason: 'la pré-transition ne survit pas au reveal',
      );
      expect(
        game.debugBattleFxImageCacheCount,
        greaterThan(0),
        reason: 'BETA-BAT-018 : les planches des capacités des deux camps '
            'sont préchauffées sous le noir — le premier coup ne gèle plus',
      );

      expect(game.debugFlowPhaseName, 'battle');
      expect(game.debugBattleOverlayComponent!.selectRootEntry(0), isTrue);
    });

    test('the battle surface is driven by controller inputs alone', () async {
      // « Clavier, manette et tactile » de BETA-BAT-007. La surface de combat est
      // pilotée par le vocabulaire AGNOSTIQUE `RuntimeInputControl` : croix
      // directionnelle, primary, secondary. Une manette qui se mappe dessus
      // pilote donc tout, à condition qu'aucune commande n'exige un autre chemin.
      //
      // Ce cas ne touche JAMAIS les méthodes de l'overlay : tout passe par
      // handleRuntimeInputEvent, exactement comme un pad. Appeler
      // moveSelectionDown() directement testerait l'overlay, pas le routage.
      //
      // L'observable est le MODE de menu et non l'index de sélection : dans ce
      // harnais headless le panneau visuel n'est pas monté, et lire son index
      // rendrait une valeur par défaut plutôt qu'une mesure. Les transitions de
      // mode suffisent à prouver que chaque touche arrive à destination.
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      // `_LoadedGame` et pas `PlayableMapGame` : handleRuntimeInputEvent
      // commence par `if (!isLoaded) return false`, et hors d'une vraie boucle
      // Flame `isLoaded` reste faux. Sans cette surcharge, TOUTES les touches
      // sont ignorées et le test verdit en ne mesurant rien. C'est d'ailleurs
      // pour cela que les autres cas de ce fichier pilotent l'overlay en direct :
      // le routage des entrées n'y avait jamais été exercé.
      final game = _LoadedGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(_playerState()),
      );
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      await game.debugOpenBattleForTest(_wildRequest(manifest, map));
      await game.debugWaitForBattleOverlaySync();

      final overlay = game.debugBattleOverlayComponent!;
      expect(overlay.currentMenuMode, BattleCommandMenuMode.root);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
        reason: 'an unhandled press means the whole vector measures nothing',
      );
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.primary),
      );
      expect(overlay.currentMenuMode, BattleCommandMenuMode.fight);
      _press(game, RuntimeInputControl.secondary);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.root);

      // La croix atteint une AUTRE commande racine, prouvée par le sous-menu
      // différent qu'elle ouvre. Sans ce pas, une croix inerte passerait pour
      // fonctionnelle — et un sabotage du routage de `right` resterait muet,
      // ce qui est exactement arrivé à une version précédente de ce test.
      _press(game, RuntimeInputControl.right);
      _press(game, RuntimeInputControl.primary);
      expect(
        overlay.currentMenuMode,
        isNot(BattleCommandMenuMode.fight),
        reason: 'the d-pad must reach a command other than FIGHT',
      );
      expect(overlay.currentMenuMode, isNot(BattleCommandMenuMode.root));
      _press(game, RuntimeInputControl.secondary);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.root);

      // Start reste hors de Flame : il appartient au shell joueur, donc une
      // manette ne doit pas ouvrir d'UI produit depuis l'intérieur du jeu.
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.menu),
        ),
        isFalse,
      );

      // La croix atteint une AUTRE commande racine, prouvée par le sous-menu
      // différent qu'elle ouvre. Sans ce pas, une croix inerte passerait pour
      // fonctionnelle.
      _press(game, RuntimeInputControl.right);
      _press(game, RuntimeInputControl.primary);
      expect(
        overlay.currentMenuMode,
        isNot(BattleCommandMenuMode.fight),
        reason: 'the d-pad must reach a command other than FIGHT',
      );
      expect(overlay.currentMenuMode, isNot(BattleCommandMenuMode.root));

      _press(game, RuntimeInputControl.secondary);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.root);
    });

    test('reduced motion shortens the turn presentation without skipping it',
        () async {
      // DÉCISION PRODUIT (Yoahn, 2026-08-20) : raccourcir, pas sauter. La mesure
      // est donc le NOMBRE D'IMAGES qu'il faut pour que la présentation du tour
      // se termine — pas la présence d'un champ, qui ne prouverait rien.
      //
      // Le tour est déclenché par le chemin manette certifié juste au-dessus :
      // primary ouvre FIGHT, primary confirme la capacité.
      //
      // RÉSERVE SUR CE QUE CE CAS PROUVE, mesurée par sabotage. L'observable est
      // `isTurnPresentationActive`, qui lit l'horloge du RUNNER. Il distingue
      // donc « la scène avance plus vite » de « elle n'avance pas », mais PAS
      // « phases raccourcies » de « phases ET visuels raccourcis » : scaler le
      // seul runner laisse ce cas vert alors que les effets seraient coupés en
      // cours de route, c'est-à-dire sautés en apparence. C'est pour ça que
      // l'implémentation met `super.update` à l'échelle aussi — voir le
      // commentaire de `motionScale` — mais cette moitié-là n'est pas prouvée
      // ici, faute d'observable sur la durée de vie des effets visuels.
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();

      final normalFrames = await _framesToFinishTurnPresentation(
        projectRoot: tempProjectRoot,
        manifest: manifest,
        map: map,
        reducedMotion: false,
      );
      final reducedFrames = await _framesToFinishTurnPresentation(
        projectRoot: tempProjectRoot,
        manifest: manifest,
        map: map,
        reducedMotion: true,
      );

      expect(
        normalFrames,
        greaterThan(1),
        reason: 'a presentation that never runs would make this vacuous',
      );
      expect(
        reducedFrames,
        lessThan(normalFrames),
        reason: 'reduced motion must shorten the presentation',
      );
      expect(
        reducedFrames,
        greaterThan(0),
        reason: 'shortened, not skipped: the presentation still happens',
      );
    });

    test('PlayableMapGame opens PSDK battle for legacy-filtered PSDK moves',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );
      const initialState = GameState(
        saveId: 'wild-flow-psdk-save',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 10,
              knownMoveIds: <String>['wrap', 'coil'],
              currentPpByMoveId: <String, int>{'wrap': 20, 'coil': 20},
              currentHp: 20,
            ),
          ],
        ),
      );
      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(initialState),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugBattleOverlayMounted, isTrue);
      expect(game.debugPsdkBattleSessionActive, isTrue);
      expect(game.debugBattleSessionSnapshot, isNotNull);
      expect(
        game.debugBattleSessionSnapshot!.state.player.moves.map(
          (move) => move.id,
        ),
        equals(<String>['wrap', 'coil']),
      );
      expect(
        game.debugBattleSessionSnapshot!.state.player.moves.first.currentPp,
        equals(20),
      );

      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      expect(overlay!.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.fight);
      expect(overlay.validateSelectedChoice(), isTrue);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugPsdkBattleSessionActive, isTrue);
      expect(
        game.debugBattleSessionSnapshot!.state.player.moves.first.currentPp,
        equals(19),
      );
    });

    test('PlayableMapGame can capture from a PSDK battle', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );
      const initialState = GameState(
        saveId: 'wild-flow-psdk-capture-save',
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'poke-ball', quantity: 2),
          ],
        ),
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 10,
              knownMoveIds: <String>['wrap', 'coil'],
              currentHp: 20,
            ),
          ],
        ),
      );
      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(initialState),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugPsdkBattleSessionActive, isTrue);
      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      overlay!.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isTrue);
      await game.debugWaitForBattleOverlaySync();

      for (var i = 0; i < 40 && overlay.isTurnPresentationActive; i++) {
        game.update(0.25);
        await Future<void>.delayed(Duration.zero);
      }

      final afterFailedAttempt = game.gameStateSnapshot;
      expect(game.debugFlowPhaseName, equals('battle'));
      expect(game.debugBattleSessionSnapshot!.state.enemy.maxHp, equals(19));
      expect(afterFailedAttempt.party.members, hasLength(1));
      expect(
        afterFailedAttempt.bag.entries.single.quantity,
        equals(1),
      );

      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      // BETA-ENC-002. L'individu que le RUNTIME a généré pour ce combat, lu
      // avant la capture parce que le contexte de combat est libéré à la
      // fermeture. C'est le seul point d'observation possible : la requête
      // enfilée par la rencontre ne porte pas encore d'individu, le générateur
      // canonique ne tourne que dans hydrateWildRequest.
      final fought = (game.debugActiveBattleRequest! as WildBattleStartRequest)
          .generatedPokemon!;
      expect(game.selectBattleBagEntry(0), isTrue);
      await game.debugWaitForBattleOverlaySync();

      await _acknowledgePostBattleAndWaitForOverworld(game);

      final snapshot = game.gameStateSnapshot;
      expect(snapshot.bag.entries, isEmpty);
      expect(game.debugFlowPhaseName, equals('overworld'));
      expect(game.debugPsdkBattleSessionActive, isFalse);
      expect(snapshot.party.members, hasLength(2));
      final capturedPokemon = snapshot.party.members.last;
      expect(capturedPokemon.speciesId, equals('sparkitten'));
      expect(canonicalPokemonNatureIds, contains(capturedPokemon.natureId));
      expect(capturedPokemon.gender, anyOf('male', 'female'));
      expect(capturedPokemon.ivs, isNot(const PokemonStatSpread()));

      // BETA-ENC-002, le critère « encounter-to-battle identity » et
      // « captured identity equality » dans le VRAI parcours.
      //
      // Les quatre assertions ci-dessus ne mesuraient que la PLAUSIBILITÉ :
      // une nature du catalogue, un genre valide, des IV non nuls. Mesuré par
      // sabotage le 2026-08-20 — en faisant capturer un AUTRE individu, avec un
      // individualId inventé et des IV substitués mais tout aussi plausibles,
      // les 22 cas de ce fichier restaient VERTS. L'égalité d'identité n'était
      // couverte qu'au niveau unitaire, sur un generatedPokemon posé à la main
      // dans runtime_battle_outcome_apply_test, donc jamais sur celui que le
      // runtime fabrique lui-même.
      //
      // Les champs comparés ici sont ceux qu'un combat ne doit PAS pouvoir
      // changer. Les PV, le statut et les PP en sont exclus exprès : eux
      // changent légitimement, et c'est le write-back qui en répond ailleurs.
      // Seuls les champs que cette fixture sait DISCRIMINER sont ici. Mesuré :
      // l'individu généré vaut form='', shiny=false, heldItem='' et des EV
      // nuls, qui sont exactement les valeurs de repli — les asserter ne
      // pourrait donc pas échouer. Sabotage à l'appui : forcer isShiny à false
      // laissait les 22 cas verts. Ces champs exotiques sont couverts par
      // runtime_battle_outcome_apply_test, qui les pose à la main
      // (formId 'midnight', isShiny true) et peut donc les mesurer.
      //
      // `experience` est exclu pour une autre raison, et elle est plus vicieuse :
      // PlayerPokemonHydrator fait `experience ??= totalExperienceForLevel`, donc
      // perdre la valeur générée la fait recalculer depuis le niveau et retomber
      // sur la même. Les deux côtés dérivent du niveau : l'assertion ne pouvait
      // pas échouer. Vérifié en la sabotant.
      expect(capturedPokemon.individualId, fought.individualId);
      expect(capturedPokemon.individualId, isNotEmpty);
      expect(capturedPokemon.speciesId, fought.speciesId);
      expect(capturedPokemon.natureId, fought.natureId);
      expect(capturedPokemon.abilityId, fought.abilityId);
      expect(capturedPokemon.gender, fought.gender);
      expect(capturedPokemon.ivs, fought.ivs);
      expect(capturedPokemon.level, fought.level);
      expect(capturedPokemon.friendship, 50);
      expect(capturedPokemon.provenance?.mapId, 'field_map');
      expect(capturedPokemon.provenance?.sourceId, 'field_grass');
      expect(capturedPokemon.provenance?.ballItemId, 'poke-ball');
      expect(capturedPokemon.provenance?.metLevel, capturedPokemon.level);
      expect(snapshot.progression.caughtSpeciesIds, contains('sparkitten'));

      final reloaded = gameStateFromSaveData(saveDataFromGameState(snapshot));
      expect(reloaded.bag.entries, isEmpty);
      expect(reloaded.party.members.last.speciesId, equals('sparkitten'));
      expect(reloaded.party.members.last, capturedPokemon);
      expect(reloaded.progression.caughtSpeciesIds, contains('sparkitten'));
    });

    test('PlayableMapGame can use a potion in a PSDK battle', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );
      const initialState = GameState(
        saveId: 'wild-flow-psdk-potion-save',
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', quantity: 1),
          ],
        ),
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 10,
              knownMoveIds: <String>['wrap', 'coil'],
              currentHp: 12,
            ),
          ],
        ),
      );
      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(initialState),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugPsdkBattleSessionActive, isTrue);
      final initialBattleHp =
          game.debugBattleSessionSnapshot!.state.player.currentHp;
      expect(initialBattleHp, equals(12));

      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      overlay!.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bagMedicineTarget);
      expect(overlay.validateSelectedChoice(), isTrue);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugFlowPhaseName, equals('battle'));
      expect(game.debugPsdkBattleSessionActive, isTrue);
      expect(game.gameStateSnapshot.bag.entries, isEmpty);
      expect(
        game.gameStateSnapshot.party.members.first.currentHp,
        equals(game.debugBattleSessionSnapshot!.state.player.currentHp),
      );
      expect(
        game.debugBattleSessionSnapshot!.state.player.currentHp,
        greaterThan(initialBattleHp),
      );
    });

    test('PlayableMapGame can run from a PSDK battle', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );
      const initialState = GameState(
        saveId: 'wild-flow-psdk-run-save',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 10,
              knownMoveIds: <String>['wrap', 'coil'],
              currentHp: 20,
            ),
          ],
        ),
      );
      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(initialState),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugPsdkBattleSessionActive, isTrue);
      // BETA-BAT-020 : le pont donnée → combat. Le typing authoré des
      // species du projet doit arriver jusqu'à la session, sinon toute
      // l'efficacité (messages, sons hitplus/hitlow) est silencieusement
      // neutre en jeu réel.
      final battleState = game.debugBattleSessionSnapshot!.state;
      expect(
        battleState.player.typing?.types,
        contains('grass'),
        reason: 'sproutle est typé grass dans la donnée du projet',
      );
      expect(
        battleState.enemy.typing?.types,
        contains('fire'),
        reason: 'sparkitten est typé fire dans la donnée du projet',
      );
      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      final activeOverlay = overlay!;
      for (var i = 0; i < 12 && !activeOverlay.commandPanelMounted; i++) {
        game.update(0.05);
        await Future<void>.delayed(Duration.zero);
      }
      expect(activeOverlay.commandPanelMounted, isTrue);

      expect(
        game.selectBattleRootEntry(BattleCommandRootAction.run.index),
        isTrue,
      );
      await game.debugWaitForBattleOverlaySync();

      await _acknowledgePostBattleAndWaitForOverworld(game);

      expect(game.debugFlowPhaseName, equals('overworld'));
      expect(game.debugPsdkBattleSessionActive, isFalse);
      expect(game.debugBattleOverlayComponent, isNull);
    });

    test(
        'wild victory with a pending move learning decides IN the scene and '
        'commits the learned move', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      // Quatre capacités connues : sous ce plafond, l'apprentissage est
      // automatique et aucune décision n'est posée — le test veut la boucle
      // complète Apprendre → choisir la capacité à remplacer.
      final strongPlayerState = GameState(
        saveId: 'wild-flow-save',
        party: const PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 10,
              knownMoveIds: <String>['vine_whip', 'scratch', 'wrap', 'coil'],
              currentPpByMoveId: <String, int>{
                'vine_whip': 35,
                'scratch': 35,
                'wrap': 20,
                'coil': 20,
              },
              currentHp: 20,
            ),
          ],
        ),
      );
      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(strongPlayerState),
        postBattleDecisionCoordinator: RuntimePostBattleDecisionCoordinator(
          resolveReward: _pendingMoveLearningResolution,
        ),
        runtimePlayerPokemonProgressionCatalogLoader:
            _progressionCatalogsForScene,
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();
      final overlay = game.debugBattleOverlayComponent!;

      // Gagner le combat par le vrai chemin de commandes.
      for (var turn = 0; turn < 25; turn++) {
        for (var i = 0;
            i < 80 &&
                (overlay.isTurnPresentationActive ||
                    !overlay.acceptsPlayerCommands);
            i++) {
          game.update(0.25);
          await Future<void>.delayed(Duration.zero);
        }
        final session = game.debugBattleSessionSnapshot;
        if (session == null || session.state.isFinished) break;
        // Le menu revient en racine ou reste sur les capacités selon le
        // tour : ouvrir ATTAQUER si possible, puis confirmer la capacité.
        if (game.selectBattleRootEntry(0)) {
          await game.debugWaitForBattleOverlaySync();
        }
        expect(game.selectBattleChoiceEntry(0), isTrue,
            reason: 'première capacité (tour $turn)');
        await game.debugWaitForBattleOverlaySync();
      }
      expect(
        game.debugBattleSessionSnapshot!.state.outcome?.isVictory,
        isTrue,
        reason: 'sproutle 10 doit battre sparkitten 6',
      );

      // BETA-BAT-017 sous-lot 2 : la décision d'apprentissage s'affiche dans
      // le panneau de la SCÈNE, jamais sur l'écran plein de progression.
      BattleCommandOverlaySnapshot? decisionSnapshot;
      for (var i = 0; i < 200; i++) {
        expect(game.debugPostBattleOverlayMounted, isFalse,
            reason: 'l’écran plein ne doit jamais se monter sur ce flux');
        final snapshot = game.battleCommandOverlayListenable.value;
        if (snapshot != null &&
            snapshot.interactionsEnabled &&
            snapshot.prompt.contains('peut apprendre')) {
          decisionSnapshot = snapshot;
          break;
        }
        game.update(0.25);
        await Future<void>.delayed(Duration.zero);
      }
      expect(decisionSnapshot, isNotNull,
          reason: 'le prompt d’apprentissage doit s’afficher dans la scène');
      expect(
        decisionSnapshot!.entries.map((entry) => entry.primaryLabel),
        <String>['Apprendre', 'Ne pas apprendre'],
      );

      // Le choix passe par le vrai contrat du shell joueur.
      expect(
        game.dispatchBattlePresentationCommand(
          BattleSelectEntryCommand(
            snapshotRevision: decisionSnapshot.revision,
            expectedMode: decisionSnapshot.mode,
            entryIndex: 0,
          ),
        ),
        isTrue,
        reason: 'Apprendre',
      );

      // Deuxième décision de la même boucle : la capacité à remplacer,
      // libellée par le catalogue du projet.
      BattleCommandOverlaySnapshot? replacementSnapshot;
      for (var i = 0; i < 200; i++) {
        expect(game.debugPostBattleOverlayMounted, isFalse);
        final snapshot = game.battleCommandOverlayListenable.value;
        if (snapshot != null &&
            snapshot.interactionsEnabled &&
            snapshot.prompt.contains('capacité à remplacer')) {
          replacementSnapshot = snapshot;
          break;
        }
        game.update(0.25);
        await Future<void>.delayed(Duration.zero);
      }
      expect(replacementSnapshot, isNotNull,
          reason: 'le choix de la capacité à remplacer suit dans la scène');
      expect(
        replacementSnapshot!.entries.map((entry) => entry.primaryLabel),
        <String>['Vine Whip', 'Scratch', 'Wrap', 'Coil', 'Ne pas apprendre'],
      );
      expect(
        game.dispatchBattlePresentationCommand(
          BattleSelectEntryCommand(
            snapshotRevision: replacementSnapshot.revision,
            expectedMode: replacementSnapshot.mode,
            entryIndex: 0,
          ),
        ),
        isTrue,
        reason: 'remplacer Vine Whip',
      );

      await _acknowledgePostBattleAndWaitForOverworld(game);

      final committed = game.gameStateSnapshot;
      expect(
        committed.party.members.single.knownMoveIds,
        contains('quick_attack'),
        reason: 'la capacité apprise via les décisions en scène est commitée',
      );
      expect(
        committed.party.members.single.knownMoveIds,
        isNot(contains('vine_whip')),
        reason: 'Vine Whip a été remplacée',
      );
      expect(committed.trainerProfile.money, 100);
      expect(game.debugFlowPhaseName, equals('overworld'));
      expect(game.debugPsdkBattleSessionActive, isFalse);
    });

    test('wild capture is disabled when the player has no poke-ball', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(
          bag: const Bag(),
        ),
        request: request,
      );

      expect(setup.allowCapture, isFalse);
    });

    test('capture choice produces a persistent captured pokemon', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      expect(setup.allowCapture, isTrue);

      final stateWithSeen = markSpeciesSeenInGameState(
        _playerState(),
        setup.enemyPokemon.speciesId,
      );
      final context = RuntimeActiveBattleContext(
        request: request,
        playerPartyIndex: 0,
      );
      final attempt = submitRuntimeBattleCaptureAttempt<BattleSession>(
        gameState: stateWithSeen,
        context: context,
        captureAllowed: setup.allowCapture,
        itemId: canonicalPokeBallItemId,
        itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
        submitToEngine: () => createBattleSession(
          setup,
          rng: const BattleScriptedRng(<int>[1]),
        ).applyChoice(const PlayerBattleChoiceCapture()),
      );
      final outcome = attempt.engineResult.state.outcome!;

      expect(outcome.isCaptured, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: attempt.updatedGameState,
        context: context,
        outcome: outcome,
        captureAttemptReceipt: attempt.receipt,
      );

      expect(updatedState.party.members, hasLength(2));
      final captured = updatedState.party.members.last;
      expect(captured.speciesId, equals('sparkitten'));
      expect(captured.level, equals(6));
      expect(captured.abilityId, equals('blaze'));
      expect(captured.natureId, equals('hardy'));
      expect(captured.knownMoveIds, equals(<String>['scratch']));
      expect(captured.currentHp, equals(outcome.finalState.enemy.currentHp));
      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'poke-ball', quantity: 1),
          ],
        ),
      );
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(updatedState.progression.caughtSpeciesIds, contains('sparkitten'));
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });

    test('wild battle can capture from BAG poke ball and return to overworld',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final initialState = _playerState();
      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: initialState,
        request: request,
      );
      final stateWithSeen = markSpeciesSeenInGameState(
        initialState,
        setup.enemyPokemon.speciesId,
      );
      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[1]),
      );

      PlayerBattleChoice? pickedChoice;
      final overlay = BattleOverlayComponent(
        session: session,
        gameState: stateWithSeen,
        itemCapabilityResolver: ItemCapabilityResolver(
          ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(pickedChoice, isA<PlayerBattleChoiceCapture>());

      final context = RuntimeActiveBattleContext(
        request: request,
        playerPartyIndex: 0,
      );
      final attempt = submitRuntimeBattleCaptureAttempt<BattleSession>(
        gameState: stateWithSeen,
        context: context,
        captureAllowed: setup.allowCapture,
        itemId: canonicalPokeBallItemId,
        itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
        submitToEngine: () => session.applyChoice(pickedChoice!),
      );
      final outcome = attempt.engineResult.state.outcome!;
      expect(outcome.isCaptured, isTrue);

      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(attempt.updatedGameState),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      game.debugApplyBattleOutcomeForTest(
        context: context,
        outcome: outcome,
        captureAttemptReceipt: attempt.receipt,
      );

      final snapshot = game.gameStateSnapshot;
      expect(game.debugFlowPhaseName, equals('overworld'));
      expect(snapshot.party.members, hasLength(2));
      expect(snapshot.party.members.last.speciesId, equals('sparkitten'));
      expect(
        snapshot.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'poke-ball', quantity: 1),
          ],
        ),
      );
      expect(snapshot.progression.caughtSpeciesIds, contains('sparkitten'));
    });

    test('wild battle BAG capture remains available when party is full',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final fullPartyState = _playerState().copyWith(
        party: PlayerParty(
          members: <PlayerPokemon>[
            ..._playerState().party.members,
            const PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['vine_whip'],
              currentPpByMoveId: <String, int>{'vine_whip': 35},
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['vine_whip'],
              currentPpByMoveId: <String, int>{'vine_whip': 35},
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['vine_whip'],
              currentPpByMoveId: <String, int>{'vine_whip': 35},
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['vine_whip'],
              currentPpByMoveId: <String, int>{'vine_whip': 35},
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['vine_whip'],
              currentPpByMoveId: <String, int>{'vine_whip': 35},
              currentHp: 10,
            ),
          ],
        ),
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: fullPartyState,
        request: request,
      );

      expect(setup.allowCapture, isTrue);

      PlayerBattleChoice? pickedChoice;
      final overlay = BattleOverlayComponent(
        session: createBattleSession(setup),
        gameState: fullPartyState,
        itemCapabilityResolver: ItemCapabilityResolver(
          ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(
          commandPanel.currentBagEntryLabels, const <String>['Poké Ball x2']);
      expect(commandPanel.currentBagStatusLabels, const <String>['OK']);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(pickedChoice, isA<PlayerBattleChoiceCapture>());
    });

    test('battle BAG potion use persists to PlayableMapGame state', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      const initialState = GameState(
        saveId: 'wild-flow-potion-save',
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', quantity: 1),
          ],
        ),
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 10,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 12,
            ),
          ],
        ),
      );

      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(initialState),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      expect(game.debugBattleSessionSnapshot, isNotNull);
      final initialBattleHp =
          game.debugBattleSessionSnapshot!.state.player.currentHp;
      final initialBattleMaxHp =
          game.debugBattleSessionSnapshot!.state.player.maxHp;
      final expectedHealedHp = min(initialBattleHp + 20, initialBattleMaxHp);

      overlay!.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bagMedicineTarget);
      expect(overlay.validateSelectedChoice(), isTrue);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugFlowPhaseName, equals('battle'));
      expect(game.debugBattleSessionSnapshot, isNotNull);
      final currentTurn = game.debugBattleSessionSnapshot!.state.currentTurn;
      expect(currentTurn, isNotNull);
      expect(
        currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemId,
          'itemKind',
          equals('potion'),
        ),
      );
      expect(currentTurn.bagHpHealItemEvents, hasLength(1));
      expect(
        currentTurn.bagHpHealItemEvents.single.itemId,
        equals('potion'),
      );
      expect(
        currentTurn.bagHpHealItemEvents.single.hpAfter,
        equals(expectedHealedHp),
      );
      expect(
        game.debugBattleSessionSnapshot!.state.player.currentHp,
        lessThanOrEqualTo(expectedHealedHp),
      );
      expect(
        game.gameStateSnapshot.party.members.first.currentHp,
        equals(game.debugBattleSessionSnapshot!.state.player.currentHp),
      );
      expect(game.gameStateSnapshot.bag.entries, isEmpty);
    });

    test('battle BAG super potion use persists to PlayableMapGame state',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      const initialState = GameState(
        saveId: 'wild-flow-super-potion-save',
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'super-potion',
              quantity: 1,
            ),
          ],
        ),
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 10,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 12,
            ),
          ],
        ),
      );

      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(initialState),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      expect(game.debugBattleSessionSnapshot, isNotNull);
      final initialBattleHp =
          game.debugBattleSessionSnapshot!.state.player.currentHp;
      final initialBattleMaxHp =
          game.debugBattleSessionSnapshot!.state.player.maxHp;
      final expectedHealedHp = min(initialBattleHp + 50, initialBattleMaxHp);

      overlay!.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bagMedicineTarget);
      expect(overlay.validateSelectedChoice(), isTrue);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugFlowPhaseName, equals('battle'));
      expect(game.debugBattleSessionSnapshot, isNotNull);
      final currentTurn = game.debugBattleSessionSnapshot!.state.currentTurn;
      expect(currentTurn, isNotNull);
      expect(
        currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemId,
          'itemKind',
          equals('super-potion'),
        ),
      );
      expect(currentTurn.bagHpHealItemEvents, hasLength(1));
      expect(
        currentTurn.bagHpHealItemEvents.single.itemId,
        equals('super-potion'),
      );
      expect(
        currentTurn.bagHpHealItemEvents.single.hpAfter,
        equals(expectedHealedHp),
      );
      expect(
        game.debugBattleSessionSnapshot!.state.player.currentHp,
        lessThanOrEqualTo(expectedHealedHp),
      );
      expect(
        game.gameStateSnapshot.party.members.first.currentHp,
        equals(game.debugBattleSessionSnapshot!.state.player.currentHp),
      );
      expect(game.gameStateSnapshot.bag.entries, isEmpty);
    });

    test('battle BAG hyper potion use persists to PlayableMapGame state',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      const initialState = GameState(
        saveId: 'wild-flow-hyper-potion-save',
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'hyper-potion',
              quantity: 1,
            ),
          ],
        ),
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 10,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 12,
            ),
          ],
        ),
      );

      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(initialState),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      expect(game.debugBattleSessionSnapshot, isNotNull);
      final initialBattleHp =
          game.debugBattleSessionSnapshot!.state.player.currentHp;
      final initialBattleMaxHp =
          game.debugBattleSessionSnapshot!.state.player.maxHp;
      final expectedHealedHp = min(initialBattleHp + 200, initialBattleMaxHp);

      overlay!.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bagMedicineTarget);
      expect(overlay.validateSelectedChoice(), isTrue);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugFlowPhaseName, equals('battle'));
      expect(game.debugBattleSessionSnapshot, isNotNull);
      final currentTurn = game.debugBattleSessionSnapshot!.state.currentTurn;
      expect(currentTurn, isNotNull);
      expect(
        currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemId,
          'itemKind',
          equals('hyper-potion'),
        ),
      );
      expect(currentTurn.bagHpHealItemEvents, hasLength(1));
      expect(
        currentTurn.bagHpHealItemEvents.single.itemId,
        equals('hyper-potion'),
      );
      expect(
        currentTurn.bagHpHealItemEvents.single.hpAfter,
        equals(expectedHealedHp),
      );
      expect(
        game.debugBattleSessionSnapshot!.state.player.currentHp,
        lessThanOrEqualTo(expectedHealedHp),
      );
      expect(
        game.gameStateSnapshot.party.members.first.currentHp,
        equals(game.debugBattleSessionSnapshot!.state.player.currentHp),
      );
      expect(game.gameStateSnapshot.bag.entries, isEmpty);
    });

    test('battle BAG max potion use persists to PlayableMapGame state',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      const initialState = GameState(
        saveId: 'wild-flow-max-potion-save',
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'max-potion',
              quantity: 1,
            ),
          ],
        ),
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 10,
              knownMoveIds: <String>['vine_whip'],
              currentHp: 12,
            ),
          ],
        ),
      );

      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(initialState),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      expect(game.debugBattleSessionSnapshot, isNotNull);
      final initialBattleMaxHp =
          game.debugBattleSessionSnapshot!.state.player.maxHp;

      overlay!.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bagMedicineTarget);
      expect(overlay.validateSelectedChoice(), isTrue);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugFlowPhaseName, equals('battle'));
      expect(game.debugBattleSessionSnapshot, isNotNull);
      final currentTurn = game.debugBattleSessionSnapshot!.state.currentTurn;
      expect(currentTurn, isNotNull);
      expect(
        currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>()
            .having(
              (action) => action.itemId,
              'itemKind',
              equals('max-potion'),
            )
            .having(
              (action) => action.effect,
              'effect',
              isA<BattleBagRestoreToFullHpHealEffect>(),
            ),
      );
      expect(currentTurn.bagHpHealItemEvents, hasLength(1));
      expect(
        currentTurn.bagHpHealItemEvents.single.itemId,
        equals('max-potion'),
      );
      expect(
        currentTurn.bagHpHealItemEvents.single.hpAfter,
        equals(initialBattleMaxHp),
      );
      expect(
        game.debugBattleSessionSnapshot!.state.player.currentHp,
        lessThanOrEqualTo(initialBattleMaxHp),
      );
      expect(
        game.gameStateSnapshot.party.members.first.currentHp,
        equals(game.debugBattleSessionSnapshot!.state.player.currentHp),
      );
      expect(game.gameStateSnapshot.bag.entries, isEmpty);
    });

    test(
        'battle end hands off from final narration to post-battle acknowledgement',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(_playerState()),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      final activeOverlay = overlay!;
      for (var i = 0; i < 12 && !activeOverlay.commandPanelMounted; i++) {
        game.update(0.05);
        await Future<void>.delayed(Duration.zero);
      }
      expect(activeOverlay.commandPanelMounted, isTrue);

      expect(
        game.selectBattleRootEntry(BattleCommandRootAction.run.index),
        isTrue,
      );
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugFlowPhaseName, equals('battle'));
      expect(game.debugBattleOverlayComponent, same(activeOverlay));
      // BETA-BAT-030 : le plan de TOUR n'annonce plus l'issue quand l'hôte
      // présente la fin dans la scène — il n'en reste que le SON de la fuite.
      // L'annonce vient du coordinator (« Vous prenez la fuite ! »), et ce
      // test la vérifie plus bas via `sawSceneFinaleMessage`. Auparavant,
      // « Tu as pris la fuite ! » s'affichait ICI puis le coordinator disait
      // la même chose : trois annonces pour une seule fuite en recette.
      expect(
        activeOverlay.currentPromptText,
        isNot(equals('Tu as pris la fuite !')),
        reason: 'plus de doublon d’annonce entre le tour et la scène',
      );

      // BETA-BAT-017 : le handoff ne passe plus par l'écran plein de
      // progression — la narration finale rend la main aux MESSAGES DU
      // COORDINATOR joués dans la scène, puis au fondu de sortie. Le combat
      // reste la phase active tant que la fin n'est pas committée.
      var sawSceneFinaleMessage = false;
      var sawExitCurtain = false;
      for (var i = 0; i < 120 && game.debugFlowPhaseName == 'battle'; i++) {
        expect(
          game.debugPostBattleOverlayMounted,
          isFalse,
          reason: 'un flux sans décision ne montre plus l’écran plein',
        );
        final battleOverlay = game.debugBattleOverlayComponent;
        if (battleOverlay != null &&
            (game.debugBattleSessionSnapshot?.state.isFinished ?? false) &&
            battleOverlay.debugCurrentAnimationMessage != null) {
          sawSceneFinaleMessage = true;
        }
        sawExitCurtain = sawExitCurtain || game.debugBattleExitCurtainMounted;
        game.update(0.25);
        await Future<void>.delayed(Duration.zero);
      }
      await game.debugWaitForPostBattleCompletion();

      expect(
        sawSceneFinaleMessage,
        isTrue,
        reason: 'la fin a joué ses messages dans la boîte de la scène',
      );
      expect(
        sawExitCurtain,
        isTrue,
        reason: 'la sortie de combat passe par le fondu au noir',
      );
      expect(game.debugFlowPhaseName, equals('overworld'));
      expect(game.debugBattleOverlayComponent, isNull);
      expect(game.debugPostBattleOverlayMounted, isFalse);
      for (var i = 0; i < 12 && game.debugBattleExitCurtainMounted; i++) {
        game.update(0.25);
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        game.debugBattleExitCurtainMounted,
        isFalse,
        reason: 'le fondu s’ouvre sur l’overworld puis se retire',
      );

      // Recette 2026-08-24 : une publication TARDIVE de l'overlay démonté
      // (course post-frame sur device) laissait le panneau « Combat
      // terminé. » et les HUD flotter sur l'overworld jusqu'au prochain
      // resize. Un overlay zombie qui republie ne doit plus avoir voix au
      // chapitre.
      expect(game.battleCommandOverlayListenable.value, isNull);
      activeOverlay.setPreferTouchListDragScroll(true);
      activeOverlay.updateTree(0.25);
      await Future<void>.delayed(Duration.zero);
      expect(
        game.battleCommandOverlayListenable.value,
        isNull,
        reason: 'le snapshot d’un overlay démonté est ignoré — le panneau de '
            'combat ne ressuscite pas sur l’overworld',
      );
    });

    test('battle overlay reflows when PlayableMapGame viewport changes',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final game = PlayableMapGame(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
        saveData: saveDataFromGameState(_playerState()),
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      await game.debugOpenBattleForTest(request);
      await game.debugWaitForBattleOverlaySync();

      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      expect(overlay!.currentSceneLayout.isPortrait, isFalse);

      game.onGameResize(Vector2(390, 844));
      await game.debugWaitForBattleOverlaySync();

      expect(overlay.currentSceneLayout.isPortrait, isTrue);
      expect(
        overlay.currentSceneLayout.commandPanelLayoutMode,
        equals(BattleCommandPanelLayoutMode.stacked),
      );
    });
  });
}

/// Suit la fin de combat jusqu'au retour en overworld.
///
/// Ce helper porte un critère d'acceptation de BETA-BAT-007 : « l'overlay se
/// ferme uniquement après résultat appliqué ». Tant qu'une fin de combat se
/// joue — messages dans la scène ou écran de progression — le runtime ne doit
/// PAS être déjà revenu en overworld, sinon le joueur reprend la main pendant
/// qu'un écran de fin flotte encore, ou pire, avant que le résultat soit
/// écrit.
///
/// BETA-BAT-017 : le vecteur nominal est désormais la SCÈNE — les messages du
/// coordinator joués dans la boîte de dialogue du combat, puis le fondu de
/// sortie. [expectScenePresentation] verrouille ce vecteur : l'écran plein de
/// progression ne doit plus jamais s'afficher sur un flux sans décision, et
/// le fondu doit s'être réellement joué puis retiré. Passer false pour un
/// flux qui attend encore l'écran plein (décisions du sous-lot 2).
Future<void> _acknowledgePostBattleAndWaitForOverworld(
  PlayableMapGame game, {
  bool expectScenePresentation = true,
}) async {
  var sawPostBattleOverlay = false;
  var sawSceneFinaleMessage = false;
  var sawExitCurtain = false;
  for (var tick = 0; tick < 240; tick++) {
    if (game.debugPostBattleOverlayMounted) {
      sawPostBattleOverlay = true;
      expect(
        game.debugFlowPhaseName,
        isNot('overworld'),
        reason: 'the overworld resumed while post-battle progression was '
            'still waiting to be acknowledged',
      );
      expect(game.debugValidatePostBattleChoice(), isTrue);
    }
    final battleOverlay = game.debugBattleOverlayComponent;
    if (battleOverlay != null &&
        (game.debugBattleSessionSnapshot?.state.isFinished ?? false) &&
        battleOverlay.debugCurrentAnimationMessage != null) {
      sawSceneFinaleMessage = true;
    }
    sawExitCurtain = sawExitCurtain || game.debugBattleExitCurtainMounted;
    if (game.debugFlowPhaseName == 'overworld') {
      await game.debugWaitForPostBattleCompletion();
      if (expectScenePresentation) {
        expect(
          sawPostBattleOverlay,
          isFalse,
          reason: 'BETA-BAT-017 : un flux sans décision ne montre plus '
              'l’écran plein de progression — la fin se joue dans la scène',
        );
        expect(
          sawSceneFinaleMessage,
          isTrue,
          reason: 'la fin doit avoir joué au moins un message dans la boîte '
              'de dialogue de la scène de combat',
        );
        expect(
          sawExitCurtain,
          isTrue,
          reason: 'la sortie de combat passe par le fondu au noir',
        );
        for (var i = 0; i < 12 && game.debugBattleExitCurtainMounted; i++) {
          game.update(0.25);
          await Future<void>.delayed(Duration.zero);
        }
        expect(
          game.debugBattleExitCurtainMounted,
          isFalse,
          reason: 'le fondu s’ouvre sur l’overworld puis se retire — un '
              'rideau orphelin laisserait un écran noir éternel',
        );
      } else {
        expect(
          sawPostBattleOverlay,
          isTrue,
          reason: 'this flow never showed the post-battle overlay, so the '
              'invariant above never ran',
        );
      }
      return;
    }
    game.update(0.25);
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Post-battle flow did not return to overworld '
    '(phase=${game.debugFlowPhaseName}, '
    'postBattle=${game.debugPostBattleOverlayMounted}).',
  );
}

/// Nombre d'images nécessaires pour épuiser la présentation d'un tour.
///
/// Le tour est lancé par le chemin manette : primary ouvre FIGHT, primary
/// confirme. On compte ensuite les images jusqu'à ce que la présentation rende
/// la main.
Future<int> _framesToFinishTurnPresentation({
  required Directory projectRoot,
  required ProjectManifest manifest,
  required MapData map,
  required bool reducedMotion,
}) async {
  final game = _LoadedGame(
    bundle: _buildBundle(projectRoot.path, manifest, map),
    projectFilePath: p.join(projectRoot.path, 'project.json'),
    saveData: saveDataFromGameState(_playerState()),
    reducedMotion: reducedMotion,
  );
  game.onGameResize(Vector2(960, 540));
  await game.onLoad();
  await game.debugOpenBattleForTest(_wildRequest(manifest, map));
  await game.debugWaitForBattleOverlaySync();

  final overlay = game.debugBattleOverlayComponent!;
  _press(game, RuntimeInputControl.primary);
  _press(game, RuntimeInputControl.primary);
  await game.debugWaitForBattleOverlaySync();

  var frames = 0;
  while (overlay.isTurnPresentationActive && frames < 4000) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    frames += 1;
  }
  return frames;
}

/// Jeu qui se déclare chargé, pour que le routage des entrées s'exécute.
final class _LoadedGame extends PlayableMapGame {
  _LoadedGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.reducedMotion,
  });

  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loaded = true;
  }
}

/// Presse puis relâche un contrôle, comme le ferait un pad.
void _press(PlayableMapGame game, RuntimeInputControl control) {
  game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
}

WildBattleStartRequest _wildRequest(ProjectManifest manifest, MapData map) {
  return buildBattleStartRequestFromEncounter(
    encounter: const GameplayEncounter(
      mapId: 'field_map',
      sourceId: 'encounter_grass',
      sourceKind: EncounterSourceKind.gameplayZone,
      tableId: 'field_grass',
      encounterKind: EncounterKind.walk,
      speciesId: 'sparkitten',
      level: 6,
      minLevel: 6,
      maxLevel: 6,
      weight: 1,
      playerPos: GridPos(x: 1, y: 0),
    ),
    world: GameplayWorldState.fromMap(
      map,
      project: manifest,
      tileWidth: 16,
      tileHeight: 16,
    ),
    createdAtEpochMs: 1,
  );
}

/// Catalogues d'hydratation synthétiques : la progression du test propose
/// quick_attack, absent des données du bundle de flux — sans ce loader,
/// l'hydratation échoue et la fin de combat retombe sur l'écran d'échec.
Future<RuntimePlayerPokemonProgressionCatalogs> _progressionCatalogsForScene({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  return const RuntimePlayerPokemonProgressionCatalogs(
    speciesById: <String, PlayerPokemonHydrationSpecies>{
      'sproutle': PlayerPokemonHydrationSpecies(
        id: 'sproutle',
        baseStats: PokemonBaseStats(
          hp: 45,
          attack: 49,
          defense: 49,
          specialAttack: 65,
          specialDefense: 65,
          speed: 45,
        ),
        primaryAbilityId: 'overgrow',
        abilityIds: <String>['overgrow'],
        growthRateId: 'medium',
      ),
    },
    maxPpByMoveId: <String, int>{
      'vine_whip': 35,
      'scratch': 35,
      'wrap': 20,
      'coil': 20,
      'quick_attack': 30,
    },
  );
}

/// Progression synthétique : la victoire sauvage rapporte assez d'Exp. pour
/// proposer quick_attack à sproutle — le vrai resolver du runtime dépend des
/// catalogues d'espèces du bundle, hors du périmètre de ce test de flux.
Future<RuntimeBattleRewardResolution> _pendingMoveLearningResolution({
  required RuntimeMapBundle bundle,
  required GameState postWriteBackState,
  required RuntimeActiveBattleContext runtimeContext,
  required BattleOutcome outcome,
}) async {
  final reward = BattleReward(
    sourceKind: BattleRewardSourceKind.trainer,
    trainerId: 'wild_bonus',
    money: 100,
  );
  final context = BattleProgressionContext(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    outcome: BattleProgressionOutcomeKind.victory,
    playerParticipantPartySlots: const <int>{0},
    // Assez d'Exp. pour traverser le niveau 11 : la candidate ne se propose
    // que si la montée de niveau franchit son learnedAtLevel.
    defeatedOpponents: const <BattleProgressionDefeatedOpponent>[
      BattleProgressionDefeatedOpponent(level: 14, baseExperience: 200),
    ],
    partySlotMetadata: const <BattleProgressionPartySlotMetadata>[
      BattleProgressionPartySlotMetadata(
        partySlot: 0,
        growthRateId: 'medium',
        oldMaxHp: 30,
        baseStats: PokemonBaseStats(
          hp: 45,
          attack: 49,
          defense: 49,
          specialAttack: 65,
          specialDefense: 65,
          speed: 45,
        ),
      ),
    ],
    moveLearningCandidatesByPartySlot: const <int,
        Iterable<PokemonMoveLearningCandidate>>{
      0: <PokemonMoveLearningCandidate>[
        PokemonMoveLearningCandidate(
          opportunityId: 'sproutle:11:quick_attack',
          moveId: 'quick_attack',
          learnedAtLevel: 11,
          maxPp: 30,
        ),
      ],
    },
  );
  return RuntimeBattleRewardResolution(
    baseState: postWriteBackState,
    reward: reward,
    progressionContext: context,
    progression: const BattleProgressionService().apply(
      state: postWriteBackState,
      context: context,
      reward: reward,
      applyAuthoredRewards: false,
    ),
  );
}

GameState _playerState({
  Bag bag = const Bag(
    entries: <BagEntry>[
      BagEntry(itemId: 'poke-ball', quantity: 2),
    ],
  ),
  String statusId = '',
  int vineWhipPp = 35,
  int currentHp = 20,
}) {
  return GameState(
    saveId: 'wild-flow-save',
    bag: bag,
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 10,
          knownMoveIds: const <String>['vine_whip'],
          currentPpByMoveId: <String, int>{'vine_whip': vineWhipPp},
          currentHp: currentHp,
          statusId: statusId,
        ),
      ],
    ),
  );
}

MapData _buildMap() {
  return const MapData(
    id: 'field_map',
    name: 'Field Map',
    size: GridSize(width: 4, height: 3),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_start',
        name: 'Spawn Start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      MapGameplayZone(
        id: 'encounter_grass',
        name: 'Encounter Grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
        encounter: EncounterZonePayload(
          encounterTableId: 'field_grass',
          encounterKind: EncounterKind.walk,
        ),
      ),
    ],
    mapMetadata: MapMetadata(
      defaultSpawnId: 'spawn_start',
    ),
  );
}

RuntimeMapBundle _buildBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
  MapData map,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

Future<ProjectManifest> _writeProjectManifest(Directory projectRoot) async {
  const manifest = ProjectManifest(
    name: 'Wild Battle Flow Test',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'field_grass',
        name: 'Field Grass',
        encounterKind: EncounterKind.walk,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'sparkitten',
            minLevel: 6,
            maxLevel: 6,
            weight: 1,
          ),
        ],
      ),
    ],
    pokemon: ProjectPokemonConfig(
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      dataRoot: 'data/pokemon',
      speciesDir: 'data/pokemon/species',
      learnsetsDir: 'data/pokemon/learnsets',
      evolutionsDir: 'data/pokemon/evolutions',
      mediaDir: 'data/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'data/pokemon/catalogs/moves.json',
        'items': 'data/pokemon/catalogs/items.json',
      },
    ),
  );

  await File(
    p.join(projectRoot.path, 'project.json'),
  ).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()));
  await _writePokemonFixtures(projectRoot);
  return manifest;
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 25,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 305,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 76,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'startingMoves': <String>['vine_whip'],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Wild battle flow test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('vine_whip', 'Vine Whip', 12, type: 'grass'),
        _moveEntry('scratch', 'Scratch', 5),
        _moveEntry(
          'wrap',
          'Wrap',
          15,
          pp: 20,
          accuracy: 90,
          effects: const <PokemonMoveEffect>[
            PokemonMoveEffect.applyVolatileStatus(
              targetScope: PokemonMoveEffectTargetScope.target,
              volatileStatusId: 'bind',
            ),
          ],
        ),
        _moveEntry(
          'coil',
          'Coil',
          0,
          type: 'poison',
          target: PokemonMoveTarget.self,
          pp: 20,
          effects: const <PokemonMoveEffect>[
            PokemonMoveEffect.modifyStats(
              targetScope: PokemonMoveEffectTargetScope.self,
              stageChanges: <PokemonMoveStatStageChange>[
                PokemonMoveStatStageChange(
                  stat: PokemonMoveStatId.attack,
                  stages: 1,
                ),
                PokemonMoveStatStageChange(
                  stat: PokemonMoveStatId.defense,
                  stages: 1,
                ),
                PokemonMoveStatStageChange(
                  stat: PokemonMoveStatId.accuracy,
                  stages: 1,
                ),
              ],
            ),
          ],
        ),
      ],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/catalogs/items.json',
    mvpItemCatalog.toJson(),
  );
}

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  String type = 'normal',
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int pp = 35,
  int accuracy = 100,
  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
}) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.physical,
    target: target,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : PokemonMoveAccuracy.percent(value: accuracy),
    pp: pp,
    effects: effects,
    engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
  ).toJson();
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

class _FixedEncounterRandom implements Random {
  _FixedEncounterRandom({
    required this.nextDoubleValues,
    required this.nextIntValues,
  });

  final List<double> nextDoubleValues;
  final List<int> nextIntValues;
  int _doubleIndex = 0;
  int _intIndex = 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() {
    if (nextDoubleValues.isEmpty) {
      return 0.0;
    }
    final index = _doubleIndex < nextDoubleValues.length
        ? _doubleIndex++
        : nextDoubleValues.length - 1;
    return nextDoubleValues[index];
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be > 0');
    }
    if (nextIntValues.isEmpty) {
      return 0;
    }
    final index = _intIndex < nextIntValues.length
        ? _intIndex++
        : nextIntValues.length - 1;
    return nextIntValues[index] % max;
  }
}
