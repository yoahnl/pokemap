import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

import 'support/golden_gate_hosts.dart';

/// Golden gate Rencontres & capture — BETA-ENC-006.
///
/// Depuis un package exporté puis installé — espace auteur et archive
/// SUPPRIMÉS, réseau qui jette — un joueur marche dans l'herbe, déclenche une
/// rencontre déterminée par les données (100 % par pas, une espèce, un niveau,
/// IVs figés), rate une capture avec la Poké Ball 1/1 (échec certain au seed
/// générique du runtime), fuit, retourne dans l'herbe, capture avec la Ball
/// 17/1 (garantie mathématique : 17 × 45 = 765, le plafond du dénominateur à
/// PV pleins), et retrouve après save + reload le même individu, le Pokédex
/// cohérent, et sa position overworld.
///
/// Tout passe par les canaux production : la marche par RuntimeInputEvent
/// (le canal du clavier), le combat par les entrées du panneau de commandes,
/// la sauvegarde par le canal pause du coordinateur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'golden journey: encounter, failed ball, flee, guaranteed capture, reload',
    timeout: const Timeout(Duration(minutes: 4)),
    () async => HttpOverrides.runZoned(
      () async {
        final root = await Directory.systemTemp.createTemp(
          'pokemap-golden-encounter-',
        );
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        const fixture = NeutralCertificationGameFixture(encounterField: true);
        final host = await GoldenGateHost.launch(
          fixture: fixture,
          root: root,
          profileId: 'player1',
          slotId: 'slot1',
        );
        addTearDown(host.dispose);

        await host.startNewGame();
        final game = host.mounted;
        // Le cycle de vie Flame que le GameWidget du hub exécute (l'ordre
        // exact de GameWidgetState.loaderFuture) : sans load/mount, isLoaded
        // reste faux et le jeu refuse tout input de marche.
        game.onGameResize(Vector2(640, 480));
        // L'ordre exact que GameWidgetState.loaderFuture exécute ; le
        // harnais n'a pas d'arbre de widgets pour le faire à sa place.
        // ignore: invalid_use_of_internal_member
        await game.load();
        // ignore: invalid_use_of_internal_member
        game.mount();
        game.update(0);
        await _waitForOverworldAuthority(game);
        final started = game.gameStateSnapshot;
        expect(started.party.members, hasLength(1));
        expect(started.bag.entries, hasLength(2));
        expect(started.playerPosition, const GridPos(x: 1, y: 1));
        expect(
          started.progression.caughtSpeciesIds,
          <String>['bulbasaur'],
          reason: 'the starter species is caught from the outset',
        );
        expect(started.progression.seenSpeciesIds, <String>['bulbasaur']);

        // 1. Un pas vers le sud entre dans l'herbe : la rencontre est
        //    déterminée par les données (chancePerStep 1, une seule entrée).
        await _walkOneStep(game, RuntimeInputControl.down);
        await _waitForBattle(game);
        final firstBattle = game.debugBattleSessionSnapshot!;
        expect(firstBattle.state.enemy.writeBackSpeciesId, 'ivysaur');

        // 2. La Poké Ball 1/1 : l'échec est certain au seed générique — le
        //    sauvage a 19 PV majorés (IVs figés), le tirage tombe à 6069 sur
        //    un seuil de 855.
        await _throwBall(
          game,
          itemId: NeutralCertificationGameFixture.weakBallItemId,
        );
        final failedAttempt = _lastCaptureAttempt(game);
        expect(failedAttempt.caught, isFalse);
        expect(
          failedAttempt.shakes,
          2,
          reason: 'the ENC-005 shake rule is live in the packaged product',
        );

        // 3. La fuite ramène à l'overworld, sur la case de la rencontre.
        await _fleeUntilOverworld(game);
        expect(
          game.gameStateSnapshot.playerPosition,
          NeutralCertificationGameFixture.encounterCell,
        );
        // Le Pokédex discrimine : l'espèce rencontrée puis fuie est VUE
        // mais pas capturée.
        final progressionAfterFlee = game.gameStateSnapshot.progression;
        expect(progressionAfterFlee.seenSpeciesIds, contains('ivysaur'));
        expect(
          progressionAfterFlee.caughtSpeciesIds,
          isNot(contains('ivysaur')),
          reason: 'fleeing a seen wild must not mark it caught',
        );
        final bagAfterFailure = game.gameStateSnapshot.bag;
        expect(
          _quantityOf(
            bagAfterFailure,
            NeutralCertificationGameFixture.weakBallItemId,
          ),
          0,
          reason: 'the failed ball was consumed exactly once',
        );
        expect(
          _quantityOf(
            bagAfterFailure,
            NeutralCertificationGameFixture.guaranteedBallItemId,
          ),
          1,
        );

        // 4. Ressortir puis rentrer dans l'herbe déclenche une nouvelle
        //    rencontre ; la Ball 17/1 la termine en capture garantie.
        await _walkOneStep(game, RuntimeInputControl.up);
        await _walkOneStep(game, RuntimeInputControl.down);
        await _waitForBattle(game);
        await _throwBall(
          game,
          itemId: NeutralCertificationGameFixture.guaranteedBallItemId,
        );
        final capturedAttempt = _lastCaptureAttempt(game);
        expect(capturedAttempt.caught, isTrue);
        expect(capturedAttempt.shakes, 4);
        await _acknowledgePostBattle(game);

        // 5. L'individu du combat est CELUI de la party, la Ball est
        //    consommée, le Pokédex reste cohérent.
        final afterCapture = game.gameStateSnapshot;
        expect(afterCapture.party.members, hasLength(2));
        final captured = afterCapture.party.members.last;
        expect(captured.speciesId, 'ivysaur');
        expect(captured.level, 5);
        expect(captured.individualId, isNotEmpty);
        expect(
          _quantityOf(
            afterCapture.bag,
            NeutralCertificationGameFixture.guaranteedBallItemId,
          ),
          0,
        );
        expect(afterCapture.progression.caughtSpeciesIds, contains('ivysaur'));
        expect(afterCapture.progression.seenSpeciesIds, contains('ivysaur'));

        // 6. Save, titre, reload : l'individu, le Pokédex et la position
        //    overworld reviennent à l'identique depuis la version installée.
        final positionBeforeSave = afterCapture.playerPosition;
        final facingBeforeSave = afterCapture.playerFacing;
        await host.openPause();
        final saved = await host.dispatchPlayer(RuntimePlayerAction.save);
        expect(saved.status, RuntimePlayerCommandStatus.accepted);
        await host.returnToTitle();
        await host.continueGame();

        final resumed = host.mounted.gameStateSnapshot;
        expect(resumed.party.members, hasLength(2));
        expect(
          resumed.party.members.last,
          captured,
          reason: 'the captured individual reloads structurally identical',
        );
        expect(resumed.progression.caughtSpeciesIds, contains('ivysaur'));
        expect(resumed.playerPosition, positionBeforeSave);
        expect(resumed.playerFacing, facingBeforeSave);
      },
      createHttpClient: (_) => throw StateError(
        'The golden encounter gate must not touch the network.',
      ),
    ),
  );

  test(
    'golden journey: capture with a full party routes to the PC and reloads',
    timeout: const Timeout(Duration(minutes: 4)),
    () async => HttpOverrides.runZoned(
      () async {
        final root = await Directory.systemTemp.createTemp(
          'pokemap-golden-encounter-full-',
        );
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        const fixture = NeutralCertificationGameFixture(
          encounterField: true,
          partySize: 6,
        );
        final host = await GoldenGateHost.launch(
          fixture: fixture,
          root: root,
          profileId: 'player1',
          slotId: 'slot1',
        );
        addTearDown(host.dispose);

        await host.startNewGame();
        final game = host.mounted;
        game.onGameResize(Vector2(640, 480));
        // ignore: invalid_use_of_internal_member
        await game.load();
        // ignore: invalid_use_of_internal_member
        game.mount();
        game.update(0);
        await _waitForOverworldAuthority(game);
        final started = game.gameStateSnapshot;
        expect(started.party.members, hasLength(6));
        expect(
          started.pokemonStorage.storedPokemon,
          isEmpty,
          reason: 'the PC starts empty; the capture must be its first entry',
        );

        await _walkOneStep(game, RuntimeInputControl.down);
        await _waitForBattle(game);
        await _throwBall(
          game,
          itemId: NeutralCertificationGameFixture.guaranteedBallItemId,
        );
        final capturedAttempt = _lastCaptureAttempt(game);
        expect(capturedAttempt.caught, isTrue);
        await _acknowledgePostBattle(game);

        // La party pleine route la capture vers le PC, sans perte ni doublon.
        final afterCapture = game.gameStateSnapshot;
        expect(afterCapture.party.members, hasLength(6));
        final stored = afterCapture.pokemonStorage.storedPokemon.single;
        expect(stored.speciesId, 'ivysaur');
        expect(stored.level, 5);
        expect(stored.individualId, isNotEmpty);
        expect(
          afterCapture.party.members
              .map((member) => member.individualId)
              .contains(stored.individualId),
          isFalse,
          reason: 'the boxed individual must not be duplicated into the party',
        );

        await host.openPause();
        final saved = await host.dispatchPlayer(RuntimePlayerAction.save);
        expect(saved.status, RuntimePlayerCommandStatus.accepted);
        await host.returnToTitle();
        await host.continueGame();

        final resumed = host.mounted.gameStateSnapshot;
        expect(resumed.party.members, hasLength(6));
        expect(
          resumed.pokemonStorage.storedPokemon.single,
          stored,
          reason: 'the boxed capture reloads structurally identical',
        );
      },
      createHttpClient: (_) => throw StateError(
        'The golden encounter gate must not touch the network.',
      ),
    ),
  );
}

/// Draine le travail d'activation de carte du boot : tant qu'il est en vol,
/// l'autorité d'input reste bloquée et aucun pas ne peut partir.
Future<void> _waitForOverworldAuthority(PlayableMapGame game) async {
  for (var frame = 0; frame < 2000; frame++) {
    if (game.inputAuthoritySnapshot.context == RuntimeInputContext.overworld) {
      return;
    }
    await _pump(game);
  }
  fail(
    'The overworld never took input authority; '
    'last=${game.inputAuthoritySnapshot.context}',
  );
}

Future<void> _pump(PlayableMapGame game, {int frames = 1}) async {
  // Un vrai délai (pas Duration.zero) : le montage du combat lit des fichiers
  // — l'event loop IO doit pouvoir tourner entre deux frames.
  for (var frame = 0; frame < frames; frame++) {
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

/// Marche d'exactement une case par le canal d'input production.
Future<void> _walkOneStep(
  PlayableMapGame game,
  RuntimeInputControl direction,
) async {
  final from = game.gameStateSnapshot.playerPosition;
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(direction)),
    isTrue,
    reason: 'the overworld must accept the walk input',
  );
  for (var frame = 0; frame < 400; frame++) {
    await _pump(game);
    if (game.gameStateSnapshot.playerPosition != from) {
      break;
    }
  }
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(direction));
  // Laisser le pas se terminer sur la case cible avant le geste suivant.
  await _pump(game, frames: 40);
  expect(
    game.gameStateSnapshot.playerPosition,
    isNot(from),
    reason: 'the walk input must move the player by one cell',
  );
}

Future<void> _waitForBattle(PlayableMapGame game) async {
  for (var frame = 0; frame < 2000; frame++) {
    await _pump(game);
    if (game.debugBattleOverlayMounted &&
        game.debugBattleSessionSnapshot != null) {
      return;
    }
  }
  fail('No battle overlay ever mounted after entering the grass.');
}

/// Appuie sur une entrée du panneau dès qu'il l'accepte — le geste d'un vrai
/// joueur : le panneau refuse pendant les animations du tour, on réessaie.
Future<void> _selectWhenReady(
  PlayableMapGame game,
  bool Function() select, {
  required BattleCommandOverlayMode requiredMode,
  required String reason,
}) async {
  // La présentation du tour avance toute seule (les steps sont temporisés) :
  // on pompe, et on agit dès que le panneau est prêt dans le bon mode. Aucun
  // primary aveugle — dans la fenêtre où le panneau vient d'être prêt, il
  // confirmerait l'entrée sélectionnée.
  for (var frame = 0; frame < 4000; frame++) {
    if (!game.debugBattleOverlayMounted) {
      return;
    }
    final snapshot = game.battleCommandOverlayListenable.value;
    if (snapshot != null &&
        snapshot.mode != requiredMode &&
        requiredMode == BattleCommandOverlayMode.root) {
      // Le panneau rouvre parfois sur le dernier sous-menu (le sac après un
      // lancer) : revenir à la racine avant de choisir, comme un joueur.
      game.backFromBattleOverlay();
      await _pump(game, frames: 2);
      continue;
    }
    if (snapshot != null && snapshot.mode == requiredMode && select()) {
      return;
    }
    await _pump(game, frames: 4);
  }
  fail('The command panel never accepted: $reason');
}

/// Lance la Ball [itemId] par le panneau de commandes (BAG puis l'entrée).
Future<void> _throwBall(
  PlayableMapGame game, {
  required String itemId,
}) async {
  final turnsBefore = _captureAttemptCount(game);
  await _selectWhenReady(
    game,
    () => game.selectBattleRootEntry(1),
    requiredMode: BattleCommandOverlayMode.root,
    reason: 'BAG must open',
  );
  await _pump(game, frames: 5);
  final bagIndex = _bagEntryIndexOf(game, itemId);
  await _selectWhenReady(
    game,
    () => game.selectBattleBagEntry(bagIndex),
    requiredMode: BattleCommandOverlayMode.bag,
    reason: 'the ball entry must submit',
  );
  for (var frame = 0; frame < 2000; frame++) {
    await _pump(game);
    if (_captureAttemptCount(game) > turnsBefore) {
      return;
    }
    if (!game.debugBattleOverlayMounted) {
      return;
    }
  }
  fail('The thrown ball never produced a capture attempt.');
}

int _bagEntryIndexOf(PlayableMapGame game, String itemId) {
  final bag = game.gameStateSnapshot.bag.entries
      .where((entry) => entry.quantity > 0)
      .toList(growable: false);
  final index = bag.indexWhere((entry) => entry.itemId == itemId);
  expect(index, isNonNegative, reason: 'the bag must still hold $itemId');
  return index;
}

int _captureAttemptCount(PlayableMapGame game) {
  final session = game.debugBattleSessionSnapshot;
  final turn = session?.state.currentTurn;
  return turn?.captureAttemptEvents.length ?? 0;
}

BattleCaptureAttemptEventView _lastCaptureAttempt(PlayableMapGame game) {
  final session = game.debugBattleSessionSnapshot!;
  final event = session.state.currentTurn!.captureAttemptEvents.last;
  return BattleCaptureAttemptEventView(
    caught: event.caught,
    shakes: event.shakes,
  );
}

final class BattleCaptureAttemptEventView {
  const BattleCaptureAttemptEventView({
    required this.caught,
    required this.shakes,
  });

  final bool caught;
  final int shakes;
}

/// Fuit par le canal du panneau (RUN, ou l'escape qui y revient), puis
/// acquitte la fin de combat jusqu'au retour overworld. La fuite est
/// déterministe : les seeds du runtime sont constants.
Future<void> _fleeUntilOverworld(PlayableMapGame game) async {
  for (var frame = 0; frame < 4000; frame++) {
    if (!game.debugBattleOverlayMounted) {
      break;
    }
    final session = game.debugBattleSessionSnapshot;
    if (session != null && session.state.isFinished) {
      expect(
        session.state.outcome?.type,
        BattleOutcomeType.runaway,
        reason: 'the battle must end by fleeing, not by any other outcome',
      );
      break;
    }
    final snapshot = game.battleCommandOverlayListenable.value;
    if (snapshot != null) {
      if (snapshot.mode == BattleCommandOverlayMode.root) {
        game.selectBattleRootEntry(3);
      } else {
        game.backFromBattleOverlay();
      }
    }
    await _pump(game, frames: 4);
  }
  await _acknowledgePostBattle(game);
  expect(
    game.debugBattleOverlayMounted,
    isFalse,
    reason: 'fleeing must return to the overworld',
  );
}

Future<void> _acknowledgePostBattle(PlayableMapGame game) async {
  for (var frame = 0; frame < 2000; frame++) {
    await _pump(game);
    if (game.debugPostBattleOverlayMounted) {
      break;
    }
    if (!game.debugBattleOverlayMounted &&
        !game.debugPostBattleOverlayMounted) {
      return;
    }
  }
  for (var input = 0;
      input < 64 && game.debugPostBattleOverlayMounted;
      input++) {
    expect(game.debugValidatePostBattleChoice(), isTrue);
    await _pump(game);
  }
  expect(game.debugPostBattleOverlayMounted, isFalse);
  await game.debugWaitForPostBattleCompletion();
  await _pump(game, frames: 10);
}

int _quantityOf(Bag bag, String itemId) {
  for (final entry in bag.entries) {
    if (entry.itemId == itemId) {
      return entry.quantity;
    }
  }
  return 0;
}
