import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

import 'support/golden_gate_hosts.dart';

/// Golden gate Objets & économie — BETA-ITM-008.
///
/// Depuis un package exporté puis installé — espace auteur et archive
/// SUPPRIMÉS, réseau qui jette — un joueur ramasse un objet (événement V2
/// oneShot, LE canal production en mode v2Only), bat son rival dont la
/// récompense porte argent ET objet, se soigne au centre (service monde
/// réel : confirm, commit, close), achète et vend à la boutique aux montants
/// exacts, apprend une CT compatible et équipe un objet tenu à effet porté
/// par le canal pause, puis recharge : quantités, argent, attaque apprise,
/// objet tenu et non-rejouabilité du ramassage reviennent à l'identique.
///
/// Deux entrées nommées hors canal production, faute de terminal sur la
/// carte neutre : l'ouverture de la boutique (debugOpenPlayerServiceShop) et
/// celle du centre de soins (debugOpenPlayerServiceHeal) — tout le reste,
/// commandes, prix, commits, verrous, est le canal réel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'golden journey: pickup, rival reward, heal, shop, TM, held item, reload',
    timeout: const Timeout(Duration(minutes: 4)),
    () async => HttpOverrides.runZoned(
      () async {
        final root = await Directory.systemTemp.createTemp(
          'pokemap-golden-economy-',
        );
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        const fixture = NeutralCertificationGameFixture(economyTown: true);
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
        final startingMoney = started.trainerProfile.money;
        expect(_quantityOf(started.bag, 'potion'), 4);
        expect(
          _quantityOf(started.bag, NeutralCertificationGameFixture.pickupItemId),
          0,
        );
        expect(
          started.party.members.single.knownMoveIds,
          <String>['tackle'],
        );
        expect(started.party.members.single.heldItemId, isEmpty);

        // 1. Le ramassage : marcher sur la case du trigger V2 par le chemin
        //    qui évite les lignes de vue.
        await _walkPath(game, const <GridPos>[
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 2, y: 3),
        ]);
        await _waitForOverworldAuthority(game);
        await _pump(game, frames: 60);
        expect(
          _quantityOf(
            game.gameStateSnapshot.bag,
            NeutralCertificationGameFixture.pickupItemId,
          ),
          1,
          reason: 'stepping on the pickup trigger grants the item once',
        );

        // 2. Le rival : sa ligne de vue couvre la case voisine — victoire,
        //    et la récompense porte argent ET objet.
        await _walkPath(game, const <GridPos>[GridPos(x: 1, y: 3)]);
        await _waitForBattle(game);
        final rivalOutcome = await _fightUntilBattleEnds(game);
        expect(rivalOutcome, BattleOutcomeType.victory);
        await _waitForOverworldAuthority(game);
        final afterRival = game.gameStateSnapshot;
        expect(afterRival.trainerProfile.money, startingMoney + 120);
        expect(
          _quantityOf(afterRival.bag, 'antidote'),
          1,
          reason: 'the rival reward grants one antidote',
        );

        // 3. Le centre de soins : le service monde réel restaure l'équipe
        //    blessée par le combat.
        final hurtHp = afterRival.party.members.single.currentHp;
        final healResult = game.debugOpenPlayerServiceHeal();
        await host.waitForWorldService();
        await host.dispatchWorldService(RuntimeWorldServiceAction.confirm);
        await host.dispatchWorldService(RuntimeWorldServiceAction.close);
        expect(
          (await healResult).status,
          PlayerServiceRuntimeStatus.completed,
        );
        final healedHp = game.gameStateSnapshot.party.members.single.currentHp;
        expect(
          healedHp,
          greaterThan(hurtHp),
          reason: 'the checkpoint heal restores the battle damage',
        );

        // 4. La boutique : acheter deux potions, vendre la super-potion
        //    ramassée — montants exacts, argent suivi à l'unité.
        final moneyBeforeShop =
            game.gameStateSnapshot.trainerProfile.money;
        final shopResult = game.debugOpenPlayerServiceShop(
          NeutralCertificationGameFixture.shopId,
        );
        await host.waitForWorldService();
        final selected = await host.dispatchWorldService(
          RuntimeWorldServiceAction.select,
          targetId: 'potion',
        );
        expect(selected.status, RuntimeWorldServiceCommandStatus.accepted);
        await host.dispatchWorldService(
          RuntimeWorldServiceAction.increaseQuantity,
        );
        await host.dispatchWorldService(RuntimeWorldServiceAction.confirm);
        final sales = await host.dispatchWorldService(
          RuntimeWorldServiceAction.showSales,
        );
        expect(sales.status, RuntimeWorldServiceCommandStatus.accepted);
        final saleSelect = await host.dispatchWorldService(
          RuntimeWorldServiceAction.select,
          targetId: NeutralCertificationGameFixture.pickupItemId,
        );
        expect(saleSelect.status, RuntimeWorldServiceCommandStatus.accepted);
        final saleConfirm =
            await host.dispatchWorldService(RuntimeWorldServiceAction.confirm);
        expect(saleConfirm.status, RuntimeWorldServiceCommandStatus.accepted);
        await host.dispatchWorldService(RuntimeWorldServiceAction.close);
        await shopResult;

        final afterShop = game.gameStateSnapshot;
        expect(_quantityOf(afterShop.bag, 'potion'), 6,
            reason: 'four starting potions plus the two bought');
        expect(
          _quantityOf(
            afterShop.bag,
            NeutralCertificationGameFixture.pickupItemId,
          ),
          0,
          reason: 'the picked-up item was sold back',
        );
        final moneyAfterShop = afterShop.trainerProfile.money;
        expect(
          moneyAfterShop,
          moneyBeforeShop - 200 + 125,
          reason: 'two potions at 100 out, one resale at 125 in — exact',
        );

        // 5. La CT compatible apprend growl ; l'objet tenu s'équipe — les
        //    deux par le canal pause réel.
        await host.openPause();
        final bagOpened =
            await host.dispatchPlayer(RuntimePlayerAction.openBag);
        expect(bagOpened.status, RuntimePlayerCommandStatus.accepted);
        final lead = game.gameStateSnapshot.party.members.single;
        final taught = await host.dispatchPlayer(
          RuntimePlayerAction.useBagItem,
          payload: RuntimePlayerPauseCommand.useBagItem(
            itemTargetId: NeutralCertificationGameFixture.machineItemId,
            partyTargetId: 'pokemon.${lead.individualId}',
          ),
        );
        expect(taught.status, RuntimePlayerCommandStatus.accepted);
        final equipped = await host.dispatchPlayer(
          RuntimePlayerAction.useBagItem,
          payload: RuntimePlayerPauseCommand.equipHeldItem(
            itemTargetId: NeutralCertificationGameFixture.heldItemId,
            partyTargetId: 'pokemon.${lead.individualId}',
          ),
        );
        expect(equipped.status, RuntimePlayerCommandStatus.accepted);
        await host.resume();
        await _waitForOverworldAuthority(game);

        final afterPause = game.gameStateSnapshot;
        expect(
          afterPause.party.members.single.knownMoveIds,
          containsAll(<String>['tackle', 'growl']),
        );
        expect(
          afterPause.party.members.single.heldItemId,
          NeutralCertificationGameFixture.heldItemId,
        );
        expect(
          _quantityOf(
            afterPause.bag,
            NeutralCertificationGameFixture.machineItemId,
          ),
          0,
          reason: 'the consumable TM is spent on teaching',
        );

        // 6. Save, titre, reload : l'économie entière revient à l'identique,
        //    et le ramassage oneShot ne se rejoue pas.
        await host.openPause();
        final saved = await host.dispatchPlayer(RuntimePlayerAction.save);
        expect(saved.status, RuntimePlayerCommandStatus.accepted);
        await host.returnToTitle();
        await host.continueGame();
        final reloadedGame = host.mounted;
        reloadedGame.onGameResize(Vector2(640, 480));
        // ignore: invalid_use_of_internal_member
        await reloadedGame.load();
        // ignore: invalid_use_of_internal_member
        reloadedGame.mount();
        reloadedGame.update(0);
        await _waitForOverworldAuthority(reloadedGame);

        final resumed = reloadedGame.gameStateSnapshot;
        expect(resumed.trainerProfile.money, moneyAfterShop);
        expect(_quantityOf(resumed.bag, 'potion'), 6);
        expect(_quantityOf(resumed.bag, 'antidote'), 1);
        expect(
          resumed.party.members.single.knownMoveIds,
          containsAll(<String>['tackle', 'growl']),
        );
        expect(
          resumed.party.members.single.heldItemId,
          NeutralCertificationGameFixture.heldItemId,
        );

        // La non-rejouabilité : revenir sur la case du ramassage.
        await _walkPath(reloadedGame, const <GridPos>[
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 2, y: 3),
        ]);
        await _pump(reloadedGame, frames: 60);
        expect(
          _quantityOf(
            reloadedGame.gameStateSnapshot.bag,
            NeutralCertificationGameFixture.pickupItemId,
          ),
          0,
          reason: 'the oneShot pickup must not replay after the reload',
        );
      },
      createHttpClient: (_) => throw StateError(
        'The golden economy gate must not touch the network.',
      ),
    ),
  );

  test(
    'the export refuses a shop selling an item unknown to the catalog',
    () async {
      // BETA-ITM-008 « invalid catalog gate » : la référence cassée est
      // bloquée AVANT le playtest — la transmission export de BETA-TRN-003.
      final root = await Directory.systemTemp.createTemp(
        'pokemap-economy-invalid-',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      const fixture = NeutralCertificationGameFixture(economyTown: true);
      final authorRoot = Directory('${root.path}/author');
      await fixture.writeAuthorWorkspace(authorRoot);
      final projectFile = File('${authorRoot.path}/project.json');
      final manifest = await projectFile.readAsString();
      await projectFile.writeAsString(
        manifest.replaceFirst('"potion"', '"phantom-elixir"'),
      );

      await expectLater(
        fixture.export(authorRoot, File('${root.path}/invalid.avelunegame')),
        throwsA(
          isA<GamePackageExportException>().having(
            (error) => error.toString(),
            'message',
            contains('phantom-elixir'),
          ),
        ),
      );
    },
  );
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

Future<void> _walkPath(PlayableMapGame game, List<GridPos> cells) async {
  for (final cell in cells) {
    if (game.debugBattleOverlayMounted) {
      return;
    }
    final position = game.gameStateSnapshot.playerPosition;
    final RuntimeInputControl direction;
    if (position.x != cell.x) {
      direction = position.x > cell.x
          ? RuntimeInputControl.left
          : RuntimeInputControl.right;
    } else {
      direction = position.y > cell.y
          ? RuntimeInputControl.up
          : RuntimeInputControl.down;
    }
    await _walkOneStep(game, direction);
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

int _quantityOf(Bag bag, String itemId) {
  for (final entry in bag.entries) {
    if (entry.itemId == itemId) {
      return entry.quantity;
    }
  }
  return 0;
}
