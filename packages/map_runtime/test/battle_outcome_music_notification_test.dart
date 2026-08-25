import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

/// Recette du 2026-08-25 : « la musique de fin de combat s'est fait la malle ».
///
/// `onOutcomePresented` ne pilote PAS un affichage : c'est lui qui dit à
/// l'hôte de basculer sur la musique de victoire. Il vivait pourtant derrière
/// le garde `outcomeBannerEnabled`, donc couper le bandeau doublon de
/// BETA-BAT-030 l'a coupé avec — silencieusement, et aucun test ne le tenait.
const _weakStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

const _strongStats = BattleStatsSnapshot(
  attack: 200,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 200,
);

BattleSession _winnableSession() {
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(
        speciesId: 'grenousse',
        level: 30,
        maxHp: 90,
        currentHp: 90,
        stats: _strongStats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'ecras_face', name: 'Écras’Face', power: 120),
        ],
      ),
      enemyPokemon: const BattleCombatantData(
        speciesId: 'roucool',
        level: 2,
        maxHp: 8,
        currentHp: 8,
        stats: _weakStats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'tornade', name: 'Tornade', power: 10),
        ],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
}

Future<void> _playOutcome({
  required bool outcomeBannerEnabled,
  required List<BattleOutcome> notified,
}) async {
  final session = _winnableSession();
  final overlay = BattleOverlayComponent(
    session: session,
    viewportSize: Vector2(960, 540),
    onPlayerChoice: (_) {},
    outcomeBannerEnabled: outcomeBannerEnabled,
    onOutcomePresented: notified.add,
  );
  await overlay.onLoad();
  await overlay.waitForPendingVisualSync();

  final fight = session.decisionRequest.allowedChoices
      .whereType<PlayerBattleChoiceFight>();
  expect(fight, isNotEmpty);
  final finished = session.applyChoice(fight.first);
  expect(
    finished.state.outcome?.isVictory,
    isTrue,
    reason: 'le scénario doit se terminer par une victoire',
  );

  overlay.updateState(finished);
  await overlay.waitForPendingVisualSync();
  var guard = 0;
  while (overlay.isTurnPresentationActive && guard++ < 400) {
    overlay.updateTree(0.05);
    await Future<void>.delayed(Duration.zero);
  }
  overlay.updateTree(0.05);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'BETA-BAT-030 : l’issue est notifiée même quand le bandeau est coupé',
      () async {
    final notified = <BattleOutcome>[];
    await _playOutcome(outcomeBannerEnabled: false, notified: notified);

    expect(
      notified.map((outcome) => outcome.isVictory),
      <bool>[true],
      reason: 'c’est cette notification qui déclenche la musique de '
          'victoire : elle ne dépend pas de l’affichage d’un bandeau',
    );
  });

  test('l’issue reste notifiée quand le bandeau est actif', () async {
    final notified = <BattleOutcome>[];
    await _playOutcome(outcomeBannerEnabled: true, notified: notified);

    expect(notified, hasLength(1));
  });

  test('l’issue n’est notifiée qu’une seule fois', () async {
    // Le tour est rejoué au-delà de sa fin : la notification ne doit pas se
    // répéter à chaque frame, sinon la musique redémarrerait sans cesse.
    final notified = <BattleOutcome>[];
    await _playOutcome(outcomeBannerEnabled: false, notified: notified);
    expect(notified, hasLength(1));
  });
}
