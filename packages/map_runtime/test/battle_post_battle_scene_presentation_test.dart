import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';

// BETA-BAT-017 : la fin de combat se joue DANS la scène, parité Platine.
// La référence enchaîne, sans changer d'écran : « Victoire ! », « X a gagné
// N points Exp. ! » pendant que la barre d'XP se remplit, « monte au N. Y ! »
// avec remise à zéro de la barre, « Vous remportez N ₽ ! », puis fondu noir.
// Ces tests verrouillent la mécanique overlay : le plan de fin joue comme un
// tour, le tween d'XP est publié dans le snapshot avec la même précision que
// les PV, et la valeur tenue survit à la fin du tween.

const _stats = BattleStatsSnapshot(
  attack: 40,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

BattleSession _session() {
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(
        speciesId: 'grenousse',
        level: 5,
        maxHp: 17,
        currentHp: 17,
        stats: _stats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'ecras_face', name: 'Écras’Face', power: 20),
        ],
      ),
      enemyPokemon: const BattleCombatantData(
        speciesId: 'roucool',
        level: 4,
        maxHp: 19,
        currentHp: 19,
        stats: _stats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'tornade', name: 'Tornade', power: 40),
        ],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
}

Future<void> _pump(BattleOverlayComponent overlay, double seconds) async {
  for (var elapsed = 0.0; elapsed < seconds; elapsed += 0.05) {
    overlay.updateTree(0.05);
    await Future<void>.delayed(Duration.zero);
  }
}

/// Le completionFuture du runner n'avance que si quelqu'un pompe l'horloge :
/// épuiser la présentation AVANT de l'attendre, sinon le test s'endort.
Future<void> _pumpUntilIdle(BattleOverlayComponent overlay) async {
  for (var i = 0; i < 400 && overlay.isTurnPresentationActive; i++) {
    overlay.updateTree(0.05);
    await Future<void>.delayed(Duration.zero);
  }
  await overlay.waitForTurnPresentationComplete();
}

Future<ui.Image> _trainerImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 8, 16),
    ui.Paint()..color = const ui.Color(0xFF2266AA),
  );
  return recorder.endRecording().toImage(8, 16);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'le plan de fin joue ses messages dans la boîte de dialogue et '
      'verrouille les commandes', () async {
    BattleCommandOverlaySnapshot? snapshot;
    final overlay = BattleOverlayComponent(
      session: _session(),
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
      onCommandOverlaySnapshotChanged: (s) => snapshot = s,
      playerExperienceProgressByLineupIndex: const <int, double>{0: 0.25},
    );
    await overlay.onLoad();
    await overlay.waitForPendingVisualSync();
    overlay.setUseFlutterCommandOverlay(true);

    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: <BattleAnimationStep>[
          ShowMessageStep(message: 'Victoire !'),
          WaitStep(durationSeconds: 0.9),
          ShowMessageStep(message: 'grenousse a gagné 21 points Exp. !'),
          HudXpTweenStep(fromProgress: 0.25, toProgress: 0.8),
          WaitStep(durationSeconds: 0.35),
        ],
      ),
    );
    await _pump(overlay, 0.2);
    expect(overlay.debugCurrentAnimationMessage, 'Victoire !');
    expect(overlay.isTurnPresentationActive, isTrue);
    expect(
      snapshot!.interactionsEnabled,
      isFalse,
      reason: 'les messages de fin jouent comme un tour : aucune commande',
    );
    expect(snapshot!.prompt, 'Victoire !');

    await _pump(overlay, 1.3);
    expect(
      overlay.debugCurrentAnimationMessage,
      'grenousse a gagné 21 points Exp. !',
    );

    await _pumpUntilIdle(overlay);
    expect(overlay.isTurnPresentationActive, isFalse);
  });

  test(
      'le tween d’XP est publié dans le snapshot puis la valeur tenue '
      'survit au plan', () async {
    BattleCommandOverlaySnapshot? snapshot;
    final overlay = BattleOverlayComponent(
      session: _session(),
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
      onCommandOverlaySnapshotChanged: (s) => snapshot = s,
      playerExperienceProgressByLineupIndex: const <int, double>{0: 0.25},
    );
    await overlay.onLoad();
    await overlay.waitForPendingVisualSync();
    overlay.setUseFlutterCommandOverlay(true);
    await _pump(overlay, 0.1);

    expect(
      snapshot!.playerHud.experienceProgress,
      0.25,
      reason: 'avant la fin : la progression d’avant combat, sans tween',
    );
    expect(snapshot!.playerHud.hasXpTween, isFalse);
    expect(snapshot!.enemyHud.experienceProgress, isNull);

    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: <BattleAnimationStep>[
          HudXpTweenStep(
            fromProgress: 0.25,
            toProgress: 0.8,
            durationMs: 600,
          ),
          WaitStep(durationSeconds: 0.5),
        ],
      ),
    );
    await _pump(overlay, 0.2);
    final playerHud = snapshot!.playerHud;
    expect(playerHud.experienceProgress, 0.25);
    expect(playerHud.experienceProgressTarget, 0.8);
    expect(playerHud.xpTweenDurationMs, 600);
    expect(playerHud.xpTweenRevision, 1);
    expect(playerHud.hasXpTween, isTrue);

    await _pump(overlay, 1.2);
    expect(
      snapshot!.playerHud.experienceProgress,
      0.8,
      reason: 'après le tween : la barre TIENT sa cible — la table d’avant '
          'combat (0.25) mentirait pendant le fondu de sortie',
    );
    expect(snapshot!.playerHud.hasXpTween, isFalse);
  });

  test(
      'une décision post-combat prend le panneau : choix publiés, navigation '
      'et validation routées, puis retour au flux normal', () async {
    BattleCommandOverlaySnapshot? snapshot;
    final overlay = BattleOverlayComponent(
      session: _session(),
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
      onCommandOverlaySnapshotChanged: (s) => snapshot = s,
    );
    await overlay.onLoad();
    await overlay.waitForPendingVisualSync();
    overlay.setUseFlutterCommandOverlay(true);
    overlay.beginPostBattleGate();

    final chosen = <int>[];
    overlay.presentPostBattleDecision(
      prompt: 'grenousse peut apprendre Vive-Attaque.',
      choices: const <String>['Apprendre', 'Ne pas apprendre'],
      onChoice: chosen.add,
    );

    expect(snapshot, isNotNull);
    expect(snapshot!.prompt, 'grenousse peut apprendre Vive-Attaque.');
    // Recette du 2026-08-24 : publiée en mode root, la décision se faisait
    // rhabiller par la personnalisation projet du shell joueur — le joueur
    // lisait « Attaquer » / « Sac » à la place de ses choix. Le mode et le
    // kind dédiés sont LA protection contre ce remapping par index.
    expect(snapshot!.mode, BattleCommandOverlayMode.decision);
    expect(
      snapshot!.entries.map((entry) => entry.kind).toSet(),
      <BattleCommandOverlayEntryKind>{BattleCommandOverlayEntryKind.decision},
    );
    expect(
      snapshot!.interactionsEnabled,
      isTrue,
      reason: 'le gate post-combat ferme les commandes du tour, mais une '
          'décision est précisément le moment où le joueur doit répondre',
    );
    expect(
      snapshot!.entries.map((entry) => entry.primaryLabel),
      <String>['Apprendre', 'Ne pas apprendre'],
    );
    expect(snapshot!.entries.first.selected, isTrue);

    expect(overlay.moveSelectionDown(), isTrue);
    expect(
      snapshot!.entries.last.selected,
      isTrue,
      reason: 'la navigation clavier est routée vers la décision',
    );
    expect(overlay.validateSelectedChoice(), isTrue);
    expect(chosen, <int>[1]);

    expect(
      overlay.selectRootEntry(0),
      isTrue,
      reason: 'le tap du Hub (mode root) est routé vers la décision',
    );
    expect(chosen, <int>[1, 0]);

    overlay.clearPostBattleDecision();
    expect(
      snapshot!.interactionsEnabled,
      isFalse,
      reason: 'décision retirée : le gate post-combat reprend la main',
    );
    expect(overlay.selectRootEntry(0), isFalse);
  });

  test(
      'le dresseur vaincu réapparaît au step quand son image est préparée, '
      'et le step sans image ne fait rien', () async {
    final overlay = BattleOverlayComponent(
      session: _session(),
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
    );
    await overlay.onLoad();
    await overlay.waitForPendingVisualSync();

    // Fallback demandé : sans image préparée, le step est un no-op et le
    // message seul fait l'annonce.
    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: <BattleAnimationStep>[
          ShowDefeatedTrainerStep(),
          ShowMessageStep(message: 'Vous avez battu Gamin Chuk !'),
        ],
      ),
    );
    await _pumpUntilIdle(overlay);
    expect(overlay.debugDefeatedTrainerSpriteMounted, isFalse);

    overlay.prepareDefeatedTrainerVisual(await _trainerImage());
    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: <BattleAnimationStep>[
          ShowDefeatedTrainerStep(),
          ShowMessageStep(message: 'Vous avez battu Gamin Chuk !'),
        ],
      ),
    );
    await _pump(overlay, 0.3);
    expect(
      overlay.debugDefeatedTrainerSpriteMounted,
      isTrue,
      reason: 'le sprite du dresseur vaincu se monte à la place de son '
          'Pokémon, ancré sur « Vous avez battu X ! »',
    );
    expect(
        overlay.debugCurrentAnimationMessage, 'Vous avez battu Gamin Chuk !');
    await _pumpUntilIdle(overlay);
  });

  test('une montée de niveau remet la barre à zéro entre deux remplissages',
      () async {
    BattleCommandOverlaySnapshot? snapshot;
    final overlay = BattleOverlayComponent(
      session: _session(),
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
      onCommandOverlaySnapshotChanged: (s) => snapshot = s,
      playerExperienceProgressByLineupIndex: const <int, double>{0: 0.7},
    );
    await overlay.onLoad();
    await overlay.waitForPendingVisualSync();
    overlay.setUseFlutterCommandOverlay(true);

    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: <BattleAnimationStep>[
          HudXpTweenStep(fromProgress: 0.7, toProgress: 1),
          ShowMessageStep(message: 'grenousse monte au N. 6 !'),
          HudXpTweenStep(fromProgress: 1, toProgress: 0, durationMs: 0),
          HudXpTweenStep(fromProgress: 0, toProgress: 0.3),
          WaitStep(durationSeconds: 0.2),
        ],
      ),
    );
    await _pump(overlay, 0.7);
    expect(
      snapshot!.playerHud.experienceProgress,
      1.0,
      reason: 'la barre est pleine pendant le message de montée de niveau',
    );

    await _pumpUntilIdle(overlay);
    overlay.updateTree(0.05);
    await Future<void>.delayed(Duration.zero);
    expect(
      snapshot!.playerHud.experienceProgress,
      0.3,
      reason: 'après le niveau : la barre repart de zéro et tient le reliquat',
    );
  });
}
