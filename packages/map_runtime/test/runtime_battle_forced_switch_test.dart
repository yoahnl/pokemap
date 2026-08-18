import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

import 'support/battle_gate_diagnostics.dart';

/// Switch après K.O. sur la surface runtime (BETA-BAT-008).
///
/// BETA-BAT-006 a certifié cet enchaînement sur le kernel legacy. Ce fichier le
/// certifie là où le joueur le vit : l'adaptateur PSDK que le runtime utilise
/// réellement, et la projection legacy qu'il montre à l'écran. Les deux surfaces
/// doivent raconter la même histoire, sinon l'UI proposerait un menu que le
/// moteur refuse — ou l'inverse.
void main() {
  group('BETA-BAT-008 a knocked out active is replaced through the runtime', () {
    test('the runtime asks for a replacement instead of a free turn', () {
      final session = _knockOutThePlayerActive();

      expect(
        session.decisionRequest.kind,
        BattleEngineDecisionRequestKind.forcedReplacement,
        reason: describeBattleFailure(session: session, initialSeeds: _seeds),
      );
      expect(session.state.isFinished, isFalse);
      expect(session.decisionRequest.switchChoices, isNotEmpty);
    });

    test('a fight command is refused while a replacement is owed', () {
      // Même exigence que BETA-BAT-006, mais sur la surface runtime : un menu
      // resté sur l'écran précédent ne doit pas pouvoir jouer un tour.
      final session = _knockOutThePlayerActive();

      expect(
        () => session.submitDecision(const BattleDecision.fight(moveSlot: 0)),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
    });

    test('the replacement enters and the battle resumes', () {
      final session = _knockOutThePlayerActive();
      final option = session.decisionRequest.switchChoices.first;

      session.submitDecision(
        BattleDecision.switchPokemon(partyIndex: option.partyIndex),
      );

      expect(session.state.isFinished, isFalse);
      expect(
        session.state.battlerAt(psdkPlayerSlot).isFainted,
        isFalse,
        reason: 'a fainted battler must not stay on the field',
      );
      expect(
        session.decisionRequest.kind,
        BattleEngineDecisionRequestKind.turnChoice,
        reason: 'the turn is free again once the debt is paid',
      );
    });

    test('the displayed session agrees that a replacement is owed', () {
      // L'UI ne lit pas l'état PSDK : elle lit la projection legacy. Si les deux
      // divergeaient ici, le joueur verrait un menu de combat sur un Pokémon
      // K.O.
      final session = _knockOutThePlayerActive();
      final display = session.createLegacyDisplaySession(isTrainerBattle: true);

      expect(display.decisionRequest, isA<BattleForcedReplacementRequest>());
      expect(display.state.isFinished, isFalse);
      expect(
        () => display.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(isA<StateError>()),
      );
    });

    test('a knocked out active with no reserve ends the battle instead', () {
      // Contraste : la demande de remplacement ne doit apparaître que lorsqu'un
      // remplaçant existe, sinon le combat est simplement perdu.
      final session = _knockOutThePlayerActive(withReserve: false);

      expect(session.state.isFinished, isTrue);
      expect(session.state.outcome?.kind, BattleEngineOutcomeKind.defeat);
      expect(
        session.decisionRequest.kind,
        BattleEngineDecisionRequestKind.finished,
      );
    });
  });
}

/// Fait tomber l'actif du joueur en laissant le combat en cours.
RuntimePsdkBattleSessionAdapter _knockOutThePlayerActive({
  bool withReserve = true,
}) {
  final session = RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      // Actif fragile et lent : l'adversaire frappe d'abord et le met à terre.
      player: _combatant(id: 'lead', hp: 12, power: 1, speed: 1),
      playerReserves: <PsdkBattleCombatantSetup>[
        if (withReserve)
          _combatant(id: 'bench', hp: 200, power: 100, speed: 100),
      ],
      opponent: _combatant(id: 'foe', hp: 200, power: 150, speed: 200),
      rngSeeds: _seeds,
      isTrainerBattle: true,
    ),
  );
  session.submitDecision(const BattleDecision.fight(moveSlot: 0));
  return session;
}

const _seeds = PsdkBattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 1,
  generic: 4,
);

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  required int power,
  required int speed,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: hp,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'tackle',
        dbSymbol: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: power,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
}
