import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

/// Le résultat montré au joueur est-il celui que le kernel a décidé ?
///
/// Critère d'acceptation de BETA-BAT-008 : « résultat UI égal au résultat
/// kernel ». Le runtime ne montre pas directement l'état PSDK : il en construit
/// une projection legacy via `createLegacyDisplaySession`, dont l'issue passe par
/// une traduction (`_legacyOutcomeType`). Une erreur de traduction afficherait
/// « victoire » sur une défaite, ou l'inverse — le pire bug possible sur cette
/// surface, parce qu'il est invisible côté moteur.
///
/// Ces cas comparent la projection AU KERNEL, jamais à une valeur écrite à la
/// main : c'est l'accord des deux qui est la propriété, pas la valeur elle-même.
void main() {
  group('BETA-BAT-008 the displayed outcome equals the kernel outcome', () {
    test('victory agrees', () {
      _expectAgreement(
        _playUntilFinished(_setup(playerWins: true)),
        BattleEngineOutcomeKind.victory,
        BattleOutcomeType.victory,
      );
    });

    test('defeat agrees', () {
      _expectAgreement(
        _playUntilFinished(_setup(playerWins: false)),
        BattleEngineOutcomeKind.defeat,
        BattleOutcomeType.defeat,
      );
    });

    test('a successful flight agrees', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(playerWins: true, canFlee: true),
      );
      session.submitDecision(const BattleDecision.flee());

      _expectAgreement(
        session,
        BattleEngineOutcomeKind.fled,
        BattleOutcomeType.runaway,
        allowFlee: true,
      );
    });

    test('a capture agrees', () {
      // Recette d'une capture garantie, reprise du cas existant de
      // runtime_psdk_battle_session_adapter_test : adversaire à 1 PV, endormi,
      // catchRate au maximum et graine générique 47. Ce cas-ci complète
      // l'existant en passant par la projection de SESSION complète plutôt que
      // par createLegacyOutcome seul.
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(
          playerWins: true,
          canCapture: true,
          enemyCatchRate: 255,
          enemyCurrentHp: 1,
          enemyAsleep: true,
          genericSeed: 47,
        ),
      );
      session.submitPlayerChoice(const PlayerBattleChoiceCapture());

      _expectAgreement(
        session,
        BattleEngineOutcomeKind.captured,
        BattleOutcomeType.captured,
        allowCapture: true,
      );
    });

    test('the projection carries the same final HP as the kernel', () {
      // L'issue seule ne suffit pas : un écran de fin qui annoncerait la bonne
      // issue avec les mauvais PV mentirait quand même au joueur.
      final session = _playUntilFinished(_setup(playerWins: true));
      final display = session.createLegacyDisplaySession(isTrainerBattle: false);

      expect(
        display.state.player.currentHp,
        session.state.battlerAt(psdkPlayerSlot).currentHp,
      );
      expect(
        display.state.enemy.currentHp,
        session.state.battlerAt(psdkOpponentSlot).currentHp,
      );
    });

    test('an unfinished battle projects no outcome at all', () {
      // Sans ce cas, une projection qui inventerait une issue en cours de
      // combat passerait inaperçue.
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(playerWins: true),
      );

      expect(session.state.isFinished, isFalse);
      expect(
        session.createLegacyDisplaySession(isTrainerBattle: false).state.outcome,
        isNull,
      );
    });
  });
}

void _expectAgreement(
  RuntimePsdkBattleSessionAdapter session,
  BattleEngineOutcomeKind expectedKernelKind,
  BattleOutcomeType expectedDisplayType, {
  bool allowFlee = false,
  bool allowCapture = false,
}) {
  expect(session.state.isFinished, isTrue, reason: 'the vector needs an end');
  expect(
    session.state.outcome!.kind,
    expectedKernelKind,
    reason: 'the vector must reach the outcome it claims to test',
  );

  final display = session.createLegacyDisplaySession(
    isTrainerBattle: false,
    allowFlee: allowFlee,
    allowCapture: allowCapture,
  );

  expect(display.state.outcome, isNotNull);
  expect(display.state.outcome!.type, expectedDisplayType);
  expect(display.state.isFinished, isTrue);
}

RuntimePsdkBattleSessionAdapter _playUntilFinished(PsdkBattleSetup setup) {
  // L'adaptateur est MUTABLE : submitDecision avance la même instance, il ne
  // rend pas une nouvelle session comme l'API legacy.
  final session = RuntimePsdkBattleSessionAdapter.fromSetup(setup);
  var turns = 0;
  while (!session.state.isFinished && turns < 20) {
    session.submitDecision(const BattleDecision.fight(moveSlot: 0));
    turns++;
  }
  return session;
}

/// Combat asymétrique : le camp qui frappe fort gagne, l'autre encaisse.
PsdkBattleSetup _setup({
  required bool playerWins,
  bool canFlee = false,
  bool canCapture = false,
  int? enemyCatchRate,
  int? enemyCurrentHp,
  bool enemyAsleep = false,
  int genericSeed = 1,
}) {
  return PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(
      id: 'player',
      hp: playerWins ? 200 : 12,
      power: playerWins ? 150 : 1,
      speed: playerWins ? 200 : 1,
    ),
    opponent: _combatant(
      id: 'opponent',
      hp: playerWins ? 12 : 200,
      power: playerWins ? 1 : 150,
      speed: playerWins ? 1 : 200,
      catchRate: enemyCatchRate,
      currentHp: enemyCurrentHp,
      majorStatus: enemyAsleep ? PsdkBattleMajorStatus.sleep : null,
    ),
    rngSeeds: PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 1,
      generic: genericSeed,
    ),
    canFlee: canFlee,
    canCapture: canCapture,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  required int power,
  required int speed,
  int? catchRate,
  int? currentHp,
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: hp,
    currentHp: currentHp ?? hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: speed,
    ),
    catchRate: catchRate,
    majorStatus: majorStatus,
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
