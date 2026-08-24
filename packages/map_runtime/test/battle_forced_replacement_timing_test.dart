import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';

/// BETA-BAT-033 — recette du 2026-08-24 : « si on va être KO pendant le tour,
/// au moment où l'on sélectionne une attaque, le moteur a déjà prédit le KO
/// et demande déjà le pokémon de remplacement donc ça retire tout le
/// suspense ».
///
/// C'est la cause racine de BETA-BAT-012, restée non généralisée : le moteur
/// résout le tour ENTIER à la soumission (voulu — le tirage vit dans le
/// moteur, un rebuild d'UI ne re-tire jamais), et la présentation doit donc
/// suivre le RUNNER, pas l'état de session. Le bandeau d'issue avait été
/// corrigé ainsi ; le panneau de commande, lui, était resté branché sur la
/// session.
const _fragileStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

const _strongStats = BattleStatsSnapshot(
  attack: 90,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 90,
);

BattleSession _sessionWithReserve() {
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(
        speciesId: 'grenousse',
        level: 5,
        maxHp: 17,
        currentHp: 1,
        stats: _fragileStats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'ecras_face', name: 'Écras’Face', power: 20),
        ],
      ),
      playerReservePokemon: <BattleCombatantData>[
        BattleCombatantData(
          speciesId: 'salameche',
          level: 5,
          maxHp: 18,
          currentHp: 18,
          stats: _fragileStats,
          moves: <BattleMoveData>[
            BattleMoveData(id: 'flammeche', name: 'Flammèche', power: 20),
          ],
        ),
      ],
      enemyPokemon: const BattleCombatantData(
        speciesId: 'roucool',
        level: 20,
        maxHp: 60,
        currentHp: 60,
        stats: _strongStats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'tornade', name: 'Tornade', power: 90),
        ],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'BETA-BAT-033 : la demande de remplaçant n’apparaît pas tant que le '
      'tour n’a pas été joué', () async {
    final snapshots = <BattleCommandOverlaySnapshot?>[];
    final session = _sessionWithReserve();
    final overlay = BattleOverlayComponent(
      session: session,
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
      onCommandOverlaySnapshotChanged: snapshots.add,
    );
    await overlay.onLoad();
    await overlay.waitForPendingVisualSync();
    overlay.setUseFlutterCommandOverlay(true);

    final request = session.decisionRequest;
    expect(
      request,
      isA<BattleTurnChoiceRequest>(),
      reason: 'le tour commence par un choix normal',
    );

    final fight = request.allowedChoices.whereType<PlayerBattleChoiceFight>();
    expect(fight, isNotEmpty);
    final afterTurn = session.applyChoice(fight.first);
    expect(
      afterTurn.decisionRequest,
      isA<BattleForcedReplacementRequest>(),
      reason: 'le moteur a bien résolu le tour et sait déjà que le joueur '
          'tombe : c’est voulu, et c’est précisément pourquoi la '
          'présentation ne doit pas le trahir',
    );

    snapshots.clear();
    overlay.updateState(afterTurn);
    await overlay.waitForPendingVisualSync();

    // Le plan du tour est posé mais rien n'a encore été joué.
    expect(
      snapshots.whereType<BattleCommandOverlaySnapshot>().any(
            (snapshot) => snapshot.forcedReplacement,
          ),
      isFalse,
      reason: 'AUCUN snapshot ne doit demander un remplaçant avant que le '
          'tour ait été joué',
    );
    // Le drapeau ne suffit pas : sans garde sur le MODE, le panneau afficherait
    // quand même la liste de l'équipe, ce que la recette a vu à l'écran.
    expect(
      snapshots.whereType<BattleCommandOverlaySnapshot>().any(
            (snapshot) => snapshot.mode == BattleCommandOverlayMode.pokemon,
          ),
      isFalse,
      reason: 'et le panneau ne doit pas non plus AFFICHER l’équipe pendant '
          'que le tour se joue',
    );

    // La fenêtre exacte de BETA-BAT-012 : le plan est POSÉ mais le runner ne
    // l'a pas encore entamé. `_animationRunner.isActive` est donc faux, et
    // sans `_presentationPendingOrRunning` le panneau se croirait interactif.
    final beforePlaying =
        snapshots.whereType<BattleCommandOverlaySnapshot>().toList();
    expect(beforePlaying, isNotEmpty);
    expect(
      beforePlaying.any((snapshot) => snapshot.interactionsEnabled),
      isFalse,
      reason: 'aucune commande n’est acceptée entre la pose du plan et son '
          'démarrage',
    );

    // On joue le tour jusqu'au bout.
    var guard = 0;
    while (overlay.isTurnPresentationActive && guard++ < 400) {
      overlay.updateTree(0.05);
      await Future<void>.delayed(Duration.zero);
    }
    overlay.updateTree(0.05);
    await Future<void>.delayed(Duration.zero);

    expect(
      snapshots.whereType<BattleCommandOverlaySnapshot>().any(
            (snapshot) => snapshot.forcedReplacement,
          ),
      isTrue,
      reason: 'et elle doit apparaître une fois le tour joué',
    );
  });
}
