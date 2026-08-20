import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

import 'support/golden_gate_hosts.dart';

/// Golden gate Dresseurs — BETA-TRN-005.
///
/// Depuis un package exporté puis installé — espace auteur et archive
/// SUPPRIMÉS, réseau qui jette — un joueur défie le boss et PERD (la défaite
/// du premier assaut est déterminée par les données : niveau 8 contre 5),
/// est récupéré par le flux de défaite, bat son rival récurrent deux fois
/// (rematch autorisé — l'XP le fait monter de niveau), revient battre le
/// boss, reçoit badge + flag + Surf + argent exactement une fois, et
/// retrouve tout après save/reload — le boss restant vaincu, le rival
/// restant défiable.
///
/// Le profil IA par difficulté (battleDifficulty 8 vs 1) est certifié par
/// runtime_trainer_psdk_ai_policy_test au niveau runtime ; la gate authore
/// les deux valeurs pour que l'export les transporte.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'golden journey: boss defeat, rival grind, boss victory, reload',
    timeout: const Timeout(Duration(minutes: 4)),
    () async => HttpOverrides.runZoned(
      () async {
        final root = await Directory.systemTemp.createTemp(
          'pokemap-golden-arena-',
        );
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        const fixture = NeutralCertificationGameFixture(trainerArena: true);
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
        expect(started.trainerProfile.badgeIds, isEmpty);
        expect(
          started.progression.unlockedFieldAbilities
              .contains(FieldAbility.surf),
          isFalse,
        );
        final startingMoney = started.trainerProfile.money;
        final startingLevel = started.party.members.single.level;

        // 1. Entrer dans la ligne de vue du boss — il attaque — et PERDRE.
        await _walkOneStep(game, RuntimeInputControl.right);
        await _waitForBattle(game);
        final bossOutcome = await _fightUntilBattleEnds(game);
        expect(
          bossOutcome,
          BattleOutcomeType.defeat,
          reason: 'level 5 against level 8 must lose the first assault',
        );
        await _waitForOverworldAuthority(game);
        await _pump(game, frames: 100);
        final afterDefeat = game.gameStateSnapshot;
        // Le whiteout complet : respawn au point de récupération, équipe
        // SOIGNÉE (le combat suivant doit être possible), pénalité d'argent.
        expect(afterDefeat.playerPosition, const GridPos(x: 1, y: 1));
        expect(
          afterDefeat.party.members.single.currentHp,
          greaterThan(0),
          reason: 'defeat recovery must heal the party for the retry',
        );
        expect(
          afterDefeat.trainerProfile.money,
          lessThan(startingMoney),
          reason: 'defeat costs money',
        );
        final moneyAfterDefeat = afterDefeat.trainerProfile.money;
        expect(
          afterDefeat.storyFlags.activeFlags,
          isNot(
            contains('trainer_defeated:'
                '${NeutralCertificationGameFixture.bossTrainerId}'),
          ),
        );
        expect(afterDefeat.trainerProfile.badgeIds, isEmpty);

        // 2. Le rival récurrent : le battre DEUX fois (rematch autorisé),
        //    l'XP fait monter le starter de niveau.
        for (var round = 0; round < 2; round++) {
          // Entre deux combats, se soigner à la potion depuis le menu pause —
          // le canal joueur réel, et le geste que tout joueur ferait.
          await _healLeadWithPotion(host, game);
          // Le réarmement du rematch exige de SORTIR de la ligne de vue puis
          // d'y revenir — le comportement produit du dresseur rematchable.
          await _walkToCell(game, const GridPos(x: 1, y: 2));
          await _walkIntoRivalSight(game);
          await _waitForBattle(game);
          final rivalOutcome = await _fightUntilBattleEnds(game);
          expect(
            rivalOutcome,
            BattleOutcomeType.victory,
            reason: 'round $round against the level-2 rival must win',
          );
          await _waitForOverworldAuthority(game);
        }
        final afterGrind = game.gameStateSnapshot;
        expect(
          afterGrind.party.members.single.level,
          greaterThan(startingLevel),
          reason: 'two rival victories must level the starter up',
        );
        expect(
          afterGrind.trainerProfile.money,
          moneyAfterDefeat + 240,
          reason: 'the rival pays 120 per victory, twice',
        );

        // 3. Revenir battre le boss : la victoire applique badge, flag,
        //    Surf et argent, exactement une fois.
        await _healLeadWithPotion(host, game);
        await _walkIntoBossSight(game);
        await _waitForBattle(game);
        final rematchOutcome = await _fightUntilBattleEnds(game);
        expect(
          rematchOutcome,
          BattleOutcomeType.victory,
          reason: 'the leveled starter must win the boss rematch',
        );
        await _waitForOverworldAuthority(game);

        final afterBoss = game.gameStateSnapshot;
        expect(
          afterBoss.trainerProfile.badgeIds,
          <String>[NeutralCertificationGameFixture.bossBadgeId],
        );
        expect(
          afterBoss.storyFlags.activeFlags,
          contains(NeutralCertificationGameFixture.bossVictoryFlagId),
        );
        expect(
          afterBoss.storyFlags.activeFlags,
          contains('trainer_defeated:'
              '${NeutralCertificationGameFixture.bossTrainerId}'),
        );
        expect(
          afterBoss.progression.unlockedFieldAbilities
              .contains(FieldAbility.surf),
          isTrue,
        );
        expect(
          afterBoss.trainerProfile.money,
          moneyAfterDefeat + 240 + 600,
        );

        // 4. Save, titre, reload : le monde vaincu revient identique.
        await host.openPause();
        final saved = await host.dispatchPlayer(RuntimePlayerAction.save);
        expect(saved.status, RuntimePlayerCommandStatus.accepted);
        await host.returnToTitle();
        await host.continueGame();

        final resumed = host.mounted.gameStateSnapshot;
        expect(
          resumed.trainerProfile.badgeIds,
          <String>[NeutralCertificationGameFixture.bossBadgeId],
        );
        expect(
          resumed.storyFlags.activeFlags,
          containsAll(<String>[
            NeutralCertificationGameFixture.bossVictoryFlagId,
            'trainer_defeated:${NeutralCertificationGameFixture.bossTrainerId}',
          ]),
        );
        expect(
          resumed.progression.unlockedFieldAbilities
              .contains(FieldAbility.surf),
          isTrue,
        );
        expect(resumed.trainerProfile.money, afterBoss.trainerProfile.money);
        expect(
          resumed.party.members.single.level,
          afterBoss.party.members.single.level,
        );
      },
      createHttpClient: (_) => throw StateError(
        'The golden trainer arena gate must not touch the network.',
      ),
    ),
  );
}

/// Soigne le Pokémon de tête avec une potion, par le canal pause réel.
Future<void> _healLeadWithPotion(
  GoldenGateHost host,
  PlayableMapGame game,
) async {
  final lead = game.gameStateSnapshot.party.members.single;
  await host.openPause();
  final bagOpened = await host.dispatchPlayer(RuntimePlayerAction.openBag);
  expect(bagOpened.status, RuntimePlayerCommandStatus.accepted);
  final healed = await host.dispatchPlayer(
    RuntimePlayerAction.useBagItem,
    payload: RuntimePlayerPauseCommand.useBagItem(
      itemTargetId: 'potion',
      partyTargetId: 'pokemon.${lead.individualId}',
    ),
  );
  // Un Pokémon déjà au maximum refuse la potion : le soin est un moyen du
  // journey, pas un critère — le no-op est légitime.
  expect(
    healed.status,
    anyOf(
      RuntimePlayerCommandStatus.accepted,
      RuntimePlayerCommandStatus.unavailable,
    ),
  );
  await host.resume();
  await _waitForOverworldAuthority(game);
}

Future<void> _waitForOverworldAuthority(PlayableMapGame game) async {
  for (var frame = 0; frame < 4000; frame++) {
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
  for (var frame = 0; frame < frames; frame++) {
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

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
  await _pump(game, frames: 40);
  if (game.debugBattleOverlayMounted) {
    return;
  }
  expect(
    game.gameStateSnapshot.playerPosition,
    isNot(from),
    reason: 'the walk input must move the player by one cell',
  );
}

/// Rejoint la ligne de vue du rival (0,3) face est : sa ligne couvre (1,3).
Future<void> _walkIntoRivalSight(PlayableMapGame game) async {
  await _walkToCell(game, const GridPos(x: 1, y: 3));
}

/// Rejoint la ligne de vue du boss (3,1) face ouest : sa ligne couvre (2,1).
Future<void> _walkIntoBossSight(PlayableMapGame game) async {
  await _walkToCell(game, const GridPos(x: 2, y: 1));
}

/// Marche case par case vers [target] (axe X puis axe Y) ; s'arrête net si un
/// combat se déclenche en route — c'est le but des lignes de vue.
Future<void> _walkToCell(PlayableMapGame game, GridPos target) async {
  for (var guard = 0; guard < 12; guard++) {
    if (game.debugBattleOverlayMounted) {
      return;
    }
    final position = game.gameStateSnapshot.playerPosition;
    if (position == target) {
      return;
    }
    final RuntimeInputControl direction;
    if (position.x != target.x) {
      direction = position.x > target.x
          ? RuntimeInputControl.left
          : RuntimeInputControl.right;
    } else {
      direction = position.y > target.y
          ? RuntimeInputControl.up
          : RuntimeInputControl.down;
    }
    await _walkOneStep(game, direction);
  }
  fail('Never reached $target.');
}

Future<void> _waitForBattle(PlayableMapGame game) async {
  for (var frame = 0; frame < 4000; frame++) {
    await _pump(game);
    if (game.debugBattleOverlayMounted &&
        game.debugBattleSessionSnapshot != null) {
      return;
    }
    // Les dialogues pré-combat des templates attendent leur confirmation,
    // comme pour un vrai joueur. Une confirmation à la fois, puis laisser la
    // bascule d'autorité se stabiliser — marteler ré-interagirait avec le PNJ
    // dans la frame de transition et écraserait l'action post-dialogue.
    if (game.inputAuthoritySnapshot.context == RuntimeInputContext.dialogue) {
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.primary),
      );
      await _pump(game, frames: 12);
    }
  }
  fail('No battle overlay ever mounted after the interaction; '
      'authority=${game.inputAuthoritySnapshot.context} '
      'pending=${game.debugPendingBattleRequest} '
      'flow=${game.debugFlowPhaseName} '
      'pos=${game.gameStateSnapshot.playerPosition}');
}

/// Joue FIGHT / premier move jusqu'à la fin du combat, acquitte le
/// post-combat, et rend l'issue observée. Déterministe : les seeds du
/// runtime sont constants.
Future<BattleOutcomeType> _fightUntilBattleEnds(PlayableMapGame game) async {
  BattleOutcomeType? outcome;
  for (var frame = 0; frame < 8000; frame++) {
    if (!game.debugBattleOverlayMounted) {
      break;
    }
    final session = game.debugBattleSessionSnapshot;
    if (session != null && session.state.isFinished) {
      outcome = session.state.outcome?.type;
      break;
    }
    final snapshot = game.battleCommandOverlayListenable.value;
    if (snapshot != null) {
      if (snapshot.mode == BattleCommandOverlayMode.root) {
        game.selectBattleRootEntry(0);
      } else if (snapshot.mode == BattleCommandOverlayMode.fight ||
          snapshot.mode == BattleCommandOverlayMode.continueOnly) {
        game.selectBattleChoiceEntry(0);
      } else {
        game.backFromBattleOverlay();
      }
    }
    await _pump(game, frames: 4);
  }
  await _acknowledgePostBattle(game);
  expect(outcome, isNotNull, reason: 'the battle must reach an outcome');
  return outcome!;
}

Future<void> _acknowledgePostBattle(PlayableMapGame game) async {
  for (var frame = 0; frame < 4000; frame++) {
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
  // Les dialogues de victoire des templates s'ouvrent après le commit :
  // les confirmer fait partie du parcours réel.
  for (var frame = 0; frame < 400; frame++) {
    await _pump(game);
    if (game.inputAuthoritySnapshot.context == RuntimeInputContext.dialogue) {
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.primary),
      );
    } else if (game.inputAuthoritySnapshot.context ==
        RuntimeInputContext.overworld) {
      break;
    }
  }
  await _pump(game, frames: 10);
}
