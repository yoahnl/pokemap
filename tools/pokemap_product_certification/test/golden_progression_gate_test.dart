import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

import 'support/golden_gate_hosts.dart';

/// Golden gate Progression post-combat — BETA-PRG-006.
///
/// Depuis un package exporté puis installé — espace auteur et archive
/// SUPPRIMÉS, réseau qui jette — un joueur enchaîne les victoires : le grind
/// fait gagner plusieurs niveaux, DEUX capacités tombent en prompt de
/// remplacement (le lead a déjà quatre attaques — chaque choix est navigué
/// aux flèches et validé comme un joueur), l'évolution est ACCEPTÉE au
/// niveau 7 — l'espèce change, l'identité individuelle JAMAIS — puis le boss
/// paie argent et milestone, et le reload rend tout structurellement égal.
///
/// Le scénario DÉFAITE du ticket (party K.O., pénalité d'argent, checkpoint,
/// restauration, reprise) est certifié par golden_trainer_arena_gate_test —
/// la même fixture d'arène, le même package.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'golden journey: grind, two move prompts, accepted evolution, reload',
    timeout: const Timeout(Duration(minutes: 4)),
    () async => HttpOverrides.runZoned(
      () async {
        final root = await Directory.systemTemp.createTemp(
          'pokemap-golden-progression-',
        );
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        const fixture = NeutralCertificationGameFixture(
          progressionArena: true,
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
        final lead = started.party.members.single;
        final individualId = lead.individualId;
        expect(lead.speciesId, 'bulbasaur');
        expect(lead.level, 5);
        expect(
          lead.knownMoveIds,
          <String>['tackle', 'leer', 'quick_attack', 'tail_whip'],
        );

        // 1. Le grind : battre le rival deux fois. Les prompts tombent dans
        //    les post-combats — growl au niveau 6 (remplace tail_whip),
        //    vine_whip au niveau 7 (remplace leer), puis l'évolution au 7
        //    est ACCEPTÉE.
        for (var round = 0; round < 2; round++) {
          // Sortir de la ligne de vue AVANT de soigner : le rival réarmé
          // re-défierait un joueur immobile dans sa ligne.
          await _walkToCell(game, const GridPos(x: 1, y: 2));
          await _healLeadWithPotion(host, game);
          await _walkToCell(game, const GridPos(x: 1, y: 3));
          await _waitForBattle(game);
          final outcome = await _fightUntilBattleEnds(
            game,
            decidePrompt: _progressionPromptPolicy,
          );
          expect(outcome, BattleOutcomeType.victory,
              reason: 'round $round against the rival must win');
          await _waitForOverworldAuthority(game);
        }

        final afterGrind = game.gameStateSnapshot;
        final evolved = afterGrind.party.members.single;
        expect(evolved.level, greaterThanOrEqualTo(7));
        expect(
          evolved.speciesId,
          'ivysaur',
          reason: 'the level-7 evolution was accepted in the post-battle flow',
        );
        expect(
          evolved.individualId,
          individualId,
          reason: 'evolution changes the species, never the individual',
        );
        expect(evolved.knownMoveIds, contains('growl'));
        expect(evolved.knownMoveIds, contains('vine_whip'));
        expect(evolved.knownMoveIds, isNot(contains('tail_whip')));
        expect(evolved.knownMoveIds, isNot(contains('leer')));
        expect(evolved.knownMoveIds, hasLength(4));

        // 2. Le boss : la victoire paie argent et milestone — la chaîne
        //    récompense complète après la progression.
        final moneyBeforeBoss = afterGrind.trainerProfile.money;
        await _walkToCell(game, const GridPos(x: 1, y: 2));
        await _healLeadWithPotion(host, game);
        await _walkToCell(game, const GridPos(x: 1, y: 1));
        await _walkToCell(game, const GridPos(x: 2, y: 1));
        await _waitForBattle(game);
        final bossOutcome = await _fightUntilBattleEnds(
          game,
          decidePrompt: _progressionPromptPolicy,
        );
        expect(bossOutcome, BattleOutcomeType.victory,
            reason: 'the evolved level-7+ lead must beat the level-6 boss');
        await _waitForOverworldAuthority(game);

        final afterBoss = game.gameStateSnapshot;
        expect(afterBoss.trainerProfile.money, moneyBeforeBoss + 600);
        expect(
          afterBoss.trainerProfile.badgeIds,
          <String>[NeutralCertificationGameFixture.bossBadgeId],
        );
        expect(
          afterBoss.storyFlags.activeFlags,
          contains(NeutralCertificationGameFixture.bossVictoryFlagId),
        );

        // 3. Save, titre, reload : l'individu évolué revient à l'identique.
        await host.openPause();
        final saved = await host.dispatchPlayer(RuntimePlayerAction.save);
        expect(saved.status, RuntimePlayerCommandStatus.accepted);
        await host.returnToTitle();
        await host.continueGame();

        final resumed = host.mounted.gameStateSnapshot;
        expect(
          resumed.party.members.single,
          afterBoss.party.members.single,
          reason: 'the evolved individual reloads structurally identical',
        );
        expect(resumed.trainerProfile.money, afterBoss.trainerProfile.money);
        expect(
          resumed.trainerProfile.badgeIds,
          afterBoss.trainerProfile.badgeIds,
        );
      },
      createHttpClient: (_) => throw StateError(
        'The golden progression gate must not touch the network.',
      ),
    ),
  );
}

/// La politique de choix du journey, sur les libellés réellement affichés :
/// « Apprendre » aux propositions, oublier Tail whip puis Leer aux
/// remplacements (les libellés sont les noms des moves connus), accepter
/// l'évolution — et valider tout le reste tel quel (index 0).
int _progressionPromptPolicy(List<String> labels) {
  int indexWhere(bool Function(String label) test) {
    for (var index = 0; index < labels.length; index++) {
      if (test(labels[index].toLowerCase())) {
        return index;
      }
    }
    return 0;
  }

  final lowered =
      labels.map((label) => label.toLowerCase()).toList(growable: false);
  final isReplacementPrompt =
      lowered.any((label) => label.contains('tackle')) ||
          lowered.any((label) => label.contains('quick'));
  if (isReplacementPrompt) {
    if (lowered.any((label) => label.contains('tail'))) {
      return indexWhere((label) => label.contains('tail'));
    }
    if (lowered.any((label) => label.contains('leer'))) {
      return indexWhere((label) => label.contains('leer'));
    }
    return 0;
  }
  if (lowered.any((label) => label.contains('évolu'))) {
    return indexWhere((label) => label.contains('évolu'));
  }
  return 0;
}

/// Soigne le Pokémon de tête à la potion par le canal pause réel ; un refus
/// à PV pleins est un no-op légitime.
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

Future<void> _walkOneStep(
  PlayableMapGame game,
  RuntimeInputControl direction,
) async {
  final from = game.gameStateSnapshot.playerPosition;
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(direction)),
    isTrue,
  );
  for (var frame = 0; frame < 400; frame++) {
    await _pump(game);
    if (game.gameStateSnapshot.playerPosition != from) {
      break;
    }
  }
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(direction));
  await _pump(game, frames: 40);
}

Future<void> _waitForBattle(PlayableMapGame game) async {
  for (var frame = 0; frame < 4000; frame++) {
    await _pump(game);
    if (game.debugBattleOverlayMounted &&
        game.debugBattleSessionSnapshot != null) {
      return;
    }
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
  fail('No battle overlay ever mounted.');
}

Future<BattleOutcomeType> _fightUntilBattleEnds(
  PlayableMapGame game, {
  required int Function(List<String> labels) decidePrompt,
}) async {
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
        game.selectBattleChoiceEntry(_offensiveChoiceIndex(snapshot));
      } else {
        game.backFromBattleOverlay();
      }
    }
    await _pump(game, frames: 4);
  }
  await _resolvePostBattlePrompts(game, decidePrompt: decidePrompt);
  expect(outcome, isNotNull, reason: 'the battle must reach an outcome');
  return outcome!;
}

/// Résout les écrans post-combat comme un joueur : lit les choix affichés,
/// navigue aux flèches jusqu'au choix décidé par [decidePrompt], valide.
/// Préfère un move offensif : après un remplacement, le premier slot peut
/// devenir un move de statut — le spammer perdrait le combat à l'usure.
int _offensiveChoiceIndex(BattleCommandOverlaySnapshot snapshot) {
  final titles = snapshot.entries
      .map((entry) => entry.primaryLabel.toLowerCase())
      .toList(growable: false);
  // Tackle d'abord : contre les types plante de l'arène, vine_whip est
  // résisté — le neutre gagne le duel d'usure.
  for (final preferred in const <String>['tackle', 'quick', 'vine']) {
    for (var index = 0; index < titles.length; index++) {
      if (titles[index].contains(preferred)) {
        return index;
      }
    }
  }
  return 0;
}

Future<void> _resolvePostBattlePrompts(
  PlayableMapGame game, {
  required int Function(List<String> labels) decidePrompt,
}) async {
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
  var lastLabels = '';
  for (var input = 0;
      input < 128 && game.debugPostBattleOverlayMounted;
      input++) {
    final labels = game.debugPostBattleDecisionLabels;
    if (labels.isEmpty) {
      // Les écrans sans choix (victoire, expérience) se valident tels quels.
      game.debugValidatePostBattleChoice();
      await _pump(game, frames: 4);
      continue;
    }
    final signature = labels.join('|');
    if (signature != lastLabels) {
      lastLabels = signature;
      final wanted = decidePrompt(labels);
      for (var move = 0; move < wanted; move++) {
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.down),
        );
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.down),
        );
        await _pump(game, frames: 2);
      }
    }
    expect(game.debugValidatePostBattleChoice(), isTrue);
    await _pump(game, frames: 4);
  }
  expect(game.debugPostBattleOverlayMounted, isFalse);
  await game.debugWaitForPostBattleCompletion();
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
